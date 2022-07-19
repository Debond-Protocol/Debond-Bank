import {

    USDCInstance, APMInstance, BankInstance, DBITTestInstance, WETHInstance
} from "../types/truffle-contracts";

const APM = artifacts.require("APMTest");
const Bank = artifacts.require("Bank");
const DBIT = artifacts.require("DBITTest");
const USDC = artifacts.require("USDC");
const WETH = artifacts.require("WETH");


contract('External Swap (from Bank)', async (accounts: string[]) => {
    const swapper = accounts[1];
    let dbitInstance: DBITTestInstance;
    let bankContract: BankInstance;
    let usdcContract: USDCInstance;
    let apmContract: APMInstance;
    let wethContract : WETHInstance;


    before('Initialisation', async () => {
        bankContract = await Bank.deployed();
        usdcContract = await USDC.deployed();
        dbitInstance = await DBIT.deployed();
        apmContract = await APM.deployed();
        wethContract = await WETH.deployed();

        //await debondBondInstance.setApprovalFor(); No need approval for now

        // 1 get some tokens
        await usdcContract.mint(swapper, web3.utils.toWei('100', 'ether'));
        await usdcContract.mint(apmContract.address, web3.utils.toWei('100', 'ether'));
        await usdcContract.approve(bankContract.address, web3.utils.toWei('100', 'ether'), {from: swapper})

        await dbitInstance.approve(bankContract.address, web3.utils.toWei('100', 'ether'), {from: swapper})

        let wethBalanceBeforeMint = await wethContract.balanceOf(apmContract.address);
        console.log("wethBalanceBeforeMint", wethBalanceBeforeMint.toString());

        //await wethContract.mint(apmContract.address, web3.utils.toWei('0.1', 'ether'));
        await wethContract.approve(bankContract.address, web3.utils.toWei('0.1', 'ether'), {from: swapper})

        let wethBalanceAfterMint = await wethContract.balanceOf(apmContract.address);
        console.log("wethBalanceAfterMint", wethBalanceAfterMint.toString());

        await dbitInstance.setBankAddress(accounts[1]);
        await dbitInstance.mintCollateralisedSupply(swapper, web3.utils.toWei('0.1', 'ether'), {from: accounts[1]});

        await dbitInstance.mintCollateralisedSupply(apmContract.address, web3.utils.toWei('200.2', 'ether'), {from: accounts[1]});
        await dbitInstance.setBankAddress(bankContract.address)

        const a = await apmContract.getReserves(usdcContract.address, dbitInstance.address);
        console.log("here we print r0 before addLiqq : " + a[0].toString(), "here we print r1 before addliq :" + a[1].toString());


        //
        await apmContract.setBankAddress(accounts[1]);

        await apmContract.updateWhenAddLiquidity(
            web3.utils.toWei('200', 'ether'),
            web3.utils.toWei('100', 'ether'),
            dbitInstance.address,
            usdcContract.address,
            {from: accounts[1]}
        );

        await apmContract.updateWhenAddLiquidity(
            web3.utils.toWei('0.2', 'ether'),
            web3.utils.toWei('0.1', 'ether'),
            dbitInstance.address,
            wethContract.address,
            {from: accounts[1]}
        );

        await apmContract.setBankAddress(bankContract.address);
        await dbitInstance.setBankAddress(bankContract.address);


        //Pour plus tard
        const s = await apmContract.getReserves(dbitInstance.address, usdcContract.address);
        console.log("here we print r0 After addLiqq : " + s[0].toString(), "here we print r1 After addliq :" + s[1].toString());

        const t = await apmContract.getReserves(dbitInstance.address, wethContract.address);
        console.log("here we print r0 AfterEth addLiqq : " + t[0].toString(), "here we print r1 AfterEth addliq :" + t[1].toString());




        let balanceEThSwapperBeforeDeposit= await wethContract.balanceOf(swapper);
        console.log("swapper weth before deposit", balanceEThSwapperBeforeDeposit.toString())

        //web3.eth.sendTransaction({from : accounts[0], to : wethContract.address, value : web3.utils.toWei('0.1', 'ether') });
        await wethContract.deposit({from : swapper, value : web3.utils.toWei('0.2', 'ether') })

        let balanceEThSwapperAfterDeposit= await wethContract.balanceOf(swapper);
        console.log("swapper weth After deposit", balanceEThSwapperAfterDeposit.toString())


        //wethContract.approve(accounts[0], web3.utils.toWei('0.1', 'ether'), {from : accounts[0]});
        await wethContract.transfer(apmContract.address, web3.utils.toWei('0.1', 'ether'), {from : swapper})

        let balanceWethApm = await wethContract.balanceOf(apmContract.address);
        console.log("APM weth amount after transfer", balanceWethApm.toString())

        let balanceEThSwapperAfterswap = await wethContract.balanceOf(swapper);
        console.log("swapper weth after transfer", balanceEThSwapperAfterswap.toString())

        let balanceDbitApm = await dbitInstance.balanceOf(apmContract.address);
        console.log("DBIT IN APM", balanceDbitApm.toString())
    });

    it("should swap", async () => {
        // setting the bank


        await apmContract.setBankAddress(bankContract.address);
        await bankContract.swapExactTokensForTokens(
            web3.utils.toWei('10', 'ether'),
            web3.utils.toWei('15', 'ether'),
            [usdcContract.address, dbitInstance.address],
            swapper,
            {from: swapper});


        const dbitBalance = await dbitInstance.balanceOf(swapper);
        expect(dbitBalance.toString()).to.equal(web3.utils.toWei('18.281818181818181818', 'ether').toString()); //value found with xy=k formula // value is 18.181818 + 0.1 the swapper already has

        const s = await apmContract.getReserves(usdcContract.address, dbitInstance.address);
        console.log("here we print r0 after swap : " + s[0].toString(), "here we print r1 after swap :" + s[1].toString());

    })

    it.only("should revert with K error", async () => {

        console.log("should NOT swap");
        const s = await apmContract.getReserves(usdcContract.address, dbitInstance.address);
        console.log("here we print r0 before swap : " + s[0].toString(), "here we print r1 before swap :" + s[1].toString());

        try {
            await apmContract.swap(0, web3.utils.toWei('10', 'ether'), usdcContract.address, dbitInstance.address, swapper)
        } catch (e: any) {
            assert(e.data.stack.includes("revert APM swap: K"))
        }


        const l = await apmContract.getReserves(usdcContract.address, dbitInstance.address);
        console.log("here we print r0 after swap : " + l[0].toString(), "here we print r1 after swap :" + l[1].toString());

    })

    it("should swapExactEthForTokens", async () => {
        // setting the bank
        await apmContract.setBankAddress(bankContract.address);
        await bankContract.swapExactEthForTokens(
            //web3.utils.toWei('0.01', 'ether'),
            web3.utils.toWei('0.0001', 'ether'),
            [wethContract.address, dbitInstance.address],
            swapper,
            {from: swapper, value : web3.utils.toWei('0.01', 'ether') });


        const dbitBalance = await dbitInstance.balanceOf(swapper);
        expect(dbitBalance.toString()).to.equal(web3.utils.toWei('0.118181818181818181', 'ether').toString()); //value found with xy=k formula //0.018181818181818181 +0.1 initally

        const s = await apmContract.getReserves(usdcContract.address, dbitInstance.address);
        console.log("here we print r0 after swap : " + s[0].toString(), "here we print r1 after swap :" + s[1].toString());

    })

    it("should swapExactTokensForEth", async () => {
        // setting the bank
        let balancebeforeSwap = await web3.eth.getBalance(swapper);
        console.log ("balance avant " , balancebeforeSwap.toString());

        await apmContract.setBankAddress(bankContract.address);

        let dbitBalanceBeforeSwap = await dbitInstance.balanceOf(swapper);
        console.log("dbitBalanceBeforeSwap", dbitBalanceBeforeSwap.toString())
        let wethBalanceBeforeSwap = await wethContract.balanceOf(swapper);
        console.log("wethBalanceBeforeSwap", wethBalanceBeforeSwap.toString())
        let wethBalanceApmBefore = await wethContract.balanceOf(apmContract.address);
        console.log("wethBalanceApmBefore", wethBalanceApmBefore.toString())


        await bankContract.swapExactTokensForEth(
            web3.utils.toWei('0.1', 'ether'),
            web3.utils.toWei('0.015', 'ether'),
            [dbitInstance.address, wethContract.address],
            swapper,
            {from: swapper});

        let balanceAfterSwap = await web3.eth.getBalance(swapper);
        console.log ("balance après swap " , balanceAfterSwap.toString());

        let v1 = parseFloat(web3.utils.fromWei(balanceAfterSwap, "ether"));
        let v2 = parseFloat(web3.utils.fromWei(balancebeforeSwap, "ether"));
        let v3 = v2-v1;
        expect(v3).to.greaterThan(-0.0333333);
        console.log("balance eth diff", v3)



        let dbitBalanceAfterSwap = await dbitInstance.balanceOf(swapper);
        console.log("dbitBalanceAfterSwap", dbitBalanceAfterSwap.toString())
        let wethBalanceAfterSwap = await wethContract.balanceOf(swapper);
        console.log("wethBalanceAfterSwap", wethBalanceAfterSwap.toString())
        let wethBalanceApmAfter = await wethContract.balanceOf(apmContract.address);
        console.log("wethBalanceApmAfter", wethBalanceApmAfter.toString())


        let diffWeth = parseFloat(web3.utils.fromWei(wethBalanceAfterSwap, "ether")) - parseFloat(web3.utils.fromWei(wethBalanceBeforeSwap, "ether"));
        //expect(diffWeth.toString()).to.equal(web3.utils.toWei('0.033333333333333333', 'ether').toString()); //value found with xy=k formula

        let diffDbit = parseFloat(web3.utils.fromWei(dbitBalanceAfterSwap, "ether")) - parseFloat(web3.utils.fromWei(dbitBalanceBeforeSwap, "ether"));
        //expect(diffDbit.toString()).to.equal(web3.utils.toWei('0.09', 'ether').toString()); //value found with xy=k formula

        const reserveAfter = await apmContract.getReserves(usdcContract.address, dbitInstance.address);
        console.log("reserveAfter after swap : " + reserveAfter[0].toString(), "reserveAfter after swap :" + reserveAfter[1].toString());

    })


});
