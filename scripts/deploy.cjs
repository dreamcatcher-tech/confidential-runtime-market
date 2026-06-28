const fs = require("fs");
const path = require("path");
const { ethers, network } = require("hardhat");

const id = (label) => ethers.id(label);
const rel = (...parts) => path.join(__dirname, "..", ...parts);

async function main() {
  const [deployer] = await ethers.getSigners();
  if (!deployer) throw new Error("No deployer signer. Set DEPLOYER_PRIVATE_KEY/WALLET_PRIVATE_KEY/PRIVATE_KEY for live networks.");

  const chain = await ethers.provider.getNetwork();
  console.log(`Deploying ARKRuntimeOrchestrator to ${network.name} chainId=${chain.chainId} as ${deployer.address}`);

  const Contract = await ethers.getContractFactory("ARKRuntimeOrchestrator");
  const contract = await Contract.deploy();
  await contract.waitForDeployment();
  const address = await contract.getAddress();
  const deployTx = contract.deploymentTransaction();
  console.log(`contract=${address}`);
  console.log(`deploy_tx=${deployTx.hash}`);

  const txs = { deploy: deployTx.hash };
  const demo = process.env.DEPLOY_DEMO !== "0";
  const sample = {
    hostId: id("host:fly-waiting-vm"),
    allowedHostSetHash: id("allowed-host-set:tom-controlled"),
    bastionAttestationHash: id("bastion-attestation:fly-preflight"),
    hardwareProfileHash: id("hardware-profile:fly-shared-cpu-256mb"),
    imageId: id("image:ark-agent:v0"),
    ociDigest: id("oci:dreamcatcher/ark-agent@sha256-demo"),
    runtimePolicyDigest: id("runtime-policy:ark-agent-cvm-v0"),
    agentId: id("agent:ark-demo"),
    parentAgentId: id("agent:parent-template"),
    lineageRoot: id("lineage:ark-demo-parenthood"),
    desirePolicyHash: id("desire-policy:serve-principal"),
    stateId: id("state:ark-demo"),
    requestId: id("request:ark-demo"),
    claimId: id("claim:ark-demo:fly-waiting-vm"),
    unlockPolicyHash: id("unlock-policy:statevault-scoped-lease"),
    agentCvmAttestationHash: id("agent-cvm-attestation:fly-preflight"),
    vmTransportPubkeyHash: id("vm-transport-pubkey:fly-preflight"),
    releaseReceiptHash: id("release-receipt:statevault-lease"),
    stateCommitmentId: id("state-commitment:v1"),
    stateRoot: id("state-root:v1"),
  };

  if (demo) {
    let r;
    r = await (await contract.registerHost(sample.hostId, sample.allowedHostSetHash, sample.bastionAttestationHash, sample.hardwareProfileHash, process.env.FLY_WAITING_VM_REF || "fly://pending-waiting-vm")).wait();
    txs.registerHost = r.hash;
    r = await (await contract.publishImage(sample.imageId, sample.ociDigest, sample.runtimePolicyDigest, "ipfs://ark-image-metadata-demo")).wait();
    txs.publishImage = r.hash;
    r = await (await contract.mintArkBirthCertificate(sample.agentId, sample.parentAgentId, sample.lineageRoot, sample.desirePolicyHash, "ipfs://ark-birth-certificate-demo")).wait();
    txs.mintBirthCertificate = r.hash;
    r = await (await contract.postBootLeaseRequest(sample.requestId, sample.agentId, sample.imageId, sample.stateId, sample.allowedHostSetHash, 3600, 1_000_000n, sample.unlockPolicyHash, { value: 0 })).wait();
    txs.postBootLeaseRequest = r.hash;
    r = await (await contract.claimBootLease(sample.requestId, sample.claimId, sample.hostId, sample.agentCvmAttestationHash, sample.vmTransportPubkeyHash, ethers.ZeroHash, 1000n)).wait();
    txs.claimBootLease = r.hash;
    const block = await ethers.provider.getBlock("latest");
    r = await (await contract.recordReleaseReceipt(sample.claimId, ethers.ZeroHash, sample.releaseReceiptHash, block.timestamp + 3600)).wait();
    txs.recordReleaseReceipt = r.hash;
    r = await (await contract.commitState(sample.claimId, sample.stateCommitmentId, 1, sample.stateRoot, ethers.ZeroHash, sample.agentCvmAttestationHash)).wait();
    txs.commitState = r.hash;
  }

  const artifact = JSON.parse(fs.readFileSync(rel("artifacts", "contracts", "ARKRuntimeOrchestrator.sol", "ARKRuntimeOrchestrator.json"), "utf8"));
  fs.mkdirSync(rel("deployments"), { recursive: true });
  fs.mkdirSync(rel("site"), { recursive: true });
  const receipt = {
    network: network.name,
    chainId: Number(chain.chainId),
    contract: address,
    deployer: deployer.address,
    deployTx: deployTx.hash,
    txs,
    sample,
    generatedAt: new Date().toISOString()
  };
  fs.writeFileSync(rel("deployments", `${network.name}.json`), JSON.stringify(receipt, null, 2));
  fs.writeFileSync(rel("deployments", "latest.json"), JSON.stringify(receipt, null, 2));
  fs.writeFileSync(rel("site", "ARKRuntimeOrchestrator.abi.json"), JSON.stringify(artifact.abi, null, 2));
  fs.writeFileSync(rel("site", "config.json"), JSON.stringify({
    network: network.name,
    chainId: Number(chain.chainId),
    contract: address,
    deployTx: deployTx.hash,
    sample,
    txs,
    generatedAt: receipt.generatedAt
  }, null, 2));
  console.log(`wrote deployments/${network.name}.json and site/config.json`);
}

main().catch((err) => {
  console.error(err.message || err);
  process.exitCode = 1;
});
