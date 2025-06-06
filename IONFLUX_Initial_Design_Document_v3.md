# IONFLUX - Initial Design Document (v3)

## 1. Introduction

This document serves as the V3 iteration of the Initial Design Document for the IONFLUX project. It represents a significant milestone, consolidating all core conceptual definitions, UI/UX principles, technical strategies, detailed agent blueprints, and E2E demo specifications that have been developed and meticulously refined during this comprehensive design and specification phase.

The high-level vision for IONFLUX is to create a "Notion-Max" platform, substantially enhanced by a suite of sophisticated AI agents, designed to function as a central command center for brands and creators. This V3 document is critically updated to reflect the incorporation of the detailed "Plano de Refatoração Mestre" (PRM) for ten core agents. These PRM-aligned agents bring advanced capabilities, including complex data processing, event-driven interactions (via Apache Kafka), sophisticated learning loops (Reinforcement Learning, feedback mechanisms), and multimodal understanding.

The revisions captured herein touch upon every aspect of the platform:
*   **Core Architecture & Data Models:** Adapted to support the rich `AgentDefinition`s from the PRM and the complex data flows they entail.
*   **SaaS/API Integration Layers:** Expanded to include new services (like an `AudioService`) and to detail how agents will interact with a wider array of external and internal services, including a central Kafka event bus.
*   **Agent Interaction & Configuration Model:** Overhauled to provide users with clear and powerful ways to configure and interact with these advanced agents, primarily through an enhanced YAML configuration interface backed by detailed `AgentDefinition` schemas.
*   **Nietzschean UX Principles:** Deepened in their practical application to reflect the adaptive, experimental, and resilient nature of the PRM agents.
*   **Monetization & Free Tier:** Re-evaluated to consider the significantly increased value of the PRM agents offered in the free tier and to explore new monetization avenues suggested by their capabilities.
*   **Technical Stack & E2E Demo Strategy:** Updated to incorporate new technologies (e.g., Kafka as a central bus, TimescaleDB), and the E2E demo strategy has been revised to showcase event-driven inter-agent communication using Python/FastAPI minimal service shells for key demo agents.

This V3 document is intended to be the definitive design blueprint moving forward, providing a robust foundation for the subsequent End-to-End (E2E) demo development and the broader Minimum Viable Product (MVP) implementation phases. It is now ready for final stakeholder and user review.

---
## 2. Core Architecture & Data Models
(Content from `conceptual_definition_v3.md`)

# IONFLUX Project: Conceptual Definition (v3)

## 1. Proposed Core Architecture

We propose a **Microservices Architecture** for IONFLUX.

**Justification:**

*   **Scalability:** Microservices allow individual services to be scaled independently based on demand. For example, if the Agent Service experiences high load, it can be scaled without affecting the User Service.
*   **Flexibility & Technology Diversity:** Each service can be developed and deployed with the technology stack best suited for its specific needs. This allows for easier adoption of new technologies and avoids vendor lock-in.
*   **Resilience:** Failure in one service is less likely to impact the entire application. This improves overall uptime and fault isolation.
*   **Maintainability & Independent Development:** Smaller, focused services are easier to understand, maintain, and update. Different teams can work on different services concurrently, accelerating development.
*   **Alignment with Project Scope:** The diverse range of functionalities (user management, AI agents, third-party integrations, real-time collaboration) lends itself well to being broken down into specialized services.

**Key Services Envisioned:**

*   **User Service:** Manages user accounts, authentication (e.g., JWT generation/validation), authorization (permissions), profiles, and potentially billing information (Stripe customer ID).
*   **Workspace Service:** Handles the creation, management, and settings of user workspaces. It will link users to their respective workspaces and manage workspace-level configurations.
*   **Brand Service:** Manages brand profiles, including their specific attributes like industry, target audience, mood boards, and links to external platforms like Shopify and TikTok. Operates within a workspace.
*   **Creator Service:** Manages creator profiles, their niches, portfolio links, and audience demographics. Operates within a workspace.
*   **Prompt Library Service:** Manages the creation, storage, and retrieval of reusable prompts and prompt libraries within a workspace.
*   **Agent Service:** Responsible for managing agent configurations, executing agent tasks, and interacting with other services (like LLM Orchestration, Shopify, TikTok) to fulfill agent directives. This includes managing the lifecycle of `AgentConfiguration` and `AgentDefinition`.
*   **Canvas Service:** Manages the creation, storage, and real-time collaboration aspects of canvas pages and their blocks. It will handle the state and content of different block types.
*   **Chat Service:** Powers the Chat Dock, managing channels, messages, real-time communication (likely via WebSockets), and potentially handling slash commands or agent mentions.
*   **Notification Service:** Manages and delivers notifications to users across different parts of the application (e.g., new messages, agent task completion, mentions).
*   **Shopify Integration Service:** Provides an abstraction layer for interacting with the Shopify API. It will handle authentication with Shopify stores, data fetching (products, orders, customers), and potentially pushing updates.
*   **TikTok Integration Service:** Provides an abstraction layer for interacting with the TikTok API. It will handle authentication, data fetching (profile info, video performance), and potentially content posting.
*   **LLM Orchestration Service:** A crucial service that manages interactions with various Large Language Models (LLMs). It will handle prompt formatting, API calls to different LLM providers, response parsing, and potentially model selection logic based on task or cost.
*   **API Gateway:** (Implicit) While not a "business" service, an API Gateway will be essential to route requests from the frontend to the appropriate microservices, handle initial authentication, rate limiting, and potentially aggregate responses.

---
## 2. Primary Data Schemas (Conceptual - Overhauled)

