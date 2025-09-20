BccUtils.RPC:Register('Feather:Banks:GetAccounts', function(params, cb, src)
    devPrint("GetAccounts RPC called. src=", src, "params=", params)

    local user = VORPcore.getUser(src)
    if not user then
        devPrint("GetAccounts: Character not found (no user).")
        NotifyClient(src, _U('error_character_not_found'), "error", 4000)
        cb(false)
        return
    end
    local char = user.getUsedCharacter
    if not char then
        devPrint("GetAccounts: Character not found (no used character).")
        NotifyClient(src, _U('error_character_not_found'), "error", 4000)
        cb(false)
        return
    end
    local characterId = char.charIdentifier
    local bankId = tonumber(params and params.bank)

    devPrint("Parsed bankId:", bankId, "characterId:", characterId)

    if not characterId then
        devPrint("GetAccounts: Character ID is nil.")
        NotifyClient(src, _U('error_character_not_found'), "error", 4000)
        cb(false)
        return
    end

    if not bankId then
        devPrint("GetAccounts: Bank ID is nil.")
        NotifyClient(src, _U('error_invalid_bank'), "error", 4000)
        cb(false)
        return
    end

    if type(GetAccounts) ~= 'function' then
        devPrint("GetAccounts is not available (nil). Ensure controllers are loaded before services.")
        NotifyClient(src, _U('error_db'), 'error', 4000)
        cb(false)
        return
    end

    local ok, result = pcall(GetAccounts, characterId, bankId)

    if not ok then
        devPrint("GetAccounts query failed:", result)
        NotifyClient(src, _U('error_fetch_accounts'), "error", 4000)
        NotifyClient(src, _U('error_db'), 'error', 4000)
        cb(false)
        return
    end

    devPrint("GetAccounts: returning", result)
    cb(true, result or {})
end)

