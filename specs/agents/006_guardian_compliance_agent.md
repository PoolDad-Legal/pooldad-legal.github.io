# Agent Blueprint: Guardian Compliance Agent - v0.9.0

## 1. Overview

*   **Agent Name:** `Guardian Compliance Agent`
*   **Version:** `0.9.0`
*   **Status:** `development`
*   **Primary Goal:** `Monitors actions and data flows within a user's IONFLUX space (and potentially federated spaces) against defined user policies, IONWALL settings, and external regulatory templates. It can flag, alert, log, and (if configured and approved under strict Hybrid Layer oversight) take preventative actions like blocking non-compliant operations.`
*   **Key Features:**
    *   **Policy-Driven Monitoring:** Evaluates system events against user-defined policies (e.g., data handling rules, agent interaction constraints, resource usage limits) stored as structured objects (e.g., JSON, YAML) in IONPOD.
    *   **Real-time Event Listening:** Subscribes to various IONFLUX event streams via NATS (e.g., `ionflux.events.agent_action_taken`, `ionflux.events.data_access_requested`, `ionflux.events.ionwall_consent_granted_or_denied`).
    *   **Rule Engine:** Utilizes a dedicated "PolicyEngine_Transform" to evaluate events against applicable policies. This transform might support various rule languages or structures (e.g., Rego/OPA, JSONLogic, custom DSL).
    *   **Alerting & Notification:** Can trigger alerts via `Comm Link Agent` (email, Matrix, etc.) or direct UI notifications when policy violations or significant compliance events are detected.
    *   **Compliance Logging:** Maintains detailed audit logs of monitored events, policy evaluations, and any actions taken, stored securely in IONPOD.
    *   **Preventative Actions (Optional & Restricted):** Can be configured to request blocking of certain actions if a severe policy violation is detected. Such preventative capabilities require explicit user consent for the Guardian agent itself and are typically subject to Hybrid Layer oversight or pre-approval for specific critical policies.
    *   **Policy Management Interface:** Facilitates (potentially via another agent or UI) the creation, update, and management of compliance policies.

## 2. FluxGraph Definition (Conceptual YAML)

