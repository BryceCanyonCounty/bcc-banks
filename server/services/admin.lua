-- Admin/Banker server commands for managing bank loan rates and inspecting data

local function IsBankAdmin(src)
    devPrint('[ADMIN] IsBankAdmin called. src=', src)

    local AdminCfg = (Config and Config.Admin) or {}
    local allowConsole = (AdminCfg.allowConsole ~= false) -- default true
    local useAce = (AdminCfg.useAce == true)
    local acePerm = AdminCfg.acePermission or 'feather.banks.admin'
    local groups = AdminCfg.groups or Config.adminGroups or {}
    local jobs = AdminCfg.jobs or Config.AllowedJobs or {}

    if src == 0 and allowConsole then
        devPrint('[ADMIN] Granting admin: source is console (0)')
        return true
    end

    if useAce and IsPlayerAceAllowed then
        local ace = IsPlayerAceAllowed(src, acePerm)
        devPrint('[ADMIN] ACE check', acePerm, '=', ace and 'true' or 'false')
        if ace then return true end
    end

    local user = VORPcore.getUser(src)
    if not user or not user.getUsedCharacter then
        devPrint('[ADMIN] Deny: VORP user/character not found for src', src)
        return false
    end
    local character = user.getUsedCharacter

    devPrint('[ADMIN] Character group=', tostring(character.group), 'job=', tostring(character.job), 'charId=', tostring(character.charIdentifier))
    devPrint('[ADMIN] Admin groups=', json.encode(groups), 'jobs=', json.encode(jobs))

    -- Group check
    for _, group in ipairs(groups) do
        if character.group == group then
            devPrint('[ADMIN] Granting admin by group match:', group)
            return true
        end
    end

    -- Job check
    for _, job in ipairs(jobs) do
        if character.job == job then
            devPrint('[ADMIN] Granting admin by job match:', job)
            return true
        end
    end

    devPrint('[ADMIN] Deny: no matching ACE/group/job')
    return false
end

BccUtils.RPC:Register('Feather:Banks:CheckAdmin', function(_, cb, src)
    devPrint('[DEV] RPC Feather:Banks:CheckAdmin called by src=' .. tostring(src))
    local allowed = IsBankAdmin(src) == true
    -- Return (ok=true, payload=allowed) to match other RPC patterns
    cb(true, allowed)
end)

-- RPC: get/set bank rate
BccUtils.RPC:Register('Feather:Banks:Admin:GetBankRate', function(params, cb, src)
    if not IsBankAdmin(src) then
        devPrint('[ADMIN] GetBankRate denied: no permission for src', src)
        NotifyClient(src, _U('admin_no_permission') or 'No permission', 'error', 3500)
        cb(false)
        return
    end
    local bankId = NormalizeId(params and params.bank)
    if not bankId then
        devPrint('[ADMIN] GetBankRate invalid bank id:', params and params.bank)
        NotifyClient(src, _U('admin_invalid_bank_id') or 'Invalid bank id', 'error', 3500)
        cb(false)
        return
    end
    local row = MySQL.query.await('SELECT interest FROM `bcc_bank_interest_rates` WHERE bank_id = ? LIMIT 1', { bankId })
    local rate = row and row[1] and row[1].interest
    cb(true, rate and tonumber(rate) or nil)
end)

BccUtils.RPC:Register('Feather:Banks:Admin:SetBankRate', function(params, cb, src)
    if not IsBankAdmin(src) then
        devPrint('[ADMIN] SetBankRate denied: no permission for src', src)
        NotifyClient(src, _U('admin_no_permission') or 'No permission', 'error', 3500)
        cb(false)
        return
    end
    local bankId = NormalizeId(params and params.bank)
    local rate = tonumber(params and params.rate)
    if not bankId or not rate then
        devPrint('[ADMIN] SetBankRate invalid input bankId/rate:', bankId, rate)
        NotifyClient(src, _U('admin_invalid_input') or 'Invalid input', 'error', 3500)
        cb(false)
        return
    end
    MySQL.query.await('INSERT INTO `bcc_bank_interest_rates` (bank_id, interest) VALUES (?, ?) ON DUPLICATE KEY UPDATE interest = VALUES(interest)', { bankId, rate })
    cb(true)
end)

