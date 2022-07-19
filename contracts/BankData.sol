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

import "./BankBondManager.sol";
import "./interfaces/IBankData.sol";
import "@debond-protocol/debond-governance-contracts/utils/GovernanceOwnable.sol";


contract BankData is IBankData, GovernanceOwnable {

    address bankAddress;


    mapping(uint256 => mapping(uint256 => bool)) _canPurchase; // can u get second input classId token from providing first input classId token
    uint public BASE_TIMESTAMP;
    uint public BENCHMARK_RATE_DECIMAL_18 = 5 * 10 ** 16;
    uint[] public classes;

    mapping(address => mapping(BankBondManager.InterestRateType => uint256)) public tokenRateTypeTotalSupply; // needed for interest rate calculation also
    mapping(address => mapping(uint256 => uint256)) public tokenTotalSupplyAtNonce;
    mapping(address => uint256[]) public classIdsPerTokenAddress;

    constructor(address _governanceAddress, address _bankAddress, uint _baseTimestamp) GovernanceOwnable(_governanceAddress) {
        bankAddress = _bankAddress;
        BASE_TIMESTAMP = _baseTimestamp;
    }

    modifier onlyBank {
        require(msg.sender == bankAddress, "BankData Error, only Bank Authorised");
        _;
    }

    function setBankAddress(address _bankAddress) external onlyGovernance {
        require(_bankAddress != address(0), "BankData Error: address 0");
        bankAddress = _bankAddress;
    }

    function updateCanPurchase(uint classIdIn, uint classIdOut, bool __canPurchase) external onlyBank {
        _canPurchase[classIdIn][classIdOut] = __canPurchase;
    }

    function setTokenInterestRateSupply(address tokenAddress, BankBondManager.InterestRateType interestRateType, uint amount) external onlyBank {
        tokenRateTypeTotalSupply[tokenAddress][interestRateType] += amount;
    }

    function setTokenTotalSupplyAtNonce(address tokenAddress, uint nonceId, uint amount) external onlyBank {
        tokenTotalSupplyAtNonce[tokenAddress][nonceId] = amount;
    }

    function pushClassIdPerToken(address tokenAddress, uint classId) external onlyBank {
        classIdsPerTokenAddress[tokenAddress].push(classId);
    }

    function addNewClassId(uint classId) external onlyBank {
        classes.push(classId);
    }

    function setBenchmarkInterest(uint _benchmarkInterest) external onlyBank {
        BENCHMARK_RATE_DECIMAL_18 = _benchmarkInterest;
    }

    function getBaseTimestamp() external view returns (uint) {
        return BASE_TIMESTAMP;
    }

    function canPurchase(uint classIdIn, uint classIdOut) external view returns (bool) {
        return _canPurchase[classIdIn][classIdOut];
    }

    function getClasses() external view returns (uint[] memory) {
        return classes;
    }

    function getTokenInterestRateSupply(address tokenAddress, BankBondManager.InterestRateType interestRateType) external view returns (uint) {
        return tokenRateTypeTotalSupply[tokenAddress][interestRateType];
    }

    function getClassIdsFromTokenAddress(address tokenAddress) external view returns (uint[] memory) {
        return classIdsPerTokenAddress[tokenAddress];
    }

    function getTokenTotalSupplyAtNonce(address tokenAddress, uint nonceId) external view returns (uint) {
        return tokenTotalSupplyAtNonce[tokenAddress][nonceId];
    }

    function getBenchmarkInterest() external view returns (uint) {
        return BENCHMARK_RATE_DECIMAL_18;
    }

}
