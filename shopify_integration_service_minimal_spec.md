# IONFLUX Project: Minimal Viable Shopify Integration Service Specification (E2E Demo)

This document defines the specifications for a minimal viable Shopify Integration Service shell required for the IONFLUX E2E Demo. Its primary focus is to handle the Shopify OAuth 2.0 flow to connect a Brand's Shopify store and securely store the resulting access token. Actual Shopify API interactions post-authentication will be minimal or mocked for this demo.

**Chosen Technology:** Python with FastAPI (as per `technical_stack_and_demo_strategy.md`).

## 1. API Endpoints (RESTful)

### 1.1. `GET /integrations/shopify/auth/initiate`

*   **Purpose:** Initiates the Shopify OAuth 2.0 flow by redirecting the user to Shopify's authorization page.
*   **Protection:** Requires a valid JWT (from User Service) to identify the user and their context. A FastAPI dependency will handle JWT validation.
*   **Query Parameters (as Pydantic model for validation):**
    *   `workspaceId: uuid` (Required): The ID of the workspace to which the Shopify connection will be linked.
    *   `brandId: uuid` (Required): The ID of the `Brand` entity (within the `workspaceId`) that will store the Shopify connection details.
*   **Response (Success 302 - Found):**
    *   `RedirectResponse` (FastAPI) to the Shopify OAuth authorization URL.
    *   The redirect URL will include:
        *   `client_id`: IONFLUX's Shopify App API Key (from environment variables/config).
        *   `scope`: Requested permissions (e.g., `read_orders,read_products` - defined in config, minimal for demo).
        *   `redirect_uri`: The callback URL for this service (i.e., `/integrations/shopify/auth/callback`).
        *   `state`: A unique, securely generated token. This token should encode or be temporarily linked (e.g., via Redis with TTL) to `workspaceId`, `brandId`, and a CSRF token.
*   **Response (Error 400 - Bad Request):** If `workspaceId` or `brandId` is missing or invalid.
*   **Response (Error 401 - Unauthorized):** If JWT is missing or invalid.
*   **Response (Error 403 - Forbidden):** If the authenticated user does not have access to the provided `workspaceId` or `brandId`.
*   **Brief Logic:**
    1.  **JWT Authentication & Authorization:**
        *   FastAPI dependency validates JWT and extracts `user_id`.
        *   Verify user has permissions for `workspaceId` (e.g., by calling Workspace Service or checking DB - for demo, checking if `Brands.workspace_id` matches and `Workspaces.owner_user_id` matches `user_id` might be done directly if DB access is consolidated for simplicity).
        *   Verify `brandId` belongs to `workspaceId`.
    2.  **State Token Generation:** Generate a unique `state` token. Store this token temporarily (e.g., in Redis with a short TTL, or a simple DB table `OAuthStateStore`) mapping it to `{'workspace_id': workspaceId, 'brand_id': brandId, 'user_id': user_id}`. The `state` token itself should be unguessable.
    3.  **Construct Shopify OAuth URL:** Build the URL using Shopify App credentials (from config/env vars) and the generated `state`.
    4.  Return FastAPI's `RedirectResponse`.

### 1.2. `GET /integrations/shopify/auth/callback`

