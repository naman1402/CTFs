lending pool - has uniswapv2 pair, factory, dvt token and weth token instance.
1. borrow method: calculate deposit amount from weth transfer, transfer weth to this pool, transfer dvt tokens to caller, emit event
2. oracle = dvt token amount * 3 / 1 ether;
- oracle uses uniswap v2, how it works
1. get reserve amount of WETH, DVT from uniswap 
2. uses qoute method from uniswapv2 library

attacker has 20 ETH, 10000 DVT tokens in balance. 
Lending Pool has 1_000_000 DVT tokens

hack idea:
- swap large amount of DVT for WETH, this increase DVT count in pool and make it cheaper so lending pool gives DVT at a lower price.
