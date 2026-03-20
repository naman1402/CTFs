contract overview:
1. AuthorizerUpgradeable: 
- holds a mapping for address->address->uint256 named wards; only allow certain deployers to be paid for specific deployments.
- init can only be called once (updating local state variable), `can` function can be called by anyone to check if a deployer is authorized or not, `_reply` method updates the mapping and only called by init method (which can be only called once)

2. TransparentProxy: 
- inherits ERC1967Proxy, local upgrader variable stores the address of the deployer, 
- there is a `_fallback` function. built on top of proxy (override), checks the msg.sender if it is the upgrader or not, if no then call the fallback function of the parent contract, 

if yes then check the msg.sig to signature of upgradeToAndCall(address, bytes) function and calls the `_dispatchUpgradeToAndCall` function, this function decodes derive params and call the upgradeToAndCall function of the parent contract. 

3. AuthorizaFactory:
- has a single function named `deployWithProxy` creates the TransparentProxy with new implementation/logic contract address and encoded bytes data of the Upgradeable.init method; init data has the wards data (for mapping in AuthorizerUpgradeable)
- checks the needsInit variable in authorizer contract and check if it is zero or not. should be zero if the init method is called in the contract which sets up the wards mapping
- also in the proxy contract is sets the upgrader to upgrader from param, which is the deployer of the proxy contract, and this is the only address that can call the upgradeToAndCall function in the TransparentProxy contract.

4. WalletDeployer contract:
- this contract allows users to deploy safe wallet, rewards them as well. 
- there is a chief that can set mom variable, 
- `aim` should be authorized, can deploy Safe at target address (aim) and pays 1 DVT.
- checks auth, call safe to deploy at target address if successful it pays the caller 1 ether of gem token which is dvt, `can` method is auth function uses low-level assembly. 

problem:
this address has 20M DVT 0xCe07CF30B540Bb84ceC5dA5547e1cb4722F9E496; user's 1:1 Safe should have landed here but lost the nonce. we need to deploy a Safe wallet at the same address and move the funds to recovery address. all in one txn, we have the private key of deployer. 

note:
- safeproxy delegates all logic to a Safe wallet singleton, it's primary function is to forward calls to the singleton using delegatecall. SafeProxy contracts are creatd using CREATE2 opcode.
we can deterministically calculate their address, 
- to guess the salt nonce, we need to brute-force by iterating through possible vaues using for loop.
- once we find the correct salt nonce, we need to use the drop function in WalletDeployer, due to storage collision 

hack idea:
- in the auth factory, after the proxy setup the setUpgrader(upgrader) make slot0 non-zero again, so we can call the init method in Authorizer again and update the wards mapping to authorize our deployer address. 
- ideally, upgrader should change slot0 of the proxy contract which stores the upgrader address. as the authorizer contract is a proxy contract, it has the same storage layout as the TransparentProxy contract, this can change the needsInit method.
 