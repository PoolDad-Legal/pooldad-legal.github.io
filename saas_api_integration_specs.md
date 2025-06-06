# IONFLUX Project: SaaS/API Integration Specifications

This document details the specifications for integrating third-party SaaS platforms and APIs into the IONFLUX ecosystem. It builds upon the `conceptual_definition.md`, `ui_ux_concepts.md`, and incorporates insights from `core_agent_blueprints.md`.

## 1. LLM Provider Integration (`LLM Orchestration Service`)

The `LLM Orchestration Service` will act as a central hub for all Large Language Model interactions, providing a unified interface for other IONFLUX services.

**1.1. Primary Provider Choice (for Beta):**

*   **Recommendation:** **OpenAI**
*   **Justification:**
    *   **Mature API:** OpenAI offers a well-documented, robust, and feature-rich API.
    *   **Model Variety & Capability:** Access to a wide range of models (e.g., GPT-3.5-turbo, GPT-4, GPT-4o, Embeddings, Whisper) suitable for diverse tasks outlined in the IONFLUX proposal.
    *   **Strong Developer Ecosystem:** Extensive community support, libraries, and resources are available, potentially speeding up development.
    *   **Performance:** Generally good performance in terms of response quality and latency for many common use cases.
    *   While other providers like Anthropic (Claude) or Google (Gemini) are strong contenders, OpenAI's current overall maturity and widespread adoption make it a pragmatic choice for the initial beta to ensure rapid development and a broad feature set. This choice can be expanded later.

**1.2. API Key Management Strategy:**

*   **How keys will be obtained:**
    *   **Initial Beta:** IONFLUX will use a **central IONFLUX-owned API key** for each LLM provider (e.g., one OpenAI key for the platform). This simplifies the initial user experience as users won't need to procure their own keys immediately.
    *   **Future Consideration:** Allow users/workspaces to optionally provide their own API keys. This can be beneficial for users who want to leverage their existing accounts, manage their own rate limits, or have specific billing arrangements with LLM providers. If a user provides a key, it would override the central key for their requests.
*   **How keys will be stored securely:**
    *   Central IONFLUX API keys will be stored in a **dedicated secrets management service** (e.g., HashiCorp Vault, AWS Secrets Manager, Google Secret Manager). They will NOT be stored directly in the database or codebase.
    *   If user-provided keys are implemented, they will be encrypted at rest (e.g., using AES-256) in the database, associated with the `Workspace` or `User` entity. The encryption key itself will be managed by the secrets management service.
*   **How `LLM Orchestration Service` accesses and uses these keys:**
    *   The `LLM Orchestration Service` will have secure, IAM-controlled access to the secrets management service to retrieve the central IONFLUX API key(s) at runtime.
    *   If user-provided keys are used, the service would retrieve the encrypted key from the database, decrypt it using a key from the secrets manager, and then use it for the API call. The decrypted key should only be held in memory for the duration of the request.
    *   A mapping within `LLM Orchestration Service` or its configuration will determine which key to use based on the request context (e.g., default IONFLUX key, or a specific user/workspace key if provided).

**1.3. Core Request/Response Structure (Internal):**

This defines the internal API contract between services like `Agent Service` and the `LLM Orchestration Service`.

*   **Request to `LLM Orchestration Service`:**
    ```json
    {
      "provider": "string (e.g., 'openai', 'anthropic', 'deepseek', 'sentence-transformers', defaults to 'openai')",
      "model": "string (e.g., 'gpt-4o', 'claude-3-haiku', 'ds-chat-b32', 'multi-qa-MiniLM-L6-cos-v1')",
      "task_type": "string (enum: 'text_generation', 'embedding', 'speech_to_text', 'image_understanding', default: 'text_generation')", // NEW
      "prompt": "string (nullable, for text_generation, image_understanding)",
      "text_to_embed": "string (nullable, for embedding task)",
      "audio_input_url": "string (nullable, for speech_to_text task)",
      "image_input_url": "string (nullable, for image_understanding task)",
      "system_prompt": "string (optional)",
      "history": [
        { "role": "user", "content": "Previous message" },
        { "role": "assistant", "content": "Previous response" }
      ],
      "parameters": {
        "max_tokens": "integer (optional)",
        "temperature": "float (optional, 0.0-2.0)",
        "top_p": "float (optional, 0.0-1.0)",
        "stop_sequences": ["string (optional)"]
      },
      "user_id": "string (UUID, references User.id)",
      "workspace_id": "string (UUID, references Workspace.id)",
      "request_id": "string (UUID, for logging and tracing)"
    }
    ```

