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

import "./IERC3475.sol";
import "./IData.sol";


interface IDebondBond is IERC3475 {

    function isActive() external returns (bool);

    function bondAmountDue(address tokenAddress, IData.InterestRateType interestRateType) external view returns (uint);

    function createNonce(uint256 classId, uint256 nonceId, uint256 maturityTime) external;

    function createClass(uint256 classId, string memory symbol, IData.InterestRateType interestRateType, address tokenAddress, uint256 periodTimestamp) external;

    function classExists(uint256 classId) external view returns (bool);

    function nonceExists(uint256 classId, uint256 nonceId) external view returns (bool);

    function bondDetails(uint256 classId, uint256 nonceId) external view returns (string memory _symbol, IData.InterestRateType _interestRateType, address _tokenAddress, uint256 _periodTimestamp, uint256 _maturityDate, uint256 _issuanceDate, uint256 _tokenLiquidity);

    function totalActiveSupply(address tokenAddress) external view returns (uint256);


}

