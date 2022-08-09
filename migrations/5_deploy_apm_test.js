const APMTest = artifacts.require("APMTest");
const Bank = artifacts.require("Bank");

module.exports = async function (deployer, networks, accounts) {

  const governanceAddress = accounts[0]
  const bankInstance = await Bank.deployed()
  await deployer.deploy(APMTest, governanceAddress, bankInstance.address);
};
