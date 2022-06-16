const DAI = artifacts.require("DAI");
const DBIT = artifacts.require("DBIT");
const USDC = artifacts.require("USDC");
const USDT = artifacts.require("USDT");
const WETH = artifacts.require("WETH");

module.exports = function (deployer) {
  deployer.deploy(DAI);
  deployer.deploy(DBIT);
  deployer.deploy(USDC);
  deployer.deploy(USDT);
  deployer.deploy(WETH);
};
