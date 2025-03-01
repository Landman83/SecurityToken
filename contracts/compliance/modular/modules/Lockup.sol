// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "../IModularCompliance.sol";
import "../../../token/IToken.sol";
import "../../../roles/AgentRole.sol";
import "./AbstractModuleUpgradeable.sol";

contract LockupPeriodModule is AbstractModuleUpgradeable {
    // Lockup period set to 6 minutes (360 seconds)
    uint256 public constant LOCKUP_PERIOD = 360;

    // Deployment timestamp for the token bound to the compliance contract
    mapping(address => uint256) public deploymentTimestamps;

    /**
    *  this event is emitted when the lockup period is set for a compliance contract
    *  the event is emitted during initialization or binding
    *  compliance is the compliance contract address
    *  _timestamp is the deployment timestamp
    */
    event LockupPeriodSet(address indexed compliance, uint256 _timestamp);

    /**
     * @dev initializes the contract and sets the initial state.
     * @notice This function should only be called once during the contract deployment.
     */
    function initialize() external initializer {
        __AbstractModule_init();
    }

    /**
     * @dev Sets the deployment timestamp for a compliance contract
     * @param _timestamp The timestamp to set
     * Only the compliance contract can call this function
     */
    function setDeploymentTimestamp(uint256 _timestamp) external onlyComplianceCall {
        if (deploymentTimestamps[msg.sender] == 0) {
            deploymentTimestamps[msg.sender] = _timestamp;
            emit LockupPeriodSet(msg.sender, _timestamp);
        }
    }

    /**
     *  @dev See {IModule-moduleTransferAction}.
     *  Records the deployment timestamp if not already set
     */
    function moduleTransferAction(address /*_from*/, address /*_to*/, uint256 /*_value*/) external override onlyComplianceCall {
        // Set deployment timestamp on first interaction if not already set
        if (deploymentTimestamps[msg.sender] == 0) {
            deploymentTimestamps[msg.sender] = block.timestamp;
            emit LockupPeriodSet(msg.sender, block.timestamp);
        }
    }

    /**
     *  @dev See {IModule-moduleMintAction}.
     *  Records the deployment timestamp if not already set
     */
    function moduleMintAction(address /*_to*/, uint256 /*_value*/) external override onlyComplianceCall {
        // Set deployment timestamp on first interaction if not already set
        if (deploymentTimestamps[msg.sender] == 0) {
            deploymentTimestamps[msg.sender] = block.timestamp;
            emit LockupPeriodSet(msg.sender, block.timestamp);
        }
    }

    /**
     *  @dev See {IModule-moduleBurnAction}.
     *  Records the deployment timestamp if not already set
     */
    function moduleBurnAction(address /*_from*/, uint256 /*_value*/) external override onlyComplianceCall {
        // Set deployment timestamp on first interaction if not already set
        if (deploymentTimestamps[msg.sender] == 0) {
            deploymentTimestamps[msg.sender] = block.timestamp;
            emit LockupPeriodSet(msg.sender, block.timestamp);
        }
    }

    /**
     *  @dev See {IModule-moduleCheck}.
     *  Checks if the transfer is allowed based on the lockup period.
     */
    function moduleCheck(
        address _from,
        address /*_to*/,
        uint256 /*_value*/,
        address _compliance
    ) external view override returns (bool) {
        // Allow minting (from address(0)) and agent transfers
        if (_from == address(0) || _isTokenAgent(_compliance, _from)) {
            return true;
        }

        // Check if the lockup period has elapsed
        uint256 startTime = deploymentTimestamps[_compliance];
        if (startTime == 0) {
            // If not set, assume still in lockup (safety mechanism)
            return false;
        }

        return block.timestamp >= startTime + LOCKUP_PERIOD;
    }

    /**
     *  @dev See {IModule-canComplianceBind}.
     */
    function canComplianceBind(address /*_compliance*/) external view override returns (bool) {
        return true;
    }

    /**
     *  @dev See {IModule-isPlugAndPlay}.
     */
    function isPlugAndPlay() external pure override returns (bool) {
        return true;
    }

    /**
     *  @dev See {IModule-name}.
     */
    function name() external pure override returns (string memory _name) {
        return "LockupPeriodModule";
    }

    /**
     *  @dev Returns the ONCHAINID (Identity) of the _userAddress
     *  @param _userAddress Address of the wallet
     */
    function _getIdentity(address _compliance, address _userAddress) internal view returns (address) {
        return address(IToken(IModularCompliance(_compliance).getTokenBound()).identityRegistry().identity(_userAddress));
    }

    /**
     *  @dev Checks if the given user address is an agent of token
     *  @param compliance the Compliance smart contract to be checked
     *  @param _userAddress ONCHAIN identity of the user
     */
    function _isTokenAgent(address compliance, address _userAddress) internal view returns (bool) {
        return AgentRole(IModularCompliance(compliance).getTokenBound()).isAgent(_userAddress);
    }
}