pragma solidity >=0.4.21 <0.7.0;

import "./Bankers.sol";

contract CoinFlip is Bankers {
    /**
     * Players need to submit the hash values of their clear text before revealing
     * As these value are not stored permanently, they will be deleted after each round
     * @notice the value are deleted in houseCleaning() function
     */
    mapping (address => bytes32) submittedHashValue;
    /// If the submitHashCount and submitClearTextCount reach 2, the next step will be processed automatically
    uint submitHashCount = 0;
    uint submitClearTextCount = 0;
    /// The front-end will read this value to determine when the user can reveal the clear text.
    bool bothSubmitHash = false;

    /**
     * Struct for Game
     * @param gameID the self-increasing ID of the game, the gameID will increase by 1 in each round
     * @param status the status of the game. 0: not started, 1: waiting for participant, 2: in process, 3: finished
     * @param player the players participating in the game
     * @param betValue provided by the first player initializing the game
     * @param winner the winner of this round
     * @param submittedClearText the submitted clear text value for each user
     */
    struct Game {
        uint ID;
        uint status;
        address[2] player;
        uint betValue;
        address winner;
        mapping (address => uint) submittedClearText;
    }

    /// Self-increasing gameID counter
    uint gameID = 1;
    /// gameID => Game struct mapping
    mapping (uint => Game) gameHistory;

    function currentGameStatus() external view returns (uint) {
        return gameHistory[gameID].status;
    }

    /**
     * Initialize a game
     * a game struct will be initialize and the betValue will be move from player's balance to banker's
     * @param betValue only the player who initialize the game can set the betValue
     *                 the participant can only accept it or wait until the game ends
     * @notice once the game is initialized, the currentWaiting will be true,
     *         and the front-end will not allow user to start a new game, they can only join the current one or wait.
     */
    function initializeGame(uint betValue) external {
        require(gameHistory[gameID].status == 0, "There is a game waiting for player, you cannot start a new game now!");
        require(userList[msg.sender].balance >= betValue, "You do not have sufficient balance.");
        // Initialize the game
        Game storage game = gameHistory[gameID];
        game.ID = gameID;
        game.player[0] = msg.sender;
        game.betValue = betValue;
        // Deduct the balance from the user's balance, move to banker's temperory balance (gameDeposit)
        userList[msg.sender].balance -= betValue;
        banker.gameDeposit += betValue;
        // Append transaction record
        addTransaction(userList[msg.sender].accountID, "banker", betValue, "Bet");
        // Set the game status to 1
        game.status = 1;
    }

    /**
     * If there is an on-going game, the user can join it.
     * Once the new player join the game, the betValue will be deducted and transfer to the banker.
     */
    function joinGame() external {
        // Initialize temporary instance for easier manipulation and less gas cost.
        Game storage game = gameHistory[gameID];
        User storage user = userList[msg.sender];

        require(game.status == 1, "There is no game waiting for player, please initiate a game!");
        require(user.balance >= game.betValue, "You do not have sufficient balance.");
        // The player initialize the game cannot join it twice.
        require(game.player[0] != msg.sender, "You are already in this game!");

        // Set the counterparty as the people join the game.
        game.player[1] = msg.sender;
        // Deduct the balance from the user's balance, move to banker's temperory balance (gameDeposit)
        user.balance -= game.betValue;
        banker.gameDeposit += game.betValue;
        // Append transaction record
        addTransaction(user.accountID, "banker", game.betValue, "Bet");
        // Once the player list is full, change game status to 2.
        game.status = 2;
    }

    /**
     * Only the enrolled players can use the command in the game.
     */
    modifier enrolledPlayer {
        require(
            gameHistory[gameID].player[0] == msg.sender || gameHistory[gameID].player[1] == msg.sender,
            "You are not enrolled in this game!"
        );
        _;
    }

    /**
     * @return current participants in this round
     */
    function currentInGamePlayer() external view returns (address[2] memory) {
        return gameHistory[gameID].player;
    }

    /**
     * @return bet value for current round
     */
    function currentGameBetValue() external view returns (uint) {
        return gameHistory[gameID].betValue;
    }

    /**
     * Players submit their hash values through this function.
     * @param hashValue each player submit the hash value generated from their clear text.
     * @dev once both players submit their hash values, the bothSubmitHash will be true,
     *      and the player can reveal their clear text.
     */
    function submitHash(bytes32 hashValue) external enrolledPlayer {
        // Require the game has started.
        require(gameHistory[gameID].status == 2, "The game status is wrong!");
        // Once the player submit the value, he/she cannot modify it.
        require(submittedHashValue[msg.sender] == "", "You have already submitted your result.");

        submittedHashValue[msg.sender] = hashValue;
        submitHashCount += 1;

        if (submitHashCount == 2) {
            bothSubmitHash = true;
        }
    }

    /**
     * Make sure the submitted hash value and clear text match.
     * @dev Hash value is the user's
     */
    function validate() private view returns (uint) {
        // Initialize temporary instance for easier manipulation and less gas cost.
        Game storage game = gameHistory[gameID];

        uint cheaterCount = 0;
        for (uint i = 0; i < 2; i++) {
            if (submittedHashValue[game.player[i]] != keccak256(abi.encodePacked(game.player[i], game.submittedClearText[game.player[i]]))) {
                cheaterCount += 1;
            }
        }

        return cheaterCount;
    }

    /**
     * If one or more players are detected cheating, this round will be invalid.
     * The money will be given back to the players.
     */
    function detectCheating() private {
        // Initialize temporary instance for easier manipulation and less gas cost
        Game storage game = gameHistory[gameID];

        // Give the money back to two participants
        userList[game.player[0]].balance += banker.gameDeposit / 2;
        userList[game.player[1]].balance += banker.gameDeposit / 2;
        // Append transaction records
        addTransaction("banker", userList[game.player[0]].accountID, banker.gameDeposit / 2, "Refund");
        addTransaction("banker", userList[game.player[1]].accountID, banker.gameDeposit / 2, "Refund");

        delete banker.gameDeposit;
    }

    /**
     * If there is not cheaters found, the banker will find the winner.
     * After find the winner or detect cheating, the houseCleaning() will start.
     * @notice the player who initialize the game will always choose the mod == 0.
     */
    function findWinner() private returns (address) {
        // Initialize temporary instance for easier manipulation and less gas cost
        Game storage game = gameHistory[gameID];

        if (validate() == 0) {
            uint mod = addmod(game.submittedClearText[game.player[0]], game.submittedClearText[game.player[1]], 2);
            // Choose the winner
            game.winner = game.player[mod];
            // Transfer balance to the winner
            balanceTransfer();
            houseCleaning();
            return game.winner;
        } else {
            detectCheating();
            houseCleaning();
            return address(0);
        }
    }

    /**
     * Transfer 95% of the temporary gameDeposit to the winner, 5% to the banker.
     * @dev To cut down the fee, transfer the balance within the contract, rather than directly to winner's address.
     */
    function balanceTransfer() private {
        // Initialize temporary instance for easier manipulation and less gas cost
        Game storage game = gameHistory[gameID];

        // Banker take 5% as the commission, and the winner take the rest
        banker.balance += banker.gameDeposit / 100 * 5;
        userList[game.winner].balance += banker.gameDeposit / 100 * 95;
        // Append transaction records
        addTransaction("banker", "banker", banker.gameDeposit / 100 * 5, "Commission");
        addTransaction("banker", userList[game.winner].accountID, banker.gameDeposit / 100 * 95, "Reward");
        // Clear the gameDeposit for the banker
        delete banker.gameDeposit;
    }

    /**
     * Function for players to submit their clear text values.
     * Once 2 players submitted the clear text values, teh findWinner process will start.
     * @param randomNumber the automatically generated randomNumber for the player.
     */
    function submitClearText(uint randomNumber) external enrolledPlayer {
        // Initialize temporary instance for easier manipulation and less gas cost
        Game storage game = gameHistory[gameID];

        // Submit hash value before submiting clear text.
        require(submittedHashValue[msg.sender] != "", "You have not submit hash value yet.");
        // Clear text can only be submitted until all players submit the hash value.
        require(submitHashCount == 2, "Not all players have submitted the hash value!");
        // Prevent modification.
        require(game.submittedClearText[msg.sender] == 0, "You have already submitted your result.");

        // Record the clear text into the game history
        game.submittedClearText[msg.sender] = randomNumber;
        submitClearTextCount += 1;

        // If all players submitted their clear text, find the winner automatically.
        if (submitClearTextCount == 2) {
            findWinner();
        }
    }

    /**
     * @dev prepare for the JavaScript to check whether all players have submitted the hash value.
     */
    function bothSubmitHashCheck() external view enrolledPlayer returns (bool){
        return bothSubmitHash;
    }

    /**
     * @return game_id of last game
     * @return bet_value of last game
     * @return total_player number of last game
     * @return your_index of the msg.sender
     */
    function lastGameHistory() external view returns (uint game_id, uint bet_value, uint total_player, uint your_index) {
        // Initialize temporary instance for easier manipulation and less gas cost
        Game storage game = gameHistory[userList[msg.sender].lastGameID];

        // Find the index of the user
        uint userIndex = 0;
        for (uint i = 0; i < 2; i++) {
            if (msg.sender == game.player[i]) {
                userIndex = i;
                break;
            }
        }
        return (game.ID, game.betValue, game.player.length, userIndex);
    }

    /**
     * House cleaning process to release resources and prepare for the next round.
     */
    function houseCleaning() private {
        // Initialize temporary instance for easier manipulation and less gas cost
        Game storage game = gameHistory[gameID];

        // Update the game status to 3
        game.status = 3;
        // Change the lastGameID of the user to this game (user can only see the history of past game)
        userList[game.player[0]].lastGameID = gameID;
        userList[game.player[1]].lastGameID = gameID;

        // Delete the value stored in the parameter
        delete bothSubmitHash;
        delete submitHashCount;
        delete submitClearTextCount;

        // Clear submitted hash value
        delete submittedHashValue[game.player[0]];
        delete submittedHashValue[game.player[1]];

        // gameID increase by 1, prepare for the next game
        gameID += 1;
    }
}
