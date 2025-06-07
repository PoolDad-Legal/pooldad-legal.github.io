# Agent Blueprint: Symbiosis Plugin Agent - v0.9.0

## 1. Overview

*   **Agent Name:** `Symbiosis Plugin Agent`
*   **Version:** `0.9.0`
*   **Status:** `development`
*   **Primary Goal:** `Manages secure interaction with third-party plugins and external APIs, acting as a controlled gateway. It uses specialized transforms for each plugin/API, ensuring that access is mediated by IONWALL, user consent, and secure credential management (conceptually via IONWALLET or a secure IONPOD store).`
*   **Key Features:**
    *   Provides a unified interface for other IONFLUX agents to interact with a variety of external services and APIs (e.g., Shopify, Stripe, GitHub, Zapier, Google Workspace, custom enterprise tools).
    *   Each external service integration is handled by a dedicated, secure "Plugin Transform" (e.g., `SecureShopifyAPI_Admin_Transform_IONWALL`, `GoogleCalendar_ReadEvents_Transform_IONWALL`).
    *   Manages API keys, OAuth tokens, and other credentials securely, ideally by interacting with IONWALLET or a specially secured IONPOD container with IONWALL mediation for access by specific Plugin Transforms.
    *   All operations, including data to be sent to and received from external services, require IONWALL approval by the user.
    *   Maintains audit logs of all external interactions in the user's IONPOD.
    *   Can be configured with plugin-specific settings and parameters stored in IONPOD.

## 2. FluxGraph Definition (Conceptual YAML)

