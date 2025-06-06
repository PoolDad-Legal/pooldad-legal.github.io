# Transform Specification: MuseGen_LLM_Transform

## 1. Overview
*   **Transform Name:** `MuseGen_LLM_Transform`
*   **Version:** 0.9.0
*   **Type:** AI Inference (Generative Text and potentially Multimodal)
*   **Primary Goal:** Securely executes generative Large Language Model (LLM) inference requests. It manages prompt construction (potentially from templates and parameters), interacts with various LLM backends (often mediated by the IONFLUX Controller or a similar service), and processes responses. All operations, especially those involving potentially sensitive data in prompts or significant computational cost (C-ION), are subject to IONWALL oversight and user consent.
*   **Key Features:**
    *   Accepts structured prompt inputs, which can include system prompts, user prompts, context data CIDs (for RAG - Retrieval Augmented Generation), and parameters for templates.
    *   Supports configuration of various LLM parameters (e.g., model ID, temperature, max tokens, stop sequences, top_p, top_k).
    *   Deep integration with IONWALL for obtaining user consent before LLM execution, particularly if Personally Identifiable Information (PII) is detected in prompts or if the operation incurs C-ION costs. IONWALL also enforces content policies and budget limits.
    *   Outputs the generated text (or structured data like JSON if requested and supported by the model), along with metadata such as token usage, model ID used, and finish reason.
    *   Aims to abstract the specifics of different LLM provider APIs, providing a consistent interface for IONFLUX agents.
    *   Potential for future extension to multimodal inputs (e.g., image CIDs as part of the prompt).

