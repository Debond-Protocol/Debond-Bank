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



import './DebondData.sol';
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IData.sol";
import "./interfaces/ICollateral.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IDebondToken.sol";
import "./interfaces/IDebondBond.sol";
import "./libraries/DebondMath.sol";
import "erc3475/contracts/IERC3475.sol";
import "debond-apm/contracts/APMRouter.sol";
import "./interfaces/IRedeemableBondCalculator.sol";


contract Bank is APMRouter, IRedeemableBondCalculator {

    using SafeERC20 for IERC20;
    using DebondMath for uint256;


    IData debondData;
    IDebondBond bond;
    IOracle oracle;
    address debondBondAddress;
    enum PurchaseMethod {Buying, Staking}
    uint public constant BASE_TIMESTAMP = 1646089200; // 2022-03-01 00:00
    uint public constant EPOCH = 24 * 3600; // every 24h we crate a new nonce.
    uint public constant BENCHMARK_RATE_DECIMAL_18 = 5 * 10 ** 16;
    address DBITAddress;
    address DGOVAddress;
    address USDCAddress;

    constructor(
        address apmAddress,
        address dataAddress,
        address bondAddress,
        address _DBITAddress,
        address _DGOVAddress,
        address oracleAddress,
        address usdcAddress
    ) APMRouter(apmAddress) {
        debondData = IData(dataAddress);
        bond = IDebondBond(bondAddress);
        debondBondAddress = bondAddress;
        DBITAddress = _DBITAddress;
        DGOVAddress = _DGOVAddress;
        oracle = IOracle(oracleAddress);
        USDCAddress = usdcAddress;
    }

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }

    function buyBond(
        uint _purchaseClassId, // token added
        uint _debondClassId, // token to mint
        uint _purchaseTokenAmount,
        uint _bondMinAmount, //should be changed to interest min amount
        PurchaseMethod purchaseMethod,
        uint24 fee
    ) external {

        uint purchaseClassId = _purchaseClassId;
        uint debondClassId = _debondClassId;
        uint purchaseTokenAmount = _purchaseTokenAmount;
        uint bondMinAmount = _bondMinAmount;

        require(debondData.canPurchase(debondClassId, purchaseClassId), "Pair not Allowed");


        (,,address purchaseTokenAddress,) = debondData.getClassFromId(purchaseClassId);
        (,IDebondBond.InterestRateType interestRateType,address debondTokenAddress,) = debondData.getClassFromId(debondClassId);

        if (debondTokenAddress == DBITAddress) {
            uint amountDBITToMint = mintDbitFromUsd(uint128(purchaseTokenAmount), purchaseTokenAddress, fee); //todo : ferivy if conversion is possible.
            IERC20(purchaseTokenAddress).transferFrom(msg.sender, address(apm), purchaseTokenAmount);
            IDebondToken(debondTokenAddress).mint(address(apm), amountDBITToMint);
            updateWhenAddLiquidity(purchaseTokenAmount, amountDBITToMint, purchaseTokenAddress, debondTokenAddress);

            //todo : put this in one addliq function

        }
        else {//else address ==dgov?
            if (purchaseTokenAddress == DBITAddress) {
                uint amountBToMint = mintDgovFromDbit(purchaseTokenAmount);
                IERC20(purchaseTokenAddress).transferFrom(msg.sender, address(apm), purchaseTokenAmount);
                IDebondToken(debondTokenAddress).mint(address(apm), amountBToMint);
                updateWhenAddLiquidity(purchaseTokenAmount, amountBToMint, purchaseTokenAddress, debondTokenAddress);
            }
            else {
                uint amountDBITToMint = mintDbitFromUsd(uint128(purchaseTokenAmount), purchaseTokenAddress, fee);
                //need cdp from usd to dgov
                uint amountDGOVToMint = mintDgovFromDbit(purchaseTokenAmount);
                IERC20(purchaseTokenAddress).transferFrom(msg.sender, address(apm), purchaseTokenAmount);
                IDebondToken(debondTokenAddress).mint(address(apm), amountDGOVToMint);
                IDebondToken(debondTokenAddress).mint(address(apm), 2 * amountDBITToMint);
                updateWhenAddLiquidity(purchaseTokenAmount, amountDBITToMint, purchaseTokenAddress, DBITAddress);
                updateWhenAddLiquidity(amountDBITToMint, amountDGOVToMint, DBITAddress, debondTokenAddress);
            }

        }

        (uint fixedRate, uint floatingRate) = interestRate(purchaseClassId, debondClassId, purchaseTokenAmount, purchaseMethod);
        if (purchaseMethod == PurchaseMethod.Staking) {
            issueBonds(msg.sender, purchaseClassId, purchaseTokenAmount);
            (uint reserveA, uint reserveB) = getReserves(purchaseTokenAddress, debondTokenAddress);
            //if reserve == 0 : use cdp price instead of quote? See with yu
            //do we have to handle the case where reserve = 0? or when deploying, we put some liquidity?
            uint amount = quote(purchaseTokenAmount, reserveA, reserveB);
            uint rate = interestRateType == IDebondBond.InterestRateType.FixedRate ? fixedRate : floatingRate;
            issueBonds(msg.sender, debondClassId, amount.mul(rate));
        }
        else if (purchaseMethod == PurchaseMethod.Buying) {
            (uint reserveA, uint reserveB) = getReserves(purchaseTokenAddress, debondTokenAddress);
            uint amount = quote(purchaseTokenAmount, reserveA, reserveB);
            uint rate = interestRateType == IDebondBond.InterestRateType.FixedRate ? fixedRate : floatingRate;
            issueBonds(msg.sender, debondClassId, amount + amount.mul(rate));
            // here the interest calculation is hardcoded. require the interest is enough high
        }


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
        uint numDaysNow = getNonceFromDate(timestampToCheck);
        uint numDaysLastNonce = getNonceFromDate(createdAt);
        uint nonceToAdd = numDaysNow - numDaysLastNonce;
        if (nonceToAdd != 0) {
            createNewNonce(classId, lastNonceId + nonceToAdd, timestampToCheck);
            (uint nonceId,) = debondData.getLastNonceCreated(classId);
            IERC3475(debondBondAddress).issue(to, classId, nonceId, amount);
            return;
        }
    }

    function getNonceFromDate(uint256 date) public view returns (uint256) {
        return (date - BASE_TIMESTAMP) / EPOCH;
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

        (,IDebondBond.InterestRateType interestRateType, address purchaseTokenAddress,) = debondData.getClassFromId(purchaseTokenClassId);
        // address of the purchase token


        // staking collateral for bonds
        if (purchaseMethod == PurchaseMethod.Staking) {
            fixRateSupply = bond.bondAmountDue(purchaseTokenAddress, IDebondBond.InterestRateType.FixedRate);
            // we get the fix rate bonds supply
            floatRateSupply = bond.bondAmountDue(purchaseTokenAddress, IDebondBond.InterestRateType.FloatingRate);
            // we get the float rate bonds supply

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

            (,,address debondTokenAddress,) = debondData.getClassFromId(debondTokenClassId);
            // address of D/BIT

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

    function isRedeemable(uint256 classId, uint256 nonceId) external view returns (bool) {
        (, IDebondBond.InterestRateType interestRateType, address tokenAddress,, uint maturityDate,, uint BsumN) = bond.bondDetails(classId, nonceId);
        if (interestRateType == IDebondBond.InterestRateType.FixedRate) return maturityDate <= block.timestamp;
        if (interestRateType == IDebondBond.InterestRateType.FixedRate) {
            return maturityDate <= block.timestamp;
        }
        uint BsumNL = bond.tokenTotalSupply(tokenAddress);
        uint BsumN = bond.tokenSupplyAtNonce(tokenAddress, nonceId);
        uint BsumNInterest = BsumN + BsumN.mul(BENCHMARK_RATE_DECIMAL_18);
        return BsumNInterest < BsumNL;
    }

    function getETA(uint256 classId, uint256 nonceId) external view returns (int256) {
        (, IDebondBond.InterestRateType interestRateType, address tokenAddress,, uint maturityDate,, uint BsumN) = bond.bondDetails(classId, nonceId);

        if (interestRateType == IDebondBond.InterestRateType.FixedRate) {
            return maturityDate;
        }

        uint BsumNL = bond.tokenTotalSupply(tokenAddress);
        uint BsumN = bond.tokenSupplyAtNonce(tokenAddress, nonceId);
        uint BsumNInterest = BsumN + BsumN.mul(BENCHMARK_RATE_DECIMAL_18);
        uint liquidityFlowOver30Nonces = bond.tokenLiquidityFlow(tokenAddress, 30, block.timestamp);
        uint Umonth = liquidityFlowOver30Nonces / 30;
        return DebondMath.floatingETA(maturityDate, BsumN, BENCHMARK_RATE_DECIMAL_18, BsumNL, EPOCH, Umonth);
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
        require(amountA > 0, 'DebondBank: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'DebondBank: INSUFFICIENT_LIQUIDITY');
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
    function _convertTokenToUsd(uint128 _amountToken, address _tokenAddress, uint24 fee) private view returns (uint256 amountUsd) {

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
    function mintDbitFromUsd(uint128 _amountToken, address _tokenAddress, uint24 fee) private view returns (uint256 amountDBIT) {

        uint256 tokenToUsd = _convertTokenToUsd(_amountToken, _tokenAddress, fee);
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
        amountDGOV = (100 ether + (_sCollateralised).div(33333).pow(2)).inv();
    }
    /**
    * @dev given the amount of dbit, returns the amout of DGOV to mint
    * @param _amountDBIT the amount of token
    * @return amountDGOV the amount of DGOV to mint
    */
    function mintDgovFromDbit(uint256 _amountDBIT) private view returns (uint256 amountDGOV) {
        uint256 rate = _cdpDbitToDgov(DGOVAddress);
        amountDGOV = _amountDBIT.mul(rate);
    }
}
