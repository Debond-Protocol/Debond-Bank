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
  uint256 public constant symbolMetadataId = 0;
  uint256 public constant tokenAddressMetadataId = 1;
  uint256 public constant interestRateTypeMetadataId = 2;
  uint256 public constant periodMetadataId = 3;

  // nonce MetadataIds
  uint256 public constant issuanceDateMetadataId = 0;
  uint256 public constant maturityDateMetadataId = 1;

  uint256 public constant EPOCH_24H = 1 days;
  bool dataInitialized;

  event ClassCreated(uint256 classId, string, address, InterestRateType, uint256);

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

  /**
   * @notice data initialization for Bonds (creation of classes) called once during
   */
  function initDatas(
    address DBITAddress,
    address USDTAddress,
    address DAIAddress,
    address DGOVAddress,
    address WETHAddress
  ) external onlyGovernance {
    require(!dataInitialized);
    dataInitialized = true;
    uint256 SIX_M_PERIOD = 180 * EPOCH_24H;
    // 1 hour period for tests

    _createInitClassMetadatas();

    _createClass(0, "DBIT", DBITAddress, InterestRateType.FixedRate, SIX_M_PERIOD);
    _createClass(1, "USDC", USDCAddress, InterestRateType.FixedRate, SIX_M_PERIOD);
    _createClass(2, "USDT", USDTAddress, InterestRateType.FixedRate, SIX_M_PERIOD);
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

  modifier onlyBank() {
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

  function setBenchmarkInterest(uint256 _benchmarkInterest) external onlyGovernance {
    IBankData(bankDataAddress).setBenchmarkInterest(_benchmarkInterest);
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
    uint256 instant = block.timestamp;
    // here we get the current nonce
    uint256 _nowNonce = _getNonceFromDate(instant);
    uint256[] memory nonceIds = new uint256[](_classIds.length);
    IERC3475.Transaction[] memory transactions = new IERC3475.Transaction[](_classIds.length);
    for (uint256 i; i < _classIds.length; i++) {
      (address _tokenAddress, InterestRateType _interestRateType, uint256 _period) = classValues(_classIds[i]);
      // here we get the nonce for a period to add it to the current nonce
      uint256 _nonceToIssueWith = _nowNonce + _getNonceFromPeriod(_period);
      (uint256 _lastNonceCreated, ) = IDebondBond(debondBondAddress).getLastNonceCreated(_classIds[i]);
      // here we check if the nonce to issue the bond with is already created
      if (_nonceToIssueWith != _lastNonceCreated) {
        createNewNonce(_classIds[i], _nonceToIssueWith, instant);
        _lastNonceCreated = _nonceToIssueWith;
      }
      nonceIds[i] = _lastNonceCreated;

      _setTokenInterestRateSupply(_tokenAddress, _interestRateType, _amounts[i]);
      _setTokenTotalSupplyAtNonce(_tokenAddress, nonceIds[i], _tokenTotalSupply(_tokenAddress));

      IERC3475.Transaction memory transaction = IERC3475.Transaction(_classIds[i], nonceIds[i], _amounts[i]);
      transactions[i] = transaction;
    }

    IERC3475(debondBondAddress).issue(_to, transactions);
  }

  /**
   * @notice redeem ERC3475 bonds only Bank can process this action
   * @param _from the address redeeming the bonds
   * @param _classIds the requested class Ids
   * @param _nonceIds the requested nonce Ids
   * @param _amounts the amounts of bond to redeem
   */
  function redeemBonds(
    address _from,
    uint256[] memory _classIds,
    uint256[] memory _nonceIds,
    uint256[] memory _amounts
  ) external onlyBank {
    require(_classIds.length == _nonceIds.length && _classIds.length == _amounts.length);
    IERC3475.Transaction[] memory transactions = new IERC3475.Transaction[](_classIds.length);
    for (uint256 i; i < _classIds.length; i++) {
      IERC3475.Transaction memory transaction = IERC3475.Transaction(_classIds[i], _nonceIds[i], _amounts[i]);
      transactions[i] = transaction;
    }
    IERC3475(debondBondAddress).redeem(_from, transactions);
  }

  /**
   * @notice gives either the progress achieved and the progress remaining for a classId and a nonceId given
   * @param _classId class Id of the requested bond
   * @param _nonceId nonce Id of the requested bond
   * @return progressAchieved and progressRemaining
   */
  function getProgress(uint256 _classId, uint256 _nonceId) external view returns (uint256 progressAchieved, uint256 progressRemaining) {
    (address _tokenAddress, InterestRateType _interestRateType, uint256 _periodTimestamp) = classValues(_classId);
    (, uint256 _maturityDate) = nonceValues(_classId, _nonceId);
    if (_interestRateType == InterestRateType.FixedRate) {
      progressRemaining = _maturityDate <= block.timestamp ? 0 : ((_maturityDate - block.timestamp) * 100) / _periodTimestamp;
      progressAchieved = 100 - progressRemaining;
      return (progressAchieved, progressRemaining);
    }

    uint256 BsumNL = _tokenTotalSupply(_tokenAddress);
    uint256 BsumN = getTokenTotalSupplyAtNonce(_tokenAddress, _nonceId);
    uint256 BsumNInterest = BsumN + BsumN.mul(getBenchmarkInterest());

    progressRemaining = BsumNInterest < BsumNL ? 0 : 100;
    progressAchieved = 100 - progressRemaining;
  }

  /**
   * @notice update classes purchasable, only Governance can process this action
   * @param _classIdIn class Id to purchase with
   * @param _classIdOut class Id to purchase
   * @param _canPurchase set to true if it can purchase, false if not
   */
  function updateCanPurchase(
    uint256 _classIdIn,
    uint256 _classIdOut,
    bool _canPurchase
  ) external onlyGovernance {
    _updateCanPurchase(_classIdIn, _classIdOut, _canPurchase);
  }

  /**
   * @notice create a new set of metadatas, only Governance can process this action
   * @param _metadataIds metadatas Ids
   * @param _metadatas set of metadatas
   */
  function createClassMetadatas(uint256[] memory _metadataIds, IERC3475.Metadata[] memory _metadatas) external onlyGovernance {
    _createClassMetadatas(_metadataIds, _metadatas);
  }

  function _updateCanPurchase(
    uint256 classIdIn,
    uint256 classIdOut,
    bool _canPurchase
  ) private {
    IBankData(bankDataAddress).updateCanPurchase(classIdIn, classIdOut, _canPurchase);
  }

  function _createClassMetadatas(uint256[] memory metadataIds, IERC3475.Metadata[] memory metadatas) internal {
    IDebondBond(debondBondAddress).createClassMetadataBatch(metadataIds, metadatas);
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
    InterestRateType _interestRateType,
    uint256 _period
  ) private pure returns (uint256[] memory, IERC3475.Values[] memory) {
    uint256[] memory _metadataIds = new uint256[](4);
    _metadataIds[0] = symbolMetadataId;
    _metadataIds[1] = tokenAddressMetadataId;
    _metadataIds[2] = interestRateTypeMetadataId;
    _metadataIds[3] = periodMetadataId;

    IERC3475.Values[] memory _values = new IERC3475.Values[](4);
    _values[0] = IERC3475.Values(_symbol, 0, address(0), false);
    _values[1] = IERC3475.Values("", 0, _tokenAddress, false);
    _values[2] = IERC3475.Values("", uint256(_interestRateType), address(0), false);
    _values[3] = IERC3475.Values("", _period, address(0), false);
    return (_metadataIds, _values);
  }

  /**
   * @notice maps nonce values into IERC3475 Values
   * @param _issuanceDate issuance date (creation date) of the bond
   * @param _maturityDate maturity date of the bond
   * @return an array of IERC3475 Values
   */
  function mapNonceValuesFrom(uint256 _issuanceDate, uint256 _maturityDate) private pure returns (uint256[] memory, IERC3475.Values[] memory) {
    uint256[] memory _metadataIds = new uint256[](2);
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
    InterestRateType _interestRateType,
    uint256 _period
  ) external onlyGovernance {
    _createClass(_classId, _symbol, _tokenAddress, _interestRateType, _period);
  }

  function _createClass(
    uint256 classId,
    string memory symbol,
    address tokenAddress,
    InterestRateType interestRateType,
    uint256 period
  ) private {
    (uint256[] memory _metadataIds, IERC3475.Values[] memory _values) = mapClassValuesFrom(symbol, tokenAddress, interestRateType, period);
    IDebondBond(debondBondAddress).createClass(classId, _metadataIds, _values);
    _pushClassIdPerToken(tokenAddress, classId);
    _addNewClassId(classId);
    _createNonceMetadatas(classId);
    emit ClassCreated(classId, symbol, tokenAddress, interestRateType, period);
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

  function createNewNonce(
    uint256 classId,
    uint256 newNonceId,
    uint256 creationTimestamp
  ) private {
    (, , uint256 period) = classValues(classId);
    (uint256[] memory _metadataIds, IERC3475.Values[] memory _values) = mapNonceValuesFrom(creationTimestamp, creationTimestamp + period);
    IDebondBond(debondBondAddress).createNonce(classId, newNonceId, _metadataIds, _values);
    _updateLastNonce(classId, newNonceId, creationTimestamp);
  }

  function _getNonceFromDate(uint256 _date) private view returns (uint256) {
    return _getNonceFromPeriod(_date - getBaseTimestamp());
  }

  function _getNonceFromPeriod(uint256 _period) private pure returns (uint256) {
    return _period / EPOCH_24H;
  }

  function _updateLastNonce(
    uint256 _classId,
    uint256 _nonceId,
    uint256 _createdAt
  ) internal {
    IDebondBond(debondBondAddress).updateLastNonce(_classId, _nonceId, _createdAt);
  }

  function getETA(uint256 _classId, uint256 _nonceId) external view returns (uint256) {
    (address _tokenAddress, InterestRateType _interestRateType, ) = classValues(_classId);
    (, uint256 _maturityDate) = nonceValues(_classId, _nonceId);

    if (_interestRateType == InterestRateType.FixedRate) {
      return _maturityDate;
    }

    uint256 _totalSupply = _tokenTotalSupply(_tokenAddress);
    uint256 _supplyAtNonce = getTokenTotalSupplyAtNonce(_tokenAddress, _nonceId);

    (uint256 lastNonceCreated, ) = IDebondBond(debondBondAddress).getLastNonceCreated(_classId);
    uint256 liquidityFlowOver30Nonces = _supplyIssuedOnPeriod(_tokenAddress, lastNonceCreated - 30, lastNonceCreated);
    uint256 averageLiquidityInOverLast30Nonces = liquidityFlowOver30Nonces / 30;
    return DebondMath.floatingETA(_maturityDate, _supplyAtNonce, getBenchmarkInterest(), _totalSupply, EPOCH_24H, averageLiquidityInOverLast30Nonces);
  }

  /**
   * @notice get the up to date supplies for fix and float rate (contains the liquidity added in the input)
   */
  function _getSupplies(
    address _tokenAddress,
    InterestRateType _interestRateType,
    uint256 _supplyToAdd
  ) internal view returns (uint256 _fixRateSupply, uint256 _floatRateSupply) {
    _fixRateSupply = getTokenInterestRateSupply(_tokenAddress, InterestRateType.FixedRate);
    _floatRateSupply = getTokenInterestRateSupply(_tokenAddress, InterestRateType.FloatingRate);

    // we had the client amount to the according bond balance to calculate interest rate after deposit
    if (_supplyToAdd > 0 && _interestRateType == InterestRateType.FixedRate) {
      _fixRateSupply += _supplyToAdd;
    }
    if (_supplyToAdd > 0 && _interestRateType == InterestRateType.FloatingRate) {
      _floatRateSupply += _supplyToAdd;
    }
  }

  /**
   * @notice gets all the class values for a given class Id
   * @param _classId the requested class Id
   * @return _tokenAddress _interestRateType _periodTimestamp (the class values)
   */
  function classValues(uint256 _classId)
    public
    view
    returns (
      address _tokenAddress,
      InterestRateType _interestRateType,
      uint256 _periodTimestamp
    )
  {
    _tokenAddress = (IERC3475(debondBondAddress).classValues(_classId, tokenAddressMetadataId)).addressValue;
    uint256 interestType = (IERC3475(debondBondAddress).classValues(_classId, interestRateTypeMetadataId)).uintValue;
    _interestRateType = interestType == 0 ? InterestRateType.FixedRate : InterestRateType.FloatingRate;
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

  function _tokenTotalSupply(address tokenAddress) internal view returns (uint256) {
    return getTokenInterestRateSupply(tokenAddress, InterestRateType.FixedRate) + getTokenInterestRateSupply(tokenAddress, InterestRateType.FloatingRate);
  }

  function _supplyIssuedOnPeriod(
    address _tokenAddress,
    uint256 _fromNonceId,
    uint256 _toNonceId
  ) internal view returns (uint256 supply) {
    require(_fromNonceId <= _toNonceId, "DebondBond Error: Invalid Input");
    // we loop on every nonces required of every token's classes
    uint256[] memory _classIdsPerTokenAddress = getClassIdsFromTokenAddress(_tokenAddress);
    for (uint256 i = _fromNonceId; i <= _toNonceId; i++) {
      for (uint256 j = 0; j < _classIdsPerTokenAddress.length; j++) {
        supply += (IDebondBond(debondBondAddress).activeSupply(_classIdsPerTokenAddress[j], i) +
          IDebondBond(debondBondAddress).redeemedSupply(_classIdsPerTokenAddress[j], i));
      }
    }
  }

  function _setTokenInterestRateSupply(
    address tokenAddress,
    InterestRateType interestRateType,
    uint256 amount
  ) internal {
    IBankData(bankDataAddress).setTokenInterestRateSupply(tokenAddress, interestRateType, amount);
  }

  function _setTokenTotalSupplyAtNonce(
    address tokenAddress,
    uint256 nonceId,
    uint256 amount
  ) internal {
    IBankData(bankDataAddress).setTokenTotalSupplyAtNonce(tokenAddress, nonceId, amount);
  }

  function _pushClassIdPerToken(address tokenAddress, uint256 classId) private {
    IBankData(bankDataAddress).pushClassIdPerTokenAddress(tokenAddress, classId);
  }

  function _addNewClassId(uint256 classId) private {
    IBankData(bankDataAddress).addNewClassId(classId);
  }

  function getBaseTimestamp() public view returns (uint256) {
    return IBankData(bankDataAddress).getBaseTimestamp();
  }

  function getClasses() external view returns (uint256[] memory) {
    return IBankData(bankDataAddress).getClasses();
  }

  function getTokenInterestRateSupply(address tokenAddress, InterestRateType interestRateType) public view returns (uint256) {
    return IBankData(bankDataAddress).getTokenInterestRateSupply(tokenAddress, interestRateType);
  }

  function getClassIdsFromTokenAddress(address tokenAddress) public view returns (uint256[] memory) {
    return IBankData(bankDataAddress).getClassIdsFromTokenAddress(tokenAddress);
  }

  function getTokenTotalSupplyAtNonce(address tokenAddress, uint256 nonceId) public view returns (uint256) {
    return IBankData(bankDataAddress).getTokenTotalSupplyAtNonce(tokenAddress, nonceId);
  }

  function getBenchmarkInterest() public view returns (uint256) {
    return IBankData(bankDataAddress).getBenchmarkInterest();
  }

  function getInterestRate(uint256 classId, uint256 amount) external view returns (uint256 rate) {
    (address tokenAddress, InterestRateType interestRateType, ) = classValues(classId);
    (uint256 fixRateSupply, uint256 floatRateSupply) = _getSupplies(tokenAddress, interestRateType, amount);

    uint256 fixRate;
    uint256 floatRate;
    uint256 oneTokenToUSDValue = _convertTokenToUSDC(1 ether, tokenAddress);
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
    } else {
      amountUsd = IOracle(oracleAddress).estimateAmountOut(_tokenAddress, _amountToken, USDCAddress, 60) * 1e12;
    }
  }

  function _getCalculatedRate(uint256 fixRateSupply, uint256 floatRateSupply) private view returns (uint256 fixedRate, uint256 floatingRate) {
    uint256 benchmarkInterest = getBenchmarkInterest();
    floatingRate = DebondMath.floatingInterestRate(fixRateSupply, floatRateSupply, benchmarkInterest);
    fixedRate = 2 * benchmarkInterest - floatingRate;
  }

  function _getDefaultRate() private view returns (uint256 fixRate, uint256 floatRate) {
    uint256 benchmarkInterest = getBenchmarkInterest();
    fixRate = (2 * benchmarkInterest) / 3;
    floatRate = 2 * fixRate;
  }
}
