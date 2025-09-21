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
            local label = "#" .. tostring(bank.id) .. " — " .. tostring(bank.name)
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
        value = tostring(bank.name) .. " (#" .. tostring(bank.id) .. ")",
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
        Parent:RouteTo()
    end)
    Hub:RegisterElement("bottomline", {
        slot  = "footer",
        style = {}
    })
    FeatherBankMenu:Open({ startupPage = Hub })
end

function OpenAdminHoursMenu(Parent, bank)
    local Page = FeatherBankMenu:RegisterPage('bank:page:admin:hours')
    Page:RegisterElement('header', { value = _U('admin_hours_header') or 'Hours', slot = 'header' })
    Page:RegisterElement('subheader', { value = _U('admin_hours_subheader') or 'Configure opening hours', slot = 'header' })
    Page:RegisterElement('line', { slot = 'header', style = {} })

    local bankIdValue = bank and tostring(bank.id) or ''
    local openVal, closeVal = '', ''
    local hoursActive = false

    if not bank then
        Page:RegisterElement('input', { label = _U('admin_bank_id_label'), placeholder = _U('admin_bank_id_placeholder'), style = {} }, function(data)
            bankIdValue = data.value
        end)
    else
        Page:RegisterElement('textdisplay', { value = 'Bank: ' .. tostring(bank.name) .. ' (#' .. tostring(bank.id) .. ')', slot = 'content' })
    end

    -- Prefetch hours (no fetch button)
    do
        local bankId = NormalizeId(bankIdValue) or (bank and NormalizeId(bank.id))
        if bankId then
            local ok, data = BccUtils.RPC:CallAsync('Feather:Banks:Admin:GetHours', { bank = bankId })
            if ok and data then
                hoursActive = data.hours_active and true or false
                openVal = tostring(data.open_hour or '')
                closeVal = tostring(data.close_hour or '')
                local status = hoursActive and (_U('admin_hours_active_yes') or 'Hours Active: Yes') or (_U('admin_hours_active_no') or 'Hours Active: No')
                local info = string.format('%s | Open: %s | Close: %s', status, openVal ~= '' and openVal or '—', closeVal ~= '' and closeVal or '—')
                Page:RegisterElement('textdisplay', { value = info, slot = 'content' })
            end
        end
    end

    -- Toggle for hours active
    Page:RegisterElement('toggle', {
        label = _U('admin_manage_hours_button') or 'Manage Hours',
        start = hoursActive,
        slot = 'content',
    }, function(data)
        local bankId = NormalizeId(bankIdValue) or (bank and NormalizeId(bank.id))
        if not bankId then Notify(_U('admin_invalid_bank_id'), 3000) return end
        local ok = BccUtils.RPC:CallAsync('Feather:Banks:Admin:ToggleHours', { bank = bankId, active = data.value and true or false })
        Notify(ok and (data.value and (_U('admin_hours_enabled') or 'Hours enabled.') or (_U('admin_hours_disabled') or 'Hours disabled.')) or _U('admin_action_failed'), ok and 'success' or 'error', 3500)
    end)

    -- Inputs for open/close with placeholders showing current
    Page:RegisterElement('input', { label = _U('admin_open_hour_label') or 'Open Hour (0-23)', placeholder = (openVal ~= '' and openVal or '7'), style = {} }, function(data)
        openVal = data.value
    end)
    Page:RegisterElement('input', { label = _U('admin_close_hour_label') or 'Close Hour (0-23)', placeholder = (closeVal ~= '' and closeVal or '21'), style = {} }, function(data)
        closeVal = data.value
    end)
    Page:RegisterElement('button', { label = _U('admin_set_hours_button') or 'Set Hours', style = {} }, function()
        local bankId = NormalizeId(bankIdValue) or (bank and NormalizeId(bank.id))
        local openH = tonumber(openVal)
        local closeH = tonumber(closeVal)
        if not bankId or openH == nil or closeH == nil then Notify(_U('admin_invalid_hours_input') or 'Enter valid bank/hours', 3000) return end
        local ok = BccUtils.RPC:CallAsync('Feather:Banks:Admin:SetHours', { bank = bankId, open = openH, close = closeH })
        Notify(ok and (_U('admin_hours_updated') or 'Hours updated.') or _U('admin_action_failed'), ok and 'success' or 'error', 3500)
    end)

    Page:RegisterElement('line', { slot = 'footer', style = {} })
    Page:RegisterElement('button', { label = _U('back_button'), slot = 'footer', style = {} }, function()
        Parent:RouteTo()
    end)
    Page:RegisterElement('bottomline', { slot = 'footer', style = {} })
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
        AdminRatesPage:RegisterElement('textdisplay', { value = 'Bank: ' .. tostring(bank.name) .. ' (#' .. tostring(bank.id) .. ')', slot = 'content' })
    end
    AdminRatesPage:RegisterElement('button', {
        label = _U('admin_get_bank_rate_button'),
        style = {}
    }, function()
        local bankId = NormalizeId(bankIdValue)
        if not bankId then Notify(_U('admin_invalid_bank_id'), 3000) return end
        local ok, rate = BccUtils.RPC:CallAsync('Feather:Banks:Admin:GetBankRate', { bank = bankId })
        local msg = ok and (_U('admin_current_rate') .. ' ' .. (rate and toFixed(rate, 2) .. '%' or _U('admin_rate_not_set'))) or _U('admin_action_failed')
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
        if not bankId or not rate then Notify(_U('admin_invalid_input'), 3000) return end
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
        if not charId then Notify(_U('admin_invalid_char_id'), 3000) return end
        local ok, rate = BccUtils.RPC:CallAsync('Feather:Banks:Admin:GetCharRate', { char = charId, bank = bankIdValue })
        local msg = ok and (_U('admin_current_rate') .. ' ' .. (rate and toFixed(rate, 2) .. '%' or _U('admin_rate_not_set'))) or _U('admin_action_failed')
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
        if not charId or not rate then Notify(_U('admin_invalid_input'), 3000) return end
        local ok = BccUtils.RPC:CallAsync('Feather:Banks:Admin:SetCharRate', { char = charId, bank = bankIdValue, rate = rate })
        Notify(ok and _U('admin_rate_updated') or _U('admin_action_failed'), ok and 'success' or 'error', 3500)
    end)
    AdminCharRatesPage:RegisterElement('button', {
        label = _U('admin_clear_char_rate_button'),
        style = {}
    }, function()
        local charId = tonumber(charIdValue)
        if not charId then Notify(_U('admin_invalid_char_id'), 3000) return end
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

local function renderSimpleList(list, headers)
    local html = '<div style="padding:8px;">'
    html = html .. '<table style="width:100%; border-collapse:collapse;">'
    html = html .. '<thead><tr>'
    for _, h in ipairs(headers) do
        html = html .. '<th style="text-align:left; padding:6px 4px;">' .. h .. '</th>'
    end
    html = html .. '</tr></thead><tbody>'
    for _, row in ipairs(list or {}) do
        html = html .. '<tr>'
        for _, key in ipairs(headers.keys or {}) do
            html = html .. '<td style="padding:6px 4px;">' .. tostring(row[key] or '') .. '</td>'
        end
        html = html .. '</tr>'
    end
    html = html .. '</tbody></table></div>'
    return html
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
    if not bank then
        AdminAccountsPage:RegisterElement('input', {
            label       = _U('admin_bank_id_label'),
            placeholder = _U('admin_bank_id_placeholder'),
            style       = {}
        }, function(data)
            bankIdValue = data.value
        end)
    else
        AdminAccountsPage:RegisterElement('textdisplay', { value = 'Bank: ' .. tostring(bank.name) .. ' (#' .. tostring(bank.id) .. ')', slot = 'content' })
    end
    AdminAccountsPage:RegisterElement('button', {
        label = _U('admin_fetch_button'),
        style = {}
    }, function()
        local bankId = NormalizeId(bankIdValue)
        if not bankId then Notify(_U('admin_invalid_bank_id'), 3000) return end
        local ok, rows = BccUtils.RPC:CallAsync('Feather:Banks:Admin:ListAccounts', { bank = bankId })
        if not ok then Notify(_U('admin_action_failed'), 3000) return end
        local headers = { _U('admin_table_id'), _U('admin_table_name'), _U('admin_table_owner'), _U('admin_table_cash'), _U('admin_table_gold') }
        local html = renderSimpleList(rows or {}, setmetatable(headers, { __index = { keys = { 'id', 'name', 'owner_id', 'cash', 'gold' } } }))
        AdminAccountsPage:RegisterElement('html', {
            value = { html },
            slot  = 'content'
        })
        FeatherBankMenu:Open({ startupPage = AdminAccountsPage })
    end)

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
        end)
    else
        AdminLoansPage:RegisterElement('textdisplay', { value = 'Bank: ' .. tostring(bank.name) .. ' (#' .. tostring(bank.id) .. ')', slot = 'content' })
    end
    AdminLoansPage:RegisterElement('button', {
        label = _U('admin_fetch_button'),
        style = {}
    }, function()
        local bankId = NormalizeId(bankIdValue)
        if not bankId then Notify(_U('admin_invalid_bank_id'), 3000) return end
        local ok, rows = BccUtils.RPC:CallAsync('Feather:Banks:Admin:ListLoans', { bank = bankId })
        if not ok then Notify(_U('admin_action_failed'), 3000) return end
        local headers = { _U('admin_table_id'), _U('admin_table_account'), _U('admin_table_amount'), _U('admin_table_interest'), _U('admin_table_duration'), _U('admin_table_created') }
        local html = renderSimpleList(rows or {}, setmetatable(headers, { __index = { keys = { 'id', 'account_id', 'amount', 'interest', 'duration', 'created_at' } } }))
        AdminLoansPage:RegisterElement('html', {
            value = { html },
            slot  = 'content'
        })
        FeatherBankMenu:Open({ startupPage = AdminLoansPage })
    end)

    -- Pending loans with Approve/Reject actions
    AdminLoansPage:RegisterElement('button', {
        label = _U('admin_fetch_pending_button') or 'Fetch Pending Loans',
        style = {}
    }, function()
        local bankId = NormalizeId(bankIdValue)
        if not bankId then Notify(_U('admin_invalid_bank_id'), 3000) return end
        local ok, rows = BccUtils.RPC:CallAsync('Feather:Banks:Admin:ListPendingLoans', { bank = bankId })
        if not ok then Notify(_U('admin_action_failed'), 3000) return end

        -- Render a simple interactive list
        AdminLoansPage:RegisterElement('line', { slot = 'content', style = {} })
        for _, r in ipairs(rows or {}) do
            local label = '#' .. tostring(r.id)
                .. ' | ' .. _U('admin_table_account') .. ' ' .. tostring(r.account_id or '-')
                .. ' | $' .. tostring(r.amount)
                .. ' | ' .. tostring(r.interest) .. '%'
                .. ' | ' .. tostring(r.duration) .. ' ' .. (_U('admin_months_short') or 'mo')
            AdminLoansPage:RegisterElement('button', {
                label = label,
                style = {}
            }, function()
                local Action = FeatherBankMenu:RegisterPage('bank:page:admin:loan:' .. tostring(r.id))
                Action:RegisterElement('header', {
                    value = _U('admin_loan_header', tostring(r.id)) or ('Loan #' .. tostring(r.id)),
                    slot  = 'header'
                })
                Action:RegisterElement('subheader', {
                    value = label,
                    slot  = 'header'
                })
                Action:RegisterElement('line', {
                    slot  = 'content',
                    style = {}
                })
                Action:RegisterElement('button', {
                    label = _U('admin_approve_button') or 'Approve',
                    style = {}
                }, function()
                    local okA = BccUtils.RPC:CallAsync('Feather:Banks:Admin:ApproveLoan', { loan = NormalizeId(r.id) })
                    if okA then Notify(_U('admin_approved_notify') or 'Approved', 2500) end
                    OpenAdminLoansMenu(Parent, bank)
                end)
                Action:RegisterElement('button', {
                    label = _U('admin_reject_button') or 'Reject',
                    style = {}
                }, function()
                    local okR = BccUtils.RPC:CallAsync('Feather:Banks:Admin:RejectLoan', { loan = NormalizeId(r.id) })
                    if okR then Notify(_U('admin_rejected_notify') or 'Rejected', 2500) end
                    OpenAdminLoansMenu(Parent, bank)
                end)
                Action:RegisterElement('line', {
                    slot  = 'footer',
                    style = {}
                })
                Action:RegisterElement('button', {
                    label = _U('back_button'),
                    slot  = 'footer',
                    style = {}
                }, function()
                    AdminLoansPage:RouteTo()
                end)
                Action:RegisterElement('bottomline', {
                    slot  = 'footer',
                    style = {}
                })
                FeatherBankMenu:Open({ startupPage = Action })
            end)
        end
        FeatherBankMenu:Open({ startupPage = AdminLoansPage })
    end)

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
        AdminSDBsPage:RegisterElement('textdisplay', { value = 'Bank: ' .. tostring(bank.name) .. ' (#' .. tostring(bank.id) .. ')', slot = 'content' })
    end
    AdminSDBsPage:RegisterElement('button', {
        label = _U('admin_fetch_button'),
        style = {}
    }, function()
        local bankId = NormalizeId(bankIdValue)
        if not bankId then Notify(_U('admin_invalid_bank_id'), 3000) return end
        local ok, rows = BccUtils.RPC:CallAsync('Feather:Banks:Admin:ListSDBs', { bank = bankId })
        if not ok then Notify(_U('admin_action_failed'), 3000) return end
        local html = renderSimpleList(rows or {}, setmetatable({ 'ID', 'Name', 'Owner', 'Size' }, { __index = { keys = { 'id', 'name', 'owner_id', 'size' } } }))
        AdminSDBsPage:RegisterElement('html', {
            value = { html },
            slot  = 'content'
        })
        FeatherBankMenu:Open({ startupPage = AdminSDBsPage })
    end)

    AdminSDBsPage:RegisterElement('line', { slot = 'footer', style = {} })
    AdminSDBsPage:RegisterElement('button', {
        label = _U('back_button'),
        slot  = 'footer',
        style = {}
    }, function()
        Parent:RouteTo()
    end)
    AdminSDBsPage:RegisterElement('bottomline', { slot = 'footer', style = {} })
    FeatherBankMenu:Open({ startupPage = AdminSDBsPage })
end

-- Single command to open the admin menus
local adminCmd = (Config and Config.Admin and Config.Admin.command) or "bankadmin"
RegisterCommand(adminCmd, function()
    OpenBankAdminMenu()
end, false)
