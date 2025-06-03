# IONFLUX Project: SaaS/API Integration Specifications (v3)

This document details the proposed specifications for integrating third-party SaaS platforms and APIs into the IONFLUX ecosystem, reflecting the detailed requirements from `core_agent_blueprints_v3.md` (PRM) and aligning with `conceptual_definition_v3.md`.

## 1. LLM Orchestration Service

The `LLM Orchestration Service` acts as a central hub for all Large Language Model interactions, providing a unified interface for other IONFLUX services (e.g., `AgentService`).

**1.1. Supported Model Providers & Types (from PRM):**
The service must support interactions with a diverse set of models and providers as specified in agent blueprints:
*   **OpenAI:**
    *   Text Generation & Reasoning: `GPT-4o`, `GPT-3.5-turbo`
    *   Embeddings: `text-embedding-3-small`
    *   Speech-to-Text: `Whisper-large` (also `Whisper v3`)
    *   Image Understanding/Generation: `GPT-4o Vision` (analysis), `DALL-E 3` (generation for badges), `CLIP` (analysis)
*   **Anthropic:**
    *   Text Generation & Reasoning: `Claude 3 Haiku` (often as a creative or fallback option)
*   **DeepSeek:**
    *   Text Generation & Reasoning: `ds-chat-b32` (as a fallback or specialized model)
*   **Sentence-Transformers:**
    *   Embeddings: Various models (e.g., `multi-qa-MiniLM-L6-cos-v1`, `all-mpnet-base-v2`). These might be accessed via API or run in a dedicated IONFLUX embedding sub-service managed by `LLM Orchestration Service`.
*   **Other Modalities (as needed by agents, routed via this service or a dedicated one like AudioService):**
    *   Text-to-Speech (TTS): See Section 7 for `Audio Generation & Processing Service`.

**1.2. API Key Management Strategy:**
*   **Platform-Managed Central Keys:** IONFLUX uses its own API keys for each provider, stored in a central secrets management service (e.g., HashiCorp Vault, AWS/Google Secrets Manager).
*   **Workspace-Provided Keys (Future):** Allow workspaces to optionally provide their own API keys (via `Workspace.settings_json.generic_secrets_config_json` referencing secrets manager paths) for specific providers, overriding the platform key. This offers users control over their own billing and rate limits with LLM providers.
*   The `LLM Orchestration Service` retrieves the appropriate key at runtime based on request context (defaulting to platform key, using workspace key if provided and valid).

**1.3. Core Request/Response Structure (Internal):**
*   The internal API contract between services (e.g., `AgentService`) and `LLM Orchestration Service` will adhere to the structure defined in `conceptual_definition_v3.md` under the `LLM Orchestration Service` section (request includes `provider`, `model`, `task_type`, `prompt`/`text_to_embed`/`audio_input_url`/`image_input_url`, etc.; response includes `status`, `provider_response` with `choices`/`embedding`/`transcription`/`image_analysis_text`, `usage`).
*   **Task Types to Support:**
    *   `text_generation`
    *   `embedding`
    *   `speech_to_text`
    *   `image_understanding` (e.g., analysis from `GPT-4o Vision`, `CLIP`)
    *   (Future) `image_generation` (e.g., for `DALL-E 3` via this service)

