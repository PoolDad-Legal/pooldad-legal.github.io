# IONFLUX - Initial Design Document

## 1. Introduction

This document consolidates the initial design specifications for the IONFLUX project. Its purpose is to provide a comprehensive overview of the project's vision, core architecture, user experience concepts, technical stack, and initial feature set, serving as a foundational guide for subsequent development phases.

IONFLUX is envisioned as an AI-native command center for brands and creators, blending the collaborative flexibility of platforms like Notion with the communication immediacy of tools like Slack. It aims to empower users by integrating powerful AI agents, seamless SaaS connections (Shopify, TikTok, etc.), and a dynamic Canvas interface, all underpinned by unique Nietzschean UX principles that emphasize evolution, recurrence, and user agency. This document details the conceptual framework and initial blueprints intended to bring this vision to life, starting with a compelling free tier and outlining paths for future monetization and platform growth.

---

## 2. Core Architecture & Data Models
*(Derived from `conceptual_definition.md`)*

### 2.1. Proposed Core Architecture

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

### 2.2. Primary Data Schemas (Conceptual)

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

### 2.3. API Interaction Concepts (High-Level)

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
*(Derived from `ui_ux_concepts.md`)*

This section outlines the foundational UI/UX concepts for the IONFLUX platform.

### 3.1. Sidebar Navigation

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

### 3.2. Canvas

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

### 3.3. Chat Dock

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

### 3.4. Command Palette (⌘K / Ctrl+K)

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

### 3.5. Core User Flows

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
*(Derived from `saas_api_integration_specs.md`)*

This section details the specifications for integrating third-party SaaS platforms and APIs into the IONFLUX ecosystem, focusing on the initial set required for beta.

### 4.1. LLM Provider Integration (`LLM Orchestration Service`)

The `LLM Orchestration Service` will act as a central hub for all Large Language Model interactions, providing a unified interface for other IONFLUX services.

**4.1.1. Primary Provider Choice (for Beta):**

*   **Recommendation:** **OpenAI**
*   **Justification:**
    *   **Mature API:** OpenAI offers a well-documented, robust, and feature-rich API.
    *   **Model Variety & Capability:** Access to a wide range of models (e.g., GPT-3.5-turbo, GPT-4, Embeddings) suitable for diverse tasks outlined in the IONFLUX proposal.
    *   **Strong Developer Ecosystem:** Extensive community support, libraries, and resources are available, potentially speeding up development.
    *   **Performance:** Generally good performance in terms of response quality and latency for many common use cases.
    *   While other providers like Anthropic (Claude) or Google (Gemini) are strong contenders, OpenAI's current overall maturity and widespread adoption make it a pragmatic choice for the initial beta to ensure rapid development and a broad feature set. This choice can be expanded later.

**4.1.2. API Key Management Strategy:**

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

**4.1.3. Core Request/Response Structure (Internal):**

This defines the internal API contract between services like `Agent Service` and the `LLM Orchestration Service`.

*   **Request to `LLM Orchestration Service`:**
    ```json
    {
      "provider": "string (e.g., 'openai', 'claude', 'gemini', defaults to 'openai')", // Optional, defaults to primary
      "model": "string (e.g., 'gpt-3.5-turbo', 'claude-2', 'gemini-pro')", // Specific model identifier
      "prompt": "string", // The actual prompt text
      "system_prompt": "string (optional)", // System-level instructions for the model
      "history": [ // Optional: for conversational context
        { "role": "user", "content": "Previous message" },
        { "role": "assistant", "content": "Previous response" }
      ],
      "parameters": { // Model-specific parameters
        "max_tokens": "integer (optional)",
        "temperature": "float (optional, 0.0-2.0)",
        "top_p": "float (optional, 0.0-1.0)",
        "stop_sequences": ["string (optional)"],
        // ... other provider-specific parameters
      },
      "user_id": "string (UUID, references User.id, for tracking/auditing/cost-attribution)",
      "workspace_id": "string (UUID, references Workspace.id, for policy/key selection)",
      "request_id": "string (UUID, for logging and tracing)" // Added for better traceability
    }
    ```

*   **Response from `LLM Orchestration Service`:**
    *   **Success:**
        ```json
        {
          "status": "success",
          "request_id": "string (UUID, mirrors request)",
          "provider_response": { // Raw or lightly processed response from the LLM provider
            "id": "string (provider's response ID)",
            "choices": [
              {
                "text": "string (generated text)", // Or "message": {"role":"assistant", "content":"..."} for chat models
                "finish_reason": "string (e.g., 'stop', 'length', 'content_filter')"
                // ... other provider-specific choice data
              }
            ],
            "usage": { // Standardized usage information
              "prompt_tokens": "integer",
              "completion_tokens": "integer",
              "total_tokens": "integer"
            }
            // ... other provider-specific metadata
          }
        }
        ```
    *   **Error:**
        ```json
        {
          "status": "error",
          "request_id": "string (UUID, mirrors request)",
          "error": {
            "code": "string (internal error code, e.g., 'PROVIDER_API_ERROR', 'INVALID_REQUEST', 'QUOTA_EXCEEDED')",
            "message": "string (user-friendly error message)",
            "provider_error": "object (optional, raw error from LLM provider if available)"
          }
        }
        ```

### 4.2. Shopify Integration (`Shopify Integration Service`)

This service will handle all communications with the Shopify platform.

**4.2.1. Authentication:**

