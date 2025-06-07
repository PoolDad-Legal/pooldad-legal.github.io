# IONVERSE Agent Interaction Model - v4.0

## 0. Introduction

### Purpose
This document defines the standardized models and protocols for interactions between users, software agents, and core platform services within the entire IONVERSE ecosystem. It aims to establish a clear, consistent, and secure framework that enables seamless collaboration, orchestration, and emergent behaviors across all components, including IONFLUX, IONWALL, IONWALLET, IONPOD, and the IONVERSE App.

### Scope
The interaction models described herein cover:
*   **User-to-Agent (U2A):** How users interact with agents, primarily through the universal orchestrator (Agent 000) or directly with IONFLUX agents via platform UIs (Canvas, Chat).
*   **Agent-to-Agent (A2A):** How different software agents (IONFLUX specialized agents, Agent 000, and agent-like interfaces of core ION apps) communicate and delegate tasks to each other. This is the primary domain of the **IONVERSE Agent Protocol (IAP)**.
*   **System-to-Agent (S2A) / Agent-to-System (A2S):** How agents are triggered by system events (e.g., from NATS/Kafka, schedulers) and how they interact with core platform services and infrastructure (e.g., IONPOD for storage, IONWALL for security).

### Core Principles
1.  **IONVERSE Agent Protocol (IAP) as Standard:** IAP is the lingua franca for all programmatic inter-agent and agent-to-service communication, ensuring interoperability and discoverability.
2.  **Agent 000 ("ION") as Primary Orchestrator:** Users primarily interact with the ecosystem via Agent 000, which translates natural language intent into orchestrated actions performed by specialized agents and services using IAP.
3.  **IONWALL as Universal Mediator:** All significant interactions, especially those involving data access, resource consumption (C-ION), financial transactions, or capability delegation, are subject to IONWALL's security policies, consent management, and reputation engine.

### Relation to Other Documents
This document supersedes `agent_interaction_model_v3.md` by incorporating the broader IONVERSE scope and the formalized IAP. It should be read in conjunction with:
*   **`/ionverse/specs/IONVERSE_AGENT_PROTOCOL.md` (IAP):** Provides the technical details for A2A and event-driven communication. This document explains *how* IAP is applied.
*   **`conceptual_definition_v3.md` & `initial_schema_demo_v3.sql`:** Define the `AgentDefinition` and `AgentConfiguration` schemas, which are foundational for agent capabilities and discovery.
*   **`ionverse/README.md`:** Provides the overarching vision and introduces Agent 000.
*   Individual App Blueprints & READMEs (IONFLUX, IONWALL, IONWALLET, IONPOD, IONVERSE App): Detail the specific functionalities and IAP exposures of each core application.
*   `specs/agents/` & `specs/transforms/`: Detailed blueprints for IONFLUX agents and their underlying transforms.

## 1. Core Concepts of IONVERSE Agent Interactions

*   **The ~20 Agent Ecosystem:** The IONVERSE is populated by a diverse set of agents:
    *   **1 User-Facing Universal Orchestrator:** Agent 000 ("ION").
    *   **10+ Core IONFLUX Specialized Agents:** (e.g., Muse, Scribe, Chronos, Guardian - see `ionverse/ionflux_app/AGENTS.md`). These perform specific, complex tasks.
    *   **~5-10 App-Core-Function Agents/Services:** Key functionalities within IONWALL, IONWALLET, IONPOD, and the IONVERSE App that expose IAP-compliant interfaces for programmatic interaction (e.g., IONWALL's reputation service, IONWALLET's transaction proposal service). These are not "agents" in the IONFLUX sense but are IAP participants.
*   **`AgentDefinition` as Agent Card / Service Definition:**
    *   For all agents (IONFLUX specialized or App-Core-Function services), the `AgentDefinition` schema (or an equivalent service definition manifest) serves as the "Agent Card."
    *   It describes identity, capabilities (skills), invocation methods (IAP endpoints, event subscriptions), input/output schemas, and IONWALL-required scopes. This is crucial for IAP discovery.
*   **`AgentConfiguration` for IONFLUX Instances:**
    *   User-specific configurations for instantiating and customizing IONFLUX `AgentDefinition`s for their particular needs (e.g., providing API key references, default parameters).
