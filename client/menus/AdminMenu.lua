-- Bank Admin Menu: one command opens UI to manage rates and view data

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

function OpenBankAdminMenu()
    local ok, allowed = BccUtils.RPC:CallAsync("Feather:Banks:CheckAdmin", {})
    if not ok or not allowed then
        Notify(_U("admin_no_permission"), "error", 3500)
        return
    end

    OpenAdminBankSelectMenu()
end

-- 1) Select a bank first
function OpenAdminBankSelectMenu()
    local Page = FeatherBankMenu:RegisterPage("bank:page:admin:banks")

    Page:RegisterElement("header", {
        value = _U("admin_header"),
        slot  = "header"
    })
    Page:RegisterElement("subheader", {
        value = _U("admin_subheader"),
        slot  = "header"
    })
    Page:RegisterElement("line", {
        slot  = "header",
        style = {}
    })

    local ok, banks = BccUtils.RPC:CallAsync("Feather:Banks:GetBanks", {})
    banks = banks or {}
    if not ok or #banks == 0 then
        Page:RegisterElement("textdisplay", {
            value = "No banks found.",
            slot  = "content"
        })
    end

    -- Always allow creating a bank from here
    Page:RegisterElement("button", {
        label = "Create Bank At Your Location",
        style = {}
    }, function()
        local CreatePage = FeatherBankMenu:RegisterPage("bank:page:admin:banks:create")
        CreatePage:RegisterElement("header", {
            value = "Create Bank",
            slot  = "header"
        })
        CreatePage:RegisterElement("line", {
            slot  = "header",
            style = {}
        })
        local nameValue = ""
        CreatePage:RegisterElement("input", {
            label       = "Bank Name",
            placeholder = "Enter bank name",
            style       = {}
        }, function(data)
            nameValue = data.value
        end)
        CreatePage:RegisterElement("button", {
            label = _U("confirm_button"),
            style = {}
        }, function()
            local okC = BccUtils.RPC:CallAsync("Feather:Banks:CreateBank", { name = nameValue })
            if okC then
                OpenAdminBankSelectMenu()
            end
        end)
        CreatePage:RegisterElement("line", {
            slot  = "footer",
            style = {}
        })
        CreatePage:RegisterElement("button", {
            label = _U("back_button"),
            slot  = "footer",
            style = {}
        }, function()
            OpenAdminBankSelectMenu()
        end)
        CreatePage:RegisterElement("bottomline", {
            slot  = "footer",
            style = {}
        })
        FeatherBankMenu:Open({ startupPage = CreatePage })
    end)

    if ok and #banks > 0 then
        for _, bank in ipairs(banks) do
            local label = tostring(bank.name)
            Page:RegisterElement("button", {
                label = label,
                style = {}
            }, function()
                OpenAdminBankHub(bank, Page)
            end)
        end
    end

    Page:RegisterElement("line", {
        slot  = "footer",
        style = {}
    })
    Page:RegisterElement("button", {
        label = _U("back_button"),
        slot  = "footer",
        style = {}
    }, function()
        FeatherBankMenu:Close()
    end)
    Page:RegisterElement("bottomline", {
        slot  = "footer",
        style = {}
    })
    FeatherBankMenu:Open({ startupPage = Page })
end

-- 2) Per-bank admin hub with actions
function OpenAdminBankHub(bank, Parent)
    local Hub = FeatherBankMenu:RegisterPage("bank:page:admin:bank:" .. tostring(bank.id))

    Hub:RegisterElement("header", {
        value = _U("admin_header"),
        slot  = "header"
    })
    Hub:RegisterElement("subheader", {
        value = tostring(bank.name),
        slot  = "header"
    })
    Hub:RegisterElement("line", {
        slot  = "header",
        style = {}
    })

    Hub:RegisterElement("button", {
        label = _U("admin_manage_rates_button"),
        style = {}
    }, function()
        OpenAdminRatesMenu(Hub, bank)
    end)
    Hub:RegisterElement("button", {
        label = _U("admin_view_accounts_button"),
        style = {}
    }, function()
        OpenAdminAccountsMenu(Hub, bank)
    end)
    Hub:RegisterElement("button", {
        label = _U("admin_view_loans_button"),
        style = {}
    }, function()
        OpenAdminLoansMenu(Hub, bank)
    end)
    Hub:RegisterElement("button", {
        label = _U("admin_view_sdbs_button"),
        style = {}
    }, function()
        OpenAdminSDBsMenu(Hub, bank)
    end)
    Hub:RegisterElement("button", {
        label = _U("admin_manage_hours_button") or "Manage Hours",
        style = {}
    }, function()
        OpenAdminHoursMenu(Hub, bank)
    end)

    Hub:RegisterElement("line", {
        slot  = "footer",
        style = {}
    })
    Hub:RegisterElement("button", {
        label = _U("back_button"),
        slot  = "footer",
        style = {}
    }, function()
        OpenAdminBankSelectMenu()
    end)
    Hub:RegisterElement("bottomline", {
        slot  = "footer",
        style = {}
    })
    FeatherBankMenu:Open({ startupPage = Hub })
