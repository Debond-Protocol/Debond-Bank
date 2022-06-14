const DAI = artifacts.require("DAI");
const DBIT = artifacts.require("DBIT");
const DGOV = artifacts.require("DGOV");
const USDC = artifacts.require("USDC");
const USDT = artifacts.require("USDT");

module.exports = function (deployer) {
  deployer.deploy(DAI);
  deployer.deploy(DBIT);
  deployer.deploy(DGOV);
  deployer.deploy(USDC);
  deployer.deploy(USDT);
};
