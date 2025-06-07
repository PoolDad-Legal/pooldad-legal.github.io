# Core IONFLUX Agents: Your Specialized Digital Workforce

IONFLUX empowers users through a suite of sophisticated, AI-driven agents, each designed for specific tasks and built on advanced principles. These agents can be orchestrated within IONFLUX workflows to create powerful automations. They are designed to be interoperable, potentially leveraging Agent-to-Agent (A2A) communication patterns for complex collaborations by exposing their capabilities and skills for discovery and invocation.

Below are the 10 core agents available within IONFLUX:

## 1. Email Wizard (agent_001)

*   **Epíteto:** O Xamã que Conjura Receita no Silêncio do E-mail
*   **TAGLINE:** INBOX ≠ ARQUIVO MORTO; INBOX = ARMA VIVA
*   **Essência:**
    *   **Arquétipo:** Magician
    *   **Frase-DNA:** “Faz o invisível falar e vender”
*   **Primary Goal:** To transform email communication from a passive archive into a dynamic, revenue-generating weapon through hyper-personalization, adaptive sequencing, and intelligent automation.
*   **Core Capabilities:**
    *   **Hyper-Segment:** Builds micro-cohorts of users in real-time using embeddings for ultra-targeted messaging.
    *   **Dopamine Drip:** Implements adaptive email sequences that adjust based on user interactions (clicks, opens) to optimize offers.
    *   **Auto-Warm-Up:** Generates engagement-friendly traffic to protect and enhance sender reputation.
    *   **Predictive Clearance:** Intelligently prunes email lists by identifying and removing low-probability recipients before sending.
*   **A2A Alignment (Conceptual):**
    *   Its `AgentDefinition` serves as the foundation for its A2A Agent Card, detailing its capabilities in email marketing automation and personalization.
    *   **Exposed Skills (Examples via JSON-RPC `message/send`):**
        *   `skillId: "draft_personalized_email"`
            *   `params: { "recipient_profile_cid": "...", "campaign_goal": "product_launch", "base_template_cid": "..." }`
        *   `skillId: "send_email_campaign"`
            *   `params: { "email_draft_cid": "...", "target_segment_cid": "...", "send_time_utc": "..." }`
        *   `skillId: "get_campaign_performance_report"`
            *   `params: { "campaign_id": "...", "metrics": ["opens", "clicks", "conversions"] }`
    *   **Consumed/Produced Events (IAP `PlatformEvent`):**
        *   Consumes: `ionflux.crm.contact_segment_updated` (to adjust targeting).
        *   Produces: `ionflux.emailwizard.campaign_sent`, `ionflux.emailwizard.email_bounced`.
    *   **Agent 000 Orchestration:** Agent 000 could command Email Wizard: "ION, draft a follow-up email sequence for leads from the 'Tech Expo' campaign, using template 'PostExpoV1', and schedule it to start tomorrow."

---

## 2. WhatsApp Pulse (agent_002)

*   **Epíteto:** O Cirurgião que Enfia Funil Dentro do Bolso do Cliente
*   **TAGLINE:** SE É VERDE E PISCA, É DINHEIRO LATENTE
*   **Essência:**
    *   **Arquétipo:** Messenger-Magician
    *   **Frase-DNA:** “Faz do sinal verde um gatilho pavloviano de compra”
*   **Primary Goal:** To automate empathetic and surgically precise communication on WhatsApp, leveraging its high open rates and rapid response times for customer engagement and conversion.
*   **Core Capabilities:**
    *   **Persona-Aware Reply:** Crafts responses in the user's dialect and style using embeddings and local slang.
    *   **Smart Drip:** Deploys progressive message sequences (reminders, soft offers, scarcity triggers, bonuses).
    *   **Opt-in Whisper:** Generates one-click opt-in links and securely saves consent proof for compliance.
    *   **Voice-Note AI:** Transforms text scripts into humanized TTS audio notes to boost engagement.
