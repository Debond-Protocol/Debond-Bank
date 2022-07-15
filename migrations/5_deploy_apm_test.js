const APMTest = artifacts.require("APMTest");
const Bank = artifacts.require("Bank");

module.exports = async function (deployer, networks, accounts) {

  const governanceAddress = accounts[0]

  await deployer.deploy(APMTest, governanceAddress);
  const apmInstance = await APMTest.deployed()
  const bankInstance = await Bank.deployed()

  await apmInstance.setBankAddress(bankInstance.address);
};
