const BankData = artifacts.require("BankData");
const BankBondManager = artifacts.require("BankBondManager");


module.exports = async function (deployer, networks, accounts) {

  const governanceAddress = accounts[0];

  const bankBondManaerInstance = await BankBondManager.deployed();
  let d = new Date();
  d.setHours(0,0,0,0);
  await deployer.deploy(BankData, governanceAddress, bankBondManaerInstance.address, d.getTime()/10**3);

};
