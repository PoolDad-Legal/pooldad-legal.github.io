# Agent Blueprint: Datascribe Transcript Agent - v0.9.0

## 1. Overview

*   **Agent Name:** `Datascribe Transcript Agent`
*   **Version:** `0.9.0`
*   **Status:** `development`
*   **Primary Goal:** `Transcribes audio/video content using a STT (Speech-to-Text) transform, cleans/formats the transcript, and optionally generates summaries or keyword lists using an LLM transform. Input from IONPOD, output to IONPOD, managed by IONWALL.`
*   **Key Features:**
    *   Accepts audio or video file CIDs from IONPOD as input.
    *   Utilizes a specific Speech-to-Text (STT) transform for transcription.
    *   Includes a text formatting transform to clean and structure the raw transcript.
    *   Conditionally uses an LLM transform (`MuseGen_LLM_Transform`) to generate a summary if requested.
    *   Conditionally uses an LLM transform or a dedicated keyword extraction transform to generate keywords if requested.
    *   Stores formatted transcript, summary (if generated), and keywords (if generated) back to IONPOD.
    *   All operations are subject to IONWALL approval.
    *   Emits completion events via NATS.

## 2. FluxGraph Definition (Conceptual YAML)

```yaml
# /specs/agents/datascribe_transcript_agent_fluxgraph.yaml (Conceptual representation)
version: "0.1.0" # FluxGraph spec version
name: "datascribe_transcript_agent_fluxgraph"
description: "Transcribes audio/video content, formats the transcript, and optionally generates summaries and keywords."

triggers:
  - type: "manual"
  - type: "event_driven"
    config: { event_source: "IONPOD", event_filter_metadata_key: "ionflux_process_for_transcription", event_filter_metadata_value: "true" }
  - type: "webhook"
    config: { path: "/webhooks/invoke/datascribe_transcript", method: "POST", authentication_method: "ionwall_jwt" }

input_schema: # JSON schema for expected input when triggered
  type: "object"
  properties:
    media_file_cid: { type: "string", description: "IPFS CID of the audio or video file stored in IONPOD." }
    transcription_options: {
      type: "object",
      properties: {
        language: { type: "string", default: "en-US", description: "Language code for transcription (e.g., en-US, es-ES)." },
        generate_summary: { type: "boolean", default: false, description: "Whether to generate a summary of the transcript." },
        generate_keywords: { type: "boolean", default: false, description: "Whether to extract keywords from the transcript." },
        summary_prompt_override_cid: { type: "string", nullable: true, description: "Optional CID of a custom prompt for summary generation."}
      },
      additionalProperties: false
    }
  required: [ "media_file_cid" ]

output_schema: # JSON schema for the agent's final output
  type: "object"
  properties:
    transcript_cid: { type: "string", description: "IPFS CID of the formatted transcript text file in IONPOD." }
    summary_cid: { type: "string", nullable: true, description: "IPFS CID of the generated summary text file in IONPOD (if requested)." }
    keywords_cid: { type: "string", nullable: true, description: "IPFS CID of the generated keywords list/object in IONPOD (if requested)." }
    status: { type: "string", enum: ["success", "failure", "partial_success"] }
    error_message: { type: "string", nullable: true }
    usage_metrics: {
      type: "object",
      properties: {
        media_duration_seconds: { type: "number" },
        stt_processing_time_ms: { type: "integer" },
        llm_tokens_processed_summary: { type: "integer", nullable: true },
        llm_tokens_processed_keywords: { type: "integer", nullable: true },
        total_execution_time_ms: { type: "integer" }
      }
    }
  required: ["status"] # transcript_cid should also be required on success

graph: # DAG of transforms
  - id: "fetch_media_file"
    transform: "FetchFromIONPOD_Transform_IONWALL"
    ionwall_approval_scope: "read_pod_data:datascribe_input_media"
    inputs:
      cid: "{{trigger.input_data.media_file_cid}}"
    outputs: [media_data_blob, media_metadata_obj] # Assuming transform provides data and metadata

  - id: "transcribe_media_stt"
    transform: "SpeechToText_Transform_VendorOpenAI" # Example STT transform
    ionwall_approval_scope: "execute_stt:datascribe_transcription"
    inputs:
      media_content_blob: "{{nodes.fetch_media_file.outputs.media_data_blob}}"
      language_code: "{{trigger.input_data.transcription_options.language}}"
      # model_preference: "whisper-large-v3" # Example config for the transform
    outputs: [raw_transcript_text, stt_confidence_score, detected_language_code]

  - id: "format_clean_transcript"
    transform: "TextFormatClean_Transform_Standard"
    ionwall_approval_scope: "execute_text_processing:datascribe_formatting" # Generic scope
    inputs:
      raw_text: "{{nodes.transcribe_media_stt.outputs.raw_transcript_text}}"
      formatting_ruleset_name: "default_transcript_punctuation_speaker_diarization" # Config for the transform
      # custom_formatting_rules_cid: "{{trigger.input_data.transcription_options.custom_formatting_cid}}" # Allow override
    outputs: [formatted_transcript_text]

  - id: "store_formatted_transcript"
    transform: "StoreToIONPOD_Transform_IONWALL"
    ionwall_approval_scope: "write_pod_data:datascribe_output_transcript"
    inputs:
      data_to_store: "{{nodes.format_clean_transcript.outputs.formatted_transcript_text}}"
      filename_suggestion: "transcript_{{trigger.input_data.media_file_cid}}.txt"
      metadata: {
        agent_name: "Datascribe Transcript Agent", version: "0.9.0", type: "transcript",
        source_media_cid: "{{trigger.input_data.media_file_cid}}",
        language: "{{nodes.transcribe_media_stt.outputs.detected_language_code}}",
        stt_confidence: "{{nodes.transcribe_media_stt.outputs.stt_confidence_score}}"
      }
    outputs: [stored_transcript_cid]

  # Conditional Summary Generation
  - id: "check_summary_needed"
    transform: "ConditionalBoolean_Transform" # A simple utility transform
    inputs:
      value: "{{trigger.input_data.transcription_options.generate_summary}}"
    outputs: [is_true]

  - id: "fetch_summary_prompt_conditional"
    transform: "FetchFromIONPOD_Transform_IONWALL"
    if: "{{nodes.check_summary_needed.outputs.is_true == true && trigger.input_data.transcription_options.summary_prompt_override_cid != null}}"
    ionwall_approval_scope: "read_pod_data:datascribe_custom_prompt"
    inputs:
      cid: "{{trigger.input_data.transcription_options.summary_prompt_override_cid}}"
    outputs: [custom_summary_prompt_text]

  - id: "generate_summary_llm"
    transform: "MuseGen_LLM_Transform"
    if: "{{nodes.check_summary_needed.outputs.is_true == true}}"
    ionwall_approval_scope: "execute_llm:datascribe_summarization"
    inputs:
      prompt_template: "{{nodes.fetch_summary_prompt_conditional.outputs.custom_summary_prompt_text if nodes.fetch_summary_prompt_conditional.outputs.custom_summary_prompt_text else 'Provide a concise summary of the following transcript: {{text_input}}'}}"
      text_input: "{{nodes.format_clean_transcript.outputs.formatted_transcript_text}}"
      llm_config: { model_id: "claude-3-haiku-20240307", max_tokens_to_sample: 512, temperature: 0.6 }
    outputs: [summary_text_output, summary_llm_tokens_processed]

  - id: "store_summary_text"
    transform: "StoreToIONPOD_Transform_IONWALL"
    if: "{{nodes.check_summary_needed.outputs.is_true == true && nodes.generate_summary_llm.outputs.summary_text_output != null}}"
    ionwall_approval_scope: "write_pod_data:datascribe_output_summary"
    inputs:
      data_to_store: "{{nodes.generate_summary_llm.outputs.summary_text_output}}"
      filename_suggestion: "summary_{{trigger.input_data.media_file_cid}}.txt"
      metadata: { agent_name: "Datascribe Transcript Agent", version: "0.9.0", type: "summary", source_transcript_cid: "{{nodes.store_formatted_transcript.outputs.stored_transcript_cid}}" }
    outputs: [stored_summary_cid]

  # Conditional Keyword Generation (similar structure for keywords)
  - id: "check_keywords_needed"
    transform: "ConditionalBoolean_Transform"
    inputs:
      value: "{{trigger.input_data.transcription_options.generate_keywords}}"
    outputs: [is_true]

  - id: "generate_keywords_llm" # Could also be a non-LLM keyword specific transform
    transform: "MuseGen_LLM_Transform" # Or "KeywordExtractor_Transform_RAKE"
    if: "{{nodes.check_keywords_needed.outputs.is_true == true}}"
    ionwall_approval_scope: "execute_llm:datascribe_keyword_extraction" # or "execute_text_analysis:datascribe_keyword_extraction"
    inputs:
      prompt_template: "Extract the top 5-10 most relevant keywords from this transcript: {{text_input}}. Return as a JSON array of strings."
      text_input: "{{nodes.format_clean_transcript.outputs.formatted_transcript_text}}"
      llm_config: { model_id: "claude-3-haiku-20240307", max_tokens_to_sample: 100 } # Expecting structured output
    outputs: [keywords_json_string, keywords_llm_tokens_processed] # Assuming LLM returns JSON string

  - id: "store_keywords_list"
    transform: "StoreToIONPOD_Transform_IONWALL"
    if: "{{nodes.check_keywords_needed.outputs.is_true == true && nodes.generate_keywords_llm.outputs.keywords_json_string != null}}"
    ionwall_approval_scope: "write_pod_data:datascribe_output_keywords"
    inputs:
      data_to_store: "{{nodes.generate_keywords_llm.outputs.keywords_json_string}}"
      filename_suggestion: "keywords_{{trigger.input_data.media_file_cid}}.json"
      metadata: { agent_name: "Datascribe Transcript Agent", version: "0.9.0", type: "keywords", source_transcript_cid: "{{nodes.store_formatted_transcript.outputs.stored_transcript_cid}}" }
    outputs: [stored_keywords_cid]

  - id: "publish_completion_event"
    transform: "IPC_NATS_Publish_Transform"
    inputs:
      topic: "ionflux.agents.datascribe_transcript.completion"
      message:
        status: "{{'success'}}" # Determine dynamically based on actual success of critical steps
        transcript_cid: "{{nodes.store_formatted_transcript.outputs.stored_transcript_cid}}"
        summary_cid: "{{nodes.store_summary_text.outputs.stored_summary_cid if nodes.store_summary_text else null}}"
        keywords_cid: "{{nodes.store_keywords_list.outputs.stored_keywords_cid if nodes.store_keywords_list else null}}"
        usage_metrics: {
           media_duration_seconds: "{{nodes.fetch_media_file.outputs.media_metadata_obj.duration_seconds}}", # Assuming metadata has duration
           stt_processing_time_ms: "{{nodes.transcribe_media_stt.outputs.processing_time_ms}}", # Assuming STT transform outputs this
           llm_tokens_processed_summary: "{{nodes.generate_summary_llm.outputs.summary_llm_tokens_processed if nodes.generate_summary_llm else 0}}",
           llm_tokens_processed_keywords: "{{nodes.generate_keywords_llm.outputs.keywords_llm_tokens_processed if nodes.generate_keywords_llm else 0}}"
           # total_execution_time_ms would need to be calculated or be a special output of the FluxGraph engine
        }
        trigger_input: "{{trigger.input_data}}"
    dependencies: [store_formatted_transcript] # Must wait for primary output. Secondary outputs are conditional.
```

