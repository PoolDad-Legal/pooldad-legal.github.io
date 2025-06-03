# IONFLUX Project: Minimal Viable Chat Service Specification (v3)

This document provides the V3 specifications for a minimal viable Chat Service shell required for the IONFLUX E2E Demo. Its primary purpose is to handle CRUD operations for `chat_channels` and `chat_messages`, facilitate real-time message exchange via WebSockets, route slash commands, and manage messages from agents, aligning with `initial_schema_demo_v3.sql`, `conceptual_definition_v3.md`, and `agent_interaction_model_v3.md`.

**Version Note:** This is v3 of the Chat Service minimal specification.

**Chosen Technology:** Node.js with Express.js (reconfirmed as per `technical_stack_and_demo_strategy_v3.md`) and the `ws` library for WebSockets.

## 1. API Endpoints (RESTful)

All endpoints listed below are protected and require a valid JWT (obtained from the User Service) in the `Authorization` header. A middleware validates the JWT and extracts `user_id`. Subsequent authorization logic ensures the user has appropriate access to the workspace associated with the chat entities.

### 1.1. `POST /workspaces/:workspace_id/channels`

*   **Purpose:** Creates a new chat channel within a specified workspace.
*   **Path Parameter:** `workspace_id` (UUID).
*   **Request Body:**
    ```json
    {
      "name": "string",
      "type": "string (enum: 'public', 'private', 'dm', 'agent_dedicated', default: 'public')",
      "description_text": "string (nullable, optional)",
      "member_user_ids_array": ["uuid (optional, for 'private' or 'dm' types, user creating is implicitly a member)"]
    }
    ```
*   **Response (Success 201 - Created):** Full V3 `ChatChannel` object.
    ```json
    {
      "id": "uuid",
      "workspace_id": "uuid",
      "name": "string",
      "type": "string",
      "description_text": "string (nullable)",
      "member_user_ids_array": ["uuid (nullable)"], // Includes creator
      "created_at": "timestamp",
      "updated_at": "timestamp",
      "message": "Chat channel created successfully"
    }
    ```
*   **Response (Error 400 - Bad Request):** Validation error (e.g., missing `name`).
*   **Response (Error 401 - Unauthorized):** JWT error.
*   **Response (Error 403 - Forbidden):** User does not have access to `workspace_id`.
*   **Response (Error 404 - Not Found):** If `workspace_id` does not exist.
*   **Brief Logic:**
    1.  JWT Authentication & Workspace Authorization Middleware.
    2.  Validate request body. If `type` is 'dm', `member_user_ids_array` should ideally contain two users (one being the creator, `req.user.id`). Ensure `req.user.id` is added to `member_user_ids_array` if not present for 'private' or 'dm' channels they create.
    3.  Create a new record in the `chat_channels` table.
    4.  Return the newly created channel object.

### 1.2. `GET /workspaces/:workspace_id/channels`

*   **Purpose:** Retrieves a list of chat channels for a given workspace accessible to the user.
*   **Path Parameter:** `workspace_id` (UUID).
*   **Response (Success 200 - OK):** Array of V3 `ChatChannel` objects.
    ```json
    [
      {
        "id": "uuid",
        "workspace_id": "uuid",
        "name": "string",
        "type": "string",
        "description_text": "string (nullable)",
        "member_user_ids_array": ["uuid (nullable)"],
        "created_at": "timestamp",
        "updated_at": "timestamp"
      }
      // ... more channels
    ]
    ```
*   **Brief Logic:**
    1.  JWT Authentication & Workspace Authorization.
    2.  Fetch records from `chat_channels` table where `workspace_id` matches.
    3.  For 'private' or 'dm' channels, further filter to include only those where the authenticated `user_id` is in `member_user_ids_array`. 'public' and 'agent_dedicated' (if readable by all in workspace) channels are returned directly.
    4.  Return the list of accessible channel objects.

### 1.3. `GET /channels/:channel_id/messages`

*   **Purpose:** Fetches historical messages for a specific channel.
*   **Path Parameter:** `channel_id` (UUID of the chat channel).
*   **Query Parameters (Optional for Demo Pagination):** `limit`, `before`.
*   **Response (Success 200 - OK):** Array of V3 `ChatMessage` objects.
    ```json
    [
      {
        "id": "uuid",
        "channel_id": "uuid",
        "sender_id": "uuid",    // User.id or AgentConfiguration.id
        "sender_type": "string ('user', 'agent', 'system')",
        "content_type": "string ('text', 'markdown', 'json_data', 'interactive_proposal', etc.)",
        "content_json": { /* structure varies by content_type, e.g., {"text_body": "Hello"} */ },
        "thread_id": "uuid (nullable)",
        "reactions_json_array": [{"emoji": ":+1:", "user_ids_array": ["uuid1", "uuid2"]}], // Example
        "read_by_user_ids_array": ["uuid1"], // Example
        "created_at": "timestamp",
        "updated_at": "timestamp (nullable)"
      }
    ]
    ```
