# Agent Blueprint: Comm Link Agent - v0.9.0

## 1. Overview

*   **Agent Name:** `Comm Link Agent`
*   **Version:** `0.9.0`
*   **Status:** `development`
*   **Primary Goal:** `Manages outgoing and incoming communications across various channels (e.g., email, NATS, Matrix, SMS), using templates and integrating with IONWALL for user consent on sending/receiving and contact details access from IONPOD.`
*   **Key Features:**
    *   Supports multiple communication channels for sending and receiving (initially Email, NATS, Matrix; extensible).
    *   Uses message templates stored in IONPOD for consistent and dynamic communication.
    *   Fetches contact details (e.g., email addresses, Matrix IDs) from IONPOD, subject to IONWALL approval.
    *   IONWALL approval required for sending messages and for establishing listeners/subscriptions on channels.
    *   Capability to route incoming messages to other agents or store them in IONPOD based on predefined rules or dynamic routing logic.
    *   Tracks communication history/logs (metadata) in IONPOD.

## 2. FluxGraph Definition (Conceptual YAML)

```yaml
# /specs/agents/comm_link_agent_fluxgraph.yaml (Conceptual representation)
version: "0.1.0" # FluxGraph spec version
name: "comm_link_agent_fluxgraph"
description: "Manages multi-channel communications (sending and receiving)."

triggers:
  - type: "manual" # For direct invocation, e.g., "send this message"
  - type: "event_driven"
    config: { event_source: "NATS", topic: "ionflux.agents.comm_link.send_message" } # Triggered by other agents
  # Specific triggers for incoming messages would be handled by continuous listener transforms if the FluxGraph engine supports them,
  # or by separate FluxGraphs dedicated to listening on each channel. For simplicity, this graph focuses on sending,
  # but can be adapted or extended for receiving.

input_schema: # JSON schema for "send_message" type triggers
  type: "object"
  properties:
    channel: { type: "string", enum: ["email", "nats", "matrix", "sms"], description: "Communication channel to use." }
    recipient_identifier_cid: { type: "string", description: "CID of an IONPOD object containing recipient details (e.g., email address, matrix_user_id, nats_topic for direct publish). Can also be a direct identifier if allowed by channel." }
    # OR recipient_direct_identifier: { type: "string" } for channels like NATS topics not requiring IONPOD lookup
    template_cid: { type: "string", description: "IPFS CID of the message template in IONPOD." }
    template_params: { type: "object", additionalProperties: true, description: "Parameters to fill into the template." }
    # For receiving (if this graph handled it directly via a trigger):
    # incoming_message_payload: { type: "object" }
    # incoming_message_metadata: { type: "object" }
  required: [ "channel", "template_cid", "template_params" ] # recipient_identifier_cid or direct needed

output_schema: # JSON schema for the agent's final output (for a send operation)
  type: "object"
  properties:
    message_id: { type: "string", nullable: true, description: "Unique ID of the sent message, if provided by the channel." }
    delivery_status: { type: "string", enum: ["sent", "failed_to_send", "pending_delivery_confirmation"], description: "Status of the send operation." }
    status: { type: "string", enum: ["success", "failure"] }
    error_message: { type: "string", nullable: true }
    # For receiving:
    # processed_incoming_message_cid: { type: "string", description: "CID of stored/routed incoming message." }
  required: ["status", "delivery_status"]

graph: # DAG of transforms - This example focuses on SENDING a message. Receiving would be a parallel graph or separate agent.
  - id: "fetch_contact_details_conditional"
    transform: "FetchFromIONPOD_Transform_IONWALL"
    if: "{{trigger.input_data.recipient_identifier_cid != null}}"
    ionwall_approval_scope: "read_pod_data:comm_link_recipient_contacts"
    inputs:
      cid: "{{trigger.input_data.recipient_identifier_cid}}"
    outputs: [contact_details_obj] # e.g., {"email": "user@example.com", "matrix_id": "@user:matrix.org"}

  - id: "fetch_message_template"
    transform: "FetchFromIONPOD_Transform_IONWALL"
    ionwall_approval_scope: "read_pod_data:comm_link_message_templates"
    inputs:
      cid: "{{trigger.input_data.template_cid}}"
    outputs: [template_string]

  - id: "process_message_template"
    transform: "TemplateProcessor_Transform_Jinja2" # Example template engine
    inputs:
      template: "{{nodes.fetch_message_template.outputs.template_string}}"
      parameters: "{{trigger.input_data.template_params}}"
    outputs: [processed_message_body, processed_message_subject_optional]

  # Channel Router - a conceptual way to direct to the correct send transform
  - id: "route_by_channel"
    transform: "SwitchCaseRouter_Transform" # Hypothetical transform
    inputs:
      switch_value: "{{trigger.input_data.channel}}"
    outputs: [to_email, to_nats, to_matrix, to_sms] # Boolean outputs

  # Email Sending Path
  - id: "send_email_message"
    transform: "Email_Send_Transform_SMTP" # Specific transform for sending email
    if: "{{nodes.route_by_channel.outputs.to_email == true}}"
    ionwall_approval_scope: "send_communication:email"
    inputs:
      recipient_email: "{{nodes.fetch_contact_details_conditional.outputs.contact_details_obj.email}}"
      subject: "{{nodes.process_message_template.outputs.processed_message_subject_optional || 'Message from IONFLUX Agent'}}"
      body_html: "{{nodes.process_message_template.outputs.processed_message_body}}" # Assuming template produces HTML for email
      # smtp_config_cid: from agent's PRM or system config
    outputs: [email_message_id, email_delivery_status]

  # NATS Publishing Path
  - id: "publish_nats_message"
    transform: "IPC_NATS_Publish_Transform" # Re-using NATS publish transform
    if: "{{nodes.route_by_channel.outputs.to_nats == true}}"
    ionwall_approval_scope: "send_communication:nats" # Different scope for NATS if needed
    inputs:
      topic: "{{trigger.input_data.recipient_direct_identifier || nodes.fetch_contact_details_conditional.outputs.contact_details_obj.nats_topic}}" # NATS topic can be direct or from contacts
      message_payload_string: "{{nodes.process_message_template.outputs.processed_message_body}}" # NATS typically sends string/JSON
      # nats_connection_config_cid: from agent's PRM or system config
    outputs: [nats_message_id, nats_delivery_status] # NATS might not have a message ID in the same way

  # Matrix Sending Path
  - id: "send_matrix_message"
    transform: "Matrix_Send_Transform"
    if: "{{nodes.route_by_channel.outputs.to_matrix == true}}"
    ionwall_approval_scope: "send_communication:matrix"
    inputs:
      matrix_room_id_or_user_id: "{{nodes.fetch_contact_details_conditional.outputs.contact_details_obj.matrix_id}}"
      message_content_markdown: "{{nodes.process_message_template.outputs.processed_message_body}}"
      # matrix_homeserver_config_cid: from agent's PRM
    outputs: [matrix_event_id, matrix_delivery_status]

  # SMS Sending Path (Conceptual - requires specific SMS transform and gateway config)
  # - id: "send_sms_message"
  #   transform: "SMS_Send_Transform_Twilio"
  #   if: "{{nodes.route_by_channel.outputs.to_sms == true}}"
  #   ionwall_approval_scope: "send_communication:sms"
  #   inputs:
  #     recipient_phone_number: "{{nodes.fetch_contact_details_conditional.outputs.contact_details_obj.phone_number}}"
  #     message_text: "{{nodes.process_message_template.outputs.processed_message_body}}"
  #   outputs: [sms_message_id, sms_delivery_status]

  - id: "aggregate_send_results" # Collects results from whichever path was taken
    transform: "MergeResults_Transform" # Hypothetical, picks the non-null result
    inputs:
      results_array: [
        {id: "{{nodes.send_email_message.outputs.email_message_id}}", status: "{{nodes.send_email_message.outputs.email_delivery_status}}", if_condition: "{{nodes.route_by_channel.outputs.to_email}}"},
        {id: "{{nodes.publish_nats_message.outputs.nats_message_id}}", status: "{{nodes.publish_nats_message.outputs.nats_delivery_status}}", if_condition: "{{nodes.route_by_channel.outputs.to_nats}}"},
        {id: "{{nodes.send_matrix_message.outputs.matrix_event_id}}", status: "{{nodes.send_matrix_message.outputs.matrix_delivery_status}}", if_condition: "{{nodes.route_by_channel.outputs.to_matrix}}"}
        # ... SMS results
      ]
    outputs: [final_message_id, final_delivery_status]

  - id: "log_communication_event"
    transform: "StoreToIONPOD_Transform_IONWALL" # Storing metadata log of the communication
    ionwall_approval_scope: "write_pod_data:comm_link_communication_log"
    inputs:
      data_to_store: {
        timestamp: "{{system.timestamp_utc}}",
        agent_name: "Comm Link Agent", version: "0.9.0",
        action: "send_message", channel: "{{trigger.input_data.channel}}",
        recipient_info_cid: "{{trigger.input_data.recipient_identifier_cid}}",
        template_cid: "{{trigger.input_data.template_cid}}",
        message_id: "{{nodes.aggregate_send_results.outputs.final_message_id}}",
        delivery_status: "{{nodes.aggregate_send_results.outputs.final_delivery_status}}"
      }
      filename_suggestion: "comm_log_{{system.timestamp_utc_iso}}.json"
    outputs: [log_entry_cid]

  - id: "publish_completion_event_nats" # Notify original requester or system
    transform: "IPC_NATS_Publish_Transform"
    inputs:
      topic: "ionflux.agents.comm_link.send_message.completion" # Specific completion topic
      message:
        status: "{{'success' if nodes.aggregate_send_results.outputs.final_delivery_status == 'sent' else 'failure'}}"
        message_id: "{{nodes.aggregate_send_results.outputs.final_message_id}}"
        delivery_status: "{{nodes.aggregate_send_results.outputs.final_delivery_status}}"
        log_cid: "{{nodes.log_communication_event.outputs.log_entry_cid}}"
        trigger_input: "{{trigger.input_data}}"
    dependencies: [log_communication_event]

# Note on Receiving: A separate FluxGraph or a continuously running listener transform type would be needed.
# Example Listener (conceptual, if engine supports this type of transform):
#  - id: "nats_listener_for_topic_x"
#    transform: "NATS_Listener_Transform" # Runs continuously or is event-triggered by NATS system
#    config: { nats_topic_to_subscribe: "some.input.topic", output_type: "parsed_message_object" }
#    outputs: [incoming_message_payload, incoming_message_metadata]
#    # Subsequent nodes would parse, route, and process this incoming_message_payload
```

