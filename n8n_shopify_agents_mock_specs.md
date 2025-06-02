# IONFLUX Project: n8n Workflow Specifications for Mocked Shopify Agents (E2E Demo)

This document defines the specifications for n8n workflows that will mock the backend logic for the `Shopify Sales Sentinel` and `Revenue Tracker Lite` agents during the E2E Demo. These workflows are triggered by the Agent Service and simulate interactions with Shopify and other services.

**Reference Documents:**
*   `core_agent_blueprints.md`
*   `agent_service_minimal_spec.md`
*   `technical_stack_and_demo_strategy.md`
*   `chat_service_minimal_spec.md` (for Chat Service interaction)

## A. `Shopify Sales Sentinel` (n8n Workflow)

**1. Agent Name:** `Shopify Sales Sentinel`

**2. Trigger:**

*   **Type:** n8n Webhook Node.
*   **Caller:** Agent Service (`POST /agent-configurations/:agentConfigId/run`).
*   **Expected Input from Agent Service (JSON Body):**
    ```json
    {
      "run_id": "uuid", // Unique ID for this execution run
      "agent_configuration_id": "uuid",
      "workspace_id": "uuid",
      "user_id": "uuid", // User who triggered or owns the config
      "yaml_config": { // Parsed YAML content
        "brand_id": "uuid-of-brand-entity",
        "min_order_value_threshold": 200.00,
        "watch_products": [
          {"sku": "TSHIRT-RED-L"}, 
          {"product_id": "gid://shopify/Product/123456789"}
        ],
        "notification_channels": [
          {"type": "chat_dock", "channel_id": "uuid-of-chat-channel"}
          // Other notification types might be ignored by this mock
        ]
      },
      "runtime_params": {} // Optional, may not be used by this agent for demo
    }
    ```

**3. Core Workflow Steps (n8n Nodes - Conceptual):**

1.  **Webhook Node ("Start Sentinel Run"):**
    *   Receives the trigger data from Agent Service.
    *   Responds immediately with HTTP 200 OK to Agent Service (as Agent Service has already marked the run as 'pending').

2.  **Function Node ("Simulate Shopify Order"):**
    *   **Purpose:** Generates a mock Shopify order payload.
    *   **Logic:**
        *   Randomly (or based on a simple counter to cycle through scenarios for demo) decide if this simulated order should trigger an alert.
        *   If triggering:
            *   Generate an order total greater than `input.json.yaml_config.min_order_value_threshold`.
            *   Optionally, include one of the `input.json.yaml_config.watch_products` (match by SKU or product_id).
            *   Example Output (mock order):
                ```json
                {
                  "order_id": "mock-order-123",
                  "total_price": 250.00,
                  "currency": "USD",
                  "customer_name": "Demo Customer", // PII, use placeholder
                  "line_items": [
                    {"product_id": "gid://shopify/Product/123456789", "name": "Watched Product A", "quantity": 1, "price": 150.00},
                    {"product_id": "gid://shopify/Product/987654321", "name": "Another Product", "quantity": 2, "price": 50.00}
                  ],
                  "meets_criteria": true // Flag set by this node
                }
                ```
        *   If not triggering:
            *   Generate an order total less than the threshold.
            *   Example Output: `{"meets_criteria": false}`
    *   Passes this mock order and the original trigger input to the next node.

3.  **IF Node ("Check if Alert Criteria Met"):**
    *   **Purpose:** Checks if the simulated order should trigger an alert.
    *   **Condition:** `{{ $json.SimulateShopifyOrder.output.meets_criteria === true }}` (Accessing output from previous node).
    *   **True Branch:** Proceeds to format and send notification.
    *   **False Branch:** Proceeds directly to "End Workflow" or "Callback to Agent Service (No Alert)".

