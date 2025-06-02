# IONFLUX Project: SaaS/API Integration Specifications - Update Proposals

This document proposes updates and additions to the `saas_api_integration_specs.md` document. These proposals are based on a review of the detailed agent specifications in `core_agent_blueprints.md` and aim to ensure the integration layer can support the defined agent functionalities.

## Proposed New Integration Sections

The agent blueprints reveal dependencies on several new categories of external services/APIs. We propose adding dedicated sections or considerations for these:

### 1. Email Sending Service Integration (e.g., SendGrid, AWS SES)

*   **Purpose within IONFLUX:** To enable agents like `Email Wizard` (Agent 001) and potentially `Outreach Automaton` (Agent 006) or `UGCMatchmaker` (Agent 005 for "GhostPitch") to send emails programmatically. This includes transactional emails, marketing messages, and outreach sequences.
*   **Authentication Approach:**
    *   **Platform-Managed Keys:** IONFLUX will configure a central account with one or more email service providers (ESPs). API keys for these ESPs will be stored securely in the IONFLUX secrets management system.
    *   **User-Provided Keys (Future):** Workspaces might be able to configure their own ESP accounts and API keys for deliverability, reputation management, and billing under their own accounts.
*   **Key API Functionalities IONFLUX Would Use:**
    *   Send single/bulk emails (transactional and marketing).
    *   Template management (if ESP supports it, or IONFLUX manages templates).
    *   Email validation (basic check).
    *   Tracking opens, clicks, bounces, spam reports (via webhooks from ESP or API polling).
*   **Responsible IONFLUX Service:**
    *   A new **`EmailService`** (microservice) is recommended to encapsulate interactions with various ESPs, providing a unified internal API for sending emails and receiving status updates.
    *   Alternatively, the `NotificationService` could be expanded if the scope is limited to basic notifications, but for full email capabilities (like those of Email Wizard), a dedicated service is cleaner.

### 2. WhatsApp Messaging Service Integration (e.g., Meta WhatsApp Cloud API)

*   **Purpose within IONFLUX:** To enable agents like `WhatsApp Pulse` (Agent 002) and potentially `Outreach Automaton` to send and receive WhatsApp messages, manage templates, and handle interactive elements.
*   **Authentication Approach:**
    *   **Platform-Managed via Meta Cloud API:** IONFLUX would need to undergo Meta's approval process to use the WhatsApp Cloud API. This involves setting up a Meta Business Account, WhatsApp Business Account, and managing system user tokens and phone number certificates. This is a complex, platform-level setup.
    *   Individual users/workspaces would then connect their WhatsApp Business Phone Numbers to the IONFLUX application.
*   **Key API Functionalities IONFLUX Would Use:**
    *   Send template messages (HSMs).
    *   Send session messages (free-form replies within 24-hour window).
    *   Receive incoming messages and status webhooks (message delivered, read, user replies).
    *   Manage message templates.
    *   User opt-in management.
*   **Responsible IONFLUX Service:**
    *   A new **`MessagingService` or `WhatsAppIntegrationService`** is highly recommended due to the complexity and specific nature of the WhatsApp API. This service would handle the API interactions, webhook processing, and provide a simplified internal API for agents.

### 3. Vector Database Integration (e.g., Pinecone, Weaviate)

*   **Purpose within IONFLUX:** Several agents (`Email Wizard`, `WhatsApp Pulse`, `TikTok Stylist`, `UGC Matchmaker`, `Outreach Automaton`, `Slack Brief Butler`, `Creator Persona Guardian`, `Revenue Tracker Lite`) specify using a Vector Database (Pinecone is frequently mentioned) for storing and querying embeddings for tasks like semantic search, persona matching, context retrieval, and memory.
*   **Management Approach & Authentication:**
    *   **Platform-Managed Instance:** IONFLUX will operate its own instance(s) of a chosen vector database (e.g., a Pinecone account). The API key for IONFLUX's own vector database account will be stored in the platform's central secrets management system.
    *   **Namespace Management:**
        *   The `AgentDefinition.memory_config.namespace_template` (e.g., `emailwizard_instance_{{instance_id}}`) and `AgentConfiguration.external_memory_namespace` fields (from `data_model_update_proposals.md`) will be used.
        *   The `AgentService` or the agent execution environment will be responsible for resolving these templates to create or connect to specific namespaces for each agent instance or definition, ensuring data isolation where needed.
