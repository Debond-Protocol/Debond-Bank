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

    error Deadline(uint deadline, uint blockTimeStamp);
    error PairNotAllowed();
    error RateNotHighEnough(uint currentRate, uint minRate);
    error INSUFFICIENT_AMOUNT(uint amount);
    error INSUFFICIENT_LIQUIDITY(uint liquidity);
    error WrongTokenAddress(address tokenAddress);

import "@debond-protocol/debond-token-contracts/interfaces/IDebondToken.sol";
import "@debond-protocol/debond-oracle-contracts/interfaces/IOracle.sol";
import "@debond-protocol/debond-governance-contracts/utils/ExecutableOwnable.sol";
import "@debond-protocol/debond-erc3475-contracts/interfaces/ILiquidityRedeemable.sol";
import "./interfaces/IWETH.sol";
import "./BankBondManager.sol";
import "./libraries/DebondMath.sol";
import "./interfaces/IBankStorage.sol";
import "./BankRouter.sol";
import "./interfaces/IBank.sol";



//todo : grammaire( _ internal, majuscules etc), commentaires

contract Bank is IBank, BankRouter, ExecutableOwnable, ILiquidityRedeemable {

    using DebondMath for uint256;

    address public bankStorageAddress;
    address public bondManagerAddress;
    address public debondBondAddress;
    enum PurchaseMethod {Buying, Staking}



    constructor(
        address _executableAddress,
        address _APMAddress,
        address _bankBondManagerAddress,
        address _bankDataAddress,
        address _DBITAddress,
        address _DGOVAddress,
        address _USDCAddress,
        address _WETHAddress,
        address _oracleAddress,
        address _debondBondAddress
    ) ExecutableOwnable(_executableAddress) BankRouter(_APMAddress, _DBITAddress, _DGOVAddress, _USDCAddress, _WETHAddress, _oracleAddress) {
        bondManagerAddress = _bankBondManagerAddress;
        bankStorageAddress = _bankDataAddress;
        debondBondAddress = _debondBondAddress;
    }

    receive() external payable {}

    modifier ensure(uint deadline) {
        if (deadline >= block.timestamp) {
            revert Deadline(deadline, block.timestamp);
        }
        _;
    }

    function updateBondManagerAddress(
        address _bondManagerAddress
    ) external onlyExecutable {
        bondManagerAddress = _bondManagerAddress;
    }

    function updateOracleAddress(
        address _oracleAddress
    ) external onlyExecutable {
        oracleAddress = _oracleAddress;
    }

    function setApmAddress(
        address _apmAddress
    ) external onlyExecutable {
        apmAddress = _apmAddress;
    }

    function setBankStorageAddress(
        address _bankStorageAddress
    ) external onlyExecutable {
        bankStorageAddress = _bankStorageAddress;
    }

    function setDBITAddress(
        address _DBITAddress
    ) external onlyExecutable {
        DBITAddress = _DBITAddress;
    }

    function setDGOVAddress(
        address _DGOVAddress
    ) external onlyExecutable {
        DGOVAddress = _DGOVAddress;
    }

    function setDebondBondAddress(
        address _debondBondAddress
    ) external onlyExecutable {
        debondBondAddress = _debondBondAddress;
    }


    /**
    * @notice return if classIdIn can purchase classIdOut
    * @param _classIdIn the classId to purchase with
    * @param _classIdOut the classId to purchase
    * @return true if it can purchased, false if not
    */
    function canPurchase(
        uint _classIdIn,
        uint _classIdOut
    ) public view returns (bool) {
        return IBankStorage(bankStorageAddress).canPurchase(_classIdIn, _classIdOut);
    }


    /**
    * @notice user purchasing DBIT bonds by staking his chosen tokens
    * @param _purchaseClassId the classId of the token to purchase with
    * @param _dbitClassId DBIT classId
    * @param _purchaseTokenAmount amount of the user's token
    * @param _minRate min interest rate desired
    * @param _deadline deadline fixed for the transaction to execute
    * @param _to address to interact with (transferring ERC20 from, ERC3475 tokens to)
    */
    function purchaseDBITBondsByStakingTokens(
        uint _purchaseClassId,
        uint _dbitClassId,
        uint _purchaseTokenAmount,
        uint _minRate,
        uint _deadline,
        address _to
    ) external ensure(_deadline) {
        if (!canPurchase(_purchaseClassId, _dbitClassId)) {
            revert PairNotAllowed();
        }
        (address debondTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(_dbitClassId);
        if (debondTokenAddress != DBITAddress) {
            revert WrongTokenAddress(debondTokenAddress);
        }
        (address purchaseTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(_purchaseClassId);
        if (purchaseTokenAddress == DBITAddress || purchaseTokenAddress == DGOVAddress) {
            revert WrongTokenAddress(purchaseTokenAddress);
        }
        uint _interestRate = interestRate(_purchaseClassId, _dbitClassId, _purchaseTokenAmount, PurchaseMethod.Staking);
        if (_interestRate < _minRate) {
            revert RateNotHighEnough(_interestRate, _minRate);
        }
        _addLiquidityDbitPair(_to, purchaseTokenAddress, _purchaseTokenAmount);
        _issuingProcessStaking(_purchaseClassId, _purchaseTokenAmount, purchaseTokenAddress, _dbitClassId, _interestRate, _to);

    }


    /**
    * @notice user purchasing DGOV bonds by staking his DBIT tokens
    * @param _dbitClassId DBIT classId
    * @param _dgovClassId DGOV classId
    * @param _dbitTokenAmount user's DBIT amount
    * @param _minRate min interest rate desired
    * @param _deadline deadline fixed for the transaction to execute
    * @param _to address to interact with (transferring tokens from, ERC3475 tokens to)
    */
    function purchaseDGOVBondsByStakingDBIT(
        uint _dbitClassId,
        uint _dgovClassId,
        uint _dbitTokenAmount,
        uint _minRate,
        uint _deadline,
        address _to
    ) external ensure(_deadline) {
        if (!canPurchase(_dbitClassId, _dgovClassId)) {
            revert PairNotAllowed();
        }
        (address purchaseTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(_dbitClassId);
        if (purchaseTokenAddress != DBITAddress) {
            revert WrongTokenAddress(purchaseTokenAddress);
        }
        (address debondTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(_dgovClassId);
        if (debondTokenAddress != DGOVAddress) {
            revert WrongTokenAddress(debondTokenAddress);
        }
        uint _interestRate = interestRate(_dbitClassId, _dgovClassId, _dbitTokenAmount, PurchaseMethod.Staking);
        if (_interestRate < _minRate) {
            revert RateNotHighEnough(_interestRate, _minRate);
        }
        _addLiquidityDbitDgov(_to, _dbitTokenAmount);
        _issuingProcessStaking(_dbitClassId, _dbitTokenAmount, DBITAddress, _dgovClassId, _interestRate, _to);
    }

    /**
    * @notice user purchasing DGOV bonds by staking his chosen tokens
    * @param _purchaseClassId the classId of the token to stake
    * @param _dgovClassId DGOV classId
    * @param _purchaseTokenAmount amount of the user's token
    * @param _minRate min interest rate desired
    * @param _deadline deadline fixed for the transaction to execute
    * @param _to address to interact with (transferring tokens from, ERC3475 tokens to)
    */
    function purchaseDGOVBondsByStakingTokens(
        uint _purchaseClassId,
        uint _dgovClassId,
        uint _purchaseTokenAmount,
        uint _minRate,
        uint _deadline,
        address _to
    ) external ensure(_deadline) {
        if (!canPurchase(_purchaseClassId, _dgovClassId)) {
            revert PairNotAllowed();
        }
        (address debondTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(_dgovClassId);
        if (debondTokenAddress != DGOVAddress) {
            revert WrongTokenAddress(debondTokenAddress);
        }
        (address purchaseTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(_purchaseClassId);
        if (purchaseTokenAddress == DBITAddress || purchaseTokenAddress == DGOVAddress) {
            revert WrongTokenAddress(purchaseTokenAddress);
        }
        uint _interestRate = interestRate(_purchaseClassId, _dgovClassId, _purchaseTokenAmount, PurchaseMethod.Staking);
        if (_interestRate < _minRate) {
            revert RateNotHighEnough(_interestRate, _minRate);
        }
        _addLiquidityDgovPair(_to, purchaseTokenAddress, _purchaseTokenAmount);
        _issuingProcessStaking(_purchaseClassId, _purchaseTokenAmount, purchaseTokenAddress, _dgovClassId, _interestRate, _to);
    }

    /**
    * @notice user purchasing DBIT bonds by exchanging his chosen tokens
    * @param _purchaseClassId the classId of the token to purchase with
    * @param _dbitClassId DBIT classId
    * @param _purchaseTokenAmount amount of the user's token
    * @param _minRate min interest rate desired
    * @param _deadline deadline fixed for the transaction to execute
    * @param _to address to interact with (transferring tokens from, ERC3475 tokens to)
    */
    function buyDBITBondsWithTokens(//else is not eth not dbit not dgov
        uint _purchaseClassId,
        uint _dbitClassId,
        uint _purchaseTokenAmount,
        uint _minRate,
        uint _deadline,
        address _to
    ) external ensure(_deadline) {
        if (!canPurchase(_purchaseClassId, _dbitClassId)) {
            revert PairNotAllowed();
        }
        (address _debondTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(_dbitClassId);
        if (_debondTokenAddress != DBITAddress) {
            revert WrongTokenAddress(_debondTokenAddress);
        }
        (address _purchaseTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(_purchaseClassId);
        if (_purchaseTokenAddress == DBITAddress || _purchaseTokenAddress == DGOVAddress || _purchaseTokenAddress == WETHAddress) {
            revert WrongTokenAddress(_purchaseTokenAddress);
        }
        uint _interestRate = interestRate(_purchaseClassId, _dbitClassId, _purchaseTokenAmount, PurchaseMethod.Buying);
        if (_interestRate < _minRate) {
            revert RateNotHighEnough(_interestRate, _minRate);
        }
        _addLiquidityDbitPair(_to, _purchaseTokenAddress, _purchaseTokenAmount);
        _issuingProcessBuying(_purchaseTokenAmount, _purchaseTokenAddress, _dbitClassId, _interestRate, _to);
    }


    /**
    * @notice user purchasing DGOV bonds by exchanging his DBIT tokens
    * @param _dbitClassId DBIT classId
    * @param _dgovClassId DGOV classId
    * @param _dbitAmount amount of the user's DBIT
    * @param _minRate min interest rate desired
    * @param _deadline deadline fixed for the transaction to execute
    * @param _to address to interact with (transferring tokens from, ERC3475 tokens to)
    */
    function buyDGOVBondsWithDBIT(
        uint _dbitClassId,
        uint _dgovClassId,
        uint _dbitAmount,
        uint _minRate,
        uint _deadline,
        address _to
    ) external ensure(_deadline) {
        if (!canPurchase(_dbitClassId, _dgovClassId)) {
            revert PairNotAllowed();
        }

        (address _purchaseTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(_dbitClassId);
        if (_purchaseTokenAddress != DBITAddress) {
            revert WrongTokenAddress(_purchaseTokenAddress);
        }
        (address _debondTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(_dgovClassId);
        if (_debondTokenAddress != DGOVAddress) {
            revert WrongTokenAddress(_debondTokenAddress);
        }
        uint _interestRate = interestRate(_dbitClassId, _dgovClassId, _dbitAmount, PurchaseMethod.Buying);
        if (_interestRate < _minRate) {
            revert RateNotHighEnough(_interestRate, _minRate);
        }
        _addLiquidityDbitDgov(_to, _dbitAmount);
        _issuingProcessBuying(_dbitAmount, DBITAddress, _dgovClassId, _interestRate, _to);
    }

    /**
    * @notice user purchasing DGOV bonds by exchanging his tokens
    * @param _purchaseClassId the classId of the token to purchase with
    * @param _dgovClassId DGOV classId
    * @param _purchaseTokenAmount amount of the user's DBIT
    * @param _minRate min interest rate desired
    * @param _deadline deadline fixed for the transaction to execute
    * @param _to address to interact with (transferring tokens from, ERC3475 tokens to)
    */
    function buyDGOVBondsWithTokens(
        uint _purchaseClassId,
        uint _dgovClassId,
        uint _purchaseTokenAmount,
        uint _minRate,
        uint _deadline,
        address _to
    ) external ensure(_deadline) {
        if (!canPurchase(_purchaseClassId, _dgovClassId)) {
            revert PairNotAllowed();
        }
        (address purchaseTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(_purchaseClassId);
        if (purchaseTokenAddress == DBITAddress || purchaseTokenAddress == DGOVAddress) {
            revert WrongTokenAddress(purchaseTokenAddress);
        }
        (address debondTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(_dgovClassId);
        if (debondTokenAddress != DGOVAddress) {
            revert WrongTokenAddress(debondTokenAddress);
        }
        uint _interestRate = interestRate(_purchaseClassId, _dgovClassId, _purchaseTokenAmount, PurchaseMethod.Buying);
        if (_interestRate < _minRate) {
            revert RateNotHighEnough(_interestRate, _minRate);
        }
        _addLiquidityDgovPair(_to, purchaseTokenAddress, _purchaseTokenAmount);
        _issuingProcessBuying(_purchaseTokenAmount, purchaseTokenAddress, _dgovClassId, _interestRate, _to);
    }


    /**
    * @notice user purchasing DBIT bonds by staking ETH
    * @param _wethClassId WETH classId
    * @param _dbitClassId DBIT classId
    * @param _minRate min interest rate desired
    * @param _deadline deadline fixed for the transaction to execute
    * @param _to address to interact with (transferring tokens from, ERC3475 tokens to)
    */
    function purchaseDBITBondsByStakingETH(
        uint _wethClassId,
        uint _dbitClassId,
        uint _minRate,
        uint _deadline,
        address _to
    ) external payable ensure(_deadline) {
        if (!canPurchase(_wethClassId, _dbitClassId)) {
            revert PairNotAllowed();
        }
        (address purchaseTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(_wethClassId);
        if (purchaseTokenAddress != WETHAddress) {
            revert WrongTokenAddress(purchaseTokenAddress);
        }
        (address debondTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(_dbitClassId);
        if (debondTokenAddress != DBITAddress) {
            revert WrongTokenAddress(debondTokenAddress);
        }
        uint purchaseTokenAmount = msg.value;
        uint _interestRate = interestRate(_wethClassId, _dbitClassId, purchaseTokenAmount, PurchaseMethod.Staking);
        if (_interestRate < _minRate) {
            revert RateNotHighEnough(_interestRate, _minRate);
        }
        IWETH(WETHAddress).deposit{value : purchaseTokenAmount}();
        _addLiquidityDbitETHPair(purchaseTokenAmount);

        _issuingProcessStaking(_wethClassId, purchaseTokenAmount, purchaseTokenAddress, _dbitClassId, _interestRate, _to);
    }

    /**
    * @notice user purchasing DGOV bonds by staking ETH
    * @param _wethClassId WETH classId
    * @param _dgovClassId DGOV classId
    * @param _minRate min interest rate desired
    * @param _deadline deadline fixed for the transaction to execute
    * @param _to address to interact with (transferring tokens from, ERC3475 tokens to)
    */
    function purchaseDGOVBondsByStakingETH(
        uint _wethClassId,
        uint _dgovClassId,
        uint _minRate,
        uint _deadline,
        address _to
    ) external payable ensure(_deadline) {
        if (!canPurchase(_wethClassId, _dgovClassId)) {
            revert PairNotAllowed();
        }
        (address purchaseTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(_wethClassId);
        if (purchaseTokenAddress != WETHAddress) {
            revert WrongTokenAddress(purchaseTokenAddress);
        }
        (address debondTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(_dgovClassId);
        if (debondTokenAddress != DGOVAddress) {
            revert WrongTokenAddress(debondTokenAddress);
        }
        uint purchaseTokenAmount = msg.value;
        uint _interestRate = interestRate(_wethClassId, _dgovClassId, purchaseTokenAmount, PurchaseMethod.Staking);
        if (_interestRate < _minRate) {
            revert RateNotHighEnough(_interestRate, _minRate);
        }

        IWETH(WETHAddress).deposit{value : purchaseTokenAmount}();
        _addLiquidityDgovETHPair(purchaseTokenAmount);
        _issuingProcessStaking(_wethClassId, purchaseTokenAmount, purchaseTokenAddress, _dgovClassId, _interestRate, _to);
    }


    /**
    * @notice user purchasing DBIT bonds by exchanging ETH
    * @param _wethClassId WETH classId
    * @param _dbitClassId DBIT classId
    * @param _minRate min interest rate desired
    * @param _deadline deadline fixed for the transaction to execute
    * @param _to address to interact with (transferring tokens from, ERC3475 tokens to)
    */
    function buyDBITBondsWithETH(//else is not eth not dbit
        uint _wethClassId,
        uint _dbitClassId,
        uint _minRate,
        uint _deadline,
        address _to
    ) external payable ensure(_deadline) {
        if (!canPurchase(_wethClassId, _dbitClassId)) {
            revert PairNotAllowed();
        }
        (address purchaseTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(_wethClassId);
        if (purchaseTokenAddress != WETHAddress) {
            revert WrongTokenAddress(purchaseTokenAddress);
        }
        (address debondTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(_dbitClassId);
        if (debondTokenAddress != DBITAddress) {
            revert WrongTokenAddress(debondTokenAddress);
        }
        uint purchaseTokenAmount = msg.value;
        uint _interestRate = interestRate(_wethClassId, _dbitClassId, purchaseTokenAmount, PurchaseMethod.Buying);
        if (_interestRate < _minRate) {
            revert RateNotHighEnough(_interestRate, _minRate);
        }
        IWETH(WETHAddress).deposit{value : purchaseTokenAmount}();
        _addLiquidityDbitETHPair(purchaseTokenAmount);
        _issuingProcessBuying(purchaseTokenAmount, purchaseTokenAddress, _dbitClassId, _interestRate, _to);
    }

    /**
    * @notice user purchasing DGOV bonds by exchanging ETH
    * @param _wethClassId WETH classId
    * @param _dgovClassId DGOV classId
    * @param _minRate min interest rate desired
    * @param _deadline deadline fixed for the transaction to execute
    * @param _to address to interact with (transferring tokens from, ERC3475 tokens to)
    */
    function buyDGOVBondsWithETH(//else is not eth not dbit
        uint _wethClassId,
        uint _dgovClassId,
        uint _minRate,
        uint _deadline,
        address _to
    ) external payable ensure(_deadline) {
        if (!canPurchase(_wethClassId, _dgovClassId)) {
            revert PairNotAllowed();
        }
        (address purchaseTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(_wethClassId);
        if (purchaseTokenAddress != WETHAddress) {
            revert WrongTokenAddress(purchaseTokenAddress);
        }
        (address debondTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(_dgovClassId);
        if (debondTokenAddress != DGOVAddress) {
            revert WrongTokenAddress(debondTokenAddress);
        }
        uint purchaseTokenAmount = msg.value;
        uint _interestRate = interestRate(_wethClassId, _dgovClassId, purchaseTokenAmount, PurchaseMethod.Buying);
        if (_interestRate < _minRate) {
            revert RateNotHighEnough(_interestRate, _minRate);
        }
        IWETH(WETHAddress).deposit{value : purchaseTokenAmount}();
        _addLiquidityDgovETHPair(purchaseTokenAmount);
        _issuingProcessBuying(purchaseTokenAmount, purchaseTokenAddress, _dgovClassId, _interestRate, _to);
    }

    function redeemLiquidity(address _from, IERC3475.Transaction[] calldata _transactions) external {
        require(msg.sender == debondBondAddress, "Bank Error: Not Authorised");
        for(uint i; i < _transactions.length; i++) {
            (address tokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(_transactions[i].classId);
            _removeLiquidity(_from, tokenAddress, _transactions[i].amount);
        }
    }

    /**
    * @notice get the actual interest rate for bond purchase
    * @param _purchaseTokenClassId token classId to purchase the bonds with
    * @param _debondTokenClassId class Id of the bond desired
    * @param _purchaseTokenAmount amount of the token to add liquidity with
    * @param _purchaseMethod either exchanging (buying) or staking
    */
    function interestRate(
        uint _purchaseTokenClassId,
        uint _debondTokenClassId,
        uint _purchaseTokenAmount,
        PurchaseMethod _purchaseMethod
    ) public view returns (uint) {

        if (!canPurchase(_purchaseTokenClassId, _debondTokenClassId)) {
            revert PairNotAllowed();
        }

        // Staking collateral for bonds
        if (_purchaseMethod == PurchaseMethod.Staking) {
            return IBankBondManager(bondManagerAddress).getInterestRate(_purchaseTokenClassId, _purchaseTokenAmount);
        }
        // buying Bonds
        else {
            (address purchaseTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(_purchaseTokenClassId);
            uint debondTokenAmount = _convertToDbit(uint128(_purchaseTokenAmount), purchaseTokenAddress);
            //todo : ferivy if conversion is possible.

            return IBankBondManager(bondManagerAddress).getInterestRate(_debondTokenClassId, debondTokenAmount);
        }
    }


    /**
    * @notice process to issue bonds to the liquidity provider
    * @param _purchaseClassId token classId to purchase the bonds with
    * @param _purchaseTokenAmount amount of the purchase token
    * @param _purchaseTokenAddress address of the purchase token
    * @param _debondClassId class Id of the bond desired
    * @param _rate rate to calculate amount of debond bonds to issue
    * @param _to address to issue bonds to
    */
    function _issuingProcessStaking(
        uint _purchaseClassId,
        uint _purchaseTokenAmount,
        address _purchaseTokenAddress,
        uint _debondClassId,
        uint _rate,
        address _to
    ) private {
        uint amount = _convertToDbit(uint128(_purchaseTokenAmount), _purchaseTokenAddress);

        uint256[] memory classIds = new uint256[](2);
        classIds[0] = _purchaseClassId;
        classIds[1] = _debondClassId;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = _purchaseTokenAmount;
        amounts[1] = amount.mul(_rate);

        IBankBondManager(bondManagerAddress).issueBonds(_to, classIds, amounts);

    }

    /**
    * @notice process to issue bonds to the liquidity provider
    * @param _purchaseTokenAmount amount of the purchase token
    * @param _purchaseTokenAddress address of the purchase token
    * @param _debondClassId class Id of the bond desired
    * @param _rate rate to calculate amount of debond bonds to issue
    * @param _to address to issue bonds to
    */
    function _issuingProcessBuying(
        uint _purchaseTokenAmount,
        address _purchaseTokenAddress,
        uint _debondClassId,
        uint _rate,
        address _to
    ) private {
        uint amount = _convertToDbit(uint128(_purchaseTokenAmount), _purchaseTokenAddress);

        uint256[] memory classIds = new uint256[](1);
        classIds[0] = _debondClassId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount + amount.mul(_rate);

        IBankBondManager(bondManagerAddress).issueBonds(_to, classIds, amounts);
    }
}
