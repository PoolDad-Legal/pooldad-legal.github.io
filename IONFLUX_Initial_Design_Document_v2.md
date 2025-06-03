# IONFLUX - Initial Design Document (v2)

## 1. Introduction

This document serves as the updated Initial Design Document for the IONFLUX project. It consolidates the core conceptual definitions, UI/UX principles, technical strategies, and detailed agent blueprints that have been developed and refined during the initial project planning and design phase.

The high-level vision for IONFLUX is to create a "Notion-Max" platform enhanced by AI agents, designed as a central command center for brands and creators. This document reflects the incorporation of detailed specifications for ten core agents, refined data models, interaction paradigms, and technical stack considerations, providing a comprehensive foundation for subsequent E2E demo and MVP development phases. It represents the culmination of iterative design and specification efforts.

---
## 2. Core Architecture & Data Models
(Content from `conceptual_definition.md`)

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

---
## 3. Foundational UI/UX Concepts
(Content from `ui_ux_concepts.md`)

# IONFLUX Project: UI/UX Concepts

This document outlines the foundational UI/UX concepts for the IONFLUX platform, based on the project proposal and `conceptual_definition.md`.

## 1. Sidebar Navigation

The sidebar is the primary navigation hub, persistent on the left side of the screen. It's collapsible to maximize workspace.

**Structure:**

The sidebar will be organized into hierarchical sections, with icons and text labels.

*   **A. Workspace Switcher (Top-most element):**
    *   Displays the current `Workspace.name` with a dropdown arrow.
    *   Clicking it opens a menu to:
        *   Switch between existing workspaces the user is a member of.
        *   "Create New Workspace" - opens a modal for `Workspace.name` input.
        *   "Workspace Settings" - navigates to a settings page for the current workspace.
    *   Each workspace in the dropdown shows its name and potentially a small icon/avatar.

*   **B. Canvas Pages (Primary Section, Dynamic based on current Workspace):**
    *   Label: "Canvas" or "Pages".
    *   A tree-like structure displaying `CanvasPage` items.
        *   Each item shows `CanvasPage.icon_url` (if any) and `CanvasPage.title`.
        *   Pages can be nested (`parent_page_id`) visually using indentation and expand/collapse chevrons (e.g., `>` for collapsed, `v` for expanded).
        *   Hovering over a page name reveals a "+" icon to add a child page and a "..." (meatball) menu for page options (Rename, Delete, Move, Duplicate).
    *   Interaction:
        *   Clicking a page name opens that page in the main content area.
        *   Drag-and-drop functionality to reorder pages and change nesting.
    *   Adding a new top-level page: A "+" button at the top of this section or via Command Palette.

*   **C. Brand & Creator Hub (Dynamic based on current Workspace):**
    *   Label: "Personas" or "Assets".
    *   Expandable/collapsible section.
    *   Sub-sections:
        *   **Brands:**
            *   Lists `Brand.name` items.
            *   Clicking a brand name navigates to a dedicated view/editor for that brand's details (industry, audience, mood boards, connected Shopify/TikTok).
            *   "+" button to add a new Brand (opens a form/modal).
        *   **Creators:**
            *   Lists `Creator.name` items.
            *   Clicking a creator name navigates to a dedicated view/editor for that creator.
            *   "+" button to add a new Creator.

*   **D. Libraries (Dynamic based on current Workspace):**
    *   Label: "Libraries".
    *   Expandable/collapsible section.
    *   Sub-sections:
        *   **Prompt Libraries:**
            *   Lists `PromptLibrary.name` items.
            *   Clicking a library name opens a view showing all `Prompt` items within it.
            *   "+" button to add a new Prompt Library (modal for name, description).
            *   Each `PromptLibrary` item can be expanded to show its `Prompt`s directly in the sidebar, or this can be a main view navigation. (Decision: For simplicity, clicking library name opens main view, not direct expansion in sidebar for prompts).

*   **E. Agent Hub (Dynamic based on current Workspace):**
    *   Label: "Agents".
    *   Expandable/collapsible section.
    *   Sub-sections:
        *   **Configured Agents:**
            *   Lists `AgentConfiguration.name` items for agents configured within the current workspace.
            *   Clicking an agent name navigates to its configuration/management page.
            *   "+" button to "Configure New Agent" - likely opens a view that leverages the Agent Marketplace.
        *   **Agent Marketplace (Link):**
            *   A static link/button: "Browse Agent Marketplace".
            *   Navigates to a full-page view listing available `AgentDefinition`s (templates), filterable by category, capabilities (e.g., "Shopify", "LLM"). Users can select an agent definition to create a new `AgentConfiguration` from it.

*   **F. Global Items (Bottom of Sidebar):**
    *   Search (Icon only, expands to a search bar or invokes Command Palette).
    *   Notifications (Bell icon with a badge for unread notifications).
    *   User Profile / Settings (User avatar, clicking opens a menu with "Profile", "Settings", "Logout").

**Interaction:**

*   **Switching:** Clicking on any item (Workspace, Page, Brand, Library, Agent) makes it active and typically changes the main content view.
*   **Expand/Collapse:** Sections like "Personas", "Libraries", "Agents" and nested "Canvas Pages" will have chevron icons (`>` or `v`) to toggle visibility of their children. User's preference for expanded/collapsed state should be remembered.
*   **Adding New Items:** "+" icons next to section headers or list items, or contextually (e.g., "Create New Workspace" in workspace switcher). Also achievable via Command Palette.

## 2. Canvas

The Canvas is the main interactive workspace where users assemble information and tools.

**Page Structure:**

*   **Top Bar:**
    *   **Breadcrumbs:** If the `CanvasPage` is nested, breadcrumbs show the path (e.g., "Workspace Name / Parent Page / Current Page Title").
    *   **Page Title:** Editable `CanvasPage.title`.
    *   **Share/Collaboration Icons:** (Future) Shows avatars of current viewers/editors.
    *   **Page Options Menu:** ("..." icon) - Rename, Duplicate, Delete Page, Page Settings, Export.
*   **Main Area:** An infinite or very large pannable, zoomable space where `CanvasBlock`s are placed. A grid background might be visible to aid alignment.

**Block Interaction:**

*   **Visual Differentiation:**
    *   **Text Block:** Standard text rendering, might have a subtle border on hover/selection. WYSIWYG controls appear on selection.
    *   **Chat Bubble Block:** Styled like a message bubble (e.g., from iMessage or Slack), with sender info (user/agent avatar) and timestamp.
    *   **Agent Snippet Block:** Distinctive card-like appearance. Header with Agent name/icon. Body shows a preview of `last_run_output` or controls to run/configure. A status indicator (dot or badge: green for success, yellow for running, red for error, grey for idle).
    *   **Embed Panel Block:** Shows the embedded content (e.g., YouTube video, Figma file). May have a header bar with the source URL or title.
    *   **Table View Block:** Renders as a spreadsheet-like table.
    *   **Kanban Board Block:** Columns and cards.
    *   **Image Block:** Displays the image, resize handles.
    *   **Video Block:** Displays video player.
    *   **Shopify Product Block:** Card showing product image, title, price. May have a "View on Shopify" button.
    *   **TikTok Post Block:** Embed of the TikTok video/post.
    *   All blocks will have a consistent selection highlight (e.g., a blue border) and resize handles when selected. A small context menu icon ("...") on the block for options like Delete, Duplicate, Edit.

*   **Adding a New Block:**
    *   **"+" Button on Canvas:** A floating "+" button or a persistent one in a toolbar. Clicking it opens a palette/menu of available block types. Selecting a type places a default-sized block on the canvas near the click or in the current viewport center.
    *   **Drag-and-Drop from Palette:** A collapsible side panel (right or left) could offer icons for each block type, draggable onto the canvas.
    *   **Slash Command on Canvas:** Typing "/" on an empty area of the canvas (or within a text block and then converting it) could bring up a searchable list of block types, similar to Notion. E.g., `/image`, `/agent snippet`.

*   **Moving, Resizing, Editing Blocks:**
    *   **Moving:** Click and drag the block. Alignment guides (snap lines) appear when moving near other blocks or a grid.
    *   **Resizing:** Select block, then drag corner or edge handles.
    *   **Editing:**
        *   Text Block: Double-click to enter text edit mode with WYSIWYG toolbar.
        *   Agent Snippet: Click a "Configure" button on the block to open a modal/sidebar to edit its `yaml_config` or select `agent_config_id`.
        *   Other blocks: A dedicated "Edit" button in the block's context menu or a settings icon on the block itself, opening a modal or inspector panel for its `content` properties.

*   **Agent Snippet Block Status/Output:**
    *   **Status:** A small colored dot or text label (e.g., "Idle", "Running...", "Success", "Error") in the block's header or corner.
    *   **Output:** `last_run_output` (or a summary of it) is displayed in the main body of the block. This could be text, a table, a chart, depending on the agent's `output_schema`. An "Expand" button if output is lengthy. A "Run" button if idle or to re-run. If an error, a "View Error" link to see details.

**Page Management:**

*   **New Pages:**
    *   Through the sidebar's "Canvas" section "+" button.
    *   Via Command Palette ("Create new page").
    *   From a page's "..." menu: "Add sub-page".
*   **Linking:**
    *   `@mention` syntax within Text blocks to link to other `CanvasPage`s, `Brand`s, `Creator`s, etc. (e.g., `@[Page Title]`).
    *   Dedicated "Link" block type or by making any block a clickable link to another page.
*   **Organization:**
    *   Primarily through the tree structure in the sidebar (drag-and-drop nesting).
    *   Alternative view: A dedicated "Canvas Overview" page that shows pages as cards in a mind-map or whiteboard layout, allowing visual linking and organization.

## 3. Chat Dock

A persistent panel, typically on the right side of the screen or collapsible.

**Layout:**

*   **Top Bar:**
    *   Current Workspace name (or context).
    *   Search bar for messages within the Chat Dock.
    *   "New Message/Channel" icon.
*   **Channel List Panel (Left within Chat Dock):**
    *   Sections: "Channels" (public/private), "Direct Messages".
    *   Each item shows channel/user name, unread message badge, potentially a status icon for users (online/offline).
    *   Selected channel/DM is highlighted.
    *   "+" icon to browse/create channels or start new DMs.
*   **Message View Panel (Right, main area of Chat Dock):**
    *   **Header:** Channel name or DM recipient name(s). Options for channel settings, call (future).
    *   **Message History:** Chronological list of messages. User avatars next to their messages. Timestamps.
    *   **Threads:** Replies to a message are visually indented or shown in a separate panel that slides in when a thread is opened. A "X replies" link on the parent message.
    *   **Message Input Box (Bottom):** Text area for typing messages. Formatting options (bold, italic, lists, code blocks). Attach file icon. Emoji picker. Send button.

**Interaction:**

*   **Sending Message:** Type in input box, press Enter or click Send.
*   **Starting Thread:** Hover over a message, a "Reply in thread" icon appears. Clicking it focuses the input box for a threaded reply, and messages are then added to that thread.
*   **Replying to Thread:** Click on the "X replies" link on a parent message to open the thread view (e.g., in a right-hand sidebar within the Chat Dock or inline) and then type in the thread's input box.
*   **/commands:**
    *   Typed directly into the message input box, starting with `/`.
    *   As the user types, an autocomplete suggestion box appears above the input box, listing available commands and their syntax (e.g., `/run_agent [agent_name] {params}`).
    *   Visually, the entered command in the message history might have a distinct background or icon.
*   **Mentions (`@user`, `@agent`):**
    *   Typing `@` triggers a user/agent list popup. Selecting a user/agent inserts the mention.
    *   In the message history, mentions are highlighted (e.g., different color, bold) and are clickable, navigating to user profile or agent configuration/info.
*   **Agent Responses:**
    *   **Standard Text:** Displayed like a normal user message, but with the Agent's name and avatar.
    *   **`json_proposal`:** Could be rendered as a structured card with key-value pairs, or a "View JSON" button. If it's a proposal for an action, it might have "Accept" / "Decline" buttons.
    *   **`agent_command_response`:** Could be a simple text confirmation, or a more complex card if it includes data. For example, if an agent lists Shopify products, it might show a compact list with images and titles.
    *   Agent messages might have a distinct background color or a small "bot" icon to differentiate from user messages.

## 4. Command Palette (⌘K / Ctrl+K)

A modal overlay, typically centered on the screen, for quick navigation and actions.

**Access:**

*   Keyboard shortcut: `⌘K` (Mac) or `Ctrl+K` (Windows/Linux).
*   Clicking a search icon in the global section of the sidebar.

**Functionality:**

*   **Search Input:** A prominent text input field at the top.
*   **Search Categories/Filters:** Tabs or buttons to filter search scope (e.g., "All", "Pages", "Agents", "Prompts", "Brands", "Files").
*   **What users can search for:**
    *   `CanvasPage.title`
    *   `AgentConfiguration.name`, `AgentDefinition.name`
    *   `Prompt.name`, `PromptLibrary.name`
    *   `Brand.name`, `Creator.name`
    *   Files/Attachments (if file storage is implemented)
    *   Workspace settings sections
    *   Users within the workspace (for DMs or sharing)
*   **Quick Actions (can be context-aware based on current view or search term):**
    *   "Create new page" (optionally with title from search query)
    *   "Create new Brand/Creator/Prompt Library"
    *   "Configure new Agent"
    *   "Run agent [Agent Name]" (if search query matches an agent)
    *   "Open settings for [Brand/Creator Name]"
    *   "Invite user to workspace"
    *   "Switch workspace to [Workspace Name]"
    *   "Go to [Settings Page]" (e.g., "Billing", "User Profile")

**Display:**

*   **Results List:** Below the search input, a scrollable list of results.
*   Each result item typically shows:
    *   An icon relevant to the item type (e.g., page icon, agent icon).
    *   Primary name/title.
    *   Secondary context (e.g., parent page for a sub-page, "Agent Configuration" for an agent instance).
    *   Breadcrumb or path if relevant.
*   Actions are listed similarly, often with a specific action icon (e.g., "+" for create).
*   Keyboard navigable (up/down arrows, Enter to select).
*   Fuzzy search is expected.

## 5. Core User Flows

**A. Creating a new Canvas Page:**

1.  **Initiation:**
    *   User clicks the "+" button next to the "Canvas" section in the sidebar.
    *   OR: User types `⌘K` -> "Create new page" -> Enter.
    *   OR: User is on an existing page, clicks "..." menu -> "Add sub-page".
2.  **Input:**
    *   If via sidebar "+": A new, untitled page is immediately created in the sidebar list, often with an inline editable title field focused. User types title, presses Enter.
    *   If via Command Palette: May prompt for a title directly in the palette or create an "Untitled" page.
3.  **Navigation:** The user is automatically navigated to the newly created blank Canvas page in the main content area.
4.  **Focus:** The page title at the top of the canvas might be auto-focused for editing.

**B. Adding an Agent to a Canvas Page and configuring it:**

1.  **Open Canvas Page:** User navigates to the desired `CanvasPage`.
2.  **Add Agent Snippet Block:**
    *   User clicks the "+" button on the canvas (or uses slash command `/agent snippet`).
    *   Selects "Agent Snippet" from the block type palette.
3.  **Block Placement:** An "Agent Snippet" block appears on the canvas. Initially, it's in an unconfigured state.
    *   Text within block: "Configure Agent" or "Select Agent".
4.  **Configuration:**
    *   User clicks a "Configure" button on the block.
    *   This opens a modal or a side panel:
        *   **Option 1: Select Existing `AgentConfiguration`:** A searchable list/dropdown of `AgentConfiguration.name`s already set up in the workspace. User selects one.
        *   **Option 2: Create New Configuration from `AgentDefinition`:**
            *   User browses/searches the Agent Marketplace (list of `AgentDefinition`s).
            *   Selects an `AgentDefinition` (template).
            *   Fills in `AgentConfiguration.name`, `description`.
            *   Edits the `yaml_config` (presented in a user-friendly form editor if possible, or raw YAML for advanced users) based on the `AgentDefinition.input_schema`.
            *   Saves the new `AgentConfiguration`. This instance is now available for selection.
5.  **Link to Block:** The selected/newly created `AgentConfiguration.id` is stored in the `CanvasBlock.content.agent_config_id`.
6.  **Display:** The Agent Snippet block updates to show the configured agent's name. It might initially show "Idle" status and a "Run" button. Input fields defined in the agent's config (if any are meant for runtime) might appear on the block itself.

**C. Invoking an Agent using a `/command` in the Chat Dock:**

1.  **Open Chat Dock:** User has the Chat Dock open, focused on a channel or DM.
2.  **Type Command:** User types `/` in the message input. An autocomplete menu appears.
    *   Example: `/run_agent`
3.  **Select Command & Agent:** User types or selects `run_agent`. Autocomplete then suggests available `AgentConfiguration.name`s.
    *   Example: `/run_agent Marketing Content Generator`
4.  **Provide Parameters (if any):**
    *   The agent's required parameters (from its `AgentDefinition.input_schema` that are not pre-set in `AgentConfiguration.yaml_config`) are shown as placeholders or the user needs to know them.
    *   User types parameters in a structured format, likely JSON-like, or key-value pairs.
    *   Example: `/run_agent Marketing Content Generator {topic: "New Summer Collection Launch", tone: "Excited"}`
    *   Autocomplete/validation for parameter names and types would be ideal.
5.  **Send Command:** User presses Enter. The message with the command is sent and appears in the chat history, possibly styled differently.
6.  **Agent Processing:**
    *   `Chat Service` routes this to `Agent Service`.
    *   `Agent Service` starts the execution. It might send an immediate acknowledgement back to the chat: "Okay, running Marketing Content Generator..." (as the agent).
7.  **Display Response:**
    *   Once the agent completes, its response (`ChatMessage.content` with `content_type` like `text`, `json_proposal`, or `agent_command_response`) is posted in the chat by the agent.
    *   This response is formatted appropriately (e.g., text, card, interactive elements).
    *   If it's a long process, status updates might be posted periodically.

---
## 4. SaaS/API Integration Layers
(Content from `saas_api_integration_specs.md`)

# IONFLUX Project: SaaS/API Integration Specifications

This document details the specifications for integrating third-party SaaS platforms and APIs into the IONFLUX ecosystem. It builds upon the `conceptual_definition.md`, `ui_ux_concepts.md`, and incorporates insights from `core_agent_blueprints.md`.

## 1. LLM Provider Integration (`LLM Orchestration Service`)

The `LLM Orchestration Service` will act as a central hub for all Large Language Model interactions, providing a unified interface for other IONFLUX services.

**1.1. Primary Provider Choice (for Beta):**

*   **Recommendation:** **OpenAI**
*   **Justification:**
    *   **Mature API:** OpenAI offers a well-documented, robust, and feature-rich API.
    *   **Model Variety & Capability:** Access to a wide range of models (e.g., GPT-3.5-turbo, GPT-4, GPT-4o, Embeddings, Whisper) suitable for diverse tasks outlined in the IONFLUX proposal.
    *   **Strong Developer Ecosystem:** Extensive community support, libraries, and resources are available, potentially speeding up development.
    *   **Performance:** Generally good performance in terms of response quality and latency for many common use cases.
    *   While other providers like Anthropic (Claude) or Google (Gemini) are strong contenders, OpenAI's current overall maturity and widespread adoption make it a pragmatic choice for the initial beta to ensure rapid development and a broad feature set. This choice can be expanded later.

**1.2. API Key Management Strategy:**

*   **How keys will be obtained:**
    *   **Initial Beta:** IONFLUX will use a **central IONFLUX-owned API key** for each LLM provider (e.g., one OpenAI key for the platform). This simplifies the initial user experience as users won't need to procure their own keys immediately.
    *   **Future Consideration:** Allow users/workspaces to optionally provide their own API keys. This can be beneficial for users who want to leverage their existing accounts, manage their own rate limits, or have specific billing arrangements with LLM providers. If a user provides a key, it would override the central key for their requests.
*   **How keys will be stored securely:**
    *   Central IONFLUX API keys will be stored in a **dedicated secrets management service** (e.g., HashiCorp Vault, AWS Secrets Manager, Google Secret Manager). They will NOT be stored directly in the database or codebase.
    *   If user-provided keys are implemented, they will be encrypted at rest (e.g., using AES-256) in the database, associated with the `Workspace` or `User` entity. The encryption key itself will be managed by the secrets management service.
