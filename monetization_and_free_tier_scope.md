# IONFLUX Project: FREE-10 Agents Package & Monetization Stubs

This document outlines the scope for the initial "FREE-10 Agents" package and the conceptual stubs for platform monetization, drawing from the project proposal and previously defined documents like `core_agent_blueprints.md` and `conceptual_definition.md`.

## 1. "FREE-10 Agents" Package

This package aims to provide significant initial value to users, showcasing core IONFLUX capabilities across automation, insights, and content assistance.

**1.1. List of the 10 Agents (from Project Proposal Section 5):**

1.  **`Email Wizard`**
2.  **`WhatsApp Pulse`**
3.  **`TikTok Stylist`** (Already blueprinted)
4.  **`Shopify Sales Sentinel`** (Already blueprinted)
5.  **`UGC Matchmaker`** (Already blueprinted, TikTok Focus for Beta)
6.  **`Outreach Automaton`**
7.  **`Slack Brief Butler`** (Already blueprinted, can be generalized to "Chat Brief Butler")
8.  **`Persona Guardian`**
9.  **`Badge Motivator`**
10. **`Revenue Tracker Lite`** (Already blueprinted, Shopify Focus for Beta)

**1.2. Brief Purpose for the 5 Non-Blueprinted Agents:**

*   **1. `Email Wizard`:**
    *   **Purpose & Value:** Assists users in drafting various types of emails, such as responses to customer inquiries, marketing outreach messages, or follow-up sequences, by leveraging LLM capabilities based on user prompts or templates. This saves time and helps maintain consistent communication quality.
*   **2. `WhatsApp Pulse`:**
    *   **Purpose & Value:** (Requires WhatsApp Business API integration) Monitors connected WhatsApp channels for keywords, sentiment shifts, or high message volume, providing summaries or alerts to help users stay on top of important conversations or customer service issues without constant manual checking.
*   **6. `Outreach Automaton`:**
    *   **Purpose & Value:** Helps users organize, track, and manage multi-step outreach campaigns across different channels (e.g., email, potentially social DMs if APIs allow). It provides reminders for follow-ups and an overview of campaign status, improving efficiency and effectiveness of outreach efforts.
*   **8. `Persona Guardian`:**
    *   **Purpose & Value:** Monitors brand mentions (if a social listening integration is added) or analyzes content drafts (from Canvas or Chat) against a pre-defined brand persona (e.g., tone, style, keywords to avoid/use). This helps maintain brand consistency across all communications and content.
*   **9. `Badge Motivator`:**
    *   **Purpose & Value:** A gamification agent that awards users or workspace members virtual badges for achieving milestones, completing tasks, utilizing IONFLUX features effectively, or collaborating successfully. This encourages platform engagement, learning, and positive team dynamics.

**1.3. Rationale for the Package:**

This selection of 10 agents offers a compelling free tier by:

*   **Showcasing Core IONFLUX Pillars:** It touches upon e-commerce integration (Shopify), social media assistance (TikTok), communication aids (Email, WhatsApp, Chat Briefs), organizational tools (Outreach), brand management (Persona), and platform engagement (Badges).
*   **Providing Immediate Utility:** Agents like `Shopify Sales Sentinel`, `Revenue Tracker Lite`, and `Slack Brief Butler` offer quick, tangible benefits by automating monitoring and summarization tasks.
*   **Encouraging Exploration & Creativity:** Creative agents like `TikTok Stylist` and utility agents like `Email Wizard` encourage users to explore LLM-powered assistance and discover new ways to enhance their workflows.
*   **Demonstrating Breadth and Integration:** The variety gives a taste of IONFLUX's potential as a central command center that integrates various external services and internal tools.
*   **Path to Paid Features & Monetization:** While useful, the "Lite" or focused nature of some free agents (e.g., `Revenue Tracker Lite`) naturally suggests more advanced capabilities, higher usage limits, or more sophisticated versions available in paid tiers or through the "Rent-an-Agent" marketplace. The package also introduces users to concepts like brand persona management (`Persona Guardian`) and outreach (`Outreach Automaton`), which can have more powerful paid counterparts.

## 2. Monetization Stubs (Conceptual Outline)

These are initial concepts for how IONFLUX will generate revenue beyond simple subscriptions (which are assumed to be a primary model for offering varying levels of resource access, agent counts beyond the free tier, etc.).

**2.1. 2% Transactional Fee:**

