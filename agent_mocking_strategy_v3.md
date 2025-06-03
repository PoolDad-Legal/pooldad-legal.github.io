# IONFLUX Agent Mocking Strategy (v3 - E2E Demo)

## 1. Introduction

This document outlines the revised strategy for mocking IONFLUX agents for the End-to-End (E2E) Demo, aligning with the advanced capabilities defined in `core_agent_blueprints_v3.md` (PRM) and the updated `technical_stack_and_demo_strategy_v3.md`.

The core shift in strategy is twofold:
1.  **n8n workflows** will primarily be used for simulating external event sources (e.g., posting mock data to Kafka topics) and for providing simple, canned responses for external SaaS API endpoints that IONFLUX services might call. n8n will generally *not* be used to mock the internal logic of the core PRM agents.
2.  **Minimal Service Shells (Python/FastAPI)** will be created for key agents participating in the E2E demo flow. These shells will run simplified Python scripts that mock the *outcomes* of complex PRM agent logic, interact with a real Kafka instance (consuming/producing events), and call other (mocked) IONFLUX services.

The goal is to create a more representative E2E demo that showcases the event-driven architecture and the sophisticated nature of PRM agents, even if their deep internal logic is simulated.

## 2. Revised Role of n8n Workflows

n8n's role is now more focused on supporting the environment around the agent shells rather than being the agent shells themselves.

**2.1. Event Simulation (Publishing to Kafka):**
*   **Purpose:** To simulate external systems or events that trigger IONFLUX agents or provide data to them via Kafka.
*   **Mechanism:**
    *   An n8n workflow can be manually triggered during the demo.
    *   This workflow will construct a JSON payload conforming to the `PlatformEvent` schema defined in `conceptual_definition_v3.md`.
    *   **Example:** For the E2E demo flow, an n8n workflow can simulate a Shopify order:
        *   It creates a `PlatformEvent` with `event_type: "ionflux.shopify.ws_XYZ.orders.created"`.
        *   The `payload_json` would contain a mock Shopify order JSON structure.
        *   This `PlatformEvent` is then sent via an HTTP POST request to either:
            *   A dedicated Kafka producer microservice (a very simple service that takes JSON and publishes it to a specified Kafka topic).
            *   A Kafka REST Proxy endpoint if available for the Kafka instance used in the demo.
            *   (If n8n has a Kafka node and direct Kafka access is configured for the demo n8n instance, it could publish directly).
*   This allows the demo to show agents (like `Shopify Sales Sentinel`) reacting to real-time events from Kafka.

**2.2. Mocking External SaaS API Endpoints (Called by IONFLUX Services):**
*   **Purpose:** To provide simple, canned responses when IONFLUX services (like `LLMOrchestrationService`, `ShopifyIntegrationService` for data fetching, or `AudioService`) make outbound calls to external SaaS APIs that are not fully implemented or should be mocked for the demo.
*   **Mechanism:**
    *   An n8n webhook node can be configured to act as the mocked endpoint for a specific external API call.
    *   When an IONFLUX service (e.g., a Python agent shell calling a mocked `LLMOrchestrationService`) makes an HTTP request to this n8n webhook URL, the n8n workflow returns a pre-defined JSON response.
    *   Example: If `Email Wizard` (Python shell) calls the (mocked) `LLMOrchestrationService` for text generation, the `LLMOrchestrationService` might internally route this to an n8n webhook that returns:
        ```json
        {
          "status": "success",
          "provider_response": {
            "choices": [{"text": "This is a mocked LLM-generated email draft about [topic]."}],
            "usage": {"prompt_tokens": 10, "completion_tokens": 20, "total_tokens": 30}
          }
        }
        ```

## 3. Minimal Service Shells (Python/FastAPI) for Key Demo Agents

As per `technical_stack_and_demo_strategy_v3.md`, key agents in the E2E demo flow will be implemented as minimal Python/FastAPI service shells. These shells will run simplified Python scripts to mock the *outcomes* of the complex internal logic defined in the PRM blueprints.

**Common Characteristics for Shells:**
*   Each shell is a distinct FastAPI application, containerized using Docker.
*   Each shell exposes an HTTP POST endpoint (e.g., `/agent_shells/invoke/{agent_definition_id_from_prm}`) that `AgentService` calls to trigger a run. This endpoint receives `run_id` and `effective_config_json`.
*   They use the provided `effective_config_json` to guide their mocked logic.
*   They report completion (success or error) by calling `POST /agent-runs/{run_id}/completed` on `AgentService`, providing `status`, `output_data_json`, `output_preview_text`, etc.
*   If their `AgentDefinition` specifies Kafka event production or consumption, they will interact with the demo Kafka instance using a Python Kafka client.

