# Agent instructions for this repo

This is a feature-driven specification repository. The `.feature` files are contracts for future implementation and conformance, not Cucumber tests with step definitions yet.

## Operating rules

- Keep features flat under `features/*.feature`.
- Do not put secrets or provider credentials in this repo.
- Preserve the split between provider-neutral protocol primitives and Ethereum-specific implementation.
- Treat Ethereum as a settlement/anchoring adapter, not the canonical domain model.
- Do not collapse Bastion CVM and Agent CVM roles.
- For technical claims, update `docs/docker-to-cvm-decision.md` or `docs/design.md` with sources.
- After changes, run `python3 scripts/validate_specs.py`.
- Commit completed spec changes.

## Vocabulary

- **Reality Ledger**: provider-neutral append-only domain ledger for epochs, state roots, attestations, receipts, offers, claims, disputes, and anchors.
- **Settlement Adapter**: Ethereum/L2, GraphFS chain, or internal fiat ledger implementation of selected Reality Ledger publication/settlement duties.
- **Bastion CVM**: first host confidential VM, the attested supervisor/watchdog/control-plane inside each physical host.
- **Agent CVM**: user workload CVM, one active agent identity per live runtime claim.
- **Foundry substrate**: minimal bare-metal host bootstrap/hypervisor layer whose job is to launch and isolate Bastion.
