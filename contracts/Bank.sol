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


contract Bank is APMRouter, BankBondManager, Ownable {

    using DebondMath for uint256;
    using SafeERC20 for IERC20;

    IOracle oracle;
    enum PurchaseMethod {Buying, Staking}
    //uint public constant BASE_TIMESTAMP = 1646089200; // 2022-03-01 00:00
    //uint public constant DIFF_TIME_NEW_NONCE = 24 * 3600; // every 24h we crate a new nonce.
    //uint public constant BENCHMARK_RATE_DECIMAL_18 = 5 * 10**16;
    //address immutable debondBondAddress;
    address immutable DBITAddress;
    address immutable DGOVAddress;
    address immutable USDCAddress;
    address immutable WETH; //TODO

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
        //debondData = IData(dataAddress);
        //bond = IDebondBond(bondAddress);
        //debondBondAddress = bondAddress;
        DBITAddress = _DBITAddress;
        DGOVAddress = _DGOVAddress;
        oracle = IOracle(oracleAddress);
        USDCAddress = usdcAddress;
        WETH = _weth;
        //TODO : call _update to update fee param!!!
    
    }

    function initializeApp(address daiAddress, address usdtAddress) external onlyOwner {
        require(!init, "BankContract Error: already initiated");
        init = true;
        uint SIX_M_PERIOD = 180 * 30; // 1 hour period for tests

        _createClass(0, "DBIT", InterestRateType.FixedRate, DBITAddress, SIX_M_PERIOD);
        _createClass(1, "USDC", InterestRateType.FixedRate, USDCAddress, SIX_M_PERIOD);
        _createClass(2, "USDT", InterestRateType.FixedRate, usdtAddress, SIX_M_PERIOD);
        _createClass(3, "DAI", InterestRateType.FixedRate, daiAddress, SIX_M_PERIOD);
        _createClass(4, "DGOV", InterestRateType.FixedRate, DGOVAddress, SIX_M_PERIOD);

        _createClass(5, "DBIT", InterestRateType.FloatingRate, DBITAddress, SIX_M_PERIOD);
        _createClass(6, "USDC", InterestRateType.FloatingRate, USDCAddress, SIX_M_PERIOD);
        _createClass(7, "USDT", InterestRateType.FloatingRate, usdtAddress, SIX_M_PERIOD);
        _createClass(8, "DAI", InterestRateType.FloatingRate, daiAddress, SIX_M_PERIOD);
        _createClass(9, "DGOV", InterestRateType.FloatingRate, DGOVAddress, SIX_M_PERIOD);

        _updateCanPurchase(1, 0, true);
        _updateCanPurchase(2, 0, true);
        _updateCanPurchase(3, 0, true);
        _updateCanPurchase(0, 4, true);
        _updateCanPurchase(1, 4, true);
        _updateCanPurchase(2, 4, true);
        _updateCanPurchase(3, 4, true);

        _updateCanPurchase(6, 5, true);
        _updateCanPurchase(7, 5, true);
        _updateCanPurchase(8, 5, true);
        _updateCanPurchase(5, 9, true);
        _updateCanPurchase(6, 9, true);
        _updateCanPurchase(7, 9, true);
        _updateCanPurchase(8, 9, true);
    }



    modifier ensure(uint deadline) {
        if (deadline >= block.timestamp) {
            revert Deadline(deadline, block.timestamp);
        } 
        _; 
    }

