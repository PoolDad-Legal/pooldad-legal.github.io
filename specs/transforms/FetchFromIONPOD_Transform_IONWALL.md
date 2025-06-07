# Transform Specification: FetchFromIONPOD_Transform_IONWALL

## 1. Overview
*   **Transform Name:** `FetchFromIONPOD_Transform_IONWALL`
*   **Version:** 0.9.0
*   **Type:** Data Access (Read)
*   **Primary Goal:** Securely fetches data objects (files, directories, structured data) from the user's IONPOD (which is built on IPFS), ensuring that all data access requests are mediated and explicitly approved by IONWALL based on user consent and defined policies.
*   **Key Features:**
    *   Takes an IPFS Content Identifier (CID) as primary input.
    *   Integrates deeply with IONWALL for pre-fetch consent and capability granting. The `ionwall_approval_scope` provided in the FluxGraph is critical for this.
    *   Outputs the fetched data content, which could be raw bytes, a parsed JSON object, or a text string, along with relevant metadata.
    *   Handles various data types with hints for processing and validation.
    *   Includes safeguards like maximum size limits.
    *   Provides clear status and error reporting.

## 2. Conceptual I/O ABI (Application Binary Interface)
### Input Schema (Conceptual JSON)
```json
{
  "type": "object",
  "properties": {
    "cid": {
      "type": "string",
      "description": "IPFS CID (v0 or v1) of the data object to fetch from the user's IONPOD."
    },
    "target_data_type_hint": {
      "type": "string",
      "enum": ["raw_bytes", "json_object", "text_string", "json_array"],
      "default": "raw_bytes",
      "description": "Hint for the expected data type of the content. If 'json_object' or 'json_array', the transform will attempt to parse it. If 'text_string', it will decode as UTF-8."
    },
    "max_size_bytes": {
      "type": "integer",
      "minimum": 1,
      "nullable": true,
      "description": "Optional maximum size limit in bytes for the fetched data. If exceeded, the fetch will fail pre-emptively or during download."
    },
    "ipfs_gateway_override_cid": {
      "type": "string",
      "nullable": true,
      "description": "Optional CID of an IONPOD object specifying a user-preferred IPFS gateway configuration for this specific fetch."
    },
    "cache_hint": {
      "type": "string",
      "enum": ["prefer_fresh", "allow_stale_if_fast", "no_cache"],
      "default": "allow_stale_if_fast",
      "description": "Hint to the underlying IPFS fetching mechanism regarding caching preferences."
    }
  },
  "required": ["cid"]
}
```
### Output Schema (Conceptual JSON)
```json
{
  "type": "object",
  "properties": {
    "data_content": {
      "type": ["string", "object", "array", "null"],
      "description": "The fetched data content. Its JavaScript/JSON type depends on 'target_data_type_hint' and the actual content. For 'raw_bytes', this might be a base64 encoded string if passed as JSON, or ideally a direct byte array/stream if the Wasm environment supports it. For 'json_object' or 'json_array', it's a parsed object/array. For 'text_string', it's a UTF-8 string."
    },
    "metadata": {
      "type": "object",
      "properties": {
        "original_cid": { "type": "string", "description": "The CID that was fetched." },
        "resolved_cid": { "type": "string", "nullable": true, "description": "The final resolved CID if the input was an IPNS name or a CID that redirected." },
        "fetched_size_bytes": { "type": "integer", "description": "Actual size of the fetched data in bytes." },
        "content_type_detected": { "type": "string", "nullable": true, "description": "MIME type detected from IPFS object metadata or file extension, if available." },
        "dag_node_type": { "type": "string", "nullable": true, "description": "Type of IPFS DAG node (e.g., 'raw', 'dag-pb', 'dag-cbor')." },
        "fetch_duration_ms": { "type": "integer", "description": "Time taken for the fetch operation within the transform."}
      },
      "required": ["original_cid", "fetched_size_bytes", "fetch_duration_ms"]
    },
    "status": {
      "type": "string",
      "enum": ["success", "failure_ionwall_denied", "failure_not_found", "failure_timeout", "failure_size_exceeded", "failure_type_mismatch", "failure_ipfs_error", "failure_config_error"],
      "description": "Status of the fetch operation."
    },
    "error_message": {
      "type": "string",
      "nullable": true,
      "description": "Detailed error message if status indicates failure."
    }
  },
  "required": ["status"]
  // "data_content" and "metadata" would be required if status is "success".
}
```