-- RPC: get/set/clear char rate
BccUtils.RPC:Register('Feather:Banks:Admin:GetCharRate', function(params, cb, src)
    if not IsBankAdmin(src) then
        devPrint('[ADMIN] GetCharRate denied: no permission for src', src)
        NotifyClient(src, _U('admin_no_permission') or 'No permission', 'error', 3500)
        cb(false)
        return
    end
    local charId = tonumber(params and params.char)
    local bankId = NormalizeId(params and params.bank)
    if not charId then
        devPrint('[ADMIN] GetCharRate invalid char id:', params and params.char)
        NotifyClient(src, _U('admin_invalid_char_id') or 'Invalid char id', 'error', 3500)
        cb(false)
        return
    end
    local row
    if not bankId or bankId == '0' then
        -- Use bank_id = '0' to represent global rate
        row = MySQL.query.await('SELECT interest FROM `bcc_loan_interest_rates` WHERE character_id = ? AND bank_id = ? LIMIT 1', { charId, '0' })
    else
        row = MySQL.query.await('SELECT interest FROM `bcc_loan_interest_rates` WHERE character_id = ? AND bank_id = ? LIMIT 1', { charId, bankId })
    end
    local rate = row and row[1] and row[1].interest
    cb(true, rate and tonumber(rate) or nil)
end)

BccUtils.RPC:Register('Feather:Banks:Admin:SetCharRate', function(params, cb, src)
    if not IsBankAdmin(src) then
        devPrint('[ADMIN] SetCharRate denied: no permission for src', src)
        NotifyClient(src, _U('admin_no_permission') or 'No permission', 'error', 3500)
        cb(false)
        return
    end
    local charId = tonumber(params and params.char)
    local bankId = NormalizeId(params and params.bank)
    local rate = tonumber(params and params.rate)
    if not charId or not rate then
        devPrint('[ADMIN] SetCharRate invalid input charId/rate:', charId, rate)
        NotifyClient(src, _U('admin_invalid_input') or 'Invalid input', 'error', 3500)
        cb(false)
        return
    end
    if not bankId or bankId == '0' then
        -- Store global rate with bank_id = '0'
        MySQL.query.await('INSERT INTO `bcc_loan_interest_rates` (character_id, bank_id, interest) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE interest = VALUES(interest)', { charId, '0', rate })
    else
        MySQL.query.await('INSERT INTO `bcc_loan_interest_rates` (character_id, bank_id, interest) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE interest = VALUES(interest)', { charId, bankId, rate })
    end
    cb(true)
end)

BccUtils.RPC:Register('Feather:Banks:Admin:ClearCharRate', function(params, cb, src)
    if not IsBankAdmin(src) then
        devPrint('[ADMIN] ClearCharRate denied: no permission for src', src)
        NotifyClient(src, _U('admin_no_permission') or 'No permission', 'error', 3500)
        cb(false)
        return
    end
    local charId = tonumber(params and params.char)
    local bankId = NormalizeId(params and params.bank)
    if not charId then
        devPrint('[ADMIN] ClearCharRate invalid char id:', params and params.char)
        NotifyClient(src, _U('admin_invalid_char_id') or 'Invalid char id', 'error', 3500)
        cb(false)
        return
    end
    if not bankId or bankId == '0' then
        -- Clear global rate stored with bank_id = '0'
        MySQL.query.await('DELETE FROM `bcc_loan_interest_rates` WHERE character_id = ? AND bank_id = ?', { charId, '0' })
    else
        MySQL.query.await('DELETE FROM `bcc_loan_interest_rates` WHERE character_id = ? AND bank_id = ?', { charId, bankId })
    end
    cb(true)
end)

-- RPC: lists
BccUtils.RPC:Register('Feather:Banks:Admin:ListAccounts', function(params, cb, src)
    if not IsBankAdmin(src) then
        devPrint('[ADMIN] ListAccounts denied: no permission for src', src)
        NotifyClient(src, _U('admin_no_permission') or 'No permission', 'error', 3500)
        cb(false)
        return
    end
    local bankId = NormalizeId(params and params.bank)
    if not bankId then
        devPrint('[ADMIN] ListAccounts invalid bank id:', params and params.bank)
        NotifyClient(src, _U('admin_invalid_bank_id') or 'Invalid bank id', 'error', 3500)
        cb(false)
        return
    end
    local rows = MySQL.query.await('SELECT id, name, owner_id, cash, gold FROM `bcc_accounts` WHERE bank_id = ? ORDER BY id DESC', { bankId })
    cb(true, rows or {})
end)

