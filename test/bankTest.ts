import { writeHeapSnapshot } from "v8";
import {
    APMInstance,
    BankInstance,
    DBITInstance, DebondBondTestInstance,
    DebondDataInstance,
    USDCInstance,
    USDTInstance,
    WethInstance
} from "../types/truffle-contracts";

const Bank = artifacts.require("Bank");
const USDC = artifacts.require("USDC");
const USDT = artifacts.require("USDT");
const DBIT = artifacts.require("DBIT");
const APM = artifacts.require("APMTest");
const WETH = artifacts.require("Weth");
const DebondData = artifacts.require("DebondData");
const DebondBondTest = artifacts.require("DebondBondTest");



contract('Bank', async (accounts: string[]) => {
    const buyer = accounts[1];
    enum PurchaseMethod {
        BUYING = 0,
        STAKING = 1,
    }

    let usdcContract: USDCInstance
    let usdtContract: USDTInstance
    let bankContract: BankInstance
    let dbitContract: DBITInstance
    let wethContract: WethInstance
    let apmContract: APMInstance
    let dataContract: DebondDataInstance
    let bondContract: DebondBondTestInstance

    let DBIT_FIX_6MTH_CLASS_ID: number;
    let USDC_FIX_6MTH_CLASS_ID: number;
    let USDT_FIX_6MTH_CLASS_ID: number;

    it('buy Bonds', async () => {
        usdcContract = await USDC.deployed();
        usdtContract = await USDT.deployed();
        bankContract = await Bank.deployed();
        dbitContract = await DBIT.deployed();
        wethContract = await WETH.deployed();
        apmContract = await APM.deployed();
        dataContract = await DebondData.deployed();
        bondContract = await DebondBondTest.deployed();

        DBIT_FIX_6MTH_CLASS_ID = ((await dataContract.allDebondClasses()).map(c => c.toNumber()))[0];
        const purchasableClasses = (await dataContract.getPurchasableClasses(DBIT_FIX_6MTH_CLASS_ID)).map(c => c.toNumber());
        USDC_FIX_6MTH_CLASS_ID = purchasableClasses[0];
        USDT_FIX_6MTH_CLASS_ID = purchasableClasses[1];


        // await apmContract.updateTotalReserve(usdcContract.address, web3.utils.toWei('10000', 'ether')) // adding reserve
        // await apmContract.updateTotalReserve(dbitContract.address, web3.utils.toWei('10000', 'ether')) // adding reserve

        await usdcContract.mint(buyer, web3.utils.toWei('100000', 'ether'));

        console.log("1");
        await usdcContract.approve(bankContract.address, web3.utils.toWei('100000', 'ether'), {from: buyer});
        console.log("2");
        await bankContract.buyBond(USDC_FIX_6MTH_CLASS_ID, DBIT_FIX_6MTH_CLASS_ID, web3.utils.toWei('3000', 'ether'), PurchaseMethod.BUYING,20, {from: buyer});
        console.log("3");



    })

    it.only('buy Bonds: stakeForDbitBondWithElse', async () => {
        usdcContract = await USDC.deployed();
        usdtContract = await USDT.deployed();
        bankContract = await Bank.deployed();
        dbitContract = await DBIT.deployed();
        wethContract = await WETH.deployed();
        apmContract = await APM.deployed();
        dataContract = await DebondData.deployed();
        bondContract = await DebondBondTest.deployed();

        DBIT_FIX_6MTH_CLASS_ID = ((await dataContract.allDebondClasses()).map(c => c.toNumber()))[0];
        const purchasableClasses = (await dataContract.getPurchasableClasses(DBIT_FIX_6MTH_CLASS_ID)).map(c => c.toNumber());
        USDC_FIX_6MTH_CLASS_ID = purchasableClasses[0];
        USDT_FIX_6MTH_CLASS_ID = purchasableClasses[1];


        // await apmContract.updateTotalReserve(usdcContract.address, web3.utils.toWei('10000', 'ether')) // adding reserve
        // await apmContract.updateTotalReserve(dbitContract.address, web3.utils.toWei('10000', 'ether')) // adding reserve

        await usdcContract.mint(buyer, web3.utils.toWei('100000', 'ether'));

        let balance = await usdcContract.balanceOf(buyer);
        console.log("usdcBalance" + balance.toString());
        
        await usdcContract.approve(bankContract.address, web3.utils.toWei('100000', 'ether'), {from: buyer});
        let amount = await bankContract.stakeForDbitBondWithElse(USDC_FIX_6MTH_CLASS_ID, DBIT_FIX_6MTH_CLASS_ID, web3.utils.toWei('3000', 'ether'), 0, 2000, buyer, {from: buyer});
        console.log("amount: " + amount);

        const DBITNonces = (await bondContract.getNoncesPerAddress(buyer, DBIT_FIX_6MTH_CLASS_ID)).map(n => n.toNumber());
        console.log("nonce: " + DBITNonces[0]);
        let dbitbondBalance = await bondContract.balanceOf(buyer, DBIT_FIX_6MTH_CLASS_ID, DBITNonces[0] );
        const USDCNonces = (await bondContract.getNoncesPerAddress(buyer, USDC_FIX_6MTH_CLASS_ID)).map(n => n.toNumber());
        console.log("nonce: " + USDCNonces[0]);
        let UsdcbondBalance = await bondContract.balanceOf(buyer, USDC_FIX_6MTH_CLASS_ID, DBITNonces[0] );
        let USDCBALANCE = await usdcContract.balanceOf(buyer);
        console.log("DBITbondBalance: " + dbitbondBalance.toString());
        console.log("USDCbondBalance: " + UsdcbondBalance.toString());
        console.log("usdcBalance: " + USDCBALANCE.toString());

    })



    it('redeem Bonds', async () => {

        const DBITNonces = (await bondContract.getNoncesPerAddress(buyer, DBIT_FIX_6MTH_CLASS_ID)).map(n => n.toNumber());
        console.log("nonce: " + DBITNonces[0]);
        await bankContract.redeemBonds(DBIT_FIX_6MTH_CLASS_ID, DBITNonces[0], web3.utils.toWei('1000', 'ether'), {from: buyer});

        console.log("balance Bond D/BIT: AFTER " + (await bondContract.balanceOf(buyer, DBIT_FIX_6MTH_CLASS_ID, DBITNonces[0])));
    })
});
