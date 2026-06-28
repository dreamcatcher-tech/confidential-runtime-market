# Confidential Runtime Market

Feature-driven specification repo for an attested confidential-VM runtime marketplace.

Working name: **Confidential Runtime Market**. The host supervisor CVM is named **Bastion**.

## One-sentence architecture

A provider-neutral **Reality Ledger** records user authority, recovery policy, agent epochs, host offers, boot-lease demand, attestations, state roots, receipts, and settlement anchors; Ethereum/L2 is one settlement adapter; bare-metal hosts boot a minimal substrate that launches an attested **Bastion CVM**, Bastion launches/supervises one-agent-per-CVM runtimes, and encrypted state is served by phone/StateVault/KMS policy through attested tunnels.

## Current status

- Status: v0 executable vertical-slice scaffold added on top of the feature specs.
- Initial scope: feature specs, manifests, ADRs, reconciliation checks, Solidity settlement adapter, Hardhat tests/deploy script, and GitHub Pages demo UI.
- Repo created: 2026-06-10 NZT.

## v0 ARK Runtime Orchestrator implementation

The v0 implementation lives in:

```text
contracts/ARKRuntimeOrchestrator.sol   Ethereum/L2 settlement adapter
scripts/deploy.cjs                     deploy + seed demo receipts
test/ARKRuntimeOrchestrator.test.cjs   contract flow tests
site/                                  GitHub Pages UI
scripts/validate_site.py               deterministic site validator
docs/v0-vertical-slice.md              executable slice notes
```

It records public commitments for ARK birth certificates/medallions, controlled-host boot leases, Agent-CVM runtime claims, StateVault release receipts, state roots, and closure receipts. It does not store secrets or raw private state.

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
docs/                      Design, thread capture, packaging decision, reconciliation
docs/adr/                  Architecture decisions
reports/                   Conformance/review reports
scripts/validate_specs.py  Deterministic spec sanity checks
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
