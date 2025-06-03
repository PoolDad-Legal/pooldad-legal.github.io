```markdown
# IONFLUX Project: Minimal Viable Chat Service Specification (v3 Proposals)

This document proposes updates for the Chat Service specification, aligning it with the V3 data models in `initial_schema_demo_v3.sql`, `conceptual_definition_v3.md`, and relevant interaction patterns from `agent_interaction_model_v3.md`.

**Version Note:** This is v3 of the Chat Service minimal specification.

**Chosen Technology:** Node.js with Express.js (reconfirmed as per `technical_stack_and_demo_strategy_v3.md`) and the `ws` library for WebSockets.

## 1. API Endpoints (RESTful)

All endpoints are protected by JWT authentication. Authorization middleware verifies user access to the relevant workspace. Table names like `chat_channels` and `chat_messages` align with `initial_schema_demo_v3.sql`.

### 1.1. `POST /workspaces/:workspace_id/channels`

*   **Purpose:** Creates a new chat channel.
*   **Path Parameter:** `workspace_id` (UUID).
*   **Request Body:**
    ```json
    {
      "name": "string",
      "type": "string (enum: 'public', 'private', 'dm', 'agent_dedicated', default: 'public')",
      "description_text": "string (nullable, optional)",
      "member_user_ids_array": ["uuid (optional, for 'private' or 'dm' types)"]
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
      "member_user_ids_array": ["uuid (nullable)"],
      "created_at": "timestamp",
      "updated_at": "timestamp",
      "message": "Chat channel created successfully"
    }
    ```
*   (Error responses: 400, 401, 403, 404 as standard).
*   **Brief Logic:**
    1.  JWT Auth & Workspace Authorization.
    2.  Validate request. If `type` is 'dm', `member_user_ids_array` should typically contain two users (one being the creator).
    3.  Create record in `chat_channels` table.
    4.  Return new channel object.

### 1.2. `GET /workspaces/:workspace_id/channels`

*   **Purpose:** Retrieves chat channels for a workspace.
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
    ]
    ```
*   **Brief Logic:**
    1.  JWT Auth & Workspace Authorization.
    2.  Fetch from `chat_channels` table. For 'private'/'dm' channels, filter by user membership in `member_user_ids_array`.
    3.  Return list.

### 1.3. `GET /channels/:channel_id/messages`

*   **Purpose:** Fetches messages for a channel.
*   **Response (Success 200 - OK):** Array of V3 `ChatMessage` objects.
    ```json
    [
      {
        "id": "uuid",
        "channel_id": "uuid",
        "sender_id": "uuid",
        "sender_type": "string ('user', 'agent', 'system')",
        "content_type": "string ('text', 'markdown', 'json_data', 'interactive_proposal', etc.)",
        "content_json": { /* structure varies by content_type */ },
        "thread_id": "uuid (nullable)",
        "reactions_json_array": [{"emoji": "string", "user_ids_array": ["uuid"]}],
        "read_by_user_ids_array": ["uuid"],
        "created_at": "timestamp",
        "updated_at": "timestamp (nullable)"
      }
    ]
    ```
*   **Brief Logic:**
    1.  JWT Auth & Workspace Authorization (via channel's `workspace_id`).
    2.  Fetch messages from `chat_messages`.
    3.  Return list.

### 1.4. `POST /internal/v1/channels/:channel_id/messages` (Internal Endpoint for Agents/System)

*   **Purpose:** Allows backend services (like `AgentService` or `NotificationService`) to post messages to a channel. This endpoint should be protected by inter-service authentication (e.g., API key, mTLS).
*   **Request Body:**
    ```json
    {
      "sender_id": "uuid", // AgentConfiguration.id or a system-defined ID
      "sender_type": "string ('agent' or 'system')",
      "content_type": "string", // e.g., 'markdown', 'json_data', 'interactive_proposal'
      "content_json": {
        // Example for 'markdown': {"text_body": "## Agent Alert! \n Something happened."}
        // Example for 'interactive_proposal':
        // {
        //   "title_text": "Approval Needed",
        //   "description_text": "Agent X proposes action Y.",
        //   "data_json": {"details": "...", "risk_level": "low"},
        //   "actions_array": [{"label": "Approve", "action_id": "approve_xyz"}, {"label": "Deny", "action_id": "deny_xyz"}]
        // }
      },
      "thread_id": "uuid (nullable)"
    }
    ```
*   **Response (Success 201 - Created):** The created V3 `ChatMessage` object.
*   **Brief Logic:**
    1.  Inter-service authentication.
    2.  Validate request (ensure `sender_type` is 'agent' or 'system').
    3.  Create record in `chat_messages` table.
    4.  Broadcast the new message via WebSocket to subscribed clients of `channel_id`.
    5.  Return created message object.

## 2. WebSocket Communication

*   **Connection Endpoint & Initiation:** (No change from previous spec: `wss://.../chat` with `token` and `workspaceId`).
*   **Message Structure (Client <-> Server):** (No change: `{"action": "string", "payload": {}}`).
*   **Channel Subscription (`action: "subscribe"`):** (No change in client request). Server logic verifies access to channel's workspace.
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
              // Future: Client might construct richer content_json for uploads, etc.
            },
            "thread_id": "uuid (nullable)",
            "client_message_id": "uuid (optional, for client-side ACK/pending state)"
          }
        }
        ```
    *   Server Logic:
        1.  Extract `user_id` from JWT for this WebSocket connection, set `sender_type` to `'user'`.
        2.  Validate `payload.channel_id` and user access.
        3.  Create record in `chat_messages` table.
        4.  Broadcast the new V3 `ChatMessage` object (see below) via `new_message` action.
        5.  If `content_json.text_body` starts with `/`, trigger command handling (Section 3).
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
            "reactions_json_array": [], // or actual reactions
            "read_by_user_ids_array": [] // or actual read receipts
          }
        }
        ```
