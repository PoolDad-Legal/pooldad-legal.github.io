# IONFLUX Project: SaaS/API Integration Specifications

This document details the specifications for integrating third-party SaaS platforms and APIs into the IONFLUX ecosystem, focusing on the initial set required for beta. It builds upon the `conceptual_definition.md` and `ui_ux_concepts.md`.

## 1. LLM Provider Integration (`LLM Orchestration Service`)

The `LLM Orchestration Service` will act as a central hub for all Large Language Model interactions, providing a unified interface for other IONFLUX services.

**1.1. Primary Provider Choice (for Beta):**

*   **Recommendation:** **OpenAI**
*   **Justification:**
    *   **Mature API:** OpenAI offers a well-documented, robust, and feature-rich API.
    *   **Model Variety & Capability:** Access to a wide range of models (e.g., GPT-3.5-turbo, GPT-4, Embeddings) suitable for diverse tasks outlined in the IONFLUX proposal.
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
      "provider": "string (e.g., 'openai', 'claude', 'gemini', defaults to 'openai')", // Optional, defaults to primary
      "model": "string (e.g., 'gpt-3.5-turbo', 'claude-2', 'gemini-pro')", // Specific model identifier
      "prompt": "string", // The actual prompt text
      "system_prompt": "string (optional)", // System-level instructions for the model
      "history": [ // Optional: for conversational context
        { "role": "user", "content": "Previous message" },
        { "role": "assistant", "content": "Previous response" }
      ],
      "parameters": { // Model-specific parameters
        "max_tokens": "integer (optional)",
        "temperature": "float (optional, 0.0-2.0)",
        "top_p": "float (optional, 0.0-1.0)",
        "stop_sequences": ["string (optional)"],
        // ... other provider-specific parameters
      },
      "user_id": "string (UUID, references User.id, for tracking/auditing/cost-attribution)",
      "workspace_id": "string (UUID, references Workspace.id, for policy/key selection)",
      "request_id": "string (UUID, for logging and tracing)" // Added for better traceability
    }
    ```

*   **Response from `LLM Orchestration Service`:**
    *   **Success:**
        ```json
        {
          "status": "success",
          "request_id": "string (UUID, mirrors request)",
          "provider_response": { // Raw or lightly processed response from the LLM provider
            "id": "string (provider's response ID)",
            "choices": [
              {
                "text": "string (generated text)", // Or "message": {"role":"assistant", "content":"..."} for chat models
                "finish_reason": "string (e.g., 'stop', 'length', 'content_filter')"
                // ... other provider-specific choice data
              }
            ],
            "usage": { // Standardized usage information
              "prompt_tokens": "integer",
              "completion_tokens": "integer",
              "total_tokens": "integer"
            }
            // ... other provider-specific metadata
          }
        }
        ```
    *   **Error:**
        ```json
        {
          "status": "error",
          "request_id": "string (UUID, mirrors request)",
          "error": {
            "code": "string (internal error code, e.g., 'PROVIDER_API_ERROR', 'INVALID_REQUEST', 'QUOTA_EXCEEDED')",
            "message": "string (user-friendly error message)",
            "provider_error": "object (optional, raw error from LLM provider if available)"
          }
        }
        ```

## 2. Shopify Integration (`Shopify Integration Service`)

This service will handle all communications with the Shopify platform.

**2.1. Authentication:**

*   **Flow:** Standard **OAuth 2.0 Authorization Code Grant Flow**.
    1.  User (Brand owner/admin) initiates connection from IONFLUX (e.g., in Brand settings).
    2.  IONFLUX redirects the user to their Shopify store's authorization prompt (`https://{store_name}.myshopify.com/admin/oauth/authorize?...`).
        *   Parameters: `client_id` (IONFLUX's Shopify App API key), `scope` (requested permissions), `redirect_uri` (back to `Shopify Integration Service`), `state` (CSRF token).
    3.  User approves the installation/scopes on Shopify.
    4.  Shopify redirects back to `redirect_uri` with an `authorization_code` and the `shop` name.
    5.  `Shopify Integration Service` exchanges the `authorization_code` (along with API key/secret) for an **access token** from Shopify (`https://{store_name}.myshopify.com/admin/oauth/access_token`).
*   **Access Token Storage:**
    *   The permanent access token received from Shopify will be stored securely.
    *   It will be associated with the `Brand.id` (or a dedicated `ShopifyConnection` entity linked to the Brand).
    *   Storage method: Encrypted (e.g., AES-256) in the database. The encryption key will be managed by a central secrets management service.
*   **Token Usage:** The stored access token will be used in the `X-Shopify-Access-Token` header for all subsequent API requests to that Shopify store.

**2.2. Key Shopify APIs & Data Points:**

*   **Admin API (primarily REST, some GraphQL if beneficial):**
    *   **Products:** `GET /admin/api/2023-10/products.json`
        *   Fields: `id`, `title`, `handle`, `status`, `vendor`, `product_type`, `created_at`, `updated_at`, `tags`, `variants` (price, sku), `images`.
    *   **Orders:** `GET /admin/api/2023-10/orders.json` (need to be careful with PII)
        *   Fields for `Revenue Tracker Lite`: `id`, `name`, `created_at`, `total_price`, `financial_status`, `fulfillment_status`, `currency`, `line_items` (product_id, quantity, price).
        *   Fields for `Shopify Sales Sentinel`: Order status changes, new orders.
    *   **Customers:** `GET /admin/api/2023-10/customers.json` (handle PII carefully, only fetch if essential for an agent's function).
        *   Fields: `id`, `email`, `first_name`, `last_name`, `orders_count`, `total_spent`.
    *   **Shop:** `GET /admin/api/2023-10/shop.json`
        *   Fields: `id`, `name`, `currency`, `domain`, `iana_timezone`.
    *   **Webhooks:** `POST /admin/api/2023-10/webhooks.json`, `GET /admin/api/2023-10/webhooks.json`, `DELETE /admin/api/2023-10/webhooks/{webhook_id}.json`.
    *   **Discount Codes:** (Future consideration for agents that might create discounts) `GET /admin/api/2023-10/price_rules.json`, `POST /admin/api/2023-10/price_rules/{price_rule_id}/discount_codes.json`.
*   **Storefront GraphQL API:**
    *   May not be essential for Beta if Admin API covers needs. Could be used for less sensitive, publicly accessible data if an agent needs to see the store "as a customer."
    *   Example: Fetching product details, collections for display or analysis without needing full admin rights.
*   **Data for `Shopify Sales Sentinel` & `Revenue Tracker Lite`:**
    *   `Revenue Tracker Lite`: Primarily aggregated sales data (total sales, average order value, sales over time) from `Orders`. Product performance (sales per product) from `Orders` and `Products`.
    *   `Shopify Sales Sentinel`: Real-time or near real-time notification of new sales, significant order values, inventory changes for key products. This heavily relies on webhooks or frequent polling of `Orders` and `Products`.

**2.3. Webhook Subscriptions:**

The `Shopify Integration Service` will dynamically subscribe to these webhooks for each connected store. The webhook endpoint will be a dedicated route within the `Shopify Integration Service`.

*   `orders/create`: Triggered when a new order is created. (Essential for Sales Sentinel)
*   `orders/updated`: Triggered when an order is updated (e.g., payment status, fulfillment). (Essential for Sales Sentinel)
*   `orders/paid`: Triggered when an order is marked as paid.
*   `orders/fulfilled`: Triggered when an order is fulfilled.
*   `products/create`: Triggered when a new product is created.
*   `products/update`: Triggered when a product is updated (e.g., inventory, price). (Important for Sales Sentinel if tracking specific products)
*   `app/uninstalled`: CRITICAL. Triggered when the user uninstalls the IONFLUX app from their Shopify store. The service must:
    *   Invalidate/delete the stored access token.
    *   Clean up any associated data for that store.
    *   Notify the user/workspace within IONFLUX.
*   `shop/update`: For changes in shop settings like currency.

**2.4. Data Sync Strategy:**

*   **Primary Method: Webhooks.** For near real-time updates (e.g., `orders/create`, `products/update`), webhooks are preferred. This makes agents like `Shopify Sales Sentinel` responsive.
*   **Secondary Method: Polling.** For initial data backfill upon connection, or for data not covered by webhooks, periodic polling will be used.
    *   Frequency will depend on the data type and importance (e.g., orders might be polled more frequently than general product catalog updates if webhooks fail).
    *   Implement intelligent polling to respect Shopify API rate limits (use leaky bucket algorithm).
*   **Data Freshness:**
    *   For event-driven agents (Sales Sentinel): As real-time as webhooks allow.
    *   For analytical agents/blocks (Revenue Tracker Lite): Can tolerate some delay (e.g., updated every few hours or on-demand refresh). Canvas blocks displaying Shopify data should indicate the last sync time.
*   The `Shopify Integration Service` will need a robust queueing and processing mechanism for incoming webhooks to handle bursts and ensure reliability.

## 3. TikTok Integration (`TikTok Integration Service`)

This service will manage interactions with TikTok APIs.

**3.1. Authentication:**

*   **Flow:** Standard **OAuth 2.0 Authorization Code Grant Flow** provided by TikTok.
    1.  User (Brand/Creator) initiates connection from IONFLUX.
    2.  IONFLUX redirects user to TikTok's OAuth server.
        *   Parameters: `client_key` (IONFLUX's TikTok App ID), `scope`, `redirect_uri`, `state`.
    3.  User logs in and authorizes requested permissions on TikTok.
    4.  TikTok redirects back to `redirect_uri` with an `authorization_code`.
    5.  `TikTok Integration Service` exchanges the `code` for an `access_token`, `refresh_token`, and `open_id` (user identifier).
*   **Access Token Storage:**
    *   `access_token`, `refresh_token`, `expires_in`, and `open_id` stored securely, associated with the `Brand.id` or `Creator.id`.
    *   Storage: Encrypted in the database, encryption key managed by secrets service.
*   **Token Refresh:** The service must implement logic to use the `refresh_token` to obtain new `access_token`s before they expire.

**3.2. Key TikTok APIs & Data Points:**

*   **API Choice:**
    *   **TikTok for Business API (Marketing API):** More focused on advertising and campaign management. May be useful for some agents but has stricter access requirements.
    *   **TikTok Developer API / TikTok Login Kit:** More suitable for general data access, content posting (if available to app type), and user profile information. **This is likely the primary API for beta features.**
    *   Clarity on which specific API IONFLUX applies for and gets approved for is crucial, as capabilities differ.
*   **Data for `TikTok Stylist`:**
    *   **Trending Content:**
        *   `GET /v2/research/video/query/` (from TikTok Developer API - if approved for research capabilities): To search for videos by keywords, hashtags, potentially identify trending sounds used in those videos.
        *   Manual or semi-automated tracking of TikTok's public "Trending" sections might be needed as a fallback or supplement, as direct "trending sounds" APIs can be limited.
    *   **Hashtags:**
        *   `GET /v2/research/hashtag/query/` (Developer API): Search for hashtags, get view counts, related videos.
*   **Data for `UGC Matchmaker`:**
    *   **Creator Search:**
        *   TikTok's APIs for direct "creator search" by niche or detailed demographics are very limited for third-party apps due to privacy.
        *   `GET /v2/user/info/` (Developer API, with `user.info.basic` scope): To get public profile information for a *specific user* once identified (e.g., if a creator connects their account or is mentioned). Fields: `open_id`, `username`, `avatar_url`, `follower_count`, `following_count`, `likes_count`, `video_count`.
        *   This agent might rely more on creators connecting their profiles to IONFLUX, or users manually inputting potential creator handles for analysis.
*   **Content Upload (as per proposal):**
    *   `POST /v2/video/upload/` (Developer API, requires `video.upload` scope and specific app approval).
    *   `POST /v2/video/publish/` (Developer API, requires `video.publish` scope).
    *   Will need to handle video file uploads, titles, descriptions, privacy settings.
*   **Insights (as per proposal):**
    *   `GET /v2/user/video/list/` (Developer API, requires `video.list` scope): Get list of user's own videos.
    *   `GET /v2/video/query/` (Developer API, with `video.list.beta` for their own videos): Get analytics for specific videos (views, likes, comments, shares, engagement rate, audience demographics if available for that video). Requires `user.video.insights` or similar advanced scope. Access to detailed video analytics is often restricted.

**3.3. Permissions (OAuth Scopes - TikTok Developer API example):**

IONFLUX will request scopes incrementally based on features used by the user/workspace.

*   **Basic:** `user.info.basic` (to get basic profile info of the connecting user).
*   **Content Viewing (Own):** `video.list` (to see user's own videos).
*   **Content Upload:** `video.upload`, `video.publish` (requires special permission from TikTok).
*   **Insights (Own Content):** `video.insights` (or equivalent for video analytics, requires special permission).
*   **Research (Public Content):** `research.video.query`, `research.hashtag.query` (requires special permission and adherence to research guidelines).

**3.4. Content Moderation/Compliance:**

*   All content generation (via `TikTok Stylist`) or uploads must adhere to TikTok's Community Guidelines and Terms of Service.
*   IONFLUX should not facilitate the creation or posting of prohibited content.
*   The `TikTok Integration Service` should implement error handling for API responses indicating policy violations (e.g., content takedowns, upload failures due to moderation).
*   Consider adding disclaimers to users about responsible content creation.

## 4. Generic Structure for Future SaaS Integrations

To ensure scalability and maintainability as IONFLUX integrates more SaaS platforms.

*   **A. Dedicated Microservice per Major Integration:**
    *   Each new complex SaaS integration (e.g., Instagram, YouTube, Google Ads) should have its own dedicated microservice (e.g., `InstagramIntegrationService`).
    *   This isolates dependencies, allows for independent scaling, and permits technology choices best suited for that specific API.
    *   Simpler integrations might be grouped if their domains are very similar and APIs are lightweight.

*   **B. Standardized Configuration Management:**
    *   A consistent way to store and manage API keys, client IDs/secrets, and other configuration details for each integration.
    *   Leverage the central secrets management service.
    *   Workspace-level or Brand/Creator-level overrides for configurations where users bring their own accounts/keys.
    *   A common interface or library within IONFLUX for services to request credentials for a specific integration and user/workspace.

*   **C. Common OAuth 2.0 Handling Library/Module:**
    *   Develop a shared library to handle the common parts of the OAuth 2.0 flow (redirect generation, state management, token exchange, token refresh, secure storage) to reduce boilerplate for new integrations.

*   **D. Standardized Internal API Contracts:**
    *   While the external APIs are unique, the internal APIs that other IONFLUX services use to interact with these integration services should follow a somewhat standardized pattern for requesting data or actions.
    *   Example: A common way to request "get data for resource X" or "post data Y to resource Z".
    *   This simplifies how `Agent Service` or `Canvas Service` consume these integrations.

*   **E. Unified Error Handling and Reporting:**
    *   Common error codes and structures for issues arising from integrations (e.g., API key invalid, permissions denied, rate limit exceeded, SaaS provider outage).
    *   Centralized logging and monitoring for integration health.
    *   Consistent feedback to the user regarding integration failures.

*   **F. Webhook Ingestion and Processing Framework:**
    *   If many integrations rely on webhooks, a common framework or set of tools for ingesting, validating, queueing, and reliably processing incoming webhooks.
    *   This includes security considerations like signature verification.

*   **G. Data Mapping and Transformation Layer:**
    *   A clear layer or set of patterns for mapping data from the external SaaS API's format to IONFLUX's internal data models (e.g., mapping a Shopify Product to a generic Product concept if needed by an agent).

*   **H. Incremental Scope Requests:**
    *   For all integrations, request the minimum necessary permissions (scopes) initially and ask for more only when the user tries to use a feature that requires them. This builds user trust.

*   **I. Clear Documentation and Developer Guidelines:**
    *   For internal developers adding new integrations, clear guidelines on these principles, security best practices, and how to use shared libraries.
```
