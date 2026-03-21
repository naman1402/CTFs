there is a permissioned vault with 1 million DVT, allows withdraw periodically as well as take all in case of emergencies.

1. AuthorizerExecutor contract:
- initialized boolean, actions bytes to bool mapping.
- setPermissions function, can be called once then initialized is set to true, sets the actions mapping to true for the given actions, no access control, anyone can call it.
- execute function: performs arbitrary call on a target contract, check permission if the user is allowed to perform the action, if not revert, otherwise execute the call.

2. SelfAuthorizedVault contract:
- withdrawal limit is 1 ether, waiting period is 15 days, stores last withdrawal timestamp.
- withdraw function can only be called by this contract, checks limit and time period, updates last timestamp and transfers the amount. 
- sweep funds can be called by this contract only, transfers all funds to the receiver
- _beforeFunctionCall is called everytime execute method is called in the AuthorizerExecutor and it checks if the target is vault conttract or not.

note:
AuthorizerExecutor.execute function: takes actionData as param
uses calldataload to extract 4 bytes of function selector from the provided actionData,starting from calldataOffset (100 bytes). 
from this selector, it checks the action id (function selector, msg.sender, target address), we can get the function selector of the sweepFunds function and call this method but we need to bypass the permissions check in the AuthorizerExecutor contract.

hack idea:
- the sweep funds can be only called by the vault contract itself, so we have to use the execute method of AuthorizerExecutor contract.
- player has access to call withdraw function and not sweepFunds 
- in execute function, it is assumed that the function selector is at byte 100 (0x40)
- we have to craft calldata and set offset to something else (0x80).
- to pass the permission check we will pass a decoy withdraw selector, 

took help from this: https://github.com/SunWeb3Sec/damn-vulnerable-defi-v4-solutions/blob/main/writeup.md#15-abi-smuggling 