---
## 3. Database Schema Fields (`agent_definitions` table)

### 3.1. `agent_name`
`"Datascribe Transcript Agent"`

### 3.2. `version`
`"0.9.0"`

### 3.3. `description`
`"Transcribes audio/video content using a STT (Speech-to-Text) transform, cleans/formats the transcript, and optionally generates summaries or keyword lists using an LLM transform. Input from IONPOD, output to IONPOD, managed by IONWALL."`

### 3.4. `status`
`"development"`

### 3.5. `flux_graph_dsl_yaml`
*(The YAML content from Section 2 is inserted here as a multi-line string)*
```yaml
# /specs/agents/datascribe_transcript_agent_fluxgraph.yaml (Conceptual representation)
version: "0.1.0" # FluxGraph spec version
name: "datascribe_transcript_agent_fluxgraph"
description: "Transcribes audio/video content, formats the transcript, and optionally generates summaries and keywords."

triggers:
  - type: "manual"
  - type: "event_driven"
    config: { event_source: "IONPOD", event_filter_metadata_key: "ionflux_process_for_transcription", event_filter_metadata_value: "true" }
  - type: "webhook"
    config: { path: "/webhooks/invoke/datascribe_transcript", method: "POST", authentication_method: "ionwall_jwt" }

input_schema: # JSON schema for expected input when triggered
  type: "object"
  properties:
    media_file_cid: { type: "string", description: "IPFS CID of the audio or video file stored in IONPOD." }
    transcription_options: {
      type: "object",
      properties: {
        language: { type: "string", default: "en-US", description: "Language code for transcription (e.g., en-US, es-ES)." },
        generate_summary: { type: "boolean", default: false, description: "Whether to generate a summary of the transcript." },
        generate_keywords: { type: "boolean", default: false, description: "Whether to extract keywords from the transcript." },
        summary_prompt_override_cid: { type: "string", nullable: true, description: "Optional CID of a custom prompt for summary generation."}
      },
      additionalProperties: false
    }
  required: [ "media_file_cid" ]

output_schema: # JSON schema for the agent's final output
  type: "object"
  properties:
    transcript_cid: { type: "string", description: "IPFS CID of the formatted transcript text file in IONPOD." }
    summary_cid: { type: "string", nullable: true, description: "IPFS CID of the generated summary text file in IONPOD (if requested)." }
    keywords_cid: { type: "string", nullable: true, description: "IPFS CID of the generated keywords list/object in IONPOD (if requested)." }
    status: { type: "string", enum: ["success", "failure", "partial_success"] }
    error_message: { type: "string", nullable: true }
    usage_metrics: {
      type: "object",
      properties: {
        media_duration_seconds: { type: "number" },
        stt_processing_time_ms: { type: "integer" },
        llm_tokens_processed_summary: { type: "integer", nullable: true },
        llm_tokens_processed_keywords: { type: "integer", nullable: true },
        total_execution_time_ms: { type: "integer" }
      }
    }
  required: ["status"] # transcript_cid should also be required on success

graph: # DAG of transforms
  - id: "fetch_media_file"
    transform: "FetchFromIONPOD_Transform_IONWALL"
    ionwall_approval_scope: "read_pod_data:datascribe_input_media"
    inputs:
      cid: "{{trigger.input_data.media_file_cid}}"
    outputs: [media_data_blob, media_metadata_obj] # Assuming transform provides data and metadata

  - id: "transcribe_media_stt"
    transform: "SpeechToText_Transform_VendorOpenAI" # Example STT transform
    ionwall_approval_scope: "execute_stt:datascribe_transcription"
    inputs:
      media_content_blob: "{{nodes.fetch_media_file.outputs.media_data_blob}}"
      language_code: "{{trigger.input_data.transcription_options.language}}"
      # model_preference: "whisper-large-v3" # Example config for the transform
    outputs: [raw_transcript_text, stt_confidence_score, detected_language_code]

  - id: "format_clean_transcript"
    transform: "TextFormatClean_Transform_Standard"
    ionwall_approval_scope: "execute_text_processing:datascribe_formatting" # Generic scope
    inputs:
      raw_text: "{{nodes.transcribe_media_stt.outputs.raw_transcript_text}}"
      formatting_ruleset_name: "default_transcript_punctuation_speaker_diarization" # Config for the transform
      # custom_formatting_rules_cid: "{{trigger.input_data.transcription_options.custom_formatting_cid}}" # Allow override
    outputs: [formatted_transcript_text]

  - id: "store_formatted_transcript"
    transform: "StoreToIONPOD_Transform_IONWALL"
    ionwall_approval_scope: "write_pod_data:datascribe_output_transcript"
    inputs:
      data_to_store: "{{nodes.format_clean_transcript.outputs.formatted_transcript_text}}"
      filename_suggestion: "transcript_{{trigger.input_data.media_file_cid}}.txt"
      metadata: {
        agent_name: "Datascribe Transcript Agent", version: "0.9.0", type: "transcript",
        source_media_cid: "{{trigger.input_data.media_file_cid}}",
        language: "{{nodes.transcribe_media_stt.outputs.detected_language_code}}",
        stt_confidence: "{{nodes.transcribe_media_stt.outputs.stt_confidence_score}}"
      }
    outputs: [stored_transcript_cid]

  # Conditional Summary Generation
  - id: "check_summary_needed"
    transform: "ConditionalBoolean_Transform" # A simple utility transform
    inputs:
      value: "{{trigger.input_data.transcription_options.generate_summary}}"
    outputs: [is_true]

  - id: "fetch_summary_prompt_conditional"
    transform: "FetchFromIONPOD_Transform_IONWALL"
    if: "{{nodes.check_summary_needed.outputs.is_true == true && trigger.input_data.transcription_options.summary_prompt_override_cid != null}}"
    ionwall_approval_scope: "read_pod_data:datascribe_custom_prompt"
    inputs:
      cid: "{{trigger.input_data.transcription_options.summary_prompt_override_cid}}"
    outputs: [custom_summary_prompt_text]

  - id: "generate_summary_llm"
    transform: "MuseGen_LLM_Transform"
    if: "{{nodes.check_summary_needed.outputs.is_true == true}}"
    ionwall_approval_scope: "execute_llm:datascribe_summarization"
    inputs:
      prompt_template: "{{nodes.fetch_summary_prompt_conditional.outputs.custom_summary_prompt_text if nodes.fetch_summary_prompt_conditional.outputs.custom_summary_prompt_text else 'Provide a concise summary of the following transcript: {{text_input}}'}}"
      text_input: "{{nodes.format_clean_transcript.outputs.formatted_transcript_text}}"
      llm_config: { model_id: "claude-3-haiku-20240307", max_tokens_to_sample: 512, temperature: 0.6 }
    outputs: [summary_text_output, summary_llm_tokens_processed]

  - id: "store_summary_text"
    transform: "StoreToIONPOD_Transform_IONWALL"
    if: "{{nodes.check_summary_needed.outputs.is_true == true && nodes.generate_summary_llm.outputs.summary_text_output != null}}"
    ionwall_approval_scope: "write_pod_data:datascribe_output_summary"
    inputs:
      data_to_store: "{{nodes.generate_summary_llm.outputs.summary_text_output}}"
      filename_suggestion: "summary_{{trigger.input_data.media_file_cid}}.txt"
      metadata: { agent_name: "Datascribe Transcript Agent", version: "0.9.0", type: "summary", source_transcript_cid: "{{nodes.store_formatted_transcript.outputs.stored_transcript_cid}}" }
    outputs: [stored_summary_cid]

  # Conditional Keyword Generation (similar structure for keywords)
  - id: "check_keywords_needed"
    transform: "ConditionalBoolean_Transform"
    inputs:
      value: "{{trigger.input_data.transcription_options.generate_keywords}}"
    outputs: [is_true]

  - id: "generate_keywords_llm" # Could also be a non-LLM keyword specific transform
    transform: "MuseGen_LLM_Transform" # Or "KeywordExtractor_Transform_RAKE"
    if: "{{nodes.check_keywords_needed.outputs.is_true == true}}"
    ionwall_approval_scope: "execute_llm:datascribe_keyword_extraction" # or "execute_text_analysis:datascribe_keyword_extraction"
    inputs:
      prompt_template: "Extract the top 5-10 most relevant keywords from this transcript: {{text_input}}. Return as a JSON array of strings."
      text_input: "{{nodes.format_clean_transcript.outputs.formatted_transcript_text}}"
      llm_config: { model_id: "claude-3-haiku-20240307", max_tokens_to_sample: 100 } # Expecting structured output
    outputs: [keywords_json_string, keywords_llm_tokens_processed] # Assuming LLM returns JSON string

  - id: "store_keywords_list"
    transform: "StoreToIONPOD_Transform_IONWALL"
    if: "{{nodes.check_keywords_needed.outputs.is_true == true && nodes.generate_keywords_llm.outputs.keywords_json_string != null}}"
    ionwall_approval_scope: "write_pod_data:datascribe_output_keywords"
    inputs:
      data_to_store: "{{nodes.generate_keywords_llm.outputs.keywords_json_string}}"
      filename_suggestion: "keywords_{{trigger.input_data.media_file_cid}}.json"
      metadata: { agent_name: "Datascribe Transcript Agent", version: "0.9.0", type: "keywords", source_transcript_cid: "{{nodes.store_formatted_transcript.outputs.stored_transcript_cid}}" }
    outputs: [stored_keywords_cid]

  - id: "publish_completion_event"
    transform: "IPC_NATS_Publish_Transform"
    inputs:
      topic: "ionflux.agents.datascribe_transcript.completion"
      message:
        status: "{{'success'}}" # Determine dynamically based on actual success of critical steps
        transcript_cid: "{{nodes.store_formatted_transcript.outputs.stored_transcript_cid}}"
        summary_cid: "{{nodes.store_summary_text.outputs.stored_summary_cid if nodes.store_summary_text else null}}"
        keywords_cid: "{{nodes.store_keywords_list.outputs.stored_keywords_cid if nodes.store_keywords_list else null}}"
        usage_metrics: {
           media_duration_seconds: "{{nodes.fetch_media_file.outputs.media_metadata_obj.duration_seconds}}", # Assuming metadata has duration
           stt_processing_time_ms: "{{nodes.transcribe_media_stt.outputs.processing_time_ms}}", # Assuming STT transform outputs this
           llm_tokens_processed_summary: "{{nodes.generate_summary_llm.outputs.summary_llm_tokens_processed if nodes.generate_summary_llm else 0}}",
           llm_tokens_processed_keywords: "{{nodes.generate_keywords_llm.outputs.keywords_llm_tokens_processed if nodes.generate_keywords_llm else 0}}"
           # total_execution_time_ms would need to be calculated or be a special output of the FluxGraph engine
        }
        trigger_input: "{{trigger.input_data}}"
    dependencies: [store_formatted_transcript]
```