*   **Response from `LLM Orchestration Service`:**
    *   **Success:**
        ```json
        {
          "status": "success",
          "request_id": "string (UUID, mirrors request)",
          "task_type": "string (mirrors request task_type)", // NEW
          "provider_response": {
            "id": "string (provider's response ID)",
            "model_used": "string (actual model that handled the request)", // NEW
            "choices": [ // For text_generation
              {
                "text": "string (generated text)",
                "finish_reason": "string (e.g., 'stop', 'length')"
              }
            ],
            "embedding": ["float (nullable, for embedding task)"], // NEW
            "transcription": "text (nullable, for speech_to_text task)", // NEW
            "image_analysis_text": "text (nullable, for image_understanding task)", // NEW
            "usage": {
              "prompt_tokens": "integer",
              "completion_tokens": "integer (nullable)",
              "total_tokens": "integer"
            }
          }
        }
        ```
    *   **Error:**
        ```json
        {
          "status": "error",
          "request_id": "string (UUID, mirrors request)",
          "error": {
            "code": "string (internal error code)",
            "message": "string (user-friendly error message)",
            "provider_error": "object (optional, raw error from LLM provider)"
          }
        }
        ```

**1.4. Supported Model Types & Providers (Initial Focus):**
The `LLM Orchestration Service` is designed to be a true orchestration layer.
*   **Text Generation & Reasoning:** OpenAI (GPT-4o, GPT-3.5-turbo), Anthropic (Claude 3 Haiku), DeepSeek (ds-chat-b32).
*   **Embeddings:** OpenAI (text-embedding-3-small), Sentence-Transformers (various models, potentially run via a dedicated embedding service IONFLUX might host, or via API if available). The service abstracts embedding generation.
*   **Speech-to-Text:** OpenAI (Whisper-large).
*   **Image Understanding/Processing (Conceptual for future agents, but good to anticipate):** Models like CLIP for image embeddings or visual Q&A. The service should anticipate routing such requests if they arise from agent needs.