```yaml
# /specs/agents/symbiosis_plugin_agent_fluxgraph.yaml (Conceptual representation)
# This FluxGraph is often a router to specific sub-graphs or directly to plugin transforms based on input.
version: "0.1.0" # FluxGraph spec version
name: "symbiosis_plugin_agent_fluxgraph"
description: "Manages secure interactions with third-party plugins and external APIs."

triggers:
  - type: "manual" # For direct "execute this plugin action" calls.
  - type: "event_driven"
    config: { event_source: "NATS", topic: "ionflux.agents.symbiosis.invoke_plugin" } # Triggered by other agents.

input_schema: # JSON schema for "invoke_plugin" type triggers
  type: "object"
  properties:
    plugin_id: { type: "string", description: "Identifier for the target plugin/API (e.g., 'shopify_admin', 'google_calendar_read'). Determines which Plugin Transform to use." }
    action_name: { type: "string", description: "Specific action/endpoint to call within the plugin (e.g., 'create_product', 'list_upcoming_events')." }
    plugin_config_cid: { type: "string", nullable: true, description: "Optional CID of an IONPOD object containing specific configurations for this plugin invocation (e.g., API version, specific flags)." }
    # Credentials are NOT passed directly in input. They are fetched by the dedicated Plugin Transform using IONWALL/IONWALLET.
    payload: { type: "object", additionalProperties: true, description: "Data payload to be sent to the plugin/API action." }
  required: [ "plugin_id", "action_name", "payload" ]

output_schema: # JSON schema for the agent's final output
  type: "object"
  properties:
    plugin_id: { type: "string" }
    action_name: { type: "string" }
    response_payload: { type: "object", additionalProperties: true, nullable: true, description: "Response data from the plugin/API." }
    status: { type: "string", enum: ["success", "failure", "plugin_specific_error"] }
    error_message: { type: "string", nullable: true }
    external_request_id: { type: "string", nullable: true, description: "ID of the request if provided by the external API." }
  required: ["plugin_id", "action_name", "status"]

graph: # DAG of transforms - This is a router graph.
  - id: "fetch_plugin_runtime_config_conditional"
    transform: "FetchFromIONPOD_Transform_IONWALL"
    if: "{{trigger.input_data.plugin_config_cid != null}}"
    ionwall_approval_scope: "read_pod_data:symbiosis_plugin_config" # Scope for reading plugin operational configs
    inputs:
      cid: "{{trigger.input_data.plugin_config_cid}}"
    outputs: [plugin_runtime_config_obj]

  # Router to specific Plugin Transforms based on plugin_id and action_name
  # This is highly conceptual. A real engine might use dynamic transform loading or a large switch.
  # We'll illustrate one path for Shopify 'create_product' example.
  - id: "route_to_plugin_action"
    transform: "PluginActionRouter_Transform" # Hypothetical: routes based on plugin_id and action_name
    inputs:
      plugin_id: "{{trigger.input_data.plugin_id}}"
      action_name: "{{trigger.input_data.action_name}}"
    outputs: [
        is_shopify_create_product,
        is_google_calendar_list_events
        # ... other boolean flags for each supported plugin/action
    ]

  # Shopify Create Product Path Example
  - id: "call_shopify_create_product"
    transform: "SecureShopifyAPI_Admin_Transform_IONWALL" # This is a specialized, secure transform
    if: "{{nodes.route_to_plugin_action.outputs.is_shopify_create_product == true}}"
    # This transform internally handles:
    # 1. Requesting IONWALL approval for "access_external_api:shopify_admin_create_product".
    # 2. Requesting IONWALL/IONWALLET to provide Shopify API credentials securely.
    # 3. Making the API call to Shopify.
    # 4. Returning the response.
    ionwall_approval_scope: "access_external_api:shopify_admin_create_product" # Overall scope for this specific action
    inputs:
      shopify_action: "create_product" # Internal parameter for the transform
      product_data: "{{trigger.input_data.payload}}" # e.g., { title: "IONFLUX T-Shirt", price: "25.00" }
      # shopify_api_version: from plugin_runtime_config_obj or agent default PRM
      # shopify_credentials_query: A query/reference for IONWALLET to fetch the right creds.
    outputs: [shopify_response_obj, shopify_status_code, shopify_error_msg, shopify_request_id]

  # Google Calendar List Events Path Example (Conceptual)
  # - id: "call_google_calendar_list_events"
  #   transform: "SecureGoogleCalendar_ReadEvents_Transform_IONWALL"
  #   if: "{{nodes.route_to_plugin_action.outputs.is_google_calendar_list_events == true}}"
  #   ionwall_approval_scope: "access_external_api:google_calendar_read_events"
  #   inputs:
  #     calendar_id: "{{trigger.input_data.payload.calendar_id || 'primary'}}"
  #     time_min: "{{trigger.input_data.payload.time_min}}" # e.g., now
  #     max_results: "{{trigger.input_data.payload.max_results || 10}}"
  #   outputs: [gcal_events_array, gcal_status_code, gcal_error_msg]

  - id: "aggregate_plugin_results" # Collects results from whichever plugin path was taken
    transform: "MergePluginResults_Transform" # Hypothetical, picks the non-null result based on active path
    inputs:
      shopify_result: { payload: "{{nodes.call_shopify_create_product.outputs.shopify_response_obj}}", status_code: "{{nodes.call_shopify_create_product.outputs.shopify_status_code}}", error: "{{nodes.call_shopify_create_product.outputs.shopify_error_msg}}", req_id: "{{nodes.call_shopify_create_product.outputs.shopify_request_id}}", if_condition: "{{nodes.route_to_plugin_action.outputs.is_shopify_create_product}}"}
      # gcal_result: { payload: "{{nodes.call_google_calendar_list_events.outputs.gcal_events_array}}", ... if_condition: "{{nodes.route_to_plugin_action.outputs.is_google_calendar_list_events}}"}
    outputs: [final_response_payload, final_status_enum, final_error_message, final_external_request_id]
    # final_status_enum would be 'success', 'failure', or 'plugin_specific_error' based on status_code

  - id: "log_plugin_interaction"
    transform: "StoreToIONPOD_Transform_IONWALL"
    ionwall_approval_scope: "write_pod_data:symbiosis_interaction_log"
    inputs:
      data_to_store: {
        timestamp: "{{system.timestamp_utc}}",
        agent_name: "Symbiosis Plugin Agent", version: "0.9.0",
        plugin_id: "{{trigger.input_data.plugin_id}}",
        action_name: "{{trigger.input_data.action_name}}",
        status: "{{nodes.aggregate_plugin_results.outputs.final_status_enum}}",
        external_request_id: "{{nodes.aggregate_plugin_results.outputs.final_external_request_id}}",
        error_if_any: "{{nodes.aggregate_plugin_results.outputs.final_error_message}}",
        # For security, request payload & response payload might be omitted or heavily summarized/anonymized in logs by default
        # payload_sent_summary_cid: (CID of stored, possibly redacted, request payload)
        # response_received_summary_cid: (CID of stored, possibly redacted, response payload)
      }
      filename_suggestion: "symbiosis_log_{{trigger.input_data.plugin_id}}_{{system.timestamp_utc_iso}}.json"
    outputs: [log_entry_cid]

  - id: "publish_completion_event_nats"
    transform: "IPC_NATS_Publish_Transform"
    inputs:
      topic: "ionflux.agents.symbiosis.invoke_plugin.completion"
      message:
        status: "{{nodes.aggregate_plugin_results.outputs.final_status_enum}}"
        plugin_id: "{{trigger.input_data.plugin_id}}"
        action_name: "{{trigger.input_data.action_name}}"
        response_payload: "{{nodes.aggregate_plugin_results.outputs.final_response_payload}}" # This could be large, consider CID if too big for NATS.
        error_message: "{{nodes.aggregate_plugin_results.outputs.final_error_message}}"
        external_request_id: "{{nodes.aggregate_plugin_results.outputs.final_external_request_id}}"
        log_cid: "{{nodes.log_plugin_interaction.outputs.log_entry_cid}}"
        trigger_input_summary: { plugin_id: "{{trigger.input_data.plugin_id}}", action_name: "{{trigger.input_data.action_name}}" } # Avoid sending full payload back
    dependencies: [log_plugin_interaction]
```

