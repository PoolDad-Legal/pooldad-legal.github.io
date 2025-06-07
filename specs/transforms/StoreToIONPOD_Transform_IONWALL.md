# Transform Specification: StoreToIONPOD_Transform_IONWALL

## 1. Overview
*   **Transform Name:** `StoreToIONPOD_Transform_IONWALL`
*   **Version:** 0.9.0
*   **Type:** Data Access (Write)
*   **Primary Goal:** Securely stores data objects (files, structured data blobs, text content) to the user's IONPOD (built on IPFS). All storage requests are mediated and explicitly approved by IONWALL, which enforces user consent, policies (like quotas, path restrictions), and manages metadata association and potential encryption.
*   **Key Features:**
    *   Accepts data content to be stored (can be raw bytes, JSON objects/arrays, or text strings).
    *   Allows specification of a target logical path within IONPOD and arbitrary key-value metadata.
    *   Integrates deeply with IONWALL for pre-storage consent and capability granting. The `ionwall_approval_scope` from the FluxGraph is vital.
    *   Outputs the IPFS CID of the successfully stored data object.
    *   Supports options for data encryption at rest, orchestrated via IONWALL and IONPOD's capabilities (potentially using keys from IONWALLET).
    *   Handles basic versioning strategies for data at a given logical path.

## 2. Conceptual I/O ABI (Application Binary Interface)
### Input Schema (Conceptual JSON)
```json
{
  "type": "object",
  "properties": {
    "data_to_store": {
      "type": ["string", "object", "array", "integer", "number", "boolean"],
      "description": "The actual data content to be stored. If 'data_is_cid' is true, this should be a CID string. For binary data not already in IPFS, it might be a base64 encoded string when input is JSON, or ideally a direct byte array/stream if the Wasm environment supports it. For structured data, it's a JSON object/array. For text, a UTF-8 string."
    },
    "data_is_cid": {
      "type": "boolean",
      "default": false,
      "description": "If true, 'data_to_store' is treated as an existing IPFS CID, and this operation becomes about linking/pinning it into a new IONPOD path with new metadata, rather than adding new raw data."
    },
    "target_ionpod_path": {
      "type": "string",
      "nullable": true,
      "description": "Suggested logical path within the user's IONPOD (e.g., '/documents/generated/', '/images/processed/myimage.png'). IONPOD (via IONWALL) resolves this path and links the new CID. If null, data is added to IPFS but not explicitly linked to a path by this transform (CID is still returned)."
    },
    "filename_suggestion": {
        "type": "string",
        "nullable": true,
        "description": "Suggested filename if the target_ionpod_path is a directory or if a filename is desired for the IPFS DAG node. Overridden by path if path includes filename."
    },
    "content_type_provided": {
        "type": "string",
        "nullable": true,
        "description": "MIME type of the data_to_store, e.g., 'application/json', 'text/plain', 'image/png'. Helps IPFS and other agents interpret the data."
    },
    "metadata_object": {
      "type": "object",
      "additionalProperties": true,
      "nullable": true,
      "description": "Key-value pairs of metadata to associate with the stored data object (e.g., source_agent_id, creation_timestamp_custom, content_description, custom_tags). This metadata itself is typically stored as a separate JSON object in IONPOD, linked to the data CID."
    },
    "encryption_options": {
      "type": "object",
      "nullable": true,
      "properties": {
        "encrypt_data": { "type": "boolean", "default": false, "description": "Whether the data should be encrypted at rest in IONPOD. Default is false, meaning IONPOD defaults apply unless user policy mandates encryption." },
        "encryption_key_id_hint": { "type": "string", "nullable": true, "description": "Hint for a specific encryption key managed by IONWALLET or a user's profile, to be used for encrypting this data. Requires IONWALL/IONWALLET coordination." }
      },
      "description": "Options related to encrypting the data at rest."
    },
    "versioning_mode": {
      "type": "string",
      "enum": ["overwrite_at_path", "new_version_at_path", "fail_if_path_exists", "no_versioning_just_add"],
      "default": "new_version_at_path",
      "description": "Strategy for handling storage if 'target_ionpod_path' is specified and already exists: 'overwrite_at_path' replaces the CID at the path, 'new_version_at_path' makes the old CID a previous version (IONPOD MFS feature), 'fail_if_path_exists' errors, 'no_versioning_just_add' adds to IPFS and returns CID without path linking if path exists (or is null)."
    },
    "pin_data": {
      "type": "boolean",
      "default": true,
      "description": "Whether to request the IPFS node to pin the data after adding it. True ensures data persistence beyond local cache."
    }
  },
  "required": ["data_to_store"]
}
```
### Output Schema (Conceptual JSON)
```json
{
  "type": "object",
  "properties": {
    "cid": { "type": "string", "description": "IPFS CID (v1) of the successfully stored data object." },
    "metadata_cid": { "type": "string", "nullable": true, "description": "IPFS CID of the metadata object, if 'metadata_object' was provided and stored separately (common practice)." },
    "size_bytes_stored": { "type": "integer", "description": "Size of the primary data object stored in IPFS in bytes." },
    "target_ionpod_path_resolved": { "type": "string", "nullable": true, "description": "The actual IONPOD path where the data was linked, if applicable." },
    "version_id": { "type": "string", "nullable": true, "description": "Version identifier if 'versioning_mode' created a new version at the path." },
    "status": {
      "type": "string",
      "enum": ["success", "failure_ionwall_denied", "failure_ipfs_add_error", "failure_metadata_linking_error", "failure_encryption_error", "failure_versioning_conflict", "failure_config_error", "failure_quota_exceeded"],
      "description": "Status of the store operation."
    },
    "error_message": {
      "type": "string",
      "nullable": true,
      "description": "Detailed error message if status indicates failure."
    }
  },
  "required": ["status"]
  // "cid" and "size_bytes_stored" would be required if status is "success".
}
```

