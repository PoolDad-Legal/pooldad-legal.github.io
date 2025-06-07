# Agent Blueprint: Wallet Ops Agent - v0.9.0

## 1. Overview

*   **Agent Name:** `Wallet Ops Agent`
*   **Version:** `0.9.0`
*   **Status:** `development`
*   **Primary Goal:** `Securely interacts with the user's IONWALLET (a separate, highly secure application or hardware component) to orchestrate operations like token transactions ($ION, C-ION, NFTs), cryptographic signing of data, and managing (or requesting access to) decentralized identity credentials (Verifiable Credentials - VCs). All operations are under strict IONWALL control and require explicit user consent via IONWALLET's own UI/HSM.`
*   **Key Features:**
    *   **Token Transfers:** Initiates requests to IONWALLET for transferring $ION, C-ION, and other fungible tokens or NFTs managed by IONWALLET.
    *   **NFT Operations:** Facilitates requests for NFT minting (if IONWALLET has minting capabilities or orchestrates with an NFT minter agent) and transfer of NFTs. Actual operations are confirmed and executed by IONWALLET.
    *   **Data Signing:** Requests IONWALLET to cryptographically sign data CIDs or messages using keys held securely within IONWALLET. The data to be signed is passed, but private keys never leave IONWALLET.
    *   **Verifiable Credentials (VCs):** Facilitates requests for presenting VCs stored in IONWALLET to relying parties, or for verifying VCs received from others (verification might use a VC_Verify_Transform).
    *   **Address Management (Read-Only):** Can request public addresses/keys from IONWALLET for specific purposes (e.g., to receive payments), with user consent.
    *   **Decoupling & Security:** Crucially, `Wallet Ops Agent` *does not* directly handle private keys or perform cryptographic operations itself. It acts as a standardized, auditable request broker between other IONFLUX agents and the user's IONWALLET, relying on IONWALLET for the ultimate security and user consent for each sensitive operation.
    *   **Transaction Logging:** Logs metadata of wallet operations (e.g., request type, parameters, transaction ID if returned, status) to IONPOD for user audit.

## 2. FluxGraph Definition (Conceptual YAML)