```json
{
  "User": {
    "id": "string (UUID)",
    "email": "string (unique, indexed)",
    "name": "string",
    "password_hash": "string",
    "created_at": "timestamp",
    "updated_at": "timestamp",
    "profile_info": {
      "avatar_url": "string (url)",
      "bio": "text",
      "user_preferences_json": "json_object (e.g., notification settings, theme)"
    },
    "stripe_customer_id": "string (nullable, for platform billing)",
    "payment_provider_details_json": "json_object (nullable, for user as service provider/agent lister, e.g., Stripe Connect ID)"
  },
  "Workspace": {
    "id": "string (UUID)",
    "name": "string",
    "owner_user_id": "string (references User.id, indexed)",
    "member_user_ids": ["string (references User.id)"],
    "created_at": "timestamp",
    "updated_at": "timestamp",
    "status": "string (enum: 'active', 'archived', 'suspended')",
    "settings_json": {
      "default_llm_config": {
        "provider": "string",
        "model": "string"
      },
      "default_timezone": "string (e.g., 'America/New_York')",
      "regional_preferences_json": "json_object (e.g., currency, language)",
      "active_kafka_topics_list": ["string (e.g., 'shopify_orders_prod', 'tiktok_feed_staging')"],
      "pinecone_api_key_secret_ref": "string (reference to secrets manager, if workspace-scoped)",
      "generic_secrets_config_json": "json_object (e.g. for user-provided API keys for certain integrations, mapping to secret manager refs)"
    }
  },
  "Brand": {
    "id": "string (UUID)",
    "workspace_id": "string (references Workspace.id, indexed)",
    "name": "string",
    "description_text": "text (nullable)",
    "industry": "string (nullable)",
    "target_audience_description_text": "text (nullable)",
    "brand_voice_guidelines_text": "text (nullable)",
    "visual_identity_assets_json": {
      "logo_url": "string",
      "color_palette_array": ["string (hex)"],
      "font_preferences_array": ["string"]
    },
    "mood_board_urls_array": ["string (url)"],
    "persona_guardian_namespace_id": "string (nullable, if specific to this brand)",
    "shopify_integration_details_json": {
      "store_url": "string (url, nullable)",
      "access_token_secret_ref": "string (nullable)",
      "last_sync_status": "string",
      "last_sync_timestamp": "timestamp"
    },
    "tiktok_integration_details_json": {
      "profile_url": "string (url, nullable)",
      "access_token_secret_ref": "string (nullable)",
      "last_sync_status": "string",
      "last_sync_timestamp": "timestamp"
    },
    "created_at": "timestamp",
    "updated_at": "timestamp",
    "status": "string (enum: 'active', 'archived')"
  },
  "Creator": { // Similar structure to Brand for profile and integration details
    "id": "string (UUID)",
    "workspace_id": "string (references Workspace.id, indexed)",
    "name": "string",
    "niche_tags_array": ["string"],
    "bio_text": "text",
    "portfolio_links_array": ["string (url)"],
    "audience_demographics_json": "json_object (nullable)",
    "persona_guardian_namespace_id": "string (nullable, if specific to this creator)",
    "tiktok_integration_details_json": { // If creator connects their own TikTok
      "handle": "string (nullable)",
      "access_token_secret_ref": "string (nullable)"
    },
    // Potentially other platform connections (YouTube, Instagram)
    "created_at": "timestamp",
    "updated_at": "timestamp",
    "status": "string (enum: 'active', 'archived')"
  },
  "PromptLibrary": { // Remains largely the same
    "id": "string (UUID)",
    "workspace_id": "string (references Workspace.id, indexed)",
    "name": "string",
    "description_text": "text (nullable)",
    "created_at": "timestamp",
    "updated_at": "timestamp"
  },
  "Prompt": { // Remains largely the same
    "id": "string (UUID)",
    "library_id": "string (references PromptLibrary.id, indexed)",
    "name": "string",
    "prompt_text": "text",
    "variables_schema_json_array": [ // Schema for expected variables
      {
        "name": "string",
        "type": "string (enum: 'text', 'number', 'date', 'json_object')",
        "description_text": "text (nullable)",
        "is_required": "boolean (default: false)",
        "default_value": "any (optional)"
      }
    ],
    "tags_array": ["string"],
    "created_by_user_id": "string (references User.id)",
    "created_at": "timestamp",
    "updated_at": "timestamp",
    "version": "integer (default: 1)"
  },
  "AgentDefinition": { // Major Overhaul
    "id": "string (e.g., 'agent_001', 'agent_002_refactored', primary key, unique)",
    "name": "string (Human-readable name, e.g., 'Email Wizard', 'Shopify Sales Sentinel v2')",
    "version": "string (semver, e.g., '0.1', '1.0.0')",
    "definition_status": "string (enum: 'prm_active', 'experimental', 'beta', 'production', 'deprecated', 'archived')",
    "created_at": "timestamp",
    "updated_at": "timestamp",
    "prm_details_json": { // Storing rich narrative and descriptive content from PRM
      "epithet": "string (nullable)",
      "tagline": "string (nullable)",
      "introduction_text": "text (nullable)",
      "archetype": "string (nullable)",
      "dna_phrase": "string (nullable)",
      "core_capabilities_array": ["string"],
      "essence_punch_text": "string (nullable)",
      "essence_interpretation_text": "text (nullable)",
      "ipo_flow_description_text": "text (nullable)", // Input-Processing-Output
      "strategic_integrations_text": "text (nullable)",
      "scheduling_triggers_summary_text": "text (nullable)",
      "kpis_definition_text": "text (nullable)",
      "failure_fallback_strategy_text": "text (nullable)",
      "example_integrated_scenario_text": "text (nullable)",
      "dynamic_expansion_notes_text": "text (nullable)",
      "escape_the_obvious_feature_text": "text (nullable)"
    },
    "triggers_config_json_array": [ // How this agent can be triggered
      {
        "type": "string (enum: 'schedule', 'webhook', 'event_stream', 'manual')",
        "description_text": "text (nullable)",
        "default_config_json": { // Default configuration for this trigger
          "cron_expression": "string (nullable, for schedule)",
          "webhook_path_suffix": "string (nullable, for webhook, base path managed by AgentService)",
          "kafka_topic_name": "string (nullable, for event_stream)",
          "kafka_consumer_group_suffix": "string (nullable, for event_stream)",
          "event_filter_json": "json_object (nullable, to filter events from a stream)"
        },
        "is_user_overridable": "boolean (default: false)" // Can user modify this trigger's config in AgentConfiguration?
      }
    ],
    "inputs_schema_json_array": [ // Defines the inputs the agent expects
      {
        "key_name": "string (e.g., 'shopify_event', 'target_audience_description')",
        "data_type": "string (enum: 'json', 'string', 'number', 'boolean', 'url')",
        "is_required": "boolean",
        "description_text": "text (user-friendly description of the input)",
        "default_value": "any (optional)",
        "accepted_values_list": ["any (optional, for enums)"],
        "example_value": "any (optional)"
      }
    ],
    "outputs_config_json_array": [ // Defines the outputs the agent produces
      {
        "key_name": "string (e.g., 'send_report', 'incident_analysis_report')",
        "data_type": "string (enum: 'json', 'string', 'markdown', 'url', 'event')",
        "description_text": "text (user-friendly description of the output)",
        "example_value": "any (optional)",
        "target_event_type": "string (nullable, if output_type is 'event', e.g., 'ionflux.agent.emailwizard.email_sent')"
      }
    ],
    "stack_details_json": {
      "primary_language": "string (e.g., 'python')",
      "primary_runtime": "string (e.g., 'FastAPI, LangChain, LangGraph')",
      "llm_models_used_array": [ // List of LLM models/providers this agent is designed for
        {"provider": "string", "model_name": "string", "purpose": "string (e.g., 'creative_copy', 'data_analysis')"}
      ],
      "vector_db_dependencies_array": [
        {"name": "string (e.g., 'Pinecone')", "usage_description": "text"}
      ],
      "queue_dependencies_array": [
        {"name": "string (e.g., 'Redis + RQ', 'Kafka')", "usage_description": "text"}
      ],
      "database_dependencies_array": [ // Non-VectorDB databases
        {"name": "string (e.g., 'PostgreSQL', 'TimescaleDB')", "usage_description": "text"}
      ],
      "other_integrations_array": [
        {"name": "string (e.g., 'Shopify Admin API', 'SendGrid API')", "usage_description": "text"}
      ],
      "observability_stack_notes_text": "text (e.g., 'Exports OpenTelemetry to Prometheus/Grafana/Loki/Jaeger')"
    },
    "deployment_info_json": {
      "ci_cd_examples_array": ["string (e.g., 'GitHub Actions + Docker Buildx')"],
      "hosting_platform_examples_array": ["string (e.g., 'Fly.io', 'Railway.app', 'Kubernetes')"],
      "default_file_structure_template_text": "text (nullable, conceptual file layout from PRM)"
    },
    "memory_config_json": {
      "required": "boolean (default: false)",
      "type": "string (enum: 'pinecone', 'redis', 'postgres', 'custom', 'none')",
      "default_namespace_template": "string (nullable, e.g., 'agent_{{agent_id}}_ws_{{workspace_id}}_instance_{{instance_id}}')",
      "description_text": "text (how memory is used by this agent)"
    },
    "category_tags_array": ["string (e.g., 'Marketing', 'Content Creation', 'E-commerce', 'Productivity')"],
    "underlying_platform_services_required_array": ["string (enum: 'LLM_Orchestration', 'Shopify_Integration', 'TikTok_Integration', 'Email_Dispatch', 'WhatsApp_Integration')"]
  },
  "AgentConfiguration": { // Instance of an AgentDefinition, configured for a workspace
    "id": "string (UUID)",
    "workspace_id": "string (references Workspace.id, indexed)",
    "agent_definition_id": "string (references AgentDefinition.id, indexed)",
    "name": "string (user-defined name for this instance)",
    "description_text": "text (nullable)",
    "created_by_user_id": "string (references User.id)",
    "yaml_config_text": "text (YAML format, stores user-provided values for inputs_schema and overrides)",
    "effective_config_cache_json": "json_object (nullable, snapshot of merged AgentDefinition defaults + yaml_config + runtime_params)",
    "resolved_memory_namespace_text": "string (nullable, actual namespace used if memory_config is active)",
    "status": "string (enum: 'active', 'inactive', 'archived', 'error_requires_review', default: 'active')",
    "last_run_summary_json": { // Denormalized summary for quick display
      "run_id": "string (UUID, references AgentRunLog.run_id)",
      "status": "string (enum: 'idle', 'pending', 'running', 'success', 'error', 'cancelled')",
      "timestamp": "timestamp",
      "output_preview_text": "text (nullable)"
    },
    "created_at": "timestamp",
    "updated_at": "timestamp"
  },
  "AgentRunLog": { // Detailed log for each agent execution
    "id": "string (UUID, internal db id)",
    "run_id": "string (UUID, public unique ID for this run, indexed)",
    "agent_configuration_id": "string (references AgentConfiguration.id, indexed)",
    "agent_definition_id_version": "string (e.g., 'agent_001/0.1', captures definition used for this run)",
    "workspace_id": "string (references Workspace.id, indexed)",
    "triggered_by_user_id": "string (references User.id, nullable)",
    "trigger_type": "string (enum: 'manual_ui', 'manual_command', 'schedule', 'webhook', 'event_api_call')",
    "status": "string (enum: 'pending', 'running', 'success', 'error', 'cancelled_by_user', 'cancelled_by_system')",
    "start_time": "timestamp",
    "end_time": "timestamp (nullable)",
    "input_params_resolved_json": "json_object (snapshot of effective_config used for this run)",
    "output_data_json": { // Stores actual output or references to it
        "outputs_array": [ // Aligns with AgentDefinition.outputs_config
            {"key_name": "string", "value": "any", "storage_ref_url": "string (nullable, if value is large)"}
        ]
    },
    "output_preview_text": "text (nullable, concise summary of output)",
    "error_details_json": {
        "error_code": "string (nullable)",
        "error_message_text": "text (nullable)",
        "stack_trace_text": "text (nullable)"
    },
    "logs_storage_ref_url": "string (nullable, URI to detailed execution logs, e.g., in S3/Loki)",
    "kpi_results_json": "json_object (nullable, agent-reported KPIs for this run)"
  },
  "Playbook": { // For agents like WhatsApp Pulse (Agent 002)
    "id": "string (UUID)",
    "workspace_id": "string (references Workspace.id, indexed)",
    "name": "string (e.g., 'Abandoned Cart Recovery - Aggressive')",
    "description_text": "text (nullable)",
    "trigger_event_schema_json": { // Defines the event that triggers this playbook
      "source_service": "string (e.g., 'ShopifyIntegrationService', 'UserActivityService')",
      "event_type": "string (e.g., 'shopify.abandoned_cart.created', 'user.segment.entered_high_value_segment')",
      "filter_conditions_json": "json_object (e.g., {'cart_value_gt': 100})"
    },
    "target_audience_segment_id": "string (nullable, references a future AudienceSegment entity)",
    "steps_json_array": [ // Sequence of actions
      {
        "step_id": "string (UUID)",
        "step_name": "string",
        "delay_seconds": "integer (0 for immediate)",
        "action_type": "string (enum: 'send_whatsapp_message', 'send_email', 'update_crm_tag', 'trigger_agent')",
        "action_config_json": { // Configuration for the action
          // Example for 'send_whatsapp_message'
          "whatsapp_template_name": "string (nullable)",
          "message_body_template_text": "string (nullable, with {{placeholders}})",
          // Example for 'trigger_agent'
          "target_agent_definition_id": "string",
          "input_params_mapping_json": "json_object (maps playbook context to agent inputs)"
        },
        "next_step_conditions_json_array": [ // Branching logic
          {"condition_on_output_key": "string", "operator": "string", "value": "any", "next_step_id": "string"}
        ],
        "default_next_step_id": "string (nullable)"
      }
    ],
    "status": "string (enum: 'draft', 'active', 'paused', 'archived')",
    "performance_metrics_json": { // Aggregated metrics for this playbook
      "total_triggered": "integer",
      "total_completed": "integer",
      "conversion_rate": "float (if applicable)"
    },
    "created_by_user_id": "string (references User.id)",
    "created_at": "timestamp",
    "updated_at": "timestamp"
  },
  "PlatformEvent": { // Conceptual schema for Kafka events
    "event_id": "string (UUID, unique)",
    "event_type": "string (namespaced, e.g., 'ionflux.shopify.order.created', 'ionflux.agent.run.completed')",
    "event_timestamp": "timestamp (ISO 8601)",
    "source_service_name": "string (e.g., 'ShopifyIntegrationService', 'AgentService')",
    "workspace_id": "string (UUID, nullable, if event is workspace-specific)",
    "user_id": "string (UUID, nullable, if event is user-specific)",
    "correlation_id": "string (UUID, nullable, for tracing related events)",
    "payload_schema_version": "string (e.g., 'v1.0')",
    "payload_json": "json_object (actual event data, specific to event_type)"
  },
  "CanvasPage": {
    "id": "string (UUID)",
    "workspace_id": "string (references Workspace.id, indexed)",
    "title": "string",
    "created_at": "timestamp",
    "updated_at": "timestamp",
    "parent_page_id": "string (references CanvasPage.id, nullable, for nesting)",
    "icon_url": "string (url, nullable)",
    "status": "string (enum: 'active', 'archived', 'template_draft', default: 'active')"
  },
  "CanvasBlock": {
    "id": "string (UUID)",
    "page_id": "string (references CanvasPage.id, indexed)",
    "type": "string (enum: 'text', 'agent_snippet', 'embed_panel', 'table_view', 'kanban_board', 'image', 'video', 'json_display')",
    "content_json": {
      "title_text": "string (nullable)",
      "markdown_text": "string (for 'text')",
      "agent_configuration_id": "string (references AgentConfiguration.id, for 'agent_snippet')",
      "agent_last_run_output_key_ref": "string (nullable, specific output key to display in snippet)",
      "embed_url": "string (for 'embed_panel')",
      "json_data_to_display": "json_object (for 'json_display', 'table_view', 'kanban_board')"
    },
    "position_x": "integer",
    "position_y": "integer",
    "width": "integer",
    "height": "integer",
    "z_index": "integer (default: 0)",
    "created_at": "timestamp",
    "updated_at": "timestamp"
  },
  "ChatDockChannel": {
    "id": "string (UUID)",
    "workspace_id": "string (references Workspace.id, indexed)",
    "name": "string",
    "type": "string (enum: 'public', 'private', 'dm', 'agent_dedicated')",
    "description_text": "text (nullable)",
    "member_user_ids_array": ["string (references User.id)"],
    "created_at": "timestamp",
    "updated_at": "timestamp"
  },
  "ChatMessage": {
    "id": "string (UUID)",
    "channel_id": "string (references ChatDockChannel.id, indexed)",
    "sender_id": "string (references User.id or AgentConfiguration.id, indexed)",
    "sender_type": "string (enum: 'user', 'agent', 'system')",
    "content_type": "string (enum: 'text', 'markdown', 'json_data', 'interactive_proposal', 'file_attachment', 'agent_status_update')",
    "content_json": {
      "text_body": "string (for text/markdown)",
      "json_payload": "json_object (for json_data, interactive_proposal)",
      "file_details_json": "json_object (for file_attachment)",
      "status_update_json": "json_object (for agent_status_update)"
    },
    "thread_id": "string (references ChatMessage.id, nullable, indexed)",
    "reactions_json_array": [{"emoji": "string", "user_ids_array": ["string"]}],
    "read_by_user_ids_array": ["string"],
    "created_at": "timestamp",
    "updated_at": "timestamp (nullable)"
  }
}
```