---
## 3. Database Schema Fields (`agent_definitions` table)

### 3.1. `agent_name`
`"Comm Link Agent"`

### 3.2. `version`
`"0.9.0"`

### 3.3. `description`
`"Manages outgoing and incoming communications across various channels (e.g., email, NATS, Matrix, SMS), using templates and integrating with IONWALL for user consent on sending/receiving and contact details access from IONPOD."`

### 3.4. `status`
`"development"`

### 3.5. `flux_graph_dsl_yaml`
*(The YAML content from Section 2 is inserted here as a multi-line string)*
```yaml
# /specs/agents/comm_link_agent_fluxgraph.yaml (Conceptual representation)
version: "0.1.0" # FluxGraph spec version
name: "comm_link_agent_fluxgraph"
description: "Manages multi-channel communications (sending and receiving)."

triggers:
  - type: "manual" # For direct invocation, e.g., "send this message"
  - type: "event_driven"
    config: { event_source: "NATS", topic: "ionflux.agents.comm_link.send_message" }

input_schema:
  type: "object"
  properties:
    channel: { type: "string", enum: ["email", "nats", "matrix", "sms"], description: "Communication channel to use." }
    recipient_identifier_cid: { type: "string", description: "CID of an IONPOD object containing recipient details." }
    template_cid: { type: "string", description: "IPFS CID of the message template in IONPOD." }
    template_params: { type: "object", additionalProperties: true, description: "Parameters to fill into the template." }
  required: [ "channel", "template_cid", "template_params" ]

output_schema:
  type: "object"
  properties:
    message_id: { type: "string", nullable: true, description: "Unique ID of the sent message, if provided by the channel." }
    delivery_status: { type: "string", enum: ["sent", "failed_to_send", "pending_delivery_confirmation"], description: "Status of the send operation." }
    status: { type: "string", enum: ["success", "failure"] }
    error_message: { type: "string", nullable: true }
  required: ["status", "delivery_status"]

graph:
  - id: "fetch_contact_details_conditional"
    transform: "FetchFromIONPOD_Transform_IONWALL"
    if: "{{trigger.input_data.recipient_identifier_cid != null}}"
    ionwall_approval_scope: "read_pod_data:comm_link_recipient_contacts"
    inputs:
      cid: "{{trigger.input_data.recipient_identifier_cid}}"
    outputs: [contact_details_obj]

  - id: "fetch_message_template"
    transform: "FetchFromIONPOD_Transform_IONWALL"
    ionwall_approval_scope: "read_pod_data:comm_link_message_templates"
    inputs:
      cid: "{{trigger.input_data.template_cid}}"
    outputs: [template_string]

  - id: "process_message_template"
    transform: "TemplateProcessor_Transform_Jinja2"
    inputs:
      template: "{{nodes.fetch_message_template.outputs.template_string}}"
      parameters: "{{trigger.input_data.template_params}}"
    outputs: [processed_message_body, processed_message_subject_optional]

  - id: "route_by_channel"
    transform: "SwitchCaseRouter_Transform"
    inputs:
      switch_value: "{{trigger.input_data.channel}}"
    outputs: [to_email, to_nats, to_matrix, to_sms]

  - id: "send_email_message"
    transform: "Email_Send_Transform_SMTP"
    if: "{{nodes.route_by_channel.outputs.to_email == true}}"
    ionwall_approval_scope: "send_communication:email"
    inputs:
      recipient_email: "{{nodes.fetch_contact_details_conditional.outputs.contact_details_obj.email}}"
      subject: "{{nodes.process_message_template.outputs.processed_message_subject_optional || 'Message from IONFLUX Agent'}}"
      body_html: "{{nodes.process_message_template.outputs.processed_message_body}}"
    outputs: [email_message_id, email_delivery_status]

  - id: "publish_nats_message"
    transform: "IPC_NATS_Publish_Transform"
    if: "{{nodes.route_by_channel.outputs.to_nats == true}}"
    ionwall_approval_scope: "send_communication:nats"
    inputs:
      topic: "{{trigger.input_data.recipient_direct_identifier || nodes.fetch_contact_details_conditional.outputs.contact_details_obj.nats_topic}}"
      message_payload_string: "{{nodes.process_message_template.outputs.processed_message_body}}"
    outputs: [nats_message_id, nats_delivery_status]

  - id: "send_matrix_message"
    transform: "Matrix_Send_Transform"
    if: "{{nodes.route_by_channel.outputs.to_matrix == true}}"
    ionwall_approval_scope: "send_communication:matrix"
    inputs:
      matrix_room_id_or_user_id: "{{nodes.fetch_contact_details_conditional.outputs.contact_details_obj.matrix_id}}"
      message_content_markdown: "{{nodes.process_message_template.outputs.processed_message_body}}"
    outputs: [matrix_event_id, matrix_delivery_status]

  - id: "aggregate_send_results"
    transform: "MergeResults_Transform"
    inputs:
      results_array: [
        {id: "{{nodes.send_email_message.outputs.email_message_id}}", status: "{{nodes.send_email_message.outputs.email_delivery_status}}", if_condition: "{{nodes.route_by_channel.outputs.to_email}}"},
        {id: "{{nodes.publish_nats_message.outputs.nats_message_id}}", status: "{{nodes.publish_nats_message.outputs.nats_delivery_status}}", if_condition: "{{nodes.route_by_channel.outputs.to_nats}}"},
        {id: "{{nodes.send_matrix_message.outputs.matrix_event_id}}", status: "{{nodes.send_matrix_message.outputs.matrix_delivery_status}}", if_condition: "{{nodes.route_by_channel.outputs.to_matrix}}"}
      ]
    outputs: [final_message_id, final_delivery_status]

  - id: "log_communication_event"
    transform: "StoreToIONPOD_Transform_IONWALL"
    ionwall_approval_scope: "write_pod_data:comm_link_communication_log"
    inputs:
      data_to_store: {
        timestamp: "{{system.timestamp_utc}}",
        agent_name: "Comm Link Agent", version: "0.9.0",
        action: "send_message", channel: "{{trigger.input_data.channel}}",
        recipient_info_cid: "{{trigger.input_data.recipient_identifier_cid}}",
        template_cid: "{{trigger.input_data.template_cid}}",
        message_id: "{{nodes.aggregate_send_results.outputs.final_message_id}}",
        delivery_status: "{{nodes.aggregate_send_results.outputs.final_delivery_status}}"
      }
      filename_suggestion: "comm_log_{{system.timestamp_utc_iso}}.json"
    outputs: [log_entry_cid]

  - id: "publish_completion_event_nats"
    transform: "IPC_NATS_Publish_Transform"
    inputs:
      topic: "ionflux.agents.comm_link.send_message.completion"
      message:
        status: "{{'success' if nodes.aggregate_send_results.outputs.final_delivery_status == 'sent' else 'failure'}}"
        message_id: "{{nodes.aggregate_send_results.outputs.final_message_id}}"
        delivery_status: "{{nodes.aggregate_send_results.outputs.final_delivery_status}}"
        log_cid: "{{nodes.log_communication_event.outputs.log_entry_cid}}"
        trigger_input: "{{trigger.input_data}}"
    dependencies: [log_communication_event]
```

