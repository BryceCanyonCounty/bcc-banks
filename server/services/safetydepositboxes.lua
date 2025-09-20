BccUtils.RPC:Register('Feather:Banks:GetSDBs', function(params, cb, src)
    local user = VORPcore.getUser(src)
    if not user then
        devPrint('GetSDBs: no user for src', src)
        NotifyClient(src, _U('error_invalid_character_or_bank'), 'error', 4000)
        cb(false)
        return
    end
    local char = user.getUsedCharacter
    if not char then
        devPrint('GetSDBs: no character for src', src)
        NotifyClient(src, _U('error_invalid_character_or_bank'), 'error', 4000)
        cb(false)
        return
    end
    local characterId = char.charIdentifier
    local bankId = tonumber(params and params.bank)

    if not characterId or not bankId then
        devPrint("GetSDBs: invalid inputs", "characterId=", characterId, "bankId=", bankId)
        NotifyClient(src, _U('error_invalid_character_or_bank'), 'error', 4000)
        cb(false)
        return
    end

    local ok, rows = pcall(function()
        return GetUserSDBData(characterId, bankId)
    end)

    if not ok then
        devPrint("GetSDBs: DB error while fetching SDBs for", characterId, "bank", bankId)
        NotifyClient(src, _U('error_db'), 'error', 4000)
        cb(false)
        return
    end

    cb(true, rows or {})
end)

