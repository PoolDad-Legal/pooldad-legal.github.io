# IONFLUX Project: Core Agent Blueprints

This document provides detailed blueprints for the initial set of core agents in the IONFLUX platform. These blueprints are derived from the project proposal, `conceptual_definition.md`, `ui_ux_concepts.md`, and `saas_api_integration_specs.md`.

---

## 1. Shopify Sales Sentinel

*   **1.1. Agent Name:** `Shopify Sales Sentinel`
*   **1.2. Purpose & Value Proposition:**
    *   Monitors a connected Shopify store for significant sales events in near real-time.
    *   Provides timely notifications to users about new orders, high-value orders, or specific product sales, enabling quick reactions, inventory checks, or marketing adjustments.
*   **1.3. Core Functionality:**
    *   Listens to Shopify order webhooks (`orders/create`, `orders/paid`).
    *   Filters incoming orders based on user-defined criteria (e.g., minimum order value, specific products, customer tags).
    *   Generates notifications for matching sales events.
    *   Can optionally post summaries to designated Chat Dock channels or update a Canvas block.
*   **1.4. Data Inputs:**
    *   **Shopify Webhooks:** `orders/create`, `orders/paid` events from `Shopify Integration Service`. Data includes order details (ID, total price, line items, customer info - handle PII carefully).
    *   **AgentConfiguration.yaml_config:** User-defined thresholds and filters.
    *   **Brand Data:** `Brand.id` to associate with the correct Shopify connection, `Brand.name` for notifications.
*   **1.5. Key Processing Logic/Steps:**
    1.  Receives webhook event from `Shopify Integration Service` (forwarded by `Agent Service`).
    2.  Parses the order data from the webhook payload.
    3.  Retrieves its `AgentConfiguration` to get notification rules (e.g., minimum value, product SKUs/IDs to watch, keywords in product titles).
    4.  Checks if the order matches any configured rules:
        *   Is `order.total_price` >= `config.min_order_value`?
        *   Do `order.line_items` contain any `product_id` or `sku` from `config.watch_products`?
        *   Does customer information match `config.watch_customer_tags`? (Requires careful PII handling and clear user consent).
    5.  If a rule is matched, format a notification message.
    6.  Send notification via `Notification Service` (e.g., in-app, email).
    7.  Optionally, send a message to a configured `ChatDockChannel.id` via `Chat Service`.
    8.  Optionally, update a dedicated `CanvasBlock` with a log of recent sentinel events (e.g., using `CanvasBlock.content` update).
*   **1.6. Data Outputs & Presentation:**
    *   **Notifications:** "New high-value order! [Order #] for [Amount] from [Customer Name (if consented)] just came in for [Brand Name]!"
    *   **Chat Messages:** Similar to notifications, posted in a specified channel. Could be more detailed, perhaps with line items.
        *   Content Type: `text` or `markdown`.
    *   **Canvas Block (Agent Snippet type):**
        *   Displays a list/feed of recent triggered alerts (e.g., "Order #1234 ($500) - 10:30 AM", "Product 'X' Sold Out! - 11:15 AM").
        *   `last_run_output_preview` could show the latest alert.
*   **1.7. Configurable Parameters (`AgentConfiguration.yaml_config`):**
    ```yaml
    brand_id: "uuid-of-brand-entity" # Pre-filled by system based on where agent is configured
    notify_on_new_order: true
    min_order_value_threshold: 200.00 # Only notify if order total is >= this value
    currency_code: "USD" # Assumed from Shopify store settings, but can be for display
    watch_products: # Notify if any of these products are in the order
      - sku: "TSHIRT-RED-L"
      - product_id: "gid://shopify/Product/123456789"
      - title_contains: "Limited Edition"
    # watch_customer_tags: # Advanced feature, PII-sensitive
    #   - "VIP"
    #   - "FirstTimeBuyer"
    notification_channels:
      - type: "in_app" # Default
      - type: "email"
        email_address: "user_preference@example.com" # Or use User.email
      - type: "chat_dock"
        channel_id: "uuid-of-chat-channel"
    canvas_block_update:
      enabled: true
      page_id: "uuid-of-canvas-page" # Optional: if agent has a dedicated canvas block
      block_id: "uuid-of-canvas-block" # Optional
    ```
