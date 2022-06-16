const DAI = artifacts.require("DAI");
const DBIT = artifacts.require("DBIT");
const USDC = artifacts.require("USDC");
const USDT = artifacts.require("USDT");
const WETH = artifacts.require("WETH");
const FakeOracle = artifacts.require("FakeOracle");

const DebondData = artifacts.require("DebondData");
const Bank = artifacts.require("Bank");
const DebondBondTest = artifacts.require("DebondBondTest");
const APMTest = artifacts.require("APMTest");



//libs
const DebondMath = artifacts.require("DebondMath");

module.exports = async function (deployer, networks, accounts) {

  const DAIInstance = await DAI.deployed();
  const DBITInstance = await DBIT.deployed();
  const USDCInstance = await USDC.deployed();
  const USDTInstance = await USDT.deployed();
  const WETHInstance = await WETH.deployed();

  const governanceAddress = accounts[0];

  await deployer.deploy(DebondMath);
  await deployer.link(DebondMath, Bank);


  await deployer.deploy(APMTest, governanceAddress);
  await deployer.deploy(DebondData, DBITInstance.address, USDCInstance.address, USDTInstance.address, DAIInstance.address)
  await deployer.deploy(DebondBondTest, governanceAddress, DBITInstance.address, USDCInstance.address, USDTInstance.address, DAIInstance.address);

  const dataAddress = (await DebondData.deployed()).address
  const debondBond = await DebondBondTest.deployed()
  const apmInstance = await APMTest.deployed();

  await deployer.deploy(FakeOracle);
  const fakeOracleInstance = await FakeOracle.deployed();

  // const oracleAddress = networks === "development" ? fakeOracleInstance.address : "0x572AE4C774E466D77BC5A80DFF8A4a59A6cEe6A0";
  // const USDCAddress = networks === "development" ? USDCInstance.address : "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174";
  const oracleAddress = fakeOracleInstance.address
  const USDCAddress = USDCInstance.address
  const WETHAddress = WETHInstance.address
  await deployer.deploy(Bank, apmInstance.address, dataAddress, debondBond.address, DBITInstance.address, DBITInstance.address, oracleAddress, USDCAddress, WETHAddress);  //oracle and usdc for polygon

  const bankInstance = await Bank.deployed();
  await apmInstance.setBankAddress(bankInstance.address);
  const bondIssuerRole = await debondBond.ISSUER_ROLE();
  await debondBond.grantRole(bondIssuerRole, bankInstance.address);
  const DBITMinterRole = await DBITInstance.MINTER_ROLE();
  await DBITInstance.grantRole(DBITMinterRole, bankInstance.address);

  await apmInstance.setBankAddress(bankInstance.address);

};
