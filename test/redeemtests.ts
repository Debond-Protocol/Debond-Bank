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
        dgovContract = await DGOV.deployed();
        apmContract = await APM.deployed();
        bondContract = await DebondBondTest.deployed();
    })

    it('should return all the classes', async () => {
        const classes = (await bankContract.getClasses()).map(c => c.toNumber())
        console.log("classes: " + classes)
    })

    //todo : put comments for test


    it('stakeForDbitBondWithElse then redeem', async () => {

        //mint usdc to the buyer
        await usdcContract.mint(buyer, web3.utils.toWei('100000', 'ether'));

        //approve usdc and buy bonds
        await usdcContract.approve(bankContract.address, web3.utils.toWei('100000', 'ether'), {from: buyer});
        await bankContract.stakeForDbitBondWithElse(1, 0, web3.utils.toWei('3000', 'ether'), 0, 2000, buyer, {from: buyer});

        //log his nonce so we can use it to query bond blance
        const DBITNonces = (await bondContract.getNoncesPerAddress(buyer, DBIT_FIX_6MTH_CLASS_ID)).map(n => n.toNumber());
        console.log("nonce: " + DBITNonces[0]);
        let dbitbondBalance = await bondContract.balanceOf(buyer, DBIT_FIX_6MTH_CLASS_ID, DBITNonces[0] );

        //same for usdc
        const USDCNonces = (await bondContract.getNoncesPerAddress(buyer, USDC_FIX_6MTH_CLASS_ID)).map(n => n.toNumber());
        console.log("nonce: " + USDCNonces[0]);
        let UsdcbondBalance = await bondContract.balanceOf(buyer, USDC_FIX_6MTH_CLASS_ID, DBITNonces[0] );

        expect( UsdcbondBalance.toString()).to.equal(web3.utils.toWei('3000', 'ether').toString());
        expect( parseFloat(web3.utils.fromWei(dbitbondBalance, "ether"))).to.greaterThan(90);


        let APMbalanceUSDC = await usdcContract.balanceOf(apmContract.address);
        console.log("apmbalanceusdc :" + APMbalanceUSDC.toString());
        expect( APMbalanceUSDC.toString()).to.equal(web3.utils.toWei('3000', 'ether').toString());

        await bankContract.redeemBonds(1, USDCNonces[0], web3.utils.toWei('3000', 'ether'), {from : buyer});

        let balanceAfterRedeem = await usdcContract.balanceOf(buyer);
        console.log ("balance après " , balanceAfterRedeem.toString());
        expect( balanceAfterRedeem.toString()).to.equal(web3.utils.toWei('100000', 'ether').toString());

    })

    it.only('stakeForDbitBondWithEth then redeem', async () => {

        await wethContract.approve(bankContract.address, web3.utils.toWei('100000', 'ether'), {from: buyer});

        let balancebeforeRedeem = await web3.eth.getBalance(buyer);
        console.log ("balance avant " , balancebeforeRedeem.toString());
        let balanceEthBankBefore = await web3.eth.getBalance(bankContract.address);
        console.log ("balance avant " , balanceEthBankBefore.toString());


        await bankContract.stakeForDbitBondWithEth(10, DBIT_FIX_6MTH_CLASS_ID, 0, 2000, buyer, {from: buyer, value: web3.utils.toWei('2', 'ether')});


        const ETHNonce = (await bondContract.getNoncesPerAddress(buyer, 10));
        const DBITNonces = (await bondContract.getNoncesPerAddress(buyer, DBIT_FIX_6MTH_CLASS_ID)).map(n => n.toNumber());
        let DBITbondBalance = await bondContract.balanceOf(buyer, DBIT_FIX_6MTH_CLASS_ID, DBITNonces[0] );
        let ETHbondBalance = await bondContract.balanceOf(buyer, 10, ETHNonce[0] );

        expect( ETHbondBalance.toString()).to.equal(web3.utils.toWei('2', 'ether').toString());
        expect( parseFloat(web3.utils.fromWei(DBITbondBalance, "ether"))).to.greaterThan(0.06);

        const WETHbalanceOfAPM = (await wethContract.balanceOf(apmContract.address)).toString()

        expect( WETHbalanceOfAPM.toString()).to.equal(web3.utils.toWei('2', 'ether').toString());

        await bankContract.redeemBondsETH(10, ETHNonce[0], web3.utils.toWei('2', 'ether'), {from : buyer});


        let balanceAfterRedeem = await web3.eth.getBalance(buyer);
        console.log ("balance après " , balanceAfterRedeem.toString());
        let balanceEthBankAfter = await web3.eth.getBalance(bankContract.address);
        console.log ("balance après " , balanceEthBankAfter.toString());


        let v1 = parseFloat(web3.utils.fromWei(balanceAfterRedeem, "ether"));
        let v2 = parseFloat(web3.utils.fromWei(balancebeforeRedeem, "ether"));
        let v3 = v2-v1;
        expect(v3).to.greaterThan(-0.01);


    })





});
