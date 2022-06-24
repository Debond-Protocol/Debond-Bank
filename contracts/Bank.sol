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

    event test(uint amount);
    event test1(uint amount);
    event test2(uint amount);
    event test3(uint amount);

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
        uint256 baseTimeStamp
    ) APMRouter(apmAddress) BankBondManager(governanceAddress, bondAddress, baseTimeStamp){
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
        uint SIX_M_PERIOD = 180 * 30;
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



    modifier ensure(uint deadline) {
        if (deadline >= block.timestamp) {
            revert Deadline(deadline, block.timestamp);
        }
        _;
    }

    //##############BUY BONDS#############

    //todo : make sure that we can't call a function dbit to dgov with someting else that dbit (for exemple with usdc)
    //############buybonds old version##############

        /**
        * @dev let the user buy a bond
        * @param _purchaseClassId classId of the token added by the user (given by frontend)
        * @param _debondClassId  classId of the debond token to mint (dgov or dbit)
        * @param _purchaseTokenAmount amount of token to add
        * @param _purchaseMethod buying method or Staking method
        * @param _minRate minimum Rate that a user is willing to accept. similar to slippage    
        */

        function buyBond(
            uint _purchaseClassId,
            uint _debondClassId, 
            uint _purchaseTokenAmount,
            PurchaseMethod _purchaseMethod,
            uint _minRate
            ) external  {

        uint purchaseClassId = _purchaseClassId;
        uint debondClassId = _debondClassId;
        uint purchaseTokenAmount = _purchaseTokenAmount;
        PurchaseMethod purchaseMethod = _purchaseMethod;
        uint minRate = _minRate;


        if (!canPurchase[purchaseClassId][debondClassId]) {
            revert PairNotAllowed();
        }
        (address purchaseTokenAddress,,) = classValues(purchaseClassId);
        (address debondTokenAddress,,) = classValues(debondClassId);

        _mintingProcess(debondTokenAddress, purchaseTokenAmount, purchaseTokenAddress);

        uint _interestRate = interestRate(purchaseClassId, debondClassId, purchaseTokenAmount, purchaseMethod);
        _issuingProcess(purchaseMethod, purchaseClassId, purchaseTokenAmount, purchaseTokenAddress, debondTokenAddress, debondClassId, _interestRate, minRate);
    }



    /**
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
    function _issuingProcess(//todo : _ for internal
        PurchaseMethod purchaseMethod,
        uint purchaseClassId,
        uint purchaseTokenAmount,
        address purchaseTokenAddress,
        address debondTokenAddress,
        uint debondClassId,
        uint _interestRate,
        uint minRate
    ) internal {
        if (purchaseMethod == PurchaseMethod.Staking) {
            issueBonds(msg.sender, purchaseClassId, purchaseTokenAmount);
            (uint reserveA, uint reserveB) = getReserves(purchaseTokenAddress, debondTokenAddress);
            //if reserve == 0 : use cdp price instead of quote? See with yu
            //do we have to handle the case where reserve = 0? or when deploying, we put some liquidity?
            //we first update reserves when buying bond so it should never be 0
            uint amount = quote(purchaseTokenAmount, reserveA, reserveB);
            if (_interestRate < minRate) {
                revert RateNotHighEnough(_interestRate, minRate);
            }
            issueBonds(msg.sender, debondClassId, amount.mul(_interestRate));
        }
        else if (purchaseMethod == PurchaseMethod.Buying) {
            (uint reserveA, uint reserveB) = getReserves(purchaseTokenAddress, debondTokenAddress);
            uint amount = quote(purchaseTokenAmount, reserveA, reserveB);
            if (_interestRate < minRate) {
                revert RateNotHighEnough(_interestRate, minRate);
            }
            issueBonds(msg.sender, debondClassId, amount + amount.mul(_interestRate));
            // here the interest calculation is hardcoded. require the interest is enough high
        }
    }


    function _mintingProcess(
        address debondTokenAddress,
        uint purchaseTokenAmount,
        address purchaseTokenAddress
    ) internal {
        if (debondTokenAddress == DBITAddress) {
            //TODO : require : purchase token is not dbit, not dgov
            uint amountDBITToMint = convertToDbit(uint128(purchaseTokenAmount), purchaseTokenAddress);
            //todo : verivy if conversion is possible.
            IERC20(purchaseTokenAddress).transferFrom(msg.sender, address(apm), purchaseTokenAmount);
            IDebondToken(debondTokenAddress).mintCollateralisedSupply(address(apm), amountDBITToMint);
            updateWhenAddLiquidity(purchaseTokenAmount, amountDBITToMint, purchaseTokenAddress, debondTokenAddress);
        }
        else {//else address ==dgov?
            if (purchaseTokenAddress == DBITAddress) {
                uint amountDGOVToMint = convertDbitToDgov(purchaseTokenAmount);
                IERC20(DBITAddress).transferFrom(msg.sender, address(apm), purchaseTokenAmount);
                IDebondToken(debondTokenAddress).mintCollateralisedSupply(address(apm), amountDGOVToMint);
                //todo : check amountDGOVToMint
                updateWhenAddLiquidity(purchaseTokenAmount, amountDGOVToMint, DBITAddress, debondTokenAddress);
            }
            else {
                uint amountDBITToMint = convertToDbit(uint128(purchaseTokenAmount), purchaseTokenAddress);
                //need cdp from usd to dgov
                uint amountDGOVToMint = convertDbitToDgov(purchaseTokenAmount);
                IERC20(purchaseTokenAddress).transferFrom(msg.sender, address(apm), purchaseTokenAmount);
                IDebondToken(DGOVAddress).mintCollateralisedSupply(address(apm), amountDGOVToMint);
                IDebondToken(DBITAddress).mintCollateralisedSupply(address(apm), 2 * amountDBITToMint);
                //TODO : check here
                updateWhenAddLiquidity(purchaseTokenAmount, amountDBITToMint, purchaseTokenAddress, DBITAddress);
                updateWhenAddLiquidity(amountDBITToMint, amountDGOVToMint, DBITAddress, debondTokenAddress);
            }

        }
    }



    //############buybonds staking method  dbit with else (else is Not eth, not dgov, not dbit)  ##############

    function stakeForDbitBondWithElse(
        uint _purchaseClassId,
        uint _DbitClassId,
        uint _purchaseTokenAmount,
        uint _minRate,
        uint deadline,
        address _to
    ) external ensure(deadline) {

        uint purchaseClassId = _purchaseClassId;
        uint debondClassId = _DbitClassId;
        uint purchaseTokenAmount = _purchaseTokenAmount;
        address to = _to;
        uint minRate = _minRate;

        if (!canPurchase[purchaseClassId][debondClassId]) {
            revert PairNotAllowed();
        }
        uint _interestRate = interestRate(purchaseClassId, debondClassId, purchaseTokenAmount, PurchaseMethod.Staking);
        if (_interestRate < minRate){
            revert RateNotHighEnough(_interestRate, minRate);
        }
        (address purchaseTokenAddress,,) = classValues(purchaseClassId);
        _mintingProcessForDbitWithElse(purchaseTokenAmount, purchaseTokenAddress, to);
        _issuingProcessStaking(purchaseClassId, purchaseTokenAmount, purchaseTokenAddress, debondClassId, _interestRate, to);
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
                uint amount = convertToDbit(uint128(purchaseTokenAmount), purchaseTokenAddress); //todo : do the same everywhere.
                issueBonds(to, debondClassId, amount.mul(rate));
        }

        function _mintingProcessForDbitWithElse(
            uint purchaseTokenAmount,
            address purchaseTokenAddress,
            address to
            ) internal {
                uint amountDBITToMint = convertToDbit(uint128(purchaseTokenAmount), purchaseTokenAddress); //todo : verify if conversion is possible.
                IERC20(purchaseTokenAddress).transferFrom(to, address(apm), purchaseTokenAmount);
                IDebondToken(DBITAddress).mintCollateralisedSupply(address(apm), amountDBITToMint);
                updateWhenAddLiquidity(purchaseTokenAmount, amountDBITToMint, purchaseTokenAddress, DBITAddress);
        }

    //############buybonds Staking method  DbitToDgov##############

        function stakeForDgovBondWithDbit(
            uint _purchaseClassId, //should it be hardcode? or it can change in debond data?
            uint _debondClassId, 
            uint _purchaseDbitAmount,
            uint _minRate,
            uint deadline,
            address _to 
            ) external  ensure(deadline) { 

        uint purchaseClassId = _purchaseClassId;
        uint debondClassId = _debondClassId;
        uint purchaseTokenAmount = _purchaseDbitAmount;
        address to = _to;
        uint minRate = _minRate;

            if (!canPurchase[purchaseClassId][debondClassId]) {
                revert PairNotAllowed();
            }
            (address debondTokenAddress,,) = classValues(debondClassId);
            uint _interestRate = interestRate(purchaseClassId, debondClassId, purchaseTokenAmount, PurchaseMethod.Staking);
            if (_interestRate < minRate){
                revert RateNotHighEnough(_interestRate, minRate);
            }
            (address purchaseTokenAddress,,) = classValues(purchaseClassId);
            _mintingProcessDgovWithDbit(debondTokenAddress, purchaseTokenAmount, purchaseTokenAddress, to);
            _issuingProcessStaking(purchaseClassId, purchaseTokenAmount, purchaseTokenAddress, debondClassId, _interestRate, to);
        }

        function _mintingProcessDgovWithDbit(
            address debondTokenAddress,
            uint purchaseDbitAmount,
            address purchaseTokenAddress,
            address to
            ) internal {
                uint amountDGOVToMint = convertDbitToDgov(purchaseDbitAmount);
                IERC20(purchaseTokenAddress).transferFrom(to, address(apm), purchaseDbitAmount);
                IDebondToken(debondTokenAddress).mintCollateralisedSupply(address(apm), amountDGOVToMint);
                updateWhenAddLiquidity(purchaseDbitAmount, amountDGOVToMint,  purchaseTokenAddress,  debondTokenAddress);
        }

    //############buybonds Staking method  else ToDgov############## else is not dbit not eth not dgov

    function stakeForDgovBondWithElse(
        uint _purchaseClassId,
        uint _debondClassId,
        uint _purchaseTokenAmount,
        uint _minRate,
        uint deadline,
        address _to
    ) external ensure(deadline) {

        uint purchaseClassId = _purchaseClassId;
        uint debondClassId = _debondClassId;
        uint purchaseTokenAmount = _purchaseTokenAmount;
        address to = _to;
        uint minRate = _minRate;

        if (!canPurchase[purchaseClassId][debondClassId]) {
            revert PairNotAllowed();
        }
        (address debondTokenAddress,,) = classValues(debondClassId);
        uint _interestRate = interestRate(purchaseClassId, debondClassId, purchaseTokenAmount, PurchaseMethod.Staking);
        if (_interestRate < minRate){
            revert RateNotHighEnough(_interestRate, minRate);
        }
        (address purchaseTokenAddress,,) = classValues(purchaseClassId);

        _mintingProcessForDgovWithElse(debondTokenAddress, purchaseTokenAmount, purchaseTokenAddress, to);
        _issuingProcessStaking(purchaseClassId, purchaseTokenAmount, purchaseTokenAddress, debondClassId, _interestRate, to);
        }

        function _mintingProcessForDgovWithElse(
            address debondTokenAddress,
            uint purchaseTokenAmount,
            address purchaseTokenAddress,
            address to
            ) internal {
                uint amountDBITToMint = convertToDbit(uint128(purchaseTokenAmount), purchaseTokenAddress); //need cdp from usd to dgov
                uint amountDGOVToMint = convertDbitToDgov(amountDBITToMint);
                IERC20(purchaseTokenAddress).transferFrom(to, address(apm), purchaseTokenAmount);
                IDebondToken(debondTokenAddress).mintCollateralisedSupply(address(apm), amountDGOVToMint);
                IDebondToken(debondTokenAddress).mintCollateralisedSupply(address(apm), 2 * amountDBITToMint);
                updateWhenAddLiquidity(purchaseTokenAmount, amountDBITToMint,  purchaseTokenAddress,  DBITAddress);
                updateWhenAddLiquidity(amountDBITToMint, amountDGOVToMint,  DBITAddress,  debondTokenAddress);

    }

    //############buybonds Buying method not eth to dbit##############

    function buyforDbitBondWithElse(//else is not eth not dbit
        uint _purchaseClassId,
        uint _debondClassId,
        uint _purchaseTokenAmount,
        uint _minRate,
        uint deadline,
        address _to
    ) external ensure(deadline) {

        uint purchaseClassId = _purchaseClassId;
        uint debondClassId = _debondClassId;
        uint purchaseTokenAmount = _purchaseTokenAmount;
        address to = _to;
        uint minRate = _minRate;

        if (!canPurchase[purchaseClassId][debondClassId]) {
            revert PairNotAllowed();
        }
        uint _interestRate = interestRate(purchaseClassId, debondClassId, purchaseTokenAmount, PurchaseMethod.Buying);
        if (_interestRate < minRate){
            revert RateNotHighEnough(_interestRate, minRate);
        }
        (address purchaseTokenAddress,,) = classValues(purchaseClassId);

        _mintingProcessForDbitWithElse(purchaseTokenAmount, purchaseTokenAddress, to);
        _issuingProcessBuying(purchaseTokenAmount, purchaseTokenAddress, DBITAddress, debondClassId, _interestRate, to);
        }

        function _issuingProcessBuying(
            uint purchaseTokenAmount,
            address purchaseTokenAddress,
            address debondTokenAddress,
            uint debondClassId,
            uint rate,
            address to
            ) internal {
                (uint reserveA, uint reserveB) = getReserves(purchaseTokenAddress, debondTokenAddress);
                uint amount = quote(purchaseTokenAmount, reserveA, reserveB);

                issueBonds(to, debondClassId, amount + amount.mul(rate));
        }


    //############buybonds Buying method DbitToDgov##############


    function buyForDgovBondWithDbit(
        uint _purchaseClassId,
        uint _debondClassId,
        uint _purchaseTokenAmount,
        uint _minRate,
        uint deadline,
        address _to
    ) external ensure(deadline) {

        uint purchaseClassId = _purchaseClassId;
        uint debondClassId = _debondClassId;
        uint purchaseTokenAmount = _purchaseTokenAmount;
        address to = _to;
        uint minRate = _minRate;

        if (!canPurchase[purchaseClassId][debondClassId]) {
            revert PairNotAllowed();
        }
        (address debondTokenAddress,,) = classValues(debondClassId);
        uint _interestRate = interestRate(purchaseClassId, debondClassId, purchaseTokenAmount, PurchaseMethod.Buying);
        if (_interestRate < minRate){
            revert RateNotHighEnough(_interestRate, minRate);
        }
        (address purchaseTokenAddress,,) = classValues(purchaseClassId);
        _mintingProcessDgovWithDbit(debondTokenAddress, purchaseTokenAmount, purchaseTokenAddress, to);

        _issuingProcessBuying(purchaseTokenAmount, purchaseTokenAddress, DBITAddress, debondClassId, _interestRate, to);
        }
        

    //############buybonds Buying method else ToDgov############## else is not dbit not eth

    function buyForDgovBondWithElse(
        uint _purchaseClassId,
        uint _debondClassId,
        uint _purchaseTokenAmount,
        uint _minRate,
        uint deadline,
        address _to
    ) external ensure(deadline) {

        uint purchaseClassId = _purchaseClassId;
        uint debondClassId = _debondClassId;
        uint purchaseTokenAmount = _purchaseTokenAmount;
        address to = _to;
        uint minRate = _minRate;

        if (!canPurchase[purchaseClassId][debondClassId]) {
            revert PairNotAllowed();
        }
        (address debondTokenAddress,,) = classValues(debondClassId);
        uint _interestRate = interestRate(purchaseClassId, debondClassId, purchaseTokenAmount, PurchaseMethod.Buying);
        if (_interestRate < minRate){
            revert RateNotHighEnough(_interestRate, minRate);
        }
        (address purchaseTokenAddress,,) = classValues(purchaseClassId);
        _mintingProcessForDgovWithElse(debondTokenAddress, purchaseTokenAmount, purchaseTokenAddress, to);

        _issuingProcessBuying(purchaseTokenAmount, purchaseTokenAddress, DBITAddress, debondClassId, _interestRate, to);
        }


    //############buybonds Staking method  ETH To DBIT############## 

    function stakeForDbitBondWithEth(
        uint _WETHClassId, // token added  //here it's eth
        uint _debondClassId, // token to mint
    //uint _purchaseTokenAmount,
        uint _minRate,
        uint deadline,
        address _to
    ) external payable ensure(deadline) {

        uint purchaseClassId = _WETHClassId;
        uint debondClassId = _debondClassId;
        uint purchaseTokenAmount = msg.value;
        address to = _to;
        uint minRate = _minRate;

        if (!canPurchase[purchaseClassId][debondClassId]) {
            revert PairNotAllowed();
        }

        uint _interestRate = interestRate(purchaseClassId, debondClassId, purchaseTokenAmount, PurchaseMethod.Staking);
        if (_interestRate < minRate){
            revert RateNotHighEnough(_interestRate, minRate);
        }

        (address purchaseTokenAddress,,) = classValues(purchaseClassId);
        (address debondTokenAddress,,) = classValues(debondClassId);

        _mintingProcessETHWithDbit(debondTokenAddress, purchaseTokenAmount);
        _issuingProcessStaking(purchaseClassId, purchaseTokenAmount, purchaseTokenAddress, debondClassId, _interestRate, to);
    }

    function _mintingProcessETHWithDbit(
        address debondTokenAddress,
        uint purchaseETHAmount
    ) internal {
        uint amountDBITToMint = convertToDbit(uint128(purchaseETHAmount), WETHAddress);
        IWeth(WETHAddress).deposit{value : purchaseETHAmount}();
        assert(IWeth(WETHAddress).transfer(address(apm), purchaseETHAmount));
        IDebondToken(debondTokenAddress).mintCollateralisedSupply(address(apm), amountDBITToMint);
        updateWhenAddLiquidity(purchaseETHAmount, amountDBITToMint, WETHAddress, debondTokenAddress);
    }


    //############buybonds Staking method  ETH To Dgov############## 

    function stakeForDgovBondWithEth(
        uint _WETHClassId, // token added  //here it's eth
        uint _debondClassId, // token to mint
    //uint _purchaseTokenAmount,
    //        PurchaseMethod _purchaseMethod,
        uint _minRate,
        uint deadline,
        address _to
    ) external payable ensure(deadline) {

        uint purchaseClassId = _WETHClassId;
        uint debondClassId = _debondClassId;
        uint purchaseTokenAmount = msg.value;
        address to = _to;
        uint minRate = _minRate;

        if (!canPurchase[purchaseClassId][debondClassId]) {
            revert PairNotAllowed();
        }


        uint _interestRate = interestRate(purchaseClassId, debondClassId, purchaseTokenAmount, PurchaseMethod.Staking);
        if (_interestRate < minRate){
            revert RateNotHighEnough(_interestRate, minRate);
        }

        (address purchaseTokenAddress,,) = classValues(purchaseClassId);
        (address debondTokenAddress,,) = classValues(debondClassId);

        _mintingProcessETHWithDgov(debondTokenAddress, purchaseTokenAmount);
        _issuingProcessStaking(purchaseClassId, purchaseTokenAmount, purchaseTokenAddress, debondClassId, _interestRate, to);
    }

        function _mintingProcessETHWithDgov(
            address debondTokenAddress,
            uint purchaseETHAmount
            ) internal {
            uint amountDBITToMint = convertToDbit(uint128(purchaseETHAmount), WETHAddress); //need cdp from usd to dgov
            uint amountDGOVToMint = convertDbitToDgov(amountDBITToMint);
            //IERC20(purchaseTokenAddress).transferFrom(msg.sender, address(apm), purchaseTokenAmount);
            IWeth(WETHAddress).deposit{value: purchaseETHAmount}();
            assert(IWeth(WETHAddress).transfer(address(apm), purchaseETHAmount));
            IDebondToken(debondTokenAddress).mintCollateralisedSupply(address(apm), amountDGOVToMint);
            IDebondToken(debondTokenAddress).mintCollateralisedSupply(address(apm), 2 * amountDBITToMint);
            updateWhenAddLiquidity(purchaseETHAmount, amountDBITToMint,  WETHAddress,  DBITAddress);
            updateWhenAddLiquidity(amountDBITToMint, amountDGOVToMint,  DBITAddress,  debondTokenAddress);
        }


    //############buybonds Buying method  ETH To DBIT############## 
    function buyforDbitBondWithEth(//else is not eth not dbit
        uint _purchaseClassId,
        uint _debondClassId,
        uint _purchaseETHAmount,
        uint _minRate,
        uint deadline,
        address _to
    ) external payable ensure(deadline) {

        uint purchaseClassId = _purchaseClassId;
        uint debondClassId = _debondClassId;
        uint purchaseTokenAmount = _purchaseETHAmount;
        address to = _to;
        uint minRate = _minRate;

        uint _interestRate = interestRate(purchaseClassId, debondClassId, purchaseTokenAmount, PurchaseMethod.Buying);
        if (_interestRate < minRate){
            revert RateNotHighEnough(_interestRate, minRate);
        }

        (address purchaseTokenAddress,,) = classValues(purchaseClassId);
        _mintingProcessForDbitWithEth(purchaseTokenAmount, purchaseTokenAddress);
        _issuingProcessBuying(purchaseTokenAmount, purchaseTokenAddress, DBITAddress, debondClassId, _interestRate, to);
            }

            function _mintingProcessForDbitWithEth(
                uint purchaseETHAmount,
                address purchaseTokenAddress
                ) internal {
                uint amountDBITToMint = convertToDbit(uint128(purchaseETHAmount), purchaseTokenAddress);
                IWeth(WETHAddress).deposit{value: purchaseETHAmount}();
                assert(IWeth(WETHAddress).transfer(address(apm), purchaseETHAmount));
                IDebondToken(DBITAddress).mintCollateralisedSupply(address(apm), amountDBITToMint);
                updateWhenAddLiquidity(purchaseETHAmount, amountDBITToMint, purchaseTokenAddress, DBITAddress);
            }


    //############buybonds Buying method  ETH To Dgov##############

    function buyforDgovBondWithEth(//else is not eth not dbit
        uint _purchaseClassId,
        uint _debondClassId,
        uint _purchaseETHAmount,
        uint _minRate,
        uint deadline,
        address _to
    ) external payable ensure(deadline) {

        uint purchaseClassId = _purchaseClassId;
        uint debondClassId = _debondClassId;
        uint purchaseTokenAmount = _purchaseETHAmount;
        address to = _to;
        uint minRate = _minRate;

        uint _interestRate = interestRate(purchaseClassId, debondClassId, purchaseTokenAmount, PurchaseMethod.Buying);
        if (_interestRate < minRate){
            revert RateNotHighEnough(_interestRate, minRate);
        }
        (address purchaseTokenAddress,,) = classValues(purchaseClassId);
        _mintingProcessForDgovWithEth(purchaseTokenAmount, purchaseTokenAddress);
        _issuingProcessBuying(purchaseTokenAmount, purchaseTokenAddress, DBITAddress, debondClassId, _interestRate, to);
            }

            function _mintingProcessForDgovWithEth(
                uint purchaseETHAmount,
                address purchaseTokenAddress
                ) internal {
                uint amountDBITToMint = convertToDbit(uint128(purchaseETHAmount), purchaseTokenAddress);
                uint amountDGOVToMint = convertDbitToDgov(amountDBITToMint);
                IWeth(WETHAddress).deposit{value: purchaseETHAmount}();
                assert(IWeth(WETHAddress).transfer(address(apm), purchaseETHAmount));
                IDebondToken(DGOVAddress).mintCollateralisedSupply(address(apm), amountDGOVToMint);
                IDebondToken(DBITAddress).mintCollateralisedSupply(address(apm), 2 * amountDBITToMint);
                updateWhenAddLiquidity(purchaseETHAmount, amountDBITToMint,  purchaseTokenAddress,  DBITAddress);
                updateWhenAddLiquidity(amountDBITToMint, amountDGOVToMint,  DBITAddress,  DGOVAddress);
            }
//##############REDEEM BONDS ##############:

    function redeemBonds(
        uint classId,
        uint nonceId,
        uint amount
    ) external {
        //1. redeem the bonds (will fail if not maturity date exceeded)
        _redeemERC3475(msg.sender, classId, nonceId, amount);

        (address tokenAddress,,) = classValues(classId);
        removeLiquidity(msg.sender, tokenAddress, amount);
    }

    function interestRate(
        uint _purchaseTokenClassId,
        uint _debondTokenClassId,
        uint _purchaseTokenAmount,
        PurchaseMethod purchaseMethod
    ) public view returns (uint) {

        if (!canPurchase[_purchaseTokenClassId][_debondTokenClassId]) {
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

    function _getCalculatedRate(uint fixRateSupply, uint floatRateSupply) private pure returns (uint fixedRate, uint floatingRate) {
        floatingRate = DebondMath.floatingInterestRate(fixRateSupply, floatRateSupply, BENCHMARK_RATE_DECIMAL_18);
        fixedRate = 2 * BENCHMARK_RATE_DECIMAL_18 - floatingRate;
    }

    function _getDefaultRate() private pure returns (uint fixRate, uint floatRate) {
        fixRate = 2 * BENCHMARK_RATE_DECIMAL_18 / 3;
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
    function convertToDbit(uint128 _amountToken, address _tokenAddress) private view returns(uint256 amountDBIT) {

        uint256 tokenToUsd = _convertTokenToUsd(_amountToken, _tokenAddress);
        uint256 rate = _cdpUsdToDBIT();

        amountDBIT = tokenToUsd.mul(rate);  //1e6 x 1e12 x 1e18 = 1e18
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
    function convertDbitToDgov(uint256 _amountDBIT) private view returns(uint256 amountDGOV) {
        uint256 rate = _cdpDbitToDgov();
        amountDGOV = _amountDBIT.mul(rate);
    }
}