## 3. Configuration Parameters (Conceptual)
*(System-level settings for the transform instance)*

*   `ionwall_interaction_service_cid`: CID of config for IONWALL communication.
*   `default_ipfs_add_gateway_config_cid`: CID of system-default IPFS gateway/node configuration for `ipfs add` operations. This node must have write access if it's a private sNetwork node.
*   `default_encryption_policy_cid`: CID of an IONPOD object specifying system/user default encryption policy (e.g., `{ "encrypt_all_by_default": true, "default_key_management_strategy": "ionwallet_derived_symmetric" }`). Overridden by `encryption_options` in input.
*   `max_data_size_to_store_bytes`: Global default maximum size for a single `data_to_store` operation (e.g., 100MB). Can be overridden by user/agent specific policies via IONWALL.
*   `default_pinning_service_config_cid`: Optional CID for configuring interaction with a specific IPFS pinning service if direct add node doesn't pin long-term.

## 4. Detailed Logic Flow & IONWALL Interaction
1.  **Input Reception & Preparation:**
    *   Transform receives input. Validates `data_to_store` is present.
    *   If `data_to_store` is not a string (e.g., JSON object/array), it's typically serialized to a UTF-8 byte array (e.g., as JSON string for objects/arrays, or direct bytes for binary). `content_type_provided` helps determine this.
    *   If `data_is_cid` is true, `data_to_store` is validated as a CID string.
    *   Checks data size against `max_data_size_to_store_bytes`.
2.  **IONWALL Consent Request:**
    *   The transform constructs a data storage request for IONWALL. This includes:
        *   The `ionwall_approval_scope` from the FluxGraph node.
        *   `requesting_agent_id`.
        *   Metadata about the data to be stored: estimated size, `content_type_provided`, proposed `target_ionpod_path`, `filename_suggestion`, and the `metadata_object` itself.
        *   `encryption_options`.
        *   `versioning_mode`.
    *   IONWALL evaluates this against user consents, policies (e.g., path restrictions, storage quotas, mandatory encryption for certain data types/paths).
    *   If interaction is needed, IONWALL prompts the user: *"Agent '[Agent Name]' wants to store data '[filename_suggestion or description from metadata]' at path '[target_ionpod_path]' (Size: X MB). Metadata: [summary]. Encrypt: [Y/N]. Allow?"*
