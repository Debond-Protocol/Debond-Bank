pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT


import "@debond-protocol/debond-erc3475-contracts/DebondERC3475.sol";


contract DebondBondTest is DebondERC3475 {

    constructor(address governanceAddress) DebondERC3475(governanceAddress) {}
}
