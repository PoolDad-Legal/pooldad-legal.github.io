# IONFLUX Project: Minimal Viable Agent Service Specification (v3)

This document provides the V3 specifications for a minimal viable Agent Service required for the IONFLUX E2E Demo. It focuses on managing `AgentDefinitions` (from PRM blueprints) and `AgentConfigurations` (user instances), handling agent execution requests by triggering appropriate demo runtimes (Python shells or n8n), processing completion callbacks, and integrating with Kafka. It aligns with `core_agent_blueprints_v3.md`, `conceptual_definition_v3.md`, `technical_stack_and_demo_strategy_v3.md`, and `agent_interaction_model_v3.md`.

**Version Note:** This is v3 of the Agent Service minimal specification.

**Chosen Technology:** Python with FastAPI (reconfirmed as per `technical_stack_and_demo_strategy_v3.md`).

## 1. API Endpoints (RESTful)

All endpoints are protected by JWT authentication (FastAPI dependency). Authorization logic (workspace membership, ownership of configurations) is handled per endpoint. Field names adhere to snake_case.

### 1.1. `AgentDefinition` Management

#### 1.1.1. `GET /agent-definitions`
*   **Purpose:** Retrieves a list of available agent definitions (templates).
*   **Response (Success 200 - OK):** Array of full `AgentDefinition` objects (as per `conceptual_definition_v3.md`).
    ```json
    [
      {
        "id": "agent_001", // From PRM
        "name": "Email Wizard",
        "version": "0.1",
        "definition_status": "prm_active",
        "prm_details_json": { /* Rich narrative content from PRM, stored as JSONB */ },
        "triggers_config_json_array": [ /* Structured trigger configs from PRM YAML, stored as JSONB */ ],
        "inputs_schema_json_array": [ /* Structured input schemas from PRM YAML, stored as JSONB */ ],
        "outputs_config_json_array": [ /* Structured output schemas from PRM YAML, stored as JSONB */ ],
        "stack_details_json": { /* Detailed stack info from PRM, stored as JSONB */ },
        "deployment_info_json": { /* Including demo_shell_url or demo_n8n_webhook_url, stored as JSONB */ },
        "memory_config_json": { /* Memory config from PRM, stored as JSONB */ },
        "category_tags_array": ["Email", "Marketing"], // Stored as TEXT[]
        "underlying_platform_services_required_array": ["LLM_Orchestration", "Email_Dispatch"], // Stored as TEXT[]
        "created_at": "timestamp",
        "updated_at": "timestamp"
      }
      // ... more agent definitions
    ]
    ```
*   **Brief Logic:** Fetches all records from `agent_definitions` table. For the demo, these are seeded from PRM blueprints, with complex YAML/JSON parts stored as JSONB or TEXT in the database.

#### 1.1.2. `GET /agent-definitions/{agent_definition_id}`
*   **Purpose:** Retrieves details for a specific agent definition.
*   **Path Parameter:** `agent_definition_id` (e.g., "agent_001", "agent_004_refactored").
*   **Response (Success 200 - OK):** Single full `AgentDefinition` object.
*   **Brief Logic:** Fetches the specified record from `agent_definitions`.

#### 1.1.3. `POST /agent-definitions` (Conceptual - Not for E2E Demo Active Use)
*   **Note:** For the E2E demo, `AgentDefinition`s are pre-loaded from `core_agent_blueprints_v3.md` via `initial_schema_demo_v3.sql`. Dynamic creation of new, complex `AgentDefinition`s via this API is a future feature and not in scope for the minimal demo.

### 1.2. `AgentConfiguration` Management

#### 1.2.1. `POST /workspaces/{workspace_id}/agent-configurations`
*   **Purpose:** Creates a new agent configuration (instance) within a specified workspace.
*   **Path Parameter:** `workspace_id` (UUID).
*   **Request Body (Pydantic model):**
    ```json
    {
      "name": "string",
      "description_text": "string (optional, nullable)",
      "agent_definition_id": "string (e.g., 'agent_001')", // Refers to AgentDefinition.id
      "yaml_config_text": "string (YAML content for instance-specific inputs and overrides)"
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
      "effective_config_cache_json": null, // Can be populated asynchronously if needed
      "resolved_memory_namespace_text": "string (nullable)", // Resolved based on definition and yaml_config
      "status": "active", // Default status
      "last_run_summary_json": null, // Initially null
      "created_at": "timestamp",
      "updated_at": "timestamp"
    }
    ```
*   **Brief Logic:**
    1.  JWT Authentication & Workspace Authorization (user must be member of `workspace_id`).
    2.  Retrieve `AgentDefinition` using `request.agent_definition_id`. If not found, return 404.
    3.  **Validation:** Parse `request.yaml_config_text`. Validate its structure and content against the schemas and override rules defined in the fetched `AgentDefinition` (e.g., `inputs_schema_json_array`, user-overridable parts of `triggers_config_json_array` and `memory_config_json`).
    4.  If `AgentDefinition.memory_config_json.required` is true, resolve the `resolved_memory_namespace_text` using `AgentDefinition.memory_config_json.default_namespace_template` and any relevant values from `yaml_config_text`.
    5.  Create and store the `agent_configurations` record with `created_by_user_id` from JWT.
    6.  Return the created `AgentConfiguration` object.

