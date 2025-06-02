# IONFLUX Project: Frontend Core Canvas & Chat Interaction Specifications (E2E Demo)

This document outlines the frontend specifications for the core Canvas and Chat Dock components required for the IONFLUX E2E Demo. It builds upon `ui_ux_concepts.md`, relevant minimal service specifications (`canvas_service_minimal_spec.md`, `chat_service_minimal_spec.md`, `agent_service_minimal_spec.md`), `agent_interaction_model.md`, and assumes a React (with Next.js) frontend stack.

## 1. Canvas Page View

*   **Purpose:** Displays a single Canvas Page, its blocks, and allows basic block interactions.
*   **Key UI Elements & Layout (referencing `ui_ux_concepts.md` Section 2):**
    *   **Page Title Area:**
        *   Displays `CanvasPages.title` (editable in future, read-only for initial demo is fine).
        *   (Optional for demo) Breadcrumbs if page is nested.
    *   **Block Rendering Area:**
        *   Iterates through the `blocks` array fetched for the page.
        *   Renders each block based on its `type`. Initially, support:
            *   **`text` block:** Displays markdown content (e.g., using `react-markdown`). For demo, direct editing might be deferred; focus on displaying text set via API.
            *   **`agent_snippet` block:** Renders the `AgentSnippetBlock` component (see Section 2 below).
        *   Blocks are positioned based on `position_x`, `position_y` (absolute positioning for demo simplicity).
    *   **Add Block Button/Mechanism:**
        *   A simple "+" button on the Canvas page.
        *   Clicking it opens a small menu/dropdown: "Add Text Block," "Add Agent Snippet."
        *   Selecting an option adds a new block of that type at a default position.
            *   For "Add Agent Snippet," it would initially be unconfigured, prompting the user to click "Configure Agent."
    *   **(Optional for Demo) Simplified Block Movement:**
        *   Allow dragging blocks to update `position_x`, `position_y`. On drag end, a `PUT /blocks/:blockId` call is made. This can be very basic for the demo.
*   **API Interaction:**
    *   **On Load (when navigating to a page):**
        *   **Endpoint:** `GET /pages/:pageId` (Canvas Service).
        *   **Headers:** Include JWT.
        *   **Success Handling:** Stores the fetched page data (title, blocks) in state.
        *   **Error Handling:** Display error message if page fetch fails.
    *   **On Adding New Block (e.g., "Add Text Block"):**
        *   **Endpoint:** `POST /pages/:pageId/blocks` (Canvas Service).
        *   **Headers:** Include JWT.
        *   **Request Body (for Text Block):**
            ```json
            {
              "type": "text",
              "content": {"markdown": "# New Text Block\nStart editing..."},
              "position_x": 0, // Or default calculated position
              "position_y": 0  // Or default calculated position
            }
            ```
        *   **Request Body (for Agent Snippet - initial, unconfigured):**
            ```json
            {
              "type": "agent_snippet",
              "content": {"agent_config_id": null, "placeholder_text": "Configure this agent"}, // No agent_config_id initially
              "position_x": 0,
              "position_y": 0
            }
            ```
        *   **Success Handling:** Add the new block to the local state (list of blocks) and re-render.
        *   **Error Handling:** Display error.
    *   **On Updating Block (e.g., after moving a block, or content update for Text block - if basic editing is in demo):**
        *   **Endpoint:** `PUT /blocks/:blockId` (Canvas Service).
        *   **Headers:** Include JWT.
        *   **Request Body (example for position update):**
            ```json
            {
              "position_x": new_x_coordinate,
              "position_y": new_y_coordinate
            }
            ```
        *   **Success Handling:** Update the block in local state.
        *   **Error Handling:** Display error.
*   **Client-Side State Management (e.g., React Context for page data, or component state):**
    *   `currentPageData`: Object (stores `id`, `title`, `workspace_id`, etc.).
    *   `blocks`: Array of block objects `[{"id": "uuid", "type": "string", "content": {}, ...}]`.
    *   `isLoadingPage`: Boolean.
    *   `pageError`: String or Object.
    *   `isAddingBlock`: Boolean (if a modal is used for block type selection).
    *   (If block editing is part of demo) `editingBlockId`: String (ID of block being edited), `editingBlockContent`: Object.

## 2. Agent Snippet Block (Frontend Component on Canvas)

