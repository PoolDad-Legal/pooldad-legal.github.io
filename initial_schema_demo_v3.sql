-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Trigger function to update 'updated_at' timestamp
CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Users Table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    name TEXT,
    password_hash TEXT NOT NULL,
    profile_info_json JSONB, -- Includes avatar_url, bio, user_preferences_json
    stripe_customer_id TEXT,
    payment_provider_details_json JSONB, -- For user as service provider/agent lister
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TRIGGER set_timestamp_users BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

-- Workspaces Table
CREATE TABLE workspaces (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    owner_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    member_user_ids_array UUID[], -- Array of user UUIDs
    settings_json JSONB, -- Includes default_llm_config, timezone, kafka_topics, secret_refs
    status TEXT NOT NULL DEFAULT 'active', -- enum: 'active', 'archived', 'suspended'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TRIGGER set_timestamp_workspaces BEFORE UPDATE ON workspaces FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

-- Brands Table
CREATE TABLE brands (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description_text TEXT,
    industry TEXT,
    target_audience_description_text TEXT,
    brand_voice_guidelines_text TEXT,
    visual_identity_assets_json JSONB, -- {logo_url, color_palette_array, font_preferences_array}
    mood_board_urls_array TEXT[],
    persona_guardian_namespace_id TEXT, -- Conceptually links to a Pinecone namespace
    shopify_integration_details_json JSONB, -- {store_url, access_token_secret_ref, last_sync_status, last_sync_timestamp}
    tiktok_integration_details_json JSONB, -- {profile_url, access_token_secret_ref, last_sync_status, last_sync_timestamp}
    status TEXT NOT NULL DEFAULT 'active', -- enum: 'active', 'archived'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TRIGGER set_timestamp_brands BEFORE UPDATE ON brands FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

-- Creators Table
CREATE TABLE creators (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    niche_tags_array TEXT[],
    bio_text TEXT,
    portfolio_links_array TEXT[],
    audience_demographics_json JSONB,
    persona_guardian_namespace_id TEXT,
    tiktok_integration_details_json JSONB, -- {handle, access_token_secret_ref}
    status TEXT NOT NULL DEFAULT 'active', -- enum: 'active', 'archived'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TRIGGER set_timestamp_creators BEFORE UPDATE ON creators FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

-- PromptLibraries Table
CREATE TABLE prompt_libraries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description_text TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TRIGGER set_timestamp_prompt_libraries BEFORE UPDATE ON prompt_libraries FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

-- Prompts Table
CREATE TABLE prompts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    library_id UUID NOT NULL REFERENCES prompt_libraries(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    prompt_text TEXT NOT NULL,
    variables_schema_json_array JSONB, -- Array of {name, type, description, is_required, default_value}
    tags_array TEXT[],
    version INTEGER NOT NULL DEFAULT 1,
    created_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL, -- Allow null if user is deleted
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TRIGGER set_timestamp_prompts BEFORE UPDATE ON prompts FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

-- AgentDefinitions Table
CREATE TABLE agent_definitions (
    id TEXT PRIMARY KEY, -- e.g., 'agent_001', 'agent_004_refactored'
    name TEXT NOT NULL, -- Human-readable name
    version TEXT NOT NULL, -- Semver
    definition_status TEXT NOT NULL DEFAULT 'prm_active', -- enum: 'prm_active', 'experimental', 'beta', 'production', 'deprecated'
    prm_details_json JSONB, -- Stores narrative: epithet, tagline, intro, archetype, capabilities, etc.
    triggers_config_json_array JSONB, -- Array of: {type, description, default_config_json, is_user_overridable}
    inputs_schema_json_array JSONB, -- Array of: {key_name, data_type, is_required, description, default_value, example_value}
    outputs_config_json_array JSONB, -- Array of: {key_name, data_type, description, example_value, target_event_type}
    stack_details_json JSONB, -- {primary_language, primary_runtime, llm_models_used_array, vector_db_dependencies_array, etc.}
    deployment_info_json JSONB, -- {ci_cd_examples_array, hosting_platform_examples_array, default_file_structure_template_text}
    memory_config_json JSONB, -- {required, type, default_namespace_template, description}
    category_tags_array TEXT[],
    underlying_platform_services_required_array TEXT[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TRIGGER set_timestamp_agent_definitions BEFORE UPDATE ON agent_definitions FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

-- AgentConfigurations Table
CREATE TABLE agent_configurations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    agent_definition_id TEXT NOT NULL REFERENCES agent_definitions(id) ON DELETE RESTRICT,
    name TEXT NOT NULL,
    description_text TEXT,
    created_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL, -- Allow null if user is deleted
    yaml_config_text TEXT NOT NULL,
    effective_config_cache_json JSONB,
    resolved_memory_namespace_text TEXT,
    status TEXT NOT NULL DEFAULT 'active', -- enum: 'active', 'inactive', 'archived', 'error_requires_review'
    last_run_summary_json JSONB, -- {run_id, status, timestamp, output_preview_text}
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (workspace_id, name)
);
CREATE TRIGGER set_timestamp_agent_configurations BEFORE UPDATE ON agent_configurations FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

-- AgentRunLogs Table
CREATE TABLE agent_run_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), -- Internal DB id
    run_id UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(), -- Public unique ID for this run
    agent_configuration_id UUID NOT NULL REFERENCES agent_configurations(id) ON DELETE CASCADE,
    agent_definition_id_version TEXT NOT NULL, -- e.g., 'agent_001/0.1'
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    triggered_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    trigger_type TEXT NOT NULL, -- enum: 'manual_ui', 'manual_command', 'schedule', 'webhook', 'event_api_call'
    status TEXT NOT NULL, -- enum: 'pending', 'running', 'success', 'error', 'cancelled_by_user', 'cancelled_by_system'
    start_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    end_time TIMESTAMPTZ,
    input_params_resolved_json JSONB, -- Snapshot of effective_config used for this run
    output_data_json JSONB, -- Stores actual output: {"outputs_array": [{"key_name": "...", "value": "...", "storage_ref_url": "..."}]}
    output_preview_text TEXT,
    error_details_json JSONB, -- {error_code, error_message_text, stack_trace_text}
    logs_storage_ref_url TEXT, -- URI to detailed execution logs (e.g., S3, Loki)
    kpi_results_json JSONB, -- Agent-reported KPIs for this run
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW() -- Log entry creation time
);

-- Playbooks Table
CREATE TABLE playbooks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description_text TEXT,
    trigger_event_schema_json JSONB NOT NULL, -- {source_service, event_type, filter_conditions_json}
    target_audience_segment_id TEXT, -- Could reference a future 'audience_segments' table
    steps_json_array JSONB NOT NULL, -- Sequence of actions: {step_id, name, delay, action_type, action_config_json, conditions_array, default_next_step_id}
    status TEXT NOT NULL DEFAULT 'draft', -- enum: 'draft', 'active', 'paused', 'archived'
    performance_metrics_json JSONB, -- {total_triggered, total_completed, conversion_rate}
    created_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TRIGGER set_timestamp_playbooks BEFORE UPDATE ON playbooks FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

-- CanvasPages Table
CREATE TABLE canvas_pages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    parent_page_id UUID REFERENCES canvas_pages(id) ON DELETE SET NULL, -- Allow null if parent is deleted
    title TEXT NOT NULL,
    icon_url TEXT,
    status TEXT NOT NULL DEFAULT 'active', -- enum: 'active', 'archived', 'template_draft'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TRIGGER set_timestamp_canvas_pages BEFORE UPDATE ON canvas_pages FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

-- CanvasBlocks Table
CREATE TABLE canvas_blocks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    page_id UUID NOT NULL REFERENCES canvas_pages(id) ON DELETE CASCADE,
    type TEXT NOT NULL, -- e.g., 'text', 'agent_snippet', 'json_display', 'embed_panel'
    content_json JSONB,
    position_x INTEGER NOT NULL DEFAULT 0,
    position_y INTEGER NOT NULL DEFAULT 0,
    width INTEGER NOT NULL DEFAULT 100,
    height INTEGER NOT NULL DEFAULT 100,
    z_index INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TRIGGER set_timestamp_canvas_blocks BEFORE UPDATE ON canvas_blocks FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

-- ChatChannels Table
CREATE TABLE chat_channels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'public', -- enum: 'public', 'private', 'dm', 'agent_dedicated'
    description_text TEXT,
    member_user_ids_array UUID[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TRIGGER set_timestamp_chat_channels BEFORE UPDATE ON chat_channels FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

-- ChatMessages Table
CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    channel_id UUID NOT NULL REFERENCES chat_channels(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL, 
    sender_type TEXT NOT NULL, -- enum: 'user', 'agent', 'system'
    content_type TEXT NOT NULL DEFAULT 'text', -- enum: 'text', 'markdown', 'json_data', 'interactive_proposal', 'file_attachment', 'agent_status_update'
    content_json JSONB NOT NULL,
    thread_id UUID REFERENCES chat_messages(id) ON DELETE CASCADE,
    reactions_json_array JSONB, -- Array of {emoji, user_ids_array}
    read_by_user_ids_array UUID[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ -- Optional, if messages can be edited
);
CREATE TRIGGER set_timestamp_chat_messages BEFORE UPDATE ON chat_messages FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

-- Indexes
CREATE INDEX idx_workspaces_owner_user_id ON workspaces(owner_user_id);
CREATE INDEX idx_brands_workspace_id ON brands(workspace_id);
CREATE INDEX idx_creators_workspace_id ON creators(workspace_id);
CREATE INDEX idx_prompt_libraries_workspace_id ON prompt_libraries(workspace_id);
CREATE INDEX idx_prompts_library_id ON prompts(library_id);
CREATE INDEX idx_agent_configurations_workspace_id ON agent_configurations(workspace_id);
CREATE INDEX idx_agent_configurations_agent_definition_id ON agent_configurations(agent_definition_id);
CREATE INDEX idx_agent_run_logs_agent_configuration_id ON agent_run_logs(agent_configuration_id);
CREATE INDEX idx_agent_run_logs_run_id ON agent_run_logs(run_id);
CREATE INDEX idx_agent_run_logs_workspace_id ON agent_run_logs(workspace_id);
CREATE INDEX idx_playbooks_workspace_id ON playbooks(workspace_id);
CREATE INDEX idx_canvas_pages_workspace_id ON canvas_pages(workspace_id);
CREATE INDEX idx_canvas_blocks_page_id ON canvas_blocks(page_id);
CREATE INDEX idx_chat_channels_workspace_id ON chat_channels(workspace_id);
CREATE INDEX idx_chat_messages_channel_id ON chat_messages(channel_id);
CREATE INDEX idx_chat_messages_thread_id ON chat_messages(thread_id);

-- Seed Data
-- Insert a demo User
INSERT INTO users (email, name, password_hash, profile_info_json) VALUES
('demo@ionflux.ai', 'Demo User', '$2b$12$D2xOAY4bZ.İNVENTED.HASH.PLEASE.REPLACE', '{"avatar_url": null, "bio": "IONFLUX Demo User", "user_preferences_json": {"notifications": "all", "theme": "dark"}}'); -- Replace with a real bcrypt hash

-- Insert a demo Workspace
INSERT INTO workspaces (name, owner_user_id, settings_json) VALUES
('Demo Workspace', (SELECT id FROM users WHERE email = 'demo@ionflux.ai'), 
'{"default_llm_config": {"provider": "openai", "model": "gpt-4o"}, "default_timezone": "America/New_York", "active_kafka_topics_list": ["ionflux.shopify.ws_demo.orders.created", "ionflux.demo.custom_events"], "pinecone_api_key_secret_ref": "projects/ionflux-demo/secrets/pinecone_api_key/versions/latest", "generic_secrets_config_json": {"my_sendgrid_key": "projects/ionflux-demo/secrets/sendgrid_demo_ws/versions/latest"}}');

-- Seed AgentDefinitions (Example for Agent 004 - Shopify Sales Sentinel v2)
-- NOTE: The JSONB fields below should contain the *actual stringified JSON or YAML snippets* from core_agent_blueprints_v3.md.
-- For brevity, only the structure and key parts are shown for agent_004_refactored. Others are more placeholder-like.
-- This seed data IS NOT COMPLETE and needs full JSON/YAML content from the blueprints.
INSERT INTO agent_definitions (
    id, name, version, definition_status, 
    prm_details_json, 
    triggers_config_json_array, 
    inputs_schema_json_array, 
    outputs_config_json_array, 
    stack_details_json, 
    deployment_info_json, 
    memory_config_json, 
    category_tags_array, 
    underlying_platform_services_required_array
) VALUES 
(
    'agent_004_refactored', 
    'Shopify Sales Sentinel v2', 
    '0.2', 
    'prm_active',
    '{
        "epithet": "O Guardião Preditivo do Fluxo de Caixa da Loja",
        "tagline": "ANTECIPA A FALHA, PROTEGE O LUCRO, MAXIMIZA O GMV — EM TEMPO REAL",
        "introduction_text": "(Full intro text from PRM Agent 004)",
        "archetype": "Guardian-Engineer aprimorado por Strategist",
        "dna_phrase": "Protege o fluxo vital e aprende com cada falha",
        "core_capabilities_array": [
            "Realtime Pulse (Aprimorado): Ingestão e monitoramento preditivo contínuo...",
            "Anomaly Guardian (Preditivo e Adaptativo): Utiliza modelos de ML/Estatística...",
            "App-Impact Radar (Baseado em Embeddings): Analisa a correlação entre mudanças...",
            "LLM Root-Cause Analyzer (Novo): Módulo assistido por LLM (GPT-4o)...",
            "Adaptive Remediation Orchestrator (Aprimorado Rollback): Orquestra sequências...",
            "Incremental GMV Protector (KPI Core): O KPI central..."
        ],
        "essence_punch_text": "Checkout que trava é faca no fluxo — o Sentinel a arranca.",
        "essence_interpretation_text": "age brutalmente; prefere remover feature a deixar receita sangrar.",
        "ipo_flow_description_text": "(Detailed IPO from PRM Agent 004, e.g., Consumes Kafka events from Shopify, processes with Flink/Spark, uses ML for anomaly detection, LLM for root cause, LangGraph/Temporal for remediation workflows, outputs incidents and alerts.)",
        "strategic_integrations_text": "Shopify (deep), Kafka (core), TimescaleDB, LLM Orchestration, Agent007 (SlackBriefButler), PagerDuty/OpsGenie, Jira.",
        "scheduling_triggers_summary_text": "Primary: Continuous Kafka stream consumption. Scheduled: Every 5 mins for health checks/model updates. Breaker: Escalates on repeated failures or high GMV impact.",
        "kpis_definition_text": "Core: Incremental GMV Protected. Process: MTTD, MTTR. Quality: Anomaly Detection Accuracy, Root Cause Analysis Accuracy. System: Model drift, Remediation success rate.",
        "failure_fallback_strategy_text": "Adaptive remediation with multiple steps; if automated actions fail or GMV impact is critical, escalates to human intervention via PagerDuty/OpsGenie and creates high-priority Jira tickets.",
        "example_integrated_scenario_text": "(Full example from PRM Agent 004, e.g., Social proof app bug scenario)",
        "dynamic_expansion_notes_text": "V1.1 (Self-Healing Code Suggestions), V2.0 (Cross-Merchant Anomaly Benchmarking)",
        "escape_the_obvious_feature_text": "Pre-emptive Price/Inventory Sync Check before major campaigns."
    }'::jsonb,
    '[
        {"type": "event_stream", "description_text": "Consumes raw Shopify events.", "default_config_json": {"kafka_topic_name": "ionflux.shopify.workspace_{{workspace_id}}.events_raw", "kafka_consumer_group_suffix": "sales_sentinel_v2_events_consumer"}, "is_user_overridable": false},
        {"type": "event_stream", "description_text": "Consumes processed performance metrics.", "default_config_json": {"kafka_topic_name": "ionflux.performance.workspace_{{workspace_id}}.metrics_processed", "kafka_consumer_group_suffix": "sales_sentinel_v2_metrics_consumer"}, "is_user_overridable": false},
        {"type": "schedule", "description_text": "Periodic health checks and model updates.", "default_config_json": {"cron_expression": "*/5 * * * *", "task": "periodic_health_check_and_model_update"}, "is_user_overridable": true}
    ]'::jsonb,
    '[
        {"key_name": "shopify_event_payload", "data_type": "json", "is_required": false, "description_text": "Raw Shopify webhook event (orders, products, themes, apps)."},
        {"key_name": "performance_metric_payload", "data_type": "json", "is_required": false, "description_text": "Aggregated performance metrics (CVR, AOV, site speed, error rates)."}
    ]'::jsonb,
    '[
        {"key_name": "incident_analysis_report", "data_type": "json", "description_text": "Structured JSON report detailing detected anomaly, root cause analysis, actions taken, and GMV impact."},
        {"key_name": "alert_to_brief_butler", "data_type": "json", "description_text": "Payload for Agente 007 to deliver a contextualized alert."}
    ]'::jsonb,
    '{
        "primary_language": "python",
        "primary_runtime": "FastAPI, Flink/Spark Streaming, LangGraph/Temporal",
        "llm_models_used_array": [{"provider": "openai", "model_name": "gpt-4o", "purpose": "root cause analysis"}],
        "vector_db_dependencies_array": [{"name": "Pinecone", "usage_description": "embeddings of error logs, app/theme descriptions for root cause analysis"}],
        "queue_dependencies_array": [{"name": "Kafka", "usage_description": "event ingestion"}, {"name": "Redis + RQ", "usage_description": "discrete remediation tasks"}],
        "database_dependencies_array": [{"name": "TimescaleDB", "usage_description": "shop_performance_metrics"}, {"name": "Postgres", "usage_description": "agent configuration, incident logs"}],
        "other_integrations_array": [{"name": "Shopify Admin API", "usage_description": "data fetching, remediation actions"}, {"name": "Agent007 (SlackBriefButler)", "usage_description": "alert delivery"}],
        "observability_stack_notes_text": "Exports OpenTelemetry to Prometheus, Grafana (SalesPulse Sentinel Dashboard), Loki, Jaeger."
    }'::jsonb,
    '{
        "ci_cd_examples_array": ["GitHub Actions + Docker Buildx"],
        "hosting_platform_examples_array": ["Kubernetes (for Flink/Spark, API services)"],
        "default_file_structure_template_text": "/agents/sales_sentinel/\n  ├── agent.py\n  ├── anomaly.py\n  ├── rootcause.py\n  ├── actions.py\n  ├── prompts.yaml\n  ├── tests/\n  │   └── test_anomaly.py\n  └── assets/\n      └── backup/\n          └── theme.zip"
    }'::jsonb,
    '{
        "required": true,
        "type": "pinecone",
        "default_namespace_template": "sentinel_rc_embeddings_ws_{{workspace_id}}",
        "description_text": "Stores embeddings of error logs, app/theme descriptions for root cause analysis."
    }'::jsonb,
    '{"E-commerce", "Monitoring", "Automation", "Analytics", "Shopify"}'::text[],
    '{"Shopify_Integration", "LLM_Orchestration", "Kafka_Bus", "Chat_Service"}'::text[]
),
(
    'agent_001', 'Email Wizard', '0.1', 'prm_active', 
    '{"epithet": "O Xamã que Conjura Receita no Silêncio do E-mail", "tagline": "INBOX ≠ ARQUIVO MORTO; INBOX = ARMA VIVA", "introduction_text": "(Full intro from PRM Agent 001)", "core_capabilities_array": ["Hyper-Segment", "Dopamine Drip"]}'::jsonb,
    '[{"type": "schedule", "default_config_json": {"cron_expression": "0 */2 * * *"}}, {"type": "webhook", "default_config_json": {"webhook_path_suffix": "/emailwizard/run"}}]'::jsonb,
    '[{"key_name": "shopify_event", "data_type": "json", "is_required": false}, {"key_name": "manual_payload", "data_type": "json", "is_required": false}]'::jsonb,
    '[{"key_name": "send_report", "data_type": "json"}]'::jsonb,
    '{"primary_language": "python", "primary_runtime": "LangChain, LangGraph", "llm_models_used_array": [{"provider": "openai", "model_name": "gpt-4o"}, {"provider": "anthropic", "model_name": "claude-3-haiku"}], "vector_db_dependencies_array": [{"name": "Pinecone"}], "queue_dependencies_array": [{"name": "Redis + RQ"}]}'::jsonb,
    '{"default_file_structure_template_text": "/agents/emailwizard/..."}'::jsonb,
    '{"type": "pinecone", "default_namespace_template": "emailwizard_personas_ws_{{workspace_id}}"}'::jsonb,
    '{"Email", "Marketing", "Automation"}'::text[],
    '{"LLM_Orchestration", "Email_Dispatch", "Shopify_Integration"}'::text[]
),
(
    'agent_010_refactored', 'Revenue Tracker Lite v2', '0.2', 'prm_active',
    '{"epithet": "O Analista Financeiro Pessoal da Sua Loja...", "tagline": "FATURAMENTO É VAIDADE, LUCRO É SANIDADE...", "introduction_text": "(Full intro for Agent 010)", "core_capabilities_array": ["Automated Cost Ingestor", "Real-time Margin Calculator"]}'::jsonb,
    '[{"type": "webhook", "default_config_json": {"webhook_path_suffix": "/revenue_tracker/shopify_event"}}, {"type": "schedule", "default_config_json": {"cron_expression": "0 5 * * *"}}]'::jsonb,
    '[{"key_name": "shopify_order_payload", "data_type": "json", "is_required": false}, {"key_name": "manual_cost_inputs", "data_type": "json", "is_required": false}]'::jsonb,
    '[{"key_name": "profitability_dashboard_data_json", "data_type": "json"}, {"key_name": "profitability_digest_markdown", "data_type": "markdown"}]'::jsonb,
    '{"primary_language": "python", "primary_runtime": "FastAPI, Pandas", "llm_models_used_array": [{"provider": "openai", "model_name": "gpt-4o", "purpose": "actionable suggestions"}]}'::jsonb,
    '{"default_file_structure_template_text": "/agents/revenue_tracker/..."}'::jsonb,
    '{"type": "none"}'::jsonb,
    '{"E-commerce", "Analytics", "Finance", "Shopify"}'::text[],
    '{"Shopify_Integration", "LLM_Orchestration"}'::text[]
),
(
    'agent_008_refactored', 'Creator Persona Guardian v2', '0.2', 'prm_active',
    '{"epithet": "O Guardião Algorítmico da Alma Criativa...", "tagline": "SUA VOZ É ÚNICA...", "introduction_text": "(Full intro for Agent 008)", "core_capabilities_array": ["Multimodal Persona Definition & Extraction", "Content Authenticity & Resonance Scoring"]}'::jsonb,
    '[{"type": "webhook", "default_config_json": {"webhook_path_suffix": "/persona_guardian/validate_content"}}, {"type": "event"}, {"type": "schedule", "default_config_json": {"cron_expression": "0 0 * * 0"}}]'::jsonb,
    '[{"key_name": "creator_id_or_brand_id", "data_type": "string", "is_required": true}, {"key_name": "content_to_analyze_text", "data_type": "string", "is_required": false}]'::jsonb,
    '[{"key_name": "authenticity_score", "data_type": "float"}, {"key_name": "repaired_content_suggestions_json", "data_type": "json"}]'::jsonb,
    '{"primary_language": "python", "primary_runtime": "FastAPI, LangChain, LangGraph", "llm_models_used_array": [{"provider": "openai", "model_name": "gpt-4o-vision"}, {"provider": "anthropic", "model_name": "claude-3-haiku"}], "vector_db_dependencies_array": [{"name": "Pinecone"}]}'::jsonb,
    '{"default_file_structure_template_text": "/agents/persona_guardian/..."}'::jsonb,
    '{"type": "pinecone", "default_namespace_template": "persona_fingerprints_ws_{{workspace_id}}_id_{{creator_id_or_brand_id}}"}'::jsonb,
    '{"Content Creation", "Brand Management", "AI"}'::text[],
    '{"LLM_Orchestration", "Audio_Service"}'::text[]
)
ON CONFLICT (id) DO UPDATE SET 
    name = EXCLUDED.name,
    version = EXCLUDED.version,
    definition_status = EXCLUDED.definition_status,
    prm_details_json = EXCLUDED.prm_details_json,
    triggers_config_json_array = EXCLUDED.triggers_config_json_array,
    inputs_schema_json_array = EXCLUDED.inputs_schema_json_array,
    outputs_config_json_array = EXCLUDED.outputs_config_json_array,
    stack_details_json = EXCLUDED.stack_details_json,
    deployment_info_json = EXCLUDED.deployment_info_json,
    memory_config_json = EXCLUDED.memory_config_json,
    category_tags_array = EXCLUDED.category_tags_array,
    underlying_platform_services_required_array = EXCLUDED.underlying_platform_services_required_array,
    updated_at = NOW();

