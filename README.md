# Confidential Runtime Market

Feature-driven specification repo for an attested confidential-VM runtime marketplace.

Working name: **Confidential Runtime Market**. The host supervisor CVM is named **Bastion**.

## One-sentence architecture

A provider-neutral **Reality Ledger** records agent epochs, host offers, boot-lease demand, attestations, state roots, receipts, and settlement anchors; Ethereum/L2 is one settlement adapter; bare-metal hosts boot a minimal substrate that launches an attested **Bastion CVM**, and Bastion launches/supervises one-agent-per-CVM runtimes whose encrypted state is unlocked only by phone/KMS policy through attested tunnels.

## Current status

- Status: specification scaffold, no production code yet.
- Initial scope: feature specs, manifests, ADRs, and reconciliation checks.
- Repo created: 2026-06-10 NZT.

## Core invariants

1. One live `AgentIdentity` maps to exactly one active `RuntimeClaim`.
2. One active `RuntimeClaim` maps to exactly one active Agent CVM.
3. One active Agent CVM can unlock only the latest accepted `AgentEpoch` unless rollback policy explicitly permits otherwise.
4. Chain/ledger layers store public commitments, not secrets.
5. Phone/KMS releases are scoped, short-lived, and encrypted to an attested runtime transport key.
6. Bastion supervises host control surfaces; the user Agent CVM must not own host-management devices.
7. Slashing is limited to objective cryptographic faults; uptime/performance uncertainty leads to non-payment/downranking/dispute, not automatic slash.

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
11. `features/phone-kms-unlock.feature`
12. `features/state-epochs-and-storage.feature`
13. `features/attestation-archive-and-watchdog.feature`
14. `features/enterprise-controlled-hosts-and-billing.feature`
15. `features/reconciliation-invariants.feature`
16. `docs/spec-reconciliation.md`

## Docker image vs CVM stance

Do **not** make every Docker image into a full bespoke VM image in the main path. Keep workloads as OCI/Docker images and run/pull/unpack them inside a measured confidential guest using a generic guest image and a small runtime agent. That is the Kata/Confidential-Containers-style path and keeps publisher UX simple.

Converting OCI images to bootable VM images is possible, e.g. `d2vm`, but treat it as a fallback for appliances or early demos because it increases image sprawl and attestation/versioning burden.
