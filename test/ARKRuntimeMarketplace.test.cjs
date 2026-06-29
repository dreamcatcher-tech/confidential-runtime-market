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
  const Birth = await ethers.getContractFactory("ARKBirthCertificate");
  const birth = await Birth.deploy();
  await birth.waitForDeployment();

  const Market = await ethers.getContractFactory("ARKRuntimeMarketplace");
  const marketplace = await Market.deploy(await birth.getAddress());
  await marketplace.waitForDeployment();
  return { birth, marketplace, owner, host, outsider };
}

async function mintDemoAgent(birth) {
  await (await birth.mint(
    id("agent:ark-demo"),
    id("agent:parent-template"),
    id("lineage:ark-demo-parenthood"),
    id("desire-policy:serve-principal"),
    id("birth-metadata:ark-demo"),
    "ipfs://ark-birth-certificate-demo"
  )).wait();
}

async function prepareFlow() {
  const f = await deployFixture();
  const { birth, marketplace, host } = f;
  const hostSet = id("allowed-host-set:tom-controlled");
  await (await marketplace.connect(host).registerHost(
    id("host:fly-waiting-vm"),
    hostSet,
    id("bastion-attestation:preflight"),
    id("host-metadata:fly-waiting-vm")
  )).wait();
  await (await marketplace.publishImage(
    id("image:ark-agent:v0"),
    id("oci:dreamcatcher/ark-agent@sha256-demo"),
    id("runtime-policy:ark-agent-cvm-v0")
  )).wait();
  await mintDemoAgent(birth);
  await (await marketplace.requestRuntime(
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

async function claimDemoRuntime(marketplace, host) {
  const claimId = id("claim:ark-demo:host1");
  await (await marketplace.connect(host).claimRuntime(
    id("request:ark-demo"),
    claimId,
    id("host:fly-waiting-vm"),
    id("agent-cvm-attestation:demo"),
    id("vm-transport-pubkey:demo"),
    1000n
  )).wait();
  return claimId;
}

describe("ARK birth certificate + runtime marketplace", function () {
  it("mints a standard ERC-721 ARK birth certificate", async function () {
    const { birth, owner } = await deployFixture();
    const agentId = id("agent:ark-demo");
    const tx = await birth.mint(agentId, ethers.ZeroHash, id("lineage"), id("desire"), id("birth-metadata"), "ipfs://birth");
    const receipt = await tx.wait();
    expect(receipt.logs.length).to.be.greaterThan(0);
    expect(await birth.name()).to.equal("ARK Birth Certificate");
    expect(await birth.symbol()).to.equal("ARKBIRTH");
    expect(await birth.supportsInterface("0x80ac58cd")).to.equal(true); // ERC-721
    expect(await birth.supportsInterface("0x5b5e139f")).to.equal(true); // ERC-721 metadata
    expect(await birth.ownerOf(1)).to.equal(owner.address);
    expect(await birth.ownerOfAgent(agentId)).to.equal(owner.address);
    expect(await birth.agentByToken(1)).to.equal(agentId);
    expect(await birth.tokenURI(1)).to.equal("ipfs://birth");
    const cert = await birth.birthByAgent(agentId);
    expect(cert.exists).to.equal(true);
    expect(cert.lineageRoot).to.equal(id("lineage"));
    expect(cert.desirePolicyHash).to.equal(id("desire"));
    expect(cert.birthMetadataHash).to.equal(id("birth-metadata"));
    await expectRevert(
      birth.mint(agentId, ethers.ZeroHash, id("lineage2"), id("desire"), id("birth-metadata"), "ipfs://birth2"),
      "agent already minted"
    );
  });

  it("separates birth certificate ownership from runtime marketplace authority", async function () {
    const { birth, marketplace, owner, host, outsider } = await prepareFlow();
    const agentId = id("agent:ark-demo");
    expect(await birth.ownerOfAgent(agentId)).to.equal(owner.address);

    const claimId = await claimDemoRuntime(marketplace, host);
    expect(await marketplace.activeClaimByAgent(agentId)).to.equal(claimId);

    await expectRevert(marketplace.connect(outsider).requestRuntime(
      id("request:outsider"), agentId, id("image:ark-agent:v0"), id("state:ark-demo-2"), ethers.ZeroHash, 3600, 1_000_000n, id("unlock-policy:statevault-scoped-lease")
    ), "not agent owner");
  });

  it("rejects a host outside the request allowed_host_set", async function () {
    const { marketplace, host, outsider } = await prepareFlow();
    await (await marketplace.connect(outsider).registerHost(
      id("host:wrong-set"),
      id("allowed-host-set:other"),
      id("bastion-attestation:other"),
      id("host-metadata:other")
    )).wait();
    await expectRevert(marketplace.connect(outsider).claimRuntime(
      id("request:ark-demo"),
      id("claim:wrong"),
      id("host:wrong-set"),
      id("agent-cvm-attestation:demo"),
      id("vm-transport-pubkey:demo"),
      1000n
    ), "host set denied");

    await claimDemoRuntime(marketplace, host);
  });

  it("records StateVault release receipt and monotonic state root in one checkpoint", async function () {
    const { marketplace, host } = await prepareFlow();
    const claimId = await claimDemoRuntime(marketplace, host);

    const now = (await ethers.provider.getBlock("latest")).timestamp;
    const state1 = id("state-commitment:v1");
    await (await marketplace.connect(host).checkpointState(
      claimId,
      state1,
      1,
      id("state-root:v1"),
      ethers.ZeroHash,
      id("agent-cvm-attestation:demo"),
      id("release-receipt:statevault-lease"),
      now + 3600
    )).wait();
    expect(await marketplace.latestStateVersionByState(id("state:ark-demo"))).to.equal(1n);
    const checkpoint = await marketplace.stateCommitments(state1);
    expect(checkpoint.releaseReceiptHash).to.equal(id("release-receipt:statevault-lease"));

    await expectRevert(marketplace.connect(host).checkpointState(
      claimId,
      id("state-commitment:v2-bad"),
      2,
      id("state-root:v2"),
      id("wrong-previous-root"),
      id("agent-cvm-attestation:demo"),
      ethers.ZeroHash,
      0
    ), "previous root mismatch");

    const state2 = id("state-commitment:v2");
    await (await marketplace.connect(host).checkpointState(
      claimId,
      state2,
      2,
      id("state-root:v2"),
      id("state-root:v1"),
      id("agent-cvm-attestation:demo"),
      ethers.ZeroHash,
      0
    )).wait();
    expect(await marketplace.latestStateCommitmentByState(id("state:ark-demo"))).to.equal(state2);
  });

  it("closes a runtime claim with a closure receipt and clears active authority", async function () {
    const { marketplace, host } = await prepareFlow();
    const claimId = await claimDemoRuntime(marketplace, host);
    const state1 = id("state-commitment:v1");
    await (await marketplace.connect(host).checkpointState(
      claimId, state1, 1, id("state-root:v1"), ethers.ZeroHash, id("agent-cvm-attestation:demo"), ethers.ZeroHash, 0
    )).wait();

    await (await marketplace.connect(host).closeRuntime(
      claimId,
      1,
      state1,
      id("closure-receipt:clean-stop")
    )).wait();
    expect(await marketplace.activeClaimByAgent(id("agent:ark-demo"))).to.equal(ethers.ZeroHash);
    expect(await marketplace.closureReceiptByClaim(claimId)).to.equal(id("closure-receipt:clean-stop"));
    const claim = await marketplace.runtimeClaims(claimId);
    expect(claim.status).to.equal(2n);
  });
});
