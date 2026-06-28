# v0 ARK Runtime Orchestrator execution report

Generated: 2026-06-28

## Repository and Pages

- Repo: https://github.com/dreamcatcher-tech/confidential-runtime-market
- GitHub Pages: https://dreamcatcher-tech.github.io/confidential-runtime-market/
- Pages workflow run: https://github.com/dreamcatcher-tech/confidential-runtime-market/actions/runs/28320617235
- Local repo path: `/opt/data/repos/confidential-runtime-market`

## Implemented vertical slice

- `contracts/ARKRuntimeOrchestrator.sol` — Solidity settlement adapter over the provider-neutral Reality Ledger.
- `test/ARKRuntimeOrchestrator.test.cjs` — Hardhat tests for medallion mint, controlled-host boot lease, allowed-host rejection, release receipt, monotonic state root, and claim closure.
- `scripts/deploy.cjs` — deploys contract and writes public deployment/site receipts.
- `site/` — static GitHub Pages app that loads the ABI/config and can read a deployed contract through a browser wallet/RPC.
- `docs/v0-vertical-slice.md` — executable slice notes and deploy commands.

## Local validation

```text
PASS: 14 feature files, 67 scenarios, 29 primitives
PASS: site validation (9 checks)
PASS: no obvious secret assignment patterns in publishable files
```

## Remote Hardhat worker proof

Heavy Ethereum harness work ran on a disposable Fly worker instead of this RAM-constrained Hermes machine.

- Work app: `ark-eth-work-0628111358`
- Work Machine: `d8d3370a3531e8`
- Node: `v20.19.1`
- npm: `10.8.2`
- Cleanup: `flyctl apps destroy ark-eth-work-0628111358 --yes`
- Destroy verification: `flyctl status --app ark-eth-work-0628111358` returned app-not-found.

Hardhat test output:

```text
ARKRuntimeOrchestrator
  ✔ mints an ARK birth certificate/medallion record
  ✔ lets an allowed host claim a controlled boot lease and bind current runtime authority
  ✔ rejects a host outside the request allowed_host_set
  ✔ records StateVault release receipts and monotonic state roots
  ✔ closes a runtime claim with a closure receipt and clears active authority

5 passing (1s)
```

## Local-devnet deployment receipt

- Network: `hardhat`
- Chain ID: `31337`
- Contract: `0x5FbDB2315678afecb367f032d93F642f64180aa3`
- Deploy tx: `0xef6b81eebd95ffe8296e7caf875813e0d3e6a938ce41c3eb9c6522dfa3ad7df6`
- Host register tx: `0xbfc367f362f5adb06c064fb009a6625896cacebf17d1c20d43a0220444dd4b4e`
- Birth-certificate mint tx: `0xa32e30e48ec549bd4a5d61d67af283ccdd8060a541f3f5fd811786a373538036`
- Boot lease request tx: `0x98004e09c24d7859a18357fd78e919b91e51dce8881faaa6d4d252ea20d6b4c9`
- Runtime claim tx: `0xc7bf7be27edd235f6a32f29da3527e98a32142125e02617f83edcf2efa67fefc`
- StateVault release receipt tx: `0x2a46b580030f926e126219f0ae7229b3fbc4e834274ba8a443b1927ea1949574`
- State root commit tx: `0xa6e75feb424a43fb56e88078522548b1dc3ac3a53e7112b5be7b2afe2a1fda84`

The hardhat deploy receipt is committed in `deployments/hardhat.json` and mirrored to `site/config.json` for the demo UI.

## Tiny Fly waiting VM test host

A tiny Fly Machine was created as a simulated waiting host/BYO CVM test target. It is **not** a real confidential VM; it is a v0 host-preflight stand-in until a real CVM provider/attestation target is approved.

