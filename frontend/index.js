import { ethers } from "./ethers-5.1.esm.min.js";
import { localAddress, abi } from "./constants.js";
const LOCAL_CHAIN_ID = 31337;
//const GOERLI_CHAIN_ID = 5;

let connectButton = document.getElementById("connectWallet");
let executeTxButton = document.getElementById("executeTx");
let revokeTxButton = document.getElementById("revokeTx");
let confirmTxButton = document.getElementById("confirmTx");
let proposeTxButton = document.getElementById("proposeTx");

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

// Proposed if Tx is a transfer, an appendium, a removal, ...
async function propose() {}

// Confirms a proposed transaction.
async function confirm() {}

// Revokes a previous confirmation done by an account
async function revoke() {}

// Executes a transaction in line if already fully confirmed.
async function execute() {}
