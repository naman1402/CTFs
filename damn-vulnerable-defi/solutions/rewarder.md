this contract is for distributing rewards of DVT tokens and ethers.
every ERC20 token has it's own distribution struct data (remaining count, batch, round to root, user to proof mapping, etc)
single contract supports multiple ERC20 token distribution 
using merkle proofs for claims verification, and bitmap for tracking claimed rewards.
https://medium.com/@JohnnyTime/the-rewarder-challenge-solution-damn-vulnerable-defi-v4-e8af3251ac61 

the mapping is updated through the _setClaimed internal function, 
tokens are transferred after proof verification but before bitmap update 
exploit:
grouping many identical claims for DVT tokens together, using the same valid proof for each claim. 
getting many transfers before the bitmap is ever checked, repeating the same for WETH token. 
