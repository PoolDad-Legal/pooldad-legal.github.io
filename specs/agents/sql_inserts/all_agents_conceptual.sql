-- /specs/agents/sql_inserts/all_agents_conceptual.sql

-- Enum for Agent Status
CREATE TYPE agent_status AS ENUM (
    'development',
    'active',
    'inactive',
    'archived',
    'error'
);

-- Enum for Agent Trigger Types
CREATE TYPE agent_trigger_type AS ENUM (
    'manual',
    'scheduled',
    'webhook',
    'event_driven',
    'continuous'
);

-- Main Table for Agent Definitions
CREATE TABLE agent_definitions (
    agent_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_name VARCHAR(255) NOT NULL,
    version VARCHAR(50) NOT NULL, -- e.g., "1.0.0", "0.9-beta"
    description TEXT,
    status agent_status DEFAULT 'development',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    flux_graph_dsl_yaml TEXT NOT NULL,
    execution_requirements_json JSONB,
    ecosystem_integration_points_json JSONB,
    prm_details_json JSONB,
    input_schema_json JSONB,
    output_schema_json JSONB,
    trigger_config_json JSONB,
    deployment_info_json JSONB,
    logging_json JSONB,
    monitoring_json JSONB,
    security_json JSONB,
    UNIQUE (agent_name, version)
);
CREATE INDEX idx_agent_name ON agent_definitions (agent_name);
CREATE INDEX idx_status ON agent_definitions (status);
CREATE INDEX idx_created_at ON agent_definitions (created_at);
COMMENT ON TABLE agent_definitions IS 'Stores definitions of IONFLUX agents, including their FluxGraph DSL and operational parameters.';
COMMENT ON COLUMN agent_definitions.flux_graph_dsl_yaml IS 'The core YAML definition of the agent as a FluxGraph (Directed Acyclic Graph of Transforms).';
COMMENT ON COLUMN agent_definitions.execution_requirements_json IS 'JSONB detailing resources, transforms, and dependencies needed for the agent to run.';
COMMENT ON COLUMN agent_definitions.ecosystem_integration_points_json IS 'JSONB describing how the agent interacts with various parts of the ION Ecosystem (IONWALL, IONPOD, Tokenomics, etc.).';
COMMENT ON COLUMN agent_definitions.prm_details_json IS 'JSONB for agent-specific parameters, configurations, and default settings.';
COMMENT ON COLUMN agent_definitions.input_schema_json IS 'JSONB schema defining the expected input structure for the agent.';
COMMENT ON COLUMN agent_definitions.output_schema_json IS 'JSONB schema defining the output structure produced by the agent.';
COMMENT ON COLUMN agent_definitions.trigger_config_json IS 'JSONB specifying the conditions and configurations for how the agent is triggered.';
COMMENT ON COLUMN agent_definitions.deployment_info_json IS 'JSONB containing information about the agent''s deployment status and runtime environment.';
CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER set_timestamp
BEFORE UPDATE ON agent_definitions
FOR EACH ROW
EXECUTE FUNCTION trigger_set_timestamp();

-- Conceptual SQL INSERT Statements for 10 Core Agents

