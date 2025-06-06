```markdown
# IONFLUX Project: Minimal Viable Canvas Service Specification (v3 Proposals)

This document proposes updates for the Canvas Service specification, aligning it with the V3 data models in `initial_schema_demo_v3.sql`, `conceptual_definition_v3.md`, and the overall technical strategy.

**Version Note:** This is v3 of the Canvas Service minimal specification.

**Chosen Technology:** Node.js with Express.js (reconfirmed as per `technical_stack_and_demo_strategy_v3.md`).

## 1. API Endpoints (RESTful)

All endpoints are protected and require JWT authentication. Authorization middleware verifies user access to the relevant workspace.

### 1.1. `POST /workspaces/:workspaceId/pages`

*   **Purpose:** Creates a new canvas page.
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
      "workspace_id": "uuid",
      "title": "string",
      "parent_page_id": "uuid (nullable)",
      "icon_url": "string (nullable)",
      "status": "string", // e.g., 'active'
      "created_at": "timestamp",
      "updated_at": "timestamp",
      "message": "Canvas page created successfully"
    }
    ```
*   (Error responses remain similar: 400, 401, 403, 404)
*   **Brief Logic:**
    1.  JWT Auth & Workspace Authorization.
    2.  Validate `title`.
    3.  Create record in `canvas_pages` table, including `icon_url` and `status` (defaulting if not provided).
    4.  Return new canvas page object.

### 1.2. `GET /workspaces/:workspaceId/pages`

*   **Purpose:** Retrieves canvas pages for a workspace.
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
        // For E2E demo, consider if blocks should be nested here or fetched by GET /pages/:pageId
      }
    ]
    ```
*   (Error responses remain similar)
*   **Brief Logic:**
    1.  JWT Auth & Workspace Authorization.
    2.  Fetch `canvas_pages` where `workspace_id` matches and `status` is typically 'active' (or allow filtering by status).
    3.  Return list.

### 1.3. `GET /pages/:pageId`

*   **Purpose:** Retrieves a specific canvas page, including its blocks.
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
          "page_id": "uuid",
          "type": "string",  // e.g., 'text', 'agent_snippet', 'json_display'
          "content_json": { /* structure varies by type */ },
          "position_x": "integer",
          "position_y": "integer",
          "width": "integer",
          "height": "integer",
          "z_index": "integer",
          "created_at": "timestamp",
          "updated_at": "timestamp"
        }
      ]
    }
    ```