*   **A2A Alignment (Conceptual):**
    *   Its `AgentDefinition` forms the basis of its A2A Agent Card, highlighting proficiency in WhatsApp automation and conversational commerce.
    *   **Exposed Skills (Examples via JSON-RPC `message/send`):**
        *   `skillId: "send_whatsapp_template_message"`
            *   `params: { "recipient_whatsapp_id": "...", "template_name": "order_confirmation", "template_params": {"order_id": "123"} }`
        *   `skillId: "initiate_whatsapp_drip_campaign"`
            *   `params: { "target_audience_cid": "...", "campaign_playbook_cid": "..." }`
        *   `skillId: "get_whatsapp_message_status"`
            *   `params: { "message_id_provider": "..." }`
    *   **Consumed/Produced Events (IAP `PlatformEvent`):**
        *   Consumes: `ionverse.marketplace.order_placed` (to trigger order confirmation).
        *   Produces: `ionflux.whatsapppulse.message_delivered`, `ionflux.whatsapppulse.user_replied`.
    *   **Agent 000 Orchestration:** Agent 000 might instruct: "ION, send a WhatsApp shipping update for order #XYZ to the customer using the 'ShipmentOut' template."

---

## 3. TikTok Stylist (agent_003)

*   **Epíteto:** O Alfaiate que Corta Vídeos na Medida da Dopamina
*   **TAGLINE:** SE NÃO SEGURA O DEDO, NEM DEVERIA EXISTIR
*   **Essência:**
    *   **Arquétipo:** Artisan-Magician
    *   **Frase-DNA:** “Escreve hipnose audiovisual no compasso do coração digital”
*   **Primary Goal:** To transform raw video footage into highly engaging, algorithm-friendly TikTok content by analyzing styles, optimizing cuts, synchronizing sound, and predicting optimal posting times.
*   **Core Capabilities:**
    *   **StyleScan:** Analyzes past video content to extract a unique visual-verbal fingerprint.
    *   **ClipForge:** Edits footage by cutting, recalibrating rhythm, inserting dynamic captions, and applying strategic zooms.
    *   **SoundSynch:** Aligns video edits with sound beats and movements to maximize retention.
    *   **AutoPost Oracle:** Calculates regional audience peak times and schedules content pushes accordingly.
*   **A2A Alignment (Conceptual):**
    *   Its `AgentDefinition` serves as its A2A Agent Card, listing supported video analysis features and content optimization techniques for TikTok.
    *   **Exposed Skills (Examples via JSON-RPC `message/send`):**
        *   `skillId: "optimize_video_for_tiktok"`
            *   `params: { "source_video_cid": "...", "target_style_preference_cid": "...", "desired_duration_seconds": 60 }`
        *   `skillId: "generate_tiktok_caption_and_hashtags"`
            *   `params: { "video_content_summary": "...", "target_audience_keywords": ["...", "..."] }`
        *   `skillId: "schedule_tiktok_publication"`
            *   `params: { "optimized_video_cid": "...", "caption_text": "...", "publish_time_utc": "..." }`
    *   **Consumed/Produced Events (IAP `PlatformEvent`):**
        *   Consumes: `ionpod.content.new_video_ready_for_social` (from IONPOD).
        *   Produces: `ionflux.tiktokstylist.video_published_to_tiktok`, `ionflux.tiktokstylist.tiktok_trending_sound_detected`.
    *   **Agent 000 Orchestration:** Agent 000 could say: "ION, take the latest video from my IONPOD 'ShortClips' folder, optimize it for TikTok with a viral dance music style, and schedule it for peak US time tomorrow."

---

## 4. Shopify Sales Sentinel (agent_004_refactored)

*   **Epíteto:** O Guardião Preditivo do Fluxo de Caixa da Loja
*   **TAGLINE:** ANTECIPA A FALHA, PROTEGE O LUCRO, MAXIMIZA O GMV — EM TEMPO REAL
*   **Essência:**
    *   **Arquétipo:** Guardian-Engineer aprimorado por Strategist
    *   **Frase-DNA:** "Protege o fluxo vital e aprende com cada falha"
*   **Primary Goal:** To proactively minimize GMV loss and optimize Shopify store performance through predictive anomaly detection, AI-assisted root cause analysis, and adaptive corrective actions.
*   **Core Capabilities:**
    *   **Realtime Pulse (Aprimorado):** Predictive monitoring of Shopify events and performance metrics.
    *   **Anomaly Guardian (Preditivo e Adaptativo):** Employs ML/Statistical models to detect anomalies.
    *   **App-Impact Radar (Baseado em Embeddings):** Correlates store changes with performance variations.
    *   **LLM Root-Cause Analyzer:** Uses GPT-4o to analyze logs and metrics.
    *   **Adaptive Remediation Orchestrator:** Orchestrates corrective actions.
