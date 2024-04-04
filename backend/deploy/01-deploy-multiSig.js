// First of all, require hardhat and use the packages
const { network, ethers, getNamedAccounts, deployments } = require("hardhat");

// Fluxogram within deploy script:
// 1. We fetch some stuff from hardhat package, which is
// a mixture of what we type in the hardhat-config but also what is
// already built-in in hardhat.

// 2. We usually fetch getNamedAccounts and deployments and network, and ethers
// since these packages and/or functions are vital for development.

// 3. Then, we begin development of the contract.

module.exports = async ({ getNamedAccounts, deployments }) => {
  // Usually what we need for development.
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = network.config.chainId;

  const multiSig = await deploy("MultiSignatureWallet", {
    from: deployer,
    args: args,
    log: true,
    waitConfirmations: network.config.blockConfirmations || 1,
  });
  console.log("Contract has been deployed.");
};

module.exports.tags = ["all", "multiSig"];
