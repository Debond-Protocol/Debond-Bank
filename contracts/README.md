## @debond-protocol/Bank

This package consist of smart contracts that acts as orchestrator for users to buy and redeem bonds for any corresponding underlying collateral supported by the protocol,  and routing of the collateral with the APM. 

Developers can:

- interact with the deployed bank contract with their custom frontend/frotnend interface.
- implement your own custom version of bank contract and interact with any market maker (AMM, APM, etc) and with the bonds.

## contract interfaces: 

- Bank.sol : The higher level interface functions for buying/redeeming the bonds, other contracts MUST need to inherit the functions in order to issue / buy bonds across purchasable class pairs as defined for the Multilayer pools. the interface is described [here](https://github.com/Debond-Protocol/Debond-Bank/blob/main/contracts/interfaces/IBank.sol).


- BankStorage.sol: storing the mapping about whitelisted bond classes, benchmark_interest_rate and baseTimestamp (used for calculation of the interest). interface is [here](https://github.com/Debond-Protocol/Debond-Bank/blob/main/contracts/interfaces/IBankStorage.sol). this is the only contract that will not be updatable by the governor.


- BankRouter.sol: interface for swapping the users ETH or collateral tokens (in order to obtain DBIT/DGOV tokens for instance). inspired by the UniswapV2Router design.

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

// Similarly we will need to interface with the functions in order to define the state parameters, use BankStorage.

```

## for any issues: 

Discord channel: [here](https://discord.gg/FzBspA5Y). 
Security bugs : info@debond.org