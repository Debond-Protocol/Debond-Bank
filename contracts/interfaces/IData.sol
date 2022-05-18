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

interface IData {

    enum InterestRateType {FixedRate, FloatingRate}

    function addClass(uint classId, string memory symbol, InterestRateType interestRateType, address tokenAddress, uint periodTimestamp) external;

    function updatePurchasableClass(uint debondClassId, uint purchaseClassId, bool purchasable) external;

    function canPurchase(uint debondClassId , uint purchaseClassId) external view returns (bool);

    function getClassFromId(uint classId) external view returns(string memory symbol, InterestRateType interestRateType, address tokenAddress, uint periodTimestamp);

    function getLastNonceCreated(uint classId) external view returns(uint nonceId, uint createdAt);

    function updateLastNonce(uint classId, uint nonceId, uint createdAt) external;
}
