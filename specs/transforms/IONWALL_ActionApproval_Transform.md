# Transform Specification: IONWALL_ActionApproval_Transform

## 1. Overview
*   **Transform Name:** `IONWALL_ActionApproval_Transform`
*   **Version:** 0.9.0
*   **Type:** Utility / Consent Management / Human Interaction
*   **Primary Goal:** Explicitly requests user approval via IONWALL for a specific, described action that an agent or FluxGraph intends to perform. This transform is crucial for scenarios where an implicit approval scope (defined in an agent's manifest or granted at the start of a FluxGraph execution) is deemed insufficient, or when a particularly sensitive, costly, or irreversible operation requires a dedicated, fine-grained user consent checkpoint.
*   **Key Features:**
    *   Takes a detailed, human-readable description of the action requiring approval, along with optional structured details (via CID) and estimated costs.
    *   Communicates with IONWALL, which is responsible for securely presenting this approval request to the user via their trusted UI (e.g., IONFLUX Canvas notification, IONWALLET prompt, or other registered consent interface).
    *   Waits for the user's response (approve/deny) from IONWALL.
    *   Outputs a boolean indicating whether the action was approved or denied, along with any contextual information from IONWALL (e.g., user comments, approval transaction ID).
    *   Acts as a deliberate pause point in a FluxGraph, deferring continuation until explicit user consent is obtained for a specific operation.

## 2. Conceptual I/O ABI (Application Binary Interface)
### Input Schema (Conceptual JSON)
```json
{
  "type": "object",
  "properties": {
    "action_description_text": {
      "type": "string",
      "description": "Clear, concise, and human-readable description of the action requiring approval. This text will be displayed to the user. It should be templated by the calling agent to include specific context (e.g., 'Allow Agent X to delete file Y.txt?', 'Approve spending 50 C-ION to summarize document Z?')."
    },
    "action_details_cid": {
      "type": "string",
      "nullable": true,
      "description": "Optional CID of an object in IONPOD containing more detailed, structured information about the action. IONWALL's UI might display a summary and allow the user to drill down into these details."
    },
    "requesting_agent_name": {
      "type": "string",
      "description": "Name of the agent or system component requesting this approval (for display in IONWALL to provide context to the user). This could be derived from `{{agent.name}}` in a FluxGraph."
    },
    "calling_fluxgraph_id": {
      "type": "string",
      "nullable": true,
      "description": "ID of the FluxGraph instance making the request, if applicable (for audit trails and context)."
    },
    "associated_data_cids_for_context": {
      "type": "array",
      "items": { "type": "string" },
      "nullable": true,
      "description": "Optional list of relevant data CIDs that IONWALL might display or link to for user context when making the decision (e.g., the CID of a document to be deleted)."
    },
    "estimated_cost_c_ion": {
      "type": "number",
      "minimum": 0,
      "nullable": true,
      "description": "Estimated C-ION cost of the action, if applicable. IONWALL will display this to the user."
    },
    "urgency": {
      "type": "string",
      "enum": ["low", "medium", "high", "critical"],
      "default": "medium",
      "description": "Urgency level, which might influence how IONWALL presents the notification to the user."
    },
    "approval_timeout_seconds_override": {
      "type": "integer",
      "minimum": 10,
      "nullable": true,
      "description": "Optional override for how long IONWALL should wait for a user response before timing out this specific request."
    },
    "required_scopes_for_action": {
      "type": "array",
      "items": { "type": "string" },
      "nullable": true,
      "description": "A list of specific IONWALL scopes that this approval would grant if the user consents. This helps IONWALL track the purpose of the consent."
    }
  },
  "required": ["action_description_text", "requesting_agent_name"]
}
```
### Output Schema (Conceptual JSON)
```json
{
  "type": "object",
  "properties": {
    "approved": {
      "type": "boolean",
      "description": "True if the user explicitly approved the action via IONWALL. False if the user denied it or if the request timed out or failed for other reasons."
    },
    "approval_context": {
      "type": "object",
      "nullable": true,
      "properties": {
        "user_comment": { "type": "string", "nullable": true, "description": "Optional comment provided by the user along with their approval/denial." },
        "ionwall_consent_receipt_cid": { "type": "string", "nullable": true, "description": "CID of a receipt object stored in IONPOD by IONWALL, cryptographically attesting to this specific consent interaction." },
        "ionwall_interaction_id": { "type": "string", "description": "Unique ID assigned by IONWALL to this specific approval interaction, for auditing." },
        "timestamp_utc": { "type": "string", "format": "date-time", "description": "Timestamp of when the approval decision was made." },
        "granted_scopes": { "type": "array", "items": {"type": "string"}, "nullable": true, "description": "Scopes granted by this approval, if applicable."}
      },
      "description": "Contextual information about the approval decision from IONWALL. Null if 'approved' is false due to communication failure or timeout before decision."
    },
    "status": {
      "type": "string",
      "enum": ["success_approved", "success_denied", "failure_ionwall_communication", "failure_user_timeout", "failure_invalid_input", "failure_internal_error"],
      "description": "Overall status of the transform's execution."
    },
    "error_message": {
      "type": "string",
      "nullable": true,
      "description": "Detailed error message if status indicates failure."
    }
  },
  "required": ["approved", "status"]
}
```

## 3. Configuration Parameters (Conceptual)
*(System-level settings for the transform instance)*

*   `ionwall_interaction_service_cid`: CID of config for IONWALL communication (e.g., API endpoint, protocol version for explicit approvals).
*   `default_approval_timeout_seconds`: System-wide default for how long IONWALL should wait for a user response (e.g., 300 seconds) if not overridden in the input.
*   `max_action_description_length`: Maximum allowed length for `action_description_text` to prevent abuse.
*   `presentation_options_cid`: Optional CID of a configuration object that guides how IONWALL might present different types of approval requests (e.g., UI hints, notification sounds based on urgency).

## 4. Detailed Logic Flow & IONWALL Interaction
1.  **Input Reception & Validation:** The transform receives its input object. It validates that all required fields (`action_description_text`, `requesting_agent_name`) are present and well-formed. Checks `action_description_text` length against `max_action_description_length`.
2.  **Fetch Action Details (Conditional):** If `action_details_cid` is provided, the transform internally uses `FetchFromIONPOD_Transform_IONWALL` to fetch this detailed information. This requires that the calling agent/FluxGraph already has implicit consent to read this specific CID (or it would trigger a separate IONWALL consent for that fetch, which is usually not desired at this stage). The fetched details are packaged for IONWALL.
3.  **Construct Approval Request:** The transform constructs an "explicit action approval request" message. This message includes:
    *   `action_description_text`
    *   Fetched `action_details_obj` (if any)
    *   `requesting_agent_name`
    *   `calling_fluxgraph_id`
    *   `associated_data_cids_for_context`
    *   `estimated_cost_c_ion`
    *   `urgency`
    *   `required_scopes_for_action`
    *   The effective timeout (input override or default).
4.  **Send Request to IONWALL:** The request is sent to IONWALL via the configured secure channel (using details from `ionwall_interaction_service_cid`).
5.  **IONWALL Presents to User:** IONWALL is responsible for:
    *   Authenticating the request (ensuring it's from a legitimate transform instance within an approved FluxGraph).
    *   Identifying the correct user and their trusted UI for presenting the request.
    *   Displaying the `action_description_text`, cost, agent name, and providing access to `action_details` and `associated_data_cids_for_context`.
    *   Collecting the user's explicit approval (e.g., "Approve", "Deny" buttons) and any optional comments. This interaction must happen on a trusted IONWALL interface.
6.  **Wait for IONWALL Response:** The transform waits for a response from IONWALL. This is a blocking call from the perspective of the FluxGraph execution, up to the configured timeout.
7.  **Process IONWALL Response:**
    *   **If Approved:** IONWALL returns an approval confirmation, potentially with user comments and a `ionwall_consent_receipt_cid`. The transform sets `approved: true`, `status: "success_approved"`, and populates `approval_context`.
    *   **If Denied:** IONWALL returns a denial confirmation. Transform sets `approved: false`, `status: "success_denied"`, and populates `approval_context` (which might include a denial reason or comment).
    *   **If Timeout:** If IONWALL indicates the user did not respond within the timeout, transform sets `approved: false`, `status: "failure_user_timeout"`.
    *   **If Communication Error:** If the transform fails to communicate with IONWALL or IONWALL returns an internal error, set `approved: false`, `status: "failure_ionwall_communication"`, and populate `error_message`.
8.  **Return Output:** The transform returns the structured output object to the FluxGraph engine.

## 5. Error Handling
*   `failure_ionwall_communication`: Transform failed to send the request to IONWALL or receive a valid response (e.g., network issue, IONWALL service down).
*   `failure_user_timeout`: IONWALL reported that the user did not respond to the approval request within the allocated timeout period. `approved` will be false.
*   `failure_invalid_input`: Required input fields like `action_description_text` or `requesting_agent_name` were missing or malformed. `approved` will be false.
*   `failure_internal_error`: An unexpected error occurred within the transform itself. `approved` will be false.
*   Note: `success_denied` is a valid success status for the transform's execution, where `approved` is false because the user actively denied the request.

## 6. Security Considerations
*   **IONWALL as Trusted Mediator:** This transform's security relies entirely on IONWALL's ability to securely authenticate the user, present the request accurately, and prevent tampering or spoofing of user responses.
*   **Clarity of `action_description_text`:** The calling agent is responsible for crafting a clear, unambiguous, and non-misleading `action_description_text`. IONWALL might have policies or AI checks to vet these descriptions for common dark patterns or misleading language.
*   **Preventing Approval Fatigue/Spam:** If an agent misbehaves and bombards the user with approval requests, IONWALL should implement rate limiting or mechanisms to temporarily mute requests from a specific agent or FluxGraph.
*   **Contextual Integrity:** Ensuring that `action_details_cid` and `associated_data_cids_for_context`, if displayed by IONWALL, are the actual CIDs the user is approving action upon. IPFS content addressing helps here.
*   **Scope of Approval:** The approval granted by this transform is typically for a *single, specific instance* of an action. It should not be misconstrued as granting broad, persistent permissions unless the `action_description_text` and `required_scopes_for_action` clearly state that.
*   **Auditability:** The `ionwall_consent_receipt_cid` and `ionwall_interaction_id` are crucial for creating an auditable trail of user consents.

## 7. Performance Considerations
*   **User Response Time:** The primary performance factor is the time it takes for the user to see and respond to the IONWALL prompt. This transform will block FluxGraph execution during this period. Therefore, it should be used for actions where such a pause is acceptable and necessary.
*   **Not for High-Frequency Operations:** Due to the mandatory user interaction, this transform is unsuitable for high-frequency, low-latency decision points within a FluxGraph.
*   **IONWALL Communication Latency:** Network latency between the transform and IONWALL should be minimal.

## 8. Versioning
*   This transform specification follows semantic versioning.
*   Changes to I/O schemas or the core interaction protocol with IONWALL would necessitate a version increment.

## 9. Ecosystem Dependencies
*   **IONWALL:** This transform is fundamentally a client to the IONWALL system. Its existence and functionality are entirely dependent on a running, accessible, and trusted IONWALL service.
*   **FluxGraph Engine:** Executes the transform, provides inputs (including context like `{{agent.name}}`), and manages its blocking state while waiting for IONWALL.
*   **IONPOD (IPFS):** Used for storing and fetching `action_details_cid` and `ionwall_consent_receipt_cid`.
*   **User Interface for IONWALL:** A trusted user interface (e.g., part of IONFLUX Canvas, a dedicated IONWALLET app, browser extension) is required for IONWALL to present approval requests to the user.

## 10. Example Usage (in FluxGraph YAML)
```yaml
# ...
  - id: "prepare_sensitive_operation_details"
    transform: "DataAggregation_Transform" # Some transform prepares details
    inputs:
      # ...
    outputs: [operation_details_obj_for_approval]

  - id: "store_op_details_for_ionwall"
    transform: "StoreToIONPOD_Transform_IONWALL"
    ionwall_approval_scope: "write_pod_data:temp_approval_details" # Agent needs to store this temp data
    inputs:
      data_to_store: "{{nodes.prepare_sensitive_operation_details.outputs.operation_details_obj_for_approval}}"
    outputs: [op_details_cid_for_ionwall]

  - id: "request_explicit_user_approval"
    transform: "IONWALL_ActionApproval_Transform"
    inputs:
      action_description_text: "Authorize {{agent.name}} to execute a high-cost financial analysis (Est: {{trigger.input_data.estimated_cost}} C-ION) on dataset '{{trigger.input_data.dataset_name}}'. This involves processing sensitive financial projections."
      action_details_cid: "{{nodes.store_op_details_for_ionwall.outputs.op_details_cid_for_ionwall}}"
      requesting_agent_name: "{{agent.name}}" # Agent's own registered name
      calling_fluxgraph_id: "{{fluxgraph.instance_id}}" # ID of this running graph
      associated_data_cids_for_context: ["{{trigger.input_data.dataset_cid_to_analyze}}"]
      estimated_cost_c_ion: "{{trigger.input_data.estimated_cost}}"
      urgency: "high"
      required_scopes_for_action: ["execute_financial_analysis_suite:{{trigger.input_data.dataset_cid_to_analyze}}", "spend_c_ion_limit:{{trigger.input_data.estimated_cost}}"]
    outputs: [user_approved_action, approval_metadata_obj]

  - id: "execute_financial_analysis_if_approved"
    transform: "FinancialAnalysisSuite_Transform" # The actual sensitive/costly action
    if: "{{nodes.request_explicit_user_approval.outputs.user_approved_action}} == true"
    ionwall_approval_scope: "{{nodes.request_explicit_user_approval.outputs.approval_metadata_obj.granted_scopes[0]}}" # Use the scope granted
    inputs:
      dataset_cid: "{{trigger.input_data.dataset_cid_to_analyze}}"
      # ... other inputs for the analysis
    outputs: [analysis_result_cid]
# ...
```

## 11. Open Questions & Future Enhancements
*   **Standardized `action_details_cid` Schemas:** Defining common schemas for `action_details_cid` objects for frequently approved actions (e.g., "delete_file_action_details_schema", "spend_tokens_action_details_schema") could allow IONWALL UIs to render richer, more structured approval dialogs.
*   **Approval with Modifications/Parameters:** Could the user, via IONWALL, not just approve/deny but also suggest modifications to the action? E.g., "Approve spending, but limit to X C-ION instead of Y." This significantly increases complexity.
*   **Granular Scopes for this Transform:** Should this transform itself require a specific IONWALL scope to even *request* an explicit approval for other scopes? E.g., an agent needs "request_ionwall_explicit_approval" scope to use this transform. (Assumed yes, implicitly part of agent's manifest).
*   **"Remember my choice" / Pre-approval for Specific Actions:** How does this interact with IONWALL's broader consent management for pre-approving certain actions for certain agents? This transform is more for *exceptions* or *specific high-value instances*.
*   **Offline Approval Handling:** What if the user is offline? The request might time out. Could IONWALL queue approval requests for when the user is next online (if not time-sensitive)?
*   **Differentiated UI based on Urgency/Sensitivity:** How IONWALL UIs adapt their presentation based on `urgency` or other risk factors.
*   **Integration with Hybrid Layer for Complex Approvals:** For actions requiring multiple approvers or complex review, IONWALL might escalate the approval request initiated by this transform to a Hybrid Layer workflow.