```yaml
# /specs/agents/guardian_compliance_agent_fluxgraph.yaml (Conceptual representation)
# This agent would likely have a primary FluxGraph for event evaluation and potentially others for policy management assistance.

version: "0.1.0"
name: "guardian_evaluate_event_for_compliance_fluxgraph"
description: "Listens to IONFLUX events, evaluates them against defined policies, and takes appropriate compliance actions (log, alert, potentially block)."

triggers:
  # This FluxGraph is designed to be triggered by various NATS events from the IONFLUX ecosystem.
  # It would subscribe to multiple topics or a wildcard topic.
  - type: "event_driven_multi_topic_listener" # Conceptual trigger type
    config:
      nats_topics: [
        "ionflux.events.agent_action_taken", # Payload: { agent_id, action_name, params, status, timestamp, user_id }
        "ionflux.events.data_access_requested", # Payload: { requesting_agent_id, data_cid, access_type, user_id }
        "ionflux.events.data_access_granted", # Payload: { data_cid, granted_to_agent_id, timestamp }
        "ionflux.events.ionwall_consent_changed", # Payload: { user_id, scope, status ('granted'/'denied'/'revoked') }
        "ionflux.events.agent_registered_or_updated" # Payload: { agent_id, version, status, description }
        # Potentially more topics for comprehensive monitoring
      ]
      # The listener transform would need to normalize these diverse event payloads or pass them as-is with topic info.

input_schema: # Expected input from the NATS listener (normalized or direct event payload)
  type: "object"
  properties:
    event_topic: { type: "string", description: "The NATS topic the event came from." }
    event_payload: { type: "object", additionalProperties: true, description: "The actual payload of the NATS event." }
    event_timestamp_utc: { type: "string", format: "date-time" }
  required: [ "event_topic", "event_payload", "event_timestamp_utc" ]

output_schema: # Output of this evaluation, primarily for internal logging or if another agent called Guardian directly.
  type: "object"
  properties:
    event_topic: { type: "string" }
    event_payload_summary: { type: "object", description: "Summary of the processed event." }
    evaluation_result: {
      type: "object",
      properties: {
        status: { type: "string", enum: ["compliant", "non_compliant_alert", "non_compliant_blocked", "error_in_evaluation"] },
        violated_policy_ids: { type: "array", items: { type: "string" }, nullable: true },
        alert_triggered_id: { type: "string", nullable: true },
        action_blocked_ref: { type: "string", nullable: true },
        error_message: { type: "string", nullable: true }
      }
    }
  required: [ "event_topic", "evaluation_result" ]

graph:
  - id: "fetch_relevant_compliance_policies"
    transform: "FetchFromIONPOD_MultiQuery_Transform_IONWALL" # Hypothetical: Fetches multiple policy CIDs based on event context
    ionwall_approval_scope: "read_pod_data:guardian_compliance_policies"
    inputs:
      # Logic to determine which policies are relevant based on event_topic and event_payload (e.g., user_id, agent_id involved, data_type)
      # This might involve querying a policy index stored in IONPOD or using TechGnosis.
      # For simplicity, let's assume it fetches all policies for the user or a predefined set.
      policy_index_cid: "{{agent.prm.default_policy_index_cid}}" # Agent has a PRM pointing to an index of policies
      event_context: "{{trigger.input_data}}" # Pass full event for context-aware policy fetching
    outputs: [policy_objects_array] # Array of policy objects (e.g., JSON or Rego strings)

  - id: "evaluate_event_with_policy_engine"
    transform: "PolicyEngine_Transform_OPA" # Example: Open Policy Agent based transform
    # This transform would need to be initialized with a set of policies (rego code) and then evaluate input data against them.
    # It might require a specific Wasm build of OPA.
    ionwall_approval_scope: "execute_compliance_policy_engine:guardian_agent"
    inputs:
      policies_data: "{{nodes.fetch_relevant_compliance_policies.outputs.policy_objects_array}}"
      input_data_to_evaluate: "{{trigger.input_data.event_payload}}" # The event itself is the input for policy evaluation
      # query_for_policy_engine: "data.main.allow" or "data.main.violations" depending on policy structure
      # context_attributes: { "event_topic": "{{trigger.input_data.event_topic}}", "timestamp": "{{trigger.input_data.event_timestamp_utc}}" }
    outputs: [evaluation_decision_obj] # e.g., { allowed: true/false, violations: [{policy_id: "P001", message: "..."}], matched_policies: ["P001", "P005"] }

  - id: "determine_compliance_action_router"
    transform: "SwitchCaseRouter_Transform" # Based on evaluation_decision_obj
    inputs:
      # Logic to map evaluation_decision_obj to "compliant", "alert_only", "attempt_block"
      # Example: if evaluation_decision_obj.allowed == false && any_violation_has_severity_critical: "attempt_block"
      # else if evaluation_decision_obj.allowed == false: "alert_only"
      # else: "compliant"
      decision_input: "{{nodes.evaluate_event_with_policy_engine.outputs.evaluation_decision_obj}}"
    outputs: [is_compliant, needs_alert, needs_block_attempt]

  # Path for Non-Compliant: Alert
  - id: "trigger_compliance_alert"
    transform: "CommLinkAgent_Invoke_Transform" # Conceptual transform to call Comm Link Agent
    if: "{{nodes.determine_compliance_action_router.outputs.needs_alert == true || nodes.determine_compliance_action_router.outputs.needs_block_attempt == true}}"
    ionwall_approval_scope: "invoke_agent:comm_link_for_guardian_alerts" # Guardian needs permission to use CommLink
    inputs:
      # Parameters for Comm Link Agent to send an alert (e.g., to user via email/Matrix, or to an admin NATS topic)
      channel: "{{agent.prm.default_alert_channel || 'email'}}"
      recipient_identifier_cid: "{{agent.prm.default_alert_recipient_cid || trigger.input_data.event_payload.user_profile_cid}}" # Alert user involved or default admin
      template_cid: "{{agent.prm.compliance_alert_template_cid}}"
      template_params: {
        event_summary: "{{trigger.input_data.event_topic}} - {{trigger.input_data.event_payload.summary_if_any}}",
        violations: "{{nodes.evaluate_event_with_policy_engine.outputs.evaluation_decision_obj.violations}}",
        timestamp: "{{trigger.input_data.event_timestamp_utc}}"
      }
    outputs: [alert_comm_link_response] # Status from Comm Link Agent

  # Path for Non-Compliant: Attempt Block (Highly sensitive, requires pre-approval and Hybrid Layer integration)
  - id: "attempt_preventative_action_block"
    transform: "IONWALL_AdminAction_Request_Transform" # Hypothetical, high-privilege transform
    if: "{{nodes.determine_compliance_action_router.outputs.needs_block_attempt == true && agent.prm.enable_preventative_blocking == true}}"
    ionwall_approval_scope: "execute_ionwall_admin_action:guardian_preventative_block" # Requires specific, powerful consent
    inputs:
      action_type: "block_agent_action" # or "revoke_data_access", "quarantine_agent"
      target_details: { # Details about what to block, derived from event_payload
        # e.g., original_agent_id, original_action_id, data_cid
        offending_event_details: "{{trigger.input_data.event_payload}}"
      }
      justification: "Automated block due to critical policy violation(s): {{nodes.evaluate_event_with_policy_engine.outputs.evaluation_decision_obj.violations}}"
    outputs: [block_action_status, block_action_ref_id]
    # This transform would interact with IONWALL/Controller at an admin level. Success is not guaranteed.

  - id: "log_compliance_evaluation"
    transform: "StoreToIONPOD_Transform_IONWALL"
    ionwall_approval_scope: "write_pod_data:guardian_compliance_logs"
    inputs:
      data_to_store: {
        event_topic: "{{trigger.input_data.event_topic}}",
        event_payload_summary: "{{trigger.input_data.event_payload}}", # Potentially summarize/redact sensitive parts of payload
        event_timestamp_utc: "{{trigger.input_data.event_timestamp_utc}}",
        policies_evaluated_cids: "{{nodes.fetch_relevant_compliance_policies.outputs.policy_objects_array.map(p => p.cid)}}", # Assuming policies have CIDs
        evaluation_decision: "{{nodes.evaluate_event_with_policy_engine.outputs.evaluation_decision_obj}}",
        action_taken: {
          alert_sent: "{{nodes.determine_compliance_action_router.outputs.needs_alert || nodes.determine_compliance_action_router.outputs.needs_block_attempt}}",
          alert_details: "{{nodes.trigger_compliance_alert.outputs.alert_comm_link_response}}",
          block_attempted: "{{nodes.determine_compliance_action_router.outputs.needs_block_attempt && agent.prm.enable_preventative_blocking}}",
          block_status: "{{nodes.attempt_preventative_action_block.outputs.block_action_status}}",
          block_ref_id: "{{nodes.attempt_preventative_action_block.outputs.block_action_ref_id}}"
        }
      }
      filename_suggestion: "compliance_log_{{trigger.input_data.event_topic}}_{{system.timestamp_utc_iso}}.json"
    outputs: [compliance_log_cid]

  # Final output preparation (simplified)
  - id: "prepare_final_output"
    transform: "NoOp_PassThrough_Transform" # Placeholder to structure the output
    inputs:
        event_topic: "{{trigger.input_data.event_topic}}",
        event_payload_summary: "{{trigger.input_data.event_payload}}", # Summarize
        evaluation_result: {
            status: "{{'compliant' if nodes.determine_compliance_action_router.outputs.is_compliant else ('non_compliant_blocked' if nodes.attempt_preventative_action_block.outputs.block_action_status == 'success' else 'non_compliant_alert')}}",
            violated_policy_ids: "{{nodes.evaluate_event_with_policy_engine.outputs.evaluation_decision_obj.violations.map(v => v.policy_id)}}",
            alert_triggered_id: "{{nodes.trigger_compliance_alert.outputs.alert_comm_link_response.message_id}}",
            action_blocked_ref: "{{nodes.attempt_preventative_action_block.outputs.block_action_ref_id}}",
            error_message: "{{null}}" # Populate if errors in Guardian itself
        }
    outputs: [final_output_obj_for_this_fluxgraph]

```

