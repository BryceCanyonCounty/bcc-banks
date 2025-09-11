function GetSDBCount(owner, bank)
    local row = MySQL.query.await(
        'SELECT COUNT(*) AS cnt FROM `bcc_safety_deposit_boxes` WHERE `owner_id`=? AND `bank_id`=?',
        { owner, bank }
    )[1]
    return tonumber(row and row.cnt) or 0
end

function IsSDBOwner(sdbId, character)
    local row = MySQL.query.await('SELECT `owner_id` FROM `bcc_safety_deposit_boxes` WHERE `id`=? LIMIT 1;', { sdbId })[1]
    if not row then return false end
    return tonumber(row.owner_id) == tonumber(character)
end

function IsSDBAdmin(sdbId, character)
    local row = MySQL.query.await(
        'SELECT `level` FROM `bcc_safety_deposit_boxes_access` WHERE `safety_deposit_box_id`=? AND `character_id`=? LIMIT 1;',
        { sdbId, character }
    )[1]
    if not row then return false end
    local lvl = tonumber(row.level)
    return lvl and lvl <= (Config.AccessLevels and Config.AccessLevels.Admin or 1)
end

function HasSDBAccess(sdbId, character)
    local row = MySQL.query.await(
        'SELECT `level` FROM `bcc_safety_deposit_boxes_access` WHERE `safety_deposit_box_id`=? AND `character_id`=? LIMIT 1;',
        { sdbId, character }
    )[1]
    return row ~= nil
end

function GetSDBAccess(sdbId, character)
    local row = MySQL.query.await(
        'SELECT `level` FROM `bcc_safety_deposit_boxes_access` WHERE `safety_deposit_box_id`=? AND `character_id`=? LIMIT 1;',
        { sdbId, character }
    )[1]
    if not row then return 0 end
    return tonumber(row.level) or 0
end

-- Count SDBs owned by a character at a bank
function GetSDBCount(owner, bank)
    local row = MySQL.query.await(
        'SELECT COUNT(*) AS cnt FROM `bcc_safety_deposit_boxes` WHERE `owner_id`=? AND `bank_id`=?',
        { owner, bank }
    )[1]
    return tonumber(row and row.cnt) or 0
end

-- List all SDBs the character can access at a bank
function GetUserSDBData(character, bank)
    local boxes = MySQL.query.await(
        'SELECT ' ..
            'sdb.id, ' ..
            'sdb.name, ' ..
            'sdb.owner_id, ' ..
            'sdb.inventory_id, ' ..
            'acc.level ' ..
            'FROM bcc_safety_deposit_boxes AS sdb ' ..
            'INNER JOIN bcc_safety_deposit_boxes_access AS acc ' ..
            '  ON sdb.id = acc.safety_deposit_box_id ' ..
            'INNER JOIN bcc_banks AS b ' ..
            '  ON b.id = sdb.bank_id ' ..
            'WHERE acc.character_id = ? ' ..
            '  AND b.id = ?;',
        { character, bank }
    )
    return boxes or {}
end

-- DB-only controller (no inventory, no payments)
function CreateSDB(name, ownerId, bankId, sizeKey)
    -- limit check
    local current = GetSDBCount(ownerId, bankId)
    if Config.SafetyDepositBoxes.MaxBoxes ~= 0 and current >= Config.SafetyDepositBoxes.MaxBoxes then
        return false, "Max boxes limit reached."
    end

    -- size check (case-insensitive)
    local sizes = Config.SafetyDepositBoxes and Config.SafetyDepositBoxes.Sizes or nil
    local resolvedKey = nil
    local sz = nil
    if sizes then
        local want = tostring(sizeKey or ""):lower()
        for k,v in pairs(sizes) do
            if tostring(k):lower() == want then
                resolvedKey = k
                sz = v
                break
            end
        end
    end
    if not sz then
        return false, "Invalid size key: " .. tostring(sizeKey)
    end

    -- insert -> id
    local newId = MySQL.insert.await(
        'INSERT INTO `bcc_safety_deposit_boxes` (`name`, `bank_id`, `owner_id`, `size`) VALUES (?,?,?,?)',
        { name, bankId, ownerId, resolvedKey }
    )
    if not newId or newId <= 0 then
        return false, "Could not create SDB."
    end

    -- load box row
    local box = MySQL.single.await('SELECT * FROM `bcc_safety_deposit_boxes` WHERE `id`=? LIMIT 1;', { newId })
    if not box then
        return false, "SDB row not found after insert."
    end

    return box, sz
end

function GetSDBAccessList(sdbId)
    local result = MySQL.query.await(
        [[
        SELECT character_id, level
        FROM bcc_safety_deposit_boxes_access
        WHERE safety_deposit_box_id = ?
    ]],
        { sdbId }
    )

    return result or {}
end

-- Grant SDB access to another character
function AddSDBAccess(sdbId, character, level)
    MySQL.query.await(
        'INSERT INTO `bcc_safety_deposit_boxes_access` (`safety_deposit_box_id`, `character_id`, `level`) VALUES (?,?,?);',
        { sdbId, character, level }
    )
    return true
end

-- Ownership / access helpers (kept here for cohesion — used by services)
function IsSDBOwner(sdbId, character)
    local row = MySQL.query.await('SELECT `owner_id` FROM `bcc_safety_deposit_boxes` WHERE `id`=? LIMIT 1;', { sdbId })[1]
    if not row then return false end
    return tonumber(row.owner_id) == tonumber(character)
end

function IsSDBAdmin(sdbId, character)
    local row = MySQL.query.await(
        'SELECT `level` FROM `bcc_safety_deposit_boxes_access` WHERE `safety_deposit_box_id`=? AND `character_id`=? LIMIT 1;',
        { sdbId, character }
    )[1]
    if not row then return false end
    local lvl = tonumber(row.level)
    return lvl and lvl <= (Config.AccessLevels and Config.AccessLevels.Admin or 1)
end

function HasSDBAccess(sdbId, character)
    local row = MySQL.query.await(
        'SELECT `level` FROM `bcc_safety_deposit_boxes_access` WHERE `safety_deposit_box_id`=? AND `character_id`=? LIMIT 1;',
        { sdbId, character }
    )[1]
    return row ~= nil
end

function GetSDBAccess(sdbId, character)
    local row = MySQL.query.await(
        'SELECT `level` FROM `bcc_safety_deposit_boxes_access` WHERE `safety_deposit_box_id`=? AND `character_id`=? LIMIT 1;',
        { sdbId, character }
    )[1]
    if not row then return 0 end
    return tonumber(row.level) or 0
end

function RemoveSDBAccess(sdbId, targetCharacter)
    MySQL.query.await(
        'DELETE FROM `bcc_safety_deposit_boxes_access` WHERE `safety_deposit_box_id` = ? AND `character_id` = ?',
        { sdbId, targetCharacter }
    )
    return { status = true, message = 'Access removed.' }
end
