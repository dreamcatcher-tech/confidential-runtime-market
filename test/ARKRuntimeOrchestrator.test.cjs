const { expect } = require("chai");
const { ethers } = require("hardhat");

const id = (label) => ethers.id(label);

async function expectRevert(promise, reason) {
  try {
    await promise;
  } catch (err) {
    expect(err.message).to.include(reason);
    return;
  }
  throw new Error(`Expected revert containing: ${reason}`);
}

async function deployFixture() {
  const [owner, host, outsider] = await ethers.getSigners();
  const Contract = await ethers.getContractFactory("ARKRuntimeOrchestrator");
  const orchestrator = await Contract.deploy();
  await orchestrator.waitForDeployment();
  return { orchestrator, owner, host, outsider };
}

async function prepareFlow() {
  const f = await deployFixture();
  const { orchestrator, host } = f;
  const hostSet = id("allowed-host-set:tom-controlled");
  await (await orchestrator.connect(host).registerHost(
    id("host:fly-waiting-vm"),
    hostSet,
    id("bastion-attestation:preflight"),
    id("hardware-profile:fly-shared-cpu-256mb"),
    "fly://ark-waiting-vm.example.internal"
  )).wait();
  await (await orchestrator.publishImage(
    id("image:ark-agent:v0"),
    id("oci:dreamcatcher/ark-agent@sha256-demo"),
    id("runtime-policy:ark-agent-cvm-v0"),
    "ipfs://ark-image-metadata-demo"
  )).wait();
  await (await orchestrator.mintArkBirthCertificate(
    id("agent:ark-demo"),
    id("agent:parent-template"),
    id("lineage:ark-demo-parenthood"),
    id("desire-policy:serve-principal"),
    "ipfs://ark-birth-certificate-demo"
  )).wait();
  await (await orchestrator.postBootLeaseRequest(
    id("request:ark-demo"),
    id("agent:ark-demo"),
    id("image:ark-agent:v0"),
    id("state:ark-demo"),
    hostSet,
    3600,
    1_000_000n,
    id("unlock-policy:statevault-scoped-lease"),
    { value: 10_000_000n }
  )).wait();
  return { ...f, hostSet };
}

