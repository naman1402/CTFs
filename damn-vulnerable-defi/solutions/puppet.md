puppet-1 ctf:
there is an uniswap v1 with 10 ETH and 10 DVT in liquidity, 
lending pool: can borrow DVT token, need to deposit twice the amount of ETH as collateral. it has 10000 DVT token so we need to deposit 20000 ETH as collateral (we have 25 ETH).
goal: save all tokens from lending pool, deposit into recovery address

we start with: 25 ETH, 1000 DVT token.
hack idea:
- do some swap in uniswap v1 and change the ratio. we need more eth (to borrow dvt) so we exchange our DVT token for ETH.

oracle price = eth balance / dvt balance in uniswap v1, 
goal is to decrease eth and increase dvt balance in pool, 
we take eth from pool and give dvt tokens to the pool by swapping.
1. give 1000 dvt tokens to uniswap v1 and crash the price of dvt token (oracle manipulation because of low liquidity pool)
2. get some eth back from the pool, use this eth to borrow DVT tokens from lending pool. after the swap, oracle price will be very low so we will have double the collateral. 