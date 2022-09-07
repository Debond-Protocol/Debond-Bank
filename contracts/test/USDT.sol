pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "./Mintable.sol";

contract USDT is Mintable {
  constructor() Mintable("USDT Test", "USDT") {}
}
