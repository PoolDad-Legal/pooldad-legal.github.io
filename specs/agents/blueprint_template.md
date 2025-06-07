# Agent Blueprint: [Agent Name] - v[Version]

## 1. Overview

*   **Agent Name:** `[Full Agent Name, e.g., Muse Prompt Chain Agent]`
*   **Version:** `[e.g., 0.9.0]`
*   **Status:** `[e.g., development, active, deprecated]`
*   **Primary Goal:** `[Concise statement of what the agent primarily does]`
*   **Key Features:**
    *   `[Feature 1]`
    *   `[Feature 2]`
    *   `[...more features]`

## 2. FluxGraph Definition (Conceptual YAML)

```yaml
# /specs/agents/[agent_filename_slug]_fluxgraph.yaml (Conceptual representation)
version: "0.1.0" # FluxGraph spec version
name: "[agent_name_slug]_fluxgraph"
description: "[Agent's detailed description for the FluxGraph]"

triggers:
  - type: "manual" # Always good to have for testing
  # - type: "event_driven"
  #   config: { event_source: "NATS", topic: "ionflux.events.something" }
  # - type: "scheduled"
  #   config: { cron_expression: "0 * * * *" } # Hourly
  # - type: "webhook"
  #   config: { path: "/webhooks/[agent_name_slug]", method: "POST" }

input_schema: # JSON schema for expected input when triggered
  type: "object"
  properties:
    # input_param1: { type: "string", description: "Description of param1" }
    # data_cid: { type: "string", description: "IPFS CID for input data from IONPOD" }
  required: [] # [ "input_param1" ]

output_schema: # JSON schema for the agent's final output
  type: "object"
  properties:
    # result_param1: { type: "string", description: "Description of result1" }
    # output_cid: { type: "string", description: "IPFS CID for output data to IONPOD" }
    status: { type: "string", enum: ["success", "failure", "partial_success"] }
    error_message: { type: "string", nullable: true }
  required: ["status"]

graph: # DAG of transforms
  - id: "initial_data_fetch" # Unique ID for this node in the graph
    transform: "FetchFromIONPOD_Transform_IONWALL" # Name/ID of the transform to use
    ionwall_approval_scope: "read_user_data_for_[agent_purpose]" # IONWALL scope for this action
    inputs: # Mapping inputs for the transform
      # cid: "{{trigger.input_data.data_cid}}" # Example: from trigger input
    outputs: [fetched_data_ref] # Names for outputs from this transform node

  # - id: "process_data_step_1"
  #   transform: "[Specific_Transform_Name]"
  #   ionwall_approval_scope: "[scope_for_this_transform_action]"
  #   inputs:
  #     input_a: "{{nodes.initial_data_fetch.outputs.fetched_data_ref}}" # Example: from previous node
  #     config_param_b: "{{agent.config.some_setting}}" # Example: from agent's own config
  #   outputs: [processed_data_ref]

  # - id: "final_storage_step"
  #   transform: "StoreToIONPOD_Transform_IONWALL"
  #   ionwall_approval_scope: "write_user_data_for_[agent_purpose]"
  #   inputs:
  #     data_to_store: "{{nodes.process_data_step_1.outputs.processed_data_ref}}"
  #     metadata: { agent_name: "[Agent Name]", version: "[Version]" }
  #   outputs: [stored_data_cid_ref]

  # - id: "publish_completion_event"
  #   transform: "IPC_NATS_Publish_Transform" # Inter-Process Communication via NATS
  #   inputs:
  #     topic: "ionflux.agents.[agent_name_slug].completion"
  #     message:
  #       status: "success"
  #       output_cid: "{{nodes.final_storage_step.outputs.stored_data_cid_ref}}"
  #       # ... other relevant info from the graph execution
  #   dependencies: [final_storage_step] # Ensure this runs after final_storage_step
```

---
## 3. Database Schema Fields (`agent_definitions` table)
*(Conceptual values for the JSONB fields and other relevant columns)*

### 3.1. `agent_name`
`"[Full Agent Name]"`

### 3.2. `version`
`"[Version, e.g., 0.9.0]"`

### 3.3. `description`
`"[Overall agent description, similar to FluxGraph description but can be more general.]"`

### 3.4. `status`
`"[e.g., development]"` (matches `agent_status` enum)

