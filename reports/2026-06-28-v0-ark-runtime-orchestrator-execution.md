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

## Public testnet deployment status

Blocked pending deploy target/custody input.

I found GitHub and Fly credentials, but no usable Ethereum testnet deploy set in the environment:

- missing funded deployer key variable such as `DEPLOYER_PRIVATE_KEY` / `WALLET_PRIVATE_KEY`;
- missing testnet RPC variable such as `SEPOLIA_RPC_URL` or `BASE_SEPOLIA_RPC_URL`;
- no evidence of testnet funds for a deployer account.

The repo is ready for either:

```bash
DEPLOYER_PRIVATE_KEY=... SEPOLIA_RPC_URL=... DEPLOY_DEMO=1 npm run deploy:sepolia
```

or:

```bash
DEPLOYER_PRIVATE_KEY=... BASE_SEPOLIA_RPC_URL=... DEPLOY_DEMO=1 npm run deploy:base-sepolia
```

Running this will update `deployments/<network>.json`, `deployments/latest.json`, `site/config.json`, and the live Pages UI after commit/push.

## Remaining approval needed

Choose one:

1. Provide a funded Sepolia/Base Sepolia deployer key and RPC URL through the approved secret path; or
2. Ask Hermes to generate a fresh deployer address, you fund it with testnet ETH, then Hermes deploys; or
3. Accept the current hardhat-devnet + GitHub Pages proof as v0 and schedule public-testnet deployment as the next goal.