*   **Purpose:** Handles the callback from Shopify after the user authorizes the application.
*   **Query Parameters (provided by Shopify, captured as Pydantic model):**
    *   `code: str` (Authorization code from Shopify).
    *   `shop: str` (The user's Shopify store URL, e.g., `your-store-name.myshopify.com`).
    *   `state: str` (The state token originally sent by this service).
    *   `hmac: str` (Hash-based message authentication code).
*   **Response (Success 200 - OK):**
    ```json
    {
      "message": "Shopify store connected successfully.",
      "brand_id": "uuid",
      "shopify_store_url": "string"
    }
    ```
    *   *Alternatively, this endpoint can redirect to a success page on the frontend (e.g., `https://<frontend_url>/integrations/success?type=shopify`).*
*   **Response (Error 400 - Bad Request):**
    *   If `state` is missing, invalid, or doesn't match/is expired.
    *   If `hmac` validation fails.
    *   If `code` or `shop` is missing.
*   **Response (Error 500 - Internal Server Error):**
    *   If exchanging the `code` for an access token fails, or during token storage/encryption.
*   **Brief Logic:**
    1.  **Validate HMAC:** Verify the authenticity of the request using Shopify's HMAC validation logic.
    2.  **Validate State:** Retrieve the stored context (e.g., `workspaceId`, `brandId`, `user_id`) using the received `state` parameter. If not found or expired, return error. Clean up the state token after retrieval.
    3.  **Exchange Code for Access Token:** Make an async POST request (using `httpx`) to Shopify's `/admin/oauth/access_token` endpoint with `client_id`, `client_secret` (from config/env vars), and the `code` to obtain the permanent access token for the shop.
    4.  **Securely Store Access Token:**
        *   Encrypt the received access token using a strong encryption method (e.g., Fernet from `cryptography` library). The encryption key **must** be managed via a secrets manager in production (for demo, can be a hardcoded env var noted for replacement).
        *   Update the `Brands` table in the database: Store the encrypted access token in `shopify_access_token` and the `shop` URL (formatted as `https://{shop}`) in `shopify_store_url` for the `brandId` retrieved from the state.
    5.  **(Optional for Demo) Test API Call:** Asynchronously, make a simple GET request to `https://{shop}/admin/api/YYYY-MM/shop.json` to confirm token validity. Log any errors but don't necessarily fail the connection for the demo if this optional call fails.
    6.  Clean up the temporary `state` token.
    7.  Return a success message or redirect to a frontend success page.

### 1.3. (Optional for Demo - Internal) `GET /integrations/shopify/brands/{brandId}/shop-details`

*   **Purpose:** An internal endpoint for other IONFLUX services (like Agent Service) to get basic shop details, primarily to confirm connectivity or fetch display information.
*   **Protection:** Inter-service authentication (e.g., shared API key in header, validated by a FastAPI dependency).
*   **Path Parameter:** `brandId` (UUID of the brand).
*   **Response (Success 200 - OK):**
    ```json
    {
      "brand_id": "uuid",
      "shop_name": "string", // e.g., "Your Awesome Store"
      "currency": "string"   // e.g., "USD"
    }
    ```
*   **Response (Error 401/403 - Unauthorized/Forbidden):** If inter-service auth fails.
*   **Response (Error 404 - Not Found):** If `brandId` is not found or has no Shopify connection.
*   **Brief Logic:**
    1.  Validate inter-service authentication.
    2.  Retrieve the `brandId`'s `shopify_access_token` (encrypted) and `shopify_store_url` from the `Brands` table.
    3.  If no token/URL, return 404.
    4.  Decrypt the access token.
    5.  **For Demo:** Return canned/mocked data like `{"brand_id": brandId, "shop_name": "Mocked Shopify Store", "currency": "USD"}`. This avoids making a live API call during the demo unless specifically showcasing this.
        *   *Production Logic: Make an authenticated GET request to `https://{shopify_store_url}/admin/api/YYYY-MM/shop.json` using the decrypted token. Parse and return relevant fields.*
    6.  Return the shop details.

## 2. Core Logic (Simplified for Demo)

*   **JWT Authentication (for `/initiate`):** FastAPI dependency using `python-jose[cryptography]`.
*   **Shopify OAuth 2.0 Flow:**
    *   **HMAC Validation:** Implement Shopify's HMAC validation algorithm using Python's `hmac` and `hashlib` modules.
    *   **State Management:** For demo, a simple dictionary acting as an in-memory store with TTL, or a small SQLite table if persistence across restarts is desired for local dev. Redis is a good production choice.
    *   **Token Exchange:** Use `httpx` for making the async POST request.
*   **Token Encryption:**
    *   **Library:** `cryptography` (Fernet symmetric encryption).
    *   **Key Management:** Use an environment variable for the encryption key for the demo. **This MUST be replaced with a key fetched from a secure secrets manager in production.**
*   **Database Interaction:**
    *   **ORM/Driver:** SQLAlchemy (core or ORM) with `asyncpg` for asynchronous PostgreSQL access.
    *   **Operations:** `SELECT` to get brand details, `UPDATE` to store `shopify_store_url` and encrypted `shopify_access_token`.

## 3. Framework & Libraries

*   **Framework:** FastAPI
*   **Key Libraries:**
    *   `fastapi`: Web framework.
    *   `uvicorn`: ASGI server.
    *   `SQLAlchemy` (asyncio support with `asyncpg`): For database interaction.
    *   `psycopg2-binary` (or `asyncpg` directly): PostgreSQL driver.
    *   `python-jose[cryptography]`: For JWT validation (if this service validates tokens directly, or relies on API Gateway).
    *   `httpx`: Asynchronous HTTP client (for Shopify token exchange & API calls).
    *   `cryptography`: For encrypting/decrypting access tokens.
    *   `itsdangerous` or similar for signed temporary state tokens (alternative to DB/Redis for state).
    *   `pydantic`: For data validation (comes with FastAPI).

This specification outlines a Shopify Integration Service focused primarily on the OAuth connection flow, which is critical for the E2E demo. Post-connection API calls are minimized or mocked to simplify the initial demo build.
```
