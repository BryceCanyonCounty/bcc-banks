Feather.RPC.Register('Feather:Banks:GetAccounts', function(params, cb, src)
    devPrint("GetAccounts RPC called. src=", src, "params=", params)

    local player = Feather.Character.GetCharacter({ src = src })
    local characterId = player and player.char and player.char.id
    local bankId = tonumber(params and params.bank)

    devPrint("Fetched character for GetAccounts:", player)
    devPrint("Parsed bankId:", bankId, "characterId:", characterId)

    if not characterId then
        devPrint("GetAccounts: Character ID is nil.")
        NotifyClient(src, "Character not found.", "error", 4000)
        cb(false, { message = "Character not found." })
        return
    end

    if not bankId then
        devPrint("GetAccounts: Bank ID is nil.")
        NotifyClient(src, "Invalid bank selected.", "error", 4000)
        cb(false, { message = "Invalid bank selected." })
        return
    end

    local ok, result = pcall(function()
        return GetAccounts(characterId, bankId)
    end)

    if not ok then
        devPrint("GetAccounts query failed:", result)
        NotifyClient(src, "Failed to fetch accounts.", "error", 4000)
        cb(false, { message = "DB error." })
        return
    end

    devPrint("GetAccounts: returning", result)
    cb(true, result or {})
end)

Feather.RPC.Register('Feather:Banks:CreateAccount', function(params, cb, src)
    devPrint("CreateAccount RPC called. src=", src, "params=", params)

    local character = Feather.Character.GetCharacter({ src = src })
    local characterId = character and character.char and character.char.id
    local name = params and params.name
    local bank = tonumber(params and params.bank)

    devPrint("Fetched character:", character)
    devPrint("CreateAccount inputs -> name:", name, "bank:", bank, "characterId:", characterId)

    if not characterId then
        devPrint("CreateAccount: Character not found or ID is nil.")
        NotifyClient(src, "Character not found.", "error", 4000)
        cb(false, { message = "Character not found." })
        return
    end

    if not name or name == "" or not bank then
        devPrint("CreateAccount: Missing name or bank.")
        NotifyClient(src, "Invalid account data.", "error", 4000)
        cb(false, { message = "Invalid data." })
        return
    end

    local ok, out = pcall(function()
        return CreateAccount(name, characterId, bank)
    end)

    if not ok then
        devPrint("CreateAccount failed:", out)
        NotifyClient(src, "Unable to create account.", "error", 4000)
        cb(false, { message = "DB error." })
        return
    end

    devPrint("CreateAccount success:", out)
    NotifyClient(src, "Account created.", "success", 4000)
    cb(true, out)
end)

Feather.RPC.Register('Feather:Banks:CloseAccount', function(params, cb, src)
    devPrint("CloseAccount RPC called. src=", src, "params=", params)

    local character = Feather.Character.GetCharacter({ src = src })
    local characterId = character and character.char and character.char.id
    local bank = tonumber(params and params.bank)
    local account = tonumber(params and params.account)

    devPrint("CloseAccount inputs -> bank:", bank, "account:", account, "characterId:", characterId)

    if not characterId or not bank or not account then
        devPrint("CloseAccount: Invalid inputs.")
        NotifyClient(src, "Invalid data.", "error", 4000)
        cb(false, { message = "Invalid data." })
        return
    end

    local ok, out = pcall(function()
        return CloseAccount(bank, account, characterId)
    end)

    if not ok then
        devPrint("CloseAccount failed:", out)
        NotifyClient(src, "Unable to close account.", "error", 4000)
        cb(false, { message = "DB error." })
        return
    end

    devPrint("CloseAccount success:", out)
    NotifyClient(src, "Account closed.", "success", 4000)
    cb(true, out)
end)

