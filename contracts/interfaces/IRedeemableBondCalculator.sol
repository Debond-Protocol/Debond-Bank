pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

interface IRedeemableBondCalculator {

    function isRedeemable(uint256 classId, uint256 nonceId) external view returns (bool);

    function getNonceFromDate(uint256 timestampDate) external view returns (uint256);
}