```yaml
# /specs/agents/wallet_ops_agent_fluxgraph.yaml (Conceptual representation)
# This agent will likely have multiple, distinct FluxGraphs for different operations,
# or a router to different sequences of IONWALLET_Request..._Transforms.
# We'll show one example for requesting a token transfer. Others (data signing, VC presentation) would follow a similar pattern.

version: "0.1.0"
name: "wallet_ops_request_token_transfer_fluxgraph" # Example for one operation
description: "Orchestrates a request to IONWALLET for a token transfer."

triggers:
  - type: "manual" # For direct testing by user/dev
  - type: "event_driven"
    config: { event_source: "NATS", topic: "ionflux.agents.wallet_ops.request_token_transfer" } # Triggered by other agents
  - type: "webhook"
    config: { path: "/webhooks/invoke/wallet_ops_request_transfer", method: "POST", authentication_method: "ionwall_jwt" }

input_schema:
  type: "object"
  properties:
    requesting_agent_id: { type: "string", description: "ID of the agent initiating this request (for audit)." }
    user_profile_cid_for_wallet_context: { type: "string", description: "CID of user's profile to help IONWALLET select the right wallet/account if multiple are managed."}

    # Token Transfer Specific:
    token_type: { type: "string", enum: ["fungible_ion", "fungible_c_ion", "nft_generic", "custom_fungible_token"], description: "Type of token to transfer." }
    token_contract_address_cid: { type: "string", nullable: true, description: "CID of IONPOD object containing contract address for custom tokens/NFTs." }
    token_id_for_nft: { type: "string", nullable: true, description: "Specific token ID if transferring an NFT." }
    recipient_address: { type: "string", description: "Public address of the recipient." }
    amount: { type: "string", description: "Amount of token to transfer (as string to handle large numbers/decimals precisely)." }
    transaction_purpose_cid: { type: "string", description: "CID of an IONPOD object detailing the purpose of the transaction (for user display in IONWALLET and audit log)." }
    # Other potential fields: gas_fee_limit_cid, transaction_memo_string
  required: [ "requesting_agent_id", "user_profile_cid_for_wallet_context", "token_type", "recipient_address", "amount", "transaction_purpose_cid" ]

output_schema: # Output for the token transfer request operation
  type: "object"
  properties:
    request_status: { type: "string", enum: ["pending_wallet_approval", "approved_by_wallet", "rejected_by_wallet", "failed_communication_with_wallet", "chain_submission_success", "chain_submission_failure", "transaction_confirmed", "transaction_failed_on_chain"], description: "Detailed status of the request and transaction."}
    transaction_id_on_chain: { type: "string", nullable: true, description: "Transaction hash/ID from the blockchain, if successful." }
    wallet_session_id: { type: "string", nullable: true, description: "Session ID for this interaction with IONWALLET." }
    error_message: { type: "string", nullable: true }
  required: [ "request_status" ]

graph:
  - id: "fetch_transaction_purpose_details"
    transform: "FetchFromIONPOD_Transform_IONWALL"
    ionwall_approval_scope: "read_pod_data:wallet_ops_transaction_metadata" # WalletOps needs to read metadata it will show to IONWALLET
    inputs:
      cid: "{{trigger.input_data.transaction_purpose_cid}}"
    outputs: [transaction_purpose_obj]

  - id: "fetch_token_contract_details_conditional"
    transform: "FetchFromIONPOD_Transform_IONWALL"
    if: "{{trigger.input_data.token_contract_address_cid != null}}"
    ionwall_approval_scope: "read_pod_data:wallet_ops_token_contract_info"
    inputs:
      cid: "{{trigger.input_data.token_contract_address_cid}}"
    outputs: [token_contract_obj] # e.g. { address: "0x...", chain_id: "..." }

  # This is the core transform that interacts with IONWALLET.
  # IONWALLET itself is a separate application/device that prompts the user for consent.
  - id: "initiate_wallet_interaction_for_transfer"
    transform: "IONWALLET_RequestTokenTransfer_Transform" # Specialized, secure transform
    # This transform handles:
    # 1. Securely packaging the request details.
    # 2. Sending the request to the user's registered IONWALLET instance (e.g., via OS-level IPC, secure enclave call, or a dedicated P2P encrypted channel).
    # 3. IONWALLET then takes over:
    #    a. Displays transaction details (recipient, amount, purpose from transaction_purpose_obj) to the user on its trusted UI.
    #    b. User approves/rejects via IONWALLET (e.g., biometrics, PIN, hardware button press).
    #    c. If approved, IONWALLET constructs, signs, and submits the transaction to the appropriate blockchain.
    # 4. This transform listens for asynchronous status updates from IONWALLET (e.g., "pending_approval", "approved_signing", "submitted_to_chain", "confirmed", "failed").
    ionwall_approval_scope: "interact_with_ionwallet:request_token_transfer" # Agent needs this high-level scope. IONWALLET handles fine-grained consent.
    inputs:
      user_wallet_context: { profile_cid: "{{trigger.input_data.user_profile_cid_for_wallet_context}}" }
      transaction_details: {
        token_type: "{{trigger.input_data.token_type}}",
        contract_address: "{{nodes.fetch_token_contract_details_conditional.outputs.token_contract_obj.address}}",
        token_id_nft: "{{trigger.input_data.token_id_for_nft}}",
        recipient_address: "{{trigger.input_data.recipient_address}}",
        amount_str: "{{trigger.input_data.amount}}",
        purpose_summary: "{{nodes.fetch_transaction_purpose_details.outputs.transaction_purpose_obj.summary}}",
        purpose_details_object: "{{nodes.fetch_transaction_purpose_details.outputs.transaction_purpose_obj}}"
        # blockchain_network_preference: from user profile or inferred from token type
      }
    outputs: [wallet_response_status_enum, chain_tx_id_if_any, wallet_interaction_error_msg, wallet_session_ref_id]
    # wallet_response_status_enum could be: "USER_APPROVED_SUBMITTED", "USER_REJECTED", "WALLET_ERROR_TIMEOUT", "CHAIN_SUBMISSION_FAILED" etc.

  - id: "log_wallet_operation_attempt"
    transform: "StoreToIONPOD_Transform_IONWALL"
    ionwall_approval_scope: "write_pod_data:wallet_ops_transaction_log"
    inputs:
      data_to_store: {
        timestamp: "{{system.timestamp_utc}}", agent_name: "Wallet Ops Agent", version: "0.9.0",
        operation_type: "token_transfer_request",
        requesting_agent_id: "{{trigger.input_data.requesting_agent_id}}",
        input_params_summary: { token: "{{trigger.input_data.token_type}}", to: "{{trigger.input_data.recipient_address}}", amount: "{{trigger.input_data.amount}}" },
        purpose_cid: "{{trigger.input_data.transaction_purpose_cid}}",
        wallet_status: "{{nodes.initiate_wallet_interaction_for_transfer.outputs.wallet_response_status_enum}}",
        chain_tx_id: "{{nodes.initiate_wallet_interaction_for_transfer.outputs.chain_tx_id_if_any}}",
        wallet_session_id: "{{nodes.initiate_wallet_interaction_for_transfer.outputs.wallet_session_ref_id}}",
        error_info: "{{nodes.initiate_wallet_interaction_for_transfer.outputs.wallet_interaction_error_msg}}"
      }
      filename_suggestion: "wallet_ops_log_transfer_{{system.timestamp_utc_iso}}.json"
    outputs: [log_entry_cid]

  - id: "publish_completion_event_nats" # Notify original requester
    transform: "IPC_NATS_Publish_Transform"
    inputs:
      topic: "ionflux.agents.wallet_ops.request_token_transfer.completion" # Specific completion topic
      message: # This is the output_schema of this FluxGraph
        request_status: "{{nodes.initiate_wallet_interaction_for_transfer.outputs.wallet_response_status_enum}}" # map this to the output_schema's enum
        transaction_id_on_chain: "{{nodes.initiate_wallet_interaction_for_transfer.outputs.chain_tx_id_if_any}}"
        wallet_session_id: "{{nodes.initiate_wallet_interaction_for_transfer.outputs.wallet_session_ref_id}}"
        error_message: "{{nodes.initiate_wallet_interaction_for_transfer.outputs.wallet_interaction_error_msg}}"
        log_cid: "{{nodes.log_wallet_operation_attempt.outputs.log_entry_cid}}"
        # Include a summary of the original request for context by the listener
        # original_request_summary: { token: "{{trigger.input_data.token_type}}", to: "{{trigger.input_data.recipient_address}}", amount: "{{trigger.input_data.amount}}" }
    dependencies: [log_wallet_operation_attempt]

# Other FluxGraphs for "request_data_signing", "request_vc_presentation" etc. would be structured similarly,
# using different IONWALLET_Request..._Transforms.
```