## 2. Conceptual I/O ABI (Application Binary Interface)
### Input Schema (Conceptual JSON)
```json
{
  "type": "object",
  "properties": {
    "prompt_template_cid": {
      "type": "string",
      "nullable": true,
      "description": "Optional CID of a prompt template object (e.g., Jinja2 format) stored in IONPOD. If provided, 'prompt_parameters_cid' or 'prompt_parameters_inline' should also be supplied."
    },
    "prompt_parameters_cid": {
      "type": "string",
      "nullable": true,
      "description": "Optional CID of an IONPOD object containing parameters (key-value pairs) to fill into the prompt template."
    },
    "prompt_parameters_inline": {
      "type": "object",
      "additionalProperties": true,
      "nullable": true,
      "description": "Optional inline JSON object containing parameters for the prompt template."
    },
    "prompt_raw": {
      "type": "object",
      "properties": {
        "system_prompt": { "type": "string", "nullable": true, "description": "Instructions or context for the LLM's persona or behavior." },
        "user_prompt": { "type": "string", "description": "The primary prompt/question from the user." },
        "context_data_cids": {
          "type": "array",
          "items": { "type": "string" },
          "nullable": true,
          "description": "Optional array of CIDs pointing to IONPOD data to be fetched and injected as context into the prompt (for RAG)."
        }
        // Future: "image_input_cids": { "type": "array", "items": { "type": "string" } } for multimodal
      },
      "description": "Raw prompt components if not using a template. 'user_prompt' is typically required if this object is used."
    },
    "llm_config": {
      "type": "object",
      "properties": {
        "model_id": { "type": "string", "description": "Identifier for the desired LLM (e.g., 'anthropic.claude-3-opus-20240229-v1:0', 'openai.gpt-4-turbo', 'google.gemini-1.5-pro-latest', or a sNetwork-specific model ID)." },
        "temperature": { "type": "number", "minimum": 0.0, "maximum": 2.0, "nullable": true, "description": "Controls randomness. Lower is more deterministic." },
        "max_tokens_to_sample": { "type": "integer", "minimum": 1, "nullable": true, "description": "Maximum number of tokens to generate in the response." },
        "stop_sequences": { "type": "array", "items": { "type": "string" }, "nullable": true, "description": "Sequences where the LLM should stop generating further tokens." },
        "top_p": { "type": "number", "minimum": 0.0, "maximum": 1.0, "nullable": true, "description": "Nucleus sampling parameter." },
        "top_k": { "type": "integer", "minimum": 1, "nullable": true, "description": "Top-k sampling parameter." },
        "response_mime_type_preference": { "type": "string", "nullable": true, "description": "Preferred MIME type for the LLM response, e.g., 'application/json' if expecting structured output."}
        // Other LLM-specific parameters can be added here, possibly under a "vendor_specific_params" object.
      },
      "required": ["model_id"]
    },
    "output_format_hint": {
      "type": "string",
      "enum": ["text", "json_object", "xml_string", "markdown_text"],
      "default": "text",
      "description": "Hint to the transform (and potentially to the LLM via prompt engineering) about the desired structure of 'generated_content'. If 'json_object', the transform may attempt to parse the LLM's text output as JSON."
    },
    "tool_choice_config_cid": {
      "type": "string",
      "nullable": true,
      "description": "Optional CID of a configuration object defining tools/functions the LLM can choose to call (for ReAct patterns or function calling)."
    }
  },
  // Logic: Must provide either (prompt_template_cid AND (prompt_parameters_cid OR prompt_parameters_inline)) OR prompt_raw. And llm_config is always required.
  "oneOf": [
    { "required": ["prompt_template_cid", "llm_config"] },
    { "required": ["prompt_raw", "llm_config"] }
  ]
}
```
### Output Schema (Conceptual JSON)
```json
{
  "type": "object",
  "properties": {
    "generated_content": {
      "type": ["string", "object", "null"],
      "description": "The LLM's primary output. If 'output_format_hint' was 'json_object' and parsing succeeded, this will be a JSON object. Otherwise, typically a string. Null if generation failed before content was produced."
    },
    "llm_response_metadata": {
      "type": "object",
      "properties": {
        "model_id_used": { "type": "string", "description": "The actual model ID that processed the request." },
        "input_token_count": { "type": "integer", "nullable": true, "description": "Number of tokens in the input prompt." },
        "output_token_count": { "type": "integer", "nullable": true, "description": "Number of tokens in the generated response." },
        "total_tokens_billed": { "type": "integer", "nullable": true, "description": "Total tokens as billed by the provider (might differ from sum of input/output)." },
        "finish_reason": {
          "type": "string",
          "enum": ["stop_sequence_reached", "max_tokens_reached", "model_error", "content_filtered_by_llm_provider", "tool_use_invoked", "unknown_provider_reason"],
          "description": "Reason why the LLM stopped generating."
        },
        "confidence_score": { "type": "number", "nullable": true, "description": "Overall confidence score for the generation, if the model provides it (rarely available directly)." },
        "provider_request_id": { "type": "string", "nullable": true, "description": "Request ID from the LLM provider, for tracing." },
        "generation_duration_ms": { "type": "integer", "description": "Time taken for the LLM inference part of the transform."}
        // Other metadata from LLM provider (e.g., latency figures, region processed)
      },
      "required": ["model_id_used", "finish_reason", "generation_duration_ms"]
    },
    "status": {
      "type": "string",
      "enum": ["success", "failure_ionwall_denied", "failure_llm_error", "failure_prompt_error", "failure_content_guardrail_triggered_by_transform", "failure_config_error", "failure_output_parsing_error"],
      "description": "Overall status of the LLM operation."
    },
    "error_message": {
      "type": "string",
      "nullable": true,
      "description": "Detailed error message if status indicates failure."
    },
    "tool_invocation_request": {
        "type": "object",
        "nullable": true,
        "description": "If the LLM requested a tool use, this object contains the details (tool name, input arguments)."
    }
  },
  "required": ["status"]
  // "generated_content" and "llm_response_metadata" are required if status is "success".
}
```

## 3. Configuration Parameters (Conceptual)
*(System-level settings for the transform instance)*

