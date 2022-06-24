//SPDX-License-Identifier: MIT
//Copyright 2021 DeBond Protocol <info@debond.org>

pragma solidity >=0.8.0;

interface IWeth {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}