-- Public: list all accounts for a bank (minimal fields)
BccUtils.RPC:Register('Feather:Banks:ListAccountsByBank', function(params, cb, src)
    local bankId = tonumber(params and params.bank)
    devPrint('ListAccountsByBank RPC called. src=', src, 'bank=', bankId)
    if not bankId then
        cb(false)
        return
    end
    local ok, rows = pcall(function()
        return GetAccountsByBankPublic(bankId)
    end)
    if not ok then
        devPrint('ListAccountsByBank DB error:', rows)
        cb(false)
        return
    end
    devPrint('ListAccountsByBank rows:', rows and #rows or 0)
    if rows and rows[1] then
        devPrint('Sample account -> id:', rows[1].id, 'name:', rows[1].name, 'acc_num_tail:', tostring(rows[1].account_number or ''):sub(-6))
    end
    cb(true, rows or {})
end)

BccUtils.RPC:Register('Feather:Banks:CreateAccount', function(params, cb, src)
    devPrint("CreateAccount RPC called. src=", src, "params=", params)

    local user = VORPcore.getUser(src)
    if not user then
        devPrint("CreateAccount: Character not found (no user).")
        NotifyClient(src, _U('error_character_not_found'), "error", 4000)
        cb(false)
        return
    end
    local char = user.getUsedCharacter
    if not char then
        devPrint("CreateAccount: Character not found (no used character).")
        NotifyClient(src, _U('error_character_not_found'), "error", 4000)
        cb(false)
        return
    end
    local characterId = char.charIdentifier
    local name = params and params.name
    local bank = tonumber(params and params.bank)

    devPrint("Fetched character:", char)
    devPrint("CreateAccount inputs -> name:", name, "bank:", bank, "characterId:", characterId)

    if not characterId then
        devPrint("CreateAccount: Character not found or ID is nil.")
        NotifyClient(src, _U('error_character_not_found'), "error", 4000)
        cb(false)
        return
    end

    if not name or name == "" or not bank then
        devPrint("CreateAccount: Missing name or bank.")
        NotifyClient(src, _U('error_invalid_account_data'), "error", 4000)
        cb(false)
        return
    end

    local ok, out = pcall(function()
        return CreateAccount(name, characterId, bank)
    end)

    if not ok then
        devPrint("CreateAccount failed:", out)
        NotifyClient(src, _U('error_unable_create_account'), "error", 4000)
        cb(false)
        return
    end

    devPrint("CreateAccount success:", out)
    NotifyClient(src, _U('success_account_created'), "success", 4000)
    cb(true, out)
end)

BccUtils.RPC:Register('Feather:Banks:CloseAccount', function(params, cb, src)
    devPrint("CloseAccount RPC called. src=", src, "params=", params)

    local user = VORPcore.getUser(src)
    if not user then
        devPrint("CloseAccount: Character not found (no user).")
        NotifyClient(src, _U('error_character_not_found'), "error", 4000)
        NotifyClient(src, _U('error_character_not_found'), 'error', 4000)
        cb(false)
        return
    end
    local char = user.getUsedCharacter
    if not char then
        devPrint("CloseAccount: Character not found (no used character).")
        NotifyClient(src, _U('error_character_not_found'), "error", 4000)
        NotifyClient(src, _U('error_character_not_found'), 'error', 4000)
        cb(false)
        return
    end
    local characterId = char.charIdentifier
    local bank = tonumber(params and params.bank)
    local account = tonumber(params and params.account)

    devPrint("CloseAccount inputs -> bank:", bank, "account:", account, "characterId:", characterId)

    if not characterId or not bank or not account then
        devPrint("CloseAccount: Invalid inputs.")
        NotifyClient(src, _U('error_invalid_data'), "error", 4000)
        NotifyClient(src, _U('error_invalid_data'), 'error', 4000)
        cb(false)
        return
    end

    local ok, out = pcall(function()
        return CloseAccount(bank, account, characterId)
    end)

    if not ok then
        devPrint("CloseAccount failed:", out)
        NotifyClient(src, _U('error_unable_close_account'), "error", 4000)
        NotifyClient(src, _U('error_db'), 'error', 4000)
        cb(false)
        return
    end

    devPrint("CloseAccount success:", out)
    NotifyClient(src, _U('success_account_closed'), "success", 4000)
    cb(true, out)
end)

BccUtils.RPC:Register('Feather:Banks:GetAccount', function(params, cb, src)
    devPrint("GetAccount RPC called. src=", src, "params=", params)

    local user = VORPcore.getUser(src)
    if not user then
        devPrint("GetAccount: Character not found (no user).")
        NotifyClient(src, _U('error_character_not_found'), "error", 4000)
        NotifyClient(src, _U('error_character_not_found'), 'error', 4000)
        cb(false)
        return
    end
    local char = user.getUsedCharacter
    if not char then
        devPrint("GetAccount: Character not found (no used character).")
        NotifyClient(src, _U('error_character_not_found'), "error", 4000)
        NotifyClient(src, _U('error_character_not_found'), 'error', 4000)
        cb(false)
        return
    end
    local characterId = char.charIdentifier
    local accId = tonumber(params and params.account)
    local lockAccount = params and params.lockAccount

    devPrint("GetAccount inputs -> accId:", accId, "characterId:", characterId, "lockAccount:", lockAccount)

    if not characterId then
        devPrint("GetAccount: Character not found.")
        NotifyClient(src, _U('error_character_not_found'), "error", 4000)
        NotifyClient(src, _U('error_character_not_found'), 'error', 4000)
        cb(false)
        return
    end
    if not accId then
        devPrint("GetAccount: Invalid account id.")
        NotifyClient(src, _U('error_invalid_account'), "error", 4000)
        NotifyClient(src, _U('error_invalid_account_id'), 'error', 4000)
        cb(false)
        return
    end

    if not HasAccountAccess(accId, characterId) and not IsAccountOwner(accId, characterId) then
        devPrint("GetAccount: HasAccountAccess=false for characterId=", characterId, "accId=", accId)
        NotifyClient(src, _U('error_insufficient_access'), "error", 4000)
        NotifyClient(src, _U('error_insufficient_access'), 'error', 4000)
        cb(false)
        return
    end

    if IsAccountLocked(accId, src) and not IsActiveUser(accId, src) then
        devPrint("GetAccount: Account locked and not active user. accId=", accId)
        NotifyClient(src, _U('error_account_locked'), "error", 4000)
        NotifyClient(src, _U('error_account_locked'), 'error', 4000)
        cb(false)
        return
    end

    if lockAccount then
        devPrint("GetAccount: Locking account for src=", src, "accId=", accId)
        SetLockedAccount(accId, src, true)
    end

    local ok, accountData, txData = pcall(function()
        return GetAccount(accId), GetAccountTransactions(accId)
    end)

    if not ok then
        devPrint("GetAccount: DB error:", accountData)
        NotifyClient(src, _U('error_failed_load_account'), "error", 4000)
        NotifyClient(src, _U('error_db'), 'error', 4000)
        cb(false)
        return
    end

    devPrint("GetAccount: success, account=", accountData, "tx_count=", txData and #txData or 0)
    cb(true, { account = accountData, transactions = txData or {} })
end)

BccUtils.RPC:Register('Feather:Banks:UnlockAccount', function(params, cb, src)
    devPrint("UnlockAccount RPC called. src=", src, "params=", params)

    local accId = tonumber(params and params.account)
    if not accId then
        devPrint("UnlockAccount: invalid account id.")
        NotifyClient(src, _U('error_invalid_account_id'), 'error', 4000)
        cb(false)
        return
    end
    if not IsActiveUser(accId, src) then
        devPrint("UnlockAccount: src is not active user for accId=", accId)
        NotifyClient(src, _U('error_not_active_user'), 'error', 4000)
        cb(false)
        return
    end

    SetLockedAccount(accId, src, false)
    devPrint("UnlockAccount: unlocked accId=", accId, "for src=", src)
    cb(true)
end)

BccUtils.RPC:Register('Feather:Banks:GetAccountAccessList', function(params, cb, src)
    devPrint("GetAccountAccessList RPC called. src=", src, "params=", params)

    local account = tonumber(params.account)
    devPrint("Parsed account ID:", account)

    if not account then
        devPrint("GetAccountAccessList: Invalid account ID.")
        NotifyClient(src, _U('error_invalid_account_id'), "error", 4000)
        NotifyClient(src, _U('error_invalid_account_id'), 'error', 4000)
        cb(false)
        return
    end

    local rawAccessList = GetAccountAccessList(account)
    local accessList = {}

    devPrint("Raw DB access rows:", json.encode(rawAccessList))

    for _, row in ipairs(rawAccessList or {}) do
        -- Resolve names from DB by VORP charidentifier, independent of online status
        local nameRow = MySQL.query.await('SELECT firstname, lastname FROM characters WHERE charidentifier = ? LIMIT 1', { row.character_id })
        nameRow = nameRow and nameRow[1] or nil
        local firstName = nameRow and nameRow.firstname or 'Unknown'
        local lastName  = nameRow and nameRow.lastname or ''

        table.insert(accessList, {
            character_id = row.character_id,
            level = row.level,
            first_name = firstName,
            last_name = lastName,
        })

        devPrint("Access entry:", "[ID:", row.character_id, "]", firstName, lastName, "(Level", row.level, ")")
    end

    devPrint("Final access list:", json.encode(accessList))

    cb(true, { access = accessList })
end)


BccUtils.RPC:Register('Feather:Banks:GiveAccountAccess', function(params, cb, src)
    devPrint("GiveAccountAccess RPC called. src=", src, "params=", params)

    local user = VORPcore.getUser(src)
    if not user or not user.getUsedCharacter then
        devPrint("GiveAccountAccess: requester not found")
        NotifyClient(src, _U('error_invalid_data_provided'), "error", 4000)
        cb(false)
        return
    end
    local requesterId = user.getUsedCharacter.charIdentifier
    local account = tonumber(params and params.account)
    -- Expect VORP character identifier (charidentifier) from client
    local otherCharacter = tonumber(params and params.character)
    if not otherCharacter then
        devPrint("GiveAccountAccess: invalid target character id")
        NotifyClient(src, _U('error_invalid_data_provided'), 'error', 4000)
        cb(false)
        return
    end
    local level = tonumber(params and params.level)

    devPrint("Parsed inputs → account:", account, "targetCharacter:", otherCharacter, "level:", level, "requesterId:", requesterId)

    if not requesterId or not account or not otherCharacter or not level then
        devPrint("GiveAccountAccess: Invalid input data.")
        NotifyClient(src, _U('error_invalid_data_provided'), "error", 4000)
        cb(false)
        return
    end

    -- Permission check
    if not (IsAccountAdmin(account, requesterId) or IsAccountOwner(account, requesterId)) then
        devPrint("GiveAccountAccess: Source", requesterId, "is not admin or owner of account", account)
        NotifyClient(src, _U('error_no_permission'), "error", 4000)
        cb(false)
        return
    end

    -- Prevent giving access to self
    --[[if requesterId == otherCharacter then
        devPrint("GiveAccountAccess: Attempted to give access to self.")
        NotifyClient(src, _U('warn_already_has_access_account'), "warning", 4000)
        cb(false)
        return
    end]]--

    -- Check if target character actually exists in the DB
    --[[local exists = MySQL.query.await("SELECT 1 FROM characters WHERE charidentifier = ? LIMIT 1", { otherCharacter })
    if not exists or not exists[1] then
        devPrint("GiveAccountAccess: Target character not found in DB →", otherCharacter)
        NotifyClient(src, _U('error_target_character_not_found'), "error", 4000)
        cb(false)
        return
    end]]--

    local result = GiveAccountAccess(account, otherCharacter, level)
    devPrint("GiveAccountAccess result:", result)

    if not result or result.status == false then
        NotifyClient(src, result.message or _U('error_failed_grant_access'), "error", 4000)
        cb(false)
        return
    end

    devPrint("GiveAccountAccess: Access granted for character", otherCharacter, "on account", account)
    NotifyClient(src, _U('success_access_granted'), "success", 4000)
    cb(true)
end)

BccUtils.RPC:Register('Feather:Banks:RemoveAccountAccess', function(params, cb, src)
    devPrint("RemoveAccountAccess RPC called. src=", src, "params=", params)

    local user = VORPcore.getUser(src)
    if not user or not user.getUsedCharacter then
        devPrint("RemoveAccountAccess: requester not found")
        NotifyClient(src, _U('error_invalid_input'), "error", 4000)
        NotifyClient(src, _U('error_invalid_input'), 'error', 4000)
        cb(false)
        return
    end
    local requesterId = user.getUsedCharacter.charIdentifier

    local account = tonumber(params.account)
    local target = tonumber(params.character)

    devPrint("Parsed inputs → account:", account, "target:", target, "requesterId:", requesterId)

    -- Validate input
    if not requesterId or not account or not target then
        devPrint("RemoveAccountAccess: Invalid input data.")
        NotifyClient(src, _U('error_invalid_input'), "error", 4000)
        NotifyClient(src, _U('error_invalid_input'), 'error', 4000)
        cb(false)
        return
    end

    -- Permission check
    if not (IsAccountAdmin(account, requesterId) or IsAccountOwner(account, requesterId)) then
        devPrint("RemoveAccountAccess: Character", requesterId, "is not admin or owner of account", account)
        NotifyClient(src, _U('error_no_permission'), "error", 4000)
        NotifyClient(src, _U('error_no_permission'), 'error', 4000)
        cb(false)
        return
    end

    -- Remove the access
    local success = RemoveAccountAccess(account, target)
    devPrint("RemoveAccountAccess result:", success)

    if not success then
        devPrint("RemoveAccountAccess: Failed to remove access.")
        NotifyClient(src, _U('error_failed_remove_access'), "error", 4000)
        NotifyClient(src, _U('error_failed_remove_access'), 'error', 4000)
        cb(false)
        return
    end

    NotifyClient(src, _U('success_access_removed'), "success", 4000)
    cb(true)
end)

BccUtils.RPC:Register('Feather:Banks:DepositCash', function(params, cb, src)
    devPrint("DepositCash RPC called. src=", src, "params=", params)

    local user = VORPcore.getUser(src)
    if not user or not user.getUsedCharacter then
        devPrint("DepositCash: invalid player/char.")
        NotifyClient(src, _U('error_invalid_character_data'), "error", 4000)
        cb(false)
        return
    end
    local char = user.getUsedCharacter

    local account        = tonumber(params and params.account)
    local amount         = tonumber(params and params.amount)
    local description    = (params and params.description) or "No description provided"
    local currentDollars = tonumber(char.money)

    devPrint("DepositCash inputs -> account:", account, "amount:", amount, "currentDollars:", currentDollars)

    local accessLevel = GetAccountAccess(account, char.charIdentifier)
    devPrint("DepositCash: accessLevel=", accessLevel, "required <=", Config.AccessLevels.Deposit)

    if not accessLevel or accessLevel > Config.AccessLevels.Deposit then
        NotifyClient(src, _U('error_no_deposit_permission'), "error", 4000)
        cb(false)
        return
    end

    if not amount or amount <= 0 then
        NotifyClient(src, _U('error_invalid_deposit_amount'), "error", 4000)
        cb(false)
        return
    end

    if (currentDollars or 0) < amount then
        NotifyClient(src, _U('error_not_enough_cash', tostring(currentDollars or 0)), "error", 4000)
        cb(false)
        return
    end

    if not DepositCash(account, amount) then
        devPrint("DepositCash: DB update failed.")
        NotifyClient(src, _U('error_unable_deposit_cash') or 'Unable to deposit cash at this time.', "error", 4000)
        cb(false)
        return
    end

    char.removeCurrency(0, amount)
    AddAccountTransaction(account, char.charIdentifier, amount, 'deposit - cash', description)

    devPrint("DepositCash: success. account=", account, "amount=", amount)
    NotifyClient(src, _U('success_deposit_cash', tostring(amount)) or ('Successfully deposited $' .. tostring(amount)), "success", 4000)
    cb(true)
end)

-- Deposit Gold
BccUtils.RPC:Register('Feather:Banks:DepositGold', function(params, cb, src)
    devPrint("DepositGold RPC called. src=", src, "params=", params)

    local user = VORPcore.getUser(src)
    if not user or not user.getUsedCharacter then
        devPrint("DepositGold: invalid player/char.")
        NotifyClient(src, _U('error_invalid_character_data'), "error", 4000)
        cb(false)
        return
    end
    local char = user.getUsedCharacter

    local account     = tonumber(params and params.account)
    local amount      = tonumber(params and params.amount)
    local description = (params and params.description) or "No description provided"
    local currentGold = tonumber(char.gold)

    devPrint("DepositGold inputs -> account:", account, "amount:", amount, "currentGold:", currentGold)

    local accessLevel = GetAccountAccess(account, char.charIdentifier)
    devPrint("DepositGold: accessLevel=", accessLevel, "required <=", Config.AccessLevels.Deposit)

    if not accessLevel or accessLevel > Config.AccessLevels.Deposit then
        NotifyClient(src, _U('error_no_deposit_permission'), "error", 4000)
        cb(false)
        return
    end

    if not amount or amount <= 0 then
        NotifyClient(src, _U('error_invalid_deposit_amount'), "error", 4000)
        cb(false)
        return
    end

    if (currentGold or 0) < amount then
        NotifyClient(src, _U('error_not_enough_gold_have', tostring(currentGold or 0)) or ('Not enough gold. You have ' .. tostring(currentGold or 0)), "error", 4000)
        cb(false)
        return
    end

    if not DepositGold(account, amount) then
        devPrint("DepositGold: DB update failed.")
        NotifyClient(src, _U('error_unable_deposit_gold'), "error", 4000)
        cb(false)
        return
    end

    char.removeCurrency(1, amount)
    AddAccountTransaction(account, char.charIdentifier, amount, 'deposit - gold', description)

    devPrint("DepositGold: success. account=", account, "amount=", amount)
    NotifyClient(src, _U('success_deposit_gold', tostring(amount)), "success", 4000)
    cb(true)
end)

BccUtils.RPC:Register('Feather:Banks:WithdrawCash', function(params, cb, src)
    devPrint("WithdrawCash RPC called. src=", src, "params=", params)

    local user = VORPcore.getUser(src)
    if not user or not user.getUsedCharacter then
        devPrint("WithdrawCash: invalid player/char.")
        NotifyClient(src, _U('error_invalid_character_data'), "error", 4000)
        cb(false)
        return
    end
    local char = user.getUsedCharacter

    local account     = tonumber(params and params.account)
    local amount      = tonumber(params and params.amount)
    local description = (params and params.description) or "No description provided"

    devPrint("WithdrawCash inputs -> account:", account, "amount:", amount)

    local accessLevel = GetAccountAccess(account, char.charIdentifier)
    devPrint("WithdrawCash: accessLevel=", accessLevel, "required <=", Config.AccessLevels.Withdraw_Deposit)

    if not accessLevel or accessLevel > Config.AccessLevels.Withdraw_Deposit then
        NotifyClient(src, _U('error_no_withdraw_permission'), "error", 4000)
        cb(false)
        return
    end

    if not amount or amount <= 0 then
        NotifyClient(src, _U('error_invalid_withdraw_amount'), "error", 4000)
        cb(false)
        return
    end

    -- Check frozen
    local accRow = GetAccount(account)
    if accRow and (accRow.is_frozen == 1 or accRow.is_frozen == true) then
        NotifyClient(src, _U('error_account_frozen') or 'Account is frozen.', "error", 4000)
        cb(false)
        return
    end

    if not WithdrawCash(account, amount) then
        devPrint("WithdrawCash: insufficient funds or DB failure.")
        NotifyClient(src, _U('error_insufficient_account_funds'), "error", 4000)
        cb(false)
        return
    end

    char.addCurrency(0, amount)
    AddAccountTransaction(account, char.charIdentifier, amount, 'withdraw - cash', description)

    devPrint("WithdrawCash: success. account=", account, "amount=", amount)
    NotifyClient(src, _U('success_withdraw_cash', tostring(amount)), "success", 4000)
    cb(true)
end)

BccUtils.RPC:Register('Feather:Banks:WithdrawGold', function(params, cb, src)
    devPrint("WithdrawGold RPC called. src=", src, "params=", params)

    local user = VORPcore.getUser(src)
    if not user or not user.getUsedCharacter then
        devPrint("WithdrawGold: invalid player/char.")
        NotifyClient(src, _U('error_invalid_character_data'), "error", 4000)
        cb(false)
        return
    end
    local char = user.getUsedCharacter

    local account     = tonumber(params and params.account)
    local amount      = tonumber(params and params.amount)
    local description = (params and params.description) or "No description provided"

    devPrint("WithdrawGold inputs -> account:", account, "amount:", amount)

    local accessLevel = GetAccountAccess(account, char.charIdentifier)
    devPrint("WithdrawGold: accessLevel=", accessLevel, "required <=", Config.AccessLevels.Withdraw_Deposit)

    if not accessLevel or accessLevel > Config.AccessLevels.Withdraw_Deposit then
        NotifyClient(src, _U('error_no_withdraw_permission'), "error", 4000)
        cb(false)
        return
    end

    if not amount or amount <= 0 then
        NotifyClient(src, _U('error_invalid_withdraw_amount'), "error", 4000)
        cb(false)
        return
    end

    -- Check frozen
    local accRow = GetAccount(account)
    if accRow and (accRow.is_frozen == 1 or accRow.is_frozen == true) then
        NotifyClient(src, _U('error_account_frozen') or 'Account is frozen.', "error", 4000)
        cb(false)
        return
    end

    if not WithdrawGold(account, amount) then
        devPrint("WithdrawGold: insufficient funds or DB failure.")
        NotifyClient(src, _U('error_insufficient_account_funds'), "error", 4000)
        cb(false)
        return
    end

    char.addCurrency(1, amount)
    AddAccountTransaction(account, char.charIdentifier, amount, 'withdraw - gold', description)

    devPrint("WithdrawGold: success. account=", account, "amount=", amount)
    NotifyClient(src, _U('success_withdraw_gold', tostring(amount)), "success", 4000)
    cb(true)
end)

-- Transfer Cash between accounts (applies fee when banks differ)
BccUtils.RPC:Register('Feather:Banks:TransferCash', function(params, cb, src)
    devPrint("TransferCash RPC called. src=", src, "params=", params)

    if not (Config.Transfer and Config.Transfer.Enabled) then
        NotifyClient(src, _U('error_unable_transfer'), 'error', 4000)
        cb(false)
        return
    end

    local user = VORPcore.getUser(src)
    if not user or not user.getUsedCharacter then
        devPrint("TransferCash: invalid player/char.")
        NotifyClient(src, _U('error_invalid_character_data'), 'error', 4000)
        cb(false)
        return
    end
    local char = user.getUsedCharacter

    local fromAccountId = tonumber(params and params.fromAccount)
    local toAccountNumber = params and params.toAccountNumber
    local toAccountId = tonumber(params and params.toAccountId)
    local amount = tonumber(params and params.amount)
    local description = (params and params.description) or "Bank transfer"

    devPrint(
        "Inputs -> fromAccount:", fromAccountId,
        "toAccountId:", toAccountId,
        "toAccountNumber:", tostring(toAccountNumber or ""),
        "amount:", amount,
        "desc:", description
    )

    if not fromAccountId or (not toAccountNumber and not toAccountId) or not amount or amount <= 0 then
        NotifyClient(src, _U('error_invalid_transfer_input'), 'error', 4000)
        cb(false)
        return
    end

    local accessLevel = GetAccountAccess(fromAccountId, char.charIdentifier)
    devPrint("Access level for fromAccount:", fromAccountId, "char:", char.charIdentifier, "=", accessLevel)
    if not accessLevel or accessLevel > Config.AccessLevels.Withdraw_Deposit then
        NotifyClient(src, _U('error_no_withdraw_permission'), 'error', 4000)
        cb(false)
        return
    end

    local fromAcc = GetAccount(fromAccountId)
    if not fromAcc then
        NotifyClient(src, _U('error_invalid_account'), 'error', 4000)
        cb(false)
        return
    end

    if fromAcc and (fromAcc.is_frozen == 1 or fromAcc.is_frozen == true) then
        NotifyClient(src, _U('error_account_frozen') or 'Source account is frozen.', 'error', 4000)
        cb(false)
        return
    end

    devPrint("Loaded fromAcc -> id:", fromAcc.id, "bank:", fromAcc.bank_id, "cash:", fromAcc.cash)

    local toAcc
    if toAccountId then
        toAcc = GetAccount(toAccountId)
    else
        toAcc = GetAccountByNumber(toAccountNumber)
    end
    if not toAcc then
        NotifyClient(src, _U('error_invalid_destination_account'), 'error', 4000)
        cb(false)
        return
    end

    devPrint("Loaded toAcc -> id:", toAcc.id, "bank:", toAcc.bank_id, "cash:", toAcc.cash)

    if tonumber(toAcc.id) == tonumber(fromAcc.id) then
        NotifyClient(src, _U('error_same_account_transfer'), 'error', 4000)
        cb(false)
        return
    end

    -- Calculate fee if cross-bank
    local feePercent = 0.0
    if tonumber(fromAcc.bank_id) ~= tonumber(toAcc.bank_id) then
        feePercent = tonumber(Config.Transfer.CrossBankFeePercent or 0.0) or 0.0
    end

    local function round2(n)
        return math.floor((n + 0.0000001) * 100 + 0.5) / 100
    end

    local fee = round2((amount * feePercent) / 100.0)
    local totalDebit = round2(amount + fee)
    devPrint("Fee calc -> feePercent:", feePercent, "fee:", fee, "totalDebit:", totalDebit)

    -- Ensure sufficient funds (cash column)
    local current = tonumber(fromAcc.cash) or 0
    devPrint("From current cash:", current, ">= totalDebit?", current >= totalDebit)
    if current < totalDebit then
        NotifyClient(src, _U('error_insufficient_account_funds'), 'error', 4000)
        cb(false)
        return
    end

    -- Perform updates; try to keep consistent even without DB transaction
    if not WithdrawCash(fromAcc.id, totalDebit) then
        devPrint("WithdrawCash failed or insufficient funds during DB update")
        NotifyClient(src, _U('error_insufficient_account_funds'), 'error', 4000)
        cb(false)
        return
    end

    local depositOk = DepositCash(toAcc.id, amount)
    devPrint("After withdraw -> attempting deposit to", toAcc.id, "amount:", amount, "ok?", depositOk)
    if not depositOk then
        -- Attempt to revert withdrawal if deposit failed
        DepositCash(fromAcc.id, totalDebit)
        devPrint("Deposit failed, reverted withdrawal of", totalDebit)
        NotifyClient(src, _U('error_unable_transfer'), 'error', 4000)
        cb(false)
        return
    end

    -- Log transactions
    local toSuffix = tostring(toAcc.account_number or '')
    toSuffix = string.sub(toSuffix, #toSuffix - 5, #toSuffix)
    local fromSuffix = tostring(fromAcc.account_number or '')
    fromSuffix = string.sub(fromSuffix, #fromSuffix - 5, #fromSuffix)

    AddAccountTransaction(fromAcc.id, char.charIdentifier, amount, 'transfer - out', description .. ' -> ' .. tostring(toSuffix))
    if fee > 0 then
        AddAccountTransaction(fromAcc.id, char.charIdentifier, fee, 'transfer - fee', 'Cross-bank fee (' .. tostring(feePercent) .. '%)')
    end
    AddAccountTransaction(toAcc.id, char.charIdentifier, amount, 'transfer - in', description .. ' <- ' .. tostring(fromSuffix))

    devPrint("Transfer completed. from:", fromAcc.id, "to:", toAcc.id, "amount:", amount, "fee:", fee)
    NotifyClient(src, _U('success_transfer', tostring(amount)), 'success', 4000)
    cb(true, { fee = fee, debited = totalDebit })
end)