---
## 3. Database Schema Fields (`agent_definitions` table)

### 3.1. `agent_name`
`"Wallet Ops Agent"`

### 3.2. `version`
`"0.9.0"`

### 3.3. `description`
`"Securely interacts with the user's IONWALLET for operations like token transactions ($ION, C-ION, NFTs), cryptographic signing of data, and managing decentralized identity credentials. All operations are under strict IONWALL control and require explicit user consent via IONWALLET's UI."`

### 3.4. `status`
`"development"`

### 3.5. `flux_graph_dsl_yaml`
*(The YAML content for `wallet_ops_request_token_transfer_fluxgraph` from Section 2 is inserted here. Other operation types like data signing would be separate FluxGraphs or a more complex routed one.)*
```yaml
version: "0.1.0"
name: "wallet_ops_request_token_transfer_fluxgraph"
description: "Orchestrates a request to IONWALLET for a token transfer."

triggers:
  - type: "manual"
  - type: "event_driven"
    config: { event_source: "NATS", topic: "ionflux.agents.wallet_ops.request_token_transfer" }
  - type: "webhook"
    config: { path: "/webhooks/invoke/wallet_ops_request_transfer", method: "POST", authentication_method: "ionwall_jwt" }

input_schema:
  type: "object"
  properties:
    requesting_agent_id: { type: "string", description: "ID of the agent initiating this request." }
    user_profile_cid_for_wallet_context: { type: "string", description: "CID of user's profile for IONWALLET context."}
    token_type: { type: "string", enum: ["fungible_ion", "fungible_c_ion", "nft_generic", "custom_fungible_token"], description: "Type of token." }
    token_contract_address_cid: { type: "string", nullable: true, description: "CID for contract address object." }
    token_id_for_nft: { type: "string", nullable: true, description: "Token ID for NFT." }
    recipient_address: { type: "string", description: "Recipient's public address." }
    amount: { type: "string", description: "Amount to transfer." }
    transaction_purpose_cid: { type: "string", description: "CID for transaction purpose details." }
  required: [ "requesting_agent_id", "user_profile_cid_for_wallet_context", "token_type", "recipient_address", "amount", "transaction_purpose_cid" ]

output_schema:
  type: "object"
  properties:
    request_status: { type: "string", enum: ["pending_wallet_approval", "approved_by_wallet", "rejected_by_wallet", "failed_communication_with_wallet", "chain_submission_success", "chain_submission_failure", "transaction_confirmed", "transaction_failed_on_chain"], description: "Detailed status."}
    transaction_id_on_chain: { type: "string", nullable: true, description: "Blockchain transaction hash/ID." }
    wallet_session_id: { type: "string", nullable: true, description: "Session ID for IONWALLET interaction." }
    error_message: { type: "string", nullable: true }
  required: [ "request_status" ]

graph:
  - id: "fetch_transaction_purpose_details"
    transform: "FetchFromIONPOD_Transform_IONWALL"
    ionwall_approval_scope: "read_pod_data:wallet_ops_transaction_metadata"
    inputs:
      cid: "{{trigger.input_data.transaction_purpose_cid}}"
    outputs: [transaction_purpose_obj]

  - id: "fetch_token_contract_details_conditional"
    transform: "FetchFromIONPOD_Transform_IONWALL"
    if: "{{trigger.input_data.token_contract_address_cid != null}}"
    ionwall_approval_scope: "read_pod_data:wallet_ops_token_contract_info"
    inputs:
      cid: "{{trigger.input_data.token_contract_address_cid}}"
    outputs: [token_contract_obj]

  - id: "initiate_wallet_interaction_for_transfer"
    transform: "IONWALLET_RequestTokenTransfer_Transform"
    ionwall_approval_scope: "interact_with_ionwallet:request_token_transfer"
    inputs:
      user_wallet_context: { profile_cid: "{{trigger.input_data.user_profile_cid_for_wallet_context}}" }
      transaction_details: {
        token_type: "{{trigger.input_data.token_type}}",
        contract_address: "{{nodes.fetch_token_contract_details_conditional.outputs.token_contract_obj.address}}",
        token_id_nft: "{{trigger.input_data.token_id_for_nft}}",
        recipient_address: "{{trigger.input_data.recipient_address}}",
        amount_str: "{{trigger.input_data.amount}}",
        purpose_summary: "{{nodes.fetch_transaction_purpose_details.outputs.transaction_purpose_obj.summary}}",
        purpose_details_object: "{{nodes.fetch_transaction_purpose_details.outputs.transaction_purpose_obj}}"
      }
    outputs: [wallet_response_status_enum, chain_tx_id_if_any, wallet_interaction_error_msg, wallet_session_ref_id]

  - id: "log_wallet_operation_attempt"
    transform: "StoreToIONPOD_Transform_IONWALL"
    ionwall_approval_scope: "write_pod_data:wallet_ops_transaction_log"
    inputs:
      data_to_store: {
        timestamp: "{{system.timestamp_utc}}", agent_name: "Wallet Ops Agent", version: "0.9.0",
        operation_type: "token_transfer_request",
        requesting_agent_id: "{{trigger.input_data.requesting_agent_id}}",
        input_params_summary: { token: "{{trigger.input_data.token_type}}", to: "{{trigger.input_data.recipient_address}}", amount: "{{trigger.input_data.amount}}" },
        purpose_cid: "{{trigger.input_data.transaction_purpose_cid}}",
        wallet_status: "{{nodes.initiate_wallet_interaction_for_transfer.outputs.wallet_response_status_enum}}",
        chain_tx_id: "{{nodes.initiate_wallet_interaction_for_transfer.outputs.chain_tx_id_if_any}}",
        wallet_session_id: "{{nodes.initiate_wallet_interaction_for_transfer.outputs.wallet_session_ref_id}}",
        error_info: "{{nodes.initiate_wallet_interaction_for_transfer.outputs.wallet_interaction_error_msg}}"
      }
      filename_suggestion: "wallet_ops_log_transfer_{{system.timestamp_utc_iso}}.json"
    outputs: [log_entry_cid]

  - id: "publish_completion_event_nats"
    transform: "IPC_NATS_Publish_Transform"
    inputs:
      topic: "ionflux.agents.wallet_ops.request_token_transfer.completion"
      message:
        request_status: "{{nodes.initiate_wallet_interaction_for_transfer.outputs.wallet_response_status_enum}}"
        transaction_id_on_chain: "{{nodes.initiate_wallet_interaction_for_transfer.outputs.chain_tx_id_if_any}}"
        wallet_session_id: "{{nodes.initiate_wallet_interaction_for_transfer.outputs.wallet_session_ref_id}}"
        error_message: "{{nodes.initiate_wallet_interaction_for_transfer.outputs.wallet_interaction_error_msg}}"
        log_cid: "{{nodes.log_wallet_operation_attempt.outputs.log_entry_cid}}"
    dependencies: [log_wallet_operation_attempt]
```