### 3.6. `execution_requirements_json`
```json
{
  "transforms_required": [
    "FetchFromIONPOD_Transform_IONWALL",
    "SpeechToText_Transform_VendorOpenAI",
    "TextFormatClean_Transform_Standard",
    "StoreToIONPOD_Transform_IONWALL",
    "ConditionalBoolean_Transform",
    "MuseGen_LLM_Transform",
    "IPC_NATS_Publish_Transform"
  ],
  "min_ram_mb": 1024,
  "gpu_required": false,
  "gpu_type_preference": null,
  "estimated_execution_duration_seconds_per_minute_of_media": 45,
  "max_concurrent_instances": 5,
  "wasm_modules_cids": {
    "FetchFromIONPOD_Transform_IONWALL": "bafyreibvlobj2rl34gsgxrjltirqesqkfbhtharb3uaxnri3ebpmpah6ce",
    "SpeechToText_Transform_VendorOpenAI": "bafyreihs7elajg767iikxgstb7i3jzysxsvhyhhp4kftrccklnlmkqv5wu",
    "TextFormatClean_Transform_Standard": "bafyreihe3tys6tsbafhnv547k3gj6zvhx2zjy6mvxcnmhdhsyxrqepkcbu",
    "StoreToIONPOD_Transform_IONWALL": "bafyreif7yqivqtkjhhwb5xkxqj3j7gyjlrvfkhhvjvbfffj4u7m5kfefbi",
    "ConditionalBoolean_Transform": "bafyreid7q3fxr5a7xkj3hsdq63fmq2m6fsxhmcvk5f7jahlmzcptx5sxqq",
    "MuseGen_LLM_Transform": "bafyreid2qjzjfxjmxkewqlpkg3fxghg7wsbywvh37vmbsfhg77kfavkdbu",
    "IPC_NATS_Publish_Transform": "bafyreihyrz7wgld5qrjmejbdjcbcm3jqrjshxphu6jnlxhnlfbk7d745xy"
  }
}
```

