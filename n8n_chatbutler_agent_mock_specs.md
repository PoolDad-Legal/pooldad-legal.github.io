# IONFLUX Project: n8n Workflow Specification for Mocked Chat Brief Butler (E2E Demo)

This document defines the specifications for an n8n workflow that will mock the backend logic for the `Slack Brief Butler` (or more generically, "Chat Brief Butler") agent during the IONFLUX E2E Demo. This workflow is triggered by the Agent Service based on user commands in the Chat Dock and simulates LLM-based summarization of chat messages.

**Reference Documents:**
*   `core_agent_blueprints.md`
*   `agent_service_minimal_spec.md`
*   `chat_service_minimal_spec.md`
*   `technical_stack_and_demo_strategy.md`

## A. `Slack Brief Butler` / `Chat Brief Butler` (n8n Workflow)

**1. Agent Name:** `Slack Brief Butler` (or `Chat Brief Butler`)

**2. Trigger:**

*   **Type:** n8n Webhook Node.
*   **Caller:** Agent Service, typically after receiving a parsed command from Chat Service (e.g., `POST /agents/invoke-command` or directly via `POST /agent-configurations/:agentConfigId/run`).
*   **Expected Input from Agent Service (JSON Body - simplified from `agent_service_minimal_spec.md` and `chat_service_minimal_spec.md`):**
    ```json
    {
      "run_id": "uuid",                 // Unique ID for this execution run
      "agent_configuration_id": "uuid", // The Butler's config ID
      "workspace_id": "uuid",
      "user_id": "uuid",                // User who invoked the command
      "yaml_config": {                  // Parsed YAML from AgentConfiguration
        "brief_structure_prompt": "Prompt string detailing desired brief structure...",
        "output_destinations": [
          {"type": "reply_in_chat"} 
          // other types ignored for this basic mock
        ]
      },
      "runtime_params": {               // Parameters passed from the Chat Service command
        "channel_id": "uuid_of_originating_channel", // Where to post the reply
        "chat_messages_content": "string" // Concatenated string of messages, or array of message strings
                                          // For demo, a single string is simpler to mock.
        // "thread_id": "uuid_or_null" // If summarizing a specific thread
      }
    }
    ```
    *   *Note: The `Chat Service` is expected to gather the relevant chat messages (e.g., from a thread or recent channel history if the command is generic) and pass this as `chat_messages_content` within `runtime_params` when it calls the Agent Service.*

**3. Core Workflow Steps (n8n Nodes - Conceptual):**

1.  **Webhook Node ("Start Chat Butler Run"):**
    *   Receives the trigger data from Agent Service.
    *   Responds immediately with HTTP 200 OK to Agent Service (as the Agent Service has already marked the run as 'pending' or 'running').

2.  **Set Node ("Extract Key Inputs"):**
    *   **Purpose:** Make key inputs easily accessible.
    *   **Logic:**
        *   `chat_messages = {{ $json.body.runtime_params.chat_messages_content }}`
        *   `brief_prompt_template = {{ $json.body.yaml_config.brief_structure_prompt }}` (This prompt itself might contain placeholders like "{Project Name}", "{Objectives}" etc.)
        *   `reply_channel_id = {{ $json.body.runtime_params.channel_id }}`
        *   `triggering_user_id = {{ $json.body.user_id }}`

