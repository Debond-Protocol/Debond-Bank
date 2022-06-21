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



import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "debond-token-contracts/interfaces/IDebondToken.sol";
import "./interfaces/IOracle.sol";
import "./BankBondManager.sol";
import "./libraries/DebondMath.sol";
import "./APMRouter.sol";


contract Bank is APMRouter, BankBondManager, Ownable {

    using DebondMath for uint256;
    using SafeERC20 for IERC20;

    IOracle oracle;
    enum PurchaseMethod {Buying, Staking}
    address public DBITAddress;
    address public DGOVAddress;
    address public USDCAddress;

    bool init;

    constructor(
        address governanceAddress,
        address apmAddress,
        address bondAddress,
        address _DBITAddress,
        address _DGOVAddress,
        address oracleAddress,
        address usdcAddress,
        uint256 baseTimeStamp
    ) APMRouter(apmAddress) BankBondManager(governanceAddress, bondAddress, baseTimeStamp){
        DBITAddress = _DBITAddress;
        DGOVAddress = _DGOVAddress;
        oracle = IOracle(oracleAddress);
        USDCAddress = usdcAddress;
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

        require(canPurchase[purchaseClassId][debondClassId], "Pair not Allowed");


        (address purchaseTokenAddress,,) = classValues(purchaseClassId);
        (address debondTokenAddress, InterestRateType interestRateType,) = classValues(debondClassId);

        if (debondTokenAddress == DBITAddress) {
            uint amountDBITToMint = mintDbitFromUsd(uint128(purchaseTokenAmount), purchaseTokenAddress, fee); //todo : ferivy if conversion is possible.
            IERC20(purchaseTokenAddress).transferFrom(msg.sender, address(apm), purchaseTokenAmount);
            IDebondToken(debondTokenAddress).mintCollateralisedSupply(address(apm), amountDBITToMint);
            updateWhenAddLiquidity(purchaseTokenAmount, amountDBITToMint, purchaseTokenAddress, debondTokenAddress);

            //todo : put this in one addliq function

        }
        else {//else address ==dgov?
            if (purchaseTokenAddress == DBITAddress) {
                uint amountBToMint = mintDgovFromDbit(purchaseTokenAmount);
                IERC20(purchaseTokenAddress).transferFrom(msg.sender, address(apm), purchaseTokenAmount);
                IDebondToken(debondTokenAddress).mintCollateralisedSupply(address(apm), amountBToMint);
                updateWhenAddLiquidity(purchaseTokenAmount, amountBToMint, purchaseTokenAddress, debondTokenAddress);
            }
            else {
                uint amountDBITToMint = mintDbitFromUsd(uint128(purchaseTokenAmount), purchaseTokenAddress, fee);
                //need cdp from usd to dgov
                uint amountDGOVToMint = mintDgovFromDbit(purchaseTokenAmount);
                IERC20(purchaseTokenAddress).transferFrom(msg.sender, address(apm), purchaseTokenAmount);
                IDebondToken(debondTokenAddress).mintCollateralisedSupply(address(apm), amountDGOVToMint);
                IDebondToken(debondTokenAddress).mintCollateralisedSupply(address(apm), 2 * amountDBITToMint);
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
            uint rate = interestRateType == InterestRateType.FixedRate ? fixedRate : floatingRate;
            issueBonds(msg.sender, debondClassId, amount.mul(rate));
        }
        else if (purchaseMethod == PurchaseMethod.Buying) {
            (uint reserveA, uint reserveB) = getReserves(purchaseTokenAddress, debondTokenAddress);
            uint amount = quote(purchaseTokenAmount, reserveA, reserveB);
            uint rate = interestRateType == InterestRateType.FixedRate ? fixedRate : floatingRate;
            issueBonds(msg.sender, debondClassId, amount.mul(rate));
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

        // staking collateral for bonds
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
        uint256 _sCollateralised = IDebondToken(dbitAddress).getTotalCollateralisedSupply();
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
        uint256 _sCollateralised = IDebondToken(dgovAddress).getTotalCollateralisedSupply();
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
