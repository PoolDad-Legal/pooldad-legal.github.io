```markdown
# n8n Workflow Mock Specifications: Chat Brief Butler (E2E Demo)

This document provides specifications for the n8n workflow mock for the Chat Brief Butler agent (AGENTE 007 - Slack Brief Butler, adapted for generic chat), specifically for the E2E demo. This mock simulates the agent's behavior of summarizing chat messages and posting a brief.

## General Workflow Notes:

*   **Workflow Naming:** The n8n workflow should be named "E2E Demo Mock: Chat Brief Butler".
*   **Environment Variables:**
    *   `AGENT_SERVICE_BASE_URL`: Base URL for the Agent Service (e.g., `http://localhost:8002`).
    *   `CHAT_SERVICE_INTERNAL_BASE_URL`: Base URL for internal Chat Service endpoints (e.g., `http://localhost:8001`).
*   **Error Handling:** For the E2E demo, the workflow will primarily focus on the success path. Production workflows would require comprehensive error handling at each step, including appropriate callbacks to the Agent Service with a "failed" status and error messages.

## 1. Chat Brief Butler (AGENTE 007) n8n Workflow Mock

### 1.1. Trigger (Webhook Node - "Start")

*   **Description:** "Webhook trigger for the Chat Brief Butler agent mock. Receives run details, the effective agent configuration (including the brief structure prompt), and runtime parameters (chat messages content and target channel ID) from the Agent Service."
*   **Method:** POST
*   **Path:** (Defined by n8n when the webhook is created, e.g., `/webhook/chat-brief-butler-mock`). This URL needs to be configured in the `AgentDefinition` for this agent.
*   **Authentication:** For the demo, a simple shared secret passed in the header or relying on network security might suffice. Production would require robust webhook security.
*   **Expected Input Data (JSON Body from Agent Service):**
    ```json
    {
      "run_id": "unique_run_identifier_from_agent_service", // e.g., "run_chatbrief_12345"
      "agent_configuration_id": "config_id_for_this_agent_instance", // e.g., "agentconfig_butler_abc"
      "workspace_id": "user_workspace_id", // e.g., "ws_xyz789"
      "user_id": "triggering_user_id", // User who invoked the agent command, e.g., "user_jane_doe"
      "effective_config": {
        // This object is the result of AgentService merging AgentConfiguration.yaml_config
        // with any runtime_params provided during invocation.

        // --- From AgentConfiguration.yaml_config (examples) ---
        "input_brief_structure_prompt_template": "Please summarize the key discussion points from the provided text. Structure the summary into the following sections: \n1. Key Decisions Made: \n2. Main Action Items (and responsible persons if mentioned): \n3. Open Questions or Points for Follow-up:",
        "input_output_language_for_brief": "en", // For mock, informational
        "input_max_brief_length_tokens": 500, // For mock, informational
        "input_llm_model_preference_for_briefing": "claude-3-haiku", // For mock, informational

        // --- From runtime_params (passed by Chat Service via Agent Service) ---
        "runtime_chat_messages_content": "Alice: Okay team, we need to finalize the Q4 roadmap. Bob: I think project Phoenix should be top priority. Charlie: Agreed, but we need to allocate resources for project Eagle too. Alice: Good point. Let's assign 60% resources to Phoenix, 40% to Eagle. Bob: I'll take the lead on Phoenix. Charlie: I can manage Eagle. Dave: When do we need the detailed project plans? Alice: End of next week. Bob: Roger.",
        "runtime_target_channel_id": "C12345ABCDE", // The ID of the chat channel where the brief should be posted
        "runtime_user_mention_ids_for_action_items": ["U012ABC3DE", "U012DEF4FG"] // Optional array of user IDs to @mention
      }
    }
    ```
*   **Note:** "The `effective_config` object is critical. `input_brief_structure_prompt_template` comes from the agent's persistent configuration. `runtime_chat_messages_content` (the actual text to be summarized) and `runtime_target_channel_id` are provided at invocation time by the Chat Service (forwarded by Agent Service) and are essential for this workflow's operation."

### 1.2. Core Workflow Steps (n8n Nodes)

