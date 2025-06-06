# Agent Blueprint: Chronos Task Agent - v0.9.0

## 1. Overview

*   **Agent Name:** `Chronos Task Agent`
*   **Version:** `0.9.0`
*   **Status:** `development`
*   **Primary Goal:** `Manages scheduled tasks, reminders, and triggers other agents or FluxGraphs based on time events (cron-like functionality, specific datetime execution, or delays from a trigger event).`
*   **Key Features:**
    *   Allows users or other agents to schedule tasks with various timing mechanisms:
        *   Cron expressions for recurring tasks (e.g., "every day at 9 AM").
        *   Specific datetime for one-time execution.
        *   Delay relative to the scheduling request (e.g., "execute in 2 hours").
    *   Tasks can trigger actions such as:
        *   Publishing a message to a NATS topic.
        *   Invoking another agent directly (e.g., via its webhook trigger or a NATS invocation message).
        *   Initiating a specific FluxGraph execution.
    *   Manages a persistent schedule of tasks. This schedule is conceptually stored in a secure way, possibly within the user's IONPOD as structured data or managed by a dedicated, robust scheduling service that Chronos interacts with via transforms (all mediated by IONWALL).
    *   Provides interfaces (e.g., triggered by NATS messages or HTTP requests) for creating, viewing, updating (rescheduling, modifying), and deleting scheduled tasks.
    *   Logs task scheduling events and execution outcomes to IONPOD.
    *   Requires IONWALL approval for scheduling tasks that will perform actions, especially those involving other agents or external interactions.

## 2. FluxGraph Definition (Conceptual YAML)

