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

    it('should add a new classId for a token Address (only Bank)', async () => {
        await bankDataInstance.pushClassIdPerTokenAddress(ERC20Address, 3, {from: bankAddress});
        await bankDataInstance.pushClassIdPerTokenAddress(ERC20Address, 4, {from: bankAddress});
        await bankDataInstance.pushClassIdPerTokenAddress(ERC20Address, 5, {from: bankAddress});
        const classIds = await bankDataInstance.getClassIdsFromTokenAddress(ERC20Address);
        assert.equal(classIds.length, 3);
    })

    it('should edit the benchmark interest rate (only Bank)', async () => {
        await bankDataInstance.setBenchmarkInterest(web3.utils.toWei('1'), {from: bankAddress});
        const benchmarkInterest = parseInt(web3.utils.fromWei((await bankDataInstance.getBenchmarkInterest()).toString()));
        assert.equal(benchmarkInterest, 1);
    })
});
