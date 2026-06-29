// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IARKBirthCertificate {
    function ownerOfAgent(bytes32 agentId) external view returns (address);
}

/// @title ARKRuntimeMarketplace
/// @notice v0 Ethereum/L2 settlement adapter for runtime supply, demand, claims, and state checkpoints.
/// @dev Stores public commitments, receipts, ids, and roots only. Never put secrets here.
contract ARKRuntimeMarketplace {
    bytes32 public constant ANY_HOST_SET = bytes32(0);

    enum ClaimStatus {
        None,
        Active,
        Closed
    }

    struct HostRecord {
        address operator;
        bytes32 allowedHostSetHash;
        bytes32 bastionAttestationHash;
        bytes32 hostMetadataHash;
        bool active;
    }

    struct ImageRecord {
        address publisher;
        bytes32 ociDigest;
        bytes32 runtimePolicyDigest;
        bool active;
    }

    struct RuntimeRequest {
        address requester;
        bytes32 agentId;
        bytes32 imageId;
        bytes32 stateId;
        bytes32 allowedHostSetHash;
        uint64 desiredSeconds;
        uint256 maxPricePerSecond;
        uint256 escrowWei;
        bytes32 unlockPolicyHash;
        bool claimed;
    }

    struct RuntimeClaim {
        bytes32 requestId;
        bytes32 agentId;
        bytes32 hostId;
        bytes32 imageId;
        bytes32 stateId;
        bytes32 agentCvmAttestationHash;
        bytes32 vmTransportPubkeyHash;
        bytes32 stateCommitmentId;
        uint256 pricePerSecond;
        uint64 openedAt;
        ClaimStatus status;
    }

    struct StateCommitment {
        bytes32 claimId;
        bytes32 stateId;
        uint64 version;
        bytes32 rootHash;
        bytes32 previousRootHash;
        bytes32 writerAttestationHash;
        bytes32 releaseReceiptHash;
        uint64 releaseExpiry;
        uint64 committedAt;
    }

    IARKBirthCertificate public immutable birthCertificate;

    mapping(bytes32 => HostRecord) public hosts;
    mapping(bytes32 => ImageRecord) public images;
    mapping(bytes32 => RuntimeRequest) public runtimeRequests;
    mapping(bytes32 => RuntimeClaim) public runtimeClaims;
    mapping(bytes32 => bytes32) public activeClaimByAgent;
    mapping(bytes32 => StateCommitment) public stateCommitments;
    mapping(bytes32 => bytes32) public latestStateCommitmentByState;
    mapping(bytes32 => uint64) public latestStateVersionByState;
    mapping(bytes32 => bytes32) public closureReceiptByClaim;

    event HostRegistered(bytes32 indexed hostId, address indexed operator, bytes32 allowedHostSetHash, bytes32 bastionAttestationHash, bytes32 hostMetadataHash);
    event ImagePublished(bytes32 indexed imageId, address indexed publisher, bytes32 ociDigest, bytes32 runtimePolicyDigest);
    event RuntimeRequested(bytes32 indexed requestId, bytes32 indexed agentId, bytes32 indexed imageId, bytes32 stateId, bytes32 allowedHostSetHash, uint256 escrowWei);
    event RuntimeClaimed(bytes32 indexed claimId, bytes32 indexed requestId, bytes32 indexed hostId, bytes32 agentId, bytes32 agentCvmAttestationHash, bytes32 vmTransportPubkeyHash);
    event StateCheckpointed(bytes32 indexed stateCommitmentId, bytes32 indexed claimId, bytes32 indexed stateId, uint64 version, bytes32 rootHash, bytes32 previousRootHash, bytes32 releaseReceiptHash);
    event RuntimeClosed(bytes32 indexed claimId, bytes32 indexed agentId, bytes32 finalStateCommitmentId, bytes32 closureReceiptHash, uint8 reason);

    constructor(address birthCertificate_) {
        require(birthCertificate_ != address(0), "birth certificate required");
        birthCertificate = IARKBirthCertificate(birthCertificate_);
    }

    modifier onlyAgentOwner(bytes32 agentId) {
        require(birthCertificate.ownerOfAgent(agentId) == msg.sender, "not agent owner");
        _;
    }

    function registerHost(
        bytes32 hostId,
        bytes32 allowedHostSetHash,
        bytes32 bastionAttestationHash,
        bytes32 hostMetadataHash
    ) external {
        require(hostId != bytes32(0), "host id required");
        require(bastionAttestationHash != bytes32(0), "bastion attestation required");
        hosts[hostId] = HostRecord({
            operator: msg.sender,
            allowedHostSetHash: allowedHostSetHash,
            bastionAttestationHash: bastionAttestationHash,
            hostMetadataHash: hostMetadataHash,
            active: true
        });
        emit HostRegistered(hostId, msg.sender, allowedHostSetHash, bastionAttestationHash, hostMetadataHash);
    }

    function publishImage(
        bytes32 imageId,
        bytes32 ociDigest,
        bytes32 runtimePolicyDigest
    ) external {
        require(imageId != bytes32(0), "image id required");
        require(ociDigest != bytes32(0), "oci digest required");
        require(runtimePolicyDigest != bytes32(0), "policy digest required");
        images[imageId] = ImageRecord({
            publisher: msg.sender,
            ociDigest: ociDigest,
            runtimePolicyDigest: runtimePolicyDigest,
            active: true
        });
        emit ImagePublished(imageId, msg.sender, ociDigest, runtimePolicyDigest);
    }

    function requestRuntime(
        bytes32 requestId,
        bytes32 agentId,
        bytes32 imageId,
        bytes32 stateId,
        bytes32 allowedHostSetHash,
        uint64 desiredSeconds,
        uint256 maxPricePerSecond,
        bytes32 unlockPolicyHash
    ) external payable onlyAgentOwner(agentId) {
        require(requestId != bytes32(0), "request id required");
        require(runtimeRequests[requestId].requester == address(0), "request exists");
        require(images[imageId].active, "image missing");
        require(stateId != bytes32(0), "state id required");
        require(desiredSeconds > 0, "duration required");
        require(unlockPolicyHash != bytes32(0), "unlock policy required");
        require(activeClaimByAgent[agentId] == bytes32(0), "agent already active");

        runtimeRequests[requestId] = RuntimeRequest({
            requester: msg.sender,
            agentId: agentId,
            imageId: imageId,
            stateId: stateId,
            allowedHostSetHash: allowedHostSetHash,
            desiredSeconds: desiredSeconds,
            maxPricePerSecond: maxPricePerSecond,
            escrowWei: msg.value,
            unlockPolicyHash: unlockPolicyHash,
            claimed: false
        });
        emit RuntimeRequested(requestId, agentId, imageId, stateId, allowedHostSetHash, msg.value);
    }

    function claimRuntime(
        bytes32 requestId,
        bytes32 claimId,
        bytes32 hostId,
        bytes32 agentCvmAttestationHash,
        bytes32 vmTransportPubkeyHash,
        uint256 pricePerSecond
    ) external {
        RuntimeRequest storage request = runtimeRequests[requestId];
        HostRecord storage host = hosts[hostId];
        require(request.requester != address(0), "request missing");
        require(!request.claimed, "request closed");
        require(claimId != bytes32(0), "claim id required");
        require(runtimeClaims[claimId].status == ClaimStatus.None, "claim exists");
        require(host.active, "host missing");
        require(host.operator == msg.sender, "not host operator");
        require(request.allowedHostSetHash == ANY_HOST_SET || request.allowedHostSetHash == host.allowedHostSetHash, "host set denied");
        require(pricePerSecond <= request.maxPricePerSecond, "price too high");
        require(agentCvmAttestationHash != bytes32(0), "agent attestation required");
        require(vmTransportPubkeyHash != bytes32(0), "transport key required");
        require(activeClaimByAgent[request.agentId] == bytes32(0), "agent already active");

        request.claimed = true;
        runtimeClaims[claimId] = RuntimeClaim({
            requestId: requestId,
            agentId: request.agentId,
            hostId: hostId,
            imageId: request.imageId,
            stateId: request.stateId,
            agentCvmAttestationHash: agentCvmAttestationHash,
            vmTransportPubkeyHash: vmTransportPubkeyHash,
            stateCommitmentId: bytes32(0),
            pricePerSecond: pricePerSecond,
            openedAt: uint64(block.timestamp),
            status: ClaimStatus.Active
        });
        activeClaimByAgent[request.agentId] = claimId;
        emit RuntimeClaimed(claimId, requestId, hostId, request.agentId, agentCvmAttestationHash, vmTransportPubkeyHash);
    }

    function checkpointState(
        bytes32 claimId,
        bytes32 stateCommitmentId,
        uint64 version,
        bytes32 rootHash,
        bytes32 previousRootHash,
        bytes32 writerAttestationHash,
        bytes32 releaseReceiptHash,
        uint64 releaseExpiry
    ) external {
        RuntimeClaim storage claim = runtimeClaims[claimId];
        require(claim.status == ClaimStatus.Active, "claim not active");
        require(_isClaimAuthority(claim), "not authorized");
        require(stateCommitmentId != bytes32(0), "state commitment id required");
        require(rootHash != bytes32(0), "root required");
        require(writerAttestationHash == claim.agentCvmAttestationHash, "writer attestation mismatch");
        if (releaseReceiptHash != bytes32(0)) {
            require(releaseExpiry > block.timestamp, "expiry stale");
        } else {
            require(releaseExpiry == 0, "receipt required for expiry");
        }

        uint64 latestVersion = latestStateVersionByState[claim.stateId];
        bytes32 latestCommitmentId = latestStateCommitmentByState[claim.stateId];
        if (latestVersion == 0) {
            require(version == 1, "first version must be 1");
            require(previousRootHash == bytes32(0), "first previous root must be empty");
        } else {
            StateCommitment storage latest = stateCommitments[latestCommitmentId];
            require(version == latestVersion + 1, "non-monotonic version");
            require(previousRootHash == latest.rootHash, "previous root mismatch");
        }

        stateCommitments[stateCommitmentId] = StateCommitment({
            claimId: claimId,
            stateId: claim.stateId,
            version: version,
            rootHash: rootHash,
            previousRootHash: previousRootHash,
            writerAttestationHash: writerAttestationHash,
            releaseReceiptHash: releaseReceiptHash,
            releaseExpiry: releaseExpiry,
            committedAt: uint64(block.timestamp)
        });
        latestStateVersionByState[claim.stateId] = version;
        latestStateCommitmentByState[claim.stateId] = stateCommitmentId;
        claim.stateCommitmentId = stateCommitmentId;

        emit StateCheckpointed(stateCommitmentId, claimId, claim.stateId, version, rootHash, previousRootHash, releaseReceiptHash);
    }

    function closeRuntime(
        bytes32 claimId,
        uint8 reason,
        bytes32 finalStateCommitmentId,
        bytes32 closureReceiptHash
    ) external {
        RuntimeClaim storage claim = runtimeClaims[claimId];
        require(claim.status == ClaimStatus.Active, "claim not active");
        require(_isClaimAuthority(claim), "not authorized");
        require(closureReceiptHash != bytes32(0), "closure receipt required");
        if (finalStateCommitmentId != bytes32(0)) {
            require(stateCommitments[finalStateCommitmentId].claimId == claimId, "final state not for claim");
        }

        claim.status = ClaimStatus.Closed;
        activeClaimByAgent[claim.agentId] = bytes32(0);
        closureReceiptByClaim[claimId] = closureReceiptHash;
        emit RuntimeClosed(claimId, claim.agentId, finalStateCommitmentId, closureReceiptHash, reason);
    }

    function _isClaimAuthority(RuntimeClaim storage claim) private view returns (bool) {
        HostRecord storage host = hosts[claim.hostId];
        if (msg.sender == host.operator) return true;
        return birthCertificate.ownerOfAgent(claim.agentId) == msg.sender;
    }
}
