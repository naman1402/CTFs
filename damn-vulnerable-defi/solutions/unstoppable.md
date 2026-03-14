in the vault contract, there is a check
```
uint256 balanceBefore = totalAssets();
if (convertToShares(totalSupply) != balanceBefore) revert InvalidBalance();
```
this checks that the total shares in the vault & the total balance of the vault are in sync, if they are not then the function wont move forward. we can transfer vault token directly to the vault contract without using the deposit method, here totalAssets is updated the shares amount is not. BREAK THE VAULT!

