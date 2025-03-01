// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "../contracts/factory/TREXFactory.sol";
import "../contracts/proxy/authority/TREXImplementationAuthority.sol";
import "@onchain-id/solidity/contracts/factory/IdFactory.sol";
import "../contracts/token/Token.sol";
import "../contracts/registry/Implementation/ClaimTopicsRegistry.sol";
import "../contracts/registry/Implementation/IdentityRegistry.sol";
import "../contracts/registry/Implementation/IdentityRegistryStorage.sol";
import "../contracts/compliance/modular/ModularCompliance.sol";
import "../contracts/registry/Implementation/TrustedIssuersRegistry.sol";

contract DeployFactory is Script {
    function run() external {
        // Load private key for deployment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy all implementation contracts first
        Token tokenImplementation = new Token();
        console.log("Deployed Token Implementation at:", address(tokenImplementation));
        
        ClaimTopicsRegistry ctrImplementation = new ClaimTopicsRegistry();
        console.log("Deployed CTR Implementation at:", address(ctrImplementation));
        
        IdentityRegistry irImplementation = new IdentityRegistry();
        console.log("Deployed IR Implementation at:", address(irImplementation));
        
        IdentityRegistryStorage irsImplementation = new IdentityRegistryStorage();
        console.log("Deployed IRS Implementation at:", address(irsImplementation));
        
        ModularCompliance mcImplementation = new ModularCompliance();
        console.log("Deployed MC Implementation at:", address(mcImplementation));
        
        TrustedIssuersRegistry tirImplementation = new TrustedIssuersRegistry();
        console.log("Deployed TIR Implementation at:", address(tirImplementation));
        
        // Deploy the Implementation Authority
        TREXImplementationAuthority implementationAuthority = new TREXImplementationAuthority(
            true, // reference status
            address(0), // trexFactory (will be set later)
            address(0)  // iaFactory (optional for initial deployment)
        );
        console.log("Deployed Implementation Authority at:", address(implementationAuthority));
        
        // Create a Version struct
        ITREXImplementationAuthority.Version memory version = ITREXImplementationAuthority.Version({
            major: 4,
            minor: 0,
            patch: 0
        });
        
        // Create a TREXContracts struct with all implementations
        ITREXImplementationAuthority.TREXContracts memory contracts = ITREXImplementationAuthority.TREXContracts({
            tokenImplementation: address(tokenImplementation),
            ctrImplementation: address(ctrImplementation),
            irImplementation: address(irImplementation),
            irsImplementation: address(irsImplementation),
            mcImplementation: address(mcImplementation),
            tirImplementation: address(tirImplementation)
        });
        
        // Add the version with implementations and set it as current
        implementationAuthority.addAndUseTREXVersion(version, contracts);
        console.log("Added and set implementations in the Implementation Authority");
        
        // Deploy the Identity Factory with the deployer as the owner
        address deployer = vm.addr(deployerPrivateKey);
        IdFactory idFactory = new IdFactory(deployer);
        console.log("Deployed Identity Factory at:", address(idFactory));
        
        // Deploy the TREX Factory
        TREXFactory factory = new TREXFactory(
            address(implementationAuthority),
            address(idFactory)
        );
        console.log("Deployed TREX Factory at:", address(factory));
        
        // Set the factory address in the implementation authority
        implementationAuthority.setTREXFactory(address(factory));
        console.log("Set factory address in Implementation Authority");
        
        // Add the factory to the identity factory
        idFactory.addTokenFactory(address(factory));
        console.log("Added factory to Identity Factory");
        
        vm.stopBroadcast();
    }
} 