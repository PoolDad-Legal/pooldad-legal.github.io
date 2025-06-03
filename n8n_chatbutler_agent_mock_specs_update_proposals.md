```markdown
# Proposed Revisions for n8n_chatbutler_agent_mock_specs.md

This document outlines proposed textual revisions to `n8n_chatbutler_agent_mock_specs.md` to align with AGENTE 007 - Slack Brief Butler (interpreted as Chat Brief Butler) from `core_agent_blueprints.md`, the revised `agent_interaction_model.md`, and `conceptual_definition.md`.

## General Changes:

*   **Workflow Naming:** Ensure workflow name is "E2E Demo Mock: Chat Brief Butler".
*   **Environment Variables:** Assume `AGENT_SERVICE_BASE_URL` and `CHAT_SERVICE_INTERNAL_BASE_URL` are available as n8n environment variables.
*   **Error Handling:** Note that production workflows need robust error handling; mocks assume success.

## 1. Chat Brief Butler (AGENTE 007) n8n Workflow Mock

### 1.1. Trigger (Webhook Node - "Start")

*   **Current (Assumed):** May have a simpler input structure.
*   **Proposed Revision:**
    *   **Description:** "Webhook trigger for the Chat Brief Butler agent mock. Receives run details, the effective agent configuration (including the brief structure prompt), and runtime parameters (chat messages content and target channel ID) from the Agent Service."
    *   **Method:** POST
    *   **Path:** (Defined by n8n, e.g., `/webhook/chat-brief-butler-mock`)
    *   **Authentication:** Secure webhook with a unique token if possible.
    *   **Expected Input Data (JSON Body):**
        ```json
        {
          "run_id": "unique_run_identifier_from_agent_service",
          "agent_configuration_id": "config_id_for_this_agent_instance",
          "workspace_id": "user_workspace_id",
          "user_id": "triggering_user_id", // User who invoked the agent command
          "effective_config": {
            // Merged AgentConfiguration.yaml_config & runtime_params.
            // For AGENTE 007 (Chat Brief Butler), this includes:
            // From AgentConfiguration.yaml_config (example values):
            "input_brief_structure_prompt_template": "Summarize the following discussion into these sections: Key Decisions, Action Items, Open Questions. Input: {{chat_messages_content}}",
            "input_output_language_for_brief": "en",
            "input_max_brief_length_tokens": 500,
            "input_llm_model_preference_for_briefing": "gpt-4-turbo-preview", // For mock, this is informational

            // From runtime_params (passed by Chat Service via Agent Service when agent is invoked):
            "runtime_chat_messages_content": "User A: Let's decide on the Q3 marketing budget. User B: I propose $50k. User A: Sounds good. User C: I'll draft the plan. User B: Any open questions? User A: No, all clear.",
            "runtime_target_channel_id": "channel_id_where_brief_should_be_posted", // e.g., "C12345"
            "runtime_user_mention_ids_for_action_items": ["UABC123", "UDEF456"] // Optional, for mock can be informational
          }
        }
        ```
    *   **Note:** "The `effective_config` object is critical. `input_brief_structure_prompt_template` comes from the agent's persistent configuration. `runtime_chat_messages_content` and `runtime_target_channel_id` are provided at invocation time by the Chat Service (via Agent Service) and are essential for this workflow."

### 1.2. Core Workflow Steps (n8n Nodes)

#### 1.2.1. Node: Simulate LLM Summarization
*   **Current (Assumed):** Generic mock, may not use a structure prompt explicitly.
*   **Proposed Revision:**
    *   **Type:** Function Node
    *   **Name:** "Simulate LLM - Generate Brief"
    *   **Logic:**
        *   Access `effective_config.input_brief_structure_prompt_template` and `effective_config.runtime_chat_messages_content`.
        *   **Mock Summarization:**
            *   A simple approach for the mock:
                1.  Check if `input_brief_structure_prompt_template` contains placeholders like "Key Decisions", "Action Items", "Open Questions".
                2.  Crudely segment `runtime_chat_messages_content` or extract lines containing keywords related to these sections.
                3.  Construct a markdown string. If "Key Decisions: {{decisions}}" is in the prompt, the output might be "### Key Decisions\n- Budget set to $50k."
                4.  If no specific structure is easily parsable from the prompt, create a generic summary: "### Summary\n{{first few lines of runtime_chat_messages_content}}...\n### Action Items\n- User C to draft plan."
            *   The goal is to *demonstrate usage* of both inputs, not to create a perfect summarizer.
        *   **Input for LLM (Conceptual):**
            ```
            Prompt: {{ effective_config.input_brief_structure_prompt_template }}
            Content to Summarize: {{ effective_config.runtime_chat_messages_content }}
            ```
        *   **Mock Output (String - Markdown formatted brief):**
            ```markdown
            ### Key Decisions
            *   Q3 marketing budget set to $50k.

            ### Action Items
            *   User C to draft the Q3 marketing plan. (Mention: <@UABC123> if IDs were mapped)

            ### Open Questions
            *   None reported.
            ```
            (The above is an ideal mock output; a simpler version is acceptable if it uses the inputs).
    *   This node outputs the generated markdown string.

### 1.3. Output/Callback

#### 1.3.1. Primary Output: Post Brief to Chat Service (HTTP Request Node)
*   **Current (Assumed):** May not exist or posts to a generic webhook.
*   **Proposed Revision:**
    *   **Type:** HTTP Request Node
    *   **Name:** "Post Brief to Chat Service"
    *   **URL:** `{{ $json.env.CHAT_SERVICE_INTERNAL_BASE_URL }}/internal/channels/{{ $json.webhook.body.effective_config.runtime_target_channel_id }}/agent-messages`
        *   Note: `runtime_target_channel_id` is critical here.
    *   **Method:** POST
    *   **Authentication:** Bearer Token, using an internal service-to-service auth token for Chat Service (if applicable for demo).
    *   **Body Type:** JSON
    *   **Send JSON Body:**
        ```json
        {
          "sender_id": "{{ $json.webhook.body.agent_configuration_id }}", // The ID of this agent's configuration
          "sender_type": "agent",
          "workspace_id": "{{ $json.webhook.body.workspace_id }}",
          "content_type": "markdown", // As defined in ChatMessage schema
          "content": {
            "text": "{{ $node[\"Simulate LLM - Generate Brief\"].json.markdown_brief }}" // Assuming the LLM node outputs { "markdown_brief": "..." }
          }
        }
        ```
    *   **Note:** "This step sends the generated brief to the appropriate channel in the Chat Service, as if the agent is posting a message."

#### 1.3.2. Secondary Callback: Notify Agent Service (HTTP Request Node)
*   **Current (Assumed):** Basic callback.
*   **Proposed Revision:**
    *   **Type:** HTTP Request Node
    *   **Name:** "Callback to Agent Service"
    *   **URL:** `{{ $json.env.AGENT_SERVICE_BASE_URL }}/api/v1/agent-runs/{{ $json.webhook.body.run_id }}/completed`
    *   **Method:** POST
    *   **Body Type:** JSON
    *   **Send JSON Body:**
        ```json
        {
          "status": "succeeded", // or "failed" if the HTTP post to Chat Service failed or LLM sim failed
          "output_preview": "Brief generated and posted to channel {{ $json.webhook.body.effective_config.runtime_target_channel_id }}. Preview: {{ $node[\"Simulate LLM - Generate Brief\"].json.markdown_brief.substring(0, 50) }}...",
          "full_output_reference": "{{ JSON.stringify({ \"posted_to_channel_id\": $json.webhook.body.effective_config.runtime_target_channel_id, \"brief_content_markdown\": $node[\"Simulate LLM - Generate Brief\"].json.markdown_brief }) }}",
          "error_message": null // Or provide error details if status is "failed"
        }
        ```
    *   **Note:** "`output_preview` confirms posting and gives a snippet. `full_output_reference` contains the full brief and target channel for logging/reference by Agent Service."
    *   This node should ideally run after the "Post Brief to Chat Service" node, and its `status` could reflect the success/failure of that posting. For simplicity in mock, can assume success if LLM sim works.

---

These proposed revisions aim to make the n8n mock workflow for the Chat Brief Butler more closely reflect the detailed agent inputs (especially `effective_config` containing both static config and runtime params like `chat_messages_content` and `target_channel_id`), outputs, and interaction patterns defined in the core project documents.
```