### 3.6. `execution_requirements_json`
```json
{
  "transforms_required": [
    "FetchFromIONPOD_Transform_IONWALL",
    "TemplateProcessor_Transform_Jinja2",
    "SwitchCaseRouter_Transform",
    "Email_Send_Transform_SMTP",
    "IPC_NATS_Publish_Transform",
    "Matrix_Send_Transform",
    "MergeResults_Transform",
    "StoreToIONPOD_Transform_IONWALL"
    // Potentially "NATS_Listener_Transform", "SMS_Send_Transform_Twilio" if fully implemented
  ],
  "min_ram_mb": 256,
  "gpu_required": false,
  "estimated_execution_duration_seconds": 10,
  "max_concurrent_instances": 10,
  "wasm_modules_cids": {
    "FetchFromIONPOD_Transform_IONWALL": "bafyreibvlobj2rl34gsgxrjltirqesqkfbhtharb3uaxnri3ebpmpah6ce",
    "TemplateProcessor_Transform_Jinja2": "bafyreid3ifqivfancx5flci3tqgws6ahmblzdxq63ot6ytkvykxuvcaapu",
    "SwitchCaseRouter_Transform": "bafyreig4fxqscqg57f2jhfgfdylncxuc32syjxgyf7yt7noypz7xvo7xoi",
    "Email_Send_Transform_SMTP": "bafyreihw5yn2nlgnwsnlqgyhprflwvqnx7sjqgqfblsjdzu46s7zfgf72q",
    "IPC_NATS_Publish_Transform": "bafyreihyrz7wgld5qrjmejbdjcbcm3jqrjshxphu6jnlxhnlfbk7d745xy",
    "Matrix_Send_Transform": "bafyreicarpscx5wzmahdnlxerdzhvy2gxbqgxtz7lkgp7c7kkqvgsbpdha",
    "MergeResults_Transform":"bafyreihdjdlxqz73237nmy2gtj7wpsacjnqv7rajidgozztx7jyqxfnhom",
    "StoreToIONPOD_Transform_IONWALL": "bafyreif7yqivqtkjhhwb5xkxqj3j7gyjlrvfkhhvjvbfffj4u7m5kfefbi"
  }
}
```

