// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "../contracts/compliance/modular/modules/AccreditationCheck.sol";
import "../contracts/compliance/modular/modules/Lockup.sol";
import "../contracts/compliance/modular/modules/ModuleProxy.sol";

contract DeployComplianceModules is Script {
    function run() external {
        // Load private key for deployment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address owner = vm.addr(deployerPrivateKey);
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy module implementations
        AccreditationVerificationModule accreditationImpl = new AccreditationVerificationModule();
        console.log("Deployed AccreditationVerificationModule implementation at:", address(accreditationImpl));
        
        LockupPeriodModule lockupImpl = new LockupPeriodModule();
        console.log("Deployed LockupPeriodModule implementation at:", address(lockupImpl));
        
        // Create initialization data for modules
        bytes memory accreditationInitData = abi.encodeWithSignature("initialize()");
        bytes memory lockupInitData = abi.encodeWithSignature("initialize()");
        
        // Deploy module proxies
        ModuleProxy accreditationProxy = new ModuleProxy(address(accreditationImpl), accreditationInitData);
        console.log("Deployed AccreditationVerificationModule proxy at:", address(accreditationProxy));
        
        ModuleProxy lockupProxy = new ModuleProxy(address(lockupImpl), lockupInitData);
        console.log("Deployed LockupPeriodModule proxy at:", address(lockupProxy));
        
        // Configure AccreditationVerificationModule
        AccreditationVerificationModule accreditationModule = AccreditationVerificationModule(address(accreditationProxy));
        
        // Add claim topics (1 for accredited investor, 2 for QIB)
        accreditationModule.addClaimTopic(1);
        accreditationModule.addClaimTopic(2);
        
        // Add trusted issuer (using the same issuer as in your token deployment)
        accreditationModule.addTrustedIssuer(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
        
        console.log("Configured AccreditationVerificationModule");
        
        // LockupPeriodModule is already configured with default 6-minute lock period
        console.log("LockupPeriodModule configured with default 6-minute lock period");
        
        vm.stopBroadcast();
    }
}