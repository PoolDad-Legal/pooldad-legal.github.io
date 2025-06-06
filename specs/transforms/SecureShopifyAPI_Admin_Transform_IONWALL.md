# Transform Specification: SecureShopifyAPI_Admin_Transform_IONWALL

## 1. Overview
*   **Transform Name:** `SecureShopifyAPI_Admin_Transform_IONWALL`
*   **Version:** 0.9.0
*   **Type:** External API Integration / Plugin (Specialized for Shopify Admin API)
*   **Primary Goal:** Securely executes requests against the Shopify Admin API on behalf of the user for a specific, pre-configured Shopify store. It manages authentication (e.g., API access tokens fetched via IONWALLET mediation through IONWALL), request construction based on a predefined set of supported Shopify actions, and response parsing. All operations require IONWALL consent for both the action itself and the use of stored credentials.
*   **Key Features:**
    *   Supports a defined, audited subset of Shopify Admin API endpoints/methods (e.g., get product, update inventory, create order, list customers). The exact list is defined in a manifest.
    *   Handles Shopify API authentication by requesting access tokens or necessary credentials through an IONWALL-IONWALLET interaction flow. Credentials are *not* directly exposed to the agent's FluxGraph logic or this transform's direct configuration.
    *   IONWALL interaction for obtaining user consent for specific Shopify actions (e.g., "Allow Agent X to update inventory for product Y on your Shopify store Z?").
    *   Parses Shopify API JSON responses into a standardized output object.
    *   Manages Shopify API rate limit information transparently.
    *   Intended to be used as a "Plugin Transform" typically invoked by a routing agent like `Symbiosis Plugin Agent`.

## 2. Conceptual I/O ABI (Application Binary Interface)
### Input Schema (Conceptual JSON)
```json
{
  "type": "object",
  "properties": {
    "shopify_store_context_cid": {
      "type": "string",
      "description": "Required. CID of an IONPOD object containing user's Shopify store URL (e.g., 'your-store.myshopify.com') and a reference/identifier for the API credential managed by IONWALLET for this store."
    },
    "shopify_api_action_key": {
      "type": "string",
      "description": "A key representing the target Shopify Admin API action (e.g., 'PRODUCTS_GET_SINGLE', 'INVENTORY_LEVELS_ADJUST', 'ORDERS_CREATE'). This key maps to a pre-defined request structure (endpoint, HTTP method, expected parameters) within the transform, ideally loaded from a manifest."
    },
    "request_parameters": {
      "type": "object",
      "additionalProperties": true,
      "nullable": true,
      "description": "Parameters required by the Shopify API for the specified 'shopify_api_action_key' (e.g., for 'PRODUCTS_GET_SINGLE', this might be { 'product_id': '12345' }; for 'INVENTORY_LEVELS_ADJUST', it might be { 'inventory_item_id': '67890', 'location_id': '1122', 'available_adjustment': -5 })."
    },
    "shopify_api_version_override": {
      "type": "string",
      "nullable": true,
      "description": "Optional Shopify API version string (e.g., '2024-01') to override the transform's default. Use with caution."
    }
  },
  "required": ["shopify_store_context_cid", "shopify_api_action_key"]
}
```
### Output Schema (Conceptual JSON)
```json
{
  "type": "object",
  "properties": {
    "shopify_response_data": {
      "type": "object", // Or array, depending on the Shopify endpoint
      "additionalProperties": true,
      "nullable": true,
      "description": "Parsed JSON data from the Shopify API response body. The structure varies based on the API endpoint called."
    },
    "http_status_code": {
      "type": "integer",
      "description": "HTTP status code returned by the Shopify API (e.g., 200, 201, 400, 401, 403, 404, 429)."
    },
    "rate_limit_info": {
      "type": "object",
      "nullable": true,
      "properties": {
        "calls_made_this_request": { "type": "integer", "description": "Typically 1, but can be more for complex actions that internally make multiple calls (though this transform aims for 1 external call per invocation)." },
        "calls_remaining_bucket": { "type": "integer", "description": "Calls remaining in the current rate limit bucket for the API key." },
        "bucket_size_total": { "type": "integer", "description": "Total size of the rate limit bucket." },
        "retry_after_seconds": { "type": "number", "nullable": true, "description": "If rate limited (HTTP 429), seconds to wait before retrying." }
      },
      "description": "Information parsed from Shopify's rate limit response headers (e.g., X-Shopify-Shop-Api-Call-Limit)."
    },
    "status": {
      "type": "string",
      "enum": ["success", "failure_ionwall_denied", "failure_credential_error", "failure_shopify_api_error", "failure_shopify_rate_limit", "failure_network_error", "failure_unsupported_action", "failure_config_error"],
      "description": "Overall status of the transform's execution."
    },
    "error_message": {
      "type": "string",
      "nullable": true,
      "description": "Concise error message summarizing the issue if status is not 'success'."
    },
    "error_details_from_shopify": {
      "type": "object", // Or string, depending on Shopify error format
      "additionalProperties": true,
      "nullable": true,
      "description": "Detailed error object/message directly from Shopify API response body if an error occurred."
    }
  },
  "required": ["status", "http_status_code"]
  // shopify_response_data is typically required on success, but nullable if an API call returns no body (e.g., 204 No Content).
}
```

