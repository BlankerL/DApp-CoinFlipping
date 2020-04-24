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

