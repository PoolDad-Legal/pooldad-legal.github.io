-- /specs/database/agent_definitions.sql

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

    -- Core FluxGraph Definition (YAML content)
    flux_graph_dsl_yaml TEXT NOT NULL, -- Stores the YAML definition of the agent's FluxGraph

    -- Execution Requirements (JSONB)
    -- Details about transforms needed, compute resources, external dependencies, etc.
    execution_requirements_json JSONB,
    -- Example: {"transforms_required": ["FetchFromIONPOD", "MuseGen_LLM"], "min_ram_mb": 256, "gpu_required": false}

    -- Ecosystem Integration Points (JSONB)
    -- How this agent interacts with IONWALL, IONPOD, Tokenomics, TechGnosis, Hybrid Layer, Carbon Loop
    ecosystem_integration_points_json JSONB,
    -- Example: {"ionwall_permissions_needed": ["read_pod_data", "trigger_llm_inference"], "tokenomic_triggers": ["task_completion_reward"]}

    -- Parameters & Configuration (JSONB)
    -- Default parameters, configurable settings by the user or other agents
    prm_details_json JSONB,
    -- Example: {"default_prompt_template": "Summarize: {{input_text}}", "max_output_tokens": 500}

    -- Input/Output Schemas (JSONB)
    -- Defines the expected input data structure and the output data structure
    input_schema_json JSONB,
    output_schema_json JSONB,
    -- Example input_schema: {"type": "object", "properties": {"text_content": {"type": "string"}}}
    -- Example output_schema: {"type": "object", "properties": {"summary": {"type": "string"}}}

    -- Trigger Configuration (JSONB)
    -- Specific settings for how the agent is triggered (e.g., cron string for scheduled, event patterns)
    trigger_config_json JSONB,
    -- Example for scheduled: {"type": "scheduled", "cron_expression": "0 0 * * *"}
    -- Example for event_driven: {"event_source": "NATS", "topic": "user.profile.updated"}

    -- Deployment & Runtime Information (JSONB)
    -- Information about where/how the agent is deployed, instance details if applicable
    deployment_info_json JSONB,
    -- Example: {"runtime_environment": "WasmEdge_Local", "current_instances": 1, "max_instances": 5}

    -- Logging & Monitoring Configuration (JSONB)
    logging_json JSONB, -- e.g., {"log_level": "info", "log_targets": ["database", "stdout"]}
    monitoring_json JSONB, -- e.g., {"metrics_endpoint": "/metrics", "health_check_endpoint": "/health"}

    -- Security & Compliance (JSONB)
    security_json JSONB, -- e.g., {"data_encryption_at_rest": true, "access_control_policy_id": "policy_xyz"}

    -- Unique constraint for agent name and version
    UNIQUE (agent_name, version)
);

-- Indexes for performance
CREATE INDEX idx_agent_name ON agent_definitions (agent_name);
CREATE INDEX idx_status ON agent_definitions (status);
CREATE INDEX idx_created_at ON agent_definitions (created_at);

-- Optional: A table for agent authors/maintainers if needed
-- CREATE TABLE agent_authors (
--    author_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--    agent_id UUID REFERENCES agent_definitions(agent_id),
--    user_id UUID, -- Assuming a user table exists in the ecosystem
--    role VARCHAR(100) -- e.g., "creator", "maintainer"
-- );

COMMENT ON TABLE agent_definitions IS 'Stores definitions of IONFLUX agents, including their FluxGraph DSL and operational parameters.';
COMMENT ON COLUMN agent_definitions.flux_graph_dsl_yaml IS 'The core YAML definition of the agent as a FluxGraph (Directed Acyclic Graph of Transforms).';
COMMENT ON COLUMN agent_definitions.execution_requirements_json IS 'JSONB detailing resources, transforms, and dependencies needed for the agent to run.';
COMMENT ON COLUMN agent_definitions.ecosystem_integration_points_json IS 'JSONB describing how the agent interacts with various parts of the ION Ecosystem (IONWALL, IONPOD, Tokenomics, etc.).';
COMMENT ON COLUMN agent_definitions.prm_details_json IS 'JSONB for agent-specific parameters, configurations, and default settings.';
COMMENT ON COLUMN agent_definitions.input_schema_json IS 'JSONB schema defining the expected input structure for the agent.';
COMMENT ON COLUMN agent_definitions.output_schema_json IS 'JSONB schema defining the output structure produced by the agent.';
COMMENT ON COLUMN agent_definitions.trigger_config_json IS 'JSONB specifying the conditions and configurations for how the agent is triggered.';
COMMENT ON COLUMN agent_definitions.deployment_info_json IS 'JSONB containing information about the agent''s deployment status and runtime environment.';

-- Trigger to automatically update updated_at timestamp
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
