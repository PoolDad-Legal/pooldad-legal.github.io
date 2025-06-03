# IONFLUX Project: Data Model Update Proposals (Post-Agent Blueprinting)

This document proposes updates to the data models in `conceptual_definition.md` to align them with the detailed specifications provided in `core_agent_blueprints.md`. The goal is to ensure the data models can accurately store and represent the richer information associated with each agent definition and configuration.

## Proposed Updated/New JSON Schemas

Here are the proposed JSON-like structures for modified entities (`AgentDefinition`, `AgentConfiguration`) and any new entities identified as potentially necessary.

```json
{
  "AgentDefinition": { // For marketplace/templates - MODIFIED
    "id": "string (UUID or agent_xxx format from blueprints)", // To match blueprint `id: agent_001`
    "name": "string (unique, e.g., 'EmailWizard', 'ShopifySalesSentinel')", // Matches blueprint `name`
    "epithet": "string (nullable, e.g., 'Pulse of the Inbox')", // From Header Narrativo
    "tagline": "string (nullable)", // From Header Narrativo
    "introduction_text": "text (nullable)", // Full 22-line intro
    "archetype": "string (nullable, e.g., 'Magician')", // From Essência
    "dna_phrase": "string (nullable, e.g., 'Faz o invisível falar e vender')", // From Essência
    "core_capabilities": ["string (nullable)"], // List from Principais Capacidades
    "essence_punch": "string (nullable)", // From PoolDad/Essência 22,22%
    "essence_interpretation": "text (nullable)", // From PoolDad/Essência 22,22%
    "version": "string (semver, e.g., '0.1')", // From blueprint YAML
    "description": "text (High-level description, already present, can be enriched)",
    "triggers_config": [ // NEW: To store trigger definitions
      {
        "type": "string (enum: 'schedule', 'webhook', 'event')",
        "config": "json_object" // For 'schedule': {"cron": "0 */2 * * *"}, for 'webhook': {"path": "/emailwizard/run", "method": "POST/GET"}
      }
    ],
    "inputs_schema": [ // NEW: More structured than just input_schema (JSON Schema)
                       // This defines the expected keys and types for `AgentConfiguration.yaml_config`
      {
        "key": "string", // e.g., "shopify_event", "manual_payload"
        "type": "string (enum: 'json', 'string', 'number', 'boolean')",
        "required": "boolean",
        "description": "text (nullable)"
      }
    ],
    "outputs_config": [ // NEW: Defines expected outputs
      {
        "key": "string", // e.g., "send_report", "match_table"
        "type": "string (enum: 'json', 'string', 'md', 'url')",
        "description": "text (nullable)"
      }
    ],
    "stack_details": { // NEW: To store technical stack
      "language": "string (e.g., 'python')",
      "runtime": "string (e.g., 'langchain', 'fastapi')",
      "models_used": ["string (e.g., 'openai:gpt-4o')"], // List of models
      "database_dependencies": ["string (nullable, e.g., 'Postgres', 'Pinecone')"], // From "Data Store" section
      "queue_dependencies": ["string (nullable, e.g., 'Redis + RQ', 'Kafka')"], // From "Stack & APIs"
      "other_integrations": ["string (nullable, e.g., 'Sendgrid', 'Meta WhatsApp Cloud API')"] // From "Stack & APIs"
    },
    "memory_config": { // NEW: For agent's memory system
      "type": "string (nullable, e.g., 'pinecone', 'redis')",
      "namespace_template": "string (nullable, e.g., 'emailwizard_instance_{{instance_id}}')" // Could be a template
    },
    "default_file_structure_template": "text (nullable)", // Stores the example file structure
    "key_files_and_paths": "json_object (nullable)", // Could store a structured representation of `Files & Paths`
    "scheduling_and_triggers_summary": "text (nullable)", // Narrative summary of scheduling
    "kpis_definition": "text (nullable)", // Narrative or structured KPIs
    "failure_fallback_strategy": "text (nullable)", // Narrative
    "example_integration_flow": "text (nullable)", // Narrative
    "dynamic_expansion_notes": "text (nullable)", // Narrative for future versions
    "escape_the_obvious_feature": "text (nullable)", // Narrative
    "underlying_services_required": ["string (enum: 'LLM', 'Shopify', 'TikTok', 'WebSearch', 'Email', 'WhatsApp')"], // Existing, ensure comprehensive
    "category": "string (e.g., 'Marketing', 'Content Creation', 'Sales', 'Productivity')", // Existing
    "created_at": "timestamp",
    "updated_at": "timestamp",
    "status": "string (enum: 'draft', 'active', 'deprecated', default: 'draft')" // Added for lifecycle
  },

  "AgentConfiguration": { // Instance of an AgentDefinition - MODIFIED
    "id": "string (UUID)",
    "workspace_id": "string (references Workspace.id, indexed)",
    "agent_definition_id": "string (references AgentDefinition.id, indexed)", // Existing
    "name": "string", // User-defined name for this instance, Existing
    "description": "text (nullable)", // User-defined description, Existing
    "created_by_user_id": "string (references User.id, indexed)", // Existing
    "yaml_config": "text (yaml format)", // Existing: Stores instance-specific values for inputs defined in AgentDefinition.inputs_schema
                                        // This IS where the user customizes the 'inputs' from the definition.
    "effective_config_cache": "json_object (nullable)", // Optional: A cache of merged definition defaults + yaml_config
    "external_memory_namespace": "string (nullable)", // Instance-specific namespace if AgentDefinition.memory_config.namespace_template is used
    "last_run_status": "string (enum: 'idle', 'pending', 'running', 'success', 'error', 'cancelled', nullable)", // 'pending' added
    "last_run_at": "timestamp (nullable)", // Existing
    "last_run_id": "string (UUID, nullable)", // To correlate with async runs
    "last_run_output_preview": "text (nullable)", // Existing
    "last_run_full_output_ref": "string (nullable, URI to full output if stored elsewhere, e.g. S3)", // NEW
    "created_at": "timestamp",
    "updated_at": "timestamp",
    "status": "string (enum: 'active', 'inactive', 'archived', default: 'active')" // Added for lifecycle
  },

  "AgentRunLog": { // NEW: To track individual agent executions
    "id": "string (UUID, primary_key, default: uuid_generate_v4())",
    "agent_configuration_id": "string (references AgentConfiguration.id, indexed)",
    "run_id": "string (UUID, unique, indexed)", // Matches AgentConfiguration.last_run_id at time of run
    "triggered_by_user_id": "string (references User.id, nullable)",
    "trigger_type": "string (enum: 'manual', 'schedule', 'webhook', 'command')",
    "status": "string (enum: 'pending', 'running', 'success', 'error', 'cancelled')",
    "start_time": "timestamp",
    "end_time": "timestamp (nullable)",
    "input_params_snapshot": "json_object (nullable)", // Snapshot of effective_config used for this run
    "output_preview": "text (nullable)",
    "full_output_ref": "string (nullable, URI to full output)",
    "error_message": "text (nullable)",
    "logs_ref": "string (nullable, URI to detailed logs if stored elsewhere)"
  },

  "Playbook": { // NEW: For agents like WhatsAppPulse that use playbooks
    "id": "string (UUID, primary_key, default: uuid_generate_v4())",
    "agent_definition_id": "string (references AgentDefinition.id, indexed, nullable, if it's a default playbook)",
    "agent_configuration_id": "string (references AgentConfiguration.id, indexed, nullable, if customized for an instance)",
    "workspace_id": "string (references Workspace.id, indexed, if custom to workspace)",
    "name": "string (e.g., 'Abandoned Cart Recovery - Aggressive')",
    "description": "text (nullable)",
    "trigger_event_type": "string (e.g., 'shopify_abandoned_cart', 'manual_list_upload')",
    "steps": "json_array_of_objects",
    // Example step: {"type": "send_whatsapp_message", "template_id": "xyz", "delay_minutes": 10, "condition": "cart_value > 50"}
    // Example step: {"type": "llm_personalize_message", "prompt_template_key": "whatsapp_cart_recovery_tone_X"}
    "is_active": "boolean (default: true)",
    "created_at": "timestamp",
    "updated_at": "timestamp"
  }

  // Note: Badge and XP related tables might be needed for `BadgeMotivator`
  // e.g., `BadgesDefinition`, `UserBadges`, `UserXPLog`. For this proposal,
  // we'll assume these could initially be managed via generic event tracking
  // or within AgentConfiguration's output/state if simple, deferring dedicated tables.
}
```

