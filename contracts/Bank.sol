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

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@debond-protocol/debond-token-contracts/interfaces/IDebondToken.sol";
import "@debond-protocol/debond-oracle-contracts/interfaces/IOracle.sol";
import "@debond-protocol/debond-governance-contracts/utils/GovernanceOwnable.sol";
import "./interfaces/IWETH.sol";
import "./BankBondManager.sol";
import "./libraries/DebondMath.sol";
import "./interfaces/IBankData.sol";
import "./BankRouter.sol";



//todo : grammaire( _ internal, majuscules etc), commentaires

contract Bank is BankRouter, GovernanceOwnable {

    using DebondMath for uint256;
    using SafeERC20 for IERC20;

    address bankDataAddress;
    address bondManagerAddress;
    enum PurchaseMethod {Buying, Staking}
    constructor(
        address _governanceAddress,
        address _APMAddress,
        address _bankBondManagerAddress,
        address _bankDataAddress,
        address _DBITAddress,
        address _DGOVAddress,
        address _USDCAddress,
        address _WETHAddress,
        address _oracleAddress
    ) GovernanceOwnable(_governanceAddress) BankRouter(_APMAddress, _DBITAddress, _DGOVAddress, _USDCAddress, _WETHAddress, _oracleAddress) {
        bondManagerAddress = _bankBondManagerAddress;
        bankDataAddress = _bankDataAddress;
    }

    receive() external payable {}

    modifier ensure(uint deadline) {
        if (deadline >= block.timestamp) {
            revert Deadline(deadline, block.timestamp);
        }
        _;
    }

    function setApmAddress(address _apmAddress) external onlyGovernance {
        _setApmAddress(_apmAddress);
    }

    function setBondManagerAddress(address _bondManagerAddress) external onlyGovernance {
        bondManagerAddress = _bondManagerAddress;
    }

    function setBankDataAddress(address _bankDataAddress) external onlyGovernance {
        bankDataAddress = _bankDataAddress;
    }

    function setDBITAddress(address _DBITAddress) external onlyGovernance {
        DBITAddress = _DBITAddress;
    }

    function setDGOVAddress(address _DGOVAddress) external onlyGovernance {
        DGOVAddress = _DGOVAddress;
    }

    function canPurchase(uint classIdIn, uint classIdOut) public view returns (bool) {
        return IBankData(bankDataAddress).canPurchase(classIdIn, classIdOut);
    }


    //############buybonds staking method  dbit with else (else is Not eth, not dgov, not dbit)  ##############

    function stakeForDbitBondWithElse(
        uint purchaseClassId,
        uint dbitClassId,
        uint purchaseTokenAmount,
        uint minRate,
        uint deadline,
        address to
    ) external ensure(deadline) {
        if (!canPurchase(purchaseClassId, dbitClassId)) {
            revert PairNotAllowed();
        }
        (address debondTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(dbitClassId);
        if (debondTokenAddress != DBITAddress) {
            revert WrongTokenAddress(debondTokenAddress);
        }
        (address purchaseTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(purchaseClassId);
        if (purchaseTokenAddress == DBITAddress || purchaseTokenAddress == DGOVAddress) {
            revert WrongTokenAddress(purchaseTokenAddress);
        }
        uint _interestRate = interestRate(purchaseClassId, dbitClassId, purchaseTokenAmount, PurchaseMethod.Staking);
        if (_interestRate < minRate) {
            revert RateNotHighEnough(_interestRate, minRate);
        }
        addLiquidityDbitPair(to, purchaseTokenAddress, purchaseTokenAmount);
        _issuingProcessStaking(purchaseClassId, purchaseTokenAmount, purchaseTokenAddress, dbitClassId, _interestRate, to);

    }

    function _issuingProcessStaking(
        uint purchaseClassId,
        uint purchaseTokenAmount,
        address purchaseTokenAddress,
        uint debondClassId,
        uint rate,
        address to
    ) public {
        uint amount = convertToDbit(uint128(purchaseTokenAmount), purchaseTokenAddress);

        uint256[] memory classIds = new uint256[](2);
        classIds[0] = purchaseClassId;
        classIds[1] = debondClassId;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = purchaseTokenAmount;
        amounts[1] = amount.mul(rate);

        IBankBondManager(bondManagerAddress).issueBonds(to, classIds, amounts);

    }

    //############buybonds Staking method  DbitToDgov##############

    function stakeForDgovBondWithDbit(
        uint dbitClassId,
        uint dgovClassId,
        uint dbitTokenAmount,
        uint minRate,
        uint deadline,
        address to
    ) external ensure(deadline) {
        if (!canPurchase(dbitClassId, dgovClassId)) {
            revert PairNotAllowed();
        }
        (address purchaseTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(dbitClassId);
        if (purchaseTokenAddress != DBITAddress) {
            revert WrongTokenAddress(purchaseTokenAddress);
        }
        (address debondTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(dgovClassId);
        if (debondTokenAddress != DGOVAddress) {
            revert WrongTokenAddress(debondTokenAddress);
        }
        uint _interestRate = interestRate(dbitClassId, dgovClassId, dbitTokenAmount, PurchaseMethod.Staking);
        if (_interestRate < minRate) {
            revert RateNotHighEnough(_interestRate, minRate);
        }
        addLiquidityDbitDgov(to, dbitTokenAmount);
        _issuingProcessStaking(dbitClassId, dbitTokenAmount, DBITAddress, dgovClassId, _interestRate, to);
    }

    //############buybonds Staking method  else ToDgov############## else is not dbit not eth not dgov

    function stakeForDgovBondWithElse(
        uint purchaseClassId,
        uint dgovClassId,
        uint purchaseTokenAmount,
        uint minRate,
        uint deadline,
        address to
    ) external ensure(deadline) {
        if (!canPurchase(purchaseClassId, dgovClassId)) {
            revert PairNotAllowed();
        }
        (address debondTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(dgovClassId);
        if (debondTokenAddress != DGOVAddress) {
            revert WrongTokenAddress(debondTokenAddress);
        }
        (address purchaseTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(purchaseClassId);
        if (purchaseTokenAddress == DBITAddress || purchaseTokenAddress == DGOVAddress) {
            revert WrongTokenAddress(purchaseTokenAddress);
        }
        uint _interestRate = interestRate(purchaseClassId, dgovClassId, purchaseTokenAmount, PurchaseMethod.Staking);
        if (_interestRate < minRate) {
            revert RateNotHighEnough(_interestRate, minRate);
        }
        addLiquidityDgovPair(to, purchaseTokenAddress, purchaseTokenAmount);
        _issuingProcessStaking(purchaseClassId, purchaseTokenAmount, purchaseTokenAddress, dgovClassId, _interestRate, to);
    }

    //############buybonds Buying method not eth to dbit##############

    function buyforDbitBondWithElse(//else is not eth not dbit not dgov
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
        addLiquidityDbitPair(_to, _purchaseTokenAddress, _purchaseTokenAmount);
        _issuingProcessBuying(_purchaseTokenAmount, _purchaseTokenAddress, _dbitClassId, _interestRate, _to);
    }

    function _issuingProcessBuying(
        uint purchaseTokenAmount,
        address purchaseTokenAddress,
        uint debondClassId,
        uint rate,
        address to
    ) internal {
        uint amount = convertToDbit(uint128(purchaseTokenAmount), purchaseTokenAddress);

        uint256[] memory classIds = new uint256[](1);
        classIds[0] = debondClassId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount + amount.mul(rate);

        IBankBondManager(bondManagerAddress).issueBonds(to, classIds, amounts);
    }


    //############buybonds Buying method DbitToDgov##############


    function buyForDgovBondWithDbit(
        uint _dbitClassId,
        uint _dgovClassId,
        uint _purchaseTokenAmount,
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
        uint _interestRate = interestRate(_dbitClassId, _dgovClassId, _purchaseTokenAmount, PurchaseMethod.Buying);
        if (_interestRate < _minRate) {
            revert RateNotHighEnough(_interestRate, _minRate);
        }
        addLiquidityDbitDgov(_to, _purchaseTokenAmount);
        _issuingProcessBuying(_purchaseTokenAmount, DBITAddress, _dgovClassId, _interestRate, _to);
    }


    //############buybonds Buying method else ToDgov############## else is not dbit not eth

    function buyForDgovBondWithElse(
        uint purchaseClassId,
        uint dgovClassId,
        uint purchaseTokenAmount,
        uint minRate,
        uint deadline,
        address to
    ) external ensure(deadline) {
        if (!canPurchase(purchaseClassId, dgovClassId)) {
            revert PairNotAllowed();
        }
        (address purchaseTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(purchaseClassId);
        if (purchaseTokenAddress == DBITAddress || purchaseTokenAddress == DGOVAddress) {
            revert WrongTokenAddress(purchaseTokenAddress);
        }
        (address debondTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(dgovClassId);
        if (debondTokenAddress != DGOVAddress) {
            revert WrongTokenAddress(debondTokenAddress);
        }
        uint _interestRate = interestRate(purchaseClassId, dgovClassId, purchaseTokenAmount, PurchaseMethod.Buying);
        if (_interestRate < minRate) {
            revert RateNotHighEnough(_interestRate, minRate);
        }
        addLiquidityDgovPair(to, purchaseTokenAddress, purchaseTokenAmount);
        _issuingProcessBuying(purchaseTokenAmount, purchaseTokenAddress, dgovClassId, _interestRate, to);
    }


    //############buybonds Staking method  ETH To DBIT##############

    function stakeForDbitBondWithEth(
        uint wethClassId,
        uint dbitClassId,
        uint minRate,
        uint deadline,
        address to
    ) external payable ensure(deadline) {
        if (!canPurchase(wethClassId, dbitClassId)) {
            revert PairNotAllowed();
        }
        (address purchaseTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(wethClassId);
        if (purchaseTokenAddress != WETHAddress) {
            revert WrongTokenAddress(purchaseTokenAddress);
        }
        (address debondTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(dbitClassId);
        if (debondTokenAddress != DBITAddress) {
            revert WrongTokenAddress(debondTokenAddress);
        }
        uint purchaseTokenAmount = msg.value;
        uint _interestRate = interestRate(wethClassId, dbitClassId, purchaseTokenAmount, PurchaseMethod.Staking);
        if (_interestRate < minRate) {
            revert RateNotHighEnough(_interestRate, minRate);
        }
        IWETH(WETHAddress).deposit{value : purchaseTokenAmount}();
        addLiquidityDbitETHPair(purchaseTokenAmount);

        _issuingProcessStaking(wethClassId, purchaseTokenAmount, purchaseTokenAddress, dbitClassId, _interestRate, to);
    }


    //############buybonds Staking method  ETH To Dgov##############

    function stakeForDgovBondWithEth(
        uint wethClassId,
        uint dgovClassId,
        uint minRate,
        uint deadline,
        address to
    ) external payable ensure(deadline) {
        if (!canPurchase(wethClassId, dgovClassId)) {
            revert PairNotAllowed();
        }
        (address purchaseTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(wethClassId);
        if (purchaseTokenAddress != WETHAddress) {
            revert WrongTokenAddress(purchaseTokenAddress);
        }
        (address debondTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(dgovClassId);
        if (debondTokenAddress != DGOVAddress) {
            revert WrongTokenAddress(debondTokenAddress);
        }
        uint purchaseTokenAmount = msg.value;
        uint _interestRate = interestRate(wethClassId, dgovClassId, purchaseTokenAmount, PurchaseMethod.Staking);
        if (_interestRate < minRate) {
            revert RateNotHighEnough(_interestRate, minRate);
        }

        IWETH(WETHAddress).deposit{value : purchaseTokenAmount}();
        addLiquidityDgovETHPair(purchaseTokenAmount);
        _issuingProcessStaking(wethClassId, purchaseTokenAmount, purchaseTokenAddress, dgovClassId, _interestRate, to);
    }


    //############buybonds Buying method  ETH To DBIT##############
    //todo : pour buying, pas besoin du class id du purchase token : faire deux fonction interest rate buying et stacking.
    function buyforDbitBondWithEth(//else is not eth not dbit
        uint wethClassId,
        uint dbitClassId,
        uint minRate,
        uint deadline,
        address to
    ) external payable ensure(deadline) {
        if (!canPurchase(wethClassId, dbitClassId)) {
            revert PairNotAllowed();
        }
        (address purchaseTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(wethClassId);
        if (purchaseTokenAddress != WETHAddress) {
            revert WrongTokenAddress(purchaseTokenAddress);
        }
        (address debondTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(dbitClassId);
        if (debondTokenAddress != DBITAddress) {
            revert WrongTokenAddress(debondTokenAddress);
        }
        uint purchaseTokenAmount = msg.value;
        uint _interestRate = interestRate(wethClassId, dbitClassId, purchaseTokenAmount, PurchaseMethod.Buying);
        if (_interestRate < minRate) {
            revert RateNotHighEnough(_interestRate, minRate);
        }
        IWETH(WETHAddress).deposit{value : purchaseTokenAmount}();
        addLiquidityDbitETHPair(purchaseTokenAmount);
        _issuingProcessBuying(purchaseTokenAmount, purchaseTokenAddress, dbitClassId, _interestRate, to);
    }


    //############buybonds Buying method  ETH To Dgov##############

    function buyforDgovBondWithEth(//else is not eth not dbit
        uint wethClassId,
        uint dgovClassId,
        uint minRate,
        uint deadline,
        address to
    ) external payable ensure(deadline) {
        if (!canPurchase(wethClassId, dgovClassId)) {
            revert PairNotAllowed();
        }
        (address purchaseTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(wethClassId);
        if (purchaseTokenAddress != WETHAddress) {
            revert WrongTokenAddress(purchaseTokenAddress);
        }
        (address debondTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(dgovClassId);
        if (debondTokenAddress != DGOVAddress) {
            revert WrongTokenAddress(debondTokenAddress);
        }
        uint purchaseTokenAmount = msg.value;
        uint _interestRate = interestRate(wethClassId, dgovClassId, purchaseTokenAmount, PurchaseMethod.Buying);
        if (_interestRate < minRate) {
            revert RateNotHighEnough(_interestRate, minRate);
        }
        IWETH(WETHAddress).deposit{value : purchaseTokenAmount}();
        addLiquidityDgovETHPair(purchaseTokenAmount);
        _issuingProcessBuying(purchaseTokenAmount, purchaseTokenAddress, dgovClassId, _interestRate, to);
    }

    //##############REDEEM BONDS ##############:

    function redeemBonds(
        uint classId,
        uint nonceId,
        uint amount
    ) external {
        //1. redeem the bonds (will fail if not maturity date exceeded)
        IBankBondManager(bondManagerAddress).redeemERC3475(msg.sender, classId, nonceId, amount);

        (address tokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(classId);
        removeLiquidity(msg.sender, tokenAddress, amount);
    }

    function redeemBondsETH(
        uint wethClassId,
        uint nonceId,
        uint amountETH
    ) external {
        IBankBondManager(bondManagerAddress).redeemERC3475(msg.sender, wethClassId, nonceId, amountETH);
        //TODO Check if wethClassId gives the WethAddress tokenAddress!!!!
        removeWETHLiquidity(amountETH);
    }

    function interestRate(
        uint _purchaseTokenClassId,
        uint _debondTokenClassId,
        uint _purchaseTokenAmount,
        PurchaseMethod purchaseMethod
    ) public view returns (uint) {

        if (!canPurchase(_purchaseTokenClassId, _debondTokenClassId)) {
            revert PairNotAllowed();
        }

        // Staking collateral for bonds
        if (purchaseMethod == PurchaseMethod.Staking) {
            return IBankBondManager(bondManagerAddress).getInterestRate(_purchaseTokenClassId, _purchaseTokenAmount);
        }
        // buying Bonds
        else {
            (address purchaseTokenAddress,,) = IBankBondManager(bondManagerAddress).classValues(_purchaseTokenClassId);
            uint debondTokenAmount = convertToDbit(uint128(_purchaseTokenAmount), purchaseTokenAddress);
            //todo : ferivy if conversion is possible.

            return IBankBondManager(bondManagerAddress).getInterestRate(_debondTokenClassId, debondTokenAmount);
        }
    }



    //##############CDP##############:

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) {/// use uint?? int256???
        if (amountA == 0) {
            revert INSUFFICIENT_AMOUNT(amountA);
        }
        if (reserveA == 0) {
            revert INSUFFICIENT_LIQUIDITY(reserveB);
        }
        if (reserveB == 0) {
            revert INSUFFICIENT_LIQUIDITY(reserveA);
        }
        //amountB = amountA.mul(reserveB) / reserveA;
        amountB = amountA * reserveB / reserveA;
    }
}
