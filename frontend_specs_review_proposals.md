```markdown
# Proposed Clarifications for Frontend Specifications

This document lists proposed clarifications and minor additions for `frontend_onboarding_specs.md` and `frontend_canvas_chat_specs.md`, based on a review against the updated `core_agent_blueprints.md`, `agent_interaction_model.md`, and `conceptual_definition.md`.

## 1. `frontend_onboarding_specs.md`

**Review Finding:**
The `frontend_onboarding_specs.md` primarily details user registration, login, workspace creation, and the main app layout. The recent updates to agent definitions and interaction models (like `AgentConfiguration.effective_config_cache` or `Workspace.settings.default_llm_config`) are more relevant to agent execution and workspace operation rather than the initial onboarding flows.

While `Workspace.settings` (e.g., `default_llm_config`) might eventually be configurable through a workspace settings UI accessible after onboarding, this is likely outside the scope of the immediate E2E demo's onboarding screens. User profile information (`User.profile_info`) also remains largely unaffected by agent-specific details at the onboarding stage.

**Proposal:**
*   **No changes are deemed necessary for `frontend_onboarding_specs.md` specifically for the E2E demo scope.**
*   A future consideration for a more comprehensive "Workspace Settings" screen (beyond onboarding) could include options related to default agent configurations or LLM preferences, but this is not an immediate requirement for the current review.

## 2. `frontend_canvas_chat_specs.md`

### 2.1. Agent Snippet Block Component (Canvas)

**Current (Assumed):** Displays agent name, status, and a way to run/configure. May show `last_run_output_preview`.

**Review Findings & Proposals:**

*   **Handling `last_run_output_preview` (from `AgentConfiguration`):**
    *   **Clarification Needed:** The `output_preview` from agent runs (e.g., n8n callbacks) can be simple text or a snippet of structured data (e.g., "Found 5 creators", "Generated 3 content ideas for #topic", or even a small JSON like `{"trend": "xyz", "views": 1000}`).
    *   **Proposal:**
        *   The UI should attempt to render `last_run_output_preview` as plain text.
        *   If the preview is very short and looks like JSON or a simple key-value pair, it can be displayed as is.
        *   Avoid complex rendering for the *preview* itself. It's a summary.
        *   Add a note: "The `last_run_output_preview` is intended as a concise textual summary. For structured data, it might be a brief description (e.g., 'Generated sales report data') rather than the data itself. The 'View Full Output' provides access to the complete data."

*   **"View Full Output" Functionality (using `last_run_full_output_ref`):**
    *   **Clarification Needed:** `last_run_full_output_ref` (from `AgentConfiguration`) contains the stringified JSON of the complete output from the agent's last run. This could be extensive JSON, markdown, or other text-based formats.
    *   **Proposal:**
        *   **Button/Link:** Clearly label a button or link, e.g., "View Full Output" or "Show Last Output Details". This should be active if `last_run_full_output_ref` is present.
        *   **Display Mechanism (E2E Demo):** For the E2E demo, clicking "View Full Output" should open a modal dialog.
        *   **Content Rendering in Modal:**
            *   The modal should attempt to detect if the content of `last_run_full_output_ref` is JSON or Markdown.
            *   If JSON: Display it pretty-printed (e.g., using `<pre>` tags with appropriate styling or a lightweight JSON viewer component).
            *   If Markdown: Render the Markdown to HTML within the modal.
            *   If plain text or unknown: Display as pre-formatted text.
            *   Add a note: "The modal for 'View Full Output' should provide basic rendering for common formats like JSON and Markdown. For the E2E demo, complex interactive displays (like tables from JSON) are not required; readable presentation is key."

### 2.2. Agent Configuration Modal Component (Canvas & potentially Agent Hub)

**Current (Assumed):** Provides a YAML editor for `AgentConfiguration.yaml_config`.

**Review Findings & Proposals:**

*   **Contextual Information from `AgentDefinition`:**
    *   **Clarification Needed:** Users editing the `yaml_config` need context about what they *can* and *should* configure, which is defined in the parent `AgentDefinition` (e.g., `inputs_schema`, `description`, what parts of `triggers_config` or `memory_config` are exposed/configurable).
    *   **Proposal:**
        *   Enhance the Agent Configuration Modal:
            *   **YAML Editor Pane:** Keep the existing YAML editor for the user's `yaml_config` overrides and input values.
            *   **Information Panel/Tab (Read-Only):** Add a separate panel or tab within the modal that displays key information from the `AgentDefinition` associated with this `AgentConfiguration`. This panel would show:
                *   `AgentDefinition.name` and `AgentDefinition.description` (and potentially `epithet`, `tagline` from blueprints).
                *   A user-friendly rendering of `AgentDefinition.inputs_schema` (e.g., "Required Inputs: `api_key` (string), `search_query` (string); Optional Inputs: `max_results` (number, default: 10)"). This helps users know what to provide in the YAML.
                *   Information on which parts of `triggers_config` or `memory_config` are designed to be overridden by the user (if this level of detail is available in a structured way in `AgentDefinition`).
                *   `AgentDefinition.version`.
            *   Add a note: "The Agent Configuration Modal should provide users with both an editable area for their specific instance's YAML configuration and a read-only reference to the underlying AgentDefinition's schema and description. This aids in discoverability and correct configuration."
        *   For the E2E demo, this information panel could initially focus on just displaying `AgentDefinition.description` and a simplified view of `inputs_schema`.

### 2.3. Chat Dock View (Rendering Agent Messages)

**Current (Assumed):** Differentiates user vs. agent messages. Basic text rendering.

**Review Findings & Proposals:**

*   **Rendering Structured Agent Messages (`ChatMessage.content_type`):**
    *   **Clarification Needed:** `ChatMessage.content` can vary based on `content_type`. The spec needs to be more explicit about rendering `markdown` and `json_proposal`.
    *   **Proposal:**
        *   **`content_type: 'text'`:** Render as plain text (existing behavior).
        *   **`content_type: 'markdown'`:** The chat message bubble should render the `content.text` (which contains markdown) as HTML. Use a standard markdown rendering library.
        *   **`content_type: 'json_proposal'`:**
            *   This type implies a more structured interaction, possibly with actions. For the E2E demo, a simplified display is acceptable.
            *   Render `content.title` (if present) as a header.
            *   Render `content.description` as text.
            *   Display `content.data` (which is likely JSON) pretty-printed within the chat bubble or a collapsible section.
            *   If `content.actions` are present (e.g., buttons for "Accept", "Decline"), these should be rendered as clickable buttons. (For E2E demo, button actions might just log to console or be non-functional, but their presence should be shown).
            *   Add a note: "Agent messages in the Chat Dock must respect `content_type`. Markdown should be rendered as HTML. For `json_proposal`, display the title, description, and a pretty-printed version of the JSON data. Action buttons, if present in the schema, should be visually represented, even if their functionality is limited in the E2E demo."
        *   **General Styling:** Ensure agent messages have distinct styling (e.g., different background color, agent avatar) from user messages, as likely already specified.

These proposals aim to ensure the frontend specifications are sufficiently detailed to handle the richer and more structured data now defined in the backend and agent models, primarily for the E2E demo scope.
```
