const $ = (id) => document.getElementById(id);
let config;
let birthAbi;
let marketplaceAbi;
let provider;
let signer;
let birthContract;
let marketplaceContract;

const explorerByChain = {
  1: "https://etherscan.io/address/",
  11155111: "https://sepolia.etherscan.io/address/",
  84532: "https://sepolia.basescan.org/address/",
  31337: "#"
};

function factList(el, facts) {
  el.innerHTML = Object.entries(facts).map(([k, v]) => `<dt>${k}</dt><dd>${String(v ?? "—")}</dd>`).join("");
}

function short(value) {
  if (!value) return "—";
  return value.length > 22 ? `${value.slice(0, 10)}…${value.slice(-8)}` : value;
}

async function loadConfig() {
  [config, birthAbi, marketplaceAbi] = await Promise.all([
    fetch("./config.json", { cache: "no-store" }).then(r => r.json()),
    fetch("./ARKBirthCertificate.abi.json", { cache: "no-store" }).then(r => r.json()),
    fetch("./ARKRuntimeMarketplace.abi.json", { cache: "no-store" }).then(r => r.json())
  ]);
  $("birthAddress").value = config.contracts?.birthCertificate || "";
  $("marketplaceAddress").value = config.contracts?.marketplace || "";
  $("agentId").value = config.sample?.agentId || "";
  $("claimId").value = config.sample?.claimId || "";
  factList($("contractFacts"), {
    network: config.network,
    chainId: config.chainId,
    birthCertificate: config.contracts?.birthCertificate,
    marketplace: config.contracts?.marketplace,
    birthDeployTx: short(config.deployTxs?.birthCertificate),
    marketplaceDeployTx: short(config.deployTxs?.marketplace),
    generatedAt: config.generatedAt
  });
  factList($("sampleFacts"), {
    agentId: config.sample?.agentId,
    imageId: config.sample?.imageId,
    hostId: config.sample?.hostId,
    allowedHostSet: config.sample?.allowedHostSetHash,
    requestId: config.sample?.requestId,
    claimId: config.sample?.claimId,
    stateId: config.sample?.stateId
  });
  const base = explorerByChain[Number(config.chainId)] || "#";
  setExplorer($("birthExplorerLink"), base, config.contracts?.birthCertificate);
  setExplorer($("marketplaceExplorerLink"), base, config.contracts?.marketplace);
  $("status").textContent = config.contracts?.marketplace ? "Config loaded. Connect a wallet to read through your browser RPC." : "Config loaded, but deployed contract addresses are not set yet.";
}

function setExplorer(el, base, address) {
  if (base !== "#" && address) el.href = `${base}${address}`;
  else el.removeAttribute("href");
}

async function connect() {
  if (!window.ethereum) throw new Error("MetaMask/window.ethereum not found");
  provider = new ethers.BrowserProvider(window.ethereum);
  await provider.send("eth_requestAccounts", []);
  signer = await provider.getSigner();
  const net = await provider.getNetwork();
  birthContract = new ethers.Contract($("birthAddress").value, birthAbi, signer);
  marketplaceContract = new ethers.Contract($("marketplaceAddress").value, marketplaceAbi, signer);
  $("status").textContent = `Connected ${await signer.getAddress()} on chain ${net.chainId}`;
}

function serialize(value) {
  return JSON.stringify(value, (_, v) => typeof v === "bigint" ? v.toString() : v, 2);
}

async function ensureBirthContract() {
  if (!birthContract) await connect();
  const address = $("birthAddress").value.trim();
  if (!ethers.isAddress(address)) throw new Error("Invalid birth certificate address");
  birthContract = new ethers.Contract(address, birthAbi, signer || provider);
  return birthContract;
}

async function ensureMarketplaceContract() {
  if (!marketplaceContract) await connect();
  const address = $("marketplaceAddress").value.trim();
  if (!ethers.isAddress(address)) throw new Error("Invalid marketplace address");
  marketplaceContract = new ethers.Contract(address, marketplaceAbi, signer || provider);
  return marketplaceContract;
}

$("connectWallet").addEventListener("click", async () => {
  try { await connect(); } catch (err) { $("status").textContent = err.message; }
});

$("readBirth").addEventListener("click", async () => {
  try {
    const c = await ensureBirthContract();
    const value = await c.birthByAgent($("agentId").value.trim());
    const owner = value.exists ? await c.ownerOfAgent($("agentId").value.trim()) : null;
    $("readOutput").textContent = serialize({ tokenId: value.exists ? await c.tokenByAgent($("agentId").value.trim()) : 0, owner, agentId: value.agentId, parentAgentId: value.parentAgentId, lineageRoot: value.lineageRoot, desirePolicyHash: value.desirePolicyHash, birthMetadataHash: value.birthMetadataHash, mintedAt: value.mintedAt, exists: value.exists });
  } catch (err) { $("readOutput").textContent = err.message; }
});

$("readClaim").addEventListener("click", async () => {
  try {
    const c = await ensureMarketplaceContract();
    const value = await c.runtimeClaims($("claimId").value.trim());
    $("readOutput").textContent = serialize({ requestId: value.requestId, agentId: value.agentId, hostId: value.hostId, imageId: value.imageId, stateId: value.stateId, agentCvmAttestationHash: value.agentCvmAttestationHash, vmTransportPubkeyHash: value.vmTransportPubkeyHash, stateCommitmentId: value.stateCommitmentId, pricePerSecond: value.pricePerSecond, openedAt: value.openedAt, status: value.status });
  } catch (err) { $("readOutput").textContent = err.message; }
});

loadConfig().catch((err) => { $("status").textContent = `Failed to load config: ${err.message}`; });
