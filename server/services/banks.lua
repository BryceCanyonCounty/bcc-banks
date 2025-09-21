BccUtils.RPC:Register('Feather:Banks:GetBanks', function(params, cb, src)
    cb(true, GetBanks())
end)

BccUtils.RPC:Register('Feather:Banks:CreateBank', function(params, res, src)
    -- Simple admin check (mirror of admin.lua IsBankAdmin logic)
    local function isAdmin()
        if src == 0 then return true end
        local user = VORPcore.getUser(src)
        if not user or not user.getUsedCharacter then return false end
        local ch = user.getUsedCharacter
        for _, g in ipairs(Config.adminGroups or {}) do
            if ch.group == g then return true end
        end
        for _, j in ipairs(Config.AllowedJobs or {}) do
            if ch.job == j then return true end
        end
        return false
    end

    if not isAdmin() then
        NotifyClient(src, _U('admin_no_permission') or 'No permission', 'error', 3500)
        res(false)
        return
    end

    local name = tostring((params and params.name) or 'New Bank')
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
    local bank = params.bank
    res(IsBankerBusy(bank, src))
end)

BccUtils.RPC:Register('Feather:Banks:SetBankerBusy', function(params, res, src)
    local bank = params.bank
    local state = params.state

    if state then
        SetBankerBusy(bank, src)
    else
        ClearBankerBusy(src)
    end
end)
