App = {
    web3Provider: null,
    contracts: {},

    init: function() {
        return App.initWeb3();
    },

    initWeb3: function() {
        // Initialize web3 and set the provider to the testRPC.
        if (typeof web3 !== 'undefined') {
            // For MetaMask, we need to call this to allow the site read the accounts.App.web3Provider = web3.currentProvider;
            web3 = new Web3(web3.currentProvider);
        } else {
            App.web3Provider = new Web3.providers.HttpProvider('http://127.0.0.1:7545');
            web3 = new Web3(App.web3Provider);
        }
        return true;
    }
};

$(window).on('load', function () {
    App.init();
});
