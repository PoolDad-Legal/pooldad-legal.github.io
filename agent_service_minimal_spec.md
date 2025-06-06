# IONFLUX Project: Minimal Viable Agent Service Specification (E2E Demo)

This document defines the specifications for a minimal viable Agent Service shell required for the IONFLUX E2E Demo. Its primary purpose is to manage `AgentDefinitions` (templates) and `AgentConfigurations` (instances), and to handle agent execution requests by triggering pre-defined n8n workflows (or similar mocked scripts).

**Chosen Technology:** Python with FastAPI (as per `technical_stack_and_demo_strategy.md`).

## 1. API Endpoints (RESTful)

All endpoints listed below are protected and require a valid JWT (obtained from the User Service) in the `Authorization` header. A FastAPI dependency will be used for JWT validation and extracting `user_id`. Subsequent authorization logic (e.g., checking workspace membership) will be handled within endpoint logic, potentially by calling the Workspace Service if needed, or by direct DB checks if permissible for demo simplicity.

### 1.1. `GET /agent-definitions`

*   **Purpose:** Retrieves a list of available agent definitions (templates).
*   **Response (Success 200 - OK):**
    ```json
    [
      {
        "id": "uuid",
        "name": "string",
        "description": "string",
        "input_schema": {}, // JSONB from DB, placeholder for demo
        "output_schema": {}, // JSONB from DB, placeholder for demo
        "underlying_services_required": ["string"], // List of strings
        "category": "string",
        "created_at": "timestamp",
        "updated_at": "timestamp"
      }
      // ... more agent definitions
    ]
    ```
    *   *For the E2E demo, these definitions are seeded into the database as per `initial_schema_demo.sql`.*
*   **Response (Error 401 - Unauthorized):** JWT error.
*   **Brief Logic:**
    1.  JWT Authentication (FastAPI dependency).
    2.  Fetch all records from the `AgentDefinitions` table using an async database session.
    3.  Return the list of agent definition objects.

### 1.2. `POST /workspaces/{workspaceId}/agent-configurations`

*   **Purpose:** Creates a new agent configuration (instance) within a specified workspace.
*   **Path Parameter:** `workspaceId` (UUID of the workspace).
*   **Request Body (Pydantic model):**
    ```json
    {
      "name": "string",
      "description": "string (optional, default null)",
      "agent_definition_id": "uuid",
      "yaml_config": "string" // YAML content as a string
    }
    ```
*   **Response (Success 201 - Created):** Full `AgentConfigurations` object including its ID and other DB-generated fields.
    ```json
    {
      "id": "uuid",
      "workspace_id": "uuid", // from path
      "agent_definition_id": "uuid",
      "created_by_user_id": "uuid", // from JWT
      "name": "string",
      "description": "string_or_null",
      "yaml_config": "string",
      "last_run_status": null,
      "last_run_at": null,
      "last_run_output_preview": null,
      "created_at": "timestamp",
      "updated_at": "timestamp"
      // "message": "Agent configuration created successfully" // Optional message field
    }
    ```
*   **Response (Error 400 - Bad Request):** Validation error (e.g., missing fields, invalid `agent_definition_id`, invalid YAML format).
*   **Response (Error 401 - Unauthorized):** JWT error.
*   **Response (Error 403 - Forbidden):** User does not have access to `workspaceId`.
*   **Response (Error 404 - Not Found):** If `workspaceId` or `agent_definition_id` does not exist.
*   **Brief Logic:**
    1.  JWT Authentication (FastAPI dependency, provides `user_id`).
    2.  Verify user access to `workspaceId` (e.g., query `Workspaces` table to check if `user_id` is `owner_user_id` or a member - for demo, owner check is sufficient).
    3.  Validate request body using Pydantic model. Check existence of `agent_definition_id`.
    4.  Create a new record in the `AgentConfigurations` table, associating `created_by_user_id` with the authenticated user.
    5.  Return the newly created agent configuration object.

### 1.3. `GET /workspaces/{workspaceId}/agent-configurations`

*   **Purpose:** Retrieves a list of agent configurations for a given workspace.
*   **Path Parameter:** `workspaceId` (UUID of the workspace).
*   **Response (Success 200 - OK):**
    ```json
    [
      {
        "id": "uuid",
        "workspace_id": "uuid",
        "agent_definition_id": "uuid",
        "name": "string",
        "description": "string_or_null",
        // Potentially include last_run_status for quick overview
        "last_run_status": "string_or_null"
      }
      // ... more configurations
    ]
    ```
