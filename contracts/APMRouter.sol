pragma solidity ^0.8.0;

// SPDX-License-Identifier: apache 2.0
import "apm-contracts/interfaces/IAPM.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import './interfaces/IWeth.sol';



abstract contract APMRouter {

    IAPM apm;

    address immutable WETHAddress;

    constructor(
        address apmAddress,
        address _wethAddress
    ) {
        apm = IAPM(apmAddress);
        WETHAddress = _wethAddress;
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
        require(amounts[amounts.length - 1] >= amountOutMin, 'APMRouter: INSUFFICIENT_OUTPUT_AMOUNT');

        IERC20(path[0]).transferFrom(msg.sender, address(apm), amounts[0]);
        _swap(amounts, path, to);
    }
    function swapExactTokensForEth(
        uint amountIn,
        uint amountEthMin,
        address[] calldata path,
        address to
    ) external {
        require(path[path.length - 1] == WETHAddress, 'APMRouter: INVALID_PATH');
        uint[] memory amounts = apm.getAmountsOut(amountIn, path);
        require(amounts[amounts.length - 1] >= amountEthMin, 'APMRouter: INSUFFICIENT_OUTPUT_AMOUNT');

        IERC20(path[0]).transferFrom(msg.sender, address(apm), amounts[0]);
        _swap(amounts, path, address(this));
        IWeth(WETHAddress).withdraw(amounts[amounts.length - 1]);
        payable(to).transfer(amounts[amounts.length - 1]);
    }
    function swapExactEthForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to
    ) external {
        require(path[0] == WETHAddress, 'APMRouter: INVALID_PATH');
        uint[] memory amounts = apm.getAmountsOut(amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'APMRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWeth(WETHAddress).deposit{value : amountIn}();
        assert(IWeth(WETHAddress).transfer(address(apm), amountIn));

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
