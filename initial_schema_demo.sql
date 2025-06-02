-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users Table
CREATE TABLE Users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    name TEXT,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Workspaces Table
CREATE TABLE Workspaces (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    owner_user_id UUID NOT NULL REFERENCES Users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Brands Table
CREATE TABLE Brands (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES Workspaces(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    shopify_store_url TEXT,
    shopify_access_token TEXT, -- Store encrypted, handle decryption in application layer
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Creators Table
CREATE TABLE Creators (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES Workspaces(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    tiktok_handle TEXT,
    tiktok_access_token TEXT, -- Store encrypted, handle decryption in application layer
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- AgentDefinitions Table
-- For the demo, input_schema and output_schema can be placeholders or simplified.
CREATE TABLE AgentDefinitions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    input_schema JSONB, -- Using JSONB for potential structure, TEXT is also fine for demo
    output_schema JSONB, -- Using JSONB for potential structure, TEXT is also fine for demo
    underlying_services_required TEXT[], -- Array of strings like {'LLM', 'Shopify'}
    category TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- AgentConfigurations Table
CREATE TABLE AgentConfigurations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES Workspaces(id) ON DELETE CASCADE,
    agent_definition_id UUID NOT NULL REFERENCES AgentDefinitions(id) ON DELETE RESTRICT, -- Prevent deleting definition if in use
    created_by_user_id UUID REFERENCES Users(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    description TEXT,
    yaml_config TEXT NOT NULL, -- Stores the agent's specific YAML configuration
    last_run_status TEXT, -- e.g., 'idle', 'running', 'success', 'error'
    last_run_at TIMESTAMPTZ,
    last_run_output_preview TEXT, -- Short summary of the last run
    -- Full output might be stored elsewhere or in a dedicated large object storage if very large
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (workspace_id, name) -- Ensure agent configuration names are unique within a workspace
);

-- CanvasPages Table
CREATE TABLE CanvasPages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES Workspaces(id) ON DELETE CASCADE,
    parent_page_id UUID REFERENCES CanvasPages(id) ON DELETE CASCADE, -- For nesting
    title TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- CanvasBlocks Table
-- For the demo, content will store JSON.
-- Specific structure for 'text' and 'agent_snippet' types will be handled by application.
CREATE TABLE CanvasBlocks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    page_id UUID NOT NULL REFERENCES CanvasPages(id) ON DELETE CASCADE,
    type TEXT NOT NULL, -- e.g., 'text', 'agent_snippet', 'embed_panel'
    content JSONB, 
    -- For 'agent_snippet': content -> '{ "agent_config_id": "uuid-of-agent-config" }'
    -- For 'text': content -> '{ "markdown": "..." }'
    position_x INTEGER DEFAULT 0,
    position_y INTEGER DEFAULT 0,
    width INTEGER DEFAULT 100,
    height INTEGER DEFAULT 100,
    z_index INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ChatDockChannels Table
CREATE TABLE ChatDockChannels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES Workspaces(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type TEXT DEFAULT 'public', -- e.g., 'public', 'private', 'dm'
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
    -- For DMs, members could be handled in a separate join table if complex, or logic in application
);

-- ChatMessages Table
-- For the demo, content will store simple text or markdown-like text.
-- sender_id can reference Users or AgentConfigurations (polymorphic, handled by application or separate columns)
CREATE TABLE ChatMessages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    channel_id UUID NOT NULL REFERENCES ChatDockChannels(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL, -- For demo, assume it's a User.id. Agent sender logic to be handled by app.
    sender_type TEXT NOT NULL, -- 'user' or 'agent'
    content_type TEXT NOT NULL DEFAULT 'text', -- e.g., 'text', 'markdown', 'agent_command_response'
    content JSONB NOT NULL, -- For 'text': content -> '{ "text": "message" }'
    thread_id UUID REFERENCES ChatMessages(id) ON DELETE CASCADE, -- For threading
    created_at TIMESTAMPTZ DEFAULT NOW()
    -- updated_at is usually not needed for chat messages unless editable
);

-- Indexes for foreign keys and frequently queried columns (examples)
CREATE INDEX idx_workspaces_owner_user_id ON Workspaces(owner_user_id);
CREATE INDEX idx_brands_workspace_id ON Brands(workspace_id);
CREATE INDEX idx_creators_workspace_id ON Creators(workspace_id);
CREATE INDEX idx_agentconfigurations_workspace_id ON AgentConfigurations(workspace_id);
CREATE INDEX idx_agentconfigurations_agent_definition_id ON AgentConfigurations(agent_definition_id);
CREATE INDEX idx_canvaspages_workspace_id ON CanvasPages(workspace_id);
CREATE INDEX idx_canvasblocks_page_id ON CanvasBlocks(page_id);
CREATE INDEX idx_chatdockchannels_workspace_id ON ChatDockChannels(workspace_id);
CREATE INDEX idx_chatmessages_channel_id ON ChatMessages(channel_id);
CREATE INDEX idx_chatmessages_thread_id ON ChatMessages(thread_id);

-- Trigger function to update 'updated_at' timestamp
CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply the trigger to tables that have 'updated_at'
-- (Repeat for each table: Workspaces, Brands, Creators, etc.)
CREATE TRIGGER set_timestamp_users
BEFORE UPDATE ON Users
FOR EACH ROW
EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_timestamp_workspaces
BEFORE UPDATE ON Workspaces
FOR EACH ROW
EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_timestamp_brands
BEFORE UPDATE ON Brands
FOR EACH ROW
EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_timestamp_creators
BEFORE UPDATE ON Creators
FOR EACH ROW
EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_timestamp_agentdefinitions
BEFORE UPDATE ON AgentDefinitions
FOR EACH ROW
EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_timestamp_agentconfigurations
BEFORE UPDATE ON AgentConfigurations
FOR EACH ROW
EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_timestamp_canvaspages
BEFORE UPDATE ON CanvasPages
FOR EACH ROW
EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_timestamp_canvasblocks
BEFORE UPDATE ON CanvasBlocks
FOR EACH ROW
EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_timestamp_chatdockchannels
BEFORE UPDATE ON ChatDockChannels
FOR EACH ROW
EXECUTE FUNCTION trigger_set_timestamp();

-- Note: ChatMessages typically don't get updated, so updated_at trigger might not be needed there.

-- Seed some AgentDefinitions for the demo (names match E2E demo flow)
INSERT INTO AgentDefinitions (name, description, underlying_services_required, category, input_schema, output_schema) VALUES
    ('Revenue Tracker Lite', 'Displays key revenue metrics from a Shopify store.', '{"Shopify"}', 'E-commerce', '{"type": "object", "properties": {"brand_id": {"type": "string"}, "reporting_period": {"type": "string", "enum": ["last_7_days", "last_30_days"]}}}'::jsonb, '{"type": "object", "properties": {"total_sales": {"type": "number"}, "aov": {"type": "number"}}}'::jsonb),
    ('Shopify Sales Sentinel', 'Alerts on new Shopify orders based on criteria.', '{"Shopify", "Notification"}', 'E-commerce', '{"type": "object", "properties": {"brand_id": {"type": "string"}, "min_order_value_threshold": {"type": "number"}}}'::jsonb, '{"type": "object", "properties": {"alert_message": {"type": "string"}}}'::jsonb),
    ('TikTok Stylist', 'Identifies trending TikTok content for inspiration.', '{"TikTok", "LLM"}', 'Social Media', '{"type": "object", "properties": {"keywords": {"type": "array", "items": {"type": "string"}}, "industry_niche": {"type": "string"}}}'::jsonb, '{"type": "object", "properties": {"trends": {"type": "array", "items": {"type": "object"}}}}'::jsonb),
    ('UGC Matchmaker', 'Helps find TikTok creators for UGC campaigns.', '{"TikTok", "LLM"}', 'Social Media', '{"type": "object", "properties": {"search_keywords": {"type": "array", "items": {"type": "string"}}, "creator_niche": {"type": "string"}}}'::jsonb, '{"type": "object", "properties": {"creators": {"type": "array", "items": {"type": "object"}}}}'::jsonb),
    ('Slack Brief Butler', 'Summarizes chat conversations into structured briefs.', '{"Chat", "LLM"}', 'Productivity', '{"type": "object", "properties": {"channel_id": {"type": "string"}, "thread_id": {"type": "string", "nullable": true}}}'::jsonb, '{"type": "object", "properties": {"brief_summary": {"type": "string"}}}'::jsonb)
ON CONFLICT (name) DO NOTHING; -- Avoid errors if run multiple times, though for demo this is fine

COMMENT ON COLUMN Brands.shopify_access_token IS 'This should be stored encrypted in a real environment.';
COMMENT ON COLUMN Creators.tiktok_access_token IS 'This should be stored encrypted in a real environment.';
COMMENT ON COLUMN AgentConfigurations.yaml_config IS 'Stores the agent''s specific YAML configuration as text.';
COMMENT ON COLUMN CanvasBlocks.content IS 'JSONB content, structure depends on block type. For agent_snippet, expects { "agent_config_id": "uuid" }. For text, expects { "markdown": "text" }.';
COMMENT ON COLUMN ChatMessages.content IS 'JSONB content. For text messages, expects { "text": "message content" }.';

```
