pragma solidity >=0.4.21 <0.7.0;

contract Users {
    /**
     * User's information
     * @param bindAddress User's external Ethereum address bind to this account
     * @param accountID User's registration account ID
     * @param balance Balance in the account for this user
     * @param lastGameID The last game this user participate in
     * @param transactionRecord The transaction record of this user
     * @notice The balance is not the ETH in user's actual Ethereum address, but his/her remaining in this contract.
     */
    struct User {
        address bindAddress;
        string accountID;
        uint balance;
        uint lastGameID;
        uint[] transactionRecord;
    }

    /**
     * Transaction detail
     * @param _transactionID ID of the transaction
     * @param _time The time of the transaction
     * @param _from Where the amount of ETH is transferred from
     * @param _to Where the amount of ETH is transferred to
     * @param _amount the The amount of ETH being transferred
     * @param _type The characteristic of this transaction, e.g., Deposit, Withdraw, Transfer, Bet, Reward, etc.
     */
    struct Transaction {
        uint _transactionID;
        uint _time;
        string _from;
        string _to;
        uint _amount;
        string _type;
    }

    /// Initiate the counter of the transaction ID
    uint internal transactionIDCounter = 1;

    /**
     * @param _from Where the amount of ETH is transferred from
     * @param _to Where the amount of ETH is transferred to
     * @param _amount The amount of ETH being transferred
     * @param _type The characteristic of this transaction, e.g., Deposit, Withdraw, Transfer, Bet, Reward, etc.
     * @dev Make the function `internal`, so it will be available in the subcontract(s).
     */
    function addTransaction(string memory _from, string memory _to, uint _amount, string memory _type) internal {
        Transaction storage transaction = transactionHistory[transactionIDCounter];
        transaction._transactionID = transactionIDCounter;
        transaction._time = now;
        transaction._from = _from;
        transaction._to = _to;
        transaction._amount = _amount;
        transaction._type = _type;

        userList[accountToAddress[_from]].transactionRecord.push(transactionIDCounter);
        userList[accountToAddress[_to]].transactionRecord.push(transactionIDCounter);

        transactionIDCounter += 1;
    }

    /**
     * Reveal the transactions within 1 day to users
     * @param targetTransactionID The transaction to reveal the details
     * @return _id The transaction ID
     * @return _type The type of the transaction
     * @return _time The timestamp of the transaction
     * @param _from Where the amount of ETH is transferred from
     * @param _to Where the amount of ETH is transferred to
     * @param _amount the The amount of ETH being transferred
     * @notice User can only see the transaction belongs to it
     */
    function userTransactionCheck(uint targetTransactionID) external view returns (uint _id, string memory _type, uint _time, string memory _from, string memory _to, uint _amount) {
        // Initialize temporary instance for easier manipulation and less gas cost
        User memory user = userList[msg.sender];
        Transaction memory transaction = transactionHistory[targetTransactionID];

        // The user can only read transaction history belongs to it
        require(user.bindAddress == accountToAddress[transaction._from] || user.bindAddress == accountToAddress[transaction._to], "This transaction does not belongs to you!");
        require(now - transaction._time <= 1 days, "You can only see transaction details within 1 day!");

        return (transaction._transactionID, transaction._type, transaction._time, transaction._from, transaction._to, transaction._amount);
    }

    /**
     * The user's transaction history
     */
    function userTransactionArrayCheck() external view returns (uint[] memory) {
        return userList[msg.sender].transactionRecord;
    }

    /// Mapping from transactionID to transaction's detail.
    mapping (uint => Transaction) internal transactionHistory;
    /// Mapping from accountID to address.
    mapping(string => address) internal accountToAddress;
    /// Mapping from address to user's information.
    mapping(address => User) internal userList;

    /**
     * A account will be created if both the address and the account ID is not taken.
     * @param  accountToRegister The account ID the user would like to use.
     */
    modifier notRegistered (string memory accountToRegister) {
        require (
            userList[msg.sender].bindAddress == address(0) && bytes(userList[msg.sender].accountID).length == 0 && userList[accountToAddress[accountToRegister]].bindAddress == address(0) && bytes(userList[accountToAddress[accountToRegister]].accountID).length == 0,
            "The address/account ID have already registered!"
        );
        _;
    }

    /**
     * Guarantee the msg.sender is a registered user.
     */
    modifier registered {
        require (
            bytes(userList[msg.sender].accountID).length != 0,
            "Your address has not registered yet! Please check again."
        );
        _;
    }

    /**
     * Guarantee the msg.sender has enough balance to do the balance-related activity.
     */
    modifier enoughBalance(uint amount) {
        require (userList[msg.sender].balance >= amount, "You do not have enough balance!");
        _;
    }

    /**
     * User registration
     * @param accountToRegister accountID the user would like to register
     */
    function createAccount(string memory accountToRegister) public notRegistered(accountToRegister) {
        // Add the accountToRegister => msg.sender to mapping
        accountToAddress[accountToRegister] = msg.sender;
        // Add the User struct to userList
        User storage user = userList[msg.sender];
        user.accountID = accountToRegister;
        user.bindAddress = msg.sender;
    }

    /**
     * Check if the user have registered or not, if yes, return the accountID
     */
    function checkRegistration() external view returns (string memory) {
        // Initialize temporary instance for easier manipulation and less gas cost
        User storage user = userList[msg.sender];
        if (bytes(user.accountID).length != 0) {
            return user.accountID;
        }

        return user.accountID;
    }

    /**
     * User deposit the money to the contract, and the contract will give him a "virtual" balance,
     * similar to deposit fiat money to bank
     */
    function deposit() external payable registered{
        userList[msg.sender].balance += msg.value;
        // Append transaction record
        addTransaction("External Wallet", userList[msg.sender].accountID, msg.value, "Deposit");
    }

    /**
     * User transfer his/her deposit to another registered user with the address
     * @param toAddress The address of the target registered user to transfer balance to
     * @param amount The amount of balance to transfer to the target registered user
     */
    function transferToAddress(address toAddress, uint amount) external registered enoughBalance(amount) {
        // Initialize temporary instance for easier manipulation and less gas cost
        User storage fromUser = userList[msg.sender];
        User storage targetUser = userList[toAddress];
        // The target should also be a registered account as well
        require (
            bytes(targetUser.accountID).length != 0,
            "The target address have not registered yet! Please check again."
        );
        // Manipulate the balance
        fromUser.balance -= amount;
        targetUser.balance += amount;
        // Append transaction record
        addTransaction(fromUser.accountID, targetUser.accountID, amount, "Transfer");
    }

    /**
     * User transfer his/her deposit to another registered user with the accountID
     * @param  toAccountID The accountID of the target registered user to transfer balance to
     * @param amount The amount of balance to transfer to the target registered user
     */
    function transferToID(string memory toAccountID, uint amount) public registered enoughBalance(amount) {
        // Initialize temporary instance for easier manipulation and less gas cost
        User storage fromUser = userList[msg.sender];
        User storage targetUser = userList[accountToAddress[toAccountID]];
        // The target should also be a registered account as well
        require (
            bytes(targetUser.accountID).length != 0,
            "The target address have not registered yet! Please check again."
        );
        // Manipulate the balance
        fromUser.balance -= amount;
        targetUser.balance += amount;
        // Append transaction record
        addTransaction(fromUser.accountID, toAccountID, amount, "Transfer");
    }

    /**
     * Withdraw the balance from the contract, get the token back to his/her ethureum address
     * @param amount The amount of balance to withdraw.
     */
    function withdraw(uint amount) external payable registered enoughBalance(amount) {
        // Initialize temporary instance for easier manipulation and less gas cost
        User storage user = userList[msg.sender];
        // Manipulate the balance
        user.balance -= amount;
        msg.sender.transfer(amount);
        // Append transaction record
        addTransaction(user.accountID, "External Wallet", amount, "Withdraw");
    }

    /**
     * Show the balance.
     */
    function checkBalance() external view registered returns (uint balance) {
        return userList[msg.sender].balance;
    }
}