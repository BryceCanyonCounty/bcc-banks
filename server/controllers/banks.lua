local Bankers = {}

function GetBanks()
	local banks = MySQL.query.await('SELECT * FROM `bcc_banks`;')
	return banks
end

function IsBankerBusy(bank, src)
    local key = NormalizeId(bank)
    if not key then return false end
    return Bankers[key] ~= nil and Bankers[key] ~= src
end

function SetBankerBusy(bank, src)
    local key = NormalizeId(bank)
    if not key then return end
    Bankers[key] = src
end

function ClearBankerBusy(src)
    for k, v in pairs(Bankers) do
        if v == src then
			Bankers[k] = nil
			return
		end
	end
end
