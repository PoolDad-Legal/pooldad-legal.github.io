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
    "member_user_ids": ["string (references User.id)"] // Added for collaboration
  },
  "Brand": {
    "id": "string (UUID)",
    "workspace_id": "string (references Workspace.id, indexed)",
    "name": "string",
    "industry": "string (nullable)",
    "target_audience": "text (nullable)",
    "mood_board_urls": ["string (url)"],
    "shopify_store_url": "string (url, nullable)",
    "tiktok_profile_url": "string (url, nullable)",
    "created_at": "timestamp",
    "updated_at": "timestamp"
  },
  "Creator": {
    "id": "string (UUID)",
    "workspace_id": "string (references Workspace.id, indexed)",
    "name": "string",
    "niche": "string (nullable)",
    "tiktok_handle": "string (nullable)",
    "portfolio_links": ["string (url)"],
    "audience_demographics": "json_object (nullable)", // e.g., { "age_range": "18-25", "interests": ["gaming", "tech"] }
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
    "tags": ["string (nullable)"] // Added for better organization
  },
  "PromptLibrary": {
    "id": "string (UUID)",
    "workspace_id": "string (references Workspace.id, indexed)",
    "name": "string",
    "description": "text (nullable)",
    "created_at": "timestamp",
    "updated_at": "timestamp"
  },
  "AgentConfiguration": {
    "id": "string (UUID)",
    "workspace_id": "string (references Workspace.id, indexed)",
    "agent_definition_id": "string (references AgentDefinition.id, indexed)",
    "name": "string",
    "description": "text (nullable)",
    "yaml_config": "text (yaml format)", // Specific settings for this instance
    "created_by_user_id": "string (references User.id, indexed)",
    "created_at": "timestamp",
    "updated_at": "timestamp",
    "last_run_status": "string (enum: 'idle', 'running', 'success', 'error', nullable)",
    "last_run_at": "timestamp (nullable)"
  },
  "AgentDefinition": { // For marketplace/templates
    "id": "string (UUID)",
    "name": "string (unique)",
    "description": "text",
    "input_schema": "json_schema", // Defines expected input structure
    "output_schema": "json_schema", // Defines structure of output
    "version": "string (semver)",
    "underlying_services_required": ["string (enum: 'LLM', 'Shopify', 'TikTok', 'WebSearch')"], // Example services
    "category": "string (e.g., 'Marketing', 'Content Creation')", // Added for organization
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
    "icon_url": "string (url, nullable)" // Added for visual distinction
  },
  "CanvasBlock": {
    "id": "string (UUID)",
    "page_id": "string (references CanvasPage.id, indexed)",
    "type": "string (enum: 'text', 'chat_bubble', 'agent_snippet', 'embed_panel', 'table_view', 'kanban_board', 'image', 'video', 'shopify_product', 'tiktok_post')",
    "content": "json_object", // Structure varies by type
    // Example for "text": { "markdown": "# Hello" }
    // Example for "agent_snippet": { "agent_config_id": "uuid", "last_run_output_preview": "...", "run_parameters": {} }
    // Example for "shopify_product": { "product_id": "gid://shopify/Product/12345", "display_options": {} }
    "position_x": "integer",
    "position_y": "integer",
    "width": "integer",
    "height": "integer",
    "created_at": "timestamp",
    "updated_at": "timestamp",
    "z_index": "integer (default: 0)" // Added for layering
  },
  "ChatDockChannel": {
    "id": "string (UUID)",
    "workspace_id": "string (references Workspace.id, indexed)",
    "name": "string",
    "type": "string (enum: 'public', 'private', 'dm')", // DM might involve user_ids instead of a generic name
    "description": "text (nullable)", // Added
    "member_user_ids": ["string (references User.id, for private/dm channels)"], // Added
    "created_at": "timestamp",
    "updated_at": "timestamp"
  },
  "ChatMessage": {
    "id": "string (UUID)",
    "channel_id": "string (references ChatDockChannel.id, indexed)",
    "sender_id": "string (references User.id or AgentConfiguration.id, indexed)", // Clarified sender can be agent
    "sender_type": "string (enum: 'user', 'agent')", // Added to distinguish sender
    "content_type": "string (enum: 'text', 'markdown', 'json_proposal', 'agent_command_response', 'file_attachment')",
    "content": "json_object", // For 'text': {"text": "message"}, for 'file_attachment': {"url": "...", "filename": "...", "mime_type": "..."}
    "created_at": "timestamp",
    "thread_id": "string (references ChatMessage.id, optional, for threading, indexed)",
    "reactions": [ // Added for interactivity
      {
        "emoji": "string",
        "user_ids": ["string (references User.id)"]
      }
    ],
    "read_by_user_ids": ["string (references User.id)"] // Added for read receipts
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
