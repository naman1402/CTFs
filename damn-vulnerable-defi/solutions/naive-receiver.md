call flashloan function in naivereceiverpool contract, 
in the receiver contract, onFlashLoan function has no access control for the caller address. it pays fees for anyone. 
receiver contract has 10 WETH balance, the FL fee is 1 WETH. with this wrong onFlashLoan function we can create FLs
and let the receiver contract pay the fee for us, repeat this until receiver loses all funds i.e., 10 times.

- need to create 10 FL to drain the receiver contract with amount 0  
for the withdrawal, 

```
uint256 TOTAL_AMOUNT = WETH_IN_POOL + WETH_IN_RECEIVER;
callDatas[10] = abi.encodePacked(
    abi.encodeCall(NaiveReceiverPool.withdraw, (TOTAL_AMOUNT, payable(recovery))),
    bytes32(uint256(uint160(deployer)))
);
```
_msgSender() reads the last 20 bytes (if coming from a TrustedForwarder) -> get deployer address
deposits[deployer] -= 1010 WETH (1000 original, 10 from receiver)   ==> test passes!
transfer this 1010 WETH to recovery address.
all these calls happens using one multicall, using the trusted forwarder, so we can impersonate the deployer address and make the pool think that the deployer is calling the withdraw function, which allows us to drain the pool.