## 3. Configuration Parameters (Conceptual)
*(These are typically set when the transform is deployed or configured at the system level, not per call)*

*   `ionwall_interaction_service_cid`: CID of a configuration object specifying how to communicate with IONWALL (e.g., endpoint URL, protocol version).
*   `default_ipfs_gateway_config_cid`: CID of a system-default IPFS gateway configuration (e.g., list of preferred public gateways, or URL of a private/sNetwork gateway).
*   `system_default_max_size_bytes`: A global default maximum fetch size (e.g., 50MB) if not specified in the input `max_size_bytes`.
*   `default_retry_policy_cid`: CID of a configuration object for retrying failed IPFS fetches (e.g., `{ "max_retries": 3, "delay_ms": 1000, "backoff_factor": 2 }`).
*   `allowed_cid_versions`: Array specifying allowed CID versions (e.g., `[0, 1]`). Default to allow all.
*   `enforce_target_data_type_hint`: Boolean. If true, a `failure_type_mismatch` is returned if actual data cannot be coerced/validated against the hint. If false, it's just a hint, and `data_content` might be raw bytes if parsing fails.

## 4. Detailed Logic Flow & IONWALL Interaction
1.  **Input Validation:** Transform receives input (CID, hints, limits). It validates the CID format and checks `max_size_bytes` against `system_default_max_size_bytes`.
2.  **IONWALL Pre-Check (Optional but Recommended):** Before attempting any IPFS operation, the transform *could* make a lightweight "can-I-fetch-this-CID-for-this-scope?" check with IONWALL. This is useful if the actual fetch is expensive.
3.  **IONWALL Consent Request:**
    *   The transform constructs a data access request for IONWALL. This request includes:
        *   The target `cid`.
        *   The `ionwall_approval_scope` string passed from the FluxGraph node (this is crucial for IONWALL to understand the context and purpose).
        *   The `requesting_agent_id` (from FluxGraph context).
        *   Potentially a hash of the data if the scope is very specific ("access_this_specific_data_if_it_matches_hash_X").
    *   This request is sent to IONWALL via the configured mechanism.
4.  **User Consent via IONWALL:**
    *   IONWALL receives the request. It evaluates its policies and the user's existing consents for the given `requesting_agent_id` and `ionwall_approval_scope`.
    *   If no pre-existing consent covers this specific request, IONWALL prompts the user via their trusted UI (e.g., IONFLUX Canvas notification, IONWALLET prompt): *"Agent '[Agent Name]' wants to access data '[CID or friendly name]' for purpose '[derived from scope]'. Allow?"*
    *   User approves or denies via the IONWALL UI.
5.  **Capability Granting (If Approved):**
    *   If the user approves (or if pre-approved), IONWALL grants a capability to the transform. This might be:
        *   A short-lived, narrowly-scoped access token that the transform can use with a specific IPFS gateway that honors these tokens.
        *   IONWALL itself acting as a proxy: the transform requests IONWALL to fetch the CID, and IONWALL fetches it from IPFS and streams it back to the transform. This is more secure as the transform never directly touches IPFS gateways with broad permissions.
6.  **IPFS Data Fetch:**
    *   Using the granted capability, the transform attempts to fetch the data for the given `cid` from IPFS. It uses the `ipfs_gateway_override_cid` if provided, else the `default_ipfs_gateway_config_cid`.
    *   It applies `max_size_bytes` limits during the download (e.g., by checking `Content-Length` or aborting if streamed bytes exceed limit).
    *   Handles retries based on `retry_policy`.
