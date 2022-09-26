pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT


import "@debond-protocol/debond-apm-contracts/APM.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract APMTest is APM {

    constructor(address governanceAddress, address bankAddress, address stakingDebondContract) APM(governanceAddress, bankAddress, stakingDebondContract) {}
} 