---
## 3. Database Schema Fields (`agent_definitions` table)

### 3.1. `agent_name`
`"Guardian Compliance Agent"`

### 3.2. `version`
`"0.9.0"`

### 3.3. `description`
`"Monitors actions and data flow within a user's IONFLUX space against defined user policies, IONWALL settings, and potentially external regulatory templates. It can flag, alert, or (if configured and approved) block non-compliant actions."`

### 3.4. `status`
`"development"`

### 3.5. `flux_graph_dsl_yaml`
*(The YAML content for `guardian_evaluate_event_for_compliance_fluxgraph` from Section 2 is inserted here)*
```yaml
version: "0.1.0"
name: "guardian_evaluate_event_for_compliance_fluxgraph"
description: "Listens to IONFLUX events, evaluates them against defined policies, and takes appropriate compliance actions (log, alert, potentially block)."

triggers:
  - type: "event_driven_multi_topic_listener"
    config:
      nats_topics: [
        "ionflux.events.agent_action_taken",
        "ionflux.events.data_access_requested",
        "ionflux.events.data_access_granted",
        "ionflux.events.ionwall_consent_changed",
        "ionflux.events.agent_registered_or_updated"
      ]

input_schema:
  type: "object"
  properties:
    event_topic: { type: "string", description: "The NATS topic the event came from." }
    event_payload: { type: "object", additionalProperties: true, description: "The actual payload of the NATS event." }
    event_timestamp_utc: { type: "string", format: "date-time" }
  required: [ "event_topic", "event_payload", "event_timestamp_utc" ]

output_schema:
  type: "object"
  properties:
    event_topic: { type: "string" }
    event_payload_summary: { type: "object", description: "Summary of the processed event." }
    evaluation_result: {
      type: "object",
      properties: {
        status: { type: "string", enum: ["compliant", "non_compliant_alert", "non_compliant_blocked", "error_in_evaluation"] },
        violated_policy_ids: { type: "array", items: { type: "string" }, nullable: true },
        alert_triggered_id: { type: "string", nullable: true },
        action_blocked_ref: { type: "string", nullable: true },
        error_message: { type: "string", nullable: true }
      }
    }
  required: [ "event_topic", "evaluation_result" ]

graph:
  - id: "fetch_relevant_compliance_policies"
    transform: "FetchFromIONPOD_MultiQuery_Transform_IONWALL"
    ionwall_approval_scope: "read_pod_data:guardian_compliance_policies"
    inputs:
      policy_index_cid: "{{agent.prm.default_policy_index_cid}}"
      event_context: "{{trigger.input_data}}"
    outputs: [policy_objects_array]

  - id: "evaluate_event_with_policy_engine"
    transform: "PolicyEngine_Transform_OPA"
    ionwall_approval_scope: "execute_compliance_policy_engine:guardian_agent"
    inputs:
      policies_data: "{{nodes.fetch_relevant_compliance_policies.outputs.policy_objects_array}}"
      input_data_to_evaluate: "{{trigger.input_data.event_payload}}"
    outputs: [evaluation_decision_obj]

  - id: "determine_compliance_action_router"
    transform: "SwitchCaseRouter_Transform"
    inputs:
      decision_input: "{{nodes.evaluate_event_with_policy_engine.outputs.evaluation_decision_obj}}"
    outputs: [is_compliant, needs_alert, needs_block_attempt]

  - id: "trigger_compliance_alert"
    transform: "CommLinkAgent_Invoke_Transform"
    if: "{{nodes.determine_compliance_action_router.outputs.needs_alert == true || nodes.determine_compliance_action_router.outputs.needs_block_attempt == true}}"
    ionwall_approval_scope: "invoke_agent:comm_link_for_guardian_alerts"
    inputs:
      channel: "{{agent.prm.default_alert_channel || 'email'}}"
      recipient_identifier_cid: "{{agent.prm.default_alert_recipient_cid || trigger.input_data.event_payload.user_profile_cid}}"
      template_cid: "{{agent.prm.compliance_alert_template_cid}}"
      template_params: {
        event_summary: "{{trigger.input_data.event_topic}} - {{trigger.input_data.event_payload.summary_if_any}}",
        violations: "{{nodes.evaluate_event_with_policy_engine.outputs.evaluation_decision_obj.violations}}",
        timestamp: "{{trigger.input_data.event_timestamp_utc}}"
      }
    outputs: [alert_comm_link_response]

  - id: "attempt_preventative_action_block"
    transform: "IONWALL_AdminAction_Request_Transform"
    if: "{{nodes.determine_compliance_action_router.outputs.needs_block_attempt == true && agent.prm.enable_preventative_blocking == true}}"
    ionwall_approval_scope: "execute_ionwall_admin_action:guardian_preventative_block"
    inputs:
      action_type: "block_agent_action"
      target_details: {
        offending_event_details: "{{trigger.input_data.event_payload}}"
      }
      justification: "Automated block due to critical policy violation(s): {{nodes.evaluate_event_with_policy_engine.outputs.evaluation_decision_obj.violations}}"
    outputs: [block_action_status, block_action_ref_id]

  - id: "log_compliance_evaluation"
    transform: "StoreToIONPOD_Transform_IONWALL"
    ionwall_approval_scope: "write_pod_data:guardian_compliance_logs"
    inputs:
      data_to_store: {
        event_topic: "{{trigger.input_data.event_topic}}",
        event_payload_summary: "{{trigger.input_data.event_payload}}",
        event_timestamp_utc: "{{trigger.input_data.event_timestamp_utc}}",
        policies_evaluated_cids: "{{nodes.fetch_relevant_compliance_policies.outputs.policy_objects_array.map(p => p.cid)}}",
        evaluation_decision: "{{nodes.evaluate_event_with_policy_engine.outputs.evaluation_decision_obj}}",
        action_taken: {
          alert_sent: "{{nodes.determine_compliance_action_router.outputs.needs_alert || nodes.determine_compliance_action_router.outputs.needs_block_attempt}}",
          alert_details: "{{nodes.trigger_compliance_alert.outputs.alert_comm_link_response}}",
          block_attempted: "{{nodes.determine_compliance_action_router.outputs.needs_block_attempt && agent.prm.enable_preventative_blocking}}",
          block_status: "{{nodes.attempt_preventative_action_block.outputs.block_action_status}}",
          block_ref_id: "{{nodes.attempt_preventative_action_block.outputs.block_action_ref_id}}"
        }
      }
      filename_suggestion: "compliance_log_{{trigger.input_data.event_topic}}_{{system.timestamp_utc_iso}}.json"
    outputs: [compliance_log_cid]

  - id: "prepare_final_output"
    transform: "NoOp_PassThrough_Transform"
    inputs:
        event_topic: "{{trigger.input_data.event_topic}}",
        event_payload_summary: "{{trigger.input_data.event_payload}}",
        evaluation_result: {
            status: "{{'compliant' if nodes.determine_compliance_action_router.outputs.is_compliant else ('non_compliant_blocked' if nodes.attempt_preventative_action_block.outputs.block_action_status == 'success' else 'non_compliant_alert')}}",
            violated_policy_ids: "{{nodes.evaluate_event_with_policy_engine.outputs.evaluation_decision_obj.violations.map(v => v.policy_id)}}",
            alert_triggered_id: "{{nodes.trigger_compliance_alert.outputs.alert_comm_link_response.message_id}}",
            action_blocked_ref: "{{nodes.attempt_preventative_action_block.outputs.block_action_ref_id}}",
            error_message: "{{null}}"
        }
    outputs: [final_output_obj_for_this_fluxgraph]
```

