there is an exchange contract
- has oracle and nft instance
- buyOne method: get median price using oracle and check against msg.value, mint to the msg.sender and send back extra ether and emit method.
- sellOne method: check ownership and approval, compare contract price with median price from oracle, transfer from caller to contract then burn the nft, send price to the caller and emit method. 
both methods are protected by a reentrancy guard.

trustful oracle: there are limited trusted sources set in the constructor -> granted role, and the price is the median of the prices from the trusted sources.
there is an trustfuloracle initializer contract, which take data in constructor -> deploys the oracle and set the trusted sources and initial price.

nft are costly in the exchange, there price of nft is fetched from the oracle (trusted sources) and attacker only has 0.1 ETH.

the data in response, it leaks Base64 encoded private keys of two of the trusted oracle sources, can use this to become source and manipulate the oracle -> NFT price becomes 0.1.
can decode this using chatgpt, to get private keys.
 hack idea:
 - decode data to get private keys, take over trusted sources, set prices to zero, buy, increase price back to 999 ether, sell and transfer the funds to recovery address.