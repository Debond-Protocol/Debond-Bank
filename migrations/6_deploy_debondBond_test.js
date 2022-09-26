const DebondBondTest = artifacts.require("DebondBondTest");
const BankBondManager = artifacts.require("BankBondManager");
const Bank = artifacts.require("Bank");
module.exports = async function (deployer, networks, accounts) {

  const governanceAddress = accounts[0]

  await deployer.deploy(DebondBondTest, governanceAddress);
  const debondBondInstance = await DebondBondTest.deployed();
  const bankBondManagerInstance = await BankBondManager.deployed();
  const bankInstance = await Bank.deployed();

  await debondBondInstance.updateBondManagerAddress(bankBondManagerInstance.address);
  await debondBondInstance.updateBankAddress(bankInstance.address);
}