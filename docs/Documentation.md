# Design Document of Assignment 2
## Machine Problem: Distributed Coin Flipping Game Using Ethereum
Jiabao LIN, 3035673521

### Requirements Analysis

As mentioned in the requirements, we need to design a platform that people could register as a user, deposit/withdraw ETH to/from this platform, do in-game transfer to other registered users, and play coin flipping game with each other. In the meantime, a banker is required to perform as a dealer, which will prove the players are not cheating and get commission for this service. 

As a DApp, the backend should be the pure Ethereum Network, no database and backend engine is needed, and I need to write a contract to satisfy all the requirements. The user connects to the Ethereum Network to interact with the contract through web3. As long as the computer is conntected to the Internet and accessible to the Ethereum Network, the user could play this game. No backend server is needed, and I can even upload and host the static site on some third-party service like GitHub Pages. 

### Design

In my consideration, I will provide 4 functions, namely, Resigtration, Balance Management, Dealer (Banker) and Coin Flipping Game. 

#### Registration

User opens the website. If the user is not registered yet, the site will not showing other contents, and it should register with a proper `accountID` first. 

For each registered user, it will have a `User` struct maintained in the contract. 

```solidity
struct User {
    address bindAddress;
    string accountID;
    uint balance;
    uint lastGameID;
    uint[] transactionRecord;
}
```

`accountID` should be identical to each other, and should not start with `0x`, as it is reserved for addresses. 

- Because users can transfer their balance to other users with the corresponding address/accountID, the website need to tell whether the input is an address or an accountID, so the accountIDs are limited to not start with `0x` to distinguish with addresses.

#### Balance Management

##### Introduction

For each user, it owns an Ethereum account, which is its private wallet. For this platform, it initialize an `User` struct for each user and maintaining their balance. Therefore, user does not need to do an transaction every time when it would like to initialize/join a game. As the `accountID` and `address` are all identical to each other, only the user itself can manage its balance. 

Once the user has registered successfully, it could perform the Balance Management. In my consideration, Balance Management should cover the following functions. 

##### Deposit

User can deposit its Ether (ETH) into the contract, and the contract will modify the corresponding `balance` for the user. 

Once the user deposit an amount of ETH into the contract through `deposit()` function, the `balance` will increase by the corresponding amount in wei. 

##### Withdraw

User can withdraw its Ether (ETH) from the contract, and the contract will modify the corresponding `balance` for the user. 

Once the user withdraw an amount of ETH from the contract through `withdraw()` function, the `balance` will decrease by the corresponding amount in wei. 

##### Transfer

User can transfer its Ether (ETH) within the contract to another registered user by its address or accountID. 

Once the user transfer an amount of ETH to another user, the `balance` of the user will decrease by this amount and the `balance` of the target will increase by this amount. 

#### Dealer (Banker)

As mentioned by the requirement, the dealer should be a third-party banker. However, if a third-party banker is a real person, it will suffer the following problems. 

1. It might not notify the players to reveal the numbers in time, 
2. It might not pick out the winner in time,
3. It might make some mistakes when calculating the `mod` and pick the winner. 

