function AddNPC(bank)
	local npc = BccUtils.Ped:Create(Config.NPCSettings.Model, tonumber(bank.x), tonumber(bank.y), tonumber(bank.z),tonumber(bank.h), 'world', false, nil, nil, true, nil)
	npc:Freeze()
	npc:Invincible()
	npc:CanBeDamaged()
	npc:SetPedCombatAttributes()
	npc:SetBlockingOfNonTemporaryEvents()
	return npc
end

function ClearNPCs()
	for _, v in pairs(Banks) do
		if v.npc then
			v.npc:Remove()
			v.npc = nil
		end
	end
end