### 3.7. `ecosystem_integration_points_json`
```json
{
  "ionwall_permissions_needed": [
    "read_pod_data:comm_link_recipient_contacts",
    "read_pod_data:comm_link_message_templates",
    "send_communication:email",
    "send_communication:nats",
    "send_communication:matrix",
    "send_communication:sms",
    "write_pod_data:comm_link_communication_log",
    "subscribe_to_nats_topic:comm_link_incoming_generic"
  ],
  "ionpod_data_access": {
    "inputs": [
      { "cid_param": "recipient_identifier_cid", "access_type": "read", "purpose": "To fetch recipient contact details." },
      { "cid_param": "template_cid", "access_type": "read", "purpose": "To fetch message template." }
    ],
    "outputs": [
      { "cid_name": "log_entry_cid", "access_type": "write", "purpose": "To store metadata log of the communication event." }
    ]
  },
  "tokenomic_triggers": [
    { "event": "message_sent_successfully_email", "action": "debit_user_service_credits", "token_id": "C-ION", "amount_formula": "0.001" },
    { "event": "message_sent_successfully_matrix", "action": "debit_user_service_credits", "token_id": "C-ION", "amount_formula": "0.0005" },
    { "event": "message_sent_successfully_nats", "action": "debit_user_service_credits", "token_id": "C-ION", "amount_formula": "0.0001" },
    { "event": "message_received_and_processed", "action": "reward_user_ion_for_engagement", "token_id": "$ION", "amount_formula": "0.0002" }
  ],
  "techgnosis_integration": {
    "knowledge_graph_queries": [
      "find_preferred_communication_channel_for_user:{{nodes.fetch_contact_details_conditional.outputs.contact_details_obj.user_profile_cid}}",
      "analyze_message_intent_for_archival_tagging:{{nodes.process_message_template.outputs.processed_message_body}}"
    ],
    "output_metadata_tags": ["communication_event", "channel_{{trigger.input_data.channel}}", "intent_{{kg_derived_intent}}"]
  },
  "hybrid_layer_escalation_points": [
    { "condition": "message_content_flagged_by_policy_engine_transform_before_send", "action": "pause_and_escalate_for_human_review_content_policy" },
    { "condition": "user_reports_unsolicited_message_via_comm_link_listener", "action": "flag_sender_and_escalate_for_review_spam_abuse" },
    { "condition": "multiple_failed_delivery_attempts_to_recipient", "action": "notify_user_and_suggest_contact_update_via_hybrid_layer_task" }
  ],
  "carbon_loop_contribution": {
    "type": "communication_efficiency_preference",
    "value_formula": "prefer_nats_over_email_if_possible_factor * carbon_saved_per_message_type_delta",
    "description": "Encourages use of lower-overhead communication channels like NATS for internal system events where appropriate, potentially reducing data transfer and processing overhead compared to email for all notifications."
  }
}
```