*   **Purpose:** Displays an instance of an `AgentConfiguration` on the Canvas and allows interaction.
*   **Props:** Receives `blockData` (including `content: { agent_config_id: "uuid" }`) and potentially the full `AgentConfiguration` details if pre-fetched by the parent Canvas Page view. If not, it might need to fetch it.
*   **Key UI Elements & Layout (based on `ui_ux_concepts.md` Section 2, `agent_interaction_model.md` Section 3.1):**
    *   **Container:** Card-like appearance.
    *   **Header:**
        *   Agent Name: Display `agentConfiguration.name`.
        *   Status Indicator: Small dot/badge colored based on `agentConfiguration.last_run_status` (e.g., green for 'success', red for 'error', yellow for 'running', grey for 'idle').
    *   **Body:**
        *   Last Run Time: "Last run: [formatted `agentConfiguration.last_run_at`]" or "Not run yet."
        *   Output Preview: Display `agentConfiguration.last_run_output_preview` (e.g., simple text).
    *   **Footer/Actions:**
        *   **"Run Agent" Button:** Enabled if status is 'idle', 'success', or 'error'. Changes to "Running..." and disables during execution.
        *   **"Configure Agent" Button:** (e.g., gear icon) Opens the Agent Configuration Modal.
        *   (Optional for demo) "View Full Output" button if output is complex.
*   **API Interaction:**
    *   **On Mount/Props Change (if `agent_config_id` exists but full config details are not passed in):**
        *   **Endpoint:** `GET /agent-configurations/:agentConfigId` (Agent Service), using `blockData.content.agent_config_id`.
        *   **Headers:** Include JWT.
        *   **Success Handling:** Populate local state with fetched agent configuration details.
    *   **"Run Agent" Button Click:**
        *   **Endpoint:** `POST /agent-configurations/:agentConfigId/run` (Agent Service), using `blockData.content.agent_config_id`.
        *   **Headers:** Include JWT.
        *   **Request Body (for demo, runtime_params might be empty if not supported by snippet block directly):**
            ```json
            {
              "runtime_params": {} 
            }
            ```
        *   **Success Handling (HTTP 202 - Accepted):**
            *   Update local agent status to "pending" or "running".
            *   Display loading indicator.
            *   **To get final status/output for demo (simplification):** After a short delay, or if a WebSocket message is received (advanced), re-fetch the agent configuration via `GET /agent-configurations/:agentConfigId` to get the updated `last_run_status` and `last_run_output_preview`.
        *   **Error Handling:** Display error message on the block or via a notification. Update local agent status to "error".
    *   **"Configure Agent" Button Click:**
        *   Opens the `AgentConfigurationModal` component, passing the `agent_config_id` and current workspace context.
*   **Client-Side State Management (local component state):**
    *   `agentConfigurationDetails`: Object (stores fetched name, status, last_run_at, output_preview, etc.).
    *   `isRunning`: Boolean (local loading state for the run button).
    *   `runError`: String or Object.

## 3. Agent Configuration Modal (Frontend Component)

*   **Purpose:** Allows users to create or edit an `AgentConfiguration`.
*   **Props:** `isOpen`, `onClose`, `workspaceId`, `agentDefinitionId` (for new), `agentConfigurationId` (for existing).
*   **Key UI Elements & Layout (based on `agent_interaction_model.md` Section 2):**
    *   **Modal Dialog Structure.**
    *   **Title:** "Configure Agent" or "Create New Agent Configuration".
    *   **Agent Name Input:**
        *   Label: "Configuration Name"
        *   Type: Text input
    *   **Description Input (Optional):**
        *   Label: "Description"
        *   Type: Text area
    *   **YAML Editor:**
        *   A text area, ideally with YAML syntax highlighting (e.g., using `react-simple-code-editor` with Prism.js, or a more advanced editor like Monaco if feasible for demo).
        *   Displays/allows editing of `yaml_config` string.
    *   **Buttons:**
        *   "Save Configuration" button.
        *   "Cancel" button (calls `onClose`).
    *   **Error Display Area.**
*   **API Interaction:**
    *   **On Open (for existing `agentConfigurationId`):**
        *   **Endpoint:** `GET /agent-configurations/:agentConfigurationId` (Agent Service).
        *   **Headers:** Include JWT.
        *   **Success Handling:** Populate form fields (`name`, `description`, `yaml_config_string`).
    *   **On Open (for new, with `agentDefinitionId`):**
        *   (Optional for demo complexity) Could fetch `AgentDefinition` from `GET /agent-definitions/:agentDefinitionId` to get a default `input_schema` or template YAML to prefill. For simplest demo, can start with empty/example YAML.
    *   **"Save Configuration" Button Click:**
        *   **If new (`agentConfigurationId` is null):**
            *   **Endpoint:** `POST /workspaces/:workspaceId/agent-configurations` (Agent Service).
            *   **Headers:** Include JWT.
            *   **Request Body:** `{"name": "...", "description": "...", "agent_definition_id": "prop.agentDefinitionId", "yaml_config": "..."}`.
        *   **If existing (`agentConfigurationId` is present):**
            *   **Endpoint:** `PUT /agent-configurations/:agentConfigurationId` (Agent Service).
            *   **Headers:** Include JWT.
            *   **Request Body:** `{"name": "...", "description": "...", "yaml_config": "..."}`.
        *   **Success Handling:**
            *   Close modal (`onClose()`).
            *   Trigger a refresh of the agent snippet block on the canvas or the list of configured agents.
        *   **Error Handling:** Display errors within the modal.
