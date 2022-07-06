pragma solidity ^0.8.0;

// SPDX-License-Identifier: apache 2.0
/*
    Copyright 2020 Sigmoid Foundation <info@SGM.finance>
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
import "@openzeppelin/contracts/access/Ownable.sol";
import "debond-token-contracts/interfaces/IDebondToken.sol";
import "debond-oracle-contracts/interfaces/IOracle.sol";
import './interfaces/IWeth.sol';


import "./BankBondManager.sol";
import "./libraries/DebondMath.sol";
import "./APMRouter.sol";

//todo : grammaire( _ internal, majuscules etc), commentaires

contract Bank is APMRouter, BankBondManager, Ownable {

    using DebondMath for uint256;
    using SafeERC20 for IERC20;

    IOracle oracle;
    enum PurchaseMethod {Buying, Staking}

    address immutable DBITAddress;
    address immutable DGOVAddress;
    address immutable USDCAddress;
    address immutable WETHAddress;

    bool init;

    constructor(
        address governanceAddress,
        address apmAddress,
        address bondAddress,
        address _DBITAddress,
        address _DGOVAddress,
        address oracleAddress,
        address usdcAddress,
        address _weth,
        address _bankData
    ) APMRouter(apmAddress) BankBondManager(governanceAddress, bondAddress, _bankData){
        DBITAddress = _DBITAddress;
        DGOVAddress = _DGOVAddress;
        oracle = IOracle(oracleAddress);
        USDCAddress = usdcAddress;
        WETHAddress = _weth;
        //TODO : call _update to update fee param!!!

    }

    function initializeApp(address daiAddress, address usdtAddress) external onlyOwner {
        require(!init, "BankContract Error: already initiated");
        init = true;
        uint SIX_M_PERIOD = 0 * EPOCH;
        // 1 hour period for tests

        _createClass(0, "DBIT", InterestRateType.FixedRate, DBITAddress, SIX_M_PERIOD);
        _createClass(1, "USDC", InterestRateType.FixedRate, USDCAddress, SIX_M_PERIOD);
        _createClass(2, "USDT", InterestRateType.FixedRate, usdtAddress, SIX_M_PERIOD);
        _createClass(3, "DAI", InterestRateType.FixedRate, daiAddress, SIX_M_PERIOD);
        _createClass(4, "DGOV", InterestRateType.FixedRate, DGOVAddress, SIX_M_PERIOD);
        _createClass(10, "WETH", InterestRateType.FixedRate, WETHAddress, SIX_M_PERIOD);

        _createClass(5, "DBIT", InterestRateType.FloatingRate, DBITAddress, SIX_M_PERIOD);
        _createClass(6, "USDC", InterestRateType.FloatingRate, USDCAddress, SIX_M_PERIOD);
        _createClass(7, "USDT", InterestRateType.FloatingRate, usdtAddress, SIX_M_PERIOD);
        _createClass(8, "DAI", InterestRateType.FloatingRate, daiAddress, SIX_M_PERIOD);
        _createClass(9, "DGOV", InterestRateType.FloatingRate, DGOVAddress, SIX_M_PERIOD);
        _createClass(11, "WETH", InterestRateType.FloatingRate, WETHAddress, SIX_M_PERIOD);


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


    function setBankData(address _bankData) external onlyGovernance {
        bankData = _bankData;
    }


    modifier ensure(uint deadline) {
        if (deadline >= block.timestamp) {
            revert Deadline(deadline, block.timestamp);
        }
        _;
    }

    function updateCanPurchase(uint classIdIn, uint classIdOut, bool _canPurchase) external onlyGovernance {
        _updateCanPurchase(classIdIn, classIdOut, _canPurchase);
    }

    function _updateCanPurchase(uint classIdIn, uint classIdOut, bool _canPurchase) internal {
        IBankData(bankData).updateCanPurchase(classIdIn, classIdOut, _canPurchase);
    }


    //todo : make sure that we can't call a function dbit to dgov with someting else that dbit (for exemple with usdc)
//############buybonds old version##############

        /*
        * @dev let the user buy a bond
        * @param _purchaseClassId classId of the token added by the user (given by frontend)
        * @param _debondClassId  classId of the debond token to mint (dgov or dbit)
        * @param _purchaseTokenAmount amount of token to add
        * @param _purchaseMethod buying method or Staking method
        * @param _minRate minimum Rate that a user is willing to accept. similar to slippage    
        */

    /*
    * @dev mint the bond to the user
        * @param purchaseMethod buying method or Staking method
        * @param purchaseClassId classId of the token added by the user (given by frontend)
        * @param purchaseTokenAmount amount of token to add
        * @param purchaseTokenAddress address of token to add
        * @param debondTokenAddress  address of the debond token to mint (dgov or dbit)
        * @param debondClassId class id of the debond token to mint (dgov or dbit)
        * @param _interestRate fixed rate or floating rate
        * @param minRate minimum Rate that a user is willing to accept. similar to slippage    
        */
   




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
        (address debondTokenAddress,,) = classValues(dbitClassId);
        if (debondTokenAddress != DBITAddress) {
                revert WrongTokenAddress(debondTokenAddress);
        }
        (address purchaseTokenAddress,,) = classValues(purchaseClassId);
        if ( purchaseTokenAddress == DBITAddress || purchaseTokenAddress == DGOVAddress) {
                revert WrongTokenAddress(purchaseTokenAddress);
        }
        uint _interestRate = interestRate(purchaseClassId, dbitClassId, purchaseTokenAmount, PurchaseMethod.Staking);
        if (_interestRate < minRate) {
            revert RateNotHighEnough(_interestRate, minRate);
        }
        _mintingProcessForDbitWithElse(purchaseTokenAmount, purchaseTokenAddress, to);
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
            issueBonds(to, purchaseClassId, purchaseTokenAmount);
            uint amount = convertToDbit(uint128(purchaseTokenAmount), purchaseTokenAddress); 
            issueBonds(to, debondClassId, amount.mul(rate));
    }

    function _mintingProcessForDbitWithElse(
        uint purchaseTokenAmount,
        address purchaseTokenAddress,
        address to
        ) internal {
            uint amountDBITToMint = convertToDbit(uint128(purchaseTokenAmount), purchaseTokenAddress); 
            //todo : verify if conversion is possible.
            IERC20(purchaseTokenAddress).transferFrom(to, address(apm), purchaseTokenAmount);
            IDebondToken(DBITAddress).mintCollateralisedSupply(address(apm), amountDBITToMint);
            updateWhenAddLiquidity(purchaseTokenAmount, amountDBITToMint, purchaseTokenAddress, DBITAddress);
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
            (address purchaseTokenAddress,,) = classValues(dbitClassId);
            if (purchaseTokenAddress != DBITAddress) {
                revert WrongTokenAddress(purchaseTokenAddress);
            }
            (address debondTokenAddress,,) = classValues(dgovClassId);
            if (debondTokenAddress != DGOVAddress) {
                revert WrongTokenAddress(debondTokenAddress);
            }
            uint _interestRate = interestRate(dbitClassId, dgovClassId, dbitTokenAmount, PurchaseMethod.Staking);
            if (_interestRate < minRate) {
                revert RateNotHighEnough(_interestRate, minRate);
            }
            _mintingProcessDgovWithDbit(dbitTokenAmount, to);
            _issuingProcessStaking(dbitClassId, dbitTokenAmount, DBITAddress, dgovClassId, _interestRate, to);
        }

    function _mintingProcessDgovWithDbit(
        uint purchaseDbitAmount,
        address to
    ) internal {
        uint amountDGOVToMint = convertDbitToDgov(purchaseDbitAmount);
        IERC20(DBITAddress).transferFrom(to, address(apm), purchaseDbitAmount);
        IDebondToken(DGOVAddress).mintCollateralisedSupply(address(apm), amountDGOVToMint);
        updateWhenAddLiquidity(purchaseDbitAmount, amountDGOVToMint, DBITAddress, DGOVAddress);
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
        (address debondTokenAddress,,) = classValues(dgovClassId);
        if (debondTokenAddress != DGOVAddress) {
            revert WrongTokenAddress(debondTokenAddress);
        }
        (address purchaseTokenAddress,,) = classValues(purchaseClassId);
        if (purchaseTokenAddress == DBITAddress || purchaseTokenAddress == DGOVAddress) {
            revert WrongTokenAddress(purchaseTokenAddress);
        }
        uint _interestRate = interestRate(purchaseClassId, dgovClassId, purchaseTokenAmount, PurchaseMethod.Staking);
        if (_interestRate < minRate) {
            revert RateNotHighEnough(_interestRate, minRate);
        }
        _mintingProcessForDgovWithElse(purchaseTokenAmount, purchaseTokenAddress, to);
        _issuingProcessStaking(purchaseClassId, purchaseTokenAmount, purchaseTokenAddress, dgovClassId, _interestRate, to);
        }

        function _mintingProcessForDgovWithElse(
            uint purchaseTokenAmount,
            address purchaseTokenAddress,
            address to
            ) internal {
                uint amountDBITToMint = convertToDbit(uint128(purchaseTokenAmount), purchaseTokenAddress);
                uint amountDGOVToMint = convertDbitToDgov(amountDBITToMint);
                IERC20(purchaseTokenAddress).transferFrom(to, address(apm), purchaseTokenAmount);
                IDebondToken(DGOVAddress).mintCollateralisedSupply(address(apm), amountDGOVToMint);
                IDebondToken(DBITAddress).mintCollateralisedSupply(address(apm), 2 * amountDBITToMint);
                updateWhenAddLiquidity(purchaseTokenAmount, amountDBITToMint, purchaseTokenAddress, DBITAddress);
                updateWhenAddLiquidity(amountDBITToMint, amountDGOVToMint, DBITAddress, DGOVAddress);
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
        (address _debondTokenAddress,,) = classValues(_dbitClassId);
        if (_debondTokenAddress != DBITAddress) {
            revert WrongTokenAddress(_debondTokenAddress);
        }
        (address _purchaseTokenAddress,,) = classValues(_purchaseClassId);
        if( _purchaseTokenAddress == DBITAddress || _purchaseTokenAddress == DGOVAddress) {
            revert WrongTokenAddress(_purchaseTokenAddress);
        }
        uint _interestRate = interestRate(_purchaseClassId, _dbitClassId, _purchaseTokenAmount, PurchaseMethod.Buying);
        if (_interestRate < _minRate) {
            revert RateNotHighEnough(_interestRate, _minRate);
        }
        _mintingProcessForDbitWithElse(_purchaseTokenAmount, _purchaseTokenAddress, _to);
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
                issueBonds(to, debondClassId, amount + amount.mul(rate));
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
        
        (address _purchaseTokenAddress,,) = classValues(_dbitClassId);
        if(_purchaseTokenAddress != DBITAddress) {
            revert WrongTokenAddress(_purchaseTokenAddress);
        }
        (address _debondTokenAddress,,) = classValues(_dgovClassId);
        if (_debondTokenAddress != DGOVAddress) {
            revert WrongTokenAddress(_debondTokenAddress);
        }
        uint _interestRate = interestRate(_dbitClassId, _dgovClassId, _purchaseTokenAmount, PurchaseMethod.Buying);
        if (_interestRate < _minRate) {
            revert RateNotHighEnough(_interestRate, _minRate);
        }
        _mintingProcessDgovWithDbit(_purchaseTokenAmount, _to);
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
        (address purchaseTokenAddress,,) = classValues(purchaseClassId);
        if (purchaseTokenAddress == DBITAddress || purchaseTokenAddress == DGOVAddress) {
            revert WrongTokenAddress(purchaseTokenAddress);
        }
        (address debondTokenAddress,,) = classValues(dgovClassId);
        if( debondTokenAddress != DGOVAddress) {
            revert WrongTokenAddress(debondTokenAddress);
        }
        uint _interestRate = interestRate(purchaseClassId, dgovClassId, purchaseTokenAmount, PurchaseMethod.Buying);
        if (_interestRate < minRate) {
            revert RateNotHighEnough(_interestRate, minRate);
        }
        _mintingProcessForDgovWithElse(purchaseTokenAmount, purchaseTokenAddress, to);
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
        (address purchaseTokenAddress,,) = classValues(wethClassId);
        if (purchaseTokenAddress != WETHAddress) {
            revert WrongTokenAddress(purchaseTokenAddress);
        }
        (address debondTokenAddress,,) = classValues(dbitClassId);
        if (debondTokenAddress != DBITAddress) {
            revert WrongTokenAddress(debondTokenAddress);
        }
        uint purchaseTokenAmount = msg.value;
        uint _interestRate = interestRate(wethClassId, dbitClassId, purchaseTokenAmount, PurchaseMethod.Staking);
        if (_interestRate < minRate) {
            revert RateNotHighEnough(_interestRate, minRate);
        }
        _mintingProcessForDbitWithEth(purchaseTokenAmount);
        _issuingProcessStaking(wethClassId, purchaseTokenAmount, purchaseTokenAddress, dbitClassId, _interestRate, to);
    }

    function _mintingProcessForDbitWithEth(
        uint purchaseETHAmount
    ) internal {
        uint amountDBITToMint = convertToDbit(uint128(purchaseETHAmount), WETHAddress);
        IWeth(WETHAddress).deposit{value : purchaseETHAmount}();
        assert(IWeth(WETHAddress).transfer(address(apm), purchaseETHAmount));
        IDebondToken(DBITAddress).mintCollateralisedSupply(address(apm), amountDBITToMint);
        updateWhenAddLiquidity(purchaseETHAmount, amountDBITToMint, WETHAddress, DBITAddress);
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
        (address purchaseTokenAddress,,) = classValues(wethClassId);
        if (purchaseTokenAddress != WETHAddress) {
            revert WrongTokenAddress(purchaseTokenAddress);
        }
        (address debondTokenAddress,,) = classValues(dgovClassId);
        if (debondTokenAddress != DGOVAddress) {
            revert WrongTokenAddress(debondTokenAddress);
        }
        uint purchaseTokenAmount = msg.value;
        uint _interestRate = interestRate(wethClassId, dgovClassId, purchaseTokenAmount, PurchaseMethod.Staking);
        if (_interestRate < minRate) {
            revert RateNotHighEnough(_interestRate, minRate);
        }
        _mintingProcessForETHWithDgov(purchaseTokenAmount);
        _issuingProcessStaking(wethClassId, purchaseTokenAmount, purchaseTokenAddress, dgovClassId, _interestRate, to);
    }

        function _mintingProcessForETHWithDgov(
            uint purchaseETHAmount
            ) internal {
            uint amountDBITToMint = convertToDbit(uint128(purchaseETHAmount), WETHAddress);
            uint amountDGOVToMint = convertDbitToDgov(amountDBITToMint);
            IWeth(WETHAddress).deposit{value : purchaseETHAmount}();
            assert(IWeth(WETHAddress).transfer(address(apm), purchaseETHAmount));
            IDebondToken(DGOVAddress).mintCollateralisedSupply(address(apm), amountDGOVToMint);
            IDebondToken(DBITAddress).mintCollateralisedSupply(address(apm), 2 * amountDBITToMint);
            updateWhenAddLiquidity(purchaseETHAmount, amountDBITToMint, WETHAddress, DBITAddress);
            updateWhenAddLiquidity(amountDBITToMint, amountDGOVToMint, DBITAddress, DGOVAddress);
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
        (address purchaseTokenAddress,,) = classValues(wethClassId);
        if (purchaseTokenAddress != WETHAddress) {
            revert WrongTokenAddress(purchaseTokenAddress);
        }
        (address debondTokenAddress,,) = classValues(dbitClassId);
        if (debondTokenAddress != DBITAddress) {
            revert WrongTokenAddress(debondTokenAddress);
        }
        uint purchaseTokenAmount = msg.value;
        uint _interestRate = interestRate(wethClassId, dbitClassId, purchaseTokenAmount, PurchaseMethod.Buying);
        if (_interestRate < minRate) {
            revert RateNotHighEnough(_interestRate, minRate);
        }
        _mintingProcessForDbitWithEth(purchaseTokenAmount);
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
        (address purchaseTokenAddress,,) = classValues(wethClassId);
        if (purchaseTokenAddress != WETHAddress) {
            revert WrongTokenAddress(purchaseTokenAddress);
        }
        (address debondTokenAddress,,) = classValues(dgovClassId);
        if (debondTokenAddress != DGOVAddress) {
            revert WrongTokenAddress(debondTokenAddress);
        }
        uint purchaseTokenAmount = msg.value;
        uint _interestRate = interestRate(wethClassId, dgovClassId, purchaseTokenAmount, PurchaseMethod.Buying);
        if (_interestRate < minRate) {
            revert RateNotHighEnough(_interestRate, minRate);
        }
        _mintingProcessForDgovWithEth(purchaseTokenAmount);
        _issuingProcessBuying(purchaseTokenAmount, purchaseTokenAddress, dgovClassId, _interestRate, to);
        }

    function _mintingProcessForDgovWithEth(
        uint purchaseETHAmount
        ) internal {
        uint amountDBITToMint = convertToDbit(uint128(purchaseETHAmount), WETHAddress);
        uint amountDGOVToMint = convertDbitToDgov(amountDBITToMint);
        IWeth(WETHAddress).deposit{value : purchaseETHAmount}();
        assert(IWeth(WETHAddress).transfer(address(apm), purchaseETHAmount));
        IDebondToken(DGOVAddress).mintCollateralisedSupply(address(apm), amountDGOVToMint);
        IDebondToken(DBITAddress).mintCollateralisedSupply(address(apm), 2 * amountDBITToMint);
        updateWhenAddLiquidity(purchaseETHAmount, amountDBITToMint, WETHAddress, DBITAddress);
        updateWhenAddLiquidity(amountDBITToMint, amountDGOVToMint, DBITAddress, DGOVAddress);
    }
