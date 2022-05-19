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

interface IAPM {

    function getReserves(address tokenA, address tokenB) external view returns (uint reserveA, uint reserveB);

    function updateWhenAddLiquidity(
        uint _amountA, 
        uint _amountB,
        address _tokenA,
        address _tokenB) external;

    function updateWhenRemoveLiquidity(
        uint amount, 
        address token) external;

    function swap(uint amount0Out, uint amount1Out,address token0, address token1, address to) external;

    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);

    function updateTotalReserve(address tokenAddress, uint amount) external;

    function removeLiquidity(address _to, address tokenAddress, uint amount) external;
}