*   **A2A Alignment (Conceptual):**
    *   Its `AgentDefinition` is the basis for its A2A Agent Card, detailing supported Shopify metrics, anomaly detection capabilities, and remediation actions.
    *   **Exposed Skills (Examples via JSON-RPC `message/send`):**
        *   `skillId: "get_shopify_health_snapshot"`
            *   `params: { "store_id": "...", "metrics_set": ["cvr", "aov", "checkout_errors"] }`
        *   `skillId: "analyze_performance_dip"`
            *   `params: { "store_id": "...", "dip_details_cid": "...", "timeframe_hours": 24 }`
        *   `skillId: "trigger_remediation_protocol"`
            *   `params: { "store_id": "...", "anomaly_id": "...", "protocol_name": "pause_ads_and_alert_dev_team" }`
    *   **Consumed/Produced Events (IAP `PlatformEvent`):**
        *   Consumes: `ionverse.shopify.app_installed_or_updated`, `ionverse.shopify.theme_changed`.
        *   Produces: `ionflux.shopifysentinel.anomaly_detected`, `ionflux.shopifysentinel.remediation_action_taken`.
    *   **Agent 000 Orchestration:** Agent 000 could be alerted: "ION, Shopify Sales Sentinel detected a critical checkout error spike on 'MyStore'. Initiate 'CodeRedCheckout' protocol and notify the on-call dev."

---

## 5. UGC Matchmaker (agent_005_refactored)

*   **Epíteto:** O Oráculo Preditivo de ROI para Colaborações Criativas
*   **TAGLINE:** CONECTA DNA DE MARCA A CRIADORES QUE CONVERTEM DE VERDADE
*   **Essência:**
    *   **Arquétipo:** Oracle-Connector aprimorado por Analyst
    *   **Frase-DNA:** "Conecta almas criativas ao lucro com inteligência preditiva"
*   **Primary Goal:** To maximize the ROI of influencer marketing and UGC campaigns by using AI to identify, predict performance of, and facilitate collaboration with the most suitable creators.
*   **Core Capabilities:**
    *   **Brief2Vector (Aprimorado):** Transforms campaign briefs into dense embeddings.
    *   **PersonaProbe (Multimodal e Preditivo):** Analyzes creator portfolios using multimodal AI.
    *   **AffinityMatrix (Otimizado por ROI Preditivo):** Calculates affinity score and predicts ROI.
    *   **GhostPitch (Adaptativo, Multi-formato e Otimizado para Conversão):** Generates hyper-personalized proposals.
    *   **Performance Feedback Loop (Contínuo e Quantitativo):** Collects feedback to refine models.
*   **A2A Alignment (Conceptual):**
    *   Its `AgentDefinition` forms its A2A Agent Card, detailing its analytical capabilities for influencer/UGC marketing and predictive matching.
    *   **Exposed Skills (Examples via JSON-RPC `message/send`):**
        *   `skillId: "find_creators_for_campaign"`
            *   `params: { "campaign_brief_cid": "...", "target_audience_persona_cid": "...", "match_threshold": 0.75 }`
        *   `skillId: "predict_creator_campaign_fit"`
            *   `params: { "creator_profile_cid": "...", "campaign_brief_cid": "..." }`
        *   `skillId: "draft_collaboration_outreach"`
            *   `params: { "creator_profile_cid": "...", "campaign_brief_cid": "...", "offer_details_cid": "..." }`
    *   **Consumed/Produced Events (IAP `PlatformEvent`):**
        *   Consumes: `ionverse.marketing.new_campaign_brief_ready`.
        *   Produces: `ionflux.ugcmatchmaker.creator_match_found`, `ionflux.ugcmatchmaker.outreach_sent`.
    *   **Agent 000 Orchestration:** "ION, find three high-ROI micro-influencers on TikTok for my new sustainable fashion line campaign, using brief 'EcoChicV1'."

---

## 6. Outreach Automaton (agent_006_refactored)