*   **How `LLM Orchestration Service` accesses and uses these keys:**
    *   The `LLM Orchestration Service` will have secure, IAM-controlled access to the secrets management service to retrieve the central IONFLUX API key(s) at runtime.
    *   If user-provided keys are used, the service would retrieve the encrypted key from the database, decrypt it using a key from the secrets manager, and then use it for the API call. The decrypted key should only be held in memory for the duration of the request.
    *   A mapping within `LLM Orchestration Service` or its configuration will determine which key to use based on the request context (e.g., default IONFLUX key, or a specific user/workspace key if provided).

**1.3. Core Request/Response Structure (Internal):**

This defines the internal API contract between services like `Agent Service` and the `LLM Orchestration Service`.

*   **Request to `LLM Orchestration Service`:**
    ```json
    {
      "provider": "string (e.g., 'openai', 'anthropic', 'deepseek', 'sentence-transformers', defaults to 'openai')",
      "model": "string (e.g., 'gpt-4o', 'claude-3-haiku', 'ds-chat-b32', 'multi-qa-MiniLM-L6-cos-v1')",
      "task_type": "string (enum: 'text_generation', 'embedding', 'speech_to_text', 'image_understanding', default: 'text_generation')", // NEW
      "prompt": "string (nullable, for text_generation, image_understanding)",
      "text_to_embed": "string (nullable, for embedding task)",
      "audio_input_url": "string (nullable, for speech_to_text task)",
      "image_input_url": "string (nullable, for image_understanding task)",
      "system_prompt": "string (optional)",
      "history": [
        { "role": "user", "content": "Previous message" },
        { "role": "assistant", "content": "Previous response" }
      ],
      "parameters": {
        "max_tokens": "integer (optional)",
        "temperature": "float (optional, 0.0-2.0)",
        "top_p": "float (optional, 0.0-1.0)",
        "stop_sequences": ["string (optional)"]
      },
      "user_id": "string (UUID, references User.id)",
      "workspace_id": "string (UUID, references Workspace.id)",
      "request_id": "string (UUID, for logging and tracing)"
    }
    ```

*   **Response from `LLM Orchestration Service`:**
    *   **Success:**
        ```json
        {
          "status": "success",
          "request_id": "string (UUID, mirrors request)",
          "task_type": "string (mirrors request task_type)", // NEW
          "provider_response": {
            "id": "string (provider's response ID)",
            "model_used": "string (actual model that handled the request)", // NEW
            "choices": [ // For text_generation
              {
                "text": "string (generated text)",
                "finish_reason": "string (e.g., 'stop', 'length')"
              }
            ],
            "embedding": ["float (nullable, for embedding task)"], // NEW
            "transcription": "text (nullable, for speech_to_text task)", // NEW
            "image_analysis_text": "text (nullable, for image_understanding task)", // NEW
            "usage": {
              "prompt_tokens": "integer",
              "completion_tokens": "integer (nullable)",
              "total_tokens": "integer"
            }
          }
        }
        ```
    *   **Error:**
        ```json
        {
          "status": "error",
          "request_id": "string (UUID, mirrors request)",
          "error": {
            "code": "string (internal error code)",
            "message": "string (user-friendly error message)",
            "provider_error": "object (optional, raw error from LLM provider)"
          }
        }
        ```

**1.4. Supported Model Types & Providers (Initial Focus):**
The `LLM Orchestration Service` is designed to be a true orchestration layer.
*   **Text Generation & Reasoning:** OpenAI (GPT-4o, GPT-3.5-turbo), Anthropic (Claude 3 Haiku), DeepSeek (ds-chat-b32).
*   **Embeddings:** OpenAI (text-embedding-3-small), Sentence-Transformers (various models, potentially run via a dedicated embedding service IONFLUX might host, or via API if available). The service abstracts embedding generation.
*   **Speech-to-Text:** OpenAI (Whisper-large).
*   **Image Understanding/Processing (Conceptual for future agents, but good to anticipate):** Models like CLIP for image embeddings or visual Q&A. The service should anticipate routing such requests if they arise from agent needs.

