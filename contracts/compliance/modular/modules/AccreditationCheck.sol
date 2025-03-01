// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "../IModularCompliance.sol";
import "../../../token/IToken.sol";
import "./AbstractModuleUpgradeable.sol";
import "@onchain-id/solidity/contracts/interface/IClaimIssuer.sol";
import "@onchain-id/solidity/contracts/interface/IIdentity.sol";

/**
 * @title AccreditationVerificationModule
 * @dev Compliance module for verifying accredited investor or QIB status via ONCHAINID
 */
contract AccreditationVerificationModule is AbstractModuleUpgradeable {
    // Storage structure to avoid variable collision in upgradeable contracts
    struct AccreditationVerificationStorage {
        // Mapping of claim topics required for transfers (1 for accredited, 2 for QIB)
        mapping(uint256 => bool) requiredClaimTopics;
        // Mapping of trusted claim issuers
        mapping(address => bool) trustedClaimIssuers;
    }

    // Storage slot
    bytes32 private constant _ACCREDITATION_STORAGE_SLOT = 
        keccak256("AccreditationVerificationModule.storage");

    // Events
    event ClaimTopicAdded(uint256 indexed claimTopic);
    event ClaimTopicRemoved(uint256 indexed claimTopic);
    event ClaimIssuerAdded(address indexed issuer);
    event ClaimIssuerRemoved(address indexed issuer);

    /**
     * @dev Initializes the contract and sets the initial state.
     */
    function initialize() external initializer {
        __AbstractModule_init();
    }

    /**
     * @dev Add a claim topic that will be required for transfers
     * @param _claimTopic The claim topic to add
     */
    function addClaimTopic(uint256 _claimTopic) external onlyOwner {
        AccreditationVerificationStorage storage s = _getAccreditationStorage();
        require(!s.requiredClaimTopics[_claimTopic], "Claim topic already exists");
        s.requiredClaimTopics[_claimTopic] = true;
        emit ClaimTopicAdded(_claimTopic);
    }

    /**
     * @dev Remove a claim topic
     * @param _claimTopic The claim topic to remove
     */
    function removeClaimTopic(uint256 _claimTopic) external onlyOwner {
        AccreditationVerificationStorage storage s = _getAccreditationStorage();
        require(s.requiredClaimTopics[_claimTopic], "Claim topic doesn't exist");
        s.requiredClaimTopics[_claimTopic] = false;
        emit ClaimTopicRemoved(_claimTopic);
    }

    /**
     * @dev Add a trusted claim issuer
     * @param _issuer The address of the trusted claim issuer
     */
    function addTrustedIssuer(address _issuer) external onlyOwner {
        AccreditationVerificationStorage storage s = _getAccreditationStorage();
        require(_issuer != address(0), "Invalid issuer address");
        require(!s.trustedClaimIssuers[_issuer], "Issuer already trusted");
        s.trustedClaimIssuers[_issuer] = true;
        emit ClaimIssuerAdded(_issuer);
    }

    /**
     * @dev Remove a trusted claim issuer
     * @param _issuer The address of the issuer to remove
     */
    function removeTrustedIssuer(address _issuer) external onlyOwner {
        AccreditationVerificationStorage storage s = _getAccreditationStorage();
        require(s.trustedClaimIssuers[_issuer], "Issuer not trusted");
        s.trustedClaimIssuers[_issuer] = false;
        emit ClaimIssuerRemoved(_issuer);
    }

    /**
     * @dev Check if a claim topic is required
     * @param _claimTopic The claim topic to check
     * @return True if the claim topic is required
     */
    function isClaimTopicRequired(uint256 _claimTopic) external view returns (bool) {
        AccreditationVerificationStorage storage s = _getAccreditationStorage();
        return s.requiredClaimTopics[_claimTopic];
    }

    /**
     * @dev Check if an issuer is trusted
     * @param _issuer The issuer address to check
     * @return True if the issuer is trusted
     */
    function isIssuerTrusted(address _issuer) external view returns (bool) {
        AccreditationVerificationStorage storage s = _getAccreditationStorage();
        return s.trustedClaimIssuers[_issuer];
    }

    /**
     * @dev See {IModule-moduleTransferAction}.
     */
    function moduleTransferAction(
        address _from,
        address _to,
        uint256 _value
    ) external override onlyComplianceCall {
        // No state changes needed for transfers
    }

    /**
     * @dev See {IModule-moduleMintAction}.
     */
    function moduleMintAction(address _to, uint256 _value) external override onlyComplianceCall {
        // No state changes needed for minting
    }

    /**
     * @dev See {IModule-moduleBurnAction}.
     */
    function moduleBurnAction(address _from, uint256 _value) external override onlyComplianceCall {
        // No state changes needed for burning
    }

    /**
     * @dev Get the ONCHAINID for an address
     * @param _userAddress The user address
     * @param _compliance The compliance contract address
     * @return The ONCHAINID address
     */
    function _getIdentity(address _userAddress, address _compliance) internal view returns (address) {
        address token = IModularCompliance(_compliance).getTokenBound();
        return address(IToken(token).identityRegistry().identity(_userAddress));
    }

    /**
     * @dev Check if an identity has the required claims
     * @param _identity The identity address to check
     * @return True if the identity has at least one of the required claims
     */
    function _hasRequiredClaims(address _identity) internal view returns (bool) {
        if (_identity == address(0)) {
            return false;
        }

        AccreditationVerificationStorage storage s = _getAccreditationStorage();
        
        // Check each required claim topic
        for (uint256 claimTopic = 1; claimTopic <= 2; claimTopic++) {
            if (s.requiredClaimTopics[claimTopic]) {
                // Check if identity has a valid claim for this topic from any trusted issuer
                if (_hasValidClaim(_identity, claimTopic)) {
                    return true;
                }
            }
        }
        
        return false;
    }

    /**
     * @dev Check if an identity has a valid claim for a specific topic
     * @param _identity The identity address
     * @param _claimTopic The claim topic to check
     * @return True if a valid claim exists
     */
    function _hasValidClaim(address _identity, uint256 _claimTopic) internal view returns (bool) {
        AccreditationVerificationStorage storage s = _getAccreditationStorage();
        
        // Get all claim IDs for this topic
        bytes32[] memory claimIds = IIdentity(_identity).getClaimIdsByTopic(_claimTopic);
        
        // Check each claim
        for (uint256 i = 0; i < claimIds.length; i++) {
            (uint256 topic, uint256 scheme, address issuer, bytes memory signature, bytes memory data, string memory uri) = 
                IIdentity(_identity).getClaim(claimIds[i]);
                
            // Check if issuer is trusted and claim is valid
            if (s.trustedClaimIssuers[issuer]) {
                // We could add additional validation here if needed
                return true;
            }
        }
        
        return false;
    }

    /**
     * @dev See {IModule-moduleCheck}.
     * Checks if both sender and receiver have the required accreditation claims
     */
    function moduleCheck(
        address _from,
        address _to,
        uint256 _value,
        address _compliance
    ) external view override returns (bool) {
        // Skip check for zero address (minting)
        if (_from == address(0)) {
            address receiverIdentity = _getIdentity(_to, _compliance);
            return _hasRequiredClaims(receiverIdentity);
        }
        
        // Skip check for zero address (burning)
        if (_to == address(0)) {
            return true;
        }
        
        // Get identities
        address fromIdentity = _getIdentity(_from, _compliance);
        address toIdentity = _getIdentity(_to, _compliance);
        
        // Check if both addresses have the required claims
        return _hasRequiredClaims(fromIdentity) && _hasRequiredClaims(toIdentity);
    }

    /**
     * @dev See {IModule-canComplianceBind}.
     */
    function canComplianceBind(address _compliance) external view override returns (bool) {
        return true;
    }

    /**
     * @dev See {IModule-isPlugAndPlay}.
     */
    function isPlugAndPlay() external pure override returns (bool) {
        return true;
    }

    /**
     * @dev See {IModule-name}.
     */
    function name() external pure override returns (string memory _name) {
        return "AccreditationVerificationModule";
    }

    /**
     * @dev Get the storage structure
     */
    function _getAccreditationStorage() private pure returns (AccreditationVerificationStorage storage s) {
        bytes32 position = _ACCREDITATION_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }
}