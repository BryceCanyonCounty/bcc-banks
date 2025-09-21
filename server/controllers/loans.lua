function CreateLoan(account_id, character_id, amount, interest, duration, bank_id)
    if (not account_id and not bank_id) or not character_id or not amount or amount <= 0 then
        return { status = false, message = 'Invalid loan data.' }
    end

    -- Duration is in months from UI; compute due in game days (30 days per month) unless overridden
    local months = tonumber(duration) or 0
    local due_game_days = months * 30
    local timingCfg = Config.LoanTiming or {}
    local overrideDays = tonumber(timingCfg.DaysUntilDefault or 0)
    if overrideDays and overrideDays > 0 then
        due_game_days = overrideDays
    end
    if due_game_days < 1 then
        due_game_days = 1
    end

    -- Seed last_game_day from weathersync so we can track days passed
    local day = 0
    if exports and exports.weathersync and exports.weathersync.getTime then
        local t = exports.weathersync:getTime() or {}
        day = tonumber(t.day) or 0
    end

    local loanId = BccUtils.UUID()
    local loanRows = MySQL.query.await(
        'INSERT INTO `bcc_loans` (id, account_id, bank_id, character_id, amount, interest, duration, status, last_game_day, game_days_elapsed, due_game_days) VALUES (?, ?, ?, ?, ?, ?, ?, \'pending\', ?, 0, ?) RETURNING *;',
        { loanId, account_id, bank_id, character_id, amount, interest or 0, months, day, due_game_days }
    )

    local loan = loanRows and loanRows[1]
    if not loan then
        return { status = false, message = 'Failed to create loan.' }
    end

    return { status = true, loan = loan }
end

function GetLoan(loan_id)
    local row = MySQL.query.await('SELECT * FROM `bcc_loans` WHERE `id` = ? LIMIT 1;', { loan_id })
    return row and row[1]
end

function GetLoansForAccount(account_id)
    local rows = MySQL.query.await('SELECT * FROM `bcc_loans` WHERE `account_id` = ? ORDER BY `created_at` DESC;', { account_id })
    return rows or {}
end

-- New: list loans by character and bank (no account)
function GetLoansForCharacterBank(character_id, bank_id)
    local rows = MySQL.query.await('SELECT * FROM `bcc_loans` WHERE `character_id` = ? AND `bank_id` = ? ORDER BY `created_at` DESC;', { character_id, bank_id })
    return rows or {}
end

function ComputeLoanOutstanding(loan_id)
    local loan = GetLoan(loan_id)
    if not loan then return nil end
    local totalDue = (tonumber(loan.amount) or 0) * (1 + ((tonumber(loan.interest) or 0) / 100))
    local repaid = SumLoanRepayments(loan_id)
    local outstanding = totalDue - repaid
    if outstanding < 0 then outstanding = 0 end
    return {
        total_due = totalDue,
        repaid = repaid,
        outstanding = outstanding,
        loan = loan
    }
end

function RepayLoan(loan_id, account_id, character_id, amount)
    if not loan_id or not account_id or not character_id or not amount or amount <= 0 then
        return { status = false, message = 'Invalid repayment data.' }
    end

    -- Prevent additional payments if already fully repaid
    local info = ComputeLoanOutstanding(loan_id)
    if info and (info.outstanding or 0) <= 0 then
        return { status = false, message = 'Loan already fully repaid.' }
    end
    if info and amount > info.outstanding then
        amount = info.outstanding
    end
    if not amount or amount <= 0 then
        return { status = false, message = 'Invalid repayment amount.' }
    end

    -- Withdraw from account to repay the loan
    local ok = WithdrawCash(account_id, amount)
    if not ok then
        return { status = false, message = 'Insufficient account funds.' }
    end

    -- Record the repayment against the loan
    AddLoanTransaction(loan_id, character_id, amount, 'loan - repayment', 'Loan repayment from account')

    -- Mark loan paid if fully repaid
    local after = ComputeLoanOutstanding(loan_id)
    if after and (after.outstanding or 0) <= 0 then
        MySQL.query.await('UPDATE `bcc_loans` SET `status` = "paid" WHERE `id` = ?', { loan_id })
    end

    return { status = true }
end

