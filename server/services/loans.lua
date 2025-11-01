local MailboxAPI

local function getMailboxApi()
    if MailboxAPI then return MailboxAPI end
    local ok, api = pcall(function()
        return exports['bcc-mailbox']:getMailboxAPI()
    end)
    if ok and api then
        MailboxAPI = api
    end
    return MailboxAPI
end

local function formatCurrency(amount)
    local num = tonumber(amount) or 0
    return string.format('%.2f', num)
end

local function safeFormat(fmt, ...)
    if type(fmt) ~= 'string' then return '' end
    local ok, result = pcall(string.format, fmt, ...)
    if ok then return result end
    return fmt
end

local function formatTimestamp(value)
    if value == nil then return nil end
    local num = tonumber(value)
    if num then
        if num > 1e12 then
            num = num / 1000
        end
        return os.date('%Y-%m-%d %H:%M:%S', math.floor(num))
    end
    local str = tostring(value)
    if str == '' then return nil end
    return str
end

BccBanksInternal = BccBanksInternal or {}
BccBanksInternal.getMailboxApi = getMailboxApi
BccBanksInternal.formatCurrency = formatCurrency
BccBanksInternal.safeFormat = safeFormat
BccBanksInternal.formatTimestamp = formatTimestamp

local function getReminderConfig()
    local timing = Config.LoanTiming or {}
    local reminders = timing.DailyReminders or {}
    return timing, reminders
end

local function getSourceForCharacter(charIdentifier)
    if not charIdentifier then return nil end
    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        local user = VORPcore.getUser(src)
        if user then
            local character = user.getUsedCharacter
            if character and tonumber(character.charIdentifier) == tonumber(charIdentifier) then
                return src
            end
        end
    end
    return nil
end

local function sendDailyReminder(loanRow, info, elapsedDays, dueDays)
    local _, reminders = getReminderConfig()
    if reminders.Enabled ~= true then return end

    local outstanding = tonumber(info and info.outstanding or 0) or 0
    if outstanding <= 0 then return end

    local totalDays = (dueDays and dueDays > 0) and dueDays or elapsedDays
    local subjectFmt = reminders.MailSubject or 'Loan Payment Reminder'
    local bodyFmt = reminders.MailBody or 'Day %d of %d for your loan #%s. Outstanding balance: $%s. Please visit the bank to avoid default.'
    local notifyMsg = reminders.NotifyMessage or 'Your bank loan is still outstanding. Visit a bank today to make a payment.'
    local fromName = reminders.MailFrom or 'Bank Postmaster'

    local formattedSubject = safeFormat(subjectFmt, elapsedDays, totalDays, loanRow.id, formatCurrency(outstanding))
    local formattedBody = safeFormat(bodyFmt, elapsedDays, totalDays, loanRow.id, formatCurrency(outstanding))

    if reminders.SendMailbox then
        local mailApi = getMailboxApi()
        if mailApi then
            mailApi:SendMailToCharacter(loanRow.character_id, formattedSubject, formattedBody, { fromName = fromName })
        end
    end

    if reminders.NotifyOnline then
        local src = getSourceForCharacter(loanRow.character_id)
        if src then
            NotifyClient(src, notifyMsg, 'warning', 6000)
        end
    end
end

BccUtils.RPC:Register('Feather:Banks:GetLoans', function(params, cb, src)
    devPrint('GetLoans RPC called. src=', src, 'params=', params)

    local account_id = NormalizeId(params and params.account)
    local bank_id    = NormalizeId(params and params.bank)

    local user = VORPcore.getUser(src)
    if not user then
        NotifyClient(src, _U('error_character_not_found'), 'error', 4000)
        cb(false)
        return
    end
    local char = user.getUsedCharacter
    if not char then
        NotifyClient(src, _U('error_character_not_found'), 'error', 4000)
        cb(false)
        return
    end
    local characterId = char.charIdentifier
    if not characterId then
        NotifyClient(src, _U('error_character_not_found'), 'error', 4000)
        cb(false)
        return
    end

    local list
    if account_id then
        if not (HasAccountAccess(account_id, characterId) or IsAccountOwner(account_id, characterId)) then
            NotifyClient(src, _U('error_insufficient_access'), 'error', 4000)
            cb(false)
            return
        end
        list = GetLoansForAccount(account_id)
    elseif bank_id then
        list = GetLoansForCharacterBank(characterId, bank_id)
    else
        NotifyClient(src, _U('error_invalid_bank') or 'Invalid bank.', 'error', 4000)
        cb(false)
        return
    end
    list = list or {}
    for _, loan in ipairs(list) do
        loan.created_at_display = (BccBanksInternal and BccBanksInternal.formatTimestamp and BccBanksInternal.formatTimestamp(loan.created_at)) or formatTimestamp(loan.created_at)
        loan.amount_formatted = formatCurrency(loan.amount)
    end
    cb(true, list)
end)

