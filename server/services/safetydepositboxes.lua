Feather.RPC.Register('Feather:Banks:GetSDBs', function(params, cb, src)
    local player = Feather.Character.GetCharacter({ src = src })
    local characterId = player and player.char and player.char.id
    local bankId = tonumber(params and params.bank)

    if not characterId or not bankId then
        cb(false, { message = "Invalid character or bank." })
        return
    end

    local ok, rows = pcall(function()
        return GetUserSDBData(characterId, bankId)
    end)

    if not ok then
        cb(false, { message = "DB error." })
        return
    end

    cb(true, rows or {})
end)

Feather.RPC.Register('Feather:Banks:CreateSDB', function(params, cb, src)
    local player = Feather.Character.GetCharacter({ src = src })
    local characterId = player and player.char and player.char.id

    local name = params and params.name
    local bank = tonumber(params and params.bank)
    local size = params and params.size

    if not characterId or not bank or not name or name == "" or not size then
        cb(false, { message = "Invalid data." })
        return
    end

    local ok, res, msg = pcall(CreateSDB, name, characterId, bank, size)
    if not ok then
        cb(false, { message = "Unhandled error: " .. tostring(res) })
        return
    end
    if res == false then
        cb(false, { message = msg or "Unable to create SDB." })
        return
    end

    cb(true, res)
end)

Feather.RPC.Register('Feather:Banks:OpenSDB', function(params, cb, src)
    local player = Feather.Character.GetCharacter({ src = src })
    local characterId = player and player.char and player.char.id
    local sdbId = tonumber(params and params.sdb_id)

    if not characterId or not sdbId then
        cb(false, { message = "Invalid data." })
        return
    end

    if not HasSDBAccess(sdbId, characterId) then
        cb(false, { message = "Insufficient Access" })
        return
    end

    local row = MySQL.query.await(
        'SELECT `inventory_id`,`name` FROM `safety_deposit_boxes` WHERE `id`=? LIMIT 1;',
        { sdbId }
    )[1]
    if not row or not row.inventory_id then
        cb(false, { message = "SDB not found." })
        return
    end

    -- Open the inventory for THIS player (server-side; src is available here)
    FeatherInventory.Inventory.OpenInventory(src, tostring(row.inventory_id))

    cb(true, { opened = true, name = row.name })
end)

-- Grant SDB access
Feather.RPC.Register('Feather:Banks:AddSDBAccess', function(params, cb, src)
    local player = Feather.Character.GetCharacter({ src = src })
    local requester = player and player.char and player.char.id
    local sdbId = tonumber(params and params.sdb_id)
    local otherSrc = tonumber(params and params.user_src)
    local level = tonumber(params and params.level)

    if not requester or not sdbId or not otherSrc or not level then
        cb(false, { message = "Invalid data." })
        return
    end

    if not (IsSDBOwner(sdbId, requester) or IsSDBAdmin(sdbId, requester)) then
        cb(false, { message = "Insufficient Access" })
        return
    end

    local otherCharObj = Feather.Character.GetCharacterBySrc(otherSrc)
    local otherCharId = otherCharObj and otherCharObj.char and otherCharObj.char.id
    if not otherCharId then
        cb(false, { message = "Target character not found." })
        return
    end

    local ok, err = pcall(function()
        return AddSDBAccess(sdbId, otherCharId, level)
    end)

    if not ok then
        cb(false, { message = "DB error." })
        return
    end

    cb(true, { message = "Access granted." })
end)
