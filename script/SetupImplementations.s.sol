// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "../contracts/proxy/authority/TREXImplementationAuthority.sol";
import "../contracts/proxy/authority/ITREXImplementationAuthority.sol";
import "../contracts/token/Token.sol";
import "../contracts/registry/ClaimTopicsRegistry.sol";
import "../contracts/registry/IdentityRegistry.sol";
import "../contracts/registry/IdentityRegistryStorage.sol";
import "../contracts/registry/TrustedIssuersRegistry.sol";
import "../contracts/compliance/modular/ModularCompliance.sol";

contract SetupImplementations is Script {
    function run() external {
        // Load private key for deployment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);
        
        // Address of the deployed Implementation Authority
        address implementationAuthorityAddress = 0x5FbDB2315678afecb367f032d93F642f64180aa3; // Replace with your actual deployed address
        TREXImplementationAuthority implementationAuthority = TREXImplementationAuthority(implementationAuthorityAddress);
        
        // Define version
        ITREXImplementationAuthority.Version memory version = ITREXImplementationAuthority.Version({
            major: 4,
            minor: 0,
            patch: 0
        });
        
        // Deploy implementation contracts
        address tokenImplementation = address(new Token());
        address ctrImplementation = address(new ClaimTopicsRegistry());
        address irImplementation = address(new IdentityRegistry());
        address irsImplementation = address(new IdentityRegistryStorage());
        address tirImplementation = address(new TrustedIssuersRegistry());
        address mcImplementation = address(new ModularCompliance());
        
        // Set up implementation contracts
        ITREXImplementationAuthority.TREXContracts memory contracts = ITREXImplementationAuthority.TREXContracts({
            tokenImplementation: tokenImplementation,
            ctrImplementation: ctrImplementation,
            irImplementation: irImplementation,
            irsImplementation: irsImplementation,
            tirImplementation: tirImplementation,
            mcImplementation: mcImplementation
        });
        
        // Add and use TREX version
        implementationAuthority.addAndUseTREXVersion(version, contracts);
        
        vm.stopBroadcast();
    }
} 