### 3.6. `execution_requirements_json`
```json
{
  "transforms_required": [
    "FetchFromIONPOD_MultiQuery_Transform_IONWALL", // Hypothetical
    "PolicyEngine_Transform_OPA", // Example, could be other rule engines
    "SwitchCaseRouter_Transform",
    "CommLinkAgent_Invoke_Transform", // Hypothetical
    "IONWALL_AdminAction_Request_Transform", // Hypothetical & high-privilege
    "StoreToIONPOD_Transform_IONWALL",
    "NoOp_PassThrough_Transform" // For structuring output
    // A NATS Listener transform is implicitly required by the trigger type.
  ],
  "min_ram_mb": 512, // Policy engine might be memory intensive depending on rule complexity and number of policies
  "gpu_required": false,
  "estimated_execution_duration_seconds": 1, // Per event, should be very fast
  "max_concurrent_instances": 5, // Depending on event volume and policy complexity
  "wasm_modules_cids": {
    "FetchFromIONPOD_MultiQuery_Transform_IONWALL": "bafyreidfqz4dnkwonos5m5qkfxno3pgnhqfipgm6h5srypvqffijz2xdvy", // Placeholder
    "PolicyEngine_Transform_OPA": "bafyreigqodyvgnqafy2k7dqygbqagg2dszqs43qb7cfafyqpnjxkfoa5oy", // Placeholder
    "SwitchCaseRouter_Transform": "bafyreig4fxqscqg57f2jhfgfdylncxuc32syjxgyf7yt7noypz7xvo7xoi",
    "CommLinkAgent_Invoke_Transform": "bafyreid7fl56mslpbhqlvyysqoolqg7xrkf4x6jgyyrqjccmsuoejwvqze", // Placeholder
    "IONWALL_AdminAction_Request_Transform": "bafyreifvqzxqj36tnjkxanpmtkrnojjnvsyr5lshbmkthrlfhfscxnxrle", // Placeholder
    "StoreToIONPOD_Transform_IONWALL": "bafyreif7yqivqtkjhhwb5xkxqj3j7gyjlrvfkhhvjvbfffj4u7m5kfefbi",
    "NoOp_PassThrough_Transform": "bafyreibwlilx3jsnetlzuoaaaguymgtyshferxklnjrwqgzgkrkmwempce"
  }
}
```

