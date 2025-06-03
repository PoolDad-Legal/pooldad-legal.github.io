```markdown
# IONFLUX Project: Agent Interaction & Configuration Model (v3 Proposals)

This document defines how users discover, configure, interact with, and manage agents within the IONFLUX platform. It is updated to align with the detailed agent specifications in `core_agent_blueprints_v3.md` (PRM version) and the data structures in `conceptual_definition_v3.md`.

## 1. Agent Discovery and Instantiation

Agents in IONFLUX are based on `AgentDefinition`s (templates with fixed IDs like `agent_001`) and are instantiated and customized by users as `AgentConfiguration`s.

**1.1. Agent Marketplace:**

*   **Browsing and Selection:**
    *   Users access the Agent Marketplace via the "Agent Hub" in the sidebar.
    *   The marketplace displays `AgentDefinition`s as cards, showcasing:
        *   `AgentDefinition.name` (e.g., "Email Wizard v0.1").
        *   `AgentDefinition.prm_details_json.epithet` and `prm_details_json.tagline`.
        *   A summary of `AgentDefinition.prm_details_json.introduction_text` or a dedicated short description.
        *   `AgentDefinition.category_tags_array` (e.g., "Marketing", "E-commerce").
        *   Icons representing `AgentDefinition.underlying_platform_services_required_array` (e.g., Shopify, TikTok, LLM).
        *   A summary of `AgentDefinition.prm_details_json.core_capabilities_array`.
    *   Filters allow users to search by category, required services, capabilities, or keywords.
    *   Clicking a card might show a detailed view with more `prm_details_json` and schema overviews.
*   **Creating an `AgentConfiguration` (Instantiation):**
    1.  User selects an `AgentDefinition` (e.g., `agent_001`) from the marketplace.
    2.  This initiates the creation of a new `AgentConfiguration` record, linking it to the chosen `AgentDefinition.id` and `version`.
    3.  The user is navigated to the Agent Configuration Interface (Section 2) for this new instance.
    4.  The user provides a unique `AgentConfiguration.name` for their instance (e.g., "My Abandoned Cart Email Sequence").
    5.  `AgentConfiguration.yaml_config_text` is pre-filled based on the `AgentDefinition` (see Section 2.2).

**1.2. Agent Shelf (Drag-and-Drop on Canvas):**

*   **Content:** The Agent Shelf provides quick access to:
    *   All available `AgentDefinition`s (templates).
    *   User's existing `AgentConfiguration`s (instances).
*   **Flow (Dragging `AgentDefinition` to Canvas):**
    1.  User drags an `AgentDefinition` icon from the Shelf onto a `CanvasPage`.
    2.  A new `Agent Snippet` block is created.
    3.  The Agent Configuration Interface (modal) opens, pre-filled for the chosen `AgentDefinition`.
    4.  User names the new `AgentConfiguration` instance and customizes its `yaml_config_text`.
    5.  The `CanvasBlock.content_json.agent_configuration_id` is linked to this new instance.
*   **Flow (Dragging existing `AgentConfiguration` to Canvas):**
    1.  User drags an `AgentConfiguration` icon from the Shelf.
    2.  A new `Agent Snippet` block is created, its `agent_configuration_id` immediately linked. The block is ready for use.

## 2. Agent Configuration Interface

This interface, primarily a modal, allows users to define instance-specific settings for an `AgentConfiguration`. It clearly distinguishes between read-only information from the `AgentDefinition` and the user-editable `yaml_config_text`.

**2.1. Layout: Two-Pane or Tabbed Modal**

*   **Pane 1: Agent Definition Information (Read-Only)**
    *   Displays key details from the parent `AgentDefinition` to provide context:
        *   `name`, `version`, `definition_status`.
        *   `prm_details_json.epithet`, `prm_details_json.tagline`, `prm_details_json.introduction_text`.
        *   **Inputs Overview:** A user-friendly summary of `inputs_schema_json_array` (key names, types, descriptions, if required, default values).
        *   **Outputs Overview:** A summary of `outputs_config_json_array` (key names, types, descriptions).
        *   **Default Triggers:** Lists triggers from `triggers_config_json_array`, indicating which parts are configurable.
        *   **Memory Configuration:** Describes `memory_config_json` (type, default namespace template, description).
        *   **Key Stack Elements:** Relevant parts of `stack_details_json` (e.g., compatible LLM models if selectable, primary language/runtime for informational purposes).
*   **Pane 2: Instance Configuration (Editable)**
    *   `AgentConfiguration.name` (text input).
    *   `AgentConfiguration.description_text` (text area, optional).
    *   `AgentConfiguration.yaml_config_text` (YAML editor, see details below).

**2.2. `AgentConfiguration.yaml_config_text` Scope and Content:**

This YAML field is for instance-specific settings and input values. It typically includes the following top-level keys:

*   **`inputs:`**
    *   **Purpose:** To provide values for parameters defined in `AgentDefinition.inputs_schema_json_array`.
    *   **Structure:** A map where keys match `key_name` from the schema.
    *   **Guidance:** The UI (comments in YAML or future GUI) should guide users on required inputs, types, and accepted values based on the schema. Default values from the schema are used if not provided for optional inputs.
    *   *Example:*
        ```yaml
        inputs:
          target_audience_description: "Tech-savvy early adopters interested in AI."
          max_results: 10 
        ```
*   **`triggers:` (Optional)**
    *   **Purpose:** To override user-configurable aspects of triggers defined in `AgentDefinition.triggers_config_json_array`.
    *   **Structure:** An array where each item references a trigger from the definition (e.g., by its type or a unique key if provided in `AgentDefinition`) and specifies overrides.
    *   **Guidance:** Only parts of a trigger marked as `is_user_overridable: true` in the `AgentDefinition` can be modified here.
    *   *Example:*
        ```yaml
        triggers:
          - trigger_definition_key: "daily_schedule" # Assumes AgentDefinition gives a key to identify the trigger
            enabled: true # Overriding the enabled state
            config_override:
              cron_expression: "0 8 * * 1-5" # New cron
          - trigger_definition_key: "shopify_order_event"
            config_override:
              event_filter_json: # Specific filter for this instance
                min_order_value: 100 
        ```
*   **`memory:` (Optional)**
    *   **Purpose:** To customize user-configurable parts of `AgentDefinition.memory_config_json`.
    *   **Structure:** A map for memory-specific overrides.
    *   *Example (if `default_namespace_template` in definition was `agent_{{agent_id}}_ws_{{workspace_id}}_{{instance_suffix}}`):*
        ```yaml
        memory:
          instance_suffix: "q4_campaign_analysis" 
        ```
*   **`stack_preferences:` (Optional)**
    *   **Purpose:** To select from options if `AgentDefinition.stack_details_json` allows choices (e.g., preferred LLM model).
    *   *Example (if `AgentDefinition` lists compatible LLMs):*
        ```yaml
        stack_preferences:
          llm_model: "anthropic:claude-3-haiku" 
        ```
*   **`advanced_features:` (Optional, Conceptual for PRM items)**
    *   **Purpose:** To enable/configure experimental modes or specific parameters for features like "Arm Z" testing or RL loops if the `AgentDefinition` supports them.
    *   *Example:*
        ```yaml
        advanced_features:
          arm_z_experiment_enabled: true
          reinforcement_learning_config:
            reward_threshold: 0.85
        ```

**2.3. Saving and Validation:**
*   Frontend sends `name`, `description_text`, and `yaml_config_text` to `AgentService`.
*   `AgentService` validates `yaml_config_text` against:
    *   Basic YAML syntax.
    *   Presence of required inputs (from `AgentDefinition.inputs_schema_json_array`).
    *   Type correctness of input values.
    *   Validity of overrides for triggers, memory, and stack (i.e., only overriding what the definition allows).
*   Stores validated configuration. `AgentService` may generate/update `AgentConfiguration.effective_config_cache_json` upon save.

## 3. Agent Output Presentation

**3.1. On Canvas (`Agent Snippet` Block):**

*   **Primary Display:** The `Agent Snippet` block shows `AgentConfiguration.name`, status, and `AgentConfiguration.last_run_summary_json.output_preview_text`.
*   **Multiple Outputs:** If `AgentDefinition.outputs_config_json_array` defines multiple outputs, the `output_preview_text` should be a concise summary or represent a designated "primary" output. The user might configure in `yaml_config_text` which output key to feature in the preview if the definition supports it.
    *   *Example in `yaml_config_text`*: `snippet_preview_output_key: "summary_table_markdown"`
*   **"View Full Output":**
    *   This action retrieves the corresponding `AgentRunLog`.
    *   The modal displays data from `AgentRunLog.output_data_json.outputs_array`.
    *   If multiple outputs exist in the array, the modal should allow the user to select which output `key_name` to view.
    *   The content is rendered based on its `data_type` (e.g., JSON pretty-printed, Markdown rendered as HTML, URL as a clickable link).
    *   If `AgentRunLog.full_output_ref_url` exists (for very large outputs), a link to this URL is provided.

**3.2. In Chat Dock:**

*   Agent messages (`ChatMessage.sender_type='agent'`) use `ChatMessage.content_json` and `ChatMessage.content_type` to render outputs.
*   The specific output key from `AgentDefinition.outputs_config_json_array` being sent to chat would be determined by the agent's logic for that chat interaction.
*   **Event Outputs:** If an agent output is `type: 'event'` with a `target_event_type`, this typically doesn't render directly in chat as that output. Instead, the agent might send a separate chat message confirming "Event [event_type] published successfully." The actual event is processed by Kafka consumers.

## 4. Invoking Agent Actions

**4.1. From Canvas `Agent Snippet` Block:**
*   Clicking "Run Agent" sends `AgentConfiguration.id` to `AgentService`.
*   `runtime_params` can be passed if the snippet block UI evolves to include dynamic input fields based on `AgentDefinition.inputs_schema_json_array` (where certain inputs are marked as "runtime promptable").

**4.2. Via `/commands` in Chat Dock:**
*   Command: `/run_agent <agent_config_name_or_id> {json_runtime_params}`.
*   `ChatService` resolves `agent_config_name_or_id` to `AgentConfiguration.id`.
*   The `{json_runtime_params}` are passed as `runtime_params` to `AgentService`.

## 5. Data Flow for Configuration and Execution (Aligned with `conceptual_definition_v3.md`)

1.  **Discovery & Instantiation:** User selects an `AgentDefinition` (e.g., `agent_001`, version `0.2`). Frontend initiates creation of `AgentConfiguration` linked to `agent_001/0.2`.
2.  **Configuration:** User provides `name` and `yaml_config_text` for the instance. `AgentService` validates and stores it.
3.  **Triggering:** User clicks "Run Agent" or issues a chat command. Request includes `AgentConfiguration.id` and any `runtime_params`.
4.  **Execution Preparation (`AgentService`):**
    *   Retrieves `AgentConfiguration` (with `yaml_config_text`) and its linked `AgentDefinition` (with all its detailed schemas and default configs).
5.  **Effective Configuration Resolution (`AgentService`):**
    *   **Start with `AgentDefinition` defaults:** Base values for triggers, memory, stack options.
    *   **Apply `AgentConfiguration.yaml_config_text`:**
        *   Values provided under `inputs:` key populate the agent's operational inputs.
        *   Overrides for `triggers:`, `memory:`, `stack_preferences:` are applied if valid against `AgentDefinition`.
    *   **Apply `runtime_params`:** Values from invocation override any corresponding input values derived from `yaml_config_text`.
    *   The final, merged configuration is the "effective configuration" for this run. A snapshot is stored in `AgentRunLog.input_params_resolved_json`.
    *   `AgentConfiguration.resolved_memory_namespace_text` is determined by applying instance specifics from `yaml_config_text` to `AgentDefinition.memory_config_json.default_namespace_template`.
6.  **Execution Logic (`AgentService` orchestrating the agent runtime):**
    *   Agent logic executes based on the "effective configuration" and its defined `stack_details_json`.
    *   Makes calls to other IONFLUX services (e.g., `LLMOrchestrationService`, `ShopifyIntegrationService`, `AudioService`) or external APIs as needed.
7.  **Output & Status:** Agent logic produces outputs according to its `AgentDefinition.outputs_config_json_array`.
8.  **Storing Results (`AgentService`):**
    *   Creates `AgentRunLog` entry with `run_id`, `agent_definition_id_version`, `status`, `start_time`, `input_params_resolved_json`.
    *   When execution finishes, updates `AgentRunLog` with `end_time`, final `status`, `output_data_json` (containing all keyed outputs or their references), `output_preview_text`, `error_details_json` (if any), `kpi_results_json`.
    *   Updates `AgentConfiguration.last_run_summary_json`.
9.  **Presentation/Notification:**
    *   `AgentService` publishes `ionflux.agent.run.completed` event to Kafka.
    *   Relevant UI components (Canvas Snippet, Chat) update based on this event (e.g., via a WebSocket service listening to Kafka) or by re-fetching `AgentConfiguration`.

## 6. Inter-Agent Communication & Event Handling (User Perspective)

*   **Consuming Kafka Events:**
    *   If an `AgentDefinition.triggers_config_json_array` includes an `event_stream` trigger, the Information Panel in the config modal will show the default `kafka_topic_name` and `event_filter_json`.
    *   If `is_user_overridable: true`, the user can specify or refine these in `AgentConfiguration.yaml_config_text` under the `triggers:` section for that specific trigger definition key.
    *   *Example in `yaml_config_text`*:
        ```yaml
        triggers:
          - trigger_definition_key: "consume_shopify_orders"
            config_override:
              kafka_topic_name: "custom_shopify_orders_topic_for_my_workspace" # If allowed by platform
              event_filter_json:
                payload_json.total_price_usd_gt: 100 
        ```
*   **Producing Kafka Events:**
    *   If an `AgentDefinition.outputs_config_json_array` includes an output of `type: 'event'`, the `target_event_type` is usually fixed by the definition (e.g., `ionflux.agent.emailwizard.email_sent`). This would be displayed in the Information Panel.
    *   The user generally doesn't configure *what* event is published, but they use the agent whose *purpose* is to publish that event. The UI might acknowledge such an output upon successful run (e.g., "Email Wizard finished and published 'email_sent' event.").

## 7. Interacting with Advanced Agent Modes (Conceptual)

Some PRM agent blueprints mention "Arm Z" experiments, Reinforcement Learning (RL) loops, or other advanced operational modes.

*   **Configuration:**
    *   If an `AgentDefinition` supports such modes, its `inputs_schema_json_array` might include keys to enable/disable them or provide specific parameters (e.g., `enable_experimental_mode: boolean`, `rl_learning_rate: float`).
    *   Users would set these in the `inputs:` section of their `AgentConfiguration.yaml_config_text` or a dedicated `advanced_features:` section as shown in 2.2.
    *   The Information Panel should clearly document these advanced configuration options if available.
*   **Monitoring Results:**
    *   Outputs from experimental runs or RL training steps might be captured in specific keys within `AgentRunLog.output_data_json` or logged to `logs_storage_ref_url`.
    *   The agent's `prm_details_json.kpis_definition_text` might include metrics specific to these advanced modes.
    *   The UI for "View Full Output" would be the primary way to inspect these results, assuming the agent formats them as one of its defined outputs.
*   **Control:** Users typically control these modes by adjusting the `yaml_config_text` and re-running the agent, or by interacting with specific commands if the agent supports dynamic control of experiments.

This revised model aims to provide a robust framework for user interaction with the advanced, PRM-defined agents, emphasizing clarity in configuration and the flow of data.
```
