# Debond-Bank:

This branch of contracts acts as the  main interface for the users to issue/ redeem the bonds and manage the liquidity provided by the lenders along with whitelisting the different bond issuers. 

## Users (dependencies):

- Bond issue (app users) to buy/stake bonds along with bond issuer. 
- Governance contract for defining the classes that are to be added/removed, doing transfers from APM to given whitelisted user allowed by the proposal is passed. 

## Contract description: 

1. Bank.sol: this is the prime contract for providing interface functions for the frontend and governance in order to issue bonds and submit the collateral. there are two ways to invest and get bonds: 
    1. either you buy and get the redemption in the underlying ERC20 bonds
    2. Or you will try to fetch the bonds by using DBIT tokens.

```solidity
  /**
    * @notice return if classIdIn can purchase classIdOut
    * @param _classIdIn the classId to purchase with
    * @param _classIdOut the classId to purchase
    * @return true if it can purchased, false if not
    */
    function canPurchase(
        uint _classIdIn,
        uint _classIdOut
    ) public view returns (bool);

    /**
    * @notice user purchasing DBIT bonds by staking his chosen tokens
    * @param _purchaseClassId the classId of the token to purchase with
    * @param _dbitClassId DBIT classId
    * @param _purchaseTokenAmount amount of the user's token
    * @param _minRate min interest rate desired
    * @param _deadline deadline fixed for the transaction to execute
    * @param _to address to interact with (transferring ERC20 from, ERC3475 tokens to)
    */
    function purchaseDBITBondsByStakingTokens(
        uint _purchaseClassId,
        uint _dbitClassId,
        uint _purchaseTokenAmount,
        uint _minRate,
        uint _deadline,
        address _to
    ) external; 


    /**
    * @notice user purchasing DGOV bonds by staking his DBIT tokens
    * @param _dbitClassId DBIT classId
    * @param _dgovClassId DGOV classId
    * @param _dbitTokenAmount user's DBIT amount
    * @param _minRate min interest rate desired
    * @param _deadline deadline fixed for the transaction to execute
    * @param _to address to interact with (transferring tokens from, ERC3475 tokens to)
    */
    function purchaseDGOVBondsByStakingDBIT(
        uint _dbitClassId,
        uint _dgovClassId,
        uint _dbitTokenAmount,
        uint _minRate,
        uint _deadline,
        address _to
    ) external;

 /**
    * @notice user purchasing DGOV bonds by staking his chosen tokens
    * @param _purchaseClassId the classId of the token to stake
    * @param _dgovClassId DGOV classId
    * @param _purchaseTokenAmount amount of the user's token
    * @param _minRate min interest rate desired
    * @param _deadline deadline fixed for the transaction to execute
    * @param _to address to interact with (transferring tokens from, ERC3475 tokens to)
    */
    function purchaseDGOVBondsByStakingTokens(
        uint _purchaseClassId,
        uint _dgovClassId,
        uint _purchaseTokenAmount,
        uint _minRate,
        uint _deadline,
        address _to
    ) external;
 /**
    * @notice user purchasing DBIT bonds by exchanging his chosen tokens
    * @param _purchaseClassId the classId of the token to purchase with
    * @param _dbitClassId DBIT classId
    * @param _purchaseTokenAmount amount of the user's token
    * @param _minRate min interest rate desired
    * @param _deadline deadline fixed for the transaction to execute
    * @param _to address to interact with (transferring tokens from, ERC3475 tokens to)
    */
    function buyDBITBondsWithTokens(//else is not eth not dbit not dgov
        uint _purchaseClassId,
        uint _dbitClassId,
        uint _purchaseTokenAmount,
        uint _minRate,
        uint _deadline,
        address _to
    ) external;

  /**
    * @notice user purchasing DGOV bonds by exchanging his DBIT tokens
    * @param _dbitClassId DBIT classId
    * @param _dgovClassId DGOV classId
    * @param _dbitAmount amount of the user's DBIT
    * @param _minRate min interest rate desired
    * @param _deadline deadline fixed for the transaction to execute
    * @param _to address to interact with (transferring tokens from, ERC3475 tokens to)
    */
    function buyDGOVBondsWithDBIT(
        uint _dbitClassId,
        uint _dgovClassId,
        uint _dbitAmount,
        uint _minRate,
        uint _deadline,
        address _to
    ) external ;

/**
    * @notice user purchasing DGOV bonds by exchanging his tokens
    * @param _purchaseClassId the classId of the token to purchase with
    * @param _dgovClassId DGOV classId
    * @param _purchaseTokenAmount amount of the user's DBIT
    * @param _minRate min interest rate desired
    * @param _deadline deadline fixed for the transaction to execute
    * @param _to address to interact with (transferring tokens from, ERC3475 tokens to)
    */
    function buyDGOVBondsWithTokens(
        uint _purchaseClassId,
        uint _dgovClassId,
        uint _purchaseTokenAmount,
        uint _minRate,
        uint _deadline,
        address _to
    ) external 



```
2. BankBondManager.sol: this is the wrapper contract that manages the interface with [Debond-ERC3475]() contract. it defines the additional logic to issue and do operations of bonds on batch. 

