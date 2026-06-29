# Spec reconciliation

## Reconciled architecture

The specs intentionally separate six concerns:

1. **Reality Ledger** — provider-neutral domain model.
2. **Settlement adapters** — Ethereum/L2/internal/GraphFS publication, payment, and anchoring.
3. **User authority** — phone, passkey, wallet, hardware-key, recovery, and threshold policy.
4. **State custody** — StateVault/KMS storage mesh, DEK wrappers, access leases, and export.
5. **Host execution** — Foundry substrate and Bastion CVM.
6. **User runtime** — Agent CVM, OCI workload, encrypted state access, and phone/StateVault/KMS unlock.

## Cross-file consistency checks

- `protocol-domain-ledger.feature` defines provider-neutral primitives, including BirthCertificate, UserAuthority, UnlockPolicy, RecoveryEnrollment, WrappedDEKRecord, StateVaultRecord, StateVaultAccessLease, DataExportReceipt, VaultCustodyReceipt, AgentEpoch, MutationRecord, HostEpoch, RuntimeClaimClosureReceipt, and ServiceReceipt so authority, storage custody, closure, and metering events are not hidden as mutable status fields.
- `ethereum-settlement-adapter.feature` implements the MVP as a split `ARKBirthCertificate` ERC-721 contract plus an `ARKRuntimeMarketplace` adapter, while preserving Reality Ledger roots for primitives that do not yet need dedicated methods.
- `runtime-marketplace.feature` uses `ownerOfAgent(agent_id)` birth-certificate ownership to authorize runtime requests, uses `BootLeaseRequest` as the MVP path to `RuntimeClaim`, and keeps `HostOffer` as a compatible ledger primitive for later direct-claim flows.
- `user-authority-and-recovery.feature` makes recovery a user-visible tier: local-only, multi-device, passkey-assisted, wallet-gated, hardware-key, or threshold recovery.
- `phone-kms-unlock.feature` ensures both demand and supply paths pass through the same secret-release rule and treats wallet signatures as scoped intent, not DEK derivation.
- `state-vault-mesh.feature` keeps root DEK custody with storage/vault services by default and gives Agent CVMs scoped access leases.
- `host-bare-metal-bootstrap.feature` launches Bastion before any user Agent CVM.
- `bastion-cvm.feature` supervises and reports but does not own user keys.
- `agent-cvm-base-image.feature` receives scoped unlock or StateVault access material and owns the user workload/state mutations.
- `oci-workload-packaging.feature` binds Docker/OCI digest into CVM policy rather than pretending a mutable Docker tag is a VM measurement.
- `state-epochs-and-storage.feature` makes `AgentEpoch` and `StateCommitment` the anti-rollback anchor even when StateVault serves data.
- `attestation-archive-and-watchdog.feature` captures permanent evidence without turning AI/reputation scores into key-release roots.
- `enterprise-controlled-hosts-and-billing.feature` restricts host predicates while preserving shared proof/receipt layers.

## Main reconciled invariants

```text
UserAuthority + UnlockPolicy
  -> RuntimeClaim / StateVaultAccessLease approval
  -> KMSReleaseReceipt / DataExportReceipt / RecoveryEnrollment
```

```text
ARKBirthCertificate (ERC-721)
  -> ownerOfAgent(agent_id)
  -> ARKRuntimeMarketplace requestRuntime / claimRuntime
  -> Agent CVM attestation + BastionReport
  -> phone/StateVault/KMS scoped unlock or access lease
  -> AgentEpoch + StateCommitment via checkpointState
  -> KMSReleaseReceipt + RuntimeClaimClosureReceipt
  -> PaymentReceipt + optional ServiceReceipt
  -> SettlementAnchor
```

```text
Reality Ledger primitive
  -> Ethereum/L2 commitment
  -> GraphFS/internal replay remains possible
```

```text
Foundry substrate
  -> Bastion CVM
  -> Agent CVM
  -> OCI workload + encrypted state access
```

## Wallet and passkey reconciliation

Passkeys improve UX for login, approval prompts, and device re-enrollment. They are allowed to recover authority only according to explicit `UnlockPolicy`; they do not silently recover a local-only DEK.

Ethereum wallets provide ownership, payment, and signed intent through SIWE/EIP-712. Wallet decryption is not a core dependency. MetaMask `eth_getEncryptionPublicKey` and `eth_decrypt` are documented as deprecated, so any wallet-decrypt path is optional and must have a non-deprecated alternative.

## Remaining design risks

1. Bastion device passthrough may be hard on some bare-metal/hypervisor stacks.
2. Full SEV-SNP/TDX attestation verification on-chain is likely not an MVP path.
3. StateVault/KMS mesh must avoid becoming an all-powerful master-key service.
4. StateVault streaming/mount semantics must be precise enough that Agent CVMs can work without holding durable root DEKs.
5. Spot eviction must be conservative until final-state proof is reliable.
6. Enterprise billing bridge has compliance/regulatory work outside pure protocol spec.
7. OCI-inside-CVM is cleaner than Docker-to-VM conversion but still requires an implementation-specific guest runtime and attestation policy.
8. Service bundles are optional but now have explicit `ServiceOffer`, `AgentRuntimeBundle`, and `ServiceReceipt` primitives so they do not leak into runtime claims implicitly.
9. Passkey recovery UX depends on Apple/Google/password-manager ecosystems and must be disclosed as a trust tradeoff.
10. Wallet-gated recovery depends on wallet continuity; smart-contract wallets and social recovery may need separate adapters.