### 3.7. `ecosystem_integration_points_json`
```json
{
  "ionwall_permissions_needed": [
    "read_pod_data:datascribe_input_media",
    "read_pod_data:datascribe_custom_prompt",
    "execute_stt:datascribe_transcription",
    "execute_text_processing:datascribe_formatting",
    "execute_llm:datascribe_summarization",
    "execute_llm:datascribe_keyword_extraction",
    "write_pod_data:datascribe_output_transcript",
    "write_pod_data:datascribe_output_summary",
    "write_pod_data:datascribe_output_keywords"
  ],
  "ionpod_data_access": {
    "inputs": [
      { "cid_param": "media_file_cid", "access_type": "read", "purpose": "Audio/video file for transcription." },
      { "cid_param": "transcription_options.summary_prompt_override_cid", "access_type": "read", "purpose": "Optional custom prompt for summary generation." }
    ],
    "outputs": [
      { "cid_name": "transcript_cid", "access_type": "write", "purpose": "Formatted transcript text file." },
      { "cid_name": "summary_cid", "access_type": "write", "purpose": "Generated summary text file (if requested)." },
      { "cid_name": "keywords_cid", "access_type": "write", "purpose": "Generated keywords list/object (if requested)." }
    ]
  },
  "tokenomic_triggers": [
    { "event": "fluxgraph_successful_completion_with_transcription", "action": "reward_user_ion", "token_id": "$ION", "amount_formula": "0.0005 * usage_metrics.media_duration_seconds" },
    { "event": "transform_SpeechToText_invocation", "action": "debit_user_compute_credits", "token_id": "C-ION", "amount_formula": "0.0001 * usage_metrics.media_duration_seconds" },
    { "event": "transform_MuseGen_LLM_Transform_invocation_summary", "action": "debit_user_compute_credits", "token_id": "C-ION", "amount_formula": "0.0001 * usage_metrics.llm_tokens_processed_summary" },
    { "event": "transform_MuseGen_LLM_Transform_invocation_keywords", "action": "debit_user_compute_credits", "token_id": "C-ION", "amount_formula": "0.0001 * usage_metrics.llm_tokens_processed_keywords" }
  ],
  "techgnosis_integration": {
    "knowledge_graph_queries": [
      "identify_entities_in_text:{{nodes.format_clean_transcript.outputs.formatted_transcript_text}}",
      "classify_text_topic:{{nodes.format_clean_transcript.outputs.formatted_transcript_text}}"
    ],
    "output_metadata_tags_standard": ["transcribed_content", "{{nodes.transcribe_media_stt.outputs.detected_language_code}}"],
    "output_metadata_tags_from_techgnosis": ["identified_entities_list", "classified_topics_list"]
  },
  "hybrid_layer_escalation_points": [
    { "condition": "nodes.transcribe_media_stt.outputs.stt_confidence_score < 0.7", "action": "flag_transcript_for_human_review_accuracy_check" },
    { "condition": "trigger.input_data.transcription_options.request_human_review_for_sensitive_content == true && sensitive_content_detected_by_sub_transform", "action": "pause_and_escalate_for_human_review_content_policy" }
  ],
  "carbon_loop_contribution": {
    "type": "data_efficiency_gain_text_vs_media",
    "value_formula": "(size_bytes(nodes.fetch_media_file.outputs.media_data_blob) - size_bytes(nodes.format_clean_transcript.outputs.formatted_transcript_text)) * carbon_value_per_byte_reduction_factor",
    "description": "Reduces data storage footprint by converting bulky media to text, contributing to data efficiency."
  }
}
```

