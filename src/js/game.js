function checkGameStatus() {
    coinFlipWeb3.contractInstance.methods.checkWaiting().call(
        {
            from: coinFlipWeb3.web3Provider.selectedAddress
        },
        function (error, result) {
            if (error) {
                console.log(error);
            } else {
                if (result) {
                    console.log("Game in progress.")  // TODO: Finish this part. Show join button.
                } else {
                    console.log("You need to start a game.")  // TODO: Show initialize game button.
                }
            }
        }
    )
}