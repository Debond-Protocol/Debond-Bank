const DBIT = artifacts.require("DBITTest");
const DGOV = artifacts.require("DGOVTest");
const Bank = artifacts.require("Bank");

module.exports = async function (deployer, network, accounts) {
  const [governanceAddress] = accounts;
  const bankInstance = await Bank.deployed();

  await deployer.deploy(DBIT, governanceAddress, bankInstance.address, "0x0000000000000000000000000000000000000000", "0x0000000000000000000000000000000000000000");
  await deployer.deploy(DGOV, governanceAddress, bankInstance.address, "0x0000000000000000000000000000000000000000", "0x0000000000000000000000000000000000000000");
};
