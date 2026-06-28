# v0 ARK Runtime Orchestrator vertical slice

This implementation is the smallest executable bridge from the existing specification scaffold to a deployable Ethereum/L2 settlement adapter plus a browser UI.

## Boundary

The Solidity contract is an **adapter** over the provider-neutral Reality Ledger model. It stores public commitments only:

- ARK birth-certificate / medallion commitments;
- host/Bastion and Agent-CVM attestation hashes;
- immutable OCI image and runtime-policy digests;
- controlled-host `allowed_host_set` hashes;
- boot-lease requests and runtime claims;
- StateVault release receipt hashes;
- monotonic state-root commitments;
- runtime-claim closure receipts.

It does **not** store secrets, raw private state, provider credentials, full bulky attestations, or unlock payloads.

## Demo flow

1. Register a host or BYO CVM as a `HostRecord` with a Bastion attestation/preflight commitment.
2. Publish an ARK OCI image digest and runtime-policy digest.
3. Mint an ARK birth-certificate medallion with lineage and desire-policy commitments.
4. Post a boot lease restricted by `allowed_host_set`.
5. Let the matching host claim the lease with Agent-CVM attestation and transport-key commitments.
6. Record a redacted StateVault/KMS release receipt.
7. Commit the first monotonic state root.
8. Optionally close or fail over the claim with a closure receipt.

## Verification commands

```bash
python3 scripts/validate_specs.py
python3 scripts/validate_site.py
npm ci
npm test
DEPLOY_DEMO=1 npx hardhat run scripts/deploy.cjs --network hardhat
```

Live testnet deployment requires a funded deployer and RPC URL, supplied only as environment variables:

```bash
DEPLOYER_PRIVATE_KEY=... SEPOLIA_RPC_URL=... DEPLOY_DEMO=1 npm run deploy:sepolia
# or
DEPLOYER_PRIVATE_KEY=... BASE_SEPOLIA_RPC_URL=... DEPLOY_DEMO=1 npm run deploy:base-sepolia
```

The deploy script writes `deployments/<network>.json`, `deployments/latest.json`, `site/config.json`, and `site/ARKRuntimeOrchestrator.abi.json`.

## Fly waiting-VM proof shape

A tiny Fly Machine can act as a simulated waiting host/BYO CVM for v0 by producing a host preflight receipt. The Fly Machine is not a real confidential VM unless the selected provider target exposes a real CVM attestation path. For v0, the receipt is recorded as `bastionAttestationHash` / `agentCvmAttestationHash` test evidence and should be replaced by real TEE evidence when a provider target is approved.
