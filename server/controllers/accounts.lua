local LockedAccounts = {}

if not _G.__bcc_accounts_rng_seeded then
    local seed = (os.time() % 100000)
    local ptr = tonumber(string.sub(tostring({}), 8)) or 0
    seed = seed + ptr
    math.randomseed(seed)
    -- warm-up calls to avoid low-quality initial outputs on some Lua implementations
    math.random(); math.random(); math.random()
    _G.__bcc_accounts_rng_seeded = true
end

function GetAccountCount(owner, bank)
    local result = MySQL.query.await(
        'SELECT COUNT(*) FROM `bcc_accounts` WHERE `owner_id` = ? AND `bank_id` = ?',
        { owner, bank }
    )
    return result and result[1] and result[1]["COUNT(*)"] or 0
end

function CreateAccount(name, owner, bank)
    devPrint("CreateAccount called with:", name, owner, bank)

    if not owner or not bank then
        devPrint("Error: owner or bank is nil.")
        return { status = false, message = "Owner or bank is invalid." }
    end

    local currentAccounts = GetAccountCount(owner, bank)
    if Config.Accounts.MaxAccounts ~= 0 and currentAccounts >= Config.Accounts.MaxAccounts then
        return { status = false, message = "Maximum accounts reached: " .. Config.Accounts.MaxAccounts }
    end

    -- Generate unique 8-digit account number
    local function generate8()
        -- range 10,000,000..99,999,999 (no leading zero)
        return tostring(math.random(10000000, 99999999))
    end
    local function nextUniqueAccountNumber()
        for i = 1, 20 do
            local candidate = generate8()
            local exists = MySQL.query.await('SELECT 1 FROM `bcc_accounts` WHERE `account_number` = ? LIMIT 1;', { candidate })
            if not exists or not exists[1] then
                return candidate
            end
        end
        -- Fallback: extremely unlikely to hit here; append a random 2-digit suffix and try again
        for i = 1, 80 do
            local candidate = tostring(math.random(10, 99)) .. tostring(math.random(1000000, 9999999))
            local exists = MySQL.query.await('SELECT 1 FROM `bcc_accounts` WHERE `account_number` = ? LIMIT 1;', { candidate })
            if not exists or not exists[1] then
                return candidate
            end
        end
        return generate8()
    end

    local acctNum = nextUniqueAccountNumber()

    local accountId = BccUtils.UUID()
    local result = MySQL.query.await(
        'INSERT INTO `bcc_accounts` (id, account_number, name, bank_id, owner_id) VALUES (?, ?, ?, ?, ?) RETURNING *;',
        { accountId, acctNum, name, bank, owner }
    )
    local account = result and result[1]

    if account then
        MySQL.query.await(
            'INSERT INTO `bcc_accounts_access` (`account_id`, `character_id`, `level`) VALUES (?, ?, ?)',
            { account.id, owner, Config.AccessLevels.Admin }
        )
    end

    return GetAccounts(owner, bank)
end