7.  **Data Processing & Validation:**
    *   Once data is fetched:
        *   Record `fetched_size_bytes` and `fetch_duration_ms`.
        *   Attempt to detect `content_type_detected` (e.g., from IPFS metadata, UnixFS type, or file magic bytes).
        *   If `target_data_type_hint` is `json_object` or `json_array`, attempt to parse the (UTF-8 decoded) data. If parsing fails and `enforce_target_data_type_hint` is true, set error. Otherwise, `data_content` might remain as raw bytes/string.
        *   If `target_data_type_hint` is `text_string`, decode as UTF-8.
        *   If `target_data_type_hint` is `raw_bytes`, provide the data as such (e.g., Uint8Array in Wasm, or base64 encoded string if output must be pure JSON text).
8.  **Output Packaging:** Construct the output object (data_content, metadata, status, error_message) according to the output schema.
9.  **Return Output:** Return the packaged output to the FluxGraph engine.

## 5. Error Handling
*   `failure_ionwall_denied`: User explicitly denied the access request via IONWALL UI, or IONWALL policy engine denied it based on existing rules.
*   `failure_not_found`: The CID is not resolvable on the IPFS network after retries.
*   `failure_timeout`: IPFS fetch operation timed out after retries.
*   `failure_size_exceeded`: Data at CID exceeds `max_size_bytes` (either from input or system default).
*   `failure_type_mismatch`: Data was fetched, but could not be parsed/validated as `target_data_type_hint` (and `enforce_target_data_type_hint` is true). E.g., expected JSON but got binary.
*   `failure_ipfs_error`: Other unspecified IPFS client or gateway error during fetch.
*   `failure_config_error`: Transform is misconfigured (e.g., IONWALL endpoint not set, invalid default gateway).

## 6. Security Considerations
*   **IONWALL as Central Authority:** The transform's security hinges entirely on correct and robust interaction with IONWALL. It *must not* provide any fallback or bypass mechanism to access IPFS directly without IONWALL's explicit grant.
*   **Capability Scope & Lifetime:** Capabilities granted by IONWALL must be narrowly scoped to the specific CID (or IPNS name) and have a short lifetime.
*   **Protection Against Malicious CIDs:**
    *   `max_size_bytes` is crucial to prevent DoS by fetching excessively large files.
    *   While IPFS itself is content-addressed, the transform should not execute any fetched content. It only reads and passes data.
    *   If fetching directory CIDs, be cautious about recursive depth and total size/number of files (not detailed in this spec, would require enhancements).
*   **Input Validation:** Strictly validate the format of input CIDs.
*   **Secure Communication:** All communication with IONWALL and trusted IPFS gateways must use secure protocols (e.g., HTTPS/TLS).
*   **Data Integrity:** IPFS CIDs inherently ensure content integrity. The transform should verify the fetched data matches the requested CID if not using a fully trusted path.

## 7. Performance Considerations
*   **Gateway Selection:** Using geographically close or high-performance IPFS gateways can significantly impact fetch times. Configuration should allow for this.
*   **Caching:**
    *   The transform itself might implement a small in-memory cache for very recently accessed CIDs (if allowed by policy and cache_hint).
    *   More broadly, caching is handled by the IPFS client library, local IPFS node (if user runs one), or the gateways. `cache_hint` can influence this.
*   **Streaming for Large Files:** For `raw_bytes` or `text_string` from large files, the `data_content` output should ideally be a reference to a stream or an iterable byte chunk provider rather than loading the entire file into memory, especially in resource-constrained Wasm environments. The current output schema is simplified; a production version would need to detail this.
*   **Parallel Fetches (If Applicable):** If a FluxGraph needs to fetch multiple CIDs, the engine might run multiple instances of this transform in parallel.