**1.4. Vector DB Interaction for RAG/Memory:**
*   (As previously defined and confirmed by PRM) The `LLM Orchestration Service` provides embeddings. The `AgentService` (or the agent's own logic) handles RAG by querying vector databases (like Pinecone) and constructing prompts.

## 2. Shopify Integration Service

This service handles all communications with the Shopify Admin API.

**2.1. Authentication:**
*   OAuth 2.0 Flow, with access tokens stored securely (encrypted at rest, associated with `Brand.shopify_integration_details_json.access_token_secret_ref`).

**2.2. Key Shopify APIs & Data Points:**
*   Comprehensive access based on needs of Agent 004 (Sales Sentinel v2) and Agent 010 (Revenue Tracker Lite v2):
    *   **Orders API:** `read_orders`, `write_orders` (for full data ingestion and potential future actions).
    *   **Products API:** `read_products`, `write_products`, `read_product_listings`.
    *   **Inventory API:** `read_inventory`, `write_inventory`.
    *   **Customers API:** `read_customers`, `write_customers` (handle PII with care).
    *   **Shop API:** `read_shop` (for shop-level settings, currency, timezone).
    *   **Themes API & ScriptTags API:** For `ShopifySalesSentinel` to perform actions like theme rollbacks or script deactivation (requires `write_themes`, `write_script_tags`).
    *   **AppEvents API (Conceptual):** If Shopify provides more granular events about app installs/uninstalls/updates, this would be valuable for `App-Impact Radar` in Agent 004.
    *   **GraphQL Admin API:** Preferred for complex queries and fetching precise data sets.
*   **Required Scopes:** Must be comprehensive, e.g., `read_orders`, `write_orders`, `read_products`, `write_products`, `read_themes`, `write_themes`, `read_script_tags`, `write_script_tags`, `read_customers`, `read_inventory`, etc.

**2.3. Webhook Subscriptions & Kafka Event Forwarding:**
*   Subscribe to a wide array of webhooks: `orders/*`, `products/*`, `themes/publish`, `app/uninstalled`, `shop/update`, `checkouts/*`, `draft_orders/*`.
*   **Critical Change:** All significant webhooks received by `ShopifyIntegrationService` **must** be published to designated Kafka topics (e.g., `ionflux.shopify.workspace_id.entity.action`, like `ionflux.shopify.ws_xyz.orders.created`) using the `PlatformEvent` schema. This is vital for decoupling and enabling real-time processing by agents like Sales Sentinel (004) and Revenue Tracker Lite (010).

**2.4. Data Sync Strategy:**
*   Primarily webhook-driven for real-time updates.
*   Scheduled polling as a fallback or for data not covered by webhooks (e.g., full product catalog sync nightly).

## 3. TikTok Integration Service

Manages interactions with TikTok APIs (Official Developer API, and potentially others if compliant).

**3.1. Authentication:**
*   OAuth 2.0 Flow, tokens stored securely (e.g., in `Brand.tiktok_integration_details_json` or `Creator.tiktok_integration_details_json`).

**3.2. Key TikTok APIs & Data Points:**
*   Align with needs of Agent 003 (TikTok Stylist) and Agent 005 (UGC Matchmaker):
    *   **User Account Info:** `user/info/` (display name, avatar, follower count).
    *   **Video Data:** `video/list/` (for user's own videos), `video/query/` (public videos matching criteria - if available and compliant).
    *   **Research/Discovery APIs (Developer API):** `GET /v2/research/video/query/`, `GET /v2/research/hashtag/query/` for trend analysis and creator discovery.
    *   **Content Publishing API (Future):** If agents need to post content, this would require `video.publish` scope.
*   **Trending Data:** As noted in PRM, direct "trending sounds" API is limited. Rely on research APIs and potentially internal IONFLUX trend detection logic.

**3.3. Permissions (OAuth Scopes):**
*   `user.info.basic`, `video.list`, `research.video.query`, `research.hashtag.query`. Add `video.publish` if content posting becomes a feature.

## 4. Email Dispatch Service (e.g., SendGrid, AWS SES)

*   **Purpose:** Enables agents (Email Wizard, Outreach Automaton, UGC Matchmaker's GhostPitch) and platform notifications to send emails.
*   **Authentication:**
    *   **Platform-Managed Keys:** IONFLUX maintains its own accounts with ESPs (e.g., SendGrid). API keys stored in IONFLUX secrets management.
    *   **Workspace-Provided Keys (Future):** Workspaces can configure their own ESP accounts via `Workspace.settings_json.generic_secrets_config_json` for better deliverability and direct billing.
*   **Key API Functionalities:**
    *   Send single emails (transactional, agent-generated).
    *   Send bulk/batched emails (respecting ESP policies and rate limits).
    *   Webhook processing for delivery status (bounces, spam reports, opens, clicks) - data published to a Kafka topic (e.g., `ionflux.email.delivery_status`).
*   **Responsible IONFLUX Service:** A dedicated **`EmailDispatchService`** is recommended due to the specific nature of email (deliverability, reputation, compliance, webhook handling). It provides an internal API like `POST /v1/emails/send`.

## 5. WhatsApp Integration Service (Meta Cloud API)

*   **Purpose:** Enables agents (WhatsApp Pulse, Outreach Automaton) to use WhatsApp for messaging.
*   **Authentication & Setup:**
    *   **Platform-Level:** IONFLUX acts as a Business Solution Provider (BSP) or partners with one. Requires Meta Business Account, WABA setup, system user tokens, phone number certificates. This is a complex, platform-wide undertaking.
    *   **Workspace Onboarding:** Workspaces connect their WhatsApp Business Phone Numbers via an IONFLUX-managed flow, linking their WABA to IONFLUX's infrastructure. Stored in `Brand.whatsapp_integration_details_json` (conceptual).
*   **Key API Functionalities (Meta Cloud API):**
    *   Send template messages (HSMs).
    *   Send session messages.
    *   Receive incoming messages and status notifications via webhooks (published to Kafka: `ionflux.whatsapp.workspace_id.incoming_message`).
    *   Manage message templates (submission, approval status).
    *   User opt-in/opt-out management.
*   **Responsible IONFLUX Service:** A dedicated **`WhatsAppIntegrationService`** is essential due to the complexity and compliance demands of the WhatsApp Business Platform.

## 6. Vector Database (Pinecone)

*   **Purpose:** Core storage for embeddings used by numerous agents for RAG, semantic search, persona matching, memory (Agents 001, 002, 003, 004, 005, 006, 007, 008, 010 all mention Pinecone or vector DBs).
*   **Management & Authentication:**
    *   **Platform-Managed Resource:** IONFLUX operates a central Pinecone account. API keys are stored in IONFLUX secrets management.
    *   **Interaction Model:**
        *   `AgentService` (or the agent's own runtime environment) uses Pinecone client libraries.
        *   The necessary Pinecone API key is securely passed to the agent's execution environment.
        *   The specific Pinecone **namespace** is resolved by `AgentService` using `AgentDefinition.memory_config_json.default_namespace_template` and `AgentConfiguration.resolved_memory_namespace_text`. This resolved namespace is then used by the agent.
*   **Key Pinecone Client Functionalities Used by Agents:**
    *   `upsert` (vectors with metadata).
    *   `query` (similarity search, by ID, with metadata filters).
    *   `delete` (vectors).
    *   (Less common for agents, more for platform admin) `create_index`, `delete_index`, `describe_index_stats`.
*   **Data Flow for Embeddings:** Typically, `AgentService` calls `LLM Orchestration Service` to generate embeddings, then the agent logic (running under `AgentService`) stores these embeddings in the designated Pinecone namespace.

## 7. Audio Generation & Processing Service (TTS & STT)

*   **Purpose:** Provide centralized Text-to-Speech and Speech-to-Text capabilities for agents.
    *   **TTS:** Agents 002 (WhatsApp Pulse - Voice-Note AI), 007 (Slack Brief Butler - Briefcast Audio) use Azure Speech, ElevenLabs, Coqui TTS.
    *   **STT:** Agents 003 (TikTok Stylist - Whisper), 008 (Creator Persona Guardian - Whisper) use Whisper.
*   **Proposed Service:** A new **`AudioService`** or an expansion of `LLM Orchestration Service` to handle these modalities. Given the diversity of TTS providers and potential for other audio processing tasks (e.g., background noise reduction), a dedicated `AudioService` might offer better focus.
*   **Authentication:** Platform-managed API keys for each TTS/STT provider (Azure, ElevenLabs, OpenAI for Whisper) stored in IONFLUX secrets management.
*   **API Interaction (Conceptual Internal API for `AudioService`):**
    *   **TTS:** `POST /v1/audio/generate-speech`
        *   Request: `{"text": "...", "voice_id": "string (e.g., 'azure_neural_jenny')", "provider_preference": ["azure", "elevenlabs"]}`
        *   Response: `{"audio_url": "...", "duration_seconds": ..., "status": "success"}`
    *   **STT:** `POST /v1/audio/transcribe`
        *   Request: `{"audio_url": "...", "language": "string (e.g., 'en-US')", "provider": "openai_whisper"}`
        *   Response: `{"transcript": "...", "confidence": ..., "status": "success"}`
*   The `LLM Orchestration Service` could still handle Whisper STT if `AudioService` is not created initially, but TTS orchestration is a distinct need.

## 8. Central Event Bus (Apache Kafka)

*   **Role:** Core integration point for asynchronous, decoupled communication between microservices and agents. Essential for scalability and resilience, as highlighted by agents like Shopify Sales Sentinel (004), Badge Motivator (009), and the general event-driven nature of the PRM designs.
*   **Topics:**
    *   A mix of predefined platform topics (e.g., `ionflux.platform.user_activity`) and dynamically provisioned or conventionally named topics for workspaces/agents (e.g., `ionflux.shopify.ws_{workspace_id}.orders`, `ionflux.agent.{agent_id}.ws_{workspace_id}.outputs`).
    *   `Workspace.settings_json.active_kafka_topics_list` might list topics relevant to a specific workspace.
*   **Schema:** Events published to Kafka should adhere to the `PlatformEvent` schema defined in `conceptual_definition_v3.md` (`event_id`, `event_type`, `timestamp`, `source_service_name`, `workspace_id`, `payload_schema_version`, `payload_json`).
*   **Interaction:**
    *   Services and agents act as producers and/or consumers using standard Kafka client libraries (configured with bootstrap server details provided by the platform, possibly via `AgentService` to agent runtimes).
    *   `AgentDefinition.triggers_config_json_array` can specify `event_stream` triggers with Kafka topic details.
    *   `AgentDefinition.outputs_config_json_array` can specify outputs of `type: 'event'` with a `target_event_type` that gets published to Kafka.

## 9. Strategy for Agent-Managed Niche Integrations

Many agents in the PRM leverage specific, niche APIs or tools that may not warrant full, dedicated platform integration services in the initial versions of IONFLUX. These include:

*   **Data Enrichment:** Clearbit, Hunter.io (Agent 006)
*   **Web Scraping/Monitoring:** Playwright, RSSBridge (Agent 006)
*   **Productivity/Collaboration:** Notion API, Jira API, Slack Bolt SDK, Calendly API, Google Calendar, Microsoft Outlook Calendar (Agents 006, 007)
*   **Advertising Platforms:** Meta Ads API, Google Ads API (Agent 010 for cost ingestion - future)
*   **CRMs:** Salesforce API, HubSpot API (Agent 006 for feedback loop)

**General Strategy:**

*   **Agent-Specific Logic:** The primary responsibility for interacting with these niche APIs lies within the agent's own codebase (executed by `AgentService`). Agents will bundle the necessary official client libraries or implement direct API calls.
*   **User-Provided Credentials:**
    *   API keys, tokens, or other necessary credentials for these niche services will be provided by the user/workspace.
    *   These will be stored securely using the mechanism defined in `Workspace.settings_json.generic_secrets_config_json`, which should map user-friendly labels to paths in a central secrets management service (e.g., HashiCorp Vault).
    *   The `AgentService` will securely retrieve these secrets at runtime and make them available to the specific agent's execution environment (e.g., as environment variables or temporary files).
*   **No Dedicated Platform Services (Initially):** IONFLUX will not build dedicated microservices to abstract each of these niche APIs in early versions. The focus is on enabling agents to use them securely.
*   **Prioritize Official APIs:** Agents should always prefer official, stable APIs.
*   **Disclaimer for Unofficial Methods:** If an agent uses unofficial methods (e.g., web scraping via Playwright for LinkedIn data as hinted in Agent 006), this must be:
    *   Clearly documented in the `AgentDefinition.prm_details_json.strategic_integrations_text` or a similar field.
    *   Acknowledged for its potential instability and ethical/ToS considerations.
    *   Designed for resilience against changes.

## 10. Generic Structure for Future SaaS Integrations (Review and Update)

*   **A. Dedicated Microservice (Re-evaluate):** While ideal for deep integrations (Shopify, TikTok, LLMs), this might be overkill for simpler or less frequently used SaaS. The "Agent-Managed Niche Integrations" strategy provides an alternative. A new SaaS integration will first be evaluated if it needs a full service or can be agent-managed.
*   **B. Standardized Configuration & OAuth:** (Still valid) Use `Workspace.settings_json.generic_secrets_config_json` for API keys, and standard OAuth 2.0 flows for user-delegated access where applicable.
*   **C. Secure Credential Storage:** (Still valid) Central secrets management is key.
*   **D. API Abstraction Layer:** (Still valid for dedicated services) Provide a clean internal API. For agent-managed ones, the "abstraction" is within the agent code.
*   **E. Common Error Handling Patterns:** (Still valid) Consistent error reporting.
*   **F. Rate Limiting & Throttling:** (Still valid) Both at API Gateway and within integration services/agents.
*   **G. Webhook Handling Framework:** (Still valid) Standardize ingestion, validation, and forwarding (e.g., to Kafka).
*   **H. Data Transformation & Mapping:** (Still valid) Especially for complex APIs.
*   **I. Monitoring & Logging:** (Still valid) Use the platform's observability stack.
*   **J. Internal Observability vs. External Integrations:** (Still valid as is).
*   **NEW K. Event Publication to Kafka:** For significant events or data changes coming from an external SaaS integration, the integration service (or agent handling it) should publish standardized `PlatformEvent`s to the central Kafka bus to enable other services/agents to react.

This revised specification aims to provide a robust and flexible framework for integrating the diverse range of SaaS platforms and APIs required by the advanced IONFLUX agents.
```