*   **Flow:** Standard **OAuth 2.0 Authorization Code Grant Flow**.
    1.  User (Brand owner/admin) initiates connection from IONFLUX (e.g., in Brand settings).
    2.  IONFLUX redirects the user to their Shopify store's authorization prompt (`https://{store_name}.myshopify.com/admin/oauth/authorize?...`).
        *   Parameters: `client_id` (IONFLUX's Shopify App API key), `scope` (requested permissions), `redirect_uri` (back to `Shopify Integration Service`), `state` (CSRF token).
    3.  User approves the installation/scopes on Shopify.
    4.  Shopify redirects back to `redirect_uri` with an `authorization_code` and the `shop` name.
    5.  `Shopify Integration Service` exchanges the `authorization_code` (along with API key/secret) for an **access token** from Shopify (`https://{store_name}.myshopify.com/admin/oauth/access_token`).
*   **Access Token Storage:**
    *   The permanent access token received from Shopify will be stored securely.
    *   It will be associated with the `Brand.id` (or a dedicated `ShopifyConnection` entity linked to the Brand).
    *   Storage method: Encrypted (e.g., AES-256) in the database. The encryption key will be managed by a central secrets management service.
*   **Token Usage:** The stored access token will be used in the `X-Shopify-Access-Token` header for all subsequent API requests to that Shopify store.

**4.2.2. Key Shopify APIs & Data Points:**

*   **Admin API (primarily REST, some GraphQL if beneficial):**
    *   **Products:** `GET /admin/api/2023-10/products.json`
        *   Fields: `id`, `title`, `handle`, `status`, `vendor`, `product_type`, `created_at`, `updated_at`, `tags`, `variants` (price, sku), `images`.
    *   **Orders:** `GET /admin/api/2023-10/orders.json` (need to be careful with PII)
        *   Fields for `Revenue Tracker Lite`: `id`, `name`, `created_at`, `total_price`, `financial_status`, `fulfillment_status`, `currency`, `line_items` (product_id, quantity, price).
        *   Fields for `Shopify Sales Sentinel`: Order status changes, new orders.
    *   **Customers:** `GET /admin/api/2023-10/customers.json` (handle PII carefully, only fetch if essential for an agent's function).
        *   Fields: `id`, `email`, `first_name`, `last_name`, `orders_count`, `total_spent`.
    *   **Shop:** `GET /admin/api/2023-10/shop.json`
        *   Fields: `id`, `name`, `currency`, `domain`, `iana_timezone`.
    *   **Webhooks:** `POST /admin/api/2023-10/webhooks.json`, `GET /admin/api/2023-10/webhooks.json`, `DELETE /admin/api/2023-10/webhooks/{webhook_id}.json`.
    *   **Discount Codes:** (Future consideration for agents that might create discounts) `GET /admin/api/2023-10/price_rules.json`, `POST /admin/api/2023-10/price_rules/{price_rule_id}/discount_codes.json`.
*   **Storefront GraphQL API:**
    *   May not be essential for Beta if Admin API covers needs. Could be used for less sensitive, publicly accessible data if an agent needs to see the store "as a customer."
    *   Example: Fetching product details, collections for display or analysis without needing full admin rights.
*   **Data for `Shopify Sales Sentinel` & `Revenue Tracker Lite`:**
    *   `Revenue Tracker Lite`: Primarily aggregated sales data (total sales, average order value, sales over time) from `Orders`. Product performance (sales per product) from `Orders` and `Products`.
    *   `Shopify Sales Sentinel`: Real-time or near real-time notification of new sales, significant order values, inventory changes for key products. This heavily relies on webhooks or frequent polling of `Orders` and `Products`.

**4.2.3. Webhook Subscriptions:**

The `Shopify Integration Service` will dynamically subscribe to these webhooks for each connected store. The webhook endpoint will be a dedicated route within the `Shopify Integration Service`.

*   `orders/create`: Triggered when a new order is created. (Essential for Sales Sentinel)
*   `orders/updated`: Triggered when an order is updated (e.g., payment status, fulfillment). (Essential for Sales Sentinel)
*   `orders/paid`: Triggered when an order is marked as paid.
*   `orders/fulfilled`: Triggered when an order is fulfilled.
*   `products/create`: Triggered when a new product is created.
*   `products/update`: Triggered when a product is updated (e.g., inventory, price). (Important for Sales Sentinel if tracking specific products)
*   `app/uninstalled`: CRITICAL. Triggered when the user uninstalls the IONFLUX app from their Shopify store. The service must:
    *   Invalidate/delete the stored access token.
    *   Clean up any associated data for that store.
    *   Notify the user/workspace within IONFLUX.
*   `shop/update`: For changes in shop settings like currency.

**4.2.4. Data Sync Strategy:**

*   **Primary Method: Webhooks.** For near real-time updates (e.g., `orders/create`, `products/update`), webhooks are preferred. This makes agents like `Shopify Sales Sentinel` responsive.
*   **Secondary Method: Polling.** For initial data backfill upon connection, or for data not covered by webhooks, periodic polling will be used.
    *   Frequency will depend on the data type and importance (e.g., orders might be polled more frequently than general product catalog updates if webhooks fail).
    *   Implement intelligent polling to respect Shopify API rate limits (use leaky bucket algorithm).
*   **Data Freshness:**
    *   For event-driven agents (Sales Sentinel): As real-time as webhooks allow.
    *   For analytical agents/blocks (Revenue Tracker Lite): Can tolerate some delay (e.g., updated every few hours or on-demand refresh). Canvas blocks displaying Shopify data should indicate the last sync time.
*   The `Shopify Integration Service` will need a robust queueing and processing mechanism for incoming webhooks to handle bursts and ensure reliability.

### 4.3. TikTok Integration (`TikTok Integration Service`)

This service will manage interactions with TikTok APIs.

**4.3.1. Authentication:**

*   **Flow:** Standard **OAuth 2.0 Authorization Code Grant Flow** provided by TikTok.
    1.  User (Brand/Creator) initiates connection from IONFLUX.
    2.  IONFLUX redirects user to TikTok's OAuth server.
        *   Parameters: `client_key` (IONFLUX's TikTok App ID), `scope`, `redirect_uri`, `state`.
    3.  User logs in and authorizes requested permissions on TikTok.
    4.  TikTok redirects back to `redirect_uri` with an `authorization_code`.
    5.  `TikTok Integration Service` exchanges the `code` for an `access_token`, `refresh_token`, and `open_id` (user identifier).
*   **Access Token Storage:**
    *   `access_token`, `refresh_token`, `expires_in`, and `open_id` stored securely, associated with the `Brand.id` or `Creator.id`.
    *   Storage: Encrypted in the database, encryption key managed by secrets service.
*   **Token Refresh:** The service must implement logic to use the `refresh_token` to obtain new `access_token`s before they expire.

**4.3.2. Key TikTok APIs & Data Points:**

*   **API Choice:**
    *   **TikTok for Business API (Marketing API):** More focused on advertising and campaign management. May be useful for some agents but has stricter access requirements.
    *   **TikTok Developer API / TikTok Login Kit:** More suitable for general data access, content posting (if available to app type), and user profile information. **This is likely the primary API for beta features.**
    *   Clarity on which specific API IONFLUX applies for and gets approved for is crucial, as capabilities differ.
*   **Data for `TikTok Stylist`:**
    *   **Trending Content:**
        *   `GET /v2/research/video/query/` (from TikTok Developer API - if approved for research capabilities): To search for videos by keywords, hashtags, potentially identify trending sounds used in those videos.
        *   Manual or semi-automated tracking of TikTok's public "Trending" sections might be needed as a fallback or supplement, as direct "trending sounds" APIs can be limited.
    *   **Hashtags:**
        *   `GET /v2/research/hashtag/query/` (Developer API): Search for hashtags, get view counts, related videos.
*   **Data for `UGC Matchmaker`:**
    *   **Creator Search:**
        *   TikTok's APIs for direct "creator search" by niche or detailed demographics are very limited for third-party apps due to privacy.
        *   `GET /v2/user/info/` (Developer API, with `user.info.basic` scope): To get public profile information for a *specific user* once identified (e.g., if a creator connects their account or is mentioned). Fields: `open_id`, `username`, `avatar_url`, `follower_count`, `following_count`, `likes_count`, `video_count`.
        *   This agent might rely more on creators connecting their profiles to IONFLUX, or users manually inputting potential creator handles for analysis.
*   **Content Upload (as per proposal):**
    *   `POST /v2/video/upload/` (Developer API, requires `video.upload` scope and specific app approval).
    *   `POST /v2/video/publish/` (Developer API, requires `video.publish` scope).
    *   Will need to handle video file uploads, titles, descriptions, privacy settings.
*   **Insights (as per proposal):**
    *   `GET /v2/user/video/list/` (Developer API, requires `video.list` scope): Get list of user's own videos.
    *   `GET /v2/video/query/` (Developer API, with `video.list.beta` for their own videos): Get analytics for specific videos (views, likes, comments, shares, engagement rate, audience demographics if available for that video). Requires `user.video.insights` or similar advanced scope. Access to detailed video analytics is often restricted.

**4.3.3. Permissions (OAuth Scopes - TikTok Developer API example):**

IONFLUX will request scopes incrementally based on features used by the user/workspace.

*   **Basic:** `user.info.basic` (to get basic profile info of the connecting user).
*   **Content Viewing (Own):** `video.list` (to see user's own videos).
*   **Content Upload:** `video.upload`, `video.publish` (requires special permission from TikTok).
*   **Insights (Own Content):** `video.insights` (or equivalent for video analytics, requires special permission).
*   **Research (Public Content):** `research.video.query`, `research.hashtag.query` (requires special permission and adherence to research guidelines).

**4.3.4. Content Moderation/Compliance:**

*   All content generation (via `TikTok Stylist`) or uploads must adhere to TikTok's Community Guidelines and Terms of Service.
*   IONFLUX should not facilitate the creation or posting of prohibited content.
*   The `TikTok Integration Service` should implement error handling for API responses indicating policy violations (e.g., content takedowns, upload failures due to moderation).
*   Consider adding disclaimers to users about responsible content creation.

### 4.4. Generic Structure for Future SaaS Integrations

To ensure scalability and maintainability as IONFLUX integrates more SaaS platforms.

*   **A. Dedicated Microservice per Major Integration:**
    *   Each new complex SaaS integration (e.g., Instagram, YouTube, Google Ads) should have its own dedicated microservice (e.g., `InstagramIntegrationService`).
    *   This isolates dependencies, allows for independent scaling, and permits technology choices best suited for that specific API.
    *   Simpler integrations might be grouped if their domains are very similar and APIs are lightweight.

*   **B. Standardized Configuration Management:**
    *   A consistent way to store and manage API keys, client IDs/secrets, and other configuration details for each integration.
    *   Leverage the central secrets management service.
    *   Workspace-level or Brand/Creator-level overrides for configurations where users bring their own accounts/keys.
    *   A common interface or library within IONFLUX for services to request credentials for a specific integration and user/workspace.

*   **C. Common OAuth 2.0 Handling Library/Module:**
    *   Develop a shared library to handle the common parts of the OAuth 2.0 flow (redirect generation, state management, token exchange, token refresh, secure storage) to reduce boilerplate for new integrations.

*   **D. Standardized Internal API Contracts:**
    *   While the external APIs are unique, the internal APIs that other IONFLUX services use to interact with these integration services should follow a somewhat standardized pattern for requesting data or actions.
    *   Example: A common way to request "get data for resource X" or "post data Y to resource Z".
    *   This simplifies how `Agent Service` or `Canvas Service` consume these integrations.

*   **E. Unified Error Handling and Reporting:**
    *   Common error codes and structures for issues arising from integrations (e.g., API key invalid, permissions denied, rate limit exceeded, SaaS provider outage).
    *   Centralized logging and monitoring for integration health.
    *   Consistent feedback to the user regarding integration failures.

*   **F. Webhook Ingestion and Processing Framework:**
    *   If many integrations rely on webhooks, a common framework or set of tools for ingesting, validating, queueing, and reliably processing incoming webhooks.
    *   This includes security considerations like signature verification.

*   **G. Data Mapping and Transformation Layer:**
    *   A clear layer or set of patterns for mapping data from the external SaaS API's format to IONFLUX's internal data models (e.g., mapping a Shopify Product to a generic Product concept if needed by an agent).

*   **H. Incremental Scope Requests:**
    *   For all integrations, request the minimum necessary permissions (scopes) initially and ask for more only when the user tries to use a feature that requires them. This builds user trust.

*   **I. Clear Documentation and Developer Guidelines:**
    *   For internal developers adding new integrations, clear guidelines on these principles, security best practices, and how to use shared libraries.

---

## 5. Core Agent Blueprints
*(Derived from `core_agent_blueprints.md`)*

This section provides detailed blueprints for the initial set of core agents in the IONFLUX platform.

### 5.1. Shopify Sales Sentinel

*   **5.1.1. Agent Name:** `Shopify Sales Sentinel`
*   **5.1.2. Purpose & Value Proposition:**
    *   Monitors a connected Shopify store for significant sales events in near real-time.
    *   Provides timely notifications to users about new orders, high-value orders, or specific product sales, enabling quick reactions, inventory checks, or marketing adjustments.
*   **5.1.3. Core Functionality:**
    *   Listens to Shopify order webhooks (`orders/create`, `orders/paid`).
    *   Filters incoming orders based on user-defined criteria (e.g., minimum order value, specific products, customer tags).
    *   Generates notifications for matching sales events.
    *   Can optionally post summaries to designated Chat Dock channels or update a Canvas block.
*   **5.1.4. Data Inputs:**
    *   **Shopify Webhooks:** `orders/create`, `orders/paid` events from `Shopify Integration Service`. Data includes order details (ID, total price, line items, customer info - handle PII carefully).
    *   **AgentConfiguration.yaml_config:** User-defined thresholds and filters.
    *   **Brand Data:** `Brand.id` to associate with the correct Shopify connection, `Brand.name` for notifications.
*   **5.1.5. Key Processing Logic/Steps:**
    1.  Receives webhook event from `Shopify Integration Service` (forwarded by `Agent Service`).
    2.  Parses the order data from the webhook payload.
    3.  Retrieves its `AgentConfiguration` to get notification rules (e.g., minimum value, product SKUs/IDs to watch, keywords in product titles).
    4.  Checks if the order matches any configured rules:
        *   Is `order.total_price` >= `config.min_order_value`?
        *   Do `order.line_items` contain any `product_id` or `sku` from `config.watch_products`?
        *   Does customer information match `config.watch_customer_tags`? (Requires careful PII handling and clear user consent).
    5.  If a rule is matched, format a notification message.
    6.  Send notification via `Notification Service` (e.g., in-app, email).
    7.  Optionally, send a message to a configured `ChatDockChannel.id` via `Chat Service`.
    8.  Optionally, update a dedicated `CanvasBlock` with a log of recent sentinel events (e.g., using `CanvasBlock.content` update).
*   **5.1.6. Data Outputs & Presentation:**
    *   **Notifications:** "New high-value order! [Order #] for [Amount] from [Customer Name (if consented)] just came in for [Brand Name]!"
    *   **Chat Messages:** Similar to notifications, posted in a specified channel. Could be more detailed, perhaps with line items.
        *   Content Type: `text` or `markdown`.
    *   **Canvas Block (Agent Snippet type):**
        *   Displays a list/feed of recent triggered alerts (e.g., "Order #1234 ($500) - 10:30 AM", "Product 'X' Sold Out! - 11:15 AM").
        *   `last_run_output_preview` could show the latest alert.
*   **5.1.7. Configurable Parameters (`AgentConfiguration.yaml_config`):**
    ```yaml
    brand_id: "uuid-of-brand-entity" # Pre-filled by system based on where agent is configured
    notify_on_new_order: true
    min_order_value_threshold: 200.00 # Only notify if order total is >= this value
    currency_code: "USD" # Assumed from Shopify store settings, but can be for display
    watch_products: # Notify if any of these products are in the order
      - sku: "TSHIRT-RED-L"
      - product_id: "gid://shopify/Product/123456789"
      - title_contains: "Limited Edition"
    # watch_customer_tags: # Advanced feature, PII-sensitive
    #   - "VIP"
    #   - "FirstTimeBuyer"
    notification_channels:
      - type: "in_app" # Default
      - type: "email"
        email_address: "user_preference@example.com" # Or use User.email
      - type: "chat_dock"
        channel_id: "uuid-of-chat-channel"
    canvas_block_update:
      enabled: true
      page_id: "uuid-of-canvas-page" # Optional: if agent has a dedicated canvas block
      block_id: "uuid-of-canvas-block" # Optional
    ```
*   **5.1.8. Dependencies (IONFLUX Services):**
    *   `Agent Service` (for execution and configuration management)
    *   `Shopify Integration Service` (to receive webhooks, potentially fetch more product details if needed)
    *   `Notification Service` (to send alerts)
    *   `Chat Service` (to post messages)
    *   `Canvas Service` (to update Canvas blocks)
    *   `Brand Service` (to get Brand context and Shopify connection details)

### 5.2. TikTok Stylist

*   **5.2.1. Agent Name:** `TikTok Stylist`
*   **5.2.2. Purpose & Value Proposition:**
    *   Helps users (Brands/Creators) identify trending sounds, hashtags, and video styles on TikTok relevant to their niche or campaign goals.
    *   Provides creative inspiration and helps improve content relevance and reach.
*   **5.2.3. Core Functionality:**
    *   Queries TikTok APIs (via `TikTok Integration Service`) for trending content based on keywords, topics, or categories.
    *   Analyzes results to identify popular sounds, hashtags, video formats, and visual styles.
    *   Uses LLM (via `LLM Orchestration Service`) to summarize findings, generate content ideas, or suggest how to adapt trends for the user's brand/niche.
*   **5.2.4. Data Inputs:**
    *   **User Configuration (`AgentConfiguration.yaml_config`):**
        *   Keywords, topics of interest (e.g., "sustainable fashion," "AI tools").
        *   Target audience description.
        *   Brand/Creator niche.
        *   Number of trends to identify.
    *   **TikTok API Data (via `TikTok Integration Service`):**
        *   Video search results (video URLs, titles, creator handles, sound names/IDs, hashtags, view counts, engagement metrics).
        *   Hashtag search results.
    *   **LLM (via `LLM Orchestration Service`):** For summarization, idea generation.
    *   **Brand/Creator Data:** `Brand.industry`, `Creator.niche` for context.
*   **5.2.5. Key Processing Logic/Steps:**
    1.  Agent is triggered (manually via Canvas block "Run" button, chat command, or on a schedule).
    2.  Reads its configuration for keywords, niche, etc.
    3.  Makes requests to `TikTok Integration Service` to:
        *   Search videos by keywords/topics.
        *   Search hashtags by keywords.
    4.  Collects and aggregates API responses (e.g., top N videos, top M hashtags).
    5.  Extracts key elements: sound names, hashtag names, video descriptions, common themes in high-performing videos.
    6.  Constructs a prompt for `LLM Orchestration Service`, including:
        *   The collected TikTok data (summarized if extensive).
        *   User's niche/brand information.
        *   The request (e.g., "Identify 5 trending sounds and suggest how [Brand Name] can use them for [Campaign Goal]").
    7.  Sends prompt to `LLM Orchestration Service` and receives generated text.
    8.  Formats the LLM output and raw trend data for presentation.
*   **5.2.6. Data Outputs & Presentation:**
    *   **Canvas Block (Agent Snippet):**
        *   Displays a list of identified trends (e.g., "Trending Sound: [Sound Name] - [Description/How to use]").
        *   Shows LLM-generated content ideas or summaries.
        *   May include links to example TikTok videos.
        *   `last_run_output_preview` shows a summary of trends.
    *   **Chat Message (if invoked via chat):**
        *   A formatted message summarizing the trends and ideas.
        *   Content Type: `markdown`.
    *   Could also generate a list of `Prompt` suggestions for a `PromptLibrary`.
*   **5.2.7. Configurable Parameters (`AgentConfiguration.yaml_config`):**
    ```yaml
    # For a Brand account if it has TikTok connected, or a Creator account
    # brand_id: "uuid-of-brand-entity" 
    # creator_id: "uuid-of-creator-entity"
    search_keywords: ["AI tools", "productivity hacks", "future of work"]
    # Optional: provide specific hashtags to analyze further, or let the agent discover them
    # seed_hashtags: ["#AI", "#TechInnovation"]
    industry_niche: "Artificial Intelligence Software" # From Brand/Creator profile or overridden here
    content_goal: "Increase brand awareness among tech enthusiasts" # User defined goal for this run
    num_trends_to_find: 5
    num_ideas_per_trend: 3
    output_format: "summary_and_ideas" # "raw_links", "summary_only"
    llm_prompt_template: | # Optional: advanced users can customize the LLM prompt
      "Based on the following TikTok data: {tiktok_data}, and for a brand in the '{industry_niche}' niche 
      aiming to '{content_goal}', please identify {num_trends_to_find} key trends 
      (sounds, hashtags, video styles) and generate {num_ideas_per_trend} distinct content ideas for each. 
      Present as a markdown list."
    ```
*   **5.2.8. Dependencies (IONFLUX Services):**
    *   `Agent Service`
    *   `TikTok Integration Service`
    *   `LLM Orchestration Service`
    *   `Brand Service` / `Creator Service` (for contextual data)
    *   `Canvas Service` / `Chat Service` (for output)

### 5.3. Revenue Tracker Lite (Shopify Focus for Beta)

*   **5.3.1. Agent Name:** `Revenue Tracker Lite`
*   **5.3.2. Purpose & Value Proposition:**
    *   Provides a simplified dashboard/summary of key revenue metrics from a connected Shopify store.
    *   Helps users quickly understand their store's performance without needing to delve into complex Shopify reports.
*   **5.3.3. Core Functionality:**
    *   Fetches order and product data from Shopify via `Shopify Integration Service`.
    *   Calculates key metrics: total sales, average order value (AOV), sales by product (top N), sales over a defined period.
    *   Presents these metrics in a structured format, typically within a Canvas block.
*   **5.3.4. Data Inputs:**
    *   **Shopify API Data (via `Shopify Integration Service`):**
        *   Orders: `id`, `created_at`, `total_price`, `line_items` (product_id, quantity, price).
        *   Products: `id`, `title` (to map product_id to names).
    *   **AgentConfiguration.yaml_config:**
        *   Time period for report (e.g., "last_7_days", "last_30_days", "month_to_date").
        *   Number of top products to display.
        *   Comparison period (optional, for future growth % display).
    *   **Brand Data:** `Brand.id` for Shopify connection.
*   **5.3.5. Key Processing Logic/Steps:**
    1.  Agent triggered (manually "Run" on Canvas block, scheduled, or page load if block is present).
    2.  Reads its configuration for the reporting period and other parameters.
    3.  Requests order data for the specified period from `Shopify Integration Service`.
        *   May need to handle pagination if many orders.
    4.  Requests product data (or uses cached product data) to map product IDs to names.
    5.  Calculates metrics:
        *   Total Sales: Sum of `total_price` for all orders in period.
        *   AOV: Total Sales / Number of Orders.
        *   Sales by Product: Aggregate `line_items.price * line_items.quantity` per `product_id`.
    6.  Formats the calculated metrics for output.
*   **5.3.6. Data Outputs & Presentation:**
    *   **Canvas Block (Agent Snippet or a dedicated "Metrics Block" type):**
        *   Displays key metrics in a clear, visual way (e.g., KPI cards, simple charts if block supports it).
        *   Example:
            *   "Total Sales (Last 30 Days): $X,XXX.XX"
            *   "Average Order Value: $YY.YY"
            *   "Top Selling Products:"
                *   "1. [Product Name A]: $Z,ZZZ.ZZ (AA units)"
                *   "2. [Product Name B]: $W,WWW.WW (BB units)"
        *   `last_run_output_preview` could show total sales.
        *   Should indicate "Last Updated: [Timestamp]".
*   **5.3.7. Configurable Parameters (`AgentConfiguration.yaml_config`):**
    ```yaml
    brand_id: "uuid-of-brand-entity"
    reporting_period: "last_30_days" # "last_7_days", "month_to_date", "custom_range"
    # custom_start_date: "YYYY-MM-DD" # If reporting_period is "custom_range"
    # custom_end_date: "YYYY-MM-DD" # If reporting_period is "custom_range"
    num_top_products: 5
    # compare_to_previous_period: false # Future: for showing % change
    display_options:
      show_total_sales: true
      show_aov: true
      show_top_products: true
      # show_sales_chart: false # Future: if block type supports charts
    ```
*   **5.3.8. Dependencies (IONFLUX Services):**
    *   `Agent Service`
    *   `Shopify Integration Service`
    *   `Brand Service`
    *   `Canvas Service` (for output)

### 5.4. UGC Matchmaker (TikTok Focus)

*   **5.4.1. Agent Name:** `UGC Matchmaker (TikTok Focus)`
*   **5.4.2. Purpose & Value Proposition:**
    *   Helps brands discover potential TikTok creators for User-Generated Content (UGC) campaigns based on niche, keywords, or audience characteristics (where API permits).
    *   Streamlines the initial phase of influencer/creator discovery.
*   **5.4.3. Core Functionality:**
    *   Searches TikTok for creators based on user-defined criteria (keywords in bio/videos, hashtags used).
    *   Collects publicly available profile information for potential matches.
    *   Optionally, uses LLM to summarize creator profiles or assess brand fit.
    *   Presents a list of potential creators.
*   **5.4.4. Data Inputs:**
    *   **User Configuration (`AgentConfiguration.yaml_config`):**
        *   Search keywords (for video content, hashtags, potentially user bios if API allows).
        *   Creator niche criteria.
        *   Audience demographic hints (though direct search by this is unlikely via API).
        *   Brand information (for LLM-based fit assessment).
    *   **TikTok API Data (via `TikTok Integration Service`):**
        *   User profile data (`open_id`, `username`, `avatar_url`, follower/following counts, likes, video counts) for identified creators.
        *   Video data (captions, hashtags from videos matching keyword searches).
    *   **LLM (via `LLM Orchestration Service`):** For profile summarization or brand fit analysis.
    *   **Brand Data:** `Brand.industry`, `Brand.target_audience` for context.
*   **5.4.5. Key Processing Logic/Steps:**
    1.  Agent triggered (manual "Run", chat command).
    2.  Reads configuration for search criteria.
    3.  Makes requests to `TikTok Integration Service`:
        *   Search videos/hashtags by keywords to identify creators active in that space.
        *   For each unique creator identified, fetch their public profile info (if not already cached/retrieved).
    4.  Filters initial list of creators based on basic metrics (e.g., minimum follower count, if configured).
    5.  (Optional) For each potential creator, construct a prompt for `LLM Orchestration Service`:
        *   Include creator's public profile data, sample video descriptions.
        *   Include brand's information and campaign goal.
        *   Ask LLM to assess brand fit or summarize creator's content style.
    6.  Compile a list of matched creators with their profile info and LLM analysis (if any).
*   **5.4.6. Data Outputs & Presentation:**
    *   **Canvas Block (Agent Snippet or Table View):**
        *   Displays a list/table of potential creators.
        *   Columns: Creator Handle (link to TikTok profile), Avatar, Followers, Avg. Likes (if available), Brand Fit Score/Summary (from LLM), Key Videos (links).
        *   `last_run_output_preview` could show number of creators found.
    *   **Chat Message (if invoked via chat):**
        *   A summary message with top N creators found, possibly with links.
        *   Content Type: `markdown`.
*   **5.4.7. Configurable Parameters (`AgentConfiguration.yaml_config`):**
    ```yaml
    brand_id: "uuid-of-brand-entity"
    search_keywords: ["skincare routine", "organic beauty", "#selfcare"]
    creator_niche: "Beauty and Wellness"
    min_follower_count: 1000
    # max_follower_count: 100000 # Optional
    num_creators_to_find: 10
    # Optional: if an LLM should assess brand fit
    assess_brand_fit: true
    # llm_brand_fit_prompt: | # Optional: advanced users can customize
    #   "Given this creator's profile: {creator_data} and our brand focusing on {brand_details}, 
    #   rate their potential fit for a UGC campaign on a scale of 1-10 and provide a brief justification."
    # country_filter: ["US", "CA"] # API dependent, may not be feasible
    ```
*   **5.4.8. Dependencies (IONFLUX Services):**
    *   `Agent Service`
    *   `TikTok Integration Service`
    *   `LLM Orchestration Service` (optional)
    *   `Brand Service`
    *   `Canvas Service` / `Chat Service` (for output)

### 5.5. Slack Brief Butler (General Utility)

*   **5.5.1. Agent Name:** `Slack Brief Butler` (Name can be generalized if not Slack-specific in Beta, e.g., "Chat Brief Butler")
*   **5.5.2. Purpose & Value Proposition:**
    *   Monitors a specified Chat Dock channel for messages that appear to be project briefs, campaign requests, or task assignments.
    *   Uses LLM to summarize these messages into a structured brief (e.g., objectives, key tasks, deadline).
    *   Helps teams quickly extract actionable information from chat conversations.
*   **5.5.3. Core Functionality:**
    *   Can be triggered by a user "tagging" it in a chat message or by monitoring a channel for keywords.
    *   Retrieves recent message history from the specified channel or thread.
    *   Uses LLM to identify and parse relevant information into a structured brief.
    *   Posts the structured brief back to the chat, or to a Canvas block, or creates a task (future).
*   **5.5.4. Data Inputs:**
    *   **Chat Messages (from `Chat Service`):**
        *   Content of messages in a specific channel or thread.
        *   User who sent the message, timestamp.
    *   **AgentConfiguration.yaml_config:**
        *   Channel(s) to monitor (if continuous monitoring).
        *   Keywords to trigger brief generation (e.g., "new brief," "campaign request," "@BriefButler").
        *   LLM prompt template for summarization.
        *   Output format/destination.
    *   **LLM (via `LLM Orchestration Service`):** For parsing and structuring the brief.
*   **5.5.5. Key Processing Logic/Steps:**
    1.  **Triggering:**
        *   **Manual:** User invokes with `/command @SlackBriefButler summarize_thread` or similar in Chat Dock.
        *   **Keyword Monitoring:** Agent (running in background if configured for a channel) sees a message with keywords.
        *   **Mention:** Agent is directly mentioned (`@SlackBriefButler`) in a channel it's configured for.
    2.  Retrieves relevant message(s) from `Chat Service`:
        *   If thread summarization, gets all messages in that thread.
        *   If channel monitoring, might get the last N messages or messages since last check.
    3.  Constructs a prompt for `LLM Orchestration Service`:
        *   Includes the raw chat message(s).
        *   Includes the desired output structure (e.g., "Extract: Project Name, Key Objectives, Main Tasks, Stakeholders, Deadline. If any are missing, state 'Not specified'.").
    4.  Sends prompt to `LLM Orchestration Service` and receives the structured brief.
    5.  Formats the brief for output.
*   **5.5.6. Data Outputs & Presentation:**
    *   **Chat Message (reply in thread or channel):**
        *   A formatted markdown message with the structured brief.
        *   Example:
            ```markdown
            **Project Brief Summary:**
            *   **Project Name:** [LLM-extracted name or "Untitled Brief"]
            *   **Objectives:** [LLM-extracted objectives]
            *   **Key Tasks:** [LLM-extracted tasks]
            *   **Stakeholders:** [LLM-extracted stakeholders or sending user]
            *   **Deadline:** [LLM-extracted deadline or "Not specified"]
            ```
        *   Content Type: `markdown` or `json_proposal` (if interactive elements are desired).
    *   **Canvas Block (Agent Snippet or Text Block):**
        *   The structured brief can be sent to a new or existing Canvas block.
    *   **Notification:** Could notify the user who triggered it or stakeholders mentioned.
*   **5.5.7. Configurable Parameters (`AgentConfiguration.yaml_config`):**
    ```yaml
    # If agent actively monitors channels:
    # monitored_channels:
    #   - channel_id: "uuid-of-general-channel"
    #     trigger_keywords: ["new project", "campaign brief", "task assignment"]
    
    # Default behavior when mentioned or invoked by command
    brief_structure_prompt: | # LLM prompt to define the output structure
      "Please analyze the following conversation and extract a concise project brief. 
      Identify the following if available: 
      1. Project/Campaign Name 
      2. Key Objectives (1-3 bullet points)
      3. Main Deliverables/Tasks (1-5 bullet points)
      4. Key Stakeholders/Owners
      5. Deadline or Timeline.
      If a field is not mentioned, explicitly state 'Not specified'.
      Format the output as clean markdown."
      
    output_destinations:
      - type: "reply_in_chat" # Default
      # - type: "new_canvas_block"
      #   target_page_id: "uuid-of-page-for-briefs" # Optional, otherwise current or user's choice
      # - type: "notification"
      #   notify_user_ids: ["uuid-of-user-who-triggered", "uuid-of-project-manager"]
    ```
*   **5.5.8. Dependencies (IONFLUX Services):**
    *   `Agent Service`
    *   `Chat Service` (for input and output)
    *   `LLM Orchestration Service`
    *   `Canvas Service` (optional output)
    *   `Notification Service` (optional output)
    *   `User Service` (to identify users if needed for stakeholder fields)

---

## 6. Agent Interaction & Configuration Model
*(Derived from `agent_interaction_model.md`)*

This section defines how users discover, configure, interact with, and manage agents within the IONFLUX platform.

### 6.1. Agent Discovery and Instantiation

Agents in IONFLUX are based on `AgentDefinition`s (templates) and are used as `AgentConfiguration`s (instances).

**6.1.1. Agent Marketplace:**

*   **Browsing and Selection:**
    *   Users access the Agent Marketplace via a dedicated link in the sidebar's "Agent Hub" section, as described in `ui_ux_concepts.md`.
    *   The marketplace presents a gallery of available `AgentDefinition`s. Each definition is displayed as a card with:
        *   `AgentDefinition.name` (e.g., "Shopify Sales Sentinel")
        *   `AgentDefinition.description` (what the agent does)
        *   `AgentDefinition.category` (e.g., "Marketing," "Sales," "Content Creation")
        *   `AgentDefinition.version`
        *   Key `AgentDefinition.underlying_services_required` (e.g., icons for "Shopify," "TikTok," "LLM") to indicate necessary integrations.
    *   Users can filter and search the marketplace by category, required services, or keywords.
*   **Creating an `AgentConfiguration` (Instantiation):**
    1.  User selects an `AgentDefinition` from the marketplace (e.g., clicks "Use this Agent" or "Configure").
    2.  This action initiates the creation of a new `AgentConfiguration` record.
    3.  The user is navigated to the Agent Configuration Interface (see Section 2) for this new instance.
    4.  The `AgentConfiguration.agent_definition_id` is set to the ID of the chosen `AgentDefinition`.
    5.  The user is prompted to give their new instance a unique `AgentConfiguration.name` (e.g., "My Shopify Store Sales Alerts," "Q4 Campaign TikTok Trends").
    6.  The `AgentConfiguration.yaml_config` is pre-filled with default parameters derived from the `AgentDefinition.input_schema` (if defined in the schema) or with commented-out examples.

**6.1.2. Agent Shelf (Drag-and-Drop):**

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
                *   Opening the Agent Configuration Interface (Modal YAML editor, see Section 2).
                *   The user names this new instance and customizes its `yaml_config`.
                *   The `CanvasBlock.content.agent_config_id` is then linked to this new `AgentConfiguration.id`.
            *   The `Agent Snippet` block initially shows a "Configuration Required" state.
        *   **If an existing `AgentConfiguration` (instance) is dropped:**
            *   A new `Agent Snippet` block is created on the Canvas.
            *   The `CanvasBlock.content.agent_config_id` is immediately linked to the `AgentConfiguration.id` of the dragged instance.
            *   The `Agent Snippet` block displays the agent's name, status, and available actions (Run, Configure, etc.), ready for use.
    *   This provides a more fluid way to integrate agents directly into a Canvas workflow.

### 6.2. Agent Configuration Interface

This interface allows users to define the specific parameters for an `AgentConfiguration` instance.

**6.2.1. Primary Method (Modal YAML - as per proposal):**

*   **Presentation:**
    *   When a user creates a new `AgentConfiguration` or chooses to edit an existing one (e.g., via a "Configure Agent" button on an `Agent Snippet` block or from the "Configured Agents" list in the sidebar), a modal window appears.
    *   This modal contains a text editor (e.g., Monaco Editor, CodeMirror) displaying the `AgentConfiguration.yaml_config`.
    *   The editor provides YAML syntax highlighting, validation, and potentially auto-completion if the `AgentDefinition.input_schema` is leveraged.
    *   A "Description" panel within the modal might display `AgentDefinition.description` and instructions or schema details for the YAML parameters.
*   **Pre-filling Default Values:**
    *   When creating a new `AgentConfiguration` from an `AgentDefinition`, the `yaml_config` editor is pre-filled.
    *   If the `AgentDefinition.input_schema` (a JSON Schema object) defines `default` values for properties, these are used to populate the initial YAML.
    *   If no defaults, the YAML might contain commented-out examples of parameters or a minimal required structure.
    *   Essential, non-optional parameters without defaults (e.g., `brand_id` for a Shopify agent if not automatically filled from context) should be clearly indicated as requiring user input.

**6.2.2. GUI for Configuration (Considerations):**

*   **Potential:** For agents with a small number of simple parameters, or for common/basic settings of more complex agents, a GUI form could be more user-friendly than raw YAML.
    *   This form could be auto-generated based on the `AgentDefinition.input_schema` (e.g., string inputs become text fields, boolean inputs become checkboxes, enum inputs become dropdowns).
*   **Switching Views:**
    *   If both GUI and YAML are offered, tabs or a toggle switch within the configuration modal could allow users to switch between:
        *   **"Easy View" / "Form View":** The GUI form.
        *   **"Advanced View" / "YAML View":** The raw YAML editor.
    *   Changes in one view should reflect in the other (with potential for data loss if a complex YAML structure cannot be represented in the simple GUI). A warning might be needed if switching from YAML to GUI could simplify/lose complex custom YAML.
*   **Priority for Beta:** YAML editor is primary. GUI is a future enhancement, potentially introduced for the most popular/simple agents first.

**6.2.3. Saving and Updating Configurations:**

*   Users make changes in the YAML editor (or GUI).
*   A "Save" or "Apply" button in the modal persists the changes.
*   The frontend sends the updated `yaml_config` (along with `AgentConfiguration.id`, `name`, `description`) to the `Agent Service`.
*   `Agent Service` validates the YAML (e.g., basic syntax check, potentially against `AgentDefinition.input_schema` if strict validation is enforced).
*   If valid, `Agent Service` updates the `AgentConfiguration` record in the database.
*   If invalid, an error message is shown to the user in the modal.

### 6.3. Agent Output to Canvas

Agents can present their information and results directly on the Canvas.

**6.3.1. `Agent Snippet` Block:**

This is the primary way an `AgentConfiguration` is represented and interacted with on the Canvas.

*   **Display Elements:**
    *   **Agent Name:** Displays `AgentConfiguration.name`. An icon representing the agent type (from `AgentDefinition`) may also be shown.
    *   **Status:** A visual indicator (e.g., colored dot, status label) shows `AgentConfiguration.last_run_status` ("Idle," "Running," "Success," "Error").
    *   **Last Run Time:** Displays `AgentConfiguration.last_run_at` (e.g., "Last run: 5 minutes ago").
    *   **Output Preview:** `AgentConfiguration.last_run_output_preview` (a short text summary or key metrics from the last execution) is displayed in the body of the block. This preview is defined by the agent's output processing logic (see `core_agent_blueprints.md`).
        *   Example: For `Revenue Tracker Lite`, this might be "Total Sales: $1,234.56". For `TikTok Stylist`, "Found 3 new trends."
*   **Interactive Elements:**
    *   **"Run Agent" Button:** (Icon or text button) Manually triggers the agent's execution. Becomes disabled or shows a "Running..." state during execution.
    *   **"View Full Output" Button/Link:** If the output is extensive, this button opens a modal, a side panel, or navigates to a dedicated view to show the complete `AgentConfiguration.last_run_output` (which could be JSON, markdown, a table, etc.).
    *   **"Configure Agent" Button:** (Often a gear icon or "...") Opens the Agent Configuration Interface (modal YAML editor) for this `AgentConfiguration` instance.
    *   **Context Menu ("...") on Block:** Standard block options like "Delete Block," "Duplicate Block," "Move Block."

**6.3.2. Output to Other Block Types:**

Agents can also be configured to send their structured output to other `CanvasBlock` types for richer presentation.

*   **Mechanism:**
    1.  The `AgentConfiguration.yaml_config` would include parameters specifying a target `CanvasBlock.id` and how to map agent output fields to the target block's content structure.
        *   Example for an agent generating text to a Text block:
            ```yaml
            output_to_canvas_block:
              target_block_id: "uuid-of-text-block"
              content_mapping: # Agent specific, defines how its output becomes markdown
                type: "markdown_template"
                template: |
                  ### Agent Results: {agent_output_field_A}
                  - Detail 1: {agent_output_field_B.sub_field_1}
                  - Detail 2: {agent_output_field_C}
            ```
    2.  When the agent runs, `Agent Service` (or the agent logic itself) would retrieve the output and the mapping configuration.
    3.  It would then call `Canvas Service` to update the `content` of the target `CanvasBlock.id` with the formatted data.
*   **Supported Blocks:**
    *   **Text Block:** Agent output (e.g., LLM-generated text, summaries) is formatted as markdown and populates a `CanvasBlock` of type `text`.
    *   **Table View Block:** Agent output (e.g., list of TikTok creators from `UGC Matchmaker`, product sales data) is formatted as JSON suitable for the `table_view` block's expected data structure.
    *   **Kanban/Other Specialized Blocks:** Requires the agent to produce output matching that block's specific JSON content schema.

### 6.4. Agent Output to Chat Dock

Agents can communicate results, send notifications, or propose actions within the Chat Dock.

*   **Styling and Differentiation (as per `ui_ux_concepts.md`):**
    *   Messages from agents are clearly marked with `ChatMessage.sender_type='agent'`.
    *   The agent's configured name (`AgentConfiguration.name`) and a distinct agent avatar (could be derived from `AgentDefinition`) are displayed.
    *   A subtle background color or border might further differentiate agent messages.
*   **Content Types:**
    *   `ChatMessage.content_type='text'` or `'markdown'`: For simple text updates, summaries, or notifications.
    *   `ChatMessage.content_type='json_proposal'`: For structured data that might include interactive elements.
        *   Example: A `Shopify Sales Sentinel` alert could be a `json_proposal` that includes buttons like "View Order in Shopify" (deep link) or "Acknowledge Alert."
    *   `ChatMessage.content_type='agent_command_response'`: Specifically for responses to `/commands`. Could be simple text or more structured data rendered as a card.
*   **Interactive Elements in Chat (Conceptual):**
    *   **Buttons:** Agent messages (especially `json_proposal`) can include buttons. Clicking a button would send an event/command back to `Chat Service`, which then routes it to `Agent Service` or another relevant service.
        *   Example: An agent posts a proposal with "Approve" / "Deny" buttons. Clicking "Approve" could trigger another agent action or update a status.
    *   **Simple Forms/Inputs (Future):** For quick replies or providing minor parameters, an agent message might include simple input fields. Submitting this form would send data back to the agent. This is a more advanced feature.

### 6.5. Invoking Agent Actions

Agents can be triggered in various ways.

**6.5.1. From Canvas `Agent Snippet` Block:**

*   User clicks the **"Run Agent"** button on an `Agent Snippet` block.
*   This action sends a request to `Agent Service`, including the `AgentConfiguration.id` associated with that block.
*   **Runtime Parameters:**
    *   For Beta, most parameters are expected to be pre-set in the `AgentConfiguration.yaml_config`.
    *   **Future Consideration:** The `Agent Snippet` block itself could have designated input fields (if defined in `AgentDefinition.input_schema` as "runtime promptable"). Values entered into these fields on the block would be passed as ephemeral, override parameters for that specific run, supplementing the stored YAML config.
        *   Example: A "Topic" text field on a content generation agent's snippet block.

**6.5.2. Via `/commands` in Chat Dock:**

*   User types a command like `/run_agent <agent_name_or_id> {param1: "value1", param2: 123}`.
*   `Chat Service` parses this command. It identifies the target `AgentConfiguration` (by name or ID lookup via `Agent Service`).
*   It extracts the parameters provided in the command (e.g., the JSON object `{param1: "value1", param2: 123}`).
*   `Chat Service` then sends a request to `Agent Service` to execute the specified `AgentConfiguration.id`, passing along these runtime parameters.
*   These runtime parameters can augment or override settings in the agent's stored `yaml_config` for that specific execution.

**6.5.3. Scheduled/Automated Triggers (Brief Conceptual Outline):**

This is a future enhancement, but the model should accommodate it.

*   **Scheduled Triggers:**
    *   `AgentConfiguration.yaml_config` could include a `schedule` section (e.g., using cron syntax: `schedule: "0 * * * *"` for hourly).
    *   A dedicated "Scheduler Service" or a component within `Agent Service` would monitor these schedules.
    *   When a scheduled time is reached, the Scheduler triggers `Agent Service` to execute the agent, similar to a manual run but without direct user interaction.
*   **Event-Driven Triggers:**
    *   Certain IONFLUX system events (e.g., "new `Brand` created," "`CanvasPage` updated," another agent completes) could publish messages to an event bus (e.g., Kafka, RabbitMQ).
    *   Agents could be configured (in their `yaml_config`) to subscribe to specific events.
    *   An "Event Listener Service" or component in `Agent Service` would consume these events and trigger relevant agents, passing event payload data as potential input.

### 6.6. Data Flow for Configuration and Execution

A simplified trace of the typical lifecycle:

1.  **Discovery & Instantiation:**
    *   User browses `AgentDefinition`s in Marketplace -> Selects one.
    *   Frontend initiates creation of new `AgentConfiguration` linked to the `AgentDefinition.id`.
2.  **Configuration:**
    *   User is presented with the (YAML) configuration interface for the new `AgentConfiguration`.
    *   User inputs/modifies `name`, `description`, and `yaml_config`.
    *   User saves -> Frontend sends data to `Agent Service`.
    *   `Agent Service` validates and stores the `AgentConfiguration` in its database.
3.  **Triggering (e.g., from Canvas):**
    *   User clicks "Run Agent" on an `Agent Snippet` block on a `CanvasPage`.
    *   Frontend sends a request to `Agent Service` with `AgentConfiguration.id` (and any immediate runtime parameters from the block, if applicable).
4.  **Execution Preparation:**
    *   `Agent Service` receives the execution request.
    *   It retrieves the full `AgentConfiguration` (including `yaml_config` and `agent_definition_id`) from its database.
    *   It fetches the corresponding `AgentDefinition` (to understand core logic, input/output schemas, required services).
5.  **Parameter Merging:**
    *   `Agent Service` merges parameters: Stored `yaml_config` < Runtime parameters (from chat/block) < System-filled context (e.g. `user_id`, `workspace_id`).
6.  **Execution Logic:**
    *   `Agent Service` orchestrates the agent's execution based on its definition:
        *   If external services are needed (e.g., LLM, Shopify), `Agent Service` makes requests to the appropriate integration services (`LLM Orchestration Service`, `Shopify Integration Service`), passing necessary parameters and credentials.
        *   Integration services handle the actual external API calls.
7.  **Receiving Output & Status:**
    *   Integration services return data/responses to `Agent Service`.
    *   The core logic of the agent (which might reside within `Agent Service` or be dynamically loaded/interpreted based on `AgentDefinition`) processes these inputs and generates the final output.
8.  **Storing Results:**
    *   `Agent Service` updates the `AgentConfiguration` record with:
        *   `last_run_status` (e.g., "success," "error").
        *   `last_run_at` (current timestamp).
        *   `last_run_output` (the full output, could be JSON, text, etc.).
        *   `last_run_output_preview` (a concise summary for snippet display).
9.  **Presentation/Notification:**
    *   `Agent Service` may push updates to `Canvas Service` (to update the `Agent Snippet` block) or `Chat Service` (if outputting to chat) or `Notification Service`.
    *   Frontend components listening to these services update the UI.

This model provides a flexible framework for users to leverage agents effectively within IONFLUX, from discovery to ongoing use and management.

---

## 7. Nietzschean UX Principles Implementation
*(Derived from `nietzschean_ux_implementation.md`)*

This section outlines how the Nietzschean UX principles, as introduced in the IONFLUX project proposal, will be practically implemented across the platform.

### 7.1. Afirmação do destino (Amor Fati - Transmutation, not Deletion)

**7.1.1. Principle Interpretation:**

In IONFLUX, "Afirmação do destino" or "Amor Fati" translates to an acceptance and affirmation of past actions and states. Instead of outright deleting entities, the system should favor "transmuting" them—changing their state, purpose, or form while preserving their history and the effort invested in them. This means that "mistakes" or outdated items become stepping stones or archives rather than being erased. It's about evolving work, not discarding it.

**7.1.2. Specific UI/UX Manifestations:**

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

**7.1.3. Data Model Implications (referencing `conceptual_definition.md`):**

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

**7.1.4. Impact on Key Entities:**

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

### 7.2. Eterno Retorno (Scheduled Re-execution, Revivals)

**7.2.1. Principle Interpretation:**

"Eterno Retorno" (Eternal Recurrence) in IONFLUX means that tasks, processes, and content are not one-off events but can be designed for repetition, revival, and cyclical execution. It emphasizes the value of recurring workflows and the ability to bring back past configurations or states for new iterations.

**7.2.2. Specific UI/UX Manifestations:**

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

**7.2.3. Data Model Implications:**

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

**7.2.4. Impact on Key Entities:**

*   **`CanvasPage`:** Can be part of a recurring workflow (e.g., a weekly report page that an agent updates). Can be saved as a `CanvasPageTemplate` for repeated use.
*   **`AgentConfiguration`:**
    *   Core entity for this principle. Can be scheduled for re-execution.
    *   Its run history embodies the recurrences.
    *   An archived agent config can be "revived" (status changed to active, schedule potentially re-enabled).
*   **`Brand` / `Creator`:** Less directly about re-execution, but campaigns for them can be cyclical (e.g., monthly performance report generation using a recurring workflow).
*   **Workflows:** A defined collection of pages and agents can be scheduled to run (e.g., "Monthly Marketing Report Workflow"). An archived workflow can be revived for a new period.
*   **`ChatMessage`:** Agents like `Shopify Sales Sentinel` might post recurring updates (e.g., "Daily Sales Summary") to a chat channel based on a schedule.

### 7.3. Vontade de Potência (Radical Customization, Forking, Remixing)

**7.3.1. Principle Interpretation:**

"Vontade de Potência" (Will to Power) in IONFLUX is about empowering users to exert their creative will and control over the platform's elements. It means providing deep customization options, allowing users to "fork" (duplicate and modify) any component, and "remix" (combine and adapt) elements to create new, more powerful configurations or workflows. It's about enabling users to overcome limitations and evolve the system to their needs.

**7.3.2. Specific UI/UX Manifestations:**

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

**7.3.3. Data Model Implications:**

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

**7.3.4. Impact on Key Entities:**

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

By embedding these Nietzschean principles into the UI, system behaviors, and data models, IONFLUX aims to create a dynamic, empowering, and resilient user experience that values user agency and the evolution of work.

---

## 8. FREE-10 Agents Package & Monetization Stubs
*(Derived from `monetization_and_free_tier_scope.md`)*

This section outlines the scope for the initial "FREE-10 Agents" package and the conceptual stubs for platform monetization.

### 8.1. "FREE-10 Agents" Package

This package aims to provide significant initial value to users, showcasing core IONFLUX capabilities across automation, insights, and content assistance.

**8.1.1. List of the 10 Agents (from Project Proposal Section 5):**

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

**8.1.2. Brief Purpose for the 5 Non-Blueprinted Agents:**

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

**8.1.3. Rationale for the Package:**

This selection of 10 agents offers a compelling free tier by:

*   **Showcasing Core IONFLUX Pillars:** It touches upon e-commerce integration (Shopify), social media assistance (TikTok), communication aids (Email, WhatsApp, Chat Briefs), organizational tools (Outreach), brand management (Persona), and platform engagement (Badges).
*   **Providing Immediate Utility:** Agents like `Shopify Sales Sentinel`, `Revenue Tracker Lite`, and `Slack Brief Butler` offer quick, tangible benefits by automating monitoring and summarization tasks.
*   **Encouraging Exploration & Creativity:** Creative agents like `TikTok Stylist` and utility agents like `Email Wizard` encourage users to explore LLM-powered assistance and discover new ways to enhance their workflows.
*   **Demonstrating Breadth and Integration:** The variety gives a taste of IONFLUX's potential as a central command center that integrates various external services and internal tools.
*   **Path to Paid Features & Monetization:** While useful, the "Lite" or focused nature of some free agents (e.g., `Revenue Tracker Lite`) naturally suggests more advanced capabilities, higher usage limits, or more sophisticated versions available in paid tiers or through the "Rent-an-Agent" marketplace. The package also introduces users to concepts like brand persona management (`Persona Guardian`) and outreach (`Outreach Automaton`), which can have more powerful paid counterparts.

### 8.2. Monetization Stubs (Conceptual Outline)

These are initial concepts for how IONFLUX will generate revenue beyond simple subscriptions (which are assumed to be a primary model for offering varying levels of resource access, agent counts beyond the free tier, etc.).

**8.2.1. 2% Transactional Fee:**

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

**8.2.2. "Rent-an-Agent" Marketplace (15% Commission):**

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
*(Derived from `technical_stack_and_demo_strategy.md`)*

This section outlines a preliminary technical stack proposal for IONFLUX and defines a strategy for an initial End-to-End (E2E) demo.

### 9.1. Preliminary Technical Stack Proposal

This stack is proposed with scalability, performance, developer productivity, and suitability for AI/ML and real-time features in mind.

**9.1.1. Frontend:**

*   **Primary Framework: React (with Next.js)**
    *   **Justification:**
        *   **Rich Ecosystem & Community:** Large talent pool, extensive libraries (state management like Redux/Zustand, UI components like Material UI/Chakra UI), and strong community support.
        *   **Component-Based Architecture:** Aligns well with IONFLUX's modular UI (Canvas blocks, sidebar sections).
        *   **Performance:** Next.js offers server-side rendering (SSR), static site generation (SSG), image optimization, and route pre-fetching, contributing to a fast user experience.
        *   **Developer Experience:** Features like Fast Refresh in Next.js improve productivity.
        *   **TypeSafety:** Strong TypeScript support is well-integrated.
*   **Alternative/Consideration: Svelte (with SvelteKit)**
    *   **Justification:** Known for its performance (compiles to vanilla JS), smaller bundle sizes, and potentially simpler state management for certain use cases. Could be considered for highly interactive parts like the Canvas if React performance becomes a concern, or for specific micro-frontends.

**9.1.2. Backend (Microservices):**

A polyglot approach is feasible, but consistency in core areas is beneficial.

*   **Primary Choice: Python with FastAPI**
    *   **Services:** `Agent Service`, `LLM Orchestration Service`, `Shopify Integration Service`, `TikTok Integration Service`, potentially `Brand Service`, `Creator Service`, `Prompt Library Service`.
    *   **Justification:**
        *   **AI/ML Ecosystem:** Python's extensive libraries for AI/ML (e.g., Hugging Face Transformers, Langchain, spaCy) are invaluable for agent development and LLM interaction.
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

**9.1.3. Databases:**

*   **Primary Relational Database: PostgreSQL**
    *   **Justification:** Robust, feature-rich (JSONB support, full-text search, extensibility), highly scalable, and strong community support. ACID compliant.
    *   **Data Types:** Core transactional data, user accounts (`User`), workspaces (`Workspace`), brand/creator profiles (`Brand`, `Creator`), prompt libraries (`PromptLibrary`, `Prompt`), agent configurations (`AgentConfiguration`, `AgentDefinition`), canvas structure (`CanvasPage`, `CanvasBlock` core attributes), chat channels (`ChatDockChannel`), financial records (`PlatformTransaction`, `AgentRentalAgreement`). Basically, most structured data where relationships and consistency are key.
*   **NoSQL Options:**
    *   **MongoDB (Document Store):**
        *   **Justification:** Flexible schema, good for storing denormalized data or rapidly evolving structures.
        *   **Data Types:** Potentially `ChatMessage` content (if highly variable or large), `CanvasBlock.content` (especially for complex, nested JSON structures within blocks), agent run outputs (`AgentConfiguration.last_run_output` if large and unstructured), temporary user session data.
    *   **Elasticsearch (Search Engine & Document Store):**
        *   **Justification:** Powerful full-text search capabilities, analytics, and logging.
        *   **Data Types:** Indexing content from `CanvasPage`s, `ChatMessage`s, `Prompt`s for the Command Palette search. Storing application logs for analysis and monitoring. Potentially for advanced analytics on agent outputs or user activity.
    *   **Redis (In-Memory Key-Value Store):**
        *   **Justification:** Extremely fast for caching, session management, rate limiting, and as a message broker for transient real-time events.
        *   **Data Types:** Session tokens, cached API responses from external services, real-time presence information (Chat/Canvas), queue for notifications.

**9.1.4. Message Broker:**

*   **Choice: RabbitMQ (or Kafka for very high throughput scenarios)**
    *   **Justification (RabbitMQ):** Mature, widely adopted, supports various messaging patterns (publish/subscribe, task queues), good for asynchronous communication between microservices (e.g., `Agent Service` signaling `Notification Service`). Easier to set up and manage for typical microservice workloads than Kafka initially.
    *   **Justification (Kafka):** If the platform anticipates extremely high volumes of event data (e.g., analytics events, logs from many agents), Kafka's log-streaming architecture would be more suitable, though it has higher operational complexity.
    *   As per `saas_api_integration_specs.md`, this is for asynchronous, event-driven communication.

**9.1.5. API Gateway:**

*   **Suggestion: Kong API Gateway (or a cloud provider's managed gateway like AWS API Gateway, Google Cloud API Gateway)**
    *   **Justification (Kong):** Open-source, feature-rich (routing, authentication, rate limiting, transformations, plugins), Kubernetes-native. Can be deployed on-prem or in any cloud.
    *   **Justification (Cloud Managed):** Reduces operational overhead, integrates well with other cloud services (IAM, logging).
    *   The API Gateway will handle routing requests to the appropriate microservices, initial authentication/authorization, rate limiting, and request/response transformations.

**9.1.6. Deployment & Infrastructure:**

*   **Containerization: Docker & Kubernetes (K8s)**
    *   **Justification:** Standard for deploying and managing microservices. Docker for packaging applications, Kubernetes for orchestration, scaling, and resilience.
*   **Cloud Provider: Flexible (AWS, GCP, or Azure are all suitable)**
    *   The choice can be driven by existing team expertise, specific managed service offerings (e.g., managed K8s, databases, AI services), or cost considerations. The architecture should aim to be cloud-agnostic where possible, relying on Kubernetes to abstract underlying infrastructure.
    *   Initial preference might lean towards a provider with strong managed Kubernetes (EKS, GKE, AKS) and serverless function offerings for certain tasks.

**9.1.7. Real-time Communication:**

*   **Confirmation: WebSockets**
    *   For `Chat Service` and real-time collaboration features in `Canvas Service` (e.g., multi-user block editing, cursor presence). Node.js backend is well-suited for this.

### 9.2. End-to-End (E2E) Demo Flow & Prototyping Strategy

**9.2.1. Core User Journey for Demo:**

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

**9.2.2. Key Screens/Interfaces to Mock/Build for Demo:**

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

**9.2.3. Prototyping Tools/Approach (n8n + YAML focus):**

*   **n8n + YAML for Backend Logic/Agent Prototyping:**
    *   **n8n Workflows:** Use n8n (a workflow automation tool) to visually model the logic of several agents or inter-service communication for the demo. Each n8n workflow can represent a simplified microservice or an agent's core task.
        *   Example: An n8n workflow for `TikTok Stylist` could have nodes for:
            1.  HTTP Request (mocking call to `TikTok Integration Service` - returns canned JSON).
            2.  Function Node (JavaScript/Python to process data).
            3.  HTTP Request (mocking call to `LLM Orchestration Service` - returns canned text).
            4.  HTTP Request (to send results back to a mocked `Agent Service` endpoint).
    *   **YAML for Agent Configuration:** The `AgentConfiguration.yaml_config` will be real and stored (perhaps in a simple DB or even flat files for the demo's backend). The n8n workflows (acting as agents) would be triggered with references to these YAML configs, and the workflow logic would parse relevant parameters from the YAML to guide its execution (even if parts of that execution are mocked).
    *   This approach allows rapid iteration on agent logic (by modifying n8n workflows and YAML) without writing full microservice code for all agents initially.
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

**9.2.4. Focus of the Demo:**

*   **Validate the core User Experience:** Demonstrate the hybrid "Notion+Slack" interaction model, focusing on the Canvas and Chat Dock as primary work hubs.
*   **Showcase Agent Capabilities & Interaction:** Illustrate how users discover, configure (via YAML), and run agents, and how agents deliver value within the Canvas and Chat.
*   **Demonstrate Key Integrations (Conceptually & Partially):** Show the Shopify connection flow and a simulated Shopify event. Show the TikTok agent flow with mocked data.
*   **Illustrate Data Flow:** Show how information from one part of the system (e.g., chat discussion) can be processed by an agent and appear elsewhere (e.g., Canvas).
*   **Gather Early Feedback:** On the core concepts, usability, and perceived value of the integrated agent experience.

This strategy prioritizes demonstrating the user-facing value and core interaction patterns while deferring full implementation of all backend complexities, using n8n and mocks for rapid prototyping of agent logic.

---

## 10. Conclusion & Next Steps

This Initial Design Document provides a comprehensive, though preliminary, blueprint for the IONFLUX platform. It spans the core architecture, data models, user experience paradigms, SaaS integration strategies, initial agent functionalities, agent interaction models, unique UX principles, free tier packaging, monetization concepts, and a proposed technical stack and demo strategy.

The goal of this consolidated document is to offer a unified vision that can guide the initial development sprints and facilitate informed discussions with stakeholders. It represents a snapshot of the design thinking at this stage, and it is expected to evolve as the project moves into implementation and user feedback is gathered.

The immediate next step is for this document to undergo a thorough review by the project team and key stakeholders. Feedback from this review will be crucial for refining these concepts and prioritizing features for the Minimum Viable Product (MVP) and the E2E demo. Subsequent phases will involve detailed technical design for each microservice, database schema finalization, and iterative development of the frontend and backend components.
```
