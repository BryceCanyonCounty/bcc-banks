local LockedAccounts = {}

function GetAccountCount(owner, bank)
    local result = MySQL.query.await(
        'SELECT COUNT(*) FROM `accounts` WHERE `owner_id` = ? AND `bank_id` = ?',
        { owner, bank }
    )
    return result and result[1] and result[1]["COUNT(*)"] or 0
end

function CreateAccount(name, owner, bank)
    print("CreateAccount called with:", name, owner, bank)

    if not owner or not bank then
        print("Error: owner or bank is nil.")
        return { status = false, message = "Owner or bank is invalid." }
    end

    local currentAccounts = GetAccountCount(owner, bank)
    if Config.Accounts.MaxAccounts ~= 0 and currentAccounts >= Config.Accounts.MaxAccounts then
        return { status = false, message = "Maximum accounts reached: " .. Config.Accounts.MaxAccounts }
    end

    local result = MySQL.query.await(
        'INSERT INTO `accounts` (name, bank_id, owner_id) VALUES (?, ?, ?) RETURNING *;',
        { name, bank, owner }
    )
    local account = result and result[1]

    if account then
        MySQL.query.await(
            'INSERT INTO `accounts_access` (`account_id`, `character_id`, `level`) VALUES (?, ?, ?)',
            { account.id, owner, Config.AccessLevels.Admin }
        )
    end

    return GetAccounts(owner, bank)
end

function CloseAccount(bank, account, character)
    local accountDetails = GetAccount(account)
    if not accountDetails then
        return { status = false, message = "Can't find account." }
    end

    if accountDetails.gold > 0 or accountDetails.cash > 0 then
        return { status = false, message = "Unable to close. Withdraw funds first." }
    end

    if not IsAccountAdmin(account, character) then
        return { status = false, message = "Insufficient Access." }
    end

    MySQL.query.await('DELETE FROM `accounts` WHERE `id` = ?', { account })
    return { status = true, accounts = GetAccounts(character, bank) }
end

function GetAccounts(characterId, bankId)
    local accounts = MySQL.query.await(
        [[
        SELECT
            accounts.id,
            accounts.name AS account_name,
            CONCAT(characters.first_name, ' ', characters.last_name) AS owner_name,
            COALESCE(accounts_access.level, 1) AS level
        FROM accounts
        LEFT JOIN accounts_access ON accounts.id = accounts_access.account_id AND accounts_access.character_id = ?
        INNER JOIN banks ON banks.id = accounts.bank_id
        INNER JOIN characters ON characters.id = accounts.owner_id
        WHERE (accounts.owner_id = ? OR accounts_access.character_id = ?) AND banks.id = ?;
        ]],
        { characterId, characterId, characterId, bankId }
    )

    return accounts or {}
end

function GetAccount(account)
    local result = MySQL.query.await('SELECT * FROM `accounts` WHERE `id` = ?', { account })
    return result and result[1] or nil
end

function AddAccountAccess(account, character, level)
    MySQL.query.await(
        'INSERT INTO `accounts_access` (`account_id`, `character_id`, `level`) VALUES (?, ?, ?);',
        { account, character, level }
    )
    return true
end

function IsAccountOwner(account, character)
    local result = MySQL.query.await(
        'SELECT `owner_id` FROM `accounts` WHERE `id` = ? LIMIT 1;',
        { account }
    )
    local owner = result and result[1] and result[1].owner_id
    return owner == character
end

function IsAccountAdmin(account, character)
    local result = MySQL.query.await(
        'SELECT `level` FROM `accounts_access` WHERE `account_id` = ? AND `character_id` = ? LIMIT 1;',
        { account, character }
    )
    local record = result and result[1]
    return record and tonumber(record.level) == Config.AccessLevels.Admin
end

function HasAccountAccess(account, character)
    local result = MySQL.query.await(
        'SELECT 1 FROM `accounts_access` WHERE `account_id` = ? AND `character_id` = ? LIMIT 1;',
        { account, character }
    )
    return result and result[1] ~= nil
end

function GetAccountAccess(account, character)
    local result = MySQL.query.await(
        'SELECT `level` FROM `accounts_access` WHERE `account_id` = ? AND `character_id` = ? LIMIT 1;',
        { account, character }
    )
    return result and result[1] and tonumber(result[1].level) or 0
end

function DepositCash(account, amount)
    local result = MySQL.query.await('SELECT `cash` FROM `accounts` WHERE `id` = ? LIMIT 1;', { account })
    local cash = result and result[1] and result[1].cash

    if cash == nil then return false end

    local newAmount = cash + amount
    MySQL.query.await('UPDATE `accounts` SET `cash` = ? WHERE `id` = ?', { newAmount, account })
    return true
end

function DepositGold(account, amount)
    local result = MySQL.query.await('SELECT `gold` FROM `accounts` WHERE `id` = ? LIMIT 1;', { account })
    local gold = result and result[1] and result[1].gold

    if gold == nil then return false end

    local newAmount = gold + amount
    MySQL.query.await('UPDATE `accounts` SET `gold` = ? WHERE `id` = ?', { newAmount, account })
    return true
end

function WithdrawCash(account, amount)
    local result = MySQL.query.await('SELECT `cash` FROM `accounts` WHERE `id` = ? LIMIT 1;', { account })
    local cash = result and result[1] and result[1].cash

    if cash == nil or (cash - amount) < 0 then return false end

    MySQL.query.await('UPDATE `accounts` SET `cash` = ? WHERE `id` = ?', { cash - amount, account })
    return true
end

function WithdrawGold(account, amount)
    local result = MySQL.query.await('SELECT `gold` FROM `accounts` WHERE `id` = ? LIMIT 1;', { account })
    local gold = result and result[1] and result[1].gold

    if gold == nil or (gold - amount) < 0 then return false end

    MySQL.query.await('UPDATE `accounts` SET `gold` = ? WHERE `id` = ?', { gold - amount, account })
    return true
end

function IsAccountLocked(account, src)
    return LockedAccounts[account] ~= nil
end

function IsActiveUser(account, src)
    return LockedAccounts[account] == src
end

function SetLockedAccount(account, src, state)
    if state then
        LockedAccounts[account] = src
    else
        LockedAccounts[account] = nil
    end
end

function ClearAccountLocks(src)
    for account, user in pairs(LockedAccounts) do
        if user == src then
            LockedAccounts[account] = nil
        end
    end
end

function GetAccountAccessList(account)
    local result = MySQL.query.await([[
        SELECT character_id, level
        FROM accounts_access
        WHERE account_id = ?
    ]], { account })

    return result or {}
end

function GiveAccountAccess(account, targetCharacter, level)
    local result = MySQL.query.await(
        'SELECT 1 FROM `accounts_access` WHERE `account_id` = ? AND `character_id` = ? LIMIT 1;',
        { account, targetCharacter }
    )

    if result and result[1] then
        return { status = false, message = "Character already has access." }
    end

    MySQL.query.await(
        'INSERT INTO `accounts_access` (`account_id`, `character_id`, `level`) VALUES (?, ?, ?)',
        { account, targetCharacter, level }
    )

    return { status = true, message = "Access granted." }
end

function RemoveAccountAccess(account, targetCharacter)
    MySQL.query.await(
        'DELETE FROM `accounts_access` WHERE `account_id` = ? AND `character_id` = ?',
        { account, targetCharacter }
    )
    return { status = true, message = "Access removed." }
end
