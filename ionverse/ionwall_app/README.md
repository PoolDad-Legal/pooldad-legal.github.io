# IONWALL: The Shield of Security & Reputation

> *“IONWALL: quando segurança vira trampolim, reputação vira moeda e compliance vira super‑poder.”*

## 0. EXECUTIVE SHIELD (The Bastion)

IONWALL stands as the unyielding, ever-vigilant bastion of the ION Super-Hub. It's not merely a firewall; it's a sophisticated **programmable reputational security fabric** designed to transcend traditional, reactive security models. Its purpose is not just to block threats, but to proactively cultivate a high-trust environment by making **reputation a tangible, valuable, and verifiable asset** for every participant in the IONVERSE. It is the zero-trust foundation upon which sovereignty, fair exchange, and complex collaborations are built.

IONWALL's core mandate is threefold:
1.  **Authenticate & Manage Sovereign Identities:** Provide robust, user-controlled, and cryptographically secure identity verification and management using DIDs and Passkeys.
2.  **Compute & Attest to Dynamic Reputation:** Continuously assess and score user and agent behavior, translating interactions into quantifiable reputation scores that are recorded on-chain for transparency and portability.
3.  **Enforce Programmable Governance:** Apply dynamic, context-aware governance policies (defined in Rego and managed via GitOps) to every transaction, data access request, and agent interaction, ensuring compliance and security with a transparent, auditable, and ideally frictionless user experience.

In essence, IONWALL transforms security from a burdensome necessity into an **active enabler of opportunity**. High reputation, as validated and attested by IONWALL, unlocks premium experiences, preferential economic terms (e.g., lower fees, better loan collateralization), enhanced matchmaking, and greater agency within the IONVERSE. Conversely, actions detrimental to the ecosystem or individual users result in adaptive restrictions, making an entity's digital "aura" or "shield health" a visible and impactful reflection of their trustworthiness and contributions. This is security as a **proactive, gamified, and economically integrated system.**

## 1. ROLE — Propósito Existencial (Existential Purpose)

IONWALL is engineered to fulfill these critical, interconnected roles within the ION Super-Hub:

*   **1.1. Sovereign Identity & Property Shield (The Keystone of Self-Ownership):**
    *   Employs **Passkeys (FIDO2 WebAuthn)** as the primary mechanism for passwordless, phishing-resistant authentication, anchoring digital identity to user-controlled hardware security keys or biometric-protected device enclaves.
    *   Integrates and champions **IONID (a custom Decentralized Identifier method)**, ensuring users have sovereign, portable, and lifelong ownership over their primary digital credentials and associated metadata, independent of any single platform.
    *   Manages Verifiable Credentials (VCs) related to identity (KYC/KYB attestations, accreditations), allowing users to selectively disclose proofs without revealing underlying data.

*   **1.2. Reputation Measurement & Monetization Engine (Reputation as Verifiable Capital):**
    *   Calculates a dynamic, multi-faceted **reputation score** (conceptually 0-1000, with sub-scores like `Score.Fin` for financial conduct, `Score.Create` for creative contributions, `Score.Social` for community interaction) for each Avatar/DID.
    *   These scores are periodically anchored or attested to on the **Base L2 blockchain** (e.g., via Merkle roots of reputation states or direct on-chain attestations for significant achievements/penalties), ensuring transparency, tamper-resistance, and portability across the IONVERSE and potentially beyond.
    *   This score directly influences economic parameters within the ecosystem (see Section 15: Tokenomics).

*   **1.3. Dynamic Zero-Trust Governance & Access Control (The Adaptive Rule of Law):**
    *   Every significant request (API call, inter-agent communication via NATS, IONPOD data access, IONWALLET transaction initiation, IONVERSE Shard interaction) is intercepted and evaluated by IONWALL's distributed policy engine.
    *   **Policy Engine:** Utilizes **Open Policy Agent (OPA)** executing policies written in **Rego**. Policies are version-controlled in Git and deployed via a GitOps workflow.
    *   **Evaluation Criteria:** A rich set of inputs, including cryptographic signature verification (SIWE, Passkey attestations), DID authentication, KYC/KYB verification tier, current reputation scores, geofencing rules, heuristic-based rate-limiting (adaptive based on reputation), context-specific permissions granted by users for their agents/data, and anomaly detection flags from the Observability Mesh. These policy evaluations are often invoked by other IONVERSE services or Agent 000 via the IONVERSE Agent Protocol (IAP).

*   **1.4. Immutable Compliance Proofing & Audit Trail (The Verifiable Record):**
    *   Each access control decision, policy evaluation, consent grant/revocation, and significant reputation change generates an immutable log entry.
    *   These logs are cryptographically chained (e.g., forming a local Merkle tree per user or per service, whose roots are then aggregated), with final roots periodically committed to the Base L2 blockchain. This provides a highly secure, verifiable, and tamper-evident audit trail for compliance, dispute resolution, and transparency.

*   **1.5. Gamified Security & Trust Experience (The "Aura" System):**
    *   Users have a visual representation of their "Trust Aura" or "Reputation Shield Health" within their IONPOD dashboard and IONVERSE Avatar profile. This aura might change color, intensity, or have visual effects based on their reputation score and recent security-positive actions.
    *   Positive security practices (e.g., enabling Passkeys on all devices, regularly reviewing granted permissions, maintaining high data hygiene in IONPOD, ethical online behavior as assessed by community feedback or AI moderation tools) contribute to a stronger, more vibrant aura, incentivizing proactive security engagement and responsible digital citizenship. Negative actions or security incidents would visibly "tarnish" or "weaken" the aura.

## 2. WHAT IT DOES — Loop de Valor (The Value Loop: Verify → Classify → Monetize/Govern → Protect → Evolve)

IONWALL's operational cycle is designed to continuously reinforce trust, enable value exchange, and adapt to new challenges:

1.  **Verify (Identity Onboarding & Attestation):**
    *   Integrates with trusted KYC/KYB providers (e.g., Passbase, Persona, Veriff, with liveness detection and document verification) to establish different tiers of verified identity (e.g., Anonymous, Pseudonymous-Verified, Fully-Verified).
    *   An IONID (DID) is issued or linked upon successful verification, and relevant Verifiable Credentials (VCs) attesting to this verification are stored in the user's IONPOD and anchored via IONWALLET.
    *   Ongoing verification: Re-validates Passkeys, checks for compromised credentials, monitors for sybil behavior.