BccUtils.RPC:Register('Feather:Banks:GetLoan', function(params, cb, src)
    local loan_id = NormalizeId(params and params.loan)
    if not loan_id then
        NotifyClient(src, _U('error_invalid_loan_id'), 'error', 4000)
        cb(false)
        return
    end
    local info = ComputeLoanOutstanding(loan_id)
    if not info then
        NotifyClient(src, _U('error_loan_not_found'), 'error', 4000)
        cb(false)
        return
    end
    cb(true, info)
end)

BccUtils.RPC:Register('Feather:Banks:GetLoanTransactions', function(params, cb, src)
    local loan_id = NormalizeId(params and params.loan)
    if not loan_id then
        NotifyClient(src, _U('error_invalid_loan_id'), 'error', 4000)
        cb(false)
        return
    end

    local loan = GetLoan(loan_id)
    if not loan then
        NotifyClient(src, _U('error_loan_not_found'), 'error', 4000)
        cb(false)
        return
    end

    local transactions = GetLoanTransactions(loan_id)
    for _, tx in ipairs(transactions or {}) do
        tx.amount_formatted = formatCurrency(tx.amount)
        tx.created_at_display = BccBanksInternal and BccBanksInternal.formatTimestamp and BccBanksInternal.formatTimestamp(tx.created_at) or formatTimestamp(tx.created_at)
    end

    cb(true, transactions or {})
end)

BccUtils.RPC:Register('Feather:Banks:ClaimLoanDisbursement', function(params, cb, src)
    local user = VORPcore.getUser(src)
    if not user then
        NotifyClient(src, _U('error_character_not_found'), 'error', 4000)
        cb(false)
        return
    end
    local char = user.getUsedCharacter
    if not char or not char.charIdentifier then
        NotifyClient(src, _U('error_character_not_found'), 'error', 4000)
        cb(false)
        return
    end
    local characterId = char.charIdentifier

    local loan_id    = NormalizeId(params and params.loan)
    local account_id = NormalizeId(params and params.account)
    if not loan_id or not account_id then
        NotifyClient(src, _U('error_invalid_input'), 'error', 4000)
        cb(false)
        return
    end

    local res = ClaimLoanToAccount(loan_id, account_id, characterId)
    if not res or res.status == false then
        NotifyClient(src, (res and res.message) or _U('error_unable_create_loan'), 'error', 4000)
        cb(false)
        return
    end
    NotifyClient(src, _U('success_loan_disbursed') or 'Loan funds transferred to account.', 'success', 4000)
    cb(true, res.loan)
end)

