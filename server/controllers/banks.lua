local Bankers = {}

function GetBanks()
	local banks = MySQL.query.await('SELECT * FROM `bcc_banks`;')
	return banks
end

function IsBankerBusy(bank, src)
	return Bankers[bank] ~= nil and Bankers[bank] ~= src
end

function SetBankerBusy(bank, src)
	Bankers[bank] = src
end

function ClearBankerBusy(src)
	for k, v in pairs(Bankers) do
		if v == src then
			Bankers[k] = nil
			return
		end
	end
end
