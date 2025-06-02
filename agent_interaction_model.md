# IONFLUX Project: Agent Interaction & Configuration Model

This document defines how users discover, configure, interact with, and manage agents within the IONFLUX platform. It builds upon the `conceptual_definition.md`, `ui_ux_concepts.md`, `saas_api_integration_specs.md`, and `core_agent_blueprints.md`.

## 1. Agent Discovery and Instantiation

Agents in IONFLUX are based on `AgentDefinition`s (templates) and are used as `AgentConfiguration`s (instances).

**1.1. Agent Marketplace:**

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
                *   Opening the Agent Configuration Interface (Modal YAML editor, see Section 2).
                *   The user names this new instance and customizes its `yaml_config`.
                *   The `CanvasBlock.content.agent_config_id` is then linked to this new `AgentConfiguration.id`.
            *   The `Agent Snippet` block initially shows a "Configuration Required" state.
        *   **If an existing `AgentConfiguration` (instance) is dropped:**
            *   A new `Agent Snippet` block is created on the Canvas.
            *   The `CanvasBlock.content.agent_config_id` is immediately linked to the `AgentConfiguration.id` of the dragged instance.
            *   The `Agent Snippet` block displays the agent's name, status, and available actions (Run, Configure, etc.), ready for use.
    *   This provides a more fluid way to integrate agents directly into a Canvas workflow.

## 2. Agent Configuration Interface

This interface allows users to define the specific parameters for an `AgentConfiguration` instance.

**2.1. Primary Method (Modal YAML - as per proposal):**

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

**2.2. GUI for Configuration (Considerations):**

*   **Potential:** For agents with a small number of simple parameters, or for common/basic settings of more complex agents, a GUI form could be more user-friendly than raw YAML.
    *   This form could be auto-generated based on the `AgentDefinition.input_schema` (e.g., string inputs become text fields, boolean inputs become checkboxes, enum inputs become dropdowns).
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
*   `Agent Service` validates the YAML (e.g., basic syntax check, potentially against `AgentDefinition.input_schema` if strict validation is enforced).
*   If valid, `Agent Service` updates the `AgentConfiguration` record in the database.
*   If invalid, an error message is shown to the user in the modal.

## 3. Agent Output to Canvas

Agents can present their information and results directly on the Canvas.

**3.1. `Agent Snippet` Block:**

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

**3.2. Output to Other Block Types:**

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

## 4. Agent Output to Chat Dock

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

## 5. Invoking Agent Actions

Agents can be triggered in various ways.

**5.1. From Canvas `Agent Snippet` Block:**

*   User clicks the **"Run Agent"** button on an `Agent Snippet` block.
*   This action sends a request to `Agent Service`, including the `AgentConfiguration.id` associated with that block.
*   **Runtime Parameters:**
    *   For Beta, most parameters are expected to be pre-set in the `AgentConfiguration.yaml_config`.
    *   **Future Consideration:** The `Agent Snippet` block itself could have designated input fields (if defined in `AgentDefinition.input_schema` as "runtime promptable"). Values entered into these fields on the block would be passed as ephemeral, override parameters for that specific run, supplementing the stored YAML config.
        *   Example: A "Topic" text field on a content generation agent's snippet block.

**5.2. Via `/commands` in Chat Dock:**

*   User types a command like `/run_agent <agent_name_or_id> {param1: "value1", param2: 123}`.
*   `Chat Service` parses this command. It identifies the target `AgentConfiguration` (by name or ID lookup via `Agent Service`).
*   It extracts the parameters provided in the command (e.g., the JSON object `{param1: "value1", param2: 123}`).
*   `Chat Service` then sends a request to `Agent Service` to execute the specified `AgentConfiguration.id`, passing along these runtime parameters.
*   These runtime parameters can augment or override settings in the agent's stored `yaml_config` for that specific execution.

**5.3. Scheduled/Automated Triggers (Brief Conceptual Outline):**

This is a future enhancement, but the model should accommodate it.

*   **Scheduled Triggers:**
    *   `AgentConfiguration.yaml_config` could include a `schedule` section (e.g., using cron syntax: `schedule: "0 * * * *"` for hourly).
    *   A dedicated "Scheduler Service" or a component within `Agent Service` would monitor these schedules.
    *   When a scheduled time is reached, the Scheduler triggers `Agent Service` to execute the agent, similar to a manual run but without direct user interaction.
*   **Event-Driven Triggers:**
    *   Certain IONFLUX system events (e.g., "new `Brand` created," "`CanvasPage` updated," another agent completes) could publish messages to an event bus (e.g., Kafka, RabbitMQ).
    *   Agents could be configured (in their `yaml_config`) to subscribe to specific events.
    *   An "Event Listener Service" or component in `Agent Service` would consume these events and trigger relevant agents, passing event payload data as potential input.

## 6. Data Flow for Configuration and Execution

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
```
