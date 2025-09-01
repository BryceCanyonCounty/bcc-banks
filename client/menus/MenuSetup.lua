FeatherMenu = exports['feather-menu'].initiate()
FeatherBankMenu = FeatherMenu:RegisterMenu('feather:bank:menu', {
    top = '3%',
    left = '3%',
    ['720width'] = '400px',
    ['1080width'] = '500px',
    ['2kwidth'] = '600px',
    ['4kwidth'] = '800px',
    style = {},
    contentslot = {
        style = {
            ['height'] = '450px',
            ['min-height'] = '350px'
        }
    },
    draggable = true,
    canclose = true
}, {
    opened = function()
        DisplayRadar(false)
    end,
    closed = function()
        DisplayRadar(true)
    end
})

function OpenUI(bank)
    if Feather.RPC.CallAsync('Feather:Banks:GetBankerBusy', { bank = bank.id }) then
        Feather.Notify.RightNotify("Banker is currently busy. Please wait.", 4000)
        return
    end

    local MainPage = FeatherBankMenu:RegisterPage('bank:page:hub:' .. tostring(bank.id))

    MainPage:RegisterElement('header', {
        value = 'Banking',
        slot = "header"
    })
    MainPage:RegisterElement('subheader', {
        value = "Select a Service",
        slot = "header"
    })
    MainPage:RegisterElement('line', {
        slot = "header",
        style = {}
    })

    MainPage:RegisterElement('button', {
        label = "Accounts",
        style = {}
    }, function()
        OpenAccountsListPage(bank, MainPage)
    end)

    MainPage:RegisterElement('button', {
        label = "Safety Deposit Box",
        style = {}
    }, function()
        OpenSDBListPage(bank, MainPage)
    end)

    MainPage:RegisterElement('button', {
        label = "Gold — Buy / Sell / Exchange",
        style = {}
    }, function()
        OpenGoldExchangePage(bank, MainPage)
    end)

    MainPage:RegisterElement('button', {
        label = "Loans",
        style = {}
    }, function()
        OpenLoansBankPage(bank, MainPage)
    end)

    MainPage:RegisterElement('line', {
        slot = "footer",
        style = {}
    })
    MainPage:RegisterElement('button', {
        label = "Exit",
        slot  = "footer",
        style = {}
    }, function()
        FeatherBankMenu:Close()
        -- Optionally clear busy on exit:
        -- Feather.RPC.Notify('Feather:Banks:SetBankerBusy', { bank = bank.id, busy = false })
    end)
    MainPage:RegisterElement('bottomline', {
        slot = "footer",
        style = {}
    })

    FeatherBankMenu:Open({ startupPage = MainPage })
    Feather.RPC.Notify('Feather:Banks:SetBankerBusy', { bank = bank.id })
end

function OpenTransactionsPage(acc, ParentPage)
    print("[BANK DEBUG] Opening transactions page for account ID:", acc.id)

    local TransactionPage = FeatherBankMenu:RegisterPage('account:page:transactions:' .. tostring(acc.id))

    TransactionPage:RegisterElement('header', {
        value = 'Transactions',
        slot = 'header'
    })
    TransactionPage:RegisterElement('subheader', {
        value = 'Recent activity for account #' .. tostring(acc.id),
        slot = 'header'
    })
    TransactionPage:RegisterElement('line', {
        slot = 'header',
        style = {}
    })

    local ok, data = Feather.RPC.CallAsync('Feather:Banks:GetTransactions', { account = tonumber(acc.id) })
    print("[BANK DEBUG] RPC call status:", ok)

    if not ok then
        local msg = (data and data.message) and data.message or 'Failed to fetch transactions.'
        print("[BANK DEBUG] RPC failed:", msg)
        Feather.Notify.RightNotify(msg, 4000)
        return
    end

    data = data or {}

    print("[BANK DEBUG] Transactions returned:", #data)
    if data[1] then
        print("[BANK DEBUG] First transaction sample:", json.encode(data[1]))
    end

    if #data == 0 then
        TransactionPage:RegisterElement('textdisplay', {
            value = "No transactions found.",
            slot = "content"
        })
    else
        local html = [[
            <div style="padding:8px;">
              <table style="width:100%; border-collapse:collapse;">
                <thead>
                  <tr>
                    <th style="text-align:left; padding:6px 4px;">ID</th>
                    <th style="text-align:left; padding:6px 4px;">When</th>
                    <th style="text-align:left; padding:6px 4px;">By</th>
                    <th style="text-align:left; padding:6px 4px;">Type</th>
                    <th style="text-align:right; padding:6px 4px;">Amount</th>
                    <th style="text-align:left; padding:6px 4px;">Description</th>
                  </tr>
                </thead>
                <tbody>
        ]]

        for i = 1, #data do
            local t = data[i]
            local id = tostring(t.id or "")
            local when = tostring(t.created_at or "")
            local by = t.character_name or "-"
            local typ = t.type or ""
            local amount = tostring(t.amount or "")
            local desc = t.description or ""

            html = html ..
                "<tr>" ..
                "<td style='padding:6px 4px;'>" .. id .. "</td>" ..
                "<td style='padding:6px 4px;'>" .. when .. "</td>" ..
                "<td style='padding:6px 4px;'>" .. by .. "</td>" ..
                "<td style='padding:6px 4px;'>" .. typ .. "</td>" ..
                "<td style='padding:6px 4px; text-align:right;'>" .. amount .. "</td>" ..
                "<td style='padding:6px 4px;'>" .. desc .. "</td>" ..
                "</tr>"
        end

        html = html .. "</tbody></table></div>"

        TransactionPage:RegisterElement('html', {
            value = { html }
        })
    end

    TransactionPage:RegisterElement('line', {
        slot = "footer",
        style = {}
    })
    TransactionPage:RegisterElement('button', {
        label = "Back",
        slot = "footer",
        style = {}
    }, function()
        ParentPage:RouteTo()
    end)
    TransactionPage:RegisterElement('bottomline', {
        slot = "footer",
        style = {}
    })

    FeatherBankMenu:Open({ startupPage = TransactionPage })
end

function OpenLoansBankPage(bank, ParentPage)
    local Page = FeatherBankMenu:RegisterPage('bank:page:loans:' .. tostring(bank.id))

    Page:RegisterElement('header', {
        value = 'Loans',
        slot = 'header'
    })
    Page:RegisterElement('subheader', {
        value = 'Manage Loans',
        slot = 'header'
    })
    Page:RegisterElement('line', {
        slot = 'header',
        style = {}
    })

    Page:RegisterElement('button', {
        label = "Apply for Loan",
        style = {}
    }, function()
        Feather.Notify.RightNotify("TODO: Implement Apply for Loan", 3000)
    end)

    Page:RegisterElement('button', {
        label = "Repay Loan",
        style = {}
    }, function()
        Feather.Notify.RightNotify("TODO: Implement Repay Loan", 3000)
    end)

    Page:RegisterElement('line', {
        slot = "footer",
        style = {}
    })
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