*   **Client-Side State Management (local component state):**
    *   `configName`: String.
    *   `configDescription`: String.
    *   `yamlConfigString`: String (content of the YAML editor).
    *   `isLoading`: Boolean.
    *   `error`: String or Object.
    *   `currentAgentDefinition`: Object (optional, if fetching definition for defaults).

## 4. Chat Dock View

*   **Purpose:** Provides the main chat interface, including channel list, message display, and message input.
*   **Key UI Elements & Layout (based on `ui_ux_concepts.md` Section 3):**
    *   **Persistent Panel (e.g., right sidebar).**
    *   **Channel List Panel:**
        *   List of `ChatDockChannel` items. Each item shows `channel.name`.
        *   Clicking a channel makes it active.
        *   (Optional for demo) "+" button to create a new channel (would need a simple modal).
    *   **Message View Panel:**
        *   Header: Displays `selectedChannel.name`.
        *   Message History: Scrollable area displaying messages.
            *   Each message shows sender (avatar/name - simplified for demo, just `sender_type` differentiation) and `content.text`.
            *   Agent messages styled differently (e.g., distinct background, "bot" icon).
    *   **Message Input Box:**
        *   Text area for message input.
        *   "Send" button.
*   **API Interaction (REST):**
    *   **On Mount / Workspace Change:**
        *   **Endpoint:** `GET /workspaces/:workspaceId/channels` (Chat Service).
        *   **Headers:** Include JWT.
        *   **Success Handling:** Populate `channelsList` state. Select a default channel (e.g., first one).
    *   **On Channel Select:**
        *   **Endpoint:** `GET /channels/:channelId/messages` (Chat Service).
        *   **Headers:** Include JWT.
        *   **Success Handling:** Populate `messages` state for the `selectedChannel`.
*   **WebSocket Interaction (based on `chat_service_minimal_spec.md` Section 2):**
    *   **Connection:**
        *   Establish WebSocket connection to `/chat?token=jwt_string&workspaceId=currentWorkspaceId` on component mount or workspace selection.
        *   Handle connection errors/closures.
    *   **Channel Subscription:**
        *   When `selectedChannel` changes, if WebSocket is connected, send:
            ```json
            {"action": "subscribe", "payload": {"channelId": "selectedChannel.id"}}
            ```
    *   **Sending User Messages (on Send button click or Enter in input):**
        *   If input message starts with `/`:
            *   Parse command locally (e.g., `/run_agent <agent_config_name_or_id> {params_json}`).
            *   **Look up `agent_config_id`:** The frontend will need a way to map the `<agent_config_name_or_id>` to an actual `agent_config_id`. This might involve:
                1.  Fetching all agent configurations for the workspace via `GET /workspaces/:workspaceId/agent-configurations` (Agent Service) and caching them.
                2.  Finding the matching agent configuration by name.
            *   **API Call:** `POST /agent-configurations/:agentConfigId/run` (Agent Service) with `runtime_params` from the parsed command. (Alternative: `POST /agents/invoke-command` on Agent Service if that endpoint is implemented to handle name resolution).
        *   Else (normal message):
            *   Send via WebSocket:
                ```json
                {
                  "action": "send_message",
                  "payload": {
                    "channelId": "selectedChannel.id",
                    "content_type": "text",
                    "content": {"text": "typed_message_content"}
                  }
                }
                ```
    *   **Receiving New Messages:**
        *   Listen for `{"action": "new_message", "payload": {...messageObject...}}` from WebSocket.
        *   If `messageObject.channel_id` matches `selectedChannel.id`, append to `messages` state to update UI.
*   **Client-Side State Management (e.g., React Context for chat state, or component state):**
    *   `channelsList`: Array of channel objects.
    *   `selectedChannel`: Object (the currently active channel).
    *   `messages`: Array of message objects for the `selectedChannel`.
    *   `newMessageInput`: String (content of the message input box).
    *   `webSocketConnection`: WebSocket object instance.
    *   `webSocketStatus`: String ('connecting', 'connected', 'disconnected').
    *   `isLoadingChannels`: Boolean.
    *   `isLoadingMessages`: Boolean.
    *   `chatError`: String or Object.
    *   `agentConfigsForWorkspace`: Array (cached, for mapping names in commands to IDs).

This specification provides a detailed guide for the frontend development of core Canvas and Chat functionalities crucial for the E2E demo.
```