### 3.8. `prm_details_json`
```json
{
  "default_stt_language": "en-US",
  "allow_user_language_override": true,
  "default_summary_llm_config": { "model_id": "claude-3-haiku-20240307", "temperature": 0.5, "max_tokens_to_sample": 512 },
  "default_keywords_llm_config": { "model_id": "claude-3-haiku-20240307", "temperature": 0.2, "max_tokens_to_sample": 100 },
  "enable_speaker_diarization_if_available_by_stt": true,
  "user_customizable_params": [
    "transcription_options.language",
    "transcription_options.generate_summary",
    "transcription_options.generate_keywords",
    "transcription_options.summary_prompt_override_cid"
  ]
}
```

### 3.9. `input_schema_json`
*(The JSON content of `input_schema` from Section 2 is inserted here)*
```json
{
  "type": "object",
  "properties": {
    "media_file_cid": { "type": "string", "description": "IPFS CID of the audio or video file stored in IONPOD." },
    "transcription_options": {
      "type": "object",
      "properties": {
        "language": { "type": "string", "default": "en-US", "description": "Language code for transcription (e.g., en-US, es-ES)." },
        "generate_summary": { "type": "boolean", "default": false, "description": "Whether to generate a summary of the transcript." },
        "generate_keywords": { "type": "boolean", "default": false, "description": "Whether to extract keywords from the transcript." },
        "summary_prompt_override_cid": { "type": "string", "nullable": true, "description": "Optional CID of a custom prompt for summary generation."}
      },
      "additionalProperties": false
    }
  },
  "required": [ "media_file_cid" ]
}
```

