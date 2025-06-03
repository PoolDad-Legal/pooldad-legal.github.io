# IONFLUX Project: n8n Workflow Specifications for Mocked Shopify Agents (E2E Demo)

This document defines the specifications for n8n workflows that will mock the backend logic for the `Shopify Sales Sentinel` and `Revenue Tracker Lite` agents during the E2E Demo. These workflows are triggered by the Agent Service and simulate interactions with Shopify and other services, aligning with updated agent blueprints and interaction models.

**Reference Documents:**
*   `core_agent_blueprints.md` (AGENTE 004 - ShopifySalesSentinel, AGENTE 010 - RevenueTrackerLite)
*   `agent_service_minimal_spec.md`
*   `agent_interaction_model.md`
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
      "effective_config": { // Merged config: AgentConfiguration.yaml_config + runtime_params
        // Specific keys from Agent 004's inputs_schema:
        "brand_id": "uuid-of-brand-entity",
        "min_order_value_threshold": 200.00,
        "watch_products": [ // Example structure
          {"sku": "TSHIRT-RED-L"},
          {"product_id": "gid://shopify/Product/123456789"},
          {"title_contains": "Limited Edition"}
        ],
        "notification_channels": [ // Example structure
          {"type": "chat_dock", "channel_id": "uuid-of-chat-channel"}
          // Other types like "email", "in_app" might be present
        ]
        // other potential inputs from the agent's inputs_schema...
      }
    }
    ```

**3. Core Workflow Steps (n8n Nodes - Conceptual):**

1.  **Webhook Node ("Start Sentinel Run"):**
    *   Receives the trigger data from Agent Service.
    *   Responds immediately with HTTP 200 OK to Agent Service.

2.  **Function Node ("Simulate Shopify Order"):**
    *   **Purpose:** Generates a mock Shopify order payload.
    *   **Logic:**
        *   Randomly (or based on a simple counter to cycle through scenarios for demo) decide if this simulated order should trigger an alert.
        *   Access parameters from `input.json.body.effective_config`.
        *   If triggering:
            *   Generate an order total greater than `effective_config.min_order_value_threshold`.
            *   Optionally, include a product in the mock order that matches one of the criteria in `effective_config.watch_products`.
            *   Example Output (mock order):
                ```json
                {
                  "order_id": "mock-order-123",
                  "total_price": 250.00,
                  "currency": "USD",
                  "customer_name": "Demo Customer",
                  "line_items": [
                    {"product_id": "gid://shopify/Product/123456789", "name": "Watched Product A", "quantity": 1, "price": 150.00},
                    {"product_id": "gid://shopify/Product/987654321", "name": "Another Product", "quantity": 2, "price": 50.00}
                  ],
                  "brand_name": "Mocked Brand Name", // Could be fetched or part of effective_config if needed for message
                  "meets_criteria": true
                }
                ```
        *   If not triggering:
            *   Generate an order total less than the threshold.
            *   Example Output: `{"meets_criteria": false}`
    *   Passes this mock order and the original trigger input (especially `effective_config`) to the next node.

3.  **IF Node ("Check if Alert Criteria Met"):**
    *   **Purpose:** Checks if the simulated order should trigger an alert.
    *   **Condition:** `{{ $json.SimulateShopifyOrder.output.meets_criteria === true }}`.
    *   **True Branch:** Proceeds to format and send notification.
    *   **False Branch:** Proceeds to "Callback to Agent Service (No Alert)".

4.  **Function Node ("Format Alert Message") - (True Branch Only):**
    *   **Purpose:** Creates the alert message string.
    *   **Input:** Data from "Simulate Shopify Order" and `effective_config` from webhook (for `notification_channels`).
    *   **Logic:**
        *   Extract `target_channel_id` from `effective_config.notification_channels` where `type` is 'chat_dock'.
        *   Constructs a message, e.g., `"IONFLUX Sentinel Alert for [Brand Name]: New order #{{ $json.SimulateShopifyOrder.output.order_id }} for ${{ $json.SimulateShopifyOrder.output.total_price }} {{ $json.SimulateShopifyOrder.output.currency }}. (Mocked)"`
    *   **Output:** `{"alert_message": "formatted_string", "target_channel_id": "uuid-from-effective_config"}`

5.  **HTTP Request Node ("Send to Chat Service") - (True Branch Only):**
    *   **Purpose:** Sends the alert message to the (mocked or minimal) Chat Service.
    *   **Method:** POST
    *   **URL:** A predefined webhook URL for the demo Chat Service (e.g., `http://chat-service-url/internal/channels/{{ $json.FormatAlertMessage.output.target_channel_id }}/agent-messages`).
    *   **Authentication:** Bearer Token (shared secret for demo).
    *   **Body (JSON):**
        ```json
        {
          "sender_id": "{{ $json.WebhookStart.body.agent_configuration_id }}",
          "sender_type": "agent",
          "content_type": "markdown",
          "content": {"text": "{{ $json.FormatAlertMessage.output.alert_message }}"}
        }
        ```

6.  **HTTP Request Node ("Callback to Agent Service - Alert Sent") - (True Branch):**
    *   **Purpose:** Notifies Agent Service of successful alert generation.
    *   **URL:** `{{ $json.WebhookStart.body.env.AGENT_SERVICE_URL || "http://localhost:8001/api/v1" }}/runs/{{ $json.WebhookStart.body.run_id }}/completed` (Agent Service URL from n8n environment variable or part of initial trigger for robustness).
    *   **Method:** POST
    *   **Authentication:** Shared secret if implemented on Agent Service callback.
    *   **Body (JSON):**
        ```json
        {
          "agent_configuration_id": "{{ $json.WebhookStart.body.agent_configuration_id }}",
          "run_id": "{{ $json.WebhookStart.body.run_id }}",
          "status": "success",
          "output_preview": "{{ $json.FormatAlertMessage.output.alert_message.substring(0, 250) }}",
          "full_output_reference": null // For demo, preview is sufficient for Sentinel. Could be mock markdown ref.
        }
        ```

