// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "debond-governance-contracts/utils/GovernanceOwnable.sol";
import "debond-erc3475-contracts/interfaces/IDebondBond.sol";
import "debond-erc3475-contracts/interfaces/IRedeemableBondCalculator.sol";
import "erc3475/IERC3475.sol";
import "./libraries/DebondMath.sol";


abstract contract BankBondManager is IRedeemableBondCalculator, GovernanceOwnable {

    using DebondMath for uint256;

    //    uint public constant BASE_TIMESTAMP = 1646089200; // 2022-03-01 00:00
    uint public BASE_TIMESTAMP;
    uint public constant EPOCH = 30; // every 24h we crate a new nonce.
    uint public constant BENCHMARK_RATE_DECIMAL_18 = 5 * 10 ** 16;


    enum InterestRateType {FixedRate, FloatingRate}

    address debondBondAddress;

    mapping(address => mapping(InterestRateType => uint256)) public tokenRateTypeTotalSupply; // needed for interest rate calculation also
    mapping(address => mapping(uint256 => uint256)) public tokenTotalSupplyAtNonce;
    mapping(address => uint256[]) public classIdsPerTokenAddress;
    mapping(uint256 => mapping(uint256 => bool)) public canPurchase; // can u get second input classId token from providing first input classId token

    mapping(uint256 => address) public fromBondValueToTokenAddress;
    mapping(address => uint256) public tokenAddressValueMapping;

    mapping(address => bool) public tokenAddressExist;
    uint256 public tokenAddressCount;

    constructor(
        address _governanceAddress,
        address _debondBondAddress,
        uint256 baseTimeStamp
    ) GovernanceOwnable(_governanceAddress) {
        debondBondAddress = _debondBondAddress;
        BASE_TIMESTAMP = baseTimeStamp;
    }

    function createClass(uint256 classId, string memory _symbol, InterestRateType interestRateType, address tokenAddress, uint256 periodTimestamp) external onlyGovernance {
        _createClass(classId, _symbol, interestRateType, tokenAddress, periodTimestamp);
    }

    function _createClass(uint256 classId, string memory _symbol, InterestRateType interestRateType, address tokenAddress, uint256 periodTimestamp) internal {
        require(!IDebondBond(debondBondAddress).classExists(classId), "ERC3475: cannot create a class that already exists");
        uint interestRateTypeValue = uint256(interestRateType);
        if (!tokenAddressExist[tokenAddress]) {
            ++tokenAddressCount;
            tokenAddressValueMapping[tokenAddress] = tokenAddressCount;
            fromBondValueToTokenAddress[tokenAddressValueMapping[tokenAddress]] = tokenAddress;
            tokenAddressExist[tokenAddress] = true;
        }
        uint tokenAddressValue = tokenAddressValueMapping[tokenAddress];

        uint256[] memory values = new uint[](3);
        values[0] = tokenAddressValue;
        values[1] = interestRateTypeValue;
        values[2] = periodTimestamp;
        IDebondBond(debondBondAddress).createClass(classId, _symbol, values);
        classIdsPerTokenAddress[tokenAddress].push(classId);
    }

    function updateCanPurchase(uint classIdIn, uint classIdOut, bool _canPurchase) external onlyGovernance {
        _updateCanPurchase(classIdIn, classIdOut, _canPurchase);
    }

    function _updateCanPurchase(uint classIdIn, uint classIdOut, bool _canPurchase) internal {
        canPurchase[classIdIn][classIdOut] = _canPurchase;
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
        tokenRateTypeTotalSupply[tokenAddress][interestRateType] += amount;
        tokenTotalSupplyAtNonce[tokenAddress][nonceId] = _tokenTotalSupply(tokenAddress);

    }

    function getNonceFromDate(uint256 date) public view returns (uint256) {
        return getNonceFromPeriod(date - BASE_TIMESTAMP);
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
        uint BsumN = tokenTotalSupplyAtNonce[_tokenAddress][nonceId];
        uint BsumNInterest = BsumN + BsumN.mul(BENCHMARK_RATE_DECIMAL_18);

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
        uint BsumN = tokenTotalSupplyAtNonce[_tokenAddress][nonceId];

        (uint lastNonceCreated,) = IDebondBond(debondBondAddress).getLastNonceCreated(classId);
        uint liquidityFlowOver30Nonces = _supplyIssuedOnPeriod(_tokenAddress, lastNonceCreated - 30, lastNonceCreated);
        uint Umonth = liquidityFlowOver30Nonces / 30;
        return DebondMath.floatingETA(_maturityDate, BsumN, BENCHMARK_RATE_DECIMAL_18, BsumNL, EPOCH, Umonth);
    }


    function interestRateByBuying(
        uint classId,
        uint amount
    ) internal view returns (uint fixRate, uint floatRate) {

        (address debondTokenAddress, InterestRateType interestRateType,) = classValues(classId);
        (uint fixRateSupply, uint floatRateSupply) = getRateSupplies(debondTokenAddress, amount, interestRateType);

        (fixRate, floatRate) = _getCalculatedRate(fixRateSupply, floatRateSupply);

    }

    function interestRateByStaking(
        uint classId,
        uint amount
    ) internal view returns (uint fixRate, uint floatRate) {
        (address purchaseTokenAddress, InterestRateType interestRateType,) = classValues(classId);
        (uint fixRateSupply, uint floatRateSupply) = getRateSupplies(purchaseTokenAddress, amount, interestRateType);

        (fixRate, floatRate) = _getCalculatedRate(fixRateSupply, floatRateSupply);
    }

    function getRateSupplies(address tokenAddress, uint tokenAmount, InterestRateType interestRateType) private view returns (uint fixRateSupply, uint floatRateSupply) {
        fixRateSupply = tokenRateTypeTotalSupply[tokenAddress][InterestRateType.FixedRate];
        floatRateSupply = tokenRateTypeTotalSupply[tokenAddress][InterestRateType.FloatingRate];

        // we had the client amount to the according bond balance to calculate interest rate after deposit
        if (tokenAmount > 0 && interestRateType == InterestRateType.FixedRate) {
            fixRateSupply += tokenAmount;
        }
        if (tokenAmount > 0 && interestRateType == InterestRateType.FloatingRate) {
            floatRateSupply += tokenAmount;
        }
    }

    function _getCalculatedRate(uint fixRateSupply, uint floatRateSupply) private pure returns (uint fixRate, uint floatRate) {
        // TODO Need to define a min liquidity
        if (fixRateSupply == 0 || floatRateSupply == 0) {
            fixRate = 2 * BENCHMARK_RATE_DECIMAL_18 / 3;
            floatRate = 2 * fixRate;
        } else {
            (fixRate, floatRate) = _interestRate(fixRateSupply, floatRateSupply, BENCHMARK_RATE_DECIMAL_18);
        }
    }

    //TODO TEST
    function _interestRate(uint fixRateSupply, uint floatRateSupply, uint benchmarkInterest) private pure returns (uint fixedRate, uint floatingRate) {
        floatingRate = DebondMath.floatingInterestRate(fixRateSupply, floatRateSupply, benchmarkInterest);
        fixedRate = 2 * benchmarkInterest - floatingRate;
    }


    function classValues(uint256 classId) public view returns (address _tokenAddress, InterestRateType _interestRateType, uint256 _periodTimestamp) {
        uint[] memory _classValues = IERC3475(debondBondAddress).classValues(classId);

        _interestRateType = _classValues[1] == 0 ? InterestRateType.FixedRate : InterestRateType.FloatingRate;
        _tokenAddress = fromBondValueToTokenAddress[_classValues[0]];
        _periodTimestamp = _classValues[2];
    }

    function nonceValues(uint256 classId, uint256 nonceId) public view returns (uint256 _issuanceDate, uint256 _maturityDate) {
        uint[] memory _nonceValues = IERC3475(debondBondAddress).nonceValues(classId, nonceId);
        _issuanceDate = _nonceValues[0];
        _maturityDate = _nonceValues[1];
    }

    function _tokenTotalSupply(address tokenAddress) internal view returns (uint256) {
        return tokenRateTypeTotalSupply[tokenAddress][InterestRateType.FloatingRate] + tokenRateTypeTotalSupply[tokenAddress][InterestRateType.FixedRate];
    }

    function _supplyIssuedOnPeriod(address tokenAddress, uint256 fromNonceId, uint256 toNonceId) internal view returns (uint256 supply) {
        require(fromNonceId <= toNonceId, "DebondBond Error: Invalid Input");
        // we loop on every nonces required of every token's classes
        for (uint i = fromNonceId; i <= toNonceId; i++) {
            for (uint j = 0; j < classIdsPerTokenAddress[tokenAddress].length; j++) {
                supply += (IERC3475(debondBondAddress).activeSupply(classIdsPerTokenAddress[tokenAddress][j], i) + IERC3475(debondBondAddress).redeemedSupply(classIdsPerTokenAddress[tokenAddress][j], i));
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


}