describe("ARKRuntimeOrchestrator", function () {
  it("mints an ARK birth certificate/medallion record", async function () {
    const { orchestrator, owner } = await deployFixture();
    const agentId = id("agent:ark-demo");
    const tx = await orchestrator.mintArkBirthCertificate(agentId, ethers.ZeroHash, id("lineage"), id("desire"), "ipfs://birth");
    const receipt = await tx.wait();
    expect(receipt.logs.length).to.be.greaterThan(0);
    expect(await orchestrator.ownerOf(1)).to.equal(owner.address);
    expect(await orchestrator.agentByToken(1)).to.equal(agentId);
    const cert = await orchestrator.birthByAgent(agentId);
    expect(cert.exists).to.equal(true);
    expect(cert.lineageRoot).to.equal(id("lineage"));
    expect(cert.desirePolicyHash).to.equal(id("desire"));
    await expectRevert(
      orchestrator.mintArkBirthCertificate(agentId, ethers.ZeroHash, id("lineage2"), id("desire"), "ipfs://birth2"),
      "agent already minted"
    );
  });

  it("lets an allowed host claim a controlled boot lease and bind current runtime authority", async function () {
    const { orchestrator, host } = await prepareFlow();
    const claimId = id("claim:ark-demo:host1");
    await (await orchestrator.connect(host).claimBootLease(
      id("request:ark-demo"),
      claimId,
      id("host:fly-waiting-vm"),
      id("agent-cvm-attestation:demo"),
      id("vm-transport-pubkey:demo"),
      ethers.ZeroHash,
      1000n
    )).wait();

    expect(await orchestrator.activeClaimByAgent(id("agent:ark-demo"))).to.equal(claimId);
    const birth = await orchestrator.birthByAgent(id("agent:ark-demo"));
    expect(birth.currentRuntimeClaimId).to.equal(claimId);
  });

  it("rejects a host outside the request allowed_host_set", async function () {
    const { orchestrator, host, outsider } = await prepareFlow();
    await (await orchestrator.connect(outsider).registerHost(
      id("host:wrong-set"),
      id("allowed-host-set:other"),
      id("bastion-attestation:other"),
      id("hardware-profile:other"),
      "fly://wrong-set"
    )).wait();
    await expectRevert(orchestrator.connect(outsider).claimBootLease(
      id("request:ark-demo"),
      id("claim:wrong"),
      id("host:wrong-set"),
      id("agent-cvm-attestation:demo"),
      id("vm-transport-pubkey:demo"),
      ethers.ZeroHash,
      1000n
    ), "host set denied");

    await (await orchestrator.connect(host).claimBootLease(
      id("request:ark-demo"),
      id("claim:ark-demo:host1"),
      id("host:fly-waiting-vm"),
      id("agent-cvm-attestation:demo"),
      id("vm-transport-pubkey:demo"),
      ethers.ZeroHash,
      1000n
    )).wait();
  });

  it("records StateVault release receipts and monotonic state roots", async function () {
    const { orchestrator, host } = await prepareFlow();
    const claimId = id("claim:ark-demo:host1");
    await (await orchestrator.connect(host).claimBootLease(
      id("request:ark-demo"), claimId, id("host:fly-waiting-vm"),
      id("agent-cvm-attestation:demo"), id("vm-transport-pubkey:demo"), ethers.ZeroHash, 1000n
    )).wait();

    const now = (await ethers.provider.getBlock("latest")).timestamp;
    await (await orchestrator.connect(host).recordReleaseReceipt(
      claimId,
      ethers.ZeroHash,
      id("release-receipt:statevault-lease"),
      now + 3600
    )).wait();
    expect(await orchestrator.releaseReceiptByClaim(claimId)).to.equal(id("release-receipt:statevault-lease"));

    const state1 = id("state-commitment:v1");
    await (await orchestrator.connect(host).commitState(
      claimId,
      state1,
      1,
      id("state-root:v1"),
      ethers.ZeroHash,
      id("agent-cvm-attestation:demo")
    )).wait();
    expect(await orchestrator.latestStateVersionByState(id("state:ark-demo"))).to.equal(1n);

    await expectRevert(orchestrator.connect(host).commitState(
      claimId,
      id("state-commitment:v2-bad"),
      2,
      id("state-root:v2"),
      id("wrong-previous-root"),
      id("agent-cvm-attestation:demo")
    ), "previous root mismatch");

    const state2 = id("state-commitment:v2");
    await (await orchestrator.connect(host).commitState(
      claimId,
      state2,
      2,
      id("state-root:v2"),
      id("state-root:v1"),
      id("agent-cvm-attestation:demo")
    )).wait();
    expect(await orchestrator.latestStateCommitmentByState(id("state:ark-demo"))).to.equal(state2);
  });

  it("closes a runtime claim with a closure receipt and clears active authority", async function () {
    const { orchestrator, host } = await prepareFlow();
    const claimId = id("claim:ark-demo:host1");
    await (await orchestrator.connect(host).claimBootLease(
      id("request:ark-demo"), claimId, id("host:fly-waiting-vm"),
      id("agent-cvm-attestation:demo"), id("vm-transport-pubkey:demo"), ethers.ZeroHash, 1000n
    )).wait();
    const state1 = id("state-commitment:v1");
    await (await orchestrator.connect(host).commitState(
      claimId, state1, 1, id("state-root:v1"), ethers.ZeroHash, id("agent-cvm-attestation:demo")
    )).wait();

    await (await orchestrator.connect(host).closeRuntimeClaim(
      claimId,
      1,
      state1,
      ethers.ZeroHash,
      id("closure-receipt:clean-stop")
    )).wait();
    expect(await orchestrator.activeClaimByAgent(id("agent:ark-demo"))).to.equal(ethers.ZeroHash);
    expect(await orchestrator.closureReceiptByClaim(claimId)).to.equal(id("closure-receipt:clean-stop"));
    const claim = await orchestrator.runtimeClaims(claimId);
    expect(claim.status).to.equal(2n);
  });
});
