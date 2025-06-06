# IONFLUX Project: Minimal Viable Workspace Service Specification (v3)

This document provides the V3 specifications for a minimal viable Workspace Service shell required for the IONFLUX E2E Demo. Its primary purpose is to handle basic CRUD operations for workspaces, aligning with `initial_schema_demo_v3.sql`, `conceptual_definition_v3.md`, and `technical_stack_and_demo_strategy_v3.md`.

**Version Note:** This is v3 of the Workspace Service minimal specification.

**Chosen Technology:** Node.js with Express.js (reconfirmed as per `technical_stack_and_demo_strategy_v3.md`).

## 1. API Endpoints (RESTful)

All endpoints listed below are protected and require a valid JWT (obtained from the User Service) in the `Authorization` header. A middleware validates the JWT and extracts `user_id` from its payload, making it available as `req.user.id`.

### 1.1. `POST /workspaces`

*   **Purpose:** Allows an authenticated user to create a new workspace.
*   **Request Body:**
    ```json
    {
      "name": "string",
      "settings_json": {
        "default_llm_config": {
            "provider": "string (e.g., 'openai')",
            "model": "string (e.g., 'gpt-4o')"
        },
        "default_timezone": "string (e.g., 'America/New_York')",
        "regional_preferences_json": {},
        "active_kafka_topics_list": ["string (e.g., 'ionflux.shopify.ws_new.orders.created')"],
        "pinecone_api_key_secret_ref": "string (nullable, path to secret if workspace-specific key)",
        "generic_secrets_config_json": {}
      }, // Optional: Initial settings for the workspace
      "member_user_ids_array": ["uuid (optional, array of user IDs to add as initial members)"]
    }
    ```
*   **Response (Success 201 - Created):**
    ```json
    {
      "id": "uuid",
      "name": "string",
      "owner_user_id": "uuid", // ID of the authenticated user who created it
      "member_user_ids_array": ["uuid"], // Includes owner and any added members
      "settings_json": { // Reflects applied settings (defaults if not provided in request)
        "default_llm_config": { "provider": "openai", "model": "gpt-4o" },
        "default_timezone": "America/New_York",
        "regional_preferences_json": {},
        "active_kafka_topics_list": [], // Or topics from request
        "pinecone_api_key_secret_ref": null,
        "generic_secrets_config_json": {}
      },
      "status": "active", // Default status upon creation
      "created_at": "timestamp",
      "updated_at": "timestamp",
      "message": "Workspace created successfully"
    }
    ```
*   **Response (Error 400 - Bad Request):**
    *   If request body validation fails (e.g., missing `name`).
    ```json
    {
      "error": "Validation error",
      "details": ["Workspace name is required"]
    }
    ```
*   **Response (Error 401 - Unauthorized):**
    *   If JWT is missing, invalid, or expired.
*   **Brief Logic:**
    1.  JWT Authentication Middleware: Validates JWT and extracts `user_id` into `req.user.id`.
    2.  Validate request body (ensure `name` is present and not empty).
    3.  The `owner_user_id` is set to `req.user.id`.
    4.  Initialize `member_user_ids_array`: Start with `owner_user_id`. If `member_user_ids_array` is provided in the request, add valid user IDs to this list (ensure owner is always present and de-duplicate).
    5.  Prepare `settings_json`: Use values provided in `request.body.settings_json` or apply service-defined defaults for any missing fields within `settings_json`.
    6.  Create a new record in the `workspaces` table with `status` defaulting to 'active'.
    7.  Return the newly created workspace object.

### 1.2. `GET /workspaces`

*   **Purpose:** Retrieves a list of workspaces accessible to the authenticated user (i.e., workspaces they own or are a member of).
*   **Response (Success 200 - OK):** An array of workspace objects.
    ```json
    [
      {
        "id": "uuid",
        "name": "string",
        "owner_user_id": "uuid",
        "member_user_ids_array": ["uuid"],
        "settings_json": { /* ... full settings object ... */ },
        "status": "string", // e.g., 'active'
        "created_at": "timestamp",
        "updated_at": "timestamp"
      }
      // ... more workspaces
    ]
    ```
*   **Response (Error 401 - Unauthorized):** (If JWT is missing, invalid, or expired)
*   **Brief Logic:**
    1.  JWT Authentication Middleware.
    2.  Fetch all records from the `workspaces` table where `owner_user_id` matches `req.user.id` OR where `req.user.id` is present in the `member_user_ids_array` column.
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
*   **Response (Error 401 - Unauthorized):** (JWT issues)
*   **Response (Error 403 - Forbidden):**
    *   If the authenticated user is not the `owner_user_id` of the requested workspace and is not listed in `member_user_ids_array`.
*   **Response (Error 404 - Not Found):**
    *   If no workspace exists with the given `workspaceId`.
