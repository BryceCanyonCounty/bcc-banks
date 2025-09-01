function OpenAccountDetails(account, AccountPage)
    local ok, resp = Feather.RPC.CallAsync('Feather:Banks:GetAccount', {
        account = tostring(account.id),
        lockAccount = true
    })

    if not ok or not resp or not resp.account then
        local msg = (resp and resp.message) and resp.message or "Could not load account."
        Feather.Notify.RightNotify(msg, 4000)
        return
    end

    local acc = resp.account
    local AccountPageDetails = FeatherBankMenu:RegisterPage('account:page:details:' .. acc.id)

    AccountPageDetails:RegisterElement('header', {
        value = 'Account Details',
        slot  = "header"
    })
    AccountPageDetails:RegisterElement('subheader', {
        value = "Select an Option",
        slot  = "header"
    })
    AccountPageDetails:RegisterElement('line', {
        slot = "header",
        style = {}
    })

    AccountPageDetails:RegisterElement('imageboxcontainer', {
        slot = "content",
        items = {
            {
                type = "imagebox",
                index = 201,
                data = {
                    img = "nui://feather-banks/ui/images/money_moneystack.png",
                    label = "$" .. acc.cash,
                    tooltip = "Cash balance",
                    style = { margin = "6px" },
                    disabled = true
                }
            },
            {
                type = "imagebox",
                index = 202,
                data = {
                    img = "nui://feather-banks/ui/images/provision_goldbar_small.png",
                    label = tostring(acc.gold) .. " g",
                    tooltip = "Gold balance",
                    style = { margin = "6px" },
                    disabled = true
                }
            }
        }
    })

    AccountPageDetails:RegisterElement('line', {
        style = {}
    })

    AccountPageDetails:RegisterElement('button', {
        label = "Deposit",
        style = {}
    }, function()
        OpenWithdrawDepositPage(acc, "deposit", AccountPageDetails)
    end)

    AccountPageDetails:RegisterElement('button', {
        label = "Withdraw",
        style = {}
    }, function()
        OpenWithdrawDepositPage(acc, "withdraw", AccountPageDetails)
    end)

    AccountPageDetails:RegisterElement('button', {
        label = "View Transactions",
        style = {}
    }, function()
        OpenTransactionsPage(acc, AccountPageDetails)
    end)

    AccountPageDetails:RegisterElement('button', {
        label = "Give / Remove Access",
        slot = "content",
    }, function()
        OpenAccessMenu(account, AccountPageDetails)
    end)

    AccountPageDetails:RegisterElement('line', {
        slot = "footer",
        style = {}
    })

    AccountPageDetails:RegisterElement('button', {
        label = "Back",
        slot  = "footer",
        style = {}
    }, function()
        AccountPage:RouteTo()
        -- Optional: unlock on back
        -- Feather.RPC.Notify('Feather:Banks:UnlockAccount', { account = tostring(acc.id) })
    end)
    AccountPageDetails:RegisterElement('bottomline', {
        slot = "footer",
        style = {}
    })

    local html = [[
        <div style="padding:30px; text-align:left;">
            <div><b>id:</b> ]] .. acc.id .. [[</div>
            <div><b>Account number</b> ]] .. acc.account_number .. [[</div>
            <div><b>Name:</b> ]] .. acc.name .. [[</div>
            <div><b>Bank Id:</b> ]] .. acc.bank_id .. [[</div>
        </div>
    ]]

    AccountPageDetails:RegisterElement("html", {
        value = { html },
        slot = "footer"
    })

    FeatherBankMenu:Open({ startupPage = AccountPageDetails })
end

function OpenCreateAccountPage(bank, AccountPage)
    local CreateAccountPage = FeatherBankMenu:RegisterPage('create:account:page')

    CreateAccountPage:RegisterElement('header', {
        value = 'Create New Account',
        slot = "header"
    })

    CreateAccountPage:RegisterElement('input', {
        label       = "Account Name",
        placeholder = "Enter account name",
        style       = {}
    }, function(data)
        CreateAccountPage.accountName = data.value
    end)

    CreateAccountPage:RegisterElement('line', {
        slot = "footer",
        style = {}
    })

    CreateAccountPage:RegisterElement('button', {
        label = "Confirm",
        slot = "footer",
        style = {}
    }, function()
        if CreateAccountPage.accountName and CreateAccountPage.accountName ~= "" then
            local data = { name = CreateAccountPage.accountName, bank = bank.id }
            print("Sending data to server:", json.encode(data))
            Feather.RPC.CallAsync('Feather:Banks:CreateAccount', data)
            Feather.Notify.RightNotify("Account created: " .. CreateAccountPage.accountName, 4000)
            OpenUI(bank)
        else
            Feather.Notify.RightNotify("Please enter a valid account name", 4000)
        end
    end)

    CreateAccountPage:RegisterElement('button', {
        label = "Back",
        slot  = "footer",
        style = {}
    }, function()
        AccountPage:RouteTo()
    end)

    CreateAccountPage:RegisterElement('line', {
        slot = "footer", style = {}
    })

    FeatherBankMenu:Open({ startupPage = CreateAccountPage })
end

function OpenAccountsListPage(bank, ParentPage)
    local Page = FeatherBankMenu:RegisterPage('bank:page:accounts:' .. tostring(bank.id))

    Page:RegisterElement('header', {
        value = 'Bank Accounts',
        slot = "header"
    })
    Page:RegisterElement('subheader', {
        value = "Select an Account",
        slot = "header"
    })
    Page:RegisterElement('line', {
        slot = "header",
        style = {}
    })

    local ok, accounts = Feather.RPC.CallAsync('Feather:Banks:GetAccounts', { bank = bank.id })
    print("Accounts fetched from server:", json.encode(accounts))

    if not ok or not accounts or #accounts == 0 then
        TextDisplay = Page:RegisterElement('textdisplay', {
            value = "No accounts found for this bank.",
            slot = "content"
        })
    else
        for _, account in ipairs(accounts) do
            Page:RegisterElement('button', {
                label = account.account_name,
                style = {}
            }, function()
                OpenAccountDetails(account, Page)
            end)
        end
    end

    Page:RegisterElement('line', {
        slot = "footer",
        style = {}
    })

    Page:RegisterElement('button', {
        label = "Create New Account",
        slot = "footer",
        style = {}
    }, function()
        OpenCreateAccountPage(bank, Page)
    end)

    Page:RegisterElement('button', {
        label = "Back",
        slot  = "footer",
        style = {}
    }, function()
        ParentPage:RouteTo()
    end)
    Page:RegisterElement('bottomline', {
        slot = "footer",
        style = {}
    })

    FeatherBankMenu:Open({ startupPage = Page })
end
