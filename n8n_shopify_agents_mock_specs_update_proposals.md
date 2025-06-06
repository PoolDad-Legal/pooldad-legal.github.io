# IONFLUX Project: n8n Workflow Specifications for Mocked Shopify Agents - Update Proposals

This document proposes updates to `n8n_shopify_agents_mock_specs.md` to align with the updated `core_agent_blueprints.md`, the revised `agent_interaction_model.md` (which clarifies how `AgentService` creates an 'effective configuration'), and the latest service specifications.

The main focus is on ensuring the n8n workflow's trigger input and internal logic correctly reflect the use of an "effective configuration" passed by the Agent Service, and that outputs align with the agent's defined capabilities and callback mechanisms.

---

## Proposed Revisions for `n8n_shopify_agents_mock_specs.md`

Below are proposed textual revisions for each Shopify agent n8n workflow.

### A. `Shopify Sales Sentinel` (n8n Workflow)

**2. Trigger:**

*   **Current "Expected Input from Agent Service (JSON Body)":** Shows `yaml_config` as a direct key.
*   **Proposed Revision to "Expected Input from Agent Service (JSON Body)":**
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
      // No separate runtime_params here, they are merged into effective_config by AgentService
    }
    ```
*   **Rationale:** The `agent_interaction_model.md` (Section 6, Step 5) now clarifies that `Agent Service` resolves and merges `yaml_config` from `AgentConfiguration` with any `runtime_params` into an "effective configuration" before triggering the agent logic (n8n workflow in this case). The n8n workflow should expect this merged `effective_config`.

**3. Core Workflow Steps (n8n Nodes - Conceptual):**

1.  **Webhook Node ("Start Sentinel Run"):**
    *   No change to its basic function of receiving data.

2.  **Function Node ("Simulate Shopify Order"):**
    *   **Logic:**
        *   **Current:** "Generate an order total greater than `input.json.yaml_config.min_order_value_threshold`." and "Optionally, include one of the `input.json.yaml_config.watch_products`"
        *   **Proposed Revision:** "Generate an order total. Compare this with `input.json.body.effective_config.min_order_value_threshold`." and "Optionally, include a product in the mock order that matches one of the criteria in `input.json.body.effective_config.watch_products` (e.g., by SKU or product_id if present in `watch_products`)."
    *   **Rationale:** Update path to reflect `effective_config`.

3.  **IF Node ("Check if Alert Criteria Met"):**
    *   No change in basic function, but conditions will use `effective_config`.

4.  **Function Node ("Format Alert Message") - (True Branch Only):**
    *   **Input:**
        *   **Current:** "Original trigger data (for `channel_id`)"
        *   **Proposed Revision:** "Input from Webhook node, specifically `effective_config.notification_channels` to find the target `channel_id` for 'chat_dock' type, and the simulated order data."
    *   **Logic:**
        *   Refine message to be more representative of `core_agent_blueprints.md` "Exemplo Integrado" for Shopify Sales Sentinel, e.g., "IONFLUX Sentinel Alert for [Brand Name]: New order [Order #] for [Amount]..."
    *   **Output:** `{"alert_message": "formatted_string", "target_channel_id": "uuid-from-effective_config"}`
    *   **Rationale:** Ensure the message is informative and uses the correct `channel_id` from the `effective_config`.

5.  **HTTP Request Node ("Send to Chat Service") - (True Branch Only):**
    *   **URL:** `http://chat-service-url/internal/channels/{{ $json.FormatAlertMessage.output.target_channel_id }}/agent-messages` (ensure `target_channel_id` is correctly extracted from `effective_config.notification_channels`).
    *   **Body (JSON):**
        ```json
        {
          "sender_id": "{{ $json.WebhookStart.body.agent_configuration_id }}",
          "sender_type": "agent",
          "content_type": "markdown", // Or "text", as per agent's output capability
          "content": {"text": "{{ $json.FormatAlertMessage.output.alert_message }}"}
        }
        ```
    *   **Rationale:** Align with Chat Service spec for agent messages.

6.  **HTTP Request Node ("Callback to Agent Service - Alert Sent") - (True Branch, Optional):**
    *   **Body (JSON):**
        ```json
        {
          "agent_configuration_id": "{{ $json.WebhookStart.body.agent_configuration_id }}",
          "run_id": "{{ $json.WebhookStart.body.run_id }}", // Add run_id
          "status": "success",
          "output_preview": "{{ $json.FormatAlertMessage.output.alert_message.substring(0, 250) }}", // Max 250 chars for preview
          "full_output_reference": null // Or "mock://output/sentinel_alert_{{$json.WebhookStart.body.run_id}}.md" if storing mock MD
        }
        ```
    *   **Rationale:** Include `run_id` in callback as per Agent Service spec. `output_preview` should be concise. `full_output_reference` could point to a conceptual mock storage for the full markdown alert if the agent was designed to produce a more detailed `incident_report: md`.