### 3.6. `execution_requirements_json`
```json
{
  "transforms_required": [
    "FetchFromIONPOD_Transform_IONWALL",
    // Each IONWALLET operation needs a dedicated, highly secure transform:
    "IONWALLET_RequestTokenTransfer_Transform",
    "IONWALLET_RequestDataSigning_Transform",
    "IONWALLET_RequestVC colorChoice_Transform", // For Selective Disclosure
    "IONWALLET_VerifyVCSignature_Transform", // If verifying VCs
    "StoreToIONPOD_Transform_IONWALL",
    "IPC_NATS_Publish_Transform"
  ],
  "min_ram_mb": 256, // These are mostly orchestration, IONWALLET app itself is separate
  "gpu_required": false,
  "estimated_execution_duration_seconds": 5, // For the agent's part; actual transaction time depends on user & blockchain
  "max_concurrent_instances": 10, // Can handle many concurrent requests to IONWALLET
  "wasm_modules_cids": {
    "FetchFromIONPOD_Transform_IONWALL": "bafyreibvlobj2rl34gsgxrjltirqesqkfbhtharb3uaxnri3ebpmpah6ce",
    "IONWALLET_RequestTokenTransfer_Transform": "bafyreihs5clst36ftnvyxfn6kolmmmq74qt3vjq7x5xuzg7s3y5lcwzfdq", // Placeholder - CRITICAL, needs extreme security review
    "IONWALLET_RequestDataSigning_Transform": "bafyreig4f5j3kduyszpuxkgymbusmeemf3s3mc7jchcmpmprqjjszslxzy", // Placeholder - CRITICAL
    "IONWALLET_RequestVCChoice_Transform": "bafyreif6v7n2s4z5kxj3lqomnsjzpxvjhcgy5jkvz6wz3a4hmsy7xqzr7m", // Placeholder - CRITICAL
    "StoreToIONPOD_Transform_IONWALL": "bafyreif7yqivqtkjhhwb5xkxqj3j7gyjlrvfkhhvjvbfffj4u7m5kfefbi",
    "IPC_NATS_Publish_Transform": "bafyreihyrz7wgld5qrjmejbdjcbcm3jqrjshxphu6jnlxhnlfbk7d745xy"
  }
}
```

