pragma solidity >=0.4.21 <0.7.0;

import "./Bankers.sol";

contract CoinFlip is Bankers {
    /**
     * Players need to submit the hash values of their clear text before revealing
     * As these value are not stored permanently, they will be deleted after each round
     * @notice the value are deleted in houseCleaning() function
     */
    mapping (address => bytes32) internal submittedHashValue;
    /// If the submitHashCount and submitClearTextCount reach 2, the next step will be processed automatically
    uint internal submitHashCount = 0;
    uint internal submitClearTextCount = 0;
    /// The front-end will read this value to determine when the user can reveal the clear text
    bool internal bothSubmitHash = false;

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
        uint maxPlayer;
        address[] player;
        uint betValue;
        address winner;
        mapping (address => uint) submittedClearText;
    }

    /// Self-increasing gameID counter
    uint internal gameID = 1;
    /// gameID => Game struct mapping
    mapping (uint => Game) internal gameHistory;

    /**
     * @return Status of the on-going game
     */
    function currentGameStatus() external view returns (uint) {
        return gameHistory[gameID].status;
    }

    event test(uint);

    /**
     * Initialize a game
     * a game struct will be initialize and the betValue will be move from player's balance to banker's
     * @param betValue Only the player who initialize the game can set the betValue,
     *                 the participant can only accept it or wait until the game ends
     * @param _maxPlayer The maximum number of players for this game
     * @notice once the game is initialized, the currentWaiting will be true,
     *         and the front-end will not allow user to start a new game, they can only join the current one or wait
     */
    function initializeGame(uint betValue, uint _maxPlayer) external {
        Game storage game = gameHistory[gameID];
        User storage user = userList[msg.sender];

        require(_maxPlayer >= 2, "At least 2 players should enrol in one game!");
        require(game.status == 0, "There is a game waiting for player, you cannot start a new game now!");
        require(user.balance >= betValue, "You do not have sufficient balance.");

        // Initialize the game
        game.ID = gameID;
        game.maxPlayer = _maxPlayer;
        game.player.push(msg.sender);
        game.betValue = betValue;
        // Deduct the balance from the user's balance, move to banker's temperory balance (gameDeposit)
        user.balance -= betValue;
        banker.gameDeposit += betValue;
        // Append transaction record
        addTransaction(user.accountID, "banker", betValue, "Bet");

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
        bool enrolled = false;
        // The maximum number of i is the current player numbers
        for (uint i = 0; i < game.player.length; i++) {
            if (game.player[i] == msg.sender) {
                enrolled = true;
            }
        }
        require(!enrolled, "You are already enrolled in this game!");

        // Set the counterparty as the people join the game.
        game.player.push(msg.sender);

        // Deduct the balance from the user's balance, move to banker's temperory balance (gameDeposit)
        user.balance -= game.betValue;
        banker.gameDeposit += game.betValue;
        // Append transaction record
        addTransaction(user.accountID, "banker", game.betValue, "Bet");

        if (game.player.length == game.maxPlayer) {
            // Once the player list is full, change game status to 2.
            game.status = 2;
        }
    }

    /**
     * Only the enrolled players can use the command in the game.
     */
    modifier enrolledPlayer {
        Game memory game = gameHistory[gameID];
        bool enrolled = false;
        for (uint i = 0; i < game.maxPlayer; i++) {
            if (game.player[i] == msg.sender) {
                enrolled = true;
            }
        }
        require(enrolled, "You are not enrolled in this game!");
        _;
    }

    /**
     * @return current participants in this round
     */
    function currentInGamePlayer() external view returns (address[] memory) {
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

        if (submitHashCount == gameHistory[gameID].maxPlayer) {
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
        for (uint i = 0; i < game.maxPlayer; i++) {
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

        // Give the money back to participants
        for (uint i = 0; i < game.maxPlayer; i++) {
            userList[game.player[i]].balance += banker.gameDeposit / game.maxPlayer;
            // Append transaction records
            addTransaction("banker", userList[game.player[i]].accountID, banker.gameDeposit / game.maxPlayer, "Refund");
        }

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
            uint sumValue = 0;
            for (uint i = 0; i < game.maxPlayer; i++) {
                sumValue += game.submittedClearText[game.player[i]];
            }
            // Choose the winner
            uint remainder = sumValue % game.maxPlayer;
            game.winner = game.player[remainder];
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
        require(submitHashCount == game.maxPlayer, "Not all players have submitted the hash value!");
        // Prevent modification.
        require(game.submittedClearText[msg.sender] == 0, "You have already submitted your result.");

        // Record the clear text into the game history
        game.submittedClearText[msg.sender] = randomNumber;
        submitClearTextCount += 1;

        // If all players submitted their clear text, find the winner automatically.
        if (submitClearTextCount == game.maxPlayer) {
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
     * @return game_id Game IDof last game
     * @return bet_value Bet value of last game
     * @return total_player  Number of players in last game
     * @return your_index Index of the msg.sender in last game
     * @return winner_index Index of the winner in last game
     */
    function lastGameHistory() external view returns (uint game_id, uint bet_value, uint total_player, uint your_index, uint winner_index) {
        // Initialize temporary instance for easier manipulation and less gas cost
        Game storage game = gameHistory[userList[msg.sender].lastGameID];

        // Find the index of the user
        uint userIndex = 0;
        uint winnerIndex = 0;
        for (uint i = 0; i < game.maxPlayer; i++) {
            if (msg.sender == game.player[i]) {
                userIndex = i + 1;
            }
            if (game.winner == game.player[i]) {
                winnerIndex = i + 1;
            }
            if (userIndex != 0 && winnerIndex != 0) {
                break;
            }
        }
        return (game.ID, game.betValue, game.player.length, userIndex, winnerIndex);
    }

    /**
     * House cleaning process to release resources and prepare for the next round.
     */
    function houseCleaning() private {
        // Initialize temporary instance for easier manipulation and less gas cost
        Game storage game = gameHistory[gameID];

        // Update the game status to 3
        game.status = 3;
        for (uint i = 0; i < game.maxPlayer; i++) {
            // Change the lastGameID of the user to this game (user can only see the history of past game)
            userList[game.player[i]].lastGameID = gameID;
            // Clear submitted hash value
            delete submittedHashValue[game.player[i]];
        }

        // Delete the value stored in the parameter
        delete bothSubmitHash;
        delete submitHashCount;
        delete submitClearTextCount;

        // gameID increase by 1, prepare for the next game
        gameID += 1;
    }
}