-- Agent 001: Muse Prompt Chain Agent
INSERT INTO agent_definitions (
    agent_name, version, description, status, flux_graph_dsl_yaml,
    execution_requirements_json, ecosystem_integration_points_json,
    prm_details_json, input_schema_json, output_schema_json,
    trigger_config_json, deployment_info_json, logging_json,
    monitoring_json, security_json
) VALUES (
    'Muse Prompt Chain Agent',
    '0.9.0',
    'Orchestrates a sequence of LLM prompts (a "prompt chain") to achieve complex generative tasks. Uses MuseGen_LLM_Transform for each step and allows dynamic parameter injection from IONPOD or user inputs, managed via IONWALL.',
    'development',
    '---
version: "0.1.0"
name: "muse_prompt_chain_agent_fluxgraph"
description: "Orchestrates a series of LLM prompts for complex generation."

triggers:
  - type: "manual"
  - type: "event_driven"
    config: { event_source: "NATS", topic: "ionflux.agents.muse.invoke" }

input_schema:
  type: "object"
  properties:
    initial_data_cid: { type: "string", description: "IPFS CID of initial data object from IONPOD." }
    prompt_chain_definition_cid: { type: "string", description: "IPFS CID of the prompt chain definition (series of prompt templates and parameter mappings)." }
    user_parameters: { type: "object", description: "User-provided parameters to customize the chain." }
  required: [initial_data_cid, prompt_chain_definition_cid]

output_schema:
  type: "object"
  properties:
    final_output_cid: { type: "string", description: "IPFS CID of the final generated output stored in IONPOD." }
    intermediate_outputs_cids: { type: "array", items: { type: "string" }, description: "IPFS CIDs of any intermediate outputs." }
    status: { type: "string", enum: ["success", "failure"] }
    error_message: { type: "string", nullable: true }

graph:
  - id: "fetch_initial_data"
    transform: "FetchFromIONPOD_Transform_IONWALL"
    ionwall_approval_scope: "read_data_for_muse_agent"
    inputs:
      cid: "{{trigger.input_data.initial_data_cid}}"
    outputs: [initial_content]

  - id: "fetch_prompt_chain_def"
    transform: "FetchFromIONPOD_Transform_IONWALL"
    ionwall_approval_scope: "read_config_for_muse_agent"
    inputs:
      cid: "{{trigger.input_data.prompt_chain_definition_cid}}"
    outputs: [prompt_chain_definition]

  # Loop or sequence through prompt_chain_definition
  # This is a conceptual representation of a loop/map operation over prompts
  - id: "prompt_step_1_llm"
    transform: "MuseGen_LLM_Transform"
    ionwall_approval_scope: "llm_inference_muse_agent"
    inputs:
      prompt_template: "{{nodes.fetch_prompt_chain_def.outputs.prompt_chain_definition.prompts[0].template}}"
      llm_config: "{{nodes.fetch_prompt_chain_def.outputs.prompt_chain_definition.prompts[0].llm_config}}"
      dynamic_params: { initial: "{{nodes.fetch_initial_data.outputs.initial_content}}", user: "{{trigger.input_data.user_parameters}}" }
    outputs: [step_1_output]
    # Potentially map outputs to next step inputs or aggregate

  - id: "prompt_step_2_llm_example"
    transform: "MuseGen_LLM_Transform"
    ionwall_approval_scope: "llm_inference_muse_agent"
    inputs:
      prompt_template: "{{nodes.fetch_prompt_chain_def.outputs.prompt_chain_definition.prompts[1].template}}"
      llm_config: "{{nodes.fetch_prompt_chain_def.outputs.prompt_chain_definition.prompts[1].llm_config}}"
      dynamic_params: { previous_step_output: "{{nodes.prompt_step_1_llm.outputs.step_1_output}}", user: "{{trigger.input_data.user_parameters}}" }
    outputs: [step_2_output]

  # ... more steps as defined in prompt_chain_definition ...

  - id: "final_processing_and_storage"
    transform: "StoreToIONPOD_Transform_IONWALL"
    ionwall_approval_scope: "write_output_muse_agent"
    inputs:
      data_to_store: "{{nodes.prompt_step_2_llm_example.outputs.step_2_output}}" # Or an aggregation of outputs
      metadata: { agent_name: "Muse Prompt Chain Agent", source_cids: ["{{trigger.input_data.initial_data_cid}}", "{{trigger.input_data.prompt_chain_definition_cid}}"] }
    outputs: [final_cid]

  - id: "publish_completion_event"
    transform: "IPC_NATS_Publish_Transform"
    inputs:
      topic: "ionflux.agents.muse.completion"
      message:
        status: "success"
        final_output_cid: "{{nodes.final_processing_and_storage.outputs.final_cid}}"
        # ... other relevant info
    dependencies: [final_processing_and_storage]
',
    '{
        "transforms_required": ["FetchFromIONPOD_Transform_IONWALL", "MuseGen_LLM_Transform", "StoreToIONPOD_Transform_IONWALL", "IPC_NATS_Publish_Transform"],
        "min_ram_mb": 512,
        "gpu_required": true,
        "gpu_type_preference": "NVIDIA_TESLA_T4_OR_EQUIVALENT",
        "estimated_execution_duration_seconds": 300,
        "max_concurrent_instances": 5,
        "wasm_modules_cids": {
            "FetchFromIONPOD_Transform_IONWALL": "bafyreig...",
            "MuseGen_LLM_Transform": "bafyreih...",
            "StoreToIONPOD_Transform_IONWALL": "bafyreif...",
            "IPC_NATS_Publish_Transform": "bafyreid..."
        }
    }',
    '{
        "ionwall_permissions_needed": [
            "read_pod_data:{{trigger.input_data.initial_data_cid}}",
            "read_pod_data:{{trigger.input_data.prompt_chain_definition_cid}}",
            "llm_inference:transform_MuseGen_LLM",
            "write_pod_data:output_muse_agent"
        ],
        "ionpod_data_access": {
            "inputs": [
                { "cid_param": "initial_data_cid", "access_type": "read", "purpose": "Initial data for prompt chain." },
                { "cid_param": "prompt_chain_definition_cid", "access_type": "read", "purpose": "Prompt chain definition." }
            ],
            "outputs": [
                { "cid_name": "final_output_cid", "access_type": "write", "purpose": "Final result of the prompt chain." }
            ]
        },
        "tokenomic_triggers": [
            { "event": "fluxgraph_successful_completion", "action": "reward_user", "token_id": "$ION", "amount_formula": "complexity_score * 0.01" },
            { "event": "transform_MuseGen_LLM_invocation", "action": "debit_user_compute_credits", "token_id": "C-ION", "amount_formula": "llm_tokens_processed * 0.0001" }
        ],
        "techgnosis_integration": {
            "knowledge_graph_queries": ["related_creative_concepts:{{nodes.fetch_initial_data.outputs.initial_content.keywords}}"],
            "symbolic_meaning_enhancement": true
        },
        "hybrid_layer_escalation_points": [
            { "condition": "low_confidence_score_from_llm", "action": "human_review_flag" },
            { "condition": "explicit_user_request_for_review", "action": "human_review_escalation" }
        ],
        "carbon_loop_contribution": {
            "type": "compute_offset",
            "value_formula": "gpu_hours * carbon_intensity_factor * offset_credit_price"
        }
    }',
    '{
        "default_llm_config": { "model_id": "claude-3-opus", "temperature": 0.7, "max_tokens": 2048 },
        "allow_user_llm_override": true,
        "max_prompt_chain_depth": 10,
        "error_handling_strategy": "retry_and_escalate",
        "user_customizable_params": ["default_llm_config.temperature", "max_prompt_chain_depth"]
    }',
    '{
        "type": "object",
        "properties": {
            "initial_data_cid": { "type": "string", "description": "IPFS CID of initial data object from IONPOD." },
            "prompt_chain_definition_cid": { "type": "string", "description": "IPFS CID of the prompt chain definition." },
            "user_parameters": { "type": "object", "description": "User-provided parameters." }
        },
        "required": ["initial_data_cid", "prompt_chain_definition_cid"]
    }',
    '{
        "type": "object",
        "properties": {
            "final_output_cid": { "type": "string", "description": "IPFS CID of the final generated output." },
            "intermediate_outputs_cids": { "type": "array", "items": { "type": "string" } },
            "status": { "type": "string", "enum": ["success", "failure"] },
            "error_message": { "type": "string", "nullable": true },
            "usage_metrics": {"type": "object", "properties": {"llm_tokens_processed": {"type": "integer"}, "execution_time_ms": {"type": "integer"}}}
        },
        "required": ["final_output_cid", "status"]
    }',
    '{
        "manual_trigger_enabled": true,
        "event_driven_triggers": [
            { "event_source": "NATS", "topic": "ionflux.agents.muse.invoke", "description": "Invokes agent when a message is published to this NATS topic." }
        ],
        "webhook_triggers": [
            { "endpoint_path": "/invoke/muse_prompt_chain", "authentication_method": "ionwall_jwt", "description": "HTTP endpoint to trigger the agent." }
        ]
    }',
    '{
        "runtime_environment": "IONFLUX_EdgeNode_Wasm",
        "current_instances_managed_by_ionflux_controller": true,
        "default_replicas": 1,
        "auto_scaling_policy": { "min_replicas": 1, "max_replicas": 5, "cpu_threshold_percentage": 70 }
    }',
    '{ "log_level": "info", "log_targets": ["ionpod_event_log", "local_stdout_dev_mode_only"], "log_retention_policy_days": 30 }',
    '{ "metrics_to_collect": ["execution_time", "llm_token_usage", "error_rate"], "metrics_endpoint_ionwall_protected": "/metrics/muse_agent", "health_check_protocol": "internal_ping" }',
    '{
        "data_encryption_at_rest_ionpod": true,
        "data_encryption_in_transit_ipfs_ionwall": true,
        "required_ionwall_consent_scopes": ["read_pod_data", "write_pod_data", "llm_inference"],
        "gdpr_compliance_features_enabled": true,
        "data_anonymization_options": ["pseudonymization_on_export"]
    }'
);

