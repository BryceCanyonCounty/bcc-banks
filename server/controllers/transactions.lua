function GetAccountTransactions(account)
    local transactions = MySQL.query.await(
        'SELECT ' ..
        '  t.id, t.account_id, t.loan_id, t.character_id, ' ..
        '  t.amount, t.type, t.description, t.created_at ' ..
        'FROM bcc_transactions AS t ' ..
        'LEFT JOIN bcc_loans AS l ON l.id = t.loan_id ' ..
        'WHERE t.account_id = ? OR l.account_id = ? ' ..
        'ORDER BY t.created_at DESC, t.id DESC;',
        { account, account }
    )
    return transactions or {}
end

local function insertTransaction(query, params)
    for attempt = 1, 5 do
        local ok, err = pcall(function()
            MySQL.query.await(query, params)
        end)
        if ok then
            return true
        end

        local errStr = err and tostring(err) or ''
        if errStr:find('Duplicate entry', 1, true) then
            params[1] = BccUtils.UUID()
        else
            error(err)
        end
    end
    error('bcc-banks: failed to insert transaction after retries')
end

function AddAccountTransaction(account, character, amount, txType, description)
    local params = {
        BccUtils.UUID(),
        account,
        character,
        amount,
        txType,
        description
    }
    insertTransaction(
        'INSERT INTO `bcc_transactions` (`id`, `account_id`, `character_id`, `amount`, `type`, `description`) VALUES (?, ?, ?, ?, ?, ?);',
        params
    )
    return true
end

function GetLoanTransactions(loan)
    local transactions = MySQL.query.await(
        'SELECT id, account_id, loan_id, character_id, amount, type, description, created_at ' ..
        'FROM `bcc_transactions` ' ..
        'WHERE `loan_id` = ? ' ..
        'ORDER BY `created_at` DESC, `id` DESC;',
        { loan }
    )
    return transactions or {}
end

function AddLoanTransaction(loan, character, amount, txType, description)
    local params = {
        BccUtils.UUID(),
        loan,
        character,
        amount,
        txType,
        description
    }
    insertTransaction(
        'INSERT INTO `bcc_transactions` (`id`, `loan_id`, `character_id`, `amount`, `type`, `description`) VALUES (?, ?, ?, ?, ?, ?);',
        params
    )
    return true
end

function SumLoanRepayments(loan)
    local row = MySQL.query.await(
        'SELECT COALESCE(SUM(amount), 0) AS total ' ..
        'FROM `bcc_transactions` ' ..
        'WHERE `loan_id` = ? AND `type` = "loan - repayment";',
        { loan }
    )
    return row and row[1] and tonumber(row[1].total) or 0
end
