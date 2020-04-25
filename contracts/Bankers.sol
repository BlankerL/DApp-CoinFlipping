pragma solidity >=0.4.21 <0.7.0;

// TODO: Reconstruct the gameHistory, maybe I can make it an array

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

    Banker private banker;

    constructor() public {
        banker = Banker({
            _bindAddress: msg.sender,
            balance: 0,
            gameDeposit: 0
        });
    }

    function bankerWithdraw(uint amount) external payable {
        require(msg.sender == banker._bindAddress, "You are not the contract owner, you cannot withdraw the money.");
        require(banker.balance >= amount, "You do not have enough balance.");
        banker._bindAddress.transfer(amount);
        banker.balance -= amount;
    }
}
