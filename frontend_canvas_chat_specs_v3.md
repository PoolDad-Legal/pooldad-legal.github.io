# IONFLUX Project: Frontend Core Canvas & Chat Interaction Specifications (v3 - E2E Demo)

**Version Note:** This is v3 of the Frontend Canvas & Chat specification, aligned with V3 backend services (`canvas_service_minimal_spec_v3.md`, `chat_service_minimal_spec_v3.md`, `agent_service_minimal_spec_v3.md`), data models (`conceptual_definition_v3.md`, `initial_schema_demo_v3.sql`), and interaction models (`agent_interaction_model_v3.md`).

This document outlines frontend specifications for Canvas and Chat Dock components for the IONFLUX E2E Demo, assuming a React (Next.js) stack.

## 1. Canvas Page View

*   **Purpose:** Displays a `CanvasPage`, its blocks, and allows basic interactions.
*   **Key UI Elements & Layout:** (Page Title Area, Add Block Button largely unchanged).
    *   **Block Rendering Area:**
        *   Fetches page data including blocks via `GET /pages/:pageId` (Canvas Service). Blocks now have a `content_json` field.
        *   Iterates through `blocks` array. Renders each block based on `block.type` using specific components that understand the `block.content_json` structure for that type.
            *   **`text` block:** Render `block.content_json.markdown_text` using a markdown component. `block.content_json.title_text` could be an optional header.
            *   **`agent_snippet` block:** Pass `block.id` and `block.content_json.agent_configuration_id` to the `AgentSnippetBlock` component.
            *   **`json_display` block:** Pretty-print `block.content_json.json_data_to_display`.
            *   **`embed_panel` block:** Use `block.content_json.embed_url` to render an iframe or appropriate embed component.
            *   **Other types (`image`, `video`, `table_view`, `kanban_board`):** Render based on their respective `content_json` structures defined in `conceptual_definition_v3.md`.
*   **API Interaction:**
    *   **On Load (`GET /pages/:pageId`):** Response page object includes `status`, `icon_url`. Nested `blocks` array contains `content_json` for each block.
    *   **On Adding New Block (`POST /pages/:pageId/blocks`):**
        *   Request body must now use `content_json` with the correct initial structure for the chosen `type`.
            *   Example for 'text': `{"type": "text", "content_json": {"markdown_text": "# New Text\n"}}`
            *   Example for 'agent_snippet': `{"type": "agent_snippet", "content_json": {"agent_configuration_id": null, "placeholder_text": "Configure Agent..."}}`
            *   Example for 'json_display': `{"type": "json_display", "content_json": {"title_text": "New JSON View", "json_data_to_display": {}}}`
    *   **On Updating Block (`PUT /blocks/:blockId`):** Request body uses `content_json`. Can also update `type` for block conversion.
    *   **Page Operations:** `POST /workspaces/:workspace_id/pages` (create), `PUT /pages/:pageId` (update), `DELETE /pages/:pageId` (archive by setting `status: 'archived'`) now handle `status` and `icon_url` fields for pages.
*   **Client-Side State Management:**
    *   `currentPageData`: Stores full V3 `CanvasPage` object (including `status`, `icon_url`).
    *   `blocks`: Array of V3 `CanvasBlock` objects (with `content_json`).

## 2. Agent Snippet Block Component (on Canvas)

*   **Purpose:** Displays an `AgentConfiguration` instance and allows interaction.
*   **Props:** `block_id`, `agent_configuration_id` (from `CanvasBlock.content_json`).
*   **Data Fetching:** On mount or when `agent_configuration_id` changes:
    1.  Fetch `AgentConfiguration` details: `GET /agent-configurations/:agent_configuration_id` (Agent Service). This returns the V3 `AgentConfiguration` object including `name`, `agent_definition_id`, `last_run_summary_json`.
    2.  Fetch `AgentDefinition` details: `GET /agent-definitions/:agent_definition_id` (using `agent_definition_id` from the fetched configuration). This returns the rich V3 `AgentDefinition` object.