#### 1.2.1. Node: Simulate LLM Summarization
*   **Type:** Function Node
*   **Name:** "Simulate LLM - Generate Brief"
*   **Logic:**
    *   Retrieves `input_brief_structure_prompt_template` and `runtime_chat_messages_content` from the incoming `effective_config` (e.g., `$json.webhook.body.effective_config.input_brief_structure_prompt_template`).
    *   **Mock Summarization Implementation:**
        *   The primary goal for the mock is to demonstrate that the `input_brief_structure_prompt_template` and `runtime_chat_messages_content` are used.
        *   A simple approach:
            1.  Extract keywords from the prompt like "Key Decisions", "Action Items", "Open Questions".
            2.  Iterate through `runtime_chat_messages_content` (e.g., split by lines or sentences).
            3.  If a line seems relevant to a keyword (e.g., "decide", "assign" for "Key Decisions"; "I'll take", "manage" for "Action Items"), append it under that section in the markdown.
            4.  If no keywords are easily matched from the prompt, create a generic summary: "### Summary\n{{first few lines of content}}\n### Action Items (mocked)\n- Review the full discussion for details."
        *   The output should be a single markdown string.
    *   **Conceptual Input to LLM (if it were real):** The prompt would be a combination of the `input_brief_structure_prompt_template` and the `runtime_chat_messages_content`.
    *   **Output of this Node (JSON object):**
        ```json
        {
          "markdown_brief": "### Key Decisions Made:\n* Assign 60% resources to Project Phoenix, 40% to Project Eagle.\n\n### Main Action Items:\n* Bob to take the lead on Project Phoenix.\n* Charlie to manage Project Eagle.\n* Detailed project plans needed by end of next week.\n\n### Open Questions or Points for Follow-up:\n* Dave asked about the deadline for detailed project plans (answered: end of next week)."
        }
        ```
        *(The above is an example. The actual mock output will depend on the simplicity of the implemented JS in the Function node. It should at least include parts of the `runtime_chat_messages_content` and attempt to use section headers from the `input_brief_structure_prompt_template`.)*

### 1.3. Output/Callback

#### 1.3.1. Primary Output: Post Brief to Chat Service (HTTP Request Node)
*   **Type:** HTTP Request Node
*   **Name:** "Post Brief to Chat Service"
*   **URL:** `{{ $json.env.CHAT_SERVICE_INTERNAL_BASE_URL }}/internal/channels/{{ $json.webhook.body.effective_config.runtime_target_channel_id }}/agent-messages`
    *   The `runtime_target_channel_id` from the trigger's `effective_config` is dynamically inserted here.
*   **Method:** POST
*   **Authentication:** Bearer Token. The token should be a pre-shared secret or a dynamically fetched service-to-service authentication token, configured as an n8n credential or environment variable. For the demo, a static placeholder token might be used.
*   **Body Type:** JSON
*   **Send JSON Body (ensure this structure matches `ChatMessage` schema for agent messages):**
    ```json
    {
      "sender_id": "{{ $json.webhook.body.agent_configuration_id }}",
      "sender_type": "agent",
      "workspace_id": "{{ $json.webhook.body.workspace_id }}",
      "content_type": "markdown",
      "content": {
        "text": "{{ $node[\"Simulate LLM - Generate Brief\"].json.markdown_brief }}"
      }
    }
    ```
*   **Options:**
    *   `Continue On Fail`: Should be OFF for critical steps in a real scenario. For the demo, can be ON to ensure callback to Agent Service still happens.
*   **Note:** "This step sends the generated brief to the specified channel in the Chat Service, making it appear as if the agent has posted a message. The `agent_configuration_id` is used as the `sender_id` for the agent message."

#### 1.3.2. Secondary Callback: Notify Agent Service (HTTP Request Node)
*   **Type:** HTTP Request Node
*   **Name:** "Callback to Agent Service"
*   **URL:** `{{ $json.env.AGENT_SERVICE_BASE_URL }}/api/v1/agent-runs/{{ $json.webhook.body.run_id }}/completed`
*   **Method:** POST
*   **Authentication:** Bearer Token (if Agent Service requires it for internal callbacks).
*   **Body Type:** JSON
*   **Send JSON Body:**
    ```json
    {
      "status": "succeeded", // This could be set dynamically based on the success of the previous "Post Brief to Chat Service" node
      "output_preview": "Brief generated and posted to channel {{ $json.webhook.body.effective_config.runtime_target_channel_id }}. Preview: {{ $node[\"Simulate LLM - Generate Brief\"].json.markdown_brief.substring(0, 70) }}...",
      "full_output_reference": "{{ JSON.stringify({ \"posted_to_channel_id\": $json.webhook.body.effective_config.runtime_target_channel_id, \"brief_content_markdown\": $node[\"Simulate LLM - Generate Brief\"].json.markdown_brief }) }}",
      "error_message": null // Populate with error details if the process failed
    }
    ```
*   **Options:**
    *   `Always Output Data`: Should be ON if this is a final step.
*   **Note:** "`output_preview` confirms posting and provides a snippet of the brief. `full_output_reference` contains the full brief content and the channel it was posted to, for logging and reference by the Agent Service. The `status` should ideally reflect the outcome of posting to the Chat Service."

---

This specification should guide the creation of the n8n mock workflow for the Chat Brief Butler for the E2E demo, ensuring it aligns with the broader IONFLUX agent architecture and interaction models.
```
