function checkGameStatus() {
    coinFlipWeb3.contractInstance.methods.currentGameStatus().call(
        {
            from: coinFlipWeb3.web3Provider.selectedAddress
        },
        function (error, gameStatus) {
            if (error) {
                console.log(error);
            } else {
                if (gameStatus === '0') {
                    $("#initialize_game").show();
                } else {
                    coinFlipWeb3.contractInstance.methods.currentInGamePlayer().call(
                        {
                            from: coinFlipWeb3.web3Provider.selectedAddress
                        },
                        function (error, inGamePlayer) {
                            if (error) {
                                console.log(error);
                            } else {
                                inGamePlayer = inGamePlayer.toLocaleString().toLowerCase().split(',');
                                if (gameStatus === '1') {
                                    if (inGamePlayer.includes(coinFlipWeb3.web3Provider.selectedAddress)) {
                                        console.log('This person is in the game.');
                                        // This person is already in the game.
                                    } else {
                                        console.log('This person is not in the game.');
                                        $("#joinGame").show();
                                        coinFlipWeb3.contractInstance.methods.currentGameBetValue().call(
                                            {
                                                from: coinFlipWeb3.web3Provider.selectedAddress
                                            },
                                            function (error, result) {
                                                if (error) {
                                                    console.log(error);
                                                } else {
                                                    document.getElementById("betValue").innerText = web3.utils.fromWei(result, "ether") + " ETH";
                                                }
                                            }
                                        )
                                    }
                                } else if (gameStatus === '2') {
                                    if (inGamePlayer.includes(coinFlipWeb3.web3Provider.selectedAddress)) {
                                        $("#inGame").show();
                                    } else {
                                        $("#waitingList").show();
                                    }
                                }
                            }
                        }
                    )
                }
            }
        }
    )
}

$("#button_initialize_game").click(
    function (e) {
        e.preventDefault();
        coinFlipWeb3.contractInstance.methods.initializeGame(
            web3.utils.toWei($("#input_betValue").val(), "ether")
        ).send(
            {
                from: coinFlipWeb3.web3Provider.selectedAddress
            },
            function (error, result) {
                if (error) {
                    console.log(error);
                }
            }
        )
    }
)

$("#button_join_game").click(
    function (e) {
        e.preventDefault();
        coinFlipWeb3.contractInstance.methods.joinGame().send(
            {
                from: coinFlipWeb3.web3Provider.selectedAddress
            },
            function (error, result) {
                if (error) {
                    console.log(error);
                }
            }
        )
    }
)
