pragma solidity ^0.8.0;

// SPDX-License-Identifier: apache 2.0
/*
    Copyright 2022 Debond Protocol <info@debond.org>
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

import "@debond-protocol/debond-governance-contracts/utils/GovernanceOwnable.sol";
import "@debond-protocol/debond-erc3475-contracts/interfaces/IDebondBond.sol";
import "@debond-protocol/debond-erc3475-contracts/interfaces/IProgressCalculator.sol";
import "@debond-protocol/debond-oracle-contracts/interfaces/IOracle.sol";
import "erc3475/IERC3475.sol";
import "./libraries/DebondMath.sol";
import "./interfaces/IBankData.sol";
import "./interfaces/IBankBondManager.sol";



contract BankBondManager is IBankBondManager, IProgressCalculator, GovernanceOwnable {

    using DebondMath for uint256;

    address debondBondAddress;
    address bankAddress;
    address bankDataAddress;
    address oracleAddress;
    address immutable USDCAddress;

    // class MetadataIds
    uint public constant symbolMetadataId = 0;
    uint public constant tokenAddressMetadataId = 1;
    uint public constant interestRateTypeMetadataId = 2;
    uint public constant periodMetadataId = 3;

    // nonce MetadataIds
    uint public constant issuanceDateMetadataId = 0;
    uint public constant maturityDateMetadataId = 1;

    uint public constant EPOCH = 1 days; // should Be 24 hours
    bool dataInitialized;


    constructor(
        address _governanceAddress,
        address _debondBondAddress,
        address _bankAddress,
        address _bankDataAddress,
        address _oracleAddress,
        address _USDCAddress
    ) GovernanceOwnable(_governanceAddress) {
        debondBondAddress = _debondBondAddress;
        bankAddress = _bankAddress;
        bankDataAddress = _bankDataAddress;
        oracleAddress = _oracleAddress;
        USDCAddress = _USDCAddress;
    }

    function initDatas(
        address DBITAddress,
        address USDTAddress,
        address DAIAddress,
        address DGOVAddress,
        address WETHAddress
    ) external onlyGovernance {
        require(!dataInitialized);
        dataInitialized = true;
        uint SIX_M_PERIOD = 180 * EPOCH;
        // 1 hour period for tests

        _createInitClassMetadatas();

        _createClass(0, "DBIT", DBITAddress, InterestRateType.FixedRate, SIX_M_PERIOD);
        _createClass(1, "USDC", USDCAddress, InterestRateType.FixedRate, SIX_M_PERIOD);
        _createClass(2, "USDT",USDTAddress, InterestRateType.FixedRate, SIX_M_PERIOD);
        _createClass(3, "DAI", DAIAddress, InterestRateType.FixedRate, SIX_M_PERIOD);
        _createClass(4, "DGOV", DGOVAddress, InterestRateType.FixedRate, SIX_M_PERIOD);
        _createClass(10, "WETH", WETHAddress, InterestRateType.FixedRate, SIX_M_PERIOD);

        _createClass(5, "DBIT", DBITAddress, InterestRateType.FloatingRate, SIX_M_PERIOD);
        _createClass(6, "USDC", USDCAddress, InterestRateType.FloatingRate, SIX_M_PERIOD);
        _createClass(7, "USDT", USDTAddress, InterestRateType.FloatingRate, SIX_M_PERIOD);
        _createClass(8, "DAI", DAIAddress, InterestRateType.FloatingRate, SIX_M_PERIOD);
        _createClass(9, "DGOV", DGOVAddress, InterestRateType.FloatingRate, SIX_M_PERIOD);
        _createClass(11, "WETH", WETHAddress, InterestRateType.FloatingRate, SIX_M_PERIOD);


        _updateCanPurchase(1, 0, true);
        _updateCanPurchase(2, 0, true);
        _updateCanPurchase(3, 0, true);
        _updateCanPurchase(10, 0, true);
        _updateCanPurchase(0, 4, true);
        _updateCanPurchase(1, 4, true);
        _updateCanPurchase(2, 4, true);
        _updateCanPurchase(3, 4, true);
        _updateCanPurchase(10, 4, true);

        _updateCanPurchase(6, 5, true);
        _updateCanPurchase(7, 5, true);
        _updateCanPurchase(8, 5, true);
        _updateCanPurchase(11, 5, true);
        _updateCanPurchase(5, 9, true);
        _updateCanPurchase(6, 9, true);
        _updateCanPurchase(7, 9, true);
        _updateCanPurchase(8, 9, true);
        _updateCanPurchase(11, 9, true);
    }

    modifier onlyBank {
        require(msg.sender == bankAddress, "BankBondManager Error, only Bank Authorised");
        _;
    }

    function setDebondBondAddress(address _debondBondAddress) external onlyGovernance {
        debondBondAddress = _debondBondAddress;
    }

    function setBankDataAddress(address _bankDataAddress) external onlyGovernance {
        bankDataAddress = _bankDataAddress;
    }

    function setBankAddress(address _bankAddress) external onlyGovernance {
        bankAddress = _bankAddress;
    }

    function setBenchmarkInterest(uint _benchmarkInterest) external onlyGovernance {
        IBankData(bankDataAddress).setBenchmarkInterest(_benchmarkInterest);
    }

    function issueBonds(address to, uint256[] memory classIds, uint256[] memory amounts) external onlyBank {
        require(classIds.length == amounts.length, "BankBondManager: Incorrect Inputs");
        uint instant = block.timestamp;
        uint _nowNonce = getNonceFromDate(block.timestamp);
        uint[] memory nonceIds = new uint[](classIds.length);
        IERC3475.Transaction[] memory transactions = new IERC3475.Transaction[](classIds.length);
        for (uint i; i < classIds.length; i++) {
            (,, uint period) = classValues(classIds[i]);
            uint _nonceToCreate = _nowNonce + getNonceFromPeriod(period);
            (uint _lastNonceCreated,) = IDebondBond(debondBondAddress).getLastNonceCreated(classIds[i]);
            if (_nonceToCreate != _lastNonceCreated) {
                createNewNonce(classIds[i], _nonceToCreate, instant);
                _lastNonceCreated = _nonceToCreate;
            }
            nonceIds[i] = _lastNonceCreated;

            (address tokenAddress, InterestRateType interestRateType,) = classValues(classIds[i]);
            setTokenInterestRateSupply(tokenAddress, interestRateType, amounts[i]);
            setTokenTotalSupplyAtNonce(tokenAddress, nonceIds[i], _tokenTotalSupply(tokenAddress));

            IERC3475.Transaction memory transaction = IERC3475.Transaction(classIds[i], nonceIds[i], amounts[i]);
            transactions[i] = transaction;
        }

        IERC3475(debondBondAddress).issue(to, transactions);
    }

    function getProgress(uint256 classId, uint256 nonceId) external view returns (uint256 progressAchieved, uint256 progressRemaining) {
        (address _tokenAddress, InterestRateType _interestRateType, uint _periodTimestamp) = classValues(classId);
        (, uint256 _maturityDate) = nonceValues(classId, nonceId);
        if (_interestRateType == InterestRateType.FixedRate) {
            progressRemaining = _maturityDate <= block.timestamp ? 0 : (_maturityDate - block.timestamp) * 100 / _periodTimestamp;
            progressAchieved = 100 - progressRemaining;
            return (progressAchieved, progressRemaining);
        }

        uint BsumNL = _tokenTotalSupply(_tokenAddress);
        uint BsumN = getTokenTotalSupplyAtNonce(_tokenAddress, nonceId);
        uint BsumNInterest = BsumN + BsumN.mul(getBenchmarkInterest());

        progressRemaining = BsumNInterest < BsumNL ? 0 : 100;
        progressAchieved = 100 - progressRemaining;
    }

    function updateCanPurchase(uint classIdIn, uint classIdOut, bool _canPurchase) external onlyGovernance {
        _updateCanPurchase(classIdIn, classIdOut, _canPurchase);
    }

    function _updateCanPurchase(uint classIdIn, uint classIdOut, bool _canPurchase) private {
        IBankData(bankDataAddress).updateCanPurchase(classIdIn, classIdOut, _canPurchase);
    }

    function createClassMetadatas(uint256[] memory metadataIds, IERC3475.Metadata[] memory metadatas) external onlyGovernance {
        _createClassMetadatas(metadataIds, metadatas);
    }

    function _createClassMetadatas(uint256[] memory metadataIds, IERC3475.Metadata[] memory metadatas) internal {
        IDebondBond(debondBondAddress).createClassMetadataBatch(metadataIds, metadatas);
    }

    function mapClassValuesFrom(string memory symbol, address tokenAddress, InterestRateType interestRateType, uint256 period) private pure returns (uint[] memory, IERC3475.Values[] memory) {
        uint[] memory _metadataIds = new uint[](4);
        _metadataIds[0] = symbolMetadataId;
        _metadataIds[1] = tokenAddressMetadataId;
        _metadataIds[2] = interestRateTypeMetadataId;
        _metadataIds[3] = periodMetadataId;

        IERC3475.Values[] memory _values = new IERC3475.Values[](4);
        _values[0] = IERC3475.Values(symbol, 0, address(0), false);
        _values[1] = IERC3475.Values("", 0, tokenAddress, false);
        _values[2] = IERC3475.Values("", uint(interestRateType), address(0), false);
        _values[3] = IERC3475.Values("", period, address(0), false);
        return  (_metadataIds, _values);
    }

    function mapNonceValuesFrom(uint256 issuanceDate, uint256 maturityDate) private pure returns (uint[] memory, IERC3475.Values[] memory) {
        uint[] memory _metadataIds = new uint[](2);
        _metadataIds[0] = issuanceDateMetadataId;
        _metadataIds[1] = maturityDateMetadataId;

        IERC3475.Values[] memory _values = new IERC3475.Values[](2);
        _values[0] = IERC3475.Values("", issuanceDate, address(0), false);
        _values[1] = IERC3475.Values("", maturityDate, address(0), false);

        return (_metadataIds, _values);
    }

    function _createInitClassMetadatas() private {
        uint256[] memory metadataIds = new uint256[](4);
        metadataIds[0] = symbolMetadataId;
        metadataIds[1] = tokenAddressMetadataId;
        metadataIds[2] = interestRateTypeMetadataId;
        metadataIds[3] = periodMetadataId;

        IERC3475.Metadata[] memory metadatas = new IERC3475.Metadata[](4);
        metadatas[0] = IERC3475.Metadata("symbol", "string", "the collateral token's symbol");
        metadatas[1] = IERC3475.Metadata("token address", "address", "the collateral token's address");
        metadatas[2] = IERC3475.Metadata("interest rate type", "int", "the interest rate type");
        metadatas[3] = IERC3475.Metadata("period", "int", "the base period for the class");
        IDebondBond(debondBondAddress).createClassMetadataBatch(metadataIds, metadatas);
    }

    function createClass(uint256 classId, string memory symbol, address tokenAddress, InterestRateType interestRateType, uint256 period) external onlyGovernance {
        _createClass(classId, symbol, tokenAddress, interestRateType, period);
    }

    function _createClass(uint256 classId, string memory symbol, address tokenAddress, InterestRateType interestRateType, uint256 period) private {
        (uint[] memory _metadataIds, IERC3475.Values[] memory _values) = mapClassValuesFrom(symbol, tokenAddress, interestRateType, period);
        IDebondBond(debondBondAddress).createClass(classId, _metadataIds, _values);
        pushClassIdPerToken(tokenAddress, classId);
        addNewClassId(classId);
        _createNonceMetadatas(classId);
    }

    function _createNonceMetadatas(uint256 classId) private {
        uint256[] memory metadataIds = new uint256[](2);
        metadataIds[0] = issuanceDateMetadataId;
        metadataIds[1] = maturityDateMetadataId;

        IERC3475.Metadata[] memory metadatas = new IERC3475.Metadata[](2);
        metadatas[0] = IERC3475.Metadata("issuance date", "int", "the issuance date of the bond");
        metadatas[1] = IERC3475.Metadata("maturity date", "int", "the maturity date of the bond");
        IDebondBond(debondBondAddress).createNonceMetadataBatch(classId, metadataIds, metadatas);
    }

    function createNewNonce(uint classId, uint newNonceId, uint creationTimestamp) private {
        (,, uint period) = classValues(classId);
        (uint[] memory _metadataIds, IERC3475.Values[] memory _values) = mapNonceValuesFrom(creationTimestamp, creationTimestamp + period);

        IDebondBond(debondBondAddress).createNonce(classId, newNonceId, _metadataIds, _values);
        _updateLastNonce(classId, newNonceId, creationTimestamp);
    }

    function getNonceFromDate(uint256 date) private view returns (uint256) {
        return getNonceFromPeriod(date - getBaseTimestamp());
    }

    function getNonceFromPeriod(uint256 period) private pure returns (uint256) {
        return period / EPOCH;
    }

    function _updateLastNonce(uint classId, uint nonceId, uint createdAt) internal {
        IDebondBond(debondBondAddress).updateLastNonce(classId, nonceId, createdAt);
    }

    function getETA(uint256 classId, uint256 nonceId) external view returns (uint256) {
        (address _tokenAddress, InterestRateType _interestRateType,) = classValues(classId);
        (, uint256 _maturityDate) = nonceValues(classId, nonceId);

        if (_interestRateType == InterestRateType.FixedRate) {
            return _maturityDate;
        }

        uint BsumNL = _tokenTotalSupply(_tokenAddress);
        uint BsumN = getTokenTotalSupplyAtNonce(_tokenAddress, nonceId);

        (uint lastNonceCreated,) = IDebondBond(debondBondAddress).getLastNonceCreated(classId);
        uint liquidityFlowOver30Nonces = _supplyIssuedOnPeriod(_tokenAddress, lastNonceCreated - 30, lastNonceCreated);
        uint Umonth = liquidityFlowOver30Nonces / 30;
        return DebondMath.floatingETA(_maturityDate, BsumN, getBenchmarkInterest(), BsumNL, EPOCH, Umonth);
    }

    function _getSupplies(address tokenAddress, InterestRateType interestRateType, uint supplyToAdd) internal view returns (uint fixRateSupply, uint floatRateSupply) {
        fixRateSupply = getTokenInterestRateSupply(tokenAddress, InterestRateType.FixedRate);
        floatRateSupply = getTokenInterestRateSupply(tokenAddress, InterestRateType.FloatingRate);

        // we had the client amount to the according bond balance to calculate interest rate after deposit
        if (supplyToAdd > 0 && interestRateType == InterestRateType.FixedRate) {
            fixRateSupply += supplyToAdd;
        }
        if (supplyToAdd > 0 && interestRateType == InterestRateType.FloatingRate) {
            floatRateSupply += supplyToAdd;
        }
    }

    function classValues(uint256 classId) public view returns (address _tokenAddress, InterestRateType _interestRateType, uint256 _periodTimestamp) {
        _tokenAddress = (IERC3475(debondBondAddress).classValues(classId, tokenAddressMetadataId)).addressValue;
        uint interestType = (IERC3475(debondBondAddress).classValues(classId, interestRateTypeMetadataId)).uintValue;
        _interestRateType = interestType == 0 ? InterestRateType.FixedRate : InterestRateType.FloatingRate;
        _periodTimestamp = (IERC3475(debondBondAddress).classValues(classId, periodMetadataId)).uintValue;
    }

    function nonceValues(uint256 classId, uint256 nonceId) public view returns (uint256 _issuanceDate, uint256 _maturityDate) {
        _issuanceDate = (IERC3475(debondBondAddress).nonceValues(classId, nonceId, issuanceDateMetadataId)).uintValue;
        _maturityDate = (IERC3475(debondBondAddress).nonceValues(classId, nonceId, maturityDateMetadataId)).uintValue;
    }

    function _tokenTotalSupply(address tokenAddress) internal view returns (uint256) {
        return getTokenInterestRateSupply(tokenAddress, InterestRateType.FixedRate) + getTokenInterestRateSupply(tokenAddress, InterestRateType.FloatingRate);
    }

    function _supplyIssuedOnPeriod(address tokenAddress, uint256 fromNonceId, uint256 toNonceId) internal view returns (uint256 supply) {
        require(fromNonceId <= toNonceId, "DebondBond Error: Invalid Input");
        // we loop on every nonces required of every token's classes
        uint[] memory _classIdsPerTokenAddress = getClassIdsFromTokenAddress(tokenAddress);
        for (uint i = fromNonceId; i <= toNonceId; i++) {
            for (uint j = 0; j < _classIdsPerTokenAddress.length; j++) {
                supply += (IDebondBond(debondBondAddress).activeSupply(_classIdsPerTokenAddress[j], i) + IDebondBond(debondBondAddress).redeemedSupply(_classIdsPerTokenAddress[j], i));
            }
        }
    }

    function redeemERC3475(address from, uint classId, uint nonceId, uint amount) external onlyBank {
        IERC3475.Transaction[] memory transactions = new IERC3475.Transaction[](1);
        IERC3475.Transaction memory transaction = IERC3475.Transaction(classId, nonceId, amount);
        transactions[0] = transaction;
        IERC3475(debondBondAddress).redeem(from, transactions);
    }

    function setTokenInterestRateSupply(address tokenAddress, InterestRateType interestRateType, uint amount) internal {
        IBankData(bankDataAddress).setTokenInterestRateSupply(tokenAddress, interestRateType, amount);
    }

    function setTokenTotalSupplyAtNonce(address tokenAddress, uint nonceId, uint amount) internal {
        IBankData(bankDataAddress).setTokenTotalSupplyAtNonce(tokenAddress, nonceId, amount);
    }

    function pushClassIdPerToken(address tokenAddress, uint classId) private {
        IBankData(bankDataAddress).pushClassIdPerToken(tokenAddress, classId);
    }

    function addNewClassId(uint classId) private {
        IBankData(bankDataAddress).addNewClassId(classId);
    }

    function getBaseTimestamp() public view returns (uint) {
        return IBankData(bankDataAddress).getBaseTimestamp();
    }

    function getClasses() external view returns (uint[] memory) {
        return IBankData(bankDataAddress).getClasses();
    }

    function getTokenInterestRateSupply(address tokenAddress, InterestRateType interestRateType) public view returns (uint) {
        return IBankData(bankDataAddress).getTokenInterestRateSupply(tokenAddress, interestRateType);
    }

    function getClassIdsFromTokenAddress(address tokenAddress) public view returns (uint[] memory) {
        return IBankData(bankDataAddress).getClassIdsFromTokenAddress(tokenAddress);
    }

    function getTokenTotalSupplyAtNonce(address tokenAddress, uint nonceId) public view returns (uint) {
        return IBankData(bankDataAddress).getTokenTotalSupplyAtNonce(tokenAddress, nonceId);
    }

    function getBenchmarkInterest() public view returns (uint) {
        return IBankData(bankDataAddress).getBenchmarkInterest();
    }

    function getInterestRate(uint classId, uint amount) external view returns (uint rate) {
        (address tokenAddress, InterestRateType interestRateType,) = classValues(classId);
        (uint fixRateSupply, uint floatRateSupply) = _getSupplies(tokenAddress, interestRateType, amount);

        uint fixRate;
        uint floatRate;
        uint oneTokenToUSDValue = _convertTokenToUSDC(1 ether, tokenAddress);
        if ((fixRateSupply.mul(oneTokenToUSDValue)) < 100_000 ether || (floatRateSupply.mul(oneTokenToUSDValue)) < 100_000 ether) {
            (fixRate, floatRate) = _getDefaultRate();
        } else {
            (fixRate, floatRate) = _getCalculatedRate(fixRateSupply, floatRateSupply);
        }
        rate = interestRateType == InterestRateType.FixedRate ? fixRate : floatRate;
    }

    /**
    * @dev convert a given amount of token to USD  (the pair needs to exist on uniswap)
    * @param _amountToken the amount of token we want to convert
    * @param _tokenAddress the address of token we want to convert
    * @return amountUsd the corresponding amount of usd
    */
    function _convertTokenToUSDC(uint128 _amountToken, address _tokenAddress) private view returns (uint256 amountUsd) {

        if (_tokenAddress == USDCAddress) {
            amountUsd = _amountToken;
        }
        else {
            amountUsd = IOracle(oracleAddress).estimateAmountOut(_tokenAddress, _amountToken, USDCAddress, 60) * 1e12;
        }
    }

    function _getCalculatedRate(uint fixRateSupply, uint floatRateSupply) private view returns (uint fixedRate, uint floatingRate) {
        uint benchmarkInterest = getBenchmarkInterest();
        floatingRate = DebondMath.floatingInterestRate(fixRateSupply, floatRateSupply, benchmarkInterest);
        fixedRate = 2 * benchmarkInterest - floatingRate;
    }

    function _getDefaultRate() private view returns (uint fixRate, uint floatRate) {
        uint benchmarkInterest = getBenchmarkInterest();
        fixRate = 2 * benchmarkInterest / 3;
        floatRate = 2 * fixRate;
    }


}