In the meantime, as the TA have answered on [Moodle](https://moodle.hku.hk/mod/forum/discuss.php?d=524799#p1076162), I make implement the banker in the contract, and the person who deploy this contract can claim the banker's balance (commission earnings) because its address will be bind to banker, which is saved in `_bindAddress`. 

Therefore, I implement a `Banker` struct in my contract.

```solidity
struct Banker {
    address payable _bindAddress;
    uint balance;
    uint gameDeposit;
}
```

Once the contract is deployed, the `constructor()` will initialize the `banker` instance automatically. 

```solidity
Banker internal banker;

constructor() public {
		banker = Banker({
				_bindAddress: msg.sender,
				balance: 0,
				gameDeposit: 0
		});
}
```

A qualified banker should have the following functions. 

##### Collect Hash Values and Clear Text

In each game, the participants will submit the hash values and random numbers in clear text to the contract. 

The hash values are stored in a temporary parameter `submittedHashValue`, which will be cleaned after each game. The clear text are stored in permanent parameter `submittedClearText`, which is a parameter of each `Game` struct (see [Coin Flipping Game](#coin-flipping-game)). 

##### Validate Hash Values and Clear Text

Once all the hash values and clear texts are received, the banker (contract) will start validating the values. (see [Round 4 in Coin Flipping Game](#round-4)).

##### Find out the Winner

If there is no cheater detected, the banker (contract) will pick out the winner automatically (see [Round 4 in Coin Flipping Game](#round-4)). 

The banker will transfer 95% of the game deposit to the winner, and transfer 5% of the game deposit to the banker's own balance as the commission fee. After that, the banker will reset the `gameDeposit`, waiting for the next round of the game.

##### Withdraw Commission

As the banker keeps earning commissions in the contract if users play games on the platform, it will have some deposit in the `balance`. The person who deploy this contract will be able to withdraw this commission earnings by calling `withdrawBanker()` function, and the required amount of ETH will be transferred to the person's Ethereum account from the contract. 

#### Coin Flipping Game

For each game initiated, a `Game` struct will be initialized in the contract and stored permanently. 

```solidity
struct Game {
    uint ID;
    uint status;
    address[2] player;
    uint betValue;
    address winner;
    mapping (address => uint) submittedClearText;
}
```

To take this game apart, we can easily find out there are several rounds for the game.

##### Round 1

A user initialize a game on the platform, set the bet value. Other users will see the game on the platform, if other users think the bet value is proper, they can click `Join Game` button to join the game. 

Once the user participates in the game, the bet value will be deducted and transferred to the banker's game deposit to make sure the player have enough balance and will not withdraw the money before the game ends. 

##### Round 2

After the table is full, each user can click the `Flip the Coin` button to generate a random number on its machine (browser), the random number is a private variable in a function, so the user cannot see the value from the console. 

The random number is concatenated with the users address (see [Answer the Question 2.](#answer-the-question)), which will be look like $Address || Random \ Number$, and fed into a SHA3-256 function. After that, the hash value is sent to the banker, and the banker will keep the hash value for validation. 

##### Round 3

Once the banker receive hash values submitted by all the users, a parameter `bothSubmitHash` will be changed from `false` to `true`. In the frontend, the JavaScript keeps checking this value (once per second). Once the JavaScript find this value has been changed to `true`, the function will automatically send the random number to the banker (reveal the clear text). 

The participants do not need to do anything else, all they need to do is to confirm the transaction pop-up in MetaMask, which is the transaction of sending the random number to banker. 

##### Round 4

Once the banker receive all the clear text, it will start the `validation()` function, which is to check whether all the users faithful in the process. If all the participants are loyal, the banker will get the sum value of the clear text, calculate the remainder with the `addmod()` function provided by Solidity. This remainder will be the index of the participants in the `player` list. 

If at least 1 user is detected cheating, the game will end automatically and the deposit will be refund to the participants account. I do not implement a punishment here because of the following reasons: 

- The random number is a private value in the `flipCoin()` funtion in JavaScript, a normal user cannot read this value in the browser. If the attacker would like to modify the value, it need to capture the browser's traffic and manipulate the hexadecimal transaction data sent by MetaMask. 
- As the attacker can capture the traffic and modify the transaction data on its local machine, it can also capture the traffic of other participants. If an attacker capture other participants package and change the transaction data, and leads to a loss for those participants, that will be quite unfair for them. 

##### Round 5: House Clearning

After each game, the contract will clear up the unnecessary parameters to save gas, and to change the game status, increase the `gameID` by $1$.

### Answer the Question

Please explain/prove whether this protocol actually works or not, in term of fairness, and what are the possible attacks (cheating) among the three parties. In your implementation, how have you solved them? 

For the given protocol, overall speaking, this outline will work, but still have some problems. 

1. Random number generation. For most of the cases, the random number generator just provide pseudo-random. 

   **Solution**

   - As I generate the random number in the website, I do not use my own random number generator, but use the `Math.random()` provided by the browser. As I found [here](https://hackernoon.com/how-does-javascripts-math-random-generate-random-numbers-ef0de6a20131), this random number is not generated by the JavaScript but generated by the browser with **xorshift128+** algorithm. This algorithm takes a long time to repeat, and the game only last for very short period of time, so the random number generation will be secure enough. 
   - Make sure the possibility of odd/even number is the same. Because the `Math.random()`  generate the random number within $[0,1]$, we need to scale it up to make the most use of it. However, even if its decimal precision is to the 18th decimal places, it is of high frequency that the last character is 0, so the occurance of odd/even number is not of same possibility. Therefore, I only scale it up to $10^{16}$ to make sure the odd/even number occurs with the same possibility. 

2. Potentially reversible hash function. Basically speaking, the hash funtion is not reversible. However, as mentioned by D Kaovratovich [1], the SHA-2 family is still acdamically crackable. If the input is not long enough (the random number is not large enough), the attack might brute-force or use collision method to crack the clear text. For example, on [this site](https://md5hashing.net/hash/sha256), it maintains a dictionary of the cracked hash values and corresponding clear text. 

   **Solution**

   - Add salt for each submit value. Because JavaScript cannot hold interger larger than $9007199254740992=2^{53}$, which is only 53 bits and shorter than the output of `keccak256()` function (SHA3-256 with 256 bits output). Therefore, I used the user's address, which is 20 bytes/160 bits long, as the salt. The concatenation of the address and the random number will be look like $Address || Random \ Number$, which is $160 + 53 = 213$ bits long, and is difficult to collision and brute-force attack. As the attacker cannot see the counterparties' addresses on the website, the attacker can only get their addresses from the Ethereum blockchain, and the attacker need to generate and maintain a table for each user it would like to attack, which will be much more difficult. Once the user thinks the address is compromised, it can easily register another account and transfer all its balance to the new account. 

3. Unreliabile third-party banker. If the banker is a real man, then he might cheat and pick out the loser as the winner. 

   **Solution**

   - As mentioned in [Dealer (Banker)](#dealer-banker) part, I implement the whole banker within the contract. Once the contract is deployed to the Main Ethereum Network, everyone can real the contract and the code, make sure I am actually not cheating at all. There is no real third-party banker involved in this game, the winner is picked out by the contract automatically. Therefore, we do not need to worry about the banker cheats or quits his job as long as the Main Ethereum Network functions. In the meantime, the banker will not maintain the transaction records or game histories, all these things are maintained in the contract. (**TODO**)

### Measurement and Analysis

Use as a emulator to see the design of the blockchain. 

initialize the user/game in the function to cut down the deployment fee and transaction gas cost.
Use mapping instead of array, because array is based on mapping, which will cost more gas.



### Reference

1. Khovratovich, D., et al. (2012). Bicliques for Preimages: Attacks on Skein-512 and the SHA-2 Family, Berlin, Heidelberg, Springer Berlin Heidelberg.