*   `ionwall_interaction_service_cid`: CID of config for IONWALL communication.
*   `ionflux_controller_llm_service_cid`: CID of config for the mediated LLM service endpoint (if used). This service would handle actual API calls to providers, manage API keys securely, and potentially provide caching or rate limiting.
*   `direct_llm_provider_configs_cids`: Object mapping `model_id` prefixes to CIDs of config objects for direct calls (e.g., for edge LLMs or if Controller mediation is bypassed for certain models). These configs would contain API keys or endpoint details, stored securely in IONPOD and only accessible to this transform via IONWALL.
*   `default_llm_config_cid`: CID of a system-wide default LLM configuration object (model, temp, etc.) if not fully specified in the input.
*   `content_guardrail_policy_input_cid`: Optional CID of a policy defining rules for input prompts (e.g., disallow certain topics, PII detection). Processed by IONWALL or a local policy engine.
*   `content_guardrail_policy_output_cid`: Optional CID of a policy for filtering LLM-generated content for harmfulness, bias, or policy violations.
*   `allowed_model_ids_list_cid`: CID of an IONPOD object listing explicitly permitted `model_id`s or patterns.
*   `max_input_context_data_size_bytes_total`: Limit for total size of data fetched from `context_data_cids`.
*   `token_cost_database_cid`: CID of a database mapping (model_id, token_type) to C-ION cost. Used for estimating costs for IONWALL.

## 4. Detailed Logic Flow & IONWALL Interaction
1.  **Input Validation & Processing:**
    *   Transform receives input. Validates that either template or raw prompt components are provided, and `llm_config` is present.
    *   **Fetch Templates/Parameters (if CIDs provided):** If `prompt_template_cid` or `prompt_parameters_cid` are used, internally calls `FetchFromIONPOD_Transform_IONWALL` to get these. This implies these CIDs must be covered by existing IONWALL consent or trigger a new consent request for data reading.
    *   **Fetch Context Data (if CIDs provided):** If `prompt_raw.context_data_cids` are present, internally calls `FetchFromIONPOD_Transform_IONWALL` for each CID. Concatenates fetched text content. Checks against `max_input_context_data_size_bytes_total`.
    *   **Construct Final Prompt:** Assembles the final prompt string(s) (system, user) using templates, parameters, and context data.
2.  **IONWALL Pre-LLM Check & Consent:**
    *   The transform constructs a request for IONWALL, including:
        *   `ionwall_approval_scope` from FluxGraph node.
        *   `llm_config` (model_id, estimated tokens if calculable).
        *   Metadata about the prompt (e.g., length, presence of context data CIDs, hash of prompt content for policy checks, but *not necessarily the full prompt text* unless the policy requires it for content filtering).
        *   Estimated C-ION cost based on `token_cost_database_cid` and prompt length/model.
    *   IONWALL evaluates this request against:
        *   User's consent for the given `ionwall_approval_scope`.
        *   User's C-ION budget for LLM usage.
        *   Input content policies (using `content_guardrail_policy_input_cid`). This might involve sending a hash or a PII-redacted version of the prompt to a policy engine.
    *   If consent is missing or policies are violated, IONWALL may prompt the user or deny the request. Output: `failure_ionwall_denied`.
3.  **LLM Invocation:**
    *   If IONWALL approves, it may return modified `llm_config` (e.g., enforcing a safer model, temperature).
    *   The transform sends the final prompt and LLM configuration to the appropriate LLM backend:
        *   Preferably via `ionflux_controller_llm_service_cid` (which handles API key security, load balancing, provider abstraction).
        *   Alternatively, for specific edge models or configurations, directly using `direct_llm_provider_configs_cids` (the transform fetches this config securely from IONPOD via IONWALL).
4.  **Receive and Process LLM Response:**
    *   Receives raw response from LLM backend (text, structured data, finish reason, token counts, etc.).
5.  **IONWALL Post-LLM Check (Output Guardrails):**
    *   The generated content can be sent to IONWALL (or a local policy engine specified by IONWALL via `content_guardrail_policy_output_cid`) for checks against harmful content, bias, or other output policies.
    *   If guardrails are violated: Output: `failure_content_guardrail_triggered_by_transform`. The specific problematic content might be redacted or the entire output suppressed.
6.  **Output Formatting & Packaging:**
    *   If `output_format_hint` was `json_object` (and not already JSON from LLM), attempt to parse `generated_content`. If parsing fails: Output: `failure_output_parsing_error` (or return raw text if configured to be lenient).
    *   Populate `llm_response_metadata`.
    *   Set final `status` and `error_message` if any.