*   **Key API Functionalities IONFLUX Would Use (via client libraries):**
    *   Create/delete indexes/collections.
    *   Upsert vectors (with metadata).
    *   Query vectors (similarity search, by ID).
    *   Delete vectors.
*   **Responsible IONFLUX Service/Component:**
    *   The **`AgentService`** will likely be the primary internal service that interacts with the vector database infrastructure on behalf of agents. Agents themselves (their code) would use client libraries for the chosen vector DB, configured by the `AgentService` with the correct API keys and namespace.
    *   The `LLM Orchestration Service` might also interact with vector DBs if it's responsible for generating embeddings that agents then store or query.
    *   This is less about integrating a *user's* SaaS account and more about IONFLUX *using* a DBaaS as part of its own backend infrastructure. The spec should clarify this distinction.

### 4. Other Potential Integrations (Brief Mentions)

*   **Project Management/Collaboration (Notion, Jira - for `Slack Brief Butler`):**
    *   **Strategy:** For the E2E demo and initial versions, these are likely to be "write-only" actions if implemented by the agent.
    *   The agent's `yaml_config` might store a user-provided API key/token for a specific Notion workspace or Jira instance and a target page/project ID.
    *   The agent logic itself (running within `AgentService`) would use the respective client libraries (e.g., Notion Python SDK, Jira Python SDK) to perform actions like "create page" or "create issue."
    *   A full, bidirectional, platform-level integration service for these is a larger scope for future consideration.
*   **Calendar/Booking (Calendly - for `Outreach Automaton`):**
    *   **Strategy:** Likely involves the agent generating a Calendly link (user provides their base Calendly link in `yaml_config`) or using Calendly's API for more direct booking if a user connects their Calendly account (future). For now, link generation is sufficient.
*   **Payment Processors (Stripe - for `Revenue Tracker Lite` data ingestion):**
    *   **Strategy:** If `Revenue Tracker Lite` needs to pull data directly from Stripe (beyond what Shopify provides), this would necessitate a Stripe Connect OAuth flow similar to Shopify, or API key handling. This would be managed by a dedicated section in the integration specs or a more generic `FinancialPlatformIntegrationService`. For the "Lite" version, focusing on Shopify-derived data is primary.
*   **Social Media Scraping/Data (for `Outreach Automaton` - LinkedIn, Similarweb; `TikTok Stylist` - Unofficial TikTok Trend API):**
    *   **Strategy:** These are not standard SaaS API integrations.
        *   LinkedIn scraping is against ToS and fragile. If used, it would be via tools like Playwright managed by the agent's own stack, with significant ethical and stability caveats.
        *   Similarweb might have an official API (paid) or be subject to scraping.
        *   Unofficial APIs are inherently unstable.
    *   These should be noted as high-risk/volatile dependencies within the agent blueprints and potentially managed by specialized modules within the `AgentService` or the agent's own codebase, rather than a generic integration service. The `saas_api_integration_specs.md` should probably highlight the risks of such dependencies if they are critical.

## Proposed Updates to Existing Integration Sections

### 1. LLM Provider Integration (`LLM Orchestration Service`)

*   **Model Diversity:**
    *   **Current:** Specifies OpenAI as primary, with others as future.
    *   **Proposal:** Explicitly state that the `LLM Orchestration Service` is designed to be a true orchestration layer. Its internal `Core Request/Response Structure` (Section 1.3) already includes `"provider"` and `"model"` fields.
    *   Add a sub-section: **"Supported Model Types & Providers (Initial Focus)"**:
        *   **Text Generation & Reasoning:** OpenAI (GPT-4o, GPT-3.5-turbo), Anthropic (Claude 3 Haiku), DeepSeek (ds-chat-b32).
        *   **Embeddings:** OpenAI (text-embedding-3-small), Sentence-Transformers (various models, potentially run locally or via an API). The service should abstract the embedding generation.
        *   **Speech-to-Text:** OpenAI (Whisper-large).
        *   **Image Understanding/Processing (Conceptual for future, but mentioned by agents):** CLIP (as mentioned in `UGC Matchmaker` for image embeddings). The service should anticipate routing such requests.
    *   **Rationale:** The agent blueprints clearly list a variety of models. The `LLM Orchestration Service` must be architected to handle this heterogeneity from the start, even if only a subset is implemented for the demo. This involves mapping generic requests to provider-specific API calls and handling diverse response formats.