---
## 3. API Interaction Concepts (Revised)

The IONFLUX platform will leverage a combination of synchronous RESTful APIs for direct request/response interactions and an asynchronous, event-driven architecture primarily using **Apache Kafka** for inter-service communication, agent triggering, and data propagation. The API Gateway remains the primary entry point for client applications.

**Key Interaction Patterns:**

1.  **Client to Backend (Synchronous REST via API Gateway):**
    *   Standard CRUD operations for core entities (Users, Workspaces, Canvas Pages, Agent Configurations, etc.).
    *   Example: Frontend calls `POST /workspaces/:workspaceId/agent-configurations` to create a new agent instance. The `AgentService` handles this synchronously.
    *   Example: Frontend calls `POST /agent-configurations/:configId/run` with `runtime_params`. `AgentService` might acknowledge the request (202 Accepted) and then initiate the agent run asynchronously.

2.  **Service-to-Service (Synchronous REST):**
    *   Used when one service requires immediate data or action from another to complete its current task.
    *   Example: `AgentService` calls `LLMOrchestrationService` and awaits a response.
    *   Example: `WorkspaceService` calls `UserService` to validate a `owner_user_id`.

3.  **Event-Driven Communication (Asynchronous via Kafka):**
    *   **Purpose:** Decoupling services, handling high-throughput data, triggering reactive workflows, and enabling real-time updates.
    *   **Core Mechanism:** Services publish events to specific Kafka topics. Other services or agents subscribe to these topics to consume and react to events.
    *   **Event Structure:** Events will follow a `PlatformEvent` like schema (see above).
    *   **Examples:**
        *   **Shopify Integration:** `ShopifyIntegrationService` receives a webhook from Shopify (e.g., new order) -> publishes a `ionflux.shopify.order.created` event to a Kafka topic.
        *   **Agent Triggering (Event-Based):** `ShopifySalesSentinel` (Agent 004) subscribes to `ionflux.shopify.order.created`. Upon receiving an event, it processes the order data.
        *   **Inter-Agent Communication:** `ShopifySalesSentinel` detects an anomaly -> publishes an `ionflux.agent.salessentinel.anomaly_detected` event. `NotificationService` or another agent (e.g., `SlackBriefButler`) might subscribe to this to alert users.
        *   **Agent Output as Events:** `EmailWizard` (Agent 001) successfully sends an email campaign -> publishes `ionflux.agent.emailwizard.campaign_sent` event with campaign stats. `BadgeMotivator` (Agent 009) could consume this to award XP.
        *   **Data Propagation for RAG/Memory:** An agent processing documents might publish `ionflux.content.document_chunk.embedded` events, which a dedicated service or another agent consumes to update a Pinecone index.

