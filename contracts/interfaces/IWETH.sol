pragma solidity >=0.8.0;

// SPDX-License-Identifier: apache 2.0

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}