-- Agent 002: Datascribe Transcript Agent
INSERT INTO agent_definitions (
    agent_name, version, description, status, flux_graph_dsl_yaml,
    execution_requirements_json, ecosystem_integration_points_json,
    prm_details_json, input_schema_json, output_schema_json,
    trigger_config_json, deployment_info_json, logging_json,
    monitoring_json, security_json
) VALUES (
    'Datascribe Transcript Agent',
    '0.9.0',
    'Transcribes audio/video content using a STT (Speech-to-Text) transform, cleans/formats the transcript, and optionally generates summaries or keyword lists using an LLM transform. Input from IONPOD, output to IONPOD, managed by IONWALL.',
    'development',
    '---
version: "0.1.0"
name: "datascribe_transcript_agent_fluxgraph"
description: "Transcribes audio/video, formats, and optionally summarizes."

triggers:
  - type: "manual"
  - type: "event_driven"
    config: { event_source: "IONPOD", event_type: "new_media_file_for_transcription" }

input_schema:
  type: "object"
  properties:
    media_file_cid: { type: "string", description: "IPFS CID of the audio/video file in IONPOD." }
    transcription_options: { type: "object", properties: { language: {type: "string", default: "en-US"}, generate_summary: {type: "boolean", default: false} } }
  required: [media_file_cid]

output_schema:
  type: "object"
  properties:
    transcript_cid: { type: "string", description: "IPFS CID of the formatted transcript." }
    summary_cid: { type: "string", nullable: true, description: "IPFS CID of the summary, if generated." }
    keywords_cid: { type: "string", nullable: true, description: "IPFS CID of keywords list, if generated." }
    status: { type: "string", enum: ["success", "failure"] }
    error_message: { type: "string", nullable: true }

graph:
  - id: "fetch_media_file"
    transform: "FetchFromIONPOD_Transform_IONWALL"
    ionwall_approval_scope: "read_media_for_transcription"
    inputs:
      cid: "{{trigger.input_data.media_file_cid}}"
    outputs: [media_data]

  - id: "transcribe_media"
    transform: "SpeechToText_Transform_VendorA" # Placeholder for a specific STT transform
    ionwall_approval_scope: "stt_processing_datascribe"
    inputs:
      audio_data: "{{nodes.fetch_media_file.outputs.media_data}}"
      language: "{{trigger.input_data.transcription_options.language}}"
    outputs: [raw_transcript, confidence_score]

  - id: "format_transcript"
    transform: "TextFormat_Clean_Transform" # Placeholder for a text formatting transform
    inputs:
      text_in: "{{nodes.transcribe_media.outputs.raw_transcript}}"
      formatting_rules: "standard_transcript_ruleset"
    outputs: [formatted_transcript]

  - id: "store_transcript"
    transform: "StoreToIONPOD_Transform_IONWALL"
    ionwall_approval_scope: "write_transcript_datascribe"
    inputs:
      data_to_store: "{{nodes.format_transcript.outputs.formatted_transcript}}"
      metadata: { agent_name: "Datascribe Transcript Agent", source_cid: "{{trigger.input_data.media_file_cid}}", type: "transcript" }
    outputs: [transcript_cid_val]

  # Conditional path for summary generation
  - id: "check_if_summary_needed"
    transform: "ConditionalRouter_Transform" # Evaluates a condition
    inputs:
      condition: "{{trigger.input_data.transcription_options.generate_summary}} == true"
    outputs: [route_to_summary, route_to_end]

  - id: "generate_summary_llm"
    transform: "MuseGen_LLM_Transform"
    if: "{{nodes.check_if_summary_needed.outputs.route_to_summary}}"
    ionwall_approval_scope: "llm_summarization_datascribe"
    inputs:
      prompt_template: "Summarize the following transcript concisely: {{nodes.format_transcript.outputs.formatted_transcript}}"
      llm_config: { model_id: "claude-3-haiku", max_tokens: 512 }
    outputs: [summary_text]

  - id: "store_summary"
    transform: "StoreToIONPOD_Transform_IONWALL"
    if: "{{nodes.check_if_summary_needed.outputs.route_to_summary}}"
    ionwall_approval_scope: "write_summary_datascribe"
    inputs:
      data_to_store: "{{nodes.generate_summary_llm.outputs.summary_text}}"
      metadata: { agent_name: "Datascribe Transcript Agent", source_cid: "{{trigger.input_data.media_file_cid}}", type: "summary" }
    outputs: [summary_cid_val]

  - id: "publish_completion_event"
    transform: "IPC_NATS_Publish_Transform"
    inputs:
      topic: "ionflux.agents.datascribe.completion"
      message:
        status: "success"
        transcript_cid: "{{nodes.store_transcript.outputs.transcript_cid_val}}"
        summary_cid: "{{nodes.store_summary.outputs.summary_cid_val if nodes.store_summary else null}}"
    dependencies: [store_transcript, store_summary] # Depends on both, even if summary is conditional
',
    '{
        "transforms_required": ["FetchFromIONPOD_Transform_IONWALL", "SpeechToText_Transform_VendorA", "TextFormat_Clean_Transform", "StoreToIONPOD_Transform_IONWALL", "ConditionalRouter_Transform", "MuseGen_LLM_Transform", "IPC_NATS_Publish_Transform"],
        "min_ram_mb": 1024, "gpu_required": false,
        "estimated_execution_duration_seconds_per_minute_of_media": 60,
        "wasm_modules_cids": {
            "FetchFromIONPOD_Transform_IONWALL": "bafy...", "SpeechToText_Transform_VendorA": "bafy...", "TextFormat_Clean_Transform": "bafy...",
            "StoreToIONPOD_Transform_IONWALL": "bafy...", "ConditionalRouter_Transform": "bafy...", "MuseGen_LLM_Transform": "bafy...", "IPC_NATS_Publish_Transform": "bafy..."
        }
    }',
    '{
        "ionwall_permissions_needed": ["read_pod_data:{{trigger.input_data.media_file_cid}}", "stt_processing", "llm_summarization_optional", "write_pod_data:transcript", "write_pod_data:summary_optional"],
        "ionpod_data_access": {
            "inputs": [{ "cid_param": "media_file_cid", "access_type": "read", "purpose": "Media file for transcription." }],
            "outputs": [
                { "cid_name": "transcript_cid", "access_type": "write", "purpose": "Generated transcript." },
                { "cid_name": "summary_cid", "access_type": "write", "purpose": "Generated summary (optional)." }
            ]
        },
        "tokenomic_triggers": [
            { "event": "fluxgraph_successful_completion", "action": "reward_user", "token_id": "$ION", "amount_formula": "media_duration_minutes * 0.005" },
            { "event": "transform_SpeechToText_invocation", "action": "debit_user_compute_credits", "token_id": "C-ION", "amount_formula": "media_duration_seconds * 0.0002" }
        ],
        "techgnosis_integration": { "entity_extraction_from_transcript": true, "topic_modeling_on_transcript": true },
        "hybrid_layer_escalation_points": [{ "condition": "low_stt_confidence_score", "action": "human_review_transcript_segment" }, {"condition": "user_flagged_inaccuracy", "action":"human_review_full_transcript"}],
        "carbon_loop_contribution": { "type": "data_efficiency_gain", "value_formula": "information_density_increase_factor_vs_raw_media" }
    }',
    '{
        "default_stt_language": "en-US", "allow_user_language_override": true,
        "default_summary_llm_config": { "model_id": "claude-3-haiku", "temperature": 0.5, "max_tokens": 512 },
        "user_customizable_params": ["transcription_options.generate_summary", "transcription_options.language", "default_summary_llm_config.model_id"]
    }',
    '{
        "type": "object", "properties": {
            "media_file_cid": { "type": "string", "description": "IPFS CID of the audio/video file in IONPOD." },
            "transcription_options": { "type": "object", "properties": { "language": {"type": "string", "default": "en-US"}, "generate_summary": {"type": "boolean", "default": false} } }
        }, "required": ["media_file_cid"]
    }',
    '{
        "type": "object", "properties": {
            "transcript_cid": { "type": "string", "description": "IPFS CID of the formatted transcript." },
            "summary_cid": { "type": "string", "nullable": true, "description": "IPFS CID of the summary, if generated." },
            "keywords_cid": { "type": "string", "nullable": true, "description": "IPFS CID of keywords list, if generated." },
            "status": { "type": "string", "enum": ["success", "failure"] },
            "error_message": { "type": "string", "nullable": true },
            "usage_metrics": {"type": "object", "properties": {"stt_processing_time_ms": {"type": "integer"}, "llm_tokens_processed": {"type": "integer"}}}
        }, "required": ["transcript_cid", "status"]
    }',
    '{
        "manual_trigger_enabled": true,
        "event_driven_triggers": [ { "event_source": "IONPOD", "event_type": "new_media_file_for_transcription", "filter_expression": "file.metadata.ionflux_process == true && (file.contentType == ''audio/mpeg'' || file.contentType == ''video/mp4'')" } ]
    }',
    '{
        "runtime_environment": "IONFLUX_EdgeNode_Wasm", "default_replicas": 1,
        "auto_scaling_policy": { "min_replicas": 1, "max_replicas": 3, "cpu_threshold_percentage": 75, "queue_length_threshold": 10 }
    }',
    '{ "log_level": "warn", "log_targets": ["ionpod_event_log"], "log_retention_policy_days": 60 }',
    '{ "metrics_to_collect": ["execution_time", "stt_accuracy_proxy", "error_rate"], "metrics_endpoint_ionwall_protected": "/metrics/datascribe_agent", "health_check_protocol": "api_endpoint_status" }',
    '{
        "data_encryption_at_rest_ionpod": true, "data_encryption_in_transit_ipfs_ionwall": true,
        "required_ionwall_consent_scopes": ["read_pod_data", "write_pod_data", "stt_processing", "llm_summarization_optional"],
        "pii_detection_and_redaction_options": ["financial_info_redaction", "personal_names_pseudonymization"],
        "hipaa_compliance_features_enabled_if_media_is_health_related": true
    }'
);