end

function OpenAdminHoursMenu(Parent, bank)
    local Page = FeatherBankMenu:RegisterPage('bank:page:admin:hours')
    Page:RegisterElement('header', {
        value = _U('admin_hours_header') or 'Hours',
        slot = 'header'
    })
    Page:RegisterElement('subheader', {
        value = _U('admin_hours_subheader') or 'Configure opening hours',
        slot = 'header'
    })
    Page:RegisterElement('line', {
        slot = 'header',
        style = {}
    })

    local bankIdValue = bank and tostring(bank.id) or ''
    local openVal, closeVal = '', ''
    local hoursActive = false

    if not bank then
        Page:RegisterElement('input', {
            label = _U('admin_bank_id_label'),
            placeholder = _U('admin_bank_id_placeholder'),
            style = {}
        }, function(data)
            bankIdValue = data.value
        end)
    else
        Page:RegisterElement('textdisplay', {
            value = 'Bank: ' .. tostring(bank.name),
            slot = 'content'
        })
    end

    do
        local bankId = NormalizeId(bankIdValue) or (bank and NormalizeId(bank.id))
        if bankId then
            local ok, data = BccUtils.RPC:CallAsync('Feather:Banks:Admin:GetHours', { bank = bankId })
            if ok and data then
                hoursActive = data.hours_active and true or false
                openVal = tostring(data.open_hour or '')
                closeVal = tostring(data.close_hour or '')
                local status = hoursActive and (_U('admin_hours_active_yes') or 'Hours Active: Yes') or
                (_U('admin_hours_active_no') or 'Hours Active: No')
                local info = status .. ' | Open: ' .. (openVal ~= '' and openVal or '—') .. ' | Close: ' .. (closeVal ~= '' and closeVal or '—')
                Page:RegisterElement('textdisplay', {
                    value = info,
                    slot = 'content'
                })
            end
        end
    end

    Page:RegisterElement('toggle', {
        label = _U('admin_manage_hours_button') or 'Manage Hours',
        start = hoursActive,
        slot = 'content',
    }, function(data)
        local bankId = NormalizeId(bankIdValue) or (bank and NormalizeId(bank.id))
        if not bankId then
            Notify(_U('admin_invalid_bank_id'), 3000)
            return
        end
        local ok = BccUtils.RPC:CallAsync('Feather:Banks:Admin:ToggleHours',
            { bank = bankId, active = data.value and true or false })
        Notify(
        ok and
        (data.value and (_U('admin_hours_enabled') or 'Hours enabled.') or (_U('admin_hours_disabled') or 'Hours disabled.')) or
        _U('admin_action_failed'), ok and 'success' or 'error', 3500)
    end)

    -- Inputs for open/close with placeholders showing current
    Page:RegisterElement('input', {
        label = _U('admin_open_hour_label') or 'Open Hour (0-23)',
        placeholder = (openVal ~= '' and openVal or '7'),
        style = {}
    }, function(data)
        openVal = data.value
    end)
    Page:RegisterElement('input', {
        label = _U('admin_close_hour_label') or 'Close Hour (0-23)',
        placeholder = (closeVal ~= '' and closeVal or '21'),
        style = {}
    }, function(data)
        closeVal = data.value
    end)
    Page:RegisterElement('button', {
        label = _U('admin_set_hours_button') or 'Set Hours',
        style = {}
    }, function()
        local bankId = NormalizeId(bankIdValue) or (bank and NormalizeId(bank.id))
        local openH = tonumber(openVal)
        local closeH = tonumber(closeVal)
        if not bankId or openH == nil or closeH == nil then
            Notify(_U('admin_invalid_hours_input') or 'Enter valid bank/hours', 3000)
            return
        end
        local ok = BccUtils.RPC:CallAsync('Feather:Banks:Admin:SetHours', { bank = bankId, open = openH, close = closeH })
        Notify(ok and (_U('admin_hours_updated') or 'Hours updated.') or _U('admin_action_failed'),
            ok and 'success' or 'error', 3500)
    end)

    Page:RegisterElement('line', {
        slot = 'footer',
        style = {}
    })
    Page:RegisterElement('button', {
        label = _U('back_button'),
        slot = 'footer',
        style = {}
    }, function()
        Parent:RouteTo()
    end)
    Page:RegisterElement('bottomline', {
        slot = 'footer',
        style = {}
    })
    FeatherBankMenu:Open({ startupPage = Page })