**Key Demo Agent Shells:**

### 3.1. Shopify Sales Sentinel (Agent 004 - PRM Refactored Version)
*   **Agent Name & PRM ID:** `Shopify Sales Sentinel v2` (`agent_004_refactored`)
*   **Purpose in Demo:** To demonstrate event-driven agent activation from a Kafka topic (mock Shopify order) and subsequent alert generation to chat.
*   **Trigger Mechanism:**
    *   **Primary:** Consumes Kafka events. The Python shell will include a Kafka consumer listening to a topic like `ionflux.shopify.ws_{workspace_id}.brand_{brand_id}.events_raw` (topic name derived from `effective_config_json` or pre-configured for demo).
    *   **Alternative (for testing):** Can also be triggered via HTTP POST from `AgentService` if needed, though Kafka is preferred for demo.
*   **Mocked Core Logic (Conceptual Python Script):**
    1.  Receives `PlatformEvent` from Kafka (or `effective_config_json` if HTTP triggered with mock event payload).
    2.  Extracts Shopify order data from `event.payload_json`.
    3.  Accesses `min_order_value_alert_threshold` from `effective_config_json.inputs`.
    4.  `if order_data.total_price > min_order_value_alert_threshold:`
        *   Construct an `alert_message` string.
        *   Prepare `output_data_json` for the `incident_analysis_report` output key (e.g., a simple JSON with order ID and alert message).
        *   Prepare `output_data_json` for the `alert_to_brief_butler` output key (payload for Chat Service).
*   **Interaction with Other Mocked Services:**
    *   Calls `ChatService` internal API (`POST /internal/v1/channels/:channel_id/messages`) to post the alert, using a pre-configured `channel_id` from `effective_config_json`.
*   **Output/Callback to `AgentService`:**
    *   Calls `POST /agent-runs/{run_id}/completed`.
    *   `output_data_json`: Contains the `incident_analysis_report` and `alert_to_brief_butler` payloads.
    *   `output_preview_text`: e.g., "High-value order #123 detected and alert sent."

### 3.2. Revenue Tracker Lite (Agent 010 - PRM Refactored Version)
*   **Agent Name & PRM ID:** `Revenue Tracker Lite v2` (`agent_010_refactored`)
*   **Purpose in Demo:** To show an agent being configured and run on a Canvas page, displaying (mocked) financial insights.
*   **Trigger Mechanism:**
    *   HTTP POST from `AgentService` to its shell endpoint (e.g., `/agent_shells/invoke/agent_010_refactored`), receiving `run_id` and `effective_config_json`.
*   **Mocked Core Logic (Conceptual Python Script):**
    1.  Receives `effective_config_json`.
    2.  Accesses input like `effective_config_json.inputs.reporting_period` (if used by mock).
    3.  Generates a fixed, simple JSON structure for the `profitability_dashboard_data_json` output, e.g.:
        ```json
        {
          "total_revenue_net": 1250.75,
          "total_cogs": 600.50,
          "total_gross_margin": 650.25,
          "top_product_by_margin": {"name": "Mock Product Alpha", "margin": 50.00}
        }
        ```
    4.  Generates a simple markdown string for `profitability_digest_markdown` output.
*   **Interaction with Other Mocked Services:** None explicitly required for its mocked logic in demo.
*   **Output/Callback to `AgentService`:**
    *   Calls `POST /agent-runs/{run_id}/completed`.
    *   `output_data_json`: Contains the mocked `profitability_dashboard_data_json` and `profitability_digest_markdown`.
    *   `output_preview_text`: e.g., "Revenue report generated for last 7 days."

### 3.3. Email Wizard (Agent 001 - PRM Version)
*   **Agent Name & PRM ID:** `Email Wizard` (`agent_001`)
*   **Purpose in Demo:** To demonstrate an LLM-powered content generation agent, configured via YAML, and showing its output.
*   **Trigger Mechanism:**
    *   HTTP POST from `AgentService` to its shell endpoint (e.g., `/agent_shells/invoke/agent_001`), receiving `run_id` and `effective_config_json`.
