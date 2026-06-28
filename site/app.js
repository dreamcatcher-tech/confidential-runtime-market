const $ = (id) => document.getElementById(id);
let config;
let abi;
let provider;
let signer;
let contract;

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
  [config, abi] = await Promise.all([
    fetch("./config.json", { cache: "no-store" }).then(r => r.json()),
    fetch("./ARKRuntimeOrchestrator.abi.json", { cache: "no-store" }).then(r => r.json())
  ]);
  $("contractAddress").value = config.contract || "";
  $("agentId").value = config.sample?.agentId || "";
  $("claimId").value = config.sample?.claimId || "";
  factList($("contractFacts"), {
    network: config.network,
    chainId: config.chainId,
    contract: config.contract,
    deployTx: short(config.deployTx),
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
  const explorer = $("explorerLink");
  if (base !== "#" && config.contract) explorer.href = `${base}${config.contract}`;
  else explorer.removeAttribute("href");
  $("status").textContent = config.contract ? "Config loaded. Connect a wallet to read through your browser RPC." : "Config loaded, but no deployed contract address is set yet.";
}

async function connect() {
  if (!window.ethereum) throw new Error("MetaMask/window.ethereum not found");
  provider = new ethers.BrowserProvider(window.ethereum);
  await provider.send("eth_requestAccounts", []);
  signer = await provider.getSigner();
  const net = await provider.getNetwork();
  contract = new ethers.Contract($("contractAddress").value, abi, signer);
  $("status").textContent = `Connected ${await signer.getAddress()} on chain ${net.chainId}`;
}

function serialize(value) {
  return JSON.stringify(value, (_, v) => typeof v === "bigint" ? v.toString() : v, 2);
}

async function ensureContract() {
  if (!contract) await connect();
  const address = $("contractAddress").value.trim();
  if (!ethers.isAddress(address)) throw new Error("Invalid contract address");
  contract = new ethers.Contract(address, abi, signer || provider);
  return contract;
}

$("connectWallet").addEventListener("click", async () => {
  try { await connect(); } catch (err) { $("status").textContent = err.message; }
});

$("readBirth").addEventListener("click", async () => {
  try {
    const c = await ensureContract();
    const value = await c.birthByAgent($("agentId").value.trim());
    $("readOutput").textContent = serialize({ tokenId: value.tokenId, agentId: value.agentId, parentAgentId: value.parentAgentId, lineageRoot: value.lineageRoot, desirePolicyHash: value.desirePolicyHash, currentRuntimeClaimId: value.currentRuntimeClaimId, exists: value.exists });
  } catch (err) { $("readOutput").textContent = err.message; }
});

$("readClaim").addEventListener("click", async () => {
  try {
    const c = await ensureContract();
    const value = await c.runtimeClaims($("claimId").value.trim());
    $("readOutput").textContent = serialize({ requestId: value.requestId, agentId: value.agentId, hostId: value.hostId, imageId: value.imageId, stateId: value.stateId, agentCvmAttestationHash: value.agentCvmAttestationHash, vmTransportPubkeyHash: value.vmTransportPubkeyHash, stateCommitmentId: value.stateCommitmentId, pricePerSecond: value.pricePerSecond, openedAt: value.openedAt, status: value.status });
  } catch (err) { $("readOutput").textContent = err.message; }
});

loadConfig().catch((err) => { $("status").textContent = `Failed to load config: ${err.message}`; });