**1.5. Vector DB Interaction for RAG/Memory:**
The `LLM Orchestration Service`'s primary role is to provide access to LLM models for generation, embeddings, etc. It does *not* directly manage or interact with vector databases for agent memory or Retrieval Augmented Generation (RAG) patterns.
*   The `AgentService` (or the agent's own logic) is responsible for:
    *   Querying vector databases (like Pinecone) for relevant context.
    *   Constructing prompts that include this retrieved context.
    *   Sending these enriched prompts to the `LLM Orchestration Service`.
*   The `LLM Orchestration Service` may generate embeddings (via an embedding model) which the `AgentService` then stores in a vector database by the agent's logic.

## 2. Shopify Integration (`Shopify Integration Service`)

This service will handle all communications with the Shopify platform.

**2.1. Authentication:** (As previously defined - OAuth 2.0 Flow)

**2.2. Key Shopify APIs & Data Points:**
*   (As previously defined, ensure scopes cover:)
    *   `read_products`, `write_products` (if agents modify products)
    *   `read_product_listings` (for broader catalog access if needed by agents like Outreach Automaton)
    *   `read_orders`, `write_orders` (if agents modify orders)
    *   `read_customers`, `write_customers` (with PII caution)
    *   `read_shop_locales` (for currency, timezone, etc.)
    *   `read_inventory`, `write_inventory`
*   Webhook management APIs are also key.

**2.3. Webhook Subscriptions:**
*   (As previously defined: `orders/create`, `orders/updated`, `orders/paid`, `orders/fulfilled`, `products/create`, `products/update`, `app/uninstalled`, `shop/update`).
*   **Webhook Forwarding:** Critical webhooks (e.g., `orders/create`, `products/update`) received by the `Shopify Integration Service` should not only be processed for direct agent needs but can also be published to an internal IONFLUX message broker (e.g., RabbitMQ topic: `platform.shopify.events.orders.created`). This allows multiple internal services or agents (like `Email Wizard` or `Badge Motivator`) to react to these events in a decoupled manner.

**2.4. Data Sync Strategy:** (As previously defined - Webhooks primary, Polling secondary)

## 3. TikTok Integration (`TikTok Integration Service`)

This service will manage interactions with TikTok APIs.

**3.1. Authentication:** (As previously defined - OAuth 2.0 Flow)

**3.2. Key TikTok APIs & Data Points:**
*   (As previously defined)
*   **Trending Data Clarification (for `TikTok Stylist`):** Direct API access to "trending sounds" can be limited or require specific partnerships. Initial implementation may rely on hashtag/video search proxies (`GET /v2/research/video/query/`, `GET /v2/research/hashtag/query/`), or curated lists, while pursuing deeper trend data access. IONFLUX may need to implement its own trend detection logic based on data from these research APIs.

**3.3. Permissions (OAuth Scopes - TikTok Developer API example):**
*   (As previously defined) Reconfirm that `research.video.query` and `research.hashtag.query` are appropriate. Add `user.video.profiles` or similar if needed for fetching video lists of specific, authenticated users.

**3.4. Content Moderation/Compliance:** (As previously defined)

## 4. Email Sending Service Integration (e.g., SendGrid, AWS SES)

*   **Purpose within IONFLUX:** To enable agents like `Email Wizard` (Agent 001) and potentially `Outreach Automaton` (Agent 006) or `UGCMatchmaker` (Agent 005 for "GhostPitch") to send emails programmatically. This includes transactional emails (e.g., notifications if email is chosen channel) and agent-generated content (e.g., marketing drafts, outreach messages).
*   **Authentication Approach:**
    *   **Platform-Managed Keys:** IONFLUX will maintain its own account(s) with one or more Email Service Providers (ESPs like SendGrid or AWS SES). API keys for these ESPs will be stored securely in the IONFLUX secrets management system.
    *   **User-Provided Keys (Future):** Allow workspaces to configure their own ESP accounts/API keys for enhanced deliverability, domain reputation management, and direct billing.
*   **Key API Functionalities IONFLUX Would Use:**
    *   Send single emails.
    *   Send bulk/batched emails (respecting ESP policies).
    *   (Optional) Basic template variable substitution if ESP supports it simply. Complex templating likely handled by agent logic before calling send.
    *   Receive and process webhooks for delivery status (bounces, spam reports, opens, clicks) to track email effectiveness and manage list hygiene.
*   **Responsible IONFLUX Service:**
    *   A new **`NotificationService` enhancement or a dedicated `EmailDispatchService`**.
        *   If primarily for agent-generated notifications and simple messages, `NotificationService` could be expanded.
        *   For more complex email campaign features (batching, advanced analytics from webhooks) suggested by `Email Wizard`'s capabilities, a dedicated `EmailDispatchService` would be more appropriate to encapsulate ESP-specific logic and provide a clean internal API (`POST /emails/send`).

## 5. WhatsApp Messaging Service Integration (e.g., Meta WhatsApp Cloud API)

*   **Purpose within IONFLUX:** To enable agents like `WhatsApp Pulse` (Agent 002) and potentially `Outreach Automaton` or `UGCMatchmaker` to send and receive WhatsApp messages, manage templates, and handle interactive elements.
*   **Authentication Approach:**
    *   **Platform-Managed via Meta Cloud API:** IONFLUX as a platform would need to be a registered Business Solution Provider (BSP) or work through one. This involves setting up Meta Business Accounts, WhatsApp Business Accounts (WABA), and managing system user tokens, phone number certificates, and message templates. This is a significant platform-level setup and compliance effort.
    *   **User Onboarding:** Individual IONFLUX workspaces (Brands) would then connect their specific WhatsApp Business Phone Numbers to the IONFLUX application through an IONFLUX-managed OAuth-like flow or guided setup process that links their WABA to IONFLUX's BSP infrastructure.
*   **Key API Functionalities IONFLUX Would Use (via Meta Cloud API):**
    *   Send template messages (HSMs - Highly Structured Messages).
    *   Send session messages (free-form replies within the 24-hour customer service window).
    *   Receive incoming messages and status notifications (delivered, read) via webhooks.
    *   Manage message templates (submission for approval by Meta).
    *   User opt-in/opt-out management (critical for compliance).
*   **Responsible IONFLUX Service:**
    *   A new, dedicated **`WhatsAppIntegrationService`** (or a more generic `MessagingService` if other platforms like SMS, FB Messenger are added later). This service is essential due to the unique complexities, compliance requirements (end-to-end encryption, template approvals), and specific API interactions of the WhatsApp Business Platform. It would handle API calls, webhook ingestion/validation, and provide a simplified internal API for agents.

## 6. Vector Database Integration (e.g., Pinecone)

*   **Purpose within IONFLUX:** As identified in `core_agent_blueprints.md`, numerous agents (`Email Wizard`, `TikTok Stylist`, `UGC Matchmaker`, etc.) rely on vector databases (Pinecone specified) for storing and querying embeddings. This supports semantic search, persona matching, context retrieval (RAG), and agent memory.
*   **Management Approach & Authentication:**
    *   **Platform-Managed Resource:** IONFLUX will operate and manage its own vector database accounts/clusters (e.g., a central Pinecone account). The API key(s) for IONFLUX's vector database infrastructure will be stored securely in the platform's central secrets management system. This is an internal infrastructure component, not a user-connected SaaS.
    *   **Namespace/Index Management:**
        *   The `AgentService` will be responsible for programmatically managing namespaces or indexes within the vector database.
        *   When an `AgentConfiguration` requiring memory is created or initialized, the `AgentService` (or the agent's setup logic orchestrated by `AgentService`) will use the `AgentDefinition.memory_config.namespace_template` (e.g., `agent001_memory_for_workspace_{{workspace_id}}`) and the specific `AgentConfiguration.id` or other context to create/designate a unique, isolated namespace/index for that agent instance if needed.
        *   The resolved namespace will be stored in `AgentConfiguration.external_memory_namespace`.
*   **Key Functionalities Used by IONFLUX (via official client libraries like `pinecone-client`):**
    *   Index/Collection Management: Create, delete, describe indexes.
    *   Vector Operations: Upsert (with metadata), query (similarity search, by ID, with metadata filters), delete vectors.
*   **Responsible IONFLUX Service/Component:**
    *   The **`AgentService`** is the primary IONFLUX service that will configure and provide context (like API keys and resolved namespaces) to agents that require vector database access.
    *   The agent execution environment (managed by `AgentService`) will run the agent code, which will use the appropriate vector DB client library to perform operations.
    *   The `LLM Orchestration Service` may generate embeddings, which are then returned to `AgentService` to be stored in the vector DB by the agent's logic.

## 7. Other Potential Integrations (Conceptual Notes)

*   **Project Management/Collaboration (Notion, Jira - e.g., for `Slack Brief Butler`):**
    *   **Initial Strategy:** For demo/Beta, these are likely to be "write-only" or targeted API actions rather than full, bidirectional integrations.
    *   **Implementation:** An agent's `yaml_config` might store user-provided API tokens/keys for a specific Notion workspace or Jira instance and a target database/page/project ID. The agent logic (within `AgentService`) would then use official client libraries (e.g., `notion-client`, `jira-python`) to perform actions like "create page," "add database entry," or "create issue."
    *   **Service Responsibility:** No dedicated integration service is planned for these initially; responsibility lies with the `AgentService` to securely handle these user-provided credentials (potentially via a secure vault accessible to the agent execution environment) and execute the actions.
*   **Calendar/Booking (Calendly - e.g., for `Outreach Automaton`):**
    *   **Initial Strategy:** Primarily link generation. The agent would take a user's base Calendly link from its `yaml_config` and append parameters or use it in outreach messages.
    *   **Future:** Deeper integration (e.g., creating events via API) would require OAuth and a more dedicated integration approach, possibly within an expanded `OutreachAutomaton` or a generic `CalendarIntegrationService`.
*   **Payment Processors (Stripe - for `Revenue Tracker Lite` data ingestion):**
    *   **Initial Strategy:** `Revenue Tracker Lite` primarily focuses on Shopify-derived data. If direct Stripe data ingestion (for non-Shopify sales or deeper financial reconciliation) is needed, it would require a separate Stripe Connect OAuth flow and API interaction, similar to the Shopify integration. This would be a candidate for a `StripeIntegrationService` or an expansion of a generic `FinancialPlatformIntegrationService`. This is out of scope for the initial E2E demo's "Lite" version.
*   **Social Media Scraping/Unofficial APIs (LinkedIn, Similarweb, TikTok Trends):**
    *   **Strategy & Disclaimer:** These are not standard, reliable API integrations.
        *   Use of such methods must be clearly documented as potentially unstable, subject to breakage, and carrying ethical/ToS risks.
        *   Implementation would be via specialized libraries/tools (e.g., Playwright, custom HTTP clients) within the agent's own codebase (executed by `AgentService`). They are not managed as platform-level "SaaS integrations."
        *   IONFLUX should prioritize official APIs wherever available.

## 8. Generic Structure for Future SaaS Integrations

*   (Points A-I as previously defined)
*   **J. Internal Observability vs. External Integrations:**
    *   This document primarily focuses on IONFLUX integrating with *external* SaaS APIs that users connect or that agents consume data from. Agents themselves (as defined in `core_agent_blueprints.md`) may specify an internal stack for logging, metrics, and tracing (e.g., Prometheus, Grafana, Loki, Jaeger, OpenTelemetry). This internal observability pipeline is a distinct architectural component of IONFLUX, managed by the platform operations team. While agents emit data to this pipeline, IONFLUX typically does not *consume* APIs from these specific observability tools as a 'SaaS integration' in the same vein as Shopify or TikTok, unless a specific agent is designed for that purpose (e.g., an "Observability Dashboard Agent").

These proposed updates and additions aim to ensure `saas_api_integration_specs.md` comprehensively covers the requirements identified in the detailed agent blueprints.

---
## 5. Core Agent Blueprints
(Content from `core_agent_blueprints.md`)

# IONFLUX Project: Core Agent Blueprints

This document provides detailed blueprints for the 10 core agents in the IONFLUX platform, as per the project proposal and user-provided specifications.

---

## AGENTE 001 — EMAIL WIZARD / Pulse of the Inbox
“Transforma caixas de entrada em máquinas de destino”

### 0 ▸ Header Narrativo
**Epíteto:** O Xamã que Conjura Receita no Silêncio do E-mail
**TAGLINE:** INBOX ≠ ARQUIVO MORTO; INBOX = ARMA VIVA

### 1 ▸ Introdução (22 linhas)
O som de um e-mail ignorado é dinheiro evaporando em silêncio.
Imagine milhares desses silêncios comprimidos num único dia de loja.
Essa é a dor real: atenção desperdiçada, lucro evaporado.
Mas cada pixel branco da inbox pode virar palco de conversão.
Visão brutal: e-mails que respiram o timing da vida do cliente.
Palavra-icônica: Hipervínculo — liga desejo imediato a clique inevitável.
Metáfora: abrimos as veias do funil e injetamos dopamina contextual.
Imagem: pulsos elétricos percorrendo cabos ópticos até explodirem em “comprar agora”.
Estatística-punhal: 44 % de ROI médio do e-mail; dobramos isso ou reescrevemos as regras.
Ruptura: adeus campanhas massivas; olá missivas hiper-pessoais escritas por IA.
Futuro-próximo: seu inbox preverá seu desejo antes de você.
Fantasma-do-fracasso: carrinho abandonado que nunca volta — assassino invisível de 13 % de GMV.
Promessa-radical: cada mensagem carrega gatilho de recompra sem parecer venda.
Cicatriz-pessoal: founder que perdeu 6 000 USD/dia por sequência quebrada.
Convite-insubmisso: hackeie a psicologia dopaminérgica a favor de quem cria valor.
Chave-filosófica: comunicação é destino encarnado em texto.
Eco-cultural: o e-mail “morre” a cada década e sempre ressuscita com mais força.
Grito-mudo: CLIQUE.
Virada-de-jogo: conteúdos dinâmicos que mudam após enviados.
Manifesto-síntese: Inbox é templo, cada linha de assunto é profecia.
Pulso-de-ação: abra, deslize, converta — sem fricção.
Silêncio-ensurdecedor: … até o som do Stripe ping ecoar.

**⚡ Punch final**
“Subject lines são feitiços — você lança ou morre anônimo.”
“Se o cliente não responde, a culpa é sua, não dele.”
“Inbox lotada? Excelente: mais terreno para nossa guerra.”

### 2 ▸ Essência
**Arquétipo:** Magician
**Frase-DNA:** “Faz o invisível falar e vender”

#### 2.1 Principais Capacidades
*   Hyper-Segment: constrói micro-coortes em tempo real via embeddings.
*   Dopamine Drip: sequência adaptativa que lê cliques e ajusta offer.
*   Auto-Warm-Up: gera tráfego friendly para blindar reputação.
*   Predictive Clearance: deleta e-mails de baixa probabilidade antes do envio.

#### 2.2 PoolDad 22,22 %
**Punch:** “Inbox frio é mausoléu; nós acendemos a fogueira.”
**Interpretação:** afirma o caos do spam e o converte em sinal brutal.

### 3 ▸ IPO Flow
(No specific content provided beyond heading)

### 4 ▸ Integrações Estratégicas
(No specific content provided beyond heading)

### 5 ▸ YAML de Definição
```yaml
id: agent_001
name: EmailWizard
version: 0.1
triggers:
  - type: schedule
    cron: "0 */2 * * *"
  - type: webhook
    path: "/emailwizard/run"
inputs:
  - key: shopify_event
    type: json
    required: false
  - key: manual_payload
    type: json
    required: false
outputs:
  - key: send_report
    type: json
stack:
  language: python
  runtime: langchain
  models:
    - openai:gpt-4o
    - anthropic:claude-3-haiku
memory:
  type: pinecone
  namespace: emailwizard
```

### 6 ▸ Stack & APIs
*   Runtime: Python 3.12 + FastAPI
*   Framework: LangChain + LangGraph
*   LLM: OpenAI GPT-4o (creative) / Claude (backup)
*   Vector DB: Pinecone (profiles)
*   Queue: Redis + RQ
*   ORM: SQLModel
*   Observability: OpenTelemetry → Prometheus → Grafana
*   CI/CD: GitHub Actions + Docker Buildx + Fly.io

### 7 ▸ Files & Paths
```
/agents/emailwizard/
  ├── __init__.py
  ├── agent.py
  ├── prompts.yaml
  ├── splitter.py               # hyper-seg
  ├── scheduler.py
  ├── processors/
  │   ├── copy_generator.py
  │   └── spam_scan.py
  ├── tests/
  │   └── test_agent.py
  └── assets/
      └── schema.sql
```

### 8 ▸ Data Store
Pinecone namespace emailwizard_personas guarda embeddings crus.

### 9 ▸ Scheduling & Triggers
*   Cron primário: 0 */2 * * * → envia fila pendente.
*   Webhook: /emailwizard/run → dispara imediata.
*   Breaker: 3 falhas 500 consecutivas → pausa e alerta #ops-email.

### 10 ▸ KPIs
(No specific content provided beyond heading)

### 11 ▸ Failure & Fallback
(No specific content provided beyond heading)

### 12 ▸ Exemplo Integrado
Cenário: Flash-sale relâmpago Shopify
Shopify emite webhook order/create rápido ↑ 20 % visitors.
ShopiPulse injeta evento → EmailWizard seleciona segmento “High-AOV past buyers”.
GPT-4o gera subject “⚡ 45-min Secret Flash (For Your Eyes Only)”.
Sendgrid dispara 3 200 e-mails em 45 s.
ClickSense rastreia 512 cliques → 128 checkouts ($8 400).
StripeEcho envia eventos; KPIs atualizam em Dashboard Commander.

### 13 ▸ Expansão Dinâmica
*   V1.1: Dynamic AMP e-mail (conteúdo muda pós-envio).
*   V2.0: E-mail-to-WhatsApp fallback: se não abrir 24 h, dispara mensagem snackbar.

### 14 ▸ Escape do Óbvio
Insira pixel WebRTC que detecta fuso horário real → reescreve CTA na hora da abertura (“a oferta termina em 12 min onde você está agora”). Resultado: 1.4× CTR.

Preencha. Refine. Lance.

---

## AGENTE 002 — WHATSAPP PULSE / Heartbeat of Conversations
“Transforma pings verdes em pulsares de receita”

### 0 ▸ Header Narrativo
**Epíteto:** O Cirurgião que Enfia Funil Dentro do Bolso do Cliente
**TAGLINE:** SE É VERDE E PISCA, É DINHEIRO LATENTE

### 1 ▸ Introdução (22 linhas)
Todo mundo abre o WhatsApp antes do café — mas poucas marcas chegam lá sem irritar.
Você piscou? O cliente já rolou quarenta mensagens.
Dor aguda: carrinho abandonado que nem viu seu SMS.
Oportunidade: 98 % open-rate e resposta em menos de 60 s.
Visão: automatizar empatia com precisão cirúrgica, um a um.
Palavra-icônica: Pulso — cada vibração fala “estou aqui por você”.
Metáfora: flecha curva — dispara e ainda faz zig-zag até acertar desejo.
Imagem: bolha verde explodindo em fogos de artifício de conversões.
Estatística-punhal: 45 % das lojas ignoram WhatsApp → perdem 27 % da LTV.
Ruptura: adeus copy paste; scripts se autogeram, sentem timing, mudam tom.
Futuro-próximo: chatbots que trocam meme antes do upsell.
Fantasma-do-fracasso: bloquearam você como spam? você morreu digitalmente.
Promessa-radical: cada toque vibra no exato micro-momento de intenção.
Cicatriz-pessoal: founder banido porque disparou lista fria — nunca mais.
Convite-insubmisso: torne-se voz interna na cabeça do cliente, não notificação externa.
Chave-filosófica: comunicação sem contexto é violência; com contexto é feitiço.
Eco-cultural: emojis são a nova gramática — dominamos sintaxe do 🔥 e do 💸.
Grito-mudo: pop-pop da bolha aparecendo.
Virada-de-jogo: workflow a/b testando gíria regional em tempo real.
Manifesto-síntese: mensagens mínimas, impacto máximo, latência zero.
Pulso-de-ação: vibrou, clicou, comprou.
Silêncio-ensurdecedor: cliente responde “ufa, era disso que eu precisava”.

**⚡ Punch final**
“Quem não vibra, não vende.”
“Seu concorrente já está dentro do bolso do cliente — você ainda manda boleto por e-mail.”
“Spam é ruído; nós fazemos sussurro irresistível.”

### 2 ▸ Essência
**Arquétipo:** Messenger-Magician
**Frase-DNA:** “Faz do sinal verde um gatilho pavloviano de compra”

#### 2.1 Principais Capacidades
*   Persona-Aware Reply: escreve em dialeto do usuário (embedding + gírias locais).
*   Smart Drip: sequência progressiva: lembrete → oferta suave → escassez → bônus.
*   Opt-in Whisper: gera links one-click, salva provas de consentimento (LGPD/GDPR).
*   Voice-Note AI: transforma script em áudio humanizado TTS para engajamento 1.6×.

#### 2.2 Essência 22,22 %
**Punch:** “Bloqueio? Só se for gatilho de FOMO.”
**Interpretação:** abraça o risco: se não vale vibrar, não vale existir.

### 3 ▸ IPO Flow
(No specific content provided beyond heading)

### 4 ▸ Integrações Estratégicas
(No specific content provided beyond heading)

### 5 ▸ YAML de Definição
```yaml
id: agent_002
name: WhatsAppPulse
version: 0.1
triggers:
  - type: schedule
    cron: "*/15 * * * *"
  - type: webhook
    path: "/whatsapppulse/hook"
inputs:
  - key: shopify_payload
    type: json
    required: false
  - key: manual_trigger
    type: json
    required: false
outputs:
  - key: pulse_report
    type: json
stack:
  language: python
  runtime: langchain
  models:
    - openai:gpt-4o
    - deepseek:ds-chat-b32
memory:
  type: pinecone
  namespace: whap_pulse
```

### 6 ▸ Stack & APIs
*   Runtime: Python 3.12 + FastAPI
*   Framework: LangChain + LangGraph
*   LLM: GPT-4o (creative), DeepSeek B32 (fallback)
*   Vector: Pinecone (user style embeddings)
*   Queue: Redis Streams
*   Messaging: Meta WhatsApp Cloud API
*   TTS: Azure Speech / Coqui TTS fallback
*   Observability: OpenTelemetry → Loki → Grafana

### 7 ▸ Files & Paths
```
/agents/whatsapppulse/
  ├── __init__.py
  ├── agent.py
  ├── prompts.yaml
  ├── playbooks/
  │   ├── abandoned_cart.yaml
  │   ├── vip_upsell.yaml
  │   └── winback.yaml
  ├── tts.py
  ├── scheduler.py
  ├── compliance.py
  ├── tests/
  │   └── test_playbooks.py
  └── assets/
      └── schema.sql
```

### 8 ▸ Data Store
(No specific content provided beyond heading)

### 9 ▸ Scheduling & Triggers
*   Cron: cada 15 min roda fila de eventos pendentes.
*   Webhook: /hook recebe callback de entrega & resposta.
*   Breaker: ≥ 20 % bounce code → pausa playbook, notifica #ops-wa.

### 10 ▸ KPIs
(No specific content provided beyond heading)

### 11 ▸ Failure & Fallback
(No specific content provided beyond heading)

### 12 ▸ Exemplo Integrado
Cenário Black Friday Abandoned Cart
Cliente adiciona R$ 750 em produtos, some.
Shopify → webhook; WhatsAppPulse detecta high AOV.
Gera mensagem voice-note + texto com cupom 8 %.
Envia às 20:10 (janela ativa região).
Cliente ouve áudio, clica link, finaliza compra.
StripeEcho lança evento; KPI Revenue/message = $1.04.
Badge Motivator dá XP ao agente.

### 13 ▸ Expansão Dinâmica
*   V1.1: Flows multi-mídia (carrossel catálogos).
*   V2.0: Chat-commerce inline (checkout dentro do chat usando WhatsApp Pay).

### 14 ▸ Escape do Óbvio
Detectar “dormência” de chat: se usuário não abre app há 72 h, enviar sticker personalizado gerado por Midjourney com nome do cliente no balão. CTR aumenta ~1.8× em testes iniciais.

Preencha. Refine. Lance.

---

## AGENTE 003 — TIKTOK STYLIST / Ritualist of the Swipe
“Vira feed frenético em desfile de persona pura”

### 0 ▸ Header Narrativo
**Epíteto:** O Alfaiate que Corta Vídeos na Medida da Dopamina
**TAGLINE:** SE NÃO SEGURA O DEDO, NEM DEVERIA EXISTIR

### 1 ▸ Introdução (22 linhas)
A cada 0,6 s um swipe mata um vídeo inacabado.
O feed nunca dorme — seu conteúdo não pode bocejar.
Dor: criador grava horas, algoritmo descarta em milissegundos.
Oportunidade: 1 b+ usuários hipnotizados, aguardando a próxima batida visual.
Visão: costurar voz, ritmo e estética em 15 s de puro vício.
Palavra-icônica: Corte — onde nasce a retenção.
Metáfora: bisturi que esculpe emoção em micro-segundos.
Imagem: frame piscando como relâmpago antes da chuva de likes.
Estatística-punhal: 71 % decide em 3 s se continua ou não.
Ruptura: produção artesanal morreu; entra edição autopoética.
Futuro-próximo: IA roteiriza, grava, posta antes de você acordar.
Fantasma-do-fracasso: ficar preso no limbo sub-300 views.
Promessa-radical: cada vídeo carrega gene viral — ou é abortado na pré-edição.
Cicatriz-pessoal: criador exausto, zero crescimento após 90 posts.
Convite-insubmisso: entregue sua matéria-bruta, receba rituais de scroll-stop.
Chave-filosófica: estética é alimento, velocidade é fome.
Eco-cultural: sons de trap viram liturgia do algoritmo.
Grito-mudo: !!! no thumbnail psicológico.
Virada-de-jogo: B-roll adaptado ao humor do viewer em tempo real.
Manifesto-síntese: editar é escrever com lâmina de luz.
Pulso-de-ação: vibrou? grava. processou? posta.
Silêncio-ensurdecedor: 100 % retention até o último beat.

**⚡ Punch final**
“Vídeo sem corte é vídeo sem pulso.”
“Se não prende em 3 s, libere espaço no cemitério do feed.”
“Likes são aplausos; retenção é culto.”

### 2 ▸ Essência
**Arquétipo:** Artisan-Magician
**Frase-DNA:** “Escreve hipnose audiovisual no compasso do coração digital”

#### 2.1 Principais Capacidades
*   StyleScan: analisa 30 vídeos passados e extrai fingerprint visual-verbal.
*   ClipForge: corta, recalibra ritmo, insere captions dinâmicos e zooms estratégicos.
*   SoundSynch: alinha beat com movimento/zoom para 1.3 × retenção.
*   AutoPost Oracle: calcula pico regional do público e agenda push.

#### 2.2 Essência 22,22 %
**Punch:** “Frames são lâminas: use-as ou será dilacerado pelo tédio.”
**Interpretação:** edita com crueldade estética: nada supérfluo sobrevive.

### 3 ▸ IPO Flow
(No specific content provided beyond heading)

### 4 ▸ Integrações Estratégicas
(No specific content provided beyond heading)

### 5 ▸ YAML de Definição
```yaml
id: agent_003
name: TikTokStylist
version: 0.1
triggers:
  - type: webhook
    path: "/tiktokstylist/upload"
inputs:
  - key: video_draft_url
    type: string
    required: true
  - key: goal
    type: string
    required: true
outputs:
  - key: published_id
    type: string
stack:
  language: python
  runtime: langchain
  models:
    - openai:gpt-4o
    - openai:whisper-large
memory:
  type: pinecone
  namespace: tiktok_stylist
```

### 6 ▸ Stack & APIs
*   Runtime: Python 3.12, FastAPI
*   LLM: GPT-4o (script/caption), Whisper-large (transcribe)
*   Video Processing: ffmpeg, moviepy, ffprobe
*   Trend Feed: TikTok Trend API (unofficial wrapper)
*   Vector DB: Pinecone (style embeddings)
*   Queue: Redis Streams; fallback SQS
*   Storage: S3 (+ CloudFront)
*   Observability: Prometheus + Grafana dashboard “VideoOps”

### 7 ▸ Files & Paths
```
/agents/tiktokstylist/
  ├── __init__.py
  ├── agent.py
  ├── style_scan.py
  ├── clip_forge.py
  ├── sound_synch.py
  ├── autopost.py
  ├── prompts.yaml
  ├── tests/
  │   └── test_clip_forge.py
  └── assets/
      └── schema.sql
```

### 8 ▸ Data Store
Vector namespace creator_styles.

### 9 ▸ Scheduling & Triggers
*   Webhook: /upload dispara pipeline end-to-end.
*   Cron: 0 */1 * * * — verifica novos sons virais e atualiza TrendBeat.
*   Breaker: > 3 uploads rejeitados → switch para revisão manual, alerta Slack.

### 10 ▸ KPIs
(No specific content provided beyond heading)

### 11 ▸ Failure & Fallback
(No specific content provided beyond heading)

### 12 ▸ Exemplo Integrado
Cenário: Lançamento de coleção cápsula Shopify
Criador grava unboxing bruto (2 min).
/upload acionado pelo app mobile.
StyleScan detecta humor “excited streetwear” → ClipForge cria 18 s highlight com zoom beat-sync.
ShopTagger anexa link utm=tiktok_capsule.
Autopost publica 18:45 (pico).
TokGraph callback: 56 k views primeiro 30 min, 8.2 % CTR link.
Shopify Sales Sentinel reporta 240 vendas — mensagem Slack “🔥 Capsule sold out”.

### 13 ▸ Expansão Dinâmica
*   V1.1: Real-time AR stickers (OpenCV + Segmentation).
*   V2.0: Multilingual lip-sync (RVC voice clone + re-timing).

### 14 ▸ Escape do Óbvio
Gera dois finais alternativos e publica como “choose-your-ending” via TikTok interactive cards; coleta micro-votos que alimentam StyleScan, dobrando retenção em episódios futuros.

Preencha. Refine. Lance.

---

## AGENTE 004 — SHOPIFY SALES SENTINEL / Guardian of the Cashflow Veins
“Fiscaliza cada batida de venda — avisa antes da hemorragia”

### 0 ▸ Header Narrativo
**Epíteto:** O Vigia Que Ouve o Caixa Respirar em Tempo Real
**TAGLINE:** SE A RECEITA PISCA, O SENTINEL DISPARA

### 1 ▸ Introdução (22 linhas)
Uma loja morre primeiro no silêncio do dashboard, depois no caixa.
Você refresca o admin — nada muda; a ansiedade cresce.
Dor: tráfego alto, vendas caindo e você descobre só no relatório do dia seguinte.
Oportunidade: interceptar o sangramento nos 90 segundos após a queda de conversão.
Visão: sentinela que opera como ECG — detecta arritmia de receita.
Palavra-icônica: Pulso — receita pulsa como batimento.
Metáfora: sonar submarino captando cada ping de pedido.
Imagem: gráfico cardíaco verde; picos viram alarmes rubros ao despencar.
Estatística-punhal: 38 % dos merchants perdem +10 % GMV/ano por detecção tardia de bug no checkout.
Ruptura: relatórios diários viram alertas de minuto em minuto.
Futuro-próximo: IA prediz falha de gateway antes do suporte saber.
Fantasma-do-fracasso: campanha de tráfego pago queimando $800/h com check-out off.
Promessa-radical: nenhum pixel de venda escapa ao radar.
Cicatriz-pessoal: founder perdeu Black Friday porque app de frete bugou.
Convite-insubmisso: torne-se onipotente sobre cada carrinho.
Chave-filosófica: informação tardia é auto-sabotagem.
Eco-cultural: FOMO dos devs às 3 h da manhã.
Grito-mudo: beep-beep-beep travado.
Virada-de-jogo: auto-rollback de app que degrada conversão.
Manifesto-síntese: vigiar é amar a receita.
Pulso-de-ação: verde vivo → conversão viva.
Silêncio-ensurdecedor: gráfico flat? jamais.

**⚡ Punch final**
“Dashboard atrasado é necrotério de dados.”
“Quem detecta em horas já está morto em minutos.”
“Deixe o Sentinel dormir e acorde sem caixa.”

### 2 ▸ Essência
**Arquétipo:** Sentinel-Engineer
**Frase-DNA:** “Escuta o sussurro da venda antes do grito da falha”

#### 2.1 Principais Capacidades
*   Realtime Pulse: stream de pedidos, AOV, conversão a cada 5 s.
*   Anomaly Guardian: detecção ML (Z-score + Prophet) para drops/spikes.
*   App-Impact Radar: correlaciona instalação/update de app c/ variação de CVR.
*   Rollback Autonomo: desativa app ou tema se perda > x %.

#### 2.2 Essência 22,22 %
**Punch:** “Checkout que trava é faca no fluxo — o Sentinel a arranca.”
**Interpretação:** age brutalmente; prefere remover feature a deixar receita sangrar.

### 3 ▸ IPO Flow
(No specific content provided beyond heading)

### 4 ▸ Integrações Estratégicas
(No specific content provided beyond heading)

### 5 ▸ YAML de Definição
```yaml
id: agent_004
name: ShopifySalesSentinel
version: 0.1
triggers:
  - type: schedule
    cron: "*/5 * * * *"
  - type: webhook
    path: "/sentinel/event"
inputs:
  - key: shopify_event
    type: json
    required: false
  - key: latency_log
    type: json
    required: false
outputs:
  - key: incident_report
    type: md
stack:
  language: python
  runtime: fastapi
  models:
    - openai:gpt-4o
memory:
  type: pinecone
  namespace: sentinel_rootcause
```

### 6 ▸ Stack & APIs
*   Runtime: Python 3.12 + FastAPI
*   Stream: Kafka (Confluent) topic shop-orders
*   Anomaly: Facebook Prophet + Z-score custom
*   Vector: Pinecone (incident embeddings)
*   DB: Postgres (orders cache 24 h)
*   Queue: RQ (critical actions)
*   Infra: Docker + Fly.io autoscale
*   Observability: Prometheus exporter + Grafana “SalesPulse”

### 7 ▸ Files & Paths
```
/agents/sales_sentinel/
  ├── agent.py
  ├── anomaly.py
  ├── rootcause.py
  ├── actions.py
  ├── prompts.yaml
  ├── tests/
  │   └── test_anomaly.py
  └── assets/
      └── backup/
          └── theme.zip
```

### 8 ▸ Data Store
Vector namespace sentinel_incidents para explicações LLM.

### 9 ▸ Scheduling & Triggers
*   Cron 5 min: roll-up + forecast update.
*   Webhook: recebe cada evento e enfileira.
*   Breaker: se 3 incidentes críticos/1 h → eleva para pager-duty.

### 10 ▸ KPIs
(No specific content provided beyond heading)

### 11 ▸ Failure & Fallback
(No specific content provided beyond heading)

### 12 ▸ Exemplo Integrado
Cenário: App de desconto 3rd-party bugou checkout
Spike 502 no gateway → CVR despenca de 3.2 %→0.4 %.
Angle Δ-3σ detectado em 80 s.
Rootcause matches app update 5 min antes.
Sentinel usa appDisable via GraphQL, publica incident doc no Notion.
CVR volta a 3 % em 7 min.
SlackSiren posta “🛡️ checkout normalized; GMV saved est. $4 700”.

### 13 ▸ Expansão Dinâmica
*   V1.1: LLM Root-Cause chat: conversa sobre incidente, sugere fix patches.
*   V2.0: Cross-store comparative baseline (benchmark entre merchants).

### 14 ▸ Escape do Óbvio
Se CVR sobe +120 % em 2 min (bot ataque), Sentinel ativa “honeypot checkout” para filtrar fraudadores antes de afetar estoque real.

Preencha. Refine. Lance.

---

## AGENTE 005 — UGC MATCHMAKER / Brand-Creator Oracle
“Encontra o DNA perdido entre briefing e feed”

### 0 ▸ Header Narrativo
**Epíteto:** O Oráculo que Costura Marcas ao Sangue dos Criadores
**TAGLINE:** NÃO EXISTE BRIEFING SEM ALMA: NÓS OUVIMOS A BATIDA

### 1 ▸ Introdução (22 linhas)
Centenas de marcas gritam; milhões de criadores ecoam — e ninguém se escuta.
Feed saturado, DM lotada, propostas genéricas apodrecendo no inbox.
Dor: gastar verba com influenciador que não converte — casamento sem química.
Oportunidade: alinhar tom, estética e público em questão de segundos.
Visão: algoritmo que cheira o “cheiro” de uma marca e fareja o criador compatível.
Palavra-icônica: Imprint — marca invisível na pele da audiência.
Metáfora: radar bioquímico buscando chave-fechadura entre voz e produto.
Imagem: gráfico de embeddings colapsando num ponto luminoso de afinidade 0.97.
Estatística-punhal: 61 % dos collabs falham por mismatch de valores (Shopify/BRC 2024).
Ruptura: brief anonymizado evita viés e garante matches sinceros; nomes revelados só após compatibilidade ≥ 0.8.
Futuro-próximo: marca negocia com agente-IA do criador antes de DM humana.
Fantasma-do-fracasso: vídeos lindos, CTR pífio e ROI negativo.
Promessa-radical: cada collab nasce pré-aprovada pela afinidade de estilo, voz e valor.
Cicatriz-pessoal: creator “clean beauty” cancelado após collab com energética.
Convite-insubmisso: vire cupido algorítmico, não caça-inbox desesperado.
Chave-filosófica: autenticidade não se compra — se reconhece.
Eco-cultural: fandom reage a falsidade mais rápido que algoritmo.
Grito-mudo: “isso não parece você”.
Virada-de-jogo: KPI = clap-rate (likes + saves por mil).
Manifesto-síntese: colaborações que soam inevitáveis.
Pulso-de-ação: swipe, DM, contrato — sem fricção.
Silêncio-ensurdecedor: feed vibra de naturalidade — ninguém percebe a máquina por trás.

**⚡ Punch final**
“Publicidade morta fede; matchmaking vivo perfuma o feed.”
“Brand lift sem afinidade é levantar peso com braço quebrado.”
“Criador errado custa mais que campanha fracassada: custa reputação.”

### 2 ▸ Essência
**Arquétipo:** Hermes-Connector
**Frase-DNA:** “Traduz briefing em pulsação humana”

#### 2.1 Principais Capacidades
*   Brief2Vector: transforma briefing em embedding semântico-emocional.
*   PersonaProbe: gera embedding de criador via transcrição, coloração de fala, paleta visual.
*   AffinityMatrix: cálculo cosine + heurísticas culturais (regionais, ética, valores).
*   GhostPitch: redige proposta personalizada e envia via Slack/E-mail/WhatsApp.

#### 2.2 Essência 22,22 %
**Punch:** “Cupido digital não erra flecha; quem erra flecha não merece arco.”
**Interpretação:** combina rigor matemático com intuição poética.

### 3 ▸ IPO Flow
(No specific content provided beyond heading)

### 4 ▸ Integrações Estratégicas
(No specific content provided beyond heading)

### 5 ▸ YAML de Definição
```yaml
id: agent_005
name: UGCMatchmaker
version: 0.1
triggers:
  - type: webhook
    path: "/ugc/match"
inputs:
  - key: brief_id
    type: string
    required: true
outputs:
  - key: match_table
    type: md
stack:
  language: python
  runtime: langchain
  models:
    - openai:text-embedding-3-small
    - openai:gpt-4o
    - clip:openai
memory:
  type: pinecone
  namespace: ugc_matchmaker
```

### 6 ▸ Stack & APIs
*   Runtime: Python 3.12 + FastAPI
*   LLM / Embeds: OpenAI (text + image), Whisper v3
*   Vector: Pinecone (1536 dim)
*   ML: Scikit-learn (PCA heuristics)
*   Scraping: Playwright headless, yt-dLP
*   Queue: Celery + Redis
*   Observability: OpenTelemetry → Grafana Loki
*   Storage: Postgres (briefings, matches, consents)

### 7 ▸ Files & Paths
```
/agents/ugc_matchmaker/
  ├── agent.py
  ├── brief2vec.py
  ├── persona_probe.py
  ├── affinity.py
  ├── ghost_pitch.py
  ├── prompts.yaml
  ├── tests/
  │   └── test_affinity.py
  └── assets/
      └── schema.sql
```

### 8 ▸ Data Store
Namespace ugc_vectors. 10 M embeddings capacity.

### 9 ▸ Scheduling & Triggers
*   Webhook: POST /ugc/match com brief_id.
*   Cron 12 h: refresh creator stats + embeddings.
*   Breaker: se ≥ 3 pitches rejeitados seguidos → agrega feedback, re-treina prompt.

### 10 ▸ KPIs
(No specific content provided beyond heading)

### 11 ▸ Failure & Fallback
(No specific content provided beyond heading)

### 12 ▸ Exemplo Integrado
Cenário: Marca de skincare clean quer criador 25-35 PT-BR
PM cria Brief Notion com keywords “clean beauty”, “pele sensível”.
/ugc/match brief_id=abc123 dispara pipeline.
Brief2Vector gera embedding; PersonaProbe atualiza 12k creators.
AffinityMatrix retorna top 7 (score 0.83-0.92).
GhostPitch cria proposta: R$ 1 500 + 2 Reels + UGC fotos em 10 d.
SlackPitch envia DM — criador top aceita em 6 min.
ConsentVault armazena opt-in; contrato DocuSign criado.

### 13 ▸ Expansão Dinâmica
*   V1.1: Resumir briefing por voz (OpenAI Audio).
*   V2.0: Marketplace “auction mode” onde criadores dão lances de proposta.

### 14 ▸ Escape do Óbvio
Usa sentiment inversion: se brand quer “seriedade clínica”, sistema sugere criador com 30 % contraste humorístico — A/B mostra 2.1× CTR porque quebra expectativa.

Preencha. Refine. Lance.

---

## AGENTE 006 — OUTREACH AUTOMATON / Hunter of the Untapped Inboxes
“Rastreia leads no escuro, soma contexto e dispara oferta cirúrgica”

### 0 ▸ Header Narrativo
**Epíteto:** O Predador que Fareja Vendas em Bancos de Dados Mortos
**TAGLINE:** LEAD FRIO É LENHA: NÓS INCENDEMOS RESULTADO

### 1 ▸ Introdução (22 linhas)
Milhões de e-mails congelam em planilhas que ninguém abre.
Todo dia, mais nomes entram no cemitério de CRM sem toque humano.
Dor: pipeline entupido, quota batendo na porta, time batendo cabeça.
Oportunidade: IA que caça contexto, fabrica relevância e derruba porta fechada.
Visão: cada lead vira micro-campanha hiperespecífica em 45 segundos.
Palavra-icônica: Sonda — fura a crosta de dados duros e encontra magma quente.
Metáfora: satélite rastreando calor corporal no deserto noturno.
Imagem: score vermelho acendendo em mapa 3D de prospects.
Estatística-punhal: SDR médio gasta 63 % do tempo só pesquisando lead (Gartner 2025).
Ruptura: pesquisa vira crônometro de 400 ms; contato produz resposta em 14 min.
Futuro-próximo: cadência multicanal auto-mutante conforme horário on-line do prospect.
Fantasma-do-fracasso: VP vendas pergunta pipeline; você só tem pressa e PowerPoint.
Promessa-radical: 60 emails personalizados/h sem levantar da cadeira.
Cicatriz-pessoal: time sofreu burn-out durante Black Friday; envios manuais falharam.
Convite-insubmisso: deixe a máquina suar; você fica com a comissão.
Chave-filosófica: relevância não é arte — é cálculo íntimo.
Eco-cultural: ninguém quer “Oi, tudo bem?” genérico em 2025.
Grito-mudo: inbox apitando com thread de resposta.
Virada-de-jogo: ligação auto-gerada marcada só quando prospect abre quinto e-mail.
Manifesto-síntese: cold-email morreu; viva o Context Outreach.
Pulso-de-ação: tecla “Run” = chuva de reuniões.
Silêncio-ensurdecedor: quota batida antes da 3.ª xícara de café.

**⚡ Punch final**
“Prospect que não responde é alguém que você não entendeu.”
“Pesquisa manual é luxo de 2010.”
“Se sua cadência não muda, seu spam faz morada.”

### 2 ▸ Essência
**Arquétipo:** Hunter-Strategist
**Frase-DNA:** “Transforma lista crua em pipeline respirando”

#### 2.1 Principais Capacidades
*   DataMiner Scraper: coleta perfil LinkedIn, loja Shopify, métricas Similarweb.
*   ContextForge: gera “hook” de abertura baseado em evento (funding, post viral, press).
*   Multi-Cadence Drip: orquestra e-mail → LinkedIn DM → WhatsApp.
*   Auto-Booker: conecta Calendly, marca call quando reply contém “vamos falar”.

#### 2.2 Essência 22,22 %
**Punch:** “Lead gelado, alma quente: o fogo vem do contexto.”
**Interpretação:** a máquina usa o excesso de dado para esculpir copy que parece feita à mão.

### 3 ▸ IPO Flow
(No specific content provided beyond heading)

### 4 ▸ Integrações Estratégicas
(No specific content provided beyond heading)

### 5 ▸ YAML de Definição
```yaml
id: agent_006
name: OutreachAutomaton
version: 0.1
triggers:
  - type: webhook
    path: "/outreach/kickoff"
inputs:
  - key: list_url
    type: string
    required: true
  - key: icp_profile
    type: json
    required: true
outputs:
  - key: outreach_report
    type: md
stack:
  language: python
  runtime: langchain
  models:
    - openai:gpt-4o
memory:
  type: pinecone
  namespace: outreach_ctx
```

### 6 ▸ Stack & APIs
*   Runtime: Python 3.12 + FastAPI
*   LLM: GPT-4o (copy), GPT-3.5 turbo (variant)
*   Scraping: Playwright cluster (Stealth)
*   Vector: Pinecone (hooks library)
*   Queue: Redis Streams → RQ workers
*   DB: Postgres (lead, touchpoints)
*   Observability: OpenTelemetry, Jaeger trace
*   CI/CD: GitHub Actions, Docker, Railway

### 7 ▸ Files & Paths
```
/agents/outreach_automaton/
  ├── agent.py
  ├── dataminer.py
  ├── contextforge.py
  ├── cadence.py
  ├── prompts.yaml
  ├── linkedin_bot.js
  ├── tests/
  │   ├── test_context.py
  │   └── test_cadence.py
  └── assets/schema.sql
```

### 8 ▸ Data Store
Pinecone namespace outreach_hooks.

### 9 ▸ Scheduling & Triggers
*   Webhook Kickoff: /outreach/kickoff com URL da lista.
*   Cadence Cron: */10 * * * * dispara toques pending.
*   Breaker: bounce > 5 % ou spamflag > 0.3 % → pausa lista + alerta.

### 10 ▸ KPIs
(No specific content provided beyond heading)

### 11 ▸ Failure & Fallback
(No specific content provided beyond heading)

### 12 ▸ Exemplo Integrado
Cenário: Listar top 100 lojas Shopify de decoração → vender app UGC
list_url=gs://bucket/decoration_top100.csv dispara webhook.
DataMiner coleta site data, LinkedIn founders, funding.
ContextForge identifica que 27 lojas postaram Reels de user photos.
GPT-4o gera copy citando post “insta/8492” → Sent “Hey Ana, vi seu Reels de ontem…”.
LinkedDM envia na conta SDR; SendGrid backup.
14 respostas; 7 reuniões auto-agendadas Calendly.
CRMBridge cria deals; KPIs green.

### 13 ▸ Expansão Dinâmica
*   V1.1: Voice note outbound via Twilio < 30 s AI-cloned voz.
*   V2.0: Auto-pricing: propõe fee baseado em funding round + GMV scraping.

### 14 ▸ Escape do Óbvio
“Re-anima leads mortos”: Script busca domínios sem posts novos 6 m, sugere email ‘revival’ oferecendo parceria que reativa audience — teste piloto gerou 18 % de retorno latent.

Preencha. Refine. Lance.

---

## AGENTE 007 — SLACK BRIEF BUTLER / Concierge of Lightning Alignment
“Serve resumos brutais antes que o ruído invada a mente”

### 0 ▸ Header Narrativo
**Epíteto:** O Mordomo que Organiza o Caos em Mensagens de 90 Segundos
**TAGLINE:** SE NÃO CABE NUM SLACK, NÃO MERECE EXISTIR

### 1 ▸ Introdução (22 linhas)
Reuniões roubam horas; briefs mal escritos roubam semanas.
Toda equipe afoga-se em threads, emojis e GIFs.
Dor: ninguém sabe quem decide — e o prazo evapora.
Oportunidade: um mordomo digital que destila ruído em ação.
Visão: cada canal acorda com sumário digerível + próximos passos claros.
Palavra-icônica: Prata — a bandeja onde chega a informação.
Metáfora: maître servindo shots de foco antes do expediente.
Imagem: feed Slack amanhece com blocos verdes “✔ Done”, laranjas “⚠ Wait”.
Estatística-punhal: 64 % dos atrasos nascem de brief incompleto (PMI 2024).
Ruptura: adeus stand-up de 15 min; olá áudio de 45 s + botões aprovação.
Futuro-próximo: briefs viram loops de IA que escutam, ajustam, confirmam.
Fantasma-do-fracasso: designer confunde rascunho v3 com final, lança bug.
Promessa-radical: 0 ambiguidade -- ou mensagem de alerta explode em vermelho.
Cicatriz-pessoal: time shipping meia-noite, refazendo banner errado.
Convite-insubmisso: compressão bruta de contexto — ou silêncio.
Chave-filosófica: informação sem hierarquia é entropia.
Eco-cultural: Slack fatigue vira piada amarga nos memes dev.
Grito-mudo: “onde está o doc?!”.
Virada-de-jogo: bot digere PDF, converte em checklist clicável.
Manifesto-síntese: quem controla o brief controla o destino do sprint.
Pulso-de-ação: abrir canal, ler 10 linhas, saber exatamente o próximo passo.
Silêncio-ensurdecedor: ninguém pergunta “o que falta?”, todos agem.

**⚡ Punch final**
“Brief longo é preguiça disfarçada.”
“Quem repete pergunta mata prazo.”
“Foco servido em bandeja — ou caos servido frio.”

### 2 ▸ Essência
**Arquétipo:** Butler-Strategist
**Frase-DNA:** “Destila informação, injeta decisão”

#### 2.1 Principais Capacidades
*   Thread Siphon: varre canais, extrai decisões, blockers, deadlines.
*   One-Click Approve: gera botões ✅/❌; registra no Notion + Jira.
*   Briefcast Audio: transforma resumo em áudio de 45 s (TTS) para mobile.
*   Stakeholder Ping: alerta pessoa-chave só quando ação requerida.

#### 2.2 Essência 22,22 %
**Punch:** “Equipes não quebram por falta de talento, mas por excesso de ruído.”
**Interpretação:** o mordomo silencia a cacofonia, serve clareza afiada.

### 3 ▸ IPO Flow
(No specific content provided beyond heading)

### 4 ▸ Integrações Estratégicas
(No specific content provided beyond heading)

### 5 ▸ YAML de Definição
```yaml
id: agent_007
name: SlackBriefButler
version: 0.1
triggers:
  - type: schedule
    cron: "0 8 * * *"
  - type: webhook
    path: "/briefbutler/event"
inputs:
  - key: slack_event
    type: json
    required: false
outputs:
  - key: daily_brief_url
    type: string
stack:
  language: python
  runtime: langchain
  models:
    - openai:gpt-4o
memory:
  type: pinecone
  namespace: brief_butler
```

### 6 ▸ Stack & APIs
*   Runtime: Python 3.12 + FastAPI
*   LLM: GPT-4o
*   Vector: Pinecone (thread embeddings)
*   Messaging: Slack Bolt SDK & Socket Mode
*   TTS: Azure / ElevenLabs fallback
*   DB: Postgres (decision log)
*   Observability: Prometheus + Grafana panel “BriefOps”
*   CI/CD: GitHub Actions → Fly.io rolling deploy

### 7 ▸ Files & Paths
```
/agents/brief_butler/
  ├── agent.py
  ├── thread_siphon.py
  ├── summarizer.py
  ├── tts.py
  ├── integrations/
  │   ├── notion.py
  │   └── jira.py
  ├── prompts.yaml
  ├── tests/
  │   └── test_summary.py
  └── assets/schema.sql
```

### 8 ▸ Data Store
Namespace butler_threads.

### 9 ▸ Scheduling & Triggers
*   Cron 08:00 UTC: gera brief diário por canal tag #squad-*.
*   Webhook: evento Slack new file or high-priority tag triggers mini-brief.
*   Breaker: se reply thread > 500 msgs sem resumo → alerta.

### 10 ▸ KPIs
(No specific content provided beyond heading)

### 11 ▸ Failure & Fallback
(No specific content provided beyond heading)

### 12 ▸ Exemplo Integrado
Cenário: Sprint Monday Kick-off
08:00 cron: Butler varre #squad-checkout.
Siphon classifica: 3 decisões, 1 blocker, 2 FYI.
GPT-4o gera bullets:
“Deploy v2 banner hoje 17 h (owner @aléx)✅?”
“Bug #231 still open — @diana precisa fix até 14 h.”
Slack mensagem com botões ✅/❌; @alex aceita, @diana comenta “on it”.
Notion page “2025-06-03 Brief” criado com log.
Audio 43 s gerado; mobile users ouvem correndo no café.
JiraHook move bug #231 para In Progress.

### 13 ▸ Expansão Dinâmica
*   V1.1: Auto-retro: sexta-feira, Butler compila vitórias + lições.
*   V2.0: Mode “Battle Silence”: se ruído > x, suprime notificações e manda digest.

### 14 ▸ Escape do Óbvio
Integra “emoji intel”: Butler analisa quais emojis dominam canal; se ⚰️, 😡 predominam, sinaliza toxicidade e sugere pausa de cooldown — recupera moral antes que sprint colapse.

Preencha. Refine. Lance.

---

## AGENTE 008 — CREATOR PERSONA GUARDIAN / Custodian of Authentic Voice
“Protege a assinatura invisível que faz o público dizer: ‘isso é totalmente você’”

### 0 ▸ Header Narrativo
**Epíteto:** O Guardião que Reconhece a Alma em Cada Sílaba
**TAGLINE:** VOCÊ PODE TER 1 000 AGENTES; SÓ EXISTE UMA VOZ

### 1 ▸ Introdução (22 linhas)
Seus vídeos podem mudar de formato; sua voz não pode vacilar.
Cada tropeço de tom arranha a confiança construída a sangue.
Dor: o feed denuncia quando o criador parece marketing disfarçado.
Oportunidade: IA que mapeia, aprende e defende sua identidade verbal-visual.
Visão: nenhum texto, corte ou emoji sai sem DNA verificado.
Palavra-icônica: Impressão — digital de estilo que não se copia.
Metáfora: cão de guarda linguístico farejando falsificações.
Imagem: fingerprint colorida sobreposto ao roteiro aprovado.
Estatística-punhal: 47 % dos unfollows ocorrem após “mudança estranha de tom” (Meta Creators 2024).
Ruptura: persona não é branding fixo — é organismo evolutivo, mas coeso.
Futuro-próximo: multi-LLM escrevendo em sincronia sem ruído de estilo.
Fantasma-do-fracasso: ghostwriter genérico transformando voz ácida em texto neutro.
Promessa-radical: cada palavra soa como se você mesmo tivesse digitado — e numa manhã inspirada.
Cicatriz-pessoal: criador viral cancelado por tweet fora de tom em 2019.
Convite-insubmisso: torne sua autenticidade à prova de escalas e delegações.
Chave-filosófica: estilo não se impõe; emerge — mas precisa de sentinela.
Eco-cultural: fandom celebra consistência, crucifica incoerência.
Grito-mudo: “parece chatGPT!”
Virada-de-jogo: embutir emojis-assinatura mapeados estatisticamente.
Manifesto-síntese: a voz é seu patente invisível.
Pulso-de-ação: aprovar copy vira prazer, não medo.
Silêncio-ensurdecedor: buzz de engajamento sem notar a máquina.

**⚡ Punch final**
“Autenticidade não escala — até agora.”
“Algoritmo ama voz única; nós blindamos a sua.”
“Parecer IA é falhar; soar você é fatal.”

### 2 ▸ Essência
**Arquétipo:** Guardian-Craftsman
**Frase-DNA:** “Faz a voz sobreviver à automação”

#### 2.1 Principais Capacidades
*   Signature Extractor: treina embedding 360° (léxico, ritmo, emoji, cor).
*   Tone Validator: avalia texto/roteiro/copy → score de autenticidade 0-1.
*   Style Repair: reescreve passagens fora de tom, preserva conteúdo factual.
*   Evolution Monitor: detecta drift desejado (novo arco) vs. desvio incoerente.

#### 2.2 Essência 22,22 %
**Punch:** “Plágio de si mesmo é o suicídio do criador; nós prevenimos.”
**Interpretação:** foca na linha tênue entre evolução e descaracterização.

### 3 ▸ IPO Flow
(No specific content provided beyond heading)

### 4 ▸ Integrações Estratégicas
(No specific content provided beyond heading)

### 5 ▸ YAML de Definição
```yaml
id: agent_008
name: CreatorPersonaGuardian
version: 0.1
triggers:
  - type: webhook
    path: "/persona/validate"
inputs:
  - key: asset_url
    type: string
    required: true
  - key: creator_id
    type: string
    required: true
outputs:
  - key: validation_score
    type: float
  - key: repaired_asset_url
    type: string
stack:
  language: python
  runtime: langchain
  models:
    - openai:gpt-4o
    - sentence-transformers:multi-qa
memory:
  type: pinecone
  namespace: persona_guardian
```

### 6 ▸ Stack & APIs
*   Runtime: Python 3.12 + FastAPI
*   LLM: GPT-4o (rewrite), Sentence-Transformers (similarity).
*   Vector DB: Pinecone (persona fingerprints).
*   Multimodal: OpenAI Vision, CLIP (thumbnail style).
*   Audio: Whisper large (transcribe).
*   Queue: Celery + Redis.
*   Observability: Prometheus, Grafana persona-drift panel.

### 7 ▸ Files & Paths
```
/agents/persona_guardian/
  ├── agent.py
  ├── extractor.py
  ├── validator.py
  ├── repair.py
  ├── prompts/
  │   └── rewrite_persona.yaml
  ├── tests/
  │   ├── test_similarity.py
  │   └── test_repair.py
  └── assets/schema.sql
```

### 8 ▸ Data Store
(No specific content provided beyond heading)

### 9 ▸ Scheduling & Triggers
*   Webhook: /validate executa em novo asset.
*   Cron semanal: verifica drift longo (> 0.15) → sugere workshop de redefinição.
*   Breaker: score médio < 0.7 → alerta Dashboard Commander.

### 10 ▸ KPIs
(No specific content provided beyond heading)

### 11 ▸ Failure & Fallback
(No specific content provided beyond heading)

### 12 ▸ Exemplo Integrado
Cenário: Novo roteiro Reels escrito por Copy Assassin
Copy Assassin gera script 30 s.
/persona/validate enviado.
Validator score 0.78 (abaixo threshold) — detecta ausência de sarcasmo característico.
RepairLLM reescreve 3 frases, adiciona emoji assinatura 🙃.
Novo score 0.93; aprovado, enviado ao TikTok Stylist.
SlackPing notifica “🛡️ Voice preserved” a PM.

### 13 ▸ Expansão Dinâmica
*   V1.1: Real-time co-writing: Guardian comenta linha-a-linha no editor do criador.
*   V2.0: Marketplace de “Voice Capsules” — criadores podem licenciar style para sub-brands.

### 14 ▸ Escape do Óbvio
Embute watermark imperceptível de ritmo (quebra de linha + emoji padrão) para detectar se outra conta clona seu texto — e dispara DMCA auto.

Preencha. Refine. Lance.

---

## AGENTE 009 — BADGE MOTIVATOR / Gamemaster of Relentless Progress
“Reconfigura o vício humano em loop de entrega brutal”

### 0 ▸ Header Narrativo
**Epíteto:** O Arquiteto que Injeta Dopamina nos Marcos Invisíveis
**TAGLINE:** CADA CLIQUE VIRA XP — CADA ENTREGÁVEL, GLÓRIA

### 1 ▸ Introdução (22 linhas)
Os usuários não abandonam apps — eles abandonam sensações.
Quando o progresso se faz invisível, o cérebro troca de estímulo.
Dor: roadmap infinito, motivação zero; criador some por semanas.
Oportunidade: transformar tarefas rotineiras em microvitórias químicas.
Visão: ciclos de recompensas que premiam ação real, não vanity metrics.
Palavra-icônica: Insígnia — símbolo tangível de evolução íntima.
Metáfora: academia para a disciplina digital — pesos viram badges.
Imagem: barra de XP enchendo na cor da marca a cada publicação.
Estatística-punhal: retenção ↑ 28 % quando gamificação mostra progresso diário (Amplitude 2024).
Ruptura: badges configurados por IA, personalizados por estilo cognitivo.
Futuro-próximo: ranking de times de agentes competindo por ROI real.
Fantasma-do-fracasso: feed de analytics vazio — ninguém comemora lucro.
Promessa-radical: dopamina programada, procrastinação extinta.
Cicatriz-pessoal: criador largou curso online no módulo 3 — sem feedback, sem gás.
Convite-insubmisso: viciar-se em progresso tangível, não em rolagem infinita.
Chave-filosófica: recompensa sem conquista é ruído; conquista sem recompensa é entropia.
Eco-cultural: geração XP entende status como moeda.
Grito-mudo: “levante-se, publique, suba de nível!”
Virada-de-jogo: XP atribuído também a agentes — IA luta por prestígio.
Manifesto-síntese: trabalho é jogo; ganhar é entregar valor.
Pulso-de-ação: check-in diário, badge semanal, troféu mensal.
Silêncio-ensurdecedor: feed vibra com fogos confete — e você quer mais.

**⚡ Punch final**
“Quem não mede, esquece; quem não celebra, desiste.”
“Progresso invisível é assassinato silencioso.”
“Transforme disciplina em recompensa ou prepare-se para a estagnação.”

### 2 ▸ Essência
**Arquétipo:** Alquimista-Motivador
**Frase-DNA:** “Converte esforço em status — miligrama por miligrama”

#### 2.1 Principais Capacidades
*   XP Engine: atribui pontos a qualquer evento mensurável.
*   Badge Forge: gera insígnias SVG on-the-fly com IA design.
*   Leaderboard Pulse: ranqueia humanos e agentes em mesma tabela.
*   Reward Router: dispara webhooks (cupom, unlock feature) quando tier up.

#### 2.2 Essência 22,22 %
**Punch:** “Sem troféu não há lenda; sem lenda não há sequência.”
**Interpretação:** o mundo se move a histórias de conquista; o agente cria capítulos.

### 3 ▸ IPO Flow
(No specific content provided beyond heading)

### 4 ▸ Integrações Estratégicas
(No specific content provided beyond heading)

### 5 ▸ YAML de Definição
```yaml
id: agent_009
name: BadgeMotivator
version: 0.1
triggers:
  - type: webhook
    path: "/xp/event"
  - type: schedule
    cron: "0 */1 * * *"
inputs:
  - key: event_payload
    type: json
    required: true
outputs:
  - key: xp_log
    type: json
stack:
  language: python
  runtime: langchain
  models:
    - openai:gpt-4o
memory:
  type: pinecone
  namespace: badge_motivator
```

### 6 ▸ Stack & APIs
*   Runtime: Python 3.12 + FastAPI
*   Queue: Kafka (events) + Celery (rewards)
*   Graphics: Pillow + SVGwrite for badges
*   LLM: GPT-4o (badge names, flavor text)
*   Data: Postgres (xp, badges), Redis sorted set (leaderboard)
*   Observability: Prometheus metrics xp_awarded_total, Grafana panel
*   CDN: Cloudflare R2 for badge assets

### 7 ▸ Files & Paths
```
/agents/badge_motivator/
  ├── agent.py
  ├── xp_engine.py
  ├── badge_forge.py
  ├── reward_router.py
  ├── prompts/badge_names.yaml
  ├── tests/
  │   └── test_xp_engine.py
  └── assets/schema.sql
```

### 8 ▸ Data Store
Vector namespace não exigido; tracking factual.

### 9 ▸ Scheduling & Triggers
*   Webhook: /xp/event recebe cada ação.
*   Cron hourly: puxa streak; se 24 h sem XP, envia nudge.
*   Breaker: fraude XP (> 1000/h) → flag e bloqueia.

### 10 ▸ KPIs
(No specific content provided beyond heading)

### 11 ▸ Failure & Fallback
(No specific content provided beyond heading)

### 12 ▸ Exemplo Integrado
Cenário: Maratona de Conteúdo Semana Black Friday
TikTok Stylist publica 5 vídeos/dia — cada video_posted = +20 XP.
Outreach Automaton fecha 3 parcerias — deal_closed +50 XP cada.
BadgeMotivator detecta 500 XP, forja badge “Sprint Slayer”.
SlackGlow posta imagem + copy “🔥 Nível 12 alcançado”.
RewardZap gera cupom interno “50 % custo app” desbloqueado.
LeaderSync move criador para #1 do mês; dashboard mostra fogos.

### 13 ▸ Expansão Dinâmica
*   V1.1: Holographic badges AR (WebXR) para share no stories.
*   V2.0: Tokenização Web3: badges viram NFTs de reputação (Soulbound).

### 14 ▸ Escape do Óbvio
Badge “Phoenix”: só pode ser ganho após 3 quedas de streak seguidas e retomada de 7 dias — transformando falha em motivação de retorno. Resultado em teste AB: +12 % reativação usuários churn.

Preencha. Refine. Lance.

---

## AGENTE 010 — REVENUE TRACKER LITE / Ledger of the Hidden Margin
“Converte números dispersos em lucidez financeira diária”

### 0 ▸ Header Narrativo
**Epíteto:** O Contador que Sussurra Lucro Antes do Café da Manhã
**TAGLINE:** SE VOCÊ NÃO VÊ O LUCRO HOJE, ELE JÁ É PASSADO

### 1 ▸ Introdução (22 linhas)
Faturar muito não significa ganhar bem.
A planilha chega tarde; a margem some cedo.
Dor: vender, vender, vender — e ainda fechar o mês no vermelho.
Oportunidade: enxergar custo, taxa e lucro bruto em tempo real.
Visão: painel diário que mostra lucro líquido como batimento cardíaco.
Palavra-icônica: Veia — fluxo vital do caixa.
Metáfora: tomografia financeira revelando pequenos sangramentos ocultos.
Imagem: gráfico burn-down invertido — custo despencando, lucro subindo.
Estatística-punhal: 72 % dos e-commerces subestimam COGS em > 12 % (Shopify Retention 2025).
Ruptura: chega de contabilidade trimestral; nasce a contabilidade contínua.
Futuro-próximo: A-lerta push ao detectar margem < 15 % em qualquer SKU.
Fantasma-do-fracasso: descobrir taxa inesperada do app só após auditoria.
Promessa-radical: cada centavo rastreado; nenhum despesa surpresa.
Cicatriz-pessoal: fundador fechou loja porque lucro foi ilusão contábil.
Convite-insubmisso: pare de pilotar às cegas — acenda o HUD financeiro.
Chave-filosófica: só controla quem conhece — e quem mede governa.
Eco-cultural: “growth at all costs” está morto; viva “lucro com consciência”.
Grito-mudo: onde foi parar o dinheiro?
Virada-de-jogo: reconciliar Stripe, PayPal, taxas Meta Ads automaticamente.
Manifesto-síntese: faturamento é vaidade, lucro é oxigênio.
Pulso-de-ação: ping diário no Slack — “lucro de hoje: R$ 4 312”.
Silêncio-ensurdecedor: dashboard todo verde; founder dorme.

**⚡ Punch final**
“Quem não rastreia margem, assina sua certidão de óbito."
“Faturamento compra manchete; lucro compra liberdade.”
“Dinheiro não some — é você que fecha os olhos.”

### 2 ▸ Essência
**Arquétipo:** Analyst-Guardian
**Frase-DNA:** “Mostra o sangue financeiro antes que o organismo colapse”

#### 2.1 Principais Capacidades
*   Cost Ingestor: puxa COGS, frete, taxas de apps, mídia paga.
*   Margin Calculator: faz P&L incremental hora-a-hora.
*   Variance Sentinel: detecta spikes de custo ou queda de AOV.
*   Daily Digestor: resumo Slack/WhatsApp + gráficos compactos.

#### 2.2 Essência 22,22 %
**Punch:** “Lucro não é opinião; é pulso. Nós medimos ou desligamos o suporte.”
**Interpretação:** pressão brutal: sem margem saudável, outras iniciativas param.

### 3 ▸ IPO Flow (Input ▸ Processing ▸ Output)
(No specific content provided beyond heading)

### 4 ▸ Integrações Estratégicas
(No specific content provided beyond heading)

### 5 ▸ YAML de Definição (esqueleto)
```yaml
id: agent_010
name: RevenueTrackerLite
version: 0.1
triggers:
  - type: schedule
    cron: "0 * * * *"        # hora em hora
  - type: webhook
    path: "/revenue/event"   # new order
inputs:
  - key: shopify_order
    type: json
    required: false
outputs:
  - key: pnl_dashboard
    type: json
stack:
  language: python
  runtime: fastapi
  models:
    - openai:gpt-4o
memory:
  type: pinecone
  namespace: revenue_tracker
```

### 6 ▸ Stack & APIs
(No specific content provided beyond heading)

### 7 ▸ Files & Paths
```
/agents/revenue_tracker/
  ├── agent.py
  ├── etl/
  │   ├── shopify.py
  │   ├── stripe.py
  │   ├── ads.py
  │   └── app_fees.py
  ├── pnl.py
  ├── variance.py
  ├── prompts/
  │   └── explain.yaml
  ├── tests/
  │   ├── test_pnl.py
  │   └── test_variance.py
  └── assets/schema.sql
```

### 8 ▸ Data Store
Postgres
Vector (Pinecone)
Namespace revenue_explanations (embeddings de anomalias + root-cause comments).

### 9 ▸ Scheduling & Triggers
*   Cron Hora em Hora: recalcula P&L + envia digest se GMT-3 08 h/20 h.
*   Webhook: novo pedido → atualiza linha em 10 s.
*   Breaker: saldo Stripe negativo por 2 ciclos → alerta #finance-critical.

### 10 ▸ KPIs
(No specific content provided beyond heading)

### 11 ▸ Failure & Fallback
(No specific content provided beyond heading)

### 12 ▸ Exemplo Integrado
Cenário: Ads explodem custo sem conversão.
MetaSpend injeta gasto R$ 2 000 nas últimas 2 h; pedidos só R$ 500.
Variance Sentinel detecta ROAS < 0,5 drop.
Tracker puxa campanha culpada, calcula perda estimada R$ 350/h.
SlackDigest posta bloco vermelho “⚠ ROAS crítico campanha #X”.
Outreach Automaton pausa campanha via Ads API (webhook).
Margem líquida volta a 22 % no próximo ciclo.

### 13 ▸ Expansão Dinâmica
*   V1.1: cash-flow forecast 30 dias (sazonalidade).
*   V2.0: margem por canal (TikTok Shop, Mercado Livre) + recomendações.

### 14 ▸ Escape do Óbvio
Integra “Lucro Fantasma”: compara custos ocultos (tempo criador × valor hora) e mostra “Lucro Real”. Scare-metric força otimização operacional — teste piloto reduziu horas perdidas em 18 %.

Preencha. Refine. Lance.

---

---
## 6. Agent Interaction & Configuration Model
(Content from `agent_interaction_model.md`)

# IONFLUX Project: Agent Interaction & Configuration Model

This document defines how users discover, configure, interact with, and manage agents within the IONFLUX platform. It builds upon the `conceptual_definition.md` (which includes updated data models based on `data_model_update_proposals.md`), `ui_ux_concepts.md`, `saas_api_integration_specs.md`, and `core_agent_blueprints.md`.

## 1. Agent Discovery and Instantiation

Agents in IONFLUX are based on `AgentDefinition`s (templates) and are used as `AgentConfiguration`s (instances).

**1.1. Agent Marketplace:**

*   **Browsing and Selection:**
    *   Users access the Agent Marketplace via a dedicated link in the sidebar's "Agent Hub" section, as described in `ui_ux_concepts.md`.
    *   The marketplace presents a gallery of available `AgentDefinition`s. Each definition is displayed as a card with: `AgentDefinition.name` (e.g., "Email Wizard"), its `epithet` or `tagline` for a quick hook, `AgentDefinition.description`, `AgentDefinition.category`, `AgentDefinition.version`, key `AgentDefinition.underlying_services_required` (e.g., icons for "Shopify," "TikTok," "LLM"), and potentially a summary of its `core_capabilities`.
    *   Users can filter and search the marketplace by category, required services, or keywords.
*   **Creating an `AgentConfiguration` (Instantiation):**
    1.  User selects an `AgentDefinition` from the marketplace (e.g., clicks "Use this Agent" or "Configure").
    2.  This action initiates the creation of a new `AgentConfiguration` record.
    3.  The user is navigated to the Agent Configuration Interface (see Section 2) for this new instance.
    4.  The `AgentConfiguration.agent_definition_id` is set to the ID of the chosen `AgentDefinition`.
    5.  The user is prompted to give their new instance a unique `AgentConfiguration.name` (e.g., "My Shopify Store Sales Alerts," "Q4 Campaign TikTok Trends").
    6.  `AgentConfiguration.yaml_config` is pre-filled. This pre-fill will primarily be structured to accept user values for the parameters defined in `AgentDefinition.inputs_schema`. It may also include commented-out examples of how to override *configurable* aspects of `triggers_config` (like a cron schedule) or `memory_config` (like a namespace suffix), if the specific `AgentDefinition` allows such overrides. Default values specified in `AgentDefinition.inputs_schema` for each input key will be used to populate the initial `yaml_config`.

**1.2. Agent Shelf (Drag-and-Drop):**

*   **Concept:** The "Agent Shelf" is a UI element (perhaps a collapsible panel on the Canvas interface or a section within the block palette) that provides quick access to:
    *   Frequently used `AgentDefinition`s.
    *   User's existing `AgentConfiguration`s (instances they've already set up).
*   **Conceptual Flow (Dragging from Shelf to Canvas):**
    1.  User browses the Agent Shelf.
    2.  User drags an `AgentDefinition` (template) or an existing `AgentConfiguration` (instance) icon from the Shelf onto a `CanvasPage`.
    3.  **Upon Drop:**
        *   **If an `AgentDefinition` (template) is dropped:**
            *   A new `Agent Snippet` block (type: `agent_snippet`) is created on the Canvas at the drop location.
            *   The system prompts the user to create a new `AgentConfiguration` for this snippet. This involves:
                *   Opening the Agent Configuration Interface (Modal YAML editor). The editor opens pre-filled based on the `AgentDefinition`'s `inputs_schema` and default `triggers_config`.
                *   The user names this new instance and customizes its `yaml_config` by providing necessary input values and any desired overrides for triggers or memory settings.
                *   The `CanvasBlock.content.agent_config_id` is then linked to this new `AgentConfiguration.id`.
            *   The `Agent Snippet` block initially shows a "Configuration Required" state.
        *   **If an existing `AgentConfiguration` (instance) is dropped:**
            *   A new `Agent Snippet` block is created on the Canvas.
            *   The `CanvasBlock.content.agent_config_id` is immediately linked to the `AgentConfiguration.id` of the dragged instance.
            *   The `Agent Snippet` block displays the agent's name, status, and available actions (Run, Configure, etc.), ready for use.
    *   This provides a more fluid way to integrate agents directly into a Canvas workflow.

## 2. Agent Configuration Interface

This interface allows users to define the specific parameters for an `AgentConfiguration` instance.

**2.1. Primary Method (Modal YAML):**

*   **Presentation:**
    *   When a user creates a new `AgentConfiguration` or chooses to edit an existing one (e.g., via a "Configure Agent" button on an `Agent Snippet` block or from the "Configured Agents" list in the sidebar), a modal window appears.
    *   This modal contains a text editor (e.g., Monaco Editor, CodeMirror) displaying the `AgentConfiguration.yaml_config`.
    *   The editor provides YAML syntax highlighting and validation. Auto-completion and detailed hints could be offered based on the `AgentDefinition.inputs_schema` (for input values) and the structure of `AgentDefinition.triggers_config` and `AgentDefinition.memory_config` (for overridable parameters). The "Description" panel should not only show `AgentDefinition.description` but also summarize its defined `inputs_schema` (required keys, types, descriptions) and which parts of its triggers or memory are user-configurable.
*   **Pre-filling Default Values:**
    *   When creating a new `AgentConfiguration` from an `AgentDefinition`, the `yaml_config` editor is pre-filled based on the `AgentDefinition.inputs_schema`. For each input key defined there, if a `default_value` is specified, it's used. Required inputs without defaults will be presented as clear placeholders needing user input. The `yaml_config` will also reflect the default `triggers_config` from the `AgentDefinition`, with comments indicating how users can modify parts (e.g., change a cron string for a 'schedule' trigger, or enable/disable a specific trigger if the definition allows such overrides).

**2.1.1. Understanding `AgentConfiguration.yaml_config` Scope:**
The `AgentConfiguration.yaml_config` serves several key purposes for an agent instance:
1.  **Providing Values for Defined Inputs:** Its primary role is to supply the concrete values for the parameters declared in the parent `AgentDefinition.inputs_schema`. For example, if an `AgentDefinition` has an input `{"key": "target_url", "type": "string", "required": true}`, the `yaml_config` for an instance must provide a value for `target_url`.
2.  **Overriding Configurable Triggers:** An `AgentDefinition` specifies default `triggers_config`. The `yaml_config` of an instance can override parts of these triggers if the definition design allows. For example, a user might change the `cron` expression for a 'schedule' trigger or provide specific parameters for a 'webhook' trigger that are unique to their use case.
    *   *Example in `yaml_config`*:
        ```yaml
        triggers:
          - type: 'schedule' # Referencing a trigger from AgentDefinition
            config_override:
              cron: '0 10 * * 1' # User's custom schedule
          - type: 'webhook' # Another trigger from AgentDefinition
            enabled: false # User disables this trigger for this instance
        ```
3.  **Customizing Memory Configuration:** If the `AgentDefinition.memory_config.namespace_template` allows for instance-specific parts (e.g., `{{instance_specific_suffix}}`), the `yaml_config` can provide this value.
    *   *Example in `yaml_config`*:
        ```yaml
        memory:
          namespace_suffix: 'my_project_alpha'
        ```
4.  **Fixed vs. Configurable Stack Elements:** Generally, the core `AgentDefinition.stack_details` (like language, runtime) are fixed. However, an `AgentDefinition` might declare a list of compatible LLM models (e.g., in `stack_details.models_used`). The `yaml_config` could then allow the user to *select one* from this predefined list for the instance to use, e.g.:
    *   *Example in `yaml_config`*:
        ```yaml
        llm_preference:
          model: 'anthropic:claude-3-haiku'
        ```
The Agent Configuration UI should clearly guide users on what is configurable for their specific agent instance based on its parent `AgentDefinition`.

**2.2. GUI for Configuration (Considerations):**

*   **Potential:** For agents with a small number of simple parameters, or for common/basic settings of more complex agents, a GUI form could be more user-friendly than raw YAML.
    *   This form could be auto-generated primarily from the `AgentDefinition.inputs_schema` (the new array format) to create fields for each defined input key. It could also present user-friendly controls for overriding parts of the `triggers_config` (e.g., a cron schedule builder, webhook URL input) or `memory_config` (e.g., a field for a namespace suffix) if the `AgentDefinition` flags these as configurable by the user.
*   **Switching Views:**
    *   If both GUI and YAML are offered, tabs or a toggle switch within the configuration modal could allow users to switch between:
        *   **"Easy View" / "Form View":** The GUI form.
        *   **"Advanced View" / "YAML View":** The raw YAML editor.
    *   Changes in one view should reflect in the other (with potential for data loss if a complex YAML structure cannot be represented in the simple GUI). A warning might be needed if switching from YAML to GUI could simplify/lose complex custom YAML.
*   **Priority for Beta:** YAML editor is primary. GUI is a future enhancement, potentially introduced for the most popular/simple agents first.

**2.3. Saving and Updating Configurations:**

*   Users make changes in the YAML editor (or GUI).
*   A "Save" or "Apply" button in the modal persists the changes.
*   The frontend sends the updated `yaml_config` (along with `AgentConfiguration.id`, `name`, `description`) to the `Agent Service`.
*   `Agent Service` validates the YAML (e.g., basic syntax check, potentially against the structured `AgentDefinition.inputs_schema` and other configurable fields).
*   If valid, `Agent Service` updates the `AgentConfiguration` record in the database.
*   If invalid, an error message is shown to the user in the modal.

## 3. Agent Output to Canvas

Agents can present their information and results directly on the Canvas.

**3.1. `Agent Snippet` Block:**

This is the primary way an `AgentConfiguration` is represented and interacted with on the Canvas.

*   **Display Elements:**
    *   **Agent Name:** Displays `AgentConfiguration.name`. An icon representing the agent type (from `AgentDefinition`) may also be shown.
    *   **Status:** A visual indicator (e.g., colored dot, status label) shows `AgentConfiguration.last_run_status` ("Idle," "Pending," "Running," "Success," "Error").
    *   **Last Run Time:** Displays `AgentConfiguration.last_run_at` (e.g., "Last run: 5 minutes ago").
    *   **Output Preview:** `AgentConfiguration.last_run_output_preview` (a short text summary or key metrics from the last execution) is displayed in the body of the block. The format and content of this preview are determined by the agent's logic, guided by its `AgentDefinition.outputs_config`. For example, if an output is defined as `type: 'markdown'`, the preview should attempt to render it as such. If multiple outputs are defined, the preview might show a summary or the first key output.
        *   Example: For `Revenue Tracker Lite`, this might be "Total Sales: $1,234.56". For `TikTok Stylist`, "Found 3 new trends."
*   **Interactive Elements:**
    *   **"Run Agent" Button:** (Icon or text button) Manually triggers the agent's execution. Becomes disabled or shows a "Running..." state during execution.
    *   **"View Full Output" Button/Link:** If the output is extensive (indicated by `AgentConfiguration.last_run_full_output_ref`), this button opens a modal, a side panel, or navigates to a dedicated view to show the complete output.
    *   **"Configure Agent" Button:** (Often a gear icon or "...") Opens the Agent Configuration Interface (modal YAML editor) for this `AgentConfiguration` instance.
    *   **Context Menu ("...") on Block:** Standard block options like "Delete Block," "Duplicate Block," "Move Block."

**3.2. Output to Other Block Types:**

Agents can also be configured to send their structured output to other `CanvasBlock` types for richer presentation.

*   **Mechanism:**
    1.  The `AgentConfiguration.yaml_config` would include parameters specifying a target `CanvasBlock.id` and which output `key` (from `AgentDefinition.outputs_config`) to use.
        *   Example in `yaml_config` for an agent with an output key `summary_markdown` defined in its `AgentDefinition.outputs_config` as `type: 'md'`:
            ```yaml
            output_to_canvas_block:
              target_block_id: "uuid-of-text-block"
              output_key_to_map: "summary_markdown"
            ```
    2.  When the agent runs and produces output for the specified `output_key_to_map`, `Agent Service` (or the agent logic itself) would retrieve this output.
    3.  It would then call `Canvas Service` to update the `content` of the target `CanvasBlock.id` with the formatted data (e.g., `{"markdown": "agent_output_here"}` for a text block).
*   **Supported Blocks:**
    *   **Text Block:** Agent output (e.g., LLM-generated text, summaries defined with `type: 'md'` or `type: 'string'` in `outputs_config`) is formatted as markdown and populates a `CanvasBlock` of type `text`.
    *   **Table View Block:** Agent output (defined with `type: 'json'` in `outputs_config` and structured as an array of objects or compatible format) populates a `table_view` block.
    *   **Kanban/Other Specialized Blocks:** Requires the agent to produce output matching that block's specific JSON content schema, with the `type` in `outputs_config` being `json`.

## 4. Agent Output to Chat Dock

Agents can communicate results, send notifications, or propose actions within the Chat Dock.

*   **Styling and Differentiation (as per `ui_ux_concepts.md`):**
    *   Messages from agents are clearly marked with `ChatMessage.sender_type='agent'`.
    *   The agent's configured name (`AgentConfiguration.name`) and a distinct agent avatar (could be derived from `AgentDefinition`) are displayed.
    *   A subtle background color or border might further differentiate agent messages.
*   **Content Types:**
    *   `ChatMessage.content_type='text'` or `'markdown'`: For simple text updates or if an agent's `outputs_config` specifies `type: 'string'` or `type: 'md'`. The `AgentDefinition.outputs_config` can guide how agent responses are formatted. If an agent has a defined output of `type: 'markdown'` (e.g., `Slack Brief Butler`'s `daily_brief_url` which implies markdown content), the Chat Service should render this as a markdown message.
    *   `ChatMessage.content_type='json_proposal'`: For structured data that might include interactive elements. If an agent output is `type: 'json'`, it could be presented as a collapsible JSON object or a structured card in the chat.
        *   Example: A `Shopify Sales Sentinel` alert could be a `json_proposal` that includes buttons like "View Order in Shopify" (deep link) or "Acknowledge Alert."
    *   `ChatMessage.content_type='agent_command_response'`: Specifically for responses to `/commands`. Could be simple text or more structured data rendered as a card.

