// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "../contracts/factory/TREXFactory.sol";
import "../contracts/factory/ITREXFactory.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DeployToken is Script {
    using stdJson for string;

    function run() external {
        // Load private key for deployment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);
        
        // Load token details from JSON file
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/script/tokenDetails.json");
        string memory json = vm.readFile(path);
        
        // Get the factory address - this should be deployed already
        // Replace with your actual factory address
        address factoryAddress = 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318;
        TREXFactory factory = TREXFactory(factoryAddress);
        
        // Parse the tokens array from the JSON
        bytes memory tokenDataRaw = json.parseRaw(".tokens");
        ITREXFactory.TokenDetails[] memory tokenDetailsArray = abi.decode(tokenDataRaw, (ITREXFactory.TokenDetails[]));
        
        // Deploy each token
        for (uint256 i = 0; i < tokenDetailsArray.length; i++) {
            ITREXFactory.TokenDetails memory tokenDetails = tokenDetailsArray[i];
            
            // Create claim details for this token
            ITREXFactory.ClaimDetails memory claimDetails;
            
            // Parse claim topics
            string memory claimTopicsPath = string.concat(".tokens[", Strings.toString(i), "].claimTopics");
            bytes memory claimTopicsRaw = json.parseRaw(claimTopicsPath);
            claimDetails.claimTopics = abi.decode(claimTopicsRaw, (uint256[]));
            
            // Parse issuers
            string memory issuersPath = string.concat(".tokens[", Strings.toString(i), "].issuers");
            bytes memory issuersRaw = json.parseRaw(issuersPath);
            claimDetails.issuers = abi.decode(issuersRaw, (address[]));
            
            // Parse issuer claims
            string memory issuerClaimsPath = string.concat(".tokens[", Strings.toString(i), "].issuerClaims");
            bytes memory issuerClaimsRaw = json.parseRaw(issuerClaimsPath);
            claimDetails.issuerClaims = abi.decode(issuerClaimsRaw, (uint256[][]));
            
            // Generate a unique salt for this token
            string memory salt = string(abi.encodePacked(
                Strings.toHexString(tokenDetails.owner),
                tokenDetails.name
            ));
            
            // Deploy the token suite
            factory.deployTREXSuite(salt, tokenDetails, claimDetails);
            
            console.log("Deployed token:", tokenDetails.name);
            console.log("Token address:", factory.getToken(salt));
        }
        
        vm.stopBroadcast();
    }
}
