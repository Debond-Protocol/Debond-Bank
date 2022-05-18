const DAI = artifacts.require("DAI");
const DBIT = artifacts.require("DBIT");
const USDC = artifacts.require("USDC");
const USDT = artifacts.require("USDT");

const DebondData = artifacts.require("DebondData");
const APM = artifacts.require("APM");
const Bank = artifacts.require("Bank");


//libs
const DebondMath = artifacts.require("DebondMath");

module.exports = async function (deployer, networks, accounts) {

  const DAIInstance = await DAI.deployed();
  const DBITInstance = await DBIT.deployed();
  const USDCInstance = await USDC.deployed();
  const USDTInstance = await USDT.deployed();

  await deployer.deploy(DebondMath);
  await deployer.link(DebondMath, Bank);


  await deployer.deploy(DebondData, DBITInstance.address, USDCInstance.address, USDTInstance.address, DAIInstance.address)
  await deployer.deploy(APM);

  const dataAddress = (await DebondData.deployed()).address
  const apmAddress = (await APM.deployed()).address

  await deployer.deploy(Bank, apmAddress, dataAddress, accounts[0], DBITInstance.address, DBITInstance.address);

  const bankInstance = await Bank.deployed();
  const DBITMinterRole = await DBITInstance.MINTER_ROLE();
  await DBITInstance.grantRole(DBITMinterRole, bankInstance.address);

};
