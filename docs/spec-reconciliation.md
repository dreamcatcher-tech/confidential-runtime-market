# Spec reconciliation

## Reconciled architecture

The specs intentionally separate four concerns:

1. **Reality Ledger** — provider-neutral domain model.
2. **Settlement adapters** — Ethereum/L2/internal/GraphFS publication, payment, and anchoring.
3. **Host execution** — Foundry substrate and Bastion CVM.
4. **User runtime** — Agent CVM, OCI workload, encrypted state, and phone/KMS unlock.

## Cross-file consistency checks

- `protocol-domain-ledger.feature` defines provider-neutral primitives, including AgentEpoch, MutationRecord, HostEpoch, RuntimeClaimClosureReceipt, and ServiceReceipt so append-only closure and metering events are not hidden as mutable status fields.
- `ethereum-settlement-adapter.feature` implements those primitives as contract modules but does not redefine them.
- `runtime-marketplace.feature` uses `HostOffer` and `BootLeaseRequest` as two paths to `RuntimeClaim`, then uses `RuntimeClaimClosureReceipt`, `PaymentReceipt`, and optional `ServiceReceipt` objects for closeout and bundles.
- `host-bare-metal-bootstrap.feature` launches Bastion before any user Agent CVM.
- `bastion-cvm.feature` supervises and reports but does not own user keys.
- `agent-cvm-base-image.feature` receives scoped unlock material and owns the user workload/state.
- `oci-workload-packaging.feature` binds Docker/OCI digest into CVM policy rather than pretending a mutable Docker tag is a VM measurement.
- `phone-kms-unlock.feature` ensures both demand and supply paths pass through the same secret-release rule.
- `state-epochs-and-storage.feature` makes `AgentEpoch` and `StateCommitment` the anti-rollback anchor.
- `attestation-archive-and-watchdog.feature` captures permanent evidence without turning AI/reputation scores into key-release roots.
- `enterprise-controlled-hosts-and-billing.feature` restricts host predicates while preserving shared proof/receipt layers.

## Main reconciled invariants

```text
HostOffer or BootLeaseRequest
  -> RuntimeClaim
  -> Agent CVM attestation + BastionReport
  -> phone/KMS scoped unlock
  -> AgentEpoch + StateCommitment
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
  -> OCI workload + encrypted state
```

## Remaining design risks

1. Bastion device passthrough may be hard on some bare-metal/hypervisor stacks.
2. Full SEV-SNP/TDX attestation verification on-chain is likely not an MVP path.
3. KMS mesh must avoid becoming an all-powerful master-key service.
4. Spot eviction must be conservative until final-state proof is reliable.
5. Enterprise billing bridge has compliance/regulatory work outside pure protocol spec.
6. OCI-inside-CVM is cleaner than Docker-to-VM conversion but still requires an implementation-specific guest runtime and attestation policy.
7. Service bundles are optional but now have explicit `ServiceOffer`, `AgentRuntimeBundle`, and `ServiceReceipt` primitives so they do not leak into runtime claims implicitly.
