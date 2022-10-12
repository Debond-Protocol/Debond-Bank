const DAI = artifacts.require("DAI");
const DBIT = artifacts.require("DBITTest");
const DGOV = artifacts.require("DGOVTest");
const USDT = artifacts.require("USDT");
const WETH = artifacts.require("WETH");
const FakeOracle = artifacts.require("FakeOracle");
const Bank = artifacts.require("Bank");
const BankBondManager = artifacts.require("BankBondManager");
const BankStorage = artifacts.require("BankStorage");
const DebondBondTest = artifacts.require("DebondBondTest");
const APMTest = artifacts.require("APMTest");

module.exports = async function (deployer) {

  const DAIInstance = await DAI.deployed();
  const DBITInstance = await DBIT.deployed();
  const DGOVInstance = await DGOV.deployed();
  const USDTInstance = await USDT.deployed();
  const WETHInstance = await WETH.deployed();
  const apmInstance = await APMTest.deployed();
  const bankDataStorage = await BankStorage.deployed();
  const debondBondInstance = await DebondBondTest.deployed()
  const bankInstance = await Bank.deployed();
  const bankBondManagerInstance = await BankBondManager.deployed();
  const oracleInstance = await FakeOracle.deployed();

  await bankBondManagerInstance.initDatas(
      DBITInstance.address,
      USDTInstance.address,
      DAIInstance.address,
      DGOVInstance.address,
      WETHInstance.address,
      debondBondInstance.address,
      bankDataStorage.address,
      oracleInstance.address
  );

  await bankInstance.initDatas(
      DBITInstance.address,
      DGOVInstance.address,
      apmInstance.address,
      bankBondManagerInstance.address,
      bankDataStorage.address,
      oracleInstance.address,
      debondBondInstance.address
  );
};
