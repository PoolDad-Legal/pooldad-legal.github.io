# IONFLUX Project: Preliminary Technical Stack & E2E Demo Strategy

This document outlines a preliminary technical stack proposal for IONFLUX and defines a strategy for an initial End-to-End (E2E) demo, drawing upon all previously generated design documents.

## 1. Preliminary Technical Stack Proposal

This stack is proposed with scalability, performance, developer productivity, and suitability for AI/ML and real-time features in mind.

**1.1. Frontend:**

*   **Primary Framework: React (with Next.js)**
    *   **Justification:**
        *   **Rich Ecosystem & Community:** Large talent pool, extensive libraries (state management like Redux/Zustand, UI components like Material UI/Chakra UI), and strong community support.
        *   **Component-Based Architecture:** Aligns well with IONFLUX's modular UI (Canvas blocks, sidebar sections).
        *   **Performance:** Next.js offers server-side rendering (SSR), static site generation (SSG), image optimization, and route pre-fetching, contributing to a fast user experience.
        *   **Developer Experience:** Features like Fast Refresh in Next.js improve productivity.
        *   **TypeSafety:** Strong TypeScript support is well-integrated.
*   **Alternative/Consideration: Svelte (with SvelteKit)**
    *   **Justification:** Known for its performance (compiles to vanilla JS), smaller bundle sizes, and potentially simpler state management for certain use cases. Could be considered for highly interactive parts like the Canvas if React performance becomes a concern, or for specific micro-frontends.

**1.2. Backend (Microservices):**

A polyglot approach is feasible, but consistency in core areas is beneficial.

*   **Primary Choice: Python with FastAPI (and associated libraries like LangChain, LangGraph, Pydantic)**
    *   **Services:** Python with FastAPI (and associated libraries like LangChain, LangGraph, Pydantic) is the **strongly preferred primary choice** for most microservices, especially those involving agent logic, LLM interactions, and complex data processing, as reflected in the detailed agent blueprints. This includes services like `Agent Service`, `LLM Orchestration Service`, `Shopify Integration Service`, `TikTok Integration Service`, and any services directly implementing core agent functionalities.
    *   **Justification:**
        *   **AI/ML Ecosystem:** Python's extensive libraries for AI/ML (e.g., Hugging Face Transformers, Langchain, spaCy) are invaluable for agent development and LLM interaction. The consistent use of Python 3.12+, FastAPI, LangChain, and LangGraph across all 10 core agent blueprints underscores its suitability for building the agentic capabilities of IONFLUX.
        *   **Async Capabilities:** FastAPI is built on Starlette and Pydantic, offering excellent support for asynchronous programming, crucial for I/O-bound tasks like calling external APIs (LLMs, Shopify, TikTok).
        *   **Performance:** FastAPI is one of the fastest Python frameworks.
        *   **Developer Productivity:** Automatic data validation, serialization, and API documentation (Swagger/OpenAPI) speed up development.
        *   **Ease of Learning:** Python's readability is generally high.
*   **Secondary Choice: Node.js with Express.js/NestJS**
    *   **Services:** `User Service`, `Workspace Service`, `Canvas Service`, `Chat Service`, `Notification Service`.
    *   **Justification:**
        *   **Real-time Communication:** Node.js excels at handling real-time, concurrent connections (WebSockets for Chat, Canvas collaboration).
        *   **I/O Throughput:** Excellent for services that are primarily I/O bound and require high concurrency (e.g., managing many simultaneous chat connections or canvas updates).
        *   **JavaScript Ecosystem:** Can share code/types with the frontend if using TypeScript across the stack. NestJS offers a more structured, opinionated framework similar to Angular.
*   **Alternative for Specific High-Performance Needs: Go**
    *   **Services:** Potentially `API Gateway` components, or core parts of `Chat Service` if extreme concurrency is needed.
    *   **Justification:** Excellent performance, concurrency model (goroutines), and low memory footprint. Steeper learning curve than Python/Node.js for many teams.

**1.3. Databases:**