7.  **Return Output:** Return the packaged output to the FluxGraph engine.

## 5. Error Handling
*   `failure_ionwall_denied`: User denied LLM use, budget exceeded, or input/output content policy violation detected by IONWALL/guardrails.
*   `failure_llm_error`: Error from the LLM provider API (e.g., model unavailable, API key issue if called directly, rate limit exceeded, internal LLM error). Includes `model_error` and `content_filtered_by_llm_provider` finish reasons.
*   `failure_prompt_error`: Invalid prompt structure, template processing error, context data CIDs not found or inaccessible.
*   `failure_content_guardrail_triggered_by_transform`: Generated content flagged by transform's own output guardrails (distinct from IONWALL's initial check, or if transform has stricter local rules).
*   `failure_config_error`: Invalid transform configuration (e.g., LLM service endpoint, allowed models list).
*   `failure_output_parsing_error`: Failed to parse LLM output into the structure specified by `output_format_hint` (e.g., expected JSON, got malformed text).

## 6. Security Considerations
*   **Prompt Injection:** Mitigated by using structured inputs, clear separation of instructions (system prompt) from user data, templating engines that escape inputs, and potentially by specialized input validation transforms or IONWALL policies that scan prompts.
*   **Data Privacy in Prompts:** IONWALL is the primary gatekeeper. Policies must define what types of data (especially PII) can be included in prompts sent to which models. Redaction or pseudonymization transforms might be applied to prompts before this LLM transform if highly sensitive data is involved but not essential for the LLM task.
*   **Cost Control:** IONWALL enforces C-ION budget limits for LLM calls. The transform should provide accurate token estimates to IONWALL.
*   **Secure API Key Management:** API keys for LLM providers should *not* be stored directly in the transform's configuration or passed in inputs. They should be managed by a secure service like the `IONFLUX Controller LLM Service` or fetched securely by the transform from a protected IONPOD location (e.g., via IONWALLET referral if keys are user-specific) with IONWALL mediation.
*   **Preventing Abuse:** Rate limiting (at Controller or IONWALL level), query complexity limits, and output guardrails are essential to prevent malicious use (e.g., generating harmful content, DoS attacks on LLM providers).
*   **Content Filtering/Guardrails:** Both input prompts and output generations should be subject to content filtering based on user and sNetwork policies.
*   **Model Provenance & Trust:** Ensuring that the `model_id` refers to a legitimate, vetted LLM, especially if allowing user-specified models. The `allowed_model_ids_list_cid` helps here.

## 7. Performance Considerations
*   **LLM Latency:** LLM inference can be slow. The transform should handle timeouts gracefully. FluxGraphs using this transform must account for this latency.
*   **Token Limits:** Models have input and output token limits. The transform needs to be aware of these (possibly fetched from model metadata via Controller/TechGnosis) and manage prompts/requests accordingly (e.g., truncating context, erroring if prompt too long).
*   **Caching:** For non-sensitive, idempotent LLM requests with identical prompts and configurations, responses could potentially be cached (e.g., by the IONFLUX Controller LLM Service or a shared caching layer) to save costs and improve latency. User consent and data privacy implications must be carefully considered for caching.
*   **Streaming Responses:** For applications like chatbots, LLMs often support streaming partial responses. This transform's output schema would need to be adapted (e.g., outputting a stream reference or emitting multiple partial outputs) if streaming is a requirement. (Marked as future enhancement).

## 8. Versioning
*   This transform specification follows semantic versioning.
*   Significant changes to I/O schemas, supported `llm_config` parameters, or core logic (e.g., IONWALL interaction protocol) would require a version increment.
*   The specific LLM models it can call are versioned by their providers (e.g., `claude-3-opus-20240229-v1:0`).

