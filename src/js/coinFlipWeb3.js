coinFlipWeb3 = {
    contractAddress: "0x3C0978f5e8E58F3F20b7092a2bE1f503FE287277",
    web3Provider: null,
    contractInstance: null,

    init: function() {
        return coinFlipWeb3.initWeb3();
    },

    initWeb3: function() {
        // Initialize web3 and set the provider to the testRPC.
        if (typeof web3 !== 'undefined') {
            // For MetaMask, we need to call this to allow the site read the accounts.App.web3Provider = web3.currentProvider;
            coinFlipWeb3.web3Provider = web3.currentProvider;
            web3 = new Web3(web3.currentProvider);
        } else {
            coinFlipWeb3.web3Provider = new Web3.providers.HttpProvider('http://127.0.0.1:7545');
            web3 = new Web3(coinFlipWeb3.web3Provider);
        }
        return coinFlipWeb3.initContract();
    },

    initContract: function() {
        $.getJSON('contracts/CoinFlip.json', function(data) {
            // Get the necessary contract artifact file and instantiate it with truffle-contract.
            coinFlipWeb3.contractInstance = new web3.eth.Contract(data['abi'], coinFlipWeb3.contractAddress);
        });
    },
};