//##############REDEEM BONDS ##############:

    function redeemBonds(
        uint classId,
        uint nonceId,
        uint amount
    ) external {
        //1. redeem the bonds (will fail if not maturity date exceeded)
        //_redeemERC3475(msg.sender, classId, nonceId, amount);

        (address tokenAddress,,) = classValues(classId);
        removeLiquidity(msg.sender, tokenAddress, amount);
    }

    function redeemBondsETH(
        uint wethClassId,
        uint nonceId,
        uint amountETH
    ) external {
        //1. redeem the bonds (will fail if not maturity date exceeded)
        _redeemERC3475(msg.sender, wethClassId, nonceId, amountETH);

        (address tokenAddress,,) = classValues(wethClassId);
        removeLiquidity(msg.sender, tokenAddress, amountETH);
        IWeth(WETHAddress).withdraw(amountETH);
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
            return _getInterestRate(_purchaseTokenClassId, _purchaseTokenAmount);
        }
        // buying Bonds
        else {
            (address purchaseTokenAddress,,) = classValues(_purchaseTokenClassId);
            uint debondTokenAmount = convertToDbit(uint128(_purchaseTokenAmount), purchaseTokenAddress);
            //todo : ferivy if conversion is possible.

            return _getInterestRate(_debondTokenClassId, debondTokenAmount);
        }
    }

    function _getInterestRate(uint classId, uint amount) private view returns (uint rate) {
        (address tokenAddress, InterestRateType interestRateType,) = classValues(classId);
        (uint fixRateSupply, uint floatRateSupply) = _getSupplies(tokenAddress, interestRateType, amount);

        uint fixRate;
        uint floatRate;
        uint oneTokenToUSDValue = _convertTokenToUsd(1, tokenAddress);
        if ((fixRateSupply.mul(oneTokenToUSDValue)) < 100_000 ether || (floatRateSupply.mul(oneTokenToUSDValue)) < 100_000 ether) {
            (fixRate, floatRate) = _getDefaultRate();
        } else {
            (fixRate, floatRate) = _getCalculatedRate(fixRateSupply, floatRateSupply);
        }
        rate = interestRateType == InterestRateType.FixedRate ? fixRate : floatRate;
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

    /**
    * @dev gives the amount of DBIT which should be minted for 1$ worth of input
    * @return amountDBIT the amount of DBIT which should be minted
    */
    function _cdpUsdToDBIT() private view returns (uint256 amountDBIT) {
        amountDBIT = 1 ether;
        uint256 _sCollateralised = IDebondToken(DBITAddress).getTotalCollateralisedSupply();
        //todo: is this working?
        if (_sCollateralised >= 1000 ether) {
            amountDBIT = 1.05 ether;
            uint256 logCollateral = (_sCollateralised / 1000).ln();
            amountDBIT = amountDBIT.pow(logCollateral);
        }
    }
    /**
    * @dev convert a given amount of token to USD  (the pair needs to exist on uniswap)
    * @param _amountToken the amount of token we want to convert
    * @param _tokenAddress the address of token we want to convert
    * @return amountUsd the corresponding amount of usd
    */
    function _convertTokenToUsd(uint128 _amountToken, address _tokenAddress) private view returns (uint256 amountUsd) {

        if (_tokenAddress == USDCAddress) {
            amountUsd = _amountToken;
        }
        else {
            amountUsd = oracle.estimateAmountOut(_tokenAddress, _amountToken, USDCAddress, 60) * 1e12;
            //1e6 x 1e12 = 1e18
        }
    }

    /**
    * @dev given the amount of tokens and the token address, returns the amout of DBIT to mint.
    * @param _amountToken the amount of token
    * @param _tokenAddress the address of token
    * @return amountDBIT the amount of DBIT to mint
    */
    function convertToDbit(uint128 _amountToken, address _tokenAddress) private view returns (uint256 amountDBIT) {

        uint256 tokenToUsd = _convertTokenToUsd(_amountToken, _tokenAddress);
        uint256 rate = _cdpUsdToDBIT();

        amountDBIT = tokenToUsd.mul(rate);
        //1e6 x 1e12 x 1e18 = 1e18
    }


// **** DGOV ****

    /**
            * @dev gives the amount of dgov which should be minted for 1 dbit of input
        * @return amountDGOV the amount of DGOV which should be minted
        */
    function _cdpDbitToDgov() private view returns (uint256 amountDGOV) {
        uint256 _sCollateralised = IDebondToken(DGOVAddress).getTotalCollateralisedSupply();
        amountDGOV = (100 ether + (_sCollateralised).div(33333).pow(2)).inv();
    }
    /**
    * @dev given the amount of dbit, returns the amout of DGOV to mint
    * @param _amountDBIT the amount of token
    * @return amountDGOV the amount of DGOV to mint
    */
    function convertDbitToDgov(uint256 _amountDBIT) private view returns (uint256 amountDGOV) {
        uint256 rate = _cdpDbitToDgov();
        amountDGOV = _amountDBIT.mul(rate);
    }


    function canPurchase(uint classIdIn, uint classIdOut) public view returns (bool) {
        return IBankData(bankData).canPurchase(classIdIn, classIdOut);
    }
}
