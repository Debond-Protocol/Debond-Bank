import {
    APMInstance,
    BankInstance,
    DBITInstance, DebondBondTestInstance,
    DebondDataInstance,
    USDCInstance,
    USDTInstance
} from "../types/truffle-contracts";

const Bank = artifacts.require("Bank");
const USDC = artifacts.require("USDC");
const USDT = artifacts.require("USDT");
const DBIT = artifacts.require("DBIT");
const APM = artifacts.require("APMTest");
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
    let apmContract: APMInstance
    let dataContract: DebondDataInstance
    let bondContract: DebondBondTestInstance

    let DBIT_FIX_6MTH_CLASS_ID: number;
    let USDC_FIX_6MTH_CLASS_ID: number;
    let USDT_FIX_6MTH_CLASS_ID: number;

    it('Initialisation', async () => {
        usdcContract = await USDC.deployed();
        usdtContract = await USDT.deployed();
        bankContract = await Bank.deployed();
        dbitContract = await DBIT.deployed();
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
        await usdcContract.approve(bankContract.address, web3.utils.toWei('100000', 'ether'), {from: buyer});
        await bankContract.buyBond(USDC_FIX_6MTH_CLASS_ID, DBIT_FIX_6MTH_CLASS_ID, web3.utils.toWei('3000', 'ether'), 0, PurchaseMethod.BUYING,0, {from: buyer});




    })

    it('redeem Bonds', async () => {

        const DBITNonces = (await bondContract.getNoncesPerAddress(buyer, DBIT_FIX_6MTH_CLASS_ID)).map(n => n.toNumber());
        console.log("nonce: " + DBITNonces[0]);
        await bankContract.redeemBonds(DBIT_FIX_6MTH_CLASS_ID, DBITNonces[0], web3.utils.toWei('1000', 'ether'), {from: buyer});

        console.log("balance Bond D/BIT: AFTER " + (await bondContract.balanceOf(buyer, DBIT_FIX_6MTH_CLASS_ID, DBITNonces[0])));
    })
});
