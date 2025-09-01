function GetAccountTransactions(account)
    local transactions = MySQL.query.await(
        "SELECT DISTINCT " ..
        "  `transactions`.`id`, `transactions`.`account_id`, `transactions`.`loan_id`, " ..
        "  `transactions`.`amount`, `transactions`.`type`, `transactions`.`description`, " ..
        "  `transactions`.`created_at` AS created_at, " ..
        "  CONCAT(`characters`.`first_name`, ' ', `characters`.`last_name`) AS character_name " ..
        "FROM `transactions` " ..
        "LEFT JOIN `characters` ON `characters`.`id` = `transactions`.`character_id` " ..
        "LEFT JOIN `loans` ON `loans`.`id` = `transactions`.`loan_id` " ..
        "WHERE `transactions`.`account_id` = ? OR `loans`.`account_id` = ? " ..
        "ORDER BY `transactions`.`created_at` DESC, `transactions`.`id` DESC;",
        { account, account })
    return transactions
end

function AddAccountTransaction(account, character, amount, type, description)
    MySQL.query.await(
        "INSERT INTO `transactions` (`account_id`, `character_id`, `amount`, `type`, `description`) VALUES (?, ?, ?, ?, ?);",
        { account, character, amount, type, description })
    return true
end

function GetLoanTransactions(loan)
    local transactions = MySQL.query.await(
        "SELECT * FROM `transactions` WHERE `loan_id` = ? ORDER BY `created_at` DESC, `id` DESC;",
        { loan })
    return transactions
end