*   **Key UI Elements & Layout:**
    *   **Header:** Display `agentConfiguration.name` and `agentDefinition.name` (or `agentDefinition.prm_details_json.epithet`).
    *   **Status:** From `agentConfiguration.last_run_summary_json.status`.
    *   **Body:**
        *   Last Run Time: From `agentConfiguration.last_run_summary_json.timestamp`.
        *   Output Preview: Display `agentConfiguration.last_run_summary_json.output_preview_text`.
    *   **Footer/Actions:**
        *   "Run Agent" Button.
        *   "Configure Agent" Button: Opens `AgentConfigurationModal` (passing `agent_configuration_id` and `agent_definition_id`).
        *   "View Full Output" Button: Enabled if `agentConfiguration.last_run_summary_json.run_id` exists. Opens `ViewFullOutputModal`.
*   **"View Full Output" Modal (`ViewFullOutputModal` Component):**
    *   **Props:** `isOpen`, `onClose`, `run_id`, `agent_definition` (the full AgentDefinition object for schema reference).
    *   **Data Fetching:** Fetches `GET /agent-runs/:run_id` (Agent Service). This endpoint should return the full `AgentRunLog` object.
    *   **UI:**
        *   Title: "Full Output for Run: {run_id}".
        *   Dropdown/Tabs: To select an output key if `AgentRunLog.output_data_json.outputs_array` has multiple items. The available keys and their types come from `props.agent_definition.outputs_config_json_array`.
        *   Content Area: Renders the selected output's `value` (or content from `storage_ref_url`) based on its `data_type` (retrieved from `props.agent_definition.outputs_config_json_array` for that `key_name`) - e.g., pretty-print JSON, render Markdown.
*   **API Interaction ("Run Agent"):**
    *   `POST /agent-configurations/:agent_configuration_id/run` with optional `runtime_params` (if snippet block UI supports them).
    *   On 202 Accepted, update local status to 'pending'. Periodically re-fetch `AgentConfiguration` to get updated `last_run_summary_json` for demo, or use WebSockets for real-time status updates if implemented.

## 3. Agent Configuration Modal Component

*   **Purpose:** Create/edit an `AgentConfiguration`.
*   **Props:** `isOpen`, `onClose`, `workspaceId`, `agentDefinitionId` (for new), `agentConfigurationId` (for existing).
*   **Layout (Two-Pane/Tabbed - as per `agent_interaction_model_v3.md`):**
    *   **Pane 1: Agent Definition Information (Read-Only):**
        *   **Data Source:** Fetches `GET /agent-definitions/:agentDefinitionId` when modal opens (using `props.agentDefinitionId` if new, or `agentConfiguration.agent_definition_id` if existing).
        *   **Displays:**
            *   `AgentDefinition.name`, `version`, `definition_status`.
            *   `prm_details_json`: `epithet`, `tagline`, `introduction_text`, `core_capabilities_array`.
            *   **Inputs Overview:** User-friendly list from `inputs_schema_json_array` (key, type, description, required, default).
            *   **Outputs Overview:** Summary from `outputs_config_json_array`.
            *   **Default Triggers:** From `triggers_config_json_array` (showing type, default config, if `is_user_overridable`).
            *   **Memory Config:** From `memory_config_json`.
            *   **Key Stack Info:** From `stack_details_json` (e.g., compatible LLMs if user can choose).
    *   **Pane 2: Instance Configuration (Editable):**
        *   `AgentConfiguration.name` (text input).
        *   `AgentConfiguration.description_text` (text area).
        *   **`yaml_config_text` Editor:**
            *   Text area with YAML syntax highlighting.
            *   On open (for new config from `agentDefinitionId`), pre-fill with comments or structure based on `AgentDefinition.inputs_schema_json_array` and overridable parts of triggers/memory. Example:
                ```yaml
                # Instance Name: My Email Campaign Helper
                # Description: Helps draft emails for Q4.
                # --- Agent Inputs (from Definition: EmailWizard v0.1) ---
                # See "Agent Definition Info" panel for details on each input.
                inputs:
                  # shopify_event: (json, optional) - Example: {"order_id": "123"}
                  manual_payload: # (json, optional)
                    customer_segment: "VIP"
                    email_goal: "engagement"

                # --- Trigger Overrides (Optional) ---
                # Default 'schedule' trigger (cron: "0 */2 * * *") can be modified if allowed by definition.
                # Example (if definition has a trigger with trigger_definition_key: "my_schedule_trigger"):
                # triggers:
                #   - trigger_definition_key: "my_schedule_trigger"
                #     enabled: true # Or false to disable
                #     config_override:
                #       cron_expression: "0 10 * * MON"

                # --- Memory Overrides (Optional) ---
                # Default namespace from definition: emailwizard_personas_ws_{{workspace_id}}
                # Example (if definition's template allows {{instance_suffix}}):
                # memory:
                #   instance_suffix: "my_custom_segment"
                ```