//##############BUY BONDS#############

        struct BankData { //to avoid stack too deep error
            uint purchaseClassId;
            uint debondClassId;
            uint purchaseTokenAmount;
            PurchaseMethod purchaseMethod;
            address to;
            uint minRate;
        }
    
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
            //uint deadline  
            //TODO : param to instead of msg.sender 
            ) external  { //ensure(deadline)

            BankData memory bankData;
            bankData.purchaseClassId = _purchaseClassId;
            bankData.debondClassId = _debondClassId;
            bankData.purchaseTokenAmount = _purchaseTokenAmount;
            bankData.purchaseMethod = _purchaseMethod;
            bankData.minRate = _minRate;

            

            if ( ! canPurchase[bankData.purchaseClassId][bankData.debondClassId]) {   //todo : changer les 3 lignes
                revert PairNotAllowed();
            } 
            (address purchaseTokenAddress,,) = classValues(bankData.purchaseClassId);
            (address debondTokenAddress, InterestRateType interestRateType,) = classValues(bankData.debondClassId);
            
            _mintingProcess(debondTokenAddress, bankData.purchaseTokenAmount, purchaseTokenAddress);
        
            (uint fixedRate, uint floatingRate) = interestRate(bankData.purchaseClassId, bankData.debondClassId, bankData.purchaseTokenAmount, bankData.purchaseMethod);
            _issuingProcess(bankData.purchaseMethod, bankData.purchaseClassId, bankData.purchaseTokenAmount, purchaseTokenAddress, debondTokenAddress, bankData.debondClassId, interestRateType, fixedRate, floatingRate, bankData.minRate);
        }

        //TODO : time 20 min                 : SEE FRONTEND
        //todo : require interest high enough: OK


        /**
        * @dev mint the bond to the user
        * @param purchaseMethod buying method or Staking method
        * @param purchaseClassId classId of the token added by the user (given by frontend)
        * @param purchaseTokenAmount amount of token to add
        * @param purchaseTokenAddress address of token to add
        * @param debondTokenAddress  address of the debond token to mint (dgov or dbit)
        * @param debondClassId class id of the debond token to mint (dgov or dbit)
        * @param interestRateType fixed rate or floating rate
        * @param fixedRate fixed rate value
        * @param floatingRate floating rate value
        * @param minRate minimum Rate that a user is willing to accept. similar to slippage    
        */
        

        function _issuingProcess( //todo : _ for internal
            PurchaseMethod purchaseMethod,
            uint purchaseClassId,
            uint purchaseTokenAmount,
            address purchaseTokenAddress,
            address debondTokenAddress,
            uint debondClassId,
            InterestRateType interestRateType,
            uint fixedRate,
            uint floatingRate,
            uint minRate
            ) internal {
            if (purchaseMethod == PurchaseMethod.Staking) {
                issueBonds(msg.sender, purchaseClassId, purchaseTokenAmount);
                (uint reserveA, uint reserveB) = getReserves(purchaseTokenAddress, debondTokenAddress);
                //if reserve == 0 : use cdp price instead of quote? See with yu
                //do we have to handle the case where reserve = 0? or when deploying, we put some liquidity?
                //we first update reserves when buying bond so it should never be 0
                uint amount = quote(purchaseTokenAmount, reserveA, reserveB);
                uint rate = interestRateType == InterestRateType.FixedRate ? fixedRate : floatingRate;
                if (rate < minRate){
                    revert RateNotHighEnough(rate, minRate);
                }
                issueBonds(msg.sender, debondClassId, amount.mul(rate));
            }
            else if (purchaseMethod == PurchaseMethod.Buying) {
                (uint reserveA, uint reserveB) = getReserves(purchaseTokenAddress, debondTokenAddress);
                uint amount = quote(purchaseTokenAmount, reserveA, reserveB);
                uint rate = interestRateType ==  InterestRateType.FixedRate ? fixedRate : floatingRate;
                if (rate < minRate){
                    revert RateNotHighEnough(rate, minRate);
                }
                issueBonds(msg.sender, debondClassId, amount + amount.mul(rate)); // here the interest calculation is hardcoded. require the interest is enough high
            }
        }


        function _mintingProcess(
            address debondTokenAddress,
            uint purchaseTokenAmount,
            address purchaseTokenAddress
            ) internal {
            if (debondTokenAddress == DBITAddress) {
                //TODO : require : purchase token is not dbit, not dgov
                uint amountDBITToMint = convertToDbit(uint128(purchaseTokenAmount), purchaseTokenAddress); //todo : verivy if conversion is possible.
                IERC20(purchaseTokenAddress).transferFrom(msg.sender, address(apm), purchaseTokenAmount);
                IDebondToken(debondTokenAddress).mintCollateralisedSupply(address(apm), amountDBITToMint);
                updateWhenAddLiquidity(purchaseTokenAmount, amountDBITToMint, purchaseTokenAddress, debondTokenAddress);
            }
            else { //else address ==dgov? 
                if (purchaseTokenAddress == DBITAddress) {
                    uint amountDGOVToMint = mintDgovFromDbit(purchaseTokenAmount);
                    IERC20(DBITAddress).transferFrom(msg.sender, address(apm), purchaseTokenAmount);
                    IDebondToken(debondTokenAddress).mintCollateralisedSupply(address(apm), amountDGOVToMint); //todo : check amountDGOVToMint
                    updateWhenAddLiquidity(purchaseTokenAmount, amountDGOVToMint,  DBITAddress,  debondTokenAddress);
                }
                else {
                    uint amountDBITToMint = convertToDbit(uint128(purchaseTokenAmount), purchaseTokenAddress); //need cdp from usd to dgov
                    uint amountDGOVToMint = mintDgovFromDbit(purchaseTokenAmount);
                    IERC20(purchaseTokenAddress).transferFrom(msg.sender, address(apm), purchaseTokenAmount);
                    IDebondToken(DGOVAddress).mintCollateralisedSupply(address(apm), amountDGOVToMint);
                    IDebondToken(DBITAddress).mintCollateralisedSupply(address(apm), 2 * amountDBITToMint);  //TODO : check here
                    updateWhenAddLiquidity(purchaseTokenAmount, amountDBITToMint,  purchaseTokenAddress,  DBITAddress);
                    updateWhenAddLiquidity(amountDBITToMint, amountDGOVToMint,  DBITAddress,  debondTokenAddress);
                }

            }
        }


            //todo : put this in one addliq function


    //############buybonds staking method  dbit with else (else is Not eth, not dgov, not dbit)  ##############

        function stakeForDbitBondWithElse(
            uint _purchaseClassId,
            uint _DbitClassId, 
            uint _purchaseTokenAmount,
            uint _minRate,
            uint deadline,
            address _to  
            ) external ensure(deadline) { 

            BankData memory bankData;
            bankData.purchaseClassId = _purchaseClassId;
            bankData.debondClassId = _DbitClassId;
            bankData.purchaseTokenAmount = _purchaseTokenAmount;
            bankData.to = _to;
            bankData.minRate = _minRate;

            if ( ! canPurchase[bankData.purchaseClassId][bankData.debondClassId]) {
                revert PairNotAllowed();
            } 

            (address purchaseTokenAddress,,) = classValues(bankData.purchaseClassId); //todo : check bankData. everywhere
            (, InterestRateType interestRateType,) = classValues(bankData.debondClassId);

            _mintingProcessForDbitWithElse(bankData.purchaseTokenAmount, purchaseTokenAddress);
        
            (uint fixedRate, uint floatingRate) = interestRate(bankData.purchaseClassId, bankData.debondClassId, bankData.purchaseTokenAmount, PurchaseMethod.Staking);
            uint amount = _issuingProcessStaking(bankData.purchaseClassId, bankData.purchaseTokenAmount, purchaseTokenAddress, bankData.debondClassId, interestRateType, fixedRate, floatingRate, bankData.minRate, bankData.to);
            emit test(amount);
        }

        function _issuingProcessStaking(
            uint purchaseClassId,
            uint purchaseTokenAmount,
            address purchaseTokenAddress,
            uint debondClassId,
            InterestRateType interestRateType,
            uint fixedRate,
            uint floatingRate,
            uint minRate,
            address to
            ) public returns(uint amount) {
                issueBonds(to, purchaseClassId, purchaseTokenAmount);
                amount = convertToDbit(uint128(purchaseTokenAmount), purchaseTokenAddress); //todo : do the same everywhere.
                uint rate = interestRateType ==  InterestRateType.FixedRate ? fixedRate : floatingRate;
                if (rate < minRate){
                    revert RateNotHighEnough(rate, minRate);
                }
                issueBonds(to, debondClassId, amount.mul(rate));
        }

        function _mintingProcessForDbitWithElse(
            uint purchaseTokenAmount,
            address purchaseTokenAddress
            ) internal {
            uint amountDBITToMint = convertToDbit(uint128(purchaseTokenAmount), purchaseTokenAddress); //todo : ferivy if conversion is possible.
            IERC20(purchaseTokenAddress).transferFrom(msg.sender, address(apm), purchaseTokenAmount);
            IDebondToken(DBITAddress).mintCollateralisedSupply(address(apm), amountDBITToMint);
            updateWhenAddLiquidity(purchaseTokenAmount, amountDBITToMint, purchaseTokenAddress, DBITAddress);
        }

    //############buybonds Staking method  DbitToDgov##############

        function stakeForDgovBondWithDbit(
            uint _purchaseClassId, //should it be hardcode? or it can change in debond data?
            uint _debondClassId, 
            uint _purchaseTokenAmount,
            uint _minRate,
            uint deadline,
            address _to 
            ) external  ensure(deadline) { 

            BankData memory bankData;
            bankData.purchaseClassId = _purchaseClassId;
            bankData.debondClassId = _debondClassId;
            bankData.purchaseTokenAmount = _purchaseTokenAmount;
            bankData.to = _to;
            bankData.minRate = _minRate;

            if ( ! canPurchase[bankData.purchaseClassId][bankData.debondClassId]) {  
                revert PairNotAllowed();
            } 
            (address purchaseTokenAddress,,) = classValues(bankData.purchaseClassId);
            (address debondTokenAddress, InterestRateType interestRateType,) = classValues(bankData.debondClassId);
            
            _mintingProcessDgovWithDbit(debondTokenAddress, bankData.purchaseTokenAmount, purchaseTokenAddress);
        
            (uint fixedRate, uint floatingRate) = interestRate(bankData.purchaseClassId, bankData.debondClassId, bankData.purchaseTokenAmount, PurchaseMethod.Staking);
            _issuingProcessStaking(bankData.purchaseClassId, bankData.purchaseTokenAmount, purchaseTokenAddress, bankData.debondClassId, interestRateType, fixedRate, floatingRate, bankData.minRate, bankData.to);
        }

        function _mintingProcessDgovWithDbit(
            address debondTokenAddress,
            uint purchaseTokenAmount,
            address purchaseTokenAddress
            ) internal {
                uint amountBToMint = mintDgovFromDbit(purchaseTokenAmount);
                IERC20(purchaseTokenAddress).transferFrom(msg.sender, address(apm), purchaseTokenAmount);
                IDebondToken(debondTokenAddress).mintCollateralisedSupply(address(apm), amountBToMint);
                updateWhenAddLiquidity(purchaseTokenAmount, amountBToMint,  purchaseTokenAddress,  debondTokenAddress);
        }

    //############buybonds Staking method  else ToDgov############## else is not dbit not eth not dgov

        function stakeForDgovBondWithElse(
            uint _purchaseClassId,
            uint _debondClassId, 
            uint _purchaseTokenAmount,
            uint _minRate,
            uint deadline,  
            address _to
            ) external  ensure(deadline) { 

            BankData memory bankData;
            bankData.purchaseClassId = _purchaseClassId;
            bankData.debondClassId = _debondClassId;
            bankData.purchaseTokenAmount = _purchaseTokenAmount;
            bankData.to = _to;
            bankData.minRate = _minRate;

            if ( ! canPurchase[bankData.purchaseClassId][bankData.debondClassId]) {  
                revert PairNotAllowed();
            } 
            (address purchaseTokenAddress,,) = classValues(bankData.purchaseClassId);
            (address debondTokenAddress, InterestRateType interestRateType,) = classValues(bankData.debondClassId);
            
            _mintingProcessForDgovWithElse(debondTokenAddress, bankData.purchaseTokenAmount, purchaseTokenAddress);
        
            (uint fixedRate, uint floatingRate) = interestRate(bankData.purchaseClassId, bankData.debondClassId, bankData.purchaseTokenAmount, PurchaseMethod.Staking);
            _issuingProcessStaking(bankData.purchaseClassId, bankData.purchaseTokenAmount, purchaseTokenAddress, bankData.debondClassId, interestRateType, fixedRate, floatingRate, bankData.minRate, bankData.to);
        }

        function _mintingProcessForDgovWithElse(
            address debondTokenAddress,
            uint purchaseTokenAmount,
            address purchaseTokenAddress
            ) internal { 
                uint amountDBITToMint = convertToDbit(uint128(purchaseTokenAmount), purchaseTokenAddress); //need cdp from usd to dgov
                uint amountDGOVToMint = mintDgovFromDbit(purchaseTokenAmount);
                IERC20(purchaseTokenAddress).transferFrom(msg.sender, address(apm), purchaseTokenAmount);
                IDebondToken(debondTokenAddress).mintCollateralisedSupply(address(apm), amountDGOVToMint);
                IDebondToken(debondTokenAddress).mintCollateralisedSupply(address(apm), 2 * amountDBITToMint);
                updateWhenAddLiquidity(purchaseTokenAmount, amountDBITToMint,  purchaseTokenAddress,  DBITAddress);
                updateWhenAddLiquidity(amountDBITToMint, amountDGOVToMint,  DBITAddress,  debondTokenAddress);

        }
        
    //############buybonds Buying method not eth to dbit##############

        function buyforDbitBondWithElse( //else is not eth not dbit   
            uint _purchaseClassId,
            uint _debondClassId, 
            uint _purchaseTokenAmount,
            uint _minRate,
            uint deadline,  
            address _to
            ) external ensure(deadline) { 

            BankData memory bankData;
            bankData.purchaseClassId = _purchaseClassId;
            bankData.debondClassId = _debondClassId;
            bankData.purchaseTokenAmount = _purchaseTokenAmount;
            bankData.to = _to;
            bankData.minRate = _minRate;

            if ( ! canPurchase[bankData.purchaseClassId][bankData.debondClassId]) {  
                revert PairNotAllowed();
            } 
            (address purchaseTokenAddress,,) = classValues(bankData.purchaseClassId);
            (, InterestRateType interestRateType,) = classValues(bankData.debondClassId);

            _mintingProcessForDbitWithElse(bankData.purchaseTokenAmount, purchaseTokenAddress);
        
            (uint fixedRate, uint floatingRate) = interestRate(bankData.purchaseClassId, bankData.debondClassId, bankData.purchaseTokenAmount, PurchaseMethod.Buying);
            _issuingProcessBuying(bankData.purchaseTokenAmount, purchaseTokenAddress, DBITAddress, bankData.debondClassId, interestRateType, fixedRate, floatingRate, bankData.minRate, bankData.to);
        }

        function _issuingProcessBuying(
            uint purchaseTokenAmount,
            address purchaseTokenAddress,
            address debondTokenAddress,
            uint debondClassId,
            InterestRateType interestRateType,
            uint fixedRate,
            uint floatingRate,
            uint minRate,
            address to
            ) internal {
                (uint reserveA, uint reserveB) = getReserves(purchaseTokenAddress, debondTokenAddress);
                uint amount = quote(purchaseTokenAmount, reserveA, reserveB);
                uint rate = interestRateType ==  InterestRateType.FixedRate ? fixedRate : floatingRate;
                if (rate < minRate){
                    revert RateNotHighEnough(rate, minRate);
                }
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
            ) external  ensure(deadline) { 

            BankData memory bankData;
            bankData.purchaseClassId = _purchaseClassId;
            bankData.debondClassId = _debondClassId;
            bankData.purchaseTokenAmount = _purchaseTokenAmount;
            bankData.to = _to;
            bankData.minRate = _minRate;

             if ( ! canPurchase[bankData.purchaseClassId][bankData.debondClassId]) {  
                revert PairNotAllowed();
            } 
            (address purchaseTokenAddress,,) = classValues(bankData.purchaseClassId);
            (address debondTokenAddress, InterestRateType interestRateType,) = classValues(bankData.debondClassId);
            
            _mintingProcessDgovWithDbit(debondTokenAddress, bankData.purchaseTokenAmount, purchaseTokenAddress);
        
            (uint fixedRate, uint floatingRate) = interestRate(bankData.purchaseClassId, bankData.debondClassId, bankData.purchaseTokenAmount, PurchaseMethod.Buying);
            _issuingProcessBuying(bankData.purchaseTokenAmount, purchaseTokenAddress, DBITAddress, bankData.debondClassId, interestRateType, fixedRate, floatingRate, bankData.minRate, bankData.to);
        }
        

    //############buybonds Buying method else ToDgov############## else is not dbit not eth

        function buyForDgovBondWithElse(
            uint _purchaseClassId,
            uint _debondClassId, 
            uint _purchaseTokenAmount,
            uint _minRate, 
            uint deadline,  
            address _to
            ) external ensure(deadline)  { 

            BankData memory bankData;
            bankData.purchaseClassId = _purchaseClassId;
            bankData.debondClassId = _debondClassId;
            bankData.purchaseTokenAmount = _purchaseTokenAmount;
            bankData.to = _to;
            bankData.minRate = _minRate;

             if ( ! canPurchase[bankData.purchaseClassId][bankData.debondClassId]) {  
                revert PairNotAllowed();
            } 
            (address purchaseTokenAddress,,) = classValues(bankData.purchaseClassId);
            (address debondTokenAddress, InterestRateType interestRateType,) = classValues(bankData.debondClassId);
            
            _mintingProcessForDgovWithElse(debondTokenAddress, bankData.purchaseTokenAmount, purchaseTokenAddress);
        
            (uint fixedRate, uint floatingRate) = interestRate(bankData.purchaseClassId, bankData.debondClassId, bankData.purchaseTokenAmount, PurchaseMethod.Buying);
            _issuingProcessBuying(bankData.purchaseTokenAmount, purchaseTokenAddress, DBITAddress, bankData.debondClassId, interestRateType, fixedRate, floatingRate, bankData.minRate, bankData.to);
        }


    //############buybonds Staking method  ETH To DBIT############## 

        function stakeForDbitBondWithEth(
                //uint _purchaseClassId, // token added  //here it's eth
                uint _debondClassId, // token to mint
                //uint _purchaseTokenAmount,
                uint _minRate, 
                uint deadline, 
                address _to 
                ) external payable ensure(deadline) { 

                BankData memory bankData;
                bankData.purchaseClassId /*= _purchaseClassId*/;
                bankData.debondClassId = _debondClassId;
                bankData.purchaseTokenAmount = msg.value;
                bankData.to = _to;
                bankData.minRate = _minRate;

                //no need to ckeck if it's allowed
                
                 
                (address purchaseTokenAddress,,) = classValues(bankData.purchaseClassId);
                (address debondTokenAddress, InterestRateType interestRateType,) = classValues(bankData.debondClassId);
                
                _mintingProcessETHWithDbit(debondTokenAddress, bankData.purchaseTokenAmount);
            
                (uint fixedRate, uint floatingRate) = interestRate(bankData.purchaseClassId, bankData.debondClassId, bankData.purchaseTokenAmount, PurchaseMethod.Staking);
                _issuingProcessStaking(bankData.purchaseClassId, bankData.purchaseTokenAmount, purchaseTokenAddress, bankData.debondClassId, interestRateType, fixedRate, floatingRate, bankData.minRate, bankData.to);
            }

            function _mintingProcessETHWithDbit(
                address debondTokenAddress,
                uint purchaseETHAmount
                ) internal {
                uint amountDBITToMint = convertToDbit(uint128(purchaseETHAmount), WETH); //todo : verify if conversion uint128 is possible.
                IWeth(WETH).deposit{value: purchaseETHAmount}();
                assert(IWeth(WETH).transfer(address(apm), purchaseETHAmount)); // see if better methods
                IDebondToken(debondTokenAddress).mintCollateralisedSupply(address(apm), amountDBITToMint);
                updateWhenAddLiquidity(purchaseETHAmount, amountDBITToMint, WETH, debondTokenAddress);
            }


    //############buybonds Staking method  ETH To Dgov############## 

     function stakeForDgovBondWithEth(
            //uint _purchaseClassId, // token added  //here it's eth
            uint _debondClassId, // token to mint
            //uint _purchaseTokenAmount,
            PurchaseMethod _purchaseMethod,
            uint _minRate, 
            uint deadline,
            address _to  
            ) external payable ensure(deadline) { 

            BankData memory bankData;
            bankData.purchaseClassId /*= _purchaseClassId*/;
            bankData.debondClassId = _debondClassId;
            bankData.purchaseTokenAmount = msg.value;
            bankData.purchaseMethod = _purchaseMethod;
            bankData.to = _to;
            bankData.minRate = _minRate;

            //no need to ckeck if it's allowed

             
            (address purchaseTokenAddress,,) = classValues(bankData.purchaseClassId);
            (address debondTokenAddress, InterestRateType interestRateType,) = classValues(bankData.debondClassId);
            
            _mintingProcessETHWithDgov(debondTokenAddress, bankData.purchaseTokenAmount);
        
            (uint fixedRate, uint floatingRate) = interestRate(bankData.purchaseClassId, bankData.debondClassId, bankData.purchaseTokenAmount, PurchaseMethod.Staking);
            _issuingProcessStaking(bankData.purchaseClassId, bankData.purchaseTokenAmount, purchaseTokenAddress, bankData.debondClassId, interestRateType, fixedRate, floatingRate, bankData.minRate, bankData.to);
        }

        function _mintingProcessETHWithDgov(
            address debondTokenAddress,
            uint purchaseETHAmount
            ) internal {
            uint amountDBITToMint = convertToDbit(uint128(purchaseETHAmount), WETH); //need cdp from usd to dgov
            uint amountDGOVToMint = mintDgovFromDbit(purchaseETHAmount);
            //IERC20(purchaseTokenAddress).transferFrom(msg.sender, address(apm), purchaseTokenAmount);
            IWeth(WETH).deposit{value: purchaseETHAmount}();
            assert(IWeth(WETH).transfer(address(apm), purchaseETHAmount)); 
            IDebondToken(debondTokenAddress).mintCollateralisedSupply(address(apm), amountDGOVToMint);
            IDebondToken(debondTokenAddress).mintCollateralisedSupply(address(apm), 2 * amountDBITToMint);
            updateWhenAddLiquidity(purchaseETHAmount, amountDBITToMint,  WETH,  DBITAddress);
            updateWhenAddLiquidity(amountDBITToMint, amountDGOVToMint,  DBITAddress,  debondTokenAddress);
        }


    //############buybonds Buying method  ETH To DBIT############## 
        function buyforDbitBondWithEth( //else is not eth not dbit   
                uint _purchaseClassId,
                uint _debondClassId, 
                uint _purchaseETHAmount,
                uint _minRate, 
                uint deadline,  
                address _to 
                ) external payable ensure(deadline) {

                BankData memory bankData;
                bankData.purchaseClassId = _purchaseClassId;
                bankData.debondClassId = _debondClassId;
                bankData.purchaseTokenAmount = _purchaseETHAmount;
                bankData.to = _to;
                bankData.minRate = _minRate;
                 
                (address purchaseTokenAddress,,) = classValues(bankData.purchaseClassId);
                (, InterestRateType interestRateType,) = classValues(bankData.debondClassId);

                _mintingProcessForDbitWithEth(bankData.purchaseTokenAmount, purchaseTokenAddress);
            
                (uint fixedRate, uint floatingRate) = interestRate(bankData.purchaseClassId, bankData.debondClassId, bankData.purchaseTokenAmount, PurchaseMethod.Buying);
                _issuingProcessBuying(bankData.purchaseTokenAmount, purchaseTokenAddress, DBITAddress, bankData.debondClassId, interestRateType, fixedRate, floatingRate, bankData.minRate, bankData.to);
            }

            function _mintingProcessForDbitWithEth(
                uint purchaseETHAmount,
                address purchaseTokenAddress
                ) internal {
                uint amountDBITToMint = convertToDbit(uint128(purchaseETHAmount), purchaseTokenAddress); //todo : ferivy if conversion is possible.
                IWeth(WETH).deposit{value: purchaseETHAmount}();
                assert(IWeth(WETH).transfer(address(apm), purchaseETHAmount)); 
                IDebondToken(DBITAddress).mintCollateralisedSupply(address(apm), amountDBITToMint);
                updateWhenAddLiquidity(purchaseETHAmount, amountDBITToMint, purchaseTokenAddress, DBITAddress);
            }

        
    //############buybonds Buying method  ETH To Dgov##############

        function buyforDgovBondWithEth( //else is not eth not dbit   
                uint _purchaseClassId,
                uint _debondClassId, 
                uint _purchaseETHAmount,
                uint _minRate, 
                uint deadline,  
                address _to 
                ) external payable ensure(deadline) { 

                BankData memory bankData;
                bankData.purchaseClassId = _purchaseClassId;
                bankData.debondClassId = _debondClassId;
                bankData.purchaseTokenAmount = _purchaseETHAmount;
                bankData.to = _to;
                bankData.minRate = _minRate;
                
                (address purchaseTokenAddress,,) = classValues(bankData.purchaseClassId);
                (, InterestRateType interestRateType,) = classValues(bankData.debondClassId);
                
                _mintingProcessForDgovWithEth(bankData.purchaseTokenAmount, purchaseTokenAddress);
            
                (uint fixedRate, uint floatingRate) = interestRate(bankData.purchaseClassId, bankData.debondClassId, bankData.purchaseTokenAmount,  PurchaseMethod.Buying);
                _issuingProcessBuying(bankData.purchaseTokenAmount, purchaseTokenAddress, DBITAddress, bankData.debondClassId, interestRateType, fixedRate, floatingRate, bankData.minRate, bankData.to);
            }

            function _mintingProcessForDgovWithEth(
                uint purchaseETHAmount,
                address purchaseTokenAddress
                ) internal {
                uint amountDBITToMint = convertToDbit(uint128(purchaseETHAmount), purchaseTokenAddress); //need cdp from usd to dgov
                uint amountDGOVToMint = mintDgovFromDbit(purchaseETHAmount);
                IWeth(WETH).deposit{value: purchaseETHAmount}();
                assert(IWeth(WETH).transfer(address(apm), purchaseETHAmount)); 
                IDebondToken(DGOVAddress).mintCollateralisedSupply(address(apm), amountDGOVToMint);
                IDebondToken(DBITAddress).mintCollateralisedSupply(address(apm), 2 * amountDBITToMint);  //TODO : check here
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
    ) public view returns (uint, uint) {

        // Staking collateral for bonds
        if (purchaseMethod == PurchaseMethod.Staking) {
            return interestRateByStaking(_purchaseTokenClassId, _purchaseTokenAmount);
        }
        // buying Bonds
        else {
            //TODO we are trying to know how many Debond Token the buying bond process will add to the LQY
            uint debondTokenAmount = _purchaseTokenAmount;
            return interestRateByBuying(_debondTokenClassId, debondTokenAmount);
        }
    }