4.  **Agent Execution Flow (Hybrid):**
    *   **Initiation:** Can be synchronous (manual run from UI/Chat command) or asynchronous (schedule, Kafka event).
    *   **Internal Steps:** An agent's internal logic (e.g., implemented with LangGraph) might involve multiple synchronous calls to `LLMOrchestrationService`, `VectorDBs` (Pinecone), or other integration services.
    *   **Result Reporting:**
        *   `AgentService` updates `AgentRunLog` (synchronously to its DB).
        *   Updates `AgentConfiguration.last_run_summary_json` (synchronously).
        *   Publishes an `ionflux.agent.run.completed` event to Kafka, containing `run_id`, status, and `output_preview_text` or reference to full output.
        *   Frontend components (Canvas Snippet, Chat) can update either by polling `AgentConfiguration` or, preferably, by receiving real-time updates via WebSockets that are themselves triggered by the Kafka event (e.g., a WebSocket service consumes relevant Kafka events and pushes to connected clients).

5.  **Real-time UI Updates (WebSockets):**
    *   `ChatService` uses WebSockets for message delivery.
    *   `CanvasService` can use WebSockets for collaborative edits (future).
    *   A dedicated `WebSocketService` might subscribe to relevant Kafka topics (e.g., `agent.run.status_changed`, `notification.user_notified`) and push updates to specific connected clients, enabling real-time UI feedback without constant polling.

