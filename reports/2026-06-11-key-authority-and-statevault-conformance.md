# Key authority and StateVault spec conformance

Date: 2026-06-11 NZST

## Scope

This report covers the passkey, Ethereum wallet, phone recovery-tier, and StateVault/DEK-custody additions.

## Checks

- User recovery is explicit and tiered, not implicit platform restore.
- Passkeys improve UX for sign-in, approval, and recovery enrollment but are not the default storage-DEK root.
- Ethereum wallets sign SIWE/EIP-712 intents and payments; wallet private keys are not treated as generic encryption keys.
- MetaMask decrypt APIs are marked optional/legacy because they are documented as deprecated.
- StateVault can hold root DEKs or threshold shares near the storage plane.
- Agent CVMs receive scoped access leases by default, not durable root DEKs.
- Phone/user authority remains required for export, recovery enrollment, and policy changes.
- Public chain/Reality Ledger stores commitments and receipts only.

## Files changed

- `features/user-authority-and-recovery.feature`
- `features/state-vault-mesh.feature`
- `features/phone-kms-unlock.feature`
- `features/state-epochs-and-storage.feature`
- `features/agent-cvm-base-image.feature`
- `features/protocol-domain-ledger.feature`
- `features/reconciliation-invariants.feature`
- `manifests/primitives.yaml`
- `manifests/module-map.yaml`
- `docs/design.md`
- `docs/spec-reconciliation.md`
- `docs/adr/0004-user-authority-and-statevault.md`
- `scripts/validate_specs.py`

## Result

Deterministic validation passed:

```text
PASS: 14 feature files, 67 scenarios, 29 primitives
```
