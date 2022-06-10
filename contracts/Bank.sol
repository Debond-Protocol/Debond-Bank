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

import './DebondData.sol';
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IData.sol";
import "./interfaces/ICollateral.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IDebondToken.sol";
import "./libraries/DebondMath.sol";
import "debond-erc3475/contracts/interfaces/IDebondBond.sol";
import "erc3475/contracts/IERC3475.sol";
import "debond-apm/contracts/APMRouter.sol";
//import './interfaces/IWETH.sol'; //TODO


contract Bank is APMRouter{

    using SafeERC20 for IERC20;
    using DebondMath for uint256;


    IData debondData;
    IDebondBond bond;
    IOracle oracle;
    enum PurchaseMethod {Buying, Staking}
    uint public constant BASE_TIMESTAMP = 1646089200; // 2022-03-01 00:00
    uint public constant DIFF_TIME_NEW_NONCE = 24 * 3600; // every 24h we crate a new nonce.
    uint public constant BENCHMARK_RATE_DECIMAL_18 = 5 * 10**16;
    address immutable debondBondAddress;
    address immutable DBITAddress;
    address immutable DGOVAddress;
    address immutable USDCAddress;
    address immutable WETH; //TODO

    constructor(
        address apmAddress,
        address dataAddress,
        address bondAddress,
        address _DBITAddress,
        address _DGOVAddress,
        address oracleAddress,
        address usdcAddress,
        address _weth
    ) APMRouter(apmAddress) {
        debondData = IData(dataAddress);
        bond = IDebondBond(bondAddress);
        debondBondAddress = bondAddress;
        DBITAddress = _DBITAddress;
        DGOVAddress = _DGOVAddress;
        oracle = IOracle(oracleAddress);
        USDCAddress = usdcAddress;
        WETH = _weth;
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
            uint24 fee;
            uint minRate;
        }

    //############buybonds without eth##############

        /**
        * @dev let the user buy a bond
        * @param _purchaseClassId classId of the token added by the user (given by frontend)
        * @param _debondClassId  classId of the debond token to mint (dgov or dbit)
        * @param _purchaseTokenAmount amount of token to add
        * @param _purchaseMethod buying method or stacking method
        * @param _fee param given by frontend, is for oracle. see uniswapv3
        * @param _minRate minimum Rate that a user is willing to accept. similar to slippage    
        */

        function buyBond(
            uint _purchaseClassId,
            uint _debondClassId, 
            uint _purchaseTokenAmount,
            PurchaseMethod _purchaseMethod,
            uint24 _fee,
            uint _minRate 
            //uint deadline  
            //TODO : param to instead of msg.sender 
            ) external  { //ensure(deadline)

            BankData memory bankData;
            bankData.purchaseClassId = _purchaseClassId;
            bankData.debondClassId = _debondClassId;
            bankData.purchaseTokenAmount = _purchaseTokenAmount;
            bankData.purchaseMethod = _purchaseMethod;
            bankData.fee = _fee;
            bankData.minRate = _minRate;

            if ( ! debondData.canPurchase(bankData.debondClassId, bankData.purchaseClassId)) {
                revert PairNotAllowed();
            } 
            (,IDebondBond.InterestRateType interestRateType ,address debondTokenAddress,) = debondData.getClassFromId(bankData.debondClassId); //todo : get info from class id
            (,,address purchaseTokenAddress,) = debondData.getClassFromId(bankData.purchaseClassId);
            
            _mintingProcess(debondTokenAddress, bankData.purchaseTokenAmount, purchaseTokenAddress, bankData.fee);
        
            (uint fixedRate, uint floatingRate) = interestRate(bankData.purchaseClassId, bankData.debondClassId, bankData.purchaseTokenAmount, bankData.purchaseMethod);
            _issuingProcess(bankData.purchaseMethod, bankData.purchaseClassId, bankData.purchaseTokenAmount, purchaseTokenAddress, debondTokenAddress, bankData.debondClassId, interestRateType, fixedRate, floatingRate, bankData.minRate);
        }

        //TODO : time 20 min                 : SEE FRONTEND
        //todo : require interest high enough: OK


        /**
        * @dev mint the bond to the user
        * @param purchaseMethod buying method or stacking method
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
            IDebondBond.InterestRateType interestRateType,
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
                uint rate = interestRateType == IDebondBond.InterestRateType.FixedRate ? fixedRate : floatingRate;
                if (rate < minRate){
                    revert RateNotHighEnough(rate, minRate);
                }
                issueBonds(msg.sender, debondClassId, amount.mul(rate));
            }
            else if (purchaseMethod == PurchaseMethod.Buying) {
                (uint reserveA, uint reserveB) = getReserves(purchaseTokenAddress, debondTokenAddress);
                uint amount = quote(purchaseTokenAmount, reserveA, reserveB);
                uint rate = interestRateType == IDebondBond.InterestRateType.FixedRate ? fixedRate : floatingRate;
                if (rate < minRate){
                    revert RateNotHighEnough(rate, minRate);
                }
                issueBonds(msg.sender, debondClassId, amount + amount.mul(rate)); // here the interest calculation is hardcoded. require the interest is enough high
            }
        }


        function _mintingProcess(
            address debondTokenAddress,
            uint purchaseTokenAmount,
            address purchaseTokenAddress,
            uint24 fee
            ) internal {
            if (debondTokenAddress == DBITAddress) {
                uint amountDBITToMint = mintDbitFromUsd(uint128(purchaseTokenAmount), purchaseTokenAddress, fee); //todo : ferivy if conversion is possible.
                IERC20(purchaseTokenAddress).transferFrom(msg.sender, address(apm), purchaseTokenAmount);
                IDebondToken(debondTokenAddress).mint(address(apm), amountDBITToMint);
                updateWhenAddLiquidity(purchaseTokenAmount, amountDBITToMint, purchaseTokenAddress, debondTokenAddress);
            }
            else { //else address ==dgov? 
                if (purchaseTokenAddress == DBITAddress) {
                    uint amountDGOVToMint = mintDgovFromDbit(purchaseTokenAmount);
                    IERC20(DBITAddress).transferFrom(msg.sender, address(apm), purchaseTokenAmount);
                    IDebondToken(debondTokenAddress).mint(address(apm), amountDGOVToMint); //todo : check amountDGOVToMint
                    updateWhenAddLiquidity(purchaseTokenAmount, amountDGOVToMint,  DBITAddress,  debondTokenAddress);
                }
                else {
                    uint amountDBITToMint = mintDbitFromUsd(uint128(purchaseTokenAmount), purchaseTokenAddress, fee); //need cdp from usd to dgov
                    uint amountDGOVToMint = mintDgovFromDbit(purchaseTokenAmount);
                    IERC20(purchaseTokenAddress).transferFrom(msg.sender, address(apm), purchaseTokenAmount);
                    IDebondToken(DGOVAddress).mint(address(apm), amountDGOVToMint);
                    IDebondToken(DBITAddress).mint(address(apm), 2 * amountDBITToMint);  //TODO : check here
                    updateWhenAddLiquidity(purchaseTokenAmount, amountDBITToMint,  purchaseTokenAddress,  DBITAddress);
                    updateWhenAddLiquidity(amountDBITToMint, amountDGOVToMint,  DBITAddress,  debondTokenAddress);
                }

            }

        }

    //############buybonds Stacking method  Not eth to dbit##############

        function stakeForDbitBondWithAll(
            uint _purchaseClassId,
            uint _debondClassId, 
            uint _purchaseTokenAmount,
            uint24 _fee,
            uint _minRate 
            //uint deadline  
            //TODO : param to instead of msg.sender 
            ) external  { //ensure(deadline)

            BankData memory bankData;
            bankData.purchaseClassId = _purchaseClassId;
            bankData.debondClassId = _debondClassId;
            bankData.purchaseTokenAmount = _purchaseTokenAmount;
            bankData.fee = _fee;
            bankData.minRate = _minRate;

            if ( ! debondData.canPurchase(bankData.debondClassId, bankData.purchaseClassId)) {
                revert PairNotAllowed();
            } 
            (,IDebondBond.InterestRateType interestRateType ,,) = debondData.getClassFromId(bankData.debondClassId); //todo : get info from class id
            (,,address purchaseTokenAddress,) = debondData.getClassFromId(bankData.purchaseClassId);
            
            _mintingProcessForDbit(bankData.purchaseTokenAmount, purchaseTokenAddress, bankData.fee);
        
            (uint fixedRate, uint floatingRate) = interestRate(bankData.purchaseClassId, bankData.debondClassId, bankData.purchaseTokenAmount, bankData.purchaseMethod);
            _issuingProcessStacking(bankData.purchaseClassId, bankData.purchaseTokenAmount, purchaseTokenAddress, DBITAddress, bankData.debondClassId, interestRateType, fixedRate, floatingRate, bankData.minRate);
        }

        function _issuingProcessStacking(
            uint purchaseClassId,
            uint purchaseTokenAmount,
            address purchaseTokenAddress,
            address debondTokenAddress,
            uint debondClassId,
            IDebondBond.InterestRateType interestRateType,
            uint fixedRate,
            uint floatingRate,
            uint minRate
            ) internal {
                issueBonds(msg.sender, purchaseClassId, purchaseTokenAmount);
                (uint reserveA, uint reserveB) = getReserves(purchaseTokenAddress, debondTokenAddress);
                uint amount = quote(purchaseTokenAmount, reserveA, reserveB);
                uint rate = interestRateType == IDebondBond.InterestRateType.FixedRate ? fixedRate : floatingRate;
                if (rate < minRate){
                    revert RateNotHighEnough(rate, minRate);
                }
                issueBonds(msg.sender, debondClassId, amount.mul(rate));
        }

        function _mintingProcessForDbit(
            uint purchaseTokenAmount,
            address purchaseTokenAddress,
            uint24 fee
            ) internal {
            uint amountDBITToMint = mintDbitFromUsd(uint128(purchaseTokenAmount), purchaseTokenAddress, fee); //todo : ferivy if conversion is possible.
            IERC20(purchaseTokenAddress).transferFrom(msg.sender, address(apm), purchaseTokenAmount);
            IDebondToken(DBITAddress).mint(address(apm), amountDBITToMint);
            updateWhenAddLiquidity(purchaseTokenAmount, amountDBITToMint, purchaseTokenAddress, DBITAddress);
        }

    //############buybonds Stacking method  DbitToDgov##############

        function stakeForDgovBondWithDbit(
            uint _purchaseClassId,
            uint _debondClassId, 
            uint _purchaseTokenAmount,
            uint _minRate 
            //uint deadline  
            //TODO : param to instead of msg.sender 
            ) external  { //ensure(deadline)

            BankData memory bankData;
            bankData.purchaseClassId = _purchaseClassId;
            bankData.debondClassId = _debondClassId;
            bankData.purchaseTokenAmount = _purchaseTokenAmount;
            bankData.minRate = _minRate;

            if ( ! debondData.canPurchase(bankData.debondClassId, bankData.purchaseClassId)) {
                revert PairNotAllowed();
            } 
            (,IDebondBond.InterestRateType interestRateType ,address debondTokenAddress,) = debondData.getClassFromId(bankData.debondClassId); //todo : get info from class id
            (,,address purchaseTokenAddress,) = debondData.getClassFromId(bankData.purchaseClassId);
            
            _mintingProcessDgovWithDbit(debondTokenAddress, bankData.purchaseTokenAmount, purchaseTokenAddress);
        
            (uint fixedRate, uint floatingRate) = interestRate(bankData.purchaseClassId, bankData.debondClassId, bankData.purchaseTokenAmount, bankData.purchaseMethod);
            _issuingProcessStacking(bankData.purchaseClassId, bankData.purchaseTokenAmount, purchaseTokenAddress, debondTokenAddress, bankData.debondClassId, interestRateType, fixedRate, floatingRate, bankData.minRate);
        }

        function _mintingProcessDgovWithDbit(
            address debondTokenAddress,
            uint purchaseTokenAmount,
            address purchaseTokenAddress
            ) internal { {
                    uint amountBToMint = mintDgovFromDbit(purchaseTokenAmount);
                    IERC20(purchaseTokenAddress).transferFrom(msg.sender, address(apm), purchaseTokenAmount);
                    IDebondToken(debondTokenAddress).mint(address(apm), amountBToMint);
                    updateWhenAddLiquidity(purchaseTokenAmount, amountBToMint,  purchaseTokenAddress,  debondTokenAddress);

            }

        }

    //############buybonds Stacking method  else ToDgov############## else is not dbit not eth

        function stakeForDgovBondWithElse(
            uint _purchaseClassId,
            uint _debondClassId, 
            uint _purchaseTokenAmount,
            uint24 _fee, //todo : proxy for fee param
            uint _minRate 
            //uint deadline  
            //TODO : param to instead of msg.sender 
            ) external  { //ensure(deadline)

            BankData memory bankData;
            bankData.purchaseClassId = _purchaseClassId;
            bankData.debondClassId = _debondClassId;
            bankData.purchaseTokenAmount = _purchaseTokenAmount;
            bankData.fee = _fee;
            bankData.minRate = _minRate;

            if ( ! debondData.canPurchase(bankData.debondClassId, bankData.purchaseClassId)) {
                revert PairNotAllowed();
            } 
            (,IDebondBond.InterestRateType interestRateType ,address debondTokenAddress,) = debondData.getClassFromId(bankData.debondClassId); //todo : get info from class id
            (,,address purchaseTokenAddress,) = debondData.getClassFromId(bankData.purchaseClassId);
            
            _mintingProcessElseToDgov(debondTokenAddress, bankData.purchaseTokenAmount, purchaseTokenAddress, bankData.fee);
        
            (uint fixedRate, uint floatingRate) = interestRate(bankData.purchaseClassId, bankData.debondClassId, bankData.purchaseTokenAmount, bankData.purchaseMethod);
            _issuingProcessStacking(bankData.purchaseClassId, bankData.purchaseTokenAmount, purchaseTokenAddress, debondTokenAddress, bankData.debondClassId, interestRateType, fixedRate, floatingRate, bankData.minRate);
        }

        function _mintingProcessElseToDgov(
            address debondTokenAddress,
            uint purchaseTokenAmount,
            address purchaseTokenAddress,
            uint24 fee
            ) internal { {
                    uint amountDBITToMint = mintDbitFromUsd(uint128(purchaseTokenAmount), purchaseTokenAddress, fee); //need cdp from usd to dgov
                    uint amountDGOVToMint = mintDgovFromDbit(purchaseTokenAmount);
                    IERC20(purchaseTokenAddress).transferFrom(msg.sender, address(apm), purchaseTokenAmount);
                    IDebondToken(debondTokenAddress).mint(address(apm), amountDGOVToMint);
                    IDebondToken(debondTokenAddress).mint(address(apm), 2 * amountDBITToMint);
                    updateWhenAddLiquidity(purchaseTokenAmount, amountDBITToMint,  purchaseTokenAddress,  DBITAddress);
                    updateWhenAddLiquidity(amountDBITToMint, amountDGOVToMint,  DBITAddress,  debondTokenAddress);
            }

        }
        
    //############buybonds Buying method not eth to dbit##############

        function buyforDbitBondWithElse( //else is not eth not dbit   
            uint _purchaseClassId,
            uint _debondClassId, 
            uint _purchaseTokenAmount,
            uint24 _fee,
            uint _minRate 
            //uint deadline  
            //TODO : param to instead of msg.sender 
            ) external  { //ensure(deadline)

            BankData memory bankData;
            bankData.purchaseClassId = _purchaseClassId;
            bankData.debondClassId = _debondClassId;
            bankData.purchaseTokenAmount = _purchaseTokenAmount;
            bankData.fee = _fee;
            bankData.minRate = _minRate;

            if ( ! debondData.canPurchase(bankData.debondClassId, bankData.purchaseClassId)) {
                revert PairNotAllowed();
            } 
            (,IDebondBond.InterestRateType interestRateType ,,) = debondData.getClassFromId(bankData.debondClassId); //todo : get info from class id
            (,,address purchaseTokenAddress,) = debondData.getClassFromId(bankData.purchaseClassId);
            
            _mintingProcessForDbit(bankData.purchaseTokenAmount, purchaseTokenAddress, bankData.fee);
        
            (uint fixedRate, uint floatingRate) = interestRate(bankData.purchaseClassId, bankData.debondClassId, bankData.purchaseTokenAmount, bankData.purchaseMethod);
            _issuingProcessBuying(bankData.purchaseTokenAmount, purchaseTokenAddress, DBITAddress, bankData.debondClassId, interestRateType, fixedRate, floatingRate, bankData.minRate);
        }

        function _issuingProcessBuying(
            uint purchaseTokenAmount,
            address purchaseTokenAddress,
            address debondTokenAddress,
            uint debondClassId,
            IDebondBond.InterestRateType interestRateType,
            uint fixedRate,
            uint floatingRate,
            uint minRate
            ) internal {
                (uint reserveA, uint reserveB) = getReserves(purchaseTokenAddress, debondTokenAddress);
                uint amount = quote(purchaseTokenAmount, reserveA, reserveB);
                uint rate = interestRateType == IDebondBond.InterestRateType.FixedRate ? fixedRate : floatingRate;
                if (rate < minRate){
                    revert RateNotHighEnough(rate, minRate);
                }
                issueBonds(msg.sender, debondClassId, amount + amount.mul(rate));
        }


    //############buybonds Buying method DbitToDgov##############


        function buyForDgovBondWithDbit(
            uint _purchaseClassId,
            uint _debondClassId, 
            uint _purchaseTokenAmount,
            uint _minRate 
            //uint deadline  
            //TODO : param to instead of msg.sender 
            ) external  { //ensure(deadline)

            BankData memory bankData;
            bankData.purchaseClassId = _purchaseClassId;
            bankData.debondClassId = _debondClassId;
            bankData.purchaseTokenAmount = _purchaseTokenAmount;
            bankData.minRate = _minRate;

            if ( ! debondData.canPurchase(bankData.debondClassId, bankData.purchaseClassId)) {
                revert PairNotAllowed();
            } 
            (,IDebondBond.InterestRateType interestRateType ,address debondTokenAddress,) = debondData.getClassFromId(bankData.debondClassId); //todo : get info from class id
            (,,address purchaseTokenAddress,) = debondData.getClassFromId(bankData.purchaseClassId);
            
            _mintingProcessDgovWithDbit(debondTokenAddress, bankData.purchaseTokenAmount, purchaseTokenAddress);
        
            (uint fixedRate, uint floatingRate) = interestRate(bankData.purchaseClassId, bankData.debondClassId, bankData.purchaseTokenAmount, bankData.purchaseMethod);
            _issuingProcessBuying(bankData.purchaseTokenAmount, purchaseTokenAddress, DBITAddress, bankData.debondClassId, interestRateType, fixedRate, floatingRate, bankData.minRate);
        }
        

    //############buybonds Buying method else ToDgov############## else is not dbit not eth

        function buyForDgovBondWithElse(
            uint _purchaseClassId,
            uint _debondClassId, 
            uint _purchaseTokenAmount,
            uint24 _fee,
            uint _minRate 
            //uint deadline  
            //TODO : param to instead of msg.sender 
            ) external  { //ensure(deadline)

            BankData memory bankData;
            bankData.purchaseClassId = _purchaseClassId;
            bankData.debondClassId = _debondClassId;
            bankData.purchaseTokenAmount = _purchaseTokenAmount;
            bankData.fee = _fee;
            bankData.minRate = _minRate;

            if ( ! debondData.canPurchase(bankData.debondClassId, bankData.purchaseClassId)) {
                revert PairNotAllowed();
            } 
            (,IDebondBond.InterestRateType interestRateType ,address debondTokenAddress,) = debondData.getClassFromId(bankData.debondClassId); //todo : get info from class id
            (,,address purchaseTokenAddress,) = debondData.getClassFromId(bankData.purchaseClassId);
            
            _mintingProcessElseToDgov(debondTokenAddress, bankData.purchaseTokenAmount, purchaseTokenAddress, bankData.fee);
        
            (uint fixedRate, uint floatingRate) = interestRate(bankData.purchaseClassId, bankData.debondClassId, bankData.purchaseTokenAmount, bankData.purchaseMethod);
            _issuingProcessBuying(bankData.purchaseTokenAmount, purchaseTokenAddress, DBITAddress, bankData.debondClassId, interestRateType, fixedRate, floatingRate, bankData.minRate);
        }


    //############buybonds Stacking method  ETH To DBIT############## 

        function stakeForDbitBondWithETH(
                //uint _purchaseClassId, // token added  //here it's eth
                uint _debondClassId, // token to mint
                //uint _purchaseTokenAmount,
                PurchaseMethod _purchaseMethod,
                uint24 _fee, //todo : proxy for fee param
                uint _minRate 
                //uint deadline  
                ) external payable { //ensure(deadline)

                BankData memory bankData;
                bankData.purchaseClassId /*= _purchaseClassId*/;
                bankData.debondClassId = _debondClassId;
                bankData.purchaseTokenAmount = msg.value;
                bankData.purchaseMethod = _purchaseMethod;
                bankData.fee = _fee;
                bankData.minRate = _minRate;

                //no need to ckeck if it's allowed

                (,IDebondBond.InterestRateType interestRateType ,address debondTokenAddress,) = debondData.getClassFromId(bankData.debondClassId);
                (,,address purchaseTokenAddress,) = debondData.getClassFromId(bankData.purchaseClassId);
                
                _mintingProcessETHWithDbit(debondTokenAddress, bankData.purchaseTokenAmount, bankData.fee);
            
                (uint fixedRate, uint floatingRate) = interestRate(bankData.purchaseClassId, bankData.debondClassId, bankData.purchaseTokenAmount, bankData.purchaseMethod);
                _issuingProcessStacking(bankData.purchaseClassId, bankData.purchaseTokenAmount, purchaseTokenAddress, debondTokenAddress, bankData.debondClassId, interestRateType, fixedRate, floatingRate, bankData.minRate);
            }

            function _mintingProcessETHWithDbit(
                address debondTokenAddress,
                uint purchaseETHAmount,
                uint24 fee
                ) internal {
                uint amountDBITToMint = mintDbitFromUsd(uint128(purchaseETHAmount), WETH, fee); //todo : verify if conversion uint128 is possible.
                //IERC20(purchaseTokenAddress).transferFrom(msg.sender, address(apm), purchaseTokenAmount);
                //IWETH(WETH).deposit{value: purchaseETHAmount}();
                //assert(IWETH(WETH).transfer(address(apm), purchaseETHAmount)); // see if better methods
                IDebondToken(debondTokenAddress).mint(address(apm), amountDBITToMint);
                updateWhenAddLiquidity(purchaseETHAmount, amountDBITToMint, WETH, debondTokenAddress);
            }


    //############buybonds Stacking method  ETH To Dgov############## 

     function stakeForDgovBondWithETH(
            //uint _purchaseClassId, // token added  //here it's eth
            uint _debondClassId, // token to mint
            //uint _purchaseTokenAmount,
            PurchaseMethod _purchaseMethod,
            uint24 _fee,
            uint _minRate 
            //uint deadline  
            ) external payable { //ensure(deadline)

            BankData memory bankData;
            bankData.purchaseClassId /*= _purchaseClassId*/;
            bankData.debondClassId = _debondClassId;
            bankData.purchaseTokenAmount = msg.value;
            bankData.purchaseMethod = _purchaseMethod;
            bankData.fee = _fee;
            bankData.minRate = _minRate;

            //no need to ckeck if it's allowed

            (,IDebondBond.InterestRateType interestRateType ,address debondTokenAddress,) = debondData.getClassFromId(bankData.debondClassId);
            (,,address purchaseTokenAddress,) = debondData.getClassFromId(bankData.purchaseClassId);
            
            _mintingProcessETHWithDgov(debondTokenAddress, bankData.purchaseTokenAmount, bankData.fee);
        
            (uint fixedRate, uint floatingRate) = interestRate(bankData.purchaseClassId, bankData.debondClassId, bankData.purchaseTokenAmount, bankData.purchaseMethod);
            _issuingProcessStacking(bankData.purchaseClassId, bankData.purchaseTokenAmount, purchaseTokenAddress, debondTokenAddress, bankData.debondClassId, interestRateType, fixedRate, floatingRate, bankData.minRate);
        }

        function _mintingProcessETHWithDgov(
            address debondTokenAddress,
            uint purchaseETHAmount,
            uint24 fee
            ) internal {
            uint amountDBITToMint = mintDbitFromUsd(uint128(purchaseETHAmount), WETH, fee); //need cdp from usd to dgov
            uint amountDGOVToMint = mintDgovFromDbit(purchaseETHAmount);
            //IERC20(purchaseTokenAddress).transferFrom(msg.sender, address(apm), purchaseTokenAmount);
            //IWETH(WETH).deposit{value: purchaseETHAmount}();
            //assert(IWETH(WETH).transfer(address(apm), purchaseETHAmount)); // see if better methods
            IDebondToken(debondTokenAddress).mint(address(apm), amountDGOVToMint);
            IDebondToken(debondTokenAddress).mint(address(apm), 2 * amountDBITToMint);
            updateWhenAddLiquidity(purchaseETHAmount, amountDBITToMint,  WETH,  DBITAddress);
            updateWhenAddLiquidity(amountDBITToMint, amountDGOVToMint,  DBITAddress,  debondTokenAddress);
        }


    //############buybonds Buying method  ETH To DBIT############## 
        function buyforDbitBondWithEth( //else is not eth not dbit   
                uint _purchaseClassId,
                uint _debondClassId, 
                uint _purchaseTokenAmount,
                uint24 _fee,
                uint _minRate 
                //uint deadline  
                //TODO : param to instead of msg.sender 
                ) external  { //ensure(deadline)

                BankData memory bankData;
                bankData.purchaseClassId = _purchaseClassId;
                bankData.debondClassId = _debondClassId;
                bankData.purchaseTokenAmount = _purchaseTokenAmount;
                bankData.fee = _fee;
                bankData.minRate = _minRate;

                if ( ! debondData.canPurchase(bankData.debondClassId, bankData.purchaseClassId)) {
                    revert PairNotAllowed();
                } 
                (,IDebondBond.InterestRateType interestRateType ,,) = debondData.getClassFromId(bankData.debondClassId); //todo : get info from class id
                (,,address purchaseTokenAddress,) = debondData.getClassFromId(bankData.purchaseClassId);
                
                _mintingProcessForDbitWithEth(bankData.purchaseTokenAmount, purchaseTokenAddress, bankData.fee);
            
                (uint fixedRate, uint floatingRate) = interestRate(bankData.purchaseClassId, bankData.debondClassId, bankData.purchaseTokenAmount, bankData.purchaseMethod);
                _issuingProcessBuying(bankData.purchaseTokenAmount, purchaseTokenAddress, DBITAddress, bankData.debondClassId, interestRateType, fixedRate, floatingRate, bankData.minRate);
            }

            function _mintingProcessForDbitWithEth(
                uint purchaseTokenAmount,
                address purchaseTokenAddress,
                uint24 fee
                ) internal {
                uint amountDBITToMint = mintDbitFromUsd(uint128(purchaseTokenAmount), purchaseTokenAddress, fee); //todo : ferivy if conversion is possible.
                //IWETH(WETH).deposit{value: purchaseETHAmount}();
                //assert(IWETH(WETH).transfer(address(apm), purchaseETHAmount)); // see if better methods
                IDebondToken(DBITAddress).mint(address(apm), amountDBITToMint);
                updateWhenAddLiquidity(purchaseTokenAmount, amountDBITToMint, purchaseTokenAddress, DBITAddress);
            }

        
    //############buybonds Buying method  ETH To Dgov##############

        function buyforDgovBondWithEth( //else is not eth not dbit   
                uint _purchaseClassId,
                uint _debondClassId, 
                uint _purchaseTokenAmount,
                uint24 _fee,
                uint _minRate 
                //uint deadline  
                //TODO : param to instead of msg.sender 
                ) external  { //ensure(deadline)

                BankData memory bankData;
                bankData.purchaseClassId = _purchaseClassId;
                bankData.debondClassId = _debondClassId;
                bankData.purchaseTokenAmount = _purchaseTokenAmount;
                bankData.fee = _fee;
                bankData.minRate = _minRate;

                if ( ! debondData.canPurchase(bankData.debondClassId, bankData.purchaseClassId)) {
                    revert PairNotAllowed();
                } 
                (,IDebondBond.InterestRateType interestRateType ,,) = debondData.getClassFromId(bankData.debondClassId); //todo : get info from class id
                (,,address purchaseTokenAddress,) = debondData.getClassFromId(bankData.purchaseClassId);
                
                _mintingProcessForDgovWithEth(bankData.purchaseTokenAmount, purchaseTokenAddress, bankData.fee);
            
                (uint fixedRate, uint floatingRate) = interestRate(bankData.purchaseClassId, bankData.debondClassId, bankData.purchaseTokenAmount, bankData.purchaseMethod);
                _issuingProcessBuying(bankData.purchaseTokenAmount, purchaseTokenAddress, DBITAddress, bankData.debondClassId, interestRateType, fixedRate, floatingRate, bankData.minRate);
            }

            function _mintingProcessForDgovWithEth(
                uint purchaseTokenAmount,
                address purchaseTokenAddress,
                uint24 fee
                ) internal {
                uint amountDBITToMint = mintDbitFromUsd(uint128(purchaseTokenAmount), purchaseTokenAddress, fee); //need cdp from usd to dgov
                uint amountDGOVToMint = mintDgovFromDbit(purchaseTokenAmount);
                IERC20(purchaseTokenAddress).transferFrom(msg.sender, address(apm), purchaseTokenAmount);
                //IWETH(WETH).deposit{value: purchaseETHAmount}();
                //assert(IWETH(WETH).transfer(address(apm), purchaseETHAmount)); // see if better methods
                IDebondToken(DGOVAddress).mint(address(apm), amountDGOVToMint);
                IDebondToken(DBITAddress).mint(address(apm), 2 * amountDBITToMint);  //TODO : check here
                updateWhenAddLiquidity(purchaseTokenAmount, amountDBITToMint,  purchaseTokenAddress,  DBITAddress);
                updateWhenAddLiquidity(amountDBITToMint, amountDGOVToMint,  DBITAddress,  DGOVAddress);
            }

    

        