*   **Mocked Core Logic (Conceptual Python Script):**
    1.  Receives `effective_config_json`.
    2.  Extracts inputs like `prompt_text` (from a selected `Prompt` via `effective_config_json.inputs.manual_payload.prompt_id` which `AgentService` would resolve to actual prompt text) or `target_audience_description`.
    3.  Simulates LLM call:
        *   Makes an HTTP POST to the mocked `LLMOrchestrationService` endpoint (which might be an n8n webhook).
        *   Sends a payload like `{"task_type": "text_generation", "prompt": "Generate email about X for Y audience..."}`.
        *   Receives a canned response, e.g., `{"choices": [{"text": "Dear [Audience], this is a great email about [Topic]..."}]}`.
    4.  Formats this as its `send_report` output (or a new output key like `generated_email_draft`).
*   **Interaction with Other Mocked Services:** Calls mocked `LLMOrchestrationService`.
*   **Output/Callback to `AgentService`:**
    *   Calls `POST /agent-runs/{run_id}/completed`.
    *   `output_data_json`: Contains the generated email draft.
    *   `output_preview_text`: e.g., "Email draft for 'New Summer Collection' generated."

### 3.4. Creator Persona Guardian (Agent 008 - PRM Refactored Version)
*   **Agent Name & PRM ID:** `Creator Persona Guardian v2` (`agent_008_refactored`)
*   **Purpose in Demo:** To show an analytical agent providing feedback on content, demonstrating a more advanced AI capability.
*   **Trigger Mechanism:**
    *   HTTP POST from `AgentService` to its shell endpoint (e.g., `/agent_shells/invoke/agent_008_refactored`), receiving `run_id` and `effective_config_json`.
*   **Mocked Core Logic (Conceptual Python Script):**
    1.  Receives `effective_config_json`.
    2.  Extracts `effective_config_json.inputs.content_to_analyze_text`.
    3.  Simulates persona analysis (no actual LLM multimodal analysis for demo):
        *   Returns a fixed `authenticity_score` (e.g., 0.85).
        *   Returns generic `repaired_content_suggestions_json` (e.g., `{"suggestions": ["Consider making the tone more upbeat.", "Add a relevant emoji."]}"`).
*   **Interaction with Other Mocked Services:** None explicitly for demo (real version would call LLM Orchestration).
*   **Output/Callback to `AgentService`:**
    *   Calls `POST /agent-runs/{run_id}/completed`.
    *   `output_data_json`: Contains `authenticity_score` and `repaired_content_suggestions_json`.
    *   `output_preview_text`: e.g., "Persona analysis complete. Score: 85%."

## 4. Mocking Other Agents (Simplified Fallback Approach)

For the remaining PRM agents in the "FREE-10" list that are not central to the E2E demo narrative (e.g., `WhatsApp Pulse`, `TikTok Stylist`, `UGC Matchmaker` (if v1 focus is on others), `Outreach Automaton`, `Slack Brief Butler`, `Badge Motivator`), a simpler mocking strategy will be used to avoid building unnecessary Python shells for the initial demo.

*   **Mechanism:**
    1.  These agents will have their `AgentDefinition.deployment_info_json.demo_execution_type` set to something like `'demo_canned_response'` or `'n8n_generic_ack'`.
    2.  When `AgentService` receives a run request for an agent with `demo_execution_type: 'demo_canned_response'`:
        *   It creates an `AgentRunLog` entry with `status: 'pending'` and `run_id`.
        *   It then immediately (or after a very short mock delay) calls its own `POST /agent-runs/{run_id}/completed` endpoint.
        *   The payload for this callback will be a generic, canned success response, e.g.:
            ```json
            {
              "status": "success",
              "output_data_json": {
                  "outputs_array": [
                      {"key_name": "generic_output", "value": "Agent run simulated successfully. This is a generic E2E demo mock response."}
                  ]
              },
              "output_preview_text": "[Agent Name] run simulated. No detailed output in this demo.",
              "error_details_json": null,
              "kpi_results_json": null
            }
            ```
            (The `key_name` for `generic_output` should match one of the defined outputs in the agent's `outputs_config_json_array`.)
    3.  If `demo_execution_type: 'n8n_generic_ack'`, `AgentService` would call a single, very simple n8n webhook that does nothing but immediately call back to `/agent-runs/:run_id/completed` with a similar canned success message.
*   **Rationale:** This approach ensures all 10 PRM agents can be "run" from the UI without errors, providing a sense of completeness for the free tier, while focusing development effort on mocking the agents core to the E2E demo flow.

This consolidated mocking strategy provides a clear path for the E2E demo, balancing the need for representative agent behavior with practical constraints on demo development.
```
