# Thread capture

Source: Telegram voice-note design thread, 2026-06-09 to 2026-06-10 NZT.

Primary research note:

- `/opt/data/notes/Research/2026-06-09 Ethereum-Coordinated Confidential VM Fleet Unlock.md`

Adjacent notes:

- `/opt/data/notes/Inbox/2026-06-08 Adaptive Agentic Chain as Integration Superset and Value Ledger.md`
- `/opt/data/notes/Inbox/2026-06-10 Confidential Runtime Marketplace Billing Extension.md`
- `/opt/data/notes/Inbox/2026-06-10 Biometric Approval Queue as Secret Delivery Surface.md`

## Distilled user requirements

1. Create a project repo and feature specs for the confidential runtime marketplace.
2. Split smart-contract design into:
   - provider-neutral protocol/domain abstraction;
   - Ethereum/L2 implementation of that abstraction.
3. Include agent epochs and related primitives independently from Ethereum.
4. Specify host software that boots on bare metal and launches the first host confidential VM.
5. Specify the first host CVM and choose a name. Decision: **Bastion CVM**.
6. Specify the minimum Agent CVM base image and Docker/OCI workload story.
7. Decide whether Docker images should be converted into VMs or run as OCI payloads inside CVMs.
8. Reconcile specs so the abstractions fit together cleanly.

## Important prior-session recall

A related session concluded that the confidential VM marketplace does not inherently need Ethereum. It needs an append-only reality log, anti-rollback state roots, host/runtime attestations, payments or credits, dispute/reputation evidence, key-release receipts, and canonical live-agent mapping. Ethereum is valuable as public money, public finality, public dispute anchor, stablecoin escrow, onboarding rails, anti-equivocation, and portable reputation.

The recommended structure was:

```text
Canonical domain ledger:
  GraphFS/N3 event log
  agent epochs
  state roots
  attestations
  evidence bundles
  runtime claims
  key-release receipts

Settlement adapters:
  Ethereum / L2
  internal fiat ledger
  future GraphFS app-chain
  maybe other chains later

Anchors:
  periodic root hash
  dispute root
  payment/escrow state
  public attestation commitment
```

Therefore this repo defines a provider-neutral **Reality Ledger** first, then an Ethereum/L2 adapter.
