import {
     BankDataInstance
} from "../types/truffle-contracts";


const BankData = artifacts.require("BankData");



contract('BankData', async (accounts: string[]) => {


    let bankDataInstance: BankDataInstance

    before('Initialisation', async () => {

        bankDataInstance = await BankData.deployed();
    })

    it('should change the bank address (only governance)', async () => {
        await bankDataInstance.setBankAddress(accounts[1]);
        await bankDataInstance
    })


});
