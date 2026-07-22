function AddNPC(bank)
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

function ClearNPCs()
	for _, v in pairs(Banks) do
		if v.npc then
			v.npc:Remove()
			v.npc = nil
		end
		v.npcSpawning = false
	end
end
