pragma solidity >=0.4.21 <0.7.0;

import "./Account.sol";

contract CoinFlip is Account{
    struct Banker {
        uint balance;
        uint gameDeposit;
    }
    Banker banker = Banker({
        balance: 0,
        gameDeposit: 0
        });

    mapping (address => bytes32) submittedHashValue;
    mapping (address => uint) submittedClearText;
    uint submitHashCount = 0;
    uint submitClearTextCount = 0;
    bool bothSubmitHash = false;
    address[2] cheater;

    struct Game {
        uint gameID;
        address[2] player;
        uint betValue;
        address winner;
        bool payout;
    }

    uint gameIDCounter = 1;
    bool currentlyWaiting = false;
    mapping (uint => Game) gameHistory;

    function initiateGame(uint betValue) external {
        gameHistory[gameIDCounter] = Game({
            gameID: gameIDCounter,
            player: [address(msg.sender), address(0)],
            betValue: betValue,
            winner: address(0),
            payout: false
            });

        userList[msg.sender].balance -= betValue;
        banker.gameDeposit += betValue;

        currentlyWaiting = true;
    }

    function joinGame() external {
        require(currentlyWaiting, "There is no game waiting for player, please initiate a game!");
        require(gameHistory[gameIDCounter].player[0] != msg.sender, "You are already in this game!");

        gameHistory[gameIDCounter].player[1] = msg.sender;

        userList[msg.sender].balance -= gameHistory[gameIDCounter].betValue;
        banker.gameDeposit += gameHistory[gameIDCounter].betValue;
    }

    modifier enrolledPlayer {
        require(
            gameHistory[gameIDCounter].player[0] == msg.sender || gameHistory[gameIDCounter].player[1] == msg.sender,
            "You are not enrolled in this game!"
        );
        _;
    }

    function submitHash(bytes32 hashValue) external enrolledPlayer {
        require(submittedHashValue[msg.sender] == "", "You have already submitted your result.");

        submittedHashValue[msg.sender] = hashValue;
        submitHashCount += 1;

        if (submitHashCount == 2) {
            bothSubmitHash = true;
        }
    }

    function validate() private returns (uint) {
        uint cheaterCount = 0;
        for (uint i = 0; i < 2; i++) {
            if (submittedHashValue[gameHistory[gameIDCounter].player[i]] != keccak256(abi.encodePacked(submittedClearText[gameHistory[gameIDCounter].player[i]])) ) {
                cheater[cheaterCount] = gameHistory[gameIDCounter].player[i];
                cheaterCount += 1;
            }
        }
        return cheaterCount;
    }

    function detectCheating() private {
        userList[gameHistory[gameIDCounter].player[1]].balance += banker.gameDeposit / 2;
        userList[gameHistory[gameIDCounter].player[2]].balance += banker.gameDeposit / 2;

        delete banker.gameDeposit;
    }

    function findWinner() private returns (address) {
        if (validate() != 0) {
            uint mod = addmod(submittedClearText[gameHistory[gameIDCounter].player[0]], submittedClearText[gameHistory[gameIDCounter].player[1]], 2);
            if (mod == 0) {
                gameHistory[gameIDCounter].winner = gameHistory[gameIDCounter].player[0];
            } else {
                gameHistory[gameIDCounter].winner = gameHistory[gameIDCounter].player[1];
            }
            balanceTransfer();
            houseCleaning();
        } else {
            detectCheating();
            houseCleaning();
            return address(0);
        }
        return gameHistory[gameIDCounter].winner;
    }

    function balanceTransfer() private {
        banker.balance += banker.gameDeposit / 100 * 3;
        userList[gameHistory[gameIDCounter].winner].balance += banker.gameDeposit / 100 * 97;
        banker.gameDeposit = 0;
    }

    function submitClearText(uint randomNumber) external enrolledPlayer {
        require(submittedClearText[msg.sender] == 0, "You have already submitted your result.");

        submittedClearText[msg.sender] = randomNumber;
        submitClearTextCount += 1;

        if (submitClearTextCount == 2) {
            findWinner();
        }
    }

    function houseCleaning() private {
        delete bothSubmitHash;
        delete submitHashCount;
        delete submitClearTextCount;
        delete currentlyWaiting;
        delete cheater;

        gameIDCounter += 1;
    }
}
