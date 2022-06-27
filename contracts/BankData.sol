pragma solidity ^0.8.0;

//SPDX-License-Identifier: MIT
//Copyright 2021 DeBond Protocol <info@debond.org>

import "./BankBondManager.sol";
import "./interfaces/IBankData.sol";
import "debond-governance-contracts/utils/GovernanceOwnable.sol";


contract BankData is IBankData, GovernanceOwnable {

    address bankAddress;


    mapping(uint256 => mapping(uint256 => bool)) _canPurchase; // can u get second input classId token from providing first input classId token
    uint public BASE_TIMESTAMP;
    uint public constant EPOCH = 30; // every 24h we crate a new nonce.
    uint public BENCHMARK_RATE_DECIMAL_18 = 5 * 10 ** 16;
    uint[] public classes;

    mapping(address => mapping(BankBondManager.InterestRateType => uint256)) public tokenRateTypeTotalSupply; // needed for interest rate calculation also
    mapping(address => mapping(uint256 => uint256)) public tokenTotalSupplyAtNonce;
    mapping(address => uint256[]) public classIdsPerTokenAddress;

    mapping(uint256 => address) public fromBondValueToTokenAddress;
    mapping(address => uint256) public tokenAddressValueMapping;

    mapping(address => bool) _tokenAddressExist;
    uint256 _tokenAddressCount;

    constructor(address _governanceAddress, address _bankAddress) GovernanceOwnable(_governanceAddress) {
        bankAddress = _bankAddress;
    }

    modifier onlyBank {
        require(msg.sender == bankAddress, "BankData Error, only Bank Authorised");
        _;
    }

    function setBankAddress(address _bankAddress) external onlyGovernance {
        require(_bankAddress != address(0), "BankData Error: address 0");
        bankAddress = _bankAddress;
    }

    function updateCanPurchase(uint classIdIn, uint classIdOut, bool __canPurchase) external onlyBank {
        _canPurchase[classIdIn][classIdOut] = __canPurchase;
    }

    function setTokenInterestRateSupply(address tokenAddress, BankBondManager.InterestRateType interestRateType, uint amount) external onlyBank {
        tokenRateTypeTotalSupply[tokenAddress][interestRateType] += amount;
    }

    function setTokenTotalSupplyAtNonce(address tokenAddress, uint nonceId, uint amount) external onlyBank {
        tokenTotalSupplyAtNonce[tokenAddress][nonceId] = amount;
    }

    function pushClassIdPerToken(address tokenAddress, uint classId) external onlyBank {
        classIdsPerTokenAddress[tokenAddress].push(classId);
    }

    function setTokenAddressWithBondValue(uint value, address tokenAddress) external onlyBank {
        fromBondValueToTokenAddress[value] = tokenAddress;
    }

    function setBondValueFromTokenAddress(address tokenAddress, uint value) external onlyBank {
        tokenAddressValueMapping[tokenAddress] = value;
    }

    function setTokenAddressExists(address tokenAddress, bool exist) external onlyBank {
        _tokenAddressExist[tokenAddress] = exist;
    }

    function incrementTokenAddressCount() external onlyBank {
        ++_tokenAddressCount;
    }

    function setBenchmarkInterest(uint _benchmarkInterest) external onlyBank {
        BENCHMARK_RATE_DECIMAL_18 = _benchmarkInterest;
    }


    function getBaseTimestamp() external view returns (uint) {
        return BASE_TIMESTAMP;
    }

    function getEpoch() external pure returns (uint) {
        return EPOCH;
    }

    function canPurchase(uint classIdIn, uint classIdOut) external view returns (bool) {
        return _canPurchase[classIdIn][classIdOut];
    }

    function getClasses() external view returns (uint[] memory) {
        return classes;
    }

    function getTokenInterestRateSupply(address tokenAddress, BankBondManager.InterestRateType interestRateType) external view returns (uint) {
        return tokenRateTypeTotalSupply[tokenAddress][interestRateType];
    }

    function getClassIdsFromTokenAddress(address tokenAddress) external view returns (uint[] memory) {
        return classIdsPerTokenAddress[tokenAddress];
    }

    function getTokenAddressFromBondValue(uint value) external view returns (address) {
        return fromBondValueToTokenAddress[value];
    }

    function getTokenTotalSupplyAtNonce(address tokenAddress, uint nonceId) external view returns (uint) {
        return tokenTotalSupplyAtNonce[tokenAddress][nonceId];
    }

    function getBondValueFromTokenAddress(address tokenAddress) external view returns (uint) {
        return tokenAddressValueMapping[tokenAddress];
    }

    function tokenAddressExist(address tokenAddress) external view returns (bool) {
        return _tokenAddressExist[tokenAddress];
    }

    function tokenAddressCount() external view returns (uint) {
        return _tokenAddressCount;
    }

    function getBenchmarkInterest() external view returns (uint) {
        return BENCHMARK_RATE_DECIMAL_18;
    }

}