-- Agent 003: Comm Link Agent
INSERT INTO agent_definitions (agent_name, version, description, status, flux_graph_dsl_yaml, execution_requirements_json, ecosystem_integration_points_json, prm_details_json, input_schema_json, output_schema_json, trigger_config_json, deployment_info_json, logging_json, monitoring_json, security_json)
VALUES ('Comm Link Agent', '0.9.0', 'Manages communications via various channels (email, NATS, Matrix). Uses templates for messages and integrates with IONWALL for permissions and IONPOD for contact lists or message history.', 'development', '{/* Full YAML DSL */}', '{/* Exec Requirements */}', '{/* Ecosystem Integrations */}', '{/* PRM Details */}', '{/* Input Schema */}', '{/* Output Schema */}', '{/* Trigger Config */}', '{/* Deployment Info */}', '{/* Logging */}', '{/* Monitoring */}', '{/* Security */}');

-- Agent 004: Symbiosis Plugin Agent
INSERT INTO agent_definitions (agent_name, version, description, status, flux_graph_dsl_yaml, execution_requirements_json, ecosystem_integration_points_json, prm_details_json, input_schema_json, output_schema_json, trigger_config_json, deployment_info_json, logging_json, monitoring_json, security_json)
VALUES ('Symbiosis Plugin Agent', '0.9.0', 'Handles integration with third-party plugins and APIs (e.g., external data sources, specialized computation services) securely, managed by IONWALL policies and potentially using TechGnosis for semantic mapping.', 'development', '{/* Full YAML DSL */}', '{/* Exec Requirements */}', '{/* Ecosystem Integrations */}', '{/* PRM Details */}', '{/* Input Schema */}', '{/* Output Schema */}', '{/* Trigger Config */}', '{/* Deployment Info */}', '{/* Logging */}', '{/* Monitoring */}', '{/* Security */}');

