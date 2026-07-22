local Bankers = {}

local function getActiveBanker(bank)
    local key = NormalizeId(bank)
    if not key then return nil, nil end

    local holder = Bankers[key]
    if holder ~= nil and GetPlayerName(holder) == nil then
        -- The previous user disconnected without closing the menu.
        Bankers[key] = nil
        holder = nil
    end
    return key, holder
end

function GetBanks()
	local banks = MySQL.query.await('SELECT * FROM `bcc_banks`;')
	return banks
end

function IsBankerBusy(bank, src)
    local key, holder = getActiveBanker(bank)
    if not key then return false end
    return holder ~= nil and holder ~= src
end

function SetBankerBusy(bank, src)
    local key, holder = getActiveBanker(bank)
    if not key then return false end
    if holder ~= nil and holder ~= src then return false end
    Bankers[key] = src
    return true
end

function ClearBankerBusy(src)
    for k, v in pairs(Bankers) do
        if v == src then
			Bankers[k] = nil
			return
		end
	end
end