### 3.10. `output_schema_json`
*(The JSON content of `output_schema` from Section 2 is inserted here)*
```json
{
  "type": "object",
  "properties": {
    "transcript_cid": { "type": "string", "description": "IPFS CID of the formatted transcript text file in IONPOD." },
    "summary_cid": { "type": "string", "nullable": true, "description": "IPFS CID of the generated summary text file in IONPOD (if requested)." },
    "keywords_cid": { "type": "string", "nullable": true, "description": "IPFS CID of the generated keywords list/object in IONPOD (if requested)." },
    "status": { "type": "string", "enum": ["success", "failure", "partial_success"] },
    "error_message": { "type": "string", "nullable": true },
    "usage_metrics": {
      "type": "object",
      "properties": {
        "media_duration_seconds": { "type": "number" },
        "stt_processing_time_ms": { "type": "integer" },
        "llm_tokens_processed_summary": { "type": "integer", "nullable": true },
        "llm_tokens_processed_keywords": { "type": "integer", "nullable": true },
        "total_execution_time_ms": { "type": "integer" }
      }
    }
  },
  "required": ["status"]
}
```

### 3.11. `trigger_config_json`
```json
{
  "manual_trigger_enabled": true,
  "event_driven_triggers": [
    {
      "event_source": "IONPOD",
      "event_filter_metadata_key": "ionflux_process_for_transcription",
      "event_filter_metadata_value": "true",
      "description": "Triggers when a new file in IONPOD has metadata 'ionflux_process_for_transcription: true'. Assumes event provides file CID.",
      "input_mapping": {
        "media_file_cid": "{{event.data.cid}}",
        "transcription_options": {
          "language": "{{event.data.metadata.language_hint if event.data.metadata.language_hint else 'en-US'}}",
          "generate_summary": "{{event.data.metadata.generate_summary if event.data.metadata.generate_summary else false}}",
          "generate_keywords": "{{event.data.metadata.generate_keywords if event.data.metadata.generate_keywords else false}}"
        }
      }
    }
  ],
  "webhook_triggers": [
    {
      "endpoint_path": "/webhooks/invoke/datascribe_transcript",
      "http_method": "POST",
      "authentication_method": "ionwall_jwt",
      "description": "HTTP endpoint to trigger transcription. Expects JSON body matching input_schema."
    }
  ]
}
```