end

function OpenAdminRatesMenu(Parent, bank)
    local AdminRatesPage = FeatherBankMenu:RegisterPage('bank:page:admin:rates')
    AdminRatesPage:RegisterElement('header', {
        value = _U('admin_rates_header'),
        slot  = 'header'
    })
    AdminRatesPage:RegisterElement('subheader', {
        value = _U('admin_rates_subheader'),
        slot  = 'header'
    })
    AdminRatesPage:RegisterElement('line', {
        slot  = 'header',
        style = {}
    })

    local bankIdValue, newRateValue = bank and tostring(bank.id) or '', ''
    if not bank then
        AdminRatesPage:RegisterElement('input', {
            label       = _U('admin_bank_id_label'),
            placeholder = _U('admin_bank_id_placeholder'),
            style       = {}
        }, function(data)
            bankIdValue = data.value
        end)
    else
        AdminRatesPage:RegisterElement('textdisplay', {
            value = 'Bank: ' .. tostring(bank.name),
            slot = 'content'
        })
    end
    AdminRatesPage:RegisterElement('button', {
        label = _U('admin_get_bank_rate_button'),
        style = {}
    }, function()
        local bankId = NormalizeId(bankIdValue)
        if not bankId then
            Notify(_U('admin_invalid_bank_id'), 3000)
            return
        end
        local ok, rate = BccUtils.RPC:CallAsync('Feather:Banks:Admin:GetBankRate', { bank = bankId })
        local msg = ok and
        (_U('admin_current_rate') .. ' ' .. (rate and toFixed(rate, 2) .. '%' or _U('admin_rate_not_set'))) or
        _U('admin_action_failed')
        Notify(msg, ok and 'success' or 'error', 3500)
    end)
    AdminRatesPage:RegisterElement('input', {
        label       = _U('admin_new_rate_label'),
        placeholder = _U('admin_new_rate_placeholder'),
        style       = {}
    }, function(data)
        newRateValue = data.value
    end)
    AdminRatesPage:RegisterElement('button', {
        label = _U('admin_set_bank_rate_button'),
        style = {}
    }, function()
        local bankId = NormalizeId(bankIdValue)
        local rate = tonumber(newRateValue)
        if not bankId or not rate then
            Notify(_U('admin_invalid_input'), 3000)
            return
        end
        local ok = BccUtils.RPC:CallAsync('Feather:Banks:Admin:SetBankRate', { bank = bankId, rate = rate })
        Notify(ok and _U('admin_rate_updated') or _U('admin_action_failed'), ok and 'success' or 'error', 3500)
    end)

    AdminRatesPage:RegisterElement('line', {
        style = {}
    })

    AdminRatesPage:RegisterElement('button', {
        label = _U('admin_manage_char_rates_button'),
        style = {}
    }, function()
        OpenAdminCharRatesMenu(AdminRatesPage)
    end)

    AdminRatesPage:RegisterElement('line', {
        slot  = 'footer',
        style = {}
    })
    AdminRatesPage:RegisterElement('button', {
        label = _U('back_button'),
        slot  = 'footer',
        style = {}
    }, function()
        Parent:RouteTo()
    end)
    AdminRatesPage:RegisterElement('bottomline', {
        slot  = 'footer',
        style = {}
    })
    FeatherBankMenu:Open({ startupPage = AdminRatesPage })
end

