# IONWALLET: The Sovereign Financial Heart

> *“IONWALLET: o cofre soberano onde ION, Drex e reputação convergem, elevando cada clique a um ato de liberdade financeira.”*

## 0. EXECUTIVE LEDGER (The Pulse of Value)

The IONWALLET is the financial core of the ION Super-Hub, meticulously designed to empower users with **uncompromising sovereign control** over their digital assets while ensuring seamless, intuitive, and frictionless financial operations. It’s not just a wallet; it's a **personal financial command center** where the digital economy of the IONVERSE meets real-world value.

IONWALLET masterfully combines:
*   **True Sovereign Custody:** For a diverse range of assets including the primary **ION** utility token, the **IONW** (IONWALLET-specific governance/staking token), **C-ION** (compute credits), tokenized **Drex** (Brazilian CBDC), various stablecoins (e.g., USDC, USDT), and unique digital collectibles (NFTs).
*   **Reputation-Enhanced Finance:** Deeply integrated with IONWALL, where a user's financial conduct (`Score.Fin`) directly impacts transaction capabilities, fees, and access to premium DeFi features. This makes responsible financial behavior a quantifiable and rewarding asset.
*   **Frictionless User Experience:** Offering features like instant cross-currency swaps, automated staking mechanisms, intuitive fiat on/off-ramps (especially Pix for BRL), and one-click payments within the IONVERSE.

Built with cutting-edge technologies including **Passkeys (FIDO2/WebAuthn)** for unparalleled access security, **Account Abstraction (ERC-4337)** for flexible and recoverable smart contract wallets, and a robust, audited bridge to the **Hyperledger Besu-based Drex network**, IONWALLET delivers a sophisticated yet profoundly user-friendly financial experience. All this is wrapped in the signature ION "neon-mystic" UX, designed to meet and exceed the stringent guidelines of Apple and Google app stores for 2025 and beyond, ensuring accessibility and compliance on both mobile (React Native + Expo EAS) and web (Next.js PWA) platforms. It’s where **“cada clique vira um ato de liberdade financeira.”**

## 1. ROLE — Propósito Existencial (Existential Purpose)

IONWALLET serves several key purposes within the ION ecosystem, acting as the user's primary interface for all value-related interactions:

*   **1.1. Hybrid & Sovereign Custody Solution:**
    *   Provides a primary **local, on-device vault** using SQLCipher (for mobile) or browser's IndexedDB with SubtleCrypto (for web PWA, keys managed by Passkeys) for user-controlled private key storage and sensitive preference management. This is the default for maximum sovereignty.
    *   Offers optional, user-initiated fallback to **Multi-Party Computation (MPC) / Social Recovery cloud solutions** for enhanced key recovery options, balancing sovereignty with usability for different user segments. This is not default but an opt-in feature.
    *   Manages keys for interacting with Base L2 (for ION, IONW, NFTs) and the permissioned Drex sidechain.

*   **1.2. Drex-ION Bridge & Atomic Swaps Engine:**
    *   Facilitates seamless, near-instant, and low-cost **atomic (or near-atomic) swaps** between the Layer-2 ION token, stablecoins (like USDC on Base), and the tokenized Brazilian CBDC (Drex) via a dedicated, audited bridge to a permissioned Hyperledger Besu sidechain.
    *   Aims to provide real-world financial utility by connecting the digital economy of IONVERSE with traditional fiat systems.

*   **1.3. Financial Reputation & Activity Hub (Interface to IONWALL `Score.Fin`):**
    *   All significant financial actions within IONWALLET (transactions, staking, loan repayments, successful trades) generate events that are fed to IONWALL's Reputation Engine.
    *   A user's aggregated financial conduct contributes significantly to their overall `Score.Fin` (Financial Reputation Score) within IONWALL.
    *   This `Score.Fin` is visibly displayed (as a component of their "Trust Aura") and directly influences:
        *   Potential reductions in gas fees or platform transaction fees (subsidized by treasury for high-rep users).
        *   Access to higher transaction limits (e.g., for Drex ↔ ION swaps).
        *   Eligibility for premium DeFi features (e.g., undercollateralized loans, exclusive staking pools) within IONWALLET or integrated third-party protocols.

*   **1.4. ION & IONW Rewards & Staking Motor:**
    *   Features an intuitive, auto-compounding **staking mechanism for both ION tokens (platform-wide utility) and IONW tokens (IONWALLET-specific benefits)**.
    *   Includes an Automated Market Maker (AMM) vault (e.g., a custom Balancer V2 style pool or integration with existing Base L2 DEXs) for ION-Drex, ION-USDC, and potentially IONW-ION liquidity provision, offering yield opportunities through swap fees and liquidity mining rewards.

*   **1.5. Universal Payment Gateway (`IONPay`):**
    *   Provides a universal payment widget/SDK (`IONPay`) for seamless in-app purchases and service payments across all IONVERSE applications (IONVERSE App, IONFLUX, IONPOD) using ION, C-ION, Drex, or other supported tokens. Agents can *propose* `IONPay` transactions via the IONVERSE Agent Protocol (IAP), which are then presented to the user within IONWALLET for final, secure approval.
    *   Designed for compliance with Apple's and Google's fiscal requirements for in-app transactions, potentially by routing fiat-equivalent purchases through their IAP systems if for purely digital consumables, while allowing direct crypto for true asset ownership or P2P trades.
    *   Integrates with Apple Pay and Google Wallet for streamlined fiat payments that can be converted to digital assets on the backend.

