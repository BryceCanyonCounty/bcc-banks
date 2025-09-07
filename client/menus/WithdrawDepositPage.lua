function OpenWithdrawDepositPage(account, actionType, parentPage)
    local pageName = actionType .. ":cash_gold:" .. account.id
    local WithdrawDepositPage = FeatherBankMenu:RegisterPage(pageName)

    local titles = {
        deposit  = _U("deposit_title"),
        withdraw = _U("withdraw_title")
    }

    local headerTitle = titles[actionType] or _U("transaction_title")

    WithdrawDepositPage:RegisterElement("header", {
        value = headerTitle .. " " .. _U("cash_gold_header"),
        slot  = "header"
    })

    local cashValue = ''
    WithdrawDepositPage:RegisterElement("input", {
        label       = _U("cash_amount_label"),
        placeholder = _U("cash_amount_placeholder"),
        style       = {}
    }, function(data)
        cashValue = data.value
    end)

    WithdrawDepositPage:RegisterElement("button", {
        label = headerTitle .. " " .. _U("cash_button"),
        style = {}
    }, function()
        local cashAmt = tonumber(cashValue)
        if not cashAmt or cashAmt <= 0 then
            Notify(_U("invalid_cash_amount"), 4000)
            return
        end

        if actionType == "deposit" then
            BccUtils.RPC:CallAsync("Feather:Banks:DepositCash", {
                account     = account.id,
                amount      = cashAmt,
                description = _U("deposit_cash_description")
            })
        else
            BccUtils.RPC:CallAsync("Feather:Banks:WithdrawCash", {
                account     = account.id,
                amount      = cashAmt,
                description = _U("withdraw_cash_description")
            })
        end

        FeatherBankMenu:Close()
        OpenWithdrawDepositPage(account, actionType, parentPage)
    end)

    -- Separator under header, consistent with other menus
    WithdrawDepositPage:RegisterElement("line", {
        slot  = "header",
        style = {}
    })

    local goldValue = ''
    WithdrawDepositPage:RegisterElement("input", {
        label       = _U("gold_amount_label"),
        placeholder = _U("gold_amount_placeholder"),
        style       = {}
    }, function(data)
        goldValue = data.value
    end)

    WithdrawDepositPage:RegisterElement("button", {
        label = headerTitle .. " " .. _U("gold_button"),
        style = {}
    }, function()
        local goldAmt = tonumber(goldValue)
        if not goldAmt or goldAmt <= 0 then
            Notify(_U("invalid_gold_amount"), 4000)
            return
        end

        if actionType == "deposit" then
            BccUtils.RPC:CallAsync("Feather:Banks:DepositGold", {
                account     = account.id,
                amount      = goldAmt,
                description = _U("deposit_gold_description")
            })
        else
            BccUtils.RPC:CallAsync("Feather:Banks:WithdrawGold", {
                account     = account.id,
                amount      = goldAmt,
                description = _U("withdraw_gold_description")
            })
        end

        FeatherBankMenu:Close()
        OpenWithdrawDepositPage(account, actionType, parentPage)
    end)

    WithdrawDepositPage:RegisterElement("line", {
        slot  = "footer",
        style = {}
    })

    WithdrawDepositPage:RegisterElement("button", {
        label = _U("back_button"),
        slot  = "footer",
        style = {}
    }, function()
        parentPage:RouteTo()
    end)

    WithdrawDepositPage:RegisterElement("bottomline", {
        slot  = "footer",
        style = {}
    })

    FeatherBankMenu:Open({ startupPage = WithdrawDepositPage })
end