BccUtils.RPC:Register('Feather:Banks:Admin:ListLoans', function(params, cb, src)
    if not IsBankAdmin(src) then
        devPrint('[ADMIN] ListLoans denied: no permission for src', src)
        NotifyClient(src, _U('admin_no_permission') or 'No permission', 'error', 3500)
        cb(false)
        return
    end
    local bankId = NormalizeId(params and params.bank)
    if not bankId then
        devPrint('[ADMIN] ListLoans invalid bank id:', params and params.bank)
        NotifyClient(src, _U('admin_invalid_bank_id') or 'Invalid bank id', 'error', 3500)
        cb(false)
        return
    end
    local rows = MySQL.query.await([[ 
        SELECT l.*
        FROM `bcc_loans` AS l
        LEFT JOIN `bcc_accounts` AS a ON l.account_id = a.id
        WHERE (a.bank_id = ? OR l.bank_id = ?)
        ORDER BY l.created_at DESC
    ]], { bankId, bankId })
    cb(true, rows or {})
end)

-- List only pending loans by bank
BccUtils.RPC:Register('Feather:Banks:Admin:ListPendingLoans', function(params, cb, src)
    if not IsBankAdmin(src) then
        devPrint('[ADMIN] ListPendingLoans denied: no permission for src', src)
        NotifyClient(src, _U('admin_no_permission') or 'No permission', 'error', 3500)
        cb(false)
        return
    end
    local bankId = NormalizeId(params and params.bank)
    if not bankId then
        devPrint('[ADMIN] ListPendingLoans invalid bank id:', params and params.bank)
        NotifyClient(src, _U('admin_invalid_bank_id') or 'Invalid bank id', 'error', 3500)
        cb(false)
        return
    end
    local rows = MySQL.query.await([[ 
        SELECT l.*
        FROM `bcc_loans` AS l
        LEFT JOIN `bcc_accounts` AS a ON l.account_id = a.id
        WHERE (a.bank_id = ? OR l.bank_id = ?) AND l.status = "pending"
        ORDER BY l.created_at DESC
    ]], { bankId, bankId })
    cb(true, rows or {})
end)

-- Approve a loan
BccUtils.RPC:Register('Feather:Banks:Admin:ApproveLoan', function(params, cb, src)
    if not IsBankAdmin(src) then
        devPrint('[ADMIN] ApproveLoan denied: no permission for src', src)
        NotifyClient(src, _U('admin_no_permission') or 'No permission', 'error', 3500)
        cb(false)
        return
    end
    local loanId = tonumber(params and params.loan)
    if not loanId then
        NotifyClient(src, _U('admin_invalid_loan_id') or 'Invalid loan id', 'error', 3500)
        cb(false)
        return
    end
    local user = VORPcore.getUser(src)
    if not user or not user.getUsedCharacter then
        NotifyClient(src, _U('error_character_not_found') or 'Character not found', 'error', 3500)
        cb(false)
        return
    end
    local approver = user.getUsedCharacter.charIdentifier
    local res = ApproveLoan(loanId, approver)
    if res and res.status then
        NotifyClient(src, _U('admin_loan_approved') or 'Loan approved and disbursed.', 'success', 3000)
        cb(true)
    else
        NotifyClient(src, (res and res.message) or _U('admin_failed_approve_loan') or 'Failed to approve loan.', 'error', 3500)
        cb(false)
    end
end)

-- Reject a loan
BccUtils.RPC:Register('Feather:Banks:Admin:RejectLoan', function(params, cb, src)
    if not IsBankAdmin(src) then
        devPrint('[ADMIN] RejectLoan denied: no permission for src', src)
        NotifyClient(src, _U('admin_no_permission') or 'No permission', 'error', 3500)
        cb(false)
        return
    end
    local loanId = tonumber(params and params.loan)
    if not loanId then
        NotifyClient(src, _U('admin_invalid_loan_id') or 'Invalid loan id', 'error', 3500)
        cb(false)
        return
    end
    local user = VORPcore.getUser(src)
    if not user or not user.getUsedCharacter then
        NotifyClient(src, _U('error_character_not_found') or 'Character not found', 'error', 3500)
        cb(false)
        return
    end
    local approver = user.getUsedCharacter.charIdentifier
    local res = RejectLoan(loanId, approver)
    if res and res.status then
        NotifyClient(src, _U('admin_loan_rejected') or 'Loan rejected.', 'success', 3000)
        cb(true)
    else
        NotifyClient(src, (res and res.message) or _U('admin_failed_reject_loan') or 'Failed to reject loan.', 'error', 3500)
        cb(false)
    end
end)

