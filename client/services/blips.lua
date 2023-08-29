function AddBlip(bank)
  local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, tonumber(bank.x), tonumber(bank.y), tonumber(bank.z))
  SetBlipSprite(blip, bank.blip, 1)
  SetBlipScale(blip, 0.2)
  local bankName = bank.name .. " Bank"
  Citizen.InvokeNative(0x9CB1A1623062F402, blip, bankName)
  return blip
end

function SetBlipColor(blip, isClosed)
  if isClosed then
    Citizen.InvokeNative(0x662D364ABF16DE2F, blip,
      joaat(Config.BlipSettings.AvailableColors[Config.BlipSettings.Colors.Closed]))
  else
    Citizen.InvokeNative(0x662D364ABF16DE2F, blip,
      joaat(Config.BlipSettings.AvailableColors[Config.BlipSettings.Colors.Open]))
  end
end

function ClearBlips()
  for _, v in pairs(Banks) do
    if v.blip_handle then
      RemoveBlip(v.blip_handle)
      v.blip_handle = nil
    end
  end
end
