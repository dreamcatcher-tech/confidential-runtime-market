// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

/// @title ARKBirthCertificate
/// @notice ERC-721 birth certificate for an ARK/agent identity.
/// @dev Stores immutable public commitments only. Runtime state lives in compatible marketplace contracts.
contract ARKBirthCertificate is ERC721URIStorage {
    struct BirthRecord {
        bytes32 agentId;
        bytes32 parentAgentId;
        bytes32 lineageRoot;
        bytes32 desirePolicyHash;
        bytes32 birthMetadataHash;
        uint64 mintedAt;
        bool exists;
    }

    uint256 public nextTokenId = 1;

    mapping(bytes32 => uint256) public tokenByAgent;
    mapping(uint256 => bytes32) public agentByToken;
    mapping(bytes32 => BirthRecord) public birthByAgent;

    event ArkBirthCertificateMinted(
        uint256 indexed tokenId,
        bytes32 indexed agentId,
        bytes32 indexed parentAgentId,
        bytes32 lineageRoot,
        bytes32 desirePolicyHash,
        bytes32 birthMetadataHash,
        string uri
    );

    constructor() ERC721("ARK Birth Certificate", "ARKBIRTH") {}

    function mint(
        bytes32 agentId,
        bytes32 parentAgentId,
        bytes32 lineageRoot,
        bytes32 desirePolicyHash,
        bytes32 birthMetadataHash,
        string calldata uri
    ) external returns (uint256 tokenId) {
        require(agentId != bytes32(0), "agent id required");
        require(tokenByAgent[agentId] == 0, "agent already minted");
        require(lineageRoot != bytes32(0), "lineage root required");
        require(desirePolicyHash != bytes32(0), "desire policy required");
        require(birthMetadataHash != bytes32(0), "metadata hash required");

        tokenId = nextTokenId++;
        tokenByAgent[agentId] = tokenId;
        agentByToken[tokenId] = agentId;
        birthByAgent[agentId] = BirthRecord({
            agentId: agentId,
            parentAgentId: parentAgentId,
            lineageRoot: lineageRoot,
            desirePolicyHash: desirePolicyHash,
            birthMetadataHash: birthMetadataHash,
            mintedAt: uint64(block.timestamp),
            exists: true
        });

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
        emit ArkBirthCertificateMinted(tokenId, agentId, parentAgentId, lineageRoot, desirePolicyHash, birthMetadataHash, uri);
    }

    function ownerOfAgent(bytes32 agentId) public view returns (address) {
        uint256 tokenId = tokenByAgent[agentId];
        require(tokenId != 0, "agent certificate missing");
        return ownerOf(tokenId);
    }
}