### 3.7. `ecosystem_integration_points_json`
```json
{
  "ionwall_permissions_needed": [
    "read_pod_data:guardian_compliance_policies", // To fetch policies
    "execute_compliance_policy_engine:guardian_agent", // To run its core logic
    "invoke_agent:comm_link_for_guardian_alerts", // To send alerts
    "execute_ionwall_admin_action:guardian_preventative_block", // Highly privileged, for blocking actions
    "write_pod_data:guardian_compliance_logs", // To store its findings
    "subscribe_to_nats_topics:ionflux_system_events" // For its NATS listener trigger
  ],
  "ionpod_data_access": {
    "inputs": [
      { "cid_param": "agent.prm.default_policy_index_cid", "access_type": "read", "purpose": "To locate and fetch relevant compliance policies from IONPOD." },
      { "data_pattern": "user_defined_policy_cids_in_index", "access_type": "read", "purpose": "To read individual policy documents."}
    ],
    "outputs": [
      { "cid_name": "compliance_log_cid", "access_type": "write", "purpose": "To store detailed logs of compliance evaluations and actions taken." }
    ]
  },
  "tokenomic_triggers": [
    { "event": "policy_violation_detected_and_logged", "action": "debit_user_compliance_monitoring_fee", "token_id": "C-ION", "amount_formula": "0.0005" }, // For the monitoring service
    { "event": "preventative_block_action_successfully_executed", "action": "reward_guardian_agent_operator_or_dao", "token_id": "$ION", "amount_formula": "0.1" } // For successful critical intervention
  ],
  "techgnosis_integration": {
    "knowledge_graph_queries": [
      "get_lineage_of_data_cid:{{trigger.input_data.event_payload.data_cid}}", // To understand data history for policy evaluation
      "identify_sensitive_entities_in_payload:{{trigger.input_data.event_payload}}", // To check against data handling policies
      "get_agent_reputation_score:{{trigger.input_data.event_payload.agent_id}}" // May influence policy strictness
    ],
    "natural_language_policy_understanding": true, // TechGnosis could help parse user-defined policies written in natural language into a format the PolicyEngine_Transform can use.
    "risk_assessment_based_on_event_pattern_analysis": true // TechGnosis identifies emerging risky patterns even if no single policy is violated.
  },
  "hybrid_layer_escalation_points": [
    { "condition": "policy_violation_ambiguous_or_requires_human_judgment", "action": "escalate_to_hybrid_layer_compliance_officer_for_review" },
    { "condition": "user_disputes_automated_compliance_action_or_finding", "action": "initiate_hybrid_layer_dispute_resolution_process" },
    { "condition": "request_for_preventative_block_action_not_pre_approved_for_automation", "action": "require_hybrid_layer_human_approval_before_block_execution" }
  ],
  "carbon_loop_contribution": {
    "type": "policy_driven_resource_optimization",
    "value_formula": "number_of_resource_intensive_actions_avoided_due_to_policy * estimated_carbon_saved_per_action",
    "description": "Compliance policies can be defined to discourage resource-intensive operations unless necessary (e.g., 'limit large data processing jobs by experimental agents during peak hours'). Guardian enforcing these contributes to overall efficiency and potentially lower carbon footprint."
  }
}
```