3.  **Capability Granting & Parameter Refinement (If Approved):**
    *   If user approves (or pre-approved), IONWALL grants a capability for the IPFS 'add' operation and path linking.
    *   IONWALL may return refined parameters, e.g., overriding `encryption_options` based on user policy, or specifying a managed encryption key. It might also return a specific IPFS add endpoint or pinning service to use.
4.  **IPFS 'add' Operation (if `data_is_cid` is false):**
    *   Using the granted capability and refined parameters, the transform adds the (potentially encrypted) data bytes to IPFS via the configured gateway/node.
    *   If `encryption_options.encrypt_data` is true, encryption happens here, client-side, before `add`. The key would be managed via IONWALL/IONWALLET interaction (not detailed here, complex flow). The raw (unencrypted) data is *not* sent to the IPFS node unless that node is part of a trusted, encrypted storage backend.
    *   The CID of the added data is returned by IPFS.
5.  **Metadata Storage (If `metadata_object` provided):**
    *   The `metadata_object` (potentially with added fields like `data_cid` it describes, `timestamp`) is serialized to JSON.
    *   This JSON data is added to IPFS, yielding a `metadata_cid`. This also requires IONWALL approval, often bundled with the main data storage approval.
6.  **IONPOD Path Linking & Versioning (If `target_ionpod_path` provided):**
    *   The transform (or IONWALL, or an IONPOD management service called by IONWALL) links the new data CID (and `metadata_cid`) to the user's IONPOD MFS (Mutable File System) at `target_ionpod_path`, respecting `versioning_mode`.
    *   If `data_is_cid` was true, this step links the existing CID to the new path/metadata.
7.  **Pinning (If `pin_data` is true):**
    *   Request the IPFS node (or configured pinning service via IONWALL mediation) to pin the `cid` (and `metadata_cid`).
8.  **Output Packaging & Return:**
    *   Construct the output object (CID, metadata_cid, size, path, version, status, error) and return.

## 5. Error Handling
*   `failure_ionwall_denied`: User denied storage permission, or IONWALL policy engine denied due to quota, path restrictions, content policy violation (if pre-scan happens), etc.
*   `failure_ipfs_add_error`: Error during `ipfs add` (network, IPFS daemon issue, disk full on node).
*   `failure_metadata_linking_error`: Data CID created, but failed to store/link metadata or update IONPOD path. May require rollback/cleanup.
*   `failure_encryption_error`: Problem encrypting data before adding (e.g., key unavailable from IONWALLET, encryption algorithm error).
*   `failure_versioning_conflict`: E.g., `versioning_mode` was `fail_if_path_exists` and path indeed existed.
*   `failure_config_error`: Transform misconfigured (e.g., IONWALL endpoint, IPFS add gateway).
*   `failure_quota_exceeded`: User's IONPOD storage quota (managed by IONWALL/IONPOD service) would be exceeded.

## 6. Security Considerations
*   **IONWALL as Central Authority:** All write operations *must* be gated by IONWALL. No direct, unapproved writes.
*   **Data Integrity & Confidentiality:**
    *   IPFS CIDs ensure integrity of stored data.
    *   Encryption (`encryption_options`) is crucial for confidentiality. Key management (likely via IONWALLET) must be secure. The transform itself should not hold keys. Client-side encryption before `ipfs add` is preferred.
*   **Path Traversal/Manipulation:** `target_ionpod_path` must be sanitized and resolved safely by IONPOD/IONWALL to prevent unauthorized writes to arbitrary locations. IONPOD MFS controls this.
*   **Metadata Security:** Metadata, even if stored separately, might contain sensitive information. It should also be subject to encryption policies if needed.
*   **Resource Exhaustion:** `max_data_size_to_store_bytes` helps prevent DoS. IONWALL enforces storage quotas.
*   **Content Scanning (Optional):** For some sNetworks, IONWALL might mandate a pre-scan of `data_to_store` for malicious content or policy violations *before* approving the IPFS add, especially if data is public.