-- Seed an initial AgentConfiguration for Shopify Sales Sentinel for the demo workspace
INSERT INTO agent_configurations (workspace_id, agent_definition_id, name, created_by_user_id, yaml_config_text, last_run_summary_json)
VALUES (
    (SELECT id FROM workspaces WHERE name = 'Demo Workspace'),
    'agent_004_refactored',
    'EcoThreads Boutique - Sales Sentinel Config',
    (SELECT id FROM users WHERE email = 'demo@ionflux.ai'),
    E'inputs:\n  min_order_value_alert_threshold: 100.00\n  # Note: Kafka topic for consumption is usually defined in AgentDefinition or by platform conventions for the workspace.\n  # User might override specific filters if AgentDefinition allows.\ntriggers:\n  - trigger_definition_key: "shopify_events_consumer" # Assuming this key matches a trigger in AgentDefinition\n    enabled: true\n    # Example of how a user might provide specific filter for this instance if the definition supports it.\n    # config_override:\n    #   event_filter_json:\n    #     payload_json.financial_status: "paid"\n    #     payload_json.total_price_usd_gt: 100.0 # Ensure this is a float for JSON\n',
    '{"status": "idle"}'::jsonb
) ON CONFLICT (workspace_id, name) DO NOTHING;

-- Seed a PromptLibrary and a Prompt for Email Wizard
INSERT INTO prompt_libraries (workspace_id, name, description_text) VALUES
((SELECT id FROM workspaces WHERE name = 'Demo Workspace'), 'Marketing Email Prompts', 'Collection of prompts for generating marketing email copy.')
ON CONFLICT DO NOTHING;