function OpenAdminCharRatesMenu(Parent)
    local AdminCharRatesPage = FeatherBankMenu:RegisterPage('bank:page:admin:char:rates')
    AdminCharRatesPage:RegisterElement('header', {
        value = _U('admin_char_rates_header'),
        slot  = 'header'
    })
    AdminCharRatesPage:RegisterElement('subheader', {
        value = _U('admin_char_rates_subheader'),
        slot  = 'header'
    })
    AdminCharRatesPage:RegisterElement('line', {
        slot  = 'header',
        style = {}
    })

    local charIdValue, bankIdValue, newRateValue = '', '', ''
    AdminCharRatesPage:RegisterElement('input', {
        label       = _U('admin_char_id_label'),
        placeholder = _U('admin_char_id_placeholder'),
        style       = {}
    }, function(data)
        charIdValue = data.value
    end)
    AdminCharRatesPage:RegisterElement('input', {
        label       = _U('admin_bank_id_label'),
        placeholder = _U('admin_bank_id_char_placeholder'),
        style       = {}
    }, function(data)
        bankIdValue = data.value
    end)
    AdminCharRatesPage:RegisterElement('button', {
        label = _U('admin_get_char_rate_button'),
        style = {}
    }, function()
        local charId = tonumber(charIdValue)
        if not charId then
            Notify(_U('admin_invalid_char_id'), 3000)
            return
        end
        local ok, rate = BccUtils.RPC:CallAsync('Feather:Banks:Admin:GetCharRate', { char = charId, bank = bankIdValue })
        local msg = ok and
        (_U('admin_current_rate') .. ' ' .. (rate and toFixed(rate, 2) .. '%' or _U('admin_rate_not_set'))) or
        _U('admin_action_failed')
        Notify(msg, ok and 'success' or 'error', 3500)
    end)
    AdminCharRatesPage:RegisterElement('input', {
        label       = _U('admin_new_rate_label'),
        placeholder = _U('admin_new_rate_placeholder'),
        style       = {}
    }, function(data)
        newRateValue = data.value
    end)
    AdminCharRatesPage:RegisterElement('button', {
        label = _U('admin_set_char_rate_button'),
        style = {}
    }, function()
        local charId = tonumber(charIdValue)
        local rate = tonumber(newRateValue)
        if not charId or not rate then
            Notify(_U('admin_invalid_input'), 3000)
            return
        end
        local ok = BccUtils.RPC:CallAsync('Feather:Banks:Admin:SetCharRate',
            { char = charId, bank = bankIdValue, rate = rate })
        Notify(ok and _U('admin_rate_updated') or _U('admin_action_failed'), ok and 'success' or 'error', 3500)
    end)
    AdminCharRatesPage:RegisterElement('button', {
        label = _U('admin_clear_char_rate_button'),
        style = {}
    }, function()
        local charId = tonumber(charIdValue)
        if not charId then
            Notify(_U('admin_invalid_char_id'), 3000)
            return
        end
        local ok = BccUtils.RPC:CallAsync('Feather:Banks:Admin:ClearCharRate', { char = charId, bank = bankIdValue })
        Notify(ok and _U('admin_rate_cleared') or _U('admin_action_failed'), ok and 'success' or 'error', 3500)
    end)

    AdminCharRatesPage:RegisterElement('line', {
        slot  = 'footer',
        style = {}
    })
    AdminCharRatesPage:RegisterElement('button', {
        label = _U('back_button'),
        slot  = 'footer',
        style = {}
    }, function()
        Parent:RouteTo()
    end)
    AdminCharRatesPage:RegisterElement('bottomline', {
        slot  = 'footer',
        style = {}
    })
    FeatherBankMenu:Open({ startupPage = AdminCharRatesPage })
end

