pragma solidity >=0.4.21 <0.7.0;

// TODO: Reconstruct the gameHistory, maybe I can make it an array
// TODO: Check how the balance is changed, currently something must be wrong.

import "./Users.sol";

contract Bankers is Users {
    /**
     * Struct for Banker, which should contain the balance and temporary deposit for the current game.
     */
    struct Banker {
        uint balance;
        uint gameDeposit;
    }

    /// Initialize the banker
    Banker banker = Banker({
        balance: 0,
        gameDeposit: 0
    });
}