---
## 3. Database Schema Fields (`agent_definitions` table)

### 3.1. `agent_name`
`"Symbiosis Plugin Agent"`

### 3.2. `version`
`"0.9.0"`

### 3.3. `description`
`"Manages secure interaction with third-party plugins and external APIs, acting as a controlled gateway. Uses specialized transforms for each plugin/API, ensuring access is mediated by IONWALL, user consent, and secure credential management."`

### 3.4. `status`
`"development"`

### 3.5. `flux_graph_dsl_yaml`
*(The YAML content from Section 2 is inserted here as a multi-line string)*
```yaml
version: "0.1.0"
name: "symbiosis_plugin_agent_fluxgraph"
description: "Manages secure interactions with third-party plugins and external APIs."

triggers:
  - type: "manual"
  - type: "event_driven"
    config: { event_source: "NATS", topic: "ionflux.agents.symbiosis.invoke_plugin" }

input_schema:
  type: "object"
  properties:
    plugin_id: { type: "string", description: "Identifier for the target plugin/API." }
    action_name: { type: "string", description: "Specific action/endpoint to call within the plugin." }
    plugin_config_cid: { type: "string", nullable: true, description: "Optional CID of an IONPOD object containing specific configurations for this plugin invocation." }
    payload: { type: "object", additionalProperties: true, description: "Data payload to be sent to the plugin/API action." }
  required: [ "plugin_id", "action_name", "payload" ]

output_schema:
  type: "object"
  properties:
    plugin_id: { type: "string" }
    action_name: { type: "string" }
    response_payload: { type: "object", additionalProperties: true, nullable: true, description: "Response data from the plugin/API." }
    status: { type: "string", enum: ["success", "failure", "plugin_specific_error"] }
    error_message: { type: "string", nullable: true }
    external_request_id: { type: "string", nullable: true, description: "ID of the request if provided by the external API." }
  required: ["plugin_id", "action_name", "status"]

graph:
  - id: "fetch_plugin_runtime_config_conditional"
    transform: "FetchFromIONPOD_Transform_IONWALL"
    if: "{{trigger.input_data.plugin_config_cid != null}}"
    ionwall_approval_scope: "read_pod_data:symbiosis_plugin_config"
    inputs:
      cid: "{{trigger.input_data.plugin_config_cid}}"
    outputs: [plugin_runtime_config_obj]

  - id: "route_to_plugin_action"
    transform: "PluginActionRouter_Transform"
    inputs:
      plugin_id: "{{trigger.input_data.plugin_id}}"
      action_name: "{{trigger.input_data.action_name}}"
    outputs: [
        is_shopify_create_product,
        is_google_calendar_list_events
    ]

  - id: "call_shopify_create_product"
    transform: "SecureShopifyAPI_Admin_Transform_IONWALL"
    if: "{{nodes.route_to_plugin_action.outputs.is_shopify_create_product == true}}"
    ionwall_approval_scope: "access_external_api:shopify_admin_create_product"
    inputs:
      shopify_action: "create_product"
      product_data: "{{trigger.input_data.payload}}"
    outputs: [shopify_response_obj, shopify_status_code, shopify_error_msg, shopify_request_id]

  - id: "aggregate_plugin_results"
    transform: "MergePluginResults_Transform"
    inputs:
      shopify_result: { payload: "{{nodes.call_shopify_create_product.outputs.shopify_response_obj}}", status_code: "{{nodes.call_shopify_create_product.outputs.shopify_status_code}}", error: "{{nodes.call_shopify_create_product.outputs.shopify_error_msg}}", req_id: "{{nodes.call_shopify_create_product.outputs.shopify_request_id}}", if_condition: "{{nodes.route_to_plugin_action.outputs.is_shopify_create_product}}"}
    outputs: [final_response_payload, final_status_enum, final_error_message, final_external_request_id]

  - id: "log_plugin_interaction"
    transform: "StoreToIONPOD_Transform_IONWALL"
    ionwall_approval_scope: "write_pod_data:symbiosis_interaction_log"
    inputs:
      data_to_store: {
        timestamp: "{{system.timestamp_utc}}",
        agent_name: "Symbiosis Plugin Agent", version: "0.9.0",
        plugin_id: "{{trigger.input_data.plugin_id}}",
        action_name: "{{trigger.input_data.action_name}}",
        status: "{{nodes.aggregate_plugin_results.outputs.final_status_enum}}",
        external_request_id: "{{nodes.aggregate_plugin_results.outputs.final_external_request_id}}",
        error_if_any: "{{nodes.aggregate_plugin_results.outputs.final_error_message}}"
      }
      filename_suggestion: "symbiosis_log_{{trigger.input_data.plugin_id}}_{{system.timestamp_utc_iso}}.json"
    outputs: [log_entry_cid]

  - id: "publish_completion_event_nats"
    transform: "IPC_NATS_Publish_Transform"
    inputs:
      topic: "ionflux.agents.symbiosis.invoke_plugin.completion"
      message:
        status: "{{nodes.aggregate_plugin_results.outputs.final_status_enum}}"
        plugin_id: "{{trigger.input_data.plugin_id}}"
        action_name: "{{trigger.input_data.action_name}}"
        response_payload: "{{nodes.aggregate_plugin_results.outputs.final_response_payload}}"
        error_message: "{{nodes.aggregate_plugin_results.outputs.final_error_message}}"
        external_request_id: "{{nodes.aggregate_plugin_results.outputs.final_external_request_id}}"
        log_cid: "{{nodes.log_plugin_interaction.outputs.log_entry_cid}}"
        trigger_input_summary: { plugin_id: "{{trigger.input_data.plugin_id}}", action_name: "{{trigger.input_data.action_name}}" }
    dependencies: [log_plugin_interaction]
```

