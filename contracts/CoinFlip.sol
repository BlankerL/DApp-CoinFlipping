pragma solidity >=0.4.21 <0.7.0;

import "./Account.sol";

contract CoinFlip is Account{
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
     * @param cheater if there are cheaters, they will be recorded here
     */
    struct Game {
        uint ID;
        uint status;
        address[2] player;
        uint betValue;
        address winner;
        mapping (address => uint) submittedClearText;
        address[2] cheater;
    }

    /// Self-increasing gameID counter
    uint gameID = 1;
    /// gameID => Game struct mapping
    mapping (uint => Game) gameHistory;

    function checkWaiting() external view returns (uint) {
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
        Game storage game = gameHistory[gameID];
        game.ID = gameID;
        game.player[0] = msg.sender;
        game.betValue = betValue;

        userList[msg.sender].balance -= betValue;
        banker.gameDeposit += betValue;

        gameHistory[gameID].status = 1;
    }

    /**
     * If there is an on-going game, the user can join it.
     * Once the new player join the game, the betValue will be deducted and transfer to the banker.
     */
    function joinGame() external {
        require(gameHistory[gameID].status == 1, "There is no game waiting for player, please initiate a game!");
        // The player initialize the game cannot join it twice.
        require(gameHistory[gameID].player[0] != msg.sender, "You are already in this game!");

        gameHistory[gameID].player[1] = msg.sender;

        userList[msg.sender].balance -= gameHistory[gameID].betValue;
        banker.gameDeposit += gameHistory[gameID].betValue;

        gameHistory[gameID].status = 2;
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
    function checkInGamePlayer() external view returns (address[2] memory) {
        return gameHistory[gameID].player;
    }

    /**
     * Players submit their hash values through this function.
     * @param hashValue each player submit the hash value generated from their clear text.
     * @dev once both players submit their hash values, the bothSubmitHash will be true,
     *      and the player can reveal their clear text.
     */
    function submitHash(bytes32 hashValue) external enrolledPlayer {
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
     * TODO: not only the random number itself should be submitted, we need other nonce.
     */
    function validate() private returns (uint) {
        uint cheaterCount = 0;
        for (uint i = 0; i < 2; i++) {
            if (submittedHashValue[gameHistory[gameID].player[i]] != keccak256(abi.encodePacked(gameHistory[gameID].submittedClearText[gameHistory[gameID].player[i]])) ) {
                gameHistory[gameID].cheater[cheaterCount] = gameHistory[gameID].player[i];
                cheaterCount += 1;
            }
        }
        return cheaterCount;
    }

    /**
     * If one or more players are detected cheating, this round will be invalid.
     * The money will be given back to the players.
     * TODO: Half of the cheater's balance will be kept by the contract/banker for punishment.
     */
    function detectCheating() private {
        userList[gameHistory[gameID].player[0]].balance += banker.gameDeposit / 2;
        userList[gameHistory[gameID].player[1]].balance += banker.gameDeposit / 2;

        delete banker.gameDeposit;
    }

    /**
     * If there is not cheaters found, the banker will find the winner.
     * After find the winner or detect cheating, the houseCleaning() will start.
     * @notice the player who initialize the game will always choose the mod == 0.
     */
    function findWinner() private returns (address) {
        if (validate() != 0) {
            uint mod = addmod(gameHistory[gameID].submittedClearText[gameHistory[gameID].player[0]], gameHistory[gameID].submittedClearText[gameHistory[gameID].player[1]], 2);
            if (mod == 0) {
                gameHistory[gameID].winner = gameHistory[gameID].player[0];
            } else {
                gameHistory[gameID].winner = gameHistory[gameID].player[1];
            }
            balanceTransfer();
            houseCleaning();
            return gameHistory[gameID].winner;
        } else {
            detectCheating();
            houseCleaning();
            return address(0);
        }
    }

    /**
     * Transfer 95% of the temporary gameDeposit to the winner, 5% to the banker.
     */
    function balanceTransfer() private {
        banker.balance += banker.gameDeposit / 100 * 5;
        userList[gameHistory[gameID].winner].balance += banker.gameDeposit / 100 * 95;
        banker.gameDeposit = 0;
    }

    /**
     * Function for players to submit their clear text values.
     * Once 2 players submitted the clear text values, teh findWinner process will start.
     * @param randomNumber the automatically generated randomNumber for the player.
     */
    function submitClearText(uint randomNumber) external enrolledPlayer {
        // Prevent modification.
        require(gameHistory[gameID].submittedClearText[msg.sender] == 0, "You have already submitted your result.");

        gameHistory[gameID].submittedClearText[msg.sender] = randomNumber;
        submitClearTextCount += 1;

        if (submitClearTextCount == 2) {
            findWinner();
        }
    }

    /**
     * House cleaning process to release resources and prepare for the next round.
     */
    function houseCleaning() private {
        gameHistory[gameID].status = 3;

        delete bothSubmitHash;
        delete submitHashCount;
        delete submitClearTextCount;

        gameID += 1;
    }
}