### 3.8. `prm_details_json`
```json
{
  "default_policy_index_cid": "bafk... (CID of a default policy index in IONPOD for this user/agent)",
  "policy_engine_type_preference": "OPA", // "JSONLogic", "CustomDSL"
  "default_alert_channel": "matrix", // "email", "nats_topic_for_alerts"
  "default_alert_recipient_cid": "bafk... (CID of contact object for default admin/user to alert)",
  "compliance_alert_template_cid": "bafk... (CID of template for alert messages)",
  "enable_preventative_blocking": false, // Default to false; requires explicit user opt-in and Hybrid Layer setup
  "preventative_blocking_requires_hybrid_approval_default": true,
  "log_retention_days_compliance_logs": 180,
  "user_customizable_params_for_policy_management": [ // For a separate policy management FluxGraph
    "policy_definition_object", "policy_status_active_inactive", "policy_scope_tags"
  ]
}
```

### 3.9. `input_schema_json`
*(The JSON content of `input_schema` for `guardian_evaluate_event_for_compliance_fluxgraph` from Section 2 is inserted here)*
```json
{
  "type": "object",
  "properties": {
    "event_topic": { "type": "string", "description": "The NATS topic the event came from." },
    "event_payload": { "type": "object", "additionalProperties": true, "description": "The actual payload of the NATS event." },
    "event_timestamp_utc": { "type": "string", "format": "date-time" }
  },
  "required": [ "event_topic", "event_payload", "event_timestamp_utc" ]
}
```

### 3.10. `output_schema_json`
*(The JSON content of `output_schema` for `guardian_evaluate_event_for_compliance_fluxgraph` from Section 2 is inserted here)*
```json
{
  "type": "object",
  "properties": {
    "event_topic": { "type": "string" },
    "event_payload_summary": { "type": "object", "description": "Summary of the processed event." },
    "evaluation_result": {
      "type": "object",
      "properties": {
        "status": { "type": "string", "enum": ["compliant", "non_compliant_alert", "non_compliant_blocked", "error_in_evaluation"] },
        "violated_policy_ids": { "type": "array", "items": { "type": "string" }, "nullable": true },
        "alert_triggered_id": { "type": "string", "nullable": true },
        "action_blocked_ref": { "type": "string", "nullable": true },
        "error_message": { "type": "string", "nullable": true }
      }
    }
  },
  "required": [ "event_topic", "evaluation_result" ]
}
```

### 3.11. `trigger_config_json`
```json
{
  "manual_trigger_enabled": false, # This agent is primarily event-driven for evaluation
  "event_driven_multi_topic_listener_configs": [ # Assuming this key is supported for such a trigger
    {
      "nats_topics": [
        "ionflux.events.agent_action_taken",
        "ionflux.events.data_access_requested",
        "ionflux.events.data_access_granted",
        "ionflux.events.ionwall_consent_changed",
        "ionflux.events.agent_registered_or_updated"
      ],
      "description": "Listens to a wide range of IONFLUX system events for compliance evaluation.",
      "queue_group_name": "guardian_compliance_evaluators", # For load balancing if multiple Guardian instances
      "payload_normalization_script_cid": null # Optional: CID of a script to normalize diverse event payloads before hitting input_schema
    }
  ],
  # Triggers for a separate policy management FluxGraph would be NATS/HTTP based for CRUD operations on policies.
  "nats_triggers_for_policy_management": [
    { "topic": "ionflux.agents.guardian.manage_policy", "description": "For creating, updating, disabling policies."}
  ]
}
```

### 3.12. `deployment_info_json`
```json
{
  "runtime_environment": "IONFLUX_EdgeNode_Wasm_HighPerf", // Policy engine might need good performance
  "current_instances_managed_by_ionflux_controller": true,
  "default_replicas": 1, // Could be >1 for high event volume, ensure NATS queue group for listeners
  "auto_scaling_policy": {
    "min_replicas": 1,
    "max_replicas": 3,
    "nats_pending_message_threshold_per_topic_group": 1000, // Scale if event queue grows
    "cpu_threshold_percentage": 70
  }
}
```

