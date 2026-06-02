// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IdentityVerifier is ReentrancyGuard, Ownable {
    constructor() Ownable(msg.sender) {}

    struct Verification {
        address verifier;
        uint256 identityId;
        string claimType;
        bytes32 claimHash;
        uint256 verifiedAt;
        uint256 expiresAt;
        bool revoked;
        bool exists;
    }

    struct VerifierRecord {
        address verifierAddress;
        string name;
        uint256 reputation;
        bool active;
        uint256 verificationsCount;
        uint256 revocationsCount;
    }

    uint256 private _verificationIds;
    mapping(uint256 => Verification) private _verifications;
    mapping(address => VerifierRecord) private _verifiers;
    mapping(address => uint256[]) private _verifierVerificationIds;
    mapping(uint256 => uint256[]) private _identityVerificationIds;

    event VerifierAdded(
        address indexed verifier,
        string name,
        uint256 reputation
    );
    event VerificationCreated(
        uint256 indexed verificationId,
        address indexed verifier,
        uint256 indexed identityId,
        string claimType
    );
    event VerificationRevoked(
        uint256 indexed verificationId,
        address indexed revoker
    );
    event VerifierReputationUpdated(
        address indexed verifier,
        uint256 oldReputation,
        uint256 newReputation
    );

    error VerifierAlreadyAdded(address verifier);
    error VerifierNotActive(address verifier);
    error VerificationDoesNotExist(uint256 verificationId);
    error VerificationAlreadyRevoked(uint256 verificationId);
    error InvalidAddress();
    error EmptyName();
    error EmptyClaimType();
    error InvalidExpiry();
    error ReputationOverflow();
    error OnlyVerifierOrOwner(address caller);
    error ReputationCannotBeNegative();

    modifier onlyVerifierOrOwner(address verifier) {
        if (msg.sender != owner() && msg.sender != verifier) {
            revert OnlyVerifierOrOwner(msg.sender);
        }
        _;
    }

    modifier verifierActive(address verifier) {
        if (!_verifiers[verifier].active) {
            revert VerifierNotActive(verifier);
        }
        _;
    }

    modifier verificationExists(uint256 verificationId) {
        if (!_verifications[verificationId].exists) {
            revert VerificationDoesNotExist(verificationId);
        }
        _;
    }

    function addVerifier(address verifierAddress, string calldata name, uint256 initialReputation)
        external
        onlyOwner
    {
        if (verifierAddress == address(0)) revert InvalidAddress();
        if (bytes(name).length == 0) revert EmptyName();
        if (_verifiers[verifierAddress].verifierAddress != address(0)) {
            revert VerifierAlreadyAdded(verifierAddress);
        }

        _verifiers[verifierAddress] = VerifierRecord({
            verifierAddress: verifierAddress,
            name: name,
            reputation: initialReputation,
            active: true,
            verificationsCount: 0,
            revocationsCount: 0
        });

        emit VerifierAdded(verifierAddress, name, initialReputation);
    }

    function deactivateVerifier(address verifier)
        external
        onlyOwner
        verifierActive(verifier)
    {
        _verifiers[verifier].active = false;
    }

    function updateVerifierReputation(address verifier, uint256 newReputation)
        external
        onlyOwner
        verifierActive(verifier)
    {
        uint256 oldReputation = _verifiers[verifier].reputation;
        _verifiers[verifier].reputation = newReputation;

        emit VerifierReputationUpdated(verifier, oldReputation, newReputation);
    }

    function verifyClaim(
        uint256 identityId,
        string calldata claimType,
        bytes32 claimHash,
        uint256 expiresAt
    )
        external
        nonReentrant
        verifierActive(msg.sender)
        returns (uint256)
    {
        if (identityId == 0) revert InvalidAddress();
        if (bytes(claimType).length == 0) revert EmptyClaimType();
        if (expiresAt <= block.timestamp) revert InvalidExpiry();

        uint256 verificationId = _verificationIds++;

        _verifications[verificationId] = Verification({
            verifier: msg.sender,
            identityId: identityId,
            claimType: claimType,
            claimHash: claimHash,
            verifiedAt: block.timestamp,
            expiresAt: expiresAt,
            revoked: false,
            exists: true
        });

        _verifierVerificationIds[msg.sender].push(verificationId);
        _identityVerificationIds[identityId].push(verificationId);

        VerifierRecord storage verifier = _verifiers[msg.sender];
        verifier.verificationsCount++;

        emit VerificationCreated(
            verificationId,
            msg.sender,
            identityId,
            claimType
        );

        return verificationId;
    }

    function revokeVerification(uint256 verificationId)
        external
        verificationExists(verificationId)
        onlyVerifierOrOwner(_verifications[verificationId].verifier)
    {
        Verification storage verification = _verifications[verificationId];

        if (verification.revoked) {
            revert VerificationAlreadyRevoked(verificationId);
        }

        verification.revoked = true;

        VerifierRecord storage verifier = _verifiers[verification.verifier];
        verifier.revocationsCount++;

        if (verifier.reputation >= 10) {
            uint256 oldReputation = verifier.reputation;
            verifier.reputation -= 10;
            emit VerifierReputationUpdated(
                verification.verifier,
                oldReputation,
                verifier.reputation
            );
        }

        emit VerificationRevoked(verificationId, msg.sender);
    }

    function isVerificationValid(uint256 verificationId)
        external
        view
        verificationExists(verificationId)
        returns (bool)
    {
        Verification storage verification = _verifications[verificationId];
        return !verification.revoked && verification.expiresAt > block.timestamp;
    }

    function getVerification(uint256 verificationId)
        external
        view
        verificationExists(verificationId)
        returns (
            address verifier,
            uint256 identityId,
            string memory claimType,
            bytes32 claimHash,
            uint256 verifiedAt,
            uint256 expiresAt,
            bool revoked
        )
    {
        Verification storage verification = _verifications[verificationId];
        return (
            verification.verifier,
            verification.identityId,
            verification.claimType,
            verification.claimHash,
            verification.verifiedAt,
            verification.expiresAt,
            verification.revoked
        );
    }

    function getVerifierVerifications(address verifier)
        external
        view
        returns (uint256[] memory)
    {
        return _verifierVerificationIds[verifier];
    }

    function getIdentityVerifications(uint256 identityId)
        external
        view
        returns (uint256[] memory)
    {
        return _identityVerificationIds[identityId];
    }

    function getVerifier(address verifier)
        external
        view
        returns (VerifierRecord memory)
    {
        return _verifiers[verifier];
    }
}
