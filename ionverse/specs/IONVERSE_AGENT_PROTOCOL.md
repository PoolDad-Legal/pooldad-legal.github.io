# IONVERSE Agent Protocol (IAP) - v0.1

## 1. Introduction

The IONVERSE Agent Protocol (IAP) defines the standards and mechanisms by which software agents within the IONVERSE ecosystem communicate, collaborate, and interoperate. This protocol is designed to support a diverse range of agents, from user-facing orchestrators like Agent 000 to specialized IONFLUX agents and the core functional components of IONVERSE applications (IONWALL, IONWALLET, IONPOD, IONVERSE App) when they expose agent-like interfaces.

IAP draws inspiration and practical examples from the Agent-to-Agent (A2A) protocol (illustrated by `ionverse/libs/a2a_example.py`) and integrates platform-specific interaction patterns defined in IONFLUX/IONVERSE design documents.

The core goals of IAP are:
*   **Discoverability:** Agents can find each other and understand their capabilities.
*   **Interoperability:** Agents built on different internal stacks can communicate effectively.
*   **Standardized Communication:** Common message formats and transport mechanisms.
*   **Support for Diverse Interaction Patterns:** Including request/response, event-driven, and streaming.
*   **Orchestration:** Enable higher-level agents like Agent 000 to manage and coordinate tasks across multiple specialized agents.

## 2. Core Concepts

### 2.1. Agents
An "Agent" in the IONVERSE context is an autonomous or semi-autonomous software entity that performs tasks, processes information, and/or interacts with users, other agents, or platform services. This includes:
*   **Agent 000 (Universal Orchestrator):** The primary user-facing agent.
*   **IONFLUX Agents:** The 10+ specialized agents defined in `ionverse/ionflux_app/AGENTS.md`.
*   **App Core Functionalities (as Agents):** Key services within IONWALL, IONWALLET, IONPOD, and the IONVERSE App that expose an A2A-compliant interface for interaction.

### 2.2. Agent Definition (`AgentDefinition`)
*   Analogous to an A2A "Agent Card," the `AgentDefinition` (schema in `conceptual_definition_v3.md` and `initial_schema_demo_v3.sql`) is the primary source of truth for an agent's identity, capabilities, and interaction protocols.
*   **Key IAP-relevant fields in `AgentDefinition`:**
    *   `id`, `name`, `version`, `description`
    *   `prm_details_json.core_capabilities_array` (high-level skills)
    *   `triggers_config_json_array`: Defines how an agent can be invoked (manual, schedule, webhook, event_stream). For A2A, a `webhook` trigger with a specific path can serve as its HTTP endpoint.
    *   `inputs_schema_json_array`: Defines the parameters for its skills/operations.
    *   `outputs_config_json_array`: Defines the structure of its results or events it produces.
    *   `deployment_info_json.a2a_http_endpoint_url` (conceptual field): The actual URL where the agent listens for A2A JSON-RPC calls. This might be derived from its `webhook` trigger or a dedicated service discovery mechanism.

### 2.3. Agent Configuration (`AgentConfiguration`)
*   User-specific instances of an `AgentDefinition`, customized via `yaml_config_text`. This is primarily for IONFLUX agents but the concept of configuration might apply to how Agent 000 tailors requests to other app functionalities.

### 2.4. Skills
*   Specific capabilities or operations an agent can perform. These are implicitly defined by the combination of `AgentDefinition.triggers_config_json_array` (how to call) and `AgentDefinition.inputs_schema_json_array` (what to pass).
*   For A2A JSON-RPC, a `skillId` can be used in the message parameters to target a specific operation if an agent exposes multiple distinct operations through a single endpoint. The `a2a_example.py` demonstrates an `AgentSkill` type within the `AgentCard`.

## 3. Agent Discovery

*   **Agent Marketplace / Registry:** IONFLUX provides a marketplace for discovering IONFLUX `AgentDefinition`s.
*   **Agent 000 Discovery:** Agent 000 must have access to a registry or a mechanism to discover all other ~20 A2A-compliant agents/app-functionalities and their "Agent Cards" (i.e., their `AgentDefinition` equivalent metadata, especially their `a2a_http_endpoint_url` and supported skills/inputs).
*   **Well-Known URI:** A2A-compliant agents should expose their "Agent Card" JSON at `/.well-known/agent.json` relative to their `a2a_http_endpoint_url`, as shown in `a2a_example.py`.

## 4. Communication Protocols

IAP supports multiple communication patterns:

### 4.1. Direct Agent-to-Agent (A2A Style - Synchronous/Asynchronous Request-Response)
*   **Transport:** HTTP/1.1 or HTTP/2 (HTTPS required in production).
*   **Protocol:** JSON-RPC 2.0.
*   **Server Implementation:** Agents acting as A2A servers (like `a2a_example.py` using `A2AStarletteApplication`) listen for JSON-RPC requests.
*   **Standard Method for Task Invocation:** `message/send`
    *   **Request `params`:**
        ```json
        {
            "message": {
                "messageId": "string (client-generated unique ID)",
                "role": "user_or_calling_agent_id",
                "parts": [
                    // Example: {"type": "TextPart", "text": "Perform analysis on..."}
                    // Example: {"type": "StructuredDataPart", "contentType": "application/json", "data": {"param1": "value1"}}
                    // Parts provide inputs aligned with AgentDefinition.inputs_schema_json_array
                ]
            },
            "skillId": "string (optional, ID of the specific skill to invoke)",
            "run_context": { // Optional context for the run
                "calling_agent_run_id": "string (optional)",
                "workspace_id": "string (optional)",
                "user_id": "string (optional)"
            }
        }
        ```
