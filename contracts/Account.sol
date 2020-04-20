pragma solidity >=0.4.21 <0.7.0;

contract Account {
    /**
     * User's information
     */
    struct User {
        address bindAddress;
        string accountID;
        uint balance;
        bool inGame;
    }

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
        require (userList[msg.sender].balance > amount, "You do not have enough balance!");
        _;
    }

    /**
     * @param accountToRegister The account ID the user would like to use.
     */
    function createAccount(string memory accountToRegister) public notRegistered(accountToRegister) {
        // Add the accountToRegister => msg.sender to mapping
        accountToAddress[accountToRegister] = msg.sender;
        // Add the User struct to userList
        User storage user = userList[msg.sender];
        user.accountID = accountToRegister;
        user.bindAddress = msg.sender;
    }

    function checkRegistration() external view returns (bool) {
        if (bytes(userList[msg.sender].accountID).length != 0) {
            return true;
        }
        return false;
    }

    /**
     * User deposit the money to the contract, and the contract will give him a "virtual" balance, similar to deposit fiat money to bank.
     */
    function deposit() external payable registered{
        userList[msg.sender].balance += msg.value;

        emit showBalance(userList[msg.sender].balance);
    }

    /**
     * User transfer his/her deposit to another registered user with the address.
     * @param toAddress The address of the target registered user to transfer balance to.
     * @param amount The amount of balance to transfer to the target registered user.
     */
    function transferToAddress(address toAddress, uint amount) external registered enoughBalance(amount) {
        // The target should also be a registered account as well
        require (
            bytes(userList[toAddress].accountID).length != 0,
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
        // The target should also be a registered account as well
        require (
            bytes(userList[accountToAddress[toAccountID]].accountID).length != 0,
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