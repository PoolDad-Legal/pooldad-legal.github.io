# IONFLUX Project: Agent Interaction Model - Update Proposals

This document proposes updates to `agent_interaction_model.md`. These changes are necessary to align the agent interaction and configuration model with the recently updated data models for `AgentDefinition` and `AgentConfiguration` (as reflected in the latest `conceptual_definition.md` and detailed in `data_model_update_proposals.md`), which were derived from the comprehensive `core_agent_blueprints.md`.

The key is to ensure the description of how users discover, configure, and interact with agents accurately reflects the richer, more structured nature of agent definitions and configurations.

---

## Proposed Revisions for `agent_interaction_model.md`

Below are proposed textual revisions and additions for relevant sections. Original section numbering from `agent_interaction_model.md` is used for clarity.

### Section 1: Agent Discovery and Instantiation

**1.1. Agent Marketplace:**

*   **Current Implication:** `AgentDefinition`s are somewhat generic templates with `input_schema` and `output_schema`.
*   **Proposed Update to Text:**
    *   Modify the description of `AgentDefinition` cards in the marketplace to reflect the richer information now available (as per the updated `AgentDefinition` schema in `conceptual_definition.md`):
        *   "Each definition is displayed as a card with: `AgentDefinition.name` (e.g., "Email Wizard"), its `epithet` or `tagline` for a quick hook, `AgentDefinition.description`, `AgentDefinition.category`, `AgentDefinition.version`, key `AgentDefinition.underlying_services_required` (e.g., icons for "Shopify," "TikTok," "LLM"), and potentially a summary of its `core_capabilities`."
    *   **Instantiation Process (Step 6):**
        *   **Current:** "`AgentConfiguration.yaml_config` is pre-filled with default parameters derived from the `AgentDefinition.input_schema` (if defined in the schema) or with commented-out examples."
        *   **Proposed Revision for Step 6:** "`AgentConfiguration.yaml_config` is pre-filled. This pre-fill will primarily be structured to accept user values for the parameters defined in `AgentDefinition.inputs_schema`. It may also include commented-out examples of how to override *configurable* aspects of `triggers_config` (like a cron schedule) or `memory_config` (like a namespace suffix), if the specific `AgentDefinition` allows such overrides. Default values specified in `AgentDefinition.inputs_schema` for each input key will be used to populate the initial `yaml_config`."

**1.2. Agent Shelf (Drag-and-Drop):**

*   **Conceptual Flow (If an `AgentDefinition` is dropped - sub-step):**
    *   **Current:** "...user names this new instance and customizes its `yaml_config`."
    *   **Proposed Revision:** "...user names this new instance. The Agent Configuration Interface (Modal YAML editor) opens, pre-filled based on the `AgentDefinition`'s `inputs_schema` and default `triggers_config`. The user then customizes the `yaml_config` by providing necessary input values and any desired overrides for triggers or memory settings."

### Section 2: Agent Configuration Interface

This section requires the most significant updates to reflect the new relationship between `AgentDefinition` and `AgentConfiguration.yaml_config`.

**2.1. Primary Method (Modal YAML):**

*   **Presentation:**
    *   **Current:** "...editor provides YAML syntax highlighting, validation, and potentially auto-completion if the `AgentDefinition.input_schema` is leveraged."
    *   **Proposed Revision:** "...editor provides YAML syntax highlighting and validation. Auto-completion and detailed hints could be offered based on the `AgentDefinition.inputs_schema` (for input values) and the structure of `AgentDefinition.triggers_config` and `AgentDefinition.memory_config` (for overridable parameters). The "Description" panel should not only show `AgentDefinition.description` but also summarize its defined `inputs_schema` (required keys, types, descriptions) and which parts of its triggers or memory are user-configurable."
*   **Pre-filling Default Values:**
    *   **Current:** "If the `AgentDefinition.input_schema` (a JSON Schema object) defines `default` values for properties, these are used to populate the initial YAML."
    *   **Proposed Revision:** "When creating a new `AgentConfiguration` from an `AgentDefinition`, the `yaml_config` editor is pre-filled based on the `AgentDefinition.inputs_schema`. For each input key defined there, if a `default_value` is specified, it's used. Required inputs without defaults will be presented as clear placeholders needing user input. The `yaml_config` will also reflect the default `triggers_config` from the `AgentDefinition`, with comments indicating how users can modify parts (e.g., change a cron string for a 'schedule' trigger, or enable/disable a specific trigger if the definition allows such overrides)."

*   **NEW Sub-section: Understanding `AgentConfiguration.yaml_config` Scope:**
    *   **Purpose:** To explicitly define what goes into the instance's YAML.
    *   **Proposed Text:**
        "The `AgentConfiguration.yaml_config` serves several key purposes for an agent instance:
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
        The Agent Configuration UI should clearly guide users on what is configurable for their specific agent instance based on its parent `AgentDefinition`."

**2.2. GUI for Configuration (Considerations):**