**1.5. Vector DB Interaction for RAG/Memory:**
The `LLM Orchestration Service`'s primary role is to provide access to LLM models for generation, embeddings, etc. It does *not* directly manage or interact with vector databases for agent memory or Retrieval Augmented Generation (RAG) patterns.
*   The `AgentService` (or the agent's own logic) is responsible for:
    *   Querying vector databases (like Pinecone) for relevant context.
    *   Constructing prompts that include this retrieved context.
    *   Sending these enriched prompts to the `LLM Orchestration Service`.
*   The `LLM Orchestration Service` may generate embeddings (via an embedding model) which the `AgentService` then stores in a vector database.

## 2. Shopify Integration (`Shopify Integration Service`)

This service will handle all communications with the Shopify platform.

**2.1. Authentication:** (As previously defined - OAuth 2.0 Flow)

**2.2. Key Shopify APIs & Data Points:**
*   (As previously defined, ensure scopes cover:)
    *   `read_products`, `write_products` (if agents modify products)
    *   `read_product_listings` (for broader catalog access if needed by agents like Outreach Automaton)
    *   `read_orders`, `write_orders` (if agents modify orders)
    *   `read_customers`, `write_customers` (with PII caution)
    *   `read_shop_locales` (for currency, timezone, etc.)
    *   `read_inventory`, `write_inventory`
*   Webhook management APIs are also key.

**2.3. Webhook Subscriptions:**
*   (As previously defined: `orders/create`, `orders/updated`, `orders/paid`, `orders/fulfilled`, `products/create`, `products/update`, `app/uninstalled`, `shop/update`).
*   **Webhook Forwarding:** Critical webhooks (e.g., `orders/create`, `products/update`) received by the `Shopify Integration Service` should not only be processed for direct agent needs but can also be published to an internal IONFLUX message broker (e.g., RabbitMQ topic: `platform.shopify.events.orders.created`). This allows multiple internal services or agents (like `Email Wizard` or `Badge Motivator`) to react to these events in a decoupled manner.

**2.4. Data Sync Strategy:** (As previously defined - Webhooks primary, Polling secondary)

## 3. TikTok Integration (`TikTok Integration Service`)

This service will manage interactions with TikTok APIs.

**3.1. Authentication:** (As previously defined - OAuth 2.0 Flow)

**3.2. Key TikTok APIs & Data Points:**
*   (As previously defined)
*   **Trending Data Clarification (for `TikTok Stylist`):** Direct API access to "trending sounds" can be limited or require specific partnerships. Initial implementation may rely on hashtag/video search proxies (`GET /v2/research/video/query/`, `GET /v2/research/hashtag/query/`), or curated lists, while pursuing deeper trend data access. IONFLUX may need to implement its own trend detection logic based on data from these research APIs.

**3.3. Permissions (OAuth Scopes - TikTok Developer API example):**
*   (As previously defined) Reconfirm that `research.video.query` and `research.hashtag.query` are appropriate. Add `user.video.profiles` or similar if needed for fetching video lists of specific, authenticated users.

**3.4. Content Moderation/Compliance:** (As previously defined)

## 4. Email Sending Service Integration (e.g., SendGrid, AWS SES)

*   **Purpose within IONFLUX:** To enable agents like `Email Wizard` (Agent 001) and potentially `Outreach Automaton` (Agent 006) or `UGCMatchmaker` (Agent 005 for "GhostPitch") to send emails programmatically. This includes transactional emails (e.g., notifications if email is chosen channel) and agent-generated content (e.g., marketing drafts, outreach messages).
*   **Authentication Approach:**
    *   **Platform-Managed Keys:** IONFLUX will maintain its own account(s) with one or more Email Service Providers (ESPs like SendGrid or AWS SES). API keys for these ESPs will be stored securely in the IONFLUX secrets management system.
    *   **User-Provided Keys (Future):** Allow workspaces to configure their own ESP accounts/API keys for enhanced deliverability, domain reputation management, and direct billing.
*   **Key API Functionalities IONFLUX Would Use:**
    *   Send single emails.
    *   Send bulk/batched emails (respecting ESP policies).
    *   (Optional) Basic template variable substitution if ESP supports it simply. Complex templating likely handled by agent logic before calling send.
    *   Receive and process webhooks for delivery status (bounces, spam reports, opens, clicks) to track email effectiveness and manage list hygiene.
*   **Responsible IONFLUX Service:**
    *   A new **`NotificationService` enhancement or a dedicated `EmailDispatchService`**.
        *   If primarily for agent-generated notifications and simple messages, `NotificationService` could be expanded.
        *   For more complex email campaign features (batching, advanced analytics from webhooks) suggested by `Email Wizard`'s capabilities, a dedicated `EmailDispatchService` would be more appropriate to encapsulate ESP-specific logic and provide a clean internal API (`POST /emails/send`).

## 5. WhatsApp Messaging Service Integration (e.g., Meta WhatsApp Cloud API)

*   **Purpose within IONFLUX:** To enable agents like `WhatsApp Pulse` (Agent 002) and potentially `Outreach Automaton` or `UGCMatchmaker` to send and receive WhatsApp messages, manage templates, and handle interactive elements.
*   **Authentication Approach:**
    *   **Platform-Managed via Meta Cloud API:** IONFLUX as a platform would need to be a registered Business Solution Provider (BSP) or work through one. This involves setting up Meta Business Accounts, WhatsApp Business Accounts (WABA), and managing system user tokens, phone number certificates, and message templates. This is a significant platform-level setup and compliance effort.
    *   **User Onboarding:** Individual IONFLUX workspaces (Brands) would then connect their specific WhatsApp Business Phone Numbers to the IONFLUX application through an IONFLUX-managed OAuth-like flow or guided setup process that links their WABA to IONFLUX's BSP infrastructure.
*   **Key API Functionalities IONFLUX Would Use (via Meta Cloud API):**
    *   Send template messages (HSMs - Highly Structured Messages).
    *   Send session messages (free-form replies within the 24-hour customer service window).
    *   Receive incoming messages and status notifications (delivered, read) via webhooks.
    *   Manage message templates (submission for approval by Meta).
    *   User opt-in/opt-out management (critical for compliance).
*   **Responsible IONFLUX Service:**
    *   A new, dedicated **`WhatsAppIntegrationService`** (or a more generic `MessagingService` if other platforms like SMS, FB Messenger are added later). This service is essential due to the unique complexities, compliance requirements (end-to-end encryption, template approvals), and specific API interactions of the WhatsApp Business Platform. It would handle API calls, webhook ingestion/validation, and provide a simplified internal API for agents.

## 6. Vector Database Integration (e.g., Pinecone)

*   **Purpose within IONFLUX:** As identified in `core_agent_blueprints.md`, numerous agents (`Email Wizard`, `TikTok Stylist`, `UGC Matchmaker`, etc.) rely on vector databases (Pinecone specified) for storing and querying embeddings. This supports semantic search, persona matching, context retrieval (RAG), and agent memory.
*   **Management Approach & Authentication:**
    *   **Platform-Managed Resource:** IONFLUX will operate and manage its own vector database accounts/clusters (e.g., a central Pinecone account). The API key(s) for IONFLUX's vector database infrastructure will be stored securely in the platform's central secrets management system. This is an internal infrastructure component, not a user-connected SaaS.
    *   **Namespace/Index Management:**
        *   The `AgentService` will be responsible for programmatically managing namespaces or indexes within the vector database.
        *   When an `AgentConfiguration` requiring memory is created or initialized, the `AgentService` (or the agent's setup logic orchestrated by `AgentService`) will use the `AgentDefinition.memory_config.namespace_template` (e.g., `agent001_memory_for_workspace_{{workspace_id}}`) and the specific `AgentConfiguration.id` or other context to create/designate a unique, isolated namespace/index for that agent instance if needed.
        *   The resolved namespace will be stored in `AgentConfiguration.external_memory_namespace`.
*   **Key Functionalities Used by IONFLUX (via official client libraries like `pinecone-client`):**
    *   Index/Collection Management: Create, delete, describe indexes.
    *   Vector Operations: Upsert (with metadata), query (similarity search, by ID, with metadata filters), delete vectors.
*   **Responsible IONFLUX Service/Component:**
    *   The **`AgentService`** is the primary IONFLUX service that will configure and provide context (like API keys and resolved namespaces) to agents that require vector database access.
    *   The agent execution environment (managed by `AgentService`) will run the agent code, which will use the appropriate vector DB client library to perform operations.
    *   The `LLM Orchestration Service` may generate embeddings, which are then returned to `AgentService` to be stored in the vector DB by the agent's logic.

## 7. Other Potential Integrations (Conceptual Notes)

*   **Project Management/Collaboration (Notion, Jira - e.g., for `Slack Brief Butler`):**
    *   **Initial Strategy:** For demo/Beta, these are likely to be "write-only" or targeted API actions rather than full, bidirectional integrations.
    *   **Implementation:** An agent's `yaml_config` might store user-provided API tokens/keys for a specific Notion workspace or Jira instance and a target database/page/project ID. The agent logic (within `AgentService`) would then use official client libraries (e.g., `notion-client`, `jira-python`) to perform actions like "create page," "add database entry," or "create issue."
    *   **Service Responsibility:** No dedicated integration service is planned for these initially; responsibility lies with the `AgentService` to securely handle these user-provided credentials (potentially via a secure vault accessible to the agent execution environment) and execute the actions.
*   **Calendar/Booking (Calendly - e.g., for `Outreach Automaton`):**
    *   **Initial Strategy:** Primarily link generation. The agent would take a user's base Calendly link from its `yaml_config` and append parameters or use it in outreach messages.
    *   **Future:** Deeper integration (e.g., creating events via API) would require OAuth and a more dedicated integration approach, possibly within an expanded `OutreachAutomaton` or a generic `CalendarIntegrationService`.
*   **Payment Processors (Stripe - for `Revenue Tracker Lite` data ingestion):**
    *   **Initial Strategy:** `Revenue Tracker Lite` primarily focuses on Shopify-derived data. If direct Stripe data ingestion (for non-Shopify sales or deeper financial reconciliation) is needed, it would require a separate Stripe Connect OAuth flow and API interaction, similar to the Shopify integration. This would be a candidate for a `StripeIntegrationService` or an expansion of a generic `FinancialPlatformIntegrationService`. This is out of scope for the initial E2E demo's "Lite" version.
*   **Social Media Scraping/Unofficial APIs (LinkedIn, Similarweb, TikTok Trends):**
    *   **Strategy & Disclaimer:** These are not standard, reliable API integrations.
        *   Use of such methods must be clearly documented as potentially unstable, subject to breakage, and carrying ethical/ToS risks.
        *   Implementation would be via specialized libraries/tools (e.g., Playwright, custom HTTP clients) within the agent's own codebase (executed by `AgentService`). They are not managed as platform-level "SaaS integrations."
        *   IONFLUX should prioritize official APIs wherever available.

## 8. Generic Structure for Future SaaS Integrations

*   (Points A-I as previously defined)
*   **J. Internal Observability vs. External Integrations:**
    *   This document primarily focuses on IONFLUX integrating with *external* SaaS APIs that users connect or that agents consume data from. Agents themselves (as defined in `core_agent_blueprints.md`) may specify an internal stack for logging, metrics, and tracing (e.g., Prometheus, Grafana, Loki, Jaeger, OpenTelemetry). This internal observability pipeline is a distinct architectural component of IONFLUX, managed by the platform operations team. While agents emit data to this pipeline, IONFLUX typically does not *consume* APIs from these specific observability tools as a 'SaaS integration' in the same vein as Shopify or TikTok, unless a specific agent is designed for that purpose (e.g., an "Observability Dashboard Agent").

These proposed updates and additions aim to ensure `saas_api_integration_specs.md` comprehensively covers the requirements identified in the detailed agent blueprints.
```