// **** REDEEM BONDS ****

    function redeemBonds(
        uint classId,
        uint nonceId,
        uint amount
    ) external {
        //1. redeem the bonds (will fail if not maturity date exceeded)
        IERC3475(debondBondAddress).redeem(msg.sender, classId, nonceId, amount);

        (,, address tokenAddress,) = debondData.getClassFromId(classId);
        removeLiquidity(msg.sender, tokenAddress, amount);
    }





    function issueBonds(address to, uint256 classId, uint256 amount) private {
        uint timestampToCheck = block.timestamp;
        (uint lastNonceId, uint createdAt) = debondData.getLastNonceCreated(classId);
        createdAt = createdAt == 0 ? BASE_TIMESTAMP : createdAt;
        uint numDaysNow = (timestampToCheck - BASE_TIMESTAMP) / DIFF_TIME_NEW_NONCE;
        uint numDaysLastNonce = (createdAt - BASE_TIMESTAMP) / DIFF_TIME_NEW_NONCE;
        uint nonceToAdd = numDaysNow - numDaysLastNonce;
        if(nonceToAdd != 0) {
            createNewNonce(classId, lastNonceId + nonceToAdd, timestampToCheck);
            (uint nonceId,) = debondData.getLastNonceCreated(classId);
            IERC3475(debondBondAddress).issue(to, classId, nonceId, amount);
            return;
        }
    }

    function createNewNonce(uint classId, uint newNonceId, uint creationTimestamp) private {
        uint _newNonceId = newNonceId;
        (,,, uint period) = debondData.getClassFromId(classId);
        bond.createNonce(classId, _newNonceId, creationTimestamp + period);
        debondData.updateLastNonce(classId, _newNonceId, creationTimestamp);
        //here 500 is liquidity info hard coded for now
    }

    function interestRate(
        uint _purchaseTokenClassId,
        uint _debondTokenClassId,
        uint _purchaseTokenAmount,
        PurchaseMethod purchaseMethod
    ) public view returns (uint fixRate, uint floatRate) {
        uint purchaseTokenClassId = _purchaseTokenClassId;
        uint debondTokenClassId = _debondTokenClassId;
        uint purchaseTokenAmount = _purchaseTokenAmount;

        uint fixRateSupply = 0;
        uint floatRateSupply = 0;

        (,IDebondBond.InterestRateType interestRateType, address purchaseTokenAddress,) = debondData.getClassFromId(purchaseTokenClassId); // address of the purchase token


        // staking collateral for bonds
        if (purchaseMethod == PurchaseMethod.Staking) {
            fixRateSupply = bond.bondAmountDue(purchaseTokenAddress, IDebondBond.InterestRateType.FixedRate);// we get the fix rate bonds supply
            floatRateSupply = bond.bondAmountDue(purchaseTokenAddress, IDebondBond.InterestRateType.FloatingRate);// we get the float rate bonds supply

            // we had the client amount to the according bond balance to calculate interest rate after deposit
            if (purchaseTokenAmount > 0 && interestRateType == IDebondBond.InterestRateType.FixedRate) {
                fixRateSupply += purchaseTokenAmount;
            }
            if (purchaseTokenAmount > 0 && interestRateType == IDebondBond.InterestRateType.FloatingRate) {
                floatRateSupply += purchaseTokenAmount;
            }

        }
        // buying Bonds
        else if (purchaseMethod == PurchaseMethod.Buying) {

            (,,address debondTokenAddress,) = debondData.getClassFromId(debondTokenClassId); // address of D/BIT

            // we are trying to know how many Debond Token the buying bond process will add to the LQY
            uint debondTokenAmount = purchaseTokenAmount;

            fixRateSupply = bond.bondAmountDue(debondTokenAddress, IDebondBond.InterestRateType.FixedRate);
            floatRateSupply = bond.bondAmountDue(debondTokenAddress, IDebondBond.InterestRateType.FloatingRate);

            if (interestRateType == IDebondBond.InterestRateType.FixedRate) {
                fixRateSupply += debondTokenAmount;
            }
            if (interestRateType == IDebondBond.InterestRateType.FloatingRate) {
                floatRateSupply += debondTokenAmount;
            }
        }

        if (fixRateSupply == 0 || floatRateSupply == 0) {
            fixRate = 2 * BENCHMARK_RATE_DECIMAL_18 / 3;
            floatRate = 2 * fixRate;
        } else {
        (fixRate, floatRate) = interestRate(fixRateSupply, floatRateSupply, BENCHMARK_RATE_DECIMAL_18);
        }
    }

    function maturityDeltaCalculation(uint classId, uint nonceId) public view returns (uint) {
        // Somme de la lqt de l'asset du debut au nonce donné
        // Somme de la lqt de l'asset du nonce donné au dernier nonce
        (,,address tokenAddress,) = debondData.getClassFromId(classId);
        (,,,,,,uint nonceTokenLiquidity) = bond.bondDetails(classId, nonceId);
        uint totalLiquidity = bond.totalActiveSupply(tokenAddress);
        return maturityDelta(totalLiquidity, nonceTokenLiquidity, BENCHMARK_RATE_DECIMAL_18, 86400, 30);
    }




    function maturityDelta(uint totalLiquidity, uint liquidityUntilGivenDay, uint benchmarkInterest, uint epoch, uint period) private pure returns (uint) {
        uint deltaLiquidity = totalLiquidity - liquidityUntilGivenDay;
        uint totalLiquidityInterest = liquidityUntilGivenDay * benchmarkInterest / 1e18;
        return ((liquidityUntilGivenDay + totalLiquidityInterest) - deltaLiquidity) * epoch / period;
    }

    function interestRate(uint fixRateSupply, uint floatRateSupply, uint benchmarkInterest) private pure returns (uint fixedRate, uint floatingRate) {
        uint sigmoidCParam = DebondMath.inv(3 ether);
        uint x = fixRateSupply.div(floatRateSupply + fixRateSupply);
        floatingRate = 2 * (benchmarkInterest.mul(DebondMath.sigmoid(x, sigmoidCParam)));
        fixedRate = 2 * benchmarkInterest - floatingRate;
    }

    //todo : input : addressA, addressB. output : ratio reserveA/reserveB