*   **Applicability:**
    *   This fee is primarily intended to apply to transactions directly facilitated or brokered by the IONFLUX platform, specifically where IONFLUX plays an active role in connecting parties or enabling a financial exchange.
    *   **Initial Target:** Brand-Creator collaborations initiated and managed through an IONFLUX workflow that includes discovery (e.g., via `UGC Matchmaker`), negotiation/agreement (potentially via a dedicated Canvas template or chat flow), and deliverable submission/acceptance.
    *   **Future Considerations:** Could extend to other types of transactions if IONFLUX introduces features like a "services marketplace" where users sell services (e.g., custom agent configurations, consulting) to each other within the platform.
*   **Data Points/Entities Needed (Conceptual):**
    *   **`PlatformTransaction` (New Entity - as previously defined, consistent with `conceptual_definition.md` if extended):**
        *   `id: string (UUID)`
        *   `workspace_id: string (references Workspace.id)`
        *   `type: string (enum: 'creator_collaboration', 'service_sale', 'agent_rental_payout')`
        *   `status: string (enum: 'pending', 'agreed', 'in_progress', 'completed', 'disputed', 'cancelled', 'payout_processed')`
        *   `initiating_user_id: string (references User.id)`
        *   `paying_user_id: string (references User.id, for rental or service sale)`
        *   `receiving_user_id: string (references User.id, for rental payout or service sale)`
        *   `counterparty_brand_id: string (references Brand.id, nullable)`
        *   `counterparty_creator_id: string (references Creator.id, nullable)`
        *   `ionflux_workflow_id: string (nullable, references a future "Workflow" entity)`
        *   `related_agent_config_id: string (nullable, references AgentConfiguration.id)`
        *   `related_marketplace_listing_id: string (nullable, references AgentMarketplaceListing.id)`
        *   `transaction_description: text`
        *   `gross_amount: decimal`
        *   `currency: string (e.g., 'USD')`
        *   `transaction_date: timestamp`
        *   `ionflux_fee_percentage: decimal (e.g., 0.02 for collaborations, 0.15 for rentals)`
        *   `ionflux_fee_amount: decimal (calculated)`
        *   `net_amount_due_recipient: decimal (calculated)`
        *   `payment_processor_reference_id: string (nullable)`
        *   `payout_reference_id: string (nullable)`
        *   `created_at: timestamp`
        *   `updated_at: timestamp`
    *   **Updates to `User` or `Workspace`:** May need fields to link to payment provider details (e.g., Stripe Connect Account ID stored in `User.profile_info` or a dedicated `UserPaymentProfile` table) if IONFLUX facilitates payouts. `User.stripe_customer_id` already exists for future billing.
*   **Service Interaction (High-Level):**
    *   A dedicated **`BillingService` or `MonetizationService`** would be responsible.
    *   This service would:
        *   Receive events or API calls from other services (e.g., `AgentService` when a `UGC Matchmaker` flow leads to an agreement, `CanvasService` if a "collaboration agreement" block is finalized, or a future `MarketplaceService` for agent rentals).
        *   Create and manage `PlatformTransaction` records.
        *   Integrate with a payment processor (e.g., Stripe Connect) to handle payments from buyers/renters and payouts to sellers/listers, automatically deducting the IONFLUX fee.
        *   `UserService` and `WorkspaceService` would provide context on users and their payment/billing status.

**2.2. "Rent-an-Agent" Marketplace (15% Commission):**

*   **Marketplace Listing Concept:**
    *   Users (typically advanced users, agencies, or developers) can list their highly customized and effective `AgentConfiguration`s or specially crafted `AgentDefinition`s (if the platform allows custom definition creation beyond simple configuration) for other users to "rent."
    *   **`AgentMarketplaceListing` (New Entity - as previously defined):**
        *   `id: string (UUID)`
        *   `lister_user_id: string (references User.id)`
        *   `lister_workspace_id: string (references Workspace.id)`
        *   `agent_configuration_id: string (references AgentConfiguration.id, if listing a specific pre-configured instance whose YAML is hidden from renter)`
        *   `agent_definition_id: string (references AgentDefinition.id, if listing a more generic template the renter configures minimally based on exposed schema)`
        *   `listing_title: string`
        *   `listing_description: text`
        *   `category: string (e.g., 'Advanced SEO', 'Shopify Optimization Pro')`
        *   `tags: [string]`
        *   `rental_model: string (enum: 'per_run', 'time_period_subscription')`
        *   `price_per_run: decimal (nullable)`
        *   `price_per_month: decimal (nullable)` // Or other time units like 'weekly', 'quarterly'
        *   `currency: string (e.g., 'USD')`
        *   `usage_instructions: text`
        *   `input_schema_overview: json (summary of what renter needs to provide if any, derived from AgentDefinition.input_schema)`
        *   `output_preview_sample: json (example of what the agent produces, from AgentDefinition.output_schema)`
        *   `status: string (enum: 'draft', 'active', 'paused', 'archived', 'under_review')`
        *   `average_rating: float (nullable)`
        *   `total_rentals: integer (default: 0)`
        *   `created_at: timestamp`
        *   `updated_at: timestamp`