### 3.8. `prm_details_json`
```json
{
  "default_from_email_cid": "bafyreihk... (CID of an IONPOD object with default sender email config)",
  "default_matrix_bot_user_cid": "bafyreihj... (CID of an IONPOD object with Matrix bot credentials)",
  "default_nats_connection_cid": "bafyreihg... (CID of an IONPOD object with NATS connection details)",
  "max_retries_per_message_send": 2,
  "template_language_default": "jinja2",
  "supported_channels_for_sending": ["email", "nats", "matrix"],
  "supported_channels_for_listening": ["nats", "matrix"],
  "user_customizable_params": [
    "recipient_identifier_cid", "template_cid", "template_params", "channel"
  ]
}
```

### 3.9. `input_schema_json`
*(The JSON content of `input_schema` from Section 2 is inserted here)*
```json
{
  "type": "object",
  "properties": {
    "channel": { "type": "string", "enum": ["email", "nats", "matrix", "sms"], "description": "Communication channel to use." },
    "recipient_identifier_cid": { "type": "string", "description": "CID of an IONPOD object containing recipient details (e.g., email address, matrix_user_id, nats_topic for direct publish). Can also be a direct identifier if allowed by channel." },
    "template_cid": { "type": "string", "description": "IPFS CID of the message template in IONPOD." },
    "template_params": { "type": "object", "additionalProperties": true, "description": "Parameters to fill into the template." }
  },
  "required": [ "channel", "template_cid", "template_params" ]
}
```

