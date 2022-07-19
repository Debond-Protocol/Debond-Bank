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

interface IBankRouter {

    /**
    * @notice this function should be only accessible by Bank
    */
    function updateWhenAddLiquidity(uint _amountA, uint _amountB, address _tokenA, address _tokenB) external;

    /**
    * @notice this function should be only accessible by Bank
    */
    function removeLiquidity(address _to, address tokenAddress, uint amount) external;

    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to) external;


    function getReserves(address tokenA, address tokenB) external view returns (uint _reserveA, uint _reserveB);
}
