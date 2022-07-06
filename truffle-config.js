require("ts-node").register({files: true});
const HDWalletProvider = require("@truffle/hdwallet-provider");
require('dotenv').config();
const Web3 = require("web3");
const web3 = new Web3();

module.exports = {
  plugins: ['truffle-plugin-verify', "truffle-contract-size"],
  api_keys: {
    etherscan: process.env.ETHERSCAN_API_KEY,
  },
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*"
    },
    rinkeby: {
      provider: function() {
        return new HDWalletProvider(process.env.TESTNET_PRIVATE_KEY, `https://rinkeby.infura.io/v3/${process.env.INFURA_ACCESS_TOKEN}`);
      },
      network_id: 4,
      // gas: 30000000, //from ganache-cli output
      // gasPrice: web3.utils.toWei('1', 'gwei')
    },
    ropsten: {
      provider: function() {
        return new HDWalletProvider(process.env.TESTNET_PRIVATE_KEY, `https://ropsten.infura.io/v3/${process.env.INFURA_ACCESS_TOKEN}`);
      },
      network_id: 3,
      // gas: 30000000, //from ganache-cli output
      gasPrice: web3.utils.toWei('1', 'gwei')
    }
  },
  mocha: {
    reporter: 'eth-gas-reporter',
  },
  compilers: {
    solc: {
      version: "0.8.13",
      settings: { // See the solidity docs for advice about optimization and evmVersion
        optimizer: {
          enabled: true,
          runs: 1000
        }
      }
    }
  }
};