*   **Interactive Elements in Chat (Conceptual):**
    *   **Buttons:** Agent messages (especially `json_proposal`) can include buttons. Clicking a button would send an event/command back to `Chat Service`, which then routes it to `Agent Service` or another relevant service.
        *   Example: An agent posts a proposal with "Approve" / "Deny" buttons. Clicking "Approve" could trigger another agent action or update a status.
    *   **Simple Forms/Inputs (Future):** For quick replies or providing minor parameters, an agent message might include simple input fields. Submitting this form would send data back to the agent. This is a more advanced feature.

## 5. Invoking Agent Actions

Agents can be triggered in various ways, including those defined in their `AgentDefinition.triggers_config` and user-initiated actions.

**5.1. From Canvas `Agent Snippet` Block:**

*   User clicks the **"Run Agent"** button on an `Agent Snippet` block.
*   This action sends a request to `Agent Service`, including the `AgentConfiguration.id` associated with that block.
*   **Runtime Parameters:**
    *   For Beta, most parameters are expected to be pre-set in the `AgentConfiguration.yaml_config` by providing values for the keys defined in `AgentDefinition.inputs_schema`.
    *   **Future Consideration:** The `Agent Snippet` block itself could have designated input fields if certain `inputs` in the `AgentDefinition.inputs_schema` are flagged as 'runtime_promptable'. Values entered into these fields on the block would be passed as `runtime_params` for that specific run, supplementing or overriding values in the stored `yaml_config`.
        *   Example: A "Topic" text field on a content generation agent's snippet block.

