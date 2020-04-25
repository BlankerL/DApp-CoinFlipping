function checkBalance() {
    coinFlipWeb3.contractInstance.methods.checkBalance().call(
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

function checkRegistration() {
    coinFlipWeb3.contractInstance.methods.checkRegistration().call(
        {
            from: coinFlipWeb3.web3Provider.selectedAddress
        },
        function(error, result) {
            if (error) {
                console.log(error);
            } else {
                document.getElementById("username").innerText = result;
            }
        }
    )
}

function createAccount() {
    let account = $("#account_id").val();
    if (account.substring(0, 2) === '0x') {
        alert("You cannot set account ID start with \"0x\"!");
    } else {
        coinFlipWeb3.contractInstance.methods.createAccount(
            account
        ).send(
            {
                from: coinFlipWeb3.web3Provider.selectedAddress
            },
            function(error, result) {
                if (error) {
                    console.log(error);
                } else {
                    console.log(result);
                }
            }
        )
    }
}

function depositEther() {
    coinFlipWeb3.contractInstance.methods.deposit().send(
        {
            from: coinFlipWeb3.web3Provider.selectedAddress,
            value: web3.utils.toWei($("#deposit_amount").val(), 'ether')
        },
        function (error, result) {
            if (error) {
                console.log(error);
            } else {
                alert('You have successfully deposited ' + $("#deposit_amount").val() + " ETH! Have fun!");
                checkBalance();
            }
        }
    )
}

function withdrawEther() {
    coinFlipWeb3.contractInstance.methods.withdraw(
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
                checkBalance();
            }
        }
    )
}

function transferEther() {
    const target_account = $("#transfer_target").val()
    if (target_account.substring(0, 2) === '0x') {  // Address starts with '0x'
        coinFlipWeb3.contractInstance.methods.transferToAddress(
            target_account,
            web3.utils.toWei($("#transfer_amount").val(), 'ether')
        ).send(
            {
                from: coinFlipWeb3.web3Provider.selectedAddress
            },
            function (error, result) {
                if (error) {
                    console.log(error);
                } else {
                    alert('You have successfully transfer ' + $("#transfer_amount").val() + " ETH to " + target_account + "!");
                    checkBalance();
                }
            }
        )
    } else {  // Account ID is not allowed to start with '0x'
        coinFlipWeb3.contractInstance.methods.transferToID(
            target_account,
            web3.utils.toWei($("#transfer_amount").val(), 'ether')
        ).send(
            {
                from: coinFlipWeb3.web3Provider.selectedAddress
            },
            function (error, result) {
                if (error) {
                    console.log(error);
                } else {
                    alert('You have successfully transfer ' + $("#transfer_amount").val() + " ETH to " + target_account + "!");
                    checkBalance();
                }
            }
        )
    }
}

function transactionCheck() {
    coinFlipWeb3.contractInstance.methods.userTransactionArrayCheck().call(
        {
            from: coinFlipWeb3.web3Provider.selectedAddress
        },
        function (error, result) {
            if (error) {
                console.log(error);
            } else {
                if (result.length === 0) {
                    document.getElementById('transaction_history').innerText = "You are a new player! No history for you!"
                } else {
                    result.reverse();
                    // TODO: Only return result within 1 day.
                    result.forEach(addTransactionHistory);
                    function addTransactionHistory(transactionID) {
                        coinFlipWeb3.contractInstance.methods.transactionCheck(
                            parseInt(transactionID)
                        ).call(
                            {
                                from: coinFlipWeb3.web3Provider.selectedAddress
                            },
                            function (error, result) {
                                if (error) {
                                    console.log(error);
                                } else {
                                    console.log(result);
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
                                }
                            }
                        )
                    }
                }
            }
        }
    )
}
