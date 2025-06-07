# IONFLUX Application: The Workflow OS

> *“IONFLUX: onde cada insight se transfigura em fluxo orquestrado, cada clique vira exército de micro‑agentes, e a fricção morre de tédio.”*

## 0. EXECUTIVE SYNAPSE (The Nerve Center)

IONFLUX serves as the central nervous system for automation, orchestration, and intelligent workflow management within the expansive IONVERSE ecosystem. It is conceptualized as a **Workflow OS (Operating System)** that seamlessly converges AI Operations (AIOps), deep multi-platform integrations (from Shopify to TikTok, from Discord to on-chain events), and an intuitive, Lego-style visual interface for building complex, event-driven processes. This is where human intent meets automated execution, amplified by AI.

The ultimate goal of IONFLUX is to empower every creator, entrepreneur, and user within the IONVERSE to construct, deploy, monitor, and *monetize* (or save costs via) sophisticated automated workflows. This is achieved without necessarily needing to write a single line of code, by using pre-built or community-contributed **Agents** and **Transforms**. Simultaneously, IONFLUX provides the depth, extensibility (custom agents, WASM transforms), and power for developers to dive into programmatic capabilities, creating and sharing new automation building blocks. It's designed to make operational friction obsolete.

## 1. ROLE — Propósito & North‑Star (Purpose & North-Star Metrics)

### 1.1 Problema Cósmico (The Cosmic Problem IONFLUX Solves)
Creators, solopreneurs, and digital businesses constantly grapple with the "platform spaghetti" – the challenge of synchronizing disparate tools and platforms: TikTok content pipelines, Shopify inventory updates, Discord community engagement, email marketing sequences, blockchain interactions (token gating, NFT minting alerts), analytics dashboards, customer support ticketing, and countless others. This operational friction consumes an obscene amount of valuable time, stifles creativity by forcing context switching, leads to lost opportunities due to delays, and generally makes scaling a nightmare. **IONFLUX is the antidote to this digital entropy.** It aims to be the unifying fabric that weaves these islands into a cohesive, automated continent of operations.

### 1.2 VALUE LOOP & NORTH-STAR METRICS
IONFLUX operates on a core iterative loop: **Think → Build (Visually) → Deploy → Observe → Iterate (Optimize).** The success and impact of this loop are measured by four North-Star metrics, reflecting the Pooldad principle of "Provocar Impacto Real":

*   **(a) Flows per Daily Active Builder (F/DAB):** Measures user engagement and the platform's utility in solving real-world automation needs. High F/DAB indicates users are successfully translating their operational needs into functional IONFLUX flows.
*   **(b) Mean-Time-to-Automation (MTTA):** Tracks the average time it takes for a user (from novice to expert) to successfully build and deploy a functional automated workflow that achieves its intended purpose. This is a key indicator of ease of use, the quality of the visual builder, and the utility of available Agents/Transforms.
*   **(c) Agent GMV (Gross Value Orchestrated by Agents):** Quantifies the economic impact of automations. This is calculated by the value generated (e.g., sales from automated marketing flows, revenue from monetized agent services) or costs saved (e.g., hours of manual work automated, errors prevented) by agent-driven workflows over time.
*   **(d) C-ION Burn Rate (for executions):** Reflects the consumption of **C-ION** (Compute-ION credits, obtained by burning ION tokens) for executing flows, agent tasks (especially AI-intensive ones), and premium transforms. This indicates platform activity and directly contributes to the ION token's utility and value accrual mechanisms.

The ultimate, overarching metric for IONFLUX, embodying its core Pooldad spirit, is: **“Minutes of human life returned to the user per day, to be reinvested in creativity, strategy, or simply living.”**

## 2. WHAT IT DOES — Descrição Macro (Macro Description)

IONFLUX provides a comprehensive, integrated suite of capabilities to function as a true Workflow OS:

1.  **Drag + Drop Visual Canvas for Flow Creation:**
    *   Utilizes an intuitive visual interface (likely based on libraries like React Flow or similar, highly customized) where users can drag, drop, and connect **Nodes**.
    *   Nodes represent various operational units:
        *   **Triggers:** (e.g., NATS event, HTTP webhook, CRON schedule via Chronos Agent, manual start).
        *   **Agents:** Instances of specialized IONFLUX Agents (see `AGENTS.md`) performing complex tasks (e.g., "Summarize text with Muse Agent," "Post video to TikTok with TikTok Stylist").
        *   **Transforms:** Granular data manipulation or interaction units (e.g., "FetchFromIONPOD," "StoreToIONPOD," "FormatJSON," "SendEmail").
        *   **Logic Gates:** Conditional branching (if/else), loops, parallel execution, error handling blocks.
    *   These visual flows are automatically translated into an underlying Abstract Syntax Tree (AST) represented in a human-readable **YAML DSL (FluxGraph Definition Language)**, ensuring version control, programmatic manipulation, and transparent execution logic.