INSERT INTO prompts (library_id, name, prompt_text, variables_schema_json_array, created_by_user_id) VALUES
((SELECT id FROM prompt_libraries WHERE name = 'Marketing Email Prompts' AND workspace_id = (SELECT id FROM workspaces WHERE name = 'Demo Workspace')),
 'Exciting Product Promotion',
 'Generate an exciting promotional email for our product: {{product_name}}. Highlight its key benefits: {{key_benefits}}. The target audience is {{target_audience}}. Include a call to action: {{call_to_action}}.',
 '[{"name": "product_name", "type": "text", "description_text": "Name of the product", "is_required": true},
   {"name": "key_benefits", "type": "text", "description_text": "Comma-separated key benefits", "is_required": true},
   {"name": "target_audience", "type": "text", "description_text": "Description of the target audience", "is_required": true},
   {"name": "call_to_action", "type": "text", "description_text": "Desired call to action", "is_required": true}]'::jsonb,
 (SELECT id FROM users WHERE email = 'demo@ionflux.ai')
) ON CONFLICT DO NOTHING;

-- Seed a Canvas Page
INSERT INTO canvas_pages (workspace_id, title) VALUES
((SELECT id FROM workspaces WHERE name = 'Demo Workspace'), 'Q4 Campaign Planning')
ON CONFLICT DO NOTHING;

