pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";

interface ITutorial {
    function callMe() external;
}

contract SolveTutorial is Script {
    function run() public {
        vm.broadcast();
        ITutorial tutorial = ITutorial(0x78aC353a65d0d0AF48367c0A16eEE0fbBC00aC88);
        tutorial.callMe();
    }
}