#### 1.2.2. `GET /workspaces/{workspace_id}/agent-configurations`
*   **Purpose:** Retrieves agent configurations for a workspace.
*   **Response (Success 200 - OK):** Array of V3 `AgentConfiguration` objects (full objects for demo).

#### 1.2.3. `GET /agent-configurations/{agent_configuration_id}`
*   **Purpose:** Retrieves a specific agent configuration.
*   **Response (Success 200 - OK):** Single V3 `AgentConfiguration` object.

#### 1.2.4. `PUT /agent-configurations/{agent_configuration_id}`
*   **Purpose:** Updates an agent configuration.
*   **Request Body (Pydantic model, all fields optional):**
    ```json
    {
      "name": "string (optional)",
      "description_text": "string (optional, nullable)",
      "yaml_config_text": "string (optional)"
    }
    ```
*   **Response (Success 200 - OK):** Updated V3 `AgentConfiguration` object.
*   **Brief Logic:** Similar to POST, including re-validation of `yaml_config_text` against the parent `AgentDefinition` if `yaml_config_text` is provided.

#### 1.2.5. `DELETE /agent-configurations/{agent_configuration_id}`
*   **Purpose:** Archives an agent configuration (soft delete).
*   **Response (Success 200 - OK):** Updated V3 `AgentConfiguration` object with `status: 'archived'`.
*   **Brief Logic:** Sets the `status` field of the `agent_configurations` record to 'archived'.

## 2. Agent Execution & Lifecycle

### 2.1. `POST /agent-configurations/{agent_configuration_id}/run`
*   **Purpose:** Triggers the execution of a configured agent.
*   **Path Parameter:** `agent_configuration_id` (UUID).
*   **Request Body (Pydantic model):**
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
    1.  JWT Authentication & Workspace/Configuration Authorization.
    2.  Retrieve `AgentConfiguration` (including `yaml_config_text`) and its parent `AgentDefinition`.
    3.  **Effective Configuration Resolution:**
        *   Start with defaults from `AgentDefinition` (for triggers, memory settings, stack options).
        *   Override these with configurations from `AgentConfiguration.yaml_config_text` (parsed inputs, trigger overrides, memory overrides, stack preferences).
        *   Further override input values with any `runtime_params` from the current request.
        *   The result is the "effective configuration" JSON for this run.
    4.  Generate a unique `run_id` (e.g., `uuid.uuid4()`).
    5.  Create an `AgentRunLog` entry with this `run_id`, `status: 'pending'`, `agent_definition_id_version` (from `AgentDefinition.id` + `/` + `AgentDefinition.version`), and store the full `input_params_resolved_json` (the effective configuration).
    6.  **Triggering Mechanism (E2E Demo - as per `technical_stack_and_demo_strategy_v3.md`):**
        *   Examine `AgentDefinition.deployment_info_json.demo_execution_type`.
        *   If `'python_shell'`: Asynchronously POST `{"run_id": "...", "effective_config_json": { ... }}` to the URL in `AgentDefinition.deployment_info_json.demo_shell_url`.
        *   If `'n8n_webhook'`: Asynchronously POST `{"run_id": "...", "effective_config_json": { ... }}` to the URL in `AgentDefinition.deployment_info_json.demo_n8n_webhook_url`.
        *   If `'internal_mock'`: Handle with simplified internal logic (for peripheral demo agents not requiring a shell). This path should be minimal.
    7.  Return 202 Accepted response with `run_id` and initial 'pending' status.

### 2.2. `POST /agent-runs/{run_id}/completed` (Callback Endpoint)
*   **Purpose:** Webhook for agent execution environments (Python shells, n8n) to report completion status and output.
*   **Path Parameter:** `run_id` (UUID).
*   **Authentication:** Secured via a unique, difficult-to-guess `run_id` in the path. For production, a more robust mechanism (e.g., shared secret, signed callback) would be needed.
*   **Request Body (Pydantic model):**
    ```json
    {
      "status": "string ('success' or 'error')",
      "output_data_json": {
          "outputs_array": [ // Array of outputs, aligning with AgentDefinition.outputs_config_json_array
              {"key_name": "string", "value": "any", "storage_ref_url": "string (nullable, if value is large/binary)"}
          ]
      },
      "output_preview_text": "string (nullable)",
      "error_details_json": { // Null if status is 'success'
          "error_code": "string (nullable)",
          "error_message_text": "string (nullable)",
          "stack_trace_text": "string (nullable)"
      },
      "kpi_results_json": "object (nullable, agent-reported KPIs)"
    }
    ```