```yaml
# /specs/agents/chronos_task_agent_fluxgraph.yaml (Conceptual representation)
# This agent likely has at least two primary functional FluxGraphs:
# 1. ManageScheduleFluxGraph: For CRUD operations on scheduled tasks.
# 2. ExecuteScheduledTaskFluxGraph: Triggered by the underlying scheduling mechanism when a task is due.

# FluxGraph 1: ManageScheduleFluxGraph
# Name: "chronos_manage_schedule_fluxgraph"
# Description: "Handles creating, updating, deleting, and listing scheduled tasks."
# Triggers: NATS (e.g., ionflux.agents.chronos.manage_task), HTTP webhook
# Input Schema: { operation: "create|update|delete|list", task_definition: { ... } }
# Output Schema: { status: "success|failure", task_id: "...", tasks_list: [{...}] }
# Graph:
#  - id: "authorize_schedule_management" (IONWALL check for permission to manage schedules)
#  - id: "route_operation" (Switch based on input.operation)
#  - id: "create_task_in_scheduler" (uses a SecureScheduler_ManageTask_Transform)
#    inputs: { action: "create", definition: "{{trigger.input_data.task_definition}}" }
#    outputs: [task_id, status]
#  - id: "update_task_in_scheduler" (uses SecureScheduler_ManageTask_Transform)
#  - id: "delete_task_in_scheduler" (uses SecureScheduler_ManageTask_Transform)
#  - id: "list_tasks_from_scheduler" (uses SecureScheduler_ManageTask_Transform)
#  - id: "log_management_action" (StoreToIONPOD)
#  - id: "return_management_response" (IPC_NATS_Publish or HTTP response)

# --- Separator for clarity ---

# FluxGraph 2: ExecuteScheduledTaskFluxGraph (This is the one detailed below)
version: "0.1.0"
name: "chronos_execute_scheduled_task_fluxgraph"
description: "Executes a scheduled task when triggered by the scheduling system."

triggers:
  - type: "internal_scheduler_event" # This is a special trigger type, implying the FluxGraph engine itself or a tightly coupled service generates this event when a scheduled task is due.
    config: { event_filter_type: "chronos_task_due" }

input_schema: # Expected input from the internal scheduler event
  type: "object"
  properties:
    task_id: { type: "string", description: "Unique ID of the scheduled task that is due." }
    task_definition_cid: { type: "string", description: "CID of the IONPOD object containing the full task definition (target, payload, etc.)." }
    # Original schedule_time and actual_trigger_time might also be included by the scheduler.
  required: [ "task_id", "task_definition_cid" ]

output_schema: # Output of this execution, primarily for logging/monitoring
  type: "object"
  properties:
    task_id: { type: "string" }
    execution_status: { type: "string", enum: ["success", "failure", "action_triggered_no_response"] }
    action_response_summary: { type: "string", nullable: true, description: "Brief summary or ID from the triggered action, if available." }
    error_message: { type: "string", nullable: true }
  required: [ "task_id", "execution_status" ]

graph:
  - id: "fetch_task_definition"
    transform: "FetchFromIONPOD_Transform_IONWALL"
    ionwall_approval_scope: "read_pod_data:chronos_task_definitions" # Chronos needs to read its own task definitions
    inputs:
      cid: "{{trigger.input_data.task_definition_cid}}"
    outputs: [task_def_obj] # Contains { target_type: "nats|webhook|agent_event", target_identifier: "...", payload_template_cid: "...", payload_params: {...} }

  # IONWALL Check: Before executing the action, ensure the original consent for this scheduled task is still valid
  # This is a conceptual step. The actual mechanism might involve checking a stored consent receipt or re-validating
  # the scope of the scheduled action against current user policies.
  - id: "validate_execution_consent"
    transform: "IONWALL_CheckStoredConsent_Transform" # Hypothetical transform
    inputs:
      task_id: "{{trigger.input_data.task_id}}"
      action_scopes_from_task_def: "{{nodes.fetch_task_definition.outputs.task_def_obj.required_ionwall_scopes}}"
    outputs: [is_consent_valid]
    # If consent is not valid, the graph should branch to an error/logging path and not proceed. This 'if' is implied for subsequent steps.

  - id: "fetch_payload_template_conditional"
    transform: "FetchFromIONPOD_Transform_IONWALL"
    if: "{{nodes.fetch_task_definition.outputs.task_def_obj.payload_template_cid != null && nodes.validate_execution_consent.outputs.is_consent_valid == true}}"
    ionwall_approval_scope: "read_pod_data:chronos_payload_templates"
    inputs:
      cid: "{{nodes.fetch_task_definition.outputs.task_def_obj.payload_template_cid}}"
    outputs: [payload_template_string]

  - id: "process_payload_template"
    transform: "TemplateProcessor_Transform_Jinja2"
    if: "{{nodes.fetch_payload_template_conditional.outputs.payload_template_string != null && nodes.validate_execution_consent.outputs.is_consent_valid == true}}"
    inputs:
      template: "{{nodes.fetch_payload_template_conditional.outputs.payload_template_string}}"
      parameters: "{{nodes.fetch_task_definition.outputs.task_def_obj.payload_params}}"
    outputs: [processed_payload_string_or_json] # Output could be JSON string or plain text based on template

  # Router for different target types
  - id: "route_by_target_type"
    transform: "SwitchCaseRouter_Transform"
    if: "{{nodes.validate_execution_consent.outputs.is_consent_valid == true}}"
    inputs:
      switch_value: "{{nodes.fetch_task_definition.outputs.task_def_obj.target_type}}"
    outputs: [is_nats_target, is_webhook_target, is_agent_event_target]

  # NATS Target Path
  - id: "trigger_nats_action"
    transform: "IPC_NATS_Publish_Transform"
    if: "{{nodes.route_by_target_type.outputs.is_nats_target == true}}"
    inputs:
      topic: "{{nodes.fetch_task_definition.outputs.task_def_obj.target_identifier}}" # e.g., "ionflux.agents.muse.invoke"
      message_payload_string: "{{nodes.process_payload_template.outputs.processed_payload_string_or_json if nodes.process_payload_template else nodes.fetch_task_definition.outputs.task_def_obj.static_payload}}"
    outputs: [nats_publish_status, nats_message_id_optional]

  # Webhook Target Path (Simplified - a real one needs more error handling, method types etc.)
  - id: "trigger_webhook_action"
    transform: "HTTP_Request_Transform_IONWALLProtected" # Assumes this transform handles IONWALL for egress
    if: "{{nodes.route_by_target_type.outputs.is_webhook_target == true}}"
    ionwall_approval_scope: "access_external_webhook:{{nodes.fetch_task_definition.outputs.task_def_obj.target_identifier}}" # Dynamic scope
    inputs:
      url: "{{nodes.fetch_task_definition.outputs.task_def_obj.target_identifier}}"
      method: "{{nodes.fetch_task_definition.outputs.task_def_obj.http_method || 'POST'}}"
      payload_json_string: "{{nodes.process_payload_template.outputs.processed_payload_string_or_json if nodes.process_payload_template else nodes.fetch_task_definition.outputs.task_def_obj.static_payload}}"
      headers: { "Content-Type": "application/json" }
    outputs: [webhook_response_obj, webhook_status_code, webhook_error_msg]

  # Agent Event Target Path (could be another NATS message to a specific agent's known topic)
  # Similar to NATS path, but potentially with more structured agent-to-agent payload.

  - id: "aggregate_action_results"
    transform: "MergeResults_Transform" # Collects results
    inputs:
      nats_result: { status: "{{nodes.trigger_nats_action.outputs.nats_publish_status}}", id: "{{nodes.trigger_nats_action.outputs.nats_message_id_optional}}", if_condition: "{{nodes.route_by_target_type.outputs.is_nats_target}}"}
      webhook_result: { status: "{{'success' if nodes.trigger_webhook_action.outputs.webhook_status_code >= 200 && nodes.trigger_webhook_action.outputs.webhook_status_code < 300 else 'failure'}}", response_summary: "{{nodes.trigger_webhook_action.outputs.webhook_status_code}}", error: "{{nodes.trigger_webhook_action.outputs.webhook_error_msg}}", if_condition: "{{nodes.route_by_target_type.outputs.is_webhook_target}}"}
    outputs: [final_execution_status, final_action_response_summary, final_error_message]

  - id: "log_task_execution"
    transform: "StoreToIONPOD_Transform_IONWALL"
    ionwall_approval_scope: "write_pod_data:chronos_execution_logs"
    inputs:
      data_to_store: {
        task_id: "{{trigger.input_data.task_id}}",
        task_definition_cid: "{{trigger.input_data.task_definition_cid}}",
        scheduled_time_utc: "{{nodes.fetch_task_definition.outputs.task_def_obj.schedule_time_utc}}", # Assuming this is in task_def
        actual_execution_time_utc: "{{system.timestamp_utc}}",
        status: "{{nodes.aggregate_action_results.outputs.final_execution_status}}",
        action_response_summary: "{{nodes.aggregate_action_results.outputs.final_action_response_summary}}",
        error_message: "{{nodes.aggregate_action_results.outputs.final_error_message}}"
      }
      filename_suggestion: "chronos_exec_log_{{trigger.input_data.task_id}}_{{system.timestamp_utc_iso}}.json"
    outputs: [execution_log_cid]

  # Optionally, update the task in the scheduler (e.g., if it was a one-time task, mark as completed or delete; if recurring, update next run time)
  # This would use the SecureScheduler_ManageTask_Transform again. For brevity, not detailed here.
```