2.  **Secure & Isolated Runtime Sandbox for Agent/Transform Execution:**
    *   Each Node (Agent task or Transform execution) within a flow is executed in an isolated **Deno worker environment** (leveraging Deno's permission model and TypeScript/JavaScript/WASM support).
    *   This sandboxing provides robust security (preventing cross-flow or cross-agent interference), resource management (CPU, memory limits per step), and allows for the execution of diverse, potentially untrusted (community-contributed) code modules with fine-grained permissions managed by IONWALL.

3.  **AI-Enhanced Workflow Design & Optimization (The "Jules AI" Co-pilot):**
    *   Leverages powerful LLMs (e.g., GPT-4o, Claude 3 Opus, or fine-tuned local models) integrated as a "Jules AI" co-pilot directly within the flow builder UI.
    *   Capabilities include:
        *   **Natural Language to Flow:** User describes a desired automation in plain language; Jules AI suggests a starting flow structure with relevant Agents and Transforms.
        *   **Prompt Optimization:** Rewriting and optimizing prompts used by LLM-based agents (like Muse) within a flow for better results and lower C-ION cost.
        *   **Token Usage Estimation & Optimization:** For API calls or LLM steps, estimates C-ION cost and suggests more efficient alternatives if available.
        *   **Error Handling & Logic Suggestion:** Recommends logical branch points, error handling routines (e.g., retry mechanisms, fallback actions), or alternative agents based on the user's intent and the flow's context.
        *   **Documentation Generation:** Auto-generates descriptions or annotations for complex flows or individual nodes.

4.  **Marketplace for Agents & Flow Blueprints:**
    *   A central hub within IONFLUX (and discoverable via the main IONVERSE app) where users and developers can:
        *   Publish their own `AgentDefinition` blueprints (see `specs/agents/blueprint_template.md`) for others to use.
        *   Share fully configured `AgentConfiguration` instances (with appropriate controls for sharing sensitive data like API key *references* which are then resolved by the end-user via their IONWALLET/IONWALL).
        *   Publish `FlowBlueprint` YAML files (successful, reusable workflow templates).
    *   Users can subscribe to, "fork," or instantiate these shared components, fostering a community-driven ecosystem of reusable automation building blocks. Monetization for popular shared agents/flows is envisioned via the ION token.

5.  **Live Observability & Operations Dashboard:**
    *   Provides a real-time, user-friendly dashboard for monitoring active flows and agent executions.
    *   Displays key metrics: execution status per step, execution times, error rates, C-ION consumption per run, data CIDs processed.
    *   Facilitates debugging with detailed logs (linked from MinIO/Loki), input/output previews for each node, and the ability to visually trace data flow.
    *   Allows for pausing, resuming, or cancelling running flows (with appropriate permissions via IONWALL).

## 3. IMPLEMENTATION — Arquitetura de Camadas (Layered Architecture)

IONFLUX is designed with a modular, scalable, and resilient layered architecture. This ensures that components can be independently developed, deployed, and scaled.

```mermaid
graph TD
    A[Edge UX Layer: React Native/Next.js - Flow Canvas] --> B{API Gateway (Node.js/Envoy)};
    B --> C[Hasura GraphQL API];
    C --> D[PostgreSQL (Flows, Runs, Agents, Billing)];
    B --> E[Flow Orchestrator (Temporal.io / Deno-based)];
    E --> F[NATS JetStream (Events, Triggers, Tasks)];
    F --> G[Runtime Sandbox Manager];
    G --> H[Deno Isolates / k8s Jobs (Agent/Transform Execution)];
    H --> I[IONWALL (Permissions, Resource Control)];
    H --> J[External Services / Other ION Apps];
    H --> K[Transforms (WASM Modules)];
    E --> D;
    G --> D;
    L[Persistence Grid: PostgreSQL, MinIO, Event Store] --> D;
    L --> M[MinIO/S3 (Artifacts, Logs)];
    L --> N[Event Store (NATS Mirror/CDC)];
    O[Observability Mesh: Prometheus, Grafana, Loki, OpenTelemetry] --> A;
    O --> B;
    O --> E;
    O --> G;
    O --> H;
    I --> O;
```

*   **Scaling Strategy:** Horizontally scalable stateless services (API Gateway, Flow Orchestrator workers, Runtime Sandbox workers) using Kubernetes HPA. Stateful sets for PostgreSQL, NATS, MinIO with read replicas and partitioning where appropriate. Deno isolates provide per-task scaling.

### 3.1 Edge UX Layer (Frontend)
*   **Technology:**
    *   **Mobile:** React Native + Expo EAS for a consistent experience on iOS and Android, allowing users to monitor flows and even perform simple edits or manual triggers on the go.
    *   **Web:** Next.js (TypeScript) for the primary, feature-rich web application, including the main visual flow builder. Shared component library with the mobile app using React.
*   **Key Component - Visual Flow Builder:**
    *   `React Flow` (or a similar library like `@projectstorm/react-diagrams` if more advanced features are needed out-of-the-box) provides the foundation for the drag-and-drop canvas.
    *   Custom nodes for Triggers, Agents, Transforms, Logic Gates.
    *   Properties panel for configuring selected nodes (e.g., setting NATS subject for a trigger, providing parameters to an Agent).
    *   Real-time validation of connections and configurations.
    *   "Jules AI" co-pilot integration as a sidebar or contextual helper.

### 3.2 API Gateway & GraphQL (Flow Control & Data Access)
*   **API Gateway:** A robust API Gateway (e.g., built with Node.js + Fastify, or using a managed service like Kong/Envoy if K8s native) handles incoming HTTP requests for:
    *   Manual flow triggering.
    *   Webhook triggers.
    *   Management APIs (CRUD for flows, agents - though primarily done via UI/GraphQL).
    *   Authentication/authorization integration with IONWALL before routing to backend services.
*   **GraphQL Layer (Hasura):**
    *   Hasura provides a unified GraphQL API over the PostgreSQL database (`flows`, `runs`, `agents`, `billing`, `event_mirror` tables).
    *   Simplifies frontend data fetching and mutations for flow definitions, execution history, agent registry, etc.
    *   Permissions managed by Hasura, integrating with IONWALL JWTs and roles.

### 3.3 Flow Orchestrator (The Conductor)
*   **Core Engine:**
    *   **Temporal.io (preferred for robustness) or a custom Deno-based orchestration engine using NATS JetStream for task queuing and state management.**
    *   Interprets the YAML FluxGraph DSL.
    *   Manages the lifecycle of a flow execution (a "Run").
    *   Handles step dependencies, conditional logic, loops, parallel execution paths.
    *   Schedules tasks for execution in the Runtime Sandbox via NATS messages to the Runtime Sandbox Manager.
    *   Listens for completion/failure events from tasks.
    *   Manages state for long-running flows (potentially hours or days for complex orchestrations with human-in-the-loop steps via IONWALL_ActionApproval_Transform).
*   **Event Bus:**
    *   **NATS JetStream:** Used for all internal asynchronous communication:
        *   Receiving external trigger events (e.g., from other ION apps).
        *   Publishing tasks to be picked up by Runtime Sandbox workers.
        *   Receiving task completion/failure events.
        *   Emitting events about flow status changes for the Observability Mesh or external subscribers.

### 3.4 Runtime Sandbox (Secure Execution Environment)
*   **Runtime Sandbox Manager:** A service that subscribes to NATS task queues from the Flow Orchestrator.
*   **Execution Units:**
    *   **Deno Isolates:** For executing TypeScript/JavaScript based Agents and Transforms. Deno's permission model (`--allow-net`, `--allow-read`, etc.) is crucial for security, configured based on the Agent/Transform manifest and IONWALL policies.
    *   **Kubernetes Jobs:** For more resource-intensive tasks or those requiring specific environments not easily managed by Deno, a K8s Job can be dynamically created.
    *   **WASM Runtimes (e.g., WasmEdge, Wasmer):** For executing compiled WebAssembly modules (Agents/Transforms written in Rust, Go, etc.), providing near-native performance and strong sandboxing. Deno itself has good WASM support.
*   **Resource Management:** The Sandbox Manager, in conjunction with Kubernetes (if used), ensures that each execution unit adheres to CPU, memory, and network I/O limits defined in its manifest or by IONWALL policies.
*   **IONWALL Integration:** Each execution unit must be able to make requests to IONWALL to check fine-grained permissions for its specific operation (e.g., an Agent attempting to call an external API via Symbiosis Plugin Agent would have its call mediated by Symbiosis, which in turn consults IONWALL).

### 3.5 Persistence Grid (Storage Layer)
*   **Primary Relational Database (PostgreSQL 16):**
    *   `flows`: Stores flow definitions (ID, owner_did, name, description, current_version_id, YAML DSL content, created_at, updated_at).
    *   `flow_versions`: Tracks versions of each flow (version_id, flow_id, yaml_dsl_cid for immutability, version_message, created_at).
    *   `runs`: Logs each execution of a flow (run_id, flow_version_id, trigger_event_id, status (running, success, failure, cancelled), start_time, end_time, input_params_cid, output_results_cid, c_ion_cost).
    *   `run_steps`: Detailed logs for each step within a run (step_run_id, run_id, node_id_in_flow, agent_transform_id, status, start_time, end_time, inputs_cid, outputs_cid, error_message, logs_artifact_cid).
    *   `agents_registry`: Catalog of available Agent Definitions (agent_def_id, name, description, version, manifest_cid, publisher_did, popularity_score).
    *   `agent_instances`: User-specific configurations of agents (instance_id, agent_def_id, owner_did, configuration_cid, display_name).
    *   `billing_events`: Records C-ION consumption events (event_id, owner_did, run_id, step_run_id, c_ion_debited, service_type (llm, storage, etc.), timestamp).
    *   `event_mirror_for_audit`: Optionally, critical NATS events can be mirrored here for long-term audit if JetStream retention is shorter.
*   **Object Storage (MinIO / S3-compatible via IONPOD abstraction):**
    *   Stores large artifacts associated with flow runs: detailed step logs (if too large for Postgres), input/output data objects for steps (referenced by CID in `run_steps`), versioned YAML DSLs (referenced by CID in `flow_versions`). Managed via IONPOD interface for user data sovereignty.
*   **Event Store (NATS JetStream):**
    *   While primarily an event bus, JetStream's persistence capabilities serve as a short-to-medium term event store for triggers, task queues, and immediate operational history.

### 3.6 Observability Mesh (Monitoring & Logging)
*   **Metrics (Prometheus & Grafana):**
    *   Flow Orchestrator, Runtime Sandbox Manager, and individual Deno isolates/K8s Jobs export metrics (e.g., execution rates, durations, error counts, resource usage) to Prometheus.
    *   Grafana dashboards provide visualization of IONFLUX system health, flow performance, and resource consumption.
*   **Logging (Loki & Grafana):**
    *   Structured logs (JSON where possible) from all components are shipped to Loki.
    *   Grafana allows querying and visualization of logs, correlated with metrics and traces.
*   **Distributed Tracing (OpenTelemetry & Tempo/Jaeger):**
    *   OpenTelemetry SDKs are used within services and potentially within high-level Agents/Transforms to propagate trace context.
    *   Traces are sent to Tempo or Jaeger for visualizing the end-to-end lifecycle of a flow execution across multiple services and steps.
*   **Alerting (Alertmanager):**
    *   Prometheus Alertmanager triggers alerts based on predefined rules (e.g., high failure rates, long queue depths, critical errors in logs).
    *   Alerts can be routed to IONWALL (for automated system responses or user notifications), Hybrid Layer (for human intervention), or directly to operations teams.

## 4. HOW‑TO‑IMPLEMENT (Kickstart & Hands‑On for Developers)

This provides a conceptual guide for developers wanting to build with or contribute to IONFLUX.

1.  **Understand the Vision & Architecture:**
    *   **Action:** Thoroughly read the IONVERSE and IONFLUX root `README.md` files. Study the "Layered Architecture" (Section 3) and "Data Store" (Section 8) of this document.
    *   **Goal:** Grasp the core concepts, the role of IONFLUX as a Workflow OS, and how it interacts with other ION Super-Hub components like IONWALL and IONPOD. "Não há feature sem mito."

2.  **Setup Local IONFLUX Environment:**
    *   **Action:** Clone the `ionverse_superhub` monorepo. Follow instructions in a root `DEVELOPMENT_SETUP.md` (or IONFLUX specific setup guide) to install PNPM, Deno, Docker, NATS CLI, etc. Use `docker-compose up` to launch local instances of PostgreSQL, NATS JetStream, MinIO, Hasura. Run database migrations for IONFLUX schema.
    *   **Goal:** Have a functional local backend for IONFLUX.

3.  **Explore the IONFLUX UI (Flow Builder):**
    *   **Action:** Run the IONFLUX Next.js frontend (`pnpm --filter @ionflux/webapp dev`). Connect to your local backend.
    *   Experiment with the visual flow builder: drag and drop available trigger nodes, basic logic (e.g., "Log Message" transform), and any pre-built simple agents. Try to construct and save a simple flow.
    *   **Goal:** Understand the user experience of flow creation and the visual representation of the YAML DSL.

4.  **Create a Simple "Hello World" Flow (YAML & UI):**
    *   **Action:**
        1.  Using the UI, create a flow with a "Manual Trigger," a "Log Message" transform (configured to log "Hello IONFLUX"), and connect them. Save and run it. Check logs.
        2.  Inspect the generated YAML DSL for this flow (e.g., via UI or by querying the `flows` table in PostgreSQL).
        3.  Try to manually write a similar YAML DSL for a slightly different message and (if an API exists) upload/import it.
    *   **Goal:** Understand the relationship between the visual representation and the underlying YAML DSL.

5.  **Develop a Custom Transform (WASM/TypeScript):**
    *   **Action:** Follow a tutorial (to be created in `ionflux/docs/guides/creating_transforms.md`) for building a simple data manipulation transform (e.g., "String Reverse" or "JSON Value Extractor") in TypeScript for Deno, or Rust compiled to WASM.
    *   Define its input/output schema (JSON Schema). Package it (e.g., as a Wasm module with a manifest).
    *   "Register" this transform with your local IONFLUX (mechanism TBD - might involve updating a local agent registry or a manifest list).
    *   **Goal:** Learn the process of creating reusable, atomic units of work.

6.  **Develop a Basic Custom Agent (Definition & Logic):**
    *   **Action:** Follow a tutorial (to be created in `ionflux/docs/guides/creating_agents.md`) to define a simple agent (e.g., "Weather Agent" that takes a city name and returns current weather using a public API via an HTTP transform).
    *   Create its `AgentDefinition` blueprint (YAML/JSON, based on `specs/agents/blueprint_template.md`).
    *   Implement its core logic as a small FluxGraph using existing transforms (like `HTTP_Request_Transform`, `JSONParser_Transform`).
    *   Register this agent definition.
    *   **Goal:** Understand how to encapsulate more complex, multi-step logic as a reusable Agent.

7.  **Orchestrate Agents in a Flow:**
    *   **Action:** In the IONFLUX UI, create a new flow that uses your "Weather Agent" (or another pre-existing agent like `CommLinkAgent`). For instance, a flow triggered by a schedule (via Chronos) that gets weather for "Lisbon" and then sends it via `CommLinkAgent` to a NATS topic.
    *   **Goal:** Experience agent orchestration and inter-agent communication patterns (via NATS).

8.  **Inspect Execution & Debug:**
    *   **Action:** Run your new multi-step flow. Use the IONFLUX Observability Dashboard to inspect the `run` log, view inputs/outputs of each step (Agent/Transform), check C-ION costs, and identify any errors.
    *   Introduce an error deliberately (e.g., provide invalid input to your Weather Agent) and see how it's handled and reported.
    *   **Goal:** Learn how to monitor, debug, and troubleshoot IONFLUX flows.

## 5. TECH STACK & TRADE‑OFFS (Rationale)

The IONFLUX technology stack is chosen to balance performance, security, developer experience, and alignment with the broader IONVERSE ecosystem.

*   **Frontend (Next.js + React + React Flow):**
    *   **Rationale:** Next.js for a modern, performant web application with SSR/SSG capabilities. React for its vast ecosystem and component model. React Flow (or similar) for a proven library for node-based UIs. This stack is popular, ensuring a good developer pool.
    *   **Trade-offs:** Can be complex for state management in highly interactive builders. Performance of very large graphs in React Flow needs careful optimization.
*   **Runtime Sandbox (Deno / Deno Isolates):**
    *   **Rationale:** Secure by default (no file, network, or env access unless explicitly granted). Native TypeScript and WASM support. Modern JavaScript features. Simpler dependency management than Node.js for individual worker scripts. Good for running untrusted or community-provided code.
    *   **Trade-offs:** Smaller ecosystem than Node.js for certain specific libraries, though growing rapidly. Cold start times for isolates can be a concern for very low-latency tasks if not managed with pooling.
*   **Workflow DSL (YAML with JSON Schema):**
    *   **Rationale:** YAML is human-readable and widely adopted for configuration. JSON Schema provides validation for inputs/outputs of nodes and overall flow structure. Allows flows to be version controlled easily.
    *   **Trade-offs:** Can become verbose for very complex flows. Visual builder must perfectly map to/from this YAML to avoid drift. Debugging YAML by hand can be error-prone for novices.
*   **Primary Database (PostgreSQL 16):**
    *   **Rationale:** Extremely robust, feature-rich (JSONB, transactions, extensibility), and scalable open-source SQL database. Reliable for storing critical state and metadata.
    *   **Trade-offs:** Requires careful schema design and potentially DBA expertise for very large-scale deployments. Can be more rigid than NoSQL options for rapidly evolving schemas, but Hasura helps mitigate this at the API layer.
*   **Flow Orchestration (Temporal.io or NATS JetStream + Custom Deno Logic):**
    *   **Temporal.io (Option A):** Highly robust, scalable, and fault-tolerant for long-running workflows. Provides strong guarantees for state management, retries, and error handling.
        *   **Trade-offs (Temporal):** Adds another significant component to the stack with its own operational complexity. Learning curve for developers.
    *   **NATS JetStream + Custom Deno Logic (Option B):** Leverages existing NATS infrastructure. Simpler to start with if Temporal is too heavy. Deno for writing orchestration workers.
        *   **Trade-offs (NATS/Custom):** Requires building more state management, retry logic, and fault tolerance manually, which is complex to get right. Potential for "state spaghetti" if not carefully designed.
*   **AI Co-pilot (GPT-4o / Claude 3 / Fine-tuned Models):**
    *   **Rationale:** State-of-the-art LLMs for providing intelligent assistance in flow design, prompt optimization, and documentation. Ability to use multiple models via provider APIs or local instances allows flexibility.
    *   **Trade-offs:** Cost of API calls to proprietary models. Latency of LLM responses. Need for careful prompt engineering and context management to get useful suggestions. Data privacy concerns if sending flow structure/content to external LLMs (mitigated by IONWALL policies or using local/on-prem models).

## 6. FILES & PATHS (Key Locations in Monorepo)

IONFLUX, as part of the `ionverse_superhub` monorepo, follows a structured layout:

*   **`ionverse/apps/ionflux_webapp/`**: Source code for the Next.js frontend (Flow Builder UI, Dashboards).
    *   `pages/` or `app/`: Next.js routing structure.
    *   `components/flow_builder/`: React components specific to the visual canvas, nodes, edges.
    *   `lib/api_clients/`: Client-side code for interacting with Hasura GraphQL and IONFLUX backend APIs.
*   **`ionverse/services/ionflux_orchestrator/`**: Core backend logic for flow orchestration (e.g., Temporal workflows/activities, or Deno/NATS based orchestrator code).
*   **`ionverse/services/ionflux_runtime_manager/`**: Service responsible for managing Deno isolates or K8s jobs for actual agent/transform execution.
*   **`ionverse/packages/fluxgraph_yaml_parser/`**: Shared library for parsing, validating, and manipulating the FluxGraph YAML DSL.
*   **`ionverse/packages/ionflux_agent_sdk/`**: SDK for developers creating custom Agents or Transforms (TypeScript/Rust). Defines interfaces, helper functions, communication protocols with the runtime.
*   **`ionverse/packages/types_schemas_ionflux/`**: TypeScript types and Zod/JSON schemas for IONFLUX specific data structures (Flows, Runs, Agent Definitions, Event payloads).
*   **`ionverse/agents_catalog/`**: (Conceptual or actual directory) Contains definitions (`AgentDefinition` blueprints) for core and community-contributed agents.
    *   `core_agents/email_wizard/manifest.yaml`
    *   `community_agents/some_user_agent/manifest.yaml`
*   **`ionverse/transforms_catalog/`**: Similar to agents_catalog, but for reusable Transforms.
*   **`ionverse/services/hasura_ionflux/migrations/` & `metadata/`: For IONFLUX-specific Hasura schema.

## 7. WHERE‑TO‑PLACE‑FILES (Conventions)

*   **New Agent Logic:**
    *   **Definition:** An `AgentDefinition` YAML/JSON blueprint in `ionverse/agents_catalog/your_agent_name/`.
    *   **Core Logic (if custom code):** If the agent uses custom TypeScript/Deno logic not encapsulated in existing transforms, this code would live in a dedicated package, e.g., `ionverse/packages/custom_agent_logic/your_agent_name/`, and the agent manifest would reference its entry point. If the agent is purely an orchestration of existing transforms (a "Flow Agent"), its logic is defined directly in its FluxGraph DSL within the manifest.
*   **New Transform Logic:**
    *   **Definition:** A Transform Specification Markdown in `specs/transforms/`.
    *   **Code (WASM/TypeScript):** In a dedicated package, e.g., `ionverse/packages/custom_transforms/your_transform_name/`. Its manifest (part of its package) would specify how the runtime should execute it.
*   **GraphQL Queries/Mutations (for UI):** Co-located with the React components that use them in `ionflux_webapp`, or in a shared `graphql/` directory within the webapp.
*   **Kubernetes Manifests (if any, for self-hosting):** `ionverse/infra/k8s/ionflux/`. Helm charts preferred.
*   **Documentation:**
    *   Core app docs: `ionverse/ionflux_app/README.md` (this file), `AGENTS.md`, `TRANSFORMS_OVERVIEW.md`.
    *   Developer guides: `ionverse/docs/guides/ionflux_*.md`.
    *   Specs: `specs/agents/`, `specs/transforms/`.

## 8. DATA STORE (Entities & Relationships - Prose for IONFLUX)

IONFLUX relies on PostgreSQL (via Hasura) for structured metadata and operational data, and MinIO/S3 (via IONPOD) for larger artifacts.

*   **`flows`**:
    *   **Purpose:** Stores definitions of user-created automation workflows.
    *   **Key Fields:** `flow_id` (PK), `owner_did` (FK to user identity via IONWALL), `name`, `description`, `current_version_id` (FK to `flow_versions`), `created_at`, `updated_at`, `tags_array`, `is_published_to_marketplace` (boolean).
    *   **Relationships:** One-to-many with `flow_versions`. One-to-many with `runs`.
    *   **Indexing:** On `owner_did`, `name`, `tags_array` (GIN index).
*   **`flow_versions`**:
    *   **Purpose:** Stores immutable versions of a flow's YAML DSL.
    *   **Key Fields:** `version_id` (PK), `flow_id` (FK), `yaml_dsl_content_cid` (IPFS CID of the actual YAML, ensuring immutability and linking to IONPOD storage), `version_message` (like a commit message), `created_at`, `creator_did`.
    *   **Relationships:** Many-to-one with `flows`.
*   **`runs` (Flow Executions):**
    *   **Purpose:** Logs each instance of a flow execution.
    *   **Key Fields:** `run_id` (PK, time-sortable like UUIDv7 or KSUID), `flow_version_id` (FK), `status` ('pending', 'running', 'success', 'failure', 'cancelled', 'awaiting_approval'), `trigger_event_details_cid` (CID of input that triggered it), `start_time`, `end_time`, `final_output_summary_cid` (CID of overall flow output), `total_c_ion_cost`.
    *   **Relationships:** Many-to-one with `flow_versions`. One-to-many with `run_steps`.
    *   **Partitioning:** By `start_time` (e.g., monthly partitions) for large volumes. Index on `status`, `flow_version_id`.
*   **`run_steps` (Individual Node Executions within a Run):**
    *   **Purpose:** Logs the execution details of each node (Agent or Transform) within a specific flow run.
    *   **Key Fields:** `step_run_id` (PK), `run_id` (FK), `node_id_in_flow_dsl` (references the ID from YAML), `agent_or_transform_name_version`, `status`, `start_time`, `end_time`, `inputs_preview_json` (summary), `outputs_preview_json` (summary), `logs_artifact_cid` (link to detailed logs in MinIO/IONPOD if extensive), `error_message_if_failed`, `c_ion_cost_for_step`.
    *   **Relationships:** Many-to-one with `runs`.
    *   **Partitioning:** By `start_time` (inherited from `runs` or separate). Index on `run_id`, `status`, `agent_or_transform_name_version`.
*   **`agents_registry` (Marketplace/Catalog of Agent Definitions):**
    *   **Purpose:** Discoverable catalog of available agents.
    *   **Key Fields:** `agent_def_id` (PK, e.g., "did:ionflux:agent:EmailWizard:v0.9.1"), `name`, `description`, `current_stable_version_tag`, `publisher_did`, `tags_array`, `average_rating`, `usage_count`, `ionwall_required_scopes_json_array`, `public_marketplace_listed` (boolean). Each version would link to an immutable `AgentDefinition` blueprint CID in IONPOD.
*   **`agent_instances` (User's configured instances of agents):**
    *   **Purpose:** Stores user-specific configurations for agents they use in their flows (e.g., API key references for an agent that calls an external service).
    *   **Key Fields:** `instance_id` (PK), `owner_did`, `agent_def_id` (FK), `display_name`, `configuration_values_encrypted_cid` (CID of an IONPOD object containing user's specific config, encrypted by IONWALL/user key).
*   **`events_for_triggers` (Persistent Event Store for Triggers):**
    *   **Purpose:** Stores events from NATS (or other sources) that can trigger flows, if persistence beyond NATS JetStream's own limits is needed or for complex event correlation.
    *   **Key Fields:** `event_id` (PK), `source_topic_or_webhook_id`, `received_at`, `payload_cid`, `status` ('pending_processing', 'processed_by_run_id', 'archived_no_trigger').
    *   **Indexing:** On `source_topic_or_webhook_id`, `status`, `received_at`.
*   **`billing_ledger` (C-ION Transactions):**
    *   **Purpose:** Immutable log of all C-ION credit and debit operations related to IONFLUX usage.
    *   **Key Fields:** `ledger_entry_id` (PK), `owner_did`, `timestamp`, `transaction_type` ('debit_flow_execution', 'debit_agent_deploy', 'credit_from_ion_burn'), `amount_c_ion`, `related_run_id` (nullable FK), `related_ion_burn_tx_hash` (nullable), `balance_after_c_ion`.
    *   **Security:** Potentially backed by a more integrity-protected ledger or blockchain mechanism if C-ION achieves high value representation.

## 9. SCHEDULING (Trigger Types & Mechanisms)

IONFLUX flows can be initiated by a variety of triggers, providing flexibility in how automations are started:

1.  **Cron-like / Scheduled Triggers:**
    *   **Mechanism:** Integration with `Chronos Task Agent`. Users define a schedule (e.g., "every Monday at 9 AM," "every 15 minutes") in Chronos.
    *   **Action:** Chronos, at the scheduled time, publishes a predefined NATS message or calls a specific IONFLUX webhook.
    *   **Payload:** The Chronos task definition includes the payload to be sent to IONFLUX, which then becomes the initial input for the triggered flow.
    *   **Use Cases:** Regular data aggregation, report generation, system maintenance tasks, scheduled social media posts.

2.  **Event-Driven Triggers (NATS):**
    *   **Mechanism:** IONFLUX flows can subscribe to specific NATS subjects (topics), including those with wildcards.
    *   **Action:** When a message is published to a subscribed NATS subject (by another agent, an external application integrated with NATS, or even another IONFLUX flow), the flow is triggered.
    *   **Payload:** The NATS message payload becomes the input to the flow.
    *   **Use Cases:** Reacting to real-time events like "new_user_signup" (from IONWALL), "shopify_order_created" (via Symbiosis Agent), "file_added_to_ionpod_folder_X", "ai_twin_insight_generated" (from IONPOD). This is the core of an event-driven architecture.

3.  **Manual Triggers (UI / API Call):**
    *   **Mechanism:** Users can manually initiate a flow run directly from the IONFLUX UI. Developers or other systems can trigger flows via a secure HTTP API endpoint provided by IONFLUX (and protected by IONWALL).
    *   **Action:** Clicking "Run" in the UI or making an API call.
    *   **Payload:** Input parameters for the flow can be provided through a form in the UI or as a JSON body in the API call.
    *   **Use Cases:** Testing flows, on-demand execution of specific tasks, user-initiated complex operations.

4.  **Conditional Triggers / Webhooks (from External Systems):**
    *   **Mechanism:** IONFLUX provides unique, secure webhook URLs for specific flows. External systems (e.g., GitHub, Stripe, Typeform, any service that can send an HTTP POST) can send data to these URLs.
    *   **Action:** An incoming HTTP request to the webhook URL triggers the associated flow.
    *   **Payload:** The HTTP request body (typically JSON) becomes the input to the flow. Headers can also be inspected.
    *   **Security:** Webhook URLs must be protected. IONWALL can apply IP whitelisting, signature verification (e.g., for GitHub webhooks), or API key checks before passing the request to IONFLUX.
    *   **Use Cases:** Integrating with third-party services, reacting to events from systems not directly on NATS.

5.  **Flow-to-Flow Triggers (Chaining):**
    *   **Mechanism:** One IONFLUX flow can, as one of its steps, publish a NATS message or call the API of another IONFLUX flow.
    *   **Action:** This allows for creating meta-orchestrations or breaking down extremely complex processes into smaller, manageable, and reusable flows.
    *   **Use Cases:** A "Daily Data Ingestion Flow" might trigger multiple specific "Data Processing Flows" based on the type of data ingested.

The choice of trigger depends on the specific automation needs, whether it's time-based, event-based, user-initiated, or externally driven.

## 10. FUTURE EXPANSION (Elaborated Points)

IONFLUX is envisioned as an evolving Workflow OS. Key future directions include:

1.  **Decentralized Flow Execution Network (Compute-ION Incentivized):**
    *   Allowing users to opt-in their spare compute resources (edge devices, personal servers with Deno/Wasm capabilities) to a decentralized network that can execute IONFLUX tasks (especially non-sensitive, publicly defined ones).
    *   Participants would earn C-ION/ION for contributing compute, creating a more resilient and potentially cost-effective execution layer. This requires robust sandboxing, reputation for compute nodes (via IONWALL), and secure task distribution.

2.  **Advanced AI-Driven Flow Generation & Self-Healing:**
    *   "Jules AI" evolving from a co-pilot to a more autonomous flow architect. Users state a high-level goal (e.g., "Alert me if any key competitor launches a new product line and draft a competitive analysis brief"), and Jules AI designs, proposes, and (upon approval) deploys the entire multi-agent flow.
    *   Flows that can self-heal: if a step fails due to a transient error in an external API or a misconfigured agent, the AI orchestrator (or a specialized "Guardian for Flows" agent) could analyze the error, consult TechGnosis for solutions, and attempt to dynamically reroute, substitute an alternative agent/transform, or adjust parameters to achieve the original goal.

3.  **Visual Debugger with Time-Travel & State Inspection:**
    *   A more advanced visual debugger integrated into the IONFLUX UI. Users could not only see past execution logs but also "time-travel" through a failed flow's execution, inspect the state (inputs/outputs) of each node at each historical step, and potentially re-run specific steps with modified inputs to diagnose issues. This requires sophisticated state snapshotting.

4.  **Formal Verification & Security Auditing for Flows:**
    *   Integration with formal verification tools or techniques to mathematically prove certain properties of a flow (e.g., "this financial flow will never transfer more than X amount without explicit multi-sig approval from IONWALLET").
    *   Automated security auditing of flow definitions, checking for common pitfalls like insecure handling of credentials (even if referenced via IONWALLET, the logic matters), data exposure risks, or overly broad permissions requested by constituent agents/transforms. Results could influence an IONWALL "Flow Trust Score."

5.  **Cross-sNetwork Flow Federation & Interoperability:**
    *   Defining standards and protocols for IONFLUX instances running in different user sNetworks (or even different organizations' sNetworks) to securely discover and invoke each other's published flows or agents (with granular permissions managed by IONWALL of each participating sNetwork).
    *   This enables more complex, decentralized collaborations and value chains, e.g., a supply chain automation that spans multiple independent businesses each running their own IONFLUX.

## 11. SERVER BOOTSTRAP (Bootstrap Script & Disaster Recovery)

*   **Bootstrap Script (`ionflux_bootstrap.sh` or similar):**
    *   **Purpose:** Automates the initial setup and configuration of a new IONFLUX instance, whether for local development, a staging environment, or a production deployment (when not fully managed by a sophisticated IaC like Terraform + Helm for K8s).
    *   **Key Actions:**
        1.  Checks for dependencies (Docker, Deno, NATS server access, PostgreSQL access).
        2.  Sets up necessary database schemas and runs initial migrations for PostgreSQL (for `flows`, `runs`, etc.) if not handled by Hasura's migration system.
        3.  Configures NATS JetStream (creates streams, consumers for core IONFLUX topics if not pre-existing).
        4.  Deploys Hasura GraphQL engine with IONFLUX metadata and connects it to the database.
        5.  Registers core system Agents and Transforms with the `agents_registry` if not already present.
        6.  Sets up default IONWALL policies related to IONFLUX (e.g., permissions for the Flow Orchestrator to talk to NATS).
        7.  Starts essential IONFLUX services (Flow Orchestrator, Runtime Sandbox Manager).
*   **Disaster Recovery (DR) Points:**
    *   **Database Backups:** Regular, automated backups of the PostgreSQL database (e.g., daily full, continuous WAL archiving) stored securely in a separate location (e.g., different cloud region or offsite). Point-in-Time Recovery (PITR) capability is crucial.
    *   **Object Storage Replication:** Versioning and cross-region replication for MinIO/S3 buckets containing flow artifacts and detailed logs.
    *   **NATS JetStream Snapshots/Mirroring:** JetStream supports clustering for HA. For DR, stream data can be snapshotted or mirrored to another NATS cluster in a DR site. If `event_mirror_for_audit` table is used, it also serves as a DR source for critical events.
    *   **Configuration as Code:** All service configurations, Helm charts, Terraform/Pulumi scripts, and the bootstrap script itself are version controlled in Git, allowing for reproducible deployments.
    *   **IONPOD Backups for User Data:** While IONFLUX itself doesn't store primary user data (that's in IONPOD), DR for IONFLUX means ensuring it can reconnect to a restored IONPOD/IPFS environment and IONWALL to resume operations. User-specific flow definitions (YAML CIDs) are backed up as part of IONPOD backup strategy.
    *   **Failover for Orchestrator/Runtime:** If using Kubernetes, ReplicaSets and orchestration health checks allow for automatic restart/failover of stateless IONFLUX components. For stateful orchestrators like Temporal, its own HA/DR mechanisms apply.

## 12. TASK TYPES (Examples & Latency SLAs)

IONFLUX processes a wide variety of "tasks," which are typically individual steps (Agent or Transform executions) within a flow. SLAs are conceptual targets and depend on underlying resources and external service performance.

1.  **Data Transformation (e.g., `JSON_Path_Extractor_Transform`, `Image_Resize_Transform`):**
    *   **Description:** Takes input data, modifies or extracts parts of it, and outputs the result. Usually CPU-bound or memory-bound if data is large.
    *   **Latency SLA (Target):** Sub-second (<100ms for small data, <1s for medium).
2.  **IONPOD Read/Write (e.g., `FetchFromIONPOD_Transform`, `StoreToIONPOD_Transform`):**
    *   **Description:** Interacts with IPFS (via IONPOD services) to get or put data. Network I/O bound, depends on IPFS network speed and gateway performance. Involves IONWALL checks.
    *   **Latency SLA (Target):** 100ms - 5 seconds (highly variable due to IPFS).
3.  **External API Call (e.g., via `SymbiosisPluginAgent` or a specific HTTP transform):**
    *   **Description:** Makes an HTTP request to a third-party API. Network I/O bound, depends on external API's latency and rate limits. Involves IONWALL checks.
    *   **Latency SLA (Target):** 200ms - 10 seconds (highly variable).
4.  **LLM Inference (e.g., `MuseGen_LLM_Transform`):**
    *   **Description:** Sends a prompt to an LLM and gets a response. Compute and network I/O bound. Latency depends on model size, prompt length, output length, and provider load. Involves IONWALL checks.
    *   **Latency SLA (Target):** 1 second - 60+ seconds (highly variable).
5.  **NATS Publish/Subscribe (e.g., `IPC_NATS_Publish_Transform`, Trigger nodes):**
    *   **Description:** Sending or receiving messages via NATS. Very low latency if NATS is local or well-connected.
    *   **Latency SLA (Target):** <10ms - 100ms.
6.  **Logic/Control Flow (e.g., `ConditionalRouter_Transform`, Loop constructs):**
    *   **Description:** Evaluates conditions or manages iteration. Very fast, CPU-bound within the orchestrator/runtime.
    *   **Latency SLA (Target):** <10ms.
7.  **Agent Orchestration Step (within `MasterPlanExecutor_Transform` in ION Reactor, or a complex IONFLUX Flow-Agent):**
    *   **Description:** One step in a larger workflow that involves invoking another agent and waiting for its completion. Latency is cumulative of that sub-agent's own tasks.
    *   **Latency SLA (Target):** Highly variable, sum of sub-tasks + orchestration overhead.

Overall flow latency is the sum of its constituent task latencies and orchestration overhead. IONFLUX aims to minimize its own overhead to ensure that the perceived performance is primarily that of the underlying agents and services being orchestrated.