3.  **Function Node ("Simulate LLM Summarization"):**
    *   **Purpose:** Generates a mocked structured brief based on the input messages and the structure prompt.
    *   **Input:** `chat_messages`, `brief_prompt_template`.
    *   **Logic (Simplified Mock):**
        *   If `chat_messages` is empty or very short, output a default "Not enough context to summarize."
        *   Otherwise, attempt a very basic "extraction" or generation:
            *   Identify keywords from the `brief_prompt_template` (e.g., "Project Name", "Objectives", "Tasks", "Deadline").
            *   Try to find lines in `chat_messages` that might correspond or just use placeholder text.
            *   Construct a markdown string.
        *   Example JavaScript in Function Node:
            ```javascript
            const messages = $json.chat_messages || "No specific input provided for summary.";
            const prompt = $json.brief_prompt_template || "Extract key points."; // Fallback
            
            let projectName = "Demo Project Brief";
            let objectives = "User initiated a Butler summary.";
            let tasks = "Process provided text: '" + messages.substring(0, 50) + "...'";
            let stakeholders = `Triggered by user: ${$json.triggering_user_id}`; // In real scenario, map to name
            let deadline = "Not specified in demo.";

            // Super simple mock: if messages contain keywords, use them
            if (messages.toLowerCase().includes("objective")) {
              objectives = messages.split('\n').find(line => line.toLowerCase().includes("objective")) || objectives;
            }
             if (messages.toLowerCase().includes("project")) {
              projectName = messages.split('\n').find(line => line.toLowerCase().includes("project")) || projectName;
            }

            const brief = `**Project Brief Summary (Mocked by n8n):**
*   **Project Name:** ${projectName}
*   **Objectives:** ${objectives}
*   **Key Tasks:** ${tasks}
*   **Stakeholders:** ${stakeholders}
*   **Deadline:** ${deadline}
---
*Prompt Used (for demo): ${prompt.substring(0,100)}...*`;
            
            return { generated_brief_markdown: brief };
            ```
    *   **Output:** `{"generated_brief_markdown": "markdown_string"}`

4.  **HTTP Request Node ("Send Brief to Chat Service"):**
    *   **Purpose:** Sends the generated brief back to the originating chat channel.
    *   **Method:** POST
    *   **URL:** A predefined webhook URL for the demo Chat Service to receive agent messages (e.g., `http://chat-service-url/internal/channels/{{ $json.SetKeyInputs.output.reply_channel_id }}/agent-messages`). This URL needs to be configurable in n8n.
    *   **Authentication:** Bearer Token (using a shared secret between n8n and the mock Chat Service for demo).
    *   **Body (JSON):**
        ```json
        {
          "sender_id": "{{ $json.body.agent_configuration_id }}", // Butler Agent's Config ID
          "sender_type": "agent",
          "content_type": "markdown", 
          "content": {"text": "{{ $json.SimulateLLMSummarization.output.generated_brief_markdown }}"}
          // Assuming Chat Service's internal endpoint can handle markdown directly or has a "markdown" field in content
        }
        ```

5.  **HTTP Request Node ("Callback to Agent Service - Success"):**
    *   **Purpose:** Notifies Agent Service of successful brief generation and posting.
    *   **URL:** `{{ $json.body.env.AGENT_SERVICE_URL || "http://localhost:8000/api/v1" }}/runs/{{ $json.body.run_id }}/completed`.
    *   **Method:** POST
    *   **Authentication:** Shared secret if implemented on Agent Service callback.
    *   **Body (JSON):**
        ```json
        {
          "agent_configuration_id": "{{ $json.body.agent_configuration_id }}",
          "status": "success",
          "output_preview": "Brief generated: {{ $json.SimulateLLMSummarization.output.generated_brief_markdown.split('\\n')[1].substring(0, 100) }}..." // e.g., "Project Name: Demo Project Brief..."
        }
        ```

**4. Output/Callback:**

*   **Primary Output:** An HTTP POST request to the (mocked) `Chat Service` containing the generated markdown brief, target `channel_id`, and agent sender information. This allows the brief to appear in the chat.
*   **Secondary Output:** An HTTP POST request to the `Agent Service`'s `/runs/:runId/completed` endpoint, updating the run status to `success` and providing a short preview of the generated brief. This helps the UI (e.g., Agent Snippet block) reflect that the agent ran successfully.

---

This n8n workflow specification for the `Slack Brief Butler` provides a mock implementation that simulates the core functionality of summarizing chat content based on a prompt and posting it back to the chat, fulfilling its role in the E2E demo.
```