-- Approve a loan: disburse funds and set status/approver metadata
function ApproveLoan(loan_id, approver_char_id)
    local loan = GetLoan(loan_id)
    if not loan then return { status = false, message = 'Loan not found.' } end
    if loan.status == 'approved' then return { status = true, loan = loan } end
    if loan.status == 'rejected' or loan.is_defaulted == 1 then
        return { status = false, message = 'Cannot approve rejected/defaulted loan.' }
    end

    -- Disbursement: if account linked, deposit now; otherwise leave pending for player claim
    local amt = tonumber(loan.amount) or 0
    if loan.account_id then
        local ok = DepositCash(loan.account_id, amt)
        if not ok then
            return { status = false, message = 'Failed to disburse funds to account.' }
        end
        AddLoanTransaction(loan.id, loan.character_id, amt, 'loan - disbursement', 'Loan disbursed to account')
        MySQL.query.await('UPDATE `bcc_loans` SET `disbursed_account_id` = ?, `disbursed_at` = NOW() WHERE `id` = ?', { loan.account_id, loan.id })
    else
        -- No immediate disbursement; player can claim to their chosen account later
    end

    -- Capture current game day at approval time
    local day = loan.last_game_day or 0
    if exports and exports.weathersync and exports.weathersync.getTime then
        local t = exports.weathersync:getTime() or {}
        day = tonumber(t.day) or day or 0
    end

    MySQL.query.await('UPDATE `bcc_loans` SET `status` = \'approved\', `approved_by` = ?, `approved_at` = NOW(), `last_game_day` = ? WHERE `id` = ?', { approver_char_id, day, loan_id })
    local updated = GetLoan(loan_id)
    return { status = true, loan = updated }
end

-- Claim approved loan funds into a selected account
function ClaimLoanToAccount(loan_id, account_id, character_id)
    local loan = GetLoan(loan_id)
    if not loan then return { status = false, message = 'Loan not found.' } end
    if tostring(loan.status) ~= 'approved' then
        return { status = false, message = 'Loan is not approved.' }
    end
    if loan.disbursed_account_id then
        return { status = false, message = 'Loan funds already disbursed.' }
    end
    if tonumber(loan.character_id) ~= tonumber(character_id) then
        return { status = false, message = 'No permission.' }
    end
    local acc = GetAccount(account_id)
    if not acc then
        return { status = false, message = 'Invalid account.' }
    end
    if loan.bank_id and acc.bank_id and not IdsEqual(loan.bank_id, acc.bank_id) then
        return { status = false, message = 'Account is not at the same bank.' }
    end
    if not (IsAccountOwner(account_id, character_id) or IsAccountAdmin(account_id, character_id)) then
        return { status = false, message = 'Insufficient Access.' }
    end
    local amt = tonumber(loan.amount) or 0
    local ok = DepositCash(account_id, amt)
    if not ok then
        return { status = false, message = 'Unable to deposit into the selected account.' }
    end
    AddLoanTransaction(loan.id, loan.character_id, amt, 'loan - disbursement', 'Loan disbursed to account (claimed)')
    MySQL.query.await('UPDATE `bcc_loans` SET `disbursed_account_id` = ?, `disbursed_at` = NOW() WHERE `id` = ?', { account_id, loan.id })
    local updated = GetLoan(loan_id)
    return { status = true, loan = updated }
end

function RejectLoan(loan_id, approver_char_id)
    local loan = GetLoan(loan_id)
    if not loan then return { status = false, message = 'Loan not found.' } end
    if loan.status == 'approved' then
        return { status = false, message = 'Loan already approved.' }
    end
    MySQL.query.await('UPDATE `bcc_loans` SET `status` = \'rejected\', `approved_by` = ?, `approved_at` = NOW() WHERE `id` = ?', { approver_char_id, loan_id })
    local updated = GetLoan(loan_id)
    return { status = true, loan = updated }
end


-- Determine interest rate for a character (optionally by bank)
function GetCharacterLoanInterest(character_id, bank_id)
    if not character_id then return 10.0 end
    local row
    -- 1) character + bank specific override
    if bank_id then
        row = MySQL.query.await('SELECT `interest` FROM `bcc_loan_interest_rates` WHERE `character_id` = ? AND `bank_id` = ? LIMIT 1;', { character_id, bank_id })
        if row and row[1] and row[1].interest then
            return tonumber(row[1].interest) or 10.0
        end
        -- 2) bank default rate
        local brow = MySQL.query.await('SELECT `interest` FROM `bcc_bank_interest_rates` WHERE `bank_id` = ? LIMIT 1;', { bank_id })
        if brow and brow[1] and brow[1].interest then
            return tonumber(brow[1].interest) or 10.0
        end
    end
    -- 3) character global default
    row = MySQL.query.await('SELECT `interest` FROM `bcc_loan_interest_rates` WHERE `character_id` = ? AND `bank_id` = ? LIMIT 1;', { character_id, '0' })
    if row and row[1] and row[1].interest then
        return tonumber(row[1].interest) or 10.0
    end
    -- 4) fallback
    return 10.0
end

-- Helper to fetch bank_id from account
function GetBankIdForAccount(account_id)
    local acc = GetAccount(account_id)
    return acc and acc.bank_id or nil
end