### 3.5. `flux_graph_dsl_yaml`
*(This is the YAML content from Section 2, stored as a string in the DB)*

### 3.6. `execution_requirements_json`
```json
{
  "transforms_required": [
    "FetchFromIONPOD_Transform_IONWALL",
    // "[Specific_Transform_Name]",
    "StoreToIONPOD_Transform_IONWALL",
    "IPC_NATS_Publish_Transform"
    // ... other required transform IDs
  ],
  "min_ram_mb": 0, // e.g., 256, 512, 1024
  "gpu_required": false, // true if GPU is needed
  "gpu_type_preference": null, // e.g., "NVIDIA_TESLA_T4_OR_EQUIVALENT"
  "estimated_execution_duration_seconds": 0, // Rough estimate for typical run
  "max_concurrent_instances": 0, // e.g., 1, 5, 10
  "wasm_modules_cids": { // IPFS CIDs for the WasmEdge modules of required transforms
    // "FetchFromIONPOD_Transform_IONWALL": "bafyrei...",
    // "[Specific_Transform_Name]": "bafyrei...",
    // "StoreToIONPOD_Transform_IONWALL": "bafyrei...",
    // "IPC_NATS_Publish_Transform": "bafyrei..."
  }
}
```

### 3.7. `ecosystem_integration_points_json`
```json
{
  "ionwall_permissions_needed": [ // Granular permissions requested from IONWALL
    // "read_pod_data:[specific_scope_or_cid_pattern]",
    // "write_pod_data:[specific_scope_or_cid_pattern]",
    // "execute_transform:[Specific_Transform_Name]",
    // "invoke_llm_model:[model_id_pattern]",
    // "access_external_api:[api_identifier]"
  ],
  "ionpod_data_access": { // Explicit declaration of IONPOD data interactions
    "inputs": [
      // { "cid_param": "[param_name_in_fluxgraph_input]", "access_type": "read", "purpose": "Brief description" }
    ],
    "outputs": [
      // { "cid_name": "[output_name_in_fluxgraph_output]", "access_type": "write", "purpose": "Brief description" }
    ]
  },
  "tokenomic_triggers": [ // How this agent interacts with $ION, C-ION, NFTs
    // { "event": "fluxgraph_successful_completion", "action": "reward_user", "token_id": "$ION", "amount_formula": "..." },
    // { "event": "transform_[TransformName]_invocation", "action": "debit_user_compute_credits", "token_id": "C-ION", "amount_formula": "..." }
  ],
  "techgnosis_integration": { // Interactions with the TechGnosis Layer
    // "knowledge_graph_queries": ["query_template_using_input_data:{{trigger.input_data.some_param}}"],
    // "symbolic_meaning_enhancement": false // or true
  },
  "hybrid_layer_escalation_points": [ // Conditions for involving human oversight
    // { "condition": "low_confidence_score_from_transform_[TransformName]", "action": "human_review_flag" },
    // { "condition": "explicit_user_request_for_review", "action": "human_review_escalation" }
  ],
  "carbon_loop_contribution": { // How this agent contributes to carbon positivity
    // "type": "compute_offset | data_efficiency_gain | direct_sequestration_action",
    // "value_formula": "calculation_based_on_execution_metrics"
  }
}
```

### 3.8. `prm_details_json`
*(Agent-specific parameters, configurations, default settings)*
```json
{
  // "default_param_1": "value1",
  // "configurable_setting_a": true,
  // "user_customizable_params": ["default_param_1"] // List of params user can override at runtime (within limits)
}
```

### 3.9. `input_schema_json`
*(This is the JSON content of `input_schema` from Section 2, stored as JSONB)*

### 3.10. `output_schema_json`
*(This is the JSON content of `output_schema` from Section 2, stored as JSONB)*

### 3.11. `trigger_config_json`
*(Detailed configuration for each trigger type defined in Section 2)*
```json
{
  "manual_trigger_enabled": true,
  // "event_driven_triggers": [
  //   { "event_source": "NATS", "topic": "ionflux.events.something", "description": "...", "filter_expression": "..." }
  // ],
  // "scheduled_triggers": [
  //   { "cron_expression": "0 * * * *", "timezone": "UTC", "description": "..." }
  // ],
  // "webhook_triggers": [
  //   { "endpoint_path": "/webhooks/[agent_name_slug]", "http_method": "POST", "authentication_method": "ionwall_jwt", "description": "..." }
  // ]
}
```