*   **IONVERSE Agent Protocol (IAP) as Lingua Franca:**
    *   All programmatic interactions between these ~20 entities adhere to IAP, ensuring they can discover, understand, and securely communicate with each other.

## 2. Agent 000: The Universal Orchestrator ("ION")

Agent 000 ("ION") is the user's primary intelligent interface and personal orchestrator for the entire IONVERSE. It aims to provide a seamless, natural language-driven experience, abstracting the complexity of the underlying multi-agent, multi-app ecosystem.

*   **Role & Purpose:**
    *   **Natural Language Understanding (NLU):** Interprets user commands given in text or voice.
    *   **Intent Recognition & Task Decomposition:** Identifies the user's goal and breaks it down into smaller, actionable tasks that can be handled by specialized agents or app functionalities.
    *   **Agent/Service Discovery:** Dynamically discovers available agents/services and their capabilities (skills, input/output schemas) using IAP mechanisms (querying a registry or resolving Agent Cards).
    *   **Orchestration & Task Dispatch:** Invokes the necessary agents/services in the correct sequence, passing appropriate data, using IAP calls (JSON-RPC `message/send` or publishing `PlatformEvent`s).
    *   **Context Management:** Maintains context across conversational turns and tasks.
    *   **Response Aggregation & Presentation:** Collects results from various agents/services and synthesizes them into a coherent response or action for the user.
    *   **Personalization:** Learns user preferences, habits, and common workflows to optimize interactions and provide proactive suggestions.
*   **Interaction Flow (Conceptual):**
    1.  **User Command:** User issues a command, e.g., "ION, find my notes on the 'Project Chimera' IONPOD episode, ask Scribe to draft a Python script based on the action items, then get Chronos to remind me to review it tomorrow morning."
    2.  **NLU & Decomposition (Agent 000):**
        *   Parse command, identify intents: "find_notes", "draft_script", "set_reminder".
        *   Identify entities: "Project Chimera episode" (IONPOD), "Python script" (Scribe), "action items" (IONPOD/Datascribe), "tomorrow morning" (Chronos).
    3.  **Discovery & Planning (Agent 000 using IAP):**
        *   Discover IONPOD skill: `queryKnowledgeBase(keywords, date_range)`.
        *   Discover Scribe skill: `generateCodeFromSpec(language, specification_text)`.
        *   Discover Chronos skill: `scheduleTask(task_description, due_datetime, target_action_event)`.
        *   Plan sequence: IONPOD -> Scribe -> Chronos.
    4.  **Task Dispatch (Agent 000 using IAP):**
        *   Call IONPOD: `message/send` with `skillId: "queryKnowledgeBase"`, params: `{ "keywords": "Project Chimera action items" }`.
        *   (Wait for response) -> Get `action_items_text`.
        *   Call Scribe: `message/send` with `skillId: "generateCodeFromSpec"`, params: `{ "language": "python", "specification_text": action_items_text }`.
        *   (Wait for response) -> Get `generated_script_cid`.
        *   Call Chronos: `message/send` with `skillId: "scheduleTask"`, params: `{ "task_description": "Review Python script for Project Chimera", "due_datetime": "tomorrow 09:00", "target_action_event": { "event_type": "user.reminder", "payload_json": { "message": "Review script: {{generated_script_cid}}" } } }`.
    5.  **Response Aggregation & Presentation (Agent 000):**
        *   "Okay, I've found your notes, asked Scribe to draft the Python script (it's now in your IONPOD at CID: ...), and set a reminder with Chronos for tomorrow at 9 AM."
*   **Security:** All actions dispatched by Agent 000 that involve sensitive data, resource consumption, or external interactions are subject to IONWALL approval, which may involve direct user confirmation for new or high-impact operations. Agent 000 itself has an `AgentDefinition` and operates under specific IONWALL scopes.

## 3. User Interaction with IONFLUX Agents (User-Initiated via IONFLUX Platform)

This model describes how users directly interact with and manage IONFLUX specialized agents through the IONFLUX UI (Canvas, Chat, Marketplace, Shelf), as adapted from `agent_interaction_model_v3.md`.

