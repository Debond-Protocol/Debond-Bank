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
import "./interfaces/IBankStorage.sol";
import "@debond-protocol/debond-governance-contracts/utils/ExecutableOwnable.sol";


contract BankStorage is IBankStorage, ExecutableOwnable {

    address public bankAddress;


    mapping(uint256 => mapping(uint256 => bool)) _canPurchase; // can u get second input classId token from providing first input classId token
    uint public BASE_TIMESTAMP;
    uint public BENCHMARK_RATE_DECIMAL_18 = 5 * 10 ** 16;
    mapping(address => uint256[]) public classIdsPerTokenAddress;

    constructor(address _executableAddress, address _bankAddress, uint _baseTimestamp) ExecutableOwnable(_executableAddress) {
        bankAddress = _bankAddress;
        BASE_TIMESTAMP = _baseTimestamp;
    }

    modifier onlyBank {
        require(msg.sender == bankAddress, "BankData Error, only Bank Authorised");
        _;
    }

    function updateBankAddress(address _bankAddress) external onlyExecutable {
        require(_bankAddress != address(0), "BankData Error: address 0");
        bankAddress = _bankAddress;
    }

    function updateCanPurchase(uint classIdIn, uint classIdOut, bool __canPurchase) external onlyBank {
        _canPurchase[classIdIn][classIdOut] = __canPurchase;
    }

    function pushClassIdPerTokenAddress(address tokenAddress, uint classId) external onlyBank {
        classIdsPerTokenAddress[tokenAddress].push(classId);
    }

    function updateBenchmarkInterest(uint _benchmarkInterest) external onlyBank {
        BENCHMARK_RATE_DECIMAL_18 = _benchmarkInterest;
    }

    function getBaseTimestamp() external view returns (uint) {
        return BASE_TIMESTAMP;
    }

    function canPurchase(uint classIdIn, uint classIdOut) external view returns (bool) {
        return _canPurchase[classIdIn][classIdOut];
    }

    function getClassIdsFromTokenAddress(address tokenAddress) external view returns (uint[] memory) {
        return classIdsPerTokenAddress[tokenAddress];
    }

    function getBenchmarkInterest() external view returns (uint) {
        return BENCHMARK_RATE_DECIMAL_18;
    }

}
