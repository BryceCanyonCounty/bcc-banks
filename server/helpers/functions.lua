function NotifyClient(src, message, type, duration)
    BccUtils.RPC:Notify("feather-banks:NotifyClient", {
        message = message,
        type = type or "info",
        duration = duration or 4000
    }, src)
end

function NormalizeId(value)
    if value == nil then return nil end
    if type(value) == 'number' then
        if value ~= value then return nil end
        return string.format('%.0f', value)
    end
    local str = tostring(value)
    str = str:match('^%s*(.-)%s*$') or str
    if str == '' then return nil end
    return str
end

function IdsEqual(left, right)
    local a = NormalizeId(left)
    local b = NormalizeId(right)
    if not a or not b then return false end
    return a == b
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