*   **Brief Logic:**
    1.  JWT Authentication & Workspace Authorization (via channel's `workspace_id`).
    2.  Fetch the `chat_channels` record by `channel_id` to verify existence and user access to its workspace (especially if it's private/dm).
    3.  Fetch messages from `chat_messages` for the `channel_id`, ordered by `created_at`. Apply pagination.
    4.  Return list.

### 1.4. `POST /internal/v1/channels/:channel_id/messages` (Internal Endpoint for Agents/System)

*   **Purpose:** Allows backend services (like `AgentService` or `NotificationService`) to post messages. Protected by inter-service authentication (e.g., API key, mTLS - not JWT).
*   **Path Parameter:** `channel_id` (UUID).
*   **Request Body:**
    ```json
    {
      "sender_id": "uuid", // AgentConfiguration.id or a system-defined ID
      "sender_type": "string ('agent' or 'system')",
      "content_type": "string", // e.g., 'markdown', 'json_data', 'interactive_proposal'
      "content_json": {
        // Example for 'markdown': {"text_body": "## Agent Alert! \n Something important happened."}
        // Example for 'interactive_proposal':
        // {
        //   "title_text": "Approval Required for Action X",
        //   "description_text": "Agent 'Shopify Sales Sentinel' proposes to temporarily disable 'FaultyApp_XYZ' due to critical error rate.",
        //   "data_json": {"app_name": "FaultyApp_XYZ", "error_rate": "85%", "potential_gmv_loss_hourly": "500 USD"},
        //   "actions_array": [
        //      {"label": "Approve Deactivation (1hr)", "action_id": "approve_deactivate_faultyapp_xyz_1hr", "style": "danger"},
        //      {"label": "View Details", "action_id": "view_faultyapp_details_abc"},
        //      {"label": "Dismiss", "action_id": "dismiss_alert_123", "style": "secondary"}
        //   ]
        // }
      },
      "thread_id": "uuid (nullable)"
    }
    ```
*   **Response (Success 201 - Created):** The created V3 `ChatMessage` object.
*   **Brief Logic:**
    1.  Inter-service authentication middleware.
    2.  Validate request (e.g., ensure `sender_type` is 'agent' or 'system', `channel_id` exists).
    3.  Create a new record in the `chat_messages` table.
    4.  Broadcast the new V3 `ChatMessage` object via WebSocket to clients subscribed to `channel_id`.
    5.  Return the created message object.

## 2. WebSocket Communication

*   **Library:** `ws`.
*   **Connection Endpoint & Initiation:** (As previously defined: `wss://.../chat` with `token` (JWT) and `workspaceId` query parameters for authentication and workspace context).
*   **Message Structure (Client <-> Server):** (As previously defined: `{"action": "string", "payload": {}}`).
*   **Channel Subscription (`action: "subscribe"`):** (No change in client request). Server logic verifies user access to the channel's workspace.
*   **Sending User Messages (Client to Server - `action: "send_message"`):**
    *   Client sends:
        ```json
        {
          "action": "send_message",
          "payload": {
            "channel_id": "uuid-of-target-channel",
            "content_type": "string", // Typically 'text' or 'markdown' from user input
            "content_json": {
              "text_body": "typed_message_content"
              // Future: Client might construct richer content_json for uploads, interactive elements etc.
            },
            "thread_id": "uuid (nullable)",
            "client_message_id": "uuid (optional, for client-side ACK/pending state)"
          }
        }
        ```
    *   Server Logic:
        1.  Extract `user_id` from the authenticated WebSocket connection; set `sender_id` to this `user_id` and `sender_type` to `'user'`.
        2.  Validate `payload.channel_id` and user's access.
        3.  Create a new record in the `chat_messages` table.
        4.  Broadcast the newly created V3 `ChatMessage` object (see below) via `new_message` action.
        5.  If `payload.content_json.text_body` starts with `/`, trigger command handling (Section 3).
*   **Receiving New Messages (Server to Client - `action: "new_message"`):**
    *   Server sends to all relevant channel subscribers:
        ```json
        {
          "action": "new_message",
          "payload": { // Full V3 ChatMessage object
            "id": "uuid",
            "channel_id": "uuid",
            "sender_id": "uuid",
            "sender_type": "string ('user', 'agent', 'system')",
            "content_type": "string",
            "content_json": { /* structure varies by content_type */ },
            "thread_id": "uuid (nullable)",
            "created_at": "timestamp",
            "updated_at": "timestamp (nullable)",
            "reactions_json_array": [],
            "read_by_user_ids_array": []
          }
        }
        ```
*   **Error Handling (Server to Client - `action: "error"`):** (No change).

## 3. Command Handling (`/commands`)

*   **Identification:** If a user message's `content_json.text_body` (received via WebSocket `send_message`) starts with `/`.
*   **Parsing (Basic for Demo):** Extract command name (e.g., `/run_agent`), agent identifier (name or `AgentConfiguration.id`), and parameters (e.g., as a JSON string: `{ "param1": "value1" }`).
*   **Routing to Agent Service:**
    1.  `ChatService` makes an HTTP POST request to `AgentService`.
        *   Endpoint on `AgentService` (example): `POST /v1/agent-commands/invoke`
        *   Request Body to `AgentService`:
            ```json
            {
              "command_name": "run_agent",
              "agent_identifier": "agent_config_name_or_id",
              "runtime_params": { /* parsed JSON parameters from command */ },
              "user_id": "uuid_of_triggering_user",
              "workspace_id": "uuid_of_current_workspace",
              "origin_details": {
                  "type": "chat",
                  "channel_id": "uuid_of_originating_channel",
                  "message_id": "uuid_of_triggering_message (optional)",
                  "thread_id": "uuid_of_originating_thread (optional)"
              }
            }
            ```
    2.  `AgentService` is responsible for locating the `AgentConfiguration` (resolving name to ID if necessary), merging `runtime_params` with its `yaml_config_text`, executing the agent, and then handling the agent's output (which might involve sending messages back to `ChatService`).

## 4. Handling Messages from Agents

*   **Mechanism:**
    *   **Option 1 (Event-Driven via Kafka - Preferred for decoupling & scalability):**
        1.  `AgentService` (or the agent itself during its execution) publishes a `PlatformEvent` to a designated Kafka topic (e.g., `ionflux.agent.output.chat_message_requested`).
        2.  The `payload_json` of this Kafka event contains all necessary data to construct a `ChatMessage`, including: target `channel_id`, `sender_id` (which is the `AgentConfiguration.id`), `sender_type: 'agent'`, the desired `content_type`, the full `content_json` for the message, and an optional `thread_id`.
        3.  A Kafka consumer within `ChatService` (or a dedicated "ChatIngestionService") subscribes to this topic.
        4.  Upon receiving the event, this consumer validates the data and creates a new record in the `chat_messages` table.
        5.  The newly created `ChatMessage` is then broadcast via WebSocket to clients subscribed to the target `channel_id`.
    *   **Option 2 (Direct Internal API Call - Simpler for initial demo if Kafka consumer is deferred):**
        1.  `AgentService` makes an authenticated internal HTTP POST request to the `ChatService` at `POST /internal/v1/channels/:channel_id/messages` (defined in Section 1.4).
        2.  The request body contains all necessary fields for the `ChatMessage` as specified for that internal endpoint.
        3.  `ChatService` saves the message and broadcasts it via WebSockets.
*   **Message Structure:** Regardless of the transport mechanism, messages from agents must conform to the V3 `ChatMessage` structure, with `sender_type: 'agent'` and `sender_id` being the `AgentConfiguration.id`. The `content_json` will be structured according to the specific `content_type` the agent intends to send (e.g., markdown, interactive proposal).

## 5. Core Logic (Simplified for Demo)

*   **Authentication & Authorization:** Standard JWT middleware for REST. Custom logic for WebSocket handshake. Workspace access checks for all channel/message operations.
*   **WebSocket Connection Management:** In-memory map of `channelId` to subscribed WebSocket clients (production: Redis Pub/Sub or similar for multi-instance scaling).
*   **Database Interaction:**
    *   **Driver:** `pg`.
    *   **Queries:** For `chat_channels` and `chat_messages` as per `initial_schema_demo_v3.sql`.
    *   Correctly handle serialization/deserialization and querying of `content_json` (JSONB) for `chat_messages`.
    *   Handle new fields in `chat_channels` like `type`, `description_text`, `member_user_ids_array`.

## 6. Framework & Libraries

*   (No change - Express.js, `ws`, `pg`, `jsonwebtoken`, `uuid`, validation library).

This v3 specification updates the Chat Service to align with the V3 data models, focusing on structured `content_json` for messages, clear `sender_type` differentiation, expanded channel properties, and robust mechanisms for handling both user and agent-generated messages, including event-driven patterns via Kafka or direct internal API calls for agent messages.
```
