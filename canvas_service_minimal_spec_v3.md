# IONFLUX Project: Minimal Viable Canvas Service Specification (v3)

This document provides the V3 specifications for a minimal viable Canvas Service shell required for the IONFLUX E2E Demo. Its primary purpose is to handle basic CRUD operations for `CanvasPages` and their associated `CanvasBlocks`, aligning with `initial_schema_demo_v3.sql`, `conceptual_definition_v3.md`, and the overall technical strategy.

**Version Note:** This is v3 of the Canvas Service minimal specification.

**Chosen Technology:** Node.js with Express.js (reconfirmed as per `technical_stack_and_demo_strategy_v3.md`).

## 1. API Endpoints (RESTful)

All endpoints listed below are protected and require a valid JWT (obtained from the User Service) in the `Authorization` header. A middleware validates the JWT and extracts `user_id`. Subsequent authorization logic (e.g., checking if the user has access to the `workspace_id` associated with the canvas entities) must be implemented.

### 1.1. `POST /workspaces/:workspaceId/pages`

*   **Purpose:** Creates a new canvas page within a specified workspace.
*   **Path Parameter:** `workspaceId` (UUID of the workspace).
*   **Request Body:**
    ```json
    {
      "title": "string",
      "parent_page_id": "uuid (nullable, optional)",
      "icon_url": "string (nullable, optional)",
      "status": "string (optional, default 'active', e.g., 'active', 'template_draft')"
    }
    ```
*   **Response (Success 201 - Created):**
    ```json
    {
      "id": "uuid",
      "workspace_id": "uuid", // workspaceId from path
      "title": "string",
      "parent_page_id": "uuid (nullable)",
      "icon_url": "string (nullable)",
      "status": "string", // e.g., 'active'
      "created_at": "timestamp",
      "updated_at": "timestamp",
      "message": "Canvas page created successfully"
    }
    ```
*   **Response (Error 400 - Bad Request):** If request body validation fails (e.g., missing `title`).
*   **Response (Error 401 - Unauthorized):** If JWT is missing, invalid, or expired.
*   **Response (Error 403 - Forbidden):** If the authenticated user does not have access to the specified `workspaceId`.
*   **Response (Error 404 - Not Found):** If `workspaceId` does not exist.
*   **Brief Logic:**
    1.  JWT Authentication & Workspace Authorization Middleware.
    2.  Validate request body (ensure `title` is present).
    3.  Create a new record in the `canvas_pages` table with `id` (auto-generated UUID), `workspace_id` from path, `title`, `parent_page_id`, `icon_url`, and `status` (defaulting if not provided).
    4.  Return the newly created canvas page object.

### 1.2. `GET /workspaces/:workspaceId/pages`

*   **Purpose:** Retrieves a list of canvas pages for a given workspace (typically active ones).
*   **Path Parameter:** `workspaceId` (UUID of the workspace).
*   **Query Parameters (Optional):** `status=active|archived|template_draft`
*   **Response (Success 200 - OK):** Array of `CanvasPage` objects.
    ```json
    [
      {
        "id": "uuid",
        "workspace_id": "uuid",
        "title": "string",
        "parent_page_id": "uuid (nullable)",
        "icon_url": "string (nullable)",
        "status": "string",
        "created_at": "timestamp",
        "updated_at": "timestamp"
        // For E2E demo, blocks are typically fetched via GET /pages/:pageId to keep this list lean.
      }
    ]
    ```