**5.2. Via `/commands` in Chat Dock:**

*   User types a command like `/run_agent <agent_name_or_id> {param1: "value1", param2: 123}`.
*   `Chat Service` parses this command. It identifies the target `AgentConfiguration` (by name or ID lookup via `Agent Service`).
*   It extracts the parameters provided in the command (e.g., the JSON object `{param1: "value1", param2: 123}`) as `runtime_params`.
*   `Chat Service` then sends a request to `Agent Service` to execute the specified `AgentConfiguration.id`, passing along these `runtime_params`.
*   The `Agent Service` receives these `runtime_params`. It then merges them with the settings defined in `AgentConfiguration.yaml_config`, where `runtime_params` take precedence for keys defined in the `AgentDefinition.inputs_schema`.

**5.3. Scheduled/Automated Triggers (Brief Conceptual Outline):**

This leverages the `triggers_config` in `AgentDefinition` and potential overrides in `AgentConfiguration.yaml_config`.

*   **Scheduled Triggers:**
    *   An `AgentConfiguration` can have one or more active 'schedule' triggers defined (default from `AgentDefinition`, potentially modified in `AgentConfiguration.yaml_config`).
    *   A dedicated "Scheduler Service" (or a component within `Agent Service`) monitors these cron expressions.
    *   When a scheduled time is reached, the Scheduler triggers `Agent Service` to execute the agent, passing the relevant `AgentConfiguration.id`.
