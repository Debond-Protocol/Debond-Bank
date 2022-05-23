pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

interface MaturityBondCalculator {

    function floatMaturityBond(uint256 class, uint256 nonce) external returns (uint256);
}
