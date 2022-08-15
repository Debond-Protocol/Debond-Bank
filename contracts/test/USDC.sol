pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "./Mintable.sol";

contract USDC is Mintable {
    constructor() Mintable("USDC Test", "USDC") {}
}