7.  **HTTP Request Node ("Callback to Agent Service - No Alert") - (False Branch, Optional):**
    *   **Body (JSON):**
        ```json
        {
          "agent_configuration_id": "{{ $json.WebhookStart.body.agent_configuration_id }}",
          "run_id": "{{ $json.WebhookStart.body.run_id }}", // Add run_id
          "status": "success",
          "output_preview": "Shopify Sales Sentinel run: No new orders met alert criteria. (Mocked)",
          "full_output_reference": null
        }
        ```

---

### B. `Revenue Tracker Lite` (n8n Workflow)

**2. Trigger:**

*   **Current "Expected Input from Agent Service (JSON Body)":** Shows `yaml_config` as a direct key.
*   **Proposed Revision to "Expected Input from Agent Service (JSON Body)":**
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
*   **Rationale:** Align with Agent Service passing the merged `effective_config`.

**3. Core Workflow Steps (n8n Nodes - Conceptual):**

1.  **Webhook Node ("Start Revenue Tracking"):** No change.

2.  **Function Node ("Generate Mock Revenue Data"):**
    *   **Input:** Use `input.json.body.effective_config.reporting_period` and `input.json.body.effective_config.num_top_products`.
    *   **Logic (JS example refinement):**
        ```javascript
        // Access effective_config
        const config = $json.body.effective_config;
        const reporting_period = config.reporting_period || "last_7_days";
        const num_top_products = config.num_top_products || 3;

        let sales_factor = 1;
        if (reporting_period === "last_30_days") {
          sales_factor = 4;
        }

        let total_sales = parseFloat((Math.random() * 1000 * sales_factor + 500 * sales_factor).toFixed(2));
        let orders = parseInt(Math.random() * 20 * sales_factor + 10 * sales_factor);
        let aov = orders > 0 ? parseFloat((total_sales / orders).toFixed(2)) : 0;

        const top_products_list = [];
        for (let i = 0; i < num_top_products; i++) {
          top_products_list.push({
            name: `Mock Product ${String.fromCharCode(65 + i)} (${reporting_period})`, // Alpha, Beta...
            sales: parseFloat((total_sales * (Math.random() * 0.15 + 0.05)).toFixed(2)), // Smaller portion for each top product
            units: parseInt(orders * (Math.random() * 0.15 + 0.05))
          });
        }

        // Structure matches pnl_dashboard: json output type from blueprint
        item.json.pnl_dashboard_data = {
          summary: {
             title: `Revenue Report (${reporting_period}) - Mocked`,
             total_sales: total_sales,
             average_order_value: aov,
             total_orders: orders
          },
          top_products: top_products_list,
          reporting_period: reporting_period // Keep for context
        };
        return item;
        ```
    *   **Output:** `{"pnl_dashboard_data": { ... structured JSON ... }}`.
    *   **Rationale:** Use `effective_config`. Structure the output to be a valid JSON object as expected by `pnl_dashboard: json` output type. This structure is more aligned with a dashboard's needs than just loose top-level keys.

3.  **HTTP Request Node ("Callback to Agent Service"):**
    *   **Body (JSON):**
        ```json
        {
          "agent_configuration_id": "{{ $json.WebhookStart.body.agent_configuration_id }}",
          "run_id": "{{ $json.WebhookStart.body.run_id }}", // Add run_id
          "status": "success",
          "output_preview": "Revenue for {{ $json.GenerateMockRevenueData.output.pnl_dashboard_data.reporting_period }}: ${{ $json.GenerateMockRevenueData.output.pnl_dashboard_data.summary.total_sales.toFixed(2) }} (Mocked)",
          "full_output_reference": "{{ JSON.stringify($json.GenerateMockRevenueData.output.pnl_dashboard_data) }}"
        }
        ```
    *   **Rationale:** The `output_preview` is a human-readable summary. The `full_output_reference` now contains the stringified JSON of the `pnl_dashboard_data` object, which the Agent Snippet block on the frontend can then parse and display more richly if designed to do so.

---

These revisions ensure that the n8n mock workflows expect the correct input structure (effective configuration) from the Agent Service and produce outputs (preview and full reference) that are consistent with the updated agent blueprints and data models.
```
