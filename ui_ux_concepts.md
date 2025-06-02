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
```
