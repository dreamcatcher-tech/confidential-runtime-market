# Confidential Runtime Market

Feature-driven specification repo for an attested confidential-VM runtime marketplace.

Working name: **Confidential Runtime Market**. The host supervisor CVM is named **Bastion**.

## One-sentence architecture

A provider-neutral **Reality Ledger** records user authority, recovery policy, birth certificates, agent epochs, host offers, boot-lease demand, attestations, state roots, receipts, and settlement anchors; Ethereum/L2 is one settlement adapter; bare-metal hosts boot a minimal substrate that launches an attested **Bastion CVM**, Bastion launches/supervises one-agent-per-CVM runtimes, and encrypted state is served by phone/StateVault/KMS policy through attested tunnels.

## High-level architecture

The executable v0 is intentionally reduced to two compatible contracts:

1. **`ARKBirthCertificate`** — a standard ERC-721 token for agent identity, lineage, desire-policy, and birth-metadata commitments.
2. **`ARKRuntimeMarketplace`** — a runtime marketplace/settlement adapter that reads `ownerOfAgent(agentId)` from the birth-certificate contract and records host/image/request/claim/state/close commitments.

```mermaid
flowchart LR
  Owner[Agent owner / principal]
  Publisher[Image publisher]
  Host[Host operator]
  Phone[Phone / KMS approval]
  Vault[StateVault]
  Ledger[Reality Ledger]
  Birth["ARKBirthCertificate\nERC-721: mint + ownerOfAgent"]
  Market["ARKRuntimeMarketplace\nregisterHost + publishImage\nrequestRuntime + claimRuntime\ncheckpointState + closeRuntime"]
  Bastion[Bastion CVM]
  Agent[Agent CVM]

  Owner -->|mint(agentId, lineageRoot, desirePolicyHash)| Birth
  Market -->|ownerOfAgent(agentId)| Birth
  Publisher -->|publishImage(imageId, ociDigest, runtimePolicyDigest)| Market
  Host -->|registerHost(hostId, allowedHostSetHash, bastionAttestationHash)| Market
  Owner -->|requestRuntime(agentId, imageId, stateId, unlockPolicyHash)| Market
  Host -->|claimRuntime(requestId, claimId, attestation, transport key)| Market
  Host --> Bastion --> Agent
  Phone -->|scoped unlock decision| Vault
  Vault -->|off-chain access lease / release receipt| Agent
  Agent -->|state root + release receipt| Host
  Host -->|checkpointState(state root, releaseReceiptHash)| Market
  Host -->|closeRuntime(closureReceiptHash)| Market
  Market -->|commitments + receipts + anchors| Ledger
```

## Typical operation sequence

```mermaid
sequenceDiagram
  autonumber
  participant Owner as Agent owner
  participant Publisher as Image publisher
  participant Birth as ARKBirthCertificate
  participant Market as ARKRuntimeMarketplace
  participant Host as Host/Bastion
  participant Vault as Phone/KMS/StateVault
  participant Agent as Agent CVM

  Owner->>Birth: mint(agentId, parentAgentId, lineageRoot, desirePolicyHash, birthMetadataHash, uri)
  Publisher->>Market: publishImage(imageId, ociDigest, runtimePolicyDigest)
  Host->>Market: registerHost(hostId, allowedHostSetHash, bastionAttestationHash, hostMetadataHash)
  Owner->>Market: requestRuntime(requestId, agentId, imageId, stateId, allowedHostSetHash, desiredSeconds, maxPricePerSecond, unlockPolicyHash)
  Market->>Birth: ownerOfAgent(agentId)
  Birth-->>Market: current ERC-721 owner
  Host->>Market: claimRuntime(requestId, claimId, hostId, agentCvmAttestationHash, vmTransportPubkeyHash, pricePerSecond)
  Host->>Agent: boot/assign measured Agent CVM
  Agent->>Vault: request scoped state access off-chain
  Vault-->>Agent: encrypted lease; releaseReceiptHash is public-safe
  Agent-->>Host: state root + releaseReceiptHash
  Host->>Market: checkpointState(claimId, stateCommitmentId, version, rootHash, previousRootHash, writerAttestationHash, releaseReceiptHash, releaseExpiry)
  Host->>Market: closeRuntime(claimId, reason, finalStateCommitmentId, closureReceiptHash)
```

## Diagram/spec conformance

The README diagrams are part of the feature contract. `features/reconciliation-invariants.feature` requires them to stay aligned with the executable contracts, and `python3 scripts/validate_specs.py` checks that:

- the README has both a Mermaid `flowchart` and `sequenceDiagram`;
- the diagrams name `ARKBirthCertificate`, `ARKRuntimeMarketplace`, `Reality Ledger`, `Bastion`, `Agent CVM`, and `StateVault`;
- the diagrams include the current core function names: `mint`, `ownerOfAgent`, `registerHost`, `publishImage`, `requestRuntime`, `claimRuntime`, `checkpointState`, and `closeRuntime`;
- the retired monolithic contract/function names are not reintroduced into active docs/code.

