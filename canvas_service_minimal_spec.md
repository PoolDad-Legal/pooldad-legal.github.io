# IONFLUX Project: Minimal Viable Canvas Service Specification (E2E Demo)

This document defines the specifications for a minimal viable Canvas Service shell required for the IONFLUX E2E Demo. Its primary purpose is to handle basic CRUD operations for `CanvasPages` and their associated `CanvasBlocks`, ensuring operations are authenticated and scoped to a workspace.

**Chosen Technology:** Node.js with Express.js (as per `technical_stack_and_demo_strategy.md` and for consistency with other demo service specs).

## 1. API Endpoints (RESTful)

All endpoints listed below are protected and require a valid JWT (obtained from the User Service) in the `Authorization` header. A middleware will validate the JWT and extract `user_id`. Subsequent authorization logic will ensure the user has appropriate access to the workspace associated with the canvas entities.

### 1.1. `POST /workspaces/:workspaceId/pages`

*   **Purpose:** Creates a new canvas page within a specified workspace.
*   **Path Parameter:** `workspaceId` (UUID of the workspace).
*   **Request Body:**
    ```json
    {
      "title": "string",
      "parent_page_id": "uuid_or_null" // Optional, for nesting pages
    }
    ```
*   **Response (Success 201 - Created):**
    ```json
    {
      "id": "uuid",                 // Page's unique ID
      "workspace_id": "uuid",       // workspaceId from path
      "title": "string",
      "parent_page_id": "uuid_or_null",
      "created_at": "timestamp",
      "updated_at": "timestamp",
      "message": "Canvas page created successfully"
    }
    ```
*   **Response (Error 400 - Bad Request):**
    *   If request body validation fails (e.g., missing `title`).
*   **Response (Error 401 - Unauthorized):**
    *   If JWT is missing, invalid, or expired.
*   **Response (Error 403 - Forbidden):**
    *   If the authenticated user does not have access to the specified `workspaceId`. (For demo, check if user owns the workspace via Workspace Service, or if `owner_user_id` in `Workspaces` table matches `user_id` from JWT).
*   **Response (Error 404 - Not Found):**
    *   If `workspaceId` does not exist.
*   **Brief Logic:**
    1.  JWT Authentication & Authorization Middleware: Validates JWT, extracts `user_id`. Verifies user has access to `workspaceId` (e.g., by calling Workspace Service or checking DB if service has direct access for optimization).
    2.  Validate request body (ensure `title` is present).
    3.  Create a new record in the `CanvasPages` table with `id` (auto-generated UUID), `workspace_id` from path, `title`, and `parent_page_id` from request.
    4.  Return the newly created canvas page object.

### 1.2. `GET /workspaces/:workspaceId/pages`

*   **Purpose:** Retrieves a list of canvas pages for a given workspace.
*   **Path Parameter:** `workspaceId` (UUID of the workspace).
*   **Response (Success 200 - OK):**
    ```json
    [
      {
        "id": "uuid",
        "workspace_id": "uuid",
        "title": "string",
        "parent_page_id": "uuid_or_null",
        "created_at": "timestamp",
        "updated_at": "timestamp"
      },
      // ... more pages
    ]
    ```
*   **Response (Error 401 - Unauthorized):**
    *   If JWT is missing, invalid, or expired.
*   **Response (Error 403 - Forbidden):**
    *   If the authenticated user does not have access to `workspaceId`.
*   **Response (Error 404 - Not Found):**
    *   If `workspaceId` does not exist.
*   **Brief Logic:**
    1.  JWT Authentication & Authorization Middleware: Validates JWT, extracts `user_id`. Verifies user access to `workspaceId`.
    2.  Fetch all records from the `CanvasPages` table where `workspace_id` matches the path parameter.
    3.  Return the list of canvas page objects.

### 1.3. `GET /pages/:pageId`

*   **Purpose:** Retrieves details for a specific canvas page, including its blocks.
*   **Path Parameter:** `pageId` (UUID of the canvas page).
*   **Response (Success 200 - OK):**
    ```json
    {
      "id": "uuid",
      "workspace_id": "uuid",
      "title": "string",
      "parent_page_id": "uuid_or_null",
      "created_at": "timestamp",
      "updated_at": "timestamp",
      "blocks": [
        {
          "id": "uuid",
          "page_id": "uuid", // Should match the parent pageId
          "type": "string",  // e.g., 'text', 'agent_snippet'
          "content": "json_object",
          "position_x": "integer",
          "position_y": "integer",
          "width": "integer",
          "height": "integer",
          "z_index": "integer",
          "created_at": "timestamp",
          "updated_at": "timestamp"
        },
        // ... more blocks
      ]
    }
    ```
*   **Response (Error 401 - Unauthorized):**
    *   If JWT is missing, invalid, or expired.
*   **Response (Error 403 - Forbidden):**
    *   If the authenticated user does not have access to the workspace containing this page.
*   **Response (Error 404 - Not Found):**
    *   If no page exists with `:pageId`.
*   **Brief Logic:**
    1.  JWT Authentication & Authorization Middleware: Validates JWT, extracts `user_id`.
    2.  Fetch the canvas page record from `CanvasPages` by `:pageId`.
    3.  If page found, verify user access to its `workspace_id`.
    4.  Fetch all associated `CanvasBlocks` for this `pageId` from the `CanvasBlocks` table.
    5.  Return the page object with its nested blocks.

### 1.4. `POST /pages/:pageId/blocks`

