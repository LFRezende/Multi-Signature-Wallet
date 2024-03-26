// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSigWallet {
    mapping(address => bool) public doubleOwner;
    // Tx Definition:
    struct Tx {
        address to;
        uint256 value;
        address owner;
        bool confirmed;
        uint256 confirmations;
    }

    address payable[] public owners; // Owners of the wallet

    constructor(
        address payable[] memory _owners,
        uint256 _initialTxChecks
    ) payable {
        // owners = _owners; - It would be ideal for gas sake, yet to ensure no invalid owners:

        require(
            _owners.length <= _initialTxChecks,
            "There are more txConfirmations required than signers!"
        );
        require(
            _owners.length > 0,
            "No address list has been passed to the constructor"
        );

        for (uint256 j = 0; j < _owners.length; j++) {
            address payable adm = _owners[j];
            require(adm != address(0), "Null address is invalid.");
            require(!doubleOwner[adm], "There is a double address input.");
            doubleOwner[adm] = true; // Registration of the owner

            owners.push(adm);
        }
    }

    Tx[] public txHistory;

    function proposeTx() public {}
}
