# IONFLUX Project: Minimal Viable Chat Service Specification (E2E Demo)

This document defines the specifications for a minimal viable Chat Service shell required for the IONFLUX E2E Demo. Its primary purpose is to handle basic CRUD operations for `ChatDockChannels` and `ChatMessages`, facilitate real-time message exchange via WebSockets, and route slash commands to the Agent Service.

**Chosen Technology:** Node.js with Express.js (as per `technical_stack_and_demo_strategy.md`) and the `ws` library for WebSockets.

## 1. API Endpoints (RESTful)

All endpoints listed below are protected and require a valid JWT (obtained from the User Service) in the `Authorization` header. A middleware will validate the JWT and extract `user_id`. Subsequent authorization logic will ensure the user has appropriate access to the workspace associated with the chat entities.

### 1.1. `POST /workspaces/:workspaceId/channels`

*   **Purpose:** Creates a new chat channel within a specified workspace.
*   **Path Parameter:** `workspaceId` (UUID of the workspace).
*   **Request Body:**
    ```json
    {
      "name": "string",
      "type": "string (e.g., 'public')" // For demo, default to 'public'. 'private' for future.
    }
    ```
*   **Response (Success 201 - Created):**
    ```json
    {
      "id": "uuid",                 // Channel's unique ID
      "workspace_id": "uuid",       // workspaceId from path
      "name": "string",
      "type": "string",
      "created_at": "timestamp",
      "updated_at": "timestamp",
      "message": "Chat channel created successfully"
    }
    ```
*   **Response (Error 400 - Bad Request):** Validation error (e.g., missing `name`).
*   **Response (Error 401 - Unauthorized):** JWT error.
*   **Response (Error 403 - Forbidden):** User does not have access to `workspaceId`.
*   **Response (Error 404 - Not Found):** If `workspaceId` does not exist.
*   **Brief Logic:**
    1.  JWT Authentication & Authorization Middleware: Validates JWT, extracts `user_id`. Verifies user access to `workspaceId`.
    2.  Validate request body.
    3.  Create a new record in the `ChatDockChannels` table.
    4.  Return the newly created channel object.

### 1.2. `GET /workspaces/:workspaceId/channels`

*   **Purpose:** Retrieves a list of chat channels for a given workspace.
*   **Path Parameter:** `workspaceId` (UUID of the workspace).
*   **Response (Success 200 - OK):**
    ```json
    [
      {
        "id": "uuid",
        "workspace_id": "uuid",
        "name": "string",
        "type": "string",
        "created_at": "timestamp",
        "updated_at": "timestamp"
      },
      // ... more channels
    ]
    ```
*   **Response (Error 401/403/404):** Standard errors.
*   **Brief Logic:**
    1.  JWT Authentication & Authorization Middleware. Verifies user access to `workspaceId`.
    2.  Fetch records from `ChatDockChannels` table where `workspace_id` matches.
    3.  Return the list of channel objects.

### 1.3. `GET /channels/:channelId/messages`

*   **Purpose:** Fetches historical messages for a specific channel.
*   **Path Parameter:** `channelId` (UUID of the chat channel).
*   **Query Parameters (Optional for Demo Pagination):**
    *   `limit`: integer (e.g., 50) - Number of messages to return.
    *   `before`: uuid (message_id) or timestamp - To fetch messages before a certain point.
    *   *(For initial demo, returning the last N messages, e.g., 50-100, without pagination is acceptable).*
*   **Response (Success 200 - OK):**
    ```json
    [
      {
        "id": "uuid",
        "channel_id": "uuid", // Should match the path channelId
        "sender_id": "uuid",    // User.id or AgentConfiguration.id
        "sender_type": "string", // 'user' or 'agent'
        "content_type": "string",// e.g., 'text'
        "content": {"text": "Actual message content"}, // JSON object as per schema
        "created_at": "timestamp",
        "thread_id": "uuid_or_null"
      },
      // ... more messages
    ]
    ```
