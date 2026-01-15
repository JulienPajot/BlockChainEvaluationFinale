// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Script.sol";
import {SimpleVotingSystem} from "../src/SimpleVotingSystem.sol";
import {VotingNFT} from "../src/VotingNFT.sol";

contract DeploySimpleVoting is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        VotingNFT votingNFT = new VotingNFT();
        SimpleVotingSystem votingSystem = new SimpleVotingSystem(address(votingNFT));
        votingNFT.transferOwnership(address(votingSystem));

        vm.stopBroadcast();
    }
}