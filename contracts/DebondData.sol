pragma solidity ^0.8.0;

// SPDX-License-Identifier: apache 2.0
/*
    Copyright 2020 Sigmoid Foundation <info@SGM.finance>
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


import './interfaces/IData.sol';


contract DebondData is IData {
    uint public constant SIX_M_PERIOD = 0; // 1 min period for tests

    struct Class {
        uint id;
        bool exists;
        string symbol;
        InterestRateType interestRateType;
        address tokenAddress;
        uint periodTimestamp;
        uint lastNonceIdCreated;
        uint lastNonceIdCreatedTimestamp;
    }

    mapping(uint => Class) classes; // mapping from classId to class
    // data to be exclusively for the front end (for now)
    mapping(uint => uint[]) public purchasableClassesCollection;//from a debond class given return purchasable class ids associated
    mapping(uint => mapping(uint => bool)) public purchasableClasses; //from a debond class given return purchasable class ids associated
    uint[] debondClasses; // return collection of class that client can purchase (debond classes)

    constructor(
        address DBIT,
        address USDC,
        address USDT,
        address DAI
    ) {

        addClass(0, "D/BIT", InterestRateType.FixedRate, DBIT, SIX_M_PERIOD);
        addClass(1, "USDC", InterestRateType.FixedRate, USDC, SIX_M_PERIOD);
        addClass(2, "USDT", InterestRateType.FixedRate, USDT, SIX_M_PERIOD);
        addClass(3, "DAI", InterestRateType.FixedRate, DAI, SIX_M_PERIOD);

        addClass(4, "D/BIT", InterestRateType.FloatingRate, DBIT, SIX_M_PERIOD);
        addClass(5, "USDC", InterestRateType.FloatingRate, USDC, SIX_M_PERIOD);
        addClass(6, "USDT", InterestRateType.FloatingRate, USDT, SIX_M_PERIOD);
        addClass(7, "DAI", InterestRateType.FloatingRate, DAI, SIX_M_PERIOD);

        debondClasses.push(0);
        debondClasses.push(4);

        assignClass(0, 1);
        assignClass(0, 2);
        assignClass(0, 3);
        assignClass(4, 5);
        assignClass(4, 6);
        assignClass(4, 7);

    }

    /**
     * @notice this method should only be called by the governance contract TODO Only Governance
     */
    function addClass(uint classId, string memory symbol, InterestRateType interestRateType, address tokenAddress, uint periodTimestamp) public override {
        Class storage class = classes[classId];
        require(!class.exists, "DebondData: cannot add an existing classId");
        class.id = classId;
        class.exists = true;
        class.symbol = symbol;
        class.interestRateType = interestRateType;
        class.tokenAddress = tokenAddress;
        class.periodTimestamp = periodTimestamp;

        // should maybe add an event
    }

    // TODO Only Governance
    function updatePurchasableClass (uint debondClassId, uint purchaseClassId, bool purchasable) external override {
        purchasableClasses[debondClassId][purchaseClassId] = purchasable;
    }

    function canPurchase(uint debondClassId, uint purchaseClassId) public view returns (bool) {
        return purchasableClasses[debondClassId][purchaseClassId];
    }

    function getClassFromId(
        uint classId
    ) external view returns(string memory symbol, InterestRateType interestRateType, address tokenAddress, uint periodTimestamp) {
        Class storage class = classes[classId];
        symbol = class.symbol;
        periodTimestamp = class.periodTimestamp;
        tokenAddress = class.tokenAddress;
        interestRateType = class.interestRateType;
        return (symbol, interestRateType, tokenAddress, periodTimestamp);
    }

    // TODO Only Bank
    function getLastNonceCreated(uint classId) external view returns(uint nonceId, uint createdAt) {
        Class storage class = classes[classId];
        require(class.exists, "Debond Data: class id given not found");
        nonceId = class.lastNonceIdCreated;
        createdAt = class.lastNonceIdCreatedTimestamp;
        return (nonceId, createdAt);
    }

    // TODO Only Bank
    function updateLastNonce(uint classId, uint nonceId, uint createdAt) external {
        Class storage class = classes[classId];
        require(class.exists, "Debond Data: class id given not found");
        class.lastNonceIdCreated = nonceId;
        class.lastNonceIdCreatedTimestamp = createdAt;
    }

    function allDebondClasses() external view returns (uint[] memory) {
        return debondClasses;
    }

    function getPurchasableClasses(uint debondClassId) external view returns (uint[] memory) {
        return purchasableClassesCollection[debondClassId];
    }

    function isPurchasableClass(uint debondClassId, uint purchasableQueryClassId) external view returns (bool) {
        return purchasableClasses[debondClassId][purchasableQueryClassId];
    }

    function assignClass(uint debondClass, uint purchaseClass) private {
        purchasableClassesCollection[debondClass].push(purchaseClass);
        purchasableClasses[debondClass][purchaseClass] = true;
    }





}
