// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSigWallet {
    // Mappings:

    mapping(address => bool) public doubleOwner;
    mapping(address => mapping(uint256 => bool)) public ownerA_confirmed_TxB;
    mapping(address => bool) public isOwner;
    mapping(uint256 => bool) public txExecuted;
    mapping(uint256 => uint256) public numConfirmations;
    mapping(address => uint256) public ownerPosition;
    // Tx Definition:
    struct Tx {
        address to; // To whom will the money be transfered
        uint256 value; // The amount it will be transfered
        address owner; // Who first proposed it
        bool executed; // If the Tx was already executed
        uint256 confirmations; // How many owners have confirmed it.
        uint256 txId; // Current tx Id.
        // For adding/removing owners and changing the numberOfConfirmations, we need the following:
        bool changeOwners; // If yes, to becomes the to be appended or to be removed owner.
        bool add1_del0; // If change owners, then if this is true, you wish to add. Otherwise, you remove.
        bool changeNumConfirmations; // Change the amount of confirmations required to execute Tx.
    }

    address payable[] public owners; // Owners of the wallet
    uint256 public minTxChecks;

    constructor(address payable[] memory _owners, uint256 _initialTxChecks) {
        // owners = _owners; - It would be ideal for gas sake, yet to ensure no invalid owners:

        require(
            _owners.length >= _initialTxChecks,
            "There are more txConfirmations required than signers!"
        );
        require(
            _owners.length > 0,
            "No address list has been passed to the constructor"
        );
        require(_initialTxChecks >= 1, "At least one owner needs to sign it!");

        for (uint256 j = 0; j < _owners.length; j++) {
            address payable adm = _owners[j];
            require(adm != address(0), "Null address is invalid.");
            require(!doubleOwner[adm], "There is a double address input.");
            doubleOwner[adm] = true; // Registration of the owner
            ownerPosition[adm] = owners.length;
            owners.push(adm);
            isOwner[adm] = true;
        }

        minTxChecks = _initialTxChecks; // The initial txChecks is passed - at least this amount must be confirmed to execute.
    }

    Tx[] public txHistory;

    // Modifiers:

    modifier onlyOwners() {
        require(isOwner[msg.sender], "Not Owner - Permission Denied");
        _;
    }

    modifier notDoubleConfirms(uint256 txId) {
        require(
            !ownerA_confirmed_TxB[msg.sender][txId],
            "This owner has already confirmed this transaction"
        );
        _;
    }

    modifier txNotExecuted(uint256 txId) {
        require(!txExecuted[txId], "This transaction was already executed");
        _;
    }

    modifier enoughConfirmations(uint256 txId) {
        require(
            numConfirmations[txId] >= minTxChecks,
            "Not enough owners have confirmed - Tx cannot execute"
        );
        _;
    }

    // Functions
    // The transaction proposed here is so that owner can propose to pay, to add/del owner or even to change the numConf.
    /** AUDIT REQUIRED */
    // Owner is able to change Num and Add/Del Owners at the same time...
    // --> Essa construção de NULL e Zero tem problemas de interseção - é interessante impedir dupla ação.
    /** ------------------ */
    function proposeTx(
        address payable _to,
        uint256 _value,
        bool _changeOwners,
        bool _add1_del0,
        bool _changeNumConfirmations
    ) public onlyOwners {
        Tx memory proposedTx = Tx({
            to: _to,
            value: _value,
            owner: msg.sender,
            executed: false,
            confirmations: 1,
            txId: txHistory.length,
            changeOwners: _changeOwners,
            add1_del0: _add1_del0,
            changeNumConfirmations: _changeNumConfirmations // If active, to is null, value is numConf.
        });
        // When changing numConf, we set the to address to NULL.

        /** NEEDS SOME SIGHT ON THIS TO BE SURE */
        if (!_changeNumConfirmations) {
            require(_to != address(0), "No burning nor adding phantom owners.");
        } else {
            proposedTx.to = address(0);
            require(_value > 0, "Not zero confirmations!");
        }
        // When changing the Owners, we set the value to ZERO.
        if (!_changeOwners) {
            require(_value > 0, "No transfer");
        } else {
            proposedTx.value = 0;
            require(_to != address(0), "Not adding phantom owners.");
        }
        /** ^^^ -------------------- ^^^  */
        ownerA_confirmed_TxB[msg.sender][txHistory.length] = true;
        numConfirmations[txHistory.length] += 1;
        txHistory.push(proposedTx);
    }

    // This function must not be confirmed again by the same address.
    function confirmTx(
        uint256 txId
    ) public onlyOwners notDoubleConfirms(txId) txNotExecuted(txId) {
        txHistory[txId].confirmations += 1;
        numConfirmations[txId] += 1;
        ownerA_confirmed_TxB[msg.sender][txId] = true;
    }

    function deposit() public payable {}

    // For withdrawing, it is the same as an usual transaction

    function executeTx(
        uint256 txId
    )
        public
        onlyOwners
        txNotExecuted(txId)
        enoughConfirmations(txId)
        returns (bool)
    {
        /** Needs AUDITING STILL  */
        if (txHistory[txId].changeOwners) {
            if (txHistory[txId].add1_del0) {
                addOwner(txHistory[txId].to); // Pass the address we wish to append
            } else {
                removeOwner(txHistory[txId].to); // Pass the address we wish to delete
            }
            // require owners.length seja diferente sei la
            return true;
        }
        // If the to-be-executed tx wishes to change NumConfirmations
        if (txHistory[txId].changeNumConfirmations) {
            changeMinChecks(txHistory[txId].value);
        }
        /** -----------------  */
        // Transfer process
        address to = txHistory[txId].to;
        uint256 amount = txHistory[txId].value;
        (bool success, ) = to.call{value: amount}("");

        // Neutralizing tx:
        txHistory[txId].executed = true;
        txExecuted[txId] = true;

        return success;
    }

    function revokeConfirmation(
        uint256 txId
    ) public onlyOwners txNotExecuted(txId) {
        require(
            ownerA_confirmed_TxB[msg.sender][txId],
            "This owner did not confirm this transaction previously"
        );
        txHistory[txId].confirmations -= 1;
        ownerA_confirmed_TxB[msg.sender][txId] = false;
    }

    // Functions only to be called by the own contract, in midst other functions.
    // We wish to take advantage of the system of transactions we have in place.
    // These functions are the sole reason of some of parameters of a transaction.

    // We do not use onlyOwners modifier since only the contract calls this function.
    /** Needs AUDITING STILL  */
    function addOwner(address _newOwner) internal {
        ownerPosition[_newOwner] = owners.length; // Map the position of the new owner.
        owners.push(payable(_newOwner)); // Append new address into the list
    }

    /** ---------------------- */
    // This here below will be tricky....
    /** Needs AUDITING STILL  */
    function removeOwner(address _oldOwner) internal {
        //uint256 index = ownerPosition[_oldOwner];
        for (uint256 j = ownerPosition[_oldOwner]; j < owners.length - 1; j++) {
            owners[j] = owners[j + 1];
            ownerPosition[owners[j]] = j; // Update on position for the owner.
        }
        owners.pop();
    }

    /** ---------------------- */
    function changeMinChecks(uint256 _newNumberOfConfirmations) internal {
        minTxChecks = _newNumberOfConfirmations;
    }

    // function valueToNumConfirmations() internal onlyOwners {}

    fallback() external payable {}

    receive() external payable {}
}
