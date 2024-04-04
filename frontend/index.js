import { ethers } from "./ethers-5.1.esm.min.js";
import { localAddress, goerliAddress, abi } from "./constants.js";
const LOCAL_CHAIN_ID = 31337;
const GOERLI_CHAIN_ID = 5;

let connectButton = document.getElementById("connectWallet");
let factText = document.getElementById("checkText");
let factButton = document.getElementById("factButton");
let responseDiv = document.getElementById("response");

connectButton.onclick = connect;
factButton.onclick = isFakeCheck;

async function connect() {
  if (typeof window.ethereum != "undefined") {
    console.log("There is an EVM-Based Wallet.");
    await window.ethereum.request({ method: "eth_requestAccounts" });
    if (window.ethereum.chainId == GOERLI_CHAIN_ID)
      connectButton.innerHTML = "Connected - Goerli";
    else if (window.ethereum.chainId == LOCAL_CHAIN_ID)
      connectButton.innerHTML = "Connected - Localhost";
    else {
      connectButton.innerHTML = "Network not supported";
    }
  } else {
    noMM.innerHTML = "Install Metamask to proceed.";
    console.log("No EVM-Based Wallet.");
  }
}

async function isFakeCheck() {
  const text = factText.value;
  if (typeof window.ethereum != "undefined") {
    // Entered the function
    console.log("It's ALIVE!!!");
    // Grabbing provider and signer
    const ethProvider = new ethers.providers.Web3Provider(window.ethereum);
    const signature = ethProvider.getSigner(); // Sign the Transaction

    // Making a setup contract

    // Making a variable for contractAddress.
    let contractAddress = "";
    if (window.ethereum.chainId == GOERLI_CHAIN_ID) {
      connectButton.innerHTML = "Connected - Goerli";
      contractAddress = goerliAddress;
    } else if (window.ethereum.chainId == LOCAL_CHAIN_ID) {
      contractAddress = localAddress;
      connectButton.innerHTML = "Connected - Localhost";
    } else {
      connectButton.innerHTML = "Network not supported.";
      return;
    }

    let contract = new ethers.Contract(contractAddress, abi, signature);
    // Now, just supporting Goerli Testnet
    try {
      console.log("Trying to catch it");
      const check = await contract.isFake(text);
      console.log(`Is it true? Answer: ${check}`);
      console.log("Done!");
      if (check == false) {
        responseDiv.textContent =
          "⚠️ No sources emitted this material - Possibly FAKE! ⚠️";
      } else if (check == true) {
        responseDiv.textContent = "✅ The info was indeed published! ✅ ";
      }
      console.log(`Is it true? Answer: ${check}`);
    } catch (isFakeCheckError) {
      console.log(isFakeCheckError);
      return;
    }
  } else {
    connectButton.innerHTML = "No Wallet Available";
  }
}

function listenForTransactionMine(txResponse, provider) {
  console.log(`Mining ${txResponse.hash} ...`);
  return new Promise((resolve, reject) => {
    provider.once(txResponse.hash, (txReceipt) => {
      console.log(`Completed with ${txReceipt.confirmations} confirmations.`);
      resolve();
    });
  });
}
//
// async function addTextJs() {} -> Hidden addition via Proper Interface for Publishers.
// async function addSourceJs() {} -> Hidden addition via Remix -> Only the ADM may do so