---
## 3. Database Schema Fields (`agent_definitions` table)

### 3.1. `agent_name`
`"Chronos Task Agent"`

### 3.2. `version`
`"0.9.0"`

### 3.3. `description`
`"Manages scheduled tasks, reminders, and triggers other agents or FluxGraphs based on time events (cron-like functionality, specific datetime execution, or delays from a trigger event)."`

### 3.4. `status`
`"development"`

### 3.5. `flux_graph_dsl_yaml`
*(The YAML content for **`chronos_execute_scheduled_task_fluxgraph`** from Section 2 is inserted here. The `chronos_manage_schedule_fluxgraph` would be a separate agent definition or its DSL included if this agent handles both aspects directly in one definition file.)*
```yaml
version: "0.1.0"
name: "chronos_execute_scheduled_task_fluxgraph"
description: "Executes a scheduled task when triggered by the scheduling system."

triggers:
  - type: "internal_scheduler_event"
    config: { event_filter_type: "chronos_task_due" }

input_schema:
  type: "object"
  properties:
    task_id: { type: "string", description: "Unique ID of the scheduled task that is due." }
    task_definition_cid: { type: "string", description: "CID of the IONPOD object containing the full task definition." }
  required: [ "task_id", "task_definition_cid" ]

output_schema:
  type: "object"
  properties:
    task_id: { type: "string" }
    execution_status: { type: "string", enum: ["success", "failure", "action_triggered_no_response"] }
    action_response_summary: { type: "string", nullable: true, description: "Brief summary or ID from the triggered action." }
    error_message: { type: "string", nullable: true }
  required: [ "task_id", "execution_status" ]

graph:
  - id: "fetch_task_definition"
    transform: "FetchFromIONPOD_Transform_IONWALL"
    ionwall_approval_scope: "read_pod_data:chronos_task_definitions"
    inputs:
      cid: "{{trigger.input_data.task_definition_cid}}"
    outputs: [task_def_obj]

  - id: "validate_execution_consent"
    transform: "IONWALL_CheckStoredConsent_Transform"
    inputs:
      task_id: "{{trigger.input_data.task_id}}"
      action_scopes_from_task_def: "{{nodes.fetch_task_definition.outputs.task_def_obj.required_ionwall_scopes}}"
    outputs: [is_consent_valid]

  - id: "fetch_payload_template_conditional"
    transform: "FetchFromIONPOD_Transform_IONWALL"
    if: "{{nodes.fetch_task_definition.outputs.task_def_obj.payload_template_cid != null && nodes.validate_execution_consent.outputs.is_consent_valid == true}}"
    ionwall_approval_scope: "read_pod_data:chronos_payload_templates"
    inputs:
      cid: "{{nodes.fetch_task_definition.outputs.task_def_obj.payload_template_cid}}"
    outputs: [payload_template_string]

  - id: "process_payload_template"
    transform: "TemplateProcessor_Transform_Jinja2"
    if: "{{nodes.fetch_payload_template_conditional.outputs.payload_template_string != null && nodes.validate_execution_consent.outputs.is_consent_valid == true}}"
    inputs:
      template: "{{nodes.fetch_payload_template_conditional.outputs.payload_template_string}}"
      parameters: "{{nodes.fetch_task_definition.outputs.task_def_obj.payload_params}}"
    outputs: [processed_payload_string_or_json]

  - id: "route_by_target_type"
    transform: "SwitchCaseRouter_Transform"
    if: "{{nodes.validate_execution_consent.outputs.is_consent_valid == true}}"
    inputs:
      switch_value: "{{nodes.fetch_task_definition.outputs.task_def_obj.target_type}}"
    outputs: [is_nats_target, is_webhook_target, is_agent_event_target]

  - id: "trigger_nats_action"
    transform: "IPC_NATS_Publish_Transform"
    if: "{{nodes.route_by_target_type.outputs.is_nats_target == true}}"
    inputs:
      topic: "{{nodes.fetch_task_definition.outputs.task_def_obj.target_identifier}}"
      message_payload_string: "{{nodes.process_payload_template.outputs.processed_payload_string_or_json if nodes.process_payload_template else nodes.fetch_task_definition.outputs.task_def_obj.static_payload}}"
    outputs: [nats_publish_status, nats_message_id_optional]

  - id: "trigger_webhook_action"
    transform: "HTTP_Request_Transform_IONWALLProtected"
    if: "{{nodes.route_by_target_type.outputs.is_webhook_target == true}}"
    ionwall_approval_scope: "access_external_webhook:{{nodes.fetch_task_definition.outputs.task_def_obj.target_identifier}}"
    inputs:
      url: "{{nodes.fetch_task_definition.outputs.task_def_obj.target_identifier}}"
      method: "{{nodes.fetch_task_definition.outputs.task_def_obj.http_method || 'POST'}}"
      payload_json_string: "{{nodes.process_payload_template.outputs.processed_payload_string_or_json if nodes.process_payload_template else nodes.fetch_task_definition.outputs.task_def_obj.static_payload}}"
      headers: { "Content-Type": "application/json" }
    outputs: [webhook_response_obj, webhook_status_code, webhook_error_msg]

  - id: "aggregate_action_results"
    transform: "MergeResults_Transform"
    inputs:
      nats_result: { status: "{{nodes.trigger_nats_action.outputs.nats_publish_status}}", id: "{{nodes.trigger_nats_action.outputs.nats_message_id_optional}}", if_condition: "{{nodes.route_by_target_type.outputs.is_nats_target}}"}
      webhook_result: { status: "{{'success' if nodes.trigger_webhook_action.outputs.webhook_status_code >= 200 && nodes.trigger_webhook_action.outputs.webhook_status_code < 300 else 'failure'}}", response_summary: "{{nodes.trigger_webhook_action.outputs.webhook_status_code}}", error: "{{nodes.trigger_webhook_action.outputs.webhook_error_msg}}", if_condition: "{{nodes.route_by_target_type.outputs.is_webhook_target}}"}
    outputs: [final_execution_status, final_action_response_summary, final_error_message]

  - id: "log_task_execution"
    transform: "StoreToIONPOD_Transform_IONWALL"
    ionwall_approval_scope: "write_pod_data:chronos_execution_logs"
    inputs:
      data_to_store: {
        task_id: "{{trigger.input_data.task_id}}",
        task_definition_cid: "{{trigger.input_data.task_definition_cid}}",
        scheduled_time_utc: "{{nodes.fetch_task_definition.outputs.task_def_obj.schedule_time_utc}}",
        actual_execution_time_utc: "{{system.timestamp_utc}}",
        status: "{{nodes.aggregate_action_results.outputs.final_execution_status}}",
        action_response_summary: "{{nodes.aggregate_action_results.outputs.final_action_response_summary}}",
        error_message: "{{nodes.aggregate_action_results.outputs.final_error_message}}"
      }
      filename_suggestion: "chronos_exec_log_{{trigger.input_data.task_id}}_{{system.timestamp_utc_iso}}.json"
    outputs: [execution_log_cid]
```