*   **Epíteto:** O Estrategista Preditivo de Conexões B2B de Alto Valor
*   **TAGLINE:** TRANSFORMA DADOS FRIOS EM PIPELINE QUENTE COM PRECISÃO CIRÚRGICA
*   **Essência:**
    *   **Arquétipo:** Hunter-Strategist aprimorado por Data Scientist
    *   **Frase-DNA:** "Transforma ruído de dados em conversas que convertem"
*   **Primary Goal:** To generate highly qualified B2B leads and schedule meetings through intelligent, predictive multi-channel outreach automation, maximizing conversion from cold contact to real opportunity.
*   **Core Capabilities:**
    *   **DataMiner Scraper (Enriquecido 360°):** Collects and cross-references data from multiple B2B data sources.
    *   **Predictive Micro-Segmenter (Dinâmico e Baseado em ICP):** Creates dynamic lead micro-segments.
    *   **ContextForge (Hiper-Contextual e Relevante):** Generates specific icebreakers and messages using LLMs.
    *   **Multi-Cadence Orchestrator (Dinâmico, Adaptativo e Otimizado):** Manages multi-channel contact flows.
    *   **Auto-Booker (Integrado e Inteligente):** Facilitates meeting scheduling.
    *   **CRM Results Feedback Loop (Contínuo e Granular):** Pulls CRM data to refine strategies.
*   **A2A Alignment (Conceptual):**
    *   Its `AgentDefinition` acts as its A2A Agent Card, outlining its B2B lead generation and automated outreach capabilities.
    *   **Exposed Skills (Examples via JSON-RPC `message/send`):**
        *   `skillId: "find_b2b_leads"`
            *   `params: { "ideal_customer_profile_cid": "...", "target_industry": "SaaS", "company_size_range": [50, 200] }`
        *   `skillId: "launch_outreach_sequence"`
            *   `params: { "lead_segment_cid": "...", "messaging_cadence_cid": "...", "goal": "schedule_demo" }`
        *   `skillId: "get_lead_engagement_status"`
            *   `params: { "lead_id": "..." }`
    *   **Consumed/Produced Events (IAP `PlatformEvent`):**
        *   Consumes: `ionflux.crm.new_lead_manually_added_for_enrichment`.
        *   Produces: `ionflux.outreachautomaton.meeting_booked`, `ionflux.outreachautomaton.lead_responded_positively`.
    *   **Agent 000 Orchestration:** "ION, find 50 new B2B leads matching ICP 'FintechScaleup', enrich their data, and start the 'InitialContactV2' outreach sequence."

---

## 7. Communication Clarity Butler (agent_007_refactored, formerly Slack Brief Butler)

*   **Epíteto:** O Orquestrador da Clareza Coletiva em Canais de Comunicação
*   **TAGLINE:** TRANSFORMA CAOS DE MENSAGENS EM DECISÕES ACIONÁVEIS — INSTANTANEAMENTE
*   **Essência:**
    *   **Arquétipo:** Scribe/Librarian/Facilitator
    *   **Frase-DNA:** "Destila ruído em sinal, transforma conversa em conhecimento acionável"
*   **Primary Goal:** To enhance team alignment and decision-making velocity in fast-paced communication platforms by converting discussions into structured summaries, explicit decisions, traceable action items, and documented knowledge.
*   **Core Capabilities:**
    *   **Conversational Thread Siphon & Distiller (Aprimorado):** Monitors or processes chat threads using LLMs with RAG.
    *   **Action Item & Decision Tracker (Aprimorado):** Identifies, formats, and logs action items/decisions.
    *   **Structured Brief & Report Generator (Aprimorado):** Generates markdown summaries and TTS audio.
    *   **Knowledge Integration & Contextualization (Novo):** Integrates with knowledge bases.
    *   **Interactive Governance & Feedback (Aprimorado):** Uses interactive chat elements for confirmations.
