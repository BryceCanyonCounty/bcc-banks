function OpenAccountDetails(account, AccountPage)
    local ok, resp = BccUtils.RPC:CallAsync("Feather:Banks:GetAccount", {
        account     = tostring(account.id),
        lockAccount = true
    })

    if not ok or not resp or not resp.account then return end

    local acc = resp.account
    local AccountPageDetails = FeatherBankMenu:RegisterPage("account:page:details:" .. acc.id)

    AccountPageDetails:RegisterElement("header", {
        value = _U("account_details_header"),
        slot  = "header"
    })

    AccountPageDetails:RegisterElement("subheader", {
        value = _U("account_details_subheader"),
        slot  = "header"
    })

    AccountPageDetails:RegisterElement("line", {
        slot  = "header",
        style = {}
    })

    AccountPageDetails:RegisterElement("imageboxcontainer", {
        slot  = "content",
        items = {
            {
                type  = "imagebox",
                index = 201,
                data  = {
                    img      = "nui://bcc-banks/ui/images/money_moneystack.png",
                    label    = "$" .. acc.cash,
                    tooltip  = _U("cash_balance_tooltip"),
                    style    = { margin = "6px" },
                    disabled = false
                }
            },
            {
                type  = "imagebox",
                index = 202,
                data  = {
                    img      = "nui://bcc-banks/ui/images/provision_goldbar_small.png",
                    label    = tostring(acc.gold) .. " g",
                    tooltip  = _U("gold_balance_tooltip"),
                    style    = { margin = "6px" },
                    disabled = false
                }
            }
        }
    })

    AccountPageDetails:RegisterElement("line", {
        slot  = "header",
        style = {}
    })

    AccountPageDetails:RegisterElement("button", {
        label = _U("deposit_button"),
        style = {}
    }, function()
        OpenWithdrawDepositPage(acc, "deposit", AccountPage)
    end)

    AccountPageDetails:RegisterElement("button", {
        label = _U("withdraw_button"),
        style = {}
    }, function()
        OpenWithdrawDepositPage(acc, "withdraw", AccountPage)
    end)

    AccountPageDetails:RegisterElement("button", {
        label = _U("transfer_button"),
        style = {}
    }, function()
        OpenTransferSelectBank(acc, AccountPage)
    end)

    AccountPageDetails:RegisterElement("button", {
        label = _U("view_transactions_button"),
        style = {}
    }, function()
        OpenTransactionsPage(acc, AccountPage)
    end)

    AccountPageDetails:RegisterElement("button", {
        label = _U("manage_access_button"),
        slot  = "content"
    }, function()
        OpenAccessMenu(account, AccountPage)
    end)

    AccountPageDetails:RegisterElement("line", {
        slot  = "footer",
        style = {}
    })

    AccountPageDetails:RegisterElement("button", {
        label = _U("back_button"),
        slot  = "footer",
        style = {}
    }, function()
        -- Reopen the accounts list for this account's bank (avoid RouteTo)
        local bank = { id = acc.bank_id }
        OpenAccountsListPage(bank, AccountPage)
    end)
    
    AccountPageDetails:RegisterElement("bottomline", {
        slot  = "footer",
        style = {}
    })

    local html = [[
        <div style="padding:30px; text-align:left;">
            <div><b>]] .. _U("account_id_label") .. [[</b> ]] .. acc.id .. [[</div>
            <div><b>]] .. _U("account_number_label") .. [[</b> ]] .. acc.account_number .. [[</div>
            <div><b>]] .. _U("account_name_label") .. [[</b> ]] .. acc.name .. [[</div>
            <div><b>]] .. _U("bank_id_label") .. [[</b> ]] .. acc.bank_id .. [[</div>
        </div>
    ]]

    AccountPageDetails:RegisterElement("html", {
        value = { html },
        slot  = "footer"
    })

    FeatherBankMenu:Open({ startupPage = AccountPageDetails })
end

