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

import "prb-math/contracts/PRBMathSD59x18.sol";

library DebondMath {

    using PRBMathSD59x18 for uint256;
    uint256 constant private NUMBER_OF_SECONDS_IN_YEAR = 31536000;
    
    /**
    * @dev calculate the sigmoid function for given params
    * @param _x the sigmoid argument (input parameter)
    * @param _c the sigmoid parameter c (see the white papaer)
    * @param result the output of sigmoid function for given _x and _c
    */
    function sigmoid(uint256 _x , uint256 _c) public pure returns (uint256 result) {
        if(_x == 0) {
            result = 0;
        }
        else if(_x == 1) {
            result = 1;
        }
        else{
            int256 temp1;
            int256 temp2;

            assembly{
                temp1 := sub(_c,1000000000000000000)
                temp2 := sub(_x,1000000000000000000)
            }

            temp1 = PRBMathSD59x18.mul(temp1, int256(_x));
            temp2 = PRBMathSD59x18.mul(temp2, int256(_c));

            temp1 = PRBMathSD59x18.inv(temp1);
            temp2 = PRBMathSD59x18.inv(temp2);

            temp1 = PRBMathSD59x18.exp2(temp1); //because temp1 = exp2(mul(temp2,log2(2)), with log2(2)=1
            temp2 = PRBMathSD59x18.exp2(temp2);

            result = uint256(PRBMathSD59x18.div(temp1, temp1 + temp2));
        }
    }

    function inv(uint256 x) public pure returns (uint256 result) {
        return uint256(PRBMathSD59x18.inv(int256(x)));
    }

    function div(uint256 x, uint256 y) public pure returns (uint256 result) {
        return uint256(PRBMathSD59x18.div(int256(x), int256(y)));
    }

    function mul(uint256 x, uint256 y) public pure returns (uint256 result) {
        return uint256(PRBMathSD59x18.mul(int256(x), int256(y)));
    }
    function pow(uint256 x, uint256 y) public pure returns (uint256 result) {
        return uint256(PRBMathSD59x18.pow(int256(x), int256(y)));
    }

    function log2(uint256 x) public pure returns (uint256 result) {
        return uint256(PRBMathSD59x18.log2(int256(x)));
    }

    /**
    * @dev calculate the floatting interest rate
    * @param _fixRateBond fixed rate bond
    * @param _floatingRateBond rate bond
    * @param _benchmarkIR benchmark interest rate
    * @param floatingRate floatting rate interest rate
    */
    function floatingInterestRate(
        uint256 _fixRateBond,
        uint256 _floatingRateBond,
        uint256 _benchmarkIR
    ) public pure returns(uint256 floatingRate) {
        uint256 x = (_fixRateBond * 1 ether) / (_fixRateBond + _floatingRateBond);
        uint256 c = 200000000000000000; // c = 1/5
        uint256 sig = sigmoid(x, c);

        floatingRate = 2 * _benchmarkIR * sig / 1 ether;
    }

    /**
    * @dev calculate the fixed interest rate
    * @param _fixRateBond fixed rate bond
    * @param _floatingRateBond rate bond
    * @param _benchmarkIR benchmark interest rate
    * @param fixedRate fixed rate interest rate
    */
    function fixedInterestRate(
        uint256 _fixRateBond,
        uint256 _floatingRateBond,
        uint256 _benchmarkIR
    ) external pure returns(uint256 fixedRate) {
        uint256 floatingRate = floatingInterestRate(
            _fixRateBond,
            _floatingRateBond,
            _benchmarkIR
        );

        return 2 * _benchmarkIR - floatingRate;
    }

    /**
    * @dev calculate the interest earned in DBIT
    * @param _duration the satking duration
    * @param _interestRate Annual percentage rate (APR)
    * @param interest interest earned for the given duration
    */
    function calculateInterestRate(
        uint256 _duration,
        uint256 _interestRate
    ) public pure returns(uint256 interest) {
        interest = _interestRate * _duration / NUMBER_OF_SECONDS_IN_YEAR;
    }

    /**
    * @dev Estimate how much Interest the user has gained since he staked dGoV
    * @param _amount the amount of DBIT staked
    * @param _duration staking duration to estimate interest from
    * @param interest the estimated interest earned so far
    */
    function estimateInterestEarned(
        uint256 _amount,
        uint256 _duration,
        uint256 _interestRate
    ) external pure returns(uint256 interest) {
        uint256 rate = calculateInterestRate(_duration, _interestRate);
        interest = _amount * rate / 1 ether;
    }

    /**
    * @dev calculate the average liquidity flow
    * @param _sumOfLiquidityFlow total liquidity flow for a given nonce
    * @param _benchmarkIR benchmark interest rate
    * @param averageFlow average liquidity flow
    */
    function lastMonthAverageLiquidityFlow(
        uint256 _sumOfLiquidityFlow,
        uint256 _benchmarkIR
    ) public pure returns(uint256 averageFlow) {
        averageFlow = _sumOfLiquidityFlow * (1 ether + _benchmarkIR) / 1 ether;
    }

    function floatingETA(
        uint256 _maturityTime,
        uint256 _sumOfLiquidityFlow,
        uint256 _benchmarkIR,
        uint256 _sumOfLiquidityOfLastNonce,
        uint256 _nonceDuration,
        uint256 _lastMonthLiquidityFlow
    ) external pure returns(uint256 redemptionTime) {
        int256 deficit = _deficitOfBond(
            _sumOfLiquidityFlow,
            _benchmarkIR,
            _sumOfLiquidityOfLastNonce
        );

        int256 sumOverLastMonth = PRBMathSD59x18.div(deficit, int256(_lastMonthLiquidityFlow)) * int256(_nonceDuration);

        redemptionTime = uint256(int256(_maturityTime * 1 ether) + sumOverLastMonth) / 1 ether;
    }

    /**
    * @dev calculate the deficit of a bond
    * @param _sumOfLiquidityFlow total liquidity flow for a given nonce
    * @param _benchmarkIR benchmark interest rate
    * @param _sumOfLiquidityOfLastNonce sum of liquidity flow for last month
    * @param deficit bond deficit
    */
    function _deficitOfBond(
        uint256 _sumOfLiquidityFlow,
        uint256 _benchmarkIR,
        uint256 _sumOfLiquidityOfLastNonce
    ) internal pure returns(int256 deficit) {
        deficit =
            (int256(_sumOfLiquidityFlow) * (1 ether + int256(_benchmarkIR))) /
            1 ether -
            int256(_sumOfLiquidityOfLastNonce);
    }

    /**
    * @dev check if in crisis or not
    * @param _sumOfLiquidityFlow total liquidity flow for a given nonce
    * @param _benchmarkIR benchmark interest rate
    * @param _sumOfLiquidityOfLastNonce sum of liquidity flow for last month
    * @param crisis true if in crisis, false otherwise
    */
    function inCrisis(
        uint256 _sumOfLiquidityFlow,
        uint256 _benchmarkIR,
        uint256 _sumOfLiquidityOfLastNonce
    ) public pure returns(bool crisis) {
        int256 deficit = _deficitOfBond(
            _sumOfLiquidityFlow,
            _benchmarkIR,
            _sumOfLiquidityOfLastNonce
        );

        crisis = deficit > 0;
    }
}
