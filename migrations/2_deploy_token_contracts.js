const DAI = artifacts.require("DAI");
const DBIT = artifacts.require("DBITTest");
const DGOV = artifacts.require("DGOVTest");
const USDC = artifacts.require("USDC");
const USDT = artifacts.require("USDT");
const WETH = artifacts.require("WETH");

module.exports = function (deployer, network, accounts) {
  const [governanceAddress, bankAddress, airdropAddress, exchangeAddress] = accounts;
  deployer.deploy(DAI);
  deployer.deploy(USDC);
  deployer.deploy(USDT);
  deployer.deploy(WETH);

  deployer.deploy(DBIT, governanceAddress, bankAddress, airdropAddress, exchangeAddress);
  deployer.deploy(DGOV, governanceAddress, bankAddress, airdropAddress, exchangeAddress);
};