### 3.13. `logging_json`
```json
{
  "log_level": "warn", // Log compliant events at info/debug, but default to warn for non-compliant or errors
  "log_targets": ["ionpod_event_log_guardian", "system_audit_trail_compliance", "local_stdout_dev_mode_only"],
  "log_retention_policy_days_compliance": 365, // Compliance logs often need longer retention
  "sensitive_fields_to_mask_in_event_payload_logs": ["event_payload.credentials", "event_payload.raw_personal_data"]
}
```

### 3.14. `monitoring_json`
```json
{
  "metrics_to_collect": [
    "events_processed_count_total", "events_evaluated_per_second",
    "compliant_events_count", "non_compliant_events_count", "alerts_triggered_count", "actions_blocked_count",
    "policy_evaluation_latency_avg_ms", "errors_in_policy_evaluation_count"
  ],
  "metrics_endpoint_ionwall_protected": "/metrics/guardian_compliance_agent",
  "health_check_protocol": "check_nats_listener_status_and_policy_store_accessibility",
  "alerting_rules": [
    {"metric": "non_compliant_events_critical_policy_count", "condition": "value > 0 for 1m", "severity": "critical", "notification_channel": "hybrid_layer_ops_pager_security"},
    {"metric": "policy_evaluation_latency_avg_ms", "condition": "value > 1000 for 5m", "severity": "warning", "notification_channel": "hybrid_layer_ops_team_chat_performance"}
  ]
}
```

### 3.15. `security_json`
```json
{
  "data_encryption_at_rest_ionpod": true,
  "data_encryption_in_transit_ipfs_ionwall": true,
  "policy_definition_integrity_check_enabled": true, // Ensure policies are not tampered with (e.g., via CIDs and digital signatures)
  "preventative_blocking_consent_model": "explicit_per_policy_or_global_with_hybrid_layer_oversight",
  "audit_log_immutability_target": "ionpod_versioned_cid_storage_or_dedicated_immutable_log_service",
  "required_ionwall_consent_scopes_for_guardian_itself": [ // Scopes Guardian needs for its own operation
     "read_pod_data:guardian_compliance_policies", "execute_compliance_policy_engine:guardian_agent",
     "invoke_agent:comm_link_for_guardian_alerts", "write_pod_data:guardian_compliance_logs",
     "subscribe_to_nats_topics:ionflux_system_events"
     // The powerful "execute_ionwall_admin_action:guardian_preventative_block" is separate and explicitly enabled via prm_details.
  ],
  "sensitive_data_handling_policy_id": "SDP-GUARDIAN-001"
}
```

---
## 4. User Experience Flow (Conceptual)

**A. Defining a New Compliance Policy:**
1.  **Initiation:** User accesses the IONFLUX Compliance Management UI (potentially a dedicated interface or part of general settings).
2.  **Policy Creation:** User defines a policy, e.g., "Data Sovereignty Policy for EU Residents":
    *   **Condition:** If `event_payload.data_subject_residency == "EU"` AND `event_payload.target_storage_location_requested` is outside EU.
    *   **Action:** `status: "non_compliant_alert"`, `alert_message_template: "Attempt to store EU resident data outside EU: {{event_payload.data_cid}} to {{event_payload.target_storage_location_requested}}"`
    *   (Optionally, for stricter policy): `action_if_severe: "attempt_block"`
    *   This policy is saved as a structured object (e.g., JSON with Rego snippet) in the user's IONPOD, and its CID is added to Guardian's policy index.
3.  **IONWALL Checkpoint (Policy Activation):**
    *   IONWALL prompts User: *"Guardian Compliance Agent wants to:
        *   Activate new policy: 'Data Sovereignty Policy for EU Residents'.
        *   This policy may trigger alerts or (if configured for blocking and pre-approved) attempt to block actions related to data storage.
        Allow Guardian to enforce this policy?"*

**B. An Agent Action Violates a Policy:**
1.  **Event:** `Agent X` attempts to store data (CID: `bafy...abc`) for an EU resident to a US-based storage (this info is in the `agent_action_taken` event payload, perhaps enriched by TechGnosis identifying data residency).
2.  **Guardian Evaluation:**
    *   `Guardian Compliance Agent` receives the NATS event.
    *   Fetches the "Data Sovereignty Policy for EU Residents" and other relevant policies.
    *   `PolicyEngine_Transform` evaluates the event: `event_payload.data_subject_residency == "EU"` (true) AND `event_payload.target_storage_location_requested == "US"` (true) => Violation!
3.  **Action (Alert):**
    *   `Guardian` determines `needs_alert` is true.
    *   Invokes `Comm Link Agent` to send an alert to the user/admin: "Compliance Alert: Attempt to store EU resident data (bafy...abc) in US, violating policy 'Data Sovereignty P007'."
4.  **Logging:** The event, policy evaluation, and alert action are logged to IONPOD.
5.  **User Review:** User sees the alert in their UI/email, can review the compliance log entry, and investigate `Agent X`'s behavior. If it was a misconfiguration, they correct Agent X. If the policy is too strict, they might revise it.

---
## 5. TechGnosis & Hybrid Layer Integration Notes

