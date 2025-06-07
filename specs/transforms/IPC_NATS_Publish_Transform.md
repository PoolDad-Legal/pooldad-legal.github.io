# Transform Specification: IPC_NATS_Publish_Transform

## 1. Overview
*   **Transform Name:** `IPC_NATS_Publish_Transform`
*   **Version:** 0.9.0
*   **Type:** Communication / Eventing / Inter-Process Communication (IPC)
*   **Primary Goal:** Publishes a message to a specified NATS subject (topic) within the IONFLUX ecosystem's NATS messaging infrastructure. This transform is a fundamental building block for enabling event-driven architectures and inter-agent communication within the sNetwork.
*   **Key Features:**
    *   Accepts a NATS subject string and a message payload (typically a JSON object, but can be any serializable data like plain text or a byte array if encoded as a string like Base64).
    *   Connects to the configured IONFLUX NATS service. The actual NATS client and connection management might be handled by the FluxGraph execution environment or the IONFLUX Controller to ensure secure and efficient NATS usage.
    *   Primarily supports "fire-and-forget" publishing. While NATS supports request-reply, this transform focuses on the publish-only aspect for simplicity in many eventing scenarios. A separate transform (`IPC_NATS_RequestReply_Transform`) might handle request-reply.
    *   IONWALL may oversee which NATS subjects an agent is permitted to publish to, based on the agent's manifest and user-defined policies. The `ionwall_approval_scope` in the FluxGraph can be used to declare intent.

## 2. Conceptual I/O ABI (Application Binary Interface)
### Input Schema (Conceptual JSON)
```json
{
  "type": "object",
  "properties": {
    "nats_subject": {
      "type": "string",
      "description": "The NATS subject (topic) to publish the message to (e.g., 'ionflux.events.agent_XYZ.completed', 'ionflux.commands.agent_ABC.process_data'). Should follow sNetwork naming conventions."
    },
    "message_payload": {
      "type": ["object", "string", "array", "integer", "number", "boolean"],
      "description": "The payload of the message. If it's an object or array, it will typically be serialized to a JSON string before publishing. If raw bytes need to be sent, they should be pre-encoded (e.g., as a Base64 string) and the subscriber must know to decode."
    },
    "headers": {
      "type": "object",
      "additionalProperties": { "type": "string" },
      "nullable": true,
      "description": "Optional NATS message headers (key-value pairs, values must be strings)."
    },
    "publish_options": {
      "type": "object",
      "nullable": true,
      "properties": {
        "expected_stream_name": { "type": "string", "nullable": true, "description": "If publishing to a JetStream stream, specify the expected stream name for an ack." },
        "expected_last_sequence_per_subject": { "type": "integer", "nullable": true, "description": "For JetStream, optimistic concurrency control."}
        // Other JetStream publish options if applicable
      }
    }
  },
  "required": ["nats_subject", "message_payload"]
}
```
### Output Schema (Conceptual JSON)
```json
{
  "type": "object",
  "properties": {
    "publish_successful": {
      "type": "boolean",
      "description": "True if the message was successfully published to the NATS server (e.g., received an ACK from server or JetStream), false otherwise."
    },
    "stream_name": { "type": "string", "nullable": true, "description": "If published to JetStream, the name of the stream." },
    "sequence_number": { "type": "integer", "nullable": true, "description": "If published to JetStream, the sequence number of the message in the stream." },
    "duplicate_message": { "type": "boolean", "nullable": true, "description": "If published to JetStream and duplicate checking was enabled, indicates if this was a duplicate." },
    "status": {
      "type": "string",
      "enum": ["success", "failure_nats_connection", "failure_publish_error", "failure_unauthorized_subject", "failure_payload_serialization", "failure_max_payload_exceeded"],
      "description": "Overall status of the publish operation."
    },
    "error_message": {
      "type": "string",
      "nullable": true,
      "description": "Detailed error message if status indicates failure."
    }
  },
  "required": ["publish_successful", "status"]
}
```

## 3. Configuration Parameters (Conceptual)
*(System-level settings for the transform instance or its execution environment)*

*   `nats_bootstrap_urls_cid`: CID of an IONPOD object containing a list of NATS server URLs (e.g., `["nats://localhost:4222", "nats://nats.ionflux.snetwork:4222"]`).
*   `nats_credentials_path_or_cid`: Path within the secure agent execution environment or an IONPOD CID pointing to NATS credentials (e.g., NKEY seed file, JWT). Access to these credentials would be managed by the IONFLUX Controller and IONWALL.
*   `default_max_payload_size_bytes`: System-wide default maximum message payload size (e.g., 1MB, as per NATS server config).
*   `subject_authorization_policy_cid`: Optional CID of an IONPOD object containing policies (e.g., Open Policy Agent - Rego) that define which `nats_subject`s this agent (or its identity) is allowed to publish to. Enforced by IONWALL or a client-side library.
*   `default_jetstream_publish_options_cid`: Optional CID of default JetStream publishing options if most publications are to JetStream.
*   `connection_timeout_ms`: Timeout for establishing a connection to NATS.
*   `publish_ack_timeout_ms`: Timeout for waiting for an ACK from the NATS server (especially for JetStream).

