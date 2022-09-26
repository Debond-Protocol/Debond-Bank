pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT


import "@debond-protocol/debond-apm-contracts/APM.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract APMTest is APM {

    constructor(address governanceAddress, address bankAddress) APM(governanceAddress, bankAddress) {}

    /*function removeLiquidityInsidePool(address _to, address _tokenA, address DBITAddress, uint _amountDbitToBurn) public {
        //IERC20(DBITAddress).mint();
    }*/
} 
