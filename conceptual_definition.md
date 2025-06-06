# IONFLUX Project: Conceptual Definition

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

## 2. Primary Data Schemas (Conceptual)

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
      "bio": "text"
    },
    "stripe_customer_id": "string (nullable, for future billing)"
  },
  "Workspace": {
    "id": "string (UUID)",
    "name": "string",
    "owner_user_id": "string (references User.id, indexed)",
    "created_at": "timestamp",
    "updated_at": "timestamp",
    "settings": {
      "default_llm_config": "json_object" // e.g., { "provider": "OpenAI", "model": "gpt-4" }
    },
    "member_user_ids": ["string (references User.id)"]
  },
  "Brand": {
    "id": "string (UUID)",
    "workspace_id": "string (references Workspace.id, indexed)",
    "name": "string",
    "industry": "string (nullable)",
    "target_audience": "text (nullable)",
    "mood_board_urls": ["string (url)"],
    "shopify_store_url": "string (url, nullable)", // Updated by ShopifyIntegrationService
    "shopify_access_token": "string (encrypted, nullable)", // Updated by ShopifyIntegrationService
    "tiktok_profile_url": "string (url, nullable)", // Updated by TikTokIntegrationService
    "tiktok_access_token": "string (encrypted, nullable)", // Updated by TikTokIntegrationService
    "created_at": "timestamp",
    "updated_at": "timestamp"
  },
  "Creator": {
    "id": "string (UUID)",
    "workspace_id": "string (references Workspace.id, indexed)",
    "name": "string",
    "niche": "string (nullable)",
    "tiktok_handle": "string (nullable)",
    "tiktok_access_token": "string (encrypted, nullable)", // If creator connects their own TikTok
    "portfolio_links": ["string (url)"],
    "audience_demographics": "json_object (nullable)",
    "created_at": "timestamp",
    "updated_at": "timestamp"
  },
  "Prompt": {
    "id": "string (UUID)",
    "library_id": "string (references PromptLibrary.id, indexed)",
    "name": "string",
    "text": "text",
    "variables": [
      {
        "name": "string",
        "type": "string (enum: 'text', 'number', 'date')",
        "default_value": "any (optional)"
      }
    ],
    "created_by_user_id": "string (references User.id, indexed)",
    "created_at": "timestamp",
    "updated_at": "timestamp",
    "tags": ["string (nullable)"]
  },
  "PromptLibrary": {
    "id": "string (UUID)",
    "workspace_id": "string (references Workspace.id, indexed)",
    "name": "string",
    "description": "text (nullable)",
    "created_at": "timestamp",
    "updated_at": "timestamp"
  },
  "AgentDefinition": {
    "id": "string (UUID or agent_xxx format from blueprints)",
    "name": "string (unique, e.g., 'EmailWizard', 'ShopifySalesSentinel')",
    "epithet": "string (nullable, e.g., 'Pulse of the Inbox')",
    "tagline": "string (nullable)",
    "introduction_text": "text (nullable)",
    "archetype": "string (nullable, e.g., 'Magician')",
    "dna_phrase": "string (nullable, e.g., 'Faz o invisível falar e vender')",
    "core_capabilities": ["string (nullable)"],
    "essence_punch": "string (nullable)",
    "essence_interpretation": "text (nullable)",
    "version": "string (semver, e.g., '0.1')",
    "description": "text (High-level description)",
    "triggers_config": [
      {
        "type": "string (enum: 'schedule', 'webhook', 'event')",
        "config": "json_object"
      }
    ],
    "inputs_schema": [
      {
        "key": "string",
        "type": "string (enum: 'json', 'string', 'number', 'boolean')",
        "required": "boolean",
        "description": "text (nullable)"
      }
    ],
    "outputs_config": [
      {
        "key": "string",
        "type": "string (enum: 'json', 'string', 'md', 'url')",
        "description": "text (nullable)"
      }
    ],
    "stack_details": {
      "language": "string (e.g., 'python')",
      "runtime": "string (e.g., 'langchain', 'fastapi')",
      "models_used": ["string (e.g., 'openai:gpt-4o')"],
      "database_dependencies": ["string (nullable, e.g., 'Postgres', 'Pinecone')"],
      "queue_dependencies": ["string (nullable, e.g., 'Redis + RQ', 'Kafka')"],
      "other_integrations": ["string (nullable, e.g., 'Sendgrid', 'Meta WhatsApp Cloud API')"]
    },
    "memory_config": {
      "type": "string (nullable, e.g., 'pinecone', 'redis')",
      "namespace_template": "string (nullable, e.g., 'emailwizard_instance_{{instance_id}}')"
    },
    "default_file_structure_template": "text (nullable)",
    "key_files_and_paths": "json_object (nullable)",
    "scheduling_and_triggers_summary": "text (nullable)",
    "kpis_definition": "text (nullable)",
    "failure_fallback_strategy": "text (nullable)",
    "example_integration_flow": "text (nullable)",
    "dynamic_expansion_notes": "text (nullable)",
    "escape_the_obvious_feature": "text (nullable)",
    "underlying_services_required": ["string (enum: 'LLM', 'Shopify', 'TikTok', 'WebSearch', 'Email', 'WhatsApp')"],
    "category": "string (e.g., 'Marketing', 'Content Creation', 'Sales', 'Productivity')",
    "created_at": "timestamp",
    "updated_at": "timestamp",
    "status": "string (enum: 'draft', 'active', 'deprecated', default: 'draft')"
  },
  "AgentConfiguration": {
    "id": "string (UUID)",
    "workspace_id": "string (references Workspace.id, indexed)",
    "agent_definition_id": "string (references AgentDefinition.id, indexed)",
    "name": "string",
    "description": "text (nullable)",
    "created_by_user_id": "string (references User.id, indexed)",
    "yaml_config": "text (yaml format)",
    "effective_config_cache": "json_object (nullable)",
    "external_memory_namespace": "string (nullable)",
    "last_run_status": "string (enum: 'idle', 'pending', 'running', 'success', 'error', 'cancelled', nullable)",
    "last_run_at": "timestamp (nullable)",
    "last_run_id": "string (UUID, nullable)",
    "last_run_output_preview": "text (nullable)",
    "last_run_full_output_ref": "string (nullable, URI to full output if stored elsewhere, e.g. S3)",
    "created_at": "timestamp",
    "updated_at": "timestamp",
    "status": "string (enum: 'active', 'inactive', 'archived', default: 'active')"
  },
  "AgentRunLog": {
    "id": "string (UUID, primary_key, default: uuid_generate_v4())",
    "agent_configuration_id": "string (references AgentConfiguration.id, indexed)",
    "run_id": "string (UUID, unique, indexed)",
    "triggered_by_user_id": "string (references User.id, nullable)",
    "trigger_type": "string (enum: 'manual', 'schedule', 'webhook', 'command')",
    "status": "string (enum: 'pending', 'running', 'success', 'error', 'cancelled')",
    "start_time": "timestamp",
    "end_time": "timestamp (nullable)",
    "input_params_snapshot": "json_object (nullable)",
    "output_preview": "text (nullable)",
    "full_output_ref": "string (nullable, URI to full output)",
    "error_message": "text (nullable)",
    "logs_ref": "string (nullable, URI to detailed logs if stored elsewhere)"
  },
  "Playbook": {
    "id": "string (UUID, primary_key, default: uuid_generate_v4())",
    "agent_definition_id": "string (references AgentDefinition.id, indexed, nullable)",
    "agent_configuration_id": "string (references AgentConfiguration.id, indexed, nullable)",
    "workspace_id": "string (references Workspace.id, indexed, nullable)",
    "name": "string (e.g., 'Abandoned Cart Recovery - Aggressive')",
    "description": "text (nullable)",
    "trigger_event_type": "string (e.g., 'shopify_abandoned_cart', 'manual_list_upload')",
    "steps": "json_array_of_objects",
    "is_active": "boolean (default: true)",
    "created_at": "timestamp",
    "updated_at": "timestamp"
  },
  "CanvasPage": {
    "id": "string (UUID)",
    "workspace_id": "string (references Workspace.id, indexed)",
    "title": "string",
    "created_at": "timestamp",
    "updated_at": "timestamp",
    "parent_page_id": "string (references CanvasPage.id, nullable, for nesting)",
    "icon_url": "string (url, nullable)"
  },
  "CanvasBlock": {
    "id": "string (UUID)",
    "page_id": "string (references CanvasPage.id, indexed)",
    "type": "string (enum: 'text', 'chat_bubble', 'agent_snippet', 'embed_panel', 'table_view', 'kanban_board', 'image', 'video', 'shopify_product', 'tiktok_post')",
    "content": "json_object",
    "position_x": "integer",
    "position_y": "integer",
    "width": "integer",
    "height": "integer",
    "created_at": "timestamp",
    "updated_at": "timestamp",
    "z_index": "integer (default: 0)"
  },
  "ChatDockChannel": {
    "id": "string (UUID)",
    "workspace_id": "string (references Workspace.id, indexed)",
    "name": "string",
    "type": "string (enum: 'public', 'private', 'dm')",
    "description": "text (nullable)",
    "member_user_ids": ["string (references User.id, for private/dm channels)"],
    "created_at": "timestamp",
    "updated_at": "timestamp"
  },
  "ChatMessage": {
    "id": "string (UUID)",
    "channel_id": "string (references ChatDockChannel.id, indexed)",
    "sender_id": "string (references User.id or AgentConfiguration.id, indexed)",
    "sender_type": "string (enum: 'user', 'agent')",
    "content_type": "string (enum: 'text', 'markdown', 'json_proposal', 'agent_command_response', 'file_attachment')",
    "content": "json_object",
    "created_at": "timestamp",
    "thread_id": "string (references ChatMessage.id, optional, for threading, indexed)",
    "reactions": [
      {
        "emoji": "string",
        "user_ids": ["string (references User.id)"]
      }
    ],
    "read_by_user_ids": ["string (references User.id)"]
  }
}
```

## 3. API Interaction Concepts (High-Level)

Microservices will primarily interact via synchronous RESTful APIs (e.g., HTTP/JSON) for request/response patterns and asynchronous messaging (e.g., using a message broker like RabbitMQ or Kafka) for event-driven communication. An API Gateway will serve as the single entry point for client applications.

*   **User Authentication & Authorization:**
    *   Client (Frontend) sends login credentials to the `API Gateway`.
    *   `API Gateway` routes the request to the `User Service`.
    *   `User Service` verifies credentials, generates a JWT, and returns it.
    *   For subsequent requests, the client includes the JWT. The `API Gateway` can perform initial validation, and downstream services can further validate and extract user information/permissions from the JWT or by calling the `User Service`.

*   **Canvas Operations:**
    *   User adds a "Shopify Product Lister" block to a Canvas page.
    *   Frontend sends a request to `Canvas Service` to create a `CanvasBlock` of type `shopify_product_lister`.
    *   `Canvas Service` stores the block configuration.
    *   To render the block, `Canvas Service` (or the client via `Canvas Service` acting as a proxy) requests product data from `Shopify Integration Service`, providing the necessary Shopify store credentials (likely retrieved via `Brand Service` or stored securely and referenced).
    *   `Shopify Integration Service` fetches data from Shopify and returns it to `Canvas Service` / client.

*   **Agent Execution via Chat:**
    *   User types `/run_marketing_agent {campaign_brief: "New summer collection"}` in the `ChatDock`.
    *   Frontend sends the message to `Chat Service`.
    *   `Chat Service` identifies it as a command, parses it, and might publish an event (e.g., `agent_command_received`) or directly call `Agent Service`.
    *   `Agent Service` receives the command, looks up the specified `AgentConfiguration` (e.g., "Marketing Agent").
    *   The agent's YAML config might specify interaction with an LLM. `Agent Service` calls `LLM Orchestration Service` with the prompt (constructed from the agent's template and user input).
    *   `LLM Orchestration Service` interacts with the configured LLM (e.g., OpenAI).
    *   The LLM response is returned to `Agent Service`.
    *   If the agent needs to fetch Shopify data (e.g., product details for the campaign), `Agent Service` would call `Shopify Integration Service`.
    *   `Agent Service` processes the results, potentially stores outputs, and sends a response back to `Chat Service`.
    *   `Chat Service` posts the agent's response message into the relevant channel.

*   **Workspace Creation:**
    *   User initiates workspace creation.
    *   Frontend sends a request to `Workspace Service` (via `API Gateway`).
    *   `Workspace Service` creates a new `Workspace` record, associating it with the `owner_user_id`.
    *   It might also trigger the creation of a default `PromptLibrary` for that workspace by calling `Prompt Library Service`.

*   **Notifications:**
    *   `Agent Service` completes a long-running task. It publishes an event (e.g., `agent_task_completed`) to a message broker.
    *   `Notification Service` subscribes to such events.
    *   Upon receiving the event, `Notification Service` determines the relevant user(s) and sends a notification (e.g., in-app popup, email) via appropriate channels (WebSockets, email provider).

*   **Cross-Service Data Consistency:**
    *   For data that needs to be referenced across services (e.g., `User.id` in `Workspace.owner_user_id`), services will either call each other directly for validation/retrieval or rely on eventual consistency patterns if strong consistency is not immediately required.
    *   For example, when creating a `Workspace`, the `Workspace Service` might call the `User Service` to validate that the `owner_user_id` exists.
```
