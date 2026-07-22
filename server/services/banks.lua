BccUtils.RPC:Register('Feather:Banks:GetBanks', function(params, cb, src)
    cb(true, GetBanks())
end)

BccUtils.RPC:Register('Feather:Banks:CreateBank', function(params, res, src)
    if not IsBankAdmin or not IsBankAdmin(src) then
        NotifyClient(src, _U('admin_no_permission') or 'No permission', 'error', 3500)
        res(false)
        return
    end

    local name = tostring((params and params.name) or 'New Bank'):sub(1, 64)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then
        NotifyClient(src, 'Unable to determine your position.', 'error', 3500)
        res(false)
        return
    end
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped) or 0.0
    local x, y, z = coords.x or coords[1], coords.y or coords[2], coords.z or coords[3]
    if not x or not y or not z then
        NotifyClient(src, 'Unable to read your coordinates.', 'error', 3500)
        res(false)
        return
    end

    local bankId = BccUtils.UUID()
    local ok = MySQL.query.await('INSERT INTO `bcc_banks` (id, name, x, y, z, h) VALUES (?, ?, ?, ?, ?, ?);', { bankId, name, x, y, z, heading })
    if ok == nil then
        NotifyClient(src, _U('admin_action_failed') or 'Action failed.', 'error', 3500)
        res(false)
        return
    end
    NotifyClient(src, 'Bank created: ' .. name, 'success', 3000)
    res(true)
end)

BccUtils.RPC:Register('Feather:Banks:GetBankerBusy', function(params, res, src)
    if not Config.UseBankerBusy then
        res(true, false)
        return
    end
    local bank = params and params.bank
    if not NormalizeId(bank) then
        res(false)
        return
    end
    res(true, IsBankerBusy(bank, src))
end)

BccUtils.RPC:Register('Feather:Banks:SetBankerBusy', function(params, res, src)
    if not Config.UseBankerBusy then
        if res then res(true) end
        return
    end
    local bank = params.bank
    local state = params.state

    if state then
        if not SetBankerBusy(bank, src) then
            if res then res(false) end
            return
        end
    else
        ClearBankerBusy(src)
    end
    if res then res(true) end
end)