### 3.6. `execution_requirements_json`
```json
{
  "transforms_required": [
    "FetchFromIONPOD_Transform_IONWALL",
    "IONWALL_CheckStoredConsent_Transform", // Hypothetical
    "TemplateProcessor_Transform_Jinja2",
    "SwitchCaseRouter_Transform",
    "IPC_NATS_Publish_Transform",
    "HTTP_Request_Transform_IONWALLProtected",
    "MergeResults_Transform",
    "StoreToIONPOD_Transform_IONWALL",
    "SecureScheduler_ManageTask_Transform" // For the management FluxGraph
  ],
  "min_ram_mb": 256,
  "gpu_required": false,
  "estimated_execution_duration_seconds": 5, // For task execution logic; scheduling logic is also quick.
  "max_concurrent_instances": 50, // Can handle many concurrent task executions; scheduler itself is robust.
  "wasm_modules_cids": {
    "FetchFromIONPOD_Transform_IONWALL": "bafyreibvlobj2rl34gsgxrjltirqesqkfbhtharb3uaxnri3ebpmpah6ce",
    "IONWALL_CheckStoredConsent_Transform": "bafyreidnkavufesxajhuki7zfdjl5medwqvc7xtx5sjoezu5yjjqvpyfau", // Placeholder
    "TemplateProcessor_Transform_Jinja2": "bafyreid3ifqivfancx5flci3tqgws6ahmblzdxq63ot6ytkvykxuvcaapu",
    "SwitchCaseRouter_Transform": "bafyreig4fxqscqg57f2jhfgfdylncxuc32syjxgyf7yt7noypz7xvo7xoi",
    "IPC_NATS_Publish_Transform": "bafyreihyrz7wgld5qrjmejbdjcbcm3jqrjshxphu6jnlxhnlfbk7d745xy",
    "HTTP_Request_Transform_IONWALLProtected": "bafyreifpkmoytcqqzaxbmsxobs7q3bmyvcygj2jqzr4of3gwjxkexwdgkq", // Placeholder
    "MergeResults_Transform":"bafyreihdjdlxqz73237nmy2gtj7wpsacjnqv7rajidgozztx7jyqxfnhom",
    "StoreToIONPOD_Transform_IONWALL": "bafyreif7yqivqtkjhhwb5xkxqj3j7gyjlrvfkhhvjvbfffj4u7m5kfefbi",
    "SecureScheduler_ManageTask_Transform": "bafyreih6s7kqqfzllj2ezxmygbolffwycwdzd2dlk73nlcyzjxwvjzgvnq" // Placeholder
  }
}
```

