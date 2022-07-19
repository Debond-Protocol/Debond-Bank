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

interface Transaction {
    classId: string;
    nonceId: string;
    amount: string;
}

function sleep(ms: any) {
    return new Promise((resolve) => {
        setTimeout(resolve, ms);
    });

}



contract('Bank', async (accounts: string[]) => {

    async function getTransactions(to: string): Promise<Transaction[]> {
        const issues = (await bondContract.getPastEvents("Issue",
            {
                filter: {
                    _to: to
                },
                fromBlock: 0
            }
        )).map(e => {
            let transactions: Transaction[] = [];
            (e.returnValues._transaction).forEach((t: any) => {
                transactions.push({
                    classId: t['classId'],
                    nonceId: t['nonceId'],
                    amount: t['amount']
                })
            })
            return transactions;
        });

        let transactions: Transaction[] = [];
        issues.flat().forEach((t) => {
            const index = transactions.findIndex(v => t.classId == v.classId && t.nonceId == v.nonceId)
            index != -1 ?
                transactions[index].amount = web3.utils.toBN(transactions[index].amount).add(web3.utils.toBN(t.amount)).toString() :
                transactions.push(t)
        })

        return transactions;
    }

    const buyer = accounts[1];

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


    it.only('stakeForDbitBondWithElse then redeem', async () => {

        //mint usdc to the buyer
        await usdcContract.mint(buyer, web3.utils.toWei('100000', 'ether'));

        //approve usdc and buy bonds
        await usdcContract.approve(bankContract.address, web3.utils.toWei('100000', 'ether'), {from: buyer});
        await bankContract.stakeForDbitBondWithElse(1, 0, web3.utils.toWei('3000', 'ether'), 0, 2000, buyer, {from: buyer});

        const transactions = await getTransactions(buyer)

        //log his nonce so we can use it to query bond blance
        let dbitbondBalance = (transactions.find(t => parseInt(t.classId) == DBIT_FIX_6MTH_CLASS_ID)?.amount) as string;
        let UsdcbondBalance = (transactions.find(t => parseInt(t.classId) == USDC_FIX_6MTH_CLASS_ID)?.amount) as string;

        expect( UsdcbondBalance.toString()).to.equal(web3.utils.toWei('3000', 'ether').toString());
        expect( parseFloat(web3.utils.fromWei(dbitbondBalance, "ether"))).to.greaterThan(90);


        let APMbalanceUSDC = await usdcContract.balanceOf(apmContract.address);
        console.log("apmbalanceusdc :" + APMbalanceUSDC.toString());
        expect( APMbalanceUSDC.toString()).to.equal(web3.utils.toWei('3000', 'ether').toString());

        const UsdcnonceId = (transactions.find(t => parseInt(t.classId) == USDC_FIX_6MTH_CLASS_ID)?.nonceId) as string
        await sleep(1500);
        await bankContract.redeemBonds(1, parseInt(UsdcnonceId), web3.utils.toWei('3000', 'ether'), {from : buyer});

        let balanceAfterRedeem = await usdcContract.balanceOf(buyer);
        console.log ("balance après " , balanceAfterRedeem.toString());
        expect( balanceAfterRedeem.toString()).to.equal(web3.utils.toWei('100000', 'ether').toString());

    })

    it('stakeForDbitBondWithEth then redeem', async () => {

        await wethContract.approve(bankContract.address, web3.utils.toWei('100000', 'ether'), {from: buyer});

        let balancebeforeRedeem = await web3.eth.getBalance(buyer);
        console.log ("balance avant " , balancebeforeRedeem.toString());
        let balanceEthBankBefore = await web3.eth.getBalance(bankContract.address);
        console.log ("balance avant " , balanceEthBankBefore.toString());


        await bankContract.stakeForDbitBondWithEth(10, DBIT_FIX_6MTH_CLASS_ID, 0, 2000, buyer, {from: buyer, value: web3.utils.toWei('2', 'ether')});


        const transactions = await getTransactions(buyer)
        let DBITbondBalance = (transactions.find(t => parseInt(t.classId) == DBIT_FIX_6MTH_CLASS_ID)?.amount) as string;
        let ETHbondBalance = (transactions.find(t => parseInt(t.classId) == 10)?.amount) as string;

        expect( ETHbondBalance.toString()).to.equal(web3.utils.toWei('2', 'ether').toString());
        expect( parseFloat(web3.utils.fromWei(DBITbondBalance, "ether"))).to.greaterThan(0.06);

        const WETHbalanceOfAPM = (await wethContract.balanceOf(apmContract.address)).toString()

        expect( WETHbalanceOfAPM.toString()).to.equal(web3.utils.toWei('2', 'ether').toString());

        const ETHNonceId = (transactions.find(t => parseInt(t.classId) == 10)?.nonceId) as string
        console.log(ETHNonceId);
        await sleep(1000);
        await bankContract.redeemBondsETH(10, parseInt(ETHNonceId), web3.utils.toWei('2', 'ether'), {from : buyer});


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
