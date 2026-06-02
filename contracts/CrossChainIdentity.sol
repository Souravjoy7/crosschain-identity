// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CrossChainIdentity is ReentrancyGuard, Ownable {
    constructor() Ownable(msg.sender) {}

    struct ChainRecord {
        uint256 chainId;
        address chainAddress;
        bool verified;
        uint256 addedAt;
    }

    struct Identity {
        address owner;
        string name;
        bytes32 metadataHash;
        uint256 createdAt;
        bool exists;
        mapping(uint256 => ChainRecord) chains;
        uint256[] chainIds;
        mapping(uint256 => bool) chainExists;
    }

    uint256 private _identityIds;
    mapping(uint256 => Identity) private _identities;
    mapping(address => uint256[]) private _userIdentities;
    mapping(address => uint256) private _addressToIdentity;

    event IdentityCreated(
        uint256 indexed identityId,
        address indexed owner,
        string name
    );
    event ChainAdded(
        uint256 indexed identityId,
        uint256 indexed chainId,
        address chainAddress
    );
    event ChainVerified(
        uint256 indexed identityId,
        uint256 indexed chainId,
        address verifier
    );
    event MetadataUpdated(
        uint256 indexed identityId,
        bytes32 newMetadataHash
    );

    error IdentityDoesNotExist(uint256 identityId);
    error ChainAlreadyAdded(uint256 identityId, uint256 chainId);
    error ChainNotFound(uint256 identityId, uint256 chainId);
    error ChainAlreadyVerified(uint256 identityId, uint256 chainId);
    error NotIdentityOwner(uint256 identityId, address caller);
    error InvalidAddress();
    error EmptyName();
    error EmptyMetadataHash();
    error InvalidChainId();
    error DuplicateIdentity(address caller);

    modifier identityExists(uint256 identityId) {
        if (!_identities[identityId].exists) {
            revert IdentityDoesNotExist(identityId);
        }
        _;
    }

    modifier onlyIdentityOwner(uint256 identityId) {
        if (_identities[identityId].owner != msg.sender) {
            revert NotIdentityOwner(identityId, msg.sender);
        }
        _;
    }

    modifier chainNotAdded(uint256 identityId, uint256 chainId) {
        if (_identities[identityId].chainExists[chainId]) {
            revert ChainAlreadyAdded(identityId, chainId);
        }
        _;
    }

    modifier chainExists(uint256 identityId, uint256 chainId) {
        if (!_identities[identityId].chainExists[chainId]) {
            revert ChainNotFound(identityId, chainId);
        }
        _;
    }

    modifier chainNotVerified(uint256 identityId, uint256 chainId) {
        if (_identities[identityId].chains[chainId].verified) {
            revert ChainAlreadyVerified(identityId, chainId);
        }
        _;
    }

    function createIdentity(string calldata name, bytes32 metadataHash)
        external
        nonReentrant
        returns (uint256)
    {
        if (msg.sender == address(0)) revert InvalidAddress();
        if (bytes(name).length == 0) revert EmptyName();
        if (metadataHash == bytes32(0)) revert EmptyMetadataHash();
        if (_addressToIdentity[msg.sender] != 0) {
            revert DuplicateIdentity(msg.sender);
        }

        uint256 identityId = _identityIds++;

        Identity storage identity = _identities[identityId];
        identity.owner = msg.sender;
        identity.name = name;
        identity.metadataHash = metadataHash;
        identity.createdAt = block.timestamp;
        identity.exists = true;

        _userIdentities[msg.sender].push(identityId);
        _addressToIdentity[msg.sender] = identityId;

        emit IdentityCreated(identityId, msg.sender, name);

        return identityId;
    }

    function addChain(uint256 identityId, uint256 chainId, address chainAddress)
        external
        identityExists(identityId)
        onlyIdentityOwner(identityId)
        chainNotAdded(identityId, chainId)
    {
        if (chainAddress == address(0)) revert InvalidAddress();
        if (chainId == 0) revert InvalidChainId();

        Identity storage identity = _identities[identityId];

        identity.chains[chainId] = ChainRecord({
            chainId: chainId,
            chainAddress: chainAddress,
            verified: false,
            addedAt: block.timestamp
        });

        identity.chainIds.push(chainId);
        identity.chainExists[chainId] = true;

        emit ChainAdded(identityId, chainId, chainAddress);
    }

    function verifyChain(uint256 identityId, uint256 chainId)
        external
        identityExists(identityId)
        chainExists(identityId, chainId)
        chainNotVerified(identityId, chainId)
    {
        Identity storage identity = _identities[identityId];
        identity.chains[chainId].verified = true;

        emit ChainVerified(identityId, chainId, msg.sender);
    }

    function updateMetadata(uint256 identityId, bytes32 newMetadataHash)
        external
        identityExists(identityId)
        onlyIdentityOwner(identityId)
    {
        if (newMetadataHash == bytes32(0)) revert EmptyMetadataHash();

        _identities[identityId].metadataHash = newMetadataHash;

        emit MetadataUpdated(identityId, newMetadataHash);
    }

    function getIdentity(uint256 identityId)
        external
        view
        identityExists(identityId)
        returns (
            address owner,
            string memory name,
            bytes32 metadataHash,
            uint256 createdAt
        )
    {
        Identity storage identity = _identities[identityId];
        return (
            identity.owner,
            identity.name,
            identity.metadataHash,
            identity.createdAt
        );
    }

    function getChains(uint256 identityId)
        external
        view
        identityExists(identityId)
        returns (uint256[] memory)
    {
        return _identities[identityId].chainIds;
    }

    function getChainRecord(uint256 identityId, uint256 chainId)
        external
        view
        identityExists(identityId)
        chainExists(identityId, chainId)
        returns (
            uint256 chainIdOut,
            address chainAddress,
            bool verified,
            uint256 addedAt
        )
    {
        ChainRecord storage record = _identities[identityId].chains[chainId];
        return (
            record.chainId,
            record.chainAddress,
            record.verified,
            record.addedAt
        );
    }

    function getUserIdentities(address user)
        external
        view
        returns (uint256[] memory)
    {
        return _userIdentities[user];
    }

    function getIdentityByAddress(address user)
        external
        view
        returns (uint256)
    {
        return _addressToIdentity[user];
    }
}
