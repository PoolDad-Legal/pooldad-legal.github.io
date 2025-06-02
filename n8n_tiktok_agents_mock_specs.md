# IONFLUX Project: n8n Workflow Specifications for Mocked TikTok Agents (E2E Demo)

This document defines the specifications for n8n workflows that will mock the backend logic for the `TikTok Stylist` and `UGC Matchmaker (TikTok Focus)` agents during the E2E Demo. These workflows are triggered by the Agent Service and simulate interactions with TikTok APIs and LLM services.

**Reference Documents:**
*   `core_agent_blueprints.md`
*   `agent_service_minimal_spec.md`
*   `technical_stack_and_demo_strategy.md`

## A. `TikTok Stylist` (n8n Workflow)

**1. Agent Name:** `TikTok Stylist`

**2. Trigger:**

*   **Type:** n8n Webhook Node.
*   **Caller:** Agent Service (`POST /agent-configurations/:agentConfigId/run`).
*   **Expected Input from Agent Service (JSON Body):**
    ```json
    {
      "run_id": "uuid", // Unique ID for this execution run
      "agent_configuration_id": "uuid",
      "workspace_id": "uuid",
      "user_id": "uuid",
      "yaml_config": { // Parsed YAML content from AgentConfiguration.yaml_config
        "search_keywords": ["keyword1", "keyword2"],
        "industry_niche": "string",
        "content_goal": "string",
        "num_trends_to_find": 3, // Example value
        "num_ideas_per_trend": 2, // Example value
        "llm_prompt_template": "string (optional)" // Or use a default
      },
      "runtime_params": {} // Optional, could override yaml_config values
    }
    ```

**3. Core Workflow Steps (n8n Nodes - Conceptual):**

1.  **Webhook Node ("Start TikTok Stylist Run"):**
    *   Receives the trigger data from Agent Service.
    *   Responds immediately with HTTP 200 OK to Agent Service.

2.  **Set Node ("Initialize Parameters"):**
    *   **Purpose:** Extract and set key parameters from the input for easier access in subsequent nodes.
    *   **Logic:**
        *   `search_keywords = {{ $json.body.yaml_config.search_keywords }}`
        *   `industry_niche = {{ $json.body.yaml_config.industry_niche }}`
        *   `content_goal = {{ $json.body.yaml_config.content_goal }}`
        *   `num_trends_to_find = {{ $json.body.yaml_config.num_trends_to_find || 3 }}`
        *   `num_ideas_per_trend = {{ $json.body.yaml_config.num_ideas_per_trend || 2 }}`