////////////////// CDP //////////////////////////:

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

    // **** DBIT ****
    /**
        * @dev gives the amount of DBIT which should be minted for 1$ worth of input
        * @param dbitAddress address of dbit
        * @return amountDBIT the amount of DBIT which should be minted
        */
    function _cdpUsdToDBIT(address dbitAddress) private view returns (uint256 amountDBIT) {
        amountDBIT = 1 ether;
        uint256 _sCollateralised = ICollateral(dbitAddress).supplyCollateralised();
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
    * @param fee fees of the pool
    * @return amountUsd the corresponding amount of usd
    */
    function _convertTokenToUsd(uint128 _amountToken, address _tokenAddress, uint24 fee) private view returns(uint256 amountUsd) {

        if (_tokenAddress == USDCAddress) {
            amountUsd = _amountToken;
        }
        else {
            amountUsd = oracle.estimateAmountOut(_tokenAddress, _amountToken, USDCAddress, fee , 5 );
        }
    }

    /**
    * @dev given the amount of tokens and the token address, returns the amout of DBIT to mint.
    * @param _amountToken the amount of token
    * @param _tokenAddress the address of token
    * @param fee fees of the pool
    * @return amountDBIT the amount of DBIT to mint
    */
    function mintDbitFromUsd(uint128 _amountToken, address _tokenAddress, uint24 fee) private view returns(uint256 amountDBIT) {

        uint256 tokenToUsd= _convertTokenToUsd(_amountToken, _tokenAddress, fee);
        uint256 rate = _cdpUsdToDBIT(DBITAddress);

        amountDBIT = (tokenToUsd * 1e12).mul(rate);  //1e6 x1e12 x 1e18 = 1e18
    }


    // **** DGOV ****

    /**
            * @dev gives the amount of dgov which should be minted for 1 dbit of input
        * @return amountDGOV the amount of DGOV which should be minted
        */
    function _cdpDbitToDgov(address dgovAddress) private view returns (uint256 amountDGOV) {
        uint256 _sCollateralised = ICollateral(dgovAddress).supplyCollateralised();
        amountDGOV = (100 ether+ (_sCollateralised).div(33333).pow(2)).inv();
    }
    /**
    * @dev given the amount of dbit, returns the amout of DGOV to mint
    * @param _amountDBIT the amount of token
    * @return amountDGOV the amount of DGOV to mint
    */
    function mintDgovFromDbit(uint256 _amountDBIT) private view returns(uint256 amountDGOV) {
        uint256 rate = _cdpDbitToDgov(DGOVAddress);
        amountDGOV = _amountDBIT.mul(rate);
    }
}