-- Agent 005: Chronos Task Agent
INSERT INTO agent_definitions (agent_name, version, description, status, flux_graph_dsl_yaml, execution_requirements_json, ecosystem_integration_points_json, prm_details_json, input_schema_json, output_schema_json, trigger_config_json, deployment_info_json, logging_json, monitoring_json, security_json)
VALUES ('Chronos Task Agent', '0.9.0', 'Manages scheduled tasks, reminders, and workflow automation based on time events. Leverages system cron capabilities or internal scheduler, interacts with IONPOD for task parameters and IONFLUX Controller for execution.', 'development', '{/* Full YAML DSL */}', '{/* Exec Requirements */}', '{/* Ecosystem Integrations */}', '{/* PRM Details */}', '{/* Input Schema */}', '{/* Output Schema */}', '{/* Trigger Config */}', '{/* Deployment Info */}', '{/* Logging */}', '{/* Monitoring */}', '{/* Security */}');

-- Agent 006: Guardian Compliance Agent
INSERT INTO agent_definitions (agent_name, version, description, status, flux_graph_dsl_yaml, execution_requirements_json, ecosystem_integration_points_json, prm_details_json, input_schema_json, output_schema_json, trigger_config_json, deployment_info_json, logging_json, monitoring_json, security_json)
VALUES ('Guardian Compliance Agent', '0.9.0', 'Monitors activities across agents and IONPOD for compliance with user-defined policies, data governance rules, and IONWALL settings. Can flag or halt non-compliant actions and integrates with Hybrid Layer for human review.', 'development', '{/* Full YAML DSL */}', '{/* Exec Requirements */}', '{/* Ecosystem Integrations */}', '{/* PRM Details */}', '{/* Input Schema */}', '{/* Output Schema */}', '{/* Trigger Config */}', '{/* Deployment Info */}', '{/* Logging */}', '{/* Monitoring */}', '{/* Security */}');

