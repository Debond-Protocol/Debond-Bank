const DAI = artifacts.require("DAI");
const USDC = artifacts.require("USDC");
const USDT = artifacts.require("USDT");
const WETH = artifacts.require("WETH");
const FakeOracle = artifacts.require("FakeOracle");
const DebondMath = artifacts.require("DebondMath");


module.exports = async function (deployer) {
  await deployer.deploy(DAI);
  await deployer.deploy(USDC);
  await deployer.deploy(USDT);
  await deployer.deploy(WETH);
  await deployer.deploy(FakeOracle);
  await deployer.deploy(DebondMath);


};
