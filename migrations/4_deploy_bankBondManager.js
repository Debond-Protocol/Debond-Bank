const USDC = artifacts.require("USDC");
const Bank = artifacts.require("Bank");


const BankBondManager = artifacts.require("BankBondManager");



//libs
const DebondMath = artifacts.require("DebondMath");

module.exports = async function (deployer, networks, accounts) {
  const bankInstance = await Bank.deployed();
  const USDCInstance = await USDC.deployed();

  const executableAddress = accounts[0];

  await deployer.link(DebondMath, BankBondManager);
  await deployer.deploy(BankBondManager,
      executableAddress,
      bankInstance.address,
      USDCInstance.address
  );
};
