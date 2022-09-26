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

import "@debond-protocol/debond-governance-contracts/utils/ExecutableOwnable.sol";
import "@debond-protocol/debond-erc3475-contracts/interfaces/IDebondBond.sol";
import "@debond-protocol/debond-erc3475-contracts/interfaces/IProgressCalculator.sol";
import "@debond-protocol/debond-oracle-contracts/interfaces/IOracle.sol";
import "erc3475/IERC3475.sol";
import "./libraries/DebondMath.sol";
import "./interfaces/IBankStorage.sol";
import "./interfaces/IBankBondManager.sol";
import "./interfaces/Types.sol";


contract BankBondManager is IBankBondManager, IProgressCalculator, ExecutableOwnable {

    using DebondMath for uint256;

    address debondBondAddress;
    address bankAddress;
    address bankStorageAddress;
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

    uint public constant EPOCH_24H = 1 days;
    uint public constant CLASS_PERIOD_1 = 180 * EPOCH_24H; // 6 months
    bool dataInitialized;


    constructor(
        address _executableAddress,
        address _debondBondAddress,
        address _bankAddress,
        address _bankDataAddress,
        address _oracleAddress,
        address _USDCAddress
    ) ExecutableOwnable(_executableAddress) {
        debondBondAddress = _debondBondAddress;
        bankAddress = _bankAddress;
        bankStorageAddress = _bankDataAddress;
        oracleAddress = _oracleAddress;
        USDCAddress = _USDCAddress;
    }

    /**
    * @notice data initialization for Bonds (creation of classes) called once during
    */
    function initDatas(
        address DBITAddress,
        address USDTAddress,
        address DAIAddress,
        address DGOVAddress,
        address WETHAddress,
        address _debondBondAddress,
        address _bankStorageAddress
    ) external onlyExecutable {
        require(!dataInitialized);
        dataInitialized = true;

        debondBondAddress = _debondBondAddress;
        bankStorageAddress = _bankStorageAddress;
        _createInitClassMetadatas();

        _createClass(0, "DBIT", DBITAddress, Types.InterestRateType.FixedRate, CLASS_PERIOD_1);
        _createClass(1, "USDC", USDCAddress, Types.InterestRateType.FixedRate, CLASS_PERIOD_1);
        _createClass(2, "USDT", USDTAddress, Types.InterestRateType.FixedRate, CLASS_PERIOD_1);
        _createClass(3, "DAI", DAIAddress, Types.InterestRateType.FixedRate, CLASS_PERIOD_1);
        _createClass(4, "DGOV", DGOVAddress, Types.InterestRateType.FixedRate, CLASS_PERIOD_1);
        _createClass(10, "WETH", WETHAddress, Types.InterestRateType.FixedRate, CLASS_PERIOD_1);

        _createClass(5, "DBIT", DBITAddress, Types.InterestRateType.FloatingRate, CLASS_PERIOD_1);
        _createClass(6, "USDC", USDCAddress, Types.InterestRateType.FloatingRate, CLASS_PERIOD_1);
        _createClass(7, "USDT", USDTAddress, Types.InterestRateType.FloatingRate, CLASS_PERIOD_1);
        _createClass(8, "DAI", DAIAddress, Types.InterestRateType.FloatingRate, CLASS_PERIOD_1);
        _createClass(9, "DGOV", DGOVAddress, Types.InterestRateType.FloatingRate, CLASS_PERIOD_1);
        _createClass(11, "WETH", WETHAddress, Types.InterestRateType.FloatingRate, CLASS_PERIOD_1);


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

    function updateBankAddress(address _bankAddress) external onlyExecutable {
        bankAddress = _bankAddress;
    }

    function updateOracleAddress(address _oracleAddress) external onlyExecutable {
        oracleAddress = _oracleAddress;
    }


    /**
    * @notice issues ERC3475 Bonds, only the Bank can execute this action
    * @param _to the address to issue bonds to
    * @param _classIds the collection of bonds class ids
    * @param _amounts the collection of bonds amounts to issue
    */
    function issueBonds(
        address _to,
        uint256[] memory _classIds,
        uint256[] memory _amounts
    ) external onlyBank {
        require(_classIds.length == _amounts.length, "BankBondManager: Incorrect Inputs");
        uint instant = block.timestamp;
        // here we get the current nonce
        uint _nowNonce = _getNonceFromDate(instant);
        uint[] memory nonceIds = new uint[](_classIds.length);
        IERC3475.Transaction[] memory transactions = new IERC3475.Transaction[](_classIds.length);
        for (uint i; i < _classIds.length; i++) {
            (,, uint _period) = classValues(_classIds[i]);
            // here we get the nonce for a period to add it to the current nonce
            uint _nonceToIssueWith = _nowNonce + _getNonceFromPeriod(_period);
            (uint _lastNonceCreated,) = IDebondBond(debondBondAddress).getLastNonceCreated(_classIds[i]);
            // here we check if the nonce to issue the bond with is already created
            if (_nonceToIssueWith > _lastNonceCreated) {
                _createNewNonce(_classIds[i], _nonceToIssueWith, instant);
                _lastNonceCreated = _nonceToIssueWith;
            }
            nonceIds[i] = _lastNonceCreated;

            IERC3475.Transaction memory transaction = IERC3475.Transaction(_classIds[i], nonceIds[i], _amounts[i]);
            transactions[i] = transaction;
        }

        IERC3475(debondBondAddress).issue(_to, transactions);
    }

    /**
    * @notice gives either the progress achieved and the progress remaining for a classId and a nonceId given
    * @param _classId class Id of the requested bond
    * @param _nonceId nonce Id of the requested bond
    * @return progressAchieved and progressRemaining
    */
    function getProgress(uint256 _classId, uint256 _nonceId) external view returns (uint256 progressAchieved, uint256 progressRemaining) {
        (address _tokenAddress, Types.InterestRateType _interestRateType, uint _periodTimestamp) = classValues(_classId);
        (, uint256 _maturityDate) = nonceValues(_classId, _nonceId);
        if (_interestRateType == Types.InterestRateType.FixedRate) {
            progressRemaining = _maturityDate <= block.timestamp ? 0 : (_maturityDate - block.timestamp) * 100 / _periodTimestamp;
            progressAchieved = 100 - progressRemaining;
            return (progressAchieved, progressRemaining);
        }

        uint BsumNL = _tokenTotalSupply(_tokenAddress);
        uint BsumN = getTokenTotalSupplyAtNonce(_tokenAddress, _nonceId);
        uint BsumNInterest = BsumN + BsumN.mul(getBenchmarkInterest());

        progressRemaining = BsumNInterest < BsumNL ? 0 : 100;
        progressAchieved = 100 - progressRemaining;
    }

    function getETA(uint256 _classId, uint256 _nonceId) external view returns (uint256) {
        (address _tokenAddress, Types.InterestRateType _interestRateType,) = classValues(_classId);
        (, uint256 _maturityDate) = nonceValues(_classId, _nonceId);

        if (_interestRateType == Types.InterestRateType.FixedRate) {
            return _maturityDate;
        }

        uint256 _totalSupply = _tokenTotalSupply(_tokenAddress);
        uint256 _supplyAtNonce = getTokenTotalSupplyAtNonce(_tokenAddress, _nonceId);

        uint256 liquidityInFromLast30Nonces = _tokenLiquidityInFromLast(_tokenAddress, 30);
        uint256 averageLiquidityInOverLast30Nonces = liquidityInFromLast30Nonces / 30;
        return DebondMath.floatingETA(_maturityDate, _supplyAtNonce, getBenchmarkInterest(), _totalSupply, EPOCH_24H, averageLiquidityInOverLast30Nonces);
    }

    /**
    * @notice update classes purchasable, only Governance can process this action
    * @param _classIdIn class Id to purchase with
    * @param _classIdOut class Id to purchase
    * @param _canPurchase set to true if it can purchase, false if not
    */
    function updateCanPurchase(uint _classIdIn, uint _classIdOut, bool _canPurchase) external onlyExecutable {
        _updateCanPurchase(_classIdIn, _classIdOut, _canPurchase);
    }

    function _updateCanPurchase(uint classIdIn, uint classIdOut, bool _canPurchase) private {
        IBankStorage(bankStorageAddress).updateCanPurchase(classIdIn, classIdOut, _canPurchase);
    }

    /**
    * @notice maps class values into IERC3475 Values
    * @param _symbol symbol of the class
    * @param _tokenAddress token address of the class
    * @param _interestRateType the interest rate type (either fix or float)
    * @param _period the period of the bond's class
    * @return an array of IERC3475 Values
    */
    function mapClassValuesFrom(
        string memory _symbol,
        address _tokenAddress,
        Types.InterestRateType _interestRateType,
        uint256 _period
    ) private pure returns (uint[] memory, IERC3475.Values[] memory) {
        uint[] memory _metadataIds = new uint[](4);
        _metadataIds[0] = symbolMetadataId;
        _metadataIds[1] = tokenAddressMetadataId;
        _metadataIds[2] = interestRateTypeMetadataId;
        _metadataIds[3] = periodMetadataId;

        IERC3475.Values[] memory _values = new IERC3475.Values[](4);
        _values[0] = IERC3475.Values(_symbol, 0, address(0), false);
        _values[1] = IERC3475.Values("", 0, _tokenAddress, false);
        _values[2] = IERC3475.Values("", uint(_interestRateType), address(0), false);
        _values[3] = IERC3475.Values("", _period, address(0), false);
        return (_metadataIds, _values);
    }

    /**
    * @notice maps nonce values into IERC3475 Values
    * @param _issuanceDate issuance date (creation date) of the bond
    * @param _maturityDate maturity date of the bond
    * @return an array of IERC3475 Values
    */
    function mapNonceValuesFrom(
        uint256 _issuanceDate,
        uint256 _maturityDate
    ) private pure returns (uint[] memory, IERC3475.Values[] memory) {
        uint[] memory _metadataIds = new uint[](2);
        _metadataIds[0] = issuanceDateMetadataId;
        _metadataIds[1] = maturityDateMetadataId;

        IERC3475.Values[] memory _values = new IERC3475.Values[](2);
        _values[0] = IERC3475.Values("", _issuanceDate, address(0), false);
        _values[1] = IERC3475.Values("", _maturityDate, address(0), false);

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

    /**
    * @notice creates a new bond's class
    * @dev the class Id given must be not used for an already created class
    */
    function createClass(
        uint256 _classId,
        string memory _symbol,
        address _tokenAddress,
        Types.InterestRateType _interestRateType,
        uint256 _period
    ) external onlyExecutable {
        _createClass(_classId, _symbol, _tokenAddress, _interestRateType, _period);
    }

    function _createClass(
        uint256 classId,
        string memory symbol,
        address tokenAddress,
        Types.InterestRateType interestRateType,
        uint256 period
    ) private {
        (uint[] memory _metadataIds, IERC3475.Values[] memory _values) = mapClassValuesFrom(symbol, tokenAddress, interestRateType, period);
        IDebondBond(debondBondAddress).createClass(classId, _metadataIds, _values);
        _pushClassIdPerToken(tokenAddress, classId);
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

    function _createNewNonce(uint classId, uint newNonceId, uint creationTimestamp) private {
        (,, uint period) = classValues(classId);
        (uint[] memory _metadataIds, IERC3475.Values[] memory _values) = mapNonceValuesFrom(creationTimestamp, creationTimestamp + period);
        IDebondBond(debondBondAddress).createNonce(classId, newNonceId, _metadataIds, _values);
    }

    function _getNonceFromDate(uint256 _date) private view returns (uint256) {
        return _getNonceFromPeriod(_date - getBaseTimestamp());
    }

    function _getNonceFromPeriod(uint256 _period) private pure returns (uint256) {
        return _period / EPOCH_24H;
    }

    /**
    * @notice get the up to date supplies for fix and float rate (contains the liquidity added in the input)
    */
    function _getSupplies(
        address _tokenAddress,
        Types.InterestRateType _interestRateType,
        uint _supplyToAdd
    ) internal view returns (uint _fixRateSupply, uint _floatRateSupply) {
        _fixRateSupply = getTokenInterestRateSupply(_tokenAddress, Types.InterestRateType.FixedRate);
        _floatRateSupply = getTokenInterestRateSupply(_tokenAddress, Types.InterestRateType.FloatingRate);

        // we had the client amount to the according bond balance to calculate interest rate after deposit
        if (_supplyToAdd > 0 && _interestRateType == Types.InterestRateType.FixedRate) {
            _fixRateSupply += _supplyToAdd;
        }
        if (_supplyToAdd > 0 && _interestRateType == Types.InterestRateType.FloatingRate) {
            _floatRateSupply += _supplyToAdd;
        }
    }

    /**
    * @notice gets all the class values for a given class Id
    * @param _classId the requested class Id
    * @return _tokenAddress _interestRateType _periodTimestamp (the class values)
    */
    function classValues(uint256 _classId) public view returns (address _tokenAddress, Types.InterestRateType _interestRateType, uint256 _periodTimestamp) {
        _tokenAddress = (IERC3475(debondBondAddress).classValues(_classId, tokenAddressMetadataId)).addressValue;
        uint interestType = (IERC3475(debondBondAddress).classValues(_classId, interestRateTypeMetadataId)).uintValue;
        _interestRateType = interestType == 0 ? Types.InterestRateType.FixedRate : Types.InterestRateType.FloatingRate;
        _periodTimestamp = (IERC3475(debondBondAddress).classValues(_classId, periodMetadataId)).uintValue;
    }

    /**
    * @notice gets all the nonce values for a given class Id and nonce Id
    * @param _classId the requested class Id
    * @param _nonceId the requested nonce Id
    * @return _issuanceDate _maturityDate the nonce values
    */
    function nonceValues(uint256 _classId, uint256 _nonceId) public view returns (uint256 _issuanceDate, uint256 _maturityDate) {
        _issuanceDate = (IERC3475(debondBondAddress).nonceValues(_classId, _nonceId, issuanceDateMetadataId)).uintValue;
        _maturityDate = (IERC3475(debondBondAddress).nonceValues(_classId, _nonceId, maturityDateMetadataId)).uintValue;
    }

    function _tokenTotalSupply(address tokenAddress) private view returns (uint256) {
        uint[] memory _tokenClasses = IBankStorage(bankStorageAddress).getClassIdsFromTokenAddress(tokenAddress);
        uint supply;
        for (uint i; i < _tokenClasses.length; i++) {
            supply += IDebondBond(debondBondAddress).classLiquidity(_tokenClasses[i]);
        }
        return supply;
    }

    function _tokenLiquidityInFromLast(address _tokenAddress, uint256 _nonceCount) private view returns (uint256 supply) {
        uint[] memory _classIdsPerTokenAddress = getClassIdsFromTokenAddress(_tokenAddress);
        for (uint i = 0; i < _classIdsPerTokenAddress.length; i++) {
            (,, uint _period) = classValues(_classIdsPerTokenAddress[i]);
            (uint _toNonceId,) = IDebondBond(debondBondAddress).getLastNonceCreated(_classIdsPerTokenAddress[i]);
            if(_toNonceId < _getNonceFromPeriod(_period) || _toNonceId < _nonceCount) {
                supply += 0;
                continue;
            }
            uint _fromNonceId = _toNonceId - _nonceCount < _getNonceFromPeriod(_period) ? _getNonceFromPeriod(_period) : _toNonceId - _nonceCount;
            supply +=
                IDebondBond(debondBondAddress).classLiquidityAtNonce(_classIdsPerTokenAddress[i], _toNonceId, _getNonceFromPeriod(_period)) -
                IDebondBond(debondBondAddress).classLiquidityAtNonce(_classIdsPerTokenAddress[i], _fromNonceId, _getNonceFromPeriod(_period));
        }
    }

    function _pushClassIdPerToken(address tokenAddress, uint classId) private {
        IBankStorage(bankStorageAddress).pushClassIdPerTokenAddress(tokenAddress, classId);
    }

    function getBaseTimestamp() public view returns (uint) {
        return IBankStorage(bankStorageAddress).getBaseTimestamp();
    }

    function getTokenInterestRateSupply(address tokenAddress, Types.InterestRateType interestRateType) public view returns (uint) {
        uint[] memory _tokenClasses = IBankStorage(bankStorageAddress).getClassIdsFromTokenAddress(tokenAddress);
        uint supply;
        for (uint i; i < _tokenClasses.length; i++) {
            (, Types.InterestRateType classInterestRateType,) = classValues(_tokenClasses[i]);
            if (classInterestRateType == interestRateType) {
                supply += IDebondBond(debondBondAddress).classLiquidity(_tokenClasses[i]);
            }
        }
        return supply;
    }

    function getClassIdsFromTokenAddress(address tokenAddress) public view returns (uint[] memory) {
        return IBankStorage(bankStorageAddress).getClassIdsFromTokenAddress(tokenAddress);
    }

    function getTokenTotalSupplyAtNonce(address tokenAddress, uint nonceId) public view returns (uint) {
        uint[] memory _tokenClasses = IBankStorage(bankStorageAddress).getClassIdsFromTokenAddress(tokenAddress);
        uint supply;
        for (uint i; i < _tokenClasses.length; i++) {
            (,, uint _period) = classValues(_tokenClasses[i]);
            supply += IDebondBond(debondBondAddress).classLiquidityAtNonce(_tokenClasses[i], nonceId, _getNonceFromPeriod(_period));
        }
        return supply;
    }

    function getBenchmarkInterest() public view returns (uint) {
        return IBankStorage(bankStorageAddress).getBenchmarkInterest();
    }

    function getInterestRate(uint classId, uint amount) external view returns (uint256) {
        (address tokenAddress, Types.InterestRateType interestRateType,) = classValues(classId);
        (uint fixRateSupply, uint floatRateSupply) = _getSupplies(tokenAddress, interestRateType, amount);

        uint fixRate;
        uint floatRate;
        uint oneTokenToUSDValue = _convertTokenToUSDC(1 ether, tokenAddress);
        if ((fixRateSupply.mul(oneTokenToUSDValue)) < 100_000 ether || (floatRateSupply.mul(oneTokenToUSDValue)) < 100_000 ether) {
            (fixRate, floatRate) = _getDefaultRate();
           return interestRateType == Types.InterestRateType.FixedRate ? fixRate : floatRate;
        } else {
            (fixRate, floatRate) = _getCalculatedRate(fixRateSupply, floatRateSupply);
            uint256 rate = interestRateType == Types.InterestRateType.FixedRate ? fixRate : floatRate;
            uint256 _last30NoncesLiquidityIn = _tokenLiquidityInFromLast(tokenAddress, 30);

            // now we calculate the weight
            uint256 weight = DebondMath.getWeight(_last30NoncesLiquidityIn, 30, _tokenTotalSupply(tokenAddress));

            return rate.mul(weight);
        }



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
