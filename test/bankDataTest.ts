import {
     BankDataInstance
} from "../types/truffle-contracts";


const BankData = artifacts.require("BankData");



contract('BankData', async (accounts: string[]) => {
    const [governanceAddress, bankAddress, ERC20Address] = accounts;
    let bankDataInstance: BankDataInstance

    before('Initialisation', async () => {

        bankDataInstance = await BankData.deployed();
    })

    it('should change the bank address (only governance)', async () => {
        await bankDataInstance.setBankAddress(bankAddress);
        await bankDataInstance
    })

    it('should update can purchase classes (only Bank)', async () => {
        await bankDataInstance.updateCanPurchase(0, 1, true, {from: bankAddress});
        assert.isTrue(await bankDataInstance.canPurchase(0, 1));
    })

    it('should set Token Interest Rate Supply (only Bank)', async () => {
        await bankDataInstance.setTokenInterestRateSupply(ERC20Address, 0, web3.utils.toWei('300'), {from: bankAddress});
        await bankDataInstance.setTokenInterestRateSupply(ERC20Address, 1, web3.utils.toWei('600'), {from: bankAddress});
        const tokenFixRateSupply = (await bankDataInstance.getTokenInterestRateSupply(ERC20Address, 0)).toString();
        const tokenFloatRateSupply = (await bankDataInstance.getTokenInterestRateSupply(ERC20Address, 1)).toString();
        assert.equal(parseInt(web3.utils.fromWei(tokenFixRateSupply)), 300);
        assert.equal(parseInt(web3.utils.fromWei(tokenFloatRateSupply)), 600);
    })

    it('should set Token Supply at Nonce (only Bank)', async () => {
        await bankDataInstance.setTokenTotalSupplyAtNonce(ERC20Address, 20, web3.utils.toWei('10000'), {from: bankAddress});
        const supplyAtNonce = parseInt(web3.utils.fromWei((await bankDataInstance.getTokenTotalSupplyAtNonce(ERC20Address, 20)).toString()));
        assert.equal(supplyAtNonce, 10000);
    })

    it('should add a new classId for a token Address (only Bank)', async () => {
        await bankDataInstance.pushClassIdPerTokenAddress(ERC20Address, 3, {from: bankAddress});
        await bankDataInstance.pushClassIdPerTokenAddress(ERC20Address, 4, {from: bankAddress});
        await bankDataInstance.pushClassIdPerTokenAddress(ERC20Address, 5, {from: bankAddress});
        const classIds = await bankDataInstance.getClassIdsFromTokenAddress(ERC20Address);
        assert.equal(classIds.length, 3);
    })

    it('should add a new classId (only Bank)', async () => {
        await bankDataInstance.addNewClassId( 3, {from: bankAddress});
        await bankDataInstance.addNewClassId(4, {from: bankAddress});
        await bankDataInstance.addNewClassId(5, {from: bankAddress});
        const classIds = await bankDataInstance.getClasses();
        assert.equal(classIds.length, 15);
    })

    it('should edit the benchmark interest rate (only Bank)', async () => {
        await bankDataInstance.setBenchmarkInterest(web3.utils.toWei('1'), {from: bankAddress});
        const benchmarkInterest = parseInt(web3.utils.fromWei((await bankDataInstance.getBenchmarkInterest()).toString()));
        assert.equal(benchmarkInterest, 1);
    })
});
