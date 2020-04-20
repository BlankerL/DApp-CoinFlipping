function refreshBalance() {
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

$("#button_register_account").click(
    function (e) {
        e.preventDefault();
        coinFlipWeb3.contractInstance.methods.createAccount(
            $("#account_id").val()
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
)

$("#button_deposit").click(
    function (e) {
        e.preventDefault();
        coinFlipWeb3.contractInstance.methods.deposit().send(
            {
                from: coinFlipWeb3.web3Provider.selectedAddress,
                value: parseFloat($("#deposit_amount").val()) * 1e+18
            },
            function (error, result) {
                if (error) {
                    console.log(error);
                } else {
                    refreshBalance()
                }
            }
        )
    }
)

$("#button_withdraw").click(
    function (e) {
        e.preventDefault();
        coinFlipWeb3.contractInstance.methods.withdraw(
            web3.utils.toWei($("#withdraw_amount").val(), 'ether')
        ).send(
            {
                from: coinFlipWeb3.web3Provider.selectedAddress
            },
            function (error, result) {
                if (error) {
                    console.log();
                } else {
                    refreshBalance();
                }
            }
        )
    }
)

$("#button_transfer").click(
    function (e) {
        e.preventDefault();
        const target_account = $("#transfer_target").val()
        console.log(target_account.substring(0, 2));
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
                        refreshBalance();
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
                        refreshBalance();
                    }
                }
            )
        }
    }
)