*   **1.8. Dependencies (IONFLUX Services):**
    *   `Agent Service` (for execution and configuration management)
    *   `Shopify Integration Service` (to receive webhooks, potentially fetch more product details if needed)
    *   `Notification Service` (to send alerts)
    *   `Chat Service` (to post messages)
    *   `Canvas Service` (to update Canvas blocks)
    *   `Brand Service` (to get Brand context and Shopify connection details)

---

## 2. TikTok Stylist

*   **2.1. Agent Name:** `TikTok Stylist`
*   **2.2. Purpose & Value Proposition:**
    *   Helps users (Brands/Creators) identify trending sounds, hashtags, and video styles on TikTok relevant to their niche or campaign goals.
    *   Provides creative inspiration and helps improve content relevance and reach.
*   **2.3. Core Functionality:**
    *   Queries TikTok APIs (via `TikTok Integration Service`) for trending content based on keywords, topics, or categories.
    *   Analyzes results to identify popular sounds, hashtags, video formats, and visual styles.
    *   Uses LLM (via `LLM Orchestration Service`) to summarize findings, generate content ideas, or suggest how to adapt trends for the user's brand/niche.
*   **2.4. Data Inputs:**
    *   **User Configuration (`AgentConfiguration.yaml_config`):**
        *   Keywords, topics of interest (e.g., "sustainable fashion," "AI tools").
        *   Target audience description.
        *   Brand/Creator niche.
        *   Number of trends to identify.
    *   **TikTok API Data (via `TikTok Integration Service`):**
        *   Video search results (video URLs, titles, creator handles, sound names/IDs, hashtags, view counts, engagement metrics).
        *   Hashtag search results.
    *   **LLM (via `LLM Orchestration Service`):** For summarization, idea generation.
    *   **Brand/Creator Data:** `Brand.industry`, `Creator.niche` for context.
*   **2.5. Key Processing Logic/Steps:**
    1.  Agent is triggered (manually via Canvas block "Run" button, chat command, or on a schedule).
    2.  Reads its configuration for keywords, niche, etc.
    3.  Makes requests to `TikTok Integration Service` to:
        *   Search videos by keywords/topics.
        *   Search hashtags by keywords.
    4.  Collects and aggregates API responses (e.g., top N videos, top M hashtags).
    5.  Extracts key elements: sound names, hashtag names, video descriptions, common themes in high-performing videos.
    6.  Constructs a prompt for `LLM Orchestration Service`, including:
        *   The collected TikTok data (summarized if extensive).
        *   User's niche/brand information.
        *   The request (e.g., "Identify 5 trending sounds and suggest how [Brand Name] can use them for [Campaign Goal]").
    7.  Sends prompt to `LLM Orchestration Service` and receives generated text.
    8.  Formats the LLM output and raw trend data for presentation.
*   **1.6. Data Outputs & Presentation:**
    *   **Canvas Block (Agent Snippet):**
        *   Displays a list of identified trends (e.g., "Trending Sound: [Sound Name] - [Description/How to use]").
        *   Shows LLM-generated content ideas or summaries.
        *   May include links to example TikTok videos.
        *   `last_run_output_preview` shows a summary of trends.
    *   **Chat Message (if invoked via chat):**
        *   A formatted message summarizing the trends and ideas.
        *   Content Type: `markdown`.
    *   Could also generate a list of `Prompt` suggestions for a `PromptLibrary`.
*   **1.7. Configurable Parameters (`AgentConfiguration.yaml_config`):**
    ```yaml
    # For a Brand account if it has TikTok connected, or a Creator account
    # brand_id: "uuid-of-brand-entity" 
    # creator_id: "uuid-of-creator-entity"
    search_keywords: ["AI tools", "productivity hacks", "future of work"]
    # Optional: provide specific hashtags to analyze further, or let the agent discover them
    # seed_hashtags: ["#AI", "#TechInnovation"]
    industry_niche: "Artificial Intelligence Software" # From Brand/Creator profile or overridden here
    content_goal: "Increase brand awareness among tech enthusiasts" # User defined goal for this run
    num_trends_to_find: 5
    num_ideas_per_trend: 3
    output_format: "summary_and_ideas" # "raw_links", "summary_only"
    llm_prompt_template: | # Optional: advanced users can customize the LLM prompt
      "Based on the following TikTok data: {tiktok_data}, and for a brand in the '{industry_niche}' niche 
      aiming to '{content_goal}', please identify {num_trends_to_find} key trends 
      (sounds, hashtags, video styles) and generate {num_ideas_per_trend} distinct content ideas for each. 
      Present as a markdown list."
    ```
