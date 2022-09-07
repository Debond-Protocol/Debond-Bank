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
  enum InterestRateType {
    FixedRate,
    FloatingRate
  }

  function setBankDataAddress(address _bankDataAddress) external;

  function setDebondBondAddress(address _debondBondAddress) external;

  function setBankAddress(address _bankAddress) external;

  function updateCanPurchase(
    uint256 classIdIn,
    uint256 classIdOut,
    bool _canPurchase
  ) external;

  function setBenchmarkInterest(uint256 _benchmarkInterest) external;

  function createClassMetadatas(uint256[] memory metadataIds, IERC3475.Metadata[] memory metadatas) external;

  function createClass(
    uint256 classId,
    string memory symbol,
    address tokenAddress,
    InterestRateType interestRateType,
    uint256 period
  ) external;

  function issueBonds(
    address to,
    uint256[] memory classIds,
    uint256[] memory amounts
  ) external;

  function redeemBonds(
    address from,
    uint256[] memory classIds,
    uint256[] memory nonceIds,
    uint256[] memory amounts
  ) external;

  function getETA(uint256 classId, uint256 nonceId) external view returns (uint256);

  function classValues(uint256 classId)
    external
    view
    returns (
      address _tokenAddress,
      InterestRateType _interestRateType,
      uint256 _periodTimestamp
    );

  function getClasses() external view returns (uint256[] memory);

  function getInterestRate(uint256 classId, uint256 amount) external view returns (uint256 rate);
}