### 3.7. `ecosystem_integration_points_json`
```json
{
  "ionwall_permissions_needed": [
    "read_pod_data:chronos_task_definitions", // To read its own task details when executing
    "read_pod_data:chronos_payload_templates", // To read payload templates for tasks
    "write_pod_data:chronos_execution_logs",   // To log when tasks execute
    "manage_scheduler_tasks:chronos_agent_self", // Permission for Chronos to add/remove/update tasks in the underlying scheduler
    // Scopes for actions performed by tasks (e.g., "publish_nats_topic:some_target_topic", "access_external_webhook:some_url")
    // are NOT held by Chronos itself, but are declared within the task definition and validated by IONWALL_CheckStoredConsent_Transform before execution.
    "check_stored_consent_for_scheduled_action:chronos_agent" // For IONWALL_CheckStoredConsent_Transform
  ],
  "ionpod_data_access": {
    "inputs": [
      { "cid_param": "task_definition_cid (execution)", "access_type": "read", "purpose": "To fetch the definition of the task to be executed." },
      { "cid_param": "task_definition.payload_template_cid (execution)", "access_type": "read", "purpose": "To fetch the payload template for the task." },
      { "data_object": "task_definition (management)", "access_type": "read,write,delete", "purpose": "To store, update, and manage task definitions in user's IONPOD if scheduler uses IONPOD as backend."}
    ],
    "outputs": [
      { "cid_name": "execution_log_cid (execution)", "access_type": "write", "purpose": "To store logs of task executions." }
    ]
  },
  "tokenomic_triggers": [
    { "event": "scheduled_task_creation_successful", "action": "debit_user_service_credits", "token_id": "C-ION", "amount_formula": "0.0001" }, // Small fee for scheduling
    { "event": "scheduled_task_execution_invokes_chargeable_action", "action": "pass_through_debit_to_user", "token_id": "C-ION", "amount_formula": "cost_of_triggered_action" } // e.g. if it triggers an LLM agent
  ],
  "techgnosis_integration": {
    "knowledge_graph_queries": [
      "find_optimal_time_slot_for_task_category:{{task_def_obj.category}}", // e.g. schedule non-urgent tasks for off-peak
      "get_user_preferences_for_reminder_delivery_channel:{{user_profile_cid}}" // If task is a reminder
    ],
    "natural_language_scheduling_parsing": true // User can say "remind me tomorrow at 9am to call X" - TechGnosis parses this into a task definition for Chronos.
  },
  "hybrid_layer_escalation_points": [
    { "condition": "recurring_task_fails_execution_N_consecutive_times", "action": "notify_user_and_escalate_to_hybrid_layer_for_investigation" },
    { "condition": "scheduled_task_attempts_to_trigger_action_without_valid_or_expired_ionwall_consent", "action": "block_execution_and_notify_user_for_re_consent" },
    { "condition": "conflicting_schedules_detected_for_high_priority_tasks", "action": "flag_for_user_or_hybrid_layer_resolution" }
  ],
  "carbon_loop_contribution": {
    "type": "schedule_optimization_for_carbon_efficiency",
    "value_formula": "number_of_tasks_shifted_to_low_carbon_intensity_periods * estimated_carbon_saved_per_task_shift",
    "description": "If integrated with real-time grid carbon intensity data (via another agent/plugin), Chronos can suggest or automatically shift non-critical tasks to periods of lower carbon emissions for their execution (especially if they trigger compute-intensive jobs)."
  }
}
```