## 3. Configuration Parameters (Conceptual)
*(System-level settings for the transform instance)*

*   `ionwall_interaction_service_cid`: CID of config for IONWALL communication.
*   `ionwallet_referral_service_cid`: CID of config for how this transform requests credential access via IONWALL, which then refers to IONWALLET.
*   `default_shopify_api_version`: Default Shopify API version string (e.g., "2024-04") targeted by this transform instance.
*   `supported_actions_manifest_cid`: Required. CID of an IONPOD object (e.g., JSON file) that explicitly defines:
    *   Each supported `shopify_api_action_key`.
    *   Its corresponding HTTP method (GET, POST, PUT, DELETE).
    *   The Shopify Admin API endpoint path template (e.g., `/admin/api/{api_version}/products/{product_id}.json`).
    *   Required and optional parameters for `request_parameters`.
    *   Expected successful HTTP status codes.
    *   A brief description of the action for potential use in IONWALL consent dialogs.
*   `default_retry_policy_on_rate_limit_cid`: Optional CID of a config object defining retry behavior if a 429 (rate limit) is encountered (e.g., `{ "max_retries": 1, "initial_backoff_ms_from_header": true }`). Retries must still respect overall FluxGraph execution timeouts.
*   `http_client_config_cid`: CID of config for the underlying HTTP client (timeouts, TLS settings, proxy if any).

## 4. Detailed Logic Flow & IONWALL Interaction
1.  **Input Validation:** Transform receives input. Validates `shopify_store_context_cid` and `shopify_api_action_key` are present.
2.  **Fetch Store Context:** Internally uses `FetchFromIONPOD_Transform_IONWALL` to fetch the content of `shopify_store_context_cid`. This object should contain the Shopify store URL (e.g., `my-shop.myshopify.com`) and an identifier for the credential set managed by IONWALLET (e.g., `my_shopify_main_store_api_key_ref`). This fetch requires its own IONWALL scope.
3.  **Load Action Manifest:** Fetches and parses the `supported_actions_manifest_cid` to get details for the requested `shopify_api_action_key` (HTTP method, path template, required params). If action key not found, return `failure_unsupported_action`.
4.  **IONWALL Consent for Shopify Action & Credential Use:**
    *   Constructs a request for IONWALL, specifying:
        *   The `ionwall_approval_scope` from the FluxGraph node (e.g., `shopify_admin:products:read:store_XYZ`).
        *   `requesting_agent_id`.
        *   Details of the Shopify action to be performed (from manifest and `request_parameters`).
        *   The Shopify store URL (from store context).
        *   The credential identifier (from store context) that IONWALLET needs to use.
    *   IONWALL presents this to the user: *"Agent '[Agent Name]' wants to '[Action Description, e.g., Get Product Details]' for product '[Product ID if any]' on your Shopify store '[Store URL]'. This requires using your stored Shopify API credentials. Allow?"*
    *   If user denies: Output `failure_ionwall_denied`.
