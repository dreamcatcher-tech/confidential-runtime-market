const fs = require("fs");
const path = require("path");
const { ethers, network } = require("hardhat");

const id = (label) => ethers.id(label);
const rel = (...parts) => path.join(__dirname, "..", ...parts);

async function main() {
  const [deployer] = await ethers.getSigners();
  if (!deployer) throw new Error("No deployer signer. Set DEPLOYER_PRIVATE_KEY/WALLET_PRIVATE_KEY/PRIVATE_KEY for live networks.");

  const chain = await ethers.provider.getNetwork();
  console.log(`Deploying ARKBirthCertificate + ARKRuntimeMarketplace to ${network.name} chainId=${chain.chainId} as ${deployer.address}`);

  const Birth = await ethers.getContractFactory("ARKBirthCertificate");
  const birth = await Birth.deploy();
  await birth.waitForDeployment();
  const birthAddress = await birth.getAddress();
  const birthDeployTx = birth.deploymentTransaction();
  console.log(`birth_certificate=${birthAddress}`);
  console.log(`birth_deploy_tx=${birthDeployTx.hash}`);

  const Market = await ethers.getContractFactory("ARKRuntimeMarketplace");
  const marketplace = await Market.deploy(birthAddress);
  await marketplace.waitForDeployment();
  const marketplaceAddress = await marketplace.getAddress();
  const marketplaceDeployTx = marketplace.deploymentTransaction();
  console.log(`marketplace=${marketplaceAddress}`);
  console.log(`marketplace_deploy_tx=${marketplaceDeployTx.hash}`);

  const txs = {
    deployBirthCertificate: birthDeployTx.hash,
    deployMarketplace: marketplaceDeployTx.hash
  };
  const demo = process.env.DEPLOY_DEMO !== "0";
  const sample = {
    hostId: id("host:fly-waiting-vm"),
    allowedHostSetHash: id("allowed-host-set:tom-controlled"),
    bastionAttestationHash: id("bastion-attestation:fly-preflight"),
    hostMetadataHash: id(process.env.FLY_WAITING_VM_REF || "host-metadata:pending-waiting-vm"),
    imageId: id("image:ark-agent:v0"),
    ociDigest: id("oci:dreamcatcher/ark-agent@sha256-demo"),
    runtimePolicyDigest: id("runtime-policy:ark-agent-cvm-v0"),
    agentId: id("agent:ark-demo"),
    parentAgentId: id("agent:parent-template"),
    lineageRoot: id("lineage:ark-demo-parenthood"),
    desirePolicyHash: id("desire-policy:serve-principal"),
    birthMetadataHash: id("birth-metadata:ark-demo"),
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
    r = await (await marketplace.registerHost(sample.hostId, sample.allowedHostSetHash, sample.bastionAttestationHash, sample.hostMetadataHash)).wait();
    txs.registerHost = r.hash;
    r = await (await marketplace.publishImage(sample.imageId, sample.ociDigest, sample.runtimePolicyDigest)).wait();
    txs.publishImage = r.hash;
    r = await (await birth.mint(sample.agentId, sample.parentAgentId, sample.lineageRoot, sample.desirePolicyHash, sample.birthMetadataHash, "ipfs://ark-birth-certificate-demo")).wait();
    txs.mintBirthCertificate = r.hash;
    r = await (await marketplace.requestRuntime(sample.requestId, sample.agentId, sample.imageId, sample.stateId, sample.allowedHostSetHash, 3600, 1_000_000n, sample.unlockPolicyHash, { value: 0 })).wait();
    txs.requestRuntime = r.hash;
    r = await (await marketplace.claimRuntime(sample.requestId, sample.claimId, sample.hostId, sample.agentCvmAttestationHash, sample.vmTransportPubkeyHash, 1000n)).wait();
    txs.claimRuntime = r.hash;
    const block = await ethers.provider.getBlock("latest");
    r = await (await marketplace.checkpointState(sample.claimId, sample.stateCommitmentId, 1, sample.stateRoot, ethers.ZeroHash, sample.agentCvmAttestationHash, sample.releaseReceiptHash, block.timestamp + 3600)).wait();
    txs.checkpointState = r.hash;
  }

  const birthArtifact = JSON.parse(fs.readFileSync(rel("artifacts", "contracts", "ARKBirthCertificate.sol", "ARKBirthCertificate.json"), "utf8"));
  const marketplaceArtifact = JSON.parse(fs.readFileSync(rel("artifacts", "contracts", "ARKRuntimeMarketplace.sol", "ARKRuntimeMarketplace.json"), "utf8"));
  fs.mkdirSync(rel("deployments"), { recursive: true });
  fs.mkdirSync(rel("site"), { recursive: true });
  const receipt = {
    network: network.name,
    chainId: Number(chain.chainId),
    contracts: {
      birthCertificate: birthAddress,
      marketplace: marketplaceAddress
    },
    deployer: deployer.address,
    deployTxs: {
      birthCertificate: birthDeployTx.hash,
      marketplace: marketplaceDeployTx.hash
    },
    txs,
    sample,
    generatedAt: new Date().toISOString()
  };
  fs.writeFileSync(rel("deployments", `${network.name}.json`), JSON.stringify(receipt, null, 2));
  fs.writeFileSync(rel("deployments", "latest.json"), JSON.stringify(receipt, null, 2));
  fs.writeFileSync(rel("site", "ARKBirthCertificate.abi.json"), JSON.stringify(birthArtifact.abi, null, 2));
  fs.writeFileSync(rel("site", "ARKRuntimeMarketplace.abi.json"), JSON.stringify(marketplaceArtifact.abi, null, 2));
  fs.writeFileSync(rel("site", "config.json"), JSON.stringify({
    network: network.name,
    chainId: Number(chain.chainId),
    contracts: receipt.contracts,
    deployTxs: receipt.deployTxs,
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