*   **A2A Alignment (Conceptual):**
    *   Its `AgentDefinition` forms its A2A Agent Card, detailing its skills in knowledge management, summarization, and action tracking from communication platforms.
    *   **Exposed Skills (Examples via JSON-RPC `message/send`):**
        *   `skillId: "summarize_communication_thread"`
            *   `params: { "platform_name": "slack", "channel_id": "...", "thread_ts": "...", "summary_length": "brief" }`
        *   `skillId: "extract_decisions_and_actions"`
            *   `params: { "transcript_cid": "...", "output_format": "markdown_list" }`
        *   `skillId: "archive_summary_to_knowledge_base"`
            *   `params: { "summary_cid": "...", "knowledge_base_target_cid": "...", "tags": ["project_phoenix", "q3_planning"] }`
    *   **Consumed/Produced Events (IAP `PlatformEvent`):**
        *   Consumes: `ionverse.communication.new_long_thread_detected_in_channel_X`.
        *   Produces: `ionflux.commbutler.summary_created`, `ionflux.commbutler.action_item_logged`.
    *   **Agent 000 Orchestration:** "ION, summarize the key decisions from the #general channel discussion on 'Q4 Budget' from yesterday and log it to our Notion workspace under 'Finance Meetings'."

---

## 8. Creator Persona Guardian (agent_008_refactored)

*   **Epíteto:** O Guardião Algorítmico da Alma Criativa e da Ressonância com a Audiência
*   **TAGLINE:** SUA VOZ É ÚNICA; NOSSA IA GARANTE QUE ELA SEJA OUVIDA E SENTIDA — SEMPRE
*   **Essência:**
    *   **Arquétipo:** Guardian/Mentor/Oracle
    *   **Frase-DNA:** "Amplifica a autenticidade, sintoniza a ressonância"
*   **Primary Goal:** To empower creators and brands to maintain and evolve their authentic voice and persona at scale, ensuring consistency, optimizing audience resonance, and protecting against identity dilution.
*   **Core Capabilities:**
    *   **Multimodal Persona Definition & Extraction (Aprimorado):** Ingests diverse content to extract a 360° persona fingerprint.
    *   **Content Authenticity & Resonance Scoring (Aprimorado):** Evaluates new content against persona and predicts audience resonance.
    *   **AI-Powered Style Repair & Enhancement (Aprimorado):** Uses LLMs to suggest edits or offer variations.
    *   **Persona Evolution & Drift Monitor (Aprimorado):** Monitors content and feedback to detect persona drift.
    *   **Persona Style Transfer Hub (Novo):** Acts as a style consultant for other content-generating agents.
*   **A2A Alignment (Conceptual):**
    *   Its `AgentDefinition` serves as its A2A Agent Card, describing its persona management, content analysis, and style alignment services.
    *   **Exposed Skills (Examples via JSON-RPC `message/send`):**
        *   `skillId: "analyze_content_for_persona_alignment"`
            *   `params: { "content_cid": "...", "target_persona_profile_cid": "..." }`
        *   `skillId: "generate_persona_style_guide"`
            *   `params: { "persona_profile_cid": "...", "output_format": "markdown" }`
        *   `skillId: "adapt_text_to_persona"`
            *   `params: { "text_input_cid": "...", "target_persona_profile_cid": "...", "strength_of_adaptation": 0.8 }`
    *   **Consumed/Produced Events (IAP `PlatformEvent`):**
        *   Consumes: `ionpod.content.new_draft_created_by_user_X`.
        *   Produces: `ionflux.personaguardian.content_review_completed`, `ionflux.personaguardian.style_suggestion_available`.
    *   **Agent 000 Orchestration:** "ION, check if my latest blog post draft aligns with my 'TechFuturist' persona and suggest improvements for audience resonance."

---

## 9. Badge Motivator (agent_009_refactored)

*   **Epíteto:** O Arquiteto de Jornadas de Engajamento e Maestria Contínua
*   **TAGLINE:** TRANSFORMA AÇÃO EM HÁBITO, HÁBITO EM CONQUISTA, CONQUISTA EM IDENTIDADE
*   **Essência:**
    *   **Arquétipo:** Gamemaster/Mentor
    *   **Frase-DNA:** "Recompensa o esforço, celebra o progresso, inspira a maestria"
