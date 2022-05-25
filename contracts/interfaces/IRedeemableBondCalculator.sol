pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

interface IRedeemableBondCalculator {

    function isRedeemable(uint256 class, uint256 nonce) external returns (bool);
}