*   **TechGnosis:**
    *   **Policy Language Interpretation:** Users might write policies in a simplified natural language or a high-level DSL. TechGnosis could translate these into the formal language required by the `PolicyEngine_Transform` (e.g., Rego).
    *   **Contextual Enrichment for Evaluation:** Before an event payload is sent to the Policy Engine, TechGnosis can enrich it with relevant context from the knowledge graph. For example, if an event involves a `data_cid`, TechGnosis could add metadata like "data_sensitivity_level: high", "data_subject_category: financial_records", which policies can then use.
    *   **Risk Assessment:** TechGnosis can analyze patterns of events and policy evaluations over time to identify emerging compliance risks or suggest new policies, even if no single event explicitly violated a current rule.
*   **Hybrid Layer:**
    *   **Adjudication of Violations:** For complex or ambiguous policy violations where automated determination is difficult, `Guardian Compliance Agent` escalates to the Hybrid Layer. A human compliance officer reviews the case and makes a judgment.
    *   **Approval for Preventative Actions:** If `Guardian` detects a critical violation and `prm_details_json.enable_preventative_blocking` is true BUT `preventative_blocking_requires_hybrid_approval_default` is also true (or for specific high-impact policies), the block action is staged. A Hybrid Layer request is created for a human to approve/deny the block in near real-time.
    *   **Policy Exception Management:** Users might request temporary or permanent exceptions to certain policies for specific agents or use cases. These requests would be managed and approved/denied through a Hybrid Layer workflow.

---
## 6. Carbon Loop Integration Notes

*   **Enforcing Green Policies:** Users can define compliance policies that encourage or mandate resource-efficient behaviors. For example:
    *   "Policy: LLM inference by 'non-critical' agents must use 'low-power' models during daytime hours."
    *   "Policy: Large-scale data processing tasks by 'research' agents should be scheduled during off-peak energy (low carbon intensity) periods."
    `Guardian Compliance Agent` would monitor agent actions and scheduler events, flagging violations of these "green policies."
*   **Incentivizing Compliance:** Tokenomic models could reward users/agents that consistently adhere to resource efficiency policies, with compliance data provided by `Guardian`.

---
## 7. Dependencies & Interactions

*   **Required Transforms (Core Guardian Logic):**
    *   NATS Listener transform (implicit in trigger)
    *   `FetchFromIONPOD_MultiQuery_Transform_IONWALL` (or similar for fetching policies)
    *   `PolicyEngine_Transform_OPA` (or other rule engine)
    *   `SwitchCaseRouter_Transform`
    *   `CommLinkAgent_Invoke_Transform` (or direct NATS publish for alerts)
    *   `IONWALL_AdminAction_Request_Transform` (for blocking, highly privileged)
    *   `StoreToIONPOD_Transform_IONWALL` (for logging)
*   **Interacting Agents (Conceptual):**
    *   Listens to events from potentially ALL other IONFLUX agents.
    *   Triggers `Comm Link Agent` for sending alerts.
    *   Interacts with `IONWALL Controller` (via `IONWALL_AdminAction_Request_Transform`) if attempting to block actions.
    *   May interact with a `Policy Management Agent` (if one exists for UI-driven policy creation).
    *   Relies on `TechGnosis Agent` for contextual enrichment or advanced policy interpretation.
    *   Escalates issues to the `Hybrid Layer` interface/system.
*   **External Systems (Indirectly):**
    *   None directly. Its actions are confined to the IONFLUX ecosystem, but the policies it enforces might relate to external regulations (e.g., GDPR, HIPAA).

---
## 8. Open Questions & Future Considerations

*   **Policy Definition Language Standard:** What is the best language/format for defining policies? Rego (OPA) is powerful but complex. JSONLogic, YAML-based rules, or a custom DSL? Needs to balance expressiveness with ease of use for non-technical users (possibly with TechGnosis translation).
*   **Granularity of Event Monitoring:** Which specific events and what level of detail within those events should Guardian monitor? Too much can impact performance; too little can miss violations.
*   **Performance Impact:** Real-time policy evaluation for a high volume of system events could be resource-intensive. Efficient Policy Engine transforms and optimized policy fetching are crucial. Consider compiled policies or caching.
*   **False Positive/Negative Handling:** How are false positives (compliant actions flagged as violations) and false negatives (violations missed) managed and minimized? Requires robust policy testing and refinement.
*   **Dynamic Policy Updates:** How quickly can Guardian react to newly added or updated policies without restarting or significant delay?
*   **Circular Dependencies:** What if Guardian itself (or an agent it depends on, like Comm Link) violates a policy? Needs careful design to avoid deadlocks or unmonitored critical components.
*   **User Interface for Compliance Dashboard:** A UI for users to view active policies, see compliance status, review violations and alerts, and manage policy exceptions.
*   **Federated Compliance:** How does Guardian handle compliance in scenarios involving multiple federated IONFLUX spaces or interactions with external, non-IONFLUX systems?
*   **Explainability of Decisions:** When a violation is flagged, providing a clear explanation of which policy was violated and why the action was deemed non-compliant.