*   **API Interaction (Save):**
    *   `POST /workspaces/:workspace_id/agent-configurations` (for new) or `PUT /agent-configurations/:agent_configuration_id` (for existing).
    *   Request body includes `name`, `description_text`, `agent_definition_id` (for new), `yaml_config_text`.

## 4. Chat Dock View

*   **Purpose:** Main chat interface.
*   **Key UI Elements & Layout:** (Channel List, Message View Panel, Message Input Box largely unchanged structurally).
*   **API Interaction (REST):**
    *   `GET /workspaces/:workspace_id/channels`: Response items are V3 `ChatChannel` objects (with `type`, `description_text`, `member_user_ids_array`).
    *   `GET /channels/:channel_id/messages`: Response items are V3 `ChatMessage` objects.
*   **WebSocket Interaction:**
    *   **Sending User Messages (`action: "send_message"`):**
        *   Payload now includes `content_type` (e.g., 'text', 'markdown') and `content_json` (e.g., `{"text_body": "User message"}`).
    *   **Receiving New Messages (`action: "new_message"`):**
        *   Payload is a full V3 `ChatMessage` object, including `sender_id`, `sender_type`, `content_type`, `content_json`, `created_at`, `reactions_json_array`, `read_by_user_ids_array`, etc.
        *   **Message Rendering Logic:**
            *   Differentiate styling for `message.sender_type: 'user'` vs. `'agent'` vs. `'system'`.
            *   Render `message.content_json` based on `message.content_type`:
                *   `'text'` or `'markdown'`: Render `message.content_json.text_body` (as HTML if markdown, using `react-markdown`).
                *   `'json_data'`: Pretty-print `message.content_json.json_payload` (e.g., in a collapsible block).
                *   `'interactive_proposal'`: Display `message.content_json.title_text` (if any), `message.content_json.description_text`. Pretty-print `message.content_json.data_json`. Render items in `message.content_json.actions_array` (e.g., `{"label": "Approve", "action_id": "approve_xyz"}`) as clickable buttons. For demo, button clicks can log `action_id` and payload to console, or send a specific event back via WebSocket if defined.
                *   `'agent_status_update'`: Display `message.content_json.status_update_json.text` with appropriate status styling.
*   **Command Handling (`/run_agent`):**
    *   Client-side: Parse command into `agent_identifier` and `runtime_params` (JSON string).
    *   API Call to Agent Service: `POST /v1/agent-commands/invoke` with payload:
        ```json
        {
          "command_name": "run_agent",
          "agent_identifier": "parsed_agent_name_or_id",
          "runtime_params": { /* parsed JSON from command string */ },
          "user_id": "current_user.id",
          "workspace_id": "current_workspace.id",
          "origin_details": {
              "type": "chat",
              "channel_id": "selectedChannel.id",
              "message_id": "client_generated_command_message_id (optional)",
              "thread_id": "current_thread.id (optional)"
          }
        }
        ```

This V3 specification aligns the frontend Canvas and Chat components with the richer data models and interaction patterns introduced by the PRM agents and updated V3 backend services.
```