*   **Response Handling:**
    *   The A2A server framework (e.g., `a2a-sdk`) uses an `EventQueue` to manage responses. This supports:
        *   **Streaming:** Results can be sent back as multiple events.
        *   **Asynchronous Completion:** The initial HTTP response might be a quick acknowledgment (e.g., 202 Accepted with a `task_id` or `run_id`), and the actual result delivered later via a webhook/callback or another event. The `AgentRunLog` system in IONFLUX fits this pattern for tasks managed by `AgentService`.
    *   Standard JSON-RPC error responses are used for protocol-level or execution errors.

### 4.2. Event-Driven Communication (via Message Bus - Kafka/NATS)
*   **Standard:** Agents can be designed as event consumers or producers.
*   **Event Schema:** All events published to the IONVERSE message bus (Kafka or NATS) **MUST** adhere to the `PlatformEvent` schema defined in `conceptual_definition_v3.md`.
    ```json
    {
      "event_id": "string (UUID)",
      "event_type": "string (namespaced, e.g., 'ionflux.shopify.order.created')",
      "event_timestamp": "timestamp (ISO 8601)",
      "source_service_name": "string (e.g., 'ShopifyIntegrationService', 'agent_004_refactored')",
      "workspace_id": "string (UUID, nullable)",
      "user_id": "string (UUID, nullable)",
      "correlation_id": "string (UUID, nullable)",
      "payload_schema_version": "string (e.g., 'v1.0')",
      "payload_json": "json_object (event-specific data)"
    }
    ```
*   **Triggers:** `AgentDefinition.triggers_config_json_array` (type `event_stream`) specifies the Kafka/NATS topic and filter conditions.
*   **Outputs:** `AgentDefinition.outputs_config_json_array` (type `event`) specifies the `target_event_type` an agent will publish.
*   **Use Cases:** Decoupled communication, broadcasting state changes, triggering reactive workflows. Agent 000 might also use this to broadcast tasks or receive widespread notifications.

### 4.3. User-to-Agent Communication (Mediated by IONFLUX Platform)
*   As detailed in `agent_interaction_model_v3.md`:
    *   Users interact via UI (Canvas, Chat).
    *   These interactions are routed through platform services (`CanvasService`, `ChatService`) to `AgentService`.
    *   `AgentService` resolves the `AgentConfiguration`, computes the "effective configuration" (merging definition defaults, instance YAML, and runtime parameters), and invokes the agent's runtime environment (e.g., Python shell, n8n webhook) passing a `run_id` and the `effective_config_json`.
    *   The agent runtime then calls back to `AgentService` with results using `POST /agent-runs/{run_id}/completed`.
    *   This pattern is for agents managed and orchestrated by the IONFLUX platform itself. Agent 000 might use this pattern to invoke IONFLUX agents if it's also managed by `AgentService`, or it could use the direct A2A HTTP calls if it's external or at a higher orchestration layer.

## 5. Task Lifecycle Management (Conceptual)

*   **Initiation:** Via A2A `message/send`, platform API call to `AgentService`, or event consumption.
*   **Tracking:**
    *   A2A: The `a2a-sdk` includes concepts like `TaskStore`. A `task_id` (or `run_id` in IONFLUX) is essential.
    *   IONFLUX: `AgentRunLog` tracks every execution.
*   **Status Updates:** For long-running tasks, agents should provide status updates (e.g., via streaming A2A events, or by updating `AgentRunLog` which then emits a Kafka event).
*   **Cancellation:** The A2A example includes a `cancel` method. A mechanism to request task cancellation should be supported (e.g., another JSON-RPC method like `task/cancel` with `task_id`).
*   **Results:** Delivered via A2A event queue/stream, or for IONFLUX-managed agents, via the callback to `AgentService` and stored in `AgentRunLog.output_data_json`.

## 6. Security & Authentication

*   **A2A Calls:** While the `a2a_example.py` omits authentication for simplicity, production A2A endpoints MUST be secured.
    *   Options: Mutual TLS (mTLS), OAuth 2.0 Bearer Tokens (Client Credentials flow for agent-to-agent), API Keys specific to agents.
    *   The `AgentCard` in A2A can specify supported authentication schemes.
*   **Platform Service Calls:** Secured by internal mechanisms (e.g., JWTs for user context, service-to-service auth tokens).
*   **IONWALL's Role:** IONWALL will be the ultimate arbiter for many interactions, checking permissions and reputation even for inter-agent calls if they involve accessing user data or performing sensitive actions. The IAP must accommodate IONWALL checkpoints.

## 7. Agent 000 Orchestration

*   Agent 000 acts as a primary IAP client and potentially an IAP server (to receive user commands).
*   It discovers other agents/app-functionalities via their Agent Cards / `AgentDefinition`s.
*   It decomposes user requests into tasks for specialized agents.
*   It uses IAP (A2A JSON-RPC calls or publishing `PlatformEvent`s) to dispatch these tasks.
*   It aggregates responses and presents them to the user.

## 8. Future Considerations
*   Standardized error codes and structures for A2A.
*   More complex skill negotiation or dynamic capability discovery.
*   Versioning of the IAP itself.

This document provides the foundational principles for agent interaction within IONVERSE. It will be refined as the specific A2A interfaces for IONWALL, IONWALLET, IONPOD, and IONVERSE app functionalities are further detailed.