## 9. Ecosystem Dependencies
*   **IONWALL:** Essential for consent management, budget control, and enforcement of content/security policies related to LLM use.
*   **IONPOD (IPFS):** For storing and fetching prompt templates, parameters, context data, and potentially LLM configurations or guardrail policies.
*   **IONFLUX Controller LLM Service (Recommended):** A centralized service that mediates calls to external LLM providers, manages API keys, handles caching, and applies sNetwork-wide policies. If not used, the transform needs a more complex direct-calling mechanism.
*   **LLM Backends:** The actual LLM services (e.g., OpenAI, Anthropic, Google Vertex AI, local/edge LLMs loaded as separate transforms or services).
*   **FluxGraph Engine:** Executes the transform and manages its lifecycle.
*   **`FetchFromIONPOD_Transform_IONWALL`:** Used internally if fetching prompt components from IONPOD.
*   **TechGnosis (Optional):** Could be used for advanced prompt engineering, model selection guidance, or interpreting LLM outputs.

## 10. Example Usage (in FluxGraph YAML)
```yaml
# ...
  - id: "generate_creative_text_summary"
    transform: "MuseGen_LLM_Transform"
    # This scope tells IONWALL what the user is consenting to at a high level.
    ionwall_approval_scope: "llm_generate_creative_summary:document_cid_{{trigger.input_data.source_doc_cid}}:for_public_post"
    inputs:
      prompt_template_cid: "{{agent.prm.summary_template_cid}}" # Agent has a default template
      prompt_parameters_inline:
        document_content_for_prompt: "{{nodes.fetch_document.outputs.document_text}}" # From a previous step
        desired_length_words: 200
        style_preference: "formal_academic"
      llm_config:
        model_id: "anthropic.claude-3-sonnet-20240229-v1:0"
        temperature: 0.6
        max_tokens_to_sample: 600 # Max output tokens
      output_format_hint: "text"
    outputs: [generated_summary_text, llm_interaction_metadata] # Names for outputs from this node

  - id: "extract_entities_as_json"
    transform: "MuseGen_LLM_Transform"
    ionwall_approval_scope: "llm_extract_entities:data_cid_{{inputs.raw_text_cid}}" # Another scope example
    inputs:
      prompt_raw:
        system_prompt: "You are an expert entity extraction system. Output ONLY valid JSON."
        user_prompt: "Extract all named entities (people, organizations, locations) from the following text: {{nodes.load_text_for_ner.outputs.text_data}}"
      llm_config:
        model_id: "openai.gpt-3.5-turbo" # Example
        temperature: 0.1
        max_tokens_to_sample: 300
        # Some models support explicit JSON output mode in their API, which would be set here
        # vendor_specific_params: { "response_format": { "type": "json_object" } } # Conceptual example
      output_format_hint: "json_object" # Hint to try parsing output as JSON
    outputs: [entities_json_object, ner_llm_metadata]
# ...
```

## 11. Open Questions & Future Enhancements
*   **Streaming LLM Responses:** Formalize support for streaming outputs for interactive applications. This would likely require changes to the FluxGraph engine's handling of transform outputs.
*   **Tool Use / Function Calling:** Define how the transform handles LLMs that can request external tools or functions to be called. This would involve structuring `tool_choice_config_cid`, outputting `tool_invocation_request`, and a subsequent step in the FluxGraph to execute the tool and feed results back to the LLM (likely requiring another instance of `MuseGen_LLM_Transform`).
*   **Fine-tuning Management:** While this transform executes inference, how are fine-tuned models managed, referenced by `model_id`, and their access controlled? (Likely a separate sNetwork function).
*   **More Sophisticated Prompt Engineering Abstractions:** Instead of just templates, could it support more complex prompt construction logic or "prompt chaining" within a single invocation (though this might be better handled by higher-level agents like Muse Prompt Chain Agent).
*   **Multimodal Inputs/Outputs:** Explicitly define schema extensions for image, audio, or video inputs/outputs as more LLMs become multimodal.
*   **Standardized Error Codes from LLM Providers:** Map diverse provider errors to a more standardized set of error codes in the output.
*   **Dynamic Model Selection/Routing:** Integration with TechGnosis or a model router service to dynamically select the best (cost, performance, capability) `model_id` based on the prompt, desired output, and user preferences, rather than always pre-specifying.
*   **Batching Requests:** Support for sending multiple prompts to the LLM in a single request, if the backend API supports it, for efficiency.
