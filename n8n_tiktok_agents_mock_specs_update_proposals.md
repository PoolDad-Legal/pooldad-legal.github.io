```markdown
# Proposed Revisions for n8n_tiktok_agents_mock_specs.md

This document outlines proposed textual revisions to `n8n_tiktok_agents_mock_specs.md` to align with the updated `core_agent_blueprints.md` (specifically for AGENTE 003 - TikTokStylist and AGENTE 005 - UGCMatchmaker), the revised `agent_interaction_model.md`, and the updated `conceptual_definition.md`.

## General Changes Applicable to Both Workflows:

*   **Workflow Naming:** Ensure workflow names clearly indicate they are for the E2E demo mocks (e.g., "E2E Demo Mock: TikTok Stylist", "E2E Demo Mock: UGC Matchmaker - TikTok").
*   **Error Handling:** Add a note that production workflows would need robust error handling, but for the mock, we assume success paths.

## 1. TikTok Stylist (AGENTE 003) n8n Workflow Mock

### 1.1. Trigger (Webhook Node - "Start")

*   **Current (Assumed):** Webhook receives `agent_id`, `config_overrides`, `runtime_params`.
*   **Proposed Revision:**
    *   **Description:** "Webhook trigger that starts the TikTok Stylist agent mock workflow. Receives run details and the effective agent configuration from the Agent Service."
    *   **Expected Input Data (JSON Body):**
        ```json
        {
          "run_id": "unique_run_identifier",
          "agent_configuration_id": "config_id_for_this_agent_instance",
          "workspace_id": "user_workspace_id",
          "user_id": "triggering_user_id",
          "effective_config": {
            // Merged AgentConfiguration.yaml_config & runtime_params
            // Based on TikTok Stylist (AGENTE 003) inputs_schema:
            "input_tiktok_platform_credentials_secret_ref": "Optional<String>", // Assumed to be handled by Agent Service for actual API calls
            "input_target_audience_description": "String", // e.g., "Gen Z interested in sustainable fashion"
            "input_brand_voice_keywords": ["eco-friendly", "trendy", "inclusive"],
            "input_content_pillars_topics": ["DIY upcycling", "Ethical brand spotlights"],
            "input_specific_campaign_objectives": "Optional<String>", // e.g., "Promote new summer collection"
            "input_key_product_service_features_to_highlight": "Optional<Array<String>>",
            "input_current_tiktok_trends_research_depth": "basic", // enum: "basic", "deep_dive"
            "input_competitor_analysis_tiktok_handles": "Optional<Array<String>>",
            "input_desired_output_formats_style_suggestions": ["content_calendar_md", "trend_report_pdf"], // For mock, we'll focus on core data
            "input_integration_with_brand_assets_drive_url": "Optional<String>",
            "input_raw_video_clips_or_image_urls_for_remix": "Optional<Array<String>>",
            "input_cta_text_and_links_for_generated_content": "Optional<Array<Object>>" // {text: "Shop Now", link: "..."}
          }
        }
        ```
    *   **Note:** "The `effective_config` contains all necessary parameters derived from the agent's configuration and any runtime inputs. The n8n workflow will use these values directly."

### 1.2. Core Workflow Steps (n8n Nodes)

#### 1.2.1. Node: Simulate TikTok API for Trends
    *   **Current (Assumed):** Generic mock.
    *   **Proposed Revision:**
        *   **Type:** Function Node
        *   **Name:** "Simulate TikTok API - Fetch Trends"
        *   **Logic:**
            *   Access `effective_config.input_target_audience_description` and `effective_config.input_content_pillars_topics` to (conceptually) refine mock data generation.
            *   If `effective_config.input_current_tiktok_trends_research_depth` is "deep_dive", generate more trends.
            *   **Mock Output:** Generate a list of 3-5 mocked trending sounds, effects, and hashtags.
                *   Example:
                    ```json
                    [
                      { "type": "sound", "name": "Catchy Tune Alpha", "source_url": "https://tiktok.com/sounds/alpha", "current_usage_estimate": 150000 },
                      { "type": "hashtag", "name": "#SustainableStyleHacks", "source_url": "https://tiktok.com/tags/sustainablestylehacks", "current_usage_estimate": 75000 },
                      { "type": "effect", "name": "Vintage Film Filter", "source_url": "https://tiktok.com/effects/vintagefilm", "current_usage_estimate": 90000 }
                    ]
                    ```

#### 1.2.2. Node: Simulate LLM for Content Ideation
    *   **Current (Assumed):** Generic mock.
    *   **Proposed Revision:**
        *   **Type:** Function Node
        *   **Name:** "Simulate LLM - Generate Content Ideas"
        *   **Logic:**
            *   Takes the mocked trends from the previous step as input.
            *   Uses `effective_config.input_target_audience_description`, `effective_config.input_brand_voice_keywords`, `effective_config.input_content_pillars_topics`, and `effective_config.input_specific_campaign_objectives` (if provided) to generate 1-2 content ideas per trend.
            *   Each idea should be a brief concept.
            *   **Mock Output Structure (aligns with `output_tiktok_content_strategy_and_ideas` from blueprint):**
                ```json
                {
                  "trend_insights_and_analysis": [
                    {
                      "trend_details": { "type": "sound", "name": "Catchy Tune Alpha", "source_url": "https://tiktok.com/sounds/alpha", "current_usage_estimate": 150000 },
                      "content_ideas": [
                        { "idea_title": "Eco-Friendly Outfit Transition with Alpha Tune", "concept_description": "Showcase 3 sustainable outfits transitioning smoothly with 'Catchy Tune Alpha'. Highlight brand values from `input_brand_voice_keywords`.", "suggested_cta": "Shop eco-collection! Link in bio." }
                      ],
                      "customization_notes": "Consider using `input_key_product_service_features_to_highlight` for product placements."
                    },
                    {
                      "trend_details": { "type": "hashtag", "name": "#SustainableStyleHacks", "source_url": "https://tiktok.com/tags/sustainablestylehacks", "current_usage_estimate": 75000 },
                      "content_ideas": [
                        { "idea_title": "DIY Upcycling Hack using #SustainableStyleHacks", "concept_description": "A quick tutorial on upcycling an old garment, fitting the `input_content_pillars_topics`. Use #SustainableStyleHacks.", "suggested_cta": "Try it & tag us!" }
                      ],
                      "customization_notes": "Collaborate with a micro-influencer for wider reach if `input_competitor_analysis_tiktok_handles` shows similar successful strategies."
                    }
                  ],
                  "overall_strategic_recommendations": "Focus on authentic, short-form video content. Leverage trending sounds quickly. Ensure CTAs from `input_cta_text_and_links_for_generated_content` are clear."
                }
                ```

### 1.3. Output/Callback (HTTP Request Node)

*   **Current (Assumed):** Basic callback with results.
*   **Proposed Revision:**
    *   **Name:** "Callback to Agent Service"
    *   **URL:** `{{ $json.env.AGENT_SERVICE_BASE_URL }}/api/v1/agent-runs/{{ $json.webhook.body.run_id }}/completed` (Assuming AGENT_SERVICE_BASE_URL is an n8n environment variable)
    *   **Method:** POST
    *   **Body Type:** JSON
    *   **JSON Body:**
        ```json
        {
          "status": "succeeded", // or "failed"
          "output_preview": "Generated 2 trend insights with content ideas for TikTok.",
          "full_output_reference": "{{ JSON.stringify($node[\"Simulate LLM - Generate Content Ideas\"].json) }}", // Stringified JSON of the detailed output
          "error_message": null // Or provide error details if status is "failed"
        }
        ```
    *   **Note:** "`full_output_reference` contains the complete mocked analysis and ideas. `output_preview` provides a brief summary for quick display."

---

## 2. UGC Matchmaker (TikTok Focus - AGENTE 005) n8n Workflow Mock

### 2.1. Trigger (Webhook Node - "Start")

*   **Current (Assumed):** Webhook receives `agent_id`, `config_overrides`, `runtime_params`.
*   **Proposed Revision:**
    *   **Description:** "Webhook trigger that starts the UGC Matchmaker (TikTok Focus) agent mock workflow. Receives run details and the effective agent configuration from the Agent Service."
    *   **Expected Input Data (JSON Body):**
        ```json
        {
          "run_id": "unique_run_identifier",
          "agent_configuration_id": "config_id_for_this_agent_instance",
          "workspace_id": "user_workspace_id",
          "user_id": "triggering_user_id",
          "effective_config": {
            // Merged AgentConfiguration.yaml_config & runtime_params
            // Based on UGC Matchmaker (AGENTE 005) inputs_schema:
            "input_tiktok_platform_credentials_secret_ref": "Optional<String>", // Assumed handled by Agent Service
            "input_brand_product_service_description": "String", // e.g., "Sustainable handmade candles"
            "input_ideal_creator_persona_description": "String", // e.g., "Eco-conscious home decor enthusiasts, values authenticity"
            "input_content_style_and_tone_preferences": ["aesthetic", "calm", "informative"],
            "input_target_audience_demographics_for_creators": "Optional<String>", // e.g., "USA, 25-45, female"
            "input_keywords_and_hashtags_for_creator_search": ["#ecohome", "#handmadecandles"],
            "input_creator_niche_focus": "home_decor", // Example from blueprint
            "input_min_follower_count": 1000,
            "input_max_follower_count": "Optional<Integer>",
            "input_min_engagement_rate_percentage": "Optional<Float>", // e.g., 2.5
            "input_geographical_location_preferences_for_creators": "Optional<Array<String>>",
            "input_past_collaboration_red_flags_keywords": "Optional<Array<String>>",
            "input_assess_brand_fit_using_llm": true,
            "input_number_of_creators_to_shortlist": 5,
            "input_custom_message_template_for_outreach": "Optional<String>"
          }
        }
        ```
    *   **Note:** "The `effective_config` contains all necessary parameters. The workflow will use these values to simulate creator discovery and assessment."

### 2.2. Core Workflow Steps (n8n Nodes)

#### 2.2.1. Node: Simulate TikTok Creator Search
    *   **Current (Assumed):** Generic mock.
    *   **Proposed Revision:**
        *   **Type:** Function Node
        *   **Name:** "Simulate TikTok Creator Search"
        *   **Logic:**
            *   Access `effective_config.input_keywords_and_hashtags_for_creator_search`, `effective_config.input_creator_niche_focus`, and `effective_config.input_min_follower_count`.
            *   Generate a list of 5-10 mocked TikTok creator profiles.
            *   Each profile should include: `id`, `username`, `follower_count`, `avg_engagement_rate` (mocked), `niche_tags` (array of strings), `sample_video_urls` (array of strings), `bio`.
            *   Filter this list based on `effective_config.input_min_follower_count` (and `max_follower_count`, `min_engagement_rate_percentage` if implemented for more detail).
            *   Limit the list to `effective_config.input_number_of_creators_to_shortlist` after filtering.
            *   **Mock Output Example (single creator):**
                ```json
                {
                  "id": "creator123",
                  "username": "EcoHomeAlice",
                  "follower_count": 15000,
                  "avg_engagement_rate": 3.5,
                  "niche_tags": ["eco-friendly", "home decor", "diy"],
                  "sample_video_urls": ["https://tiktok.com/alice/video1", "https://tiktok.com/alice/video2"],
                  "bio": "Lover of all things sustainable and beautiful for your home.",
                  "profile_url": "https://tiktok.com/@EcoHomeAlice"
                }
                ```

#### 2.2.2. Node: Simulate LLM for Brand Fit Assessment (Conditional)
    *   **Current (Assumed):** May not exist or is generic.
    *   **Proposed Revision:**
        *   **Type:** Function Node (could also be a Switch node leading to this Function node)
        *   **Name:** "Simulate LLM - Assess Brand Fit"
        *   **Execution Condition:** Only run if `effective_config.input_assess_brand_fit_using_llm` is `true`.
        *   **Logic:**
            *   Takes the list of mocked creators from the previous step.
            *   For each creator, use `effective_config.input_brand_product_service_description` and `effective_config.input_ideal_creator_persona_description` to generate a mock qualitative assessment.
            *   **Mock Output:** Add an `brand_fit_assessment` object to each creator profile.
                *   Example for one creator:
                    ```json
                    {
                      // ... existing creator fields ...
                      "brand_fit_assessment": {
                        "score": 0.85, // Mocked score 0.0 to 1.0
                        "reasoning": "Aligns well with eco-conscious values. Content style is aesthetic and informative. Audience likely matches target demographics.",
                        "potential_collaboration_ideas": ["Review of new candle line", "DIY home decor using our products"]
                      }
                    }
                    ```

### 2.3. Output/Callback (HTTP Request Node)

*   **Current (Assumed):** Basic callback.
*   **Proposed Revision:**
    *   **Name:** "Callback to Agent Service"
    *   **URL:** `{{ $json.env.AGENT_SERVICE_BASE_URL }}/api/v1/agent-runs/{{ $json.webhook.body.run_id }}/completed`
    *   **Method:** POST
    *   **Body Type:** JSON
    *   **JSON Body:**
        ```json
        {
          "status": "succeeded",
          "output_preview": "Found {{ $node[\"Simulate TikTok Creator Search\"].json.length }} potential TikTok creators matching criteria.",
          // If brand fit assessment was run, the data from that node would be used. Otherwise, use the output of creator search.
          // This assumes the brand fit node passes through or merges data.
          // A more robust way would be to have a dedicated "Prepare Output" node. For this proposal, we'll assume direct use.
          "full_output_reference": "{{ JSON.stringify($node[ $json.webhook.body.effective_config.input_assess_brand_fit_using_llm ? \"Simulate LLM - Assess Brand Fit\" : \"Simulate TikTok Creator Search\" ].json) }}",
          "error_message": null
        }
        ```
    *   **Note:** "`full_output_reference` contains the list of mocked creators (with assessments if performed). `output_preview` gives a count. The conditional logic for `full_output_reference` ensures the correct node's data is captured."
    *   **Alternative for `full_output_reference` if nodes don't easily pass through all data:** Have a final "Compile Output" Function node that takes inputs from previous relevant nodes and structures the final JSON object for `full_output_reference`.

---

These proposed revisions aim to make the n8n mock workflows for TikTok Stylist and UGC Matchmaker more closely reflect the detailed agent inputs, outputs, and interaction patterns defined in the core project documents.
```