*   **3.1. Discovery & Instantiation (Marketplace, Shelf):**
    *   Users discover `AgentDefinition` blueprints in the IONFLUX Marketplace.
    *   They can "add" or "subscribe" to an agent, creating an `AgentConfiguration` instance on their "Shelf." This configuration links to the parent `AgentDefinition`.
*   **3.2. Configuration Interface (`yaml_config_text` & UI Modal):**
    *   Users customize their `AgentConfiguration` by providing specific parameters (e.g., API key references for IONWALLET, default prompts, target accounts). This is often done via a UI modal that translates to the `yaml_config_text` stored in the `AgentConfiguration`.
    *   The UI for configuration is dynamically rendered based on the `inputs_schema_json_array` from the agent's `AgentDefinition`.
*   **3.3. Invoking Actions (Canvas Snippets, Chat Commands, UI Buttons):**
    *   **Canvas:** Users drag agent instances from their Shelf onto the IONFLUX visual flow builder (Canvas). They configure its specific runtime inputs by connecting outputs from other nodes or manually entering values.
    *   **Chat:** Users can invoke agents via chat commands (e.g., `/muse generate story --prompt "A heroic cat"`). The `ChatService` parses this and routes it to `AgentService`.
    *   **Direct UI:** Some agents might have dedicated UIs or buttons for common actions.