-- Create an account and return the created row (used for auto-loan accounts)
function CreateAccountReturn(name, owner, bank)
    if not owner or not bank then
        return { status = false, message = "Owner or bank is invalid." }
    end

    local currentAccounts = GetAccountCount(owner, bank)
    if Config.Accounts.MaxAccounts ~= 0 and currentAccounts >= Config.Accounts.MaxAccounts then
        return { status = false, message = "Maximum accounts reached: " .. Config.Accounts.MaxAccounts }
    end

    local function generate8()
        return tostring(math.random(10000000, 99999999))
    end
    local function nextUniqueAccountNumber()
        for i = 1, 20 do
            local candidate = generate8()
            local exists = MySQL.query.await('SELECT 1 FROM `bcc_accounts` WHERE `account_number` = ? LIMIT 1;', { candidate })
            if not exists or not exists[1] then
                return candidate
            end
        end
        for i = 1, 80 do
            local candidate = tostring(math.random(10, 99)) .. tostring(math.random(1000000, 9999999))
            local exists = MySQL.query.await('SELECT 1 FROM `bcc_accounts` WHERE `account_number` = ? LIMIT 1;', { candidate })
            if not exists or not exists[1] then
                return candidate
            end
        end
        return generate8()
    end

    local acctNum = nextUniqueAccountNumber()

    local accountId = BccUtils.UUID()
    local result = MySQL.query.await(
        'INSERT INTO `bcc_accounts` (id, account_number, name, bank_id, owner_id) VALUES (?, ?, ?, ?, ?) RETURNING *;',
        { accountId, acctNum, name, bank, owner }
    )
    local account = result and result[1]

    if not account then
        return { status = false, message = 'Failed to create account.' }
    end

    MySQL.query.await(
        'INSERT INTO `bcc_accounts_access` (`account_id`, `character_id`, `level`) VALUES (?, ?, ?)',
        { account.id, owner, Config.AccessLevels.Admin }
    )

    return { status = true, account = account }
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

    MySQL.query.await('DELETE FROM `bcc_accounts` WHERE `id` = ?', { account })
    return { status = true, accounts = GetAccounts(character, bank) }
end

function GetAccounts(characterId, bankId)
    local accounts = MySQL.query.await(
        'SELECT ' ..
        'a.id, ' ..
        'a.name AS account_name, ' ..
        'a.owner_id, ' ..
        'COALESCE(aa.level, 1) AS level ' ..
        'FROM bcc_accounts AS a ' ..
        'LEFT JOIN bcc_accounts_access AS aa ' ..
        '  ON a.id = aa.account_id ' ..
        ' AND aa.character_id = ? ' ..
        'INNER JOIN bcc_banks AS b ' ..
        '  ON b.id = a.bank_id ' ..
        'WHERE (a.owner_id = ? OR aa.character_id = ?) ' ..
        '  AND b.id = ?;',
        { characterId, characterId, characterId, bankId }
    )

    return accounts or {}
end

function GetAccount(account)
    local result = MySQL.query.await('SELECT * FROM `bcc_accounts` WHERE `id` = ?', { account })
    return result and result[1] or nil
end

-- Find account by external account_number (UUID-like)
function GetAccountByNumber(accountNumber)
    if not accountNumber or accountNumber == '' then return nil end
    local row = MySQL.query.await('SELECT * FROM `bcc_accounts` WHERE `account_number` = ? LIMIT 1;', { accountNumber })
    return row and row[1] or nil
end

-- Public listing: list all accounts under a bank (minimal fields)
function GetAccountsByBankPublic(bankId)
    local rows = MySQL.query.await(
        'SELECT id, name, account_number FROM `bcc_accounts` WHERE `bank_id` = ? ORDER BY `name` ASC, `id` ASC;',
        { bankId }
    )
    return rows or {}
end

function AddAccountAccess(account, character, level)
    MySQL.query.await(
        'INSERT INTO `bcc_accounts_access` (`account_id`, `character_id`, `level`) VALUES (?, ?, ?);',
        { account, character, level }
    )
    return true
end

function IsAccountOwner(account, character)
    local result = MySQL.query.await(
        'SELECT `owner_id` FROM `bcc_accounts` WHERE `id` = ? LIMIT 1;',
        { account }
    )
    local owner = result and result[1] and result[1].owner_id
    return owner == character
end

function IsAccountAdmin(account, character)
    local result = MySQL.query.await(
        'SELECT `level` FROM `bcc_accounts_access` WHERE `account_id` = ? AND `character_id` = ? LIMIT 1;',
        { account, character }
    )
    local record = result and result[1]
    return record and tonumber(record.level) == Config.AccessLevels.Admin
end

