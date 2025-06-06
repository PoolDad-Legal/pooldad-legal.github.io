# IONFLUX Project: Minimal Viable Shopify Integration Service Specification (v3)

This document provides the V3 specifications for a minimal viable Shopify Integration Service required for the IONFLUX E2E Demo. It aligns with `core_agent_blueprints_v3.md` (especially Agent 004 - Shopify Sales Sentinel), `conceptual_definition_v3.md` (`PlatformEvent` schema, Kafka integration), `saas_api_integration_specs_v3.md`, and `technical_stack_and_demo_strategy_v3.md`. The primary focus is on robust webhook handling and publishing standardized events to Kafka, in addition to the OAuth flow.

**Version Note:** This is v3 of the Shopify Integration Service minimal specification.

**Chosen Technology:** Python with FastAPI (reconfirmed as per `technical_stack_and_demo_strategy_v3.md`).

## 1. Authentication & Initial Setup

### 1.1. `GET /integrations/shopify/auth/initiate`
*   **Purpose:** Initiates the Shopify OAuth 2.0 flow by redirecting the user to Shopify's authorization page.
*   **Protection:** Requires a valid JWT (from User Service) to identify the user and their context. A FastAPI dependency will handle JWT validation.
*   **Query Parameters (as Pydantic model for validation):**
    *   `workspace_id: uuid` (Required): The ID of the workspace to which the Shopify connection will be linked.
    *   `brand_id: uuid` (Required): The ID of the `Brand` entity (within the `workspace_id`) that will store the Shopify connection details.
*   **Response (Success 302 - Found):**
    *   `RedirectResponse` (FastAPI) to the Shopify OAuth authorization URL.
    *   The redirect URL will include:
        *   `client_id`: IONFLUX's Shopify App API Key (from environment variables/config).
        *   `scope`: Requested permissions (e.g., `read_orders,read_products,read_script_tags,write_script_tags,read_themes,write_themes` - expanded for PRM agent needs).
        *   `redirect_uri`: The callback URL for this service (i.e., `/integrations/shopify/auth/callback`).
        *   `state`: A unique, securely generated token. This token should encode or be temporarily linked (e.g., via Redis with TTL) to `workspace_id`, `brand_id`, `user_id`, and a CSRF token.
*   **Brief Logic:**
    1.  JWT Authentication & Authorization: Verify user access to `workspace_id` and `brand_id`.
    2.  State Token Generation: Generate and temporarily store the `state` token with context.
    3.  Construct Shopify OAuth URL.
    4.  Return FastAPI's `RedirectResponse`.

### 1.2. `GET /integrations/shopify/auth/callback`
*   **Purpose:** Handles the callback from Shopify after the user authorizes the application.
*   **Query Parameters (from Shopify, captured as Pydantic model):** `code`, `shop`, `state`, `hmac`.
*   **Response (Success 200 - OK or Redirect to frontend success page):**
    ```json
    {
      "message": "Shopify store connected successfully. Webhooks are being registered.",
      "brand_id": "uuid",
      "shopify_store_url": "string"
    }
    ```
