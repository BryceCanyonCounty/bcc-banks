function OpenWithdrawDepositPage(account, actionType, parentPage)
    local pageName = actionType .. ":cash_gold:" .. account.id
    local WithdrawDepositPage = FeatherBankMenu:RegisterPage(pageName)

    local titles = {
        deposit = "Deposit",
        withdraw = "Withdraw"
    }
    local headerTitle = titles[actionType] or "Transaction"

    WithdrawDepositPage:RegisterElement('header', {
        value = headerTitle .. " Cash / Gold",
        slot  = "header"
    })

    local cashValue = ''
    WithdrawDepositPage:RegisterElement('input', {
        label       = "Cash Amount",
        placeholder = "Enter cash amount",
        style       = {}
    }, function(data)
        cashValue = data.value
    end)

    WithdrawDepositPage:RegisterElement('button', {
        label = headerTitle .. " Cash",
        style = {}
    }, function()
        local cashAmt = tonumber(cashValue)
        if not cashAmt or cashAmt <= 0 then
            Feather.Notify.RightNotify("Enter a valid cash amount.", 4000)
            return
        end

        if actionType == "deposit" then
            Feather.RPC.CallAsync("Feather:Banks:DepositCash", {
                account     = account.id,
                amount      = cashAmt,
                description = "Player deposit - cash"
            })
        else
            Feather.RPC.CallAsync("Feather:Banks:WithdrawCash", {
                account     = account.id,
                amount      = cashAmt,
                description = "Player withdraw - cash"
            })
        end
        FeatherBankMenu:Close()
        OpenWithdrawDepositPage(account, actionType, parentPage)
    end)

    WithdrawDepositPage:RegisterElement('line', {
        style = {}
    })

    local goldValue = ''
    WithdrawDepositPage:RegisterElement('input', {
        label       = "Gold Amount",
        placeholder = "Enter gold amount",
        style       = {}
    }, function(data)
        goldValue = data.value
    end)

    WithdrawDepositPage:RegisterElement('button', {
        label = headerTitle .. " Gold",
        style = {}
    }, function()
        local goldAmt = tonumber(goldValue)
        if not goldAmt or goldAmt <= 0 then
            Feather.Notify.RightNotify("Enter a valid gold amount.", 4000)
            return
        end

        if actionType == "deposit" then
            Feather.RPC.CallAsync("Feather:Banks:DepositGold", {
                account     = account.id,
                amount      = goldAmt,
                description = "Player deposit - gold"
            })
        else
            Feather.RPC.CallAsync("Feather:Banks:WithdrawGold", {
                account     = account.id,
                amount      = goldAmt,
                description = "Player withdraw - gold"
            })
        end

        FeatherBankMenu:Close()
        OpenWithdrawDepositPage(account, actionType, parentPage)
    end)

    WithdrawDepositPage:RegisterElement('line', {
        slot = "footer",
        style = {}
    })

    WithdrawDepositPage:RegisterElement('button', {
        label = "Back",
        slot  = "footer",
        style = {}
    }, function()
        parentPage:RouteTo()
    end)

    WithdrawDepositPage:RegisterElement('bottomline', {
        slot = "footer",
        style = {}
    })

    FeatherBankMenu:Open({ startupPage = WithdrawDepositPage })
end
