const DAI = artifacts.require("DAI");
const DBIT = artifacts.require("DBITTest");
const DGOV = artifacts.require("DGOVTest");
const USDT = artifacts.require("USDT");

const Bank = artifacts.require("Bank");
const BankData = artifacts.require("BankData");
const DebondBondTest = artifacts.require("DebondBondTest");
const APMTest = artifacts.require("APMTest");

module.exports = async function (deployer, networks, accounts) {

  const DAIInstance = await DAI.deployed();
  const DBITInstance = await DBIT.deployed();
  const DGOVInstance = await DGOV.deployed();
  const USDTInstance = await USDT.deployed();
  const apmInstance = await APMTest.deployed();
  const bankDataInstance = await BankData.deployed();
  const debondBondInstance = await DebondBondTest.deployed()
  const bankInstance = await Bank.deployed();



  await apmInstance.setBankAddress(bankInstance.address);
  await debondBondInstance.setBankAddress(bankInstance.address);
  await bankDataInstance.setBankAddress(bankInstance.address);
  await DBITInstance.setBankAddress(bankInstance.address);
  await DGOVInstance.setBankAddress(bankInstance.address);
  // await bankInstance.initializeApp(DAIInstance.address, USDTInstance.address);
};