5.  **Secure Credential Acquisition (Mediated by IONWALL/IONWALLET):**
    *   If user approves in IONWALL, IONWALL (using `ionwallet_referral_service_cid` logic) signals IONWALLET to provide an access token or perform the signing for the request.
    *   **Crucially, IONWALLET does not return the raw API key to this transform or IONWALL.** Instead, IONWALLET might:
        *   Return a short-lived, narrowly-scoped OAuth token if Shopify supports it for this type of access.
        *   Require the request to be passed to it, sign it internally, and return the signed request for this transform to dispatch.
        *   Instruct an IONFLUX Controller service (acting as a secure proxy) to make the call using the credential, and this transform communicates with that proxy.
    *   If credential acquisition fails (e.g., user denies in IONWALLET, credential revoked): Output `failure_credential_error`.
6.  **Construct Shopify API Request:**
    *   Uses the API version (override or default).
    *   Builds the full URL using the store URL, API version, and path template from the manifest, populating path parameters from `request_parameters`.
    *   Prepares HTTP headers (including the acquired Authorization token, `Content-Type: application/json`, etc.).
    *   Serializes the appropriate part of `request_parameters` as the JSON request body (for POST, PUT).
7.  **Execute HTTP Request:** Makes the HTTP call to the Shopify Admin API using the configured HTTP client.
8.  **Process Shopify Response:**
    *   Parses the HTTP status code and response body (expected to be JSON).
    *   Extracts rate limit information from response headers (`X-Shopify-Shop-Api-Call-Limit`).
    *   If HTTP status indicates success (e.g., 200, 201 based on manifest): Set `status: "success"`, populate `shopify_response_data`.
    *   If HTTP 401/403: Set `status: "failure_shopify_api_error"` (or `failure_authentication` if distinguishable), populate `error_details_from_shopify`.
    *   If HTTP 429: Set `status: "failure_shopify_rate_limit"`. Handle retries if configured (within overall timeout).
    *   For other error codes: Set `status: "failure_shopify_api_error"`, populate `error_details_from_shopify`.
    *   If network error: Set `status: "failure_network_error"`.
9.  **Return Output:** Package and return the output object.

## 5. Error Handling
*   `failure_ionwall_denied`: User denied consent via IONWALL for the Shopify action or credential use.
*   `failure_credential_error`: IONWALLET could not provide/use the necessary Shopify API credentials (e.g., not found, revoked, user denied in IONWALLET UI).
*   `failure_shopify_api_error`: Shopify API returned an error (e.g., 400 Bad Request, 403 Forbidden, 404 Not Found, 5xx Server Error). `error_details_from_shopify` will contain specifics.
*   `failure_shopify_rate_limit`: Shopify API returned HTTP 429, indicating rate limit exceeded.
*   `failure_network_error`: Network issue communicating with Shopify API.
*   `failure_unsupported_action`: The provided `shopify_api_action_key` is not defined in the transform's `supported_actions_manifest_cid`.
*   `failure_config_error`: Transform is misconfigured (e.g., missing manifest CID, invalid IONWALL/IONWALLET service CIDs).

## 6. Security Considerations
*   **Credential Management (Paramount):** The most critical aspect. API keys/tokens for Shopify *must never* be directly configured in or passed through the FluxGraph or stored insecurely by this transform. The IONWALL-IONWALLET mediated flow is essential. IONWALLET is the secure vault.
*   **Scope Limitation & Action Manifest:** The `supported_actions_manifest_cid` ensures this transform can only perform a predefined, audited set of Shopify operations, limiting its potential attack surface if compromised or misused.
*   **IONWALL Consent Specificity:** User consent obtained by IONWALL must be specific to the Shopify store, the action being performed (e.g., "read products" vs. "update inventory"), and ideally the specific data items involved (e.g., product ID).
*   **Input Sanitization:** While `request_parameters` are often structured, any string inputs that might be part of API paths or query parameters should be appropriately sanitized/encoded to prevent injection attacks if Shopify API has such vulnerabilities (though less common in REST APIs).
*   **Data Privacy:** Ensure only necessary data fields are included in `request_parameters` sent to Shopify, respecting user privacy and consent. Data returned from Shopify should also be handled with care by the calling agent.
*   **Protection Against Replay Attacks:** If the credential mechanism involves temporary tokens, ensure they are single-use or have very short validity to prevent replay.
*   **Secure Communication:** All communication with IONWALL, IONWALLET (indirectly), and Shopify API must use HTTPS/TLS.