### 3.6. `execution_requirements_json`
```json
{
  "transforms_required": [
    "FetchFromIONPOD_Transform_IONWALL",
    "PluginActionRouter_Transform", // Hypothetical, central to this agent's logic
    // Specific Plugin Transforms are not listed here as they are dynamically invoked.
    // The Symbiosis agent itself needs to be aware of available plugin transforms.
    // Alternatively, this list could represent *all* possible plugin transforms it *could* use if statically defined.
    "SecureShopifyAPI_Admin_Transform_IONWALL", // Example
    "SecureGoogleCalendar_ReadEvents_Transform_IONWALL", // Example
    "MergePluginResults_Transform", // Hypothetical
    "StoreToIONPOD_Transform_IONWALL",
    "IPC_NATS_Publish_Transform"
  ],
  "min_ram_mb": 256,
  "gpu_required": false,
  "estimated_execution_duration_seconds": 15, // Highly variable based on external API
  "max_concurrent_instances": 20, // Can handle many concurrent external calls
  "wasm_modules_cids": {
    "FetchFromIONPOD_Transform_IONWALL": "bafyreibvlobj2rl34gsgxrjltirqesqkfbhtharb3uaxnri3ebpmpah6ce",
    "PluginActionRouter_Transform": "bafyreid6cvjoe77u6otgyusncnbsghftjjykgxsbqvwucommszr2qztfsi", // Placeholder
    "SecureShopifyAPI_Admin_Transform_IONWALL": "bafyreifarvjuxhkkcfc6svyrkxgxfk3qrigbsa2sinqjhk2vjlhytxbdsq", // Placeholder
    "SecureGoogleCalendar_ReadEvents_Transform_IONWALL": "bafyreigik777qjlkxftdtzffgsob6akekttlqbvznq5uwnuhtl2a36j7ci", // Placeholder
    "MergePluginResults_Transform": "bafyreia4k5vjoxz6ivz7nswmufldyvj7auntdoixwzyoauzvlpr7x2pvuu", // Placeholder
    "StoreToIONPOD_Transform_IONWALL": "bafyreif7yqivqtkjhhwb5xkxqj3j7gyjlrvfkhhvjvbfffj4u7m5kfefbi",
    "IPC_NATS_Publish_Transform": "bafyreihyrz7wgld5qrjmejbdjcbcm3jqrjshxphu6jnlxhnlfbk7d745xy"
  }
}
```