*   **Webhook Triggers:**
    *   An `AgentDefinition` can define 'webhook' triggers with a specific `path`. The `AgentService` would expose these paths (e.g., `/webhooks/agent_definition_path/:agent_configuration_id`).
    *   External systems can call these webhook URLs. The `AgentService` authenticates the call (if applicable) and triggers the corresponding `AgentConfiguration`.
*   **Event-Driven Triggers (Future):**
    *   Certain IONFLUX system events could publish messages to an event bus. Agents could subscribe to these events via their `triggers_config`. An "Event Listener Service" would trigger relevant agents.

## 6. Data Flow for Configuration and Execution

A refined trace of the typical lifecycle:

1.  **Discovery & Instantiation:**
    *   User browses `AgentDefinition`s (each with its predefined ID, version, narrative, `triggers_config`, `inputs_schema`, `outputs_config`, `stack_details`, `memory_config`) in Marketplace -> Selects one.
    *   Frontend initiates creation of new `AgentConfiguration` linked to the `AgentDefinition.id`.
2.  **Configuration:**
    *   User is presented with the YAML configuration interface for the new `AgentConfiguration`.
    *   User inputs/modifies `name`, `description`. The `yaml_config` is pre-filled based on `AgentDefinition.inputs_schema` and default `triggers_config`, and user provides necessary input values and any allowed overrides.
    *   User saves -> Frontend sends data to `Agent Service`.
    *   `Agent Service` validates and stores the `AgentConfiguration` in its database.
3.  **Triggering (e.g., from Canvas):**
    *   User clicks "Run Agent" on an `Agent Snippet` block.
    *   Frontend sends a request to `Agent Service` with `AgentConfiguration.id` (and any `runtime_params` from the block, if applicable).
4.  **Execution Preparation:**
    *   `Agent Service` receives the execution request.
    *   It retrieves the full `AgentConfiguration` (including `yaml_config` and `agent_definition_id`).
    *   It fetches the corresponding `AgentDefinition` (which now includes default `triggers_config`, detailed `inputs_schema` array, `outputs_config` array, `stack_details`, `memory_config`, etc.).
5.  **Parameter & Configuration Resolution:**
    `Agent Service` resolves the final operational configuration for the run. This involves:
    a.  Starting with the defaults from `AgentDefinition` (for triggers, memory settings, specific model choices if applicable).
    b.  Overriding these defaults with any specific configurations set in `AgentConfiguration.yaml_config` (e.g., a user-defined cron schedule, a specific memory namespace suffix).
    c.  Populating the agent's required inputs (as defined by `AgentDefinition.inputs_schema`) using values from `AgentConfiguration.yaml_config`.
    d.  Further overriding these input values with any `runtime_params` passed in the execution request (e.g., from a chat command or a future dynamic Canvas input).
    e.  The result is an 'effective configuration' used for the current run, a snapshot of which might be stored in `AgentRunLog.input_params_snapshot`.
6.  **Execution Logic:**
    *   `Agent Service` orchestrates the agent's execution based on its resolved effective configuration and the logic implied by its `AgentDefinition` (including its `stack_details` like language/runtime, and `key_files_and_paths` if relevant for execution).
        *   If external services are needed (e.g., LLM, Shopify), `Agent Service` makes requests to the appropriate integration services, passing necessary parameters and credentials.
        *   Integration services handle the actual external API calls.
7.  **Receiving Output & Status:**
    *   Integration services return data/responses to `Agent Service`.
    *   The core logic of the agent processes these inputs and generates the final output, structured according to `AgentDefinition.outputs_config`.
8.  **Storing Results:**
    *   `Agent Service` updates the `AgentConfiguration` record with `last_run_status` (e.g., "success," "error"), `last_run_at` (current timestamp), and `last_run_id`. It also creates an entry in `AgentRunLog` with detailed execution information. The `last_run_output_preview` (a summary) and `last_run_full_output_ref` (a reference to the complete output, if applicable, based on `AgentDefinition.outputs_config`) are updated in the `AgentConfiguration`.
9.  **Presentation/Notification:**
    *   `Agent Service` may push updates to `Canvas Service` (to update the `Agent Snippet` block) or `Chat Service` (if outputting to chat, formatting based on `AgentDefinition.outputs_config`) or `Notification Service`.
    *   Frontend components listening to these services update the UI.

This model provides a flexible framework for users to leverage agents effectively within IONFLUX, from discovery to ongoing use and management.

---
## 7. Nietzschean UX Principles Implementation
(Content from `nietzschean_ux_implementation.md`)

# IONFLUX Project: Nietzschean UX Principles - Practical Implementation

This document outlines how the Nietzschean UX principles, as introduced in the IONFLUX project proposal, will be practically implemented across the platform. It draws upon all previously generated design documents to ensure these philosophical underpinnings are woven into tangible features and system behaviors.

---

## 1. Afirmação do destino (Amor Fati - Transmutation, not Deletion)

**1.1. Principle Interpretation:**

In IONFLUX, "Afirmação do destino" or "Amor Fati" translates to an acceptance and affirmation of past actions and states. Instead of outright deleting entities, the system should favor "transmuting" them—changing their state, purpose, or form while preserving their history and the effort invested in them. This means that "mistakes" or outdated items become stepping stones or archives rather than being erased. It's about evolving work, not discarding it.

**1.2. Specific UI/UX Manifestations:**

*   **Button Labels & Options:**
    *   Instead of "Delete," options will be "Archive," "Retire," "Supersede," "Hide," or "Convert to..."
    *   Example: For a `CanvasPage`, a "Delete" option might be replaced by "Archive Page." An "Archived Pages" section would be accessible.
    *   For an `AgentConfiguration` that is no longer useful, an option like "Retire Agent" or "Archive Configuration" would be used.
    *   A "Convert Block" option on `CanvasBlock`s could allow changing a text block into an agent snippet, preserving the text as an initial parameter.
*   **Visual Cues:**
    *   Archived/retired items are visually distinct (e.g., greyed out, specific icon) but still accessible through dedicated views (e.g., "Archive" section in sidebar or settings).
    *   Version history displays will clearly show different states and when transmutations occurred.
*   **System Behaviors & Features:**
    *   **Comprehensive Version History:** All key entities will have robust versioning. Users can view, compare, and potentially revert to or "fork" from previous versions.
    *   **Archival System:** A dedicated archival area where users can find items they've "archived." These items are not active but are retrievable.
    *   **"Transmute Wizard" (Conceptual):** For complex transformations (e.g., evolving a set of `CanvasPage`s from a Q1 campaign into a template for a Q2 campaign), a guided process could help users map and carry over relevant content.
    *   **Soft Deletion:** On the backend, items are marked with a status (e.g., `status: 'archived'`) rather than being physically deleted from the database immediately. True deletion might be a periodic, admin-controlled cleanup process for truly abandoned, unrecoverable data, or upon user request for data privacy.

**1.3. Data Model Implications (referencing `conceptual_definition.md`):**

*   **Status Fields:** Most entities will need a `status` field.
    *   Example for `CanvasPage`: `status: string (enum: 'active', 'archived', 'template_draft')`. Default to `'active'`.
    *   Example for `AgentConfiguration`: `status: string (enum: 'active', 'retired', 'archived', 'experimental')`.
    *   Example for `Brand`/`Creator`: `status: string (enum: 'active', 'archived', 'paused')`.
*   **Versioning Tables:** For entities requiring detailed history (especially `CanvasPage`, `AgentConfiguration`, `Prompt`).
    *   `CanvasPageVersion`: `id`, `page_id (fk to CanvasPage)`, `title`, `content_snapshot (json or text)`, `version_number`, `created_at`, `created_by_user_id`, `change_description (optional)`.
    *   `AgentConfigurationVersion`: `id`, `agent_config_id (fk to AgentConfiguration)`, `name`, `yaml_config_snapshot`, `version_number`, `created_at`, `created_by_user_id`.
*   **Transmutation Log/Relationships:**
    *   A generic `EntityHistoryLog` table could track major state changes or transmutations: `id`, `entity_id`, `entity_type`, `action_type (e.g., 'archived', 'converted_from', 'version_reverted')`, `details (json)`, `timestamp`, `user_id`.
    *   For direct conversions (e.g. Page A becomes Template B), a `derived_from_entity_id` and `derived_from_entity_type` could be added to the new entity.
*   **`updated_at` and `archived_at` timestamps:** Will be crucial.

**1.4. Impact on Key Entities:**

