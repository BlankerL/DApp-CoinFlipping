pragma solidity >=0.6.0 <0.7.0;

/// TODO: Remove the registered, use accountID as the symbol.

contract Account {
    /**
     * User's information
     */
    struct User {
        address bindAddress;
        string accountID;
        uint balance;
        bool inGame;
        bool registered;
    }

    /// Mapping from accountID to address.
    mapping(string => address) internal accountToAddress;
    /// Mapping from address to user's information.
    mapping(address => User) internal userList;

    /**
     * A account will be created if both the address and the account ID is not taken.
     * @param  accountID The account ID the user would like to use.
     */
    modifier notRegistered (string memory accountID) {
        require (
            !userList[msg.sender].registered && !userList[accountToAddress[accountID]].registered,
            "The address/account ID have already registered!"
        );
        _;
    }

    /**
     * Guarantee the msg.sender is a registered user.
     */
    modifier registered {
        require (
            userList[msg.sender].registered,
            "Your address has not registered yet! Please check again."
        );
        _;
    }

    /**
     * Guarantee the msg.sender has enough balance to do the balance-related activity.
     */
    modifier enoughBalance(uint amount) {
        require (userList[msg.sender].balance > amount, "You do not have enough balance!");
        _;
    }

    /**
     * @param accountID The account ID the user would like to use.
     */
    function createAccount(string memory accountID) public notRegistered(accountID) {
        //
        accountToAddress[accountID] = msg.sender;
        //
        User storage user = userList[msg.sender];
        user.accountID = accountID;
        user.bindAddress = msg.sender;
        user.registered = true;
    }

    function checkRegistration() external view returns (bool) {
        return userList[msg.sender].registered;
    }

    /**
     * User deposit the money to the contract, and the contract will give him a "virtual" balance, similar to deposit fiat money to bank.
     */
    function deposit() external payable {
        require (
            userList[msg.sender].registered,
            "The address has not registered yet! Please check again."
        );

        userList[msg.sender].balance += msg.value;

        emit showBalance(userList[msg.sender].balance);
    }

    /**
     * User transfer his/her deposit to another registered user with the address.
     * @param toAddress The address of the target registered user to transfer balance to.
     * @param amount The amount of balance to transfer to the target registered user.
     */
    function transferToAddress(address toAddress, uint amount) external registered enoughBalance(amount) {
        require (
            userList[toAddress].registered,
            "The target address have not registered yet! Please check again."
        );
        userList[msg.sender].balance -= amount;
        userList[toAddress].balance += amount;

        emit showBalance(userList[msg.sender].balance);
    }

    event showBalance(uint balance);

    /**
     * User transfer his/her deposit to another registered user with the accountID.
     * @param  toAccountID The accountID of the target registered user to transfer balance to.
     * @param amount The amount of balance to transfer to the target registered user.
     */
    function transferToID(string memory toAccountID, uint amount) public registered enoughBalance(amount) {
        require (
            userList[accountToAddress[toAccountID]].registered,
            "The target address have not registered yet! Please check again."
        );
        userList[msg.sender].balance -= amount;
        userList[accountToAddress[toAccountID]].balance += amount;

        emit showBalance(userList[msg.sender].balance);
    }

    /**
     * Withdraw the balance from the contract, get the token back to his/her ethureum address.
     * @param amount The amount of balance to withdraw.
     */
    function withdraw(uint amount) external payable registered enoughBalance(amount) {
        userList[msg.sender].balance -= amount;
        msg.sender.transfer(amount);

        emit showBalance(userList[msg.sender].balance);
    }

    /**
     * Show the balance.
     */
    function checkBalance() external view registered returns (uint balance) {
        return userList[msg.sender].balance;
    }
}