Feather.RPC.Register('Feather:Banks:GetAccount', function(params, cb, src)
    devPrint("GetAccount RPC called. src=", src, "params=", params)

    local character = Feather.Character.GetCharacter({ src = src })
    local characterId = character and character.char and character.char.id
    local accId = tonumber(params and params.account)
    local lockAccount = params and params.lockAccount

    devPrint("GetAccount inputs -> accId:", accId, "characterId:", characterId, "lockAccount:", lockAccount)

    if not characterId then
        devPrint("GetAccount: Character not found.")
        NotifyClient(src, "Character not found.", "error", 4000)
        cb(false, { message = "Character not found." })
        return
    end
    if not accId then
        devPrint("GetAccount: Invalid account id.")
        NotifyClient(src, "Invalid account.", "error", 4000)
        cb(false, { message = "Invalid account id." })
        return
    end

    if not HasAccountAccess(accId, characterId) and not IsAccountOwner(accId, characterId) then
        devPrint("GetAccount: HasAccountAccess=false for characterId=", characterId, "accId=", accId)
        NotifyClient(src, "Insufficient access.", "error", 4000)
        cb(false, { message = "Insufficient Access" })
        return
    end

    if IsAccountLocked(accId, src) and not IsActiveUser(accId, src) then
        devPrint("GetAccount: Account locked and not active user. accId=", accId)
        NotifyClient(src, "Account is locked.", "error", 4000)
        cb(false, { message = "Account is locked." })
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
        NotifyClient(src, "Failed to load account.", "error", 4000)
        cb(false, { message = "DB error." })
        return
    end

    devPrint("GetAccount: success, account=", accountData, "tx_count=", txData and #txData or 0)
    cb(true, { account = accountData, transactions = txData or {} })
end)

Feather.RPC.Register('Feather:Banks:UnlockAccount', function(params, cb, src)
    devPrint("UnlockAccount RPC called. src=", src, "params=", params)

    local accId = tonumber(params and params.account)
    if not accId then
        devPrint("UnlockAccount: invalid account id.")
        cb(false, { message = "Invalid account id." })
        return
    end
    if not IsActiveUser(accId, src) then
        devPrint("UnlockAccount: src is not active user for accId=", accId)
        cb(false, { message = "Not active user." })
        return
    end

    SetLockedAccount(accId, src, false)
    devPrint("UnlockAccount: unlocked accId=", accId, "for src=", src)
    cb(true)
end)

Feather.RPC.Register('Feather:Banks:GetAccountAccessList', function(params, cb, src)
    devPrint("GetAccountAccessList RPC called. src=", src, "params=", params)

    local account = tonumber(params.account)
    devPrint("Parsed account ID:", account)

    if not account then
        devPrint("GetAccountAccessList: Invalid account ID.")
        NotifyClient(src, "Invalid account ID.", "error", 4000)
        cb(false, { message = "Invalid account id." })
        return
    end

    local rawAccessList = GetAccountAccessList(account)
    local accessList = {}

    devPrint("Raw DB access rows:", json.encode(rawAccessList)) -- Print DB result

    for _, row in ipairs(rawAccessList or {}) do
        local charObj = Feather.Character.GetCharacterByID({ id = row.character_id })
        local charData = charObj and charObj.char

        devPrint(string.format("Resolving character_id: %s → charObj: %s", row.character_id, charObj and "found" or "nil"))

        local firstName = charData and charData.first_name or "Unknown"
        local lastName = charData and charData.last_name or ""

        table.insert(accessList, {
            character_id = row.character_id,
            level = row.level,
            first_name = firstName,
            last_name = lastName
        })

        devPrint(string.format("Access entry: [ID: %s] %s %s (Level %d)", row.character_id, firstName, lastName, row.level))
    end

    devPrint("Final access list:", json.encode(accessList))

    cb(true, { access = accessList })
end)


Feather.RPC.Register('Feather:Banks:GiveAccountAccess', function(params, cb, src)
    devPrint("GiveAccountAccess RPC called. src=", src, "params=", params)

    local character = Feather.Character.GetCharacter({ src = src })
    local requesterId = character and character.char and character.char.id
    local account = tonumber(params and params.account)
    local targetSrc = tonumber(params and params.character)
    local targetChar = Feather.Character.GetCharacter({ src = targetSrc })
    local otherCharacter = targetChar and targetChar.char and targetChar.char.id
    local level = tonumber(params and params.level)

    devPrint("Parsed inputs → account:", account, "targetCharacter:", otherCharacter, "level:", level, "requesterId:", requesterId)

    if not requesterId or not account or not otherCharacter or not level then
        devPrint("GiveAccountAccess: Invalid input data.")
        NotifyClient(src, "Invalid data provided.", "error", 4000)
        cb(false)
        return
    end

    -- Permission check
    if not (IsAccountAdmin(account, requesterId) or IsAccountOwner(account, requesterId)) then
        devPrint("GiveAccountAccess: Source", requesterId, "is not admin or owner of account", account)
        NotifyClient(src, "You do not have permission.", "error", 4000)
        cb(false)
        return
    end

    -- Prevent giving access to self
    if requesterId == otherCharacter then
        devPrint("GiveAccountAccess: Attempted to give access to self.")
        NotifyClient(src, "You already have access to this account.", "warning", 4000)
        cb(false)
        return
    end

    -- Check if target character actually exists in the DB
    local exists = MySQL.query.await("SELECT 1 FROM characters WHERE id = ? LIMIT 1", { otherCharacter })
    if not exists or not exists[1] then
        devPrint("GiveAccountAccess: Target character not found in DB →", otherCharacter)
        NotifyClient(src, "Character not found.", "error", 4000)
        cb(false)
        return
    end

    local result = GiveAccountAccess(account, otherCharacter, level)
    devPrint("GiveAccountAccess result:", result)

    if not result or result.status == false then
        NotifyClient(src, result.message or "Failed to grant access.", "error", 4000)
        cb(false)
        return
    end

    devPrint("GiveAccountAccess: Access granted for character", otherCharacter, "on account", account)
    NotifyClient(src, "Access granted successfully.", "success", 4000)
    cb(true)
end)

Feather.RPC.Register('Feather:Banks:RemoveAccountAccess', function(params, cb, src)
    devPrint("RemoveAccountAccess RPC called. src=", src, "params=", params)

    local character = Feather.Character.GetCharacter({ src = src })
    local requesterId = character and character.char and character.char.id

    local account = tonumber(params.account)
    local target = tonumber(params.character)

    devPrint("Parsed inputs → account:", account, "target:", target, "requesterId:", requesterId)

    -- Validate input
    if not requesterId or not account or not target then
        devPrint("RemoveAccountAccess: Invalid input data.")
        NotifyClient(src, "Invalid input.", "error", 4000)
        cb(false, { message = "Invalid input." })
        return
    end

    -- Permission check
    if not (IsAccountAdmin(account, requesterId) or IsAccountOwner(account, requesterId)) then
        devPrint("RemoveAccountAccess: Character", requesterId, "is not admin or owner of account", account)
        NotifyClient(src, "You do not have permission.", "error", 4000)
        cb(false, { message = "You do not have permission." })
        return
    end

    -- Remove the access
    local success = RemoveAccountAccess(account, target)
    devPrint("RemoveAccountAccess result:", success)

    if not success then
        devPrint("RemoveAccountAccess: Failed to remove access.")
        NotifyClient(src, "Failed to remove access.", "error", 4000)
        cb(false, { message = "Failed to remove access." })
        return
    end

    NotifyClient(src, "Access removed.", "success", 4000)
    cb(true)
end)

Feather.RPC.Register('Feather:Banks:DepositCash', function(params, cb, src)
    devPrint("DepositCash RPC called. src=", src, "params=", params)

    local player = Feather.Character.GetCharacter({ src = src })
    if not player or not player.char then
        devPrint("DepositCash: invalid player/char.")
        NotifyClient(src, "Error: Character data invalid.", "error", 4000)
        cb(false)
        return
    end

    local account        = tonumber(params and params.account)
    local amount         = tonumber(params and params.amount)
    local description    = (params and params.description) or "No description provided"
    local currentDollars = tonumber(player.char.dollars)

    devPrint("DepositCash inputs -> account:", account, "amount:", amount, "currentDollars:", currentDollars)

    local accessLevel = GetAccountAccess(account, player.char.id)
    devPrint("DepositCash: accessLevel=", accessLevel, "required <=", Config.AccessLevels.Deposit)

    if not accessLevel or accessLevel > Config.AccessLevels.Deposit then
        NotifyClient(src, "You don’t have permission to deposit here.", "error", 4000)
        cb(false)
        return
    end

    if not amount or amount <= 0 then
        NotifyClient(src, "Invalid deposit amount.", "error", 4000)
        cb(false)
        return
    end

    if (currentDollars or 0) < amount then
        NotifyClient(src, "Not enough cash. You have $" .. tostring(currentDollars or 0), "error", 4000)
        cb(false)
        return
    end

    if not DepositCash(account, amount) then
        devPrint("DepositCash: DB update failed.")
        NotifyClient(src, "Unable to deposit cash at this time.", "error", 4000)
        cb(false)
        return
    end

    player:Subtract('dollars', amount)
    AddAccountTransaction(account, player.char.id, amount, 'deposit - cash', description)

    devPrint("DepositCash: success. account=", account, "amount=", amount)
    NotifyClient(src, "Successfully deposited $" .. tostring(amount), "success", 4000)
    cb(true)
end)

-- Deposit Gold
Feather.RPC.Register('Feather:Banks:DepositGold', function(params, cb, src)
    devPrint("DepositGold RPC called. src=", src, "params=", params)

    local player = Feather.Character.GetCharacter({ src = src })
    if not player or not player.char then
        devPrint("DepositGold: invalid player/char.")
        NotifyClient(src, "Error: Character data invalid.", "error", 4000)
        cb(false)
        return
    end

    local account     = tonumber(params and params.account)
    local amount      = tonumber(params and params.amount)
    local description = (params and params.description) or "No description provided"
    local currentGold = tonumber(player.char.gold)

    devPrint("DepositGold inputs -> account:", account, "amount:", amount, "currentGold:", currentGold)

    local accessLevel = GetAccountAccess(account, player.char.id)
    devPrint("DepositGold: accessLevel=", accessLevel, "required <=", Config.AccessLevels.Deposit)

    if not accessLevel or accessLevel > Config.AccessLevels.Deposit then
        NotifyClient(src, "You don’t have permission to deposit gold here.", "error", 4000)
        cb(false)
        return
    end

    if not amount or amount <= 0 then
        NotifyClient(src, "Invalid deposit amount.", "error", 4000)
        cb(false)
        return
    end

    if (currentGold or 0) < amount then
        NotifyClient(src, "Not enough gold. You have " .. tostring(currentGold or 0), "error", 4000)
        cb(false)
        return
    end

    if not DepositGold(account, amount) then
        devPrint("DepositGold: DB update failed.")
        NotifyClient(src, "Unable to deposit gold at this time.", "error", 4000)
        cb(false)
        return
    end

    player:Subtract('gold', amount)
    AddAccountTransaction(account, player.char.id, amount, 'deposit - gold', description)

    devPrint("DepositGold: success. account=", account, "amount=", amount)
    NotifyClient(src, "Successfully deposited " .. tostring(amount) .. " gold.", "success", 4000)
    cb(true)
end)

Feather.RPC.Register('Feather:Banks:WithdrawCash', function(params, cb, src)
    devPrint("WithdrawCash RPC called. src=", src, "params=", params)

    local player = Feather.Character.GetCharacter({ src = src })
    if not player or not player.char then
        devPrint("WithdrawCash: invalid player/char.")
        NotifyClient(src, "Error: Character data invalid.", "error", 4000)
        cb(false)
        return
    end

    local account     = tonumber(params and params.account)
    local amount      = tonumber(params and params.amount)
    local description = (params and params.description) or "No description provided"

    devPrint("WithdrawCash inputs -> account:", account, "amount:", amount)

    local accessLevel = GetAccountAccess(account, player.char.id)
    devPrint("WithdrawCash: accessLevel=", accessLevel, "required <=", Config.AccessLevels.Withdraw_Deposit)

    if not accessLevel or accessLevel > Config.AccessLevels.Withdraw_Deposit then
        NotifyClient(src, "You don’t have permission to withdraw from this account.", "error", 4000)
        cb(false)
        return
    end

    if not amount or amount <= 0 then
        NotifyClient(src, "Invalid withdraw amount.", "error", 4000)
        cb(false)
        return
    end

    if not WithdrawCash(account, amount) then
        devPrint("WithdrawCash: insufficient funds or DB failure.")
        NotifyClient(src, "Insufficient account funds.", "error", 4000)
        cb(false)
        return
    end

    player:Add('dollars', amount)
    AddAccountTransaction(account, player.char.id, amount, 'withdraw - cash', description)

    devPrint("WithdrawCash: success. account=", account, "amount=", amount)
    NotifyClient(src, "Successfully withdrew $" .. tostring(amount), "success", 4000)
    cb(true)
end)

Feather.RPC.Register('Feather:Banks:WithdrawGold', function(params, cb, src)
    devPrint("WithdrawGold RPC called. src=", src, "params=", params)

    local player = Feather.Character.GetCharacter({ src = src })
    if not player or not player.char then
        devPrint("WithdrawGold: invalid player/char.")
        NotifyClient(src, "Error: Character data invalid.", "error", 4000)
        cb(false)
        return
    end

    local account     = tonumber(params and params.account)
    local amount      = tonumber(params and params.amount)
    local description = (params and params.description) or "No description provided"

    devPrint("WithdrawGold inputs -> account:", account, "amount:", amount)

    local accessLevel = GetAccountAccess(account, player.char.id)
    devPrint("WithdrawGold: accessLevel=", accessLevel, "required <=", Config.AccessLevels.Withdraw_Deposit)

    if not accessLevel or accessLevel > Config.AccessLevels.Withdraw_Deposit then
        NotifyClient(src, "You don’t have permission to withdraw from this account.", "error", 4000)
        cb(false)
        return
    end

    if not amount or amount <= 0 then
        NotifyClient(src, "Invalid withdraw amount.", "error", 4000)
        cb(false)
        return
    end

    if not WithdrawGold(account, amount) then
        devPrint("WithdrawGold: insufficient funds or DB failure.")
        NotifyClient(src, "Insufficient account funds.", "error", 4000)
        cb(false)
        return
    end

    player:Add('gold', amount)
    AddAccountTransaction(account, player.char.id, amount, 'withdraw - gold', description)

    devPrint("WithdrawGold: success. account=", account, "amount=", amount)
    NotifyClient(src, "Successfully withdrew " .. tostring(amount) .. " gold.", "success", 4000)
    cb(true)
end)
