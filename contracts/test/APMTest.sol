pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT


import "apm-contracts/APM.sol";

contract APMTest is APM {

    constructor(address governanceAddress) APM(governanceAddress) {}
}