*   **3.4. `AgentService` Orchestration & Effective Configuration:**
    *   All these user interactions are typically routed to the IONFLUX `AgentService`.
    *   `AgentService` takes the `AgentConfiguration.id`, any runtime parameters from the Canvas/Chat, and user context.
    *   It computes the **"effective configuration"** by merging:
        1.  `AgentDefinition.prm_details_json` (defaults).
        2.  `AgentConfiguration.yaml_config_text` (user's instance overrides).
        3.  Runtime parameters from the specific invocation.
    *   `AgentService` then initiates an `AgentRunLog` entry and dispatches the task (with the `effective_config_json` and a unique `run_id`) to the agent's runtime environment (e.g., Deno isolate, Python shell via NATS).
*   **3.5. Agent Runtime Execution & Callback:**
    *   The agent runtime executes its logic based on the `effective_config_json`.
    *   During execution, it can use IONFLUX Transforms (e.g., `FetchFromIONPOD_Transform_IONWALL`, `MuseGen_LLM_Transform`). These transforms handle their own IONWALL interactions for consent if needed.
    *   Upon completion (or failure, or for status updates), the agent runtime sends an HTTP callback to `AgentService` (`POST /agent-runs/{run_id}/completed` or `/updated`) with the results or error information.
*   **3.6. Output Presentation & `AgentRunLog`:**
    *   `AgentService` updates the `AgentRunLog` with the results.
    *   The IONFLUX UI (Canvas, Chat) subscribes to updates for the `run_id` and displays the outputs or status changes to the user.
*   **IAP Compliance of IONFLUX Agent Runtimes:**
    *   While the user interaction is mediated by `AgentService`, the actual runtime environment for an IONFLUX agent should be designed to be IAP-compliant if that agent needs to:
        *   Be discoverable and directly callable by Agent 000 or other IAP agents.
        *   Call other IAP-compliant services/agents within its own logic.
    *   This means its `AgentDefinition` must accurately reflect its IAP skills, and its runtime might embed an A2A server component or use an IAP client library.

## 4. Programmatic Agent & Service Interactions (The IONVERSE Agent Protocol - IAP)

This section details how agents and core ION app functionalities interact programmatically using IAP, referencing `/ionverse/specs/IONVERSE_AGENT_PROTOCOL.md`.

### 4.1. Agent/Service Discovery via IAP
*   **Agent Cards / Service Definitions:** All IAP-compliant entities (IONFLUX Agents, App Core Services, Agent 000 itself if exposing skills) must have an "Agent Card" or equivalent service definition.
    *   For IONFLUX Agents, this is derived from their `AgentDefinition` stored in the `agents_registry`.
    *   For App Core Services (IONWALL, IONWALLET, etc.), this is a published service manifest detailing their IAP skills and endpoint.
*   **Discovery Mechanism:**
    *   **Registry:** A central (or decentralized) IAP service registry where agents/services publish their Agent Cards. Agent 000 and other agents query this registry.
    *   **Well-Known URI:** Each IAP-compliant HTTP endpoint should expose its Agent Card at `/.well-known/agent.json` for direct discovery if its base URL is known.
*   **Content of Agent Card (for IAP):** Includes `id`, `name`, `description`, `a2a_http_endpoint_url`, list of `skills` (with `skillId`, `description`, `inputSchema`, `outputSchema`), and supported `PlatformEvent`s (consumed/produced).

### 4.2. Direct A2A Calls (JSON-RPC over HTTP/S)
*   **Transport:** HTTPS is mandatory for security. HTTP/2 preferred for performance.
*   **Protocol:** JSON-RPC 2.0.
*   **Request Structure:**
    *   `method`: Typically `"message/send"` as per A2A SDK example.
    *   `params`:
        *   `message`: (object)
            *   `messageId`: Client-generated unique ID (UUID).
            *   `role`: Identifier of the calling agent/user (e.g., their DID).
            *   `parts`: Array of input parts, e.g., `{ "type": "StructuredDataPart", "contentType": "application/json", "data": { ...skill-specific params... } }`. The `data` object aligns with the `inputSchema` of the target `skillId`.
        *   `skillId`: (string, optional) The specific skill/operation to invoke on the target agent/service. If omitted, the agent may use a default skill or require it.
        *   `run_context`: (object, optional) Contains `calling_agent_run_id`, `workspace_id`, `user_id` for tracing and context.
    *   `id`: JSON-RPC request ID.
*   **Response Handling:**
    *   **Synchronous Acknowledgement:** The HTTP response to the JSON-RPC call might be a quick acknowledgment (HTTP 202 Accepted) with a `taskId` or `runId` if the task is long-running.
    *   **Asynchronous Results (Streaming / EventQueue):** The A2A SDK's `EventQueue` model is adopted. The called agent, after initial acknowledgement, can send multiple events back to a pre-agreed callback URL or NATS subject specified by the caller (or implied by the `taskId`). These events can be status updates or partial results.
    *   **Final Result:** The final result is typically the last event in the stream or a specific "completed" event.
    *   **Errors:** Standard JSON-RPC error responses are used for protocol errors or immediate execution failures. Application-level errors for asynchronous tasks are reported in the event stream.

### 4.3. Event-Driven Communication (Message Bus - NATS/Kafka)
*   **`PlatformEvent` Schema:** All asynchronous, broadcasted events within IONVERSE **MUST** adhere to the `PlatformEvent` JSON schema:
    ```json
    {
      "event_id": "string (UUID)",
      "event_type": "string (namespaced, e.g., 'ionflux.shopify.order.created', 'ionwall.reputation.score_updated')",
      "event_timestamp": "timestamp (ISO 8601 UTC)",
      "source_service_name": "string (e.g., 'ShopifySalesSentinelAgent', 'IONWALL_ReputationEngine')",
      "user_did": "string (DID of the user context, nullable)",
      "workspace_id": "string (UUID, nullable, if applicable)",
      "correlation_id": "string (UUID, nullable, to link related events)",
      "payload_schema_version": "string (e.g., 'v1.0', 'v2.1')",
      "payload_json": "json_object (event-specific data, structure defined by event_type and payload_schema_version)"
    }
    ```
*   **Agent Consumption/Production:**
    *   `AgentDefinition.triggers_config_json_array` (type `event_stream`) specifies the NATS/Kafka topic and filters (e.g., JSONPath on `payload_json`) an IONFLUX agent consumes.
    *   `AgentDefinition.outputs_config_json_array` (type `event`) specifies the `event_type`(s) an IONFLUX agent might produce.
    *   Agent 000 and App Core Services also use this schema for their event interactions.

### 4.4. Interaction with App Core Functionalities (as IAP Services)

Each core ION application exposes key functionalities as IAP-compliant services, allowing Agent 000 and other agents to interact with them programmatically.

*   **IONWALL:**
    *   **Exposed Skills (Conceptual Examples):**
        *   `skillId: "getReputationScore"` (params: `{ targetDid, scoreTypes }`)
        *   `skillId: "evaluatePolicyForAction"` (params: `{ requesterDid, targetResource, action, context }`)
        *   `skillId: "requestUserConsent"` (params: `{ requesterDid, actionDescription, detailsCid, scopes }`) -> interfaces with `IONWALL_ActionApproval_Transform` logic.
        *   `skillId: "logAuditEvent"` (params: `{ eventDetails, actorDid }`)
        *   `skillId: "verifyCredentialPresentation"` (params: `{ holderDid, verifiablePresentation }`)
    *   **Events Consumed:** `ionwallet.transaction.initiated`, `ionflux.agent.action_requested_sensitive_data`.
    *   **Events Produced:** `ionwall.reputation.score_updated`, `ionwall.policy.violation_detected`.
*   **IONWALLET:**
    *   **Exposed Skills (Conceptual Examples):**
        *   `skillId: "getWalletBalances"` (params: `{ userDid, tokenTypeArray }`)
        *   `skillId: "proposeTokenTransfer"` (params: `{ ...details... }`) -> *Returns proposalId, requires user approval in IONWALLET UI.*
        *   `skillId: "proposeStakingOperation"` (params: `{ ...details... }`) -> *Returns proposalId, requires user approval in IONWALLET UI.*
    *   **Events Consumed:** `ionwall.reputation.score_fin_updated` (to adjust limits).
    *   **Events Produced:** `ionwallet.transaction.initiated_by_iap`, `ionwallet.transaction.confirmed_by_user_via_iap`, `ionwallet.transaction.confirmed_on_chain`.
*   **IONPOD:**
    *   **Exposed Skills (Conceptual Examples, AI Twin focused):**
        *   `skillId: "queryPersonalKnowledgeBase"` (params: `{ userDid, natural_language_query }`)
        *   `skillId: "summarizeContentItem"` (params: `{ userDid, itemCid, output_length_hint }`)
        *   `skillId: "draftContentFromPod"` (params: `{ userDid, topic, style_guide_cid, output_format }`)
        *   `skillId: "storeDataToPod"` (params: `{ userDid, data_to_store, target_path, metadata }`) -> (uses `StoreToIONPOD_Transform_IONWALL` logic)
    *   **Events Consumed:** `ionflux.agent.output_ready_for_pod_storage`.
    *   **Events Produced:** `ionpod.content.new_item_added`, `ionpod.ai_twin.insight_generated`.
*   **IONVERSE App (3D Hub):**
    *   **Exposed Skills (Conceptual Examples):**
        *   `skillId: "getShardDetails"` (params: `{ shardIdOrCid }`)
        *   `skillId: "listMarketplaceItems"` (params: `{ filtersJson }`)
        *   `skillId: "proposeAvatarAction"` (params: `{ userDid, actionType: 'emote', emoteId: 'wave' }`) -> *Requires user to be active in IONVERSE App; action performed by their Avatar.*
        *   `skillId: "publishToUserFeed"` (params: `{ userDid, content_cid, message }`)
    *   **Events Consumed:** `ionpod.content.new_item_published_publicly` (to show in feeds).
    *   **Events Produced:** `ionverse.avatar.entered_shard`, `ionverse.social.friend_request_sent`.

## 5. Advanced Agent Mode Interactions & IAP

(Adapting `agent_interaction_model_v3.md` Section 7 - PRM details)
Advanced IONFLUX agents, particularly those with "Pluggable Runtime Modules" (PRMs) like ARM A, B, Z, or "Reinforcement Learning Loops," interact with IAP in sophisticated ways:

*   **Configuration:** Users configure these advanced modes via the standard `AgentConfiguration` (`yaml_config_text`). This YAML might specify:
    *   Which IAP events the agent should monitor for its RL loop or experimental branches.
    *   Parameters for IAP calls it makes during its different modes (e.g., different `skillId`s or `params` for Agent B in an A/B test).
    *   Endpoints or skills of other agents it needs to coordinate with for complex experiments.
*   **Monitoring:** The agent's internal state and performance in different PRM modes are reported via custom `PlatformEvent`s (e.g., `ionflux.prm_agent.experiment_arm_a_result`, `ionflux.prm_agent.rl_loop_reward_update`). Agent 000 or a specialized analytics agent can subscribe to these for higher-level monitoring and control.
*   **Control:** Users (or Agent 000) can switch between an agent's PRM modes or update its experimental parameters by sending an IAP `message/send` call to a specific `skillId` on that agent (e.g., `skillId: "set_active_prm_mode"`, params: `{ "mode": "arm_z", "config_cid": "..." }`). This requires the agent's runtime to expose such an IAP skill.

## 6. Security, Consent & IONWALL in IAP Interactions

IONWALL is the linchpin for secure and consensual agent interactions.

*   **IONWALL's Role in IAP Calls:**
    *   **Authentication:** Every IAP call (HTTP JSON-RPC or NATS event leading to action) must carry verifiable identity of the caller (user DID via JWT, or agent's service DID via mTLS/signed message). IONWALL authenticates this.
    *   **Authorization:** IONWALL's OPA engine evaluates each IAP call against policies. Policies consider:
        *   Caller's identity and reputation.
        *   Target agent/service and requested `skillId`.
        *   Parameters being passed (especially CIDs of data being accessed/modified).
        *   Pre-existing user consents for the calling agent or the `ionwall_approval_scope` associated with the calling FluxGraph.
    *   **Resource Control:** IONWALL tracks C-ION consumption and can deny IAP calls that would exceed user budgets.
*   **`IONWALL_ActionApproval_Transform` as an IAP Interaction:**
    *   When an agent (including Agent 000 or an IONFLUX agent) determines that an explicit user confirmation is needed for a *subsequent* action it intends to perform (which might itself be another IAP call), it uses the `IONWALL_ActionApproval_Transform`.
    *   This transform, under the hood, makes an IAP call to IONWALL's `requestUserConsent` skill (or similar). This standardizes how any agent can request explicit, out-of-band user approval.
*   **Consent Gating Agent Capabilities:**
    *   An agent's IAP skills listed in its Agent Card are potential capabilities. Actual permission to use them is gated by IONWALL based on user consent given:
        *   At agent instantiation/configuration time (broad scopes).
        *   At the start of a FluxGraph run (scopes for that flow).
        *   Dynamically via `IONWALL_ActionApproval_Transform` (for specific, high-risk operations).
*   **Data Privacy in IAP Messages & `PlatformEvent` Payloads:**
    *   Agents should only exchange the minimum necessary data via IAP.
    *   If sensitive data must be passed in `message.parts` or `PlatformEvent.payload_json`, and the transport (NATS) is not E2EE for that topic, application-level encryption should be considered (e.g., encrypting specific JSON fields, with key exchange managed via IONWALL/IONWALLET). IONPOD interaction for data sharing often involves passing CIDs of already encrypted data.

## 7. Appendix: Example Interaction Scenarios (Illustrating IAP)

**Scenario 1: User -> Agent 000 -> IONPOD AI Twin (IAP Query) + IONFLUX Scribe Agent (IAP Task)**

1.  **User Command (Voice/Text to Agent 000 UI):** "ION, get the main points from my 'IONVERSE Vision' note in IONPOD, then ask Scribe to draft a short tweet thread about it."
2.  **Agent 000 (IAP Client):**
    *   Sends IAP JSON-RPC `message/send` to IONPOD service:
        *   `skillId: "queryPersonalKnowledgeBase"`
        *   `params: { "userDid": "user_did", "natural_language_query": "main points of 'IONVERSE Vision' note" }`
    *   IONPOD (IAP Server) responds with: `{ "status": "success", "summary_text": "The IONVERSE is about..." }`
3.  **Agent 000 (IAP Client):**
    *   Sends IAP JSON-RPC `message/send` to Scribe Agent (IONFLUX):
        *   `skillId: "draftTextFromInput"` (conceptual Scribe skill)
        *   `params: { "userDid": "user_did", "input_text": "The IONVERSE is about...", "output_format_request": "twitter_thread_3_tweets", "style_hint": "concise_and_impactful" }`
    *   Scribe Agent (IAP Server) processes, then its EventQueue might stream back:
        *   Event 1: `{ "type": "StatusUpdatePart", "status": "processing_tweet_1" }`
        *   Event 2: `{ "type": "TextPart", "text": "Tweet 1: ..." }`
        *   ...
        *   Event N: `{ "type": "TaskCompletionPart", "status": "success", "final_result_cid": "bafy..." }` (if stored to IONPOD)
4.  **Agent 000:** Aggregates tweet thread, presents to user for review/posting.

**Scenario 2: IONFLUX Shopify Sales Sentinel (triggered by NATS `PlatformEvent`) -> IAP call to IONWALL (`evaluatePolicy`) -> IAP call to Comm Link Agent (to send alert).**

1.  **External Event:** Shopify sends a webhook for "new order" to an IONFLUX webhook trigger.
2.  **IONFLUX Flow (Initial Transform):** A transform parses the webhook and publishes an IAP `PlatformEvent`:
    *   `event_type: "ionverse.shopify.order.created"`
    *   `payload_json: { "order_id": "123", "total_amount": 250.00, "customer_email": "...", "items_count": 3 }`
3.  **Shopify Sales Sentinel (IONFLUX Agent - IAP Event Consumer):**
    *   Triggered by the `ionverse.shopify.order.created` event.
    *   Its FluxGraph logic analyzes the order. Let's say it detects a high-value order from a new customer with a high-risk score (from a previous IONWALL lookup not shown here).
4.  **Shopify Sales Sentinel (IAP Client to IONWALL):**
    *   Sends IAP JSON-RPC `message/send` to IONWALL:
        *   `skillId: "evaluatePolicyForAction"`
        *   `params: { "requesterDid": "did_of_sales_sentinel_instance", "targetResource": "order_id_123", "action": "flag_for_review", "context": { "order_amount": 250.00, "customer_risk_score": "high" } }`
    *   IONWALL responds: `{ "result": { "allow": true, "decision_id": "...", "actions_to_take": ["log_high_risk_order", "alert_fraud_team"] } }` (policy allows flagging and alerting).
5.  **Shopify Sales Sentinel (IAP Client to Comm Link Agent):**
    *   Sends IAP JSON-RPC `message/send` to Comm Link Agent:
        *   `skillId: "send_email"`
        *   `params: { "recipient_address_key": "fraud_team_email_group", "template_id": "high_risk_order_alert", "template_params": { "order_id": "123", "reason": "High value from new high-risk customer" } }`
    *   Comm Link Agent sends the email.

**Scenario 3: Agent 000 proposes a transaction -> IAP call to IONWALLET (`proposeTokenTransfer`) -> User Confirmation in IONWALLET UI -> IONWALLET emits `PlatformEvent` (`ionwallet.transaction.confirmed_by_user`).**

1.  **User Command to Agent 000:** "ION, pay JohnDoeDID 50 ION for the design work."
2.  **Agent 000 (IAP Client to IONWALLET):**
    *   Sends IAP JSON-RPC `message/send` to IONWALLET's IAP service:
        *   `skillId: "proposeTokenTransfer"`
        *   `params: { "requesterAgentDid": "did_of_agent_000_instance", "fromUserDid": "current_user_did", "toUserDidOrAddress": "JohnDoeDID", "tokenSymbol": "ION", "amountWei": "50000000000000000000", "purposeMetadataCid": "cid_for_payment_for_design_work" }`
    *   IONWALLET IAP service responds: `{ "result": { "proposalId": "prop_789", "status": "pending_user_approval_in_ionwallet" } }`
3.  **IONWALLET UI:**
    *   User receives a notification in their IONWALLET app (mobile/web).
    *   Opens IONWALLET, sees a clear prompt: "Agent 000 proposes sending 50 ION to JohnDoeDID for 'Design Work'. [Approve] [Reject]". Details from `purposeMetadataCid` are shown.
    *   User clicks [Approve] and authenticates with their Passkey.
4.  **IONWALLET Backend:**
    *   Securely constructs and signs the transaction using user's ERC-4337 account via Wallet Core SDK / Passkey. Submits to Base L2.
5.  **IONWALLET (IAP `PlatformEvent` Producer):**
    *   Publishes `PlatformEvent` to NATS:
        *   `event_type: "ionwallet.transaction.approved_by_user_via_iap"` (and later `...confirmed_on_chain`)
        *   `payload_json: { "proposalId": "prop_789", "userDid": "current_user_did", "chain_tx_hash": "0xabc..." }`
6.  **Agent 000 (IAP `PlatformEvent` Consumer):**
    *   Subscribed to these events, receives confirmation, and informs user: "Payment of 50 ION to JohnDoeDID approved and submitted to the network."

This v4 model emphasizes IAP as the core communication backbone, enabling more fluid, standardized, and secure interactions across the diverse landscape of IONVERSE agents and services.
