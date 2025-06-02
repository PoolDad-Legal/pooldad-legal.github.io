```markdown
# n8n Workflow Mock Specifications: TikTok Agents (E2E Demo)

This document provides specifications for n8n workflow mocks for TikTok-related agents, specifically for the E2E demo. These mocks simulate the behavior of the agents by interacting with mocked data and services.

## General Changes Applicable to Both Workflows:

*   **Workflow Naming:** Ensure workflow names clearly indicate they are for the E2E demo mocks (e.g., "E2E Demo Mock: TikTok Stylist", "E2E Demo Mock: UGC Matchmaker - TikTok").
*   **Error Handling:** Add a note that production workflows would need robust error handling, but for the mock, we assume success paths.
*   **Environment Variables:** It's assumed that `AGENT_SERVICE_BASE_URL` will be available as an n8n environment variable for constructing callback URLs.

## 1. TikTok Stylist (AGENTE 003) n8n Workflow Mock

### 1.1. Trigger (Webhook Node - "Start")

*   **Description:** "Webhook trigger that starts the TikTok Stylist agent mock workflow. Receives run details and the effective agent configuration from the Agent Service."
*   **Method:** POST
*   **Path:** (Defined by n8n when the webhook is created, e.g., `/webhook/tiktok-stylist-mock`)
*   **Authentication:** Secure webhook with a unique token if possible, or rely on network-level security for the demo.
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

#### 1.2.1. Node: Simulate TikTok API - Fetch Trends
*   **Type:** Function Node
*   **Name:** "Simulate TikTok API - Fetch Trends"
*   **Logic:**
    *   Access `effective_config.input_target_audience_description` and `effective_config.input_content_pillars_topics` to (conceptually) refine mock data generation.
    *   If `effective_config.input_current_tiktok_trends_research_depth` is "deep_dive", generate more trends (e.g., 5-7 vs. 3-5 for "basic").
    *   **Mock Output:** Generate a list of mocked trending sounds, effects, and hashtags.
        *   Example:
            ```json
            [
              { "type": "sound", "name": "Catchy Tune Alpha", "source_url": "https://tiktok.com/sounds/alpha", "current_usage_estimate": 150000 },
              { "type": "hashtag", "name": "#SustainableStyleHacks", "source_url": "https://tiktok.com/tags/sustainablestylehacks", "current_usage_estimate": 75000 },
              { "type": "effect", "name": "Vintage Film Filter", "source_url": "https://tiktok.com/effects/vintagefilm", "current_usage_estimate": 90000 }
            ]
            ```
    *   This node passes its output to the next node.

#### 1.2.2. Node: Simulate LLM - Generate Content Ideas
*   **Type:** Function Node
*   **Name:** "Simulate LLM - Generate Content Ideas"
*   **Logic:**
    *   Takes the mocked trends from the "Simulate TikTok API - Fetch Trends" node as input.
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
            // Add more trend insights as generated
          ],
          "overall_strategic_recommendations": "Focus on authentic, short-form video content. Leverage trending sounds quickly. Ensure CTAs from `input_cta_text_and_links_for_generated_content` (if provided) are clear."
        }
        ```
    *   This node's output is the final data for the callback.

### 1.3. Output/Callback (HTTP Request Node)

*   **Name:** "Callback to Agent Service"
*   **URL:** `{{ $json.env.AGENT_SERVICE_BASE_URL }}/api/v1/agent-runs/{{ $json.webhook.body.run_id }}/completed`
*   **Method:** POST
*   **Body Type:** JSON
*   **Send JSON Body:**
    ```json
    {
      "status": "succeeded",
      "output_preview": "Generated {{ $node[\"Simulate LLM - Generate Content Ideas\"].json.trend_insights_and_analysis.length }} trend insights with content ideas for TikTok.",
      "full_output_reference": "{{ JSON.stringify($node[\"Simulate LLM - Generate Content Ideas\"].json) }}",
      "error_message": null
    }
    ```
*   **Note:** "`full_output_reference` contains the complete mocked analysis and ideas. `output_preview` provides a brief summary for quick display. Ensure `JSON.stringify` is used for `full_output_reference` as Agent Service expects a string."
*   **Error Handling (Simplified for Mock):** If any prior node fails, this node might not be reached. A real workflow would have error branches leading to a callback with `status: "failed"` and an `error_message`.

---

## 2. UGC Matchmaker (TikTok Focus - AGENTE 005) n8n Workflow Mock

### 2.1. Trigger (Webhook Node - "Start")

