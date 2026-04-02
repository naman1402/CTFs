pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";

interface IStunt {
    function attempt(address target) external;

    function claimReward(address target) external;

    function withdraw() external;

    function owner() external returns (address);

    function solved(address) external returns (bool);

    function claimed(address) external returns (bool);
}

interface ITarget {
    function first() external returns (bytes32);

    function second() external returns (bytes32);

    function third() external returns (bytes32);
}

// https://onlypwner.xyz/challenges/8
/*
there are 100 eth in the contract, first person to solve the challenge receives the full amount. 
the target can only claim 100 ether when the (extcodesize) size is <= 3 (and > 0)
we need to create a contract address, pass attempt() and then selfdestruct the contract in the same transaction. and then redeploy the same address with smaller runtime (size==2) and call claimReward() to get all 100 ether.
post-shangai update: selfdestruct does not fully delete old contract across transactions. 
*/
contract SolveShapeShifter is Script {
    function run() external {
        vm.startBroadcast();
        vm.stopBroadcast();
    }
}