### 3.8. `prm_details_json`
```json
{
  "scheduler_backend_preference": "IONFLUX_NativeScheduler_HighAvailability", // Could be "IONPOD_TaskList_Simple" for very basic needs
  "max_cron_frequency_allowed_minutes": 1, // Prevent too frequent schedules
  "default_task_priority": 5, // 1-10 scale
  "max_lookahead_for_scheduling_ui_days": 365,
  "timezone_management_default": "user_preference_from_ionpod_profile_or_utc",
  "payload_template_engine": "jinja2",
  "user_customizable_params_for_task_creation": [ // Fields in the task_definition object
    "schedule_type ('cron'|'datetime'|'delay')", "schedule_value",
    "target_type ('nats'|'webhook'|'agent_event')", "target_identifier",
    "payload_template_cid", "payload_params", "required_ionwall_scopes_for_action", "task_description"
  ]
}
```

### 3.9. `input_schema_json`
*(The JSON content of `input_schema` for `chronos_execute_scheduled_task_fluxgraph` from Section 2 is inserted here)*
```json
{
  "type": "object",
  "properties": {
    "task_id": { "type": "string", "description": "Unique ID of the scheduled task that is due." },
    "task_definition_cid": { "type": "string", "description": "CID of the IONPOD object containing the full task definition (target, payload, etc.)." }
  },
  "required": [ "task_id", "task_definition_cid" ]
}
```

### 3.10. `output_schema_json`
*(The JSON content of `output_schema` for `chronos_execute_scheduled_task_fluxgraph` from Section 2 is inserted here)*
```json
{
  "type": "object",
  "properties": {
    "task_id": { "type": "string" },
    "execution_status": { "type": "string", "enum": ["success", "failure", "action_triggered_no_response"] },
    "action_response_summary": { "type": "string", "nullable": true, "description": "Brief summary or ID from the triggered action, if available." },
    "error_message": { "type": "string", "nullable": true }
  },
  "required": [ "task_id", "execution_status" ]
}
```

### 3.11. `trigger_config_json`
```json
{
  "manual_trigger_enabled_for_execute_fluxgraph": false, # Execution should only be by internal scheduler
  "internal_scheduler_event_triggers": [
    {
      "event_filter_type": "chronos_task_due",
      "description": "Triggered by the IONFLUX native scheduler when a previously defined task is due for execution."
      # No input_mapping needed as the scheduler directly provides the required input_schema fields.
    }
  ],
  # For the "ManageScheduleFluxGraph", it would have NATS and Webhook triggers:
  "nats_triggers_for_management": [
    { "topic": "ionflux.agents.chronos.manage_task", "description": "Listen for commands to create, update, delete, list tasks. Payload specifies operation and task details."}
  ],
  "webhook_triggers_for_management": [
    { "endpoint_path": "/webhooks/chronos/manage_task", "http_method": "POST", "authentication_method": "ionwall_jwt_scoped_for_chronos_management", "description": "HTTP endpoint for task management." }
  ]
}
```

### 3.12. `deployment_info_json`
```json
{
  "runtime_environment": "IONFLUX_EdgeNode_Wasm_Or_ControllerService", # Scheduler might be a core service
  "current_instances_managed_by_ionflux_controller": true,
  "default_replicas_task_execution": 3, # For executing due tasks
  "default_replicas_task_management": 1, # For handling CRUD on schedules
  "auto_scaling_policy_task_execution": {
    "min_replicas": 1,
    "max_replicas": 10,
    "cpu_threshold_percentage": 70,
    "pending_task_queue_length_threshold": 100 # If scheduler emits to a queue Chronos reads from
  }
}
```

### 3.13. `logging_json`
```json
{
  "log_level": "info",
  "log_targets": ["ionpod_event_log_chronos", "local_stdout_dev_mode_only", "system_audit_trail_for_scheduler_actions"],
  "log_retention_policy_days": 90,
  "sensitive_fields_to_mask_in_log": ["task_def_obj.payload_params.api_key_if_any"]
}
```

### 3.14. `monitoring_json`
```json
{
  "metrics_to_collect": [
    "scheduled_tasks_count_total", "tasks_executed_count", "tasks_failed_execution_count", "tasks_missed_count",
    "task_execution_latency_avg_ms", "scheduler_queue_depth_if_applicable", "task_management_api_request_rate"
  ],
  "metrics_endpoint_ionwall_protected": "/metrics/chronos_task_agent",
  "health_check_protocol": "check_scheduler_service_health_and_task_definition_store_connectivity",
  "alerting_rules": [
    {"metric": "tasks_missed_count", "condition": "value > 5 for 1h", "severity": "critical", "notification_channel": "hybrid_layer_ops_pager"},
    {"metric": "tasks_failed_execution_count_high_priority", "condition": "value > 1 for 15m", "severity": "warning", "notification_channel": "hybrid_layer_ops_team_chat"}
  ]
}
```

