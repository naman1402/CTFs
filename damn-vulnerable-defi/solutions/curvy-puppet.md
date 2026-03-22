lending protocol:
- can borrow LP token from curve stETH/ETH pool, collateral is DVT token
- borrowed positions grows than collateral - anyone can liquidate by repaying the debt (eth) and taking the collateral (DVT)
- uses permit2 for approvals, using permissioned oracle.
- alice, bob, charlie are borrowers; created overcollateralize positions. 
- we have 200 WETH, 6 LP tokens. 

1. oracle contract:
- address asset to price mapping, price contains value and expiration timestamp, 
- only owner can set the price
- getter function, take asset address and returns the Price struct, if price is expired it reverts.

2. lending contract:
- has borrow asset, collateral asset, instance of oracle, curve pool, permit2 contract.
- user to positions mapping, positions has collateral and borrow amount.
- deposit, withdraw functions
- borrow, redeem, liquidate functions

- three user deposited 2500 DVT as collateral to borrow 1 LP token, as long as the collateral value remains above 1.75 x the borrowed value.
- 
hack idea:
unlike previous puppet challenge, we cannot manipulate the price of curve pool with this less funds (mainnet pool) as it has significant liquidity, 

TOUGH ⚠️