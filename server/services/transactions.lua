Feather.RPC.Register('Feather:Banks:GetTransactions', function(params, cb, src)
    print("[BANK DEBUG] RPC called by src:", src)

    local account = tonumber(params and params.account)
    print("[BANK DEBUG] Received account ID:", account)

    if not account then
        print("[BANK DEBUG] Invalid account ID.")
        NotifyClient(src, "Invalid account id.")
        cb(false)
        return
    end

    local ok, rows = pcall(function()
        return GetAccountTransactions(account)
    end)

    print("[BANK DEBUG] DB query status:", ok)

    if not ok then
        print("[BANK DEBUG] Database error during transaction fetch.")
        NotifyClient(src, "DB error.")
        cb(false)
        return
    end

    rows = rows or {}
    print("[BANK DEBUG] Transactions returned:", #rows)

    if rows[1] then
        print("[BANK DEBUG] First transaction sample:")
        for k, v in pairs(rows[1]) do
            print("  [BANK DEBUG] ", k, v)
        end
    end

    cb(true, rows)
end)
