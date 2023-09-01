function GetAccountTransactions(account)
  local transactions = MySQL.query.await('SELECT * FROM `transactions` WHERE `account`=?;', { account })
  return transactions
end

function AddAccountTransaction(account, character, amount, type, description)
  MySQL.query.await(
    'INSERT INTO `transactions` (`account_id`, `character_id`, `amount`, `type`, `description`) VALUES (?, ?, ?, ?);',
    { account, character, amount, type })
  return true
end

function GetLoanTransactions(loan)
  local transactions = MySQL.query.await('SELECT * FROM `transactions` WHERE `loan`=?;', { loan })
  return transactions
end