### 3.7. `ecosystem_integration_points_json`
```json
{
  "ionwall_permissions_needed": [
    "read_pod_data:symbiosis_plugin_config", // For plugin-specific operational configs
    // Permissions for specific plugin transforms are defined within those transforms and approved by IONWALL at runtime.
    // Example: "access_external_api:shopify_admin_create_product" would be requested by the Shopify transform.
    // Example: "access_external_api:google_calendar_read_events" by the Google Calendar transform.
    "read_secure_credential_from_ionwallet:symbiosis_plugin_any", // Broad scope for Symbiosis to request creds for plugins
    "write_pod_data:symbiosis_interaction_log"
  ],
  "ionpod_data_access": {
    "inputs": [
      { "cid_param": "plugin_config_cid", "access_type": "read", "purpose": "To fetch operational configuration for a specific plugin invocation." }
    ],
    "outputs": [
      { "cid_name": "log_entry_cid", "access_type": "write", "purpose": "To store a log of the plugin interaction." }
      // Actual data from plugins might be passed via NATS or CIDs to other agents, not directly stored by Symbiosis itself unless for caching.
    ]
  },
  "tokenomic_triggers": [
    { "event": "plugin_action_successful_chargeable_api", "action": "debit_user_service_credits", "token_id": "C-ION", "amount_formula": "plugin_specific_cost_factor * 0.01" }, // Cost defined by plugin manifest
    { "event": "new_plugin_transform_registered_by_developer", "action": "reward_developer_ion", "token_id": "$ION", "amount_formula": "fixed_reward_for_approved_plugin_transform" }
  ],
  "techgnosis_integration": {
    "knowledge_graph_queries": [
      "get_plugin_transform_metadata:{{trigger.input_data.plugin_id}}", // To find which transform to use, its capabilities, required scopes.
      "map_ionflux_data_schema_to_plugin_schema:{{trigger.input_data.plugin_id}},{{trigger.input_data.action_name}},{{trigger.input_data.payload.schema_version_if_any}}"
    ],
    "plugin_discovery_and_recommendation": true // TechGnosis helps find relevant plugins for a task.
  },
  "hybrid_layer_escalation_points": [
    { "condition": "plugin_transform_reports_authentication_failure_with_stored_credential", "action": "notify_user_to_update_credential_via_ionwallet_and_hybrid_layer_task" },
    { "condition": "external_api_returns_unexpected_breaking_schema_change", "action": "pause_plugin_use_and_escalate_to_hybrid_layer_developer_community_for_transform_update" },
    { "condition": "plugin_action_payload_or_response_flagged_by_policy_engine", "action": "block_action_and_escalate_for_human_review_content_policy" }
  ],
  "carbon_loop_contribution": {
    "type": "api_call_efficiency_and_batching",
    "value_formula": "number_of_batched_calls_vs_individual * carbon_saved_per_avoided_http_request",
    "description": "Encourages plugin transforms to support batch operations where external APIs allow, reducing an_http_requestsoverall number of HTTP requests. Symbiosis agent could facilitate batching if multiple requests for the same plugin come in a short window."
  }
}
```

### 3.8. `prm_details_json`
```json
{
  "default_timeout_for_external_api_seconds": 30,
  "max_retries_on_transient_api_error": 2,
  "credential_management_service_preference": "IONWALLET_Referral_Protocol", // How it asks IONWALLET for credentials
  "plugin_transform_discovery_method": "TechGnosis_KG_Query", // How it finds available plugin transforms
  "supported_plugin_ids_static_list": [ // Fallback or override if TechGnosis is unavailable
    "shopify_admin_v1", "google_calendar_v3", "zapier_webhook_v1", "stripe_payments_v2"
  ],
  "user_customizable_params": [ // Parameters user can set when invoking Symbiosis
    "plugin_id", "action_name", "plugin_config_cid", "payload"
  ]
}
```

