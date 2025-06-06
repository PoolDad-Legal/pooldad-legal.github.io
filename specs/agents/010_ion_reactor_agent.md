# Agent Blueprint: ION Reactor Agent - v0.9.0

## 1. Overview

*   **Agent Name:** `ION Reactor Agent`
*   **Version:** `0.9.0`
*   **Status:** `development`
*   **Primary Goal:** `Acts as a high-level orchestrator and system management agent within the user's IONFLUX space. It manages agent lifecycles (conceptually deploying, updating, or retiring agents based on definitions from IONPOD and user policies), monitors overall system health, responds to critical IONFLUX ecosystem events, and executes complex, multi-agent workflows defined as "master plans" or "symphonies."`
*   **Key Features:**
    *   **Workflow Orchestration:** Executes "Master Plans" (complex workflows involving sequences and dependencies of other agents' tasks) defined as structured objects in IONPOD.
    *   **Agent Lifecycle Management (Conceptual):** Can request the IONFLUX Controller (via specialized, high-privilege transforms) to:
        *   Deploy new agent instances from `agent_definitions` stored in IONPOD.
        *   Update existing agent instances when new versions of their definitions become available (subject to user policies and IONWALL consent).
        *   Retire (deactivate or undeploy) agent instances.
    *   **System Monitoring & Response:** Listens to critical system-level events, monitors key performance indicators (KPIs) or health metrics from other agents or the IONFLUX environment.
    *   **Emergency Response:** Can trigger predefined emergency response plans (which are themselves Master Plans) if critical system issues are detected (e.g., widespread agent failures, security alerts from Guardian).
    *   **Escalation:** Escalates unresolvable issues or critical decisions to the Hybrid Layer or directly to the user via `Comm Link Agent`.
    *   **High Trust Operation:** Operates with a high degree of trust and capability within the user's sNetwork, but all its significant actions (especially those affecting other agents or system configuration) are still subject to IONWALL oversight and user consent, particularly for initial setup and granting of powerful permissions.

## 2. FluxGraph Definition (Conceptual YAML)

```yaml
# /specs/agents/ion_reactor_agent_fluxgraph.yaml (Conceptual representation)
# The ION Reactor Agent would likely have several distinct FluxGraphs for its varied responsibilities.
# We'll detail one for "execute_master_plan" and briefly outline others.

# FluxGraph 1: Execute Master Plan
version: "0.1.0"
name: "ion_reactor_execute_master_plan_fluxgraph"
description: "Fetches, parses, and executes a multi-agent workflow (Master Plan) from IONPOD."

triggers:
  - type: "manual" # User directly requests execution of a plan
  - type: "event_driven"
    config: { event_source: "NATS", topic: "ionflux.reactor.execute_master_plan" } # Another agent or system process triggers a plan
  - type: "webhook"
    config: { path: "/webhooks/invoke/reactor_execute_plan", method: "POST", authentication_method: "ionwall_jwt" }

input_schema:
  type: "object"
  properties:
    master_plan_cid: { type: "string", description: "CID of the Master Plan definition object in IONPOD." }
    plan_parameters_cid: { type: "string", nullable: true, description: "Optional CID of an object containing runtime parameters for this plan execution." }
    execution_mode: { type: "string", enum: ["run_all", "step_through_debug", "dry_run_validate_only"], default: "run_all" }
  required: [ "master_plan_cid" ]

output_schema: # Output for the overall plan execution
  type: "object"
  properties:
    master_plan_cid: { type: "string" }
    execution_id: { type: "string", description: "Unique ID for this specific execution run of the plan." }
    overall_status: { type: "string", enum: ["success", "failure", "partial_success_with_errors", "cancelled"] }
    step_results_summary_cid: { type: "string", nullable: true, description: "CID of an IONPOD object logging the status and outputs of each step in the plan." }
    error_details: { type: "array", items: {type: "object"}, nullable: true, description: "Details of any errors encountered during execution."}
  required: [ "master_plan_cid", "execution_id", "overall_status" ]

graph:
  - id: "fetch_master_plan_definition"
    transform: "FetchFromIONPOD_Transform_IONWALL"
    ionwall_approval_scope: "read_pod_data:reactor_master_plans"
    inputs:
      cid: "{{trigger.input_data.master_plan_cid}}"
    outputs: [master_plan_obj] # Contains { name, description, version, steps: [{ step_id, agent_to_call, input_mapping, dependencies, ... }] }

  - id: "fetch_plan_parameters_conditional"
    transform: "FetchFromIONPOD_Transform_IONWALL"
    if: "{{trigger.input_data.plan_parameters_cid != null}}"
    ionwall_approval_scope: "read_pod_data:reactor_plan_parameters"
    inputs:
      cid: "{{trigger.input_data.plan_parameters_cid}}"
    outputs: [plan_parameters_obj]

  # This is the core orchestration logic. It's highly conceptual and would require a sophisticated transform
  # or native FluxGraph engine capabilities for looping, conditionals, parallel execution, and error handling based on the master_plan_obj.
  - id: "execute_workflow_steps"
    transform: "MasterPlanExecutor_Transform_IONFLUXController" # Hypothetical, high-privilege transform
    # This transform would:
    # 1. Parse master_plan_obj.steps.
    # 2. For each step:
    #    a. Resolve input data (from previous steps, plan_parameters_obj, or fixed values).
    #    b. Construct the invocation message for the target agent (e.g., NATS message, HTTP request).
    #    c. Invoke the target agent (potentially using CommLinkAgent_Invoke_Transform or direct IPC_NATS_Publish_Transform / HTTP_Request_Transform).
    #       - IONWALL consent for each sub-agent call is critical. The MasterPlan itself must have declared needed scopes,
    #         and Reactor Agent must have been granted rights to invoke these scopes on behalf of the user.
    #    d. Monitor for completion/failure of the sub-agent task.
    #    e. Handle dependencies between steps.
    #    f. Log status of each step.
    ionwall_approval_scope: "execute_master_plan:{{trigger.input_data.master_plan_cid}}" # Reactor needs broad scope, with specifics defined in the plan.
    inputs:
      plan_definition: "{{nodes.fetch_master_plan_definition.outputs.master_plan_obj}}"
      runtime_parameters: "{{nodes.fetch_plan_parameters_conditional.outputs.plan_parameters_obj}}"
      execution_mode: "{{trigger.input_data.execution_mode}}"
      # It would need access to invoke other agents, potentially via specific invoke transforms or NATS.
      # It also needs a way to query the IONFLUX Controller for agent status or to request actions.
    outputs: [overall_plan_execution_status, step_results_log_obj, plan_error_details_array]

  - id: "store_step_results_summary"
    transform: "StoreToIONPOD_Transform_IONWALL"
    if: "{{nodes.execute_workflow_steps.outputs.step_results_log_obj != null}}"
    ionwall_approval_scope: "write_pod_data:reactor_plan_execution_logs"
    inputs:
      data_to_store: "{{nodes.execute_workflow_steps.outputs.step_results_log_obj}}"
      filename_suggestion: "plan_exec_summary_{{trigger.input_data.master_plan_cid}}_{{system.timestamp_utc_iso}}.json"
    outputs: [stored_summary_cid]

  - id: "publish_plan_completion_event"
    transform: "IPC_NATS_Publish_Transform"
    inputs:
      topic: "ionflux.reactor.execute_master_plan.completion"
      message: # This is the output_schema of this FluxGraph
        master_plan_cid: "{{trigger.input_data.master_plan_cid}}"
        execution_id: "{{nodes.execute_workflow_steps.outputs.execution_id}}" # Assuming executor generates a unique ID
        overall_status: "{{nodes.execute_workflow_steps.outputs.overall_plan_execution_status}}"
        step_results_summary_cid: "{{nodes.store_step_results_summary.outputs.stored_summary_cid}}"
        error_details: "{{nodes.execute_workflow_steps.outputs.plan_error_details_array}}"
    dependencies: [store_step_results_summary]

# Other Conceptual FluxGraphs for ION Reactor Agent:
# - Name: "ion_reactor_manage_agent_lifecycle_fluxgraph"
#   Description: "Handles requests to deploy, update, or retire agents."
#   Triggers: NATS (e.g., ionflux.reactor.manage_agent), User UI action.
#   Input: { operation: "deploy|update|retire", agent_definition_cid: "...", agent_id_to_update_or_retire: "..." }
#   Graph: Fetches agent_def, validates, then uses "IONFLUXController_Admin_Transform" to request action from the sNetwork controller. Requires high privileges.
#
# - Name: "ion_reactor_monitor_system_health_fluxgraph"
#   Description: "Periodically checks system health metrics or listens for critical alerts."
#   Triggers: Scheduled (via Chronos), NATS (e.g., ionflux.system.critical_alert from Guardian).
#   Graph: Fetches metrics (from Monitoring Agent or direct system queries), evaluates against thresholds,
#          if issue detected: triggers CommLink alert, or invokes an emergency Master Plan.
```

---
## 3. Database Schema Fields (`agent_definitions` table)

### 3.1. `agent_name`
`"ION Reactor Agent"`

### 3.2. `version`
`"0.9.0"`

### 3.3. `description`
`"Acts as a high-level orchestrator and system management agent. Manages agent lifecycles, monitors system health, responds to critical events, and executes complex multi-agent workflows ('Master Plans')."`

### 3.4. `status`
`"development"`

### 3.5. `flux_graph_dsl_yaml`
*(The YAML content for `ion_reactor_execute_master_plan_fluxgraph` from Section 2 is inserted here. Other FluxGraphs for lifecycle management or health monitoring would ideally be part of this agent's definition or separate, linked agent definitions if they become very complex.)*
```yaml
version: "0.1.0"
name: "ion_reactor_execute_master_plan_fluxgraph"
description: "Fetches, parses, and executes a multi-agent workflow (Master Plan) from IONPOD."

triggers:
  - type: "manual"
  - type: "event_driven"
    config: { event_source: "NATS", topic: "ionflux.reactor.execute_master_plan" }
  - type: "webhook"
    config: { path: "/webhooks/invoke/reactor_execute_plan", method: "POST", authentication_method: "ionwall_jwt" }

input_schema:
  type: "object"
  properties:
    master_plan_cid: { type: "string", description: "CID of the Master Plan definition object in IONPOD." }
    plan_parameters_cid: { type: "string", nullable: true, description: "Optional CID of an object containing runtime parameters." }
    execution_mode: { type: "string", enum: ["run_all", "step_through_debug", "dry_run_validate_only"], default: "run_all" }
  required: [ "master_plan_cid" ]

output_schema:
  type: "object"
  properties:
    master_plan_cid: { type: "string" }
    execution_id: { type: "string", description: "Unique ID for this specific execution run." }
    overall_status: { type: "string", enum: ["success", "failure", "partial_success_with_errors", "cancelled"] }
    step_results_summary_cid: { type: "string", nullable: true, description: "CID of an IONPOD object logging step statuses." }
    error_details: { type: "array", items: {type: "object"}, nullable: true, description: "Details of any errors."}
  required: [ "master_plan_cid", "execution_id", "overall_status" ]

graph:
  - id: "fetch_master_plan_definition"
    transform: "FetchFromIONPOD_Transform_IONWALL"
    ionwall_approval_scope: "read_pod_data:reactor_master_plans"
    inputs:
      cid: "{{trigger.input_data.master_plan_cid}}"
    outputs: [master_plan_obj]

  - id: "fetch_plan_parameters_conditional"
    transform: "FetchFromIONPOD_Transform_IONWALL"
    if: "{{trigger.input_data.plan_parameters_cid != null}}"
    ionwall_approval_scope: "read_pod_data:reactor_plan_parameters"
    inputs:
      cid: "{{trigger.input_data.plan_parameters_cid}}"
    outputs: [plan_parameters_obj]

  - id: "execute_workflow_steps"
    transform: "MasterPlanExecutor_Transform_IONFLUXController"
    ionwall_approval_scope: "execute_master_plan:{{trigger.input_data.master_plan_cid}}"
    inputs:
      plan_definition: "{{nodes.fetch_master_plan_definition.outputs.master_plan_obj}}"
      runtime_parameters: "{{nodes.fetch_plan_parameters_conditional.outputs.plan_parameters_obj}}"
      execution_mode: "{{trigger.input_data.execution_mode}}"
    outputs: [overall_plan_execution_status, step_results_log_obj, plan_error_details_array, execution_id]

  - id: "store_step_results_summary"
    transform: "StoreToIONPOD_Transform_IONWALL"
    if: "{{nodes.execute_workflow_steps.outputs.step_results_log_obj != null}}"
    ionwall_approval_scope: "write_pod_data:reactor_plan_execution_logs"
    inputs:
      data_to_store: "{{nodes.execute_workflow_steps.outputs.step_results_log_obj}}"
      filename_suggestion: "plan_exec_summary_{{trigger.input_data.master_plan_cid}}_{{system.timestamp_utc_iso}}.json"
    outputs: [stored_summary_cid]

  - id: "publish_plan_completion_event"
    transform: "IPC_NATS_Publish_Transform"
    inputs:
      topic: "ionflux.reactor.execute_master_plan.completion"
      message:
        master_plan_cid: "{{trigger.input_data.master_plan_cid}}"
        execution_id: "{{nodes.execute_workflow_steps.outputs.execution_id}}"
        overall_status: "{{nodes.execute_workflow_steps.outputs.overall_plan_execution_status}}"
        step_results_summary_cid: "{{nodes.store_step_results_summary.outputs.stored_summary_cid}}"
        error_details: "{{nodes.execute_workflow_steps.outputs.plan_error_details_array}}"
    dependencies: [store_step_results_summary]
```

### 3.6. `execution_requirements_json`
```json
{
  "transforms_required": [
    "FetchFromIONPOD_Transform_IONWALL",
    "MasterPlanExecutor_Transform_IONFLUXController", // Hypothetical, core to this agent
    "StoreToIONPOD_Transform_IONWALL",
    "IPC_NATS_Publish_Transform",
    // For other functionalities (agent lifecycle, monitoring):
    "IONFLUXController_Admin_Transform", // Hypothetical, high-privilege
    "SystemMonitoring_Query_Transform" // Hypothetical
  ],
  "min_ram_mb": 1024, // Orchestration and state management for complex plans can be demanding
  "gpu_required": false, // Unless master plans themselves involve GPU-heavy agents and Reactor needs to co-locate
  "estimated_execution_duration_seconds": 0, // Highly variable, depends on the Master Plan being executed
  "max_concurrent_instances": 2, // Usually low, as it's a central orchestrator. HA might be achieved differently.
  "wasm_modules_cids": {
    "FetchFromIONPOD_Transform_IONWALL": "bafyreibvlobj2rl34gsgxrjltirqesqkfbhtharb3uaxnri3ebpmpah6ce",
    "MasterPlanExecutor_Transform_IONFLUXController": "bafyreigxkogzvtykvvwb6v5odxmyyhpce7t6wnolfyefivp7dwxiseqhiy", // Placeholder
    "StoreToIONPOD_Transform_IONWALL": "bafyreif7yqivqtkjhhwb5xkxqj3j7gyjlrvfkhhvjvbfffj4u7m5kfefbi",
    "IPC_NATS_Publish_Transform": "bafyreihyrz7wgld5qrjmejbdjcbcm3jqrjshxphu6jnlxhnlfbk7d745xy",
    "IONFLUXController_Admin_Transform": "bafyreihaltmsv4s7kaxylvn7eekxcqoeqrl7qyfrqkcoq3qjrjsw7xjxhm", // Placeholder - CRITICAL
    "SystemMonitoring_Query_Transform": "bafyreibaxwmyujl2xazb575s7kccxqzqj3j7gyjlrfkhhvjvbfffnmqpde" // Placeholder
  }
}
```

### 3.7. `ecosystem_integration_points_json`
```json
{
  "ionwall_permissions_needed": [
    "read_pod_data:reactor_master_plans", // To fetch plan definitions
    "read_pod_data:reactor_plan_parameters", // To fetch runtime parameters for plans
    "read_pod_data:reactor_agent_definitions_for_lifecycle_mgmnt", // To read agent defs it might deploy/update
    "write_pod_data:reactor_plan_execution_logs",
    "write_pod_data:reactor_system_health_reports",
    // CRITICAL & BROAD SCOPES - these require significant user trust and careful Hybrid Layer oversight policies:
    "execute_master_plan:*", // Wildcard, or scope per plan CID. Allows Reactor to invoke other agents as defined in any plan.
    "invoke_ionflux_controller_admin_actions:manage_agent_lifecycle", // For deploy/update/retire agents
    "read_system_monitoring_data:all_agents_or_specific_groups", // For health monitoring
    "publish_nats_topic:ionflux_reactor_all_notifications" // Broad publish for its events
  ],
  "ionpod_data_access": {
    "inputs": [
      { "cid_pattern": "master_plans/*.json", "access_type": "read", "purpose": "To load Master Plan definitions for execution." },
      { "cid_pattern": "agent_definitions_catalog/*.json", "access_type": "read", "purpose": "To load agent definitions for lifecycle management."}
    ],
    "outputs": [
      { "path_pattern": "reactor_logs/plan_executions/*.json", "access_type": "write", "purpose": "To store detailed logs of Master Plan executions." },
      { "path_pattern": "reactor_logs/system_health/*.json", "access_type": "write", "purpose": "To store system health reports or snapshots." }
    ]
  },
  "tokenomic_triggers": [
    { "event": "master_plan_successful_execution_complex", "action": "reward_user_ion_for_orchestration_setup", "token_id": "$ION", "amount_formula": "0.01 * number_of_steps_in_plan * avg_complexity_of_steps" },
    { "event": "ionflux_controller_admin_action_invoked_for_agent_lifecycle", "action": "debit_user_system_management_fee", "token_id": "C-ION", "amount_formula": "0.05" } // For high-privilege operations
  ],
  "techgnosis_integration": {
    "knowledge_graph_queries": [
      "validate_master_plan_dependencies_and_agent_compatibility:{{nodes.fetch_master_plan_definition.outputs.master_plan_obj}}", // Before execution
      "get_optimal_agent_instance_for_task:{{step.agent_to_call_type}},{{step.required_resources}}", // If multiple instances of an agent type exist
      "predict_potential_bottlenecks_or_failures_in_master_plan:{{nodes.fetch_master_plan_definition.outputs.master_plan_obj}}"
    ],
    "master_plan_generation_assistance": true, // TechGnosis could help users construct valid and efficient Master Plans from high-level goals.
    "automated_recovery_path_suggestion_for_failed_plan_step": true // If a step fails, TechGnosis suggests alternatives.
  },
  "hybrid_layer_escalation_points": [
    { "condition": "critical_step_in_master_plan_fails_repeatedly_and_no_automated_recovery_path_succeeds", "action": "pause_plan_and_escalate_to_hybrid_layer_system_operator_for_manual_intervention" },
    { "condition": "request_to_deploy_agent_with_known_security_vulnerability_or_from_untrusted_source", "action": "block_deployment_and_escalate_to_hybrid_layer_security_review" },
    { "condition": "system_wide_instability_detected_or_cascading_failures_imminent", "action": "trigger_emergency_shutdown_or_safe_mode_master_plan_requiring_hybrid_layer_confirmation_if_possible_else_act_autonomously_if_pre_authorized_for_catastrophe" }
  ],
  "carbon_loop_contribution": {
    "type": "orchestration_for_snetwork_energy_efficiency",
    "value_formula": "total_compute_saved_by_optimized_workflow_execution_order_and_resource_allocation * carbon_value_per_compute_unit_saved",
    "description": "By intelligently orchestrating multi-agent workflows (Master Plans), the ION Reactor can optimize the order of operations, co-locate dependent agents on the same efficient hardware, or schedule resource-intensive parts of a plan during low carbon intensity periods. This requires sophisticated integration with TechGnosis and potentially Chronos Agent."
  }
}
```

### 3.8. `prm_details_json`
```json
{
  "default_master_plan_repository_cid": "bafk... (CID of user's preferred IONPOD folder for Master Plans)",
  "default_agent_definition_catalog_cid": "bafk... (CID of user's or sNetwork's official agent definitions)",
  "max_master_plan_recursion_depth": 3, // A plan calling another plan
  "global_timeout_for_master_plan_execution_hours": 24,
  "default_error_handling_strategy_for_plan_steps": "retry_once_then_fail_step_and_escalate", // "continue_plan_on_step_failure_if_independent"
  "system_health_check_interval_minutes_if_cron_driven": 15,
  "user_customizable_params_for_master_plan_execution": [ // Fields from input_schema
    "master_plan_cid", "plan_parameters_cid", "execution_mode"
  ]
}
```

### 3.9. `input_schema_json`
*(The JSON content of `input_schema` for `ion_reactor_execute_master_plan_fluxgraph` from Section 2 is inserted here)*
```json
{
  "type": "object",
  "properties": {
    "master_plan_cid": { "type": "string", "description": "CID of the Master Plan definition object in IONPOD." },
    "plan_parameters_cid": { "type": "string", "nullable": true, "description": "Optional CID of an object containing runtime parameters for this plan execution." },
    "execution_mode": { "type": "string", "enum": ["run_all", "step_through_debug", "dry_run_validate_only"], "default": "run_all" }
  },
  "required": [ "master_plan_cid" ]
}
```

### 3.10. `output_schema_json`
*(The JSON content of `output_schema` for `ion_reactor_execute_master_plan_fluxgraph` from Section 2 is inserted here)*
```json
{
  "type": "object",
  "properties": {
    "master_plan_cid": { "type": "string" },
    "execution_id": { "type": "string", "description": "Unique ID for this specific execution run of the plan." },
    "overall_status": { "type": "string", "enum": ["success", "failure", "partial_success_with_errors", "cancelled"] },
    "step_results_summary_cid": { "type": "string", "nullable": true, "description": "CID of an IONPOD object logging the status and outputs of each step in the plan." },
    "error_details": { "type": "array", "items": { "type": "object" }, "nullable": true, "description": "Details of any errors encountered during execution."}
  },
  "required": [ "master_plan_cid", "execution_id", "overall_status" ]
}
```

### 3.11. `trigger_config_json`
```json
{
  "manual_trigger_enabled": true, // For Execute Master Plan
  "event_driven_triggers": [
    {
      "event_source": "NATS",
      "topic": "ionflux.reactor.execute_master_plan",
      "description": "Trigger to execute a defined Master Plan. Payload matches input_schema for Execute Master Plan FluxGraph.",
      "input_mapping_jmespath": "payload"
    },
    {
      "event_source": "NATS",
      "topic": "ionflux.reactor.manage_agent_lifecycle",
      "description": "Trigger for agent lifecycle operations. Payload specifies operation, agent_def_cid, etc."
      // "target_fluxgraph_id": "ion_reactor_manage_agent_lifecycle_fluxgraph" // If using multiple named FluxGraphs within one agent def
    },
    {
      "event_source": "NATS",
      "topic": "ionflux.system.critical_alert", # From Guardian or other monitoring
      "description": "Trigger for system health monitoring and response FluxGraph."
      // "target_fluxgraph_id": "ion_reactor_monitor_system_health_fluxgraph"
    }
  ],
  "webhook_triggers": [
     {
      "endpoint_path": "/webhooks/invoke/reactor/execute_plan",
      "http_method": "POST",
      "authentication_method": "ionwall_jwt_scoped_for_reactor_master_plan_execution",
      "description": "HTTP endpoint to trigger Master Plan execution."
    },
    {
      "endpoint_path": "/webhooks/invoke/reactor/manage_agent",
      "http_method": "POST",
      "authentication_method": "ionwall_jwt_scoped_for_reactor_lifecycle_management",
      "description": "HTTP endpoint for agent lifecycle operations."
    }
  ],
  "scheduled_triggers_by_chronos_cid": [ // If Reactor's monitoring is periodic
    // CID of a Chronos Task definition that triggers ion_reactor_monitor_system_health_fluxgraph
    "bafk..."
  ]
}
```

### 3.12. `deployment_info_json`
```json
{
  "runtime_environment": "IONFLUX_ControllerNode_HighAvailability", // Needs to be robust and potentially co-located with controller functions
  "current_instances_managed_by_ionflux_controller": true,
  "default_replicas": 1, // Often a singleton for orchestration to avoid conflicting actions, HA via controller failover
  "auto_scaling_policy": {
    "min_replicas": 1, "max_replicas": 1, // Singleton behavior
    "custom_failover_strategy_id": "controller_managed_active_passive"
  }
}
```

### 3.13. `logging_json`
```json
{
  "log_level": "info",
  "log_targets": ["ionpod_event_log_reactor", "system_audit_trail_orchestration_and_lifecycle", "local_stdout_dev_mode_only"],
  "log_retention_policy_days_reactor": 120,
  "sensitive_fields_to_mask_in_log": ["plan_parameters_obj.secret_values", "master_plan_obj.step_credentials_if_any_bad_practice"]
}
```

### 3.14. `monitoring_json`
```json
{
  "metrics_to_collect": [
    "master_plans_executed_count", "master_plans_successful_count", "master_plans_failed_count",
    "avg_master_plan_duration_ms", "avg_steps_per_master_plan",
    "agent_lifecycle_actions_count_deploy_update_retire",
    "system_health_status_current", // A summary metric it might maintain
    "critical_events_responded_to_count"
  ],
  "metrics_endpoint_ionwall_protected": "/metrics/ion_reactor_agent",
  "health_check_protocol": "check_connectivity_to_ionflux_controller_and_core_services_like_nats_ionpod",
  "alerting_rules": [
    {"metric": "master_plans_failed_critical_count", "condition": "value > 0 for 1h", "severity": "critical", "notification_channel": "hybrid_layer_ops_pager_reactor_plan_failure"},
    {"metric": "ionflux_controller_admin_transform_error_rate", "condition": "value > 0.05 for 30m", "severity": "critical", "notification_channel": "hybrid_layer_ops_pager_controller_integration_issue"}
  ]
}
```

### 3.15. `security_json`
```json
{
  "data_encryption_at_rest_ionpod": true,
  "data_encryption_in_transit_ipfs_ionwall": true,
  "master_plan_security_validation_transform_cid": "bafk... (Optional CID of a transform that validates Master Plan for security issues before execution, e.g. excessive permissions requested)",
  "ionflux_controller_communication_protocol_security_level": "mutual_tls_and_signed_requests_enforced",
  "principle_of_least_privilege_for_master_plan_execution": true, // Reactor requests only the *specific* broad scopes declared in the Master Plan for that execution.
  "required_ionwall_consent_scopes_for_reactor_agent_itself": [
    // These are the foundational permissions Reactor needs. More granular permissions for what plans *do* are consented at plan execution time.
    "read_pod_data:reactor_master_plans", "read_pod_data:reactor_plan_parameters", "read_pod_data:reactor_agent_definitions_for_lifecycle_mgmnt",
    "write_pod_data:reactor_plan_execution_logs", "write_pod_data:reactor_system_health_reports",
    "publish_nats_topic:ionflux_reactor_all_notifications",
    // The following are extremely powerful and must be granted with utmost caution, likely during sNetwork setup by the owner.
    "execute_master_plan:*", // Allows it to orchestrate any plan. Could be narrowed.
    "invoke_ionflux_controller_admin_actions:manage_agent_lifecycle", // Allows it to manage other agents.
    "read_system_monitoring_data:all_agents_or_specific_groups" // For health monitoring.
  ],
  "sensitive_data_handling_in_master_plans_policy_id": "SDP-REACTOR-001"
}
```

---
## 4. User Experience Flow (Conceptual)

**Scenario: User wants to run a "Publish Daily Digest" Master Plan.**
1.  **Initiation:** User, via IONFLUX UI, selects the "Publish Daily Digest" Master Plan (which has a known `master_plan_cid`) and clicks "Execute". They might provide runtime parameters (e.g., `plan_parameters_cid` pointing to `{ "target_audience_segment": "subscribers_group_A" }`).
2.  **IONWALL Checkpoint (Master Plan Orchestration Consent):**
    *   IONWALL prompts User: *"ION Reactor Agent wants to execute Master Plan: 'Publish Daily Digest'.
        *   This plan will orchestrate several agents (e.g., DataQueryAgent, MuseAgent for summarization, CommLinkAgent for email distribution).
        *   It requires permissions to: [List of aggregated permissions derived from the Master Plan's definition - e.g., read specific data sources, invoke LLMs, send emails].
        *   Read Master Plan 'Publish Daily Digest' from your IONPOD.
        *   (If params CID provided) Read Plan Parameters '{{plan_parameters_cid.name}}' from your IONPOD.
        *   Store execution logs for this plan to your IONPOD.
        Allow ION Reactor Agent to orchestrate this plan with these permissions?"*
3.  **Execution (by `MasterPlanExecutor_Transform`):**
    *   If User approves, `ION Reactor Agent` fetches the plan and parameters.
    *   The `MasterPlanExecutor_Transform` starts:
        *   **Step 1 (e.g., Query Data):** Reactor invokes `DataQueryAgent` with parameters from the plan/runtime_params. Waits for completion and `queried_data_cid`. (Each such sub-invocation is implicitly covered by the overall plan consent, but IONWALL still tracks it).
        *   **Step 2 (e.g., Summarize Data):** Reactor invokes `Muse Prompt Chain Agent` with `queried_data_cid` and a `prompt_chain_def_cid` for summarization. Waits for `summary_cid`.
        *   **Step 3 (e.g., Send Digest):** Reactor invokes `Comm Link Agent` with `summary_cid`, a `template_cid` for the digest email, and `target_audience_segment` to get recipient list.
    *   Executor monitors progress, handles errors per plan's strategy (e.g., retry step, skip, halt plan).
4.  **Logging & Completion:**
    *   `ION Reactor Agent` (via the Executor transform) logs the status of each step and the overall plan outcome to IONPOD.
    *   Publishes a NATS event (`ionflux.reactor.execute_master_plan.completion`) with the overall status and a CID to the detailed log.
    *   User's UI updates to show the "Publish Daily Digest" plan is complete (or failed, with error details).

---
## 5. TechGnosis & Hybrid Layer Integration Notes

*   **TechGnosis:**
    *   **Master Plan Validation & Optimization:** Before execution, a Master Plan definition can be passed to TechGnosis to:
        *   Validate dependencies between steps (e.g., ensure `Agent B` correctly uses outputs from `Agent A`).
        *   Check compatibility of agent versions specified in the plan.
        *   Suggest optimizations (e.g., reordering steps for efficiency, identifying possibilities for parallel execution).
    *   **Dynamic Agent Selection:** If a plan step specifies an agent type (e.g., "any summarization agent") rather than a specific `agent_id`, TechGnosis can select the most appropriate, available, and resource-efficient agent instance at runtime based on current system state and agent capabilities in its KG.
    *   **Predictive Monitoring:** By analyzing past plan executions and current system load (from KG), TechGnosis could predict potential bottlenecks or failures in an upcoming Master Plan execution, allowing Reactor to take preemptive action (e.g., alert user, request more resources).
*   **Hybrid Layer:**
    *   **Critical Plan Step Failures:** If a critical step in a Master Plan fails and automated retries/error handling within the plan are exhausted, `ION Reactor Agent` escalates to the Hybrid Layer. A human operator can then investigate the specific failed agent/step, manually intervene (e.g., fix input data, restart a component), and instruct Reactor to resume, retry, or abort the plan.
    *   **Agent Lifecycle Approvals:** For significant lifecycle actions (e.g., deploying a new agent from an untrusted source, auto-updating a critical agent to a new major version), Reactor's request to the IONFLUX Controller could first require Hybrid Layer approval, even if the user granted initial broad permissions.
    *   **Emergency Response Confirmation:** If Reactor detects a severe system issue and decides to trigger an emergency Master Plan (e.g., "safe_mode_data_lockdown"), it might require a confirmation from a human operator via the Hybrid Layer before initiating such drastic actions, unless pre-authorized for fully autonomous catastrophic response.

---
## 6. Carbon Loop Integration Notes

*   **Workflow Optimization for Energy Efficiency:** `ION Reactor Agent`, especially when guided by TechGnosis, can orchestrate Master Plans in a way that minimizes overall energy consumption. This could involve:
    *   Sequencing tasks to maximize reuse of already loaded data or warmed-up agent instances.
    *   Co-locating data-intensive communicating agents on the same physical node (if sNetwork topology allows such influence) to reduce network data transfer.
    *   Scheduling resource-intensive, non-urgent Master Plans (or parts thereof) during periods of high renewable energy availability or low overall grid carbon intensity, by integrating with `Chronos Task Agent` and a "CarbonOracleAgent".
*   **Agent Deployment for Efficiency:** When requesting deployment of new agent instances as part of a plan, Reactor could specify preferences for deployment on nodes known for energy efficiency, if such metadata is available.

---
## 7. Dependencies & Interactions

*   **Required Transforms (Core Reactor Logic):**
    *   `FetchFromIONPOD_Transform_IONWALL` (for plans, params, agent definitions)
    *   `MasterPlanExecutor_Transform_IONFLUXController` (hypothetical, core orchestration engine)
    *   `StoreToIONPOD_Transform_IONWALL` (for logging)
    *   `IPC_NATS_Publish_Transform` (for its own events and triggering other agents)
    *   `IONFLUXController_Admin_Transform` (hypothetical, for agent lifecycle management - high privilege)
    *   `SystemMonitoring_Query_Transform` (hypothetical, for health checks)
    *   Potentially `CommLinkAgent_Invoke_Transform` for direct notifications if not using NATS.
*   **Interacting Agents (Conceptual):**
    *   Can invoke **any** other IONFLUX agent as defined in a Master Plan.
    *   Interacts with `IONFLUX Controller` (not an agent, but the underlying platform manager) via `IONFLUXController_Admin_Transform` for lifecycle operations.
    *   Listens to events from `Guardian Compliance Agent` (e.g., critical security alerts) or other monitoring agents.
    *   May use `Chronos Task Agent` to schedule execution of Master Plans or its own monitoring tasks.
    *   Relies on `TechGnosis Agent` for advanced plan validation, optimization, and dynamic decision-making.
    *   Escalates to/interacts with the `Hybrid Layer` system for human intervention.
*   **External Systems:**
    *   None directly, but agents it orchestrates might interact with external systems (e.g., via `Symbiosis Plugin Agent`).

---
## 8. Open Questions & Future Considerations

*   **Master Plan Definition Standard:** A robust, expressive, yet manageable language or schema for defining Master Plans is crucial. Should it be YAML, JSON, a visual BPMN-like language, or a programmatic DSL? How are complex logic (conditionals, loops, error handling, parallel execution) represented?
*   **Error Handling & Recovery in Workflows:** Sophisticated mechanisms for defining error handling strategies at both step and plan level (e.g., retry with backoff, skip step, compensate transaction, halt plan, trigger alternative plan).
*   **Security & Privilege Model:** Given Reactor's powerful capabilities (orchestrating anything, managing agent lifecycles), its own security and the permission model for Master Plans are paramount. How to ensure a compromised Master Plan definition doesn't lead to sNetwork-wide issues? (IONWALL scope checks per step are key).
*   **Distributed Orchestration:** For very large-scale sNetworks or multi-user plans, could orchestration itself be distributed across multiple Reactor instances or a federated model?
*   **Versioning of Master Plans:** How are changes to Master Plan definitions managed, versioned, and migrated if old versions are still executing?
*   **State Management for Long-Running Plans:** Where and how is the state of a long-running Master Plan (which might take hours or days) persistently and reliably stored? (Likely IONPOD via the `MasterPlanExecutor_Transform`).
*   **User Interface for Plan Management & Monitoring:** A UI for users to design/upload Master Plans, monitor their execution in real-time, view logs, and manage running instances.
*   **Dynamic Resource Allocation for Plans:** Integration with IONFLUX Controller to request/allocate necessary compute/storage resources just-in-time for the agents involved in a Master Plan.
*   **Simulation & Dry-Run Mode:** Enhancing the "dry_run_validate_only" mode to provide detailed simulation of a plan's execution, including potential costs, resource usage, and IONWALL interactions, without actually performing actions.