### 3.7. `ecosystem_integration_points_json`
```json
{
  "ionwall_permissions_needed": [
    "read_pod_data:wallet_ops_transaction_metadata", // For transaction purpose, contract details etc.
    "read_pod_data:wallet_ops_token_contract_info",
    "read_pod_data:wallet_ops_data_to_be_signed",   // For data signing operations
    "interact_with_ionwallet:request_token_transfer", // High-level scope for WalletOps to talk to IONWALLET for transfers
    "interact_with_ionwallet:request_data_signing",   // Scope for data signing
    "interact_with_ionwallet:request_vc_presentation", // Scope for VC operations
    "write_pod_data:wallet_ops_transaction_log",    // For audit logging
    "write_pod_data:wallet_ops_signed_data_output"  // For storing results of signing
  ],
  "ionpod_data_access": {
    "inputs": [
      { "cid_param": "transaction_purpose_cid", "access_type": "read", "purpose": "To load details about the purpose of a transaction for user display in IONWALLET." },
      { "cid_param": "token_contract_address_cid", "access_type": "read", "purpose": "To load contract address details for custom tokens or NFTs." },
      { "cid_param": "data_to_sign_cid (for signing ops)", "access_type": "read", "purpose": "To load data that needs to be signed." }
    ],
    "outputs": [
      { "cid_name": "log_entry_cid", "access_type": "write", "purpose": "To store logs of wallet operations." },
      { "cid_name": "signed_data_artifact_cid (for signing ops)", "access_type": "write", "purpose": "To store the signature or the signed data object." }
    ]
  },
  "tokenomic_triggers": [
    // Wallet operations themselves (L1 transactions) have their own gas fees.
    // Tokenomic events here are for the service provided by Wallet Ops Agent / IONFLUX.
    { "event": "wallet_ops_successful_token_transfer_request_processed", "action": "debit_user_service_fee", "token_id": "C-ION", "amount_formula": "0.002" }, // Small fee for orchestration service
    { "event": "wallet_ops_successful_data_signing_request_processed", "action": "debit_user_service_fee", "token_id": "C-ION", "amount_formula": "0.001" },
    { "event": "wallet_ops_successful_vc_presentation_request_processed", "action": "debit_user_service_fee", "token_id": "C-ION", "amount_formula": "0.0005" }
  ],
  "techgnosis_integration": {
    "knowledge_graph_queries": [
      "get_recipient_wallet_risk_score:{{trigger.input_data.recipient_address}}", // Before transfer, check against known scam addresses
      "get_nft_collection_details_from_contract_address:{{nodes.fetch_token_contract_details_conditional.outputs.token_contract_obj.address}}", // For user display
      "get_vc_issuer_reputation:{{vc_to_present.issuer_did}}" // For VC operations
    ],
    "transaction_pattern_analysis_for_fraud_detection": true, // TechGnosis observes patterns (not content) of WalletOps requests to flag unusual activity for Hybrid Layer.
    "semantic_meaning_of_transaction_purpose": true // TechGnosis can categorize transaction purposes for user's financial overview.
  },
  "hybrid_layer_escalation_points": [
    { "condition": "repeated_failed_transactions_to_same_address_or_contract", "action": "notify_user_and_escalate_to_hybrid_layer_for_potential_issue_investigation" },
    { "condition": "request_for_exceptionally_large_token_transfer_exceeds_user_defined_threshold_or_historical_pattern", "action": "require_additional_hybrid_layer_step_up_authentication_or_manual_approval_via_ionwallet_extension" },
    { "condition": "suspected_phishing_attempt_via_data_signing_request_payload_looks_like_a_transaction", "action": "block_request_and_alert_user_via_hybrid_layer_and_ionwallet_notification" },
    { "condition": "dispute_over_nft_transfer_or_vc_presentation", "action": "initiate_hybrid_layer_dispute_resolution_protocol" }
  ],
  "carbon_loop_contribution": {
    "type": "blockchain_choice_optimization_support",
    "value_formula": "user_selection_of_low_carbon_l2_or_chain_factor * transaction_complexity_score",
    "description": "If interacting with multiple blockchains, Wallet Ops Agent (guided by TechGnosis and user preference) could help route transactions through more energy-efficient L1s/L2s when options exist for the same asset or outcome. This is highly dependent on IONWALLET capabilities and ecosystem support for multiple chains."
  }
}
```

### 3.8. `prm_details_json`
```json
{
  "default_user_profile_cid_if_not_provided": null, // Should usually be provided by caller
  "preferred_ion_l1_rpc_node_cid": "bafk... (CID of config for primary ION L1 RPC)",
  "preferred_ethereum_l1_rpc_node_cid": "bafk... (CID of config for an Eth L1 RPC, if used)",
  "max_retries_for_wallet_communication_timeout": 2,
  "default_timeout_for_ionwallet_response_seconds": 120, // User needs time to react to IONWALLET prompt
  "log_full_transaction_payload_locally": false, // Security: default to false, only log metadata
  "user_customizable_params_for_requests": [ // Fields from input_schema that users can typically set
    "token_type", "token_contract_address_cid", "token_id_for_nft",
    "recipient_address", "amount", "transaction_purpose_cid",
    "data_to_sign_cid", "key_id_hint_for_signing", // For signing operations
    "vc_query_cid", "relying_party_did" // For VC operations
  ]
}
```

### 3.9. `input_schema_json`
*(The JSON content of `input_schema` for `wallet_ops_request_token_transfer_fluxgraph` from Section 2 is inserted here)*
```json
{
  "type": "object",
  "properties": {
    "requesting_agent_id": { "type": "string", "description": "ID of the agent initiating this request (for audit)." },
    "user_profile_cid_for_wallet_context": { "type": "string", "description": "CID of user's profile to help IONWALLET select the right wallet/account if multiple are managed." },
    "token_type": { "type": "string", "enum": ["fungible_ion", "fungible_c_ion", "nft_generic", "custom_fungible_token"], "description": "Type of token to transfer." },
    "token_contract_address_cid": { "type": "string", "nullable": true, "description": "CID of IONPOD object containing contract address for custom tokens/NFTs." },
    "token_id_for_nft": { "type": "string", "nullable": true, "description": "Specific token ID if transferring an NFT." },
    "recipient_address": { "type": "string", "description": "Public address of the recipient." },
    "amount": { "type": "string", "description": "Amount of token to transfer (as string to handle large numbers/decimals precisely)." },
    "transaction_purpose_cid": { "type": "string", "description": "CID of an IONPOD object detailing the purpose of the transaction (for user display in IONWALLET and audit log)." }
  },
  "required": [ "requesting_agent_id", "user_profile_cid_for_wallet_context", "token_type", "recipient_address", "amount", "transaction_purpose_cid" ]
}
```