*   **Response (Error 401, 403, 404):** (As defined for POST)
*   **Brief Logic:**
    1.  JWT Authentication & Workspace Authorization Middleware.
    2.  Fetch records from the `canvas_pages` table where `workspace_id` matches. Apply filtering based on `status` query parameter if provided (default to 'active').
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
      "parent_page_id": "uuid (nullable)",
      "icon_url": "string (nullable)",
      "status": "string",
      "created_at": "timestamp",
      "updated_at": "timestamp",
      "blocks": [ // Blocks array with content_json
        {
          "id": "uuid",
          "page_id": "uuid", // Should match the parent pageId
          "type": "string",  // e.g., 'text', 'agent_snippet', 'json_display'
          "content_json": { /* structure varies by type, see conceptual_definition_v3.md */ },
          "position_x": "integer",
          "position_y": "integer",
          "width": "integer",
          "height": "integer",
          "z_index": "integer",
          "created_at": "timestamp",
          "updated_at": "timestamp"
        }
        // ... more blocks
      ]
    }
    ```
*   **Response (Error 401, 403, 404):** (As defined for POST, 403 if user cannot access the page's workspace).
*   **Brief Logic:**
    1.  JWT Authentication & Workspace Authorization Middleware (verifying access to the page's `workspace_id`).
    2.  Fetch the canvas page record from `canvas_pages` by `pageId`.
    3.  If page found and user authorized, fetch all associated `CanvasBlocks` for this `pageId` from the `canvas_blocks` table.
    4.  Return the page object with its nested blocks, ensuring `content_json` is used for blocks.

### 1.4. `PUT /pages/:pageId`

*   **Purpose:** Updates a canvas page's properties.
*   **Path Parameter:** `pageId` (UUID of the canvas page).
*   **Request Body:**
    ```json
    {
      "title": "string (optional)",
      "parent_page_id": "uuid (nullable, optional)",
      "icon_url": "string (nullable, optional)",
      "status": "string (optional, e.g., 'active', 'archived', 'template_draft')"
    }
    ```
*   **Response (Success 200 - OK):** The updated V3 `CanvasPage` object.
*   **Response (Error 400, 401, 403, 404):** (Standard errors).
*   **Brief Logic:**
    1.  JWT Authentication & Workspace Authorization Middleware.
    2.  Fetch the page from `canvas_pages` to verify existence and user's access to its workspace.
    3.  Validate request body.
    4.  Update the specified fields in the `canvas_pages` table for the given `pageId`.
    5.  Return the updated page object.

### 1.5. `DELETE /pages/:pageId` (Archive/Soft Delete)

*   **Purpose:** Archives a canvas page (soft delete).
*   **Path Parameter:** `pageId` (UUID of the canvas page).
*   **Response (Success 200 - OK):**
    ```json
    {
      "id": "uuid", // pageId
      "status": "archived",
      "message": "Canvas page archived successfully."
    }
    ```
*   **Response (Error 401, 403, 404):** (Standard errors).
*   **Brief Logic:**
    1.  JWT Authentication & Workspace Authorization Middleware.
    2.  Fetch the page to verify existence and user's access.
    3.  Update the `status` of the `canvas_pages` record to 'archived'. **Do not perform a hard delete.**
    4.  Return a confirmation message including the page ID and its new status.

### 1.6. `POST /pages/:pageId/blocks`

*   **Purpose:** Creates a new canvas block on a specified page.
*   **Path Parameter:** `pageId` (UUID of the canvas page).
*   **Request Body:**
    ```json
    {
      "type": "string", // e.g., "text", "agent_snippet", "json_display", "embed_panel", "image", "video"
      "content_json": {
        // Structure depends on 'type'. Examples from conceptual_definition_v3.md:
        // For 'text': {"markdown_text": "# New Block", "title_text": "Optional Title"}
        // For 'agent_snippet': {"agent_configuration_id": "uuid-of-agent-config", "agent_last_run_output_key_ref": "primary_output"}
        // For 'json_display': {"title_text": "My Live Data", "json_data_to_display": {"key": "value"}}
        // For 'embed_panel': {"embed_url": "https://example.com"}
        // For 'image': {"image_url": "https://path.to/image.png", "caption_text": "Optional caption"}
      },
      "position_x": "integer (optional, default 0)",
      "position_y": "integer (optional, default 0)",
      "width": "integer (optional, default 100)",
      "height": "integer (optional, default 100)",
      "z_index": "integer (optional, default 0)"
    }
    ```
*   **Response (Success 201 - Created):** Full V3 `CanvasBlock` object (with `content_json`).
*   **Response (Error 400, 401, 403, 404):** (Standard errors).
*   **Brief Logic:**
    1.  JWT Authentication & Workspace Authorization Middleware (via page's `workspace_id`).
    2.  Fetch the `CanvasPage` by `pageId` to verify its existence and that the user has access to its workspace.
    3.  Validate request body (ensure `type` is present and valid; `content_json` basic validation).
    4.  Create a new record in `canvas_blocks` table, associated with `pageId`.
    5.  Return the newly created block object.

### 1.7. `GET /pages/:pageId/blocks` (Often included in `GET /pages/:pageId`)

*   **Purpose:** Retrieves all blocks for a given canvas page.
*   **Path Parameter:** `pageId` (UUID of the canvas page).
*   **Response (Success 200 - OK):** Array of V3 `CanvasBlock` objects (each with `content_json`).
*   **Response (Error 401/403/404):** Similar to `GET /pages/:pageId`.
*   **Brief Logic:**
    1.  JWT Authentication & Workspace Authorization.
    2.  Fetch `CanvasPage` by `pageId` for auth check.
    3.  Fetch all `CanvasBlocks` associated with the `pageId`.
    4.  Return list.

### 1.8. `PUT /blocks/:blockId`

*   **Purpose:** Updates an existing canvas block.
*   **Path Parameter:** `blockId` (UUID of the canvas block).
*   **Request Body:** (Allow partial updates)
    ```json
    {
      "type": "string (optional, if block type conversion is supported)",
      "content_json": { /* Full new content_json object, or support partial merge based on block type */ },
      "position_x": "integer (optional)",
      "position_y": "integer (optional)",
      "width": "integer (optional)",
      "height": "integer (optional)",
      "z_index": "integer (optional)"
    }
    ```
*   **Response (Success 200 - OK):** Updated V3 `CanvasBlock` object (with `content_json`).
*   **Response (Error 400, 401, 403, 404):** Standard errors.
*   **Brief Logic:**
    1.  JWT Authentication & Workspace Authorization (via block's page's `workspace_id`).
    2.  Fetch `CanvasBlock` by `blockId` and its parent `CanvasPage` for auth.
    3.  Validate request body.
    4.  Update specified fields. For `content_json`, this could be a full replacement or a JSONB merge if appropriate for the block type and update.
    5.  Return updated block.

### 1.9. `DELETE /blocks/:blockId`

*   **Purpose:** Deletes a canvas block.
*   **Path Parameter:** `blockId` (UUID of the canvas block).
*   **Response (Success 204 - No Content):**
*   **Response (Error 401/403/404):** Standard errors.
*   **Brief Logic:**
    1.  JWT Authentication & Workspace Authorization.
    2.  Fetch `CanvasBlock` and parent `CanvasPage` for auth.
    3.  **Hard delete** the `canvas_blocks` record. (For demo, soft delete for blocks is not implemented unless `canvas_blocks` table gets a `status` field).
    4.  Return 204.

## 2. Core Logic (Simplified for Demo)

*   **Authentication/Authorization Middleware:**
    *   Validates JWT, extracts `user_id`.
    *   For operations, determines the `workspace_id` of the target page/block.
    *   Verifies user access to this `workspace_id` (e.g., by an optimized query or call to Workspace Service).
*   **Database Interaction:**
    *   **Driver:** `pg`.
    *   **Queries:** For `canvas_pages` and `canvas_blocks` as per `initial_schema_demo_v3.sql`.
    *   Handles `canvas_pages.status` for page archival (soft delete).
    *   Manages `canvas_blocks.content_json` (JSONB), ensuring that the structure passed from the client for different block `type`s is stored and retrieved correctly. Specific validation of `content_json` structure per type can be minimal for the demo but noted for production.

## 3. Framework & Libraries

*   **Framework:** Express.js
*   **Key Libraries:** (As previously defined: `express`, `pg`, `jsonwebtoken`, `uuid`, validation library).

This v3 specification ensures the Canvas Service aligns with the updated database schema (`initial_schema_demo_v3.sql`), particularly regarding `canvas_pages.status`, the structured `canvas_blocks.content_json` field, and clarifies soft delete behavior for pages. Field name conventions (snake_case) are maintained.
```
