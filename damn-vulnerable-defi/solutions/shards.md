marketplace where holders can sell nft, sellers can also offer them in smaller fractions (shards) and buyers can buy those shards represented using ERC1155.
marketplace pays the seller once the whole NFT is sold. 
marketplace charges 1% fee in DVT, stored in fee vault and integrated with DVT staking pool.
player starts with 0 DVT

1. ShardsFeeVault contract:
- permissioned, initializable, deposit token into vault -> staked, only owner can withdraw.
- owner can set unstake true or false, if true it claims rewards from staking pool and also withdraws the staking amount, if false it only transfers the token balance in the vault to the owner.

2. ShardsMarketplace contract:
- this marketplace is the owner of feevault, payment token is dvt and is set in the constructor.
- seller can call openOffer method: list nft and shards, update mapping, transfer nft to address(this), emit event, call _chargeFees. 
- buyer can call redeem method, get offer from nft id, call _burn method and transfer nft from address(this) to msg.sender, 
- fill method is called by the buyer for partial fills, validates offer stocks, price, isOpen, updates purchases mapping, transfers token from buyer to marketplace, if remaining stock is zero then close the offer. 

notes:
- _toDVT private function uses 1e6 as decimal price factor, using this with the multiDivDown in fill function can result into underflow and final result to be zero. 

hack idea:
we can use the underflow to  get significant number of NFT shards by paying 0 DVT tokens, maximum value of want that can result in a 0-price purchase is 113. 
- we can then cancel and return shards and receive DVT tokens, we can repeat this process until we drain enough dvt tokens, then transfer it to recovery address. (objective)