//##############CDP##############:

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) { /// use uint?? int256???
        if ( amountA == 0) {
            revert INSUFFICIENT_AMOUNT(amountA);
        } 
        if ( reserveA == 0 ){
            revert INSUFFICIENT_LIQUIDITY(reserveB);
        } 
        if (reserveB == 0) {
                revert INSUFFICIENT_LIQUIDITY(reserveA);
            }
        //amountB = amountA.mul(reserveB) / reserveA;
        amountB =  amountA * reserveB / reserveA;
    }

    /**
    * @dev gives the amount of DBIT which should be minted for 1$ worth of input
    * @return amountDBIT the amount of DBIT which should be minted
    */
    function _cdpUsdToDBIT() private view returns (uint256 amountDBIT) {
        amountDBIT = 1 ether;
        uint256 _sCollateralised = IDebondToken(DBITAddress).getTotalCollateralisedSupply(); //todo: is this working?
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
    function _convertTokenToUsd(uint128 _amountToken, address _tokenAddress) private view returns(uint256 amountUsd) {

        if (_tokenAddress == USDCAddress) {
            amountUsd = _amountToken;
        }
        else {
            amountUsd = oracle.estimateAmountOut(_tokenAddress, _amountToken, USDCAddress ,60 ) * 1e12 ; //1e6 x 1e12 = 1e18
        }
    }

    /**
    * @dev given the amount of tokens and the token address, returns the amout of DBIT to mint.
    * @param _amountToken the amount of token
    * @param _tokenAddress the address of token
    * @return amountDBIT the amount of DBIT to mint
    */
    function convertToDbit(uint128 _amountToken, address _tokenAddress) private  returns(uint256 amountDBIT) {

        uint256 tokenToUsd= _convertTokenToUsd(_amountToken, _tokenAddress);
        uint256 rate = _cdpUsdToDBIT();

        amountDBIT = tokenToUsd.mul(rate);  //1e6 x 1e12 x 1e18 = 1e18

        emit test1(amountDBIT);
        emit test2(rate);
        emit test3(tokenToUsd);

    }


    // **** DGOV ****

    /**
            * @dev gives the amount of dgov which should be minted for 1 dbit of input
        * @return amountDGOV the amount of DGOV which should be minted
        */
    function _cdpDbitToDgov(address dgovAddress) private view returns (uint256 amountDGOV) {
        uint256 _sCollateralised = IDebondToken(dgovAddress).getTotalCollateralisedSupply();
        amountDGOV = (100 ether + (_sCollateralised).div(33333).pow(2)).inv();
    }
    /**
    * @dev given the amount of dbit, returns the amout of DGOV to mint
    * @param _amountDBIT the amount of token
    * @return amountDGOV the amount of DGOV to mint
    */
    function mintDgovFromDbit(uint256 _amountDBIT) private view returns(uint256 amountDGOV) {  //todo: change name to convertDbitToDgov
        uint256 rate = _cdpDbitToDgov(DGOVAddress);
        amountDGOV = _amountDBIT.mul(rate);
    }
}
