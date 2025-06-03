# IONFLUX Project: Technical Stack & E2E Demo Strategy (v3)

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
    *   **Justification:** The PRM blueprints consistently specify Python 3.12+, FastAPI, and libraries like LangChain/LangGraph for complex agent workflows, data processing, and AI model interaction. This makes it the definitive choice for the core agentic layer. (Other existing justifications for Python/FastAPI remain valid).
*   **Primary Choice for Real-time UI-Facing Services: Node.js with Express.js/NestJS**
    *   **Services:** `User Service`, `Workspace Service`, `Canvas Service`, `Chat Service`, `Notification Service`, `WebSocketService`.
    *   **Justification:** Node.js's strengths in handling real-time, concurrent connections (WebSockets) and I/O-bound tasks remain crucial for these user-facing services. (Other existing justifications remain valid).
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
    *   (Retain as secondary options for previously stated use cases like `ChatMessage.content_json`, `CanvasBlock.content_json`, or advanced log search via Elasticsearch, but note that many agent-specific structured data needs are now met by dedicated Postgres tables per agent).

**1.4. Message Broker / Event Bus (Revised Emphasis):**

*   **Primary Event Bus: Apache Kafka**
    *   **Justification:** Elevated to the **central, high-throughput event bus** for all significant platform-level events and critical asynchronous inter-agent/service communication. This aligns with the event-driven architecture implied by multiple PRM agents (e.g., Sales Sentinel consuming Shopify order events, Badge Motivator consuming platform activity events) and the `PlatformEvent` schema in `conceptual_definition_v3.md`.
    *   **Usage:** Streaming Shopify webhooks (via `ShopifyIntegrationService`), agent output events, triggers for event-driven agents, audit trails, data propagation for real-time analytics. Event schemas will follow `PlatformEvent` structure.
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
    *   **Simulation:** An n8n workflow (acting as an external event simulator) posts a mock high-value Shopify order JSON to a specific **Kafka topic** (e.g., `ionflux.shopify.ws_ecothreads.orders.created`). This event uses the `PlatformEvent` schema.
    *   **Agent Activation:** The pre-configured `Shopify Sales Sentinel` (Agent 004 - PRM version, running in a minimal Python/FastAPI shell) consumes this event from its designated Kafka topic (as per its `AgentConfiguration` which references `AgentDefinition.triggers_config_json_array`).
    *   **Agent Processing (Mocked Core Logic):** The Sentinel's Python script identifies the order as a "high-value anomaly" based on its (simplified demo) rules.
    *   **Cross-Agent Communication & Notification:** The Sentinel formats an alert (as a `ChatMessage` payload) and posts it to a designated "Alerts" channel in the IONFLUX Chat Dock. This is achieved by calling the `ChatService` API. (Alternatively, it could publish an `ionflux.agent.salessentinel.alert_generated` Kafka event, which `NotificationService` or a chat bot component of `ChatService` consumes).
3.  **Insight & Analysis on Canvas:**
    *   User reviews the alert in the Chat Dock.
    *   User navigates to a Canvas Page. Drags the `Revenue Tracker Lite` (Agent 010 - PRM version, also a Python/FastAPI shell) onto the Canvas and configures it for their "EcoThreads Boutique" Shopify store using the Agent Configuration Modal.
    *   The `Revenue Tracker Lite` agent snippet block populates with (mocked, but PRM-capability-aligned) profitability insights, potentially highlighting the product from the high-value order.
4.  **Content Creation & Persona Alignment:**
    *   Based on insights (e.g., high-profit product), user decides to create a promotional email.
    *   User uses the `Email Wizard` (Agent 001 - PRM, Python/FastAPI shell) from the Canvas or Chat. They select a (mocked) prompt from a `PromptLibrary` like "Generate exciting promo email for [Product Name]".
    *   The `Email Wizard` generates draft email copy (mocked LLM interaction).
    *   User then drags the `Creator Persona Guardian` (Agent 008 - PRM, Python/FastAPI shell) onto the Canvas, links the generated email copy to it (e.g., by referencing the block ID or passing text).
    *   The `Creator Persona Guardian` (mocked logic) provides a score (e.g., "85% Persona Alignment") and a brief (mocked) suggestion for improvement, displayed in its agent snippet block.
5.  **Review & Next Steps:**
    *   User has an alert, profitability insights, a draft email, and persona feedback, all within IONFLUX, showcasing an integrated workflow driven by advanced agents and event-based interactions.

**2.2. Key Screens/Interfaces to Mock/Build for Demo:**
*   (Largely as previously defined: Login/Signup, Workspace Dashboard/Switcher, Sidebar, Canvas Page View, Chat Dock, Agent Marketplace (simplified), Connection Modals, Notifications).
*   **Agent Configuration Modal:** Crucially, this must clearly display read-only `AgentDefinition` details (especially `triggers_config_json_array` for event-driven agents like Sales Sentinel, showing default Kafka topics/filters, and `inputs_schema_json_array` for required inputs) alongside the editable `yaml_config_text` area. This aligns with `agent_interaction_model_v3.md`.
*   **Canvas `Agent Snippet` Block:** Needs to robustly display status and summary outputs from the Python shell-based agents, and support the "View Full Output" modal which might show more complex JSON or markdown.
*   **Chat Dock:** Must render agent-generated messages (alerts, summaries) with appropriate formatting (markdown, simple JSON structures) as per `conceptual_definition_v3.md` and `agent_interaction_model_v3.md`.

**2.3. Prototyping Tools/Approach (Revised Strategy):**

The complexity of PRM agents necessitates a refined prototyping strategy for the E2E demo.