### 3.10. `output_schema_json`
*(The JSON content of `output_schema` for `wallet_ops_request_token_transfer_fluxgraph` from Section 2 is inserted here)*
```json
{
  "type": "object",
  "properties": {
    "request_status": { "type": "string", "enum": ["pending_wallet_approval", "approved_by_wallet", "rejected_by_wallet", "failed_communication_with_wallet", "chain_submission_success", "chain_submission_failure", "transaction_confirmed", "transaction_failed_on_chain"], "description": "Detailed status of the request and transaction." },
    "transaction_id_on_chain": { "type": "string", "nullable": true, "description": "Transaction hash/ID from the blockchain, if successful." },
    "wallet_session_id": { "type": "string", "nullable": true, "description": "Session ID for this interaction with IONWALLET." },
    "error_message": { "type": "string", "nullable": true }
  },
  "required": [ "request_status" ]
}
```

### 3.11. `trigger_config_json`
```json
{
  "manual_trigger_enabled": true, // For testing specific operations
  "event_driven_triggers": [
    {
      "event_source": "NATS",
      "topic": "ionflux.agents.wallet_ops.request_token_transfer",
      "description": "Trigger for token transfer requests. Payload must match input_schema for token transfers.",
      "input_mapping_jmespath": "payload"
    },
    {
      "event_source": "NATS",
      "topic": "ionflux.agents.wallet_ops.request_data_signing",
      "description": "Trigger for data signing requests. Payload must match input_schema for data signing.",
      "input_mapping_jmespath": "payload"
    }
    // ... other triggers for other wallet operations (VCs, etc.)
  ],
  "webhook_triggers": [
     {
      "endpoint_path": "/webhooks/invoke/wallet_ops", // A single endpoint, operation type specified in body
      "http_method": "POST",
      "authentication_method": "ionwall_jwt_scoped_for_wallet_ops",
      "description": "HTTP endpoint for various wallet operations. Request body must include operation_type and then match relevant input_schema."
    }
  ]
}
```

### 3.12. `deployment_info_json`
```json
{
  "runtime_environment": "IONFLUX_EdgeNode_Wasm_SecureEnclave_Preferred", // Prefers runtime with strong isolation if available for these sensitive ops
  "current_instances_managed_by_ionflux_controller": true,
  "default_replicas": 1, // Usually low concurrency, as each op requires user interaction with IONWALLET
  "auto_scaling_policy": {
    "min_replicas": 1,
    "max_replicas": 3, // Limited scaling due to user interaction bottleneck
    "pending_requests_threshold_per_instance": 5 // If requests can queue briefly waiting for IONWALLET interaction
  }
}
```

### 3.13. `logging_json`
```json
{
  "log_level": "info",
  "log_targets": ["ionpod_event_log_wallet_ops", "system_audit_trail_financial_if_applicable", "local_stdout_dev_mode_only"],
  "log_retention_policy_days_wallet_ops": 365, // Financial/security logs often need long retention
  "sensitive_fields_to_mask_in_log": ["transaction_details.amount_str", "recipient_address_full", "token_id_for_nft_full_value_if_sensitive"]
}
```

### 3.14. `monitoring_json`
```json
{
  "metrics_to_collect": [
    "wallet_op_request_count_by_type", "wallet_op_success_rate_ionwallet_comm", "wallet_op_failure_rate_ionwallet_comm",
    "chain_submission_success_rate_by_type", "chain_submission_failure_rate_by_type",
    "avg_ionwallet_response_time_ms", "avg_blockchain_confirmation_time_ms_if_tracked"
  ],
  "metrics_endpoint_ionwall_protected": "/metrics/wallet_ops_agent",
  "health_check_protocol": "check_connectivity_to_ionwallet_proxy_or_service_and_rpc_nodes",
  "alerting_rules": [
    {"metric": "wallet_op_failure_rate_ionwallet_comm", "condition": "value > 0.1 for 30m", "severity": "critical", "notification_channel": "hybrid_layer_ops_pager_ionwallet_integration_issue"},
    {"metric": "chain_submission_failure_rate_fungible_ion", "condition": "value > 0.05 for 1h", "severity": "warning", "notification_channel": "hybrid_layer_ops_team_chat_blockchain_issues"}
  ]
}
```

### 3.15. `security_json`
```json
{
  "data_encryption_at_rest_ionpod_for_logs": true,
  "data_encryption_in_transit_to_ionwallet_protocol_cid": "bafk... (CID of spec for secure IONWALLET communication protocol)",
  "private_key_handling_policy": "NO_PRIVATE_KEYS_HANDLED_BY_AGENT_EVER_ALL_OPS_DEFERRED_TO_IONWALLET",
  "ionwallet_communication_transform_security_attestation_cid": "bafk... (CID of security audit report for IONWALLET_Request..._Transforms)",
  "max_transaction_value_threshold_for_standard_flow_ion": "10000", // Amounts above this might trigger stricter Hybrid Layer checks in PRM/Policy
  "required_ionwall_consent_scopes_for_wallet_ops_agent_itself": [
    // These are for Wallet Ops Agent's own operations, not for the transactions themselves (which IONWALLET gates).
    "read_pod_data:wallet_ops_transaction_metadata", "read_pod_data:wallet_ops_token_contract_info",
    "read_pod_data:wallet_ops_data_to_be_signed",
    "write_pod_data:wallet_ops_transaction_log", "write_pod_data:wallet_ops_signed_data_output",
    // The "interact_with_ionwallet:*" scopes are the critical ones that allow this agent to send requests TO IONWALLET.
    // IONWALLET then has its own UI and consent mechanism for each specific operation (transfer, sign, etc.).
    "interact_with_ionwallet:request_token_transfer",
    "interact_with_ionwallet:request_data_signing",
    "interact_with_ionwallet:request_vc_presentation"
  ],
  "sensitive_data_handling_policy_id": "SDP-WALLETOPS-001"
}
```