BccUtils.RPC:Register('Feather:Banks:CreateLoan', function(params, cb, src)
    devPrint('CreateLoan RPC called. src=', src, 'params=', params)

    local user = VORPcore.getUser(src)
    if not user then
        NotifyClient(src, _U('error_character_not_found'), 'error', 4000)
        cb(false)
        return
    end
    local char = user.getUsedCharacter
    if not char then
        NotifyClient(src, _U('error_character_not_found'), 'error', 4000)
        cb(false)
        return
    end
    local characterId = char.charIdentifier
    if not characterId then
        NotifyClient(src, _U('error_character_not_found'), 'error', 4000)
        cb(false)
        return
    end

    local account_id = NormalizeId(params and params.account)
    local bankId     = NormalizeId(params and params.bank)
    local amount     = tonumber(params and params.amount)
    local duration   = tonumber(params and params.duration) or 0

    if (not account_id and not bankId) or not amount or amount <= 0 then
        NotifyClient(src, _U('error_invalid_input'), 'error', 4000)
        cb(false)
        return
    end

    -- Derive bank from account if provided; otherwise require bankId
    if account_id then
        bankId = bankId or GetBankIdForAccount(account_id)
        if not (IsAccountOwner(account_id, characterId) or IsAccountAdmin(account_id, characterId)) then
            NotifyClient(src, _U('error_insufficient_access'), 'error', 4000)
            cb(false)
            return
        end
    elseif not bankId then
        NotifyClient(src, _U('error_invalid_bank') or 'Invalid bank.', 'error', 4000)
        cb(false)
        return
    end

    -- Compute interest server-side for this character (and bank)
    local interest = GetCharacterLoanInterest(characterId, bankId)
    local res = CreateLoan(account_id, characterId, amount, interest, duration, bankId)
    if not res or res.status == false then
        NotifyClient(src, res and res.message or _U('error_unable_create_loan'), 'error', 4000)
        cb(false)
        return
    end

    -- Inform user that the loan application is pending approval
    NotifyClient(src, _U('success_loan_created') or 'Loan application submitted for approval.', 'success', 4000)
    cb(true, res.loan)
end)

BccUtils.RPC:Register('Feather:Banks:GetLoanRate', function(params, cb, src)
    local user = VORPcore.getUser(src)
    if not user then
        NotifyClient(src, _U('error_character_not_found'), 'error', 4000)
        cb(false)
        return
    end
    local char = user.getUsedCharacter
    if not char then
        NotifyClient(src, _U('error_character_not_found'), 'error', 4000)
        cb(false)
        return
    end
    local characterId = char.charIdentifier
    if not characterId then
        NotifyClient(src, _U('error_character_not_found'), 'error', 4000)
        cb(false)
        return
    end
    local account_id = NormalizeId(params and params.account)
    local bankId = account_id and GetBankIdForAccount(account_id) or NormalizeId(params and params.bank)
    local rate = GetCharacterLoanInterest(characterId, bankId)
    cb(true, rate)
end)

-- Background: track in-game days passed and enforce defaults -> freeze accounts
CreateThread(function()
    while true do
        Wait(60000) -- check roughly once per real minute
        local curDay = 0
        if exports and exports.weathersync and exports.weathersync.getTime then
            local t = exports.weathersync:getTime() or {}
            curDay = tonumber(t.day) or 0
        end

        -- Fetch approved, non-defaulted loans
        local loans = MySQL.query.await('SELECT id, character_id, last_game_day, game_days_elapsed, due_game_days, status FROM `bcc_loans` WHERE `status` = "approved" AND `is_defaulted` = 0') or {}
        for _, ln in ipairs(loans) do
            local last = tonumber(ln.last_game_day or curDay)
            local elapsed = tonumber(ln.game_days_elapsed or 0)
            local due = tonumber(ln.due_game_days or 0)
            if last ~= curDay then
                local delta = (curDay - last) % 7
                local newElapsed = elapsed + delta
                MySQL.query.await('UPDATE `bcc_loans` SET `game_days_elapsed` = ?, `last_game_day` = ? WHERE `id` = ?', { newElapsed, curDay, ln.id })

                local info = ComputeLoanOutstanding(ln.id)
                if info then
                    if delta > 0 then
                        sendDailyReminder(ln, info, newElapsed, due)
                    end

                    local outstanding = tonumber(info.outstanding or 0) or 0
                    if due and due > 0 and newElapsed >= due and outstanding > 0 then
                        local mailApi = getMailboxApi()
                        if mailApi then
                            local _, reminders = getReminderConfig()
                            local fromName = reminders.MailFrom or 'Bank Postmaster'
                            local subject = 'Loan Default Notice'
                            local body = ('Your loan #%s is overdue with $%s outstanding. Visit any bank immediately to settle the debt or expect enforcement actions.'):format(
                                ln.id,
                                formatCurrency(outstanding)
                            )
                            mailApi:SendMailToCharacter(ln.character_id, subject, body, { fromName = fromName })
                        end
                        -- Mark defaulted and freeze all accounts for owner
                        MySQL.query.await('UPDATE `bcc_loans` SET `is_defaulted` = 1, `status` = "defaulted" WHERE `id` = ?', { ln.id })
                        SetOwnerAccountsFrozen(tonumber(ln.character_id), true)
                    end
                end
            end
        end
    end
end)

