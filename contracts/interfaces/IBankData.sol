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

import "./IBankBondManager.sol";

interface IBankData {
  function setBankAddress(address _bankAddress) external;

  function updateCanPurchase(
    uint256 classIdIn,
    uint256 classIdOut,
    bool _canPurchase
  ) external;

  function setTokenInterestRateSupply(
    address tokenAddress,
    IBankBondManager.InterestRateType,
    uint256 amount
  ) external;

  function setTokenTotalSupplyAtNonce(
    address tokenAddress,
    uint256 nonceId,
    uint256 amount
  ) external;

  function pushClassIdPerTokenAddress(address tokenAddress, uint256 classId) external;

  function addNewClassId(uint256 classId) external;

  function setBenchmarkInterest(uint256 benchmarkInterest) external;

  function getBaseTimestamp() external view returns (uint256);

  function canPurchase(uint256 classIdIn, uint256 classIdOut) external view returns (bool);

  function getClasses() external view returns (uint256[] memory);

  function getTokenInterestRateSupply(address tokenAddress, IBankBondManager.InterestRateType) external view returns (uint256);

  function getClassIdsFromTokenAddress(address tokenAddress) external view returns (uint256[] memory);

  function getTokenTotalSupplyAtNonce(address tokenAddress, uint256 nonceId) external view returns (uint256);

  function getBenchmarkInterest() external view returns (uint256);
}
