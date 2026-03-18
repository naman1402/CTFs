there is a wallet registry contract, 
this is a registry contract for safe multisig wallet, deploy and register safe wallets and the registry awards tokens to the wallet.

variables:
- singletonCopy instance and walletFactory instance, these are used to create the safe wallet
- ERC20 token instance
- mapping to store beneficiaries (address to bool)
- mapping to store wallet data (address to address)

beneficiaries can only be added by owner, make the address state true.

a user can create a safe through the proxy factory -> createProxyWithCallback function. 
factory then deploys the safe and calls the registry proxy created function as callback (which is in this contract).
this registry method verifies the wallet:
1. check the caller is the factory, singletone as expected 
2. inits with Safe.setup selector, check the owners count and threshold, and owner should be beneficiary
3. fallback manager should be address(0)
4. after check are performed and wallet passes, it updates the mapping (make the beneficiary false, and wallet mapping with the new address), transfers token to wallet address. (send 10 DVT)

more about safe wallet setup:
setup function takes address to and bytes data as param, and make delegate call to `to` if it is not address(0).
the setup function calls setupModules with to, data as param -> this checks and makes the delegate call.
this is not checked by the registry, so we can pass an address in the safe setup and pass data to create an deletegate call to the attacker contract.

hack idea:
in this delegatecall we can give approval to attacker for the tokens in new wallet.
there are four users who are beneficiaries, we can create four wallets for them and in the setup of each wallet we can give approval to the attacker contract, then we can transfer all the tokens from these wallets to our address.
- we create approvalmodule contract, in each wallet setup we keep to = address(module) and data = approveToken(token, attacker), delegatecall runs on storage context to this approval runs as it is executed as if Safe called it. attacker takes 10 DVT tokens from safe to recovery (attacker has approval).