*   **Vector DB Interaction for RAG/Memory:**
    *   **Proposal:** Add a note clarifying the relationship between `LLM Orchestration Service` and Vector Databases. While agents might directly query/update vector DBs for their long-term memory or specific RAG patterns (managed via `AgentService` context), the `LLM Orchestration Service` itself might *not* directly integrate with vector DBs. Its role is to provide access to LLM models. However, it might receive context *from* a vector DB (passed in the prompt by `AgentService`) or generate embeddings that `AgentService` then stores. This clarifies boundaries.

### 2. Shopify Integration (`Shopify Integration Service`)

*   **Review Agent Needs:**
    *   `Shopify Sales Sentinel`: Requires `orders/create`, `orders/paid` webhooks. (Already in spec). Also uses `/admin/shop.json` for currency, etc. (covered by optional test call).
    *   `Revenue Tracker Lite`: Requires fetching Orders and Products. (Already in spec).
    *   `Email Wizard` (Exemplo Integrado): Mentions "Shopify emite webhook order/create rápido". This implies `Shopify Integration Service` should forward such events to an internal message broker that other services/agents can subscribe to, or `AgentService` can route them.
    *   `Outreach Automaton` (DataMiner Scraper): Mentions collecting "loja Shopify" data. This might imply needing product/collection data for context. Add `read_product_listings` scope if not covered by `read_products`.
*   **Proposal:**
    *   **Webhook Forwarding:** Add a note under "Data Sync Strategy" or "Webhook Subscriptions" that critical webhooks (like `orders/create`) might also be published to an internal message broker (e.g., RabbitMQ/Kafka topic like `shopify.events.orders.created`) for consumption by various interested IONFLUX services/agents, not just the one that initiated the Shopify connection. This supports event-driven architecture across IONFLUX.
    *   **Scopes:** Ensure `read_orders`, `read_products`, `read_customers` (with PII caution) are listed. Add `read_product_listings` if it's a distinct, broader scope for catalog browsing.

### 3. TikTok Integration (`TikTok Integration Service`)

*   **Review Agent Needs:**
    *   `TikTok Stylist`: Needs video search, hashtag search, potentially trend APIs. `GET /v2/research/video/query/`, `GET /v2/research/hashtag/query/` are listed. Confirm these are the best for "trending sounds" or if alternative methods are needed.
    *   `UGC Matchmaker`: Needs user info (`GET /v2/user/info/`), video data for identified creators.
    *   `Creator Persona Guardian` (indirectly, if validating TikTok content): Might need to fetch video transcripts or metadata if the `asset_url` points to a TikTok video.
*   **Proposal:**
    *   **Trending Data Clarification:** In section "3.2 Key TikTok APIs & Data Points" for `TikTok Stylist`, add a note: "Direct API access to 'trending sounds' can be limited or require specific partnerships. Initial implementation may rely on hashtag/video search proxies, or curated lists, while pursuing deeper trend data access."
    *   **Scopes:** Reconfirm that `research.video.query` and `research.hashtag.query` are the correct scopes for the research functionalities mentioned and that IONFLUX would need to apply for these. Add `user.video.profiles` if needed for fetching video lists of specific users (beyond just `user.info.basic`).

### 4. Generic Structure for Future SaaS Integrations

*   **Observability Tools (Prometheus, Grafana, Loki, Jaeger):**
    *   **Proposal:** Add a new sub-point:
        *   **"J. Internal Observability vs. External Integrations:"** "This document primarily focuses on IONFLUX integrating with *external* SaaS APIs that users connect or that agents consume data from. Agents themselves (as defined in `core_agent_blueprints.md`) may specify an internal stack for logging, metrics, and tracing (e.g., Prometheus, Grafana, Loki, Jaeger). This internal observability pipeline is a distinct architectural component of IONFLUX, managed by the platform operations team. While agents emit data to this pipeline, IONFLUX typically does not *consume* APIs from these specific observability tools as a 'SaaS integration' in the same vein as Shopify or TikTok."
    *   **Rationale:** This clarifies the scope of `saas_api_integration_specs.md` versus internal platform architecture.

These proposed updates aim to make the `saas_api_integration_specs.md` more comprehensive, aligning it with the detailed functionalities and technical requirements emerging from the agent blueprints.
```
