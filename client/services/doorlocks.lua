CreateThread(function()
  for door, state in pairs(Config.Doors) do
    if not IsDoorRegisteredWithSystem(door) then
      Citizen.InvokeNative(0xD99229FE93B46286, door, 1, 1, 0, 0, 0, 0)
    end
    DoorSystemSetDoorState(door, state)
  end
end)
