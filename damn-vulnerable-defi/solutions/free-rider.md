nft marketplace:
- token id to price mapping, constructor = create nft, mint all nfts to msg.sender, amount is param
- owner can offer the nft using the offerMany (_offerOne method), which takes in an array of token ids and prices, and updates the mapping
- buyer can call buyMany method, which takes in an array of token ids calls _buyOne each time, this private function checks the msg.value against price of nft, transfers token from owner to msg.sender (buyer), and sends priceToPay to the owner and emits events.

vulnerability:
1. buyMany is payable, it takes msg.value and calls _buyOne each time, it does not check the msg.value against total values of all nft caller wants to buy. instead it checks msg.value against each nft price in _buyOne, so user can pay for one NFT and try to buy multiple NFT, with this wrong price check it will pass but during the ether transfer it will most likely fail.
2. BUT, in the _buyOne method, it performs price check (which we can pass if we have funds for one nft and wants to buy all), transfers the nft from owner to caller and later transfers funds from address(this) to owner which is US. it should send the funds to original owner as he is the seller, but as ownership has changes to it sends the fudns back to us.
buyer -> buy nfts & pays for 1 NFT -> becomes owner -> gets the funds back from address(this) for that nft -> so we can now pay for the next nft with the funds we got from the previous one, and repeat this process until we get all nfts for the price of one nft.

hack idea:
- use funds of one nft and buy all of them, as explained in the vulnerability. 
- 6 NFTs, each if 15 ETH, total bounty is 45 ETH to send it to the recovery address, balance is only 0.1 ETH. 
- we can use flashloan to get initial funds for one NFT, buy all NFTs, send them to recovery address and get the bounty, repay the FL and keep the profit.
take FL of WETH, swap for ETH and then buy the NFTs - later repay the loan
