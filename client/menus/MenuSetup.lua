function OpenUI(bank)
    if BccUtils.RPC:CallAsync('Feather:Banks:GetBankerBusy', { bank = bank.id }) then
        Notify(_U("banker_busy_notify"), 4000)
        return
    end
    local MainPage = FeatherBankMenu:RegisterPage('bank:page:hub:' .. tostring(bank.id))
    MainPage:RegisterElement('header', {
        value = _U("banking_header"),
        slot = "header"
    })
    MainPage:RegisterElement('subheader', {
        value = _U("banking_subheader"),
        slot = "header"
    })
    MainPage:RegisterElement('line', {
        slot = "header",
        style = {}
    })
    MainPage:RegisterElement('button', {
        label = _U("accounts_button"),
        style = {}
    }, function()
        OpenAccountsListPage(bank, MainPage)
    end)
    MainPage:RegisterElement('button', {
        label = _U("safety_deposit_box_button"),
        style = {}
    }, function()
        OpenSDBListPage(bank, MainPage)
    end)
    MainPage:RegisterElement('button', {
        label = _U("gold_exchange_button"),
        style = {}
    }, function()
        OpenGoldExchangePage(bank, MainPage)
    end)
    MainPage:RegisterElement('button', {
        label = _U("loans_button"),
        style = {}
    }, function()
        OpenLoansBankPage(bank, MainPage)
    end)
    MainPage:RegisterElement('line', {
        slot = "footer",
        style = {}
    })
    MainPage:RegisterElement('button', {
        label = _U("exit_button"),
        slot  = "footer",
        style = {}
    }, function()
        FeatherBankMenu:Close()
    end)
    MainPage:RegisterElement('bottomline', {
        slot = "footer",
        style = {}
    })
    FeatherBankMenu:Open({ startupPage = MainPage })
    BccUtils.RPC:Notify('Feather:Banks:SetBankerBusy', { bank = bank.id })
end