4.  **Function Node ("Format Alert Message") - (True Branch Only):**
    *   **Purpose:** Creates the alert message string.
    *   **Input:** Original trigger data (for `channel_id`) and the simulated order data.
    *   **Logic:** Constructs a message, e.g.,
        `"🎉 New High-Value Order! Order #{{ $json.SimulateShopifyOrder.output.order_id }} for ${{ $json.SimulateShopifyOrder.output.total_price }} {{ $json.SimulateShopifyOrder.output.currency }} from {{ $json.SimulateShopifyOrder.output.customer_name }}. Product: {{ $json.SimulateShopifyOrder.output.line_items[0].name }}. (Mocked for Demo)"`
    *   **Output:** `{"alert_message": "formatted_string", "target_channel_id": "uuid-from-yaml_config"}`

5.  **HTTP Request Node ("Send to Chat Service") - (True Branch Only):**
    *   **Purpose:** Sends the alert message to the (mocked or minimal) Chat Service.
    *   **Method:** POST
    *   **URL:** A predefined webhook URL for the demo Chat Service to receive agent messages (e.g., `http://chat-service-url/internal/channels/{{ $json.FormatAlertMessage.output.target_channel_id }}/agent-messages`). This URL needs to be configurable in n8n.
    *   **Authentication:** Bearer Token (using a shared secret between n8n and the mock Chat Service for demo).
    *   **Body (JSON):**
        ```json
        {
          "sender_id": "{{ $json.WebhookStart.body.agent_configuration_id }}", // Sentinel Agent's Config ID
          "sender_type": "agent",
          "content_type": "text", // Or markdown
          "content": {"text": "{{ $json.FormatAlertMessage.output.alert_message }}"}
        }
        ```
    *   *Note: This simulates `Agent Service` calling `Chat Service` as per `chat_service_minimal_spec.md`.*

6.  **HTTP Request Node ("Callback to Agent Service - Alert Sent") - (True Branch, Optional):**
    *   **Purpose:** Notifies Agent Service of successful alert generation.
    *   **URL:** `{{ $env.AGENT_SERVICE_URL }}/runs/{{ $json.WebhookStart.body.run_id }}/completed` (Agent Service URL from n8n environment variable).
    *   **Method:** POST
    *   **Authentication:** Shared secret if implemented on Agent Service callback.
    *   **Body (JSON):**
        ```json
        {
          "agent_configuration_id": "{{ $json.WebhookStart.body.agent_configuration_id }}",
          "status": "success",
          "output_preview": "{{ $json.FormatAlertMessage.output.alert_message.substring(0, 100) }}" // First 100 chars
        }
        ```

7.  **HTTP Request Node ("Callback to Agent Service - No Alert") - (False Branch, Optional):**
    *   **Purpose:** Notifies Agent Service that no alert was generated.
    *   **URL:** `{{ $env.AGENT_SERVICE_URL }}/runs/{{ $json.WebhookStart.body.run_id }}/completed`
    *   **Method:** POST
    *   **Body (JSON):**
        ```json
        {
          "agent_configuration_id": "{{ $json.WebhookStart.body.agent_configuration_id }}",
          "status": "success", // Workflow itself succeeded, just no alert
          "output_preview": "No new orders met alert criteria. (Mocked)"
        }
        ```

**4. Output/Callback:**

*   Primary output is the HTTP request to the Chat Service (if criteria met).
*   Secondary, optional callback to Agent Service's `/runs/:runId/completed` endpoint to update `last_run_status` and `last_run_output_preview` on the `AgentConfiguration`. This helps the UI reflect that the agent ran.

---

## B. `Revenue Tracker Lite` (n8n Workflow)

**1. Agent Name:** `Revenue Tracker Lite`

**2. Trigger:**

*   **Type:** n8n Webhook Node.
*   **Caller:** Agent Service (`POST /agent-configurations/:agentConfigId/run`).
*   **Expected Input from Agent Service (JSON Body):**
    ```json
    {
      "run_id": "uuid",
      "agent_configuration_id": "uuid",
      "workspace_id": "uuid",
      "user_id": "uuid",
      "yaml_config": { // Parsed YAML content
        "brand_id": "uuid-of-brand-entity",
        "reporting_period": "last_7_days" // e.g., "last_30_days"
        // "num_top_products": 5 (can be used by mock)
      },
      "runtime_params": {} // Likely not used for this agent in demo
    }
    ```

