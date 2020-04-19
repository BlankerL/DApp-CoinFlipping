coinFlipWeb3 = {
    web3Provider: null,

    init: function() {
        return this.initWeb3();
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
        return this.initContract();
    },

    initContract: function() {
        $.getJSON('CoinFlip.json', function(data) {
            // Get the necessary contract artifact file and instantiate it with truffle-contract.
            coinFlipWeb3.contract = new web3.eth.Contract(data['abi'], "0xD759Ac5344c0A9ecB2C738d45411Ffa967C95A91");
        });
    },
};