*   **Primary Relational Database: PostgreSQL**
    *   **Justification:** Robust, feature-rich (JSONB support, full-text search, extensibility), highly scalable, and strong community support. ACID compliant.
    *   **Data Types:** Core transactional data, user accounts (`User`), workspaces (`Workspace`), brand/creator profiles (`Brand`, `Creator`), prompt libraries (`PromptLibrary`, `Prompt`), agent configurations (`AgentConfiguration`, `AgentDefinition`), canvas structure (`CanvasPage`, `CanvasBlock` core attributes), chat channels (`ChatDockChannel`), financial records (`PlatformTransaction`, `AgentRentalAgreement`). Basically, most structured data where relationships and consistency are key. Individual agents may also utilize dedicated PostgreSQL tables or schemas for their specific structured data storage needs (e.g., `email_wizard_emails` for the Email Wizard, `whatsapp_pulse_playbooks` for WhatsApp Pulse), complementing the main platform PostgreSQL database used for shared entities.
*   **NoSQL Options:**
    *   **MongoDB (Document Store):**
        *   **Justification:** Flexible schema, good for storing denormalized data or rapidly evolving structures.
        *   **Data Types:** Potentially `ChatMessage` content (if highly variable or large), `CanvasBlock.content` (especially for complex, nested JSON structures within blocks), agent run outputs (`AgentConfiguration.last_run_output` if large and unstructured), temporary user session data.
    *   **Elasticsearch (Search Engine & Document Store):**
        *   **Justification:** Powerful full-text search capabilities, analytics, and logging.
        *   **Data Types:** Indexing content from `CanvasPage`s, `ChatMessage`s, `Prompt`s for the Command Palette search. Storing application logs for analysis and monitoring. Potentially for advanced analytics on agent outputs or user activity.
    *   **Redis (In-Memory Key-Value Store):**
        *   **Justification:** Extremely fast for caching (e.g., external API responses, LLM prompts/completions), session management, rate limiting, real-time presence information, and as a message broker for many internal agent task queues (e.g., using **RQ (Redis Queue)** or **Redis Streams** as indicated in agent blueprints).
        *   **Data Types:** Session tokens, cached API responses from external services, real-time presence information (Chat/Canvas), queue for notifications and agent tasks.
    *   **Vector Database: Pinecone**
        *   **Justification:** Chosen as the primary Vector Database for agents requiring Retrieval Augmented Generation (RAG) capabilities, embedding storage, and semantic search, as specified for agents like `Creator Persona Guardian` and `Slack Brief Butler`. Pinecone is managed and scalable, fitting well with the microservice architecture.
        *   **Data Types:** Vector embeddings of documents, chat histories, brand guidelines, content pieces for semantic search and RAG by various agents.

**1.4. Message Broker Strategy:**

A hybrid approach to messaging and task queuing is anticipated, leveraging the strengths of different technologies based on specific needs observed in agent designs:
*   **Redis (with RQ or Redis Streams):** For many internal agent task queues and inter-service communication. Its widespread mention in agent blueprints (e.g., for `Outreach Automaton`, `Email Wizard`) for background task processing makes it a primary choice for typical asynchronous operations within the platform due to its simplicity and performance.
*   **Apache Kafka:** Reserved for scenarios requiring very high-throughput, persistent, ordered event streams, and where its log-streaming capabilities are beneficial. An example is handling `shop-orders` events for the `Shopify Sales Sentinel` agent, which needs to process a potentially large and critical stream of events reliably.
*   **Justification:** This approach allows for the operational simplicity of Redis-based queues for common tasks while retaining the power of Kafka for specialized, high-volume data streams. This aligns with the diverse needs of the agent ecosystem.

**1.5. API Gateway:**

