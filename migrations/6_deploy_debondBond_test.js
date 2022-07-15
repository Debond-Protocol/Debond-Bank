const DebondBondTest = artifacts.require("DebondBondTest");
const BankBondManager = artifacts.require("BankBondManager");
module.exports = async function (deployer, networks, accounts) {

  const governanceAddress = accounts[0]

  await deployer.deploy(DebondBondTest, governanceAddress);
  const debondBondInstance = await DebondBondTest.deployed();
  const bankBondManagerInstance = await BankBondManager.deployed();

  await debondBondInstance.setBankAddress(bankBondManagerInstance.address);
}