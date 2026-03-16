user to funds mapping, updated using deposit and withdraw functions 
flashloan function: sends ether to receiver, check the balance before and after the call to receiver, revert if balance after is less than before. actual ether in pool is calculated using address(this).balance 


attacker has 1 ETH, pool has 1000 ETH, rescue all ETH from the pool and deposit into recovery account.

idea #1:
take loan, use callback to deposit the same ETH into pool (update the mapping). this will pass the balance check as the address(this).balance is restored by the deposit earlier. call withdraw to get the 1000 ETH out of the pool. then transfer to recovery address.
