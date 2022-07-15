const USDC = artifacts.require("USDC");
const FakeOracle = artifacts.require("FakeOracle");
const Bank = artifacts.require("Bank");


const BankBondManager = artifacts.require("BankBondManager");



//libs
const DebondMath = artifacts.require("DebondMath");

module.exports = async function (deployer, networks, accounts) {

  const USDCInstance = await USDC.deployed();
  const fakeOracleInstance = await FakeOracle.deployed();
  const bankInstance = await Bank.deployed();


  const governanceAddress = accounts[0];

  await deployer.link(DebondMath, BankBondManager);


  await deployer.deploy(BankBondManager,
      governanceAddress,
      "0x0000000000000000000000000000000000000000",
      bankInstance.address,
      "0x0000000000000000000000000000000000000000",
      fakeOracleInstance.address,
      USDCInstance.address
  );
};