2.  **Classify (Reputation Scoring & Risk Assessment):**
    *   The **Reputation Engine** continuously ingests a wide array of data points via NATS event streams (IAP `PlatformEvent`s) from across the ION Super-Hub:
        *   `ionwallet.transaction.successful`, `ionwallet.loan.repaid_on_time`
        *   `ionverse.marketplace.trade_completed_positively`, `ionverse.shard.content_highly_rated`
        *   `ionflux.flow.execution_successful_and_efficient`, `ionflux.agent.published_and_adopted`
        *   `ionpod.credential.verified_by_others`, `ionpod.data.shared_with_consent_and_positive_feedback`
        *   `ionwall.security_challenge.passed`, `ionwall.governance.vote_cast`
        *   Negative signals: `ionverse.moderation.strike_issued`, `ionwall.policy_violation_detected`, `ionflux.flow.execution_failed_due_to_misconfig`.
    *   These inputs are weighted according to a transparent, version-controlled, and potentially DAO-governed **Rego policy set** (the "Reputation Calculation Policy"). The formula is multifaceted, e.g.:
        `ReputationScore = (BaseTrustFromKYC * w1) + (EconomicActivityScore * w2) + (SocialGraphScore * w3) + (CreativeContributionScore * w4) - (NegativeIncidentsScore * w5)`
        Each sub-score is derived from multiple weighted inputs.
    *   Risk assessment: Simultaneously, IONWALL assesses the risk of incoming requests based on sender reputation, request patterns, and payload heuristics, often as part of an IAP interaction.

3.  **Monetize/Govern (Reputation & Policy as Active Factors):**
    *   **Economic Impact (Monetize):** Reputation scores directly influence economic parameters defined in other ION apps, often queried or factored in by these applications via IAP. High reputation can mean lower fees in IONWALLET/Marketplace, better rates in DeFi protocols, higher visibility for created content in IONVERSE, or increased C-ION rewards from IONFLUX.
    *   **Access Control (Govern):** IONWALL's OPA engine evaluates every request (many arriving as IAP calls) against relevant policies. Policies use reputation scores, identity attributes (VCs), request context, and risk scores as inputs to make fine-grained allow/deny decisions.

4.  **Protect (Adaptive Security Enforcement & Incident Response):**
    *   The **Edge Gateway** (see 3.1) provides first-line defense. WASM plugins at the edge perform initial heuristic analysis.
    *   Requests from low-reputation sources or matching known threat patterns (potentially identified via IAP metadata from the calling agent or user) are either rate-limited more aggressively, challenged (e.g., CAPTCHA, or triggering an `IONWALL_ActionApproval_Transform` flow via IAP), or routed to a sandboxed environment.
    *   If a policy violation is confirmed by OPA, IONWALL can block the request, suspend capabilities, trigger alerts (potentially as IAP `PlatformEvent`s), and log the incident.

5.  **Evolve (Continuous Learning, Policy & Reputation Model Refinement):**
    *   All decision logs (many related to IAP interactions), incident reports, and user feedback are fed into the ClickHouse Data Vault.
    *   Machine learning models analyze this data to identify new threat patterns, suggest adjustments to reputation/policy models.
    *   Policy updates are version-controlled and deployed via GitOps.

## 3. IMPLEMENTATION — Arquitetura em Camadas (Layered Architecture)

IONWALL's architecture is designed for high availability, resilience, low-latency decision-making, and verifiable auditability. It functions as a set of distributed services closely integrated with the sNetwork's core infrastructure.

