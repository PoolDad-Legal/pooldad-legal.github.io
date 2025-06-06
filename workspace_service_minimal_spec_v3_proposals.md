```markdown
# IONFLUX Project: Minimal Viable Workspace Service Specification (v3 Proposals)

This document proposes updates for the Workspace Service specification, aligning it with the V3 data models in `initial_schema_demo_v3.sql`, `conceptual_definition_v3.md`, and the overall technical strategy in `technical_stack_and_demo_strategy_v3.md`.

**Version Note:** This is v3 of the Workspace Service minimal specification.

**Chosen Technology:** Node.js with Express.js (reconfirmed as per `technical_stack_and_demo_strategy_v3.md`).

## 1. API Endpoints (RESTful)

All endpoints listed below are protected and require a valid JWT (obtained from the User Service) in the `Authorization` header. A middleware validates the JWT and extracts `user_id`.

### 1.1. `POST /workspaces`

*   **Purpose:** Allows an authenticated user to create a new workspace.
*   **Request Body:**
    ```json
    {
      "name": "string",  // Name of the new workspace
      "settings_json": { // Optional: Initial settings for the workspace
        "default_llm_config": {
            "provider": "string (e.g., 'openai')",
            "model": "string (e.g., 'gpt-4o')"
        },
        "default_timezone": "string (e.g., 'America/New_York')",
        "regional_preferences_json": {}, // e.g., {"currency": "USD", "language": "en-US"}
        "active_kafka_topics_list": ["string (e.g., 'ionflux.shopify.ws_new.orders.created')"], // Optional initial topics
        "pinecone_api_key_secret_ref": "string (nullable, path to secret if workspace-specific key)",
        "generic_secrets_config_json": {} // e.g., {"my_custom_api_key_label": "path_to_secret_xyz"}
      },
      "member_user_ids_array": ["uuid (optional, array of user IDs to add as initial members)"]
    }
    ```
*   **Response (Success 201 - Created):**
    ```json
    {
      "id": "uuid",
      "name": "string",
      "owner_user_id": "uuid",
      "member_user_ids_array": ["uuid"], // Includes owner and any added members
      "settings_json": { // Reflects applied settings (defaults if not provided in request)
        "default_llm_config": { "provider": "openai", "model": "gpt-4o" },
        "default_timezone": "America/New_York",
        "regional_preferences_json": {},
        "active_kafka_topics_list": [],
        "pinecone_api_key_secret_ref": null,
        "generic_secrets_config_json": {}
      },
      "status": "active",
      "created_at": "timestamp",
      "updated_at": "timestamp",
      "message": "Workspace created successfully"
    }
    ```
*   **Response (Error 400 - Bad Request):** (No change)
*   **Response (Error 401 - Unauthorized):** (No change)
*   **Brief Logic:**
    1.  JWT Authentication Middleware.
    2.  Validate `name`.
    3.  `owner_user_id` is the authenticated `user_id`.
    4.  Initialize `member_user_ids_array` with `owner_user_id`. If `member_user_ids_array` is in request, add valid user IDs to this list (ensure owner is always present).
    5.  Prepare `settings_json`: Use provided values or apply service-defined defaults if not provided.
    6.  Create a new record in the `workspaces` table with `status` 'active'.
    7.  Return the newly created workspace object.

### 1.2. `GET /workspaces`

*   **Purpose:** Retrieves a list of workspaces accessible to the authenticated user (owned or member of).
*   **Response (Success 200 - OK):** An array of workspace objects.
    ```json
    [
      {
        "id": "uuid",
        "name": "string",
        "owner_user_id": "uuid",
        "member_user_ids_array": ["uuid"],
        "settings_json": { /* ... full settings object ... */ },
        "status": "string",
        "created_at": "timestamp",
        "updated_at": "timestamp"
      }
      // ... more workspaces
    ]
    ```
*   **Response (Error 401 - Unauthorized):** (No change)
*   **Brief Logic:**
    1.  JWT Authentication Middleware.
    2.  Fetch all records from `workspaces` table where `owner_user_id` matches the authenticated `user_id` OR where the authenticated `user_id` is present in the `member_user_ids_array`.
    3.  Return the list of workspace objects.

### 1.3. `GET /workspaces/:workspaceId`

*   **Purpose:** Retrieves details for a specific workspace if the authenticated user has access.
*   **Path Parameter:** `workspaceId` (UUID of the workspace).
*   **Response (Success 200 - OK):**
    ```json
    {
      "id": "uuid",
      "name": "string",
      "owner_user_id": "uuid",
      "member_user_ids_array": ["uuid"],
      "settings_json": { /* ... full settings object ... */ },
      "status": "string",
      "created_at": "timestamp",
      "updated_at": "timestamp"
    }
    ```
*   **Response (Error 401, 403, 404):** (No change, but 403 applies if user is not owner or member).
*   **Brief Logic:**
    1.  JWT Authentication Middleware.
    2.  Fetch workspace by `workspaceId`.
    3.  If found, verify user is `owner_user_id` or in `member_user_ids_array`.
    4.  If access permitted, return workspace object.

### 1.4. `PUT /workspaces/:workspaceId`

*   **Purpose:** Allows an authorized user (e.g., owner) to update workspace properties.
*   **Path Parameter:** `workspaceId` (UUID of the workspace).
*   **Request Body:** (Allow partial updates)
    ```json
    {
      "name": "string (optional)",
      "settings_json": { // Optional: Provide only fields to update within settings_json
        "default_llm_config": { "provider": "anthropic", "model": "claude-3-opus" },
        "active_kafka_topics_list": ["new_topic_1", "new_topic_2"]
        // Other settings fields can be included for update
      },
      "member_user_ids_array": ["uuid (optional, full new list of members for replacement, or handle via dedicated member endpoints)"]
    }
    ```
    *   **Note on `member_user_ids_array` update:** For a minimal spec, replacing the whole array is simpler. Granular add/remove might be separate endpoints (e.g., `/workspaces/:workspaceId/members`). Owner should not be removable here.
*   **Response (Success 200 - OK):** The updated full workspace object.
    ```json
    {
      "id": "uuid",
      "name": "string", // Updated name
      "owner_user_id": "uuid",
      "member_user_ids_array": ["uuid"], // Updated array
      "settings_json": { /* ... full updated settings object ... */ },
      "status": "string",
      "created_at": "timestamp",
      "updated_at": "timestamp", // Reflects update time
      "message": "Workspace updated successfully"
    }
    ```
*   **Response (Error 400, 401, 403, 404):** (As previously defined).
*   **Brief Logic:**
    1.  JWT Authentication Middleware.
    2.  Fetch workspace, verify ownership (or specific member permissions if defined for settings changes).
    3.  Validate request body.
    4.  Merge updates: If `settings_json` is provided, merge its fields into the existing `settings_json` in the DB (JSONB merge). Update `name` if provided. Replace `member_user_ids_array` if provided (ensure owner remains).
    5.  Save to `workspaces` table.
    6.  Return updated workspace object.

### 1.5. `DELETE /workspaces/:workspaceId`

*   **Purpose:** Allows the owner to "delete" (archive/mark for deletion) a workspace.
*   **Brief Logic:**
    1.  JWT Authentication Middleware.
    2.  Fetch workspace, verify ownership.
    3.  Instead of actual DB row deletion, update `workspaces.status` to 'archived' or 'pending_deletion'.
    4.  Return 200 OK with a confirmation message or the updated workspace object with the new status.

## 2. Core Logic (Simplified for Demo)

*   **Authentication Middleware:** (As previously defined) Validates JWT, extracts `user_id`, attaches to `req.user`.
*   **Database Interaction:**
    *   **Driver:** `pg` (Node.js PostgreSQL client).
    *   **Queries:** SQL `INSERT`, `SELECT`, `UPDATE` for the `workspaces` table as per `initial_schema_demo_v3.sql`.
    *   Handle reads/writes for `settings_json JSONB` (e.g., JSON stringify/parse, or use DB JSON functions for partial updates).
    *   Handle reads/writes for `member_user_ids_array UUID[]`.

## 3. Framework & Libraries

*   (No change - Express.js, `pg`, `jsonwebtoken`, `uuid`, validation library).

This v3 specification ensures the Workspace Service aligns with the updated database schema (`initial_schema_demo_v3.sql`), particularly regarding `settings_json` and `member_user_ids_array`. Field name conventions (snake_case) are maintained.
```