### 3.10. `output_schema_json`
*(The JSON content of `output_schema` from Section 2 is inserted here)*
```json
{
  "type": "object",
  "properties": {
    "message_id": { "type": "string", "nullable": true, "description": "Unique ID of the sent message, if provided by the channel." },
    "delivery_status": { "type": "string", "enum": ["sent", "failed_to_send", "pending_delivery_confirmation"], "description": "Status of the send operation." },
    "status": { "type": "string", "enum": ["success", "failure"] },
    "error_message": { "type": "string", "nullable": true }
  },
  "required": ["status", "delivery_status"]
}
```

### 3.11. `trigger_config_json`
```json
{
  "manual_trigger_enabled": true,
  "event_driven_triggers": [
    {
      "event_source": "NATS",
      "topic": "ionflux.agents.comm_link.send_message",
      "description": "Triggered by other agents to send a message. Payload should match input_schema.",
      "input_mapping_jmespath": "payload" # Assumes the NATS message payload is the full input_schema
    }
    // Listener configurations would be more complex, possibly managed by the IONFLUX controller
    // to instantiate listeners rather than direct FluxGraph triggers for continuous listening.
    // For example, a separate "listener_registration" could be an input type.
  ],
  "webhook_triggers": [
     {
      "endpoint_path": "/webhooks/invoke/comm_link_send",
      "http_method": "POST",
      "authentication_method": "ionwall_jwt",
      "description": "HTTP endpoint to trigger sending a message. Expects JSON body matching input_schema."
    }
  ]
}
```

### 3.12. `deployment_info_json`
```json
{
  "runtime_environment": "IONFLUX_EdgeNode_Wasm",
  "current_instances_managed_by_ionflux_controller": true,
  "default_replicas_send_fluxgraph": 1,
  "default_replicas_listener_nats_matrix": 1, # If listeners are part of this agent definition
  "auto_scaling_policy_send": {
    "min_replicas": 1, "max_replicas": 5, "queue_length_threshold": 20
  }
  # Listener scaling might be different, based on number of subscriptions or traffic.
}
```

### 3.13. `logging_json`
```json
{
  "log_level": "info",
  "log_targets": ["ionpod_event_log", "local_stdout_dev_mode_only"],
  "log_retention_policy_days": 15,
  "sensitive_fields_to_mask": ["contact_details_obj.email", "template_params.password_if_any"]
}
```

