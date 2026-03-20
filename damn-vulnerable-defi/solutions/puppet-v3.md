lending pool using uniswap v3 as price oracle, 
deposit factor for loan is 3.

oracle:
- uses uniswap v3 oracle libary, gets tick from uniswap v3 pool that was 10 minutes ago, get quote price from tick using oracle library (tick, amount, token0, token1)
- deposit amount is oracle quote * deposti factor which is 3

borrow function:
- user sets amount of token they want, 
- transfer collateral (weth) to pool , this amount is calculated using oracle
- update mapping, transfer token amount set by user to borrower and emit events

note:
uniswap pool has 100 weth, 100 dvt token
lending pool has 1_000_000 dvt token 
we have 1 eth and 110 dvt token
must solve this withint 115 seconds, 

hack idea:
1. how normal oracle manipulation works:
- swap dvt token for weth, increase dvt supply in pool so it's price decreases, we have eth and try to borrow dvt token as price is down, get as much dvt token. 
2. we can exchange 110 DVT token for some eth, making DVT extremely cheap. since twap is delayed, attacker needs to exploit price manipulation before TWAP price recovers to its normal price. 