### 3.9. `input_schema_json`
*(The JSON content of `input_schema` from Section 2 is inserted here)*
```json
{
  "type": "object",
  "properties": {
    "plugin_id": { "type": "string", "description": "Identifier for the target plugin/API (e.g., 'shopify_admin', 'google_calendar_read'). Determines which Plugin Transform to use." },
    "action_name": { "type": "string", "description": "Specific action/endpoint to call within the plugin (e.g., 'create_product', 'list_upcoming_events')." },
    "plugin_config_cid": { "type": "string", "nullable": true, "description": "Optional CID of an IONPOD object containing specific configurations for this plugin invocation (e.g., API version, specific flags)." },
    "payload": { "type": "object", "additionalProperties": true, "description": "Data payload to be sent to the plugin/API action." }
  },
  "required": [ "plugin_id", "action_name", "payload" ]
}
```

### 3.10. `output_schema_json`
*(The JSON content of `output_schema` from Section 2 is inserted here)*
```json
{
  "type": "object",
  "properties": {
    "plugin_id": { "type": "string" },
    "action_name": { "type": "string" },
    "response_payload": { "type": "object", "additionalProperties": true, "nullable": true, "description": "Response data from the plugin/API." },
    "status": { "type": "string", "enum": ["success", "failure", "plugin_specific_error"] },
    "error_message": { "type": "string", "nullable": true },
    "external_request_id": { "type": "string", "nullable": true, "description": "ID of the request if provided by the external API." }
  },
  "required": ["plugin_id", "action_name", "status"]
}
```

### 3.11. `trigger_config_json`
```json
{
  "manual_trigger_enabled": true,
  "event_driven_triggers": [
    {
      "event_source": "NATS",
      "topic": "ionflux.agents.symbiosis.invoke_plugin",
      "description": "Triggered by other IONFLUX agents to execute a plugin action. Payload must match input_schema.",
      "input_mapping_jmespath": "payload"
    }
  ],
  "webhook_triggers": [
     {
      "endpoint_path": "/webhooks/invoke/symbiosis_plugin",
      "http_method": "POST",
      "authentication_method": "ionwall_jwt_scoped_for_symbiosis_invocation",
      "description": "HTTP endpoint to trigger a plugin action. Expects JSON body matching input_schema."
    }
  ]
}
```

### 3.12. `deployment_info_json`
```json
{
  "runtime_environment": "IONFLUX_EdgeNode_Wasm",
  "current_instances_managed_by_ionflux_controller": true,
  "default_replicas": 2,
  "auto_scaling_policy": {
    "min_replicas": 1,
    "max_replicas": 10,
    "cpu_threshold_percentage": 60,
    "pending_requests_threshold_per_instance": 5
  }
}
```

### 3.13. `logging_json`
```json
{
  "log_level": "info",
  "log_targets": ["ionpod_event_log_symbiosis", "local_stdout_dev_mode_only"],
  "log_retention_policy_days": 30,
  "sensitive_fields_to_mask_in_log": ["payload.api_key", "response_payload.access_token", "plugin_runtime_config_obj.credentials"]
}
```

### 3.14. `monitoring_json`
```json
{
  "metrics_to_collect": [
    "plugin_invocation_count_by_id_action", "plugin_invocation_success_rate_by_id_action", "plugin_invocation_failure_rate_by_id_action",
    "external_api_latency_ms_avg_by_id_action", "credential_fetch_failure_rate_ionwallet"
  ],
  "metrics_endpoint_ionwall_protected": "/metrics/symbiosis_plugin_agent",
  "health_check_protocol": "check_availability_of_core_services_like_ionwallet_techgnosis_plugin_discovery",
  "alerting_rules": [
    {"metric": "plugin_invocation_failure_rate_shopify_admin_v1", "condition": "value > 0.2 for 15m", "severity": "warning", "notification_channel": "hybrid_layer_ops_team_chat_shopify_channel"},
    {"metric": "credential_fetch_failure_rate_ionwallet", "condition": "value > 0.05 for 5m", "severity": "critical", "notification_channel": "hybrid_layer_ops_pager_security"}
  ]
}
```

