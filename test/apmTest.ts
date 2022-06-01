import {
    APMInstance,
    DBITInstance,
    USDCInstance,
    USDTInstance
} from "../types/truffle-contracts";

const USDC = artifacts.require("USDC");
const USDT = artifacts.require("USDT");
const DBIT = artifacts.require("DBIT");
const APM = artifacts.require("APM");

contract('APM', async (accounts: string[]) => {

    let usdcContract: USDCInstance
    let usdtContract: USDTInstance
    let dbitContract: DBITInstance
    let apmContract : APMInstance
    const bankAddress = accounts[1];

    it('update add liquidity', async () => {
        usdcContract = await USDC.deployed();
        usdtContract = await USDT.deployed();
        dbitContract = await DBIT.deployed();
        apmContract = (await APM.deployed());
        
        await usdcContract.mint(accounts[0], 100000);
        

        const s = await apmContract.getReserves(usdcContract.address, dbitContract.address);
        console.log("here we print r0 before addLiqq : " +  s[0].toString(),"here we print r1 before addliq :" + s[1].toString());

        await apmContract.updateWhenAddLiquidity(100, 10000, usdcContract.address, dbitContract.address, {from: bankAddress});
        const r = await apmContract.getReserves(usdcContract.address, dbitContract.address);
        console.log("here we print r0 after addliq : " +  r[0].toString(),"here we print r1 after addliq :" + r[1].toString());

        const usdcBalance = r[0].toString();
        const dbitBalance = r[1].toString();
        expect(usdcBalance).to.equal('100');
        expect(dbitBalance).to.equal('10000');

        
    })
    it('update remove', async () => {
        usdcContract = await USDC.deployed();
        dbitContract = await DBIT.deployed();
        apmContract = (await APM.deployed());

        await usdcContract.mint(accounts[0], 100000);


        const s = await apmContract.getReserves(usdcContract.address, dbitContract.address);
        console.log("here we print r0 before remove : " +  s[0].toString(),"here we print r1 before remove : " + s[1].toString());

        await apmContract.updateWhenRemoveLiquidity(5000, dbitContract.address, {from: bankAddress});

        const r = await apmContract.getReserves(usdcContract.address, dbitContract.address);
        console.log("here we print r0 after remove : " +  r[0].toString(),"here we print r1 after remove : " + r[1].toString());

        const dbitBalance = r[1].toString();
        expect(dbitBalance).to.equal('5000');

        const usdcBalance = r[0].toString();
        expect(usdcBalance).to.equal('100');


    })
    // it('update swap', async () => {
    //     usdcContract = await USDC.deployed();
    //     bankContract = await Bank.deployed();
    //     bondContract = await DebondBond.deployed();
    //     dbitContract = await DBIT.deployed();
    //     apmContract = (await APM.deployed());
    //
    //     await usdcContract.mint(accounts[0], 100000);
    //
    //
    //     const s = await apmContract.getReserves(usdcContract.address, dbitContract.address);
    //     console.log("here we print r0 before swap:" +  s[0].toNumber(),"here we print r1 before swap :" + s[1].toNumber());
    //
    //     await apmContract.updateWhenSwap(15, 10, usdcContract.address, dbitContract.address);
    //
    //
    //     const r = await apmContract.getReserves(usdcContract.address, dbitContract.address);
    //     console.log("here we print r0 after swap:" +  r[0].toNumber(),"here we print r1 after swap :" + r[1].toNumber());
    //
    //     const usdcBalance = r[0].toNumber().toString();
    //     const dbitBalance = r[1].toNumber().toString();
    //     expect(usdcBalance).to.equal('115');
    //     expect(dbitBalance).to.equal('4990');
    // })

    it('update add liquidity', async () => {

        await usdtContract.mint(accounts[0], 100000);


        const s = await apmContract.getReserves(usdtContract.address, dbitContract.address);
        console.log("here we print r0 before addLiqq : " +  s[0].toString(),"here we print r1 before addliq :" + s[1].toString());

        await apmContract.updateWhenAddLiquidity(100, 10000, usdtContract.address, dbitContract.address, {from: bankAddress});

        const r = await apmContract.getReserves(usdtContract.address, dbitContract.address);
        console.log("here we print r0 after addliq : " +  r[0].toString(),"here we print r1 after addliq :" + r[1].toString());

        const usdtBalance = r[0].toString();
        const dbitBalance = r[1].toString();
        expect(usdtBalance).to.equal('100');
        expect(dbitBalance).to.equal('10000');
    })
});