*   (Error responses remain similar)
*   **Brief Logic:**
    1.  JWT Auth & Workspace Authorization (via page's `workspace_id`).
    2.  Fetch page from `canvas_pages`.
    3.  Fetch associated blocks from `canvas_blocks`.
    4.  Return page with nested blocks, ensuring `content_json` is used for blocks.

### 1.4. `PUT /pages/:pageId`

*   **Purpose:** Updates a canvas page's properties.
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
*   (Error responses remain similar)
*   **Brief Logic:**
    1.  JWT Auth & Workspace Authorization.
    2.  Fetch page, validate user permissions for update.
    3.  Update fields in `canvas_pages` table.
    4.  Return updated page object.

### 1.5. `DELETE /pages/:pageId` (Archive/Soft Delete)

*   **Purpose:** Archives a canvas page (soft delete).
*   **Response (Success 200 - OK):**
    ```json
    {
      "id": "uuid",
      "status": "archived",
      "message": "Canvas page archived successfully."
    }
    ```
*   (Error responses remain similar)
*   **Brief Logic:**
    1.  JWT Auth & Workspace Authorization.
    2.  Update `status` of the `canvas_pages` record to 'archived'. **Do not hard delete.**
    3.  Return confirmation or the updated page object.

### 1.6. `POST /pages/:pageId/blocks`

*   **Purpose:** Creates a new canvas block on a page.
*   **Request Body:**
    ```json
    {
      "type": "string", // e.g., "text", "agent_snippet", "json_display", "embed_panel"
      "content_json": {
        // Structure depends on 'type'. Examples:
        // For 'text': {"markdown_text": "# New Block"}
        // For 'agent_snippet': {"agent_configuration_id": "uuid-of-agent-config", "placeholder_text": "Click to run me!"}
        // For 'json_display': {"title_text": "My Live Data", "json_data_to_display": {"initial_key": "initial_value"}}
        // For 'embed_panel': {"embed_url": "https://example.com"}
      },
      "position_x": "integer (optional, default 0)",
      "position_y": "integer (optional, default 0)",
      "width": "integer (optional, default 100)",
      "height": "integer (optional, default 100)",
      "z_index": "integer (optional, default 0)"
    }
    ```
*   **Response (Success 201 - Created):** Full V3 `CanvasBlock` object (with `content_json`).
*   (Error responses remain similar)
*   **Brief Logic:**
    1.  JWT Auth & Workspace Authorization (via page's `workspace_id`).
    2.  Fetch page to verify it exists and user has access.
    3.  Validate `type` and basic structure of `content_json`.
    4.  Create record in `canvas_blocks` table.
    5.  Return new block object.

### 1.7. `GET /pages/:pageId/blocks` (Mostly for completeness, often nested in GET /pages/:pageId)

*   **Purpose:** Retrieves all blocks for a page.
*   **Response (Success 200 - OK):** Array of V3 `CanvasBlock` objects (with `content_json`).
*   (Error responses remain similar)

### 1.8. `PUT /blocks/:blockId`

*   **Purpose:** Updates an existing canvas block.
*   **Request Body:**
    ```json
    {
      "type": "string (optional, if block type conversion is supported)",
      "content_json": { /* Full new content_json object, or support partial merge */ },
      "position_x": "integer (optional)",
      "position_y": "integer (optional)",
      "width": "integer (optional)",
      "height": "integer (optional)",
      "z_index": "integer (optional)"
    }
    ```
*   **Response (Success 200 - OK):** Updated V3 `CanvasBlock` object (with `content_json`).
*   (Error responses remain similar)
*   **Brief Logic:**
    1.  JWT Auth & Workspace Authorization (via block's page's `workspace_id`).
    2.  Fetch block, validate user permissions.
    3.  Update fields. For `content_json`, this could be a full replacement or a JSONB merge.
    4.  Return updated block.

### 1.9. `DELETE /blocks/:blockId`

*   **Purpose:** Deletes a canvas block.
*   **Response (Success 204 - No Content):**
*   (Error responses remain similar)
*   **Brief Logic:**
    1.  JWT Auth & Workspace Authorization.
    2.  Fetch block, validate permissions.
    3.  **Hard delete** the `canvas_blocks` record (unless soft delete for blocks is specifically introduced with a `status` field on `canvas_blocks` table, which is not in `initial_schema_demo_v3.sql`).
    4.  Return 204.

## 2. Core Logic (Simplified for Demo)

*   **Authentication/Authorization Middleware:** (As previously defined) Validates JWT, then verifies user access to the workspace associated with the page/block, possibly via an internal call to Workspace Service or direct DB check for demo.
*   **Database Interaction:**
    *   **Driver:** `pg`.
    *   **Queries:** For `canvas_pages` and `canvas_blocks` as per `initial_schema_demo_v3.sql`.
    *   Crucially handle `canvas_pages.status` for soft deletes/archival.
    *   Correctly serialize/deserialize and query `canvas_blocks.content_json` (JSONB), understanding its structure varies by `type`.

## 3. Framework & Libraries

*   (No change - Express.js, `pg`, `jsonwebtoken`, `uuid`, validation library).

This v3 specification ensures the Canvas Service aligns with the updated database schema, particularly `canvas_pages.status` and the structured `canvas_blocks.content_json` field, and clarifies soft delete behavior for pages.
```