*   **Brief Logic:**
    1.  JWT Authentication Middleware.
    2.  Fetch the workspace record from the `workspaces` table by `workspaceId`.
    3.  If found, verify that the authenticated `user_id` is the `owner_user_id` or is included in the `member_user_ids_array`.
    4.  If access is permitted, return the workspace object. Otherwise, return 403 or 404.

### 1.4. `PUT /workspaces/:workspaceId`

*   **Purpose:** Allows an authorized user (e.g., owner or member with specific permissions - for demo, assume owner only) to update workspace properties.
*   **Path Parameter:** `workspaceId` (UUID of the workspace).
*   **Request Body:** (Allow partial updates)
    ```json
    {
      "name": "string (optional)",
      "settings_json": { // Optional: Provide only fields to update within settings_json.
                         // The service should merge this with existing settings_json.
        "default_llm_config": { "provider": "anthropic", "model": "claude-3-opus" },
        "active_kafka_topics_list": ["updated_topic_1"],
        "default_timezone": "Europe/London"
      },
      "member_user_ids_array": ["uuid (optional, replaces the entire existing array if provided)"]
      // For demo, owner cannot be removed from members. More granular member management (add/remove)
      // would typically be separate endpoints like /workspaces/:workspaceId/members.
    }
    ```
*   **Response (Success 200 - OK):** The updated full workspace object.
    ```json
    {
      "id": "uuid",
      "name": "string", // Updated name
      "owner_user_id": "uuid",
      "member_user_ids_array": ["uuid"], // Updated array
      "settings_json": { /* ... full updated settings object ... */ },
      "status": "string",
      "created_at": "timestamp", // Original creation time
      "updated_at": "timestamp", // Reflects update time
      "message": "Workspace updated successfully"
    }
    ```
*   **Response (Error 400, 401, 403, 404):** (As previously defined, 403 if not owner for demo).
*   **Brief Logic:**
    1.  JWT Authentication Middleware.
    2.  Fetch workspace by `workspaceId`; verify ownership by `req.user.id`.
    3.  Validate request body (e.g., `name` if provided is not empty).
    4.  Merge updates:
        *   If `name` is provided, update it.
        *   If `settings_json` is provided, perform a deep merge of its fields into the existing `settings_json` data in the database.
        *   If `member_user_ids_array` is provided, replace the existing array (ensure `owner_user_id` is always included).
    5.  Save changes to the `workspaces` table (DB trigger handles `updated_at`).
    6.  Return the fully updated workspace object.

### 1.5. `DELETE /workspaces/:workspaceId`

*   **Purpose:** Allows the owner to "delete" (archive) a workspace.
*   **Path Parameter:** `workspaceId` (UUID of the workspace).
*   **Response (Success 200 - OK):**
    ```json
    {
      "id": "uuid",
      "status": "archived", // Or "pending_deletion"
      "message": "Workspace archived successfully."
    }
    ```
*   **Response (Error 401, 403, 404):** (As previously defined).
*   **Brief Logic:**
    1.  JWT Authentication Middleware.
    2.  Fetch workspace by `workspaceId`; verify ownership by `req.user.id`.
    3.  Update the `workspaces.status` field to 'archived' (or 'pending_deletion'). **Do not perform a hard delete.** (Aligns with "Amor Fati" principle).
    4.  Return a confirmation message and the workspace ID with its new status.

## 2. Core Logic (Simplified for Demo)

*   **Authentication Middleware:** (As previously defined) Validates JWT, extracts `user_id` from token, attaches to `req.user`.
*   **Database Interaction:**
    *   **Driver:** `pg` (Node.js PostgreSQL client).
    *   **Queries:** SQL `INSERT`, `SELECT`, `UPDATE` for the `workspaces` table as defined in `initial_schema_demo_v3.sql`. Parameterized queries are essential.
    *   The `owner_user_id` field is populated with `req.user.id`.
    *   `settings_json` (JSONB type) should be handled correctly (JSON.stringify before save if ORM doesn't handle it, JSON.parse after fetch). For partial updates to `settings_json`, use appropriate PostgreSQL JSONB update functions (e.g., `jsonb_set`, `||` operator for merging).
    *   `member_user_ids_array` (UUID[] type) handled as an array.

## 3. Framework & Libraries

*   **Framework:** Express.js
*   **Key Libraries:**
    *   `express`: Web framework.
    *   `pg`: PostgreSQL client.
    *   `jsonwebtoken`: For JWT validation.
    *   `uuid`: For UUID generation if needed (though DB defaults are used).
    *   Input validation library (e.g., `express-validator`).

This v3 specification ensures the Workspace Service aligns with the updated database schema (`initial_schema_demo_v3.sql`), particularly regarding the structure and handling of `settings_json`, `member_user_ids_array`, and the `status` field. Field name conventions (snake_case) are maintained.
```