*   **Response (Error 401/403/404):** Standard errors (auth check against the channel's workspace).
*   **Brief Logic:**
    1.  JWT Authentication & Authorization Middleware.
    2.  Fetch the `ChatDockChannel` by `:channelId` to verify existence and get `workspace_id` for auth check.
    3.  Fetch messages from `ChatMessages` table for the given `:channelId`, ordered by `created_at` (descending for recent messages). Apply pagination if implemented.
    4.  Return the list of message objects.

### 1.4. `POST /channels/:channelId/messages`

*   **Purpose:** Allows submitting a message via REST API. Primarily for specific use cases like programmatic message posting or as a fallback if WebSockets are not used for sending. WebSocket is preferred for standard user messages.
*   **Path Parameter:** `channelId` (UUID of the chat channel).
*   **Request Body:**
    ```json
    {
      "content_type": "string", // e.g., "text"
      "content": {"text": "Hello from REST!"} // JSON object matching content_type
    }
    ```
*   **Response (Success 201 - Created):** Full `ChatMessages` object.
*   **Response (Error 400/401/403/404):** Standard errors.
*   **Brief Logic:**
    1.  JWT Authentication & Authorization Middleware.
    2.  Fetch `ChatDockChannel` by `:channelId` for auth and existence check.
    3.  Validate request body.
    4.  Extract `sender_id` from JWT (`req.user.id`) and set `sender_type` to `'user'`.
    5.  Create a new record in `ChatMessages` table.
    6.  Broadcast the message via WebSocket to subscribers of this `channelId` (see Section 2).
    7.  If `content.text` starts with `/`, trigger command handling (see Section 3).
    8.  Return the created message object.

## 2. WebSocket Communication

*   **Library:** `ws` (a popular, lightweight WebSocket library for Node.js).
*   **Connection Endpoint:** `wss://[your-ionflux-domain]/chat` (or `ws://` for local dev).
*   **Connection Initiation:**
    *   Client initiates WebSocket connection.
    *   During connection handshake (e.g., via query parameters or an initial auth message):
        *   Client sends `token` (JWT string) and `workspaceId` (UUID).
        *   Server validates JWT. If valid, extracts `user_id`.
        *   Server verifies user has access to `workspaceId`.
        *   If authentication/authorization fails, server closes the connection.
*   **Message Structure (Client <-> Server via WebSocket):** All messages are JSON strings.
    ```json
    {
      "action": "string", // e.g., "subscribe", "send_message", "new_message", "error"
      "payload": {}       // Action-specific payload
    }
    ```
*   **Channel Subscription:**
    *   Client sends:
        ```json
        {
          "action": "subscribe",
          "payload": {
            "channelId": "uuid-of-channel-to-subscribe-to"
          }
        }
        ```
    *   Server Logic:
        1.  Verify client has access to the workspace containing this `channelId`.
        2.  Add the WebSocket client connection to an in-memory list/map of subscribers for that `channelId`. (For demo, in-memory is fine. Production would use Redis pub/sub or similar).
*   **Sending Messages (from Client to Server):**
    *   Client sends:
        ```json
        {
          "action": "send_message",
          "payload": {
            "channelId": "uuid-of-target-channel",
            "content_type": "text", // For demo, primarily 'text'
            "content": {"text": "Hello world!"},
            "client_message_id": "uuid_generated_by_client (optional, for ack)" 
          }
        }
        ```
    *   Server Logic:
        1.  Extract `user_id` from the authenticated WebSocket connection. Set `sender_type` to `'user'`.
        2.  Validate `payload.channelId` and user's access to it.
        3.  Create a new record in the `ChatMessages` table.
        4.  Broadcast the newly created message object to all subscribers of `payload.channelId` using the `new_message` action (see below).
        5.  If `content.text` starts with `/`, trigger command handling (see Section 3).
*   **Receiving Messages (from Server to Client - Broadcast):**
    *   Server sends to all relevant channel subscribers:
        ```json
        {
          "action": "new_message",
          "payload": { // Full ChatMessage object from database
            "id": "uuid",
            "channel_id": "uuid",
            "sender_id": "uuid",
            "sender_type": "string", // 'user' or 'agent'
            "content_type": "string",
            "content": {"text": "The message content"},
            "created_at": "timestamp",
            "thread_id": "uuid_or_null"
            // Potentially include sender's name/avatar if denormalized or fetched
          }
        }
        ```
*   **Error Handling (Server to Client):**
    *   Server sends:
        ```json
        {
          "action": "error",
          "payload": {
            "message": "Error description",
            "details": "Optional additional details"
          }
        }
        ```

*   **Agent Messages to WebSocket Clients:**
    *   When an agent needs to post a message to a channel (e.g., after a command execution or a scheduled task):
        1.  `Agent Service` (or the agent itself) makes an internal, authenticated HTTP request to a dedicated endpoint on the `Chat Service` (e.g., `POST /internal/channels/:channelId/agent-messages`).
        2.  Request Body: Full message details including `sender_id` (AgentConfiguration.id), `sender_type` ('agent'), `content_type`, `content`.
        3.  `Chat Service` validates the internal request (e.g., shared secret, internal network check).
        4.  Creates a `ChatMessages` record.
        5.  Broadcasts the message to WebSocket subscribers of the channel using the `new_message` action.

## 3. Command Handling (`/commands`)

*   **Identification:**
    *   If a message's `content.text` (received via REST `POST /channels/:channelId/messages` or WebSocket `send_message` action) starts with a `/`.
*   **Parsing (Basic for Demo):**
    *   Extract command name (e.g., `/run_agent`).
    *   Extract agent identifier (name or `AgentConfiguration.id`).
    *   Extract parameters (e.g., as a JSON string: `{ "param1": "value1" }`).
    *   Example: `/run_agent "My Shopify Analyzer" {"days": 7}`
*   **Routing to Agent Service:**
    1.  The Chat Service, upon identifying and parsing a command, makes an HTTP POST request to the `Agent Service`.
        *   Endpoint on Agent Service (example): `POST /agents/invoke-command`
        *   Request Body to Agent Service:
            ```json
            {
              "command_name": "run_agent", // or the specific command
              "agent_identifier": "My Shopify Analyzer", // Name or ID
              "parameters": {"days": 7}, // Parsed parameters
              "user_id": "uuid_of_triggering_user", // From JWT
              "workspace_id": "uuid_of_current_workspace",
              "channel_id": "uuid_of_originating_channel" // For context or replies
            }
            ```
    2.  The `Agent Service` handles locating the `AgentConfiguration`, validating parameters against its schema (if defined), executing the agent, and then sending any output messages back to the `Chat Service` via its internal agent message endpoint for broadcasting.

## 4. Core Logic (Simplified for Demo)

*   **JWT Authentication:** Middleware for REST. Custom logic for WebSocket connection handshake using `jsonwebtoken`.
*   **WebSocket Connection Management:**
    *   Maintain an in-memory map of `channelId` to a list/set of active WebSocket client connections subscribed to it.
    *   Handle client disconnections by removing them from subscription lists.
*   **Database Interaction:**
    *   **Driver:** `pg`.
    *   **Queries:** Basic SQL for `ChatDockChannels` and `ChatMessages`.
*   **Command Parsing:** Simple string manipulation to extract command parts. Robust parsing is a future enhancement.

## 5. Framework & Libraries

*   **Framework:** Express.js
*   **WebSocket Library:** `ws`
*   **Key Libraries:**
    *   `express`: Web framework.
    *   `ws`: WebSocket server.
    *   `pg`: PostgreSQL client.
    *   `jsonwebtoken`: For JWT validation.
    *   `uuid`: For generating UUIDs.
    *   Basic input validation.

This specification provides a foundation for a Chat Service that supports core messaging features, real-time updates, and basic command integration needed for the E2E demo.
```
