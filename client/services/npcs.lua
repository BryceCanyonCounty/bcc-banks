local function deletePedEntity(ped)
	if not ped or ped == 0 or not DoesEntityExist(ped) then return end
	SetEntityAsMissionEntity(ped, true, true)
	DeletePed(ped)
	if DoesEntityExist(ped) then DeleteEntity(ped) end
end

local function clearOrphanedTellersAtBank(bank)
	local model = Config.NPCSettings.Model
	local modelHash = type(model) == 'number' and model or GetHashKey(model)
	local bankCoords = vector3(tonumber(bank.x), tonumber(bank.y), tonumber(bank.z))
	for _, ped in ipairs(GetGamePool('CPed') or {}) do
		if ped ~= PlayerPedId() and DoesEntityExist(ped) and GetEntityModel(ped) == modelHash then
			local coords = GetEntityCoords(ped)
			if #(coords - bankCoords) <= 2.0 then
				deletePedEntity(ped)
			end
		end
	end
end

function AddNPC(bank)
	-- A resource restart can leave the old locally-created wrapper entity behind.
	-- Remove matching tellers at this exact bank before creating its replacement.
	clearOrphanedTellersAtBank(bank)
	local npc = BccUtils.Ped:Create(Config.NPCSettings.Model, tonumber(bank.x), tonumber(bank.y), tonumber(bank.z),tonumber(bank.h), 'world', false, nil, nil, true, nil)
	local ped = npc:GetPed()

	-- Teller NPCs are fixtures, not ambient pedestrians. Blocking ambient events and
	-- fleeing prevents gunshots from starting a flee task while the entity is frozen
	-- (the combination that makes the ped appear to run in place).
	ClearPedTasksImmediately(ped)
	SetBlockingOfNonTemporaryEvents(ped, true)
	SetPedFleeAttributes(ped, 0, false)
	SetPedCanRagdoll(ped, false)
	SetEntityInvincible(ped, true)
	SetEntityCanBeDamaged(ped, false)
	npc:Freeze()
	return npc
end

function RemoveNPC(bank)
	if not bank or not bank.npc then return end
	local npc = bank.npc
	local ok, ped = pcall(function() return npc:GetPed() end)
	if ok then deletePedEntity(ped) end
	pcall(function() npc:Remove() end)
	bank.npc = nil
	bank.npcSpawning = false
end

function ClearNPCs()
	for _, v in pairs(Banks) do
		RemoveNPC(v)
		v.npcSpawning = false
	end
end
