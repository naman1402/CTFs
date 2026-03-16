lending pool that offers flash loans of dvt token for free, 
flashloan function:
- balance before of dvt token in the pool
- send dvt token to borrower
- call encoded function on borrower contract using target.functionCall(data), data is param -> ideally should be receiver method call so borrower can pay back 
- balance check, before vs current balance of dvt tokens in pool. revert if current balance is less. 

hack idea:
- send mal data in flashloan function, this data will be approavl fuction in the token address (target addres) and borrower will be the attacker contract
- so the attacker contract will be borrower, target will be token address. attacker will create FL of zero token and in the data, it will encode the approval function of the token contract, so the token address (target) will call the approval function and approve the attacker contract to spend the tokens in the pool. the balance check will pass because amount is zero so we are not really taking any tokens during the loan.
- need to do this in the attacker contract constructor because we need to do this in a single txns. deploying and calling a method cannot be done in the same transaction. 

```
bytes memory data = 
    abi.encodeWithSignature("approve(address,uint256)", address(this), _token.balanceOf(address(_pool)));
_pool.flashLoan(0, address(this), address(_token), data);
_token.transferFrom(address(_pool), _recoveryAddr, _token.balanceOf(address(_pool)));
```
