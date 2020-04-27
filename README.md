## Machine Problem: Distributed Coin Flipping Game Using Ethereum
### Description

This is my assignment outcome for COMP7408 Distributed Ledger and Blockchain Technology Assignment 2 in the University of Hong Kong. This project includes user management and a coin flipping game. It has the following characteristics: 

- **Highly anoymous and confidential.** Users cannot see the counterparties' username (accountID) in the game and game history. In game history, only the user's index and winner's index will be provided. Unless the counterparties go to the [Ethereum Blockchain Explorer](https://etherscan.io/) to track the transactions one by one, they will never know your actual accountID. 
- **High speed.** The banker (dealer) is implemented within the contract, no real-person dealer is needed. Therefore, the speed of the game will be much faster (at least 16.7% faster if the users always act in time). This part is discussed in [Design Document](docs/Design Document.md). 
- **Light weight.** There is no server/backend actually needed, all the user/game/transaction information are stored in the blockchain. Even with GitHub Pages, a full functional site can be hosted without any effort. 
- **Multiple players.** More than 2 players in each round of game is supported. The people who initialize the game can decide how many players are allowed in this round. 

### File Structure

```
CoinFlipping
├── README.md
├── build
├── contracts
│   ├── Bankers.sol
│   ├── CoinFlip.sol
│   ├── Migrations.sol
│   └── Users.sol
├── docs
│   ├── Design Document.md
│   ├── Requirements.pdf
│   └── User Manual.md
├── migrations
├── src
│   ├── banker.html
│   ├── contracts
│   │   └── CoinFlip.json
│   ├── index.html
│   └── js
│       ├── account.js
│       ├── admin.js
│       ├── coinFlipWeb3.js
│       └── game.js
└── truffle-config.js

```

#### HTML files

All the HTML related files are in the `src` folder of this project. 

`index.html` is the default page for the user. 

`banker.html` is the administration panel for the banker. 

Files in `js` folder are the JavaScript written by me. Other dependencies (JavaScript and CSS) are loaded directly from the CDN ([jsDelivr](https://www.jsdelivr.com/)) in the HTML, so I do not includes them into the `src` folder. 

#### Documentation

Documentation are placed in the `docs` folder. 

`Design Document` is mainly about the desiging of this project, and answering all the questions. 

`User Manual` is a brief introduction of how you can interact with this project. 

All the static files are stored in the `*.assets` folders, you do not need to access this folders, they will be automatically loaded into the Markdown files. 

**It is recommended to use Markdown file, as some of the hyperlinks might not work properly after exported as PDF file.** 

### Deployment

Open Ganache, set the RPC Server to `http://127.0.0.1:7545`. 

Open the terminal, get into directory, run the following commands to deploy. 

```bash
truffle migrate --reset
```

Then, you can run `lite-server` in the `src` folder to go to the index page. 

```bash
lite-server
```

If your selected address in MetaMask is the address of contract owner, the webpage will ask you whether you would like to go to the administration panel, which is `/banker.html`. Otherwise, you can only visit the user panel, which is`/index.html`. 