```json
{
  "app": "ark-waiting-vm-0628112126",
  "machine": "e825416fd64728",
  "state": "started",
  "region": "syd",
  "image_ref": {
    "registry": "docker-hub-mirror.fly.io",
    "repository": "library/alpine",
    "tag": "3.20",
    "digest": "sha256:c64c687cbea9300178b30c95835354e34c4e4febc4badfe27102879de0483b5e"
  },
  "private_ip": "fdaa:12:8117:a7b:2dd:d920:452a:2",
  "guest": {
    "cpu_kind": "shared",
    "cpus": 1,
    "memory_mb": 256
  },
  "preflight_hash": "0x5186bf82ed19fbd1431f7623dd1f27e37af5cf088ac4f9cdd2fcb26320a7dd52"
}
```

The Hardhat HostRecord endpoint reference used this Fly test host:

```text
fly://ark-waiting-vm-0628112126/e825416fd64728
```

## GitHub Pages verification

- Live index returned HTTP 200.
- `config.json`, `app.js`, `styles.css`, and `ARKRuntimeOrchestrator.abi.json` returned HTTP 200.
- Browser desktop QA: legible; no obvious clipping, overlap, or horizontal overflow.
- Playwright tablet/mobile full-page QA: legible; no page-level horizontal overflow or overlap. Minor issue: long hex strings wrap awkwardly on mobile, but remain contained.



## Public Sepolia deployment

Completed after generating and funding a fresh deployer through the Sepolia PoW faucet.

### Faucet funding

- Deployer address: `0xbE46900C1Fb37efdea9dC75400fDdEa2bf7Fa5E7`
- Faucet: https://sepolia-faucet.pk910.de/
- Faucet session: `e398b57d-d99e-4ad6-a777-cdd2d9cc367f`
- Faucet tx: `0xb1af616e58ec2a40356d7b5118c15d6e2ccc7a9af344d8277c672c38d44b1b30`
- Faucet block: `11158908`
- Amount: `0.411 SepETH`

### Contract deployment

- Network: `sepolia`
- Chain ID: `11155111`
- Contract: `0xf32ac756ea8f12c6B7DdDb3525ff8EaA2349aB64`
- Deploy tx: `0x196e6b7f73e561edc95a0adfab024432f3c88fb33a074049c104f1ec5dca9eb0`
- Deploy block: `11158923`
- Explorer: https://sepolia.etherscan.io/address/0xf32ac756ea8f12c6B7DdDb3525ff8EaA2349aB64
- On-chain verification: `eth_getCode` returned `11221` bytes and deploy tx receipt status `0x1`.

### Demo seed transactions

- Register host tx: `0xa783afb6b7845401da8d8b51427011177c47a6ef583acbbc27ae0ab43783a6a2`
- Publish image tx: `0xc0cac8973b0c9e001a75b37b305435bb70399b4a84a656b49de75bd30d750b0c`
- Mint birth certificate tx: `0xaf899846a995e1ad1f87f1496d2fa00369a5391987d7921cb646036e48e78ca1`
- Post boot lease tx: `0x8b71e8b0ac35e5c96ea24d21898b447dd58909612d6c28d778c9dbf773429668`
- Claim boot lease tx: `0x942b6d9d92d90b0139fd095656200773eb4534d5bd15f0f5cdf1cc8c9c5ec214`
- Record release receipt tx: `0x40b0c1b89b311e2fd1b9ebeadc3b5406e3af1adec7357623e59a36fe4eda9b75`
- Commit state tx: `0xe42a9fef25a5d448dfc378c2b203e57e7373279ceba70c34b95a9dc14f8921e8`

### Sepolia deploy worker proof

Heavy Hardhat deploy/test work ran on a second disposable Fly worker.

- Deploy worker app: `ark-eth-deploy-0628143535`
- Deploy worker Machine: `683993ec531448`
- Test output: `5 passing (1s)`
- Cleanup: `flyctl apps destroy ark-eth-deploy-0628143535 --yes`
- Destroy verification: `flyctl status --app ark-eth-deploy-0628143535` returned app-not-found.

The public GitHub Pages UI now reads `site/config.json`, which points at this Sepolia contract and sample IDs.

## Public testnet deployment status

Completed on Sepolia. The committed `deployments/sepolia.json`, `deployments/latest.json`, and `site/config.json` contain public deployment receipts only. The deployer private key remains outside the repo at `/opt/data/.secrets/ark-runtime-orchestrator-deployer.env` with mode `600`.