*   **Primary Goal:** To drive user engagement, feature adoption, task completion, and productive collaboration within IONFLUX and the broader IONVERSE through a sophisticated, adaptive, and social gamification system.
*   **Core Capabilities:**
    *   **Dynamic XP & Achievement Engine (Aprimorado):** Attributes XP and tracks progress for measurable actions.
    *   **Generative & Symbolic Badge Forge (Aprimorado):** Generates unique SVG/PNG badges.
    *   **Adaptive Leaderboards & Social Feeds (Aprimorado):** Creates dynamic leaderboards and activity feeds.
    *   **Intelligent Reward & Recognition Router (Aprimorado):** Triggers webhooks/notifications for rewards.
    *   **Quest & Challenge Designer (Novo):** Allows creation of structured "Quests."
*   **A2A Alignment (Conceptual):**
    *   Its `AgentDefinition` is the basis for its A2A Agent Card, detailing its role in the platform's engagement, quest, and reward systems.
    *   **Exposed Skills (Examples via JSON-RPC `message/send`):**
        *   `skillId: "record_user_action_for_xp"`
            *   `params: { "user_did": "...", "action_type": "flow_created", "action_metadata_cid": "..." }`
        *   `skillId: "award_badge_manually"`
            *   `params: { "user_did": "...", "badge_id": "early_adopter_q1", "reason": "Exceptional community contribution" }`
        *   `skillId: "get_user_achievements_list"`
            *   `params: { "user_did": "..." }`
    *   **Consumed/Produced Events (IAP `PlatformEvent`):**
        *   Consumes: `ionverse.app.feature_X_used_by_user_Y`, `ionflux.flow.successfully_executed_by_user_Z`.
        *   Produces: `ionflux.badgemotivator.badge_awarded`, `ionflux.badgemotivator.level_up`.
    *   **Agent 000 Orchestration:** Agent 000 itself could be a source of actions that Badge Motivator tracks, or it could query a user's achievements: "ION, what badges has User Alpha earned this month?"

---

## 10. Revenue Tracker Lite (agent_010_refactored)

*   **Epíteto:** O Analista Financeiro Pessoal da Sua Loja, Focado em Lucratividade Real
*   **TAGLINE:** FATURAMENTO É VAIDADE, LUCRO É SANIDADE, FLUXO DE CAIXA É REI — NÓS MOSTRAMOS OS TRÊS.
*   **Essência:**
    *   **Arquétipo:** Analyst/Sage
    *   **Frase-DNA:** "Revela a verdade financeira por trás da receita"
*   **Primary Goal:** To provide e-commerce store owners with clear, concise, and actionable insights into their real profitability by tracking revenue and variable costs to calculate contribution margin.
*   **Core Capabilities:**
    *   **Automated Cost Ingestor (Aprimorado e Conectado):** Pulls revenue data from Shopify; allows input/integration for COGS, fees, shipping, marketing.
    *   **Real-time Margin Calculator (Aprimorado):** Calculates gross and net contribution margins.
    *   **Profitability Variance Sentinel (Aprimorado):** Monitors margin trends and alerts on deviations.
    *   **Actionable Insights & Daily Digestor (Aprimorado):** Provides summaries and LLM-generated optimization suggestions.
    *   **Data Source for Other Agents (Novo):** Exposes profitability data for other agents.
*   **A2A Alignment (Conceptual):**
    *   Its `AgentDefinition` serves as its A2A Agent Card, outlining its financial analysis capabilities specifically for e-commerce profitability.
    *   **Exposed Skills (Examples via JSON-RPC `message/send`):**
        *   `skillId: "get_profit_margin_for_product"`
            *   `params: { "store_id": "...", "product_id_shopify": "...", "time_period": "last_30_days" }`
        *   `skillId: "generate_profitability_report"`
            *   `params: { "store_id": "...", "report_period": "q1_2024", "output_format_cid_preference": "..." }`
        *   `skillId: "add_manual_cost_entry"`
            *   `params: { "store_id": "...", "cost_category": "marketing_spend_facebook", "amount": 150.75, "date_incurred": "..." }`
    *   **Consumed/Produced Events (IAP `PlatformEvent`):**
        *   Consumes: `ionverse.shopify.order_created`, `ionverse.adsplatform.campaign_spend_updated`.
        *   Produces: `ionflux.revenuetracker.profit_margin_alert`, `ionflux.revenuetracker.weekly_digest_ready`.
    *   **Agent 000 Orchestration:** "ION, what was the net profit margin for my 'SuperWidget' product last month, and are there any cost anomalies I should look into?"

---