## Rationale for Changes

### 1. `AgentDefinition` Entity Modifications:

The previous `AgentDefinition` was quite minimal. The new agent blueprints provide rich, structured information about what an agent is, how it's triggered, its technical makeup, and its operational parameters.

*   **`id` and `name`**: The blueprints use specific IDs like `agent_001` and names like `EmailWizard`. The schema should reflect this. `name` should be unique.
*   **Narrative Fields**: `epithet`, `tagline`, `introduction_text`, `archetype`, `dna_phrase`, `core_capabilities`, `essence_punch`, `essence_interpretation` are added to capture the rich descriptive and conceptual elements from the blueprints (Sections 0, 1, 2). This is vital for the Agent Marketplace and user understanding.
*   **`version`**: Explicitly added as a top-level field as seen in the agent YAMLs.
*   **`triggers_config` (New Array of Objects)**:
    *   **Rationale**: Agent YAMLs clearly define `triggers` with `type` (schedule, webhook) and specific configurations (`cron` expression, `path`). The old model didn't store this.
    *   **Structure**: An array to allow multiple triggers. Each object has a `type` and a flexible `config` JSON object to store type-specific settings.
*   **`inputs_schema` (New Array of Objects - Replaces/Enhances `input_schema`)**:
    *   **Rationale**: The agent YAMLs have an `inputs` array detailing `key`, `type`, `required`. The existing `input_schema: json_schema` is good for validation but doesn't explicitly list expected input keys in a simple way for UI generation or documentation. This new structure makes input parameters more explicit and can still be used to generate a JSON schema for validation if needed.
    *   **Structure**: Array of objects, each defining an input parameter.