---
## 4. User Experience Flow (Conceptual)

**Scenario: Agent A (e.g., an NFT Marketplace Agent) needs to facilitate User transferring an NFT to Buyer.**
1.  **Initiation:** `Agent A` has confirmed a sale. It triggers `Wallet Ops Agent` via NATS:
    `{ requesting_agent_id: "AgentA_ID", user_profile_cid_for_wallet_context: "UserProfileCID_Seller", token_type: "nft_generic", token_contract_address_cid: "NFTContractCID", token_id_for_nft: "NFT_Token_ID_123", recipient_address: "Buyer_Wallet_Address", transaction_purpose_cid: "SalePurposeCID_Details_of_Sale_Item" }`.
2.  **Wallet Ops Agent Processing:**
    *   `Wallet Ops Agent`'s `wallet_ops_request_token_transfer_fluxgraph` is triggered.
    *   It fetches details from `SalePurposeCID_Details_of_Sale_Item` and `NFTContractCID` via IONPOD (with IONWALL approval).
3.  **IONWALL Checkpoint (High-Level Orchestration Consent):**
    *   IONWALL prompts User (Seller), potentially on their IONFLUX Canvas: *"Wallet Ops Agent, on behalf of NFT Marketplace Agent, wants to:
        *   Prepare a request for your IONWALLET to transfer NFT '{{NFT_Token_ID_123}}' from contract '{{NFTContractName}}' to '{{Buyer_Wallet_Address_Short}}' for the purpose of '{{SalePurposeSummary}}'.
        *   This will involve interacting with your IONWALLET.
        Allow Wallet Ops Agent to proceed with this request?"*
    *   *Note: This IONWALL consent is for `Wallet Ops Agent` to *talk* to `IONWALLET`. The actual transaction approval happens *inside* `IONWALLET`.*
4.  **Interaction with IONWALLET (via `IONWALLET_RequestTokenTransfer_Transform`):**
    *   If User approves in IONFLUX, the transform sends the structured request to the User's IONWALLET application/device.
    *   **IONWALLET UI Activation:** The IONWALLET application activates on the user's trusted device (e.g., phone, hardware wallet display). It shows:
        *   "Action Requested: Transfer NFT"
        *   "NFT Name/Image: [Image of NFT_Token_ID_123]"
        *   "From Contract: [NFTContractName] ([NFTContractAddress_Short])"
        *   "To: [Buyer_Wallet_Address]"
        *   "Purpose: Sale of 'Awesome Digital Art Piece' on NFT Marketplace."
        *   "Estimated Network Fee: X $ION / Y ETH"
        *   "[Approve Button] [Reject Button]"
    *   User reviews details *on the IONWALLET's trusted display* and physically approves (e.g., biometric scan, PIN entry on device, hardware button press).
5.  **Transaction & Confirmation:**
    *   If approved in IONWALLET, IONWALLET signs and submits the transaction to the blockchain.
    *   IONWALLET sends status updates (e.g., "submitted", "confirmed", "failed") back to `IONWALLET_RequestTokenTransfer_Transform`.
6.  **Wallet Ops Agent Logging & Notification:**
    *   `Wallet Ops Agent` receives the final status from the transform.
    *   Logs the outcome (e.g., success, transaction hash) to the Seller's IONPOD.
    *   Publishes a NATS completion event, which `Agent A` (Marketplace Agent) receives to finalize the sale record.

---
## 5. TechGnosis & Hybrid Layer Integration Notes

*   **TechGnosis:**
    *   **Risk Scoring:** Before `Wallet Ops Agent` even sends a request to IONWALLET, TechGnosis could analyze the `recipient_address` or `token_contract_address_cid` against known scam/malicious addresses or risky smart contracts in its knowledge graph. If a high risk is detected, it could warn `Wallet Ops Agent`, which might then include a warning in the data sent to IONWALLET for user display, or even suggest Hybrid Layer review.
    *   **Transaction Pattern Analysis:** TechGnosis can observe anonymized metadata patterns of `Wallet Ops Agent` requests (e.g., frequency, typical amounts, types of tokens per user segment) to detect anomalies that might indicate a compromised agent or unusual user behavior, flagging this for potential Hybrid Layer review.
    *   **NFT/Token Metadata Enrichment:** For NFT transfers or interactions with custom tokens, TechGnosis can fetch and provide richer metadata (e.g., NFT image, collection name, token description) from the `token_contract_address_cid` or `token_id_for_nft` to be displayed in the IONWALLET confirmation UI, improving user confidence.