function HasAccountAccess(account, character)
    local result = MySQL.query.await(
        'SELECT 1 FROM `bcc_accounts_access` WHERE `account_id` = ? AND `character_id` = ? LIMIT 1;',
        { account, character }
    )
    return result and result[1] ~= nil
end

function GetAccountAccess(account, character)
    local result = MySQL.query.await(
        'SELECT `level` FROM `bcc_accounts_access` WHERE `account_id` = ? AND `character_id` = ? LIMIT 1;',
        { account, character }
    )
    return result and result[1] and tonumber(result[1].level) or 0
end

function DepositCash(account, amount)
    local result = MySQL.query.await('SELECT `cash` FROM `bcc_accounts` WHERE `id` = ? LIMIT 1;', { account })
    local cash = result and result[1] and result[1].cash

    if cash == nil then return false end

    local newAmount = cash + amount
    MySQL.query.await('UPDATE `bcc_accounts` SET `cash` = ? WHERE `id` = ?', { newAmount, account })
    return true
end

function DepositGold(account, amount)
    local result = MySQL.query.await('SELECT `gold` FROM `bcc_accounts` WHERE `id` = ? LIMIT 1;', { account })
    local gold = result and result[1] and result[1].gold

    if gold == nil then return false end

    local newAmount = gold + amount
    MySQL.query.await('UPDATE `bcc_accounts` SET `gold` = ? WHERE `id` = ?', { newAmount, account })
    return true
end

function WithdrawCash(account, amount)
    local result = MySQL.query.await('SELECT `cash`, `is_frozen` FROM `bcc_accounts` WHERE `id` = ? LIMIT 1;', { account })
    local row = result and result[1]
    if not row then return false end
    if row.is_frozen == 1 or row.is_frozen == true then return false end
    local cash = row.cash

    if cash == nil or (cash - amount) < 0 then return false end

    MySQL.query.await('UPDATE `bcc_accounts` SET `cash` = ? WHERE `id` = ?', { cash - amount, account })
    return true
end

function WithdrawGold(account, amount)
    local result = MySQL.query.await('SELECT `gold`, `is_frozen` FROM `bcc_accounts` WHERE `id` = ? LIMIT 1;', { account })
    local row = result and result[1]
    if not row then return false end
    if row.is_frozen == 1 or row.is_frozen == true then return false end
    local gold = row.gold

    if gold == nil or (gold - amount) < 0 then return false end

    MySQL.query.await('UPDATE `bcc_accounts` SET `gold` = ? WHERE `id` = ?', { gold - amount, account })
    return true
end

function IsAccountLocked(account, src)
    return LockedAccounts[account] ~= nil
end

-- Freeze/unfreeze all accounts belonging to an owner character
function SetOwnerAccountsFrozen(ownerId, frozen)
    if not ownerId then return end
    MySQL.query.await('UPDATE `bcc_accounts` SET `is_frozen` = ? WHERE `owner_id` = ?', { frozen and 1 or 0, ownerId })
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
    local result = MySQL.query.await('SELECT character_id, level FROM `bcc_accounts_access` WHERE account_id = ?', { account })

    return result or {}
end

function GiveAccountAccess(account, targetCharacter, level)
    local result = MySQL.query.await(
        'SELECT 1 FROM `bcc_accounts_access` WHERE `account_id` = ? AND `character_id` = ? LIMIT 1;',
        { account, targetCharacter }
    )

    if result and result[1] then
        return { status = false, message = "Character already has access." }
    end

    MySQL.query.await(
        'INSERT INTO `bcc_accounts_access` (`account_id`, `character_id`, `level`) VALUES (?, ?, ?)',
        { account, targetCharacter, level }
    )

    return { status = true, message = "Access granted." }
end

function RemoveAccountAccess(account, targetCharacter)
    MySQL.query.await(
        'DELETE FROM `bcc_accounts_access` WHERE `account_id` = ? AND `character_id` = ?',
        { account, targetCharacter }
    )
    return { status = true, message = "Access removed." }
end