function OpenTransferPage(account, ParentPage)
    local TransferPage = FeatherBankMenu:RegisterPage('account:page:transfer:' .. tostring(account.id))

    TransferPage:RegisterElement('header', {
        value = _U('transfer_header'),
        slot  = 'header'
    })
    TransferPage:RegisterElement('subheader', {
        value = _U('transaction_title'),
        slot  = 'header'
    })
    TransferPage:RegisterElement('line', {
        slot  = 'header',
        style = {}
    })

    local destNumber, amountValue, descValue = '', '', ''

    TransferPage:RegisterElement('input', {
        label = _U('destination_account_label'),
        placeholder = _U('destination_account_placeholder'),
        style = {}
    }, function(data)
        destNumber = data.value
    end)

    TransferPage:RegisterElement('input', {
        label = _U('transfer_amount_label'),
        placeholder = _U('cash_amount_placeholder'),
        style = {}
    }, function(data)
        amountValue = data.value
    end)

    TransferPage:RegisterElement('input', {
        label = _U('transfer_description_label'),
        placeholder = _U('transaction_title'),
        style = {}
    }, function(data)
        descValue = data.value
    end)

    -- Optional helper text
    local feePercent = (Config and Config.Transfer and Config.Transfer.CrossBankFeePercent) or 0.0
    TransferPage:RegisterElement('textdisplay', {
        value = _U('transfer_fee_note', tostring(feePercent)),
        slot = 'content'
    })

    TransferPage:RegisterElement('button', {
        label = _U('transfer_confirm_button'),
        style = {}
    }, function()
        local amt = tonumber(amountValue)
        if not amt or amt <= 0 then
            Notify(_U('invalid_cash_amount'), 4000)
            return
        end
        local ok, resp = BccUtils.RPC:CallAsync('Feather:Banks:TransferCash', {
            fromAccount = account.id,
            toAccountNumber = destNumber,
            amount = amt,
            description = descValue
        })
        if ok then
            Notify(_U('success_transfer', tostring(amt)), 4000)
            -- Refresh details
            OpenAccountDetails(account, ParentPage)
        end
    end)

    TransferPage:RegisterElement('line', { slot = 'footer', style = {} })
    TransferPage:RegisterElement('button', {
        label = _U('back_button'),
        slot  = 'footer',
        style = {}
    }, function()
        ParentPage:RouteTo()
    end)
    TransferPage:RegisterElement('bottomline', { slot = 'footer', style = {} })

    FeatherBankMenu:Open({ startupPage = TransferPage })
end

