const USDC = artifacts.require("USDC");
const WETH = artifacts.require("WETH");
const FakeOracle = artifacts.require("FakeOracle");

const Bank = artifacts.require("Bank");



//libs
const DebondMath = artifacts.require("DebondMath");

module.exports = async function (deployer, networks, accounts) {

  const USDCInstance = await USDC.deployed();
  const WETHInstance = await WETH.deployed();
  const fakeOracleInstance = await FakeOracle.deployed();

  const governanceAddress = accounts[0];

  await deployer.link(DebondMath, Bank);


  // const USDCAddress = networks === "development" ? USDCInstance.address : "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174";
  const oracleAddress = fakeOracleInstance.address
  const USDCAddress = USDCInstance.address
  const WETHAddress = WETHInstance.address

  await deployer.deploy(Bank,
      governanceAddress,
      "0x0000000000000000000000000000000000000000",
      "0x0000000000000000000000000000000000000000",
      "0x0000000000000000000000000000000000000000",
      "0x0000000000000000000000000000000000000000",
      "0x0000000000000000000000000000000000000000",
      USDCAddress,
      WETHAddress,
      oracleAddress);

  // const bankInstance = await Bank.deployed();
  // await apmInstance.setBankAddress(bankInstance.address);
  // await debondBondInstance.setBankAddress(bankInstance.address);
  // await bankDataInstance.setBankAddress(bankInstance.address);
  // await DBITInstance.setBankAddress(bankInstance.address);
  // await DGOVInstance.setBankAddress(bankInstance.address);
};
