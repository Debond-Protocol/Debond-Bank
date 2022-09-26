const BankStorage = artifacts.require("BankStorage");
const BankBondManager = artifacts.require("BankBondManager");


module.exports = async function (deployer, networks, accounts) {

  const governanceAddress = accounts[0];

  const bankBondManaerInstance = await BankBondManager.deployed();
  let d = new Date();
  d.setDate(d.getDate() - 1);
  d.setHours(0,0,0,0);
  await deployer.deploy(BankStorage, governanceAddress, bankBondManaerInstance.address, d.getTime()/10**3);

};