-- Agent 007: Scribe Code Gen Agent
INSERT INTO agent_definitions (agent_name, version, description, status, flux_graph_dsl_yaml, execution_requirements_json, ecosystem_integration_points_json, prm_details_json, input_schema_json, output_schema_json, trigger_config_json, deployment_info_json, logging_json, monitoring_json, security_json)
VALUES ('Scribe Code Gen Agent', '0.9.0', 'Generates code snippets, boilerplate, or full scripts in various languages based on specifications from user prompts, IONPOD data structures, or other agent outputs. Uses specialized code-gen LLMs via MuseGen_LLM_Transform.', 'development', '{/* Full YAML DSL */}', '{/* Exec Requirements */}', '{/* Ecosystem Integrations */}', '{/* PRM Details */}', '{/* Input Schema */}', '{/* Output Schema */}', '{/* Trigger Config */}', '{/* Deployment Info */}', '{/* Logging */}', '{/* Monitoring */}', '{/* Security */}');

-- Agent 008: Canvas Render Agent
INSERT INTO agent_definitions (agent_name, version, description, status, flux_graph_dsl_yaml, execution_requirements_json, ecosystem_integration_points_json, prm_details_json, input_schema_json, output_schema_json, trigger_config_json, deployment_info_json, logging_json, monitoring_json, security_json)
VALUES ('Canvas Render Agent', '0.9.0', 'Renders visual outputs (diagrams, charts, UI components) for the IONFLUX Canvas or other frontends. Takes structured data from IONPOD or agents and uses rendering transforms (e.g., VegaLite, MermaidJS, or custom Wasm renderers).', 'development', '{/* Full YAML DSL */}', '{/* Exec Requirements */}', '{/* Ecosystem Integrations */}', '{/* PRM Details */}', '{/* Input Schema */}', '{/* Output Schema */}', '{/* Trigger Config */}', '{/* Deployment Info */}', '{/* Logging */}', '{/* Monitoring */}', '{/* Security */}');