*   **1.8. Dependencies (IONFLUX Services):**
    *   `Agent Service`
    *   `TikTok Integration Service`
    *   `LLM Orchestration Service`
    *   `Brand Service` / `Creator Service` (for contextual data)
    *   `Canvas Service` / `Chat Service` (for output)

---

## 3. Revenue Tracker Lite (Shopify Focus for Beta)

*   **2.1. Agent Name:** `Revenue Tracker Lite`
*   **2.2. Purpose & Value Proposition:**
    *   Provides a simplified dashboard/summary of key revenue metrics from a connected Shopify store.
    *   Helps users quickly understand their store's performance without needing to delve into complex Shopify reports.
*   **2.3. Core Functionality:**
    *   Fetches order and product data from Shopify via `Shopify Integration Service`.
    *   Calculates key metrics: total sales, average order value (AOV), sales by product (top N), sales over a defined period.
    *   Presents these metrics in a structured format, typically within a Canvas block.
*   **2.4. Data Inputs:**
    *   **Shopify API Data (via `Shopify Integration Service`):**
        *   Orders: `id`, `created_at`, `total_price`, `line_items` (product_id, quantity, price).
        *   Products: `id`, `title` (to map product_id to names).
    *   **AgentConfiguration.yaml_config:**
        *   Time period for report (e.g., "last_7_days", "last_30_days", "month_to_date").
        *   Number of top products to display.
        *   Comparison period (optional, for future growth % display).
    *   **Brand Data:** `Brand.id` for Shopify connection.
*   **2.5. Key Processing Logic/Steps:**
    1.  Agent triggered (manually "Run" on Canvas block, scheduled, or page load if block is present).
    2.  Reads its configuration for the reporting period and other parameters.
    3.  Requests order data for the specified period from `Shopify Integration Service`.
        *   May need to handle pagination if many orders.
    4.  Requests product data (or uses cached product data) to map product IDs to names.
    5.  Calculates metrics:
        *   Total Sales: Sum of `total_price` for all orders in period.
        *   AOV: Total Sales / Number of Orders.
        *   Sales by Product: Aggregate `line_items.price * line_items.quantity` per `product_id`.
    6.  Formats the calculated metrics for output.
*   **1.6. Data Outputs & Presentation:**
    *   **Canvas Block (Agent Snippet or a dedicated "Metrics Block" type):**
        *   Displays key metrics in a clear, visual way (e.g., KPI cards, simple charts if block supports it).
        *   Example:
            *   "Total Sales (Last 30 Days): $X,XXX.XX"
            *   "Average Order Value: $YY.YY"
            *   "Top Selling Products:"
                *   "1. [Product Name A]: $Z,ZZZ.ZZ (AA units)"
                *   "2. [Product Name B]: $W,WWW.WW (BB units)"
        *   `last_run_output_preview` could show total sales.
        *   Should indicate "Last Updated: [Timestamp]".
*   **1.7. Configurable Parameters (`AgentConfiguration.yaml_config`):**
    ```yaml
    brand_id: "uuid-of-brand-entity"
    reporting_period: "last_30_days" # "last_7_days", "month_to_date", "custom_range"
    # custom_start_date: "YYYY-MM-DD" # If reporting_period is "custom_range"
    # custom_end_date: "YYYY-MM-DD" # If reporting_period is "custom_range"
    num_top_products: 5
    # compare_to_previous_period: false # Future: for showing % change
    display_options:
      show_total_sales: true
      show_aov: true
      show_top_products: true
      # show_sales_chart: false # Future: if block type supports charts
    ```
*   **1.8. Dependencies (IONFLUX Services):**
    *   `Agent Service`
    *   `Shopify Integration Service`
    *   `Brand Service`
    *   `Canvas Service` (for output)

---

## 4. UGC Matchmaker (TikTok Focus)