### 3.15. `security_json`
```json
{
  "data_encryption_at_rest_ionpod": true,
  "data_encryption_in_transit_ipfs_ionwall": true,
  "scheduler_task_definition_access_control": "user_specific_via_ionpod_permissions_and_ionwall",
  "required_ionwall_consent_for_scheduled_actions": true, // Enforced by IONWALL_CheckStoredConsent_Transform
  "max_recursion_depth_for_scheduled_tasks": 1, // Prevent a task from scheduling itself in a tight loop, or limit chained schedules
  "permission_model_for_task_management_api": "owner_based_or_explicitly_delegated_via_ionwall_sharing",
  "required_ionwall_consent_scopes_for_chronos_itself": [ // Scopes Chronos needs for its own operation
    "read_pod_data:chronos_task_definitions", "read_pod_data:chronos_payload_templates",
    "write_pod_data:chronos_execution_logs", "manage_scheduler_tasks:chronos_agent_self",
    "check_stored_consent_for_scheduled_action:chronos_agent"
  ],
  "sensitive_data_handling_policy_id": "SDP-CHRONOS-001"
}
```

---
## 4. User Experience Flow (Conceptual)

1.  **Scheduling a Task (e.g., Daily Reminder Email):**
    *   User interacts with an IONFLUX UI (or another agent acting on user's behalf). They want a daily email reminder.
    *   UI/Agent prepares a task definition:
        *   `schedule_type: "cron"`, `schedule_value: "0 9 * * *"` (9 AM daily)
        *   `target_type: "agent_event"`, `target_identifier: "ionflux.agents.comm_link.send_message"`
        *   `payload_template_cid: "cid_of_email_reminder_template"`
        *   `payload_params: { recipient_cid: "user_profile_cid_with_email", subject: "Daily Reminder" }`
        *   `required_ionwall_scopes_for_action: ["read_pod_data:user_profile_cid_with_email", "send_communication:email"]` (scopes needed by Comm Link for this action)
    *   This task definition is sent to `Chronos Task Agent`'s management endpoint (e.g., NATS topic `ionflux.agents.chronos.manage_task` with operation `create`).
2.  **IONWALL Checkpoint (Task Creation & Future Action Consent):**
    *   IONWALL prompts User: *"Chronos Task Agent wants to:
        *   Schedule a daily task: 'Daily Reminder'.
        *   This task will, at 9 AM daily, trigger Comm Link Agent to send an email.
        *   To do this, Comm Link Agent will need permission to:
            *   Read contact details from '{{user_profile_cid_with_email.name}}'.
            *   Send an Email.
        Allow Chronos to schedule this task and grant these future permissions for its execution?"*
    *   (User might also be asked where to store the task definition CID in their IONPOD, or it's a default location).
3.  **Task Scheduled:**
    *   If approved, `Chronos Task Agent` (via its management FluxGraph and `SecureScheduler_ManageTask_Transform`) stores the task definition (gets a `task_definition_cid`) and registers it with the underlying scheduler with its `task_id`.
4.  **Task Execution (Next day at 9 AM):**
    *   The IONFLUX internal scheduler triggers `Chronos Task Agent`'s `chronos_execute_scheduled_task_fluxgraph` with the `task_id` and `task_definition_cid`.
    *   The execution FluxGraph runs:
        *   Fetches `task_def_obj` from IONPOD.
        *   `IONWALL_CheckStoredConsent_Transform` verifies the previously granted consent for the scopes like "send_communication:email" is still valid.
        *   Fetches and processes payload template.
        *   Publishes to `ionflux.agents.comm_link.send_message` with the payload for the email.
    *   `Comm Link Agent` receives this, and *its own* IONWALL checks for sending email are re-verified (usually cached if original consent from Chronos scheduling is still valid and specific enough). Email is sent.
5.  **Logging:** `Chronos Task Agent` logs the execution of the reminder task to the user's IONPOD.

---
## 5. TechGnosis & Hybrid Layer Integration Notes

*   **TechGnosis:**
    *   **Natural Language Scheduling:** A user could say/type "Remind me every Friday at 5 PM to submit my timesheet." TechGnosis (possibly via a dedicated "NLP Interface Agent") would parse this into a structured task definition that `Chronos Task Agent` can understand and schedule.
    *   **Task Optimization:** For tasks that are flexible (e.g., "process new data feeds sometime overnight"), TechGnosis could analyze system load patterns or user activity patterns from the knowledge graph to suggest optimal, less intrusive times for scheduling, or even adjust schedules dynamically if permitted.
    *   **Understanding Task Intent:** TechGnosis could help categorize tasks (e.g., "reminder", "data_processing", "system_maintenance") which could inform priority, error handling, or resource allocation.
*   **Hybrid Layer:**
    *   **Recurring Failures:** If a recurring scheduled task fails multiple consecutive times (e.g., the target NATS topic is no longer valid, or a webhook URL is consistently down), `Chronos Task Agent` escalates to the Hybrid Layer. A human can then investigate, notify the user, or manually adjust/disable the task.
    *   **Consent Expiry/Revocation:** If `IONWALL_CheckStoredConsent_Transform` finds that the consent granted when the task was scheduled is no longer valid (e.g., user revoked a specific permission), the task execution is blocked, and the user is notified via the Hybrid Layer to re-approve the task's permissions.
    *   **Conflicting Schedules:** For high-priority tasks, if Chronos (potentially with TechGnosis's help) detects a new task that would create a conflict or overload resources, it could flag this for user or Hybrid Layer resolution before confirming the schedule.

---
## 6. Carbon Loop Integration Notes

*   **Energy-Aware Scheduling:** If the IONFLUX ecosystem has access to real-time (or predictive) data about the carbon intensity of the underlying compute resources (e.g., edge nodes running on renewables vs. grid, or cloud regions with varying PUE/carbon intensity), `Chronos Task Agent` could:
    *   Allow users to mark tasks as "carbon-shiftable" (non-time-critical).
    *   Consult a "CarbonOracle Agent" (hypothetical) to find periods of lower carbon intensity.
    *   Shift the execution of these tasks to greener times, within user-defined constraints.
*   **Reducing Redundant Triggers:** By providing reliable scheduling, Chronos can help avoid less efficient methods like frequent polling by other agents, thus reducing overall system load and energy use.

---
## 7. Dependencies & Interactions

*   **Required Transforms (Core Chronos Logic - for `ExecuteScheduledTaskFluxGraph`):**
    *   `FetchFromIONPOD_Transform_IONWALL`
    *   `IONWALL_CheckStoredConsent_Transform` (Hypothetical, but crucial for consent validation at execution time)
    *   `TemplateProcessor_Transform_Jinja2`
    *   `SwitchCaseRouter_Transform`
    *   `IPC_NATS_Publish_Transform`
    *   `HTTP_Request_Transform_IONWALLProtected`
    *   `MergeResults_Transform`
    *   `StoreToIONPOD_Transform_IONWALL`
*   **Required Transforms (Core Chronos Logic - for `ManageScheduleFluxGraph`):**
    *   `SecureScheduler_ManageTask_Transform` (Hypothetical: an abstraction over the actual scheduling backend - could be interacting with a Kubernetes CronJob controller, a systemD timer, a robust DB-backed scheduler, or even a simple IONPOD-based list for basic scheduling).
*   **Interacting Agents (Conceptual):**
    *   Can be triggered by almost any agent (or user via UI) to schedule tasks.
    *   Triggers virtually any other agent or system accessible via NATS or Webhooks, as defined in the scheduled tasks. Examples:
        *   Triggers `Comm Link Agent` to send reminders.
        *   Triggers `Datascribe Transcript Agent` to process new media files found by a scheduled `IONPOD_Query_Agent`.
        *   Triggers `Muse Prompt Chain Agent` for scheduled content generation.
*   **External Systems (via Transforms actions scheduled):**
    *   Any system reachable by an HTTP POST (via `HTTP_Request_Transform_IONWALLProtected`).
    *   Any system integrated via NATS messages.

---
## 8. Open Questions & Future Considerations

*   **Scheduler Backend Robustness:** The actual implementation of the scheduling mechanism (`SecureScheduler_ManageTask_Transform` abstraction) is critical. Needs to be persistent, reliable, and scalable. Options:
    *   Leverage underlying OS/platform capabilities (Kubernetes CronJobs, systemd timers).
    *   Use a distributed scheduling library (e.g., based on Raft/Paxos for HA).
    *   Simple IONPOD-based list for very basic, non-critical, single-node deployments.
*   **Time Zone Management:** Handling time zones consistently for scheduling and execution across distributed users and nodes. Storing schedules in UTC and converting to/from user's local time is standard.
*   **Missed Task Handling ("Catch-up"):** If an agent or node is down when a task was due, what happens when it comes back up? Policy for running missed tasks (e.g., run immediately, skip, run N missed instances).
*   **Complex Recurrence Patterns:** Beyond cron, support for more complex patterns (e.g., "every third Tuesday", "2 days after event X if before 5 PM"). This might require a more sophisticated scheduling library/DSL.
*   **Task Versioning & Updates:** How are updates to a scheduled task's definition (e.g., changing the payload template) handled? Does it create a new version of the task?
*   **UI for Schedule Management:** A user-friendly interface within IONFLUX for users to view their scheduled tasks, see execution history, create new ones (perhaps with natural language input via TechGnosis), and manage existing ones.
*   **Distributed Scheduler & Lock Management:** If multiple Chronos instances can pick tasks, ensuring a task is executed only once (distributed locking if scheduler backend isn't already HA).
*   **Permissions for Scheduling:** What prevents an agent from scheduling a task to make another agent do something malicious? The IONWALL consent model at scheduling time, plus re-validation at execution time, is key.