7.  **HTTP Request Node ("Callback to Agent Service - No Alert") - (False Branch):**
    *   **Purpose:** Notifies Agent Service that no alert was generated.
    *   **URL:** `{{ $json.WebhookStart.body.env.AGENT_SERVICE_URL || "http://localhost:8001/api/v1" }}/runs/{{ $json.WebhookStart.body.run_id }}/completed`.
    *   **Method:** POST
    *   **Body (JSON):**
        ```json
        {
          "agent_configuration_id": "{{ $json.WebhookStart.body.agent_configuration_id }}",
          "run_id": "{{ $json.WebhookStart.body.run_id }}",
          "status": "success",
          "output_preview": "Shopify Sales Sentinel run: No new orders met alert criteria. (Mocked)",
          "full_output_reference": null
        }
        ```

**4. Output/Callback:**

*   Primary output (if criteria met) is the HTTP request to the Chat Service.
*   Secondary callback to Agent Service's `/runs/:runId/completed` endpoint updates `last_run_status` and `last_run_output_preview` on the `AgentConfiguration`.

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
      "effective_config": { // Merged config: AgentConfiguration.yaml_config + runtime_params
        // Specific keys from Agent 010's inputs_schema:
        "brand_id": "uuid-of-brand-entity",
        "reporting_period": "last_7_days", // e.g., "last_30_days"
        "num_top_products": 5 // Example value
        // other potential inputs...
      }
    }
    ```

**3. Core Workflow Steps (n8n Nodes - Conceptual):**

1.  **Webhook Node ("Start Revenue Tracking"):**
    *   Receives trigger data.
    *   Responds immediately with HTTP 200 OK to Agent Service.

2.  **Function Node ("Generate Mock Revenue Data"):**
    *   **Purpose:** Creates mocked revenue figures based on `effective_config.reporting_period` and `effective_config.num_top_products`.
    *   **Input:** `input.json.body.effective_config`.
    *   **Logic (JS example refinement):**
        ```javascript
        const config = $json.body.effective_config;
        const reporting_period = config.reporting_period || "last_7_days";
        const num_top_products = config.num_top_products || 3;

        let sales_factor = 1;
        if (reporting_period === "last_30_days") {
          sales_factor = 4;
        }

        let total_sales = parseFloat((Math.random() * 1000 * sales_factor + 500 * sales_factor).toFixed(2));
        let orders = Math.max(1, parseInt(Math.random() * 20 * sales_factor + 10 * sales_factor)); // Ensure orders > 0
        let aov = parseFloat((total_sales / orders).toFixed(2));

        const top_products_list = [];
        for (let i = 0; i < num_top_products; i++) {
          top_products_list.push({
            name: `Mock Product ${String.fromCharCode(65 + i)} (${reporting_period})`,
            sales: parseFloat((total_sales * (Math.random() * 0.15 + 0.05)).toFixed(2)),
            units: Math.max(1, parseInt(orders * (Math.random() * 0.15 + 0.05)))
          });
        }

        // Align with pnl_dashboard: json output type from blueprint AGENTE 010
        item.json.pnl_dashboard_data = {
          summary: {
             title: `Revenue Report (${reporting_period}) - Mocked by n8n`,
             total_sales: total_sales,
             average_order_value: aov,
             total_orders: orders
          },
          top_products: top_products_list,
          reporting_period: reporting_period
        };
        return item;
        ```
    *   **Output:** `{"pnl_dashboard_data": { ... structured JSON ... }}`.

3.  **HTTP Request Node ("Callback to Agent Service"):**
    *   **Purpose:** Sends the mocked data back to Agent Service.
    *   **URL:** `{{ $json.body.env.AGENT_SERVICE_URL || "http://localhost:8001/api/v1" }}/runs/{{ $json.body.run_id }}/completed`.
    *   **Method:** POST
    *   **Authentication:** Shared secret if implemented.
    *   **Body (JSON):**
        ```json
        {
          "agent_configuration_id": "{{ $json.WebhookStart.body.agent_configuration_id }}",
          "run_id": "{{ $json.WebhookStart.body.run_id }}",
          "status": "success",
          "output_preview": "Revenue for {{ $json.GenerateMockRevenueData.output.pnl_dashboard_data.reporting_period }}: ${{ $json.GenerateMockRevenueData.output.pnl_dashboard_data.summary.total_sales.toFixed(2) }} (Mocked)",
          "full_output_reference": "{{ JSON.stringify($json.GenerateMockRevenueData.output.pnl_dashboard_data) }}"
        }
        ```

**4. Output/Callback:**

*   The primary output is the HTTP POST request to the Agent Service's `/runs/:runId/completed` endpoint.
*   `output_preview` provides a human-readable summary.
*   `full_output_reference` contains the stringified JSON of the `pnl_dashboard_data`, aligning with the agent's defined output of `pnl_dashboard: json`.

---

These revisions ensure the n8n mock workflows are aligned with the concept of receiving an "effective configuration" and that their outputs (both preview and full reference) are structured consistently with the agent blueprints and the Agent Service's expectations.
```
