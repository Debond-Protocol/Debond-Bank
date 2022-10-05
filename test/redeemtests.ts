import {
    APMInstance,
    BankInstance,
    DBITTestInstance,
    DGOVTestInstance,
    DebondBondTestInstance,
    USDCInstance,
    USDTInstance,
    WETHInstance,
    BankBondManagerInstance, APMTestInstance
} from "../types/truffle-contracts";

const Bank = artifacts.require("Bank");
const USDC = artifacts.require("USDC");
const USDT = artifacts.require("USDT");
const DBIT = artifacts.require("DBITTest");
const DGOV = artifacts.require("DGOVTest");
const APM = artifacts.require("APMTest");
const WETH = artifacts.require("WETH");
const DebondBondTest = artifacts.require("DebondBondTest");
const BankBondManager = artifacts.require("BankBondManager");

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
    let apmContract: APMTestInstance
    let bondContract: DebondBondTestInstance
    let BankBondManagerContract : BankBondManagerInstance

    const DBIT_FIX_6MTH_CLASS_ID = 0;

    before('Initialisation', async () => {
        usdcContract = await USDC.deployed();
        usdtContract = await USDT.deployed();
        bankContract = await Bank.deployed();
        dbitContract = await DBIT.deployed();
        wethContract = await WETH.deployed();
        dgovContract = await DGOV.deployed();
        apmContract = await APM.deployed();
        bondContract = await DebondBondTest.deployed();
        BankBondManagerContract = await BankBondManager.deployed();

        let governanceAddress = accounts[0];
        await BankBondManagerContract.createClass(12, "USDC", usdcContract.address, 0, 1, {from: governanceAddress});
        await BankBondManagerContract.createClass(13, "WETH", wethContract.address, 0, 1, {from: governanceAddress});

        await BankBondManagerContract.updateCanPurchase(12, 0, true, {from: governanceAddress});
        await BankBondManagerContract.updateCanPurchase(13, 0, true, {from: governanceAddress});

    })


    it('stakeForDbitBondWithElse then redeem', async () => {

        

        //mint usdc to the buyer
        await usdcContract.mint(buyer, web3.utils.toWei('100000', 'ether'));
        
        await dbitContract.setBankAddress(accounts[1]);
        await dbitContract.mintCollateralisedSupply(apmContract.address, web3.utils.toWei('300', 'ether'), {from: accounts[1]});
        await dbitContract.setBankAddress(bankContract.address)

        //approve usdc and buy bonds
        await usdcContract.approve(bankContract.address, web3.utils.toWei('100000', 'ether'), {from: buyer});
        await bankContract.purchaseDBITBondsByStakingTokens(12, 0, web3.utils.toWei('3000', 'ether'), 0, 2000, buyer, {from: buyer});

        const transactions = await getTransactions(buyer)

        //log his nonce so we can use it to query bond blance
        let dbitbondBalance = (transactions.find(t => parseInt(t.classId) == DBIT_FIX_6MTH_CLASS_ID)?.amount) as string;
        let UsdcbondBalance = (transactions.find(t => parseInt(t.classId) == 12)?.amount) as string;

        expect( UsdcbondBalance.toString()).to.equal(web3.utils.toWei('3000', 'ether').toString());
        expect( parseFloat(web3.utils.fromWei(dbitbondBalance, "ether"))).to.greaterThan(90);


        let APMbalanceUSDC = await usdcContract.balanceOf(apmContract.address);
        console.log("apmbalanceusdc :" + APMbalanceUSDC.toString());
        expect( APMbalanceUSDC.toString()).to.equal(web3.utils.toWei('3000', 'ether').toString());

        const UsdcnonceId = (transactions.find(t => parseInt(t.classId) == 12)?.nonceId) as string
        await sleep(1500);
        console.log("before redeeem")
        const DBIT = await dbitContract.balanceOf(apmContract.address)
        console.log(DBIT.toString())
        const r0 = await dbitContract.balanceOf(apmContract.address);

        await bondContract.redeem(buyer, [{classId : 12, nonceId : parseInt(UsdcnonceId), amount: web3.utils.toWei('3000', 'ether')}], {from : buyer});
        console.log("after redeeem")

        let balanceAfterRedeem = await usdcContract.balanceOf(buyer);
        console.log ("balance après " , balanceAfterRedeem.toString());
        expect( balanceAfterRedeem.toString()).to.equal(web3.utils.toWei('100000', 'ether').toString());

        const r1 = await dbitContract.balanceOf(apmContract.address);

        console.log("HEEEEEERRE  " +  r0.toString(), r1.toString());

    })

    it.only('stakeForDbitBondWithEth then redeem', async () => {

        const r0 = await dbitContract.balanceOf(apmContract.address);

        await wethContract.approve(bankContract.address, web3.utils.toWei('100000', 'ether'), {from: buyer});

        let balancebeforeRedeem = await web3.eth.getBalance(buyer);
        console.log ("balance avant " , balancebeforeRedeem.toString());
        let balanceEthBankBefore = await web3.eth.getBalance(bankContract.address);
        console.log ("balance avant " , balanceEthBankBefore.toString());


        await bankContract.purchaseDBITBondsByStakingETH(13, DBIT_FIX_6MTH_CLASS_ID, 0, 2000, buyer, {from: buyer, value: web3.utils.toWei('2', 'ether')});


        const transactions = await getTransactions(buyer)
        let DBITbondBalance = (transactions.find(t => parseInt(t.classId) == DBIT_FIX_6MTH_CLASS_ID)?.amount) as string;
        let ETHbondBalance = (transactions.find(t => parseInt(t.classId) == 13)?.amount) as string;

        expect( ETHbondBalance.toString()).to.equal(web3.utils.toWei('2', 'ether').toString());
        expect( parseFloat(web3.utils.fromWei(DBITbondBalance, "ether"))).to.greaterThan(0.06);

        const WETHbalanceOfAPM = (await wethContract.balanceOf(apmContract.address)).toString()

        expect( WETHbalanceOfAPM.toString()).to.equal(web3.utils.toWei('2', 'ether').toString());

        const ETHNonceId = (transactions.find(t => parseInt(t.classId) == 13)?.nonceId) as string
        console.log(ETHNonceId);
        await sleep(1000);
        await bondContract.redeem(buyer, [{classId : 13, nonceId : parseInt(ETHNonceId), amount: web3.utils.toWei('2', 'ether')}], {from : buyer});

        let balanceAfterRedeem = await web3.eth.getBalance(buyer);
        console.log ("balance après " , balanceAfterRedeem.toString());
        let balanceEthBankAfter = await web3.eth.getBalance(bankContract.address);
        console.log ("balance après " , balanceEthBankAfter.toString());


        let v1 = parseFloat(web3.utils.fromWei(balanceAfterRedeem, "ether"));
        let v2 = parseFloat(web3.utils.fromWei(balancebeforeRedeem, "ether"));
        let v3 = v2-v1;
        expect(v3).to.lessThan(0.03); // gas used

        const r1 = await dbitContract.balanceOf(apmContract.address);

        let p0 = parseFloat(web3.utils.fromWei(r0, "ether"));
        let p1 = parseFloat(web3.utils.fromWei(r1, "ether"));
        let p2 = p1-p0;
        expect(p2).to.lessThan(37000000000000000000); // gas used

        console.log("HEEEEEERRE" + r0.toString(), r1.toString());
    })





});