*   **Suggestion: Kong API Gateway (or a cloud provider's managed gateway like AWS API Gateway, Google Cloud API Gateway)**
    *   **Justification (Kong):** Open-source, feature-rich (routing, authentication, rate limiting, transformations, plugins), Kubernetes-native. Can be deployed on-prem or in any cloud.
    *   **Justification (Cloud Managed):** Reduces operational overhead, integrates well with other cloud services (IAM, logging).
    *   The API Gateway will handle routing requests to the appropriate microservices, initial authentication/authorization, rate limiting, and request/response transformations.

**1.6. Deployment & Infrastructure:**

*   **Containerization: Docker & Kubernetes (K8s)**
    *   **Justification:** Standard for deploying and managing microservices. Docker for packaging applications, Kubernetes for orchestration, scaling, and resilience.
*   **Cloud Provider: Flexible (AWS, GCP, or Azure are all suitable)**
    *   The choice can be driven by existing team expertise, specific managed service offerings (e.g., managed K8s, databases, AI services), or cost considerations. The architecture should aim to be cloud-agnostic where possible, relying on Kubernetes to abstract underlying infrastructure.
    *   Initial preference might lean towards a provider with strong managed Kubernetes (EKS, GKE, AKS) and serverless function offerings for certain tasks.

**1.7. Real-time Communication:**

*   **Confirmation: WebSockets**
    *   For `Chat Service` and real-time collaboration features in `Canvas Service` (e.g., multi-user block editing, cursor presence). Node.js backend is well-suited for this.

**1.8. Observability & Operational Tooling Strategy:**

A comprehensive observability stack is critical for monitoring, debugging, and ensuring the reliability of the microservices and agent operations. The following tools, consistently mentioned in agent blueprints, will form the core of our internal observability strategy:
*   **OpenTelemetry:** For standardized generation of traces, metrics, and logs across all services.
*   **Prometheus:** For metrics collection and alerting.
*   **Grafana:** For visualization of metrics and logs (often paired with Prometheus and Loki).
*   **Loki:** For log aggregation and querying.
*   **Jaeger (or similar like Zipkin):** For distributed tracing.

This internal stack is distinct from any external SaaS monitoring services that might be used for broader application performance management but focuses on the detailed operational health of IONFLUX services.

Furthermore, the agent blueprints indicate the use of modern CI/CD and deployment practices. The platform's operational environment will be designed to support:
*   **CI/CD:** Tools like **GitHub Actions** for automated building, testing, and deployment.
*   **Containerization:** **Docker (with Buildx for multi-arch builds)** for packaging applications.
*   **Deployment Platforms:** Leveraging platforms like **Fly.io** or **Railway.app** for simplified deployment and management of containerized applications, alongside Kubernetes for more complex orchestration if needed.

## 2. End-to-End (E2E) Demo Flow & Prototyping Strategy

The detailed agent specifications in `core_agent_blueprints.md` provide rich context for the expected outputs and interactions at each stage of this demo flow, making the demonstration of agent value more concrete.

**2.1. Core User Journey for Demo:**

This journey aims to demonstrate the "Notion+Slack" hybrid, key agent interactions, and core platform value.

1.  **Onboarding & Setup:**
    *   User signs up, creates a Workspace ("My Marketing Agency").
    *   User connects their Shopify store (Brand: "My Test Store") – OAuth flow.
    *   User connects their TikTok account (Creator: "My Test Creator") – OAuth flow.
2.  **Canvas & Chat Interaction (Campaign Planning):**
    *   User creates a new `CanvasPage` titled "Q4 Holiday Campaign Plan."
    *   User adds a Text block: "Goal: Drive 20% more sales for Product X."
    *   User uses the `ChatDock` to discuss ideas with a team member (mocked or another user).
    *   User types `/run_agent Slack Brief Butler summarize_thread` in the chat. The agent posts a structured brief of the discussion. User copies this brief into a Text block on the Canvas.
3.  **Shopify Agent Integration:**
    *   User drags `Revenue Tracker Lite` agent from the "Agent Shelf" onto the Canvas. Configures it for "My Test Store" to show "Last 7 Days" data. The block populates with sales figures.
    *   User configures `Shopify Sales Sentinel` for "My Test Store" to alert on orders > $100. (Simulate a webhook event for a $150 order). A notification appears, and a message is posted to a designated chat channel.
4.  **TikTok Agent Integration:**
    *   User drags `TikTok Stylist` onto the Canvas. Configures it with keywords like "holiday gift ideas" and "fashion."
    *   User runs `TikTok Stylist`. The agent's snippet block on Canvas updates with trending sounds and hashtags.
    *   User drags `UGC Matchmaker` onto the Canvas. Configures it for "fashion" niche. Runs it. The block populates with a list of (mocked/example) TikTok creator handles.
5.  **Review & Action:**
    *   User reviews the populated Canvas page, which now contains the campaign brief, Shopify sales data, TikTok trends, and potential UGC creators.
    *   User uses the Chat Dock to assign tasks based on the gathered info.

**2.2. Key Screens/Interfaces to Mock/Build for Demo:**

*   **Login/Signup Screens**
*   **Workspace Dashboard/Switcher**
*   **Sidebar Navigation** (as per `ui_ux_concepts.md`)
*   **Canvas Page View:**
    *   Toolbar for adding blocks.
    *   Rendering of Text blocks, Agent Snippet blocks.
    *   Basic block manipulation (move, resize - simplified).
*   **Chat Dock:**
    *   Channel list, message view, message input.
    *   Display of user and agent messages (including formatted agent output).
    *   `/command` input with basic autocomplete.
*   **Agent Configuration Modal:**
    *   YAML editor view.
    *   Ability to name/describe agent instance and save.
*   **Agent Marketplace (Simplified View):** Showing cards for the demo agents.
*   **Brand/Creator Asset Connection Modals:** For Shopify & TikTok OAuth placeholders.
*   **Notifications Panel/Indicator.**

**2.3. Prototyping Tools/Approach (n8n + YAML focus):**

*   **n8n + YAML for Backend Logic/Agent Prototyping:**
    *   **n8n Workflows:** Use n8n (a workflow automation tool) to visually model the logic of several agents or inter-service communication for the demo. Each n8n workflow can represent a simplified microservice or an agent's core task.
        *   Example: An n8n workflow for `TikTok Stylist` could have nodes for:
            1.  HTTP Request (mocking call to `TikTok Integration Service` - returns canned JSON).
            2.  Function Node (JavaScript/Python to process data).
            3.  HTTP Request (mocking call to `LLM Orchestration Service` - returns canned text).
            4.  HTTP Request (to send results back to a mocked `Agent Service` endpoint).
    *   **YAML for Agent Configuration:** The `AgentConfiguration.yaml_config` will be real and stored (perhaps in a simple DB or even flat files for the demo's backend). The n8n workflows (acting as agents) would be triggered with references to these YAML configs, and the workflow logic would parse relevant parameters from the YAML to guide its execution (even if parts of that execution are mocked).
    *   This approach allows rapid iteration on agent logic (by modifying n8n workflows and YAML) without writing full microservice code for all agents initially.
    *   This n8n-based prototyping approach remains valid even with the detailed agent tech stacks specified in `core_agent_blueprints.md`. The n8n workflows will simulate the *external behavior and API interactions* of agents that would, in production, be built with technologies like Python/FastAPI and Pinecone, rather than n8n itself running that specific internal stack.
*   **Microservices Prototyping Strategy:**
    *   **Heavily Mocked/Simplified (using n8n/scripts):**
        *   `TikTok Integration Service`: Returns canned TikTok API responses.
        *   `LLM Orchestration Service`: Returns pre-defined text outputs for specific prompts.
        *   Most of the `Agent Service`'s complex orchestration logic can be represented by n8n workflows that are triggered via simple API calls.
        *   `Notification Service`: May just log to console or send a simple webhook to a mock UI.
    *   **Minimal Robust Implementation (Lean Service Shells):**
        *   `User Service`: Basic user registration, login (JWT), and retrieval.
        *   `Workspace Service`: CRUD for workspaces.
        *   `Agent Service (Core)`: CRUD for `AgentConfiguration` and `AgentDefinition` (storing YAML, names, etc.). Needs to trigger n8n workflows (or other scripts) representing agent execution.
        *   `Shopify Integration Service`: Needs to handle the OAuth callback and store tokens securely. API calls for the demo can return canned data for `Revenue Tracker Lite` but should process a *simulated* webhook for `Sales Sentinel` to show the E2E flow.
        *   `Canvas Service`: Basic CRUD for `CanvasPage` and `CanvasBlock` (storing type, content - especially `agent_config_id` for snippet blocks).
        *   `Chat Service`: Basic CRUD for channels and messages. Needs to parse `/commands` and trigger `Agent Service` (or its n8n workflow endpoint). Needs WebSocket connection for sending/receiving messages.
*   **Frontend:** Build the key UI screens using React/Next.js, focusing on the interaction flows. API calls from the frontend would go to the minimal robust service shells or n8n webhook triggers.

**2.4. Focus of the Demo:**

*   **Validate the core User Experience:** Demonstrate the hybrid "Notion+Slack" interaction model, focusing on the Canvas and Chat Dock as primary work hubs.
*   **Showcase Agent Capabilities & Interaction:** Illustrate how users discover, configure (via YAML), and run agents, and how agents deliver value within the Canvas and Chat.
*   **Demonstrate Key Integrations (Conceptually & Partially):** Show the Shopify connection flow and a simulated Shopify event. Show the TikTok agent flow with mocked data.
*   **Illustrate Data Flow:** Show how information from one part of the system (e.g., chat discussion) can be processed by an agent and appear elsewhere (e.g., Canvas).
*   **Gather Early Feedback:** On the core concepts, usability, and perceived value of the integrated agent experience.

This strategy prioritizes demonstrating the user-facing value and core interaction patterns while deferring full implementation of all backend complexities, using n8n and mocks for rapid prototyping of agent logic.
```