BccUtils.RPC:Register('Feather:Banks:CreateSDB', function(params, cb, src)
    local user = VORPcore.getUser(src)
    if not user then NotifyClient(src, _U('error_invalid_data'), 'error', 4000) return cb(false) end
    local char = user.getUsedCharacter
    if not char then NotifyClient(src, _U('error_invalid_data'), 'error', 4000) return cb(false) end

    -- inputs
    local characterId = char.charIdentifier          -- adjust if your framework uses a different name
    local name        = params and params.name
    local bank        = tonumber(params and params.bank)
    local sizeKey     = params and params.size
    local payWith     = (params and params.payWith) or "cash"  -- "cash" | "gold"

    if not characterId or not bank or not name or name == "" or not sizeKey then
        devPrint("CreateSDB invalid inputs", characterId, bank, name, sizeKey)
        NotifyClient(src, _U('error_invalid_data'), 'error', 4000)
        return cb(false)
    end

    -- resolve size & price from config (case-insensitive)
    local sizes = Config.SafetyDepositBoxes.Sizes or {}
    local resolvedKey, sz
    do
        local want = tostring(sizeKey):lower()
        for k,v in pairs(sizes) do
            if tostring(k):lower() == want then resolvedKey = k; sz = v; break end
        end
    end
    if not sz then
        NotifyClient(src, _U('error_invalid_data'), 'error', 4000)
        return cb(false)
    end

    local CURRENCY = { cash = 0, gold = 1 }
    local currencyId = CURRENCY[(payWith == 'gold') and 'gold' or 'cash']
    local price = (payWith == 'gold') and (sz.GoldPrice or 0) or (sz.CashPrice or 0)
    if price <= 0 then
        NotifyClient(src, _U('error_invalid_data'), 'error', 4000)
        return cb(false)
    end

    -- check balance using VORP character fields
    local balance = (currencyId == 0) and tonumber(char.money) or tonumber(char.gold)
    if not balance or balance < price then
        if currencyId == 0 then
            NotifyClient(src, _U('error_not_enough_cash', tostring(balance or 0)), 'error', 4000)
        else
            NotifyClient(src, _U('error_not_enough_gold_to_sell'), 'error', 4000)
        end
        return cb(false)
    end

    -- try to charge first so we don't create resources the player can't pay for
    local charged = false
    local chargeOk, chargeErr = pcall(function()
        char.removeCurrency(currencyId, price)
        charged = true
    end)
    if not chargeOk then
        devPrint("CreateSDB charge failed:", tostring(chargeErr))
        NotifyClient(src, _U('error_unable_create_sdb'), 'error', 4000)
        return cb(false)
    end

    -- create DB row
    local ok, boxOrErr, szFromCtrl = pcall(CreateSDB, name, characterId, bank, resolvedKey)
    if not ok or boxOrErr == false then
        -- refund if DB failed
        if charged then pcall(function() if char.addCurrency then char.addCurrency(currencyId, price) end end) end
        devPrint("CreateSDB DB failed:", tostring(ok and (szFromCtrl or "unknown") or boxOrErr))
        NotifyClient(src, _U('error_unable_create_sdb'), 'error', 4000)
        return cb(false)
    end
    local box = boxOrErr
    local szCfg = szFromCtrl or sz

    -- register inventory & grant access
    local invId   = 'sdb_' .. tostring(box.id)
    local invName = 'SDB #' .. tostring(box.id)
    local restrictedItems  = (szCfg.BlacklistItems and #szCfg.BlacklistItems or 0) > 0 and szCfg.BlacklistItems or nil
    local ignoreItemLimits = (szCfg.IgnoreItemLimit == true)

    local invOk, invErr = pcall(function()
        exports.vorp_inventory:registerInventory({
            id = invId,
            name = invName,
            limit = 100,
            acceptWeapons = true,
            shared = true,
            ignoreItemStackLimit = ignoreItemLimits,
            whitelistItems = false,
            UsePermissions = false,
            UseBlackList = restrictedItems ~= nil,
            whitelistWeapons = false,
        })
        if restrictedItems then
            for _, itemName in ipairs(restrictedItems) do
                exports.vorp_inventory:BlackListCustomAny(invId, itemName)
            end
        end

        MySQL.update.await('UPDATE `bcc_safety_deposit_boxes` SET `inventory_id`=? WHERE `id`=?', { invId, box.id })
        MySQL.insert.await(
            'INSERT INTO `bcc_safety_deposit_boxes_access` (`safety_deposit_box_id`, `character_id`, `level`) VALUES (?,?,?)',
            { box.id, characterId, Config.AccessLevels.Admin }
        )
    end)

    if not invOk then
        -- rollback + refund
        pcall(function()
            MySQL.query.await('DELETE FROM `bcc_safety_deposit_boxes_access` WHERE `safety_deposit_box_id`=?', { box.id })
            MySQL.query.await('DELETE FROM `bcc_safety_deposit_boxes` WHERE `id`=?', { box.id })
            if charged and char.addCurrency then char.addCurrency(currencyId, price) end
        end)
        devPrint("CreateSDB: inventory registration failed:", tostring(invErr))
        NotifyClient(src, _U('error_unable_create_sdb'), 'error', 4000)
        return cb(false)
    end

    -- success (client will show its own toast)
    cb(true, box)
end)

local function resolveSDBSizeConfig(sizeKey)
    if not sizeKey then return nil end
    local sizes = Config and Config.SafetyDepositBoxes and Config.SafetyDepositBoxes.Sizes or {}
    if not sizes then return nil end
    local want = tostring(sizeKey)
    local wantLower = want:lower()
    for key, cfg in pairs(sizes) do
        local keyStr = tostring(key)
        if keyStr == want or keyStr:lower() == wantLower then
            return cfg
        end
    end
    return nil
end

local function ensureSDBInventoryRegistered(boxId, inventoryId, displayName, sizeKey)
    local invId = inventoryId
    if not invId or invId == '' then
        invId = 'sdb_' .. tostring(boxId)
    end

    local invName = (displayName and displayName ~= '') and displayName or ('SDB #' .. tostring(boxId))
    local sizeCfg = resolveSDBSizeConfig(sizeKey)
    local ignoreStacks = sizeCfg and sizeCfg.IgnoreItemLimit == true
    local blacklist = (sizeCfg and sizeCfg.BlacklistItems and #sizeCfg.BlacklistItems > 0) and sizeCfg.BlacklistItems or nil
    local limit = tonumber(sizeCfg and sizeCfg.MaxWeight) or 100

    local isRegistered = exports.vorp_inventory:isCustomInventoryRegistered(invId)
    if not isRegistered then
        exports.vorp_inventory:registerInventory({
            id = invId,
            name = invName,
            limit = limit,
            acceptWeapons = true,
            shared = true,
            ignoreItemStackLimit = ignoreStacks,
            whitelistItems = false,
            UsePermissions = false,
            UseBlackList = blacklist ~= nil,
            whitelistWeapons = false,
        })

        if blacklist then
            for _, itemName in ipairs(blacklist) do
                exports.vorp_inventory:BlackListCustomAny(invId, itemName)
            end
        end
    end

    return invId, invName, sizeCfg
end

BccUtils.RPC:Register('Feather:Banks:OpenSDB', function(params, cb, src)
    local user = VORPcore.getUser(src)
    if not user then
        devPrint('OpenSDB: no user for src', src)
        NotifyClient(src, _U('error_invalid_data'), 'error', 4000)
        cb(false)
        return
    end
    local char = user.getUsedCharacter
    if not char then
        devPrint('OpenSDB: no character for src', src)
        NotifyClient(src, _U('error_invalid_data'), 'error', 4000)
        cb(false)
        return
    end
    local characterId = char.charIdentifier
    local sdbId = tonumber(params and params.sdb_id)

    if not characterId or not sdbId then
        devPrint("OpenSDB: invalid inputs", "characterId=", characterId, "sdbId=", sdbId)
        NotifyClient(src, _U('error_invalid_data'), 'error', 4000)
        cb(false)
        return
    end

    if not HasSDBAccess(sdbId, characterId) then
        devPrint("OpenSDB: no access", "charId=", characterId, "sdbId=", sdbId)
        NotifyClient(src, _U('error_insufficient_access'), 'error', 4000)
        cb(false)
        return
    end

    -- Always query our table name directly
    local row = MySQL.query.await(
        'SELECT `inventory_id`,`name`,`size` FROM `bcc_safety_deposit_boxes` WHERE `id`=? LIMIT 1;',
        { sdbId }
    )[1]
    if not row then
        devPrint("OpenSDB: SDB row not found for id", sdbId)
        NotifyClient(src, _U('error_sdb_not_found'), 'error', 4000)
        cb(false)
        return
    end

    local invId, invName = ensureSDBInventoryRegistered(sdbId, row.inventory_id, row.name, row.size)
    if not row.inventory_id or row.inventory_id ~= invId then
        MySQL.query.await('UPDATE `bcc_safety_deposit_boxes` SET `inventory_id`=? WHERE `id`=?', { invId, sdbId })
        row.inventory_id = invId
    end

    local invIdStr = tostring(invId)
    devPrint('OpenSDB: attempting openInventory for', invId, 'src=', src)
    Wait(100)
    -- Proactively close any current inventory to avoid conflicts
    --[[pcall(function() exports.vorp_inventory:closeInventory(src) end)
    local ok, err = pcall(function()
        exports.vorp_inventory:openInventory(src, invId)
    end)]]--
    --[[if not ok then
        devPrint('OpenSDB: openInventory error:', tostring(err))
        NotifyClient(src, _U('error_unable_open_sdb') or 'Unable to open SDB right now.', 'error', 3500)
        cb(false)
        return
    end]]--
    devPrint("[OpenInv] Opening " .. invIdStr .. " for src " .. tostring(src))
    exports.vorp_inventory:openInventory(src, invIdStr)
    cb(true)
end)

BccUtils.RPC:Register('Feather:Banks:GetSDBAccessList', function(params, cb, src)
    local sdbId = tonumber(params and params.sdb_id)
    if not sdbId then
        devPrint("GetSDBAccessList: invalid sdbId", params and params.sdb_id)
        NotifyClient(src, _U('error_invalid_sdb_id'), 'error', 4000)
        cb(false)
        return
    end

    local rawAccessList = GetSDBAccessList(sdbId)
    local accessList = {}

    devPrint("Raw DB access rows:", json.encode(rawAccessList))

    for _, row in ipairs(rawAccessList) do
        -- Resolve names from DB using VORP charidentifier (works for offline characters)
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

    cb(true, { access = accessList })
end)

BccUtils.RPC:Register('Feather:Banks:AddSDBAccess', function(params, cb, src)
    devPrint("AddSDBAccess RPC called. src=", src, "params=", params)

    local user          = VORPcore.getUser(src)
    local requesterId
    do
        if not user then
            devPrint("AddSDBAccess: requester user not found")
            NotifyClient(src, _U('error_invalid_data_provided'), "error", 4000)
            cb(false)
            return
        end
        local ch = user.getUsedCharacter
        if not ch then
            devPrint("AddSDBAccess: requester character not found")
            NotifyClient(src, _U('error_invalid_data_provided'), "error", 4000)
            cb(false)
            return
        end
        requesterId = ch.charIdentifier
    end
    local sdbId         = tonumber(params and params.sdb_id)
    -- Expect a VORP character identifier (charidentifier). Keep compatibility with older param name 'user_src'
    local otherCharId   = tonumber(params and params.character) or tonumber(params and params.user_src)
    if not otherCharId then
        devPrint("AddSDBAccess: invalid target character id")
        NotifyClient(src, _U('error_invalid_data_provided'), 'error', 4000)
        cb(false)
        return
    end
    local level         = tonumber(params and params.level)

    devPrint("Parsed inputs → sdbId:", sdbId, "otherCharId:", otherCharId, "level:", level, "requesterId:", requesterId)

    -- Validation
    if not requesterId or not sdbId or not otherCharId or not level then
        devPrint("AddSDBAccess: Invalid input data.")
        NotifyClient(src, _U('error_invalid_data_provided'), "error", 4000)
        cb(false)
        return
    end

    -- Permission check
    if not (IsSDBAdmin(sdbId, requesterId) or IsSDBOwner(sdbId, requesterId)) then
        devPrint("AddSDBAccess: Source", requesterId, "is not admin or owner of SDB", sdbId)
        NotifyClient(src, _U('error_no_permission'), "error", 4000)
        cb(false)
        return
    end

    -- Prevent giving access to self
    if requesterId == otherCharId then
        devPrint("AddSDBAccess: Attempted to give access to self.")
        NotifyClient(src, _U('warn_you_already_have_access_box'), "warning", 4000)
        cb(false)
        return
    end

    -- Check if target character exists in DB
    local exists = MySQL.query.await("SELECT 1 FROM characters WHERE charidentifier = ? LIMIT 1", { otherCharId })
    if not exists or not exists[1] then
        devPrint("AddSDBAccess: Target character not found in DB →", otherCharId)
        NotifyClient(src, _U('error_target_character_not_found'), "error", 4000)
        cb(false)
        return
    end

    -- Check if they already have access
    local already = MySQL.query.await([[
        SELECT 1 FROM bcc_safety_deposit_boxes_access
        WHERE safety_deposit_box_id = ? AND character_id = ? LIMIT 1
    ]], { sdbId, otherCharId })

    if already and already[1] then
        devPrint("AddSDBAccess: Target already has access. sdbId=", sdbId, "charId=", otherCharId)
        NotifyClient(src, _U('warn_already_has_access_box'), "warning", 4000)
        cb(false)
        return
    end

    -- Insert access row
    local success = MySQL.query.await([[
        INSERT INTO bcc_safety_deposit_boxes_access (safety_deposit_box_id, character_id, level)
        VALUES (?, ?, ?)
    ]], { sdbId, otherCharId, level })

    devPrint("AddSDBAccess: Access granted. sdbId=", sdbId, "charId=", otherCharId, "level=", level)
    NotifyClient(src, _U('success_access_granted'), "success", 4000)
    cb(true)
end)

BccUtils.RPC:Register('Feather:Banks:RemoveSDBAccess', function(params, cb, src)
    devPrint("RemoveSDBAccess RPC called. src=", src, "params=", params)

    local user = VORPcore.getUser(src)
    if not user or not user.getUsedCharacter then
        devPrint("RemoveSDBAccess: requester not found")
        NotifyClient(src, _U('error_invalid_input'), "error", 4000)
        cb(false)
        return
    end
    local requesterId = user.getUsedCharacter.charIdentifier

    local sdbId = tonumber(params and params.sdb_id)
    local targetCharId = tonumber(params and params.character)

    devPrint("Parsed inputs → sdbId:", sdbId, "target:", targetCharId, "requesterId:", requesterId)

    -- Validate input
    if not requesterId or not sdbId or not targetCharId then
        devPrint("RemoveSDBAccess: Invalid input data.")
        NotifyClient(src, _U('error_invalid_input'), "error", 4000)
        cb(false)
        return
    end

    -- Permission check
    if not (IsSDBAdmin(sdbId, requesterId) or IsSDBOwner(sdbId, requesterId)) then
        devPrint("RemoveSDBAccess: Character", requesterId, "is not admin or owner of SDB", sdbId)
        NotifyClient(src, _U('error_no_permission'), "error", 4000)
        cb(false)
        return
    end

    local result = RemoveSDBAccess(sdbId, targetCharId)

    if not result or result.status == false then
        devPrint("RemoveSDBAccess: Failed to remove access.")
        NotifyClient(src, _U('error_failed_remove_access'), "error", 4000)
        cb(false)
        return
    end

    NotifyClient(src, _U('success_access_removed'), "success", 4000)
    cb(true)
end)
