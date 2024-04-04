require("@nomicfoundation/hardhat-toolbox");
require("hardhat-deploy");
require("dotenv").config();
/** @type import('hardhat/config').HardhatUserConfig */

// Needs:
// 1 - url goerli on env and RUNNING in alchemy
// 2 - private key in env

// Fluxogram of Project:
// Contract --> Hardhat
// Hardhat: {
// 1. import packages: hardhat deploy, hardhat deploy npm, dotenv...
// 2. make deploy folder with deploy files
// 3. hardhat config stuff and env to predetermine.
//}
module.exports = {
  solidity: "0.8.24",
  defaultNetwork: "hardhat",
  networks: {
    goerli: {
      url: process.env.GOERLI_RPC_URL,
      accounts: [process.env.PRIVATE_KEY], // yeah, put the stupid brackets...
      chainId: 5,
      blockConfirmations: 6,
    },
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};