*   **Error Handling (Server to Client - `action: "error"`):** (No change).

## 3. Command Handling (`/commands`)

*   **Identification:** If a user message's `content_json.text_body` (received via WebSocket `send_message`) starts with `/`.
*   **Parsing:** (Basic for demo, as previously defined). Extract command name, agent identifier, parameters (JSON string).
*   **Routing to Agent Service:**
    1.  `ChatService` makes an HTTP POST request to `AgentService`.
        *   Endpoint on `AgentService` (example): `POST /v1/agent-commands/invoke` (or specific to `run_agent` if preferred by `AgentService`).
        *   Request Body to `AgentService`:
            ```json
            {
              "command_name": "run_agent",
              "agent_identifier": "agent_config_name_or_id",
              "runtime_params": { /* parsed JSON parameters */ },
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
    2.  `AgentService` handles locating the `AgentConfiguration` (potentially resolving name to ID), merging `runtime_params` with `yaml_config_text`, executing the agent, and then posting results.

## 4. Handling Messages from Agents

*   **Mechanism:**
    *   **Option 1 (Event-Driven via Kafka - Preferred for decoupling):**
        1.  `AgentService` (or the agent itself) publishes a `PlatformEvent` to a Kafka topic (e.g., `ionflux.agent.output.chat_message_requested`).
        2.  The `payload_json` of this event contains the full data needed to construct a `ChatMessage` (target `channel_id`, `sender_id` as `AgentConfiguration.id`, `sender_type: 'agent'`, `content_type`, `content_json`, `thread_id`).
        3.  A Kafka consumer within `ChatService` (or a dedicated "ChatIngestionService") subscribes to this topic.
        4.  Upon receiving the event, the consumer validates the data and creates a new record in the `chat_messages` table.
        5.  The message is then broadcast via WebSocket to clients subscribed to the target `channel_id`.
    *   **Option 2 (Direct Internal API Call):**
        1.  `AgentService` makes an authenticated internal HTTP POST request to `ChatService` at `POST /internal/v1/channels/:channel_id/messages` (defined in Section 1.4).
        2.  The request body contains all necessary fields for the `ChatMessage`.
        3.  `ChatService` saves and broadcasts the message.
*   **Message Structure:** Messages from agents must conform to the V3 `ChatMessage` structure, with `sender_type: 'agent'` and `sender_id` being the `AgentConfiguration.id`. The `content_json` will vary based on the agent's output and defined `content_type`.

## 5. Core Logic (Simplified for Demo)

*   **Authentication & Authorization:** Standard JWT middleware for REST. Custom logic for WebSocket handshake. Workspace access checks for all channel/message operations.
*   **WebSocket Connection Management:** In-memory map of `channelId` to subscribed WebSocket clients (production: Redis Pub/Sub).
*   **Database Interaction:**
    *   **Driver:** `pg`.
    *   **Queries:** For `chat_channels` and `chat_messages` as per `initial_schema_demo_v3.sql`.
    *   Correctly handle serialization/deserialization of `content_json` (JSONB) for `chat_messages`.
    *   Handle new fields in `chat_channels` like `type`, `description_text`, `member_user_ids_array`.

## 6. Framework & Libraries

*   (No change - Express.js, `ws`, `pg`, `jsonwebtoken`, `uuid`, validation library).

This v3 specification updates the Chat Service to align with the V3 data models, focusing on structured `content_json` for messages, clear `sender_type` differentiation, expanded channel properties, and robust mechanisms for handling both user and agent-generated messages, including event-driven patterns.
```
