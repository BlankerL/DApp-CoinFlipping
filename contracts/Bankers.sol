pragma solidity >=0.4.21 <0.7.0;

import "./Users.sol";

contract Bankers is Users {
    /**
     * Struct for Banker
     * @param _bindAddress The address of the banker, defined in constructor
     * @param balance The remaining of the banker, i.e. the commission of the banker
     * @param gameDeposit The temporary deposit for the current game
     */
    struct Banker {
        address payable _bindAddress;
        uint balance;
        uint gameDeposit;
    }

    Banker internal banker;

    constructor() internal {
        banker = Banker({
            _bindAddress: msg.sender,
            balance: 0,
            gameDeposit: 0
        });
    }

    /**
     * The functions within this contract are only allowed for banker
     */
    modifier isBanker() {
        require(msg.sender == banker._bindAddress, "You are not banker, you cannot call this function!");
        _;
    }

    /**
     * Check if the msg.sender is the banker, used in front-end only
     */
    function checkIsBanker() external view isBanker returns (bool _isBanker) {
        return true;
    }

    /**
     * Check the banker's balance
     */
    function bankerCheckBalance() external view isBanker returns (uint balance) {
        return banker.balance;
    }

    /**
     * Permit the banker to withdraw the balance (commission earnings)
     */
    function bankerWithdraw(uint amount) external payable isBanker {
        require(banker.balance >= amount, "You do not have enough balance.");
        banker._bindAddress.transfer(amount);
        banker.balance -= amount;
    }

    /**
     * The banker can know the latest transaction ID
     */
    function latestTransactionID() external view isBanker returns (uint _latestTransactionID) {
        return transactionIDCounter;
    }

    /**
     * The banker can read transactions of all users
     * @param targetTransactionID The transaction to reveal the details
     * @return _id The transaction ID
     * @return _type The type of the transaction
     * @return _time The timestamp of the transaction
     * @param _from Where the amount of ETH is transferred from
     * @param _to Where the amount of ETH is transferred to
     * @param _amount the The amount of ETH being transferred
     */
    function bankerTransactionCheck(uint targetTransactionID) external view isBanker returns (uint _id, string memory _type, uint _time, string memory _from, string memory _to, uint _amount) {
        // Initialize temporary instance for easier manipulation and less gas cost
        Transaction memory transaction = transactionHistory[targetTransactionID];

        return (transaction._transactionID, transaction._type, transaction._time, transaction._from, transaction._to, transaction._amount);
    }
}