3.  **Function Node ("Simulate TikTok API - Trend Search"):**
    *   **Purpose:** Generates a list of mocked trending TikTok sounds and hashtags based on `search_keywords`.
    *   **Logic:**
        *   Iterate (or pick one) `search_keywords`.
        *   For each keyword, create 1-2 mock trends.
        *   Example Output (JavaScript in Function Node):
            ```javascript
            const keywords = $json.search_keywords || ["general"];
            const num_trends = $json.num_trends_to_find;
            const trends = [];
            for (let i = 0; i < num_trends; i++) {
              const type = Math.random() > 0.5 ? "sound" : "hashtag";
              if (type === "sound") {
                trends.push({
                  type: "sound",
                  name: `Catchy Sound ${i + 1} for ${keywords[0]}`,
                  source_url: `http://tiktok.example.com/sound${i+1}`,
                  description: `A popular upbeat track often used in ${keywords[0]} videos.`
                });
              } else {
                trends.push({
                  type: "hashtag",
                  name: `#${keywords[0]}Trend${i+1}`,
                  views: `${(Math.random() * 5 + 1).toFixed(1)}M`,
                  description: `A trending hashtag related to ${keywords[0]}.`
                });
              }
            }
            return { "mock_tiktok_trends": trends };
            ```
    *   Passes `mock_tiktok_trends` and original trigger data.

4.  **Function Node ("Simulate LLM - Content Idea Generation"):**
    *   **Purpose:** Takes mocked trends and generates sample content ideas.
    *   **Input:** `mock_tiktok_trends` from previous node, and `industry_niche`, `content_goal`, `num_ideas_per_trend` from "Initialize Parameters" node (or directly from webhook body).
    *   **Logic:**
        *   Iterate through `mock_tiktok_trends`.
        *   For each trend, generate `num_ideas_per_trend` generic ideas, incorporating the trend name and `industry_niche`.
        *   Example Output (JavaScript in Function Node):
            ```javascript
            const trends = $json.mock_tiktok_trends;
            const niche = $json.industry_niche;
            const goal = $json.content_goal;
            const ideas_per_trend = $json.num_ideas_per_trend;
            const analysis = trends.map(trend => {
              const ideas = [];
              for (let i = 0; i < ideas_per_trend; i++) {
                ideas.push(`Idea ${i+1}: Use '${trend.name}' in a video about ${niche} to achieve ${goal}.`);
              }
              return {
                trend_name: trend.name,
                trend_type: trend.type,
                trend_details: trend.description || trend.views,
                ideas: ideas
              };
            });
            return { 
              trends_analysis: analysis,
              summary: `Found ${trends.length} demo trends. Consider these for your ${niche} campaign aiming for ${goal}.`
            };
            ```

5.  **HTTP Request Node ("Callback to Agent Service"):**
    *   **Purpose:** Reports completion and results to Agent Service.
    *   **URL:** `{{ $json.body.env.AGENT_SERVICE_URL || "http://localhost:8000/api/v1" }}/runs/{{ $json.body.run_id }}/completed` (Assuming Agent Service URL might be in env or passed in trigger).
    *   **Method:** POST
    *   **Authentication:** Shared secret if configured on Agent Service callback.
    *   **Body (JSON):**
        ```json
        {
          "agent_configuration_id": "{{ $json.body.agent_configuration_id }}",
          "status": "success",
          "output_preview": "{{ $json.SimulateLLMContentIdeaGeneration.output.summary.substring(0, 250) }}", 
          "full_output_reference": "{{ JSON.stringify($json.SimulateLLMContentIdeaGeneration.output) }}"
        }
        ```
        *   *Note: `output_preview` is a concise summary. `full_output_reference` (for demo) contains the full JSON string of the generated analysis. In a real system, this might be a URL to stored JSON.*

**4. Output/Callback:**

*   The workflow calls back to `Agent Service`'s `/runs/:runId/completed` endpoint.
*   The `output_preview` will contain the summary from the LLM simulation.
*   The `full_output_reference` will contain the stringified JSON of the detailed trend analysis and ideas for the demo.

---

## B. `UGC Matchmaker (TikTok Focus)` (n8n Workflow)

**1. Agent Name:** `UGC Matchmaker (TikTok Focus)`

**2. Trigger:**

*   **Type:** n8n Webhook Node.
*   **Caller:** Agent Service (`POST /agent-configurations/:agentConfigId/run`).
*   **Expected Input from Agent Service (JSON Body):**
    ```json
    {
      "run_id": "uuid",
      "agent_configuration_id": "uuid",
      "workspace_id": "uuid",
      "user_id": "uuid",
      "yaml_config": { // Parsed YAML content
        "search_keywords": ["keywordA", "keywordB"],
        "creator_niche": "string",
        "min_follower_count": 1000,
        "num_creators_to_find": 5,
        "assess_brand_fit": true // boolean
      },
      "runtime_params": {}
    }
    ```

**3. Core Workflow Steps (n8n Nodes - Conceptual):**

1.  **Webhook Node ("Start UGC Matchmaker Run"):**
    *   Receives trigger data.
    *   Responds immediately with HTTP 200 OK.

2.  **Set Node ("Initialize Parameters"):**
    *   Extracts `search_keywords`, `creator_niche`, `min_follower_count`, `num_creators_to_find`, `assess_brand_fit` from `input.json.body.yaml_config`.

3.  **Function Node ("Simulate TikTok Creator Search"):**
    *   **Purpose:** Generates a list of mocked TikTok creator profiles.
    *   **Logic:**
        *   Use `search_keywords` and `creator_niche` to influence generated names/bios slightly.
        *   Generate `num_creators_to_find` + a few extra (to allow filtering).
        *   For each creator, generate random follower count.
        *   Example Output (JavaScript in Function Node):
            ```javascript
            const niche = $json.creator_niche || "general";
            const num_to_find = $json.num_creators_to_find || 3;
            const creators = [];
            for (let i = 0; i < num_to_find + 2; i++) {
              creators.push({
                username: `@${niche.replace(/\s+/g, '')}Creator${i+1}`,
                followers: Math.floor(Math.random() * 50000) + 500,
                niche: niche,
                bio: `Lover of all things ${niche}. UGC creator. Collabs open!`,
                sample_video_url: `http://tiktok.example.com/video${i+1}`
              });
            }
            return { "mock_creators_raw": creators };
            ```

4.  **Filter Node or Function Node ("Filter by Followers"):**
    *   **Purpose:** Filters creators based on `min_follower_count`.
    *   **Logic:** Keep only creators where `followers >= min_follower_count`.
    *   Limit to `num_creators_to_find`.

5.  **IF Node ("Assess Brand Fit?"):**
    *   **Condition:** `{{ $json.assess_brand_fit === true }}`.
    *   **True Branch:** Go to "Simulate LLM for Brand Fit".
    *   **False Branch:** Go directly to "Prepare Final Output".

6.  **Function Node ("Simulate LLM for Brand Fit") - (True Branch Only):**
    *   **Purpose:** For each filtered creator, generate a mock brand fit assessment.
    *   **Input:** List of filtered creators.
    *   **Logic:**
        *   Iterate through creators.
        *   Add a `brand_fit_assessment` field, e.g., "Seems like a good fit for [niche] campaigns due to their engaging style. (Mocked LLM assessment)". Randomly assign a score if desired.
        *   Example Output (JavaScript for one creator):
            ```javascript
            // Assuming 'item' is one creator from the input list
            item.json.brand_fit_assessment = `Potential: ${Math.floor(Math.random() * 3) + 7}/10. Style seems ${ (Math.random() > 0.5 ? "upbeat and trendy" : "authentic and relatable") }. (Mocked LLM)`;
            return item;
            ```
    *   This node would likely run for each item if using SplitInBatches or a Loop.

7.  **Function Node ("Prepare Final Output"):**
    *   **Purpose:** Consolidate the list of creators (with or without brand fit assessment) into the final structure.
    *   **Input:** Output from "Filter by Followers" or "Simulate LLM for Brand Fit".
    *   **Output:** `{"matched_creators": [list_of_creator_objects], "summary": "Found X potential creators."}`

8.  **HTTP Request Node ("Callback to Agent Service"):**
    *   **Purpose:** Reports completion and results to Agent Service.
    *   **URL:** `{{ $json.body.env.AGENT_SERVICE_URL || "http://localhost:8000/api/v1" }}/runs/{{ $json.body.run_id }}/completed`.
    *   **Method:** POST
    *   **Authentication:** Shared secret if configured.
    *   **Body (JSON):**
        ```json
        {
          "agent_configuration_id": "{{ $json.body.agent_configuration_id }}",
          "status": "success",
          "output_preview": "{{ $json.PrepareFinalOutput.output.summary.substring(0, 250) }}",
          "full_output_reference": "{{ JSON.stringify($json.PrepareFinalOutput.output) }}"
        }
        ```

**4. Output/Callback:**

*   The workflow calls back to `Agent Service`'s `/runs/:runId/completed` endpoint.
*   The `output_preview` contains a summary (e.g., "Found 3 potential creators.").
*   The `full_output_reference` contains the stringified JSON of the `matched_creators` list.

---

These n8n workflow specifications for the TikTok agents focus on simulating the core data retrieval and AI processing steps, providing realistic-looking mock data that can be used to populate the frontend for the E2E demo.
```
