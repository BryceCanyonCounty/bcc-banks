-- Admin/Banker server commands for managing bank loan rates and inspecting data

local function IsBankAdmin(src)
    devPrint('[ADMIN] IsBankAdmin called. src=', src)
    if src == 0 then
        devPrint('[ADMIN] Granting admin: source is console (0)')
        return true
    end
    -- Uncomment to enable ACE check; logs the result too
    -- if IsPlayerAceAllowed then
    --     local ace = IsPlayerAceAllowed(src, 'feather.banks.admin')
    --     devPrint('[ADMIN] ACE check feather.banks.admin =', ace and 'true' or 'false')
    --     if ace then return true end
    -- end

    local user = VORPcore.getUser(src)
    if not user then
        devPrint('[ADMIN] Deny: VORP user not found for src', src)
        return false
    end
    if not user.getUsedCharacter then
        devPrint('[ADMIN] Deny: getUsedCharacter missing on user for src', src)
        return false
    end
    local character = user.getUsedCharacter
    if not character then
        devPrint('[ADMIN] Deny: character not found for src', src)
        return false
    end

    devPrint('[ADMIN] Character group=', tostring(character.group), 'job=', tostring(character.job), 'charId=', tostring(character.charIdentifier))
    devPrint('[ADMIN] Config.adminGroups=', json.encode(Config.adminGroups or {}), 'AllowedJobs=', json.encode(Config.AllowedJobs or {}))

    -- Check VORP group against configured admin groups
    for _, group in ipairs(Config.adminGroups or {}) do
        if character.group == group then
            devPrint('[ADMIN] Granting admin by group match:', group)
            return true
        end
    end

    -- Check VORP job against allowed jobs
    for _, job in ipairs(Config.AllowedJobs or {}) do
        if character.job == job then
            devPrint('[ADMIN] Granting admin by job match:', job)
            return true
        end
    end

    devPrint('[ADMIN] Deny: no matching group/job; consider ACE or legacy role checks')
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
    local bankId = tonumber(params and params.bank)
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
    local bankId = tonumber(params and params.bank)
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
    local bankId = params and params.bank
    if not charId then
        devPrint('[ADMIN] GetCharRate invalid char id:', params and params.char)
        NotifyClient(src, _U('admin_invalid_char_id') or 'Invalid char id', 'error', 3500)
        cb(false)
        return
    end
    local row
    if bankId == nil or bankId == '' then
        -- Use bank_id = 0 to represent global rate
        row = MySQL.query.await('SELECT interest FROM `bcc_loan_interest_rates` WHERE character_id = ? AND bank_id = 0 LIMIT 1', { charId })
    else
        bankId = tonumber(bankId)
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
    local bankId = params and params.bank
    local rate = tonumber(params and params.rate)
    if not charId or not rate then
        devPrint('[ADMIN] SetCharRate invalid input charId/rate:', charId, rate)
        NotifyClient(src, _U('admin_invalid_input') or 'Invalid input', 'error', 3500)
        cb(false)
        return
    end
    if bankId == nil or bankId == '' or tonumber(bankId) == 0 then
        -- Store global rate with bank_id = 0
        MySQL.query.await('INSERT INTO `bcc_loan_interest_rates` (character_id, bank_id, interest) VALUES (?, 0, ?) ON DUPLICATE KEY UPDATE interest = VALUES(interest)', { charId, rate })
    else
        bankId = tonumber(bankId)
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
    local bankId = params and params.bank
    if not charId then
        devPrint('[ADMIN] ClearCharRate invalid char id:', params and params.char)
        NotifyClient(src, _U('admin_invalid_char_id') or 'Invalid char id', 'error', 3500)
        cb(false)
        return
    end
    if bankId == nil or bankId == '' then
        -- Clear global rate stored with bank_id = 0
        MySQL.query.await('DELETE FROM `bcc_loan_interest_rates` WHERE character_id = ? AND bank_id = 0', { charId })
    else
        bankId = tonumber(bankId)
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
    local bankId = tonumber(params and params.bank)
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
    local bankId = tonumber(params and params.bank)
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
    local bankId = tonumber(params and params.bank)
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
    local bankId = tonumber(params and params.bank)
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