**3. Core Workflow Steps (n8n Nodes - Conceptual):**

1.  **Webhook Node ("Start Revenue Tracking"):**
    *   Receives trigger data.
    *   Responds immediately with HTTP 200 OK to Agent Service.

2.  **Function Node ("Generate Mock Revenue Data"):**
    *   **Purpose:** Creates mocked revenue figures based on the `reporting_period`.
    *   **Input:** `input.json.yaml_config.reporting_period`.
    *   **Logic:**
        *   Use simple logic or a switch:
            *   If "last_7_days": `total_sales = Math.random() * 1000 + 500`, `aov = total_sales / (Math.random() * 10 + 5)`.
            *   If "last_30_days": `total_sales = Math.random() * 5000 + 2000`, `aov = total_sales / (Math.random() * 50 + 20)`.
        *   Generate a few mock top products:
            ```javascript
            // Example JavaScript in Function Node
            let sales = parseFloat((Math.random() * 1000 + 500).toFixed(2));
            let orders = parseInt(Math.random() * 20 + 10);
            let aov = parseFloat((sales / orders).toFixed(2));
            
            item.json.mock_revenue_data = {
              total_sales: sales,
              average_order_value: aov,
              top_products: [
                { name: "Mock Product Alpha", sales: parseFloat((sales * 0.3).toFixed(2)), units: parseInt(orders * 0.3) },
                { name: "Mock Product Beta", sales: parseFloat((sales * 0.2).toFixed(2)), units: parseInt(orders * 0.2) }
              ],
              reporting_period: items[0].json.yaml_config.reporting_period
            };
            return item;
            ```
    *   **Output:** JSON object with fields like `total_sales`, `average_order_value`, `top_products`, `reporting_period`.

3.  **HTTP Request Node ("Callback to Agent Service"):**
    *   **Purpose:** Sends the mocked data back to Agent Service to update the agent's status and output preview.
    *   **URL:** `{{ $env.AGENT_SERVICE_URL }}/runs/{{ $json.WebhookStart.body.run_id }}/completed`.
    *   **Method:** POST
    *   **Authentication:** Shared secret if implemented.
    *   **Body (JSON):**
        ```json
        {
          "agent_configuration_id": "{{ $json.WebhookStart.body.agent_configuration_id }}",
          "status": "success",
          "output_preview": "Total Sales ({{ $json.GenerateMockRevenueData.output.reporting_period }}): ${{ $json.GenerateMockRevenueData.output.total_sales.toFixed(2) }}. AOV: ${{ $json.GenerateMockRevenueData.output.average_order_value.toFixed(2) }} (Mocked)",
          "full_output_reference": "{{ JSON.stringify($json.GenerateMockRevenueData.output) }}" 
          // For demo, we can send the full JSON as a string in full_output_reference or directly in output_preview if small enough.
          // Agent Service would need to parse this if it's to store it more structuredly.
        }
        ```
        *   *Note: `output_preview` should be a concise string. The `Agent Snippet` block on the Canvas will display this. The full JSON data could be stored by Agent Service if it has a field like `last_run_full_output (JSONB)` or just passed through to be part of the `output_preview` if the preview can handle structured data.* For this demo, we'll assume `output_preview` can take the string summary, and the Canvas block will get the full data from `full_output_reference` if it were to implement a "View Full Output" feature. For the E2E demo, simply updating `output_preview` with key metrics is sufficient.

**4. Output/Callback:**

*   The primary output is the HTTP POST request to the Agent Service's `/runs/:runId/completed` endpoint.
*   This callback provides the `status: 'success'` and the `output_preview` (and optionally `full_output_reference`) which the Agent Service then stores in the `AgentConfiguration` record. The frontend `Agent Snippet` block will then fetch these updated details to display the results.

---

These n8n workflow specifications provide a clear path for mocking the backend behavior of the specified Shopify agents, enabling the E2E demo to proceed without requiring full Shopify API integration or complex agent logic implementation at this stage. The n8n webhook URLs will need to be configured in the Agent Service's mapping for these agent definitions.
```