BccUtils.RPC:Register('Feather:Banks:RepayLoan', function(params, cb, src)
    devPrint('RepayLoan RPC called. src=', src, 'params=', params)

    local user = VORPcore.getUser(src)
    if not user then
        NotifyClient(src, _U('error_character_not_found'), 'error', 4000)
        cb(false)
        return
    end
    local char = user.getUsedCharacter
    if not char then
        NotifyClient(src, _U('error_character_not_found'), 'error', 4000)
        cb(false)
        return
    end
    local characterId = char.charIdentifier
    if not characterId then
        NotifyClient(src, _U('error_character_not_found'), 'error', 4000)
        cb(false)
        return
    end

    local loan_id   = NormalizeId(params and params.loan)
    local amount    = tonumber(params and params.amount)

    if not loan_id or not amount or amount <= 0 then
        NotifyClient(src, _U('error_invalid_input'), 'error', 4000)
        cb(false)
        return
    end

    -- Prevent repayment of loans that are not approved yet
    local loanRow = GetLoan(loan_id)
    if not loanRow then
        NotifyClient(src, _U('error_loan_not_found'), 'error', 4000)
        cb(false)
        return
    end
    local status = tostring(loanRow.status)
    local isDefaulted = status == 'defaulted' or tonumber(loanRow.is_defaulted) == 1
    if status == 'paid' then
        NotifyClient(src, _U('error_loan_already_paid') or 'Loan already fully repaid.', 'success', 4000)
        cb(false)
        return
    elseif status ~= 'approved' and not isDefaulted then
        NotifyClient(src, _U('error_loan_not_approved') or 'Loan has not been approved yet.', 'error', 4000)
        cb(false)
        return
    end

    -- Check current outstanding and prevent over/extra payments
    local info = ComputeLoanOutstanding(loan_id)
    if info and info.outstanding then
        if info.outstanding <= 0 then
            NotifyClient(src, _U('error_loan_already_paid') or 'Loan already fully repaid.', 'success', 4000)
            cb(false)
            return
        end
        if amount > info.outstanding then
            amount = info.outstanding
        end
    end

    if not amount or amount <= 0 then
        NotifyClient(src, _U('invalid_repay_amount') or 'Enter a valid repayment amount.', 'error', 4000)
        cb(false)
        return
    end

    -- Ensure the loan belongs to this character
    if tonumber(loanRow.character_id) ~= tonumber(characterId) then
        NotifyClient(src, _U('error_no_permission') or 'No permission.', 'error', 4000)
        cb(false)
        return
    end

    -- Check player has enough cash and remove it
    local currentDollars = tonumber(char.money) or 0
    if currentDollars < amount then
        NotifyClient(src, _U('error_not_enough_cash', tostring(currentDollars)) or 'Not enough cash.', 'error', 4000)
        cb(false)
        return
    end
    char.removeCurrency(0, amount)

    -- Record the repayment against the loan
    local repayDesc = _U and _U('loan_repayment_cash_desc') or 'Loan repayment from character cash'
    AddLoanTransaction(loan_id, characterId, amount, 'loan - repayment', repayDesc)

    -- If fully repaid now, mark loan as paid
    local after = ComputeLoanOutstanding(loan_id)
    if after and (after.outstanding or 0) <= 0 then
        MySQL.query.await('UPDATE `bcc_loans` SET `status` = "paid", `is_defaulted` = 0 WHERE `id` = ?', { loan_id })
        if loanRow and loanRow.character_id then
            SetOwnerAccountsFrozen(tonumber(loanRow.character_id), false)
        end
    end

    NotifyClient(src, _U('success_loan_repaid'), 'success', 4000)
    cb(true)
end)
