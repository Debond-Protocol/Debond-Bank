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
import "./Types.sol";
interface IBank is Types {

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
    ) external;

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
    ) external;

 /**
    * @notice user purchasing DBIT bonds by staking ETH
    * @param _wethClassId WETH classId
    * @param _dbitClassId DBIT classId
    * @param _minRate min interest rate desired
    * @param _deadline deadline fixed for the transaction to execute
    * @param _to address to interact with (transferring tokens from, ERC3475 tokens to)
    */
    function purchaseDBITBondsByStakingETH(
        uint _wethClassId,
        uint _dbitClassId,
        uint _minRate,
        uint _deadline,
        address _to
    ) external payable;


  /**
    * @notice user purchasing DGOV bonds by staking ETH
    * @param _wethClassId WETH classId
    * @param _dgovClassId DGOV classId
    * @param _minRate min interest rate desired
    * @param _deadline deadline fixed for the transaction to execute
    * @param _to address to interact with (transferring tokens from, ERC3475 tokens to)
    */
    function purchaseDGOVBondsByStakingETH(
        uint _wethClassId,
        uint _dgovClassId,
        uint _minRate,
        uint _deadline,
        address _to
    ) external payable;


  /**
    * @notice get the actual interest rate for bond purchase
    * @param _purchaseTokenClassId token classId to purchase the bonds with
    * @param _debondTokenClassId class Id of the bond desired
    * @param _purchaseTokenAmount amount of the token to add liquidity with
    * @param _purchaseMethod either exchanging (buying) or staking
    */
    function interestRate(
        uint _purchaseTokenClassId,
        uint _debondTokenClassId,
        uint _purchaseTokenAmount,
        PurchaseMethod _purchaseMethod
    ) external;

    function updateBondManagerAddress(address _bondManagerAddress) external;

    function updateOracleAddress(address _oracleAddress) external;
}
