require("ts-node").register({files: true});
const HDWalletProvider = require("@truffle/hdwallet-provider");
require('dotenv').config();
const Web3 = require("web3");
const web3 = new Web3();

module.exports = {
  plugins: ['truffle-plugin-verify'],
  api_keys: {
    etherscan: "YWW54NEHSEUXR7E4NP5JFWP176QN9N4NN5",
  },
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*"
    },
    rinkeby: {
      provider: function() {
        return new HDWalletProvider("a6c283e0090a5b51410f2239f45ad1c33bd503456001428933ab4819ce555fc4", `https://rinkeby.infura.io/v3/bc900f3c5d3f46718632cf0aa0b03f1c`);
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
    // reporter: 'eth-gas-reporter',
  },
  compilers: {
    solc: {
      version: "0.8.13",
      settings: { // See the solidity docs for advice about optimization and evmVersion
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    }
  }
};