*   **Response (Error 401/403/404):** Standard errors.
*   **Brief Logic:**
    1.  JWT Authentication & Authorization. Verify user access to `workspaceId`.
    2.  Fetch records from `AgentConfigurations` table where `workspace_id` matches.
    3.  Return the list of agent configuration objects (summary view).

### 1.4. `GET /agent-configurations/{agentConfigId}`

*   **Purpose:** Retrieves details for a specific agent configuration.
*   **Path Parameter:** `agentConfigId` (UUID of the agent configuration).
*   **Response (Success 200 - OK):** Full `AgentConfigurations` object (as per schema in `initial_schema_demo.sql`, including `yaml_config`, `last_run_status`, etc.).
*   **Response (Error 401/403/404):** Standard errors (auth check against the configuration's workspace).
*   **Brief Logic:**
    1.  JWT Authentication.
    2.  Fetch the `AgentConfigurations` record by `:agentConfigId`.
    3.  If found, verify user access to its `workspace_id`.
    4.  Return the full agent configuration object.

### 1.5. `PUT /agent-configurations/{agentConfigId}`

*   **Purpose:** Updates an existing agent configuration.
*   **Path Parameter:** `agentConfigId` (UUID of the agent configuration).
*   **Request Body (Pydantic model, all fields optional):**
    ```json
    {
      "name": "string (optional)",
      "description": "string (optional)",
      "yaml_config": "string (optional)" // YAML content
    }
    ```
*   **Response (Success 200 - OK):** Updated full `AgentConfigurations` object.
*   **Response (Error 400/401/403/404):** Standard errors.
*   **Brief Logic:**
    1.  JWT Authentication.
    2.  Fetch the `AgentConfigurations` record by `:agentConfigId` for auth check against its `workspace_id` and existence.
    3.  Validate request body (Pydantic model).
    4.  Update the specified fields in the `AgentConfigurations` table. `updated_at` will be handled by DB trigger.
    5.  Return the updated agent configuration object.

### 1.6. `POST /agent-configurations/{agentConfigId}/run`

*   **Purpose:** Triggers the execution of a configured agent. This is the primary interaction point for running agents.
*   **Path Parameter:** `agentConfigId` (UUID of the agent configuration).
*   **Request Body (Pydantic model, optional):**
    ```json
    {
      "runtime_params": {} // JSON object (Dict in Python)
    }
    ```
*   **Response (Success 202 - Accepted):**
    ```json
    {
      "run_id": "uuid", // A unique ID for this specific execution run (can be generated by Agent Service)
      "agent_configuration_id": "uuid",
      "status": "pending",       // Initial status; will be updated asynchronously
      "message": "Agent execution started"
    }
    ```
*   **Response (Error 400 - Bad Request):** Invalid `runtime_params` structure.
*   **Response (Error 401 - Unauthorized):** JWT error.
*   **Response (Error 403 - Forbidden):** User does not have access to the workspace of this agent configuration.
*   **Response (Error 404 - Not Found):** If `:agentConfigId` does not exist.
*   **Brief Logic:**
    1.  JWT Authentication.
    2.  Fetch `AgentConfiguration` by `:agentConfigId` (includes `yaml_config`, `agent_definition_id`). Verify user access to its `workspace_id`.
    3.  Fetch the corresponding `AgentDefinition` using `agent_definition_id`.
    4.  **Determine n8n Webhook URL:** (Demo specific) Retrieve this from a simple lookup map or a field in `AgentDefinition` (e.g., `AgentDefinition.input_schema['x-n8n-webhook-url']`). For the demo, this URL could be stored directly in `AgentDefinition.description` or a custom field if `input_schema` is strictly for parameters.
    5.  **Prepare Payload for n8n:**
        *   Parse `yaml_config` (string from DB) into a Python dictionary.
        *   Merge this dict with `runtime_params` from request body (runtime params take precedence).
        *   Generate a unique `run_id` (e.g., `uuid.uuid4()`).
        *   Include `run_id`, `agent_configuration_id`, `workspace_id`, `user_id` (from JWT) in the payload to n8n for context.
    6.  **Trigger n8n Workflow (as background task):** Use FastAPI's `BackgroundTasks` to make an asynchronous HTTP POST request to the n8n webhook URL with the payload.
    7.  Update `AgentConfiguration` in DB: set `last_run_status` to 'pending' (or 'running' if n8n call is synchronous and fast for demo), `last_run_at` to `NOW()`.
    8.  Return the 202 Accepted response with `run_id`.

### 1.7. (Optional) `POST /agents/invoke-command` (Internal endpoint called by Chat Service)

*   **Purpose:** Allows the Chat Service to trigger an agent based on a parsed chat command.
*   **Authentication:** Inter-service (e.g., shared secret API key in header, validated by a FastAPI dependency).
*   **Request Body (Pydantic model):**
    ```json
    {
      "command_name": "string",
      "agent_identifier": "string", // Name or ID of the AgentConfiguration
      "parameters": {}, // Dict
      "user_id": "uuid",
      "workspace_id": "uuid",
      "channel_id": "uuid"
    }
    ```
*   **Response (Success 202 - Accepted):** Similar to `/run` endpoint.
    ```json
    {
      "run_id": "uuid",
      "status": "pending",
      "message": "Agent command execution initiated"
    }
    ```
*   **Response (Error 400/404):** Invalid parameters / Agent Config not found.
*   **Brief Logic:**
    1.  Verify inter-service authentication.
    2.  Look up `AgentConfiguration` by `agent_identifier` within the `workspace_id`.
    3.  Proceed similarly to the `/agent-configurations/:agentConfigId/run` endpoint (steps 3-8), using `parameters` from request as `runtime_params`. The `channel_id` is passed to n8n for context, so n8n can instruct the Chat Service where to reply.

## 2. Internal Endpoint (Optional - for n8n callback)

### 2.1. `POST /runs/{runId}/completed`

*   **Purpose:** A webhook endpoint for n8n (or other async task runners) to call back when an agent execution finishes.
*   **Path Parameter:** `runId` (UUID generated by Agent Service).
*   **Authentication:** Secured via a unique, difficult-to-guess `runId` or a simple shared secret in a header for demo.
*   **Request Body (Pydantic model):**
    ```json
    {
      "agent_configuration_id": "uuid", // To ensure correct record update
      "status": "string", // "success" or "error"
      "output_preview": "string (optional)",
      "full_output_reference": "string (optional)" // e.g., link to where full output is stored
    }
    ```
*   **Response (Success 200 - OK):** `{"message": "Run status updated"}`.
*   **Brief Logic:**
    1.  Validate callback authentication.
    2.  Fetch `AgentConfiguration` using `agent_configuration_id`.
    3.  Update `last_run_status` to `request.status`, `last_run_output_preview` to `request.output_preview`.
    4.  (Future) Could trigger notifications or UI updates (e.g., via WebSocket message to Canvas Service/Chat Service if a direct update is needed).

## 3. Core Logic (Simplified for Demo)

*   **JWT Authentication:** FastAPI dependency using `python-jose[cryptography]`.
*   **Database Interaction:**
    *   **ORM/Driver:** SQLAlchemy (core or ORM) with `asyncpg` for asynchronous PostgreSQL access.
    *   **Queries:** CRUD operations on `AgentDefinitions` and `AgentConfigurations`.
*   **n8n Interaction:**
    *   **HTTP Client:** `httpx` library for making asynchronous HTTP requests to n8n webhook URLs.
    *   **URL Mapping:** A simple dictionary or configuration file within the Agent Service can map `AgentDefinition.name` or `id` to its corresponding n8n webhook URL for the demo. (e.g., stored in `AgentDefinition.description` or a custom field like `input_schema['x-n8n-webhook-url']`).

## 4. Framework & Libraries

*   **Framework:** FastAPI
*   **Key Libraries:**
    *   `fastapi`: Web framework.
    *   `uvicorn`: ASGI server.
    *   `SQLAlchemy` (asyncio support with `asyncpg`): ORM.
    *   `psycopg2-binary` (or `asyncpg` directly): PostgreSQL driver.
    *   `python-jose[cryptography]`: JWT handling.
    *   `httpx`: Asynchronous HTTP client.
    *   `pydantic`: Data validation (built into FastAPI).
    *   `PyYAML`: For parsing `yaml_config` string into a dictionary.

This specification details an Agent Service capable of managing basic agent definitions and configurations, and importantly, triggering external n8n workflows to simulate agent execution for the E2E Demo.
```