### 3.12. `deployment_info_json`
```json
{
  "runtime_environment": "IONFLUX_EdgeNode_Wasm",
  "current_instances_managed_by_ionflux_controller": true,
  "default_replicas": 1,
  "auto_scaling_policy": {
    "min_replicas": 0,
    "max_replicas": 5,
    "cpu_threshold_percentage": 80,
    "queue_length_threshold": 10
  }
}
```

### 3.13. `logging_json`
```json
{
  "log_level": "info",
  "log_targets": ["ionpod_event_log", "local_stdout_dev_mode_only"],
  "log_retention_policy_days": 30,
  "sensitive_fields_to_mask": ["media_file_cid_content_preview_if_any"]
}
```

### 3.14. `monitoring_json`
```json
{
  "metrics_to_collect": [
    "execution_time_total_ms", "stt_processing_time_ms", "llm_tokens_processed_summary", "llm_tokens_processed_keywords",
    "success_rate_fluxgraph", "failure_rate_fluxgraph", "stt_confidence_score_avg",
    "input_media_duration_seconds_avg"
  ],
  "metrics_endpoint_ionwall_protected": "/metrics/datascribe_transcript_agent",
  "health_check_protocol": "internal_ping_to_controller_check_transform_availability",
  "alerting_rules": [
    {"metric": "failure_rate_fluxgraph", "condition": "value > 0.15 for 10m", "severity": "critical", "notification_channel": "hybrid_layer_ops_pager"},
    {"metric": "stt_confidence_score_avg", "condition": "value < 0.75 for 1h", "severity": "warning", "notification_channel": "hybrid_layer_ops_team_chat"}
  ]
}
```

### 3.15. `security_json`
```json
{
  "data_encryption_at_rest_ionpod": true,
  "data_encryption_in_transit_ipfs_ionwall": true,
  "required_ionwall_consent_scopes": [
    "read_pod_data:datascribe_input_media", "read_pod_data:datascribe_custom_prompt",
    "execute_stt:datascribe_transcription", "execute_text_processing:datascribe_formatting",
    "execute_llm:datascribe_summarization", "execute_llm:datascribe_keyword_extraction",
    "write_pod_data:datascribe_output_transcript", "write_pod_data:datascribe_output_summary", "write_pod_data:datascribe_output_keywords"
  ],
  "gdpr_compliance_features_enabled": true,
  "pii_detection_and_redaction_options": ["transcript_text_pii_scan_on_request_via_transform"],
  "sensitive_data_handling_policy_id": "SDP-DATASCRB-001",
  "input_validation_rules": {
    "max_media_file_size_bytes": 1073741824, "allowed_media_mime_types": ["audio/mpeg", "audio/wav", "video/mp4", "video/quicktime"]
  }
}
```

---
## 4. User Experience Flow (Conceptual)

