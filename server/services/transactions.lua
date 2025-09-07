BccUtils.RPC:Register('Feather:Banks:GetTransactions', function(params, cb, src)
    devPrint("RPC called by src:", src)

    local account = tonumber(params and params.account)
    devPrint("Received account ID:", account)

    if not account then
        devPrint("Invalid account ID.")
        NotifyClient(src, _U('error_invalid_account_id') or 'Invalid account id.', 'error', 4000)
        cb(false)
        return
    end

    local ok, rows = pcall(function()
        return GetAccountTransactions(account)
    end)

    devPrint("DB query status:", ok)

    if not ok then
        devPrint("Database error during transaction fetch.")
        NotifyClient(src, _U('error_db') or 'DB error.', 'error', 4000)
        cb(false)
        return
    end

    rows = rows or {}

    -- Format created_at server-side to avoid client os/date limitations
    local function fmtWhen(val)
        local function pad2(n)
            n = tonumber(n) or 0
            if n < 10 then return '0' .. n end
            return tostring(n)
        end
        if type(val) == 'number' then
            local secs = (val > 1e12) and math.floor(val / 1000) or math.floor(val)
            local t = os.date('*t', secs)
            return pad2(t.day) .. '/' .. pad2(t.month) .. '/' .. tostring(t.year) .. ' ' .. pad2(t.hour) .. ':' .. pad2(t.min)
        elseif type(val) == 'string' then
            local y, m, d, h, mi = string.match(val, '^(%d+)%-(%d+)%-(%d+)%s+(%d+):(%d+)')
            if y then
                return tostring(d) .. '/' .. tostring(m) .. '/' .. tostring(y) .. ' ' .. tostring(h) .. ':' .. tostring(mi)
            end
            local num = tonumber(val)
            if num then
                return fmtWhen(num)
            end
        end
        return tostring(val or '')
    end

    for _, r in ipairs(rows) do
        r.created_at = fmtWhen(r.created_at)
    end

    devPrint("Transactions returned:", #rows)

    if rows[1] then
        devPrint("First transaction sample:")
        for k, v in pairs(rows[1]) do
            devPrint("  ", k, v)
        end
    end

    cb(true, rows)
end)
