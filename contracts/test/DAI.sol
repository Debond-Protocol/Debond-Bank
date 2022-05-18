pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DAI is ERC20, Ownable {
    constructor() ERC20("DAI Test", "DAI") {}

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }
}
