// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "../contracts/factory/TREXFactory.sol";
import "../contracts/factory/ITREXFactory.sol";

contract DeployToken is Script {
    function run() external {
        // Load private key for deployment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address owner = vm.addr(deployerPrivateKey);
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);
        
        // Get the factory address - this should be deployed already
        address factoryAddress = 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318;
        TREXFactory factory = TREXFactory(factoryAddress);
        
        // Use your provided ONCHAINID contract address
        address onchainId = 0x9A676e781A523b5d0C0e43731313A708CB607508;
        
        // Empty arrays for agents and compliance
        address[] memory tokenAgents = new address[](0);
        address[] memory irAgents = new address[](0);
        address[] memory complianceModules = new address[](0);
        bytes[] memory complianceSettings = new bytes[](0);
        
        // Create token details struct
        ITREXFactory.TokenDetails memory tokenDetails = ITREXFactory.TokenDetails({
            name: "Example Security Token",
            symbol: "EST",
            decimals: 18,
            owner: owner,
            irs: address(0),
            ONCHAINID: onchainId,  // Using your provided ONCHAINID address
            irAgents: irAgents,
            tokenAgents: tokenAgents,
            complianceModules: complianceModules,
            complianceSettings: complianceSettings
        });
        
        // Hardcoded claim details
        uint256[] memory claimTopics = new uint256[](2);
        claimTopics[0] = 1;
        claimTopics[1] = 7;
        
        address[] memory issuers = new address[](1);
        issuers[0] = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        
        uint256[][] memory issuerClaims = new uint256[][](1);
        issuerClaims[0] = new uint256[](2);
        issuerClaims[0][0] = 1;
        issuerClaims[0][1] = 7;
        
        ITREXFactory.ClaimDetails memory claimDetails = ITREXFactory.ClaimDetails({
            claimTopics: claimTopics,
            issuers: issuers,
            issuerClaims: issuerClaims
        });
        
        // Generate a unique salt for this token
        string memory salt = string(abi.encodePacked(
            toHexString(tokenDetails.owner),
            tokenDetails.name
        ));
        
        // Deploy the token suite
        factory.deployTREXSuite(salt, tokenDetails, claimDetails);
        
        console.log("Deployed token:", tokenDetails.name);
        console.log("Token address:", factory.getToken(salt));
        
        vm.stopBroadcast();
    }
    
    // Helper function to convert address to hex string
    function toHexString(address addr) internal pure returns (string memory) {
        bytes memory buffer = new bytes(42);
        buffer[0] = '0';
        buffer[1] = 'x';
        for (uint256 i = 0; i < 20; i++) {
            uint8 b = uint8(uint160(addr) / (2**(8*(19 - i))));
            buffer[2 + i*2] = toHexChar(b / 16);
            buffer[3 + i*2] = toHexChar(b % 16);
        }
        return string(buffer);
    }
    
    // Helper function to convert uint8 to hex character
    function toHexChar(uint8 val) internal pure returns (bytes1) {
        if (val < 10) {
            return bytes1(uint8(bytes1('0')) + val);
        } else {
            return bytes1(uint8(bytes1('a')) + val - 10);
        }
    }
}
