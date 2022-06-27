//SPDX-License-Identifier: MIT
//Copyright 2021 DeBond Protocol <info@debond.org>

pragma solidity >=0.8.0;

import "../BankBondManager.sol";

interface IBankData {

    function setBankAddress(address _bankAddress) external;

    function updateCanPurchase(uint classIdIn, uint classIdOut, bool _canPurchase) external;

    function setTokenInterestRateSupply(address tokenAddress, BankBondManager.InterestRateType, uint amount) external;

    function setTokenTotalSupplyAtNonce(address tokenAddress, uint nonceId, uint amount) external;

    function pushClassIdPerToken(address tokenAddress, uint classId) external;

    function setTokenAddressWithBondValue(uint value, address tokenAddress) external;

    function setBondValueFromTokenAddress(address tokenAddress, uint value) external;

    function setTokenAddressExists(address tokenAddress, bool exist) external;

    function incrementTokenAddressCount() external;

    function setBenchmarkInterest(uint benchmarkInterest) external;




    function getBaseTimestamp() external view returns (uint);

    function getEpoch() external view returns (uint);

    function canPurchase(uint classIdIn, uint classIdOut) external view returns (bool);

    function getClasses() external view returns (uint[] memory);

    function getTokenInterestRateSupply(address tokenAddress, BankBondManager.InterestRateType) external view returns (uint);

    function getClassIdsFromTokenAddress(address tokenAddress) external view returns (uint[] memory);

    function getTokenAddressFromBondValue(uint value) external view returns (address);

    function getTokenTotalSupplyAtNonce(address tokenAddress, uint nonceId) external view returns (uint);

    function getBondValueFromTokenAddress(address tokenAddress) external view returns (uint);

    function tokenAddressExist(address tokenAddress) external view returns (bool);

    function tokenAddressCount() external view returns (uint);

    function getBenchmarkInterest() external view returns (uint);

}