### 3.15. `security_json`
```json
{
  "data_encryption_at_rest_ionpod": true,
  "data_encryption_in_transit_ipfs_ionwall": true,
  "credential_handling_protocol_version": "IONWALLET_SecureFetch_v1.1", // Protocol for transform to ask IONWALLET
  "plugin_transform_sandboxing_enabled": true, // Wasm transforms are sandboxed by default
  "network_egress_policy_reference_cid": "bafkreih... (CID of policy defining allowed external endpoints for plugins)",
  "required_ionwall_consent_scopes_generic": [ // Generic scopes for Symbiosis agent itself
    "read_pod_data:symbiosis_plugin_config",
    "read_secure_credential_from_ionwallet:symbiosis_plugin_any", // To request creds on behalf of a plugin transform
    "write_pod_data:symbiosis_interaction_log"
  ],
  // Specific scopes like "access_external_api:shopify_admin_create_product" are requested by the *Plugin Transforms* themselves.
  "gdpr_compliance_features_enabled_via_ionwall_and_plugin_design": true,
  "data_flow_policy_engine_cid_for_payloads": "bafkreig... (CID of policy for validating data sent/received by plugins)",
  "sensitive_data_handling_policy_id": "SDP-SYMBIOSIS-001"
}
```

---
## 4. User Experience Flow (Conceptual)

