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
/// @title interface oracle
/// @dev reference: https://github.com/Debond-Protocol/Oracle/blob/main/contracts/Oracle.sol. 
/// @notice determining the price of the given ERC20 token in the denomination of token defined  in `tokenOut` (generally it will be stablecoin  USDC/USDT).
/// @dev needs to defploy  the debond-protocol/oracle contracts and setting the params of token before get it working.

interface IOracle {


/// @dev determines the approximate amount for the issuance of the amountsOut of the USD equivalent of tokens.
/// @param tokenIn is  address of token that is to be deposited as collateral for bond issuance
/// @param tokenOut is the address of the stablecoin token (USDC/USDT) in which you want to denominate.
/// @param amountIn is the amount of ERC20 tokens of address `tokenIn` you need to be denominated .
/// @return amountOut is the amount(in USD denominated stablecoin) for the given token. 
    function estimateAmountOut(
        address tokenIn,
        uint128 amountIn,
        address tokenOut,
        uint32 secondsAgo
    ) external view returns (uint amountOut);
}


