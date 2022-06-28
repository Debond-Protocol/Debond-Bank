// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "debond-governance-contracts/utils/GovernanceOwnable.sol";
import "debond-erc3475-contracts/interfaces/IDebondBond.sol";
import "debond-erc3475-contracts/interfaces/IRedeemableBondCalculator.sol";
import "erc3475/IERC3475.sol";
import "./libraries/DebondMath.sol";
import "./interfaces/IBankData.sol";


abstract contract BankBondManager is IRedeemableBondCalculator, GovernanceOwnable {

    using DebondMath for uint256;

    enum InterestRateType {FixedRate, FloatingRate}

    address debondBondAddress;
    address bankData;

    uint public constant EPOCH = 30;


    constructor(
        address _governanceAddress,
        address _debondBondAddress,
        address _bankData
    ) GovernanceOwnable(_governanceAddress) {
        debondBondAddress = _debondBondAddress;
        bankData = _bankData;
    }

    function createClass(uint256 classId, string memory _symbol, InterestRateType interestRateType, address tokenAddress, uint256 periodTimestamp) external onlyGovernance {
        _createClass(classId, _symbol, interestRateType, tokenAddress, periodTimestamp);
    }

    function _createClass(uint256 classId, string memory _symbol, InterestRateType interestRateType, address tokenAddress, uint256 periodTimestamp) internal {
        require(!IDebondBond(debondBondAddress).classExists(classId), "ERC3475: cannot create a class that already exists");
        uint interestRateTypeValue = uint256(interestRateType);
        if (!tokenAddressExist(tokenAddress)) {
            incrementTokenAddressCount();
            uint _tokenAddressCount = tokenAddressCount();
            setBondValueFromTokenAddress(tokenAddress, _tokenAddressCount);
            setTokenAddressWithBondValue(_tokenAddressCount, tokenAddress);
            setTokenAddressExists(tokenAddress, true);
        }
        uint tokenAddressValue = getBondValueFromTokenAddress(tokenAddress);

        uint256[] memory values = new uint[](3);
        values[0] = tokenAddressValue;
        values[1] = interestRateTypeValue;
        values[2] = periodTimestamp;
        IDebondBond(debondBondAddress).createClass(classId, _symbol, values);
        pushClassIdPerToken(tokenAddress, classId);
        addNewClassId(classId);
    }

    function issueBonds(address to, uint256 classId, uint256 amount) internal {
        uint instant = block.timestamp;
        uint _nowNonce = getNonceFromDate(block.timestamp);
        (,, uint period) = classValues(classId);
        uint _nonceToCreate = _nowNonce + getNonceFromPeriod(period);
        (uint _lastNonceCreated,) = IDebondBond(debondBondAddress).getLastNonceCreated(classId);
        if (_nonceToCreate != _lastNonceCreated) {
            createNewNonce(classId, _nonceToCreate, instant);
            (_lastNonceCreated,) = IDebondBond(debondBondAddress).getLastNonceCreated(classId);
        }
        _issue(to, classId, _lastNonceCreated, amount);
    }

    function createNewNonce(uint classId, uint newNonceId, uint creationTimestamp) private {
        uint _newNonceId = newNonceId;
        (,, uint period) = classValues(classId);
        _createNonce(classId, _newNonceId, creationTimestamp + period);
        _updateLastNonce(classId, _newNonceId, creationTimestamp);
    }

    function _issue(address to, uint256 classId, uint256 nonceId, uint256 amount) internal {
        (address tokenAddress, InterestRateType interestRateType,) = classValues(classId);
        _issueERC3475(to, classId, nonceId, amount);
        setTokenInterestRateSupply(tokenAddress, interestRateType, amount);
        setTokenTotalSupplyAtNonce(tokenAddress, nonceId, _tokenTotalSupply(tokenAddress));

    }

    function getNonceFromDate(uint256 date) public view returns (uint256) {
        return getNonceFromPeriod(date - getBaseTimestamp());
    }

    function getNonceFromPeriod(uint256 period) private pure returns (uint256) {
        return period / EPOCH;
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

    function _createNonce(uint256 classId, uint256 nonceId, uint256 _maturityDate) internal {
        uint256[] memory values = new uint[](2);
        values[0] = block.timestamp;
        values[1] = _maturityDate;
        IDebondBond(debondBondAddress).createNonce(classId, nonceId, values);
    }

    function _updateLastNonce(uint classId, uint nonceId, uint createdAt) internal {
        IDebondBond(debondBondAddress).updateLastNonce(classId, nonceId, createdAt);
    }
    // READS

    //TODO TEST
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
        uint[] memory _classValues = IERC3475(debondBondAddress).classValues(classId);

        _interestRateType = _classValues[1] == 0 ? InterestRateType.FixedRate : InterestRateType.FloatingRate;
        _tokenAddress = getTokenAddressFromBondValue(_classValues[0]);
        _periodTimestamp = _classValues[2];
    }

    function nonceValues(uint256 classId, uint256 nonceId) public view returns (uint256 _issuanceDate, uint256 _maturityDate) {
        uint[] memory _nonceValues = IERC3475(debondBondAddress).nonceValues(classId, nonceId);
        _issuanceDate = _nonceValues[0];
        _maturityDate = _nonceValues[1];
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
                supply += (IERC3475(debondBondAddress).activeSupply(_classIdsPerTokenAddress[j], i) + IERC3475(debondBondAddress).redeemedSupply(_classIdsPerTokenAddress[j], i));
            }
        }
    }

    function _issueERC3475(address to, uint classId, uint nonceId, uint amount) internal {
        IERC3475.Transaction[] memory transactions = new IERC3475.Transaction[](1);
        IERC3475.Transaction memory transaction = IERC3475.Transaction(classId, nonceId, amount);
        transactions[0] = transaction;
        IERC3475(debondBondAddress).issue(to, transactions);
    }

    function _redeemERC3475(address from, uint classId, uint nonceId, uint amount) internal {
        IERC3475.Transaction[] memory transactions = new IERC3475.Transaction[](1);
        IERC3475.Transaction memory transaction = IERC3475.Transaction(classId, nonceId, amount);
        transactions[0] = transaction;
        IERC3475(debondBondAddress).redeem(from, transactions);
    }

    function setTokenInterestRateSupply(address tokenAddress, BankBondManager.InterestRateType interestRateType, uint amount) internal {
        IBankData(bankData).setTokenInterestRateSupply(tokenAddress, interestRateType, amount);
    }

    function setTokenTotalSupplyAtNonce(address tokenAddress, uint nonceId, uint amount) internal {
        IBankData(bankData).setTokenTotalSupplyAtNonce(tokenAddress, nonceId, amount);
    }

    function pushClassIdPerToken(address tokenAddress, uint classId) internal {
        IBankData(bankData).pushClassIdPerToken(tokenAddress, classId);
    }

    function addNewClassId(uint classId) internal {
        IBankData(bankData).addNewClassId(classId);
    }

    function setTokenAddressWithBondValue(uint value, address tokenAddress) internal {
        IBankData(bankData).setTokenAddressWithBondValue(value, tokenAddress);
    }

    function setBondValueFromTokenAddress(address tokenAddress, uint value) internal {
        IBankData(bankData).setBondValueFromTokenAddress(tokenAddress, value);
    }

    function setTokenAddressExists(address tokenAddress, bool exist) internal {
        IBankData(bankData).setTokenAddressExists(tokenAddress, exist);
    }

    function incrementTokenAddressCount() internal {
        IBankData(bankData).incrementTokenAddressCount();
    }

    function setBenchmarkInterest(uint _benchmarkInterest) internal {
        IBankData(bankData).setBenchmarkInterest(_benchmarkInterest);
    }

    function getBaseTimestamp() public view returns (uint) {
        return IBankData(bankData).getBaseTimestamp();
    }

    function getClasses() public view returns (uint[] memory) {
        return IBankData(bankData).getClasses();
    }

    function getTokenInterestRateSupply(address tokenAddress, BankBondManager.InterestRateType interestRateType) public view returns (uint) {
        return IBankData(bankData).getTokenInterestRateSupply(tokenAddress, interestRateType);
    }

    function getClassIdsFromTokenAddress(address tokenAddress) public view returns (uint[] memory) {
        return IBankData(bankData).getClassIdsFromTokenAddress(tokenAddress);
    }

    function getTokenAddressFromBondValue(uint value) public view returns (address) {
        return IBankData(bankData).getTokenAddressFromBondValue(value);
    }

    function getTokenTotalSupplyAtNonce(address tokenAddress, uint nonceId) public view returns (uint) {
        return IBankData(bankData).getTokenTotalSupplyAtNonce(tokenAddress, nonceId);
    }

    function getBondValueFromTokenAddress(address tokenAddress) public view returns (uint) {
        return IBankData(bankData).getBondValueFromTokenAddress(tokenAddress);
    }

    function tokenAddressExist(address tokenAddress) public view returns (bool) {
        return IBankData(bankData).tokenAddressExist(tokenAddress);
    }

    function tokenAddressCount() public view returns (uint) {
        return IBankData(bankData).tokenAddressCount();
    }

    function getBenchmarkInterest() public view returns (uint) {
        return IBankData(bankData).getBenchmarkInterest();
    }


}