-- Seed Chat Channels
INSERT INTO chat_channels (workspace_id, name, type) VALUES
((SELECT id FROM workspaces WHERE name = 'Demo Workspace'), 'general', 'public'),
((SELECT id FROM workspaces WHERE name = 'Demo Workspace'), 'alerts', 'public')
ON CONFLICT DO NOTHING;


COMMENT ON TABLE agent_definitions IS 'Stores the immutable definition of various agent types, including their capabilities, schemas, and PRM narrative details. Content for JSONB fields often comes directly from agent blueprint YAMLs/JSONs.';
COMMENT ON TABLE agent_configurations IS 'Represents a user''s specific instance and configuration of an AgentDefinition within a workspace.';
COMMENT ON TABLE agent_run_logs IS 'Logs each execution of an agent configuration, capturing inputs, outputs, status, and errors.';
COMMENT ON TABLE playbooks IS 'Defines automated multi-step workflows that can involve triggering agents or other actions based on events.';
COMMENT ON COLUMN canvas_blocks.content_json IS 'JSONB content, structure depends on block type. For agent_snippet, expects { "agent_configuration_id": "uuid" }. For text, expects { "markdown_text": "text" }.';
COMMENT ON COLUMN chat_messages.content_json IS 'JSONB content. For text messages, expects { "text_body": "message content" }.';

```
