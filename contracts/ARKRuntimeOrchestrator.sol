// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title ARKRuntimeOrchestrator
/// @notice v0 Ethereum/L2 settlement adapter for a provider-neutral Reality Ledger.
/// @dev Stores public commitments, receipts, ids, roots, and runtime authority only. Never put secrets here.
contract ARKRuntimeOrchestrator {
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
        bytes32 hardwareProfileHash;
        string endpointRef;
        bool active;
    }

    struct ImageRecord {
        address publisher;
        bytes32 ociDigest;
        bytes32 runtimePolicyDigest;
        string metadataURI;
        bool active;
    }

    struct BirthCertificate {
        uint256 tokenId;
        bytes32 agentId;
        bytes32 parentAgentId;
        bytes32 lineageRoot;
        bytes32 desirePolicyHash;
        bytes32 currentRuntimeClaimId;
        bool exists;
    }

    struct BootLeaseRequest {
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
        bool cancelled;
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
        uint64 committedAt;
    }

    uint256 public nextTokenId = 1;

    mapping(bytes32 => HostRecord) public hosts;
    mapping(bytes32 => ImageRecord) public images;
    mapping(bytes32 => BirthCertificate) public birthByAgent;
    mapping(uint256 => bytes32) public agentByToken;
    mapping(bytes32 => BootLeaseRequest) public bootLeaseRequests;
    mapping(bytes32 => RuntimeClaim) public runtimeClaims;
    mapping(bytes32 => bytes32) public activeClaimByAgent;
    mapping(bytes32 => StateCommitment) public stateCommitments;
    mapping(bytes32 => bytes32) public latestStateCommitmentByState;
    mapping(bytes32 => uint64) public latestStateVersionByState;
    mapping(bytes32 => bytes32) public releaseReceiptByClaim;
    mapping(bytes32 => bytes32) public closureReceiptByClaim;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => string) private _tokenURIs;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event HostRegistered(bytes32 indexed hostId, address indexed operator, bytes32 allowedHostSetHash, bytes32 bastionAttestationHash);
    event ImagePublished(bytes32 indexed imageId, address indexed publisher, bytes32 ociDigest, bytes32 runtimePolicyDigest);
    event ArkBirthCertificateMinted(uint256 indexed tokenId, bytes32 indexed agentId, bytes32 indexed parentAgentId, bytes32 lineageRoot, bytes32 desirePolicyHash, string uri);
    event BootLeaseRequested(bytes32 indexed requestId, bytes32 indexed agentId, bytes32 indexed imageId, bytes32 stateId, bytes32 allowedHostSetHash, uint256 escrowWei);
    event RuntimeClaimed(bytes32 indexed claimId, bytes32 indexed requestId, bytes32 indexed hostId, bytes32 agentId, bytes32 agentCvmAttestationHash, bytes32 vmTransportPubkeyHash);
    event ReleaseReceiptRecorded(bytes32 indexed claimId, bytes32 indexed stateCommitmentId, bytes32 releaseReceiptHash, uint64 expiry);
    event StateCommitted(bytes32 indexed stateCommitmentId, bytes32 indexed claimId, bytes32 indexed stateId, uint64 version, bytes32 rootHash, bytes32 previousRootHash);
    event RuntimeClaimClosed(bytes32 indexed claimId, bytes32 indexed agentId, bytes32 finalStateCommitmentId, bytes32 successorClaimId, bytes32 closureReceiptHash, uint8 reason);

    modifier onlyTokenOwner(bytes32 agentId) {
        BirthCertificate storage cert = birthByAgent[agentId];
        require(cert.exists, "agent certificate missing");
        require(_owners[cert.tokenId] == msg.sender, "not agent owner");
        _;
    }

    function balanceOf(address owner) external view returns (uint256) {
        require(owner != address(0), "zero owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "unknown token");
        return owner;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_owners[tokenId] != address(0), "unknown token");
        return _tokenURIs[tokenId];
    }

    function registerHost(
        bytes32 hostId,
        bytes32 allowedHostSetHash,
        bytes32 bastionAttestationHash,
        bytes32 hardwareProfileHash,
        string calldata endpointRef
    ) external {
        require(hostId != bytes32(0), "host id required");
        require(bastionAttestationHash != bytes32(0), "bastion attestation required");
        hosts[hostId] = HostRecord({
            operator: msg.sender,
            allowedHostSetHash: allowedHostSetHash,
            bastionAttestationHash: bastionAttestationHash,
            hardwareProfileHash: hardwareProfileHash,
            endpointRef: endpointRef,
            active: true
        });
        emit HostRegistered(hostId, msg.sender, allowedHostSetHash, bastionAttestationHash);
    }

    function publishImage(
        bytes32 imageId,
        bytes32 ociDigest,
        bytes32 runtimePolicyDigest,
        string calldata metadataURI
    ) external {
        require(imageId != bytes32(0), "image id required");
        require(ociDigest != bytes32(0), "oci digest required");
        require(runtimePolicyDigest != bytes32(0), "policy digest required");
        images[imageId] = ImageRecord({
            publisher: msg.sender,
            ociDigest: ociDigest,
            runtimePolicyDigest: runtimePolicyDigest,
            metadataURI: metadataURI,
            active: true
        });
        emit ImagePublished(imageId, msg.sender, ociDigest, runtimePolicyDigest);
    }

    function mintArkBirthCertificate(
        bytes32 agentId,
        bytes32 parentAgentId,
        bytes32 lineageRoot,
        bytes32 desirePolicyHash,
        string calldata uri
    ) external returns (uint256 tokenId) {
        require(agentId != bytes32(0), "agent id required");
        require(!birthByAgent[agentId].exists, "agent already minted");
        require(lineageRoot != bytes32(0), "lineage root required");
        require(desirePolicyHash != bytes32(0), "desire policy required");

        tokenId = nextTokenId++;
        _owners[tokenId] = msg.sender;
        _balances[msg.sender] += 1;
        _tokenURIs[tokenId] = uri;
        agentByToken[tokenId] = agentId;
        birthByAgent[agentId] = BirthCertificate({
            tokenId: tokenId,
            agentId: agentId,
            parentAgentId: parentAgentId,
            lineageRoot: lineageRoot,
            desirePolicyHash: desirePolicyHash,
            currentRuntimeClaimId: bytes32(0),
            exists: true
        });

        emit Transfer(address(0), msg.sender, tokenId);
        emit ArkBirthCertificateMinted(tokenId, agentId, parentAgentId, lineageRoot, desirePolicyHash, uri);
    }

    function postBootLeaseRequest(
        bytes32 requestId,
        bytes32 agentId,
        bytes32 imageId,
        bytes32 stateId,
        bytes32 allowedHostSetHash,
        uint64 desiredSeconds,
        uint256 maxPricePerSecond,
        bytes32 unlockPolicyHash
    ) external payable onlyTokenOwner(agentId) {
        require(requestId != bytes32(0), "request id required");
        require(bootLeaseRequests[requestId].requester == address(0), "request exists");
        require(images[imageId].active, "image missing");
        require(stateId != bytes32(0), "state id required");
        require(desiredSeconds > 0, "duration required");
        require(unlockPolicyHash != bytes32(0), "unlock policy required");
        require(activeClaimByAgent[agentId] == bytes32(0), "agent already active");

        bootLeaseRequests[requestId] = BootLeaseRequest({
            requester: msg.sender,
            agentId: agentId,
            imageId: imageId,
            stateId: stateId,
            allowedHostSetHash: allowedHostSetHash,
            desiredSeconds: desiredSeconds,
            maxPricePerSecond: maxPricePerSecond,
            escrowWei: msg.value,
            unlockPolicyHash: unlockPolicyHash,
            claimed: false,
            cancelled: false
        });
        emit BootLeaseRequested(requestId, agentId, imageId, stateId, allowedHostSetHash, msg.value);
    }

    function claimBootLease(
        bytes32 requestId,
        bytes32 claimId,
        bytes32 hostId,
        bytes32 agentCvmAttestationHash,
        bytes32 vmTransportPubkeyHash,
        bytes32 stateCommitmentId,
        uint256 pricePerSecond
    ) external {
        BootLeaseRequest storage request = bootLeaseRequests[requestId];
        HostRecord storage host = hosts[hostId];
        require(request.requester != address(0), "request missing");
        require(!request.claimed && !request.cancelled, "request closed");
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
            stateCommitmentId: stateCommitmentId,
            pricePerSecond: pricePerSecond,
            openedAt: uint64(block.timestamp),
            status: ClaimStatus.Active
        });
        activeClaimByAgent[request.agentId] = claimId;
        if (birthByAgent[request.agentId].exists) {
            birthByAgent[request.agentId].currentRuntimeClaimId = claimId;
        }
        emit RuntimeClaimed(claimId, requestId, hostId, request.agentId, agentCvmAttestationHash, vmTransportPubkeyHash);
    }

    function recordReleaseReceipt(
        bytes32 claimId,
        bytes32 stateCommitmentId,
        bytes32 releaseReceiptHash,
        uint64 expiry
    ) external {
        RuntimeClaim storage claim = runtimeClaims[claimId];
        require(claim.status == ClaimStatus.Active, "claim not active");
        HostRecord storage host = hosts[claim.hostId];
        require(msg.sender == host.operator || msg.sender == ownerOf(birthByAgent[claim.agentId].tokenId), "not authorized");
        require(releaseReceiptHash != bytes32(0), "receipt required");
        require(expiry > block.timestamp, "expiry stale");
        releaseReceiptByClaim[claimId] = releaseReceiptHash;
        emit ReleaseReceiptRecorded(claimId, stateCommitmentId, releaseReceiptHash, expiry);
    }

    function commitState(
        bytes32 claimId,
        bytes32 stateCommitmentId,
        uint64 version,
        bytes32 rootHash,
        bytes32 previousRootHash,
        bytes32 writerAttestationHash
    ) external {
        RuntimeClaim storage claim = runtimeClaims[claimId];
        require(claim.status == ClaimStatus.Active, "claim not active");
        HostRecord storage host = hosts[claim.hostId];
        require(msg.sender == host.operator || msg.sender == ownerOf(birthByAgent[claim.agentId].tokenId), "not authorized");
        require(stateCommitmentId != bytes32(0), "state commitment id required");
        require(rootHash != bytes32(0), "root required");
        require(writerAttestationHash == claim.agentCvmAttestationHash, "writer attestation mismatch");

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
            committedAt: uint64(block.timestamp)
        });
        latestStateVersionByState[claim.stateId] = version;
        latestStateCommitmentByState[claim.stateId] = stateCommitmentId;
        claim.stateCommitmentId = stateCommitmentId;

        emit StateCommitted(stateCommitmentId, claimId, claim.stateId, version, rootHash, previousRootHash);
    }

    function closeRuntimeClaim(
        bytes32 claimId,
        uint8 reason,
        bytes32 finalStateCommitmentId,
        bytes32 successorClaimId,
        bytes32 closureReceiptHash
    ) external {
        RuntimeClaim storage claim = runtimeClaims[claimId];
        require(claim.status == ClaimStatus.Active, "claim not active");
        HostRecord storage host = hosts[claim.hostId];
        require(msg.sender == host.operator || msg.sender == ownerOf(birthByAgent[claim.agentId].tokenId), "not authorized");
        require(closureReceiptHash != bytes32(0), "closure receipt required");
        if (finalStateCommitmentId != bytes32(0)) {
            require(stateCommitments[finalStateCommitmentId].claimId == claimId, "final state not for claim");
        }

        claim.status = ClaimStatus.Closed;
        activeClaimByAgent[claim.agentId] = successorClaimId;
        if (birthByAgent[claim.agentId].exists) {
            birthByAgent[claim.agentId].currentRuntimeClaimId = successorClaimId;
        }
        closureReceiptByClaim[claimId] = closureReceiptHash;
        emit RuntimeClaimClosed(claimId, claim.agentId, finalStateCommitmentId, successorClaimId, closureReceiptHash, reason);
    }
}
