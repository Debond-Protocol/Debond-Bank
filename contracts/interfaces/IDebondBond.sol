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


interface IDebondBond {

    enum InterestRateType {FixedRate, FloatingRate}

    function bondAmountDue(address tokenAddress, InterestRateType interestRateType) external view returns (uint);

    function createNonce(uint256 classId, uint256 nonceId, uint256 maturityTime) external;

    function createClass(uint256 classId, string memory symbol, InterestRateType interestRateType, address tokenAddress, uint256 periodTimestamp) external;

    function setRedeemableBondCalculatorAddress(address _redeemableBondCalculatorAddress) external;

    function updateLastNonce(uint classId, uint nonceId, uint createdAt) external;



    function classExists(uint256 classId) external view returns (bool);

    function nonceExists(uint256 classId, uint256 nonceId) external view returns (bool);

    function bondDetails(uint256 classId, uint256 nonceId) external view returns (string memory _symbol, InterestRateType _interestRateType, address _tokenAddress, uint256 _periodTimestamp, uint256 _maturityDate, uint256 _issuanceDate, uint256 _tokenLiquidity);

    function tokenTotalSupply(address tokenAddress) external view returns (uint256);

    function tokenLiquidityFlow(address tokenAddress, uint256 nonceNumber, uint256 fromDate) external view returns (uint256);

    function tokenSupplyAtNonce(address tokenAddress, uint256 nonceId) external view returns (uint256);

    function getLastNonceCreated(uint classId) external view returns(uint nonceId, uint createdAt);

    function getClassesPerTokenAddress(address tokenAddress) external view returns (uint256[]);
}

