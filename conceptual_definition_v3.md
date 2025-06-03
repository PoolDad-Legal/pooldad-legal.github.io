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