*   **Description:** "Webhook trigger that starts the UGC Matchmaker (TikTok Focus) agent mock workflow. Receives run details and the effective agent configuration from the Agent Service."
*   **Method:** POST
*   **Path:** (Defined by n8n, e.g., `/webhook/ugc-matchmaker-mock`)
*   **Authentication:** Secure webhook with a unique token if possible.
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
        "input_creator_niche_focus": "home_decor",
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
*   **Type:** Function Node
*   **Name:** "Simulate TikTok Creator Search"
*   **Logic:**
    *   Access `effective_config.input_keywords_and_hashtags_for_creator_search`, `effective_config.input_creator_niche_focus`, and `effective_config.input_min_follower_count`.
    *   Generate a list of 5-10 mocked TikTok creator profiles. Each profile should include: `id`, `username`, `follower_count`, `avg_engagement_rate` (mocked, e.g., random float between 1.0 and 10.0), `niche_tags` (array of strings based on keywords and niche), `sample_video_urls` (array of 2-3 mock TikTok video URLs), `bio` (short mocked bio), and `profile_url` (mocked URL).
    *   Filter this list based on `effective_config.input_min_follower_count`.
    *   If `effective_config.input_max_follower_count` is provided, filter by that too.
    *   If `effective_config.input_min_engagement_rate_percentage` is provided, filter by that.
    *   Limit the list to `effective_config.input_number_of_creators_to_shortlist` after filtering.
    *   **Mock Output Example (list of creators, one shown):**
        ```json
        [
          {
            "id": "creator123",
            "username": "EcoHomeAlice",
            "follower_count": 15000,
            "avg_engagement_rate": 3.5,
            "niche_tags": ["eco-friendly", "home decor", "diy"],
            "sample_video_urls": ["https://tiktok.com/@EcoHomeAlice/video/123", "https://tiktok.com/@EcoHomeAlice/video/456"],
            "bio": "Lover of all things sustainable and beautiful for your home. ✨",
            "profile_url": "https://tiktok.com/@EcoHomeAlice"
          }
          // ... more creators
        ]
        ```
    *   Passes the list of creators to the next node.

#### 2.2.2. Node: Determine if LLM Brand Fit Assessment is Needed
*   **Type:** IF Node (or Switch Node)
*   **Name:** "Assess Brand Fit Needed?"
*   **Condition:** Checks `{{ $json.webhook.body.effective_config.input_assess_brand_fit_using_llm }}`.
    *   If `true`, proceed to "Simulate LLM - Assess Brand Fit" node.
    *   If `false`, proceed directly to "Prepare Output Data" node (or the Callback node if no further processing is needed).

#### 2.2.3. Node: Simulate LLM - Assess Brand Fit
*   **Type:** Function Node
*   **Name:** "Simulate LLM - Assess Brand Fit"
*   **Execution:** Only runs if the "Assess Brand Fit Needed?" node routes to it.
*   **Logic:**
    *   Takes the list of mocked creators from "Simulate TikTok Creator Search" node as input.
    *   For each creator, use `effective_config.input_brand_product_service_description` and `effective_config.input_ideal_creator_persona_description` to generate a mock qualitative assessment.
    *   **Mock Output:** Modifies the input list of creators by adding an `brand_fit_assessment` object to each creator.
        *   Example for one creator's assessment:
            ```json
            {
              // ... existing creator fields ...
              "brand_fit_assessment": {
                "score": 0.85, // Mocked score 0.0 to 1.0
                "reasoning": "Aligns well with eco-conscious values specified in `input_ideal_creator_persona_description`. Content style is aesthetic and informative. Audience likely matches target demographics.",
                "potential_collaboration_ideas": ["Review of new `input_brand_product_service_description` line", "DIY home decor using our products"]
              }
            }
            ```
    *   Passes the augmented list of creators.

#### 2.2.4. Node: Prepare Output Data
*   **Type:** Function Node
*   **Name:** "Prepare Output Data"
*   **Logic:**
    *   This node receives data either from "Simulate LLM - Assess Brand Fit" (if it ran) or directly from "Simulate TikTok Creator Search".
    *   Its purpose is to ensure the data is consistently structured for the callback, regardless of whether the LLM assessment was performed.
    *   If the LLM assessment was skipped, it simply passes through the data from "Simulate TikTok Creator Search".
    *   If the LLM assessment ran, it passes through that augmented data.
    *   **Output:** The final list of creators (with or without `brand_fit_assessment`).

### 2.3. Output/Callback (HTTP Request Node)

*   **Name:** "Callback to Agent Service"
*   **URL:** `{{ $json.env.AGENT_SERVICE_BASE_URL }}/api/v1/agent-runs/{{ $json.webhook.body.run_id }}/completed`
*   **Method:** POST
*   **Body Type:** JSON
*   **Send JSON Body:**
    ```json
    {
      "status": "succeeded",
      "output_preview": "Found {{ $node[\"Prepare Output Data\"].json.length }} potential TikTok creators matching criteria.",
      "full_output_reference": "{{ JSON.stringify($node[\"Prepare Output Data\"].json) }}",
      "error_message": null
    }
    ```
*   **Note:** "`full_output_reference` contains the list of mocked creators (with assessments if performed). `output_preview` gives a count. Using a 'Prepare Output Data' node makes the input to `JSON.stringify` consistent."
*   **Error Handling (Simplified for Mock):** Similar to TikTok Stylist, error branches would lead to a callback with `status: "failed"`.

---

These specifications should guide the creation of the n8n mock workflows for the E2E demo.
```