1.  **Initiation:** An `IONFLUX Agent` (e.g., `RetailBot Agent`) needs to update product inventory on Shopify. It triggers `Symbiosis Plugin Agent` via NATS: ` { plugin_id: "shopify_admin_v1", action_name: "update_inventory", payload: { product_id: "12345", new_stock_level: 50 } } `.
2.  **IONWALL Checkpoint (External API Access & Credential Use):**
    *   IONWALL (acting for `Symbiosis Plugin Agent` which invokes the `SecureShopifyAPI_Admin_Transform_IONWALL`) prompts User: *"RetailBot Agent, via Symbiosis Plugin Agent, wants to:
        *   Access Shopify Admin API to 'Update Inventory' for product '{{payload.product_id}}'.
        *   Use your stored Shopify API credentials managed by IONWALLET.
        Allow?"*
    *   (If `plugin_config_cid` was provided and requires read access, that's included too).
3.  **Execution:**
    *   `Symbiosis Plugin Agent` routes to `SecureShopifyAPI_Admin_Transform_IONWALL`.
    *   The Shopify transform requests the necessary Shopify API key from IONWALLET (which may have its own user prompt if interactive use is needed for the credential).
    *   The Shopify transform constructs the API request with the payload and sends it to Shopify.
    *   The response from Shopify is received by the transform.
4.  **Response Handling & Logging:**
    *   The Shopify transform passes the response (success/failure, data) back to `Symbiosis Plugin Agent`.
    *   `Symbiosis Plugin Agent` logs the interaction details (plugin, action, status, request ID, but not sensitive payload data) to the user's IONPOD (with IONWALL approval for write).
    *   `Symbiosis Plugin Agent` publishes a NATS completion event with the outcome and any non-sensitive response data, which `RetailBot Agent` is listening for.
5.  **Completion:** `RetailBot Agent` receives the completion event and proceeds accordingly.

---
## 5. TechGnosis & Hybrid Layer Integration Notes

*   **TechGnosis:**
    *   **Plugin Discovery:** TechGnosis maintains a knowledge graph of available `Plugin Transforms`, their capabilities (`action_name`s), required IONWALL scopes, expected data schemas, and current versions. `Symbiosis Plugin Agent` queries this to find the correct transform for a given `plugin_id`.
    *   **Data Mapping:** For complex plugins, TechGnosis can assist in mapping data from IONFLUX's internal schemas to the specific schema required by the external API, and vice-versa for responses. This could be a transform itself or a service used by plugin transforms.
    *   **Semantic Invocation:** Instead of `plugin_id` and `action_name`, an agent could request a semantic goal like "post message to social media about X", and TechGnosis + Symbiosis could determine the available social media plugins and how to invoke them.
*   **Hybrid Layer:**
    *   **Credential Failures:** If a Plugin Transform reports persistent authentication failure with a stored credential, `Symbiosis Plugin Agent` escalates to the Hybrid Layer. A task is created for the user to update their credentials in IONWALLET.
    *   **API Errors/Schema Changes:** If an external API returns unexpected errors or its response schema seems to have changed (breaking the Plugin Transform), this can be escalated. The Hybrid Layer might notify the developer community or maintainers of the specific Plugin Transform.
    *   **Policy Violations:** If data being sent to or received from a plugin violates a user-defined or system-wide policy (checked by an integrated Policy Engine transform), the action is blocked, and details are escalated to the Hybrid Layer for review.

---
## 6. Carbon Loop Integration Notes

*   **API Call Efficiency:** `Symbiosis Plugin Agent` and the underlying Plugin Transforms can be designed to encourage or enforce efficient API usage. For example:
    *   Supporting batch operations if the external API allows (e.g., updating 100 Shopify products in one call instead of 100 individual calls).
    *   Using webhooks from external services (if available and configured via a listener Symbiosis agent) instead of polling for changes, reducing unnecessary API calls.
*   **Caching:** For frequently accessed, non-sensitive data from external APIs that doesn't change often, Symbiosis could (with user consent and clear cache policies) cache responses in IONPOD for a short period to reduce redundant external calls.
*   The `carbon_loop_contribution` field in `ecosystem_integration_points_json` reflects these strategies.

---
## 7. Dependencies & Interactions

*   **Required Transforms (Core Symbiosis Logic):**
    *   `FetchFromIONPOD_Transform_IONWALL` (for plugin configs)
    *   `PluginActionRouter_Transform` (or equivalent dynamic routing logic)
    *   `MergePluginResults_Transform` (or equivalent)
    *   `StoreToIONPOD_Transform_IONWALL` (for logging)
    *   `IPC_NATS_Publish_Transform` (for completion events)
*   **Required Transforms (Dynamically Invoked by Symbiosis - "Plugin Transforms"):** This is an extensible list of specialized transforms, each dedicated to a specific external API/service and action. Examples:
    *   `SecureShopifyAPI_Admin_Transform_IONWALL`
    *   `SecureGoogleCalendar_ReadEvents_Transform_IONWALL`
    *   `SecureStripe_CreatePayment_Transform_IONWALL`
    *   `Zapier_Webhook_Send_Transform_IONWALL`
    *   `GitHub_RepoRead_Transform_IONWALL`
    These transforms are responsible for secure credential handling (via IONWALLET interaction), API call construction, and response parsing.
*   **Interacting Agents (Conceptual):**
    *   Any agent that needs to interact with an external service not directly supported by a basic transform would call `Symbiosis Plugin Agent`. (e.g., `RetailBot Agent` for Shopify, `ProductivityPal Agent` for Google Calendar, `DevOpsMaster Agent` for GitHub).
    *   `IONWALLET Agent` (conceptual): For securely providing credentials to the Plugin Transforms.
*   **External Systems (via Plugin Transforms):**
    *   Shopify, Google Workspace, Stripe, Zapier, GitHub, Slack, Notion, custom enterprise APIs, etc.

---
## 8. Open Questions & Future Considerations

*   **Plugin Transform Standard:** Define a clear specification for creating new Plugin Transforms (input/output schemas, credential handling protocol with IONWALLET, error reporting, IONWALL scope declaration).
*   **Dynamic Loading of Plugin Transforms:** How does `Symbiosis Plugin Agent` become aware of new Plugin Transforms as they are developed and registered in TechGnosis? Does it dynamically load their Wasm modules, or does the agent's own definition need to be updated to reference them?
*   **OAuth Flow Management:** For services using OAuth2/3, how does `Symbiosis Plugin Agent` (or the specific Plugin Transform) manage the OAuth dance? This likely involves tight integration with IONWALLET and possibly a user-facing UI component spawned by IONWALL for the authorization redirect.
*   **Credential Scope Management:** Granular control over which Plugin Transform can access which specific credential stored in IONWALLET (e.g., only `SecureShopifyAPI_Admin_Transform_IONWALL` can request the "my_store_shopify_key").
*   **User Interface for Plugin Management:** A UI where users can see which plugins `Symbiosis Plugin Agent` can interact with, manage their credentials for these plugins (via IONWALLET), and view logs of plugin activity.
*   **Rate Limiting & Throttling:** Implementing robust handling of external API rate limits, potentially with shared rate limit counters for plugins accessing the same service.
*   **Webhooks from External Services:** While this blueprint focuses on *calling* external APIs, a complementary Symbiosis "Listener" agent pattern would be needed to securely receive webhooks *from* external services and route them into the IONFLUX ecosystem.