-- Agent 009: Wallet Ops Agent
INSERT INTO agent_definitions (agent_name, version, description, status, flux_graph_dsl_yaml, execution_requirements_json, ecosystem_integration_points_json, prm_details_json, input_schema_json, output_schema_json, trigger_config_json, deployment_info_json, logging_json, monitoring_json, security_json)
VALUES ('Wallet Ops Agent', '0.9.0', 'Interacts with IONWALLET for token transactions ($ION, C-ION, NFTs), NFT minting/management, and cryptographic operations (signing, verification), under strict IONWALL control and user consent.', 'development', '{/* Full YAML DSL */}', '{/* Exec Requirements */}', '{/* Ecosystem Integrations */}', '{/* PRM Details */}', '{/* Input Schema */}', '{/* Output Schema */}', '{/* Trigger Config */}', '{/* Deployment Info */}', '{/* Logging */}', '{/* Monitoring */}', '{/* Security */}');

-- Agent 010: ION Reactor Agent
INSERT INTO agent_definitions (agent_name, version, description, status, flux_graph_dsl_yaml, execution_requirements_json, ecosystem_integration_points_json, prm_details_json, input_schema_json, output_schema_json, trigger_config_json, deployment_info_json, logging_json, monitoring_json, security_json)
VALUES ('ION Reactor Agent', '0.9.0', 'Core system agent for managing and orchestrating other agents, dynamic FluxGraph modifications, system-level tasks, and responding to critical ecosystem events. Interacts heavily with IONFLUX Controller and TechGnosis for system state awareness.', 'development', '{/* Full YAML DSL */}', '{/* Exec Requirements */}', '{/* Ecosystem Integrations */}', '{/* PRM Details */}', '{/* Input Schema */}', '{/* Output Schema */}', '{/* Trigger Config */}', '{/* Deployment Info */}', '{/* Logging */}', '{/* Monitoring */}', '{/* Security */}');
