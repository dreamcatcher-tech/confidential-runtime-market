# v0 split-contract vertical slice

This implementation is the smallest executable bridge from the existing specification scaffold to a deployable Ethereum/L2 settlement adapter plus a browser UI.

## Boundary

The Solidity contracts are **adapters** over the provider-neutral Reality Ledger model. They store public commitments only:

- ARK birth-certificate / medallion commitments in an ERC-721-compatible `ARKBirthCertificate` contract;
- host/Bastion and Agent-CVM attestation hashes in `ARKRuntimeMarketplace`;
- immutable OCI image and runtime-policy digests;
- controlled-host `allowed_host_set` hashes;
- prepaid runtime requests and runtime claims;
- StateVault release receipt hashes embedded in state checkpoints;
- monotonic state-root commitments;
- runtime-claim closure receipts.

They do **not** store secrets, raw private state, provider credentials, full bulky attestations, or unlock payloads.

## Why the split is smaller

Birth certificates are durable identity/provenance artifacts and benefit from a standard NFT surface. Runtime claims are operational, mutable marketplace state. Separating them means runtime contracts only need `ownerOfAgent(agentId)` compatibility instead of custom token ownership logic, and the birth-certificate contract can evolve without redeploying the runtime marketplace.

`checkpointState` intentionally combines the prior separate release-receipt and state-root operations. For v0, the public proof we need is one checkpoint: which claim wrote which state root, and which redacted StateVault/KMS release receipt supported that write.

## Demo flow

1. Mint an ARK birth-certificate medallion with lineage, desire-policy, and metadata commitments.
2. Register a host or BYO CVM as a `HostRecord` with a Bastion attestation/preflight commitment.
3. Publish an ARK OCI image digest and runtime-policy digest.
4. Post a runtime request restricted by `allowed_host_set`.
5. Let the matching host claim the request with Agent-CVM attestation and transport-key commitments.
6. Checkpoint the first monotonic state root with a redacted StateVault/KMS release receipt.
7. Optionally close or fail over the claim with a closure receipt.

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

The deploy script writes `deployments/<network>.json`, `deployments/latest.json`, `site/config.json`, `site/ARKBirthCertificate.abi.json`, and `site/ARKRuntimeMarketplace.abi.json`.

## Fly waiting-VM proof shape

A tiny Fly Machine can act as a simulated waiting host/BYO CVM for v0 by producing a host preflight receipt. The Fly Machine is not a real confidential VM unless the selected provider target exposes a real CVM attestation path. For v0, the receipt is recorded as `bastionAttestationHash` / `agentCvmAttestationHash` test evidence and should be replaced by real TEE evidence when a provider target is approved.