*   **n8n Workflows (Role Shifted):**
    *   **Primarily for Event Simulation:** To simulate external systems or other platform parts posting data to Kafka topics (e.g., mock Shopify orders as `PlatformEvent` JSONs). An n8n workflow can be triggered manually or on a schedule to send these to Kafka.
    *   **Mocking External SaaS APIs (Simplistic):** Can provide simple, canned JSON responses if IONFLUX services (like `LLMOrchestrationService` or `ShopifyIntegrationService`) need to make outbound calls during a demo sequence. The Python agent shells would call these mocked IONFLUX service endpoints.
    *   *n8n will generally not be used to mock the core internal logic of the PRM agents themselves for the demo.*
*   **Minimal Service Shells (Python/FastAPI - Primary for Key Demo Agents):**
    *   **Target Agents for Demo:** `Shopify Sales Sentinel` (Agent 004), `Revenue Tracker Lite` (Agent 010), `Email Wizard` (Agent 001), `Creator Persona Guardian` (Agent 008) – chosen for their roles in the revised demo flow.
    *   **Implementation:** Each will be a lean FastAPI service application, containerized with Docker.
        *   **API Endpoints:** Expose HTTP endpoints that the `AgentService` can call to trigger runs (as defined in `agent_interaction_model_v3.md`).
        *   **Kafka Consumers (if applicable):** For agents like `Shopify Sales Sentinel`, the shell will include a Python Kafka consumer (e.g., using `kafka-python` library) to listen to relevant topics defined in its `AgentConfiguration`.
        *   **Mocked Core Logic:** The FastAPI endpoint handlers or Kafka message processors will execute a **simplified Python script**. This script *mocks the outcome* of the complex PRM internal operations (e.g., no actual ML, RL, or full LangGraph execution).
            *   *Example (Sales Sentinel):* Consumes a Kafka message; if `order.total > 100`, it constructs an alert payload.
            *   *Example (Email Wizard):* Receives `topic` via API; returns `f"Exciting email for {topic}! Buy now!"`.
        *   **Interaction with Mocked IONFLUX Services:** These Python scripts can make HTTP requests to other IONFLUX services (e.g., `LLMOrchestrationService`, `AudioService`), which themselves will be mocked at their API boundaries (potentially by n8n webhooks or other simple FastAPI mocks).
        *   **Output Generation:** Produces output according to its `AgentDefinition.outputs_config_json_array` (e.g., posts a `PlatformEvent` to a Kafka topic for other agents/services, or returns JSON for an API call to `AgentService`).
    *   **Rationale:** This approach allows the demo to:
        *   Run agents in a Python environment, closer to their PRM specification.
        *   Use actual Kafka consumers/producers for demonstrating event-driven parts.
        *   Have agents with callable APIs as per the platform architecture.
        *   Focus demo development on the agent's *interface contract* (API, event schemas, configuration) rather than its complex internals.
*   **Other Agents in "FREE-10" (Contextual Representation):**
    *   Agents not actively participating in the main demo flow (e.g., `WhatsApp Pulse`, `TikTok Stylist`, `UGC Matchmaker`, `Outreach Automaton`, `Slack Brief Butler`, `Badge Motivator` if not central to the flow) can be represented by their detailed `AgentDefinition` in the Agent Marketplace. If a user configures one, its execution can be very simply mocked by `AgentService` itself or a generic n8n workflow that just acknowledges the run and returns a canned "output preview" without a dedicated Python shell.
*   **Core IONFLUX Services (`User`, `Workspace`, `AgentService`, `Canvas`, `Chat`, `LLMOrchestration`, `AudioService`, `ShopifyIntegration`, `Kafka Bus`):**
    *   `User Service`, `Workspace Service`, `AgentService` (for CRUD of `AgentDefinition`s based on PRM YAMLs and `AgentConfiguration`s), `Canvas Service`, `Chat Service`: Require minimal robust implementations for core E2E demo functionality (persisting configurations, pages, messages).
    *   `LLMOrchestrationService`, `AudioService`, `ShopifyIntegrationService`: Can be heavily mocked at their API boundaries (e.g., using n8n webhooks or simple FastAPI endpoint mocks) to provide canned responses to the Python agent shells.
    *   **`Kafka Bus`:** A real, lightweight Kafka instance (e.g., local Docker container via Redpanda/Strimzi, or a small cloud instance) is **essential** for the revised demo flow.

**2.4. Focus of the Demo (Revised):**

*   Validate the core User Experience for configuring and interacting with more advanced, PRM-defined agents via the updated Agent Configuration Modal and Agent Snippets.
*   **Demonstrate the event-driven architecture:** Clearly show a simulated external event (Shopify order via n8n) flowing through Kafka, triggering a Python-shelled agent (`Shopify Sales Sentinel`), and resulting in a user-visible outcome (chat alert).
*   Illustrate conceptual inter-agent communication/synergy (e.g., insights from `Revenue Tracker Lite` informing content creation with `Email Wizard`, which is then checked by `Creator Persona Guardian`).
*   Showcase the *nature and potential* of PRM agent capabilities (e.g., "Sales Sentinel's advanced models detected this anomaly based on subtle deviations...", "Persona Guardian uses multimodal analysis of your brand's core assets to provide this alignment score...").
*   Verify that the platform can manage and trigger agents whose mocked runtimes are Python-based and interact with Kafka.
*   Gather early feedback on the perceived intelligence, utility, and usability of the more powerful and interconnected agent ecosystem.

This revised strategy aims for a more authentic representation of the PRM agent architecture within the E2E demo, particularly the event-driven aspects and Python-based agent runtimes, while still heavily mocking the deep internal logic of the agents themselves.
```
