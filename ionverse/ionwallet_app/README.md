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
    *   Provides a universal payment widget/SDK (`IONPay`) for seamless in-app purchases and service payments across all IONVERSE applications (IONVERSE App, IONFLUX, IONPOD) using ION, C-ION, Drex, or other supported tokens.
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
    *   Review and approve/deny transaction requests initiated by other IONFLUX agents (via the `Wallet Ops Agent` interacting with IONWALLET's secure UI).

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
        MW_TX_ORCH[Transaction Orchestrator & Nonce Manager (Go/Node.js)]
        MW_PAYMENT_GW[Payment Gateway Integrator (Stripe, Pix - for On/Off Ramps)]
        MW_NATS_PUBSUB[NATS Event Publisher/Subscriber (for IONWALL, IONFLUX)]
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
    *   Manages the lifecycle of transactions initiated by users or `Wallet Ops Agent`.
    *   Handles nonce management for ERC-4337 accounts on Base L2 to prevent replay attacks and ensure ordered transactions.
    *   Interfaces with Base L2 nodes (e.g., Infura, Alchemy, or self-hosted Erigon/Geth nodes) for transaction submission and status tracking.
    *   May incorporate a gas estimation service.
*   **Payment Gateway Integration Service (Stripe, Pix via PSPs):**
    *   Manages fiat on-ramps (Pix, credit/debit cards) and off-ramps (Pix).
    *   Securely handles communication with Payment Service Providers (PSPs).
    *   Coordinates with Drex-ION Bridge Service to convert fiat to/from digital assets.
*   **NATS Event Publisher/Subscriber:**
    *   Publishes events like `ionwallet.transaction.created`, `ionwallet.transaction.confirmed`, `ionwallet.transaction.failed`, `ionwallet.stake.initiated`, `ionwallet.reward.claimed` to NATS JetStream.
    *   Subscribes to relevant events from other ION apps (e.g., `ionwall.reputation.updated_for_user_X` if it needs to adjust user limits).

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

## 4. HOW‑TO‑IMPLEMENT (Kickstart & Hands‑On for Developers)

1.  **Understand IONWALLET's Role & Security Model:**
    *   **Action:** Read this `README.md` thoroughly, focusing on Sections 0, 1, 2, and 14 (Security). Understand that IONWALLET is the user's sovereign space; other apps *request* actions, IONWALLET (with user approval) *performs* them.
    *   **Goal:** Internalize the security principles and the user-in-control paradigm.

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

6.  **Integrate with `Wallet Ops Agent` (Conceptual):**
    *   **Action:** Review `specs/agents/009_wallet_ops_agent.md`. If a test script or mock `Wallet Ops Agent` is available, try to trigger an action (e.g., `request_token_transfer`) that would theoretically interact with your running IONWALLET instance.
    *   Observe how IONWALLET would receive and display such a request (this might require a mock IONWALLET UI harness that simulates the secure prompt).
    *   **Goal:** Understand the A2A interaction flow between a generic agent and IONWALLET via the `Wallet Ops Agent`.

7.  **Explore Smart Contract Interactions (Staking/Swaps):**
    *   **Action:** If staking or AMM features are implemented in the UI, try staking some test ION/IONW. Inspect the underlying smart contract calls being made (e.g., using a block explorer for Base Sepolia connected to your MetaMask if testing through Snap, or by examining logs from the Transaction Orchestrator).
    *   **Goal:** Understand how IONWALLET interacts with on-chain DeFi protocols.

8.  **Security Review (Conceptual):**
    *   **Action:** Consider a common attack vector (e.g., phishing for Passkey creation, malicious DApp trying to trick user into signing a harmful transaction). Think about how IONWALLET's architecture (Passkeys, ERC-4337, IONWALL mediation, clear transaction summaries in IONWALLET UI) aims to mitigate this.
    *   **Goal:** Appreciate the security layers involved.

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
    *   **Rationale:** Hasura for rapid API development over PostgreSQL. Rust/Axum for performance-critical and security-sensitive Drex bridge service. Go or Node.js (TypeScript) for transaction orchestration and other middleware, chosen based on team expertise and specific needs of each microservice.
*   **Database (PostgreSQL 16 & Redis/DragonflyDB):**
    *   **Rationale:** PostgreSQL for robust, transactional off-chain ledger. Redis/DragonflyDB for caching and session management.
*   **Blockchain (Base L2, Hyperledger Besu):**
    *   **Rationale:** Base L2 for ION/IONW/NFTs due to Ethereum alignment, scalability, and growing ecosystem. Hyperledger Besu for a permissioned Drex sidechain allows for controlled CBDC integration and compliance.
*   **Event Bus (NATS JetStream):**
    *   **Rationale:** For reliable asynchronous eventing of financial transactions to the rest of the ION Super-Hub.

## 6. FILES & PATHS (Key Locations)

*   **`ionverse/apps/ionwallet_mobile/`**: React Native/Expo source code for the mobile IONWALLET.
*   **`ionverse/apps/ionwallet_webapp/`**: Next.js source code for the PWA IONWALLET.
*   **`ionverse/services/ionwallet_middleware/`**: Backend services.
    *   `drex_bridge_svc/` (Rust/Axum)
    *   `tx_orchestrator_svc/` (Go/Node.js)
    *   `payment_gateway_svc/`
    *   `hasura_ionwallet/migrations` & `metadata`
*   **`ionverse/packages/ion_crypto_core/`**: Fork or wrapper around WalletCore SDK (WASM bindings, helper functions).
*   **`ionverse/packages/types_schemas_ionwallet/`**: TypeScript types and Zod/JSON schemas for IONWALLET data.
*   **`ionverse/contracts/ionwallet_erc4337/`**: Solidity code for ERC-4337 smart contract wallet components (EntryPoint, WalletFactory, Paymaster) on Base L2.
*   **`ionverse/contracts/ion_drex_bridge/`**: Solidity/other code for smart contracts managing the ION-Drex bridge on Base L2 and the Besu sidechain.

## 7. WHERE‑TO‑PLACE‑FILES (Conventions)

*   **Client UI Components:** Within the respective `ionwallet_mobile/components/` or `ionwallet_webapp/components/`. Shared components might go into `ionverse/packages/ui_components_financial/`.
*   **Blockchain Interaction Logic (Client-Side):** Abstracted within `ion_crypto_core` or specific service modules in the client apps that prepare transactions for `Wallet Ops Agent` or direct IONWALLET interaction.
*   **Middleware Service Logic:** Within the relevant service directory in `ionverse/services/ionwallet_middleware/`.
*   **Smart Contracts:** In `ionverse/contracts/` subdirectories.
*   **Database Schemas/Migrations:** Within the Hasura metadata/migrations directories for PostgreSQL.

## 8. DATA STORE — ERD (Prose Description for IONWALLET PostgreSQL)

*   **`wallets` / `accounts` (ERC-4337 based):** `wallet_id` (PK, user_did from IONWALL), `erc4337_address` (on Base L2, unique), `ion_balance_wei`, `ionw_balance_wei`, `drex_balance_wei_on_bridge` (cached), `default_currency_preference`, `created_at`, `last_accessed_at`. (Primary table for user's smart contract wallet).
*   **`assets` (NFTs & Custom Tokens):** `asset_id` (PK), `wallet_id` (FK), `contract_address` (L2), `token_id_if_nft` (string), `standard` (ERC721/1155), `balance_if_fungible` (string), `metadata_cache_cid` (link to IONPOD for rich metadata).
*   **`transactions_offchain_ledger`:** `tx_id` (PK, internal UUID), `wallet_id` (FK), `timestamp_initiated`, `timestamp_completed_or_failed`, `type` (e.g., 'swap_ion_drex', 'stake_ionw', 'send_nft', 'internal_transfer_ionpay'), `status` (pending_ionwall, pending_user_approval_ionwallet, submitted_to_chain, confirmed_on_chain, failed_reason_code), `from_address_internal`, `to_address_internal`, `asset_1_type`, `asset_1_amount_wei`, `asset_2_type` (for swaps), `asset_2_amount_wei`, `chain_tx_hash` (nullable), `related_nats_event_id`, `ionwall_consent_receipt_cid`. (Detailed log of all operations orchestrated or recorded by IONWALLET backend).
*   **`staking_positions`:** `stake_id` (PK), `wallet_id` (FK), `pool_id` (e.g., 'ion_main_staking', 'ionw_wallet_utility', 'amm_ion_drex_lp'), `staked_amount_wei`, `token_type_staked` (ION or IONW), `start_date`, `last_compounded_date` (if auto-compounding), `claimed_rewards_wei`, `associated_lp_token_id` (if AMM).
*   **`rewards_ledger`:** `reward_id` (PK), `wallet_id` (FK), `source_type` (staking, liquidity_provision, platform_bonus), `amount_reward_token_wei`, `reward_token_type`, `timestamp_accrued`, `timestamp_claimed` (nullable).
*   **`fx_rates_history`:** `rate_id` (PK), `timestamp_recorded`, `base_currency` (e.g., ION), `quote_currency` (e.g., DREX), `rate_sell`, `rate_buy`, `source_oracle_name`. (For historical swap calculations and display).
*   **`user_preferences_wallet`:** `wallet_id` (PK, FK), `default_gas_setting` (slow, medium, fast), `auto_restake_rewards_preference_map` (JSONB mapping pool_id to boolean), `notification_preferences_json`.

**Relationships:**
*   `wallets` is central, linked to `assets`, `transactions_offchain_ledger`, `staking_positions`, `rewards_ledger`, `user_preferences_wallet`.
*   Transactions are linked to assets involved. Staking positions generate rewards.

## 9. SCHEDULING (Cron Jobs & Scheduled Tasks for IONWALLET)

Managed by Chronos Agent via IONFLUX, these tasks support IONWALLET operations:

*   **Auto-Compounding Staking Rewards:** For staking pools configured to auto-compound (e.g., weekly), a scheduled task calculates accrued rewards and re-stakes them into the principal for users who have opted-in.
*   **FX Rate Updates:** Periodically fetches latest FX rates from configured oracles (Chainlink, Pyth) and updates `fx_rates_history`.
*   **Pending Transaction Monitoring & Timeout:** Scans `transactions_offchain_ledger` for transactions stuck in "submitted_to_chain" for too long; may re-broadcast, alert user, or mark as potentially failed.
*   **Notification of Unclaimed Rewards:** Periodically checks `rewards_ledger` for significant unclaimed rewards and sends a NATS event (to Comm Link Agent) to notify users.
*   **Update ERC-4337 Paymaster Balances/Policies:** If IONWALLET uses paymasters for sponsored transactions, scheduled tasks might refresh paymaster balances or update their sponsoring policies.
*   **Cache Invalidation/Refresh:** For FX rates, account balances if heavily cached.
*   **Financial Report Snapshots (for user in IONPOD):** Scheduled task to generate a summary of a user's IONWALLET activity and store it as a document in their IONPOD.

## 10. FUTURE EXPANSION (Elaborated Points)

*   **10.1. Integrated DeFi Hub (Lending, Borrowing, Yield Farming):**
    *   Beyond basic staking/swaps, integrate access to a curated set of trusted DeFi protocols on Base L2 (or other supported chains). Users could lend assets, use assets as collateral for loans, or participate in yield farming strategies directly from IONWALLET, with risk assessments provided by TechGnosis and clear UX.
*   **10.2. Cross-Chain Asset Management & Bridging (Beyond Drex):**
    *   Natively support more L1s/L2s (e.g., Solana, Polygon, Arbitrum) and integrate robust, audited cross-chain bridges (e.g., Hop, Connext) for asset transfers, managed with the same security and UX principles.
*   **10.3. Advanced Account Abstraction Features (Social Recovery, Session Keys):**
    *   Fully implement ERC-4337 social recovery (e.g., trusted guardians).
    *   Introduce "Session Keys": allow users to grant temporary, restricted permissions to DApps or IONFLUX agents to perform specific actions from their wallet without needing approval for every transaction (e.g., "allow this game to make up to 10 small in-game purchases per day using my C-ION for the next hour"). Managed via IONWALL policies.
*   **10.4. Programmable Payments & Subscriptions (On-Chain):**
    *   Enable users to set up recurring payments, streaming payments (e.g., using Superfluid), or conditional payments directly from their IONWALLET using on-chain mechanisms where possible, or orchestrated via IONFLUX for off-chain components.
*   **10.5. NFC & Point-of-Sale (POS) Integration for Real-World Payments:**
    *   Explore using NFC capabilities on mobile devices to allow IONWALLET (with Drex or stablecoins) to interact with compatible real-world POS terminals for payments, truly bridging the digital and physical economies. This is highly ambitious and regulation-dependent.
*   **10.6. AI-Powered Financial Advisor (IONPOD AI Twin Integration):**
    *   Allow the user's IONPOD AI Twin (with explicit permission) to analyze their IONWALLET transaction history and financial goals to provide personalized insights, budget recommendations, or alerts about spending patterns, without raw financial data ever leaving the user's control perimeter (analysis happens via secure queries or on-device).

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
      natsUrl: "nats://nats.ion-system:4222"
      baseL2RpcUrlSecretName: "base-l2-rpc-url"
      drexBesuRpcUrlSecretName: "drex-besu-rpc-url"
      ionTokenAddress: "0x..."
      ionwTokenAddress: "0x..." # Address of the IONW token
      logLevel: "info"

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

IONWALLET backend services handle various "tasks" in response to client requests or events:

1.  **FetchAccountBalances:**
    *   **Description:** Retrieves current token balances (ION, IONW, Drex, NFTs, etc.) for a user's wallet from PostgreSQL cache and verifies/updates with on-chain data.
    *   **Latency SLA (Target):** < 500ms (cached), < 5s (on-chain refresh).
2.  **GetTransactionHistory:**
    *   **Description:** Queries PostgreSQL for a user's transaction history with filtering/pagination.
    *   **Latency SLA (Target):** < 300ms.
3.  **InitiateTokenTransfer (Off-Chain Orchestration):**
    *   **Description:** Receives transfer request, validates, creates entry in `transactions_offchain_ledger` with `pending_user_approval_ionwallet` status, sends NATS event to `Wallet Ops Agent` to trigger IONWALLET UI for approval.
    *   **Latency SLA (Target):** < 100ms for initial processing.
4.  **ProcessWalletApprovalAndSubmitToChain (ERC-4337):**
    *   **Description:** Receives confirmation from `Wallet Ops Agent` (after user approves in IONWALLET UI). Transaction Orchestrator constructs, signs (via ERC-4337 bundler using user's Passkey-derived signature or hardware wallet signature), and submits transaction to Base L2. Updates status.
    *   **Latency SLA (Target):** < 2s for submission (excluding user approval time and chain confirmation).
5.  **ExecuteDrexIonSwap:**
    *   **Description:** Drex-ION Bridge Service orchestrates an atomic swap, involving locking assets on one chain, verifying, and releasing on the other. Complex, multi-step.
    *   **Latency SLA (Target):** 5s - 30s (depends on both chains' confirmation times and bridge security model).
6.  **ProcessStakingRequest:**
    *   **Description:** Interacts with staking smart contracts on Base L2 to stake/unstake ION or IONW. Similar flow to token transfer regarding user approval.
    *   **Latency SLA (Target):** < 2s for submission after approval.
7.  **ProcessFiatOnRamp (Pix/Card):**
    *   **Description:** Payment Gateway Integrator communicates with PSP, receives confirmation, coordinates with Drex Bridge or TX Orchestrator to credit user's IONWALLET with digital assets.
    *   **Latency SLA (Target):** 1s - 10s (Pix is fast; card payments can vary).

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
    *   **Apple/Google:** If selling digital goods *consumed within the app* (e.g., C-ION credits *if not directly exchangeable for ION that has external value*, or premium wallet themes), IAP must be used.
    *   **Strategy:** For core crypto transactions (sending ION, swapping on DEX), these are generally *not* IAP as they involve user's own assets with external value. However, if IONWALLET charges a *service fee* for facilitating these, that fee *might* need to be via IAP if Apple/Google deem it a digital service. This is a notorious gray area. Be prepared for scrutiny. Offering IONW token for staking to reduce such fees might be a compliant path.
*   **KYC/AML:**
    *   Implement robust KYC/AML processes via IONWALL integration, with tiers of verification. This is essential for fiat on/off-ramps and to comply with financial regulations. Clearly explain why KYC is needed for certain features.
*   **Security & Data Privacy:**
    *   Transparent privacy policy. Explain data encryption (SQLCipher, HTTPS, Passkey security).
    *   Regular security audits of the app and smart contracts are non-negotiable.
    *   Clearly articulate the non-custodial aspects and user's responsibility for their Passkey/recovery mechanisms.
*   **Geofencing:** Restrict access to certain features (e.g., Drex bridge, specific DeFi protocols) based on user's jurisdiction and local regulations.

## 14. SECURITY & COMPLIANCE (Expanded: E2EE, STRIDE, SOC-2, KYT)

IONWALLET's security posture is paramount.

*   **End-to-End Encryption (E2EE) for Sensitive User Data:**
    *   User preferences, notes, or address book entries stored locally are encrypted using SQLCipher (mobile) or SubtleCrypto (web), with keys derived from Passkeys.
    *   Communication with backend services uses TLS 1.3.
    *   Sensitive parameters for `Wallet Ops Agent` calls are E2EE if possible, or use secure channels.
*   **STRIDE Threat Modeling:**
    *   Regularly conduct STRIDE (Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege) threat modeling exercises for all IONWALLET components (clients, middleware, smart contracts, bridges).
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
    4.  **Enhanced API Limits (for Agents):** IONFLUX Agents using `Wallet Ops Agent` to interact with a user's IONWALLET might receive higher API call limits or preferential processing if the user (or the agent's owner) has a significant IONW stake, signaling commitment and trustworthiness for wallet interactions.
*   **IONW Total Supply:** `[Specify Total Supply, e.g., 100,000,000 IONW]` (This would come from the Blueprint)
*   **IONW Allocation (Example):**
    *   **Community Treasury / Ecosystem Development:** `[e.g., 40%]` - For grants, partnerships, liquidity mining for IONW pairs.
    *   **Team & Advisors:** `[e.g., 20%]` - Subject to vesting.
    *   **Staking Rewards & Incentives:** `[e.g., 30%]` - Released over several years.
    *   **Public/Private Sale (Optional):** `[e.g., 10%]` - For initial fundraising if applicable.
*   **IONW Vesting Schedules:** Standard vesting schedules for team, advisors, and potentially private sale investors (e.g., 6-12 month cliff, 24-48 month linear vesting).
*   **IONWALLET Fees & IONW Interaction:**
    *   IONWALLET may generate revenue from:
        *   Small percentage on swaps performed via its integrated DEX aggregator (if it offers best execution routing).
        *   Fees for premium DeFi feature access (e.g., advanced analytics, automated yield strategies).
        *   Fees for specific types of fiat on/off-ramp operations above a certain volume.
    *   A portion of these fees could be used to:
        *   Fund the IONWALLET treasury (governed by IONW holders).
        *   Buy back and burn IONW tokens from the market.
        *   Distribute as additional rewards to IONW stakers.
*   **Relationship with ION Token:**
    *   ION remains the primary gas token (via C-ION) for operations and the main governance token for the overall IONVERSE sNetwork.
    *   IONW provides specialized governance and utility *within* IONWALLET. There might be liquidity pools like ION/IONW.
    *   Burning ION to get C-ION might be influenced by IONW staking tiers (e.g., better conversion rates).

This dedicated IONW token allows for a focused economic model around the IONWALLET application itself, rewarding its users and stakeholders directly for its growth and utility, while still being synergistic with the main ION token.

## 16. METRICS & OKRs (Significance for IONWALLET)

IONWALLET's success is measured by user adoption, asset security, financial activity, and its contribution to the user's overall financial well-being and sovereignty.

*   **User Adoption & Retention:**
    *   **Active Wallets (DAU/MAU):** Number of unique wallets making at least one signed operation.
    *   **New Wallet Creation Rate.**
    *   **M30 Wallet Retention:** Percentage of new wallets active after 30 days.
    *   **Passkey Adoption Rate:** Percentage of wallets secured with Passkeys.
*   **Asset Management & Value:**
    *   **Total Value Locked (TVL) in Wallet (ION, IONW, Drex, Stablecoins, NFTs - estimated):** Aggregate value of assets managed.
    *   **Average Number of Assets Held per Wallet.**
    *   **Staking Participation Rate (ION & IONW):** Percentage of eligible tokens staked.
    *   **Drex Bridge Volume (BRL equivalent):** Activity through the Drex bridge.
*   **Transactional Activity:**
    *   **Transaction Count & Volume (by type: Send, Swap, Stake, NFT trade via IONPay).**
    *   **`IONPay` Usage:** Number and volume of transactions using the IONPay widget.
    *   **Fiat On/Off-Ramp Volume (Pix, Cards).**
*   **Security & User Trust:**
    *   **Number of Security Incidents Reported/Prevented:** (Goal is zero reported by users).
    *   **Rate of Successful Account Recovery (for MPC/Social Recovery users).**
    *   **User-Reported Fraud Rate on Transactions Facilitated by Wallet.**
*   **North-Star KPI (Reiteration):** **“Total Value Locked & Actively Managed (TVLAM) × User Financial Health Score Improvement (derived from Score.Fin velocity)”**

**OKRs will focus on:**
*   **Objective:** Become the preferred sovereign wallet for IONVERSE citizens.
    *   **KR1:** Achieve X active ERC-4337 smart wallets by end of Q1.
    *   **KR2:** Process Y volume via Drex-ION bridge in Q1.
    *   **KR3:** Attain an average M30 Wallet Retention of Z%.
*   **Objective:** Deliver best-in-class security and user trust.
    *   **KR1:** Successfully complete 2 external smart contract audits for all new on-chain components.
    *   **KR2:** Achieve >90% Passkey adoption among active users.

## 17. ROADMAP (Descriptive Milestones for IONWALLET)

*   **Phase 0: Core Infrastructure & Security Design (Completed)**
    *   Selection of ERC-4337 stack, WalletCore SDK, Passkey integration strategy.
    *   Security modeling (STRIDE), initial smart contract architecture for IONW and staking.
    *   Drex bridge conceptual design and regulatory consultation.
*   **Phase 1: MVP - Secure Custody & Core Token Operations (Target: Q3-Q4 2024, aligns with IONVERSE MVP)**
    *   **Focus:** Launch secure, user-controlled wallet for ION, IONW, and Base L2 ETH (for gas). Passkey creation/login. Basic send/receive. ERC-4337 account deployment.
    *   **Milestones:**
        *   Mobile (React Native/Expo) and Web PWA clients with Passkey integration.
        *   View balances for ION, IONW, ETH on Base L2.
        *   Send/receive these assets using ERC-4337 smart accounts.
        *   IONW token contract deployed; basic IONW staking contract (e.g., deposit IONW, earn more IONW).
        *   Initial integration with IONWALL for linking wallet activity to DID and basic `Score.Fin` input.
*   **Phase 2: Drex Bridge & Staking Expansion (Target: Q1 2025)**
    *   **Focus:** Launch Drex bridge MVP for BRL (Pix) ↔ tokenized Drex ↔ ION/USDC. Expand ION/IONW staking features (e.g., auto-compounding, AMM LPs).
    *   **Milestones:**
        *   Drex-ION bridge service operational for pilot users (transactions logged, security audited).
        *   Pix on-ramp to Drex/USDC functional.
        *   AMM for ION-Drex (or ION-USDC) pair with liquidity provision and fee generation.
        *   `IONPay` widget MVP for simple ION payments within IONVERSE app.
*   **Phase 3: DeFi Integration & Advanced Features (Target: Q2-Q3 2025)**
    *   **Focus:** Integrate selected DeFi protocols (lending/borrowing). Full ERC-4337 features (social recovery, session keys). NFT management.
    *   **Milestones:**
        *   NFT display and transfer capabilities for major standards on Base L2.
        *   Integration with one audited lending/borrowing protocol on Base L2.
        *   Social recovery mechanism for ERC-4337 accounts implemented and user-testable.
        *   Advanced `Score.Fin` from IONWALL visibly impacting fees or feature access.
*   **Phase 4: Cross-Chain & Real-World Expansion (Target: Q4 2025 onwards)**
    *   **Focus:** Explore further cross-chain integrations. Enhance real-world payment capabilities (e.g., NFC PoC). Mature DAO governance for IONW.
    *   **Milestones:**
        *   Pilot for cross-chain bridge beyond Drex (e.g., to another L2 or L1).
        *   Full IONW DAO governance over selected IONWALLET parameters.
        *   Partnerships for wider adoption of `IONPay`.

This roadmap is dynamic and will adapt to user feedback, technological advancements, and the regulatory landscape. The Pooldad spirit of "romper a normalidade" means constantly seeking impactful innovations in sovereign finance.