**Revised Conceptual Flow Example (Shopify Order -> Sentinel -> Alert):**

1.  Shopify store receives a new order.
2.  Shopify sends a webhook to `ShopifyIntegrationService`.
3.  `ShopifyIntegrationService` validates the webhook and publishes a detailed `ionflux.shopify.order.created` event to the `orders_raw` Kafka topic (payload contains full order JSON).
4.  `ShopifySalesSentinel` (Agent 004), subscribed to `orders_raw` for its configured `workspace_id`, consumes the event.
5.  Sentinel's internal logic (Anomaly Guardian, etc.) processes the order. It detects a high-value order that matches its alert criteria.
6.  Sentinel (via `AgentService`) determines an alert needs to be sent. It could:
    a.  Directly call `ChatService` API to post a message to a pre-configured channel.
    b.  Publish an `ionflux.agent.salessentinel.alert_generated` event to a Kafka topic.
7.  If event published (6b):
    *   `NotificationService` (or `SlackBriefButler` if configured as a listener) consumes this event.
    *   It formats a user-friendly notification.
    *   It sends the notification to the user via their preferred channel (e.g., pushes to `ChatService` to post in a specific channel, or sends an email via `EmailDispatchService`).
8.  The `AgentRunLog` for this Sentinel execution is updated by `AgentService`.

This revised model emphasizes a more robust, scalable, and decoupled architecture, better suited for the complex, event-driven nature of advanced AI agents.
---
---
## Appendix: E2E Demo Specifications (v3)

This appendix consolidates the minimal viable specifications for services and frontend components required for the IONFLUX End-to-End (E2E) Demo, all updated to V3.