*   **2.1. Agent Name:** `UGC Matchmaker (TikTok Focus)`
*   **2.2. Purpose & Value Proposition:**
    *   Helps brands discover potential TikTok creators for User-Generated Content (UGC) campaigns based on niche, keywords, or audience characteristics (where API permits).
    *   Streamlines the initial phase of influencer/creator discovery.
*   **2.3. Core Functionality:**
    *   Searches TikTok for creators based on user-defined criteria (keywords in bio/videos, hashtags used).
    *   Collects publicly available profile information for potential matches.
    *   Optionally, uses LLM to summarize creator profiles or assess brand fit.
    *   Presents a list of potential creators.
*   **2.4. Data Inputs:**
    *   **User Configuration (`AgentConfiguration.yaml_config`):**
        *   Search keywords (for video content, hashtags, potentially user bios if API allows).
        *   Creator niche criteria.
        *   Audience demographic hints (though direct search by this is unlikely via API).
        *   Brand information (for LLM-based fit assessment).
    *   **TikTok API Data (via `TikTok Integration Service`):**
        *   User profile data (`open_id`, `username`, `avatar_url`, follower/following counts, likes, video counts) for identified creators.
        *   Video data (captions, hashtags from videos matching keyword searches).
    *   **LLM (via `LLM Orchestration Service`):** For profile summarization or brand fit analysis.
    *   **Brand Data:** `Brand.industry`, `Brand.target_audience` for context.
*   **2.5. Key Processing Logic/Steps:**
    1.  Agent triggered (manual "Run", chat command).
    2.  Reads configuration for search criteria.
    3.  Makes requests to `TikTok Integration Service`:
        *   Search videos/hashtags by keywords to identify creators active in that space.
        *   For each unique creator identified, fetch their public profile info (if not already cached/retrieved).
    4.  Filters initial list of creators based on basic metrics (e.g., minimum follower count, if configured).
    5.  (Optional) For each potential creator, construct a prompt for `LLM Orchestration Service`:
        *   Include creator's public profile data, sample video descriptions.
        *   Include brand's information and campaign goal.
        *   Ask LLM to assess brand fit or summarize creator's content style.
    6.  Compile a list of matched creators with their profile info and LLM analysis (if any).
*   **1.6. Data Outputs & Presentation:**
    *   **Canvas Block (Agent Snippet or Table View):**
        *   Displays a list/table of potential creators.
        *   Columns: Creator Handle (link to TikTok profile), Avatar, Followers, Avg. Likes (if available), Brand Fit Score/Summary (from LLM), Key Videos (links).
        *   `last_run_output_preview` could show number of creators found.
    *   **Chat Message (if invoked via chat):**
        *   A summary message with top N creators found, possibly with links.
        *   Content Type: `markdown`.
*   **1.7. Configurable Parameters (`AgentConfiguration.yaml_config`):**
    ```yaml
    brand_id: "uuid-of-brand-entity"
    search_keywords: ["skincare routine", "organic beauty", "#selfcare"]
    creator_niche: "Beauty and Wellness"
    min_follower_count: 1000
    # max_follower_count: 100000 # Optional
    num_creators_to_find: 10
    # Optional: if an LLM should assess brand fit
    assess_brand_fit: true
    # llm_brand_fit_prompt: | # Optional: advanced users can customize
    #   "Given this creator's profile: {creator_data} and our brand focusing on {brand_details}, 
    #   rate their potential fit for a UGC campaign on a scale of 1-10 and provide a brief justification."
    # country_filter: ["US", "CA"] # API dependent, may not be feasible
    ```
*   **1.8. Dependencies (IONFLUX Services):**
    *   `Agent Service`
    *   `TikTok Integration Service`
    *   `LLM Orchestration Service` (optional)
    *   `Brand Service`
    *   `Canvas Service` / `Chat Service` (for output)

---

## 5. Slack Brief Butler (General Utility)

*   **2.1. Agent Name:** `Slack Brief Butler` (Name can be generalized if not Slack-specific in Beta)
*   **2.2. Purpose & Value Proposition:**
    *   Monitors a specified Chat Dock channel for messages that appear to be project briefs, campaign requests, or task assignments.
    *   Uses LLM to summarize these messages into a structured brief (e.g., objectives, key tasks, deadline).
    *   Helps teams quickly extract actionable information from chat conversations.