local function renderTable(list, columns)
    local html = '<div style="padding:8px;">'
    html = html .. '<table style="width:100%; border-collapse:collapse;">'
    html = html .. '<thead><tr>'
    for _, col in ipairs(columns or {}) do
        local label = tostring(col.label or '')
        html = html .. '<th style="text-align:left; padding:6px 4px;">' .. label .. '</th>'
    end
    html = html .. '</tr></thead><tbody>'

    local rows = list or {}
    if #rows == 0 then
        local span = tostring(#(columns or {}))
        if span == '0' then span = '1' end
        local emptyMsg = _U('no_loans_found') or 'No loans found.'
        html = html .. '<tr><td style="padding:8px 6px; text-align:center;" colspan="' .. span .. '">' .. emptyMsg .. '</td></tr>'
    else
        for _, row in ipairs(rows) do
            html = html .. '<tr>'
            for _, col in ipairs(columns or {}) do
                local value
                if type(col.value) == 'function' then
                    value = col.value(row)
                elseif col.key then
                    value = row[col.key]
                end
                if value == nil then value = '' end
                html = html .. '<td style="padding:6px 4px;">' .. tostring(value) .. '</td>'
            end
            html = html .. '</tr>'
        end
    end

    html = html .. '</tbody></table></div>'
    return html
end

local function formatAccountCell(row)
    local accName = row.account_name or ''
    local accId = row.account_id or ''
    if accName and accName ~= '' then
        return accName .. ' (#' .. tostring(accId) .. ')'
    end
    if accId and accId ~= '' then
        return '#' .. tostring(accId)
    end
    return _U('unknown') or 'Unknown'
end

local function formatBorrowerCell(row)
    local first = tostring(row.borrower_firstname or '')
    local last = tostring(row.borrower_lastname or '')
    local trimmedFirst = first:match('^%s*(.-)%s*$') or ''
    local trimmedLast = last:match('^%s*(.-)%s*$') or ''
    local hasFirst = trimmedFirst ~= ''
    local hasLast = trimmedLast ~= ''
    local fullName
    if hasFirst or hasLast then
        if hasFirst and hasLast then
            fullName = trimmedFirst .. ' ' .. trimmedLast
        elseif hasFirst then
            fullName = trimmedFirst
        else
            fullName = trimmedLast
        end
    else
        fullName = _U('unknown') or 'Unknown'
    end
    local charId = row.character_id and tostring(row.character_id) or ''
    if charId ~= '' then
        fullName = fullName .. ' (#' .. charId .. ')'
    end
    return fullName
end

local function formatCreatedWithAmount(row)
    local created = row.created_at and tostring(row.created_at) or '-'
    local amount = toFixed(row.amount, 2)
    return created .. ' — $' .. amount
end

local function openAdminLoanDetails(loan, ParentPage, bank)
    local loanId = tostring(loan.id)
    local detailPage = FeatherBankMenu:RegisterPage('bank:page:admin:loan:' .. loanId)

    detailPage:RegisterElement('header', {
        value = _U('admin_loan_header', loanId) or ('Loan #' .. loanId),
        slot  = 'header'
    })

    local borrowerSummary = formatBorrowerCell(loan)
    local amountValue = toFixed(loan.amount, 2)
    local amountSummary = '$' .. amountValue
    detailPage:RegisterElement('subheader', {
        value = borrowerSummary .. ' — ' .. amountSummary,
        slot  = 'header'
    })

    detailPage:RegisterElement('line', {
        slot  = 'header',
        style = {}
    })

    local totalRepaid = toFixed(loan.total_repaid or loan.totalRepaid or 0, 2)
    local totalOutstanding = toFixed(loan.total_outstanding or loan.outstanding or 0, 2)
    local totalDue = toFixed(loan.total_due or ((tonumber(loan.amount) or 0) * (1 + ((tonumber(loan.interest) or 0) / 100))), 2)

    local createdDisplay = loan.created_at_display or loan.created_at or '-'

    local infoHtml = [[
        <div style="padding:12px;">
            <div><b>]] .. (_U('admin_table_owner') or 'Owner') .. [[</b> ]] .. borrowerSummary .. [[</div>
            <div><b>]] .. (_U('admin_table_account') or 'Account') .. [[</b> ]] .. formatAccountCell(loan) .. [[</div>
            <div><b>]] .. (_U('loan_amount_label') or 'Loan Amount') .. [[</b> $]] .. amountValue .. [[</div>
            <div><b>]] .. (_U('admin_table_interest') or 'Interest') .. [[</b> ]] .. toFixed(loan.interest, 2) .. [[%</div>
            <div><b>]] .. (_U('admin_table_duration') or 'Duration') .. [[</b> ]] .. tostring(loan.duration or '-') .. ' ' .. ((_U('admin_months_short') or 'months')) .. [[</div>
            <div><b>]] .. (_U('repaid_label') or 'Repaid:') .. [[</b> $]] .. totalRepaid .. [[</div>
            <div><b>]] .. (_U('outstanding_label') or 'Outstanding:') .. [[</b> $]] .. totalOutstanding .. [[</div>
            <div><b>]] .. (_U('total_due_label') or 'Total Due:') .. [[</b> $]] .. totalDue .. [[</div>
            <div><b>]] .. (_U('admin_table_created') or 'Created') .. [[</b> ]] .. createdDisplay .. [[</div>
            <div><b>Status</b> ]] .. (loan.status or 'pending') .. [[</div>
        </div>
    ]]

    detailPage:RegisterElement('html', {
        value = { infoHtml },
        slot  = 'content'
    })

    detailPage:RegisterElement('line', {
        slot  = 'content',
        style = {}
    })

    if tostring(loan.status) == 'pending' then
        detailPage:RegisterElement('button', {
            label = _U('admin_approve_button') or 'Approve',
            style = {}
        }, function()
            local okA = BccUtils.RPC:CallAsync('Feather:Banks:Admin:ApproveLoan', { loan = NormalizeId(loanId) })
            if okA then
                Notify(_U('admin_approved_notify') or 'Approved', 2500)
            end
            OpenAdminLoansMenu(ParentPage, bank)
        end)
        detailPage:RegisterElement('button', {
            label = _U('admin_reject_button') or 'Reject',
            style = {}
        }, function()
            local okR = BccUtils.RPC:CallAsync('Feather:Banks:Admin:RejectLoan', { loan = NormalizeId(loanId) })
            if okR then
                Notify(_U('admin_rejected_notify') or 'Rejected', 2500)
            end
            OpenAdminLoansMenu(ParentPage, bank)
        end)
    end

    detailPage:RegisterElement('line', {
        slot  = 'footer',
        style = {}
    })

    detailPage:RegisterElement('button', {
        label = _U('back_button'),
        slot  = 'footer',
        style = {}
    }, function()
        ParentPage:RouteTo()
    end)

    detailPage:RegisterElement('bottomline', {
        slot  = 'footer',
        style = {}
    })

    FeatherBankMenu:Open({ startupPage = detailPage })
end

local function renderLoanButtons(page, loans, bank)
    if not loans or #loans == 0 then return end

    for _, loan in ipairs(loans) do
        local borrowerLabel = formatBorrowerCell(loan)
        local amountText = toFixed(loan.amount, 2)
        local repaidText = toFixed(loan.total_repaid or loan.totalRepaid or 0, 2)
        local label = borrowerLabel .. ' — $' .. amountText .. ' | ' .. (_U('repaid_label') or 'Repaid:') .. ' $' .. repaidText
        page:RegisterElement('button', {
            label = label,
            style = {}
        }, function()
            openAdminLoanDetails(loan, page, bank)
        end)
    end
end

function OpenAdminAccountsMenu(Parent, bank)
    local AdminAccountsPage = FeatherBankMenu:RegisterPage('bank:page:admin:accounts')
    AdminAccountsPage:RegisterElement('header', {
        value = _U('admin_accounts_header'),
        slot  = 'header'
    })
    AdminAccountsPage:RegisterElement('subheader', {
        value = _U('admin_accounts_subheader'),
        slot  = 'header'
    })
    AdminAccountsPage:RegisterElement('line', {
        slot  = 'header',
        style = {}
    })

    local bankIdValue = bank and tostring(bank.id) or ''

    -- Helper: fetch and render accounts as buttons (Owner — Account)
    local function renderAccountsList(bankId)
        if not bankId then return end
        local ok, rows = BccUtils.RPC:CallAsync('Feather:Banks:Admin:ListAccounts', { bank = bankId })
        if not ok then
            Notify(_U('admin_action_failed'), 3000)
            return
        end

        AdminAccountsPage:RegisterElement('line', {
            slot = 'content',
            style = {}
        })

        if not rows or #rows == 0 then
            AdminAccountsPage:RegisterElement('textdisplay', {
                value = _U('no_accounts_found'),
                slot  = 'content'
            })
        else
            for _, r in ipairs(rows or {}) do
                local first    = (r.owner_firstname and tostring(r.owner_firstname)) or ''
                local last     = (r.owner_lastname and tostring(r.owner_lastname)) or ''
                local fullName = (first ~= '' or last ~= '') and (first .. ' ' .. last) or (_U('unknown') or 'Unknown')
                local accName  = (r.name and tostring(r.name)) or (_U('bank_accounts_header') or 'Account')
                local label    = fullName .. ' — ' .. accName

                AdminAccountsPage:RegisterElement('button', {
                    label = label,
                    style = {}
                }, function()
                    OpenAdminAccountDetails(r.id, AdminAccountsPage)
                end)
            end
        end

        FeatherBankMenu:Open({ startupPage = AdminAccountsPage })
    end
    if not bank then
        AdminAccountsPage:RegisterElement('input', {
            label       = _U('admin_bank_id_label'),
            placeholder = _U('admin_bank_id_placeholder'),
            style       = {}
        }, function(data)
            bankIdValue = data.value
            local bankId = NormalizeId(bankIdValue)
            if bankId then
                renderAccountsList(bankId)
            end
        end)
    else
        AdminAccountsPage:RegisterElement('textdisplay', {
            value = 'Bank: ' .. tostring(bank.name),
            slot = 'content'
        })
    end
    -- If bank is provided, render immediately
    do
        local preBankId = bank and NormalizeId(bank.id) or nil
        if preBankId then
            renderAccountsList(preBankId)
        end
    end

    AdminAccountsPage:RegisterElement('line', {
        slot  = 'footer',
        style = {}
    })
    AdminAccountsPage:RegisterElement('button', {
        label = _U('back_button'),
        slot  = 'footer',
        style = {}
    }, function()
        Parent:RouteTo()
    end)
    AdminAccountsPage:RegisterElement('bottomline', {
        slot  = 'footer',
        style = {}
    })
    FeatherBankMenu:Open({ startupPage = AdminAccountsPage })
end

-- Admin view: account details (read-only)
function OpenAdminAccountDetails(accountId, ParentPage)
    local ok, resp = BccUtils.RPC:CallAsync('Feather:Banks:Admin:GetAccount', { account = tostring(accountId) })
    if not ok or not resp or not resp.account then
        Notify(_U('admin_action_failed') or 'Failed to load account.', 'error', 3500)
        return
    end

    local acc = resp.account
    local Page = FeatherBankMenu:RegisterPage('bank:page:admin:account:' .. tostring(acc.id))

    Page:RegisterElement('header', {
        value = _U('account_details_header') or 'Account Details',
        slot = 'header'
    })
    Page:RegisterElement('subheader', {
        value = (acc.name or ('#' .. tostring(acc.id))),
        slot = 'header'
    })
    Page:RegisterElement('line', {
        slot = 'header',
        style = {}
    })

    -- Summary balances
    Page:RegisterElement('imageboxcontainer', {
        slot  = 'content',
        items = {
            { type = 'imagebox', index = 401, data = { img = 'nui://bcc-banks/ui/images/money_moneystack.png', label = '$' .. tostring(acc.cash or 0), tooltip = _U('cash_balance_tooltip'), style = { margin = '6px' } } },
            { type = 'imagebox', index = 402, data = { img = 'nui://bcc-banks/ui/images/provision_goldbar_small.png', label = tostring(acc.gold or 0) .. ' g', tooltip = _U('gold_balance_tooltip'), style = { margin = '6px' } } }
        }
    })

    -- Meta
    local ownerName = ((acc.owner_firstname or '') ~= '' or (acc.owner_lastname or '') ~= '')
        and (tostring(acc.owner_firstname or '') .. ' ' .. tostring(acc.owner_lastname or ''))
        or (_U('unknown') or 'Unknown')
    local html = [[
        <div style="padding:20px; text-align:left;">
            <div><b>]] ..
    (_U('account_number_label') or 'Account Number') .. [[</b> ]] .. tostring(acc.account_number or '-') .. [[</div>
            <div><b>]] .. (_U('account_name_label') or 'Name') .. [[</b> ]] .. tostring(acc.name or '-') .. [[</div>
            <div><b>Owner ID</b> ]] .. tostring(acc.owner_id or '-') .. [[</div>
            <div><b>Owner Name</b> ]] .. ownerName .. [[</div>
        </div>
    ]]
    Page:RegisterElement('html', {
        value = { html },
        slot = 'content'
    })

    Page:RegisterElement('line', {
        slot = 'footer',
        style = {}
    })
    Page:RegisterElement('button', {
        label = _U('back_button'),
        slot = 'footer',
        style = {}
    }, function()
        ParentPage:RouteTo()
    end)
    Page:RegisterElement('bottomline', {
        slot = 'footer',
        style = {}
    })

    FeatherBankMenu:Open({ startupPage = Page })
end

function OpenAdminLoansMenu(Parent, bank)
    local AdminLoansPage = FeatherBankMenu:RegisterPage('bank:page:admin:loans')
    AdminLoansPage:RegisterElement('header', {
        value = _U('admin_loans_header'),
        slot  = 'header'
    })
    AdminLoansPage:RegisterElement('subheader', {
        value = _U('admin_loans_subheader'),
        slot  = 'header'
    })
    AdminLoansPage:RegisterElement('line', {
        slot  = 'header',
        style = {}
    })

    local bankIdValue = bank and tostring(bank.id) or ''
    if not bank then
        AdminLoansPage:RegisterElement('input', {
            label       = _U('admin_bank_id_label'),
            placeholder = _U('admin_bank_id_placeholder'),
            style       = {}
        }, function(data)
            bankIdValue = data.value
            local normalized = NormalizeId(bankIdValue)
            if normalized then
                OpenAdminLoansMenu(Parent, { id = normalized })
            end
        end)
    else
        local displayValue = bank.name and ('Bank: ' .. tostring(bank.name)) or ('Bank ID: ' .. tostring(bank.id))
        AdminLoansPage:RegisterElement('textdisplay', {
            value = displayValue,
            slot = 'content'
        })
    end
    local function loadLoanSections(targetBankId)
        if not targetBankId then return end

        local okPending, pendingLoans = BccUtils.RPC:CallAsync('Feather:Banks:Admin:ListPendingLoans', { bank = targetBankId })
        if not okPending then
            Notify(_U('admin_action_failed'), 3000)
            return
        end

        local okAll, allLoans = BccUtils.RPC:CallAsync('Feather:Banks:Admin:ListLoans', { bank = targetBankId })
        if not okAll then
            Notify(_U('admin_action_failed'), 3000)
            return
        end

        AdminLoansPage:RegisterElement('line', {
            slot  = 'content',
            style = {}
        })

        local hasAny = false

        if pendingLoans and #pendingLoans > 0 then
            hasAny = true
            AdminLoansPage:RegisterElement('textdisplay', {
                value = _U('admin_pending_loans') or 'Pending Loans',
                slot  = 'content'
            })
            renderLoanButtons(AdminLoansPage, pendingLoans, bank)
        end

        local remaining = {}
        if allLoans and #allLoans > 0 then
            local pendingLookup = {}
            if pendingLoans then
                for _, p in ipairs(pendingLoans) do
                    pendingLookup[tostring(p.id)] = true
                end
            end
            for _, loan in ipairs(allLoans) do
                if not pendingLookup[tostring(loan.id)] then
                    remaining[#remaining + 1] = loan
                end
            end
        end

        if #remaining > 0 then
            if pendingLoans and #pendingLoans > 0 then
                AdminLoansPage:RegisterElement('line', {
                    slot  = 'content',
                    style = { margin = '4px 0' }
                })
            end
            hasAny = true
            AdminLoansPage:RegisterElement('textdisplay', {
                value = _U('admin_all_loans') or 'All Loans',
                slot  = 'content'
            })
            renderLoanButtons(AdminLoansPage, remaining, bank)
        end

        if not hasAny then
            AdminLoansPage:RegisterElement('textdisplay', {
                value = _U('no_loans_found') or 'No loans found.',
                slot  = 'content'
            })
        end
    end

    do
        local preBankId = bank and NormalizeId(bank.id) or nil
        if preBankId then
            loadLoanSections(preBankId)
        end
    end

    AdminLoansPage:RegisterElement('line', {
        slot  = 'footer',
        style = {}
    })
    AdminLoansPage:RegisterElement('button', {
        label = _U('back_button'),
        slot  = 'footer',
        style = {}
    }, function()
        Parent:RouteTo()
    end)
    AdminLoansPage:RegisterElement('bottomline', {
        slot  = 'footer',
        style = {}
    })
    FeatherBankMenu:Open({ startupPage = AdminLoansPage })
end

function OpenAdminSDBsMenu(Parent, bank)
    local AdminSDBsPage = FeatherBankMenu:RegisterPage('bank:page:admin:sdbs')
    AdminSDBsPage:RegisterElement('header', {
        value = _U('admin_sdbs_header'),
        slot  = 'header'
    })
    AdminSDBsPage:RegisterElement('subheader', {
        value = _U('admin_sdbs_subheader'),
        slot  = 'header'
    })
    AdminSDBsPage:RegisterElement('line', {
        slot  = 'header',
        style = {}
    })

    local bankIdValue = bank and tostring(bank.id) or ''
    if not bank then
        AdminSDBsPage:RegisterElement('input', {
            label       = _U('admin_bank_id_label'),
            placeholder = _U('admin_bank_id_placeholder'),
            style       = {}
        }, function(data)
            bankIdValue = data.value
        end)
    else
        AdminSDBsPage:RegisterElement('textdisplay', {
            value = 'Bank: ' .. tostring(bank.name),
            slot = 'content'
        })
    end
    AdminSDBsPage:RegisterElement('button', {
        label = _U('admin_fetch_button'),
        style = {}
    }, function()
        local bankId = NormalizeId(bankIdValue)
        if not bankId then
            Notify(_U('admin_invalid_bank_id'), 3000)
            return
        end
        local ok, rows = BccUtils.RPC:CallAsync('Feather:Banks:Admin:ListSDBs', { bank = bankId })
        if not ok then
            Notify(_U('admin_action_failed'), 3000)
            return
        end
        -- Render interactive buttons per SDB: "<Name> — Char <owner_id>"
        AdminSDBsPage:RegisterElement('line', {
            slot  = 'content',
            style = {}
        })
        if not rows or #rows == 0 then
            AdminSDBsPage:RegisterElement('textdisplay', {
                value = _U('no_boxes_found'),
                slot  = 'content'
            })
        else
            for _, box in ipairs(rows or {}) do
                local boxName = (box.name and tostring(box.name)) or (_U('box_default_name', tostring(box.id)) or ('Box #' .. tostring(box.id)))
                local ownerId = tostring(box.owner_id or '-')
                local label   = boxName .. ' — Char ' .. ownerId

                AdminSDBsPage:RegisterElement('button', {
                    label = label,
                    style = {}
                }, function()
                    -- Admin open SDB inventory directly
                    FeatherBankMenu:Close()
                    SetNuiFocus(false, false)
                    Wait(250)
                    local okOpen = BccUtils.RPC:CallAsync('Feather:Banks:Admin:OpenSDB', { sdb_id = NormalizeId(box.id) })
                    if not okOpen then
                        Notify(_U('error_unable_open_sdb') or 'Unable to open SDB right now.', 'error', 3500)
                    end
                end)
            end
        end
        FeatherBankMenu:Open({ startupPage = AdminSDBsPage })
    end)

    AdminSDBsPage:RegisterElement('line', {
        slot = 'footer',
        style = {}
    })
    AdminSDBsPage:RegisterElement('button', {
        label = _U('back_button'),
        slot  = 'footer',
        style = {}
    }, function()
        Parent:RouteTo()
    end)
    AdminSDBsPage:RegisterElement('bottomline', {
        slot = 'footer',
        style = {}
    })
    FeatherBankMenu:Open({ startupPage = AdminSDBsPage })
end

-- Single command to open the admin menus
local adminCmd = (Config and Config.Admin and Config.Admin.command) or "bankadmin"
RegisterCommand(adminCmd, function()
    OpenBankAdminMenu()
end, false)