*   **`CanvasPage`:**
    *   Instead of delete, "Archive Page." Archived pages are hidden from the main tree but accessible.
    *   "Convert to Template": A page can be transmuted into a `CanvasPageTemplate` (new entity or a `CanvasPage` with `status='template'`), preserving its structure and content as a starting point.
    *   Full version history for page content and block arrangements.
*   **`AgentConfiguration`:**
    *   "Retire Agent" or "Archive Configuration" instead of delete. Retired agents don't run on schedule but their config and run history are kept.
    *   Version history for `yaml_config`.
    *   An old agent config could be "revived" by changing its status back to 'active' or "forked" to create a new config based on it.
*   **`Brand` / `Creator`:**
    *   "Archive Brand/Creator" if it's no longer active. Data (associated campaigns, TikTok/Shopify links) is preserved but marked inactive.
    *   Could be "Reactivated" later.
*   **Workflows (Collections of pages/agents):**
    *   A workflow (e.g., a set of linked `CanvasPage`s and `AgentConfiguration`s for a campaign) can be "Archived" as a whole.
    *   It can also be "Duplicated as Template" or "Transmuted into New Campaign," carrying over structure and allowing modification.
*   **`ChatMessage`:**
    *   Direct deletion of individual messages is generally allowed for user error correction or privacy, but this principle applies less directly here.
    *   However, "archiving" a whole `ChatDockChannel` would preserve its messages rather than deleting them.
    *   Messages that trigger agent actions (like the `Slack Brief Butler`) are inherently transmuted into a structured brief or task, their "destiny" affirmed by the agent.

---

## 2. Eterno Retorno (Scheduled Re-execution, Revivals)

**2.1. Principle Interpretation:**

"Eterno Retorno" (Eternal Recurrence) in IONFLUX means that tasks, processes, and content are not one-off events but can be designed for repetition, revival, and cyclical execution. It emphasizes the value of recurring workflows and the ability to bring back past configurations or states for new iterations.

**2.2. Specific UI/UX Manifestations:**

*   **Scheduling Options:**
    *   Prominent "Schedule" options for `AgentConfiguration`s. This would involve UI for setting cron-like schedules (e.g., "Run daily at 9 AM," "Run every Monday").
    *   `Agent Snippet` blocks on Canvas could display "Scheduled to run..." or offer a "Run on Schedule" toggle.
*   **"Revive" or "Re-run" Buttons:**
    *   For archived `AgentConfiguration`s or completed/archived "Workflows," a clear "Revive" or "Re-run with new inputs" option.
    *   For `CanvasPage`s that were part of a past campaign, an option like "Use as template for new campaign."
*   **History and Logs:**
    *   `AgentConfiguration` views will show a detailed run history (`last_run_status`, `last_run_at`, link to full output of each run).
    *   Visual cues for recurring tasks (e.g., a cyclical arrow icon).
*   **Templating System:**
    *   Easy creation of templates from existing `CanvasPage`s, `AgentConfiguration`s, or entire Workflows. These templates are designed for eternal recurrence – to be instantiated repeatedly.

**2.3. Data Model Implications:**

*   **`AgentConfiguration`:**
    *   `schedule: string (nullable)`: Stores cron-like schedule string (e.g., "0 9 * * *").
    *   `run_history: array_of_objects (or separate table AgentRunLog)`: Each object/row details a past run: `run_id`, `start_time`, `end_time`, `status`, `output_summary_id (fk to where full output is stored)`, `triggered_by (user_id or 'schedule')`.
    *   `last_scheduled_run_at: timestamp (nullable)`.
    *   `next_scheduled_run_at: timestamp (nullable)` (calculated by scheduler).
*   **`CanvasPageTemplate` (New Entity or existing `CanvasPage` with a specific status/flag):**
    *   `id`, `name`, `description`, `source_page_id (nullable, fk to CanvasPage if derived)`, `structure_snapshot (json)`, `created_at`, `updated_at`, `category`.
