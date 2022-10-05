## @debond-protocol/Bank

This package consist of smart contracts that acts as orchestrator for users to buy and redeem bonds for any corresponding underlying collateral supported by the protocol,  and routing of the collateral with the APM. 

developers can:

- interact with the deployed bank contract with their custom frontend/frotnend interface.
- implement your own custom version of bank contract and interact with any market maker (AMM, APM, etc) and with the bonds.

## contracts: 

- Bank.sol : The higher level interface functions for buying and also redeeming the bonds. 
- BankStorage.sol: storing the details about approved classes, and the class details mapped with the underlying collateral.
- BankRouter.sol: interface for swapping the users ETH or collateral tokens (in order to obtain DBIT/DGOV tokens for instance).

## Use:

```bash

npm i @debond-protocol/debond-bank-contracts

```

And then developers can integrate the interfaces to create their own implementation for buying/staking in bonds:

```solidity

import "@debond-protocol/debond-bank-contracts/interfaces/IBank.sol";


contract demoBank is IBank {
.....
}
```




## for any issues: 

Discord channel: [here](https://discord.gg/FzBspA5Y). 
Security bugs : info@debond.org