*   **1.6. Instant Fiat On-Ramp & Off-Ramp (Focus on Brazil - Pix):**
    *   Supports direct fiat deposits (on-ramp) primarily via **Pix** (Brazil's instant payment system) for BRL, converting to tokenized Drex or directly to ION/stablecoins.
    *   Integrates with global providers like Stripe or Ramp Network for credit/debit card on-ramping into stablecoins.
    *   Aims to provide compliant and efficient fiat off-ramping (Drex to BRL via Pix) as regulations and partnerships allow.

## 2. WHAT IT DOES — Loop de Valor (The Value Loop: Deposit → Stake/Use → Earn/Transact → Manage → Grow)

The IONWALLET user experience is built around a continuous cycle of value creation, utilization, and financial empowerment:

1.  **Deposit & Acquire (Funding the Wallet):**
    *   Users transfer fiat (e.g., BRL via Pix) which is seamlessly converted to tokenized Drex or a stablecoin like USDC on Base L2.
    *   Alternatively, users can deposit existing crypto assets (ION, ETH, USDC, etc.) from external wallets to their IONWALLET (ERC-4337 smart account) address.
    *   All funding transactions are clearly logged with associated hashes and IONWALL attestations if applicable.

2.  **Stake & Use (Participating in the Economy):**
    *   **Staking:** Users can easily stake their ION tokens (for general ecosystem rewards and governance participation) and IONW tokens (for specific IONWALLET fee reductions or enhanced features) in designated staking contracts or AMM liquidity pools (e.g., ION-Drex, IONW-ION). Staking for IONW might offer a share of IONWALLET-specific fees.
    *   **Utility:** Use ION to pay for marketplace items in IONVERSE, C-ION (acquired by burning ION) to pay for IONFLUX agent tasks, or Drex for services with direct fiat equivalence.

3.  **Earn & Transact (Generating Returns & Exchanging Value):**
    *   **Earning:** Staking generates rewards (in ION, IONW, or underlying pool tokens). Providing liquidity to AMMs earns swap fees. Positive financial activity enhances `Score.Fin` via IONWALL, unlocking further economic benefits.
    *   **Transacting:** Send/receive supported tokens and NFTs. Perform atomic swaps between Drex, ION, and stablecoins. Pay for services using `IONPay`.

4.  **Manage & Secure (Controlling Your Assets):**
    *   View comprehensive asset balances and transaction history with clear visualizations.
    *   Manage IONWALLET security settings: Passkey management, connected DApps/Agents (via IONWALL consent records), recovery options (MPC enrollment, social recovery setup for ERC-4337).
    *   Review and approve/deny transaction or action proposals initiated by other IONFLUX agents or Agent 000 via IAP. These proposals are securely presented within the IONWALLET UI for final user consent before any execution involving user funds or keys.

5.  **Grow & Reinvest (Closing the Loop & Expanding Financial Horizons):**
    *   Earned rewards (ION, IONW) can be auto-compounded or manually re-staked to maximize yield.
    *   Increased `Score.Fin` unlocks access to more sophisticated DeFi opportunities or better terms.
    *   The wallet provides clear dashboards displaying real APY, portfolio performance, and financial health indicators, empowering users to make informed decisions.

**North-Star KPI:** The primary success metric is defined as **“Total Value Locked & Actively Managed (TVLAM) × User Financial Health Score Improvement (derived from Score.Fin velocity)”**, emphasizing both platform growth and tangible benefit to the user's financial sovereignty and well-being.

## 3. IMPLEMENTATION — Arquitetura em Camadas (Layered Architecture)

IONWALLET's architecture prioritizes security (Security by Design, STRIDE modeling), performance, cross-platform compatibility, and regulatory compliance awareness.

```mermaid
graph TD
    subgraph Client Layer (Mobile: React Native/Expo; Web: Next.js PWA)
        CLIENT_UI[UI Components: Tamagui/NativeBase]
        CLIENT_STATE[State Management: Zustand/Jotai]
        CLIENT_CRYPTO[Crypto Core: WalletCore SDK (WASM), Secure Enclave/Keystore via Native Modules, Passkey APIs]
        CLIENT_BLE[Ledger BLE Connector (Optional)]
        CLIENT_METAMASK_SNAP[MetaMask Snap (Web - Fallback)]
    end

    CLIENT_UI --> CLIENT_STATE;
    CLIENT_STATE --> CLIENT_CRYPTO;

    subgraph Middleware Layer (IONWALLET Backend Services)
        MW_HASURA[GraphQL API: Hasura (`ionwallet_*` schema)]
        MW_BRIDGE_DREX[Drex-ION Bridge Service (Rust/Axum)]
        MW_TX_ORCH[Transaction Orchestrator & Nonce Manager (Go/Node.js) - Processes IAP Proposals]
        MW_PAYMENT_GW[Payment Gateway Integrator (Stripe, Pix - for On/Off Ramps)]
        MW_NATS_PUBSUB[NATS Event Publisher/Subscriber (for IONWALL, IONFLUX - IAP PlatformEvents)]
    end

    CLIENT_CRYPTO --> MW_HASURA;
    CLIENT_CRYPTO --> MW_TX_ORCH;


    subgraph Data / Storage Layer
        DS_POSTGRES[PostgreSQL 16 (Off-chain Ledger: Accounts, TXs, Stakes, FX Rates)]
        DS_SQLCIPHER[Local Device Vault: SQLCipher (Encrypted Keys/Prefs - Mobile)]
        DS_BROWSER_CRYPTO[Browser SubtleCrypto/IndexedDB (Encrypted Keys/Prefs - Web via Passkey)]
        DS_IPFS[IPFS/IONPOD (Receipts, Proofs, Large Metadata)]
        DS_REDIS[Redis (Cache: Sessions, FX Rates, Pending TX States)]
    end

    MW_HASURA --> DS_POSTGRES;
    MW_TX_ORCH --> DS_POSTGRES;
    MW_TX_ORCH --> DS_REDIS;
    MW_BRIDGE_DREX --> DS_POSTGRES;
    CLIENT_CRYPTO --> DS_SQLCIPHER;
    CLIENT_CRYPTO --> DS_BROWSER_CRYPTO;

    subgraph Blockchain Bridges & L2s
        BB_BASE_L2[Base L2 (ION, IONW, NFTs, ERC-4337 Accounts)]
        BB_DREX_SIDECHAIN[Hyperledger Besu Sidechain (Tokenized Drex)]
        BB_ORACLES[Oracles (Chainlink/Pyth for FX Rates, Asset Prices)]
    end

    MW_TX_ORCH --> BB_BASE_L2;
    MW_BRIDGE_DREX --> BB_DREX_SIDECHAIN;
    MW_BRIDGE_DREX --> BB_BASE_L2;
    MW_PAYMENT_GW --> BB_DREX_SIDECHAIN;
    MW_PAYMENT_GW --> BB_BASE_L2;


    subgraph DevOps & Observability
        DEVOPS_CI_CD[CI/CD: GitHub Actions, EAS Build, Docker]
        DEVOPS_IAC[IaC: Terraform/Helm]
        DEVOPS_MONITOR[Monitoring: Grafana, Prometheus, Loki, OpenTelemetry]
    end

    IONWALL_SVC[IONWALL (External Service for AuthN/AuthZ, Reputation, KYC)]
    CLIENT_CRYPTO --> IONWALL_SVC;
    MW_TX_ORCH --> IONWALL_SVC;

    style CLIENT_UI fill:#cde,stroke:#333
    style CLIENT_STATE fill:#cde,stroke:#333
    style CLIENT_CRYPTO fill:#cde,stroke:#333
    style CLIENT_BLE fill:#cde,stroke:#333
    style CLIENT_METAMASK_SNAP fill:#cde,stroke:#333

    style MW_HASURA fill:#dcf,stroke:#333
    style MW_BRIDGE_DREX fill:#dcf,stroke:#333
    style MW_TX_ORCH fill:#dcf,stroke:#333
    style MW_PAYMENT_GW fill:#dcf,stroke:#333
    style MW_NATS_PUBSUB fill:#dcf,stroke:#333

    style DS_POSTGRES fill:#edc,stroke:#333
    style DS_SQLCIPHER fill:#edc,stroke:#333
    style DS_BROWSER_CRYPTO fill:#edc,stroke:#333
    style DS_IPFS fill:#edc,stroke:#333
    style DS_REDIS fill:#edc,stroke:#333

    style BB_BASE_L2 fill:#fde,stroke:#333
    style BB_DREX_SIDECHAIN fill:#fde,stroke:#333
    style BB_ORACLES fill:#fde,stroke:#333

    style DEVOPS_CI_CD fill:#efd,stroke:#333
    style DEVOPS_IAC fill:#efd,stroke:#333
    style DEVOPS_MONITOR fill:#efd,stroke:#333

    style IONWALL_SVC fill:#ddd,stroke:#333,stroke-width:2px
```

### 3.1 Client Layer (The User's Command Deck)
*   **Mobile Application (iOS/Android):**
    *   **Framework:** React Native with Expo (EAS for simplified builds and over-the-air updates).
    *   **Engine:** Hermes JavaScript engine for optimized performance.
    *   **UI:** Tamagui (preferred for performance and themeability) or NativeBase for cross-platform UI components, styled with the ION "neon-mystic" aesthetic.
    *   **Secure Storage:** Native Secure Enclave (iOS) / StrongBox Keystore (Android) accessed via React Native modules for storing sensitive parts of Passkey credentials or derived symmetric keys. Local data encrypted with SQLCipher.
    *   **Biometric Authentication:** FaceID/TouchID integration for transaction signing and app unlock.
*   **Web Application (PWA):**
    *   **Framework:** Next.js 14+ (App Router) for a responsive, installable Progressive Web App.
    *   **UI:** Tamagui or ShadCN/UI with Tailwind CSS, matching mobile app's theme.
    *   **Alternative Wallet Connection:** MetaMask Snap integration to allow users to manage IONWALLET assets via their existing MetaMask, if they prefer not to use the embedded Passkey solution for web.
*   **Passkey Integration (FIDO2/WebAuthn):**
    *   Native platform APIs on mobile (`ASAuthorizationController` on iOS, Credential Manager on Android).
    *   Browser WebAuthn APIs for PWA, coordinated with IONWALL for registration and authentication ceremonies. Credentials ideally stored on device or synced via user's iCloud Keychain/Google Password Manager.
*   **Cryptographic Core:**
    *   **WalletCore SDK (forked & customized):** A C++ cross-platform library (with JS bindings via WASM for web/React Native) for generating keys, constructing transactions for multiple blockchains (Base L2, Drex sidechain, others as needed), and signing. This ensures consistent crypto logic.
    *   **WASM Optimization:** WASM build of WalletCore optimized for size and speed.
*   **Hardware Wallet Support (Optional):**
    *   Ledger BLE connector (or WebHID for web) allowing users to approve transactions using their Ledger hardware devices for ultimate key security.

### 3.2 Middleware Layer (The Secure Transaction Engine)
*   **GraphQL API (Hasura):**
    *   Provides the primary API for clients. Schema `ionwallet_*` includes queries/mutations for: `accounts` (balances, types), `transactions` (history, status), `pending_actions` (awaiting IONWALLET UI approval), `fx_rates`, `kyc_tiers` (read-only from IONWALL data), `staking_positions`, `reward_claims`.
    *   Permissions integrated with IONWALL JWTs and user reputation scores.
*   **Drex-ION Bridge Service (Rust/Axum):**
    *   A dedicated microservice for handling atomic (or near-atomic via HTLC-like mechanisms) swaps between tokenized Drex on its Hyperledger Besu sidechain and ION/USDC on Base L2.
    *   Manages liquidity, FX rate oracles, and transaction atomicity. Requires high security and auditability.
*   **Transaction Orchestrator & Nonce Manager (Go/Node.js):**
    *   Manages the lifecycle of transactions initiated by users directly or *proposed* by other agents via IAP (e.g., through the `Wallet Ops Agent`).
    *   Handles nonce management for ERC-4337 accounts on Base L2 to prevent replay attacks and ensure ordered transactions.
    *   Interfaces with Base L2 nodes (e.g., Infura, Alchemy, or self-hosted Erigon/Geth nodes) for transaction submission and status tracking.
    *   May incorporate a gas estimation service.
*   **Payment Gateway Integration Service (Stripe, Pix via PSPs):**
    *   Manages fiat on-ramps (Pix, credit/debit cards) and off-ramps (Pix).
    *   Securely handles communication with Payment Service Providers (PSPs).
    *   Coordinates with Drex-ION Bridge Service to convert fiat to/from digital assets.
*   **NATS Event Publisher/Subscriber:**
    *   Publishes IAP `PlatformEvent`s like `ionwallet.transaction.created`, `ionwallet.transaction.confirmed`, `ionwallet.transaction.failed`, `ionwallet.stake.initiated`, `ionwallet.reward.claimed` to NATS JetStream.
    *   Subscribes to relevant IAP `PlatformEvent`s from other ION apps (e.g., `ionwall.reputation.updated_for_user_X` if it needs to adjust user limits).

### 3.3 Data / Storage Layer (The Vault & Ledger)
*   **Primary Off-Chain Ledger (PostgreSQL 16):**
    *   Stores non-blockchain transaction metadata, user account details (linked to DID), staking positions, reward calculation data, FX rate history, KYC tier references (from IONWALL), user preferences.
    *   Partitioned by `user_did` or `wallet_id` for scalability. Uses JSONB for flexible metadata.
*   **Local Device Vault (Client-Side):**
    *   **Mobile:** SQLCipher for encrypted storage of cached private key components (if MPC is used for parts of the key), user settings, frequently used addresses, and pending transaction data for offline display. Encryption key derived from Passkey/biometric authentication.
    *   **Web (PWA):** Browser's IndexedDB with data encrypted via SubtleCrypto, with keys managed by or derived from Passkey credentials.
*   **Receipts & Proofs (IPFS via IONPOD):**
    *   Immutable transaction receipts, signed messages, staking proofs, or other important financial attestations are stored as objects on IPFS via IONPOD, with CIDs linked in the PostgreSQL ledger. Ensures verifiability and user ownership of their records.
*   **Cache (Redis 6 / DragonflyDB):**
    *   Caches WebSocket sessions for real-time updates, current FX rates from oracles, pending transaction states before on-chain confirmation, and frequently accessed account balances to reduce DB load.

### 3.4 Blockchain Bridges & L2 Interaction (The Multi-Chain Connectome)
*   **Base L2 (Primary sNetwork Chain):**
    *   Hosts the **ION** (ERC-20 utility/governance) and **IONW** (ERC-20 IONWALLET specific) tokens.
    *   Hosts user **ERC-4337 Smart Contract Wallets** (entry point contract, paymaster for sponsored transactions, user-specific wallet contracts).
    *   Hosts **NFT contracts** (ERC-721, ERC-1155) for IONVERSE assets.
    *   Hosts **DeFi protocol contracts** (AMM, staking contracts for ION/IONW).
*   **Drex Sidechain (Hyperledger Besu - Permissioned):**
    *   Hosts the tokenized **Drex (Real Digital)**.
    *   The Drex-ION Bridge Service interacts with smart contracts on this chain and on Base L2 to facilitate swaps. Requires a permissioned validator set and secure bridge oracles/relayers.
*   **Oracles (Chainlink/Pyth Network/RedStone):**
    *   Provide reliable FX rate feeds (e.g., BRL/USD, USD/ION, ETH/ION) for swap calculations.
    *   Provide price feeds for assets used in DeFi protocols or as collateral.
    *   May provide other relevant data like market volatility indexes.

### 3.5 DevOps & Observability (The Control & Monitoring Deck)
*   **CI/CD:** GitHub Actions for building clients (React Native/Expo EAS, Next.js), backend services (Docker images), smart contracts (Foundry/Hardhat). Automated testing (unit, integration, E2E with Playwright/Appium) and deployment to respective platforms (Expo EAS, Vercel/Cloudflare Pages, Kubernetes).
*   **Infrastructure as Code (IaC):** Terraform (or Pulumi) for provisioning and managing cloud infrastructure (Kubernetes clusters, managed databases, NATS clusters, monitoring stack). Helm charts for Kubernetes deployments.
*   **Observability:**
    *   **Metrics:** Prometheus for collecting metrics from all services (transaction throughput, error rates, API latencies, bridge volumes, staking APYs). Grafana for dashboards.
    *   **Logging:** Loki for centralized log aggregation.
    *   **Tracing:** OpenTelemetry for distributed tracing across microservices and blockchain interactions.
    *   **Alerting:** Alertmanager for critical alerts (e.g., bridge anomalies, high transaction failure rates, security events from IONWALL related to wallet activity).

## 3.bis. IONWALLET & The IONVERSE Agent Protocol (IAP)

IONWALLET, while primarily a user-facing application for direct interaction with their assets, also serves as a critical component within the IONVERSE Agent Protocol (IAP) ecosystem. It exposes certain functionalities and consumes events in a standardized way, enabling Agent 000 and other authorized IONFLUX agents to *propose* or *query* financial operations, always contingent on final user approval within the secure IONWALLET interface.

*   **IONWALLET as an IAP Service Provider (Conceptual Service Card):**
    *   IONWALLET's backend, particularly the Transaction Orchestrator, can be seen as exposing a conceptual "Service Card" or `AgentDefinition` to the IAP network (discoverable via a registry Agent 000 uses). This card would detail the "skills" IONWALLET offers for IAP interaction.
*   **Key IAP Skills/Endpoints Exposed by IONWALLET (via `Wallet Ops Agent` mediation):**
    *   **`skillId: "getWalletBalances"`**
        *   `params: { "userDid": "did:ionid:...", "tokenTypeArray": ["ION", "IONW", "DREX_Tokenized"] }`
        *   Returns current balances for specified tokens. Read-only, may require only general IONWALL consent for Wallet Ops Agent to access this info for the user.
    *   **`skillId: "getTransactionHistory"`**
        *   `params: { "userDid": "did:ionid:...", "filtersJson": { "limit": 10, "tokenType": "ION" } }`
        *   Returns a list of past transactions based on filters. Read-only, IONWALL consent.
    *   **`skillId: "proposeTokenTransfer"`**
        *   `params: { "requesterAgentDid": "did:ionflux:...", "fromUserDid": "did:ionid:user_abc", "toUserDidOrAddress": "0x123...", "tokenSymbol": "ION", "amountWei": "1000000000000000000", "purposeMetadataCid": "bafy..." }`
        *   **Output:** `{ "proposalId": "uuid_xyz", "status": "pending_user_approval_in_ionwallet" }`
        *   This IAP call *does not execute* the transfer. It stages a proposal that appears in the user's IONWALLET UI for explicit approval or rejection.
    *   **`skillId: "proposeStakingOperation"`**
        *   `params: { "requesterAgentDid": "did:ionflux:...", "userDid": "did:ionid:user_abc", "poolId": "ionw_main_pool", "amountWei": "500000000000000000000", "operationType": "stake" }`
        *   **Output:** `{ "proposalId": "uuid_abc", "status": "pending_user_approval_in_ionwallet" }`
        *   Similar to transfers, staking/unstaking actions are proposed and await user confirmation in IONWALLET.
    *   **`skillId: "getDrexBridgeStatus"`**
        *   `params: {}` (or specific query params if needed)
        *   Returns operational status of the Drex-ION bridge, current FX rates, and perhaps queue lengths. Read-only.
    *   **`skillId: "getEstimatedTxFee"`**
        *   `params: { "txDetailsJson": { "chain": "BaseL2", "token": "ION", "operation": "transfer", "estimatedGasUnits": "21000" } }`
        *   Returns an estimated transaction fee in ION/ETH for a proposed operation on Base L2.
*   **IONWALLET as IAP Event Consumer & Producer (NATS):**
    *   **Consumes `PlatformEvent`s:**
        *   `ionwall.reputation.score_fin_updated`: To potentially adjust user's transaction limits or display updated reputation context.
        *   `ionflux.payment_request_for_service`: A specific event from an IONFLUX agent requesting payment for a service, which IONWALLET translates into a `proposeTokenTransfer` scenario for user approval.
    *   **Produces `PlatformEvent`s:**
        *   `ionwallet.transaction.initiated_by_iap_proposal` (Payload: `{ proposalId, userDid, status: 'pending_user_approval' }`)
        *   `ionwallet.transaction.approved_by_user_via_iap` (Payload: `{ proposalId, userDid, chain_tx_hash }`)
        *   `ionwallet.transaction.rejected_by_user_via_iap` (Payload: `{ proposalId, userDid }`)
        *   `ionwallet.transaction.confirmed_on_chain` (Payload: `{ chain_tx_hash, status: 'success', block_number }`)
        *   `ionwallet.transaction.failed_on_chain` (Payload: `{ chain_tx_hash, status: 'failure', error_details }`)
*   **Critical Emphasis on User Approval in IONWALLET UI:**
    *   It is paramount that **no IAP call can directly execute a transaction, move funds, or sign data on behalf of the user.** Any IAP skill that proposes such an action (e.g., `proposeTokenTransfer`, `proposeStakingOperation`) *must* result in a request being queued for the user.
    *   The user **must then explicitly and unambiguously approve or reject this specific proposed action through the secure interface of their IONWALLET application (mobile or web PWA).** This approval step involves their Passkey authentication and is the ultimate point of consent.
    *   IONWALL policies will enforce that only IONWALLET itself (identified by its secure DID/credentials) can initiate the final signing and submission of transactions to the blockchain after receiving this direct user approval from its trusted UI. The `Wallet Ops Agent` is the designated IONFLUX agent that formats IAP requests *to* IONWALLET's proposal system.
*   **Further Details:** The specific schemas and nuances of these IAP interactions are further detailed in the main **[IONVERSE Agent Protocol (IAP) document](../specs/IONVERSE_AGENT_PROTOCOL.md)**.

## 4. HOW‑TO‑IMPLEMENT (Kickstart & Hands‑On for Developers)

1.  **Understand IONWALLET's Role & Security Model:**
    *   **Action:** Read this `README.md` thoroughly, focusing on Sections 0, 1, 2, 3.bis (IAP), and 14 (Security). Understand that IONWALLET is the user's sovereign space; other apps *request* actions, IONWALLET (with user approval) *performs* them.
    *   **Goal:** Internalize the security principles and the user-in-control paradigm, especially for IAP interactions.

2.  **Setup Local IONWALLET Environment:**
    *   **Action:** Clone `ionverse_superhub`. Follow `ionverse/ionwallet_app/DEVELOPMENT_SETUP.md` (to be created). This will involve running local PostgreSQL, Redis, NATS, Hasura (for `ionwallet_*` schema), and mock services for Drex bridge/payment gateways if not testing end-to-end.
    *   **Goal:** A functional local backend for IONWALLET.

3.  **Run IONWALLET Client (Web PWA First):**
    *   **Action:** `pnpm --filter @ionwallet/webapp dev`. Connect to your local backend.
    *   If Passkey setup is part of the initial flow, register a test Passkey (your OS/browser might prompt for this).
    *   **Goal:** See the basic wallet interface, even if balances are zero.

4.  **Fund with Testnet Assets:**
    *   **Action:** Use faucets for Base Sepolia (or other testnet) to get test ETH and then acquire test ION/IONW tokens (either via a faucet or a mock swap). For Drex, the local mock bridge service might have a "mint test Drex" function.
    *   **Goal:** Have assets to test transactions.

5.  **Perform Basic Operations via UI:**
    *   **Action:** Try to view balances, see transaction history (empty initially), send a small amount of test ION to another test account, attempt a mock swap between test ION and test Drex (if UI supports it).
    *   Observe IONWALL interaction prompts if they are simulated or if a local IONWALL mock is running.
    *   **Goal:** Understand the user flow for core wallet functions.

6.  **Simulate an IAP `proposeTokenTransfer` call (e.g., using `curl` or a test script):**
    *   **Action:** Manually construct a JSON-RPC message for the `proposeTokenTransfer` skill (as defined in 3.bis). Send it to the appropriate IONWALLET backend endpoint (likely exposed by the Transaction Orchestrator or API Gateway and IAP-enabled).
    *   Observe if a "pending approval" item appears in your IONWALLET UI (this requires the UI to poll or subscribe for such proposals). Attempt to approve it from the IONWALLET UI.
    *   **Goal:** Understand the IAP flow for agent-proposed transactions and the critical user approval step in IONWALLET.

7.  **Explore Smart Contract Interactions (Staking/Swaps):**
    *   **Action:** If staking or AMM features are implemented in the UI, try staking some test ION/IONW. Inspect the underlying smart contract calls being made (e.g., using a block explorer for Base Sepolia connected to your MetaMask if testing through Snap, or by examining logs from the Transaction Orchestrator).
    *   **Goal:** Understand how IONWALLET interacts with on-chain DeFi protocols.

8.  **Security Review (Focus on IAP & Consent):**
    *   **Action:** Consider how an IONFLUX agent might try to misuse an IAP call to IONWALLET (e.g., proposing a misleading transaction). How does the mandatory IONWALLET UI approval step, showing clear details of the *actual* proposed on-chain transaction, mitigate this?
    *   **Goal:** Appreciate the security layers of IAP + IONWALLET UI confirmation.

## 5. TECH — Stack & Justificativas (Rationale)

IONWALLET's technology choices are driven by the paramount needs for security, user sovereignty, cross-platform reach, and seamless integration with both traditional and decentralized financial systems.

*   **Client Frameworks (React Native/Expo & Next.js):**
    *   **Rationale:** As with IONVERSE App, for maximum code sharing and developer velocity across mobile and web. Native modules via React Native for secure enclave/hardware access. Next.js for robust PWA capabilities.
*   **Authentication (Passkeys - FIDO2/WebAuthn):**
    *   **Rationale:** Gold standard for phishing-resistant, passwordless authentication. User controls keys on their device. Enhances security and UX significantly over passwords or even traditional hardware wallet seed phrases for many users.
*   **Smart Contract Wallet (ERC-4337 Account Abstraction):**
    *   **Rationale:** Enables programmable wallets with features like social recovery, gas sponsoring, batch transactions, and custom security policies, all while users can still initiate actions with their Passkey (via an appropriate bundler and signature scheme). Crucial for abstracting blockchain complexity.
*   **Cryptographic Core (WalletCore SDK - WASM):**
    *   **Rationale:** Proven, open-source C++ library for multi-chain cryptographic operations. Compiling to WASM allows its use in JavaScript environments (React Native, Next.js) consistently.
*   **Local Encrypted Storage (SQLCipher / SubtleCrypto):**
    *   **Rationale:** For securely storing user preferences or cached sensitive data directly on the user's device, encrypted with keys derived from their primary authenticator (Passkey).
*   **Middleware (Hasura GraphQL, Rust/Axum for Drex Bridge, Go/Node.js for TX Orchestrator):**
    *   **Rationale:** Hasura for rapid API development over PostgreSQL. Rust/Axum for performance-critical and security-sensitive Drex bridge service. Go or Node.js (TypeScript) for transaction orchestration (including IAP proposals) and other middleware, chosen based on team expertise and specific needs of each microservice.
*   **Database (PostgreSQL 16 & Redis/DragonflyDB):**
    *   **Rationale:** PostgreSQL for robust, transactional off-chain ledger. Redis/DragonflyDB for caching and session management.
*   **Blockchain (Base L2, Hyperledger Besu):**
    *   **Rationale:** Base L2 for ION/IONW/NFTs due to Ethereum alignment, scalability, and growing ecosystem. Hyperledger Besu for a permissioned Drex sidechain allows for controlled CBDC integration and compliance.
*   **Event Bus (NATS JetStream for IAP `PlatformEvent`s):**
    *   **Rationale:** For reliable asynchronous eventing of financial transactions to the rest of the ION Super-Hub, using standardized IAP `PlatformEvent` schemas.

## 6. FILES & PATHS (Key Locations)

*   **`ionverse/apps/ionwallet_mobile/`**: React Native/Expo source code for the mobile IONWALLET.
*   **`ionverse/apps/ionwallet_webapp/`**: Next.js source code for the PWA IONWALLET.
*   **`ionverse/services/ionwallet_middleware/`**: Backend services.
    *   `drex_bridge_svc/` (Rust/Axum)
    *   `tx_orchestrator_svc/` (Go/Node.js - handles IAP proposals)
    *   `payment_gateway_svc/`
    *   `hasura_ionwallet/migrations` & `metadata`
*   **`ionverse/packages/ion_crypto_core/`**: Fork or wrapper around WalletCore SDK (WASM bindings, helper functions).
*   **`ionverse/packages/types_schemas_ionwallet/`**: TypeScript types and Zod/JSON schemas for IONWALLET data, including IAP skill parameters/responses.
*   **`ionverse/contracts/ionwallet_erc4337/`**: Solidity code for ERC-4337 smart contract wallet components (EntryPoint, WalletFactory, Paymaster) on Base L2.
*   **`ionverse/contracts/ion_drex_bridge/`**: Solidity/other code for smart contracts managing the ION-Drex bridge on Base L2 and the Besu sidechain.
*   **`ionverse/contracts/ionw_token/`**: Solidity code for the IONW ERC-20 token and related staking/governance contracts.

## 7. WHERE‑TO‑PLACE‑FILES (Conventions)

*   **Client UI Components:** Within the respective `ionwallet_mobile/components/` or `ionwallet_webapp/components/`. Shared components might go into `ionverse/packages/ui_components_financial/`.
*   **Blockchain Interaction Logic (Client-Side):** Abstracted within `ion_crypto_core` or specific service modules in the client apps that prepare transactions for IAP proposal to `Wallet Ops Agent` or direct IONWALLET interaction.
*   **IAP Skill Handling Logic (Backend):** Within the `tx_orchestrator_svc` or a dedicated `iap_handler_svc` if complexity grows.
*   **Middleware Service Logic:** Within the relevant service directory in `ionverse/services/ionwallet_middleware/`.
*   **Smart Contracts:** In `ionverse/contracts/` subdirectories.
*   **Database Schemas/Migrations:** Within the Hasura metadata/migrations directories for PostgreSQL.

## 8. DATA STORE — ERD (Prose Description for IONWALLET PostgreSQL)

*   **`wallets` / `accounts` (ERC-4337 based):** `wallet_id` (PK, user_did from IONWALL), `erc4337_address` (on Base L2, unique), `ion_balance_wei`, `ionw_balance_wei`, `drex_balance_wei_on_bridge` (cached), `default_currency_preference`, `created_at`, `last_accessed_at`. (Primary table for user's smart contract wallet).
*   **`assets` (NFTs & Custom Tokens):** `asset_id` (PK), `wallet_id` (FK), `contract_address` (L2), `token_id_if_nft` (string), `standard` (ERC721/1155), `balance_if_fungible` (string), `metadata_cache_cid` (link to IONPOD for rich metadata).
*   **`transactions_offchain_ledger`:** `tx_id` (PK, internal UUID), `wallet_id` (FK), `timestamp_initiated`, `timestamp_completed_or_failed`, `type` (e.g., 'swap_ion_drex', 'stake_ionw', 'send_nft', 'internal_transfer_ionpay', 'iap_proposed_transfer'), `status` (pending_ionwall, pending_user_approval_ionwallet, submitted_to_chain, confirmed_on_chain, failed_reason_code), `from_address_internal`, `to_address_internal`, `asset_1_type`, `asset_1_amount_wei`, `asset_2_type` (for swaps), `asset_2_amount_wei`, `chain_tx_hash` (nullable), `related_nats_event_id`, `ionwall_consent_receipt_cid`, `iap_proposal_id` (nullable, if initiated via IAP). (Detailed log of all operations orchestrated or recorded by IONWALLET backend).
*   **`staking_positions`:** `stake_id` (PK), `wallet_id` (FK), `pool_id` (e.g., 'ion_main_staking', 'ionw_wallet_utility', 'amm_ion_drex_lp'), `staked_amount_wei`, `token_type_staked` (ION or IONW), `start_date`, `last_compounded_date` (if auto-compounding), `claimed_rewards_wei`, `associated_lp_token_id` (if AMM).
*   **`rewards_ledger`:** `reward_id` (PK), `wallet_id` (FK), `source_type` (staking, liquidity_provision, platform_bonus), `amount_reward_token_wei`, `reward_token_type`, `timestamp_accrued`, `timestamp_claimed` (nullable).
*   **`fx_rates_history`:** `rate_id` (PK), `timestamp_recorded`, `base_currency` (e.g., ION), `quote_currency` (e.g., DREX), `rate_sell`, `rate_buy`, `source_oracle_name`. (For historical swap calculations and display).
*   **`user_preferences_wallet`:** `wallet_id` (PK, FK), `default_gas_setting` (slow, medium, fast), `auto_restake_rewards_preference_map` (JSONB mapping pool_id to boolean), `notification_preferences_json`.
*   **`iap_transaction_proposals`**: `proposal_id` (PK, UUID), `wallet_id` (FK), `requester_agent_did`, `skill_id_invoked`, `proposal_params_json`, `status` ('pending_user_approval', 'approved_by_user', 'rejected_by_user', 'expired', 'processed_tx_id' (FK to `transactions_offchain_ledger`)), `created_at`, `expires_at`.

**Relationships:**
*   `wallets` is central. `iap_transaction_proposals` links to `wallets`. Other tables as previously described.

## 9. SCHEDULING (Cron Jobs & Scheduled Tasks for IONWALLET)

Managed by Chronos Agent via IONFLUX, these tasks support IONWALLET operations:

*   **Auto-Compounding Staking Rewards:** For staking pools configured to auto-compound (e.g., weekly), a scheduled task calculates accrued rewards and re-stakes them into the principal for users who have opted-in.
*   **FX Rate Updates:** Periodically fetches latest FX rates from configured oracles (Chainlink, Pyth) and updates `fx_rates_history`.
*   **Pending Transaction Monitoring & Timeout:** Scans `transactions_offchain_ledger` for transactions stuck in "submitted_to_chain" for too long; may re-broadcast, alert user (via IAP event to Comm Link), or mark as potentially failed. Also checks `iap_transaction_proposals` for expired, unapproved proposals.
*   **Notification of Unclaimed Rewards:** Periodically checks `rewards_ledger` for significant unclaimed rewards and sends a NATS event (to Comm Link Agent) to notify users.
*   **Update ERC-4337 Paymaster Balances/Policies:** If IONWALLET uses paymasters for sponsored transactions, scheduled tasks might refresh paymaster balances or update their sponsoring policies.
*   **Cache Invalidation/Refresh:** For FX rates, account balances if heavily cached.
*   **Financial Report Snapshots (for user in IONPOD):** Scheduled task to generate a summary of a user's IONWALLET activity and store it as a document in their IONPOD.

## 10. FUTURE EXPANSION (Elaborated Points)

*   **10.1. Integrated DeFi Hub (Lending, Borrowing, Yield Farming):**
    *   Beyond basic staking/swaps, integrate access to a curated set of trusted DeFi protocols on Base L2 (or other supported chains). Users could lend assets, use assets as collateral for loans, or participate in yield farming strategies directly from IONWALLET, with risk assessments provided by TechGnosis and clear UX. IAP skills could propose entering/exiting these positions.
*   **10.2. Cross-Chain Asset Management & Bridging (Beyond Drex):**
    *   Natively support more L1s/L2s (e.g., Solana, Polygon, Arbitrum) and integrate robust, audited cross-chain bridges (e.g., Hop, Connext) for asset transfers, managed with the same security and UX principles. IAP proposals could target cross-chain actions.
*   **10.3. Advanced Account Abstraction Features (Social Recovery, Session Keys):**
    *   Fully implement ERC-4337 social recovery (e.g., trusted guardians).
    *   Introduce "Session Keys": allow users to grant temporary, restricted permissions via IAP to DApps or IONFLUX agents to perform specific actions from their wallet without needing approval for every transaction (e.g., "allow this game to make up to 10 small in-game purchases per day using my C-ION for the next hour"). Managed via IONWALL policies and approved in IONWALLET.
*   **10.4. Programmable Payments & Subscriptions (On-Chain):**
    *   Enable users to set up recurring payments, streaming payments (e.g., using Superfluid), or conditional payments directly from their IONWALLET using on-chain mechanisms where possible, or orchestrated via IONFLUX for off-chain components. IAP skills for managing these programmable payments.
*   **10.5. NFC & Point-of-Sale (POS) Integration for Real-World Payments:**
    *   Explore using NFC capabilities on mobile devices to allow IONWALLET (with Drex or stablecoins) to interact with compatible real-world POS terminals for payments, truly bridging the digital and physical economies. This is highly ambitious and regulation-dependent.
*   **10.6. AI-Powered Financial Advisor (IONPOD AI Twin Integration):**
    *   Allow the user's IONPOD AI Twin (with explicit permission via IAP call to IONPOD) to analyze their IONWALLET transaction history (read-only IAP skill) and financial goals to provide personalized insights, budget recommendations, or alerts about spending patterns, without raw financial data ever leaving the user's control perimeter.

## 11. SERVER BOOTSTRAP (Helm Chart's Role & Example Values for IONWALLET)

The IONWALLET backend services (GraphQL API, Drex Bridge, TX Orchestrator, Payment Gateway Integrator) are deployed to Kubernetes using a Helm chart (`ionverse/charts/ionwallet-services`).

*   **Helm Chart Role:** Defines, installs, and manages all K8s resources: Deployments, StatefulSets (for any small stateful components not covered by managed DBs), Services, Ingresses, ConfigMaps, Secrets.
*   **Example `values.yaml` snippets for IONWALLET chart:**
    ```yaml
    replicaCount: 2 # Default replicas for stateless services

    image:
      drexBridge: "your_registry/ionwallet-drex-bridge:v0.9.0"
      txOrchestrator: "your_registry/ionwallet-tx-orchestrator:v0.9.0"

    config:
      postgresUrlSecretName: "ionwallet-postgres-url"
      natsUrl: "nats://nats.ion-system:4222" # For IAP PlatformEvents
      baseL2RpcUrlSecretName: "base-l2-rpc-url"
      drexBesuRpcUrlSecretName: "drex-besu-rpc-url"
      ionTokenAddress: "0x..."
      ionwTokenAddress: "0x..." # Address of the IONW token
      logLevel: "info"
      iapListenerEnabled: true # For services that process IAP proposals

    resources: # Default resource requests/limits
      requests:
        cpu: "250m"
        memory: "512Mi"
      limits:
        cpu: "1000m"
        memory: "2Gi"

    autoscaling:
      enabled: true
      minReplicas: 2
      maxReplicas: 5
      targetCPUUtilizationPercentage: 75
    ```
    This allows for environment-specific configuration of critical parameters like database connections, RPC URLs for blockchains, token contract addresses, and scaling behaviors.

## 12. TASK TYPES (Common Operations within IONWALLET Backend)

IONWALLET backend services handle various "tasks" in response to client requests or IAP proposals:

1.  **FetchAccountBalances:**
    *   **Description:** Retrieves current token balances (ION, IONW, Drex, NFTs, etc.) for a user's wallet from PostgreSQL cache and verifies/updates with on-chain data.
    *   **Latency SLA (Target):** < 500ms (cached), < 5s (on-chain refresh).
2.  **GetTransactionHistory:**
    *   **Description:** Queries PostgreSQL for a user's transaction history with filtering/pagination.
    *   **Latency SLA (Target):** < 300ms.
3.  **ProcessIAPProposal (e.g., for TokenTransfer, Staking):**
    *   **Description:** Receives an IAP proposal (e.g., from `Wallet Ops Agent`), validates it, creates an entry in `iap_transaction_proposals` with `pending_user_approval` status. Notifies client (IONWALLET UI) to present for approval.
    *   **Latency SLA (Target):** < 100ms for initial processing and queuing.
4.  **ExecuteApprovedProposal (ERC-4337):**
    *   **Description:** After user approves an IAP proposal in IONWALLET UI, the Transaction Orchestrator constructs, signs (via ERC-4337 bundler using user's Passkey-derived signature or hardware wallet signature), and submits transaction to Base L2. Updates status in `iap_transaction_proposals` and `transactions_offchain_ledger`.
    *   **Latency SLA (Target):** < 2s for submission (excluding user approval time and chain confirmation).
5.  **ExecuteDrexIonSwap:**
    *   **Description:** Drex-ION Bridge Service orchestrates an atomic swap.
    *   **Latency SLA (Target):** 5s - 30s.
6.  **ProcessStakingRequest (Direct or IAP-Proposed):**
    *   **Description:** Interacts with staking smart contracts on Base L2.
    *   **Latency SLA (Target):** < 2s for submission after approval.
7.  **ProcessFiatOnRamp (Pix/Card):**
    *   **Description:** Payment Gateway Integrator communicates with PSP, coordinates asset crediting.
    *   **Latency SLA (Target):** 1s - 10s.

## 13. APPLE & ANDROID PUBLISHING PLAYBOOK (Compliance for Financial Apps)

Publishing IONWALLET, as a financial application dealing with cryptocurrencies and fiat bridges, requires extremely careful adherence to App Store and Google Play policies.

*   **Cryptocurrency Wallet Policies:**
    *   **Apple:** Generally allows crypto wallets but scrutinizes them. Must comply with all laws in regions where offered. No mining on device. ICOs/futures trading often restricted. Focus on user custody of keys.
    *   **Google:** More permissive but still requires compliance with financial regulations.
    *   **IONWALLET Strategy:** Emphasize non-custodial nature (user controls keys via Passkeys/device security for local vault, or MPC where user is active participant). Clearly explain risks of crypto. Avoid features that could be seen as facilitating unregulated securities.
*   **Financial Services & Money Transmission:**
    *   If IONWALLET facilitates fiat-to-crypto or crypto-to-fiat exchanges directly (not just P2P via DEXs), it may be considered a Money Service Business (MSB) or require similar licenses in various jurisdictions.
    *   **Strategy:** Partner with licensed PSPs (Stripe, Ramp, Pix providers) for fiat on/off-ramps. The Drex bridge is a critical area requiring specific regulatory approval/understanding with the Central Bank of Brazil. Clearly delineate IONWALLET's role as a technology provider vs. a licensed financial institution.
*   **In-App Purchases (IAP):**
    *   **Apple/Google:** If selling digital goods *consumed within the app* (e.g., C-ION credits *if not directly exchangeable for ION that has external value*, or premium wallet themes, or IONW tokens if sold directly by the app operator for fiat), IAP must be used.
    *   **Strategy:** For core crypto transactions (sending ION, swapping on DEX), these are generally *not* IAP as they involve user's own assets with external value. However, if IONWALLET charges a *service fee* for facilitating these, that fee *might* need to be via IAP if Apple/Google deem it a digital service. This is a notorious gray area. Be prepared for scrutiny. Offering IONW token for staking to reduce such fees might be a compliant path. Direct P2P NFT trading or external asset purchases are different.
*   **KYC/AML:**
    *   Implement robust KYC/AML processes via IONWALL integration, with tiers of verification. This is essential for fiat on/off-ramps and to comply with financial regulations. Clearly explain why KYC is needed for certain features.
*   **Security & Data Privacy:**
    *   Transparent privacy policy. Explain data encryption (SQLCipher, HTTPS, Passkey security).
    *   Regular security audits of the app and smart contracts are non-negotiable.
    *   Clearly articulate the non-custodial aspects and user's responsibility for their Passkey/recovery mechanisms.
*   **Geofencing:** Restrict access to certain features (e.g., Drex bridge, specific DeFi protocols, certain token sales) based on user's jurisdiction and local regulations.

## 14. SECURITY & COMPLIANCE (Expanded: E2EE, STRIDE, SOC-2, KYT)

IONWALLET's security posture is paramount.

*   **End-to-End Encryption (E2EE) for Sensitive User Data:**
    *   User preferences, notes, or address book entries stored locally are encrypted using SQLCipher (mobile) or SubtleCrypto (web), with keys derived from Passkeys.
    *   Communication with backend services uses TLS 1.3.
    *   Sensitive parameters for IAP calls (e.g., to `Wallet Ops Agent`) should be E2EE where possible, or use secure channels established by IONWALL.
*   **STRIDE Threat Modeling:**
    *   Regularly conduct STRIDE (Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege) threat modeling exercises for all IONWALLET components (clients, middleware, smart contracts, bridges, IAP interactions).
    *   Document threats and mitigations. This informs security testing and development priorities.
*   **SOC-2 Compliance (Aspirational Goal):**
    *   While full SOC-2 Type II compliance is a long-term goal requiring significant process maturity, design IONWALLET's backend services and operational procedures with SOC-2 trust service criteria (Security, Availability, Processing Integrity, Confidentiality, Privacy) in mind from early stages. This includes logging, change management, access controls.
*   **KYT (Know Your Transaction) / AML (Anti-Money Laundering):**
    *   Integrate with on-chain analytics services (e.g., Chainalysis, Elliptic, TRM Labs) via IONWALL or a dedicated compliance agent.
    *   Monitor transactions to/from IONWALLET smart accounts for AML red flags (e.g., interaction with sanctioned addresses, mixers, high-risk exchanges).
    *   Alerts trigger reviews by Hybrid Layer compliance team. This is crucial for maintaining banking relationships for fiat on/off-ramps and regulatory standing.
*   **Smart Contract Audits:** All custom smart contracts (ERC-4337 components, Drex bridge, staking contracts for ION/IONW) undergo multiple independent audits by reputable firms before mainnet deployment and after significant upgrades.
*   **Hardware Wallet Integration Security:** Ensure secure communication protocols (BLE, WebHID) and that transaction data displayed on the hardware wallet for signing is accurate and cannot be tampered with by the client application.
*   **Passkey Security:** Educate users on securing their devices where Passkeys are stored and on managing Passkey synchronization across their devices (e.g., iCloud Keychain, Google Password Manager). Emphasize that the Passkey *is* the key.
*   **MPC/Social Recovery Security:** If MPC/Social Recovery is implemented, ensure the chosen schemes are audited, non-custodial in spirit (user always controls a share or the initiation), and that recovery processes have strong identity verification steps managed by IONWALL/Hybrid Layer.

## 15. TOKENOMICS (IONW Token Specifics - based on `IONWALLET — Blueprint v5.0` guidance)

While the **ION** token is the primary utility and governance token for the broader IONVERSE ecosystem, the **IONW (IONWALLET Governance & Utility) token** is specific to the IONWALLET application, designed to incentivize its usage, security, and decentralized governance of its features.

*   **IONW Token Utility:**
    1.  **Staking for Fee Reduction/Discounts:** Users staking IONW tokens within IONWALLET receive tiered discounts on IONWALLET-specific service fees (e.g., fees for advanced DeFi features, premium support, or specific types of swaps if applicable above standard AMM fees).
    2.  **Governance over IONWALLET Features:** IONW holders can vote on proposals related to:
        *   Prioritization of new blockchain integrations for IONWALLET.
        *   Selection of new DeFi protocols to be integrated or featured.
        *   Fee structures for IONWALLET-specific premium services.
        *   Allocation of a portion of IONWALLET-generated fees to its own treasury or for buy-back/burn of IONW.
    3.  **Early Access to Beta Features:** IONW stakers might get early access to new, experimental IONWALLET features.
    4.  **Enhanced IAP Limits (for Agents):** IONFLUX Agents or Agent 000 making IAP proposals to a user's IONWALLET might receive higher request limits or preferential processing if the target user (or the agent's owner on behalf of the agent) has a significant IONW stake, signaling commitment and trustworthiness for wallet interactions.
*   **IONW Total Supply:** `1,000,000,000 IONW` (Example, replace with actual from Blueprint)
*   **IONW Allocation (Example):**
    *   **Community Treasury / Ecosystem Development:** `40%` (400,000,000 IONW) - For grants, partnerships, liquidity mining for IONW pairs (e.g., IONW/ION, IONW/ETH on Base L2 DEXs).
    *   **Team & Advisors:** `20%` (200,000,000 IONW) - Subject to vesting (e.g., 12-month cliff, 36-month linear vesting thereafter).
    *   **Staking Rewards & User Incentives:** `30%` (300,000,000 IONW) - Released algorithmically over several years to reward IONW stakers and active IONWALLET users.
    *   **Public/Private Sale (Optional):** `10%` (100,000,000 IONW) - For initial fundraising if applicable, with its own vesting.
*   **IONW Vesting Schedules:** Clearly defined for team, advisors, and any private sale participants, e.g., 6-12 month cliff from Token Generation Event (TGE), followed by 24-48 months linear or milestone-based vesting. Staking rewards are distributed over a longer emission schedule.
*   **IONWALLET Fees & IONW Interaction:**
    *   IONWALLET may generate revenue from:
        *   A small percentage (e.g., 0.05%-0.1%) on swaps performed via its integrated DEX aggregator if it provides best execution routing or value-add.
        *   Fees for accessing premium DeFi features (e.g., advanced analytics, automated yield strategies, undercollateralized loan origination if offered).
        *   Potentially, a share of fees from fiat on/off-ramp services above certain volumes, if permissible by PSP agreements.
    *   A portion of these collected fees (e.g., 25-50%) could be allocated by IONW governance to:
        *   Fund the IONWALLET operational treasury.
        *   Buy back IONW tokens from the market and burn them (deflationary).
        *   Distribute as additional rewards (e.g., in ION or stablecoins) to IONW stakers.
*   **Relationship with ION & C-ION Tokens:**
    *   **ION:** Remains the primary utility token for the sNetwork (e.g., marketplace, core services) and the token burned to create C-ION.
    *   **C-ION:** Used to pay for compute/AI tasks across IONFLUX and other apps. IONWALLET itself might consume C-ION if its backend services perform significant AI/compute (e.g., for fraud detection or AI financial advisor features).
    *   IONW provides specific utility and governance *within* the IONWALLET application. Synergies exist, e.g., staking IONW might give users slightly better rates for burning ION into C-ION, or make them eligible for C-ION airdrops.
    *   Liquidity pools like ION/IONW will be encouraged on Base L2 DEXs.

This dedicated IONW token allows for a focused economic model and governance structure around the IONWALLET application, rewarding its users and stakeholders directly for its growth, security, and utility, while remaining deeply interconnected with the main ION token and the C-ION credit system.

## 16. METRICS & OKRs (Significance for IONWALLET)

IONWALLET's success is measured by user adoption, asset security, financial activity, and its contribution to the user's overall financial well-being and sovereignty.

*   **User Adoption & Retention:**
    *   **Active Wallets (DAU/MAU):** Number of unique wallets making at least one signed operation or IAP-confirmed action.
    *   **New Wallet Creation Rate (ERC-4337 accounts deployed).**
    *   **M30 Wallet Retention:** Percentage of new wallets active after 30 days.
    *   **Passkey Adoption Rate:** Percentage of wallets secured primarily with Passkeys.
    *   **IONW Staking Rate:** % of circulating IONW staked.
*   **Asset Management & Value:**
    *   **Total Value Locked (TVL) in IONWALLET (ION, IONW, Drex, Stablecoins, NFTs - estimated):** Aggregate value of assets managed through IONWALLET smart accounts.
    *   **Average Number & Diversity of Assets Held per Wallet.**
    *   **Staking Participation Value (ION & IONW):** Total value staked.
    *   **Drex Bridge Volume (BRL equivalent):** Activity through the Drex bridge.
*   **Transactional Activity:**
    *   **Transaction Count & Volume (by type: Send, Swap, Stake, NFT trade via IONPay, IAP-proposed actions).**
    *   **`IONPay` Usage:** Number and volume of transactions using the IONPay widget.
    *   **Fiat On/Off-Ramp Volume (Pix, Cards).**
    *   **Number of IAP proposals processed (initiated, approved, rejected).**
*   **Security & User Trust:**
    *   **Number of Security Incidents Reported/Prevented:** (Goal is zero reported by users).
    *   **Rate of Successful Account Recovery (for MPC/Social Recovery users).**
    *   **User-Reported Fraud Rate on Transactions Facilitated by Wallet.**
*   **North-Star KPI (Reiteration):** **“Total Value Locked & Actively Managed (TVLAM) × User Financial Health Score Improvement (derived from Score.Fin velocity)”**

**OKRs will focus on:**
*   **Objective:** Become the preferred sovereign and secure wallet for IONVERSE citizens.
    *   **KR1:** Achieve X thousand active ERC-4337 smart wallets by end of Q1 2025.
    *   **KR2:** Process Y million BRL equivalent via Drex-ION bridge in Q1 2025.
    *   **KR3:** Attain an average M30 Wallet Retention of Z%.
    *   **KR4:** Launch IONW staking with W% of initial eligible supply staked within 2 months.
*   **Objective:** Deliver best-in-class security and user trust for financial operations.
    *   **KR1:** Successfully complete 2 external smart contract audits for all new on-chain components (IONW token, staking, ERC-4337 factory/paymaster).
    *   **KR2:** Achieve >90% Passkey adoption among newly created wallets.
    *   **KR3:** Implement and test KYT monitoring for X number of transactions, with an alert-to-action rate of Y.

## 17. ROADMAP (Descriptive Milestones for IONWALLET)

*   **Phase 0: Core Infrastructure & Security Design (Completed)**
    *   Selection of ERC-4337 stack, WalletCore SDK, Passkey integration strategy.
    *   Security modeling (STRIDE), initial smart contract architecture for IONW and staking.
    *   Drex bridge conceptual design and preliminary regulatory consultation. IAP interaction points defined.
*   **Phase 1: MVP - Secure Custody & Core Token Operations (Target: Q3-Q4 2024, aligns with IONVERSE MVP)**
    *   **Focus:** Launch secure, user-controlled wallet for ION, IONW, and Base L2 ETH (for gas). Passkey creation/login. Basic send/receive. ERC-4337 account deployment.
    *   **Milestones:**
        *   Mobile (React Native/Expo) and Web PWA clients with Passkey integration.
        *   View balances for ION, IONW, ETH on Base L2.
        *   Send/receive these assets using ERC-4337 smart accounts.
        *   IONW token contract deployed; basic IONW staking contract (e.g., deposit IONW, earn more IONW).
        *   Initial integration with IONWALL for linking wallet activity to DID and basic `Score.Fin` input.
        *   Basic IAP skills for balance check and transaction proposal exposed for `Wallet Ops Agent`.
*   **Phase 2: Drex Bridge & Staking Expansion (Target: Q1 2025)**
    *   **Focus:** Launch Drex bridge MVP for BRL (Pix) ↔ tokenized Drex ↔ ION/USDC. Expand ION/IONW staking features (e.g., auto-compounding, AMM LPs for IONW/ION).
    *   **Milestones:**
        *   Drex-ION bridge service operational for pilot users (transactions logged, security audited).
        *   Pix on-ramp to Drex/USDC functional.
        *   AMM for IONW-ION pair with liquidity provision and fee generation.
        *   `IONPay` widget MVP for simple ION payments within IONVERSE app, with IAP proposal flow.
*   **Phase 3: DeFi Integration & Advanced Features (Target: Q2-Q3 2025)**
    *   **Focus:** Integrate selected DeFi protocols (lending/borrowing). Full ERC-4337 features (social recovery, session keys via IAP). NFT management (display, transfer).
    *   **Milestones:**
        *   NFT display and transfer capabilities for major standards on Base L2.
        *   Integration with one audited lending/borrowing protocol on Base L2, accessible via IONWALLET UI and IAP proposals.
        *   Social recovery mechanism for ERC-4337 accounts implemented and user-testable.
        *   Advanced `Score.Fin` from IONWALL visibly impacting fees or feature access within IONWALLET.
*   **Phase 4: Cross-Chain, Governance & Real-World Expansion (Target: Q4 2025 onwards)**
    *   **Focus:** Explore further cross-chain integrations. Enhance real-world payment capabilities (e.g., NFC PoC). Mature DAO governance for IONW token and IONWALLET parameters.
    *   **Milestones:**
        *   Pilot for cross-chain asset bridge beyond Drex (e.g., to another L2 or L1 for key stablecoins or blue-chip assets).
        *   Full IONW DAO governance over selected IONWALLET parameters (e.g., fee structures, treasury allocations).
        *   Partnerships for wider adoption of `IONPay` and potential real-world use cases.

This roadmap is dynamic and will adapt to user feedback, technological advancements, and the regulatory landscape. The Pooldad spirit of "romper a normalidade" means constantly seeking impactful innovations in sovereign finance.