*   **Brief Logic:**
    1.  Validate HMAC and `state` token (retrieve `workspace_id`, `brand_id`, `user_id`).
    2.  Exchange `code` for an access token with Shopify using `client_id` and `client_secret`.
    3.  **Securely Store Token & Details:**
        *   Encrypt the received access token.
        *   Generate a unique `secure_path_identifier` for webhook URLs for this connection.
        *   Retrieve the Shopify shared secret for HMAC validation (if not already available or if it needs to be fetched/confirmed).
        *   Update the `Brand` entity (e.g., via `BrandService` or direct DB update if this service has controlled access to `Brand.shopify_integration_details_json`) with:
            *   `store_url`: `https://{shop}`
            *   `access_token_secret_ref`: Reference to the securely stored encrypted token.
            *   `webhook_secure_path_identifier`: The generated unique identifier.
            *   `shared_secret_ref`: Reference to the securely stored Shopify shared secret.
            *   `last_sync_status`: 'connected'.
            *   `last_sync_timestamp`: `NOW()`.
    4.  **Register Essential Webhooks (Critical V3 Update):**
        *   Asynchronously (e.g., using FastAPI's `BackgroundTasks`), after storing the token and details, initiate a process to register necessary webhooks with the newly connected Shopify store using the obtained access token.
        *   **Webhook Topics:** A configurable list including `orders/create`, `orders/updated`, `orders/paid`, `orders/fulfilled`, `products/create`, `products/update`, `themes/publish`, `app/uninstalled`, `shop/update`, `checkouts/*`, `draft_orders/*`, and others relevant to PRM agents (especially Agent 004).
        *   **Webhook URL:** For each webhook, the URL provided to Shopify must be the new ingestion endpoint (see Section 2.1), e.g., `https://<ionflux_api_domain>/integrations/shopify/webhooks/{secure_path_identifier}`.
    5.  Clean up temporary `state` token.
    6.  Return success message or redirect.

## 2. Shopify Webhook Ingestion & Kafka Event Publishing (Core V3 Functionality)

This section is central to enabling event-driven agent behavior within IONFLUX.

### 2.1. `POST /integrations/shopify/webhooks/{secure_path_identifier}`
*   **Purpose:** Receives incoming webhooks from Shopify for all connected stores. This endpoint must be publicly accessible but secured.
*   **Path Parameter:** `secure_path_identifier` (A unique, unguessable token generated per Shopify store connection during the OAuth callback's webhook registration step. This service must maintain a mapping or be able to look up the `workspace_id`, `brand_id`, and Shopify shared secret using this identifier).
*   **Request Headers (from Shopify):**
    *   `X-Shopify-Topic: string` (e.g., `orders/create`)
    *   `X-Shopify-Hmac-Sha256: string` (HMAC signature)
    *   `X-Shopify-Shop-Domain: string` (e.g., `your-store-name.myshopify.com`)
*   **Request Body:** Raw Shopify webhook payload (JSON).
*   **Response (to Shopify - Synchronous):**
    *   **Success 200 - OK:** Empty body. This must be returned quickly to Shopify to acknowledge receipt.
    *   **Error 400/401/403:** If validation (HMAC, identifier) fails. Shopify might retry on some errors.
*   **Brief Logic:**
    1.  **Identify Source & Retrieve Secrets:** Using `secure_path_identifier`, retrieve the associated `workspace_id`, `brand_id`, and the Shopify shared secret (from secure storage, potentially via `BrandService` or its own datastore). If the identifier is invalid or no matching configuration is found, return 403 Forbidden.
    2.  **Validate Webhook Authenticity:** Verify the `X-Shopify-Hmac-Sha256` signature using the retrieved Shopify shared secret and the raw request body. If invalid, return 401 Unauthorized.
    3.  **Acknowledge Shopify:** Immediately return a 200 OK response to Shopify.
    4.  **Asynchronous Processing (Crucial):** Perform the following steps in a background task (e.g., using FastAPI's `BackgroundTasks` or by pushing to an internal, short-lived, reliable queue like Redis RQ).
        a.  Extract Shopify topic from `X-Shopify-Topic` header.
        b.  **Transform to `PlatformEvent` (as per `conceptual_definition_v3.md`):**
            *   `event_id`: Generate new UUID (e.g., `uuid.uuid4()`).
            *   `event_type`: Construct a standardized IONFLUX event type. Example format: `ionflux.shopify.ws_{workspace_id}.brand_{brand_id}.{entity}.{action}` (e.g., `ionflux.shopify.ws_abc.brand_xyz.orders.created`). The entity/action part can be derived from the Shopify topic.
            *   `event_timestamp`: Use the timestamp from the Shopify webhook if available and reliable, otherwise use current UTC time (`datetime.utcnow().isoformat()`).
            *   `source_service_name`: `"ShopifyIntegrationService"`.
            *   `workspace_id`: The `workspace_id` identified from `secure_path_identifier`.
            *   `payload_schema_version`: e.g., `"v1.shopify.2024-01"` (Reflecting Shopify API version used for webhook).
            *   `payload_json`: The full JSON payload received from the Shopify webhook.
        c.  **Publish to Kafka:**
            *   Publish the created `PlatformEvent` object (serialized as JSON) to a designated Kafka topic.
            *   **Topic Strategy:** As defined in `technical_stack_and_demo_strategy_v3.md`, this will likely be a workspace-specific or even brand-specific topic to allow targeted consumption by agents (e.g., `ionflux.shopify.ws_{workspace_id}.brand_{brand_id}.events_raw` or a more general `ionflux.shopify.events.raw_by_ws.{workspace_id}`). The `AgentDefinition` for agents like Sales Sentinel will specify which topics or event types they consume.
            *   Log success or failure of Kafka publishing for monitoring. If publishing fails, implement a retry mechanism or dead-letter queue.

## 3. API Endpoints for Data Fetching (Optional for E2E Demo)

These endpoints are secondary for the event-driven E2E demo flow but might be used by agents for initial data synchronization or non-event-based data needs.

### 3.1. `GET /integrations/shopify/brands/{brand_id}/shop-details`
*   **Purpose:** An internal endpoint for other IONFLUX services to get basic shop details.
*   **Protection:** Inter-service authentication.
*   **Path Parameter:** `brand_id` (UUID).
*   **Response (Success 200 - OK):**
    ```json
    {
      "brand_id": "uuid",
      "shop_name": "string (Mocked Shopify Store for Demo)",
      "currency": "string (e.g., USD)",
      "domain": "string (e.g., your-store-name.myshopify.com)"
    }
    ```
*   **Brief Logic (Demo):**
    1.  Validate inter-service authentication.
    2.  Retrieve `Brand.shopify_integration_details_json.store_url` for the given `brand_id`.
    3.  Return mocked data, including the `store_url` as domain.
    *   *Production logic would involve decrypting the access token and making a live API call to Shopify's `/admin/api/YYYY-MM/shop.json` endpoint.*

### 3.2. Other Data Fetching Endpoints (Conceptual for Future)
*   Endpoints like `/integrations/shopify/brands/{brand_id}/products` or `/integrations/shopify/brands/{brand_id}/orders` could be implemented for agents needing to pull historical data. These would use the stored, decrypted access token to query the Shopify API. For the E2E demo, these are out of scope; agents will be primarily event-driven or use very limited mocked initial data provided via `AgentConfiguration`.

## 4. Secure Token & Secret Management
*   **Access Tokens & Shared Secrets:** Shopify access tokens and shared secrets (for HMAC validation) are critical credentials.
    *   They are obtained during the OAuth flow.
    *   They are stored encrypted, with references (e.g., paths in a secrets manager like HashiCorp Vault or cloud provider's KMS/Secrets Manager) in `Brand.shopify_integration_details_json`.
*   **Usage:** This service decrypts tokens/secrets in memory only when needed for API calls to Shopify (e.g., registering webhooks, optional data fetching) or for validating incoming webhooks. The raw decrypted values should not be logged extensively.

## 5. Database Interaction
*   This service primarily interacts with the `brands` table (or potentially calls a `BrandService` if direct DB access is restricted) to:
    *   Retrieve `shopify_integration_details_json` (to get `access_token_secret_ref`, `shared_secret_ref`, `webhook_secure_path_identifier`).
    *   Update `shopify_integration_details_json` after OAuth flow (with `store_url`, new token/secret refs, `secure_path_identifier`).
*   It may also manage its own small table mapping `secure_path_identifier` to `workspace_id`, `brand_id`, and `shared_secret_ref` for quick lookups during webhook ingestion, if these are not directly part of the `Brand` entity or if a separate mapping is more performant/secure.

## 6. Framework & Libraries
*   **Framework:** FastAPI.
*   **Key Libraries:**
    *   `uvicorn`: ASGI server.
    *   `SQLAlchemy` (async with `asyncpg`): For any direct database interaction.
    *   `httpx`: Asynchronous HTTP client (for Shopify token exchange & API calls).
    *   `cryptography`: For encrypting/decrypting access tokens and shared secrets.
    *   `python-jose[cryptography]`: For JWT validation (if handling JWTs directly for the `/initiate` endpoint).
    *   `kafka-python` or `confluent-kafka-python`: For publishing events to Kafka.
    *   `pydantic`: For data validation.

This V3 specification for the Shopify Integration Service emphasizes its critical role in the event-driven architecture by robustly handling webhook ingestion and publishing standardized `PlatformEvent`s to Kafka, thereby enabling advanced, reactive agent functionalities as defined in the PRM.
```
