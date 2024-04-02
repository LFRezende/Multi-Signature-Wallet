// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSigWallet {
    // Mappings:

    mapping(address => bool) public doubleOwner;
    mapping(address => mapping(uint256 => bool)) public ownerA_confirmed_TxB;
    mapping(address => bool) public isOwner;
    mapping(uint256 => bool) public txExecuted;
    mapping(uint256 => uint256) public numConfirmations;
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

    function proposeTx(
        address payable _to,
        uint256 _value,
        bool _changeOwners
    ) public onlyOwners {
        Tx memory proposedTx = Tx({
            to: _to,
            value: _value,
            owner: msg.sender,
            executed: false,
            confirmations: 1,
            txId: txHistory.length,
            changeOwners: _changeOwners
        });
        require(_to != address(0), "No burning nor adding phantom owners.");
        if (!_changeOwners) {
            require(_value > 0, "No transfer");
        } else {
            proposedTx.value = 0;
        }

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

    function addOwner() internal onlyOwners {}

    function removeOwner() internal onlyOwners {}

    function changeNumConfimations() internal onlyOwners {}

    function valueToNumConfirmations() internal onlyOwners {}

    fallback() external payable {}

    receive() external payable {}
}