## 4. Detailed Logic Flow & IONWALL Interaction
1.  **Input Validation:**
    *   Transform receives input (`nats_subject`, `message_payload`, etc.).
    *   Validates that `nats_subject` and `message_payload` are present.
    *   Serializes `message_payload` to a suitable format for NATS (typically JSON string). If serialization fails, set `status: "failure_payload_serialization"` and return.
    *   Checks serialized payload size against `default_max_payload_size_bytes`. If exceeded, set `status: "failure_max_payload_exceeded"` and return.
2.  **IONWALL Subject Authorization Check (Conceptual):**
    *   Before attempting to connect or publish, the transform (or the NATS client library it uses, which should be IONFLUX-aware) may consult IONWALL or a local policy cache derived from `subject_authorization_policy_cid`.
    *   The check verifies if the `requesting_agent_id` (from FluxGraph context) and its `ionwall_approval_scope` grant permission to publish to the specific `nats_subject`.
    *   If authorization is denied: Set `status: "failure_unauthorized_subject"`, `publish_successful: false`, and return.
    *   *Note: This step makes publishing an IONWALL-mediated action, enhancing security. If not implemented, NATS server-side authorization would be the primary gatekeeper.*
3.  **NATS Connection:**
    *   Ensure a connection to the NATS server is available. The execution environment might provide a shared, persistent NATS connection managed by the IONFLUX Controller.
    *   If no active connection, attempt to connect using `nats_bootstrap_urls_cid` and `nats_credentials_path_or_cid` within `connection_timeout_ms`.
    *   If connection fails: Set `status: "failure_nats_connection"`, `publish_successful: false`, and return.
4.  **Message Publishing:**
    *   Publish the serialized message payload to the `nats_subject` with any provided `headers` and `publish_options` (for JetStream).
    *   Wait for an acknowledgement (ACK) from the NATS server if required by the NATS client configuration or JetStream options, within `publish_ack_timeout_ms`.
5.  **Process Publish Result:**
    *   **If Successful (ACK received or fire-and-forget succeeded):** Set `publish_successful: true`, `status: "success"`. If JetStream ACK, populate `stream_name`, `sequence_number`, `duplicate_message`.
    *   **If Publish Error (e.g., NATS server returns an error, no ACK):** Set `publish_successful: false`, `status: "failure_publish_error"`, and populate `error_message` with details from NATS client.
6.  **Return Output:** Return the structured output object.

## 5. Error Handling
*   `failure_nats_connection`: Transform failed to connect to the NATS server(s) specified in configuration (e.g., network issue, server down, invalid credentials).
*   `failure_publish_error`: The NATS server acknowledged the connection but returned an error during the publish operation (e.g., subject invalid on server-side, server error, JetStream specific errors like `expected_last_sequence_per_subject` mismatch).
*   `failure_unauthorized_subject`: Publishing to the specified `nats_subject` was denied by IONWALL policy or NATS server-side authorization.
*   `failure_payload_serialization`: The provided `message_payload` could not be serialized into the required format (e.g., JSON stringification of a complex object with circular references failed).
*   `failure_max_payload_exceeded`: The serialized `message_payload` exceeds the configured `default_max_payload_size_bytes` or the NATS server's limit.

## 6. Security Considerations
*   **Subject Authorization:** Crucial. Without proper authorization (ideally via IONWALL and/or robust NATS server ACLs), agents could spam arbitrary subjects, trigger unintended actions in other agents, or interfere with sNetwork operations. The `subject_authorization_policy_cid` is key if client-side checks are implemented.
*   **Data Privacy of Payloads:** Message payloads sent over NATS should be treated with the same data privacy considerations as any other data. If the NATS transport is not end-to-end encrypted between all potential publishers and subscribers for a sensitive subject, the `message_payload` should be encrypted *before* being passed to this transform (application-level encryption).
*   **Message Integrity & Authenticity:** NATS itself does not inherently guarantee message integrity against tampering during transit (TLS helps) or strong publisher authenticity beyond the NATS connection credentials. For critical messages, consider including digital signatures or secure hashes within the `message_payload` itself, to be verified by subscribers.
*   **NATS Credentials Management:** Secure management of NATS client credentials (`nats_credentials_path_or_cid`) is vital. These should be protected by the agent execution environment and ideally provisioned via the IONFLUX Controller with IONWALL oversight.
*   **Denial of Service:** An agent publishing excessively large messages or at an extremely high frequency could attempt to overload the NATS infrastructure or subscribers. `default_max_payload_size_bytes` and NATS server-side limits, along with rate limiting policies (potentially enforced by IONWALL or Controller), are important.