\`\`\`mermaid
graph LR
    subgraph User/Agent Request Flow
        A[External/Internal Request via IAP/Direct] --> B(Edge Gateway: Traefik + WASM Plugins);
        B --> C{IONWALL Core Services};
    end

    subgraph IONWALL Core Services
        C --> D[Identity Fabric: DID/Passkey/VC Service (IAP Skills)];
        C --> E[Reputation Engine: OPA + Scoring Logic (IAP Skills)];
        E --> F[Policy Store: Git/IPFS -> OPA Cache];
        C --> G[Governance & Compliance Engine (IAP Skills)];
        G --> H[Audit Trail Service];
        H --> I[Blockchain Anchoring Service];
    end

    subgraph Data & Supporting Infrastructure
        J[Data Vault: ClickHouse OLAP] --> E;
        J --> G;
        K[Primary DB: PostgreSQL - Configs, Hot Policies] --> E;
        K --> F;
        L[NATS JetStream: Event Ingestion (IAP PlatformEvents)] --> E;
        L --> J;
        M[Observability Mesh: Prometheus, Grafana, Loki] --> C;
        M --> B;
    end

    D --> IONWALLET_Interaction;
    IONWALLET_Interaction[IONWALLET (External User Interface/HSM)] --> D;
    I --> Blockchain_L2[Base L2 Blockchain];

    style A fill:#fff,stroke:#333,stroke-width:2px
    style B fill:#f9f,stroke:#333,stroke-width:2px
    style C fill:#ccf,stroke:#333,stroke-width:2px
    style D fill:#lightgrey,stroke:#333
    style E fill:#lightgrey,stroke:#333
    style F fill:#lightgrey,stroke:#333
    style G fill:#lightgrey,stroke:#333
    style H fill:#lightgrey,stroke:#333
    style I fill:#lightgrey,stroke:#333
    style J fill:#e6e6fa,stroke:#333
    style K fill:#e6e6fa,stroke:#333
    style L fill:#e6e6fa,stroke:#333
    style M fill:#e6e6fa,stroke:#333
    style IONWALLET_Interaction fill:#def,stroke:#333,stroke-width:2px
    style Blockchain_L2 fill:#def,stroke:#333,stroke-width:2px
\`\`\`
*   **Scaling Strategy:** Stateless components (Edge Gateway plugins, OPA instances, API services for Identity/Reputation/Governance) are horizontally scalable via Kubernetes HPA. Stateful data stores (PostgreSQL, ClickHouse, NATS) use clustering, read replicas, and partitioning. OPA policies are cached locally on evaluation nodes for low-latency decisions.

### 3.1 Edge Gateway (First Line of Defense & IAP Entry Point)
*   **Technology:** **Traefik** (or Nginx/Envoy) as the primary reverse proxy, ingress controller, and load balancer. Serves as a primary entry point for many IAP requests to IONWALL services.
*   **WASM Plugins:** Custom WebAssembly plugins (written in Rust or Go) executed by Traefik for:
    *   Deep HTTP/GraphQL request inspection.
    *   Initial DID/JWT validation (from IAP calls).
    *   Heuristic-based threat detection.
    *   Dynamic rate limiting enforcement.
    *   Routing IAP requests to appropriate IONWALL core services.
*   **Security Policies (Gateway Level):** Enforces TLS 1.3+, HSTS, CSP, etc.
*   **Rate Limiting & Throttling:** Utilizes **Redis Cell** or similar, with limits influenced by reputation scores of the calling agent/user DID.

### 3.2 Identity Fabric (The "Who Are You?" Layer & IAP Provider)
*   **Primary Authentication Service:** Handles Passkey ceremonies. Issues JWTs containing DID.
*   **Decentralized Identifier (DID) Management:** IONID Service for \`did:ionid:*\` lifecycle. DID Docs on IPFS.
*   **Verifiable Credential (VC) Service:** Issues and verifies VCs. This service exposes IAP skills like \`issueAttestation(subjectDid, claim, attesterId)\` and \`verifyCredential(holderDid, vc)\`.
*   **On-Chain Identity Linkage (ERC-4337):** Links DID/Passkeys to ERC-4337 smart wallets via IONWALLET.

### 3.3 Reputation Engine (The "Are You Trustworthy?" Layer & IAP Provider)
*   **Policy Engine Core (OPA):** Evaluates requests against Rego policies. Policies fetched from Git/IPFS via Policy Store.
*   **Reputation Data Ingestion & Processing Service:** Subscribes to NATS IAP \`PlatformEvent\`s. Feeds data to Reputation Scoring Logic (Rego/microservice).
*   **Reputation Score Storage & Attestation:** Scores in PostgreSQL for OPA. Attestations to Base L2. This engine exposes IAP skills like \`getReputationScore(targetDid, scoreTypes)\`.

### 3.4 Data Vault (The Immutable Record & Analytical Mind)
*   **Primary Audit Log Store (ClickHouse):** Stores all IONWALL decision logs, consent records, reputation changes, security incidents.
*   **Blockchain Anchoring Service:** Periodically anchors Merkle roots of audit logs to Base L2.
*   **Analytics & ML Feedback Loop:** IONFLUX agents query ClickHouse for analysis to refine policies and models.

### 3.5 Governance & Compliance Engine (The Rule Setter & Enforcer & IAP Provider)
*   **Policy Management Interface/Service:** Tools for Rego policy lifecycle management (create, test, version, deploy via GitOps).
*   **Consent Management Service:** Tracks user consents (from \`IONWALL_ActionApproval_Transform\` IAP calls and others). OPA queries this for active consent. Exposes IAP skills like \`requestUserConsent(requesterDid, actionDescription, detailsCid, scopes)\`.
*   **Regulatory Compliance Module:** Specific OPA policy sets for GDPR, LGPD, CCPA. Facilitates compliance reporting.
*   **Audit Service Interface:** Exposes an IAP skill like \`logAuditEvent(eventDetails, actorDid)\` for other services/agents to securely log critical events to IONWALL's immutable log.

### 3.6 Observability Mesh (The Watchtower) - *Implementation Details*
*   As previously detailed: Prometheus, Grafana, Loki, OpenTelemetry/Tempo, Alertmanager. Tailored dashboards for IONWALL.

### 3.7 DevSecOps (Secure Foundations & Operations)
*   As previously detailed: CI/CD Security (SAST, DAST, vulnerability scanning), IaC Security, Secret Management (Vault), GitOps for policies, regular audits/pen-tests.

## 3.bis. IONWALL & The IONVERSE Agent Protocol (IAP)

IONWALL is not just a passive enforcer but an active participant and crucial service provider within the IONVERSE Agent Protocol (IAP) ecosystem. Its functionalities are exposed as well-defined services that other agents, including Agent 000 and IONFLUX agents, rely upon for secure and reputation-aware operations.

*   **Discoverability:** IONWALL's IAP-accessible services are discoverable via the mechanisms outlined in the IAP specifications. Conceptually, an "IONWALL Service Agent Card" describes its available skills, endpoints, and schemas.

*   **Key IAP Capabilities Provided by IONWALL:**
    IONWALL exposes a range of IAP skills allowing authorized agents to:
    *   Query reputation scores for entities within the IONVERSE.
    *   Request policy evaluations for specific actions or resource access.
    *   Initiate and manage user consent flows for sensitive operations.
    *   Securely log critical audit events to IONWALL's immutable trail.
    *   Handle the verification and issuance of Verifiable Credentials related to identity and attestations.

*   **IONWALL as IAP Event Consumer & Producer (NATS):**
    *   **Consumes \`PlatformEvent\`s:** IONWALL's Reputation Engine subscribes to a multitude of \`PlatformEvent\`s from across the IONVERSE (e.g., \`ionwallet.transaction.completed\`, \`ionverse.marketplace.trade_disputed\`, \`ionflux.agent.execution_failed\`) to gather data for reputation scoring.
    *   **Produces \`PlatformEvent\`s:** IONWALL publishes its own critical events to NATS for other agents or services to consume, such as:
        *   \`ionwall.reputation.score_updated\`
        *   \`ionwall.policy.violation_detected\`
        *   \`ionwall.security.threat_level_changed\`
        *   \`ionwall.consent.granted_or_revoked\`

*   **Overarching Security:** All IAP interactions with IONWALL services are inherently subject to IONWALL's own rigorous authentication and authorization mechanisms, ensuring that agents can only access information or invoke operations for which they have explicit permission.

*   **Further Details:** The comprehensive architectural patterns, interaction models, specific IAP message schemas, and detailed technical specifications for how agents (including Agent 000) interact with services like IONWALL are detailed in the central IONVERSE documentation:
    *   **[IONVERSE Agent Interaction Model](../specs/agent_interaction_model_v4.md):** Describes the roles, patterns, and high-level interactions within the agent ecosystem.
    *   **[IONVERSE Agent Protocol Specification](../specs/IONVERSE_AGENT_PROTOCOL.md):** Provides the definitive technical details of the protocol, including message structures, transport mechanisms, and event schemas.

## 4. HOW‑TO‑IMPLEMENT (Kickstart & Hands‑On for Developers)

This guides developers interacting with or contributing to IONWALL.

1.  **Understand Core Concepts:**
    *   **Action:** Deeply read IONWALL \`README.md\` (this file), especially Sections 0, 1, 2, and 3.bis. Study \`specs/transforms/IONWALL_ActionApproval_Transform.md\`. Review example OPA/Rego policies if available.
    *   **Goal:** Grasp Zero-Trust, Reputation-as-Capital, Passkeys/DIDs, IAP integration, and how IONWALL mediates requests.

2.  **Local IONWALL Mock/Dev Instance:**
    *   **Action:** The IONVERSE \`docker-compose.yml\` should include a minimal OPA instance and potentially mock services for Identity/Reputation for local development of other apps. For IONWALL core devs, a more complete local setup is needed.
    *   Run \`docker-compose up opa mock-identity-svc mock-reputation-svc\`.
    *   Explore the OPA HTTP API (\`http://localhost:8181\`).
    *   **Goal:** Have a local environment to test policy evaluations and understand API interactions.

3.  **Write & Test a Simple Rego Policy:**
    *   **Action:** Create a basic Rego policy (e.g., \`allow_if_user_has_role_X.rego\`). Test it using the OPA CLI against sample input JSON data.
    *   \`opa eval --data your_policy.rego --input sample_input.json "data.your_package.allow"\`
    *   **Goal:** Get hands-on with Rego syntax and OPA evaluation.

4.  **Integrate IONWALL Check in a Mock Agent/Service (IAP Client):**
    *   **Action:** Create a simple Deno/Node.js script that simulates an agent making a request. Before performing its "action," have it make an HTTP IAP call (JSON-RPC \`message/send\` with \`skillId: "evaluatePolicyForAction"\`) to your local OPA/mock-IONWALL endpoint, sending relevant context as input.
    *   Based on the JSON-RPC response, decide whether to proceed.
    *   **Goal:** Understand how applications query IONWALL for policy decisions via IAP.

5.  **Explore Passkey/WebAuthn Integration (Client-Side):**
    *   **Action:** Use a library like \`@simplewebauthn/browser\` in a simple Next.js/React frontend to implement Passkey registration and login flows. The backend would interface with IONWALL's Identity Fabric services to store/verify credentials.
    *   **Goal:** Understand the client-side mechanics of passwordless authentication that IONWALL leverages.

6.  **Inspect NATS IAP \`PlatformEvent\`s for Reputation Engine:**
    *   **Action:** If local NATS is running and other ION apps are generating events, use \`nats-cli\` to subscribe to topics like \`ionwallet.transaction.completed\` or \`ionverse.moderation.strike_issued\`.
    *   Observe the structure of these \`PlatformEvent\`s, as they would be inputs to the Reputation Engine.
    *   **Goal:** Understand the data sources for reputation calculation via IAP.

7.  **Contribute to Policy Development (Conceptual):**
    *   **Action:** Identify a use case in an ION app (e.g., IONFLUX agent needs to access a sensitive IONPOD resource). Draft a Rego policy snippet that would govern this, considering user roles, reputation scores, and resource sensitivity.
    *   Propose this policy via the established GitOps workflow for policies.
    *   **Goal:** Understand the policy lifecycle and contribution process.

8.  **Review Audit Logs & Reputation Changes (Simulated):**
    *   **Action:** If a local ClickHouse instance and mock log generation are available, query the audit logs for specific decisions or reputation score changes.
    *   Understand how \`ionwall_consent_receipt_cid\` links back to specific user approvals.
    *   **Goal:** Appreciate the importance and structure of the immutable audit trail.

## 5. TECH — Stack & Justificativas (Rationale)

IONWALL's stack is chosen for security, performance, scalability, and policy expressiveness.

*   **Policy Engine (Open Policy Agent - OPA & Rego):**
    *   **Rationale:** CNCF graduated project, industry standard for policy enforcement. Rego is a powerful, declarative language specifically designed for policy. OPA is lightweight, fast, and can be deployed as a sidecar, library, or daemon. Allows for GitOps-driven policy management.
    *   **Trade-offs:** Rego has a learning curve. Managing complex policy sets requires discipline.
*   **Edge Gateway (Traefik + WASM Plugins - Rust/Go):**
    *   **Rationale:** Traefik is lightweight, cloud-native, and supports WASM for custom middleware. WASM allows for high-performance, sandboxed execution of custom logic (e.g., request inspection, preliminary auth checks) at the edge. Rust/Go for performance and safety in WASM module development.
    *   **Trade-offs:** Developing and managing custom WASM plugins adds complexity compared to built-in gateway features.
*   **Identity (FIDO2 Passkeys, DIDs - \`did:ionid\`, ERC-4337 via IONWALLET):**
    *   **Rationale:** Passkeys for phishing-resistant, passwordless UX. DIDs for decentralized, sovereign identity. ERC-4337 for linking web3 activity to this identity via smart contract wallets, enabling gas abstraction and social recovery.
    *   **Trade-offs:** Passkey adoption is still growing. DID/VC ecosystem is maturing. ERC-4337 adds smart contract risk and complexity.
*   **Reputation Data Ingestion (NATS JetStream for IAP \`PlatformEvent\`s):**
    *   **Rationale:** High-performance, persistent event streaming for decoupling reputation event sources from the Reputation Engine. Supports at-least-once delivery.
*   **Audit Log Store (ClickHouse OLAP Database):**
    *   **Rationale:** Optimized for high-volume ingestion and fast analytical queries on large datasets, perfect for audit logs and security analytics. Columnar storage is efficient for this use case.
    *   **Trade-offs:** Not a transactional database for OLTP workloads. Requires separate PostgreSQL for configuration/hot data.
*   **Primary Configuration Store (PostgreSQL 16):**
    *   **Rationale:** For storing IONWALL configurations, active policy set references, user consent linkage (hot data), and potentially cached reputation scores for very fast access by OPA.
*   **DevSecOps (GitOps - ArgoCD/Flux, HashiCorp Vault, Trivy/Snyk/SonarQube):**
    *   **Rationale:** GitOps for auditable, version-controlled deployment of policies and services. Vault for centralized, secure secret management. Integrated security scanning tools for a proactive DevSecOps posture.

## 6. FILES & PATHS (Key Locations)

Key IONWALL-specific files and directories within the \`ionverse_superhub\` monorepo:

*   **\`ionverse/services/ionwall_core/\`**: Main backend services for IONWALL.
    *   \`identity_fabric/\`: Services for Passkey auth, DID management, VC issuance/verification (exposing IAP skills).
    *   \`reputation_engine/\`: Logic for score calculation, event ingestion from NATS (consuming IAP \`PlatformEvent\`s), OPA integration (exposing IAP skills like \`getReputationScore\`).
    *   \`governance_engine/\`: OPA policy distribution, consent management service (exposing IAP skills like \`requestUserConsent\`).
    *   \`audit_service/\`: Service for writing to ClickHouse and anchoring to blockchain (may expose IAP skill \`logAuditEvent\`).
*   **\`ionverse/policies/ionwall_rego/\`**: Git repository (or submodule) containing all Rego policies.
    *   \`identity/\`, \`reputation/\`, \`access_control/\`, \`snetwork_global/\` subdirectories for policy organization.
*   **\`ionverse/edge_plugins/ionwall_traefik_wasm/\`**: Source code for custom WASM plugins for Traefik.
*   **\`ionverse/packages/ionwall_sdk/\`**: Client SDK (TypeScript) for internal ION apps to easily interact with IONWALL IAP skills or OPA decision points.
*   **\`ionverse/packages/types_schemas_ionwall/\`**: TypeScript types and Zod/JSON schemas for IONWALL API requests, responses, IAP \`PlatformEvent\` payloads it consumes/produces, and policy inputs.
*   **\`ionverse/infra/k8s/ionwall/\`**: Kubernetes manifests / Helm chart for deploying IONWALL services.
*   **\`ionverse/db/migrations/ionwall_postgres/\` & \`ionwall_clickhouse/\`**: Database schema migrations.

## 7. WHERE‑TO‑PLACE‑FILES (Conventions)

*   **New Rego Policies:** In the appropriate subdirectory under \`ionverse/policies/ionwall_rego/\`. Must include unit tests (\`_test.rego\` files).
*   **Identity Logic Extensions:** Within \`ionverse/services/ionwall_core/identity_fabric/\`.
*   **Reputation Algorithm Changes:** Modifications to services in \`ionverse/services/ionwall_core/reputation_engine/\` and corresponding Rego policies.
*   **WASM Plugin Code:** In \`ionverse/edge_plugins/\`.
*   **Shared Types/Schemas for IAP:** In \`ionverse/packages/types_schemas_ionwall/\` or a global IAP types package.
*   **Client Interaction Logic (if building a new ION app):** Use or extend the \`ionwall_sdk\` to call IONWALL's IAP skills.

## 8. DATA STORE — ERD (Entity Relationship Diagram - Prose for IONWALL)

IONWALL utilizes PostgreSQL for configuration and "hot" operational data, and ClickHouse for its immutable audit "Data Vault."

**PostgreSQL (\`ionwall_config_db\`):**
*   **\`users_identity_map\`**: \`user_did\` (PK), \`primary_passkey_credential_id\`, \`status\` (active, suspended), \`kyc_tier\`, \`created_at\`, \`ionwallet_erc4337_address_link\` (nullable). (Links DID to primary auth method and status).
*   **\`reputation_scores_live\`**: \`user_did\` (PK, FK), \`overall_score\`, \`score_fin\`, \`score_social\`, \`score_create\`, \`last_updated_at\`, \`version_of_calc_policy\`. (Cache of current scores for fast OPA access).
*   **\`active_policies_registry\`**: \`policy_id\` (PK), \`policy_name\`, \`rego_module_path_in_git\`, \`version_hash_from_git\`, \`status\` (active, deprecated), \`description_cid\`. (Registry of currently active OPA policies).
*   **\`consent_records_active\`**: \`consent_id\` (PK), \`user_did\`, \`requesting_agent_id_or_scope\`, \`granted_scopes_json_array\`, \`expires_at\` (nullable), \`consent_receipt_cid_ref\` (links to immutable proof in ClickHouse/IPFS). (For active, frequently checked consents).

**ClickHouse (\`ionwall_data_vault\` - All events are append-only):**
*   **\`audit_log_entries\`**: \`event_id\` (UUID), \`timestamp_usec_utc\`, \`event_type\` (e.g., "api_request_evaluated", "reputation_score_updated", "identity_verified", "iap_skill_invoked"), \`user_did_actor\`, \`user_did_target\` (if different), \`service_name_source\`, \`policy_ids_evaluated_array_string\`, \`decision_result\` (allow, deny, challenged), \`input_parameters_summary_json\`, \`context_tags_map_string_string\`. (The core immutable log).
*   **\`reputation_change_log\`**: \`log_id\` (UUID), \`timestamp_usec_utc\`, \`user_did\`, \`previous_score_overall\`, \`new_score_overall\`, \`contributing_event_ids_array_uuid\` (links to \`audit_log_entries\` or IAP \`PlatformEvent\` IDs), \`reason_code_or_description_cid\`.
*   **\`consent_interaction_log\`**: \`interaction_id\` (UUID, from \`IONWALL_ActionApproval_Transform\` or IAP \`requestUserConsent\` skill), \`timestamp_usec_utc\`, \`user_did\`, \`requesting_agent_name\`, \`action_description_text_hash\`, \`action_details_cid_if_any\`, \`scopes_requested_array_string\`, \`user_decision\` (approved, denied, timed_out), \`user_comment_if_any\`, \`consent_receipt_cid\` (this CID is the proof).

**Relationships:**
*   \`users_identity_map\` is central. \`reputation_scores_live\` and \`consent_records_active\` link to it via \`user_did\`.
*   All ClickHouse tables are primarily event streams, but \`user_did\` allows them to be correlated. \`consent_receipt_cid\` from PostgreSQL links to the detailed interaction in ClickHouse.
*   OPA policies (\`active_policies_registry\`) use data from \`users_identity_map\` and \`reputation_scores_live\` as part of their input context for decisions.

## 9. SCHEDULING (Cron Jobs & Scheduled Tasks for IONWALL)

IONWALL relies on scheduled tasks (managed by Chronos Agent via IONFLUX) for several key background processes:

*   **Reputation Score Recalculation (Batch):**
    *   **Purpose:** Periodically (e.g., hourly or daily) re-calculate and update reputation scores for all active users, or for users with recent activity. This batch process aggregates new events from NATS (mirrored to ClickHouse/Postgres event store) that occurred since the last calculation.
    *   **Mechanism:** Chronos triggers an IONFLUX flow that queries recent events, runs the main Reputation Scoring Rego policy (or a dedicated scoring service) for affected users, and updates \`reputation_scores_live\` in PostgreSQL.
*   **Blockchain Anchoring Service Trigger:**
    *   **Purpose:** Regularly (e.g., every few hours) take the Merkle root of new \`audit_log_entries\` from ClickHouse and commit this root to a smart contract on Base L2.
    *   **Mechanism:** Chronos triggers an IONFLUX flow that invokes the Blockchain Anchoring Service component of IONWALL.
*   **Stale Consent/Session Pruning:**
    *   **Purpose:** Clean up expired session tokens or temporary consent grants from \`consent_records_active\` that have passed their \`expires_at\` time.
    *   **Mechanism:** Scheduled task queries for expired records and removes/archives them.
*   **Policy Cache Refresh for OPA Instances:**
    *   **Purpose:** Ensure all distributed OPA instances have the latest active policies from the Git-managed Policy Store, especially if a push-based update from GitOps fails or as a fallback.
    *   **Mechanism:** Scheduled task triggers OPA instances to poll their configured policy distribution point.
*   **Report Generation (Compliance, Security):**
    *   **Purpose:** Generate periodic compliance reports (e.g., summary of access denials, policy exception rates) or security incident summaries from the ClickHouse Data Vault.
    *   **Mechanism:** Chronos triggers specific IONFLUX flows that query ClickHouse and format reports (e.g., as Markdown/PDF stored in IONPOD).

## 10. FUTURE EXPANSION (Elaborated Points)

IONWALL is designed to evolve into an increasingly intelligent and adaptive security and reputation fabric:

*   **10.1. AI-Driven Predictive Threat Intelligence & Proactive Policy Adjustment:**
    *   Integrate ML models (trained on IONWALL's Data Vault and potentially federated threat feeds) directly into the policy evaluation loop. These models would predict the risk score of an incoming request in real-time, augmenting OPA's rule-based decisions.
    *   Allow IONWALL to suggest or even autonomously (with high-level consent) deploy temporary "emergency" OPA policies in response to novel attack patterns detected by its ML systems, buying time for human review and permanent policy updates.
*   **10.2. Decentralized Reputation Oracles & Cross-sNetwork Attestations:**
    *   Develop a standardized protocol for other sNetworks or external applications to query an Avatar's IONWALL reputation (with user consent) via decentralized oracles.
    *   Enable users to import reputation attestations from other compatible systems into their IONWALL score (after validation), and export their IONWALL reputation components as VCs for use elsewhere. This creates a bridge for "reputation portability."
*   **10.3. ZK-Proofs for Privacy-Preserving Policy Evaluation & Reputation Claims:**
    *   Allow users to prove certain attributes or compliance with policies without revealing the underlying sensitive data. For example, proving "my KYC tier is Gold" or "my financial score is >700" using a Zero-Knowledge Proof, which IONWALL's OPA engine can then verify as part of its input, instead of needing direct access to the raw data.
*   **10.4. User-Defined Programmable Consent & Data Usage Policies (via IONPOD):**
    *   Empower users with a simple UI in IONPOD to define their own granular data access and usage policies (e.g., "Allow Agent X to read my health data only between 9-5 on weekdays, only for purpose Y, and log all accesses").
    *   IONWALL would fetch and enforce these user-specific policies in conjunction with sNetwork-level and agent-specific policies, giving users ultimate control.
*   **10.5. "Reputation Staking" & Conditional Access Based on Economic Bonds:**
    *   Allow users or agents to "stake" ION tokens as a bond to gain access to certain high-value resources or perform sensitive operations. Misbehavior would result in slashing of the staked bond.
    *   IONWALL would manage the rules for such reputation/economic staking, and the reputation engine would factor in the value and status of these bonds. This aligns economic incentives with trustworthy behavior.

## 11. SERVER BOOTSTRAP (Helm Chart's Role for IONWALL)

For deploying IONWALL's backend services (OPA, Identity Fabric services, Reputation Engine components, Audit Service, etc.) to a Kubernetes environment, a dedicated **Helm chart** (\`ionverse/charts/ionwall-services\`) is essential.

*   **Purpose:** The Helm chart automates the deployment, configuration, and management of all Kubernetes resources required for IONWALL's backend infrastructure. This includes:
    *   Deployments/StatefulSets for each microservice.
    *   Configuration for OPA instances (including how they load policies).
    *   Service definitions for internal and external communication.
    *   Ingress rules (if any specific to IONWALL internal APIs, though most traffic comes via main gateway).
    *   ConfigMaps for service configurations, connection strings to PostgreSQL/ClickHouse/NATS.
    *   Secrets for sensitive data like database credentials, NATS credentials for IONWALL services (managed via Sealed Secrets or a Vault injector).
    *   NetworkPolicies for restricting traffic flow between IONWALL components and other parts of the sNetwork.
*   **Benefits:** Same as for IONVERSE App (Reproducibility, Version Control of Infra, Simplified Deployments/Upgrades, Configurability via \`values.yaml\`). IONWALL's Helm chart would have specific values for tuning OPA performance, database connections, and security contexts for its pods.
*   **Process:** \`helm install ionwall-release ./ionverse/charts/ionwall-services -f values.production.yaml --namespace ion-system\`.

## 12. TASK TYPES (Common Operations Managed/Processed by IONWALL)

IONWALL itself processes specific types of internal "tasks" or handles requests that translate to these operations:

1.  **AuthenticateUser (\`did:ionid\`, Passkey):**
    *   **Description:** Verifies a user's Passkey credential against their registered DID, issues a session JWT.
    *   **Latency SLA (Target):** 50-200ms (depends on client-side WebAuthn ceremony and network).
2.  **EvaluateActionPolicy (OPA Evaluation / IAP Skill):**
    *   **Description:** Takes a request context (user DID, reputation, resource, action) and evaluates it against loaded Rego policies.
    *   **Latency SLA (Target):** 5-50ms (OPA is designed to be very fast; depends on policy complexity and data fetching for context).
3.  **UpdateReputationScore (Batch or Stream):**
    *   **Description:** Ingests reputation-affecting events (often IAP \`PlatformEvent\`s), recalculates a user's score based on defined formula.
    *   **Latency SLA (Target):** Variable. Real-time updates for critical events might be <1s; full batch recalculation might take minutes for many users but individual score updates should be fast once triggered.
4.  **RecordAuditEvent (to ClickHouse & Anchor / IAP Skill):**
    *   **Description:** Writes a detailed audit log entry to ClickHouse. Periodically, a batch of Merkle roots of these logs is anchored to L2.
    *   **Latency SLA (Target):** <50ms for ClickHouse write; anchoring is an asynchronous batch process.
5.  **IssueVerifiableCredential (e.g., for KYC Tier / IAP Skill):**
    *   **Description:** Generates and signs a VC for a user, making it available in their IONPOD.
    *   **Latency SLA (Target):** <500ms.
6.  **ProcessUserConsentRequest (via \`IONWALL_ActionApproval_Transform\` flow / IAP Skill):**
    *   **Description:** Receives request from transform/IAP call, presents to user via trusted UI, awaits response, records consent.
    *   **Latency SLA (Target):** User-dependent, but system timeout usually 60-300 seconds. IONWALL's own processing part <100ms.

## 13. APPLE & ANDROID PUBLISHING PLAYBOOK (Implications for Mobile Apps)

While IONWALL is primarily a backend service fabric, its functionality has significant implications for any IONVERSE mobile apps (like IONVERSE App, IONWALLET, IONPOD) that rely on it:

*   **Passkey Integration:** Mobile apps *must* correctly implement native Passkey APIs (e.g., \`ASAuthorizationController\` on iOS, Credential Manager API on Android) and securely communicate Passkey attestations to IONWALL's Identity Fabric for registration and authentication. This is a core part of the user login/auth UX.
*   **Secure Storage for Session Tokens:** After successful Passkey authentication via IONWALL, mobile apps receive a session JWT. This token must be stored securely on the device (e.g., iOS Keychain, Android Keystore).
*   **In-App Display of IONWALL Prompts:** When an \`IONWALL_ActionApproval_Transform\` is used by a mobile agent flow, or when IONWALL needs to step-up auth (or an IAP \`requestUserConsent\` skill is invoked), the mobile app must have a way to display these IONWALL-originated prompts securely. This could be via:
    *   A webview rendering a trusted IONWALL page.
    *   A native UI component that securely loads prompt content from IONWALL.
    *   Push notifications that deep-link into a specific IONWALL approval section of the app or a companion IONWALLET app.
*   **Privacy Manifests & Justifications (Apple):** Mobile apps must declare the types of data they collect and the reasons for that collection in privacy manifests. If IONWALL policies or monitoring lead to data collection that needs declaration (e.g., for security analytics, fraud prevention), this must be accurately reflected. API calls to IONWALL services (including IAP calls for policy checks or reputation) must be justified (e.g., "required reason API" usage).
*   **User Data Access & Control:** Mobile UIs should provide interfaces (likely within IONPOD sections) for users to view their reputation scores, review active consents managed by IONWALL, and initiate data access/erasure requests as per GDPR/LGPD, which IONWALL would process.
*   **Transparency:** Clearly explain to users how IONWALL uses their data for reputation and security, and how they can control permissions. This is vital for app store approval.

## 14. SECURITY & COMPLIANCE (Expanded Measures for IONWALL itself)

IONWALL is the security backbone; its own protection is paramount.

*   **Service Hardening:** All IONWALL microservices run with minimal privileges, in hardened containers, on patched OS, with network segmentation (strict NetworkPolicies in Kubernetes).
*   **API Security (Internal & External via IAP):** All IONWALL APIs (including IAP skill endpoints) use mTLS for service-to-service authentication. External-facing APIs are protected by the Edge Gateway. Strict input validation on all APIs.
*   **OPA Policy Security:** Rego policies are linted, tested (unit tests with \`opa test\`), and code-reviewed before deployment via GitOps. Access to the policy Git repository is tightly controlled. Consider signing policy bundles.
*   **Data Vault Integrity:** ClickHouse audit logs are append-only. Access controls on ClickHouse are extremely strict. Blockchain anchoring of Merkle roots ensures public verifiability of log integrity against tampering.
*   **Credential Management for IONWALL Services:** Database passwords, NATS credentials, API keys for external services (like KYC providers) used by IONWALL itself are stored in HashiCorp Vault and accessed with short-lived leases by services.
*   **Insider Threat Mitigation:** Segregation of duties for IONWALL administrators and developers. Multi-party approval for critical policy changes or infrastructure modifications (Hybrid Layer governance).
*   **Regular Audits & Pen-Tests:** IONWALL's codebase, infrastructure, and policies are subject to frequent internal and external security audits and penetration tests.
*   **Compliance Certifications (Goal):** Aim for relevant certifications over time (e.g., SOC 2, ISO 27001) for IONWALL's operational processes.

## 15. TOKENOMICS (IONWALL's Role & Reputation as Economic Modifier)

IONWALL itself does not have its own distinct token. Instead, it plays a crucial role within the broader **ION token ecosystem** by making **reputation a significant economic modifier**. The $ION token (on Base L2) and C-ION credits are the primary economic units.

*   **Reputation Affects Costs & Access:**
    *   **Reduced C-ION Costs:** Users with higher IONWALL reputation scores (e.g., \`Score.Overall\` or specific sub-scores like \`Score.ComputeEfficiency\`) may receive preferential rates when converting ION to C-ION, or pay slightly less C-ION for certain IONFLUX agent executions. This incentivizes positive platform behavior.
    *   **Lower Platform Fees:** IONWALL reputation can influence fees on the IONVERSE Marketplace or transaction fees within certain IONWALLET services. High-reputation users might see a 0.1-0.5% reduction, for example.
    *   **Access to Premium Features/APIs:** Certain advanced IONFLUX agents, IONVERSE Shards, or IONPOD AI Twin capabilities might require a minimum reputation score, effectively making reputation a key to unlock value. These checks are done via IAP calls to IONWALL.
    *   **DeFi Benefits (Future):** In future DeFi protocols integrated via IONWALLET, higher \`Score.Fin\` (financial reputation) from IONWALL could lead to better loan-to-value ratios, lower collateral requirements, or access to undercollateralized lending pools.
*   **Staking & Reputation:** Staking ION tokens (via IONWALLET) can be a positive factor in the reputation calculation, signifying commitment to the ecosystem. Conversely, early unstaking penalties or irresponsible governance voting could negatively impact reputation.
*   **Reputation Attestations On-Chain:** While the full score calculation is complex and off-chain (with results cached in PostgreSQL), key reputation milestones or attestations can be written to Base L2 by IONWALL (e.g., "DID X achieved 'Trusted Creator' status"). These on-chain attestations can then be used by other smart contracts or dApps to grant permissions or benefits.
*   **No Direct "Reputation Token":** Reputation is an attribute of the user's DID, not a directly tradable token. This prevents purely financial speculation on reputation scores themselves, keeping the focus on genuine behavior and contribution. However, the *benefits* of high reputation (lower fees, better access) are economically tangible.
*   **IONWALL Service Costs:** The operational costs of running IONWALL's infrastructure (OPA evaluations, ClickHouse storage, etc.) are covered by the overall IONVERSE platform revenue streams (e.g., a small portion of marketplace fees, IONFLUX execution fees, or treasury allocations), ensuring it remains a well-maintained core utility.

IONWALL's role is to make good behavior economically advantageous and risky behavior economically disadvantageous, directly tying trust into the utility and velocity of the ION token.

## 16. METRICS & OKRs (Significance for IONWALL)

IONWALL's success is measured by its ability to foster trust, enhance security, and enable fair value exchange.

*   **Security & Trust Metrics:**
    *   **Policy Violation Rate:** Number of detected vs. actual (post-incident review) policy violations. Aim for low actual violations and effective detection.
    *   **Mean Time to Detect (MTTD) & Mean Time to Respond (MTTR) to Security Incidents:** How quickly IONWALL (and associated Guardian agents/Hybrid Layer) identify and react to threats.
    *   **Reputation Score Accuracy & Predictiveness:** Correlation between reputation scores and positive/negative user outcomes (e.g., do high-rep users truly cause fewer issues?). Requires ongoing model validation.
    *   **User Trust Score (Survey-based):** Periodic surveys to gauge user perception of IONWALL's fairness and effectiveness.
    *   **False Positive/Negative Rate for OPA Policies:** Minimizing incorrect blocks or missed detections.
    *   **IAP Request Success/Failure Rate for IONWALL Skills.**
*   **Performance & Scalability Metrics:**
    *   **OPA Policy Evaluation Latency (P95, P99):** Must be extremely low to not impede user experience.
    *   **Reputation Score Update Latency:** Time from a reputation-impacting event to score update.
    *   **Audit Log Ingestion Rate & Query Performance (ClickHouse).**
    *   **Throughput of Authentications / Authorizations per second (including IAP calls).**
*   **Ecosystem Impact Metrics:**
    *   **Correlation of High Reputation with Positive Economic Activity:** Demonstrating that higher IONWALL reputation scores lead to increased positive GMV for those users in IONVERSE/IONFLUX.
    *   **Reduction in Fraudulent Activity / Scams:** Measurable decrease in incidents reported by users or detected by other systems.
    *   **Adoption of Passkeys & DIDs:** Percentage of active users utilizing these core identity features.

**OKRs (Objectives and Key Results) for IONWALL will focus on:**
*   **Objective:** Enhance Predictive Security Capabilities.
    *   **KR1:** Implement 2 new ML models for anomaly detection in Q1.
    *   **KR2:** Reduce false positive rate in critical access policies by 10% in Q1.
*   **Objective:** Increase User Trust & Transparency.
    *   **KR1:** Launch V1 of user-facing "My Reputation Dashboard" in IONPOD in Q2.
    *   **KR2:** Publish a clear "Guide to IONWALL Reputation Scoring" in Q2.

## 17. ROADMAP (Descriptive Milestones for IONWALL)

*   **Phase 0: Core Design (Completed)**
    *   Specification of core components (Identity, Reputation, OPA-based Governance, Audit Vault).
    *   Technology selection and architectural blueprints. IAP integration points defined.
*   **Phase 1: MVP - Identity & Basic Access Control (Target: Q3-Q4 2024, aligns with IONVERSE MVP)**
    *   **Focus:** Implement Passkey/DID authentication. Basic OPA policy evaluation for core IONVERSE/IONFLUX API access. Initial reputation score calculation (KYC tier + activity flags). Secure audit logging to ClickHouse with manual blockchain anchoring. Basic IAP skills for auth and policy check exposed.
    *   **Milestones:**
        *   Passkey login for IONVERSE apps.
        *   IONID issuance/resolution PoC.
        *   OPA deployed, evaluating 5-10 critical access policies via direct checks and IAP.
        *   V1 Reputation Engine: scores based on KYC & on-chain transaction count (Base L2).
        *   Basic \`IONWALL_ActionApproval_Transform\` functional for high-value actions, using IAP \`requestUserConsent\` skill.
*   **Phase 2: Reputation Engine v2 & Policy Expansion (Target: Q1-Q2 2025)**
    *   **Focus:** Expand inputs to Reputation Engine (social graph data, content creation metrics, IONFLUX flow success via IAP events). More granular Rego policies. Automated blockchain anchoring of audit logs. Full suite of read-only IAP skills for reputation and policy.
    *   **Milestones:**
        *   Reputation scores incorporate data from at least 3 ION apps via NATS IAP \`PlatformEvent\`s.
        *   User-facing display of basic reputation score and contributing factors (in IONPOD).
        *   GitOps pipeline for policy management fully operational.
        *   Automated Merkle root anchoring of ClickHouse logs to Base L2.
*   **Phase 3: Advanced Security & AI Integration (Target: Q3 2025)**
    *   **Focus:** Implement AI-driven threat detection heuristics at Edge Gateway. Introduce ZK-proof capabilities for privacy-preserving claims via IAP. More sophisticated gamification of security. IAP skills for VC issuance.
    *   **Milestones:**
        *   WASM plugins at Edge Gateway using basic ML models for request filtering.
        *   PoC for ZK-proof based VC verification via IAP skill.
        *   "Trust Aura" visualization in IONVERSE reflects reputation changes in near real-time.
*   **Phase 4: Decentralized Governance of Policies & Cross-sNetwork Reputation (Target: Q4 2025 onwards)**
    *   **Focus:** Transitioning parts of policy definition and reputation model weighting to DAO-based governance. Developing standards for cross-sNetwork reputation exchange using IAP and VCs.
    *   **Milestones:**
        *   First set of IONWALL parameters (e.g., certain fee modifiers based on reputation) managed by ION DAO.
        *   Pilot program for federated reputation with one external partner ecosystem using IAP-compatible VCs.

## 18. GOVERNANCE & AUDIT TRAIL (Elaborated)

*   **Policy Governance:**
    *   **Core sNetwork Policies:** Defined by the founding IONVERSE team/DAO, versioned in a secure Git repository, deployed via GitOps (e.g., ArgoCD/Flux) to OPA instances. Changes require rigorous review, testing (static analysis of Rego, scenario simulation), and potentially multi-sig approval for deployment.
    *   **User-Defined Policies (Future):** Users may define specific policies for their own IONPOD data or agents via a simplified interface, which are then compiled into Rego and layered with core policies. IONWALL ensures user policies cannot override fundamental security or sNetwork stability rules.
    *   **DAO Veto/Proposal Power:** The ION DAO will have the power to propose changes to core policies and, in critical cases, veto harmful policy updates.
*   **Audit Trail Imperatives:**
    *   **Comprehensive Logging:** Every significant event related to IONWALL's operation is logged:
        *   Authentication success/failure (Passkey, DID).
        *   API request received by Edge Gateway (including IAP calls).
        *   OPA policy evaluation (input, policy matched, decision, output).
        *   Reputation score calculation inputs and outputs.
        *   Consent granted/denied via \`IONWALL_ActionApproval_Transform\` or IAP \`requestUserConsent\` skill (including a hash of the \`action_description_text\`).
        *   Administrative changes to policies or IONWALL configuration.
    *   **Immutability & Verifiability:** Logs are written to ClickHouse (optimized for append-only). Merkle roots of log batches are anchored to Base L2 blockchain, making the audit trail tamper-evident and publicly verifiable without exposing raw log content. Users can verify that their specific log entries are part of an anchored batch using Merkle proofs.
    *   **Accessibility (Controlled):** Users have access to their own audit log data via IONPOD (e.g., "View my recent access history," "Show all consents I've granted"). System administrators and (with proper authorization) Hybrid Layer compliance officers can access broader logs for security analysis or dispute resolution.

## 19. OBSERVABILITY & INCIDENT RESPONSE (Operational Aspects, distinct from 3.6)

While section 3.6 (Observability Mesh) details the *tools* (Prometheus, Grafana, Loki, Tempo), this section focuses on the *operational processes* built around them for IONWALL.

*   **Real-time Dashboards & Alerting:**
    *   **Security Operations Dashboard (Grafana):** Displays critical IONWALL metrics: policy violation rates, authentication failures, suspicious API traffic patterns (including IAP call anomalies), OPA performance, reputation score anomalies, health of KYC provider integrations.
    *   **Automated Alerts (Alertmanager → Multiple Channels):**
        *   **Critical Alerts (PagerDuty/OpsGenie for Hybrid Layer SecOps Team):** Sustained high rate of auth failures, OPA policy evaluation errors, Edge Gateway under attack, potential breach indicators from ML models, critical IAP endpoint failures.
        *   **Warning Alerts (Secure Chat Channel for SecOps/Devs):** Unusual spikes in specific policy denials, performance degradation in a specific IONWALL service, nearing capacity limits for ClickHouse/PostgreSQL.
        *   **Info Alerts (NATS topics for other agents like Guardian):** Specific non-critical but notable policy hits, reputation score reaching certain thresholds for specific users (published as IAP \`PlatformEvent\`s).
*   **Incident Response Playbooks:**
    *   Predefined playbooks for common security incidents (e.g., "Compromised Agent Detected," "DDoS Attack on Edge Gateway," "Sudden Mass Reputation Drop," "KYC Provider Outage," "Anomalous IAP Activity Spike").
    *   Playbooks detail steps for containment, investigation, eradication, recovery, and post-mortem. May involve automated actions by ION Reactor (triggered by IONWALL alerts) or manual intervention by Hybrid Layer.
*   **Log Analysis & Threat Hunting:**
    *   Regular (automated and manual) analysis of ClickHouse audit logs and Loki application logs to proactively hunt for emerging threats, policy bypass attempts, or unusual behavior not caught by automated alerts. IONFLUX itself can be used to build flows for this analysis, leveraging IONWALL's IAP skills for data.
*   **Post-Mortem & Learning:**
    *   After any significant security incident or major policy failure, a blameless post-mortem is conducted.
    *   Findings are used to update OPA policies, improve monitoring/alerting rules, refine reputation algorithms, and enhance security training for developers/users. This feeds back into the "Evolve" stage of IONWALL's value loop.
*   **User-Reported Incidents:** Mechanisms for users to report suspicious activity or apparent IONWALL errors directly (e.g., via IONPOD helpdesk feature, which routes to Hybrid Layer). These are triaged and fed into the incident response process.

IONWALL's observability and incident response are not just about system health; they are integral to maintaining the trustworthiness and perceived fairness of the entire IONVERSE reputation and security model, including all IAP interactions it governs.
