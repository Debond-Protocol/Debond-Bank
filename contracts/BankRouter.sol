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

import "@debond-protocol/debond-apm-contracts/interfaces/IAPM.sol";
import "@debond-protocol/debond-governance-contracts/utils/GovernanceOwnable.sol";
import "@debond-protocol/debond-oracle-contracts/interfaces/IOracle.sol";
import "@debond-protocol/debond-token-contracts/interfaces/IDebondToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IWETH.sol";

import "./libraries/DebondMath.sol";





abstract contract BankRouter {

    using DebondMath for uint256;
    using SafeERC20 for IERC20;



    address apmAddress;
    address DBITAddress;
    address DGOVAddress;
    address immutable USDCAddress;
    address immutable WETHAddress;
    address oracleAddress;

    constructor(
        address _apmAddress,
        address _DBITAddress,
        address _DGOVAddress,
        address _USDCAddress,
        address _WETHAddress,
        address _oracleAddress
    ) {
        apmAddress = _apmAddress;
        DBITAddress = _DBITAddress;
        DGOVAddress = _DGOVAddress;
        USDCAddress = _USDCAddress;
        WETHAddress = _WETHAddress;
        oracleAddress = _oracleAddress;
    }

    function _setApmAddress(address _apmAddress) internal {
        apmAddress = _apmAddress;
    }

    function updateWhenAddLiquidity(
        uint _amountA,
        uint _amountB,
        address _tokenA,
        address _tokenB) internal {
        IAPM(apmAddress).updateWhenAddLiquidity(_amountA, _amountB, _tokenA, _tokenB);
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to
    ) external {
        uint[] memory amounts = IAPM(apmAddress).getAmountsOut(amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');

        IERC20(path[0]).transferFrom(msg.sender, apmAddress, amounts[0]);
        _swap(amounts, path, to);
    }

    function swapExactTokensForEth(
        uint amountIn,
        uint amountEthMin,
        address[] calldata path,
        address to
    ) external {
        require(path[path.length - 1] == WETHAddress, 'APMRouter: INVALID_PATH');
        uint[] memory amounts = IAPM(apmAddress).getAmountsOut(amountIn, path);
        uint lastAmount = amounts[amounts.length - 1];
        require(lastAmount >= amountEthMin, 'APMRouter: INSUFFICIENT_OUTPUT_AMOUNT');

        IERC20(path[0]).transferFrom(msg.sender, apmAddress, amounts[0]);
        _swap(amounts, path, address(this));
        IWETH(WETHAddress).withdraw(lastAmount);
        payable(to).transfer(lastAmount);
    }
    function swapExactEthForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to
    ) external payable {
        require(path[0] == WETHAddress, 'APMRouter: INVALID_PATH');
        uint amountIn = msg.value;
        uint[] memory amounts = IAPM(apmAddress).getAmountsOut(amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'APMRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETHAddress).deposit{value : amountIn}();
        assert(IWETH(WETHAddress).transfer(apmAddress, amountIn));
        _swap(amounts, path, to);
    }

    function removeLiquidity(address _to, address tokenAddress, uint amount) internal {
        IAPM(apmAddress).removeLiquidity(_to, tokenAddress, amount);
    }

    function removeWETHLiquidity(uint amount) internal {
        IAPM(apmAddress).removeLiquidity(address(this), WETHAddress, amount);
        IWETH(WETHAddress).withdraw(amount);
        payable(msg.sender).transfer(amount);
    }

    function addLiquidityDbitPair(address _from, address tokenAddress, uint amount) internal {
        IERC20(tokenAddress).safeTransferFrom(_from, apmAddress, amount);

        uint amountDBITToMint = convertToDbit(amount, tokenAddress);
        IDebondToken(DBITAddress).mintCollateralisedSupply(apmAddress, amountDBITToMint);

        updateWhenAddLiquidity(amount, amountDBITToMint, tokenAddress, DBITAddress);
    }

    function addLiquidityDgovPair(address _from, address tokenAddress, uint amount) internal {
        IERC20(tokenAddress).transferFrom(_from, apmAddress, amount);

        uint amountDBITToMint = tokenAddress == DBITAddress ? amount : convertToDbit(uint128(amount), tokenAddress);
        uint amountDGOVToMint = convertDbitToDgov(amountDBITToMint);

        IDebondToken(DBITAddress).mintCollateralisedSupply(apmAddress, amountDGOVToMint);
        IDebondToken(DBITAddress).mintCollateralisedSupply(apmAddress, 2 * amountDBITToMint);

        updateWhenAddLiquidity(amount, amountDBITToMint, tokenAddress, DBITAddress);
        updateWhenAddLiquidity(amountDBITToMint, amountDGOVToMint, DBITAddress, DGOVAddress);
    }

    function addLiquidityDbitETHPair(uint amount) internal {
        IWETH(WETHAddress).transfer(apmAddress, amount);

        uint amountDBITToMint = convertToDbit(amount, WETHAddress);
        IDebondToken(DBITAddress).mintCollateralisedSupply(apmAddress, amountDBITToMint);

        updateWhenAddLiquidity(amount, amountDBITToMint, WETHAddress, DBITAddress);
    }

    function addLiquidityDgovETHPair(uint amount) internal {
        IWETH(WETHAddress).transfer(apmAddress, amount);

        uint amountDBITToMint = convertToDbit(uint128(amount), WETHAddress);
        uint amountDGOVToMint = convertDbitToDgov(amountDBITToMint);

        IDebondToken(DBITAddress).mintCollateralisedSupply(apmAddress, amountDGOVToMint);
        IDebondToken(DBITAddress).mintCollateralisedSupply(apmAddress, 2 * amountDBITToMint);

        updateWhenAddLiquidity(amount, amountDBITToMint, WETHAddress, DBITAddress);
        updateWhenAddLiquidity(amountDBITToMint, amountDGOVToMint, DBITAddress, DGOVAddress);
    }

    function addLiquidityDbitDgov(address _from, uint DBITamount) internal {
        IERC20(DBITAddress).transferFrom(_from, apmAddress, DBITamount);

        uint amountDGOVToMint = convertDbitToDgov(DBITamount);
        IDebondToken(DGOVAddress).mintCollateralisedSupply(apmAddress, amountDGOVToMint);
        updateWhenAddLiquidity(DBITamount, amountDGOVToMint, DBITAddress, DGOVAddress);

    }

    function getReserves(address tokenA, address tokenB) external view returns (uint _reserveA, uint _reserveB) {
        (_reserveA, _reserveB) = IAPM(apmAddress).getReserves(tokenA, tokenB);
    }

    function _swap(uint[] memory amounts, address[] memory path, address to) private {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = (uint(0), amountOut);
            IAPM(apmAddress).swap(
                amount0Out, amount1Out, input, output, to
            );
        }
    }

    /**
    * @dev given the amount of tokens and the token address, returns the amout of DBIT to mint.
    * @param _amountToken the amount of token
    * @param _tokenAddress the address of token
    * @return amountDBIT the amount of DBIT to mint
    */
    function convertToDbit(uint256 _amountToken, address _tokenAddress) internal view returns (uint256 amountDBIT) {

        uint256 tokenToUsd = _convertTokenToUSDC(_amountToken, _tokenAddress);
        uint256 rate = _cdpUsdToDBIT();

        amountDBIT = tokenToUsd.mul(rate);
        //1e6 x 1e12 x 1e18 = 1e18
    }

    /**
    * @dev gives the amount of DBIT which should be minted for 1$ worth of input
    * @return amountDBIT the amount of DBIT which should be minted
    */
    function _cdpUsdToDBIT() private view returns (uint256 amountDBIT) {
        amountDBIT = 1 ether;
        uint256 _sCollateralised = IDebondToken(DBITAddress).getTotalCollateralisedSupply();

        if (_sCollateralised >= 1000 ether) {
            amountDBIT = 1.05 ether;
            uint256 logCollateral = (_sCollateralised / 1000).log2();
            amountDBIT = amountDBIT.pow(logCollateral);
        }
    }

    /**
    * @dev convert a given amount of token to USD  (the pair needs to exist on uniswap)
    * @param _amountToken the amount of token we want to convert
    * @param _tokenAddress the address of token we want to convert
    * @return amountUsd the corresponding amount of usd
    */
    function _convertTokenToUSDC(uint256 _amountToken, address _tokenAddress) private view returns (uint256 amountUsd) {

        if (_tokenAddress == USDCAddress) {
            amountUsd = _amountToken;
        }
        else {
            amountUsd = IOracle(oracleAddress).estimateAmountOut(_tokenAddress, uint128(_amountToken), USDCAddress, 60) * 1e12;
        }
    }

    /**
            * @dev gives the amount of dgov which should be minted for 1 dbit of input
        * @return amountDGOV the amount of DGOV which should be minted
        */
    function _cdpDbitToDgov() private view returns (uint256 amountDGOV) {
        uint256 _sCollateralised = IDebondToken(DGOVAddress).getTotalCollateralisedSupply();
         amountDGOV = (100 ether + ((_sCollateralised * 1e9) / 33333 / 1e18)**2).inv();
    }
    /**
    * @dev given the amount of dbit, returns the amout of DGOV to mint
    * @param _amountDBIT the amount of token
    * @return amountDGOV the amount of DGOV to mint
    */
    function convertDbitToDgov(uint256 _amountDBIT) private view returns (uint256 amountDGOV) {
        uint256 rate = _cdpDbitToDgov();
        amountDGOV = _amountDBIT.mul(rate);
    }

    function _convertToDgov(address tokenAddress, uint256 amount) internal view returns (uint256 amountDgov) {
        uint amountDBITToMint = tokenAddress == DBITAddress ? amount : convertToDbit(uint128(amount), tokenAddress);
        amountDgov = convertDbitToDgov(amountDBITToMint);
    }
}