### 3.12. `deployment_info_json`
```json
{
  "runtime_environment": "IONFLUX_EdgeNode_Wasm", // or "IONFLUX_Cloud_Worker" etc.
  "current_instances_managed_by_ionflux_controller": true,
  "default_replicas": 1,
  "auto_scaling_policy": {
    // "min_replicas": 1,
    // "max_replicas": 5,
    // "cpu_threshold_percentage": 70,
    // "queue_length_threshold": 100 // For event-driven agents
  }
}
```

### 3.13. `logging_json`
```json
{
  "log_level": "info", // "debug", "warn", "error"
  "log_targets": ["ionpod_event_log"], // "local_stdout_dev_mode_only", "remote_syslog"
  "log_retention_policy_days": 30
}
```

### 3.14. `monitoring_json`
```json
{
  "metrics_to_collect": [ // Standard set + agent-specific
    "execution_time", "success_rate", "failure_rate", "resource_utilization_cpu_mem"
    // ... agent-specific metrics derived from its operations
  ],
  "metrics_endpoint_ionwall_protected": "/metrics/[agent_name_slug]",
  "health_check_protocol": "internal_ping" // or "http_get_to_status_endpoint"
}
```

### 3.15. `security_json`
```json
{
  "data_encryption_at_rest_ionpod": true,
  "data_encryption_in_transit_ipfs_ionwall": true,
  "required_ionwall_consent_scopes": [ // Duplicates/confirms ionwall_permissions_needed for clarity at security level
    // ...
  ],
  "gdpr_compliance_features_enabled": true,
  "data_anonymization_options": [], // e.g., "pseudonymization_on_export", "differential_privacy_filters"
  "sensitive_data_handling_policy_id": null // Link to a policy document if applicable
}
```

---
## 4. User Experience Flow (Conceptual)
*(How a user interacts with this agent, including IONWALL checkpoints)*

1.  **Initiation:** `[User action, e.g., clicks "Transcribe Audio" button in UI, or an event occurs in IONPOD]`
2.  **IONWALL Checkpoint 1 (Data Access):** `[If input data from IONPOD is needed, IONWALL prompts user for consent: "Agent X wants to read file Y. Allow?"]`
3.  **Configuration (Optional):** `[User sets parameters, e.g., chooses language for transcription, selects LLM model for summary]`
4.  **IONWALL Checkpoint 2 (Execution Approval):** `[IONWALL prompts: "Agent X wants to perform action Y (e.g., transcribe, generate text). This may incur C-ION costs. Allow?"]`
5.  **Execution:** `[Agent FluxGraph runs. Progress might be shown in UI.]`
6.  **IONWALL Checkpoint 3 (Output Storage):** `[If storing results to IONPOD, IONWALL prompts: "Agent X wants to save file Z to your IONPOD. Allow?"]`
7.  **Completion/Notification:** `[User is notified of completion. Results available in IONPOD/UI.]`

---
## 5. TechGnosis & Hybrid Layer Integration Notes

*   **TechGnosis:** `[How does this agent leverage or contribute to the TechGnosis layer? E.g., queries knowledge graph for contextual enrichment, tags outputs with symbolic metadata, uses archetypal patterns in its logic.]`
*   **Hybrid Layer:** `[Under what conditions does this agent escalate to the Hybrid Layer for human review or intervention? E.g., low confidence scores, ambiguous inputs, ethical dilemmas detected, user explicit request.]`

---
## 6. Carbon Loop Integration Notes

*   `[How does this agent's operation factor into the Carbon Loop? E.g., Is its compute offset? Does it enable data efficiencies that reduce overall storage/compute? Does it directly trigger any carbon sequestration actions via other specialized agents/transforms?]`

---
## 7. Dependencies & Interactions

*   **Required Transforms:** `[List of specific Transform IDs from execution_requirements_json]`
*   **Interacting Agents (Conceptual):** `[Other agents this agent might trigger or be triggered by, e.g., "May be triggered by Datascribe Transcript Agent to summarize text."]`
*   **External Systems (via Transforms):** `[e.g., Specific LLM APIs, Shopify Admin API if Symbiosis Plugin Agent is used as a transform]`

---
## 8. Open Questions & Future Considerations

*   `[Any unresolved design questions]`
*   `[Potential future enhancements or versions]`