## Current status

- Status: v0 executable vertical-slice scaffold reduced to split birth-certificate and runtime-marketplace contracts.
- Initial scope: feature specs, manifests, ADRs, reconciliation checks, ERC-721 birth certificate, Solidity runtime marketplace adapter, Hardhat tests/deploy script, and GitHub Pages demo UI.
- Repo created: 2026-06-10 NZT.

## v0 implementation

The v0 implementation lives in:

```text
contracts/ARKBirthCertificate.sol      ERC-721 agent birth-certificate contract
contracts/ARKRuntimeMarketplace.sol    Ethereum/L2 runtime marketplace settlement adapter
scripts/deploy.cjs                     deploy + seed demo receipts
test/ARKRuntimeMarketplace.test.cjs    split-contract flow tests
site/                                  GitHub Pages UI
scripts/validate_site.py               deterministic site validator
docs/v0-vertical-slice.md              executable slice notes
```

It records public commitments for ARK birth certificates/medallions, controlled-host boot requests, Agent-CVM runtime claims, StateVault release receipts, state roots, and closure receipts. It does not store secrets or raw private state.

Run lightweight local validation with:

```bash
python3 scripts/validate_specs.py
python3 scripts/validate_site.py
```

Run the Ethereum harness on a larger/ephemeral worker when possible:

```bash
npm ci
npm test
DEPLOY_DEMO=1 npx hardhat run scripts/deploy.cjs --network hardhat
```

## Core invariants

1. One live `AgentIdentity` maps to exactly one active `RuntimeClaim`.
2. One active `RuntimeClaim` maps to exactly one active Agent CVM.
3. One active Agent CVM can unlock only the latest accepted `AgentEpoch` unless rollback policy explicitly permits otherwise.
4. Chain/ledger layers store public commitments, not secrets.
5. Phone/StateVault/KMS releases are scoped, short-lived, and encrypted to an attested runtime or vault transport key.
6. Users explicitly choose a recovery tier: local-only, multi-device, passkey-assisted, wallet-gated, hardware-key, or threshold recovery.
7. Root DEKs should remain in StateVault custody by default; Agent CVMs receive scoped state access leases unless the user opts into local DEK portability.
8. Bastion supervises host control surfaces; the user Agent CVM must not own host-management devices.
9. Slashing is limited to objective cryptographic faults; uptime/performance uncertainty leads to non-payment/downranking/dispute, not automatic slash.

## Repository layout

```text
features/                  Flat, agent-readable Gherkin specs
manifests/                 Provider-neutral primitives and module mappings
contracts/                 Solidity v0 adapter contracts
docs/                      Design, thread capture, packaging decision, reconciliation
docs/adr/                  Architecture decisions
reports/                   Conformance/review reports
scripts/validate_specs.py  Deterministic spec + diagram sanity checks
```

## Read order for future agents

1. `docs/thread-capture.md`
2. `docs/design.md`
3. `manifests/primitives.yaml`
4. `features/protocol-domain-ledger.feature`
5. `features/runtime-marketplace.feature`
6. `features/ethereum-settlement-adapter.feature`
7. `features/host-bare-metal-bootstrap.feature`
8. `features/bastion-cvm.feature`
9. `features/agent-cvm-base-image.feature`
10. `features/oci-workload-packaging.feature`
11. `features/user-authority-and-recovery.feature`
12. `features/phone-kms-unlock.feature`
13. `features/state-vault-mesh.feature`
14. `features/state-epochs-and-storage.feature`
15. `features/attestation-archive-and-watchdog.feature`
16. `features/enterprise-controlled-hosts-and-billing.feature`
17. `features/reconciliation-invariants.feature`
18. `docs/spec-reconciliation.md`

## Docker image vs CVM stance

Do **not** make every Docker image into a full bespoke VM image in the main path. Keep workloads as OCI/Docker images and run/pull/unpack them inside a measured confidential guest using a generic guest image and a small runtime agent. That is the Kata/Confidential-Containers-style path and keeps publisher UX simple.

Converting OCI images to bootable VM images is possible, e.g. `d2vm`, but treat it as a fallback for appliances or early demos because it increases image sprawl and attestation/versioning burden.

## User authority stance

Passkeys are good UX for sign-in, re-enrollment, and approval prompts, but they are not the default root storage DEK. Ethereum wallets are good for SIWE/EIP-712 intent, ownership, payment, and continuity, but wallet signing is separate from encryption. MetaMask-style wallet decryption is treated as an optional legacy adapter, not a core dependency.

## StateVault stance

Prefer a StateVault/storage mesh that keeps root DEK custody near the encrypted data plane and issues scoped object/file/mount leases to Agent CVMs. This means a working Hermes/Agent CVM normally does not carry a durable DEK; the phone proves authority for approval, recovery, export, and vault policy changes.