### 3.14. `monitoring_json`
```json
{
  "metrics_to_collect": [
    "messages_sent_count_by_channel", "message_send_failure_count_by_channel", "message_processing_time_avg_ms",
    "active_listeners_count_by_channel", "messages_received_count_by_channel"
  ],
  "metrics_endpoint_ionwall_protected": "/metrics/comm_link_agent",
  "health_check_protocol": "check_downstream_service_connectivity_eg_smtp_matrix_nats",
  "alerting_rules": [
    {"metric": "message_send_failure_count_email", "condition": "value > 10 for 5m", "severity": "warning", "notification_channel": "hybrid_layer_ops_team_chat"},
    {"metric": "nats_listener_status_topic_xyz", "condition": "status == unhealthy for 2m", "severity": "critical", "notification_channel": "hybrid_layer_ops_pager"}
  ]
}
```

### 3.15. `security_json`
```json
{
  "data_encryption_at_rest_ionpod": true,
  "data_encryption_in_transit_ipfs_ionwall": true,
  "channel_specific_encryption_matrix": "end_to_end_encryption_megolm_enabled_via_transform_config",
  "channel_specific_encryption_email": "tls_smtp_mandatory_pgp_support_planned_via_transform_option",
  "required_ionwall_consent_scopes": [
    "read_pod_data:comm_link_recipient_contacts", "read_pod_data:comm_link_message_templates",
    "send_communication:email", "send_communication:nats", "send_communication:matrix", "send_communication:sms",
    "write_pod_data:comm_link_communication_log",
    "subscribe_to_nats_topic:comm_link_incoming_generic", "receive_matrix_messages:comm_link_bot_user"
  ],
  "gdpr_compliance_features_enabled": true,
  "communication_policy_enforcement_cid": "bafyreia... (CID of a policy object in IONPOD defining rate limits, content filters - checked by a transform)",
  "anti_spam_measures_for_incoming": "rate_limiting_per_sender_ip_or_id_header_analysis_transform_level",
  "sensitive_data_handling_policy_id": "SDP-COMMLINK-001"
}
```

---
## 4. User Experience Flow (Conceptual)

**A. Sending a Message (Triggered by another Agent):**
1.  **Initiation:** `Agent A` (e.g., `Chronos Task Agent` for a reminder) decides to send an email. It triggers `Comm Link Agent` via a NATS event (`ionflux.agents.comm_link.send_message`) with payload: `{ channel: "email", recipient_identifier_cid: "cid_of_user_profile_with_email", template_cid: "cid_of_reminder_email_template", template_params: { task_name: "Review Q3 Report" } }`.
2.  **IONWALL Checkpoint 1 (Data Access & Send Permission):**
    *   (If first time or consent expired for this interaction type) IONWALL prompts User (owner of `Agent A` and `Comm Link Agent`): *"Comm Link Agent, on behalf of Chronos Task Agent, wants to:
        *   Read contact details from '{{recipient_identifier_cid.name}}' in your IONPOD.
        *   Read message template '{{template_cid.name}}' from your IONPOD.
        *   Send an Email to '{{contact_details_obj.email}}'.
        Allow?"*
3.  **Execution:**
    *   `Comm Link Agent` fetches contact (email address) and template.
    *   It processes the template with `template_params`.
    *   It invokes `Email_Send_Transform_SMTP` to send the email.
4.  **Logging & Completion:**
    *   The communication event (metadata, recipient, status) is logged to User's IONPOD via `StoreToIONPOD_Transform_IONWALL`. IONWALL approval might be cached for this internal logging.
    *   A NATS event is published by `Comm Link Agent` on `ionflux.agents.comm_link.send_message.completion` indicating success/failure, which `Agent A` might listen to.

**B. Setting up a NATS Listener to Store Messages:**
1.  **Initiation:** User, through an IONFLUX UI, wants to monitor a specific NATS topic (`custom.data.feed`) and store all messages into an IONPOD folder (`/nats_archive/custom_data_feed/`).
2.  **Configuration UI:** User specifies: NATS topic, target IONPOD path, and maybe a parsing/filtering rule (e.g., only JSON, or messages containing "critical_alert").
3.  **IONWALL Checkpoint (Subscription & Write Permission):**
    *   IONWALL prompts User: *"Comm Link Agent wants to:
        *   Subscribe to and receive messages from NATS topic 'custom.data.feed'.
        *   Store received messages into your IONPOD at path '/nats_archive/custom_data_feed/'.
        Allow?"*
4.  **Execution (Conceptual - Listener Management):**
    *   The IONFLUX Controller, based on this approved request, configures/deploys a listener instance of `Comm Link Agent` (or a specialized listener FluxGraph) dedicated to this NATS topic.
    *   This listener FluxGraph would use `NATS_Listener_Transform`, then `StoreToIONPOD_Transform_IONWALL` for each message.
5.  **Ongoing Operation:** Messages arriving on `custom.data.feed` are automatically processed by the listener and stored. User sees new files appearing in their IONPOD.