## 7. Performance Considerations
*   **IPFS 'add' Latency:** Adding large files to IPFS can take time, depending on network bandwidth to the IPFS node, disk speed of the node, and whether client-side encryption is performed.
*   **Streaming to IPFS:** For large `data_to_store`, the transform should ideally stream data to the IPFS add endpoint rather than requiring the entire content in memory. Wasm capabilities for this are key.
*   **Network Hops:** Minimizing hops to the IPFS node used for adding is beneficial. An edge node or local IPFS daemon is ideal.

## 8. Versioning
*   Transform specification uses semantic versioning.
*   Data versioning within IONPOD is handled by the `versioning_mode` input and IONPOD's MFS capabilities.

## 9. Ecosystem Dependencies
*   **IONWALL:** Essential for consent, policy enforcement (quotas, paths, encryption), and capability granting.
*   **IONPOD (IPFS):** The target storage system. Requires access to an IPFS node's `add` functionality and MFS/linking API (often via IONWALL or a dedicated IONPOD service).
*   **FluxGraph Engine:** Executes the transform.
*   **IONWALLET (Potentially):** If `encryption_options` involve user-specific keys managed by IONWALLET.
*   **Wasm Environment:** Must support necessary operations like data serialization, (potentially) client-side encryption, and communication with IPFS/IONWALL.

## 10. Example Usage (in FluxGraph YAML)
```yaml
# ...
  - id: "generate_report_data"
    transform: "ReportGenerator_Transform" # Some agent generates data
    inputs:
      #...
    outputs: [report_json_object_to_store, report_metadata_obj]

  - id: "store_generated_report_to_ionpod"
    transform: "StoreToIONPOD_Transform_IONWALL"
    # This scope tells IONWALL the intent, for user consent and policy checks.
    ionwall_approval_scope: "write_report:/reports/daily/{{fluxgraph.instance_id}}.json:for_agent_ReportGenerator"
    inputs:
      data_to_store: "{{nodes.generate_report_data.outputs.report_json_object_to_store}}"
      target_ionpod_path: "/reports/daily/{{fluxgraph.instance_id}}.json" # Dynamic path
      filename_suggestion: "daily_sales_report_{{system.date_iso}}.json"
      content_type_provided: "application/json"
      metadata_object: "{{nodes.generate_report_data.outputs.report_metadata_obj}}" # Pass metadata from previous step
      encryption_options: {
        "encrypt_data": true
        # "encryption_key_id_hint": "user_financial_data_key" # Optional hint for IONWALLET
      }
      versioning_mode: "new_version_at_path" # Keep previous versions if path exists
      pin_data: true
    outputs: [stored_report_cid, report_metadata_object_cid, bytes_stored_count]
# ...
```

## 11. Open Questions & Future Enhancements
*   **Standardized Streaming to IPFS 'add':** Formalizing how large data streams are passed from `data_to_store` (if it's a stream reference from a previous Wasm transform) directly to an IPFS `add` stream without materializing fully in memory.
*   **Atomic Operations for Data + Metadata + Path Linking:** Ensuring that if any part of the store (add data, add metadata, link path) fails, the operation is rolled back cleanly or handled consistently to avoid orphaned data or metadata. This is complex in distributed systems.
*   **More Sophisticated Versioning Control:** Beyond basic modes, options like "keep last N versions", "semantic versioning tags for paths".
*   **Conflict Resolution for `target_ionpod_path`:** Define strategies if `versioning_mode: "fail_if_path_exists"` is too strict, but simple overwrite is not desired (e.g., "rename_new_with_timestamp_if_path_exists").
*   **Batch Store Operations:** Inputting an array of `data_to_store` objects to be processed in a single transform call for efficiency.
*   **Progress Indication for Large Uploads:** How the transform (or underlying IPFS client) can report progress for very large file uploads.
*   **Direct Browser-to-IPFS Upload (Conceptual):** For UI-driven uploads, can this transform orchestrate a direct browser-to-IPFS upload (via user's node or gateway) that is then "claimed" or "registered" into IONPOD via IONWALL, to avoid data passing through the Wasm transform itself?
