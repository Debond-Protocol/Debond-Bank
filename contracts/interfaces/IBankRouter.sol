pragma solidity ^0.8.0;

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