---
## 5. TechGnosis & Hybrid Layer Integration Notes

*   **TechGnosis:**
    *   For outgoing messages, TechGnosis could analyze `template_params` or message body to suggest optimal communication channels or recipient groups based on past interactions or content semantics ("This seems like a broadcast message, consider using a NATS topic for registered subscribers instead of individual emails").
    *   For incoming messages, TechGnosis can perform intent analysis, entity extraction, and sentiment analysis on the message body. This enriched data can be used for intelligent routing or tagging of the stored message in IONPOD.
    *   `knowledge_graph_queries` can fetch preferred contact methods or historical communication patterns for a given user profile CID.
*   **Hybrid Layer:**
    *   If a message to be sent is flagged by an integrated policy/content filter transform (e.g., for containing sensitive PII without proper context, or for violating communication policies), it can be escalated to the Hybrid Layer for human review before sending.
    *   For incoming messages, if TechGnosis intent analysis detects urgent or critical issues (e.g., a complaint, a security alert), it can be escalated to the Hybrid Layer for human attention and action.
    *   Users can report unsolicited or abusive messages received via `Comm Link Agent` listeners; these reports are handled by the Hybrid Layer to investigate and potentially block senders.

---
## 6. Carbon Loop Integration Notes

*   The agent can be configured to prefer communication channels with lower carbon footprints for non-critical, bulk, or internal system communications (e.g., using NATS messages which are typically smaller and have less overhead than formatted emails with headers/HTML). This preference can be part of the `prm_details_json` or dynamically chosen if a "carbon intensity" metric per channel becomes available.
*   Logging communication events to IONPOD contributes to data that can be analyzed for patterns, potentially optimizing communication strategies to reduce redundant messages, thus indirectly contributing to lower data transfer and processing.

---
## 7. Dependencies & Interactions

*   **Required Transforms:**
    *   `FetchFromIONPOD_Transform_IONWALL` (for templates, contact CIDs)
    *   `TemplateProcessor_Transform_Jinja2` (or similar for message templating)
    *   `SwitchCaseRouter_Transform` (or similar logic for channel selection)
    *   `Email_Send_Transform_SMTP`, `IPC_NATS_Publish_Transform`, `Matrix_Send_Transform` (and other channel-specific sender transforms like `SMS_Send_Transform_Twilio`).
    *   `MergeResults_Transform` (to consolidate output from different send paths).
    *   `StoreToIONPOD_Transform_IONWALL` (for logging communication events).
    *   For receiving: `NATS_Listener_Transform`, `Matrix_Listener_Transform`, and potentially channel-specific parsing transforms.
*   **Interacting Agents (Conceptual):**
    *   Almost any agent could trigger `Comm Link Agent` to send notifications, alerts, or messages (e.g., `Chronos Task Agent`, `Guardian Compliance Agent`, `Muse Prompt Chain Agent` upon completion).
    *   Incoming messages processed by `Comm Link Agent` might trigger other agents based on routing rules (e.g., an incoming NATS event on a specific topic could trigger `Datascribe Transcript Agent`).
*   **External Systems (via Transforms):**
    *   Email SMTP servers.
    *   NATS brokers.
    *   Matrix homeservers.
    *   SMS gateways (e.g., Twilio).

---
## 8. Open Questions & Future Considerations

*   **Listener Architecture:** How are continuous listeners for incoming messages best managed? As separate, long-running FluxGraphs, or a feature of the IONFLUX controller managing transform instances?
*   **End-to-End Encryption (E2EE):** For channels like Matrix or Email (PGP), how is key management handled? Integration with an IONWALLET Agent or a dedicated KeyManagement Transform that securely fetches/uses keys from IONPOD/IONWALLET.
*   **Contact Management:** More sophisticated querying of contact details (e.g., "get all users in group X who prefer Matrix notifications"). This might require a dedicated "Contacts_Query_Transform" that interacts with a structured contacts list in IONPOD or a TechGnosis service.
*   **Support for more channels:** XMPP, Signal, Telegram, etc. Each would require a dedicated set of Send/Receive transforms.
*   **Complex Routing Rules for Incoming Messages:** Beyond simple topic-based routing, allow users to define rules based on message content, sender, etc. (possibly using a RulesEngine Transform).
*   **Delivery Confirmation & Read Receipts:** Standardizing how these are handled across different channels that support them.
*   **Attachment Handling:** Securely handling attachments for sending and receiving.
*   **Unsubscribe Management:** For broadcast-type messages, providing a way for recipients to unsubscribe, and honoring those preferences.
