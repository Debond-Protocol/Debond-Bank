import {before} from "mocha";
import {
    DBITInstance,
    BankInstance, USDCInstance, APMInstance
} from "../types/truffle-contracts";

const APM = artifacts.require("APM");
const Bank = artifacts.require("Bank");
const DBIT = artifacts.require("DBIT");
const USDC = artifacts.require("USDC");


contract('APM', async (accounts: string[]) => {
    const swapper = accounts[1];
    let dbitInstance: DBITInstance;
    let bankContract: BankInstance;
    let usdcContract: USDCInstance;
    let apmContract : APMInstance;


    it('Initialisation', async () => {
        bankContract = await Bank.deployed();
        usdcContract = await USDC.deployed();
        dbitInstance = await DBIT.deployed();
        apmContract = await APM.deployed();

        //await debondBondInstance.setApprovalFor(); No need approval for now

        // 1 get some tokens
        await usdcContract.mint(swapper, web3.utils.toWei('100', 'ether'));
        await usdcContract.mint(apmContract.address, web3.utils.toWei('100', 'ether'));
        await usdcContract.approve(bankContract.address, web3.utils.toWei('100', 'ether'), {from: swapper})
        //pareil avec dbit

        const MINTER_ROLE = await dbitInstance.MINTER_ROLE();
        await dbitInstance.grantRole(MINTER_ROLE, accounts[0]);
        await dbitInstance.mint(apmContract.address, web3.utils.toWei('200', 'ether'));

        const a = await apmContract.getReserves(usdcContract.address, dbitInstance.address);
        console.log("here we print r0 before addLiqq : " +  a[0].toString(),"here we print r1 before addliq :" + a[1].toString());
        //
        await apmContract.updateWhenAddLiquidity(
            web3.utils.toWei('200', 'ether'),
            web3.utils.toWei('100', 'ether'),
            dbitInstance.address,
            usdcContract.address
        );

        //Pour plus tard
        const s = await apmContract.getReserves(usdcContract.address, dbitInstance.address);
        console.log("here we print r0 before addLiqq : " +  s[0].toString(),"here we print r1 before addliq :" + s[1].toString());

    });

    it("should swap", async () => {
        await bankContract.swapExactTokensForTokens(
            web3.utils.toWei('10', 'ether'),
            web3.utils.toWei('15', 'ether'),
            [usdcContract.address, dbitInstance.address],
            {from: swapper});


        const dbitBalance = await dbitInstance.balanceOf(swapper);
        expect(dbitBalance.toString()).to.equal( web3.utils.toWei('18.181818181818181818', 'ether').toString() ); //value found with xy=k formula

    })
})