BccUtils.RPC:Register('Feather:Banks:Admin:ListSDBs', function(params, cb, src)
    if not IsBankAdmin(src) then
        devPrint('[ADMIN] ListSDBs denied: no permission for src', src)
        NotifyClient(src, _U('admin_no_permission') or 'No permission', 'error', 3500)
        cb(false)
        return
    end
    local bankId = NormalizeId(params and params.bank)
    if not bankId then
        devPrint('[ADMIN] ListSDBs invalid bank id:', params and params.bank)
        NotifyClient(src, _U('admin_invalid_bank_id') or 'Invalid bank id', 'error', 3500)
        cb(false)
        return
    end
    local rows = MySQL.query.await('SELECT id, name, owner_id, size FROM `bcc_safety_deposit_boxes` WHERE bank_id = ? ORDER BY id DESC', { bankId })
    cb(true, rows or {})
end)

-- Legacy admin commands were removed in favor of the /bankadmin UI.

-- Admin: Get/Set bank opening hours
BccUtils.RPC:Register('Feather:Banks:Admin:GetHours', function(params, cb, src)
    if not IsBankAdmin(src) then
        NotifyClient(src, _U('admin_no_permission') or 'No permission', 'error', 3500)
        cb(false)
        return
    end
    local bankId = NormalizeId(params and params.bank)
    if not bankId then
        NotifyClient(src, _U('admin_invalid_bank_id') or 'Invalid bank id', 'error', 3500)
        cb(false)
        return
    end
    local row = MySQL.query.await('SELECT hours_active, open_hour, close_hour FROM `bcc_banks` WHERE id = ? LIMIT 1', { bankId })
    local data = row and row[1]
    if not data then
        cb(true, { hours_active = false, open_hour = nil, close_hour = nil })
        return
    end
    cb(true, { hours_active = (data.hours_active == 1 or data.hours_active == true), open_hour = data.open_hour, close_hour = data.close_hour })
end)

BccUtils.RPC:Register('Feather:Banks:Admin:SetHours', function(params, cb, src)
    if not IsBankAdmin(src) then
        NotifyClient(src, _U('admin_no_permission') or 'No permission', 'error', 3500)
        cb(false)
        return
    end
    local bankId = NormalizeId(params and params.bank)
    local active = params and params.active
    local openH = tonumber(params and params.open)
    local closeH = tonumber(params and params.close)
    if not bankId or openH == nil or closeH == nil then
        NotifyClient(src, _U('admin_invalid_hours_input') or 'Enter valid bank id and hours.', 'error', 3500)
        cb(false)
        return
    end
    if openH < 0 or openH > 23 or closeH < 0 or closeH > 23 then
        NotifyClient(src, _U('admin_hours_range_error') or 'Hours must be 0-23.', 'error', 3500)
        cb(false)
        return
    end
    local actv
    if type(active) == 'boolean' then
        actv = active and 1 or 0
    elseif type(active) == 'number' then
        actv = (active ~= 0) and 1 or 0
    else
        -- Keep current when not provided: fetch existing
        local row = MySQL.query.await('SELECT hours_active FROM `bcc_banks` WHERE id = ? LIMIT 1', { bankId })
        actv = (row and row[1] and (row[1].hours_active == 1 or row[1].hours_active == true)) and 1 or 0
    end
    MySQL.query.await('UPDATE `bcc_banks` SET hours_active = ?, open_hour = ?, close_hour = ? WHERE id = ?', { actv, openH, closeH, bankId })
    -- Notify all clients to refresh bank data
    TriggerClientEvent('Feather:Banks:Refresh', -1)
    cb(true)
end)

BccUtils.RPC:Register('Feather:Banks:Admin:ToggleHours', function(params, cb, src)
    if not IsBankAdmin(src) then
        NotifyClient(src, _U('admin_no_permission') or 'No permission', 'error', 3500)
        cb(false)
        return
    end
    local bankId = NormalizeId(params and params.bank)
    local active = params and params.active
    if not bankId or type(active) ~= 'boolean' then
        NotifyClient(src, _U('admin_invalid_hours_toggle') or 'Enter valid bank id and toggle.', 'error', 3500)
        cb(false)
        return
    end
    local actv = active and 1 or 0
    MySQL.query.await('UPDATE `bcc_banks` SET hours_active = ? WHERE id = ?', { actv, bankId })
    TriggerClientEvent('Feather:Banks:Refresh', -1)
    cb(true)
end)
