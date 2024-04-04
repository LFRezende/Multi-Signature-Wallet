import { ethers } from "./ethers-5.1.esm.min.js";
import { localAddress, abi } from "./constants.js";
const LOCAL_CHAIN_ID = 31337;
//const GOERLI_CHAIN_ID = 5;

let connectButton = document.getElementById("connectWallet");

connectButton.onclick = connect;
factButton.onclick = isFakeCheck;

async function connect() {
  if (typeof window.ethereum != "undefined") {
    console.log("There is an EVM-Based Wallet.");
    await window.ethereum.request({ method: "eth_requestAccounts" });
    if (window.ethereum.chainId == LOCAL_CHAIN_ID)
      connectButton.innerHTML = "Connected - Localhost";
    else {
      connectButton.innerHTML = "Network not supported";
    }
  } else {
    noMM.innerHTML = "Install Metamask to proceed.";
    console.log("No EVM-Based Wallet.");
  }
}