### 10.1 Initial Demo Database Schema (SQL)
(Content of `initial_schema_demo_v3.sql`)
```sql
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
    created_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
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
    created_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
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
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Playbooks Table
CREATE TABLE playbooks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description_text TEXT,
    trigger_event_schema_json JSONB NOT NULL, -- {source_service, event_type, filter_conditions_json}
    target_audience_segment_id TEXT,
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
    parent_page_id UUID REFERENCES canvas_pages(id) ON DELETE SET NULL,
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
    reactions_json_array JSONB,
    read_by_user_ids_array UUID[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);
CREATE TRIGGER set_timestamp_chat_messages BEFORE UPDATE ON chat_messages FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

-- Indexes
CREATE INDEX IF NOT EXISTS idx_workspaces_owner_user_id ON workspaces(owner_user_id);
CREATE INDEX IF NOT EXISTS idx_brands_workspace_id ON brands(workspace_id);
CREATE INDEX IF NOT EXISTS idx_creators_workspace_id ON creators(workspace_id);
CREATE INDEX IF NOT EXISTS idx_prompt_libraries_workspace_id ON prompt_libraries(workspace_id);
CREATE INDEX IF NOT EXISTS idx_prompts_library_id ON prompts(library_id);
CREATE INDEX IF NOT EXISTS idx_agent_configurations_workspace_id ON agent_configurations(workspace_id);
CREATE INDEX IF NOT EXISTS idx_agent_configurations_agent_definition_id ON agent_configurations(agent_definition_id);
CREATE INDEX IF NOT EXISTS idx_agent_run_logs_agent_configuration_id ON agent_run_logs(agent_configuration_id);
CREATE INDEX IF NOT EXISTS idx_agent_run_logs_run_id ON agent_run_logs(run_id);
CREATE INDEX IF NOT EXISTS idx_agent_run_logs_workspace_id ON agent_run_logs(workspace_id);
CREATE INDEX IF NOT EXISTS idx_playbooks_workspace_id ON playbooks(workspace_id);
CREATE INDEX IF NOT EXISTS idx_canvas_pages_workspace_id ON canvas_pages(workspace_id);
CREATE INDEX IF NOT EXISTS idx_canvas_blocks_page_id ON canvas_blocks(page_id);
CREATE INDEX IF NOT EXISTS idx_chat_channels_workspace_id ON chat_channels(workspace_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_channel_id ON chat_messages(channel_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_thread_id ON chat_messages(thread_id);

-- Seed Data
INSERT INTO users (email, name, password_hash, profile_info_json) VALUES
('demo@ionflux.ai', 'Demo User', '$2b$12$D2xOAY4bZ.İNVENTED.HASH.PLEASE.REPLACE', '{"avatar_url": null, "bio": "IONFLUX Demo User", "user_preferences_json": {"notifications": "all", "theme": "dark"}}') -- Replace with a real bcrypt hash
ON CONFLICT (email) DO NOTHING;

INSERT INTO workspaces (name, owner_user_id, settings_json) VALUES
('Demo Workspace', (SELECT id FROM users WHERE email = 'demo@ionflux.ai'),
'{"default_llm_config": {"provider": "openai", "model": "gpt-4o"}, "default_timezone": "America/New_York", "active_kafka_topics_list": ["ionflux.shopify.ws_demo.orders.created", "ionflux.demo.custom_events"], "pinecone_api_key_secret_ref": "projects/ionflux-demo/secrets/pinecone_api_key/versions/latest", "generic_secrets_config_json": {"my_sendgrid_key": "projects/ionflux-demo/secrets/sendgrid_demo_ws/versions/latest"}}')
ON CONFLICT (name) WHERE owner_user_id = (SELECT id FROM users WHERE email = 'demo@ionflux.ai') DO NOTHING;


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
        "ipo_flow_description_text": "Consumes Kafka events from Shopify, processes with Flink/Spark, uses ML for anomaly detection, LLM for root cause, LangGraph/Temporal for remediation workflows, outputs incidents and alerts.",
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
    '{"epithet": "O Xamã que Conjura Receita no Silêncio do E-mail", "tagline": "INBOX ≠ ARQUIVO MORTO; INBOX = ARMA VIVA", "introduction_text": "(Full intro from PRM Agent 001)", "core_capabilities_array": ["Hyper-Segment", "Dopamine Drip", "Auto-Warm-Up", "Predictive Clearance"]}'::jsonb,
    '[{"type": "schedule", "description_text": "Default schedule to send pending emails.", "default_config_json": {"cron_expression": "0 */2 * * *"}, "is_user_overridable": true}, {"type": "webhook", "description_text": "Trigger for immediate email sending.", "default_config_json": {"webhook_path_suffix": "/emailwizard/run"}, "is_user_overridable": false}]'::jsonb,
    '[{"key_name": "shopify_event", "data_type": "json", "is_required": false, "description_text": "Optional Shopify event data to trigger email."}, {"key_name": "manual_payload", "data_type": "json", "is_required": false, "description_text": "Manual payload for triggering specific email sequences."}]'::jsonb,
    '[{"key_name": "send_report", "data_type": "json", "description_text": "Report of emails sent and their status."}]'::jsonb,
    '{"primary_language": "python", "primary_runtime": "LangChain, LangGraph", "llm_models_used_array": [{"provider": "openai", "model_name": "gpt-4o", "purpose": "creative copy"}, {"provider": "anthropic", "model_name": "claude-3-haiku", "purpose": "backup/variation"}], "vector_db_dependencies_array": [{"name": "Pinecone", "usage_description": "Storing user profiles/segments for hyper-personalization"}], "queue_dependencies_array": [{"name": "Redis + RQ", "usage_description": "Managing email sending queues"}], "database_dependencies_array": [{"name": "PostgreSQL", "usage_description": "Storing email templates, campaign history"}], "other_integrations_array": [{"name": "SendGrid API", "usage_description": "Actual email dispatch"}, {"name": "Shopify API", "usage_description": "Customer data for segmentation"}]}'::jsonb,
    '{"ci_cd_examples_array": ["GitHub Actions + Docker Buildx + Fly.io"], "default_file_structure_template_text": "/agents/emailwizard/\n  ├── agent.py\n  ├── prompts.yaml\n  ├── splitter.py\n  └── processors/copy_generator.py"}'::jsonb,
    '{"required": true, "type": "pinecone", "default_namespace_template": "emailwizard_personas_ws_{{workspace_id}}", "description_text": "Stores user/customer embeddings for hyper-segmentation and personalization."}'::jsonb,
    '{"Email", "Marketing", "Automation", "E-commerce"}'::text[],
    '{"LLM_Orchestration", "Email_Dispatch", "Shopify_Integration"}'::text[]
),
(
    'agent_010_refactored', 'Revenue Tracker Lite v2', '0.2', 'prm_active',
    '{"epithet": "O Analista Financeiro Pessoal da Sua Loja...", "tagline": "FATURAMENTO É VAIDADE, LUCRO É SANIDADE...", "introduction_text": "(Full intro for Agent 010)", "core_capabilities_array": ["Automated Cost Ingestor", "Real-time Margin Calculator", "Profitability Variance Sentinel", "Actionable Insights & Daily Digestor", "Data Source for Other Agents"]}'::jsonb,
    '[{"type": "webhook", "description_text": "Triggered by Shopify order events.", "default_config_json": {"webhook_path_suffix": "/revenue_tracker/shopify_event"}, "is_user_overridable": false}, {"type": "schedule", "description_text": "Daily profitability digest generation.", "default_config_json": {"cron_expression": "0 5 * * *", "task": "generate_daily_profitability_digest"}, "is_user_overridable": true}]'::jsonb,
    '[{"key_name": "shopify_order_payload", "data_type": "json", "is_required": false, "description_text": "Payload of a Shopify order event."}, {"key_name": "manual_cost_inputs", "data_type": "json", "is_required": false, "description_text": "JSON for manual COGS, app fees, avg marketing cost."}]'::jsonb,
    '[{"key_name": "profitability_dashboard_data_json", "data_type": "json", "description_text": "Data for profitability dashboard."}, {"key_name": "profitability_digest_markdown", "data_type": "markdown", "description_text": "Daily/weekly profitability digest."}, {"key_name": "actionable_alert_payload", "data_type": "json", "description_text": "Payload for critical profitability alerts."}]'::jsonb,
    '{"primary_language": "python", "primary_runtime": "FastAPI, Pandas", "llm_models_used_array": [{"provider": "openai", "model_name": "gpt-4o", "purpose": "actionable suggestions"}], "database_dependencies_array": [{"name": "PostgreSQL", "usage_description": "Storing processed financial data, COGS"}, {"name": "Redis", "usage_description": "Caching dashboard data"}], "queue_dependencies_array": [{"name": "Redis + RQ", "usage_description": "Async report generation"}]}'::jsonb,
    '{"default_file_structure_template_text": "/agents/revenue_tracker/..."}'::jsonb,
    '{"required": false, "type": "none", "description_text": "Primarily uses structured data in PostgreSQL."}'::jsonb,
    '{"E-commerce", "Analytics", "Finance", "Shopify"}'::text[],
    '{"Shopify_Integration", "LLM_Orchestration"}'::text[]
),
(
    'agent_008_refactored', 'Creator Persona Guardian v2', '0.2', 'prm_active',
    '{"epithet": "O Guardião Algorítmico da Alma Criativa...", "tagline": "SUA VOZ É ÚNICA...", "introduction_text": "(Full intro for Agent 008)", "core_capabilities_array": ["Multimodal Persona Definition & Extraction", "Content Authenticity & Resonance Scoring", "AI-Powered Style Repair & Enhancement", "Persona Evolution & Drift Monitor", "Persona Style Transfer Hub"]}'::jsonb,
    '[{"type": "webhook", "description_text": "Validate content against persona.", "default_config_json": {"webhook_path_suffix": "/persona_guardian/validate_content"}, "is_user_overridable": false}, {"type": "event", "description_text": "Trigger on new content creation events.", "default_config_json": {"event_type": "ionflux.content_creation_event"}, "is_user_overridable": false}, {"type": "schedule", "description_text": "Weekly persona evolution analysis.", "default_config_json": {"cron_expression": "0 0 * * 0", "task": "persona_evolution_analysis_and_report"}, "is_user_overridable": true}]'::jsonb,
    '[{"key_name": "creator_id_or_brand_id", "data_type": "string", "is_required": true, "description_text": "Identifier for the persona."}, {"key_name": "content_to_analyze_text", "data_type": "string", "is_required": false, "description_text": "Text content to validate."}, {"key_name": "content_to_analyze_url", "data_type": "url", "is_required": false, "description_text": "URL of multimodal content."}]'::jsonb,
    '[{"key_name": "authenticity_score", "data_type": "float", "description_text": "Content alignment score."}, {"key_name": "resonance_score_predicted", "data_type": "float", "description_text": "Predicted audience resonance score."}, {"key_name": "repaired_content_suggestions_json", "data_type": "json", "description_text": "Suggestions for style/tone repair."}, {"key_name": "persona_evolution_report_md", "data_type": "markdown", "description_text": "Weekly persona consistency report."}]'::jsonb,
    '{"primary_language": "python", "primary_runtime": "FastAPI, LangChain, LangGraph", "llm_models_used_array": [{"provider": "openai", "model_name": "gpt-4o-vision", "purpose": "multimodal analysis & generation"}, {"provider": "anthropic", "model_name": "claude-3-haiku", "purpose": "style repair variations"}], "vector_db_dependencies_array": [{"name": "Pinecone", "usage_description": "Storing persona fingerprints"}], "queue_dependencies_array": [{"name": "Redis + RQ", "usage_description": "Async content processing"}]}'::jsonb,
    '{"default_file_structure_template_text": "/agents/persona_guardian/..."}'::jsonb,
    '{"required": true, "type": "pinecone", "default_namespace_template": "persona_fingerprints_ws_{{workspace_id}}_id_{{creator_id_or_brand_id}}", "description_text": "Stores multimodal embeddings defining the persona."}'::jsonb,
    '{"Content Creation", "Brand Management", "AI", "Quality Assurance"}'::text[],
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

INSERT INTO agent_configurations (workspace_id, agent_definition_id, name, created_by_user_id, yaml_config_text, last_run_summary_json)
VALUES (
    (SELECT id FROM workspaces WHERE name = 'Demo Workspace'),
    'agent_004_refactored',
    'EcoThreads Boutique - Sales Sentinel Config',
    (SELECT id FROM users WHERE email = 'demo@ionflux.ai'),
    E'inputs:\n  min_order_value_alert_threshold: 100.00\ntriggers:\n  - trigger_definition_key: "shopify_events_consumer" # This key needs to map to a defined trigger in AgentDefinition\n    enabled: true\n',
    '{"status": "idle"}'::jsonb
) ON CONFLICT (workspace_id, name) DO NOTHING;

INSERT INTO prompt_libraries (workspace_id, name, description_text)
SELECT id, 'Marketing Email Prompts', 'Collection of prompts for generating marketing email copy.' FROM workspaces WHERE name = 'Demo Workspace'
ON CONFLICT (workspace_id, name) DO NOTHING;

INSERT INTO prompts (library_id, name, prompt_text, variables_schema_json_array, created_by_user_id)
SELECT
    (SELECT id FROM prompt_libraries WHERE name = 'Marketing Email Prompts' AND workspace_id = (SELECT id FROM workspaces WHERE name = 'Demo Workspace')),
    'Exciting Product Promotion',
    'Generate an exciting promotional email for our product: {{product_name}}. Highlight its key benefits: {{key_benefits}}. The target audience is {{target_audience}}. Include a call to action: {{call_to_action}}.',
    '[{"name": "product_name", "type": "text", "description_text": "Name of the product", "is_required": true},
      {"name": "key_benefits", "type": "text", "description_text": "Comma-separated key benefits", "is_required": true},
      {"name": "target_audience", "type": "text", "description_text": "Description of the target audience", "is_required": true},
      {"name": "call_to_action", "type": "text", "description_text": "Desired call to action", "is_required": true}]'::jsonb,
    (SELECT id FROM users WHERE email = 'demo@ionflux.ai')
WHERE NOT EXISTS (
    SELECT 1 FROM prompts
    WHERE name = 'Exciting Product Promotion'
    AND library_id = (SELECT id FROM prompt_libraries WHERE name = 'Marketing Email Prompts' AND workspace_id = (SELECT id FROM workspaces WHERE name = 'Demo Workspace'))
);


INSERT INTO canvas_pages (workspace_id, title)
SELECT id, 'Q4 Campaign Planning' FROM workspaces WHERE name = 'Demo Workspace'
ON CONFLICT (workspace_id, title) DO NOTHING; -- Assuming title is unique per workspace for demo simplicity

INSERT INTO chat_channels (workspace_id, name, type)
SELECT id, 'general', 'public' FROM workspaces WHERE name = 'Demo Workspace'
ON CONFLICT (workspace_id, name) DO NOTHING; -- Assuming name is unique per workspace

INSERT INTO chat_channels (workspace_id, name, type)
SELECT id, 'alerts', 'public' FROM workspaces WHERE name = 'Demo Workspace'
ON CONFLICT (workspace_id, name) DO NOTHING;


COMMENT ON TABLE agent_definitions IS 'Stores the immutable definition of various agent types, including their capabilities, schemas, and PRM narrative details. Content for JSONB fields often comes directly from agent blueprint YAMLs/JSONs.';
COMMENT ON TABLE agent_configurations IS 'Represents a user''s specific instance and configuration of an AgentDefinition within a workspace.';
COMMENT ON TABLE agent_run_logs IS 'Logs each execution of an agent configuration, capturing inputs, outputs, status, and errors.';
COMMENT ON TABLE playbooks IS 'Defines automated multi-step workflows that can involve triggering agents or other actions based on events.';
COMMENT ON COLUMN canvas_blocks.content_json IS 'JSONB content, structure depends on block type. For agent_snippet, expects { "agent_configuration_id": "uuid" }. For text, expects { "markdown_text": "text" }.';
COMMENT ON COLUMN chat_messages.content_json IS 'JSONB content. For text messages, expects { "text_body": "message content" }.';

---
## 11. Conclusion & Next Steps

This IONFLUX Initial Design Document (v3) provides a comprehensive blueprint for the platform, integrating detailed agent specifications from the "Plano de Refatoração Mestre" (PRM) across all aspects of the system architecture, data models, API designs, UI/UX concepts, and E2E demo strategy.

The V3 revisions ensure that:
*   Core data models, especially `AgentDefinition`, can accommodate the rich, structured information of PRM agents.
*   API and service specifications are aligned with these advanced agent capabilities and the event-driven (Kafka-centric) architecture.
*   Frontend specifications are updated to handle richer data displays and more complex user interactions for agent configuration and output visualization.
*   Philosophical UX principles are more deeply embedded, reflecting the adaptive and experimental nature of the PRM agents.
*   Monetization strategies and the E2E demo plan are updated to leverage the power of these refactored agents.

This document now serves as the definitive guide for the development of the IONFLUX End-to-End (E2E) demo and the subsequent Minimum Viable Product (MVP). It is ready for final stakeholder review to ensure alignment and to kick off the implementation phase. Future iterations and more detailed technical design for each microservice and component will build upon this foundational V3 design.
```

[end of IONFLUX_Initial_Design_Document_v3.md]
