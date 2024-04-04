const { network } = require("hardhat");

const networkSetup = {
  5: {
    name: "goerli",
    addressOfMultiSig: "", // This here must be the address we grab in order for the application to run.
  },
  31337: {
    name: "hardhat",
    addressOfMultiSig: "", // Same here for the hardhat local network.
  },
};

const devChains = ["hardhat, localhost"];

module.exports = {
  networkSetup,
  devChains,
};
