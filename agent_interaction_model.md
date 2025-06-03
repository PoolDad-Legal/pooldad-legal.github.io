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
```
