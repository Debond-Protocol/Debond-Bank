import { writeHeapSnapshot } from "v8";
import {
    APMInstance,
    BankInstance,
    DBITTestInstance,
    DGOVTestInstance,
    DebondBondTestInstance,
    USDCInstance,
    USDTInstance,
    WETHInstance
} from "../types/truffle-contracts";

const Bank = artifacts.require("Bank");
const USDC = artifacts.require("USDC");
const USDT = artifacts.require("USDT");
const DBIT = artifacts.require("DBITTest");
const DGOV = artifacts.require("DGOVTest");
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
    let dgovContract: DGOVTestInstance
    let apmContract: APMInstance
    let bondContract: DebondBondTestInstance

    const DBIT_FIX_6MTH_CLASS_ID = 0;
    const USDC_FIX_6MTH_CLASS_ID = 1;
    const USDT_FIX_6MTH_CLASS_ID = 2;

    before('Initialisation', async () => {
        usdcContract = await USDC.deployed();
        usdtContract = await USDT.deployed();
        bankContract = await Bank.deployed();
        dbitContract = await DBIT.deployed();
        wethContract = await WETH.deployed();
        apmContract = await APM.deployed();
        bondContract = await DebondBondTest.deployed();
    })

    it('should return all the classes', async () => {
        const classes = (await bankContract.getClasses()).map(c => c.toNumber())
        console.log("classes: " + classes)
    })
    
    //todo : put comments for test
    //we should do this test with something else than usdc
    it('buy Bonds: stakeForDbitBondWithElse', async () => {

        //mint usdc to the buyer
        await usdcContract.mint(buyer, web3.utils.toWei('100000', 'ether'));

        //log his usdc balance
        let balance = await usdcContract.balanceOf(buyer);
        console.log("usdcBalance" + balance.toString());

        //approve usdc and buy bonds
        await usdcContract.approve(bankContract.address, web3.utils.toWei('100000', 'ether'), {from: buyer});
        let amount = await bankContract.stakeForDbitBondWithElse(USDC_FIX_6MTH_CLASS_ID, DBIT_FIX_6MTH_CLASS_ID, web3.utils.toWei('3000', 'ether'), 0, 2000, buyer, {from: buyer});
        
       //log his nonce so we can use it to query bond blance
        const DBITNonces = (await bondContract.getNoncesPerAddress(buyer, DBIT_FIX_6MTH_CLASS_ID)).map(n => n.toNumber());
        console.log("nonce: " + DBITNonces[0]);
        let dbitbondBalance = await bondContract.balanceOf(buyer, DBIT_FIX_6MTH_CLASS_ID, DBITNonces[0] );
        
        //same for usdc
        const USDCNonces = (await bondContract.getNoncesPerAddress(buyer, USDC_FIX_6MTH_CLASS_ID)).map(n => n.toNumber());
        console.log("nonce: " + USDCNonces[0]);
        let UsdcbondBalance = await bondContract.balanceOf(buyer, USDC_FIX_6MTH_CLASS_ID, DBITNonces[0] );
        
        //query how much usdc buyer has now after buying
        let USDCBALANCE = await usdcContract.balanceOf(buyer);
        console.log("usdcBalance: " + USDCBALANCE.toString());

        //log bond balances
        console.log("DBITbondBalance: " + dbitbondBalance.toString());
        console.log("USDCbondBalance: " + UsdcbondBalance.toString());

        //we should have 3000 usdc bond
        expect( UsdcbondBalance.toString()).to.equal(web3.utils.toWei('3000', 'ether').toString());
        
        //now we have check bond balances, we check balances in apm

        const s = await apmContract.getReserves(usdcContract.address, dbitContract.address);
        console.log("here we print r0 after stakebonds : " + s[0].toString(), "here we print r1 after stake bonds :" + s[1].toString());

        let APMbalanceUSDC = await usdcContract.balanceOf(apmContract.address);
        console.log("apmbalanceusdc :" + APMbalanceUSDC.toString());
        expect( APMbalanceUSDC.toString()).to.equal(web3.utils.toWei('3000', 'ether').toString());

        let APMbalanceDBIT = await dbitContract.balanceOf(apmContract.address);
        console.log("apmbalanceDBIT :" , APMbalanceDBIT.toString());
    })

    //todo : error to solve : sender account not recognized (mintcoll supply)
    it('buy Bonds: stakeForDgovBondWithDbit', async () => {

        await dbitContract.setBankAddress(accounts[1]);
        //mint dbit to the buyer
        await dbitContract.mintCollateralisedSupply(buyer, web3.utils.toWei('100000', 'ether'), {from: accounts[1]});
        await dbitContract.setBankAddress(bankContract.address)

        //log his dbit balance
        let balance = await dbitContract.balanceOf(buyer);
        console.log("dbitBalance" + balance.toString());

        //approve dbit and buy bonds
        await dbitContract.approve(bankContract.address, web3.utils.toWei('100000', 'ether'), {from: buyer});
        let amount = await bankContract.stakeForDgovBondWithDbit(0, 4, web3.utils.toWei('3000', 'ether'), 0, 2000, buyer, {from: buyer});
        
       //log his nonce so we can use it to query bond blance
        const DGOVNonces = (await bondContract.getNoncesPerAddress(buyer, DBIT_FIX_6MTH_CLASS_ID)).map(n => n.toNumber());
        console.log("nonce: " + DGOVNonces[0]);
        let dgovbondBalance = await bondContract.balanceOf(buyer, 4, DGOVNonces[0] );
        
        //same for DBIT
        const DBITNonces = (await bondContract.getNoncesPerAddress(buyer, 0)).map(n => n.toNumber());
        console.log("nonce: " + DBITNonces[0]);
        let DBITbondBalance = await bondContract.balanceOf(buyer, 0, DBITNonces[0] );
        
        //query how much dbit buyer has now after buying
        let DBITBALANCE = await dbitContract.balanceOf(buyer);
        console.log("dbitBalance: " + DBITBALANCE.toString());

        //log bond balances
        console.log("dgovbondBalance: " + dgovbondBalance.toString());
        console.log("DBITbondBalance: " + DBITbondBalance.toString());

        //we should have 3000 usdc bond
        expect( DBITbondBalance.toString()).to.equal(web3.utils.toWei('3000', 'ether').toString());
        
        //now we have check bond balances, we check balances in apm

        /*
        const s = await apmContract.getReserves(dbitContract.address, dgovContract.address);
        console.log("here we print r0 after stakebonds : " + s[0].toString(), "here we print r1 after stake bonds :" + s[1].toString());

        let APMbalanceDGOV = await dgovContract.balanceOf(apmContract.address);
        console.log("apmbalanceusdc :" + APMbalanceDGOV.toString());

        let APMbalanceDBIT = await dbitContract.balanceOf(apmContract.address);
        console.log("apmbalanceDBIT :" , APMbalanceDBIT.toString());
        expect( APMbalanceDBIT.toString()).to.equal(web3.utils.toWei('3000', 'ether').toString());
        */
    })

    it.only('buy Bonds: stakeFordgovBondWithElse', async () => {

        //mint usdc to the buyer
        await usdcContract.mint(buyer, web3.utils.toWei('100000', 'ether'));

        //log his usdc balance
        let balance = await usdcContract.balanceOf(buyer);
        console.log("usdcBalance" + balance.toString());

        //approve usdc and buy bonds
        await usdcContract.approve(bankContract.address, web3.utils.toWei('100000', 'ether'), {from: buyer});
        let amount = await bankContract.stakeForDgovBondWithElse(USDC_FIX_6MTH_CLASS_ID, 4, web3.utils.toWei('3000', 'ether'), 0, 2000, buyer, {from: buyer});
        
       //log his nonce so we can use it to query bond blance
        const dgovNonces = (await bondContract.getNoncesPerAddress(buyer, 4)).map(n => n.toNumber());
        console.log("nonce: " + dgovNonces[0]);
        let dgovbondBalance = await bondContract.balanceOf(buyer, 4, dgovNonces[0] );
        
        //same for usdc
        const USDCNonces = (await bondContract.getNoncesPerAddress(buyer, USDC_FIX_6MTH_CLASS_ID)).map(n => n.toNumber());
        console.log("nonce: " + USDCNonces[0]);
        let UsdcbondBalance = await bondContract.balanceOf(buyer, USDC_FIX_6MTH_CLASS_ID, dgovNonces[0] );
        
        //query how much usdc buyer has now after buying
        let USDCBALANCE = await usdcContract.balanceOf(buyer);
        console.log("usdcBalance: " + USDCBALANCE.toString());

        //log bond balances
        console.log("dgovbondBalance: " + dgovbondBalance.toString());
        console.log("USDCbondBalance: " + UsdcbondBalance.toString());

        //we should have 3000 usdc bond
        expect( UsdcbondBalance.toString()).to.equal(web3.utils.toWei('3000', 'ether').toString());
        
        //now we have check bond balances, we check balances in apm

        /*
        const s = await apmContract.getReserves(usdcContract.address, dgovContract.address);
        console.log("here we print r0 after stakebonds : " + s[0].toString(), "here we print r1 after stake bonds :" + s[1].toString());

        let APMbalanceUSDC = await usdcContract.balanceOf(apmContract.address);
        console.log("apmbalanceusdc :" + APMbalanceUSDC.toString());
        expect( APMbalanceUSDC.toString()).to.equal(web3.utils.toWei('3000', 'ether').toString());

        let APMbalancedgov = await dgovContract.balanceOf(apmContract.address);
        console.log("apmbalancedgov :" , APMbalancedgov.toString());
        */
    })

    it('buy Bonds: stakeFordgovBondWithEth', async () => {
        usdcContract = await USDC.deployed();
        usdtContract = await USDT.deployed();
        bankContract = await Bank.deployed();
        dbitContract = await DBIT.deployed();
        wethContract = await WETH.deployed();
        apmContract = await APM.deployed();
        bondContract = await DebondBondTest.deployed();


        
        await wethContract.approve(bankContract.address, web3.utils.toWei('100000', 'ether'), {from: buyer});
        await usdcContract.approve(bankContract.address, web3.utils.toWei('100000', 'ether'), {from: buyer});
        await bankContract.stakeForDbitBondWithEth(10, DBIT_FIX_6MTH_CLASS_ID, 0, 2000, buyer, {from: buyer, value: web3.utils.toWei('2', 'ether')});

        const DBITNoncesTest = (await bondContract.getNoncesPerAddress(buyer, DBIT_FIX_6MTH_CLASS_ID));
        console.log("nonce: " + DBITNoncesTest);

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



    
});
