import {
    BankStorageInstance
} from "../types/truffle-contracts";


const BankData = artifacts.require("BankStorage");



contract('BankStorage', async (accounts: string[]) => {
    const [governanceAddress, bankAddress, ERC20Address] = accounts;
    let bankStorageInstance: BankStorageInstance

    before('Initialisation', async () => {

        bankStorageInstance = await BankData.deployed();
    })

    it('should change the bank address (only governance)', async () => {
        await bankStorageInstance.updateBankAddress(bankAddress);
        await bankStorageInstance
    })

    it('should update can purchase classes (only Bank)', async () => {
        await bankStorageInstance.updateCanPurchase(0, 1, true, {from: bankAddress});
        assert.isTrue(await bankStorageInstance.canPurchase(0, 1));
    })

    it('should add a new classId for a token Address (only Bank)', async () => {
        await bankStorageInstance.pushClassIdPerTokenAddress(ERC20Address, 3, {from: bankAddress});
        await bankStorageInstance.pushClassIdPerTokenAddress(ERC20Address, 4, {from: bankAddress});
        await bankStorageInstance.pushClassIdPerTokenAddress(ERC20Address, 5, {from: bankAddress});
        const classIds = await bankStorageInstance.getClassIdsFromTokenAddress(ERC20Address);
        assert.equal(classIds.length, 3);
    })

    it('should edit the benchmark interest rate (only Bank)', async () => {
        await bankStorageInstance.updateBenchmarkInterest(web3.utils.toWei('1'), {from: bankAddress});
        const benchmarkInterest = parseInt(web3.utils.fromWei((await bankStorageInstance.getBenchmarkInterest()).toString()));
        assert.equal(benchmarkInterest, 1);
    })
});