*   **Hybrid Layer:**
    *   **Dispute Resolution:** If a user claims a transaction was unauthorized or incorrect (despite IONWALLET approval), a dispute resolution process managed by the Hybrid Layer can be initiated. Logs from `Wallet Ops Agent` and IONWALLET would be critical evidence.
    *   **High-Value Transaction Review:** For transactions exceeding a user-defined threshold or flagged as unusual by TechGnosis, `Wallet Ops Agent` (or IONWALLET itself) could be configured to require an additional "step-up" approval from a human via a Hybrid Layer task before the transaction is submitted to the chain. This could involve a video call or answering security questions.
    *   **Recovery Assistance:** In cases of lost IONWALLET access (where recovery mechanisms exist for IONWALLET itself), the Hybrid Layer might play a role in verifying user identity to assist in the IONWALLET's recovery procedures, before `Wallet Ops Agent` can resume interactions.

---
## 6. Carbon Loop Integration Notes

*   **Blockchain Choice Awareness:** If IONWALLET and the sNetwork support multiple blockchains (L1s, L2s) for certain assets:
    *   `Wallet Ops Agent`, guided by TechGnosis and user preferences (e.g., "prefer low carbon impact"), could query for the estimated carbon footprint or energy efficiency of transacting on different compatible chains for a given operation.
    *   This information could be presented to the user within the IONWALLET UI when approving a transaction, allowing them to choose a "greener" option if available.
*   **Optimizing Transaction Batching (Conceptual):** For scenarios where an agent needs to make multiple small payments or distributions, `Wallet Ops Agent` could potentially interface with a "TransactionBatching_Service_Transform" that collects multiple requests and uses a smart contract (on a supported L1/L2) to disburse them more efficiently, reducing per-transaction overhead and thus overall network energy use. This is an advanced concept.

---
## 7. Dependencies & Interactions

*   **Required Transforms:**
    *   `FetchFromIONPOD_Transform_IONWALL` (for fetching metadata like transaction purpose, contract details).
    *   **`IONWALLET_RequestTokenTransfer_Transform`**: Specialized, highly secure transform that acts as a bridge to the user's IONWALLET application/device for token transfers.
    *   **`IONWALLET_RequestDataSigning_Transform`**: Similar bridge for data signing requests.
    *   **`IONWALLET_RequestVCChoice_Transform`**: Similar bridge for Verifiable Credential presentation requests.
    *   **`IONWALLET_VerifyVCSignature_Transform`**: If WalletOps needs to verify an incoming VC.
    *   `StoreToIONPOD_Transform_IONWALL` (for audit logging).
    *   `IPC_NATS_Publish_Transform` (for completion events).
*   **Interacting Agents (Conceptual):**
    *   Triggered by any agent needing to perform wallet operations on behalf of the user (e.g., `MarketplaceAgent` for sales/payouts, `ServiceSubscriptionAgent` for payments, `DAOManagerAgent` for distributing voting tokens or rewards, any agent needing data signed or VCs presented).
    *   Relies heavily on the **`IONWALLET` application/device** (which is NOT an IONFLUX agent but a separate, trusted user client).
    *   May provide signed data CIDs to `AttestationAgent` or `NotaryAgent`.
*   **External Systems (Indirectly via IONWALLET):**
    *   Various blockchains (ION sNetwork L1, Ethereum, Polygon, etc.) that IONWALLET supports.

---
## 8. Open Questions & Future Considerations

*   **IONWALLET Communication Protocol:** Defining a secure, standardized, and potentially versioned communication protocol between `IONWALLET_Request..._Transforms` and the IONWALLET application/device is paramount. This includes message encryption, authentication, and prevention of replay attacks.
*   **Transaction State Management & Monitoring:** For blockchain transactions, handling pending states, confirmations (with configurable confirmation counts), failures, and timeouts robustly. This might involve a separate "BlockchainMonitorAgent" that WalletOps subscribes to.
*   **Support for Various Blockchains/L2s:** How are new blockchains or L2 solutions added to IONWALLET and made accessible via `Wallet Ops Agent`? This implies updates to IONWALLET and potentially new types of `IONWALLET_Request..._Transforms`.
*   **Cross-Chain Operations:** Facilitating more complex cross-chain atomic swaps or interactions.
*   **DeFi Interactions:** Requesting IONWALLET to interact with DeFi protocols (e.g., staking, lending, liquidity provision). This would require new, highly specialized `IONWALLET_RequestDeFi..._Transforms`.
*   **Key Derivation & Management within IONWALLET:** While WalletOps doesn't handle keys, IONWALLET needs robust key derivation (e.g., HD wallet paths) so it can use the "right" key for a given request or DApp context. WalletOps might pass hints for this.
*   **Gas Fee Estimation & Management:** Providing users with accurate gas fee estimates within IONWALLET before approval, and allowing them to set limits or choose fee levels. `Wallet Ops Agent` might fetch current gas prices to assist.
*   **Hardware Wallet Integration with IONWALLET:** Ensuring the communication protocol and transforms are compatible with IONWALLET instances running on hardware wallets.
*   **Standard for "Purpose of Transaction" Objects:** Defining a schema for `transaction_purpose_cid` objects to ensure clarity for users in IONWALLET.
*   **Batching Wallet Operations:** Allowing an agent to request a batch of operations (e.g., multiple signatures, multiple small transfers) to be approved once in IONWALLET, if the UI/UX can support this safely.
