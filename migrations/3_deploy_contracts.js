const DAI = artifacts.require("DAI");
const DBIT = artifacts.require("DBIT");
const USDC = artifacts.require("USDC");
const USDT = artifacts.require("USDT");

const DebondData = artifacts.require("DebondData");
const APM = artifacts.require("APM");
const Bank = artifacts.require("Bank");
const DebondBondTest = artifacts.require("DebondBondTest");


//libs
const DebondMath = artifacts.require("DebondMath");

module.exports = async function (deployer, networks, accounts) {

  const DAIInstance = await DAI.deployed();
  const DBITInstance = await DBIT.deployed();
  const USDCInstance = await USDC.deployed();
  const USDTInstance = await USDT.deployed();

  const governanceAddress = accounts[0];
  const bankAddress = accounts[1];

  await deployer.deploy(DebondMath);
  await deployer.link(DebondMath, Bank);


  await deployer.deploy(DebondData, DBITInstance.address, USDCInstance.address, USDTInstance.address, DAIInstance.address)
  await deployer.deploy(APM, governanceAddress);
  await deployer.deploy(DebondBondTest, governanceAddress, DBITInstance.address, USDCInstance.address, USDTInstance.address, DAIInstance.address);

  const dataAddress = (await DebondData.deployed()).address
  const apmInstance = await APM.deployed()
  const debondBond = await DebondBondTest.deployed()

  await deployer.deploy(Bank, apmInstance.address, dataAddress, debondBond.address, DBITInstance.address, DBITInstance.address);

  const bankInstance = await Bank.deployed();
  await apmInstance.setBankAddress(bankInstance.address);
  const bondIssuerRole = await debondBond.ISSUER_ROLE();
  await debondBond.grantRole(bondIssuerRole, bankInstance.address);
  const DBITMinterRole = await DBITInstance.MINTER_ROLE();
  await DBITInstance.grantRole(DBITMinterRole, bankInstance.address);

  await apmInstance.setBankAddress(bankAddress);

};
