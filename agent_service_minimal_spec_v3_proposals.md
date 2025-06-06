```markdown
# IONFLUX Project: Minimal Viable Agent Service Specification (v3 Proposals)

This document proposes updates for the Agent Service specification, aligning it with `core_agent_blueprints_v3.md` (PRM), `conceptual_definition_v3.md`, `technical_stack_and_demo_strategy_v3.md`, and `agent_interaction_model_v3.md`.

**Version Note:** This is v3 of the Agent Service minimal specification.

**Chosen Technology:** Python with FastAPI (reconfirmed as per `technical_stack_and_demo_strategy_v3.md`).

## 1. API Endpoints (RESTful)

All endpoints are protected by JWT authentication (FastAPI dependency). Authorization logic (workspace membership, ownership) is handled per endpoint.

### 1.1. `AgentDefinition` Management

#### 1.1.1. `GET /agent-definitions`
*   **Purpose:** Retrieves a list of available agent definitions.
*   **Response (Success 200 - OK):** Array of full `AgentDefinition` objects (as per `conceptual_definition_v3.md`).
    ```json
    [
      {
        "id": "agent_001", // From PRM
        "name": "Email Wizard",
        "version": "0.1",
        "definition_status": "prm_active",
        "prm_details_json": { /* ... narrative content from PRM ... */ },
        "triggers_config_json_array": [ /* ... structured trigger configs ... */ ],
        "inputs_schema_json_array": [ /* ... structured input schemas ... */ ],
        "outputs_config_json_array": [ /* ... structured output schemas ... */ ],
        "stack_details_json": { /* ... detailed stack info ... */ },
        "deployment_info_json": { /* ... demo_shell_url, demo_n8n_webhook_url, etc. ... */ },
        "memory_config_json": { /* ... memory config ... */ },
        "category_tags_array": ["Email", "Marketing"],
        "underlying_platform_services_required_array": ["LLM_Orchestration", "Email_Dispatch"],
        "created_at": "timestamp",
        "updated_at": "timestamp"
      }
    ]
    ```
*   **Brief Logic:** Fetches all records from `agent_definitions` table. For demo, these are seeded from PRM blueprints.

#### 1.1.2. `GET /agent-definitions/{agent_definition_id}`
*   **Purpose:** Retrieves details for a specific agent definition.
*   **Path Parameter:** `agent_definition_id` (e.g., "agent_001").
*   **Response (Success 200 - OK):** Single full `AgentDefinition` object.
*   **Brief Logic:** Fetches the specified record from `agent_definitions`.

#### 1.1.3. `POST /agent-definitions` (Conceptual - Not for E2E Demo Active Use)
*   **Purpose:** Allows dynamic creation of new agent definitions (future feature).
*   **Note:** For the E2E demo, `AgentDefinition`s are pre-loaded from `core_agent_blueprints_v3.md` via `initial_schema_demo_v3.sql`. This endpoint would not be actively used in the demo.

### 1.2. `AgentConfiguration` Management

#### 1.2.1. `POST /workspaces/{workspace_id}/agent-configurations`
*   **Purpose:** Creates a new agent configuration (instance) within a workspace.
*   **Request Body:**
    ```json
    {
      "name": "string",
      "description_text": "string (optional)",
      "agent_definition_id": "string (e.g., 'agent_001')", // Refers to AgentDefinition.id
      "yaml_config_text": "string (YAML content)"
    }
    ```
*   **Response (Success 201 - Created):** Full V3 `AgentConfiguration` object.
    ```json
    {
      "id": "uuid",
      "workspace_id": "uuid",
      "agent_definition_id": "string", // e.g., "agent_001"
      "name": "string",
      "description_text": "string (nullable)",
      "created_by_user_id": "uuid", // from JWT
      "yaml_config_text": "string",
      "effective_config_cache_json": null, // May be populated later or by a background process
      "resolved_memory_namespace_text": "string (nullable)", // Resolved based on definition and yaml_config
      "status": "active",
      "last_run_summary_json": null,
      "created_at": "timestamp",
      "updated_at": "timestamp"
    }
    ```
*   **Brief Logic:**
    1.  JWT Auth & Workspace Authorization.
    2.  Retrieve `AgentDefinition` using `agent_definition_id`.
    3.  Validate `yaml_config_text` structure and content against `AgentDefinition.inputs_schema_json_array` and other configurable aspects (triggers, memory, stack preferences) defined as overridable in the `AgentDefinition`.
    4.  If `AgentDefinition.memory_config_json.required` is true, resolve the `resolved_memory_namespace_text` using `AgentDefinition.memory_config_json.default_namespace_template` and any relevant values from `yaml_config_text`.
    5.  Create and store the `agent_configurations` record.
    6.  Return created object.

#### 1.2.2. `GET /workspaces/{workspace_id}/agent-configurations`
*   **Purpose:** Retrieves agent configurations for a workspace.
*   **Response (Success 200 - OK):** Array of V3 `AgentConfiguration` objects (can be a summary view, but full object for consistency in demo).

#### 1.2.3. `GET /agent-configurations/{agent_configuration_id}`
*   **Purpose:** Retrieves a specific agent configuration.
*   **Response (Success 200 - OK):** Single V3 `AgentConfiguration` object.

#### 1.2.4. `PUT /agent-configurations/{agent_configuration_id}`
*   **Purpose:** Updates an agent configuration.
*   **Request Body:**
    ```json
    {
      "name": "string (optional)",
      "description_text": "string (optional)",
      "yaml_config_text": "string (optional)"
    }
    ```
*   **Response (Success 200 - OK):** Updated V3 `AgentConfiguration` object.
*   **Brief Logic:** Similar to POST, includes validation of `yaml_config_text` if provided.

#### 1.2.5. `DELETE /agent-configurations/{agent_configuration_id}`
*   **Purpose:** Archives an agent configuration (soft delete).
*   **Response (Success 200 - OK):** Updated V3 `AgentConfiguration` object with status 'archived'.
*   **Brief Logic:** Sets `status` field to 'archived'.

## 2. Agent Execution & Lifecycle

### 2.1. `POST /agent-configurations/{agent_configuration_id}/run`
*   **Purpose:** Triggers the execution of a configured agent.
*   **Request Body:**
    ```json
    {
      "runtime_params": {} // JSON object (optional, Dict in Python)
    }
    ```
*   **Response (Success 202 - Accepted):**
    ```json
    {
      "run_id": "uuid",
      "agent_configuration_id": "uuid",
      "status": "pending",
      "message": "Agent run initiated."
    }
    ```
*   **Brief Logic:**
    1.  JWT Auth & Workspace/Configuration Authorization.
    2.  Retrieve `AgentConfiguration` (with `yaml_config_text`) and its parent `AgentDefinition`.
    3.  **Effective Configuration Resolution:**
        *   Start with `AgentDefinition` defaults (triggers, memory, stack options).
        *   Apply instance-specific settings from `AgentConfiguration.yaml_config_text` (inputs, trigger overrides, memory overrides, stack preferences).
        *   Merge/override with `runtime_params` from the request.
        *   This final "effective configuration" is prepared as JSON.
    4.  Generate a unique `run_id`. Create an `AgentRunLog` entry with this `run_id`, `status: 'pending'`, `agent_definition_id_version` (from `AgentDefinition`), and store the `input_params_resolved_json` (the effective configuration).
    5.  **Triggering Mechanism (E2E Demo):**
        *   Examine `AgentDefinition.deployment_info_json.demo_execution_type`.
        *   If `'python_shell'`: Asynchronously POST `{"run_id": "...", "effective_config_json": { ... }}` to the URL in `AgentDefinition.deployment_info_json.demo_shell_url`.
        *   If `'n8n_webhook'`: Asynchronously POST `{"run_id": "...", "effective_config_json": { ... }}` to the URL in `AgentDefinition.deployment_info_json.demo_n8n_webhook_url`.
        *   If `'internal_mock'`: Handle with simplified internal logic for peripheral demo agents (not the key Python shell ones).
    6.  Return 202 Accepted with `run_id` and initial status.

### 2.2. `POST /agent-runs/{run_id}/completed` (Callback Endpoint)
*   **Purpose:** Webhook for agent execution environments (Python shells, n8n) to report completion.
*   **Authentication:** Secured via a unique, difficult-to-guess `run_id` in path, or internal network policies / shared secret for demo.
*   **Request Body:**
    ```json
    {
      "status": "string ('success' or 'error')",
      "output_data_json": {
          "outputs_array": [
              {"key_name": "string", "value": "any", "storage_ref_url": "string (nullable)"}
          ]
      }, // As per conceptual_definition_v3.md
      "output_preview_text": "string (nullable)",
      "error_details_json": { // Null if success
          "error_code": "string (nullable)",
          "error_message_text": "string (nullable)",
          "stack_trace_text": "string (nullable)"
      },
      "kpi_results_json": "object (nullable)"
    }
    ```
*   **Response (Success 200 - OK):** `{"message": "Run status updated"}`.
*   **Brief Logic:**
    1.  Validate callback.
    2.  Update the `AgentRunLog` for `run_id` with all provided fields.
    3.  Update `AgentConfiguration.last_run_summary_json` with `run_id`, `status`, `NOW()` timestamp, and `output_preview_text`.
    4.  Publish an `ionflux.agent.run.completed` event to Kafka (see Section 3.1).

### 2.3. `POST /v1/agent-commands/invoke` (Internal, called by Chat Service)
*   **Purpose:** Allows Chat Service to trigger an agent based on a parsed command.
*   **Request Body:** (As defined in `chat_service_minimal_spec_v3.md`)
    ```json
    {
      "command_name": "string", // e.g., "run_agent"
      "agent_identifier": "string", // Name or ID of AgentConfiguration
      "runtime_params": {},
      "user_id": "uuid",
      "workspace_id": "uuid",
      "origin_details": {
          "type": "chat",
          "channel_id": "uuid",
          "message_id": "uuid (optional)",
          "thread_id": "uuid (optional)"
      }
    }
    ```
*   **Response (Success 202 - Accepted):** Similar to `/run` endpoint.
*   **Brief Logic:**
    1.  Inter-service authentication.
    2.  Resolve `agent_identifier` to an `AgentConfiguration.id` within the `workspace_id`.
    3.  Proceed with logic similar to `/agent-configurations/:agent_config_id/run` (effective config resolution, `AgentRunLog` creation, triggering agent shell/webhook). The `origin_details` can be passed within the `effective_config` if the agent needs them.

## 3. Kafka Integration

### 3.1. Publishing Events
*   **`ionflux.agent.run.completed` Event:**
    *   **Topic:** A designated Kafka topic (e.g., `ionflux.agent_run_updates`).
    *   **Payload (conforming to `PlatformEvent` schema from `conceptual_definition_v3.md`):**
        ```json
        {
          "event_id": "uuid",
          "event_type": "ionflux.agent.run.completed",
          "event_timestamp": "timestamp",
          "source_service_name": "AgentService",
          "workspace_id": "uuid",
          "payload_schema_version": "v1.0",
          "payload_json": {
            "run_id": "uuid",
            "agent_configuration_id": "uuid",
            "agent_definition_id": "string",
            "status": "string ('success' or 'error')",
            "output_preview_text": "string (nullable)",
            "kpi_results_json": "object (nullable)"
            // Potentially a reference to full output if needed by consumers
          }
        }
        ```

### 3.2. Consuming Events (Conceptual for Demo)
*   While PRM agents might be triggered by Kafka events they consume directly in their runtime, for the E2E demo, `AgentService` itself might not directly consume many external Kafka events to trigger agents. Instead, agent shells (Python/FastAPI) would have their own Kafka consumers if their `AgentDefinition.triggers_config_json_array` specifies an `event_stream` trigger.
*   `AgentService` *could* conceptually consume certain platform events (e.g., `ionflux.workspace.saas_connection_updated`) to perform administrative actions on related `AgentConfiguration`s (e.g., mark as 'error_requires_review' if a required connection is dropped). This is not a primary focus for the minimal demo spec.

## 4. Core Logic & Framework

*   **Framework:** FastAPI.
*   **Database Interaction:** SQLAlchemy (async with `asyncpg`). CRUD for `agent_definitions`, `agent_configurations`, `agent_run_logs`.
*   **HTTP Client:** `httpx` for async calls to agent shells/n8n.
*   **YAML Parsing:** `PyYAML`.
*   **Kafka Client:** `kafka-python` or `confluent-kafka-python` for publishing events.

This v3 spec aligns Agent Service with PRM agent complexity, revised demo strategy (Python shells, Kafka), and V3 data models.
```
