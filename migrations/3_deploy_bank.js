const USDC = artifacts.require("USDC");
const WETH = artifacts.require("WETH");
const FakeOracle = artifacts.require("FakeOracle");

const Bank = artifacts.require("Bank");



//libs
const DebondMath = artifacts.require("DebondMath");

module.exports = async function (deployer, networks, accounts) {

  const executableAddress = accounts[0];

  await deployer.link(DebondMath, Bank);

  const USDCInstance = await USDC.deployed();
  const WETHInstance = await WETH.deployed();
  // const USDCAddress = networks === "development" ? USDCInstance.address : "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174";
  const USDCAddress = USDCInstance.address
  const WETHAddress = WETHInstance.address

  await deployer.deploy(Bank,
      executableAddress,
      USDCAddress,
      WETHAddress
  );
};