1.  **Initiation:**
    *   User uploads an audio/video file to their IONPOD and, through a UI, sets metadata: `ionflux_process_for_transcription: true`. Alternatively, a user selects "Transcribe Media" in an app and chooses a file from IONPOD.
    *   User might specify options like "Generate Summary" or "Target Language" via UI mapped to `transcription_options`.
2.  **IONWALL Checkpoint 1 (Data Access & Core Action):**
    *   IONWALL prompts: *"Datascribe Transcript Agent wants to:
        *   Read 'Media File: {{media_file_cid.name}}' from your IONPOD.
        *   (If custom prompt CID provided) Read 'Custom Prompt: {{summary_prompt_override_cid.name}}' from your IONPOD.
        *   Perform Speech-to-Text transcription.
        *   (If generate_summary is true) Perform AI-based summarization.
        *   (If generate_keywords is true) Perform AI-based keyword extraction.
        This may use C-ION compute credits. Allow?"*
3.  **Execution:**
    *   Agent fetches media via `FetchFromIONPOD_Transform_IONWALL`.
    *   `SpeechToText_Transform` processes the media.
    *   `TextFormatClean_Transform` formats the raw transcript.
    *   If requested, `MuseGen_LLM_Transform` is invoked for summary and/or keywords.
    *   Progress updates (e.g., "Transcribing...", "Summarizing...") might be shown.
4.  **IONWALL Checkpoint 2 (Output Storage):**
    *   IONWALL prompts: *"Datascribe Transcript Agent wants to save:
        *   'Transcript: transcript_{{media_file_cid.name}}.txt' to your IONPOD.
        *   (If generated) 'Summary: summary_{{media_file_cid.name}}.txt' to your IONPOD.
        *   (If generated) 'Keywords: keywords_{{media_file_cid.name}}.json' to your IONPOD.
        Allow?"*
5.  **Completion/Notification:**
    *   User is notified: "Transcription complete for {{media_file_cid.name}}!"
    *   CIDs of the transcript, summary, and keywords are available.
    *   `IPC_NATS_Publish_Transform` sends a detailed completion event.

---
## 5. TechGnosis & Hybrid Layer Integration Notes

*   **TechGnosis:**
    *   The agent uses TechGnosis integration (as defined in `ecosystem_integration_points_json`) to identify entities and classify topics from the formatted transcript. This enriched metadata can be stored alongside the transcript or used for further processing by other agents.
    *   Keywords generated can be cross-referenced with TechGnosis knowledge graph for disambiguation or to link to broader concepts.
*   **Hybrid Layer:**
    *   Low STT confidence scores (e.g., `< 0.7`) trigger a flag for human review of the transcript's accuracy. The UI could highlight segments with low confidence.
    *   If the user or an upstream process flags the input media for potentially sensitive content, and a (hypothetical) sub-transform detects such content during processing, the agent can pause and escalate to the Hybrid Layer for review before further processing or storage.

---
## 6. Carbon Loop Integration Notes

*   The agent contributes to the Carbon Loop by **data efficiency gain**. Converting audio/video (large file sizes) to text (much smaller file sizes) significantly reduces storage footprint. The `carbon_loop_contribution` formula in `ecosystem_integration_points_json` quantifies this.
*   This efficiency can lead to reduced energy consumption for data storage and transmission within the ION sNetwork.

---
## 7. Dependencies & Interactions

*   **Required Transforms:**
    *   `FetchFromIONPOD_Transform_IONWALL`
    *   `SpeechToText_Transform_VendorOpenAI` (or other STT provider transform)
    *   `TextFormatClean_Transform_Standard`
    *   `StoreToIONPOD_Transform_IONWALL`
    *   `ConditionalBoolean_Transform`
    *   `MuseGen_LLM_Transform` (for summary/keywords)
    *   `IPC_NATS_Publish_Transform`
*   **Interacting Agents (Conceptual):**
    *   May provide transcripts to `Muse Prompt Chain Agent` for further processing.
    *   Could be triggered by a `Content Ingestion Agent` that places media into IONPOD.
    *   Its outputs (textual data) could be used by various analytical or archival agents.
*   **External Systems (via Transforms):**
    *   STT Provider APIs (e.g., OpenAI Whisper API) via `SpeechToText_Transform_VendorOpenAI`.
    *   LLM Provider APIs (e.g., Anthropic Claude) via `MuseGen_LLM_Transform`.

---
## 8. Open Questions & Future Considerations

*   Choice of specific STT and LLM transforms: Should these be configurable by the user at runtime, or fixed per agent version? (Current design allows some LLM config, STT is fixed).
*   Support for more languages and dialects in STT.
*   Advanced text formatting options (e.g., custom dictionaries, speaker label editing).
*   Batch processing of multiple media files.
*   More sophisticated keyword extraction methods (e.g., RAKE, YAKE!, or LLM-based with specific prompting for structure).
*   Integration with a dedicated "PII Detection & Redaction Transform" as a standard step before storage.
*   How to best calculate and expose `total_execution_time_ms` in `usage_metrics`.
