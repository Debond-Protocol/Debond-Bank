pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "./Mintable.sol";

contract DAI is Mintable {
  constructor() Mintable("DAI Test", "DAI") {}
}