*   **`outputs_config` (New Array of Objects - Replaces/Enhances `output_schema`)**:
    *   **Rationale**: Similar to `inputs_schema`, agent YAMLs define `outputs`. This makes the expected outputs explicit.
    *   **Structure**: Array of objects, each defining an output.
*   **`stack_details` (New Object)**:
    *   **Rationale**: Agent YAMLs detail `stack` (language, runtime, models) and the markdown specifies other tech (DBs, Queues, etc. in section 6 & 7). This consolidates technical stack information.
    *   **Structure**: Nested object for clarity. `models_used`, `database_dependencies`, `queue_dependencies`, `other_integrations` are arrays of strings.
*   **`memory_config` (New Object)**:
    *   **Rationale**: Agent YAMLs specify `memory` (type, namespace). This is crucial for agents using external vector stores like Pinecone. The `namespace_template` allows for dynamic namespace creation per instance if needed.
*   **`default_file_structure_template` (New Text field)**:
    *   **Rationale**: To store the example file structures shown in section "7 ▸ Files & Paths" of the blueprints, aiding developers or advanced users.
*   **`key_files_and_paths` (New JSON Object)**:
    *   **Rationale**: A more structured way to store the file paths, potentially useful for agent scaffolding or documentation.
*   **Narrative Fields from Blueprints**: Added fields like `scheduling_and_triggers_summary`, `kpis_definition`, `failure_fallback_strategy`, etc., to directly map the descriptive sections from the blueprints.
*   **`underlying_services_required`**: Ensured it's comprehensive to include new types like 'Email', 'WhatsApp'.
*   **`status`**: Added for agent definition lifecycle management (e.g., 'draft', 'active', 'deprecated').

### 2. `AgentConfiguration` Entity Modifications:

*   **`yaml_config`**: This field remains crucial. It's where users will provide instance-specific values for the `inputs` defined in `AgentDefinition.inputs_schema`. For example, for `EmailWizard`, the `yaml_config` might contain specific `shopify_event` details or `manual_payload` content for a particular run or setup.
*   **`effective_config_cache` (New JSON Object)**:
    *   **Rationale**: For performance and clarity, it can be useful to store the result of merging `AgentDefinition` defaults with the instance's `yaml_config`. This is what the agent actually runs with.
*   **`external_memory_namespace` (New String)**:
    *   **Rationale**: If an `AgentDefinition`'s `memory_config` specifies a `namespace_template` (e.g., `emailwizard_instance_{{instance_id}}`), this field would store the actual, resolved namespace for this specific configuration instance (e.g., `emailwizard_instance_abcdef12345`).
*   **`last_run_id` (New String)**:
    *   **Rationale**: To link an agent configuration to its specific execution log entries in `AgentRunLog`.
*   **`last_run_full_output_ref` (New String)**:
    *   **Rationale**: Agent outputs can be large. Storing a reference (like an S3 URI or an ID to another table/document store) is more scalable than putting large JSON/text directly in the configuration's preview field.
*   **`status`**: Added for instance lifecycle (e.g., allowing users to temporarily disable an agent configuration).
*   **`last_run_status`**: Added 'pending' to the enum to reflect the state after triggering and before completion.

### 3. New Entity: `AgentRunLog`

*   **Rationale**: The `AgentConfiguration` stores the *last* run's details. A dedicated `AgentRunLog` table is essential for auditing, history, and debugging. It tracks every individual execution attempt. This is implied by the need to see historical runs and their statuses, as mentioned in `ui_ux_concepts.md` for agent views.
*   **Fields**: Captures `run_id`, link to configuration, trigger info, status, timings, a snapshot of input parameters (very important for reproducibility), and references to outputs/logs.

### 4. New Entity: `Playbook`

*   **Rationale**: Specifically called out by `AGENTE 002 — WHATSAPP PULSE` which has a `playbooks/` directory and mentions different playbooks (abandoned_cart, vip_upsell). This suggests playbooks are reusable, potentially customizable sets of rules or steps that an agent instance can execute.
*   **Fields**: Links to an agent definition (for default playbooks) or a configuration (for customized versions), name, trigger type, and a JSON field for steps. This allows for structured definition of multi-step agent behaviors.

### 5. External Data Stores (e.g., Pinecone Namespaces):

*   The `AgentDefinition.memory_config.namespace_template` and `AgentConfiguration.external_memory_namespace` fields address this.
*   **Rationale**: Many agents in the blueprints (EmailWizard, TikTokStylist, etc.) specify using Pinecone with specific namespaces. Making this configurable or at least referenceable in the definition/configuration is important. The `namespace_template` in `AgentDefinition` allows a base definition (e.g., `customer_profiles_for_{{workspace_id}}`) and the `AgentConfiguration` can store the resolved, instance-specific namespace.

These proposed changes aim to make the core data models significantly more representative of the detailed agent designs, providing a better foundation for development.
```
