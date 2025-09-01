function NotifyClient(src, message, type, duration)
    Feather.RPC.Notify("feather-banks:NotifyClient", {
        message = message,
        type = type or "info",
        duration = duration or 4000
    }, src)
end

if Config.devMode then
    function devPrint(...)
        local args = { ... }
        for i = 1, #args do
            if type(args[i]) == "table" then
                args[i] = json.encode(args[i])
            elseif args[i] == nil then
                args[i] = "nil"
            else
                args[i] = tostring(args[i])
            end
        end
        print("^1[DEV MODE] ^4" .. table.concat(args, " ") .. "^0")
    end
else
    function devPrint(...) end
end