# IONFLUX Project: Minimal Viable Workspace Service Specification (E2E Demo)

This document defines the specifications for a minimal viable Workspace Service shell required for the IONFLUX E2E Demo. Its primary purpose is to handle basic CRUD operations for workspaces, associating them with authenticated users.

**Chosen Technology:** Node.js with Express.js (as per `technical_stack_and_demo_strategy.md` and for consistency with the User Service spec for the demo).

## 1. API Endpoints (RESTful)

All endpoints listed below are protected and require a valid JWT (obtained from the User Service) in the `Authorization` header (e.g., `Authorization: Bearer <jwt_string>`). A middleware will be responsible for validating the JWT and extracting the `user_id` from its payload.

### 1.1. `POST /workspaces`

*   **Purpose:** Allows an authenticated user to create a new workspace.
*   **Request Body:**
    ```json
    {
      "name": "string"  // Name of the new workspace
    }
    ```
*   **Response (Success 201 - Created):**
    ```json
    {
      "id": "uuid",                 // Workspace's unique ID from the database
      "name": "string",
      "owner_user_id": "uuid",      // ID of the authenticated user who created it
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
    1.  JWT Authentication Middleware: Validates JWT and extracts `user_id`.
    2.  Validate request body (ensure `name` is present and not empty).
    3.  Create a new record in the `Workspaces` table with `id` (auto-generated UUID), provided `name`, and `owner_user_id` set to the authenticated `user_id`.
    4.  Return the newly created workspace object.

### 1.2. `GET /workspaces`

*   **Purpose:** Retrieves a list of workspaces accessible to the authenticated user. For the E2E demo, this will primarily be workspaces owned by the user.
*   **Response (Success 200 - OK):**
    ```json
    [
      {
        "id": "uuid",
        "name": "string",
        "owner_user_id": "uuid",
        "created_at": "timestamp",
        "updated_at": "timestamp"
        // "settings": {} // Optional: Could include basic settings if defined
      },
      // ... more workspaces
    ]
    ```
*   **Response (Error 401 - Unauthorized):**
    *   If JWT is missing, invalid, or expired.
*   **Brief Logic:**
    1.  JWT Authentication Middleware: Validates JWT and extracts `user_id`.
    2.  Fetch all records from the `Workspaces` table where `owner_user_id` matches the authenticated `user_id`.
        *   *(Future enhancement: This would also include workspaces the user is a member of, via the `member_user_ids` array in the conceptual schema, likely requiring a join or separate query).*
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
      "created_at": "timestamp",
      "updated_at": "timestamp",
      "settings": null // Or an empty JSON object {} if settings are not implemented for demo
                      // conceptual_definition.md has: "settings": { "default_llm_config": "json_object" }
    }
    ```
*   **Response (Error 401 - Unauthorized):**
    *   If JWT is missing, invalid, or expired.
*   **Response (Error 403 - Forbidden):**
    *   If the authenticated user is not the `owner_user_id` of the requested workspace (or not a member, in future iterations).
*   **Response (Error 404 - Not Found):**
    *   If no workspace exists with the given `:workspaceId`.
*   **Brief Logic:**
    1.  JWT Authentication Middleware: Validates JWT and extracts `user_id`.
    2.  Fetch the workspace record from the `Workspaces` table by `:workspaceId`.
    3.  If found, verify that the authenticated `user_id` is the `owner_user_id` of the workspace.
        *   *(Future enhancement: Check membership in `member_user_ids`)*.
    4.  If access is permitted, return the workspace object. Otherwise, return 403 or 404 as appropriate.

### 1.4. (Optional for Demo) `PUT /workspaces/:workspaceId`

*   **Purpose:** Allows the owner of a workspace to update its properties (e.g., name, settings).
*   **Path Parameter:** `workspaceId` (UUID of the workspace).
*   **Request Body:**
    ```json
    {
      "name": "string (optional)",
      "settings": "json_object_or_null (optional)" // e.g., {"default_llm_config": {"provider": "OpenAI", "model": "gpt-4"}}
    }
    ```
*   **Response (Success 200 - OK):**
    ```json
    {
      "id": "uuid",
      "name": "string",
      "owner_user_id": "uuid",
      "created_at": "timestamp",
      "updated_at": "timestamp", // Should reflect the update time
      "settings": "json_object_or_null",
      "message": "Workspace updated successfully"
    }
    ```
*   **Response (Error 400 - Bad Request):**
    *   If request body validation fails.
*   **Response (Error 401 - Unauthorized):**
    *   If JWT is missing, invalid, or expired.
*   **Response (Error 403 - Forbidden):**
    *   If the authenticated user is not the `owner_user_id`.
*   **Response (Error 404 - Not Found):**
    *   If no workspace exists with the given `:workspaceId`.
*   **Brief Logic:**
    1.  JWT Authentication Middleware: Validates JWT and extracts `user_id`.
    2.  Fetch the workspace record from the `Workspaces` table by `:workspaceId`.
    3.  If found, verify that the authenticated `user_id` is the `owner_user_id`.
    4.  If access is permitted, validate the request body (e.g., `name` if provided is not empty).
    5.  Update the specified fields (e.g., `name`, `settings`) in the `Workspaces` table for the given `id`. The `updated_at` timestamp will be updated by the database trigger.
    6.  Return the updated workspace object.

## 2. Core Logic (Simplified for Demo)

*   **Authentication Middleware:**
    *   A shared or reusable middleware function (potentially in a common library if other Express.js services are built) will be used for all protected routes.
    *   This middleware will:
        1.  Extract the JWT from the `Authorization: Bearer <token>` header.
        2.  Validate the token using the same secret key and library (`jsonwebtoken`) as the User Service.
        3.  If valid, extract the `user_id` (and potentially other relevant claims like `email`) from the token payload and attach it to the Express `request` object (e.g., `req.user = { id: 'user-uuid', email: 'user@example.com' }`).
        4.  If invalid, respond with a 401 error.
*   **Database Interaction:**
    *   **Driver:** `pg` (Node.js PostgreSQL client), consistent with User Service.
    *   **Queries:** Basic SQL `INSERT`, `SELECT`, and `UPDATE` queries for the `Workspaces` table as defined in `initial_schema_demo.sql`. Parameterized queries are essential.
    *   The `owner_user_id` field in the `Workspaces` table will be populated with the `user_id` from the validated JWT.

## 3. Framework & Libraries

*   **Framework:** Express.js
    *   Chosen for consistency with the User Service shell and its suitability for building straightforward REST APIs for the demo.
*   **Key Libraries:**
    *   `express`: Web framework.
    *   `pg`: PostgreSQL client.
    *   `jsonwebtoken`: For JWT validation (though actual signing is done by User Service, validation is needed here).
    *   `uuid`: For generating UUIDs if needed (though database defaults are preferred).
    *   Basic input validation (e.g., `express-validator` or simple manual checks).

This specification provides the blueprint for a Workspace Service that is minimal yet functional enough to support the workspace management needs of the IONFLUX E2E Demo, ensuring that all workspace operations are tied to an authenticated user.
```