*   **Current:** "This form could be auto-generated based on the `AgentDefinition.input_schema`..."
*   **Proposed Revision:** "This form could be auto-generated primarily from the `AgentDefinition.inputs_schema` (the new array format) to create fields for each defined input key. It could also present user-friendly controls for overriding parts of the `triggers_config` (e.g., a cron schedule builder, webhook URL input) or `memory_config` (e.g., a field for a namespace suffix) if the `AgentDefinition` flags these as configurable by the user."

### Section 3: Agent Output to Canvas

**3.1. `Agent Snippet` Block:**

*   **Output Preview:**
    *   **Current:** "`AgentConfiguration.last_run_output_preview` ... is displayed..."
    *   **Proposed Addition:** "The format and content of this preview are determined by the agent's logic, guided by its `AgentDefinition.outputs_config`. For example, if an output is defined as `type: 'markdown'`, the preview should attempt to render it as such. If multiple outputs are defined, the preview might show a summary or the first key output."

**3.2. Output to Other Block Types:**

*   **Current:** Mentions mapping agent output fields to target block structure.
*   **Proposed Addition/Clarification:** "The `AgentDefinition.outputs_config` lists the `key` and `type` for each potential output of an agent. When configuring an agent to send output to another Canvas block, the user (or the agent's `yaml_config`) would specify which output `key` (e.g., `pnl_dashboard` from Revenue Tracker Lite, which has `type: 'json'`) should populate the target block. The `Canvas Service` or frontend would then need to ensure the content from this output key is compatible with the target block's expected `content` structure (e.g., JSON for a `table_view`, markdown string for a `text` block)."

### Section 4: Agent Output to Chat Dock

*   **Current:** Describes styling and content types like `json_proposal`.
*   **Proposed Addition/Clarification (under Content Types):** "The `AgentDefinition.outputs_config` can guide how agent responses are formatted. If an agent has a defined output of `type: 'markdown'` (e.g., `Slack Brief Butler`'s `daily_brief_url` which implies markdown content), the Chat Service should render this as a markdown message. If an output is `type: 'json'`, it could be presented as a collapsible JSON object or a structured card in the chat."

### Section 5: Invoking Agent Actions

**5.1. From Canvas `Agent Snippet` Block:**

*   **Runtime Parameters:**
    *   **Proposed Revision:** "For Beta, most parameters are expected to be pre-set in the `AgentConfiguration.yaml_config` by providing values for the keys defined in `AgentDefinition.inputs_schema`.
    *   **Future Consideration:** The `Agent Snippet` block itself could have designated input fields if certain `inputs` in the `AgentDefinition.inputs_schema` are flagged as 'runtime_promptable'. Values entered into these fields on the block would be passed as `runtime_params` for that specific run, supplementing or overriding values in the stored `yaml_config`."

**5.2. Via `/commands` in Chat Dock:**

*   **Proposed Revision:** "The `Agent Service` receives these `runtime_params`. It then merges them with the settings defined in `AgentConfiguration.yaml_config`, where `runtime_params` take precedence for keys defined in the `AgentDefinition.inputs_schema`."

### Section 6: Data Flow for Configuration and Execution

This section needs to be updated to reflect the more detailed interaction between `AgentDefinition` and `AgentConfiguration`.

*   **Proposed Revisions:**
    *   **Step 4 (Execution Preparation):** "It fetches the corresponding `AgentDefinition` (which now includes default `triggers_config`, detailed `inputs_schema` array, `outputs_config` array, `stack_details`, `memory_config`, etc.)."
    *   **Step 5 (Parameter Merging - to be more explicit):**
        "**5. Parameter & Configuration Resolution:**
        `Agent Service` resolves the final operational configuration for the run. This involves:
        a.  Starting with the defaults from `AgentDefinition` (for triggers, memory settings, specific model choices if applicable).
        b.  Overriding these defaults with any specific configurations set in `AgentConfiguration.yaml_config` (e.g., a user-defined cron schedule, a specific memory namespace suffix).
        c.  Populating the agent's required inputs (as defined by `AgentDefinition.inputs_schema`) using values from `AgentConfiguration.yaml_config`.
        d.  Further overriding these input values with any `runtime_params` passed in the execution request (e.g., from a chat command or a future dynamic Canvas input).
        e.  The result is an 'effective configuration' used for the current run, a snapshot of which might be stored in `AgentRunLog.input_params_snapshot`."
    *   **Step 6 (Execution Logic):** "...`Agent Service` orchestrates the agent's execution based on its resolved effective configuration and the logic implied by its `AgentDefinition` (including its `stack_details` like language/runtime, and `key_files_and_paths` if relevant for execution)."
    *   **Step 8 (Storing Results):** "...`Agent Service` updates the `AgentConfiguration` record with `last_run_status`, `last_run_at`, `last_run_id`. It also creates an entry in `AgentRunLog` with detailed execution information. The `last_run_output_preview` (a summary) and `last_run_full_output_ref` (a reference to the complete output, if applicable, based on `AgentDefinition.outputs_config`) are updated in the `AgentConfiguration`."

---

These proposed updates should make `agent_interaction_model.md` more consistent with the detailed agent structures defined in `core_agent_blueprints.md` and the corresponding data model revisions.
```