*   **Response (Success 200 - OK):** `{"message": "Run status updated"}`.
*   **Brief Logic:**
    1.  Validate `run_id`. Fetch the corresponding `AgentRunLog` and `AgentConfiguration`.
    2.  Update the `AgentRunLog` with all fields from the request body (`status`, `output_data_json`, `output_preview_text`, `error_details_json`, `kpi_results_json`, `end_time: NOW()`).
    3.  Update the `AgentConfiguration.last_run_summary_json` with `run_id`, `status`, current `timestamp`, and `output_preview_text`.
    4.  Publish an `ionflux.agent.run.completed` event to Kafka (see Section 3.1).

### 2.3. `POST /v1/agent-commands/invoke` (Internal Endpoint, Called by Chat Service)
*   **Purpose:** Standardized way for other services (initially `ChatService`) to trigger agent runs.
*   **Authentication:** Inter-service (e.g., shared secret API key, mTLS).
*   **Request Body (Pydantic model):**
    ```json
    {
      "command_name": "string", // e.g., "run_agent"
      "agent_identifier": "string", // Name or ID of the AgentConfiguration
      "runtime_params": {},
      "user_id": "uuid", // User who initiated the command
      "workspace_id": "uuid",
      "origin_details": { // Context from where the command originated
          "type": "string (e.g., 'chat', 'canvas_action')",
          "channel_id": "uuid (nullable, if from chat)",
          "message_id": "uuid (nullable, if from chat message)",
          "thread_id": "uuid (nullable, if from chat thread)",
          "canvas_page_id": "uuid (nullable, if from canvas)",
          "canvas_block_id": "uuid (nullable, if from canvas block)"
      }
    }
    ```
*   **Response (Success 202 - Accepted):** Similar to `/agent-configurations/{agent_config_id}/run`.
    ```json
    {
      "run_id": "uuid",
      "status": "pending",
      "message": "Agent command execution initiated via invoke."
    }
    ```
*   **Brief Logic:**
    1.  Inter-service authentication.
    2.  Resolve `agent_identifier` to an `AgentConfiguration.id` within the `workspace_id`. If not found, return 404.
    3.  Verify `user_id` has permission to run this agent configuration in the `workspace_id`.
    4.  Proceed with logic similar to `/agent-configurations/:agent_config_id/run` (Steps 3-7: Effective Configuration Resolution, `AgentRunLog` creation, Triggering agent shell/webhook, Return 202). The `origin_details` can be passed within the `effective_config_json` if the target agent is designed to use them.

## 3. Kafka Integration

### 3.1. Publishing Events
*   **Event: `ionflux.agent.run.completed`**
    *   **Topic:** A designated Kafka topic (e.g., `ionflux.public.agent_run_updates`).
    *   **Payload (conforming to `PlatformEvent` schema from `conceptual_definition_v3.md`):**
        ```json
        {
          "event_id": "uuid_generated_by_agent_service",
          "event_type": "ionflux.agent.run.completed",
          "event_timestamp": "current_timestamp_iso8601",
          "source_service_name": "AgentService",
          "workspace_id": "uuid_of_workspace",
          "payload_schema_version": "v1.0",
          "payload_json": {
            "run_id": "uuid_of_the_completed_run",
            "agent_configuration_id": "uuid",
            "agent_definition_id": "string (e.g., 'agent_001')",
            "agent_definition_version": "string (e.g., '0.1')",
            "status": "string ('success' or 'error')",
            "output_preview_text": "string (nullable)",
            "kpi_results_json": "object (nullable)",
            "user_id": "uuid_of_triggering_user (nullable)", // User who initiated the run
            "trigger_type": "string" // How the run was triggered
            // Potentially a reference to full output if needed by general consumers,
            // or consumers can use AgentRunLog.run_id to fetch full details.
          }
        }
        ```

### 3.2. Consuming Events (Conceptual for Demo / Future)
*   For the E2E demo, `AgentService` primarily acts as a Kafka producer.
*   Future capabilities might involve `AgentService` consuming events to:
    *   Trigger agents whose `AgentDefinition.triggers_config_json_array` specifies an `event_stream` type that is centrally managed/orchestrated by `AgentService` (though the PRM/demo strategy leans towards agent shells consuming their own Kafka triggers).
    *   Perform administrative actions based on platform events (e.g., if a SaaS connection linked to an agent configuration is revoked).

## 4. Core Logic & Framework

*   **Framework:** FastAPI.
*   **Database Interaction:** SQLAlchemy (async with `asyncpg`) for CRUD operations on `agent_definitions`, `agent_configurations`, `agent_run_logs`.
*   **HTTP Client:** `httpx` for making asynchronous HTTP requests to agent shells or n8n webhooks.
*   **YAML Parsing:** `PyYAML` for parsing `yaml_config_text` from `AgentConfiguration`.
*   **Kafka Client:** `kafka-python` or `confluent-kafka-python` for publishing events.
*   **Authentication:** FastAPI dependencies using `python-jose[cryptography]` for JWT validation.

This v3 specification for the Agent Service aligns it with the advanced capabilities of PRM agents, the revised E2E demo strategy (Python/FastAPI shells, Kafka integration), and the V3 data models, particularly for managing detailed agent definitions, configurations, and the full lifecycle of agent execution runs.
```
