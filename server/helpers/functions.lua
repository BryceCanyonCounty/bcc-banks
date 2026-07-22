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

function IsFinitePositiveNumber(value)
    local number = tonumber(value)
    -- Account currency columns are DOUBLE(15,2); reject non-finite and oversized
    -- values before they can trigger database overflow or undefined arithmetic.
    return number ~= nil and number > 0 and number == number
        and number < math.huge and number <= 9999999999999.99
end

function IsValidAccessLevel(level)
    level = tonumber(level)
    if not level or level % 1 ~= 0 then return false end
    for _, configuredLevel in pairs(Config.AccessLevels or {}) do
        if level == tonumber(configuredLevel) then return true end
    end
    return false
end

local PlayerFinancialLocks = {}

function AcquirePlayerFinancialLock(src)
    if PlayerFinancialLocks[src] then return false end
    PlayerFinancialLocks[src] = true
    return true
end

function ReleasePlayerFinancialLock(src)
    PlayerFinancialLocks[src] = nil
end

AddEventHandler('playerDropped', function()
    PlayerFinancialLocks[source] = nil
end)

local function isBankOpenNow(bank)
    local active = bank.hours_active == 1 or bank.hours_active == true or bank.hours_active == '1'
    if not active then return true end
    local openHour, closeHour = tonumber(bank.open_hour), tonumber(bank.close_hour)
    if openHour == nil or closeHour == nil then return true end

    local hour
    local ok, current = pcall(function() return exports.weathersync:getTime() end)
    if ok and type(current) == 'table' then hour = tonumber(current.hour) end
    if hour == nil then return true end -- fail open if the configured clock is unavailable
    if openHour == closeHour then return true end
    if openHour < closeHour then return hour >= openHour and hour < closeHour end
    return hour >= openHour or hour < closeHour
end

function IsPlayerNearBank(src, bankId, extraDistance, requireOpen)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    local coords = GetEntityCoords(ped)
    if not coords then return false end

    local maxDistance = tonumber((Config.PromptSettings and Config.PromptSettings.Distance) or 3.0) or 3.0
    maxDistance = maxDistance + (tonumber(extraDistance) or 2.0)

    for _, bank in ipairs(GetBanks() or {}) do
        if not bankId or IdsEqual(bank.id, bankId) then
            local bankCoords = vector3(tonumber(bank.x) or 0, tonumber(bank.y) or 0, tonumber(bank.z) or 0)
            if #(vector3(coords.x, coords.y, coords.z) - bankCoords) <= maxDistance
                and (requireOpen == false or isBankOpenNow(bank)) then
                return true
            end
        end
    end
    return false
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