## 7. Performance Considerations
*   **NATS Latency:** NATS is designed for very low latency. Publishing is typically a fast operation.
*   **NATS Throughput:** Performance depends on the NATS server cluster's capacity, network bandwidth, and message sizes.
*   **Message Size:** Smaller messages generally lead to better performance and lower network overhead.
*   **Serialization Cost:** Serializing complex `message_payload` objects (e.g., to JSON) incurs some computational cost within the transform.
*   **Connection Pooling:** The execution environment should ideally manage NATS connections efficiently, using pooling and persistent connections to avoid repeated TCP handshakes and authentication for every publish.

## 8. Versioning
*   This transform specification follows semantic versioning.
*   Changes to I/O schemas or significant changes in interaction with NATS (e.g., adding mandatory JetStream features) would require a version increment.

## 9. Ecosystem Dependencies
*   **NATS Messaging Infrastructure:** The transform is entirely dependent on a running and accessible NATS server or cluster.
*   **IONWALL (Recommended for Subject Authorization):** For enforcing policies on which agents can publish to which subjects.
*   **IONFLUX Controller (Recommended for Configuration):** For providing NATS connection details, credentials, and potentially managing shared NATS client instances.
*   **FluxGraph Engine:** Executes the transform and provides its inputs.
*   **Wasm Environment:** Must provide networking capabilities for NATS client operations.

## 10. Example Usage (in FluxGraph YAML)
```yaml
# In an agent's FluxGraph definition:
# ...
  - id: "signal_task_completion_event"
    transform: "IPC_NATS_Publish_Transform"
    # Optional: If IONWALL mediates NATS publishing based on general scopes
    # ionwall_approval_scope: "publish_event:task_completion:for_agent_{{agent.name}}"
    inputs:
      nats_subject: "ionflux.events.{{agent.name}}.task_id_{{trigger.input_data.task_identifier}}.completed" # Dynamic subject
      message_payload:
        source_fluxgraph_instance_id: "{{fluxgraph.instance_id}}"
        status_code: "SUCCESS_FINAL"
        completion_timestamp_utc: "{{system.timestamp_utc}}"
        output_data_summary_cid: "{{nodes.store_final_result_to_ionpod.outputs.cid}}" # Output from a previous step
      headers:
        "X-Correlation-ID": "{{trigger.input_data.correlation_id_if_any}}"
        "X-IONFLUX-Event-Version": "1.0"
    outputs: [event_published_successfully, publish_status_details] # Variable names for outputs

# Example publishing to JetStream (conceptual)
  - id: "publish_to_jetstream_orders_stream"
    transform: "IPC_NATS_Publish_Transform"
    inputs:
      nats_subject: "ORDERS.new" # Subject mapped to a JetStream stream
      message_payload: { order_id: "12345", item: "FluxCapacitor", quantity: 1 }
      publish_options:
        expected_stream_name: "ORDERS_STREAM" # For JetStream ACK
    outputs: [js_published_ok, js_publish_status]
# ...
```

## 11. Open Questions & Future Enhancements
*   **Standardized NATS Subject Naming Conventions:** Establishing clear, sNetwork-wide conventions for NATS subjects to ensure discoverability, proper routing, and effective wildcard subscriptions.
*   **Built-in Support for Common Message Envelopes:** Option to automatically wrap `message_payload` in a standard envelope (e.g., CloudEvents format), including metadata like event ID, source, timestamp, data content type.
*   **Automatic Retry Mechanisms:** Configurable automatic retries for publishing messages if transient NATS errors occur.
*   **Dead-Letter Queue (DLQ) Configuration:** Options to specify a DLQ subject if messages cannot be published after retries, for later analysis or manual intervention.
*   **Request-Reply Pattern:** Formalizing a separate `IPC_NATS_RequestReply_Transform` that handles publishing a request and then subscribing to a reply subject, managing timeouts and correlation. The current `reply_to_subject` is a very basic nod.
*   **Schema Validation for Payloads:** Option to provide a JSON schema CID to validate `message_payload` before publishing.
*   **More Granular NATS Client Configuration:** Exposing more NATS client library options (e.g., flush timeout, pending message limits) if needed for advanced scenarios, possibly via a config CID.
*   **End-to-End Payload Encryption Orchestration:** While payload encryption is an application concern, this transform could potentially integrate with an "Encryption_Transform" or use keys from IONWALLET (via another transform) to encrypt/decrypt payloads transparently based on policy or input flags. This is complex.
