## Machine Problem: Distributed Coin Flipping Game Using Ethereum
**It is recommended to use Markdown file, as some of the hyperlinks might not work properly after exported as PDF file.** 

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

### Deployment

Open Ganache, set the RPC Server to `http://127.0.0.1:7545`. 

Open the terminal, get into directory, run the following commands to deploy. 

```bash
truffle migrate --reset
```

You will get a contract address of the `CoinFlip`, the information will be similar to the following one. Therefore, the contract address is `0xc5C7187AFDa52957bE5052Cf5d9fdc11E0120111`.

```
> transaction hash:    0xbfab5e31d8c82739ad02541b5f64204c3ac5a2c41cb025361675427ade09215e
> Blocks: 0            Seconds: 0
> contract address:    0xc5C7187AFDa52957bE5052Cf5d9fdc11E0120111
> block number:        854
> block timestamp:     1587999346
> account:             0x7a14Fbf94e944769c125e53e4A8993eC65322764
> balance:             61.768400299702833669
> gas used:            5680976
> gas price:           20 gwei
> value sent:          0 ETH
> total cost:          0.11361952 ETH
```

Replace the contract address in the `src/js/coinFlipWeb3.js`.

```javascript
coinFlipWeb3 = {
    contractAddress: "0xc5C7187AFDa52957bE5052Cf5d9fdc11E0120111",  // Replace here
    web3Provider: null,
    contractInstance: null
}
```

Then, you can run `lite-server` in the `src` folder to go to the index page. 

```bash
lite-server
```

If your selected address in MetaMask is the address of contract owner, the webpage will ask you whether you would like to go to the administration panel, which is `/banker.html`. Otherwise, you can only visit the user panel, which is `/index.html`. 