```solidity

pragma solidity ^0.8.0;

// SPDX-License-Identifier: apache 2.0
/*
    Copyright 2022 Debond Protocol <info@debond.org>
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

import "erc3475/IERC3475.sol";

interface IBankBondManager {
    enum InterestRateType {FixedRate, FloatingRate}

    // functions for setting the contract parameters.

    function setBankDataAddress(address _bankDataAddress) external;
    function setDebondBondAddress(address _debondBondAddress) external;
    function setBankAddress(address _bankAddress) external;
    // function to determine whether the specific bond pair from any nonce of (ClassIdIn, ClassIdOut in the same order) are whitelisted by the governance.

    function updateCanPurchase(uint classIdIn, uint classIdOut, bool _canPurchase) external;
    // set the minimum interest rate of returns on DBIT floating bond types. 

    function setBenchmarkInterest(uint _benchmarkInterest) external;
        
    // define the metadata of the new class of bonds is initialized.
    function createClassMetadatas(uint256[] memory metadataIds, IERC3475.Metadata[] memory metadatas) external;
    // defining the new class of bond for giving type of ERC20 represented by 'tokenAddress' and parameters.
    function createClass(uint256 classId, string memory symbol, address tokenAddress, InterestRateType interestRateType, uint256 period) external;

    /**
    Allows the issuance of bonds for the classId's that are whitelisted. 
    */


function issueBonds(address to, uint256[] memory classIds, uint256[] memory amounts) external;


    function getETA(uint256 classId, uint256 nonceId) external view returns (uint256);
    function classValues(uint256 classId) external view returns (address _tokenAddress, InterestRateType _interestRateType, uint256 _periodTimestamp);
    function nonceValues(uint256 classId, uint256 nonceId) external view returns (uint256 _issuanceDate, uint256 _maturityDate);
    function getInterestRate(uint classId, uint amount) external view returns (uint rate);
}

```

3. BankData: this defines the details such as parameters from the bank interface.


```solidity


import "./IBankBondManager.sol";

interface IBankData {

    function setBankAddress(address _bankAddress) external;

    function updateCanPurchase(uint classIdIn, uint classIdOut, bool _canPurchase) external;

    
    function pushClassIdPerTokenAddress(address tokenAddress, uint classId) external;

    // determining the Benchmark address (only called by governance executable address).
    function setBenchmarkInterest(uint benchmarkInterest) external;


    // getter functions for bank parameters.
    function getBaseTimestamp() external view returns (uint);

    function canPurchase(uint classIdIn, uint classIdOut) external view returns (bool);

    function getClassIdsFromTokenAddress(address tokenAddress) external view returns (uint[] memory);
   
 function getBenchmarkInterest() external view returns (uint);

}

  
```

## Workflow:


1. After the debond-bank deployment, we need to define the class of bonds and collaterals that will be accepted by our application. 

2. initially the user selects the type of bond (buy/staking) the bonds, which in turn interacts the bondRouter to transfer the liquidity from the user to APM, and in return issuing the bond.

3. Then for the redemption, user can call the `redeemLiquidity` which will in turn will check the redemption condition of the bonds. and if its valid, based on whether bond is bought/staked by the other ERC20 token or by DBIT respectively.


- [bank contract workflow](./bank_architecture.svg).

## Security information: 

1. Functions that includes setting up the purchasable class and standards, we need to be only callable by the governance.

## installation and configuration: 

```bash
> npm install --save-dev @debond/bank
```