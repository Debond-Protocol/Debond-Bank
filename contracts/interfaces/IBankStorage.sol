pragma solidity >=0.8.0;

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

interface IBankStorage {

    function updateBankAddress(address _bankAddress) external;

    function updateCanPurchase(uint classIdIn, uint classIdOut, bool _canPurchase) external;

    function updateBenchmarkInterest(uint benchmarkInterest) external;

    function pushClassIdPerTokenAddress(address tokenAddress, uint classId) external;

    function getBaseTimestamp() external view returns (uint);

    function canPurchase(uint classIdIn, uint classIdOut) external view returns (bool);

    function getClassIdsFromTokenAddress(address tokenAddress) external view returns (uint[] memory);

    function getBenchmarkInterest() external view returns (uint);

}