*   **Purpose:** Creates a new canvas block on a specified page.
*   **Path Parameter:** `pageId` (UUID of the canvas page).
*   **Request Body:**
    ```json
    {
      "type": "string", // e.g., "text", "agent_snippet"
      "content": {},    // JSON object, structure depends on type
                       // For 'agent_snippet': {"agent_config_id": "uuid"}
                       // For 'text': {"markdown": "Some text"}
      "position_x": "integer (optional, default 0)",
      "position_y": "integer (optional, default 0)",
      "width": "integer (optional, default 100)",
      "height": "integer (optional, default 100)",
      "z_index": "integer (optional, default 0)"
    }
    ```
*   **Response (Success 201 - Created):** Full `CanvasBlock` object (as defined in `GET /pages/:pageId` blocks array).
*   **Response (Error 400 - Bad Request):** Validation error (e.g., missing `type` or invalid `content` structure for type).
*   **Response (Error 401 - Unauthorized):** JWT error.
*   **Response (Error 403 - Forbidden):** User doesn't have access to the workspace of the page.
*   **Response (Error 404 - Not Found):** If `:pageId` does not exist.
*   **Brief Logic:**
    1.  JWT Authentication & Authorization Middleware.
    2.  Fetch the `CanvasPage` by `:pageId` to verify its existence and get `workspace_id` for auth check.
    3.  Validate request body (ensure `type` is present, `content` is valid JSON; specific content validation based on `type` for demo can be minimal).
    4.  Create a new record in `CanvasBlocks` table, associated with `:pageId`.
    5.  Return the newly created block object.

### 1.5. `GET /pages/:pageId/blocks`

*   **Purpose:** Retrieves all blocks for a given canvas page.
*   **Path Parameter:** `pageId` (UUID of the canvas page).
*   **Response (Success 200 - OK):** Array of `CanvasBlock` objects (as defined in `GET /pages/:pageId` blocks array).
*   **Response (Error 401/403/404):** Similar to `GET /pages/:pageId`.
*   **Brief Logic:**
    1.  JWT Authentication & Authorization Middleware.
    2.  Fetch the `CanvasPage` by `:pageId` to verify its existence and get `workspace_id` for auth check.
    3.  Fetch all `CanvasBlocks` associated with the `:pageId`.
    4.  Return the list of blocks.

### 1.6. `PUT /blocks/:blockId`

*   **Purpose:** Updates an existing canvas block (e.g., its content or position).
*   **Path Parameter:** `blockId` (UUID of the canvas block).
*   **Request Body:**
    ```json
    {
      "content": "json_object (optional)",
      "position_x": "integer (optional)",
      "position_y": "integer (optional)",
      "width": "integer (optional)",
      "height": "integer (optional)",
      "z_index": "integer (optional)"
    }
    ```
*   **Response (Success 200 - OK):** Updated full `CanvasBlock` object.
*   **Response (Error 400/401/403/404):** Standard errors.
*   **Brief Logic:**
    1.  JWT Authentication & Authorization Middleware.
    2.  Fetch the `CanvasBlock` by `:blockId` and its parent `CanvasPage` to verify existence and perform auth check against the page's `workspace_id`.
    3.  Validate request body.
    4.  Update the specified fields in the `CanvasBlocks` table.
    5.  Return the updated block object.

### 1.7. (Optional for Demo) `DELETE /blocks/:blockId`

*   **Purpose:** Deletes a canvas block.
*   **Path Parameter:** `blockId` (UUID of the canvas block).
*   **Response (Success 204 - No Content):**
*   **Response (Error 401/403/404):** Standard errors.
*   **Brief Logic:**
    1.  JWT Authentication & Authorization Middleware.
    2.  Fetch the `CanvasBlock` by `:blockId` and its parent `CanvasPage` to verify existence and perform auth check against the page's `workspace_id`.
    3.  Delete the record from `CanvasBlocks` table.
    4.  Return 204. (For demo, hard delete is acceptable. Production would consider soft delete/archival).

## 2. Core Logic (Simplified for Demo)

*   **Authentication/Authorization Middleware:**
    *   This service will use a similar JWT validation middleware as the Workspace Service.
    *   Crucially, after validating the JWT and extracting `user_id`, for any operation on a page or block, the service must determine the `workspace_id` associated with that page/block.
    *   It then needs to verify if the `user_id` has access to that `workspace_id`. For the demo, this can be simplified by:
        *   Fetching the workspace from the `Workspaces` table (if this service has DB access to it, which is not ideal microservice architecture but acceptable for a lean demo shell).
        *   OR, by making an internal API call to the Workspace Service (e.g., `GET /workspaces/:workspaceId`) and checking if the current user is the owner. This is a cleaner approach.
*   **Database Interaction:**
    *   **Driver:** `pg` (Node.js PostgreSQL client).
    *   **Queries:** Basic SQL `INSERT`, `SELECT`, `UPDATE`, `DELETE` for `CanvasPages` and `CanvasBlocks` tables as defined in `initial_schema_demo.sql`.
    *   `CanvasBlocks.content` will be stored and retrieved as JSONB. The application logic (frontend and potentially this service for validation) will handle the specific structure within this JSONB field based on the `type` (e.g., `{"agent_config_id": "..."}` for `agent_snippet`).

## 3. Framework & Libraries

*   **Framework:** Express.js
*   **Key Libraries:**
    *   `express`: Web framework.
    *   `pg`: PostgreSQL client.
    *   `jsonwebtoken`: For JWT validation.
    *   `uuid`: For generating UUIDs (if not handled by DB default).
    *   Basic input validation (e.g., `express-validator`).

This specification outlines a Canvas Service shell capable of managing the basic structure of pages and blocks, which is essential for the E2E demo's focus on the Canvas as a central workspace.
```