function OpenTransferSelectBank(account, ParentPage)
    local SelectBankTransferPage = FeatherBankMenu:RegisterPage('account:page:transfer:selectbank:' .. tostring(account.id))
    SelectBankTransferPage:RegisterElement('header', {
        value = _U('transfer_header'),
        slot  = 'header'
    })
    SelectBankTransferPage:RegisterElement('subheader', {
        value = _U('bank_accounts_header'),
        slot  = 'header'
    })
    SelectBankTransferPage:RegisterElement('line', {
        slot  = 'header',
        style = {}
    })

    local ok, banks = BccUtils.RPC:CallAsync('Feather:Banks:GetBanks', {})
    -- Normalize return shape: some RPCs return (data) instead of (ok, data)
    if type(ok) == 'table' and banks == nil then
        banks = ok
        ok = true
    end
    devPrint('Transfer SelectBank: ok=', ok, 'banks_count=', (banks and #banks) or 0)
    if not ok or not banks or #banks == 0 then
        SelectBankTransferPage:RegisterElement('textdisplay', {
            value = _U('no_accounts_found'),
            slot  = 'content'
        })
    else
        for _, bank in ipairs(banks) do
            SelectBankTransferPage:RegisterElement('button', {
                label = bank.name,
                style = {}
            }, function()
                OpenTransferSelectAccount(account, bank, SelectBankTransferPage)
            end)
        end
    end

    SelectBankTransferPage:RegisterElement('line', {
        slot  = 'footer',
        style = {}
    })
    SelectBankTransferPage:RegisterElement('button', {
        label = _U('back_button'),
        slot  = 'footer',
        style = {}
    }, function()
        ParentPage:RouteTo()
    end)
    SelectBankTransferPage:RegisterElement('bottomline', {
        slot  = 'footer',
        style = {}
    })
    FeatherBankMenu:Open({ startupPage = SelectBankTransferPage })
end

function OpenTransferSelectAccount(account, bank, ParentPage)
    local SelectAccountTransferPage = FeatherBankMenu:RegisterPage('account:page:transfer:selectacc:' .. tostring(account.id) .. ':' .. tostring(bank.id))
    SelectAccountTransferPage:RegisterElement('header', {
        value = bank.name,
        slot  = 'header'
    })
    SelectAccountTransferPage:RegisterElement('subheader', {
        value = _U('select_account_header'),
        slot  = 'header'
    })
    SelectAccountTransferPage:RegisterElement('line', {
        slot  = 'header',
        style = {}
    })

    -- List only YOUR accounts at the selected bank
    local ok, accounts = BccUtils.RPC:CallAsync('Feather:Banks:GetAccounts', { bank = bank.id })
    devPrint('Transfer SelectAccount (mine-only): bank=', bank.id, 'ok=', ok, 'accounts_count=', accounts and #accounts or 0)
    if not ok or not accounts or #accounts == 0 then
        SelectAccountTransferPage:RegisterElement('textdisplay', {
            value = _U('no_accounts_found'),
            slot  = 'content'
        })
    else
        for _, acc in ipairs(accounts) do
            local label = (acc.account_name or acc.name or ('#' .. tostring(acc.id)))
            SelectAccountTransferPage:RegisterElement('button', {
                label = label,
                style = {}
            }, function()
                OpenTransferForm(account, acc, SelectAccountTransferPage)
            end)
        end
    end

    -- Optional path: enter a destination account number manually
    SelectAccountTransferPage:RegisterElement('line', { slot = 'content', style = {} })
    SelectAccountTransferPage:RegisterElement('button', {
        label = _U('transfer_enter_number_button'),
        style = {}
    }, function()
        OpenTransferPage(account, SelectAccountTransferPage)
    end)

    SelectAccountTransferPage:RegisterElement('line', { slot = 'footer', style = {} })
    SelectAccountTransferPage:RegisterElement('button', {
        label = _U('back_button'),
        slot  = 'footer',
        style = {}
    }, function()
        ParentPage:RouteTo()
    end)
    SelectAccountTransferPage:RegisterElement('bottomline', { slot = 'footer', style = {} })
    FeatherBankMenu:Open({ startupPage = SelectAccountTransferPage })
end

function OpenTransferForm(fromAccount, toAccount, ParentPage)
    local TransferFormPage = FeatherBankMenu:RegisterPage('account:page:transfer:form:' .. tostring(fromAccount.id) .. ':' .. tostring(toAccount.id))
    TransferFormPage:RegisterElement('header', {
        value = _U('transfer_header'),
        slot  = 'header'
    })
    local accnum = tostring(toAccount.account_number or '')
    local subtext = (toAccount.account_name or toAccount.name or ("#" .. tostring(toAccount.id)))
    if accnum ~= '' then
        local tail = string.sub(accnum, math.max(1, #accnum - 5))
        subtext = subtext .. ' (' .. tail .. ')'
    end
    TransferFormPage:RegisterElement('subheader', {
        value = subtext,
        slot  = 'header'
    })
    TransferFormPage:RegisterElement('line', {
        slot  = 'header',
        style = {}
    })

    local amountValue, descValue = '', ''

    TransferFormPage:RegisterElement('input', { label = _U('transfer_amount_label'), placeholder = _U('cash_amount_placeholder'), style = {} }, function(data)
        amountValue = data.value
    end)

    TransferFormPage:RegisterElement('input', { label = _U('transfer_description_label'), placeholder = _U('transaction_title'), style = {} }, function(data)
        descValue = data.value
    end)

    local feePercent = (Config and Config.Transfer and Config.Transfer.CrossBankFeePercent) or 0.0
    TransferFormPage:RegisterElement('textdisplay', { value = _U('transfer_fee_note', tostring(feePercent)), slot = 'content' })

    TransferFormPage:RegisterElement('button', {
        label = _U('transfer_confirm_button'),
        style = {}
    }, function()
        local amt = tonumber(amountValue)
        if not amt or amt <= 0 then
            Notify(_U('invalid_cash_amount'), 4000)
            return
        end
        local ok, resp = BccUtils.RPC:CallAsync('Feather:Banks:TransferCash', {
            fromAccount = fromAccount.id,
            toAccountId = toAccount.id,
            amount = amt,
            description = descValue
        })
        if ok then
            Notify(_U('success_transfer', tostring(amt)), 4000)
            OpenAccountDetails(fromAccount, ParentPage)
        end
    end)

    TransferFormPage:RegisterElement('line', { slot = 'footer', style = {} })
    TransferFormPage:RegisterElement('button', {
        label = _U('back_button'),
        slot  = 'footer',
        style = {}
    }, function()
        ParentPage:RouteTo()
    end)
    TransferFormPage:RegisterElement('bottomline', { slot = 'footer', style = {} })
    FeatherBankMenu:Open({ startupPage = TransferFormPage })
end

function OpenCreateAccountPage(bank, AccountPage)
    local CreateAccountPage = FeatherBankMenu:RegisterPage('create:account:page')

    CreateAccountPage:RegisterElement('header', {
        value = _U("create_account_header"),
        slot = "header"
    })

    CreateAccountPage:RegisterElement('input', {
        label       = _U("account_name_label"),
        placeholder = _U("account_name_placeholder"),
        style       = {}
    }, function(data)
        CreateAccountPage.accountName = data.value
    end)

    CreateAccountPage:RegisterElement('line', {
        slot  = "footer",
        style = {}
    })

    CreateAccountPage:RegisterElement('button', {
        label = _U("confirm_button"),
        slot  = "footer",
        style = {}
    }, function()
        if CreateAccountPage.accountName and CreateAccountPage.accountName ~= "" then
            local data = {
                name = CreateAccountPage.accountName,
                bank = bank.id
            }

            devPrint("Sending data to server:", json.encode(data))
            BccUtils.RPC:CallAsync('Feather:Banks:CreateAccount', data)

            OpenUI(bank)
        else
            Notify(_U("invalid_account_name"), 4000)
        end
    end)

    CreateAccountPage:RegisterElement('button', {
        label = _U("back_button"),
        slot  = "footer",
        style = {}
    }, function()
        AccountPage:RouteTo()
    end)

    CreateAccountPage:RegisterElement('line', {
        slot  = "footer",
        style = {}
    })

    FeatherBankMenu:Open({ startupPage = CreateAccountPage })
end

function OpenAccountsListPage(bank, ParentPage)
    local AccountsListPage = FeatherBankMenu:RegisterPage('bank:page:accounts:' .. tostring(bank.id))

    AccountsListPage:RegisterElement('header', {
        value = _U("bank_accounts_header"),
        slot  = "header"
    })

    AccountsListPage:RegisterElement('subheader', {
        value = _U("bank_accounts_subheader"),
        slot  = "header"
    })

    AccountsListPage:RegisterElement('line', {
        slot  = "header",
        style = {}
    })

    local ok, accounts = BccUtils.RPC:CallAsync('Feather:Banks:GetAccounts', { bank = bank.id })

    devPrint("Accounts fetched from server:", json.encode(accounts))

    if not ok or not accounts or #accounts == 0 then
        AccountsListPage:RegisterElement('textdisplay', {
            value = _U("no_accounts_found"),
            slot  = "content"
        })
    else
        for _, account in ipairs(accounts) do
            AccountsListPage:RegisterElement('button', {
                label = account.account_name,
                style = {}
            }, function()
                OpenAccountDetails(account, AccountsListPage)
            end)
        end
    end

    AccountsListPage:RegisterElement('line', {
        slot  = "footer",
        style = {}
    })

    AccountsListPage:RegisterElement('button', {
        label = _U("create_account_button"),
        slot  = "footer",
        style = {}
    }, function()
        OpenCreateAccountPage(bank, AccountsListPage)
    end)

    AccountsListPage:RegisterElement('button', {
        label = _U("back_button"),
        slot  = "footer",
        style = {}
    }, function()
        OpenUI(bank)
    end)

    AccountsListPage:RegisterElement('bottomline', {
        slot  = "footer",
        style = {}
    })

    FeatherBankMenu:Open({ startupPage = AccountsListPage })
end
