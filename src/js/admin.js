function bankerCheckBalance() {
    coinFlipWeb3.contractInstance.methods.bankerCheckBalance().call(
        {
            from: coinFlipWeb3.web3Provider.selectedAddress
        },
        function(error, result) {
            if (error) {
                console.log(error);
            } else {
                document.getElementById("balance").innerText = web3.utils.fromWei(result, 'ether') + ' ETH';
            }
        }
    )
}

function withdrawEther() {
    coinFlipWeb3.contractInstance.methods.bankerWithdraw(
        web3.utils.toWei($("#withdraw_amount").val(), 'ether')
    ).send(
        {
            from: coinFlipWeb3.web3Provider.selectedAddress
        },
        function (error, result) {
            if (error) {
                console.log(error);
            } else {
                alert('You have successfully withdrawn ' + $("#withdraw_amount").val() + " ETH!");
                document.getElementById("withdraw_amount").value = "";
                checkBalance();
                transactionCheck();
            }
        }
    )
}

function transactionCheck() {
    coinFlipWeb3.contractInstance.methods.latestTransactionID().call(
        {
            from: coinFlipWeb3.web3Provider.selectedAddress
        },
        function (error, result) {
            if (error) {
                console.log(error);
            } else {
                result = [...Array(parseInt(result)).keys()];
                if (result.length === 0) {
                    document.getElementById('transaction_history').className = "text-center";
                    document.getElementById('transaction_history').innerText = "You are a new player! No history for you!"
                } else {
                    $("#transaction_history_tbody").empty();
                    result.reverse();
                    result.some(addTransactionHistory);
                    function addTransactionHistory(transactionID) {
                        coinFlipWeb3.contractInstance.methods.bankerTransactionCheck(
                            parseInt(transactionID + 1)
                        ).call(
                            {
                                from: coinFlipWeb3.web3Provider.selectedAddress
                            },
                            function (error, result) {
                                if (error) {
                                    console.log(error);
                                } else {
                                    // Only loop for transaction happens within 24 hours
                                    if (Math.floor(Date.now() / 1000) - result["_time"] <= 86400) {
                                        let targetRow = document.getElementById('transaction_history').getElementsByTagName('tbody')[0].insertRow();
                                        // Transaction ID
                                        let targetCell = targetRow.insertCell(0);
                                        targetCell.appendChild(document.createTextNode(result["_id"]));
                                        // Transaction Type
                                        targetCell = targetRow.insertCell(1);
                                        targetCell.appendChild(document.createTextNode(result["_type"]))
                                        // Transaction Time
                                        targetCell = targetRow.insertCell(2);
                                        let transaction_time = new Date(result["_time"] * 1000)
                                        targetCell.appendChild(document.createTextNode(transaction_time.toLocaleDateString('zh-HK') + ' ' + transaction_time.toLocaleTimeString()));
                                        // From
                                        targetCell = targetRow.insertCell(3);
                                        targetCell.appendChild(document.createTextNode(result["_from"]))
                                        // To
                                        targetCell = targetRow.insertCell(4);
                                        targetCell.appendChild(document.createTextNode(result["_to"]))
                                        // Amount
                                        targetCell = targetRow.insertCell(5);
                                        targetCell.appendChild(document.createTextNode(
                                            web3.utils.fromWei(result["_amount"], 'ether') + ' ETH'
                                        ))
                                    } else {  // if the time exceed, return and stop the loop
                                        return true;
                                    }
                                }
                            }
                        )
                    }
                }
            }
        }
    )
}
