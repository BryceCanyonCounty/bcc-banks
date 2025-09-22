BccUtils = exports["bcc-utils"].initiate()

function LoadModel(model)
  RequestModel(model)
  while not HasModelLoaded(model) do
    RequestModel(model)
    Wait(100)
  end
end

function Notify(message, typeOrDuration, maybeDuration)
    local notifyType = "info"
    local notifyDuration = 4000

    -- Detect which argument is which
    if type(typeOrDuration) == "string" then
        notifyType = typeOrDuration
        notifyDuration = tonumber(maybeDuration) or 4000
    elseif type(typeOrDuration) == "number" then
        notifyDuration = typeOrDuration
    end

    if Config.Notify == "feather-menu" then
        FeatherMenu:Notify({
            message = message,
            type = notifyType,
            autoClose = notifyDuration,
            position = "top-center",
            transition = "slide",
            icon = true,
            hideProgressBar = false,
            rtl = false,
            style = {},
            toastStyle = {},
            progressStyle = {}
        })
    elseif Config.Notify == "vorp_core" then
        -- Only message and duration supported
        Notify(message, notifyDuration)
    else
        devPrint("[Notify] Invalid Config.Notify:", tostring(Config.Notify))
    end
end

BccUtils.RPC:Register("feather-banks:NotifyClient", function(data)
    Notify(data.message, data.type, data.duration)
end)

function NormalizeId(value)
    if value == nil then return nil end
    if type(value) == 'number' then
        if value ~= value then return nil end
        if math.type and math.type(value) == 'integer' then
            return tostring(value)
        end
        local rounded
        if value >= 0 then
            rounded = math.floor(value + 0.5)
        else
            rounded = math.ceil(value - 0.5)
        end
        return tostring(rounded)
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