function OpenTransactionsPage(acc, ParentPage)
    devPrint("Opening transactions page for account ID:", acc.id)
    local TransactionPage = FeatherBankMenu:RegisterPage('account:page:transactions:' .. tostring(acc.id))
    TransactionPage:RegisterElement('header', {
        value = _U("transactions_header"),
        slot = 'header'
    })
    TransactionPage:RegisterElement('subheader', {
        value = _U("transactions_subheader", tostring(acc.id)),
        slot = 'header'
    })
    TransactionPage:RegisterElement('line', {
        slot = 'header',
        style = {}
    })
    local ok, data = BccUtils.RPC:CallAsync('Feather:Banks:GetTransactions', { account = tonumber(acc.id) })
    devPrint("RPC call status:", ok)
    if not ok then
        local msg = (data and data.message) and data.message or _U("failed_fetch_transactions")
        devPrint("RPC failed:", msg)
        Notify(msg, 4000)
        return
    end
    data = data or {}
    devPrint("Transactions returned:", #data)
    if data[1] then
        devPrint("First transaction sample:", json.encode(data[1]))
    end
    if #data == 0 then
        TransactionPage:RegisterElement('textdisplay', {
            value = _U("no_transactions_found"),
            slot = "content"
        })
    else
        local function badgeColor(tp)
            if not tp then return '#666' end
            if string.find(tp, 'deposit', 1, true) then return '#1e7e34' end
            if string.find(tp, 'withdraw', 1, true) then return '#b02a37' end
            if string.find(tp, 'transfer - out', 1, true) then return '#b76e00' end
            if string.find(tp, 'transfer - in', 1, true) then return '#0d6efd' end
            if string.find(tp, 'fee', 1, true) then return '#6c757d' end
            if string.find(tp, 'loan', 1, true) then return '#6610f2' end
            return '#495057'
        end
        local html = [[
            <div style="padding:10px;">
              <table style="width:100%; border-collapse:collapse; font-size:14px;">
                <thead>
                  <tr style="background:#f1f3f5; color:#212529;">
                    <th style="text-align:left; padding:8px 6px; width:10%">]] .. _U("transaction_id") .. [[</th>
                    <th style="text-align:left; padding:8px 6px; width:18%">]] .. _U("transaction_when") .. [[</th>
                    <th style="text-align:left; padding:8px 6px; width:18%">]] .. _U("transaction_by") .. [[</th>
                    <th style="text-align:left; padding:8px 6px; width:18%">]] .. _U("transaction_type") .. [[</th>
                    <th style="text-align:right; padding:8px 6px; width:18%">]] .. _U("transaction_amount") .. [[</th>
                    <th style="text-align:left; padding:8px 6px;">]] .. _U("transaction_description") .. [[</th>
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
            local badge = "<span style='display:inline-block; padding:2px 6px; border-radius:12px; background:" .. badgeColor(typ) .. "; color:#fff;'>" .. typ .. "</span>"
            html = html ..
                "<tr style='border-bottom:1px solid #dee2e6;'>" ..
                "<td style='padding:8px 6px;'>" .. id .. "</td>" ..
                "<td style='padding:8px 6px;'>" .. when .. "</td>" ..
                "<td style='padding:8px 6px;'>" .. by .. "</td>" ..
                "<td style='padding:8px 6px;'>" .. badge .. "</td>" ..
                "<td style='padding:8px 6px; text-align:right;'>$" .. amount .. "</td>" ..
                "<td style='padding:8px 6px;'>" .. desc .. "</td>" ..
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
        label = _U("back_button"),
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
    local LoansBankPage = FeatherBankMenu:RegisterPage('bank:page:loans:' .. tostring(bank.id))
    LoansBankPage:RegisterElement('header', {
        value = _U("loans_header"),
        slot = 'header'
    })
    LoansBankPage:RegisterElement('subheader', {
        value = _U("loans_subheader"),
        slot = 'header'
    })
    LoansBankPage:RegisterElement('line', { slot = 'header', style = {} })

    LoansBankPage:RegisterElement('button', {
        label = _U("apply_loan_button"),
        style = {}
    }, function()
        -- Apply directly: create a dedicated account automatically on server
        OpenLoanApplyForm_NoAccount(bank, LoansBankPage)
    end)

    -- New: list loans button (directly shows your loans at this bank)
    LoansBankPage:RegisterElement('button', {
        label = _U("view_loans_button"),
        style = {}
    }, function()
        OpenLoansListPage_NoAccount(bank, LoansBankPage)
    end)

    LoansBankPage:RegisterElement('button', {
        label = _U("repay_loan_button"),
        style = {}
    }, function()
        OpenLoansListPage_NoAccount(bank, LoansBankPage)
    end)

    LoansBankPage:RegisterElement('line', { slot = "footer", style = {} })
    LoansBankPage:RegisterElement('button', {
        label = _U("back_button"),
        slot  = "footer",
        style = {}
    }, function()
        ParentPage:RouteTo()
    end)
    LoansBankPage:RegisterElement('bottomline', {
        slot  = 'footer',
        style = {}
    })
    FeatherBankMenu:Open({ startupPage = LoansBankPage })
end

function OpenLoanApplyAccountSelect(bank, ParentPage)
    local LoanApplySelectAccountPage = FeatherBankMenu:RegisterPage('bank:page:loans:apply:select:' .. tostring(bank.id))
    LoanApplySelectAccountPage:RegisterElement('header', {
        value = _U('select_account_header'),
        slot  = 'header'
    })
    LoanApplySelectAccountPage:RegisterElement('subheader', {
        value = _U('select_account_subheader'),
        slot  = 'header'
    })
    LoanApplySelectAccountPage:RegisterElement('line', { slot = 'header', style = {} })

    local ok, accounts = BccUtils.RPC:CallAsync('Feather:Banks:GetAccounts', { bank = bank.id })
    if not ok or not accounts or #accounts == 0 then
        LoanApplySelectAccountPage:RegisterElement('textdisplay', {
            value = _U('no_accounts_found'),
            slot  = 'content'
        })
    else
        for _, account in ipairs(accounts) do
            LoanApplySelectAccountPage:RegisterElement('button', {
                label = account.account_name,
                style = {}
            }, function()
                OpenLoanApplyForm(account, bank, LoanApplySelectAccountPage)
            end)
        end
    end

    LoanApplySelectAccountPage:RegisterElement('line', { slot = 'footer', style = {} })
    LoanApplySelectAccountPage:RegisterElement('button', {
        label = _U('back_button'),
        slot  = 'footer',
        style = {}
    }, function()
        ParentPage:RouteTo()
    end)
    LoanApplySelectAccountPage:RegisterElement('bottomline', {
        slot  = 'footer',
        style = {}
    })
    FeatherBankMenu:Open({ startupPage = LoanApplySelectAccountPage })
end

function OpenLoanApplyForm(account, bank, ParentPage)
    local LoanApplyFormPage = FeatherBankMenu:RegisterPage('bank:page:loans:apply:form:' .. tostring(account.id))
    LoanApplyFormPage:RegisterElement('header', { 
        value = _U('apply_loan_header'), 
        slot = 'header' 
    })
    LoanApplyFormPage:RegisterElement('subheader', {
        value = _U('account_name_label') .. ' ' .. ((account.account_name or account.name or '')),
        slot  = 'header'
    })
    LoanApplyFormPage:RegisterElement('line', { slot = 'header', style = {} })

    local amountValue = ''
    LoanApplyFormPage:RegisterElement('input', { 
        label = _U('loan_amount_label'), 
        placeholder = _U('loan_amount_placeholder'), 
        style = {} 
    }, function(data)
        amountValue = data.value
    end)

    -- Fetch server-defined interest rate for this character/account
    local okRate, rate = BccUtils.RPC:CallAsync('Feather:Banks:GetLoanRate', { account = account.id })
    rate = tonumber(rate) or 10.0
    LoanApplyFormPage:RegisterElement('textdisplay', {
        value = _U('loan_interest_label') .. ': ' .. tostring(rate) .. '%',
        style = {}
    })

    local durationValue = ''
    LoanApplyFormPage:RegisterElement('input', { 
        label = _U('loan_duration_label'), 
        placeholder = _U('loan_duration_placeholder'), 
        style = {} 
    }, function(data)
        durationValue = data.value
    end)

    LoanApplyFormPage:RegisterElement('button', {
        label = _U('create_loan_button'),
        style = {}
    }, function()
        local amount = tonumber(amountValue)
        local duration = tonumber(durationValue)
        if not amount or amount <= 0 then
            Notify(_U('invalid_loan_amount'), 4000)
            return
        end
        if not duration or duration < 0 then
            Notify(_U('invalid_duration'), 4000)
            return
        end

        local total = amount * (1 + (rate / 100))
        local ConfirmPage = FeatherBankMenu:RegisterPage('bank:page:loans:apply:confirm:' .. tostring(account.id))
        ConfirmPage:RegisterElement('header', {
            value = _U('confirm_loan_header'),
            slot  = 'header'
        })
        local function toFixed(n, decimals)
            n = tonumber(n) or 0
            local mult = 10 ^ (decimals or 0)
            local v = math.floor(n * mult + 0.5) / mult
            local s = tostring(v)
            if decimals and decimals > 0 then
                local dot = string.find(s, '.', 1, true)
                if not dot then
                    s = s .. '.' .. string.rep('0', decimals)
                else
                    local places = #s - dot
                    if places < decimals then
                        s = s .. string.rep('0', decimals - places)
                    end
                end
            end
            return s
        end

        ConfirmPage:RegisterElement('textdisplay', {
            value = _U('confirm_loan_text', toFixed(amount, 2), toFixed(rate, 2), tostring(math.floor(duration)), toFixed(total, 2)),
            style = { ['text-align'] = 'center' }
        })
        ConfirmPage:RegisterElement('button', {
            label = _U('confirm_button')
        }, function()
            local ok = BccUtils.RPC:CallAsync('Feather:Banks:CreateLoan', {
                account = account.id,
                amount = amount,
                duration = duration
            })
            if ok then
                Notify(_U('loan_created_notify'), 'success', 4000)
            end
            OpenLoanApplyAccountSelect(bank, ParentPage)
        end)
        ConfirmPage:RegisterElement('line', {
            slot  = 'footer',
            style = {}
        })
        ConfirmPage:RegisterElement('button', {
            label = _U('back_button'),
            slot  = 'footer',
            style = {}
        }, function()
            OpenLoanApplyForm(account, bank, ParentPage)
        end)
        ConfirmPage:RegisterElement('bottomline', {
            slot  = 'footer',
            style = {}
        })
        FeatherBankMenu:Open({ startupPage = ConfirmPage })
    end)

    LoanApplyFormPage:RegisterElement('line', { slot = 'footer', style = {} })
    LoanApplyFormPage:RegisterElement('button', {
        label = _U('back_button'),
        slot  = 'footer',
        style = {}
    }, function()
        ParentPage:RouteTo()
    end)
    LoanApplyFormPage:RegisterElement('bottomline', {
        slot  = 'footer',
        style = {}
    })
    FeatherBankMenu:Open({ startupPage = LoanApplyFormPage })
end

-- Apply for a loan without selecting an account; server will create a dedicated account
function OpenLoanApplyForm_NoAccount(bank, ParentPage)
    local LoanApplyFormNoAccountPage = FeatherBankMenu:RegisterPage('bank:page:loans:apply:form:noacct:' .. tostring(bank.id))
    LoanApplyFormNoAccountPage:RegisterElement('header', {
        value = _U('apply_loan_header'),
        slot  = 'header'
    })
    LoanApplyFormNoAccountPage:RegisterElement('subheader', {
        value = _U('loan_account_auto_note') or _U('loans_subheader'),
        slot  = 'header'
    })
    LoanApplyFormNoAccountPage:RegisterElement('line', { slot = 'header', style = {} })

    local amountValue = ''
    LoanApplyFormNoAccountPage:RegisterElement('input', { label = _U('loan_amount_label'), placeholder = _U('loan_amount_placeholder'), style = {} }, function(data)
        amountValue = data.value
    end)

    -- Fetch server-defined interest rate for this character at this bank
    local okRate, rate = BccUtils.RPC:CallAsync('Feather:Banks:GetLoanRate', { bank = bank.id })
    rate = tonumber(rate) or 10.0
    LoanApplyFormNoAccountPage:RegisterElement('textdisplay', {
        value = _U('interest_rate_display', tostring(rate)),
        style = { ['text-align'] = 'center' }
    })

    local durationValue = ''
    LoanApplyFormNoAccountPage:RegisterElement('input', { label = _U('loan_duration_label'), placeholder = _U('loan_duration_placeholder'), style = {} }, function(data)
        durationValue = data.value
    end)

    LoanApplyFormNoAccountPage:RegisterElement('button', {
        label = _U('create_loan_button'),
        style = {}
    }, function()
        local amount = tonumber(amountValue)
        local duration = tonumber(durationValue)
        if not amount or amount <= 0 then
            Notify(_U('invalid_loan_amount'), 4000)
            return
        end
        if not duration or duration < 0 then
            Notify(_U('invalid_duration'), 4000)
            return
        end

        local total = amount * (1 + (rate / 100))
        local ConfirmPage = FeatherBankMenu:RegisterPage('bank:page:loans:apply:confirm:noacct:' .. tostring(bank.id))
        ConfirmPage:RegisterElement('header', {
            value = _U('confirm_loan_header'),
            slot  = 'header'
        })
        local function toFixed(n, decimals)
            n = tonumber(n) or 0
            local mult = 10 ^ (decimals or 0)
            local v = math.floor(n * mult + 0.5) / mult
            local s = tostring(v)
            if decimals and decimals > 0 then
                local dot = string.find(s, '.', 1, true)
                if not dot then
                    s = s .. '.' .. string.rep('0', decimals)
                else
                    local places = #s - dot
                    if places < decimals then
                        s = s .. string.rep('0', decimals - places)
                    end
                end
            end
            return s
        end
        ConfirmPage:RegisterElement('textdisplay', {
            value = _U('confirm_loan_text', toFixed(amount, 2), toFixed(rate, 2), tostring(math.floor(duration)), toFixed(total, 2)),
            style = { ['text-align'] = 'center' }
        })
        ConfirmPage:RegisterElement('button', {
            label = _U('confirm_button')
        }, function()
            local ok = BccUtils.RPC:CallAsync('Feather:Banks:CreateLoan', {
                bank = bank.id,
                amount = amount,
                duration = duration
            })
            if ok then
                Notify(_U('loan_created_notify'), 'success', 4000)
            end
            -- After creating, show loan list for this bank
            OpenLoansListPage_NoAccount(bank, ParentPage)
        end)
        ConfirmPage:RegisterElement('line', {
            slot  = 'footer',
            style = {}
        })
        ConfirmPage:RegisterElement('button', {
            label = _U('back_button'),
            slot  = 'footer',
            style = {}
        }, function()
            OpenLoanApplyForm_NoAccount(bank, ParentPage)
        end)
        ConfirmPage:RegisterElement('bottomline', {
            slot  = 'footer',
            style = {}
        })
        FeatherBankMenu:Open({ startupPage = ConfirmPage })
    end)

    LoanApplyFormNoAccountPage:RegisterElement('line', { slot = 'footer', style = {} })
    LoanApplyFormNoAccountPage:RegisterElement('button', {
        label = _U('back_button'),
        slot  = 'footer',
        style = {}
    }, function()
        ParentPage:RouteTo()
    end)
    LoanApplyFormNoAccountPage:RegisterElement('bottomline', {
        slot  = 'footer',
        style = {}
    })
    FeatherBankMenu:Open({ startupPage = LoanApplyFormNoAccountPage })
end

-- List loans for this bank (no account selection)
function OpenLoansListPage_NoAccount(bank, ParentPage)
    local LoansListNoAccountPage = FeatherBankMenu:RegisterPage('bank:page:loans:list:noacct:' .. tostring(bank.id))
    LoansListNoAccountPage:RegisterElement('header', {
        value = _U('loans_list_header'),
        slot  = 'header'
    })
    LoansListNoAccountPage:RegisterElement('subheader', {
        value = _U('loans_subheader'),
        slot  = 'header'
    })
    LoansListNoAccountPage:RegisterElement('line', { slot = 'header', style = {} })

    local ok, loans = BccUtils.RPC:CallAsync('Feather:Banks:GetLoans', { bank = bank.id })
    loans = loans or {}
    if not ok or #loans == 0 then
        LoansListNoAccountPage:RegisterElement('textdisplay', {
            value = _U('no_loans_found'),
            slot  = 'content'
        })
    else
        for _, loan in ipairs(loans) do
            local status = tostring(loan.status or '')
            local statusTxt = status ~= '' and (' (' .. status .. ')') or ''
            local label = _U('loan_label') .. ' #' .. tostring(loan.id) .. statusTxt
            LoansListNoAccountPage:RegisterElement('button', {
                label = label,
                style = {}
            }, function()
                OpenLoanDetailsPage_NoAccount(bank, loan.id, LoansListNoAccountPage)
            end)
        end
    end

    LoansListNoAccountPage:RegisterElement('line', { slot = 'footer', style = {} })
    LoansListNoAccountPage:RegisterElement('button', {
        label = _U('back_button'),
        slot  = 'footer',
        style = {}
    }, function()
        ParentPage:RouteTo()
    end)
    LoansListNoAccountPage:RegisterElement('bottomline', {
        slot  = 'footer',
        style = {}
    })
    FeatherBankMenu:Open({ startupPage = LoansListNoAccountPage })
end

function OpenLoansListPage(account, bank, ParentPage)
    local LoansListPage = FeatherBankMenu:RegisterPage('bank:page:loans:list:' .. tostring(account.id))
    LoansListPage:RegisterElement('header', {
        value = _U('loans_list_header'),
        slot  = 'header'
    })
    LoansListPage:RegisterElement('subheader', {
        value = _U('loans_subheader'),
        slot  = 'header'
    })
    LoansListPage:RegisterElement('line', { slot = 'header', style = {} })

    local ok, loans = BccUtils.RPC:CallAsync('Feather:Banks:GetLoans', { account = account.id })
    loans = loans or {}
    if not ok or #loans == 0 then
        LoansListPage:RegisterElement('textdisplay', {
            value = _U('no_loans_found'),
            slot  = 'content'
        })
    else
        for _, loan in ipairs(loans) do
            local status = tostring(loan.status or '')
            local statusTxt = status ~= '' and (' (' .. status .. ')') or ''
            local label = _U('loan_label') .. ' #' .. tostring(loan.id) .. statusTxt
            LoansListPage:RegisterElement('button', {
                label = label,
                style = {}
            }, function()
                OpenLoanDetailsPage(account, bank, loan.id, LoansListPage)
            end)
        end
    end

    LoansListPage:RegisterElement('line', { slot = 'footer', style = {} })
    LoansListPage:RegisterElement('button', {
        label = _U('back_button'),
        slot  = 'footer',
        style = {}
    }, function()
        ParentPage:RouteTo()
    end)
    LoansListPage:RegisterElement('bottomline', {
        slot  = 'footer',
        style = {}
    })
    FeatherBankMenu:Open({ startupPage = LoansListPage })
end

function OpenLoanDetailsPage(account, bank, loanId, ParentPage)
    local ok, info = BccUtils.RPC:CallAsync('Feather:Banks:GetLoan', { loan = loanId })
    if not ok or not info then
        Notify(_U('failed_fetch_loan'), 4000)
        return
    end

    local LoanDetailsPage = FeatherBankMenu:RegisterPage('bank:page:loans:details:' .. tostring(loanId))
    LoanDetailsPage:RegisterElement('header', {
        value = _U('loan_details_header'),
        slot  = 'header'
    })
    LoanDetailsPage:RegisterElement('subheader', { value = _U('loan_label') .. ' #' .. tostring(loanId), slot = 'header' })
    LoanDetailsPage:RegisterElement('line', { slot = 'header', style = {} })

    local html = [[
        <div style="padding:10px;">
            <div><b>]] .. _U('total_due_label') .. [[</b> $]] .. tostring(info.total_due) .. [[</div>
            <div><b>]] .. _U('repaid_label') .. [[</b> $]] .. tostring(info.repaid) .. [[</div>
            <div><b>]] .. _U('outstanding_label') .. [[</b> $]] .. tostring(info.outstanding) .. [[</div>
        </div>
    ]]
    LoanDetailsPage:RegisterElement('html', { value = { html } })

    local repayValue = ''
    LoanDetailsPage:RegisterElement('input', { label = _U('repay_amount_label'), placeholder = _U('repay_amount_placeholder'), style = {} }, function(data)
        repayValue = data.value
    end)

    LoanDetailsPage:RegisterElement('button', {
        label = _U('repay_loan_button'),
        style = {}
    }, function()
        local amt = tonumber(repayValue)
        if not amt or amt <= 0 then
            Notify(_U('invalid_repay_amount'), 4000)
            return
        end
        local ConfirmPage = FeatherBankMenu:RegisterPage('bank:page:loans:repay:confirm:' .. tostring(loanId))
    ConfirmPage:RegisterElement('header', {
        value = _U('confirm_repay_header'),
        slot  = 'header'
    })
        local function toFixed(n, decimals)
            n = tonumber(n) or 0
            local mult = 10 ^ (decimals or 0)
            local v = math.floor(n * mult + 0.5) / mult
            local s = tostring(v)
            if decimals and decimals > 0 then
                local dot = string.find(s, '.', 1, true)
                if not dot then
                    s = s .. '.' .. string.rep('0', decimals)
                else
                    local places = #s - dot
                    if places < decimals then
                        s = s .. string.rep('0', decimals - places)
                    end
                end
            end
            return s
        end
        ConfirmPage:RegisterElement('textdisplay', {
            value = _U('confirm_repay_text', toFixed(amt, 2), tostring(loanId)),
            style = { ['text-align'] = 'center' }
        })
        ConfirmPage:RegisterElement('button', {
            label = _U('confirm_button')
        }, function()
            BccUtils.RPC:CallAsync('Feather:Banks:RepayLoan', { loan = loanId, amount = amt })
            OpenLoanDetailsPage(account, bank, loanId, ParentPage)
        end)
        ConfirmPage:RegisterElement('line', { slot = 'footer', style = {} })
        ConfirmPage:RegisterElement('button', {
            label = _U('back_button'),
            slot  = 'footer',
            style = {}
        }, function()
            OpenLoanDetailsPage(account, bank, loanId, ParentPage)
        end)
        ConfirmPage:RegisterElement('bottomline', {
            slot  = 'footer',
            style = {}
        })
        FeatherBankMenu:Open({ startupPage = ConfirmPage })
    end)

    LoanDetailsPage:RegisterElement('line', { slot = 'footer', style = {} })
    LoanDetailsPage:RegisterElement('button', {
        label = _U('back_button'),
        slot  = 'footer',
        style = {}
    }, function()
        ParentPage:RouteTo()
    end)
    LoanDetailsPage:RegisterElement('bottomline', {
        slot  = 'footer',
        style = {}
    })
    FeatherBankMenu:Open({ startupPage = LoanDetailsPage })
end

-- Loan Details without account context
function OpenLoanDetailsPage_NoAccount(bank, loanId, ParentPage)
    local ok, info = BccUtils.RPC:CallAsync('Feather:Banks:GetLoan', { loan = loanId })
    if not ok or not info then
        Notify(_U('failed_fetch_loan'), 4000)
        return
    end

    local LoanDetailsNoAccountPage = FeatherBankMenu:RegisterPage('bank:page:loans:details:noacct:' .. tostring(loanId))
    LoanDetailsNoAccountPage:RegisterElement('header', {
        value = _U('loan_details_header'),
        slot  = 'header'
    })
    LoanDetailsNoAccountPage:RegisterElement('subheader', { value = _U('loan_label') .. ' #' .. tostring(loanId), slot = 'header' })
    LoanDetailsNoAccountPage:RegisterElement('line', { slot = 'header', style = {} })

    local html = [[
        <div style="padding:10px;">
            <div><b>]] .. _U('total_due_label') .. [[</b> $]] .. tostring(info.total_due) .. [[</div>
            <div><b>]] .. _U('repaid_label') .. [[</b> $]] .. tostring(info.repaid) .. [[</div>
            <div><b>]] .. _U('outstanding_label') .. [[</b> $]] .. tostring(info.outstanding) .. [[</div>
        </div>
    ]]
    LoanDetailsNoAccountPage:RegisterElement('html', { value = { html } })

    -- If approved and not yet disbursed to an account, allow claiming to a selected account
    if info and info.loan and tostring(info.loan.status) == 'approved' and not info.loan.disbursed_account_id then
    LoanDetailsNoAccountPage:RegisterElement('line', { slot = 'content', style = {} })
    LoanDetailsNoAccountPage:RegisterElement('button', {
        label = _U('loan_claim_button') or 'Transfer funds to account',
        style = {}
    }, function()
            OpenLoanClaimSelectAccount(bank, loanId, LoanDetailsNoAccountPage)
        end)
    end

    local repayValue = ''
    LoanDetailsNoAccountPage:RegisterElement('input', { label = _U('repay_amount_label'), placeholder = _U('repay_amount_placeholder'), style = {} }, function(data)
        repayValue = data.value
    end)

    LoanDetailsNoAccountPage:RegisterElement('button', {
        label = _U('repay_loan_button'),
        style = {}
    }, function()
        local amt = tonumber(repayValue)
        if not amt or amt <= 0 then
            Notify(_U('invalid_repay_amount'), 4000)
            return
        end
        local ConfirmPage = FeatherBankMenu:RegisterPage('bank:page:loans:repay:confirm:noacct:' .. tostring(loanId))
    ConfirmPage:RegisterElement('header', {
        value = _U('confirm_repay_header'),
        slot  = 'header'
    })
        local function toFixed(n, decimals)
            n = tonumber(n) or 0
            local mult = 10 ^ (decimals or 0)
            local v = math.floor(n * mult + 0.5) / mult
            local s = tostring(v)
            if decimals and decimals > 0 then
                local dot = string.find(s, '.', 1, true)
                if not dot then
                    s = s .. '.' .. string.rep('0', decimals)
                else
                    local places = #s - dot
                    if places < decimals then
                        s = s .. string.rep('0', decimals - places)
                    end
                end
            end
            return s
        end
        ConfirmPage:RegisterElement('textdisplay', {
            value = _U('confirm_repay_text', toFixed(amt, 2), tostring(loanId)),
            style = { ['text-align'] = 'center' }
        })
        ConfirmPage:RegisterElement('button', {
            label = _U('confirm_button')
        }, function()
            BccUtils.RPC:CallAsync('Feather:Banks:RepayLoan', { loan = loanId, amount = amt })
            OpenLoanDetailsPage_NoAccount(bank, loanId, ParentPage)
        end)
        ConfirmPage:RegisterElement('line', { slot = 'footer', style = {} })
        ConfirmPage:RegisterElement('button', {
            label = _U('back_button'),
            slot  = 'footer',
            style = {}
        }, function()
            OpenLoanDetailsPage_NoAccount(bank, loanId, ParentPage)
        end)
        ConfirmPage:RegisterElement('bottomline', {
            slot  = 'footer',
            style = {}
        })
        FeatherBankMenu:Open({ startupPage = ConfirmPage })
    end)

    LoanDetailsNoAccountPage:RegisterElement('line', { slot = 'footer', style = {} })
    LoanDetailsNoAccountPage:RegisterElement('button', {
        label = _U('back_button'),
        slot  = 'footer',
        style = {}
    }, function()
        ParentPage:RouteTo()
    end)
    LoanDetailsNoAccountPage:RegisterElement('bottomline', {
        slot  = 'footer',
        style = {}
    })
    FeatherBankMenu:Open({ startupPage = LoanDetailsNoAccountPage })
end

-- Select an account to receive approved loan funds
function OpenLoanClaimSelectAccount(bank, loanId, ParentPage)
    local LoanClaimSelectAccountPage = FeatherBankMenu:RegisterPage('bank:page:loans:claim:select:noacct:' .. tostring(bank.id) .. ':' .. tostring(loanId))
    LoanClaimSelectAccountPage:RegisterElement('header', {
        value = _U('loan_claim_select_account') or 'Select account to receive funds',
        slot  = 'header'
    })
    LoanClaimSelectAccountPage:RegisterElement('line', { slot = 'header', style = {} })

    local ok, accounts = BccUtils.RPC:CallAsync('Feather:Banks:GetAccounts', { bank = bank.id })
    if not ok or not accounts or #accounts == 0 then
        LoanClaimSelectAccountPage:RegisterElement('textdisplay', { value = _U('no_accounts_found'), slot = 'content' })
    else
        for _, account in ipairs(accounts) do
        LoanClaimSelectAccountPage:RegisterElement('button', {
            label = account.account_name,
            style = {}
        }, function()
                local success = BccUtils.RPC:CallAsync('Feather:Banks:ClaimLoanDisbursement', { loan = loanId, account = account.id })
                if success then
                    Notify(_U('loan_claim_success') or 'Funds transferred to account.', 'success', 4000)
                end
                OpenLoanDetailsPage_NoAccount(bank, loanId, ParentPage)
            end)
        end
    end

    LoanClaimSelectAccountPage:RegisterElement('line', { slot = 'footer', style = {} })
    LoanClaimSelectAccountPage:RegisterElement('button', {
        label = _U('back_button'),
        slot  = 'footer',
        style = {}
    }, function()
        ParentPage:RouteTo()
    end)
    LoanClaimSelectAccountPage:RegisterElement('bottomline', { slot = 'footer', style = {} })
    FeatherBankMenu:Open({ startupPage = LoanClaimSelectAccountPage })
end
