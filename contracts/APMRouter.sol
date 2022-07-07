pragma solidity ^0.8.0;

// SPDX-License-Identifier: apache 2.0
import "apm-contracts/interfaces/IAPM.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


abstract contract APMRouter {
    IAPM apm;
    constructor(
        address apmAddress
    ) {
        apm = IAPM(apmAddress);
    }

    function updateWhenAddLiquidity(
        uint _amountA,
        uint _amountB,
        address _tokenA,
        address _tokenB) internal {
        apm.updateWhenAddLiquidity(_amountA, _amountB, _tokenA, _tokenB);
    }
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to
    ) external {
        uint[] memory amounts = apm.getAmountsOut(amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');

        IERC20(path[0]).transferFrom(msg.sender, address(apm), amounts[0]);
        _swap(amounts, path, to);
    }

    function removeLiquidity(address _to, address tokenAddress, uint amount) internal {
        apm.removeLiquidity(_to, tokenAddress, amount);
    }

    function getReserves(address tokenA, address tokenB) internal view returns (uint _reserveA, uint _reserveB) {
        (_reserveA, _reserveB) = apm.getReserves(tokenA, tokenB);
    }

    function _swap(uint[] memory amounts, address[] memory path, address to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = (uint(0), amountOut);
            apm.swap(
                amount0Out, amount1Out, input, output, to
            );
        }
    }
}