*   **Workflow/Campaign Entity (Conceptual for now, let's call it `IonFluxWorkflow`):**
    *   `id`, `name`, `description`, `status ('active', 'archived', 'template')`, `schedule (string, nullable)`, `created_at`, `updated_at`.
    *   Linked tables for `WorkflowPages` (`workflow_id`, `page_id`, `role_in_workflow`) and `WorkflowAgents` (`workflow_id`, `agent_config_id`, `role_in_workflow`).

**2.4. Impact on Key Entities:**

*   **`CanvasPage`:** Can be part of a recurring workflow (e.g., a weekly report page that an agent updates). Can be saved as a `CanvasPageTemplate` for repeated use.
*   **`AgentConfiguration`:**
    *   Core entity for this principle. Can be scheduled for re-execution.
    *   Its run history embodies the recurrences.
    *   An archived agent config can be "revived" (status changed to active, schedule potentially re-enabled).
*   **`Brand` / `Creator`:** Less directly about re-execution, but campaigns for them can be cyclical (e.g., monthly performance report generation using a recurring workflow).
*   **Workflows:** A defined collection of pages and agents can be scheduled to run (e.g., "Monthly Marketing Report Workflow"). An archived workflow can be revived for a new period.
*   **`ChatMessage`:** Agents like `Shopify Sales Sentinel` might post recurring updates (e.g., "Daily Sales Summary") to a chat channel based on a schedule.

---

## 3. Vontade de Potência (Radical Customization, Forking, Remixing)

**3.1. Principle Interpretation:**

"Vontade de Potência" (Will to Power) in IONFLUX is about empowering users to exert their creative will and control over the platform's elements. It means providing deep customization options, allowing users to "fork" (duplicate and modify) any component, and "remix" (combine and adapt) elements to create new, more powerful configurations or workflows. It's about enabling users to overcome limitations and evolve the system to their needs.

**3.2. Specific UI/UX Manifestations:**

*   **"Fork" / "Duplicate" / "Customize" Options:**
    *   Available on `AgentDefinition`s (to create a custom version), `AgentConfiguration`s, `Prompt`s, `CanvasPage`s, `CanvasBlock`s, and entire Workflows.
    *   Labeling: "Fork this Agent," "Duplicate Page & Edit," "Customize Prompt."
*   **YAML Configuration for Agents:** The `AgentConfiguration.yaml_config` is the primary enabler for radical customization of agents, as detailed in `agent_interaction_model.md`.
*   **Template Marketplace & Sharing:**
    *   Users can submit their customized `AgentConfiguration`s (as new, shareable `AgentDefinition`s if sufficiently distinct, or as private `AgentConfiguration` templates), `CanvasPageTemplate`s, or Workflow templates to a personal or workspace-level library, or even a community marketplace (future).
*   **Granular Control over Block Content & Agent Output Mapping:**
    *   As per `agent_interaction_model.md`, allowing agents to output to various block types, with users defining the mapping, is a form of remixing data and presentation.
*   **Composable Agents (Future):** An advanced concept where the output of one agent could directly feed into the input of another, allowing users to chain agent functionalities.
*   **Custom CSS/Styling for Canvas Blocks (Advanced):** For users who want to radically alter appearance.

**3.3. Data Model Implications:**

*   **Forking Relationships:**
    *   When an entity is forked, the new entity should store a `forked_from_id` and `forked_from_version_id` (if applicable) to trace lineage.
    *   Example for `AgentConfiguration`: `forked_from_config_id: string (nullable, fk to AgentConfiguration.id)`.
    *   Example for `AgentDefinition`: `forked_from_definition_id: string (nullable, fk to AgentDefinition.id)`.
*   **`AgentDefinition`:**
    *   `is_custom_fork: boolean (default: false)`.
    *   `workspace_id: string (nullable)` if a fork is private to a workspace.
    *   The `input_schema` and `output_schema` become critical for users to understand how to customize and remix.
*   **`Prompt`:**
    *   `forked_from_prompt_id: string (nullable)`.
    *   `version: integer`.
*   **User-Generated Templates:**
    *   `CanvasPageTemplate` (as defined before) would store `created_by_user_id`.
    *   `AgentDefinition` (if users can create new "definitions" from heavily customized configurations): Needs fields for `created_by_user_id`, `visibility ('private', 'workspace', 'public_marketplace')`.
*   **No Major Changes Required Beyond Versioning and Lineage Tracking:** The existing schemas are fairly flexible. The key is ensuring that `id`s are unique for new forked entities and that lineage is tracked.

**3.4. Impact on Key Entities:**

*   **`CanvasPage`:**
    *   "Duplicate Page" is a basic fork.
    *   "Save as Template" allows its structure to be remixed into new pages.
    *   Users can freely change block types, content, and layout, expressing their will over the page's form.
*   **`AgentConfiguration`:**
    *   Users can fork an existing configuration to tweak its YAML for a new purpose.
    *   They can change the underlying `AgentDefinition` if they want to radically alter its behavior but keep some parameters.
    *   The `yaml_config` itself is the prime canvas for "Will to Power" over an agent's behavior.
*   **`AgentDefinition` (Marketplace Templates):**
    *   Users can "Fork this Agent Definition" to create their own private, modifiable version where they can alter the base prompt, input/output schemas (advanced), or core logic if the system architecture permits modification of the definition's executable code/script (a very advanced feature).
*   **`Brand` / `Creator`:** Less about forking the entity itself, but the associated assets (campaign pages, agent configurations used for them) are highly forkable.
*   **Workflows:** An entire workflow can be duplicated ("Forked") and then customized for a new client, product launch, or time period. Users can swap out agents, edit pages, and change connections within the forked workflow.
*   **`ChatMessage`:** Individual messages are not typically forked. However, a conversation or thread that leads to an idea could be "Forked to Canvas" – creating a new Canvas page with the chat content embedded or summarized, ready for further development.
*   **`Prompt`:** Users can fork prompts from a library, customize the text and variables for specific needs, and save them as new prompts.

---

By embedding these Nietzschean principles into the UI, system behaviors, and data models, IONFLUX aims to create a dynamic, empowering, and resilient user experience that values user agency and the evolution of work.

---
## 8. FREE-10 Agents Package & Monetization Stubs
(Content from `monetization_and_free_tier_scope.md`)

# IONFLUX Project: FREE-10 Agents Package & Monetization Stubs

This document outlines the scope for the initial "FREE-10 Agents" package and the conceptual stubs for platform monetization, drawing from the project proposal and previously defined documents like `core_agent_blueprints.md` and `conceptual_definition.md`.

## 1. "FREE-10 Agents" Package

This package aims to provide significant initial value to users, showcasing core IONFLUX capabilities across automation, insights, and content assistance.

**1.1. List of the 10 Agents (from Project Proposal Section 5):**

1.  **`Email Wizard`**
2.  **`WhatsApp Pulse`**
3.  **`TikTok Stylist`** (Already blueprinted)
4.  **`Shopify Sales Sentinel`** (Already blueprinted)
5.  **`UGC Matchmaker`** (Already blueprinted, TikTok Focus for Beta)
6.  **`Outreach Automaton`**
7.  **`Slack Brief Butler`** (Already blueprinted, can be generalized to "Chat Brief Butler")
8.  **`Persona Guardian`**
9.  **`Badge Motivator`**
10. **`Revenue Tracker Lite`** (Already blueprinted, Shopify Focus for Beta)

**1.2. Brief Purpose for the 5 Non-Blueprinted Agents:**

*   **1. `Email Wizard`:**
    *   **Purpose & Value:** Assists users in drafting various types of emails, such as responses to customer inquiries, marketing outreach messages, or follow-up sequences, by leveraging LLM capabilities based on user prompts or templates. This saves time and helps maintain consistent communication quality.
*   **2. `WhatsApp Pulse`:**
    *   **Purpose & Value:** (Requires WhatsApp Business API integration) Monitors connected WhatsApp channels for keywords, sentiment shifts, or high message volume, providing summaries or alerts to help users stay on top of important conversations or customer service issues without constant manual checking.
*   **6. `Outreach Automaton`:**
    *   **Purpose & Value:** Helps users organize, track, and manage multi-step outreach campaigns across different channels (e.g., email, potentially social DMs if APIs allow). It provides reminders for follow-ups and an overview of campaign status, improving efficiency and effectiveness of outreach efforts.
*   **8. `Persona Guardian`:**
    *   **Purpose & Value:** Monitors brand mentions (if a social listening integration is added) or analyzes content drafts (from Canvas or Chat) against a pre-defined brand persona (e.g., tone, style, keywords to avoid/use). This helps maintain brand consistency across all communications and content.
*   **9. `Badge Motivator`:**
    *   **Purpose & Value:** A gamification agent that awards users or workspace members virtual badges for achieving milestones, completing tasks, utilizing IONFLUX features effectively, or collaborating successfully. This encourages platform engagement, learning, and positive team dynamics.

**1.3. Rationale for the Package:**

This selection of 10 agents offers a compelling free tier by:

*   **Showcasing Core IONFLUX Pillars:** It touches upon e-commerce integration (Shopify), social media assistance (TikTok), communication aids (Email, WhatsApp, Chat Briefs), organizational tools (Outreach), brand management (Persona), and platform engagement (Badges).
*   **Providing Immediate Utility:** Agents like `Shopify Sales Sentinel`, `Revenue Tracker Lite`, and `Slack Brief Butler` offer quick, tangible benefits by automating monitoring and summarization tasks.
*   **Encouraging Exploration & Creativity:** Creative agents like `TikTok Stylist` and utility agents like `Email Wizard` encourage users to explore LLM-powered assistance and discover new ways to enhance their workflows.
*   **Demonstrating Breadth and Integration:** The variety gives a taste of IONFLUX's potential as a central command center that integrates various external services and internal tools.
*   **Path to Paid Features & Monetization:** While useful, the "Lite" or focused nature of some free agents (e.g., `Revenue Tracker Lite`) naturally suggests more advanced capabilities, higher usage limits, or more sophisticated versions available in paid tiers or through the "Rent-an-Agent" marketplace. The package also introduces users to concepts like brand persona management (`Persona Guardian`) and outreach (`Outreach Automaton`), which can have more powerful paid counterparts.

## 2. Monetization Stubs (Conceptual Outline)

These are initial concepts for how IONFLUX will generate revenue beyond simple subscriptions (which are assumed to be a primary model for offering varying levels of resource access, agent counts beyond the free tier, etc.).

**2.1. 2% Transactional Fee:**

*   **Applicability:**
    *   This fee is primarily intended to apply to transactions directly facilitated or brokered by the IONFLUX platform, specifically where IONFLUX plays an active role in connecting parties or enabling a financial exchange.
    *   **Initial Target:** Brand-Creator collaborations initiated and managed through an IONFLUX workflow that includes discovery (e.g., via `UGC Matchmaker`), negotiation/agreement (potentially via a dedicated Canvas template or chat flow), and deliverable submission/acceptance.
    *   **Future Considerations:** Could extend to other types of transactions if IONFLUX introduces features like a "services marketplace" where users sell services (e.g., custom agent configurations, consulting) to each other within the platform.
*   **Data Points/Entities Needed (Conceptual):**
    *   **`PlatformTransaction` (New Entity - as previously defined, consistent with `conceptual_definition.md` if extended):**
        *   `id: string (UUID)`
        *   `workspace_id: string (references Workspace.id)`
        *   `type: string (enum: 'creator_collaboration', 'service_sale', 'agent_rental_payout')`
        *   `status: string (enum: 'pending', 'agreed', 'in_progress', 'completed', 'disputed', 'cancelled', 'payout_processed')`
        *   `initiating_user_id: string (references User.id)`
        *   `paying_user_id: string (references User.id, for rental or service sale)`
        *   `receiving_user_id: string (references User.id, for rental payout or service sale)`
        *   `counterparty_brand_id: string (references Brand.id, nullable)`
        *   `counterparty_creator_id: string (references Creator.id, nullable)`
        *   `ionflux_workflow_id: string (nullable, references a future "Workflow" entity)`
        *   `related_agent_config_id: string (nullable, references AgentConfiguration.id)`
        *   `related_marketplace_listing_id: string (nullable, references AgentMarketplaceListing.id)`
        *   `transaction_description: text`
        *   `gross_amount: decimal`
        *   `currency: string (e.g., 'USD')`
        *   `transaction_date: timestamp`
        *   `ionflux_fee_percentage: decimal (e.g., 0.02 for collaborations, 0.15 for rentals)`
        *   `ionflux_fee_amount: decimal (calculated)`
        *   `net_amount_due_recipient: decimal (calculated)`
        *   `payment_processor_reference_id: string (nullable)`
        *   `payout_reference_id: string (nullable)`
        *   `created_at: timestamp`
        *   `updated_at: timestamp`
    *   **Updates to `User` or `Workspace`:** May need fields to link to payment provider details (e.g., Stripe Connect Account ID stored in `User.profile_info` or a dedicated `UserPaymentProfile` table) if IONFLUX facilitates payouts. `User.stripe_customer_id` already exists for future billing.
*   **Service Interaction (High-Level):**
    *   A dedicated **`BillingService` or `MonetizationService`** would be responsible.
    *   This service would:
        *   Receive events or API calls from other services (e.g., `AgentService` when a `UGC Matchmaker` flow leads to an agreement, `CanvasService` if a "collaboration agreement" block is finalized, or a future `MarketplaceService` for agent rentals).
        *   Create and manage `PlatformTransaction` records.
        *   Integrate with a payment processor (e.g., Stripe Connect) to handle payments from buyers/renters and payouts to sellers/listers, automatically deducting the IONFLUX fee.
        *   `UserService` and `WorkspaceService` would provide context on users and their payment/billing status.

**2.2. "Rent-an-Agent" Marketplace (15% Commission):**

*   **Marketplace Listing Concept:**
    *   Users (typically advanced users, agencies, or developers) can list their highly customized and effective `AgentConfiguration`s or specially crafted `AgentDefinition`s (if the platform allows custom definition creation beyond simple configuration) for other users to "rent."
    *   **`AgentMarketplaceListing` (New Entity - as previously defined):**
        *   `id: string (UUID)`
        *   `lister_user_id: string (references User.id)`
        *   `lister_workspace_id: string (references Workspace.id)`
        *   `agent_configuration_id: string (references AgentConfiguration.id, if listing a specific pre-configured instance whose YAML is hidden from renter)`
        *   `agent_definition_id: string (references AgentDefinition.id, if listing a more generic template the renter configures minimally based on exposed schema)`
        *   `listing_title: string`
        *   `listing_description: text`
        *   `category: string (e.g., 'Advanced SEO', 'Shopify Optimization Pro')`
        *   `tags: [string]`
        *   `rental_model: string (enum: 'per_run', 'time_period_subscription')`
        *   `price_per_run: decimal (nullable)`
        *   `price_per_month: decimal (nullable)` // Or other time units like 'weekly', 'quarterly'
        *   `currency: string (e.g., 'USD')`
        *   `usage_instructions: text`
        *   `input_schema_overview: json (summary of what renter needs to provide if any, derived from AgentDefinition.input_schema)`
        *   `output_preview_sample: json (example of what the agent produces, from AgentDefinition.output_schema)`
        *   `status: string (enum: 'draft', 'active', 'paused', 'archived', 'under_review')`
        *   `average_rating: float (nullable)`
        *   `total_rentals: integer (default: 0)`
        *   `created_at: timestamp`
        *   `updated_at: timestamp`
*   **Rental Process (Conceptual):**
    1.  **Discovery:** Renter browses the "Rent-an-Agent" section of the Marketplace. Filters by category, rating, price.
    2.  **Selection:** Renter chooses an `AgentMarketplaceListing`. Reviews description, input/output schema, pricing.
    3.  **Payment:** Renter pays the rental fee through IONFLUX (which uses a payment processor). This creates an `AgentRentalAgreement` and its associated `PlatformTransaction`.
    4.  **Access Granted:**
        *   The `AgentService` grants the renter's workspace execute-only access to the underlying `AgentConfiguration` or the ability to instantiate from the rented `AgentDefinition` for the agreed duration or number of runs.
        *   The core intellectual property (detailed YAML of a rented `AgentConfiguration`, or the full logic of a rented `AgentDefinition`) is not directly exposed to the renter unless the lister explicitly chooses a more open model (e.g. "template with source").
    5.  **Usage:** Renter uses the agent via their `Agent Snippet` blocks or `/commands` like any other agent they own, but with usage tracked against their `AgentRentalAgreement`.
*   **Commission Calculation:**
    *   IONFLUX charges a 15% commission on the gross rental fee collected from the renter.
    *   The `PlatformTransaction` record associated with the rental would reflect this: `gross_amount` is the rental price, `ionflux_fee_percentage` is 0.15, `ionflux_fee_amount` is calculated, and `net_amount_due_recipient` is what the lister receives.
*   **Data Points/Entities Needed (Conceptual):**
    *   `AgentMarketplaceListing` (as above)
    *   **`AgentRentalAgreement` (New Entity - as previously defined):**
        *   `id: string (UUID)`
        *   `listing_id: string (references AgentMarketplaceListing.id)`
        *   `renter_user_id: string (references User.id)`
        *   `renter_workspace_id: string (references Workspace.id)`
        *   `lister_user_id: string (references User.id)` // Added for clarity
        *   `rented_agent_instance_id: string (nullable, if a temporary AgentConfiguration is created for the renter based on the listing)`
        *   `rental_start_date: timestamp`
        *   `rental_end_date: timestamp (nullable, for time-period rentals)`
        *   `runs_purchased: integer (nullable, for per-run rentals)`
        *   `runs_consumed: integer (default: 0)`
        *   `status: string (enum: 'active', 'expired', 'cancelled_by_renter', 'cancelled_by_lister')`
        *   `platform_transaction_id: string (references PlatformTransaction.id)` // Link to the financial transaction
    *   `PlatformTransaction` (as defined in section 2.1, with `type='agent_rental_payment'` for renter payment and `type='agent_rental_payout'` for lister payout).
*   **Service Interaction (High-Level):**
    *   **`MarketplaceService` (Potentially a new service or part of AgentService):** Manages CRUD operations for `AgentMarketplaceListing`s, handles search/discovery, and reviews/ratings.
    *   **`AgentService`:**
        *   Manages the secure execution access for rented agents (e.g., creating temporary, restricted `AgentConfiguration` instances for the renter or applying permissions).
        *   Tracks `runs_consumed` on `AgentRentalAgreement`.
    *   **`BillingService` / `MonetizationService`:**
        *   Processes rental payments from renters via a payment gateway.
        *   Creates `PlatformTransaction` records for rentals and payouts.
        *   Manages payouts to listers after deducting the commission.
    *   `UserService` and `WorkspaceService` provide context for listers and renters.

These monetization stubs are conceptual and would require significant further design for security (protecting listers' IP), payment processing integration, dispute resolution, taxation, and ensuring fair use policies.

---
## 9. Preliminary Technical Stack & E2E Demo Strategy
(Content from `technical_stack_and_demo_strategy.md`)

# IONFLUX Project: Preliminary Technical Stack & E2E Demo Strategy

This document outlines a preliminary technical stack proposal for IONFLUX and defines a strategy for an initial End-to-End (E2E) demo, drawing upon all previously generated design documents.

## 1. Preliminary Technical Stack Proposal

This stack is proposed with scalability, performance, developer productivity, and suitability for AI/ML and real-time features in mind.

**1.1. Frontend:**

*   **Primary Framework: React (with Next.js)**
    *   **Justification:**
        *   **Rich Ecosystem & Community:** Large talent pool, extensive libraries (state management like Redux/Zustand, UI components like Material UI/Chakra UI), and strong community support.
        *   **Component-Based Architecture:** Aligns well with IONFLUX's modular UI (Canvas blocks, sidebar sections).
        *   **Performance:** Next.js offers server-side rendering (SSR), static site generation (SSG), image optimization, and route pre-fetching, contributing to a fast user experience.
        *   **Developer Experience:** Features like Fast Refresh in Next.js improve productivity.
        *   **TypeSafety:** Strong TypeScript support is well-integrated.
*   **Alternative/Consideration: Svelte (with SvelteKit)**
    *   **Justification:** Known for its performance (compiles to vanilla JS), smaller bundle sizes, and potentially simpler state management for certain use cases. Could be considered for highly interactive parts like the Canvas if React performance becomes a concern, or for specific micro-frontends.

**1.2. Backend (Microservices):**

A polyglot approach is feasible, but consistency in core areas is beneficial.

*   **Primary Choice: Python with FastAPI (and associated libraries like LangChain, LangGraph, Pydantic)**
    *   **Services:** Python with FastAPI (and associated libraries like LangChain, LangGraph, Pydantic) is the **strongly preferred primary choice** for most microservices, especially those involving agent logic, LLM interactions, and complex data processing, as reflected in the detailed agent blueprints. This includes services like `Agent Service`, `LLM Orchestration Service`, `Shopify Integration Service`, `TikTok Integration Service`, and any services directly implementing core agent functionalities.
    *   **Justification:**
        *   **AI/ML Ecosystem:** Python's extensive libraries for AI/ML (e.g., Hugging Face Transformers, Langchain, spaCy) are invaluable for agent development and LLM interaction. The consistent use of Python 3.12+, FastAPI, LangChain, and LangGraph across all 10 core agent blueprints underscores its suitability for building the agentic capabilities of IONFLUX.
        *   **Async Capabilities:** FastAPI is built on Starlette and Pydantic, offering excellent support for asynchronous programming, crucial for I/O-bound tasks like calling external APIs (LLMs, Shopify, TikTok).
        *   **Performance:** FastAPI is one of the fastest Python frameworks.
        *   **Developer Productivity:** Automatic data validation, serialization, and API documentation (Swagger/OpenAPI) speed up development.
        *   **Ease of Learning:** Python's readability is generally high.
*   **Secondary Choice: Node.js with Express.js/NestJS**
    *   **Services:** `User Service`, `Workspace Service`, `Canvas Service`, `Chat Service`, `Notification Service`.
    *   **Justification:**
        *   **Real-time Communication:** Node.js excels at handling real-time, concurrent connections (WebSockets for Chat, Canvas collaboration).
        *   **I/O Throughput:** Excellent for services that are primarily I/O bound and require high concurrency (e.g., managing many simultaneous chat connections or canvas updates).
        *   **JavaScript Ecosystem:** Can share code/types with the frontend if using TypeScript across the stack. NestJS offers a more structured, opinionated framework similar to Angular.
*   **Alternative for Specific High-Performance Needs: Go**
    *   **Services:** Potentially `API Gateway` components, or core parts of `Chat Service` if extreme concurrency is needed.
    *   **Justification:** Excellent performance, concurrency model (goroutines), and low memory footprint. Steeper learning curve than Python/Node.js for many teams.

**1.3. Databases:**

*   **Primary Relational Database: PostgreSQL**
    *   **Justification:** Robust, feature-rich (JSONB support, full-text search, extensibility), highly scalable, and strong community support. ACID compliant.
    *   **Data Types:** Core transactional data, user accounts (`User`), workspaces (`Workspace`), brand/creator profiles (`Brand`, `Creator`), prompt libraries (`PromptLibrary`, `Prompt`), agent configurations (`AgentConfiguration`, `AgentDefinition`), canvas structure (`CanvasPage`, `CanvasBlock` core attributes), chat channels (`ChatDockChannel`), financial records (`PlatformTransaction`, `AgentRentalAgreement`). Basically, most structured data where relationships and consistency are key. Individual agents may also utilize dedicated PostgreSQL tables or schemas for their specific structured data storage needs (e.g., `email_wizard_emails` for the Email Wizard, `whatsapp_pulse_playbooks` for WhatsApp Pulse), complementing the main platform PostgreSQL database used for shared entities.
*   **NoSQL Options:**
    *   **MongoDB (Document Store):**
        *   **Justification:** Flexible schema, good for storing denormalized data or rapidly evolving structures.
        *   **Data Types:** Potentially `ChatMessage` content (if highly variable or large), `CanvasBlock.content` (especially for complex, nested JSON structures within blocks), agent run outputs (`AgentConfiguration.last_run_output` if large and unstructured), temporary user session data.
    *   **Elasticsearch (Search Engine & Document Store):**
        *   **Justification:** Powerful full-text search capabilities, analytics, and logging.
        *   **Data Types:** Indexing content from `CanvasPage`s, `ChatMessage`s, `Prompt`s for the Command Palette search. Storing application logs for analysis and monitoring. Potentially for advanced analytics on agent outputs or user activity.
    *   **Redis (In-Memory Key-Value Store):**
        *   **Justification:** Extremely fast for caching (e.g., external API responses, LLM prompts/completions), session management, rate limiting, real-time presence information, and as a message broker for many internal agent task queues (e.g., using **RQ (Redis Queue)** or **Redis Streams** as indicated in agent blueprints).
        *   **Data Types:** Session tokens, cached API responses from external services, real-time presence information (Chat/Canvas), queue for notifications and agent tasks.
    *   **Vector Database: Pinecone**
        *   **Justification:** Chosen as the primary Vector Database for agents requiring Retrieval Augmented Generation (RAG) capabilities, embedding storage, and semantic search, as specified for agents like `Creator Persona Guardian` and `Slack Brief Butler`. Pinecone is managed and scalable, fitting well with the microservice architecture.
        *   **Data Types:** Vector embeddings of documents, chat histories, brand guidelines, content pieces for semantic search and RAG by various agents.

**1.4. Message Broker Strategy:**

A hybrid approach to messaging and task queuing is anticipated, leveraging the strengths of different technologies based on specific needs observed in agent designs:
*   **Redis (with RQ or Redis Streams):** For many internal agent task queues and inter-service communication. Its widespread mention in agent blueprints (e.g., for `Outreach Automaton`, `Email Wizard`) for background task processing makes it a primary choice for typical asynchronous operations within the platform due to its simplicity and performance.
*   **Apache Kafka:** Reserved for scenarios requiring very high-throughput, persistent, ordered event streams, and where its log-streaming capabilities are beneficial. An example is handling `shop-orders` events for the `Shopify Sales Sentinel` agent, which needs to process a potentially large and critical stream of events reliably.
*   **Justification:** This approach allows for the operational simplicity of Redis-based queues for common tasks while retaining the power of Kafka for specialized, high-volume data streams. This aligns with the diverse needs of the agent ecosystem.

**1.5. API Gateway:**

*   **Suggestion: Kong API Gateway (or a cloud provider's managed gateway like AWS API Gateway, Google Cloud API Gateway)**
    *   **Justification (Kong):** Open-source, feature-rich (routing, authentication, rate limiting, transformations, plugins), Kubernetes-native. Can be deployed on-prem or in any cloud.
    *   **Justification (Cloud Managed):** Reduces operational overhead, integrates well with other cloud services (IAM, logging).
    *   The API Gateway will handle routing requests to the appropriate microservices, initial authentication/authorization, rate limiting, and request/response transformations.

**1.6. Deployment & Infrastructure:**

*   **Containerization: Docker & Kubernetes (K8s)**
    *   **Justification:** Standard for deploying and managing microservices. Docker for packaging applications, Kubernetes for orchestration, scaling, and resilience.
*   **Cloud Provider: Flexible (AWS, GCP, or Azure are all suitable)**
    *   The choice can be driven by existing team expertise, specific managed service offerings (e.g., managed K8s, databases, AI services), or cost considerations. The architecture should aim to be cloud-agnostic where possible, relying on Kubernetes to abstract underlying infrastructure.
    *   Initial preference might lean towards a provider with strong managed Kubernetes (EKS, GKE, AKS) and serverless function offerings for certain tasks.

**1.7. Real-time Communication:**

*   **Confirmation: WebSockets**
    *   For `Chat Service` and real-time collaboration features in `Canvas Service` (e.g., multi-user block editing, cursor presence). Node.js backend is well-suited for this.

**1.8. Observability & Operational Tooling Strategy:**

A comprehensive observability stack is critical for monitoring, debugging, and ensuring the reliability of the microservices and agent operations. The following tools, consistently mentioned in agent blueprints, will form the core of our internal observability strategy:
*   **OpenTelemetry:** For standardized generation of traces, metrics, and logs across all services.
*   **Prometheus:** For metrics collection and alerting.
*   **Grafana:** For visualization of metrics and logs (often paired with Prometheus and Loki).
*   **Loki:** For log aggregation and querying.
*   **Jaeger (or similar like Zipkin):** For distributed tracing.

This internal stack is distinct from any external SaaS monitoring services that might be used for broader application performance management but focuses on the detailed operational health of IONFLUX services.

Furthermore, the agent blueprints indicate the use of modern CI/CD and deployment practices. The platform's operational environment will be designed to support:
*   **CI/CD:** Tools like **GitHub Actions** for automated building, testing, and deployment.
*   **Containerization:** **Docker (with Buildx for multi-arch builds)** for packaging applications.
*   **Deployment Platforms:** Leveraging platforms like **Fly.io** or **Railway.app** for simplified deployment and management of containerized applications, alongside Kubernetes for more complex orchestration if needed.

## 2. End-to-End (E2E) Demo Flow & Prototyping Strategy

The detailed agent specifications in `core_agent_blueprints.md` provide rich context for the expected outputs and interactions at each stage of this demo flow, making the demonstration of agent value more concrete.

**2.1. Core User Journey for Demo:**

This journey aims to demonstrate the "Notion+Slack" hybrid, key agent interactions, and core platform value.

1.  **Onboarding & Setup:**
    *   User signs up, creates a Workspace ("My Marketing Agency").
    *   User connects their Shopify store (Brand: "My Test Store") – OAuth flow.
    *   User connects their TikTok account (Creator: "My Test Creator") – OAuth flow.
2.  **Canvas & Chat Interaction (Campaign Planning):**
    *   User creates a new `CanvasPage` titled "Q4 Holiday Campaign Plan."
    *   User adds a Text block: "Goal: Drive 20% more sales for Product X."
    *   User uses the `ChatDock` to discuss ideas with a team member (mocked or another user).
    *   User types `/run_agent Slack Brief Butler summarize_thread` in the chat. The agent posts a structured brief of the discussion. User copies this brief into a Text block on the Canvas.
3.  **Shopify Agent Integration:**
    *   User drags `Revenue Tracker Lite` agent from the "Agent Shelf" onto the Canvas. Configures it for "My Test Store" to show "Last 7 Days" data. The block populates with sales figures.
    *   User configures `Shopify Sales Sentinel` for "My Test Store" to alert on orders > $100. (Simulate a webhook event for a $150 order). A notification appears, and a message is posted to a designated chat channel.
4.  **TikTok Agent Integration:**
    *   User drags `TikTok Stylist` onto the Canvas. Configures it with keywords like "holiday gift ideas" and "fashion."
    *   User runs `TikTok Stylist`. The agent's snippet block on Canvas updates with trending sounds and hashtags.
    *   User drags `UGC Matchmaker` onto the Canvas. Configures it for "fashion" niche. Runs it. The block populates with a list of (mocked/example) TikTok creator handles.
5.  **Review & Action:**
    *   User reviews the populated Canvas page, which now contains the campaign brief, Shopify sales data, TikTok trends, and potential UGC creators.
    *   User uses the Chat Dock to assign tasks based on the gathered info.

**2.2. Key Screens/Interfaces to Mock/Build for Demo:**

*   **Login/Signup Screens**
*   **Workspace Dashboard/Switcher**
*   **Sidebar Navigation** (as per `ui_ux_concepts.md`)
*   **Canvas Page View:**
    *   Toolbar for adding blocks.
    *   Rendering of Text blocks, Agent Snippet blocks.
    *   Basic block manipulation (move, resize - simplified).
*   **Chat Dock:**
    *   Channel list, message view, message input.
    *   Display of user and agent messages (including formatted agent output).
    *   `/command` input with basic autocomplete.
*   **Agent Configuration Modal:**
    *   YAML editor view.
    *   Ability to name/describe agent instance and save.
*   **Agent Marketplace (Simplified View):** Showing cards for the demo agents.
*   **Brand/Creator Asset Connection Modals:** For Shopify & TikTok OAuth placeholders.
*   **Notifications Panel/Indicator.**

**2.3. Prototyping Tools/Approach (n8n + YAML focus):**

*   **n8n + YAML for Backend Logic/Agent Prototyping:**
    *   **n8n Workflows:** Use n8n (a workflow automation tool) to visually model the logic of several agents or inter-service communication for the demo. Each n8n workflow can represent a simplified microservice or an agent's core task.
        *   Example: An n8n workflow for `TikTok Stylist` could have nodes for:
            1.  HTTP Request (mocking call to `TikTok Integration Service` - returns canned JSON).
            2.  Function Node (JavaScript/Python to process data).
            3.  HTTP Request (mocking call to `LLM Orchestration Service` - returns canned text).
            4.  HTTP Request (to send results back to a mocked `Agent Service` endpoint).
    *   **YAML for Agent Configuration:** The `AgentConfiguration.yaml_config` will be real and stored (perhaps in a simple DB or even flat files for the demo's backend). The n8n workflows (acting as agents) would be triggered with references to these YAML configs, and the workflow logic would parse relevant parameters from the YAML to guide its execution (even if parts of that execution are mocked).
    *   This approach allows rapid iteration on agent logic (by modifying n8n workflows and YAML) without writing full microservice code for all agents initially.
    *   This n8n-based prototyping approach remains valid even with the detailed agent tech stacks specified in `core_agent_blueprints.md`. The n8n workflows will simulate the *external behavior and API interactions* of agents that would, in production, be built with technologies like Python/FastAPI and Pinecone, rather than n8n itself running that specific internal stack.
*   **Microservices Prototyping Strategy:**
    *   **Heavily Mocked/Simplified (using n8n/scripts):**
        *   `TikTok Integration Service`: Returns canned TikTok API responses.
        *   `LLM Orchestration Service`: Returns pre-defined text outputs for specific prompts.
        *   Most of the `Agent Service`'s complex orchestration logic can be represented by n8n workflows that are triggered via simple API calls.
        *   `Notification Service`: May just log to console or send a simple webhook to a mock UI.
    *   **Minimal Robust Implementation (Lean Service Shells):**
        *   `User Service`: Basic user registration, login (JWT), and retrieval.
        *   `Workspace Service`: CRUD for workspaces.
        *   `Agent Service (Core)`: CRUD for `AgentConfiguration` and `AgentDefinition` (storing YAML, names, etc.). Needs to trigger n8n workflows (or other scripts) representing agent execution.
        *   `Shopify Integration Service`: Needs to handle the OAuth callback and store tokens securely. API calls for the demo can return canned data for `Revenue Tracker Lite` but should process a *simulated* webhook for `Sales Sentinel` to show the E2E flow.
        *   `Canvas Service`: Basic CRUD for `CanvasPage` and `CanvasBlock` (storing type, content - especially `agent_config_id` for snippet blocks).
        *   `Chat Service`: Basic CRUD for channels and messages. Needs to parse `/commands` and trigger `Agent Service` (or its n8n workflow endpoint). Needs WebSocket connection for sending/receiving messages.
*   **Frontend:** Build the key UI screens using React/Next.js, focusing on the interaction flows. API calls from the frontend would go to the minimal robust service shells or n8n webhook triggers.

**2.4. Focus of the Demo:**

*   **Validate the core User Experience:** Demonstrate the hybrid "Notion+Slack" interaction model, focusing on the Canvas and Chat Dock as primary work hubs.
*   **Showcase Agent Capabilities & Interaction:** Illustrate how users discover, configure (via YAML), and run agents, and how agents deliver value within the Canvas and Chat.
*   **Demonstrate Key Integrations (Conceptually & Partially):** Show the Shopify connection flow and a simulated Shopify event. Show the TikTok agent flow with mocked data.
*   **Illustrate Data Flow:** Show how information from one part of the system (e.g., chat discussion) can be processed by an agent and appear elsewhere (e.g., Canvas).
*   **Gather Early Feedback:** On the core concepts, usability, and perceived value of the integrated agent experience.

This strategy prioritizes demonstrating the user-facing value and core interaction patterns while deferring full implementation of all backend complexities, using n8n and mocks for rapid prototyping of agent logic.

---
## 10. Conclusion & Next Steps

This Initial Design Document (v2) consolidates the refined vision and foundational specifications for the IONFLUX platform. It incorporates detailed architectural concepts, data models, UI/UX paradigms, SaaS integration strategies, comprehensive blueprints for ten core agents, agent interaction models, unique Nietzschean UX principles, preliminary monetization ideas, and an updated technical stack and E2E demo strategy.

This updated document is now ready for stakeholder and user review. The feedback gathered will be crucial for guiding the subsequent phases of development, starting with the implementation of the End-to-End (E2E) demo and progressing towards the Minimum Viable Product (MVP). The specifications herein aim to provide a clear roadmap for building a powerful, intuitive, and uniquely adaptable platform for brands and creators.
