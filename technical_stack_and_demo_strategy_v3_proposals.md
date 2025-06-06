```markdown
# IONFLUX Project: Technical Stack & E2E Demo Strategy (v3 Proposals)

This document proposes updates to the preliminary technical stack and E2E demo strategy for IONFLUX, aligning with `core_agent_blueprints_v3.md` (PRM), `conceptual_definition_v3.md`, and `saas_api_integration_specs_v3.md`.

## 1. Preliminary Technical Stack Proposal (Revised)

This stack is updated to reflect the technologies and architectural patterns solidified in the v3 design documents.

**1.1. Frontend:** (No major changes proposed, React with Next.js remains primary)

*   **Primary Framework: React (with Next.js)**
    *   (Existing justifications remain valid)
*   **Alternative/Consideration: Svelte (with SvelteKit)**
    *   (Existing justifications remain valid)

**1.2. Backend (Microservices):**

*   **Primary Choice for Agent Core Logic & Specialized Services: Python 3.12+ with FastAPI, LangChain, LangGraph**
    *   **Services:** `Agent Service`, `LLM Orchestration Service`, `AudioService` (newly specified for TTS/STT), `Shopify Integration Service`, `TikTok Integration Service`, and services directly implementing complex agent logic derived from PRM blueprints.
    *   **Justification:** (Existing justifications enhanced by PRM specifics) The PRM blueprints consistently specify Python 3.12+, FastAPI, and libraries like LangChain/LangGraph for complex agent workflows, data processing, and AI model interaction. This makes it the definitive choice for the core agentic layer.
*   **Primary Choice for Real-time UI-Facing Services: Node.js with Express.js/NestJS**
    *   **Services:** `User Service`, `Workspace Service`, `Canvas Service`, `Chat Service`, `Notification Service`, `WebSocketService`.
    *   **Justification:** (Existing justifications remain valid) Node.js's strengths in handling real-time, concurrent connections (WebSockets) and I/O-bound tasks remain crucial for these user-facing services.
*   **Alternative for Specific High-Performance Needs: Go**
    *   (Existing justifications remain valid, e.g., for API Gateway components).

**1.3. Databases (Revised & Expanded):**

*   **Primary Relational Database: PostgreSQL**
    *   **Justification:** (Existing justifications remain valid).
    *   **Data Types:** Core platform entities (`User`, `Workspace`, `AgentDefinition`, `AgentConfiguration`, `AgentRunLog`, `Playbook`, etc.) and, importantly, **agent-specific structured data stores** as detailed in PRM blueprints (e.g., `rt_shopify_orders_processed` for Agent 010, `outreach_leads` for Agent 006). Each agent requiring such storage will have its schema managed within its own service/codebase but will utilize the platform's PostgreSQL infrastructure.
*   **Vector Database: Pinecone**
    *   **Justification:** Explicitly chosen as the primary Vector Database for all agents requiring RAG, semantic search, and embedding storage, as per numerous PRM blueprints (Agents 001, 002, 003, 004, 005, 006, 007, 008, 010). Platform-managed via central keys, with namespaces resolved and used by agents via `AgentService`.
    *   **Data Types:** Vector embeddings of documents, text chunks, images, audio, persona fingerprints, etc.
*   **In-Memory Key-Value Store: Redis**
    *   **Justification:** Caching (API responses, LLM prompt/completion caches), session management, rate limiting, real-time presence, and as a **message broker/queue for simpler, intra-service or less critical inter-service task management** (e.g., using RQ or Redis Streams as indicated in PRM for agents like EmailWizard, OutreachAutomaton). This complements Kafka for less demanding queueing needs.
*   **Time-Series Database: TimescaleDB (PostgreSQL Extension)**
    *   **Justification:** Explicitly required by PRM for Agent 004 (Shopify Sales Sentinel v2) for storing `shop_performance_metrics` (CVR, AOV, error rates over time) for trend analysis and anomaly detection.
    *   **Data Types:** Time-stamped performance metrics.
*   **NoSQL Document Store (MongoDB/Elasticsearch):**
    *   (Retain as secondary options for previously stated use cases like `ChatMessage` content, `CanvasBlock.content_json`, or advanced log search via Elasticsearch, but note that many agent-specific structured data needs are now met by dedicated Postgres tables per agent).

**1.4. Message Broker / Event Bus (Revised Emphasis):**

*   **Primary Event Bus: Apache Kafka**
    *   **Justification:** Elevated to the **central, high-throughput event bus** for all significant platform-level events and critical asynchronous inter-agent/service communication. This aligns with the event-driven architecture implied by multiple PRM agents (e.g., Sales Sentinel consuming Shopify order events, Badge Motivator consuming platform activity events) and the `PlatformEvent` schema in `conceptual_definition_v3.md`.
    *   **Usage:** Streaming Shopify webhooks, agent output events, triggers for event-driven agents, audit trails, data propagation for real-time analytics.
*   **Secondary Queuing: Redis (RQ / Streams)**
    *   **Justification:** Suitable for simpler, intra-service task queuing or less critical inter-service messaging where the overhead of Kafka is not justified, as seen in several PRM agent blueprints for background processing.
    *   **Usage:** Distributing tasks within an agent's own service, managing short-lived job queues.

**1.5. Key Platform Services (Updates & Additions):**

*   **LLM Orchestration Service:** (Confirming role from `saas_api_integration_specs_v3.md`) Manages diverse models (OpenAI suite including GPT-4o Vision/DALL-E 3/CLIP/Whisper, Anthropic Claude 3 Haiku, DeepSeek DS-Chat-B32, Sentence-Transformers) and tasks (text_generation, embedding, speech_to_text, image_understanding).
*   **Audio Service (New):** (As specified in `saas_api_integration_specs_v3.md`) A dedicated service for centralizing Text-to-Speech (Azure, ElevenLabs, Coqui TTS) and Speech-to-Text (Whisper, potentially others) capabilities required by various PRM agents (002, 003, 007, 008).
*   **API Gateway:** (No change, Kong or cloud-managed still preferred).

**1.6. Deployment & Infrastructure:** (Confirming previous updates)
*   **Containerization: Docker & Kubernetes (K8s)**
*   **Cloud Provider: Flexible (AWS, GCP, Azure)**

**1.7. Real-time Communication:** (No change, WebSockets via Node.js services)

**1.8. Observability & Operational Tooling Strategy (Revised Section Title & Confirmation):**
*   **Internal Observability Suite:** Formally adopt OpenTelemetry as the standard for traces, metrics, and logs. Backend composed of Prometheus (metrics), Grafana (visualization), Loki (logging), Jaeger/Zipkin (tracing), as consistently specified in PRM agent blueprints.
*   **CI/CD & Deployment Tooling:** Standardize on GitHub Actions for CI/CD. Docker (with Buildx) for containerization. Target deployment platforms like Fly.io, Railway.app for simplified PaaS-like management of containerized services, with Kubernetes as an option for more complex orchestration needs (e.g., Kafka, Flink/Spark clusters if used by agents like Sales Sentinel).

## 2. End-to-End (E2E) Demo Flow & Prototyping Strategy (Revised)

The E2E demo needs to evolve to showcase the more advanced, interconnected, and event-driven capabilities of the PRM agents.

**2.1. Core User Journey for E2E Demo (Revised Narrative):**

This revised journey emphasizes event-driven interactions and the advanced analytical capabilities of PRM agents.

1.  **Onboarding & Initial Setup:**
    *   User signs up, creates a Workspace ("My Sustainable Apparel Brand").
    *   User connects their Shopify store (Brand: "EcoThreads Boutique") via the guided OAuth flow in IONFLUX. `ShopifyIntegrationService` confirms connection.
2.  **Event-Driven Anomaly Detection (Kafka in Action):**
    *   **Simulation:** An n8n workflow (acting as an external event simulator) posts a mock high-value Shopify order JSON to a specific **Kafka topic** (e.g., `ionflux.shopify.ws_ecothreads.orders.created`).
    *   **Agent Activation:** The pre-configured `Shopify Sales Sentinel` (Agent 004 - PRM version, running in a minimal Python/FastAPI shell) consumes this event from Kafka.
    *   **Agent Processing (Mocked Core Logic):** The Sentinel's script identifies the order as "high-value anomaly" based on its (simplified demo) rules.
    *   **Cross-Agent Communication & Notification:** The Sentinel formats an alert and posts it to a designated "Alerts" channel in the IONFLUX Chat Dock. This might involve directly calling the `ChatService` API or publishing another Kafka event (e.g., `ionflux.agent.salessentinel.alert_generated`) that a notification component (part of `ChatService` or `NotificationService`) consumes to render the chat message.
3.  **Insight & Analysis on Canvas:**
    *   User reviews the alert in the Chat Dock.
    *   User navigates to a Canvas Page. Drags the `Revenue Tracker Lite` (Agent 010 - PRM version, also a Python/FastAPI shell) onto the Canvas and configures it for their "EcoThreads Boutique" Shopify store.
    *   The `Revenue Tracker Lite` block populates with (mocked, but PRM-capability-aligned) profitability insights, potentially highlighting the product from the high-value order.
4.  **Content Creation & Persona Alignment:**
    *   Based on insights (e.g., high-profit product), user decides to create a promotional email.
    *   User uses the `Email Wizard` (Agent 001 - PRM, Python/FastAPI shell) from the Canvas or Chat. They select a (mocked) prompt from a `PromptLibrary` like "Generate exciting promo email for [Product Name]".
    *   The `Email Wizard` generates draft email copy.
    *   User then drags the `Creator Persona Guardian` (Agent 008 - PRM, Python/FastAPI shell) onto the Canvas, links the generated email copy to it.
    *   The `Persona Guardian` (mocked logic) provides a score (e.g., "85% Persona Alignment") and a brief (mocked) suggestion for improvement.
5.  **Review & Next Steps:**
    *   User has an alert, profitability insights, a draft email, and persona feedback, all within IONFLUX, showcasing an integrated workflow.

**2.2. Key Screens/Interfaces to Mock/Build for Demo:**
*   (Largely as previously defined, but interactions will be richer)
*   **Agent Configuration Modal:** Must clearly show read-only `AgentDefinition` details (especially `triggers_config_json_array` for event-driven agents) and the `yaml_config_text` area for instance-specific settings (e.g., Kafka topic filters if user-configurable).
*   **Canvas `Agent Snippet` Block:** Needs to display status and potentially summary outputs from Python shell-based agents.
*   **Chat Dock:** Must render formatted agent alerts and allow invocation of agents that might then publish to or consume from Kafka.

**2.3. Prototyping Tools/Approach (Revised Strategy):**

The complexity of PRM agents (Python stacks, LangGraph, ML models, Kafka consumers/producers) necessitates a shift in the prototyping strategy.

*   **n8n Workflows (Role Shifted):**
    *   **Primarily for Event Simulation:** To simulate external systems posting data to Kafka topics (e.g., mock Shopify orders, mock social media events).
    *   **Mocking External SaaS APIs:** Can provide simple, canned JSON responses if IONFLUX services (like `LLMOrchestrationService` or `ShopifyIntegrationService`) call out to them during the demo.
    *   *Not for mocking the core logic of PRM agents.*
*   **Minimal Service Shells (Python/FastAPI - Primary for Demo Agents):**
    *   **Target Agents for Demo:** `Shopify Sales Sentinel` (Agent 004), `Revenue Tracker Lite` (Agent 010), `Email Wizard` (Agent 001), `Creator Persona Guardian` (Agent 008).
    *   **Implementation:** Each of these will be a lean FastAPI service.
        *   It will expose HTTP endpoints that the `AgentService` can call (as defined in `agent_interaction_model_v3.md`).
        *   It will include a Python Kafka consumer if it's triggered by Kafka events (e.g., Sales Sentinel).
        *   The core logic will be a **simplified Python script** that *mocks the outcome* of the complex PRM internal operations. No actual ML, RL, or full LangGraph execution.
            *   Example: Sales Sentinel script: `if kafka_message.order.total > 100: generate_alert_payload()`.
            *   Example: Email Wizard script: `return f"Exciting email for {params['product_name']}! Buy now!"`.
        *   It will interact with *other mocked* IONFLUX services (e.g., call a mocked `LLMOrchestrationService` endpoint that might be an n8n webhook).
        *   It will produce output according to its `AgentDefinition.outputs_config_json_array` (e.g., post to a Kafka topic, return JSON).
    *   **Rationale:** This approach allows the demo to run agents in a Python environment, use actual Kafka consumers/producers (for event-driven parts), and have APIs callable by `AgentService`, providing a more representative mock of the PRM architecture.
*   **Other Agents in "FREE-10" (for demo context, if not actively used in the flow):**
    *   These can be represented by their `AgentDefinition` in the marketplace. If configured, their execution might be fully mocked by `AgentService` itself or a generic n8n workflow, simply returning a canned response without a dedicated Python shell.
*   **Core IONFLUX Services (`User`, `Workspace`, `AgentService`, `Canvas`, `Chat`, `LLMOrchestration`, `AudioService`, `ShopifyIntegration`, `Kafka Bus`):**
    *   `User`, `Workspace`, `AgentService` (for CRUD of Definitions/Configurations), `Canvas`, `Chat`: Minimal robust implementations are still needed.
    *   `LLMOrchestrationService`, `AudioService`, `ShopifyIntegrationService`: Can be heavily mocked at their API boundaries (e.g., using n8n webhooks to return canned data) for what the Python agent shells will call.
    *   `Kafka Bus`: A real Kafka instance (local Docker or cloud) is essential for the demo.

**2.4. Focus of the Demo (Revised):**

*   Validate the core UX for configuring and interacting with more advanced, event-driven PRM agents.
*   **Demonstrate the event-driven architecture:** Show a Kafka event triggering an agent and leading to a user-visible outcome.
*   Illustrate conceptual inter-agent communication (e.g., one agent's output/alert being acted upon by a user who then invokes another agent).
*   Showcase the *potential and nature* of PRM agent capabilities (e.g., "Sales Sentinel's models would have detected this...", "Persona Guardian uses multimodal analysis to provide this feedback...").
*   Verify that the platform can manage agents with diverse underlying technologies (Python shells) and trigger mechanisms (API, Kafka).
*   Gather feedback on the clarity of the more complex agent interactions and the value proposition of the PRM-level agents.

This revised strategy aims for a more authentic representation of the PRM agent architecture within the E2E demo, particularly the event-driven aspects and Python-based agent runtimes, while still heavily mocking the deep internal logic of the agents themselves.
```