*   **2.3. Core Functionality:**
    *   Can be triggered by a user "tagging" it in a chat message or by monitoring a channel for keywords.
    *   Retrieves recent message history from the specified channel or thread.
    *   Uses LLM to identify and parse relevant information into a structured brief.
    *   Posts the structured brief back to the chat, or to a Canvas block, or creates a task (future).
*   **2.4. Data Inputs:**
    *   **Chat Messages (from `Chat Service`):**
        *   Content of messages in a specific channel or thread.
        *   User who sent the message, timestamp.
    *   **AgentConfiguration.yaml_config:**
        *   Channel(s) to monitor (if continuous monitoring).
        *   Keywords to trigger brief generation (e.g., "new brief," "campaign request," "@BriefButler").
        *   LLM prompt template for summarization.
        *   Output format/destination.
    *   **LLM (via `LLM Orchestration Service`):** For parsing and structuring the brief.
*   **2.5. Key Processing Logic/Steps:**
    1.  **Triggering:**
        *   **Manual:** User invokes with `/command @SlackBriefButler summarize_thread` or similar in Chat Dock.
        *   **Keyword Monitoring:** Agent (running in background if configured for a channel) sees a message with keywords.
        *   **Mention:** Agent is directly mentioned (`@SlackBriefButler`) in a channel it's configured for.
    2.  Retrieves relevant message(s) from `Chat Service`:
        *   If thread summarization, gets all messages in that thread.
        *   If channel monitoring, might get the last N messages or messages since last check.
    3.  Constructs a prompt for `LLM Orchestration Service`:
        *   Includes the raw chat message(s).
        *   Includes the desired output structure (e.g., "Extract: Project Name, Key Objectives, Main Tasks, Stakeholders, Deadline. If any are missing, state 'Not specified'.").
    4.  Sends prompt to `LLM Orchestration Service` and receives the structured brief.
    5.  Formats the brief for output.
*   **1.6. Data Outputs & Presentation:**
    *   **Chat Message (reply in thread or channel):**
        *   A formatted markdown message with the structured brief.
        *   Example:
            ```markdown
            **Project Brief Summary:**
            *   **Project Name:** [LLM-extracted name or "Untitled Brief"]
            *   **Objectives:** [LLM-extracted objectives]
            *   **Key Tasks:** [LLM-extracted tasks]
            *   **Stakeholders:** [LLM-extracted stakeholders or sending user]
            *   **Deadline:** [LLM-extracted deadline or "Not specified"]
            ```
        *   Content Type: `markdown` or `json_proposal` (if interactive elements are desired).
    *   **Canvas Block (Agent Snippet or Text Block):**
        *   The structured brief can be sent to a new or existing Canvas block.
    *   **Notification:** Could notify the user who triggered it or stakeholders mentioned.
*   **1.7. Configurable Parameters (`AgentConfiguration.yaml_config`):**
    ```yaml
    # If agent actively monitors channels:
    # monitored_channels:
    #   - channel_id: "uuid-of-general-channel"
    #     trigger_keywords: ["new project", "campaign brief", "task assignment"]
    
    # Default behavior when mentioned or invoked by command
    brief_structure_prompt: | # LLM prompt to define the output structure
      "Please analyze the following conversation and extract a concise project brief. 
      Identify the following if available: 
      1. Project/Campaign Name 
      2. Key Objectives (1-3 bullet points)
      3. Main Deliverables/Tasks (1-5 bullet points)
      4. Key Stakeholders/Owners
      5. Deadline or Timeline.
      If a field is not mentioned, explicitly state 'Not specified'.
      Format the output as clean markdown."
      
    output_destinations:
      - type: "reply_in_chat" # Default
      # - type: "new_canvas_block"
      #   target_page_id: "uuid-of-page-for-briefs" # Optional, otherwise current or user's choice
      # - type: "notification"
      #   notify_user_ids: ["uuid-of-user-who-triggered", "uuid-of-project-manager"]
    ```
*   **1.8. Dependencies (IONFLUX Services):**
    *   `Agent Service`
    *   `Chat Service` (for input and output)
    *   `LLM Orchestration Service`
    *   `Canvas Service` (optional output)
    *   `Notification Service` (optional output)
    *   `User Service` (to identify users if needed for stakeholder fields)

---
```
