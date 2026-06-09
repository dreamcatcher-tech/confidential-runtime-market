# Baseline spec conformance report

Date: 2026-06-10T00:32:04+1200 NZST
Repo: `/opt/data/repos/confidential-runtime-market`

## Scope

Initial feature-driven specification scaffold for the confidential runtime market:

- provider-neutral Reality Ledger protocol primitives;
- Ethereum/L2 settlement adapter;
- two-sided runtime marketplace;
- Foundry bare-metal host bootstrap;
- Bastion host supervisor CVM;
- Agent CVM base image;
- OCI workload packaging inside CVMs;
- phone/KMS scoped unlock;
- state epochs and encrypted storage;
- permanent attestation archive and watchdog evidence;
- enterprise controlled-host and billing bridge;
- cross-spec reconciliation invariants.

## Deterministic validation

Command:

```bash
python3 scripts/validate_specs.py
```

Observed output:

```text
PASS: 12 feature files, 52 scenarios, 21 primitives
```

## Review pass

Three focused reviews were run before finalization:

1. Provider-neutral protocol vs Ethereum adapter.
2. Foundry/Bastion/Agent CVM and OCI packaging coherence.
3. Feature-driven repo completeness and cross-spec reconciliation.

Initial review gaps found and fixed:

- Added explicit `RuntimeClaimClosureReceipt` so claim close/cutover/eviction is append-only rather than just mutable status.
- Added explicit `MutationRecord` so mutating external actions are first-class epoch objects.
- Added explicit `HostEpoch` so high-frequency host telemetry batches have a primitive.
- Added explicit `ServiceReceipt` so bundled service credits have metering/settlement receipts.
- Expanded `manifests/module-map.yaml` to align with provider-neutral primitive coverage.
- Updated Ethereum adapter feature to map `PaymentReceipt` via `PaymentEscrow` and `DisputePatch` via `DisputeRegistry`.
- Updated demand-side `BootLeaseRequest` scenario to include `agent_id`, `state_id`, and spot policy fields.
- Replaced stale “guardian” terminology with **Bastion**.
- Expanded README read order to include all reconciliation-critical features.

Final review result:

```text
PASS
- validate_specs.py passed.
- old guardian/guard terminology search returned 0 matches.
- no remaining reconciliation gaps found.
```

## Decision notes

- Host supervisor CVM name: **Bastion CVM**.
- Bare-metal bootstrap layer: **Foundry substrate**.
- Domain abstraction: **Reality Ledger**.
- Ethereum role: settlement/anchoring adapter, not the canonical domain model.
- Docker/OCI decision: default to OCI workload inside a generic measured Agent CVM; Docker-to-VM conversion is fallback only.

## Remaining open questions

See `manifests/open-questions.yaml` for current open product/platform/security questions.
