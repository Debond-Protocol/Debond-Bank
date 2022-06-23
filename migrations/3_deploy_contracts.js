const DAI = artifacts.require("DAI");
const DBIT = artifacts.require("DBITTest");
const DGOV = artifacts.require("DGOVTest");
const USDC = artifacts.require("USDC");
const USDT = artifacts.require("USDT");
const WETH = artifacts.require("WETH");
const FakeOracle = artifacts.require("FakeOracle");

const Bank = artifacts.require("Bank");
const DebondBondTest = artifacts.require("DebondBondTest");
const APMTest = artifacts.require("APMTest");



//libs
const DebondMath = artifacts.require("DebondMath");

module.exports = async function (deployer, networks, accounts) {

  const DAIInstance = await DAI.deployed();
  const DBITInstance = await DBIT.deployed();
  const DGOVInstance = await DGOV.deployed();
  const USDCInstance = await USDC.deployed();
  const USDTInstance = await USDT.deployed();
  const WETHInstance = await WETH.deployed();

  const governanceAddress = accounts[0];

  await deployer.deploy(DebondMath);
  await deployer.link(DebondMath, Bank);

  await deployer.deploy(APMTest, governanceAddress);
  const apmInstance = await APMTest.deployed();

  await deployer.deploy(DebondBondTest, governanceAddress);
  const debondBondInstance = await DebondBondTest.deployed()

  // const oracleAddress = networks === "development" ? fakeOracleInstance.address : "0x572AE4C774E466D77BC5A80DFF8A4a59A6cEe6A0";
  // const USDCAddress = networks === "development" ? USDCInstance.address : "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174";
  await deployer.deploy(FakeOracle);
  const fakeOracleInstance = await FakeOracle.deployed();
  const oracleAddress = fakeOracleInstance.address
  const USDCAddress = USDCInstance.address
  const WETHAddress = WETHInstance.address

  let d = new Date();
  d.setHours(0,0,0,0);

  console.log(d.getTime());
  await deployer.deploy(Bank,
      governanceAddress,
      apmInstance.address,
      debondBondInstance.address,
      DBITInstance.address,
      DGOVInstance.address,
      oracleAddress,
      USDCAddress,
      WETHAddress,
      d.getTime()/10**3);  //oracle and usdc for polygon

  const bankInstance = await Bank.deployed();
  await apmInstance.setBankAddress(bankInstance.address);
  await debondBondInstance.setBankAddress(bankInstance.address);
  await DBITInstance.setBankAddress(bankInstance.address);
  await DGOVInstance.setBankAddress(bankInstance.address);
  await bankInstance.initializeApp(DAIInstance.address, USDTInstance.address);
};
