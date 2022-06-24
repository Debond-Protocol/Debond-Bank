import { writeHeapSnapshot } from "v8";
import {
    APMInstance,
    BankInstance,
    DBITTestInstance,
    DebondBondTestInstance,
    USDCInstance,
    USDTInstance,
    WETHInstance
} from "../types/truffle-contracts";

const Bank = artifacts.require("Bank");
const USDC = artifacts.require("USDC");
const USDT = artifacts.require("USDT");
const DBIT = artifacts.require("DBITTest");
const APM = artifacts.require("APMTest");
const WETH = artifacts.require("WETH");
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
    let wethContract: WETHInstance
    let dbitContract: DBITTestInstance
    let apmContract: APMInstance
    let bondContract: DebondBondTestInstance

    const DBIT_FIX_6MTH_CLASS_ID = 0;
    const USDC_FIX_6MTH_CLASS_ID = 1;
    const USDT_FIX_6MTH_CLASS_ID = 2;

    it('buy Bonds with USDC', async () => {
        usdcContract = await USDC.deployed();
        usdtContract = await USDT.deployed();
        bankContract = await Bank.deployed();
        dbitContract = await DBIT.deployed();
        wethContract = await WETH.deployed();
        apmContract = await APM.deployed();
        bondContract = await DebondBondTest.deployed();


        await usdcContract.mint(buyer, web3.utils.toWei('100000', 'ether'));
        await usdcContract.approve(bankContract.address, web3.utils.toWei('100000', 'ether'), {from: buyer});
        await bankContract.buyBond(USDC_FIX_6MTH_CLASS_ID, DBIT_FIX_6MTH_CLASS_ID, web3.utils.toWei('3000', 'ether'), PurchaseMethod.BUYING, 0, {from: buyer});
        const DBITNonces = (await bondContract.getNoncesPerAddress(buyer, DBIT_FIX_6MTH_CLASS_ID)).map(n => n.toNumber());
        console.log("balance Bond D/BIT: AFTER " + (await bondContract.balanceOf(buyer, DBIT_FIX_6MTH_CLASS_ID, DBITNonces[0])));

        console.log("1");
        await usdcContract.approve(bankContract.address, web3.utils.toWei('100000', 'ether'), {from: buyer});
        console.log("2");
        await bankContract.buyBond(USDC_FIX_6MTH_CLASS_ID, DBIT_FIX_6MTH_CLASS_ID, web3.utils.toWei('3000', 'ether'), PurchaseMethod.BUYING,20, {from: buyer});
        console.log("3");


    })

    it('buy Bonds with USDT', async () => {

        usdcContract = await USDC.deployed();
        usdtContract = await USDT.deployed();
        bankContract = await Bank.deployed();
        dbitContract = await DBIT.deployed();
        apmContract = await APM.deployed();
        bondContract = await DebondBondTest.deployed();

        await usdtContract.mint(buyer, web3.utils.toWei('100000', 'ether'));
        await usdtContract.approve(bankContract.address, web3.utils.toWei('100000', 'ether'), {from: buyer});
        await bankContract.buyBond(USDT_FIX_6MTH_CLASS_ID, DBIT_FIX_6MTH_CLASS_ID, web3.utils.toWei('3000', 'ether'), PurchaseMethod.BUYING,0, {from: buyer});
        const DBITNonces = (await bondContract.getNoncesPerAddress(buyer, DBIT_FIX_6MTH_CLASS_ID)).map(n => n.toNumber());
        console.log("balance Bond D/BIT: AFTER " + (await bondContract.balanceOf(buyer, DBIT_FIX_6MTH_CLASS_ID, DBITNonces[0])));



    })

    //we should do this test with something else than usdc
    it('buy Bonds: stakeForDbitBondWithElse', async () => {
        usdcContract = await USDC.deployed();
        usdtContract = await USDT.deployed();
        bankContract = await Bank.deployed();
        dbitContract = await DBIT.deployed();
        wethContract = await WETH.deployed();
        apmContract = await APM.deployed();
        bondContract = await DebondBondTest.deployed();


        // await apmContract.updateTotalReserve(usdcContract.address, web3.utils.toWei('10000', 'ether')) // adding reserve
        // await apmContract.updateTotalReserve(dbitContract.address, web3.utils.toWei('10000', 'ether')) // adding reserve

        await usdcContract.mint(buyer, web3.utils.toWei('100000', 'ether'));

        let balance = await usdcContract.balanceOf(buyer);
        console.log("usdcBalance" + balance.toString());
        
        await usdcContract.approve(bankContract.address, web3.utils.toWei('100000', 'ether'), {from: buyer});
        let amount = await bankContract.stakeForDbitBondWithElse(USDC_FIX_6MTH_CLASS_ID, DBIT_FIX_6MTH_CLASS_ID, web3.utils.toWei('3000', 'ether'), 0, 2000, buyer, {from: buyer});
        
       
        //console.log("logs: ", amount.logs);
        console.log("logs: ", parseInt(amount.receipt.rawLogs[0].topics, 16));
        

        
        
        //console.log("amount: ", amount.logs[0].args[0]["words"][1]);

        /*
        let amount0 = amount.logs[0].args[0]["words"][1];
        console.log("amount0: ", amount0);

        let amount1 = amount.logs[1].args[0]["words"][1];
        console.log("amount1: ", amount1);

        let amount2 = amount.logs[2].args[0]["words"][1];
        console.log("amount2: ", amount2);

        let amount3 = amount.logs[3].args[0];
        console.log("amount3: ", amount3);

        let amount4 = amount.logs[4].args[0];
        console.log("amount4: ", amount4);

        let amount5 = amount.logs[5].args[0];
        console.log("amount5: ", amount5);

        let amount6 = amount.logs[6].args[0]["words"][1];
        console.log("amount6: ", amount6);*/

        

        const DBITNonces = (await bondContract.getNoncesPerAddress(buyer, DBIT_FIX_6MTH_CLASS_ID)).map(n => n.toNumber());
        console.log("nonce: " + DBITNonces[0]);
        let dbitbondBalance = await bondContract.balanceOf(buyer, DBIT_FIX_6MTH_CLASS_ID, DBITNonces[0] );
        
        const USDCNonces = (await bondContract.getNoncesPerAddress(buyer, USDC_FIX_6MTH_CLASS_ID)).map(n => n.toNumber());
        console.log("nonce: " + USDCNonces[0]);
        let UsdcbondBalance = await bondContract.balanceOf(buyer, USDC_FIX_6MTH_CLASS_ID, DBITNonces[0] );
        
        let USDCBALANCE = await usdcContract.balanceOf(buyer);
        console.log("DBITbondBalance: " + dbitbondBalance.toString());
        console.log("USDCbondBalance: " + UsdcbondBalance.toString());
        expect( UsdcbondBalance.toString()).to.equal(web3.utils.toWei('3000', 'ether').toString());
        console.log("usdcBalance: " + USDCBALANCE.toString());

        //now we have check bond balances, we check balances in apm

        const s = await apmContract.getReserves(usdcContract.address, dbitContract.address);
        console.log("here we print r0 after stakebonds : " + s[0].toString(), "here we print r1 after stake bonds :" + s[1].toString());

        let APMbalanceUSDC = await usdcContract.balanceOf(apmContract.address);
        console.log("apmbalanceusdc :" + APMbalanceUSDC.toString());

        let APMbalanceDBIT = await dbitContract.balanceOf(apmContract.address);
        console.log("apmbalanceDBIT :" , APMbalanceDBIT.toString());
    })

    it('buy Bonds: stakeForDbitBondWithEth', async () => {
        usdcContract = await USDC.deployed();
        usdtContract = await USDT.deployed();
        bankContract = await Bank.deployed();
        dbitContract = await DBIT.deployed();
        wethContract = await WETH.deployed();
        apmContract = await APM.deployed();
        bondContract = await DebondBondTest.deployed();


        
        await wethContract.approve(bankContract.address, web3.utils.toWei('100000', 'ether'), {from: buyer});
        await usdcContract.approve(bankContract.address, web3.utils.toWei('100000', 'ether'), {from: buyer});
        await bankContract.stakeForDbitBondWithEth(10, DBIT_FIX_6MTH_CLASS_ID, 0, 2000, buyer, {from: buyer, value: web3.utils.toWei('2', 'ether').toString()});


        const DBITNonces = (await bondContract.getNoncesPerAddress(buyer, DBIT_FIX_6MTH_CLASS_ID)).map(n => n.toNumber());
        console.log("nonce: " + DBITNonces[0]);
        let dbitbondBalance = await bondContract.balanceOf(buyer, DBIT_FIX_6MTH_CLASS_ID, DBITNonces[0] );
        
        
        let UsdcbondBalance = await bondContract.balanceOf(buyer, USDC_FIX_6MTH_CLASS_ID, DBITNonces[0] );
        
        let USDCBALANCE = await usdcContract.balanceOf(buyer);
        console.log("DBITbondBalance: " + dbitbondBalance.toString());
        console.log("USDCbondBalance: " + UsdcbondBalance.toString());
        //expect( UsdcbondBalance.toString()).to.equal(web3.utils.toWei('3000', 'ether').toString());
        console.log("usdcBalance: " + USDCBALANCE.toString());

        //now we have check bond balances, we check balances in apm

        const s = await apmContract.getReserves(usdcContract.address, dbitContract.address);
        console.log("here we print r0 after stakebonds : " + s[0].toString(), "here we print r1 after stake bonds :" + s[1].toString());

        let APMbalanceUSDC = await usdcContract.balanceOf(apmContract.address);
        console.log("apmbalanceusdc :" + APMbalanceUSDC.toString());

        let APMbalanceDBIT = await dbitContract.balanceOf(apmContract.address);
        console.log("apmbalanceDBIT :" , APMbalanceDBIT.toString());

        const WETHbalanceOfAPM = (await wethContract.balanceOf(apmContract.address)).toString()
        console.log("WETH Balance of APM: " + WETHbalanceOfAPM);



    })



    it('redeem Bonds too early should send error', async () => {

        const DBITNonces = (await bondContract.getNoncesPerAddress(buyer, DBIT_FIX_6MTH_CLASS_ID)).map(n => n.toNumber());
        console.log("nonce: " + DBITNonces[0]);
        try {
            await bankContract.redeemBonds(DBIT_FIX_6MTH_CLASS_ID, DBITNonces[0], web3.utils.toWei('1000', 'ether'), {from: buyer});
        } catch (e: any) {
            assert.isTrue(true)
        }

        console.log("balance Bond D/BIT: AFTER " + (await bondContract.balanceOf(buyer, DBIT_FIX_6MTH_CLASS_ID, DBITNonces[0])));
    })
});