## 8. Versioning
*   This transform specification follows standard semantic versioning (e.g., v0.9.0, v1.0.0, v1.1.0).
*   Changes to Input/Output Schemas or core logic (especially IONWALL interaction) would necessitate a version change.
*   The Wasm module CID for the compiled transform is inherently versioned by its content hash.

## 9. Ecosystem Dependencies
*   **IONWALL:** Absolutely critical for consent, policy enforcement, and capability granting. The specific IONWALL API version and interaction protocol must be compatible.
*   **IONPOD (IPFS):** The underlying distributed storage system where the data resides. Transform needs access to an IPFS client or gateway.
*   **FluxGraph Engine:** Provides the execution environment for the Wasm transform, supplies inputs (including contextual ones like `requesting_agent_id`), and consumes outputs.
*   **Wasm Environment:** The specific Wasm runtime (e.g., WasmEdge, Wasmer) and its supported System Interfaces (WASI) will affect how data (especially streams or large byte arrays) is handled.

## 10. Example Usage (in FluxGraph YAML)
```yaml
# In an agent's FluxGraph definition:
# ...
  - id: "fetch_user_document_for_analysis" # Unique ID for this node
    transform: "FetchFromIONPOD_Transform_IONWALL" # Name of the transform
    # This scope is critical. IONWALL uses it to determine consent text and policy.
    ionwall_approval_scope: "read_document:{{trigger.input_data.document_cid}}:for_sentiment_analysis_by_MuseAgent"
    inputs:
      cid: "{{trigger.input_data.document_cid}}" # Dynamically from trigger
      target_data_type_hint: "text_string"
      max_size_bytes: 10485760 # 10MB limit for this specific fetch
      cache_hint: "prefer_fresh" # We want the latest version for analysis
    outputs: [document_text_content, document_fetch_metadata] # Names for outputs from this node
    # These outputs can then be used as inputs to subsequent transform nodes.
    # e.g., document_text_content -> MuseGen_LLM_Transform.inputs.prompt_context

  - id: "get_json_config_file"
    transform: "FetchFromIONPOD_Transform_IONWALL"
    ionwall_approval_scope: "read_config:{{agent.config.settings_cid}}:for_agent_initialization"
    inputs:
      cid: "{{agent.config.settings_cid}}" # From agent's own static configuration
      target_data_type_hint: "json_object"
    outputs: [agent_settings_obj, settings_fetch_metadata]
# ...
```

## 11. Open Questions & Future Enhancements
*   **Directory Fetching:** How to handle fetching entire directories (UnixFSv1 sharded directories)? Recursively fetch all files? Output a list of file CIDs and metadata? This needs a more complex output schema and potentially new input parameters (e.g., `max_directory_depth`, `max_total_size_for_directory`).
*   **IPNS Name Resolution:** Support for resolving IPNS names to CIDs before fetching. This should also be mediated by IONWALL. Does this happen inside this transform or as a preceding, separate transform? (Likely inside, with `resolved_cid` in output metadata).
*   **Advanced Streaming:** Formalize how large file streams are passed as output to subsequent Wasm transforms without excessive memory copying. This is highly dependent on the Wasm runtime and inter-transform communication capabilities of the FluxGraph engine.
*   **Partial Content Fetching (Range Requests):** Support for fetching only specific byte ranges from a larger file, if the IPFS gateway and protocol support it.
*   **More Sophisticated Data Type Validation/Conversion:** E.g., validating a fetched JSON object against a JSON schema CID provided in the input.
*   **Conditional Fetching (ETag/If-None-Match like behavior):** Input a previously fetched CID or hash; only fetch if the content at the target CID has changed.
*   **Error Reporting Granularity:** More detailed error codes for different IPFS failure modes.
*   **Batch Fetching:** An input that takes an array of CIDs and outputs an array of results, potentially fetched in parallel.
