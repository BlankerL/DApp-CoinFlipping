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
                                        $("#joinGame").show();
                                        $("#enrolled_successfully").show();
                                        $("#button_join_game").hide();
                                    } else {
                                        $("#joinGame").show();
                                    }
                                    coinFlipWeb3.contractInstance.methods.currentGameInformation().call(
                                        {
                                            from: coinFlipWeb3.web3Provider.selectedAddress
                                        },
                                        function (error, result) {
                                            if (error) {
                                                console.log(error);
                                            } else {
                                                document.getElementById("betValue").innerText = web3.utils.fromWei(result["bet_value"], "ether") + " ETH";
                                                document.getElementById("maxPlayers").innerText = result["max_player"];
                                                document.getElementById("currentPlayers").innerText = result["current_player"];
                                            }
                                        }
                                    )
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

function initializeGame() {
    coinFlipWeb3.contractInstance.methods.initializeGame(
        web3.utils.toWei($("#input_betValue").val(), "ether"),
        $("#input_maxPlayers").val()
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

function joinGame() {
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

function flipCoin() {
    const randomNumber = Math.floor(Math.random() * 1e+16);
    submitHash(randomNumber);
    let submitHashCheckTimer = setInterval(
        function checkAllSubmitHash() {
            coinFlipWeb3.contractInstance.methods.checkAllSubmitHash().call(
                {
                    from: coinFlipWeb3.web3Provider.selectedAddress
                },
                function (error, result) {
                    if (error) {
                        console.log(error);
                    } else {
                        if (result) {
                            clearInterval(submitHashCheckTimer);
                            submitClearText(randomNumber);
                        }
                    }
                }
            )
        },
        1000
    );
}

function submitHash(clearText) {
    coinFlipWeb3.contractInstance.methods.submitHash(
        web3.utils.sha3(
            "0x" +
            coinFlipWeb3.web3Provider.selectedAddress.substring(2,) +
            web3.utils.leftPad(
                web3.utils.numberToHex(clearText).substring(2,),
                64, 0
            )
        )
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

function submitClearText(clearText) {
    coinFlipWeb3.contractInstance.methods.submitClearText(
        // Use the BigNumber to fix the invalid value problem.
        web3.utils.toBN("" + clearText)
    ).send(
        {
            from: coinFlipWeb3.web3Provider.selectedAddress,
            gas: 2000000
        },
        function (error, result) {
            if (error) {
                console.log(error);
            }
        }
    )
}

function lastGameHistory() {
    coinFlipWeb3.contractInstance.methods.lastGameHistory().call(
        {
            from: coinFlipWeb3.web3Provider.selectedAddress
        },
        function (error, result) {
            if (error) {
                console.log(error);
            } else {
                if (result["game_id"] !== "0") {
                    document.getElementById('last_game_id').innerText = result["game_id"];
                    document.getElementById('last_game_bet_value').innerText = web3.utils.fromWei(result["bet_value"], 'ether') + ' ETH';
                    document.getElementById('last_game_total_player').innerText = result["total_player"];
                    document.getElementById('last_game_your_index').innerText = result["your_index"];
                    document.getElementById('last_game_winner_index').innerText = result["winner_index"];
                } else {
                    document.getElementById('game_history').className = "text-center";
                    document.getElementById('game_history').innerText = "You are a new player! No history for you!";
                }
            }
        }
    )
}