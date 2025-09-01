function GetSDBCount(owner, bank)
	local row = MySQL.query.await(
		'SELECT COUNT(*) AS cnt FROM `safety_deposit_boxes` WHERE `owner_id`=? AND `bank_id`=?',
		{ owner, bank }
	)[1]
	return tonumber(row and row.cnt) or 0
end

function IsSDBOwner(sdbId, character)
	local row = MySQL.query.await('SELECT `owner_id` FROM `safety_deposit_boxes` WHERE `id`=? LIMIT 1;', { sdbId })[1]
	if not row then return false end
	return tonumber(row.owner_id) == tonumber(character)
end

function IsSDBAdmin(sdbId, character)
	local row = MySQL.query.await(
		'SELECT `level` FROM `safety_deposit_boxes_access` WHERE `safety_deposit_box_id`=? AND `character_id`=? LIMIT 1;',
		{ sdbId, character }
	)[1]
	if not row then return false end
	local lvl = tonumber(row.level)
	return lvl and lvl <= (Config.AccessLevels and Config.AccessLevels.Admin or 1)
end

function HasSDBAccess(sdbId, character)
	local row = MySQL.query.await(
		'SELECT `level` FROM `safety_deposit_boxes_access` WHERE `safety_deposit_box_id`=? AND `character_id`=? LIMIT 1;',
		{ sdbId, character }
	)[1]
	return row ~= nil
end

function GetSDBAccess(sdbId, character)
	local row = MySQL.query.await(
		'SELECT `level` FROM `safety_deposit_boxes_access` WHERE `safety_deposit_box_id`=? AND `character_id`=? LIMIT 1;',
		{ sdbId, character }
	)[1]
	if not row then return 0 end
	return tonumber(row.level) or 0
end

-- Count SDBs owned by a character at a bank
function GetSDBCount(owner, bank)
	local row = MySQL.query.await(
		'SELECT COUNT(*) AS cnt FROM `safety_deposit_boxes` WHERE `owner_id`=? AND `bank_id`=?',
		{ owner, bank }
	)[1]
	return tonumber(row and row.cnt) or 0
end

-- List all SDBs the character can access at a bank
function GetUserSDBData(character, bank)
	local boxes = MySQL.query.await(
		[[
            SELECT
                sdb.`id`,
                sdb.`name`,
                sdb.`owner_id`,
                sdb.`inventory_id`,
                acc.`level`
            FROM `safety_deposit_boxes` AS sdb
            INNER JOIN `safety_deposit_boxes_access` AS acc
                ON sdb.`id` = acc.`safety_deposit_box_id`
            INNER JOIN `banks` AS b
                ON b.`id` = sdb.`bank_id`
            WHERE acc.`character_id` = ? AND b.`id` = ?;
        ]],
		{ character, bank }
	)
	return boxes
end
function CreateSDB(name, owner, bank, size)
    -- limit check
    local current = GetSDBCount(owner, bank)
    if Config.SafetyDepositBoxes.MaxBoxes ~= 0 and current >= Config.SafetyDepositBoxes.MaxBoxes then
        return false, "Max boxes limit reached."
    end

    -- size check
    local sizes = Config.SafetyDepositBoxes and Config.SafetyDepositBoxes.Sizes or nil
    local sz = sizes and sizes[size] or nil
    if not sz then
        return false, "Invalid size key: " .. tostring(size)
    end

    -- insert SDB (no RETURNING in MySQL)
    MySQL.query.await(
        'INSERT INTO `safety_deposit_boxes` (`name`, `bank_id`, `owner_id`, `size`) VALUES (?,?,?,?)',
        { name, bank, owner, size }
    )

    -- fetch new id
    local idRow = MySQL.query.await('SELECT LAST_INSERT_ID() AS id;')[1]
    local newId = idRow and idRow.id
    if not newId then
        return false, "Could not fetch new SDB id."
    end

    -- load box row
    local box = MySQL.query.await('SELECT * FROM `safety_deposit_boxes` WHERE `id`=? LIMIT 1;', { newId })[1]
    if not box then
        return false, "SDB row not found after insert."
    end

    -- inventory settings from size
    local maxWeight        = sz.MaxWeight
    local restrictedItems  = (sz.BlacklistItems and #sz.BlacklistItems or 0) > 0 and sz.BlacklistItems or nil
    local ignoreItemLimits = (sz.IgnoreItemLimit == true)

    -- register inventory (adjust the call if your API is FeatherInventory.Inventory.RegisterInventory)
    local inventoryId = FeatherInventory.Inventory.RegisterInventory(
        'safety_deposit_boxes', box.id, maxWeight, restrictedItems, ignoreItemLimits
    )
    if not inventoryId then
        return false, "Inventory registration failed."
    end

    -- persist inventory id
    MySQL.query.await('UPDATE `safety_deposit_boxes` SET `inventory_id`=? WHERE `id`=?', { inventoryId, box.id })

    -- grant owner admin access (FK must point to safety_deposit_boxes.id)
    MySQL.query.await(
        'INSERT INTO `safety_deposit_boxes_access` (`safety_deposit_box_id`, `character_id`, `level`) VALUES (?,?,?)',
        { box.id, owner, Config.AccessLevels.Admin }
    )

    return box
end

-- Grant SDB access to another character
function AddSDBAccess(sdbId, character, level)
	MySQL.query.await(
		'INSERT INTO `safety_deposit_boxes_access` (`safety_deposit_box_id`, `character_id`, `level`) VALUES (?,?,?);',
		{ sdbId, character, level }
	)
	return true
end

-- Ownership / access helpers (kept here for cohesion — used by services)
function IsSDBOwner(sdbId, character)
	local row = MySQL.query.await('SELECT `owner_id` FROM `safety_deposit_boxes` WHERE `id`=? LIMIT 1;', { sdbId })[1]
	if not row then return false end
	return tonumber(row.owner_id) == tonumber(character)
end

function IsSDBAdmin(sdbId, character)
	local row = MySQL.query.await(
		'SELECT `level` FROM `safety_deposit_boxes_access` WHERE `safety_deposit_box_id`=? AND `character_id`=? LIMIT 1;',
		{ sdbId, character }
	)[1]
	if not row then return false end
	local lvl = tonumber(row.level)
	return lvl and lvl <= (Config.AccessLevels and Config.AccessLevels.Admin or 1)
end

function HasSDBAccess(sdbId, character)
	local row = MySQL.query.await(
		'SELECT `level` FROM `safety_deposit_boxes_access` WHERE `safety_deposit_box_id`=? AND `character_id`=? LIMIT 1;',
		{ sdbId, character }
	)[1]
	return row ~= nil
end

function GetSDBAccess(sdbId, character)
	local row = MySQL.query.await(
		'SELECT `level` FROM `safety_deposit_boxes_access` WHERE `safety_deposit_box_id`=? AND `character_id`=? LIMIT 1;',
		{ sdbId, character }
	)[1]
	if not row then return 0 end
	return tonumber(row.level) or 0
end
