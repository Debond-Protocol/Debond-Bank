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
import "./interfaces/IAPM.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "debond-governance/contracts/utils/GovernanceOwnable.sol";




contract APM is IAPM, GovernanceOwnable {

    using SafeERC20 for IERC20;


    mapping(address => uint256) internal totalReserve;
    mapping(address => uint256) internal totalVlp; //Vlp : virtual liquidity pool
    //mapping(address => mapping( address => Pair) ) pairs;
    mapping(address => mapping( address => uint) ) vlp;
    address bankAddress;


    struct UpdateData { //to avoid stack too deep error
        uint amountA;
        uint amountB;
        address tokenA;
        address tokenB;
    }

    constructor(address _governanceAddress) GovernanceOwnable(_governanceAddress) {}

    modifier onlyBank() {
        require(msg.sender == bankAddress, "APM: Not Authorised");
        _;
    }

    function setBankAddress(address _bankAddress) external onlyGovernance {
        require(_bankAddress != address(0), "APM: Address 0 given for Bank!");
        bankAddress = _bankAddress;
    }

    function getReservesOneToken(
        address tokenA, //token we want to know reserve
        address tokenB //pool associated
    ) private view returns (uint reserveA) {
        uint totalVlpA = totalVlp[tokenA]; //gas saving
        if( totalVlpA != 0){
            uint vlpA = vlp[tokenA][tokenB];
            reserveA = vlpA * totalReserve[tokenA] / totalVlpA; //use mulDiv?
        }
    }
    function getReserves(
        address tokenA,
        address tokenB
    ) public override view returns (uint reserveA, uint reserveB) {
        (reserveA, reserveB) = (getReservesOneToken(tokenA, tokenB), getReservesOneToken(tokenB, tokenA) );
    }
    function updateTotalReserve(address tokenAddress, uint amount) public {
            totalReserve[tokenAddress] = totalReserve[tokenAddress] + amount;
    }
    function getVlps(address tokenA, address tokenB) public view returns (uint vlpA) {
        vlpA = vlp[tokenA][tokenB];
    }
    function updateWhenAddLiquidityOneToken(
        uint amountA,
        address tokenA,
        address tokenB) private {

        UpdateData memory updateData;
        updateData.amountA = amountA;
        updateData.tokenA = tokenA;
        updateData.tokenB = tokenB;

        uint totalReserveA = totalReserve[updateData.tokenA];//gas saving

        if(totalReserveA != 0){
            //update Vlp
            uint oldVlpA = vlp[tokenA][tokenB];  //for update total vlp
            uint totalVlpA = totalVlp[updateData.tokenA]; //save gas

            uint vlpA = amountToAddVlp(oldVlpA, updateData.amountA, totalVlpA, totalReserveA);
            vlp[tokenA][tokenB] = vlpA;

            //update total vlp
            totalVlp[updateData.tokenA] = totalVlpA - oldVlpA + vlpA;
        }
        else {
            vlp[tokenA][tokenB] = amountA;
            totalVlp[updateData.tokenA] = updateData.amountA;
        }
        totalReserve[updateData.tokenA] = totalReserveA + updateData.amountA;
    }
    function updateWhenAddLiquidity(
        uint amountA,
        uint amountB,
        address tokenA,
        address tokenB) external onlyBank { //TODO : restrict update functions for bank only, using assert/require and not modifiers
        updateWhenAddLiquidityOneToken(amountA, tokenA, tokenB);
        updateWhenAddLiquidityOneToken(amountB, tokenB, tokenA);
    }
    function updateWhenRemoveLiquidityOneToken(
        uint amountA,
        address tokenA,
        address tokenB) private {
        UpdateData memory updateData;
        updateData.amountA = amountA;
        updateData.tokenA = tokenA;
        updateData.tokenB = tokenB;

        uint totalReserveA = totalReserve[updateData.tokenA];//gas saving

        if(totalReserveA != 0){
            //update Vlp
            uint oldVlpA = vlp[tokenA][tokenB];  //for update total vlp
            uint totalVlpA = totalVlp[updateData.tokenA]; //save gas

            uint vlpA = amountToRemoveVlp(oldVlpA, updateData.amountA, totalVlpA, totalReserveA);
            vlp[tokenA][tokenB] = vlpA;

            //update total vlp
            totalVlp[updateData.tokenA] = totalVlpA - oldVlpA + vlpA;
        }
        else {
            vlp[tokenA][tokenB] = amountA;
            totalVlp[updateData.tokenA] = updateData.amountA;
        }
        totalReserve[updateData.tokenA] = totalReserveA - updateData.amountA;
    }
    function updateWhenRemoveLiquidity(
        uint amount, //amountA is the amount of tokenA removed in total pool reserve ( so not the total amount of tokenA in total pool reserve)
        address token) public {
        require(msg.sender == bankAddress, "APM: Not Authorised");

        totalReserve[token] -= amount;
    }
    function updateWhenSwap(
        uint amountAAdded, //amountA is the amount of tokenA swapped in this pool ( so not the total amount of tokenA in this pool after the swap)
        uint amountBWithdrawn,
        address tokenA,
        address tokenB) private {

        updateWhenAddLiquidityOneToken(amountAAdded, tokenA, tokenB);
        updateWhenRemoveLiquidityOneToken(amountBWithdrawn, tokenB, tokenA);
    }
    function amountToAddVlp(uint oldVlp, uint amount, uint totalVlpToken, uint totalReserveToken) public pure returns (uint newVlp) {
        newVlp = oldVlp + amount * totalVlpToken / totalReserveToken;
    }
    function amountToRemoveVlp(uint oldVlp, uint amount, uint totalVlpToken, uint totalReserveToken) public pure returns (uint newVlp) {
        newVlp = oldVlp - amount * totalVlpToken / totalReserveToken;
    }
    struct SwapData { //to avoid stack too deep error
        uint totalReserve0;
        uint totalReserve1;
        uint currentReserve0;
        uint currentReserve1;
        uint amount0In;
        uint amount1In;
    }

    uint private unlocked = 1; //reentracy
    function swap(uint amount0Out, uint amount1Out,address token0, address token1, address to) external { //no need to have both amount >0, there is always one equals to 0 (according to yu).
        require(unlocked == 1, 'APM swap: LOCKED');
        unlocked = 0;
        require( (amount0Out != 0 && amount1Out == 0)|| (amount0Out == 0 && amount1Out != 0), 'APM swap: INSUFFICIENT_OUTPUT_AMOUNT_Or_Both_output >0');
        require(to != token0 && to != token1, 'APM swap: INVALID_TO'); // do we really need this?
        (uint _reserve0, uint _reserve1) = getReserves(token0, token1); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'APM swap: INSUFFICIENT_LIQUIDITY');

        if (amount0Out == 0) IERC20(token1).transfer(to, amount1Out);
        else IERC20(token0).transfer(to, amount0Out);

        SwapData memory swapData;
        
        swapData.totalReserve0 = IERC20(token0).balanceOf(address(this));
        swapData.totalReserve1 = IERC20(token1).balanceOf(address(this));
        swapData.currentReserve0 = _reserve0 + swapData.totalReserve0 - totalReserve[token0]; // should be >= 0
        swapData.currentReserve1 = _reserve1 + swapData.totalReserve1 - totalReserve[token1];
        require(swapData.currentReserve0 * swapData.currentReserve1 >= _reserve0 * _reserve1, 'APM swap: K');

        swapData.amount0In = swapData.currentReserve0 > _reserve0 - amount0Out ? swapData.currentReserve0 - (_reserve0 - amount0Out) : 0;
        swapData.amount1In = swapData.currentReserve1 > _reserve1 - amount1Out ? swapData.currentReserve1 - (_reserve1 - amount1Out) : 0;
        require(swapData.amount0In > 0 || swapData.amount1In > 0, 'APM swap: INSUFFICIENT_INPUT_AMOUNT');
        if (amount0Out == 0) {
             updateWhenSwap(swapData.amount0In, amount1Out, token0, token1);
             }
        else {
            updateWhenSwap(swapData.amount1In, amount0Out, token1, token0);
        }
        unlocked = 1;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'APM: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'APM: INSUFFICIENT_LIQUIDITY');
        uint numerator = amountIn * reserveOut;
        uint denominator = reserveIn + amountIn;
        amountOut = numerator / denominator;
    }

    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts) {
        require(path.length >= 2, 'APM: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }


    // Bank Access
    function removeLiquidity(address _to, address tokenAddress, uint amount) external onlyBank {
        // transfer
        IERC20(tokenAddress).safeTransfer(_to, amount);
        // update getReserves
        updateWhenRemoveLiquidity(amount, tokenAddress);
    }
}