*   **Rental Process (Conceptual):**
    1.  **Discovery:** Renter browses the "Rent-an-Agent" section of the Marketplace. Filters by category, rating, price.
    2.  **Selection:** Renter chooses an `AgentMarketplaceListing`. Reviews description, input/output schema, pricing.
    3.  **Payment:** Renter pays the rental fee through IONFLUX (which uses a payment processor). This creates an `AgentRentalAgreement` and its associated `PlatformTransaction`.
    4.  **Access Granted:**
        *   The `AgentService` grants the renter's workspace execute-only access to the underlying `AgentConfiguration` or the ability to instantiate from the rented `AgentDefinition` for the agreed duration or number of runs.
        *   The core intellectual property (detailed YAML of a rented `AgentConfiguration`, or the full logic of a rented `AgentDefinition`) is not directly exposed to the renter unless the lister explicitly chooses a more open model (e.g. "template with source").
    5.  **Usage:** Renter uses the agent via their `Agent Snippet` blocks or `/commands` like any other agent they own, but with usage tracked against their `AgentRentalAgreement`.
*   **Commission Calculation:**
    *   IONFLUX charges a 15% commission on the gross rental fee collected from the renter.
    *   The `PlatformTransaction` record associated with the rental would reflect this: `gross_amount` is the rental price, `ionflux_fee_percentage` is 0.15, `ionflux_fee_amount` is calculated, and `net_amount_due_recipient` is what the lister receives.
*   **Data Points/Entities Needed (Conceptual):**
    *   `AgentMarketplaceListing` (as above)
    *   **`AgentRentalAgreement` (New Entity - as previously defined):**
        *   `id: string (UUID)`
        *   `listing_id: string (references AgentMarketplaceListing.id)`
        *   `renter_user_id: string (references User.id)`
        *   `renter_workspace_id: string (references Workspace.id)`
        *   `lister_user_id: string (references User.id)` // Added for clarity
        *   `rented_agent_instance_id: string (nullable, if a temporary AgentConfiguration is created for the renter based on the listing)`
        *   `rental_start_date: timestamp`
        *   `rental_end_date: timestamp (nullable, for time-period rentals)`
        *   `runs_purchased: integer (nullable, for per-run rentals)`
        *   `runs_consumed: integer (default: 0)`
        *   `status: string (enum: 'active', 'expired', 'cancelled_by_renter', 'cancelled_by_lister')`
        *   `platform_transaction_id: string (references PlatformTransaction.id)` // Link to the financial transaction
    *   `PlatformTransaction` (as defined in section 2.1, with `type='agent_rental_payment'` for renter payment and `type='agent_rental_payout'` for lister payout).
*   **Service Interaction (High-Level):**
    *   **`MarketplaceService` (Potentially a new service or part of AgentService):** Manages CRUD operations for `AgentMarketplaceListing`s, handles search/discovery, and reviews/ratings.
    *   **`AgentService`:**
        *   Manages the secure execution access for rented agents (e.g., creating temporary, restricted `AgentConfiguration` instances for the renter or applying permissions).
        *   Tracks `runs_consumed` on `AgentRentalAgreement`.
    *   **`BillingService` / `MonetizationService`:**
        *   Processes rental payments from renters via a payment gateway.
        *   Creates `PlatformTransaction` records for rentals and payouts.
        *   Manages payouts to listers after deducting the commission.
    *   `UserService` and `WorkspaceService` provide context for listers and renters.

These monetization stubs are conceptual and would require significant further design for security (protecting listers' IP), payment processing integration, dispute resolution, taxation, and ensuring fair use policies.
```