## 7. Performance Considerations
*   **Shopify API Latency:** External API calls to Shopify will introduce latency. This transform is network-bound.
*   **Shopify API Rate Limits:** The transform must respect Shopify's rate limits. The `rate_limit_info` in the output helps calling agents manage this. Configurable retries (with backoff) for 429 errors are important.
*   **Payload Sizes:** Large request or response payloads can impact performance and network usage.
*   **Manifest Parsing:** The `supported_actions_manifest_cid` should be fetched and parsed efficiently, potentially cached by the transform instance if allowed.

## 8. Versioning
*   Transform specification uses semantic versioning.
*   Must be updated in conjunction with changes to Shopify API versions it targets (via `default_shopify_api_version` and manifest updates). A major Shopify API change might require a new major version of this transform.

## 9. Ecosystem Dependencies
*   **IONWALL:** Essential for user consent for actions and for mediating access to credentials.
*   **IONWALLET (or equivalent secure credential store):** The ultimate holder of Shopify API keys/tokens. The transform interacts with it indirectly via IONWALL.
*   **IONPOD (IPFS):** For storing `shopify_store_context_cid`, `supported_actions_manifest_cid`, and other configuration CIDs.
*   **Shopify Admin API:** The external service this transform interacts with.
*   **FluxGraph Engine:** Executes the transform.
*   **`FetchFromIONPOD_Transform_IONWALL`:** Used internally to fetch context/manifest CIDs.
*   **Secure HTTP Client Library:** Embedded within the Wasm module for making HTTPS calls.

## 10. Example Usage (in FluxGraph YAML)
```yaml
# Executed by Symbiosis Plugin Agent, which receives plugin_id, action_name, payload
# Assume Symbiosis has routed to this transform based on plugin_id='shopify_admin_v1'
# and action_name='PRODUCTS_GET_SINGLE' maps to shopify_api_action_key='PRODUCTS_GET_SINGLE'

# ...
  - id: "call_shopify_get_product_details"
    transform: "SecureShopifyAPI_Admin_Transform_IONWALL"
    # The ionwall_approval_scope is typically set by the agent *triggering* Symbiosis,
    # indicating the user's intent for this specific Shopify interaction.
    # Example: "ionflux_symbiosis_plugin_agent:shopify_admin_v1:PRODUCTS_GET_SINGLE:store_mycoolshop"
    ionwall_approval_scope: "{{trigger.input_data.ionwall_scope_for_this_plugin_action}}"
    inputs:
      shopify_store_context_cid: "{{trigger.input_data.external_system_context_cid}}" # e.g., a CID provided by user for their Shopify store info + cred ref
      shopify_api_action_key: "PRODUCTS_GET_SINGLE" # Corresponds to Symbiosis action_name
      request_parameters:
        id: "{{trigger.input_data.payload.product_id_from_symbiosis_payload}}" # Payload from Symbiosis's input
    outputs: [product_details_from_shopify, shopify_call_http_status, shopify_call_error_info]
# ...
```

## 11. Open Questions & Future Enhancements
*   **Standardized Manifest for Supported Actions:** Refine the structure of `supported_actions_manifest_cid` for clarity, validation, and ease of updating as Shopify API evolves.
*   **Shopify Webhooks:** Handling incoming webhooks from Shopify would require a separate "listener" type transform or agent, not this request-response transform.
*   **Shopify GraphQL API Support:** Current design implies REST. Supporting Shopify's GraphQL Admin API would require significant changes (e.g., `request_parameters` would become a GraphQL query string and variables). Might be a separate transform.
*   **More Sophisticated Retry & Rate Limit Handling:** Implement more elaborate retry strategies (e.g., exponential backoff, jitter) based on `default_retry_policy_for_rate_limits_cid`. Could also involve a shared rate limit counter across multiple instances if running in a scaled environment.
*   **Batch Operations:** Supporting Shopify Admin API batch requests if available and appropriate for certain actions.
*   **OAuth Flow for Initial Credential Setup:** While this transform *uses* existing credentials (via IONWALLET), how does a user initially link their Shopify store and grant API permissions? This would involve an OAuth2 flow, likely orchestrated by IONWALL and IONWALLET, not directly by this transform. This transform consumes the *result* of that setup.
*   **Webhook Subscriptions:** Adding actions to subscribe/unsubscribe to Shopify webhooks via API.
*   **File Uploads/Downloads:** Handling multipart/form-data for Shopify API endpoints that require file uploads (e.g., product images), or downloading files.
