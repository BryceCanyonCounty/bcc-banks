local IsReady = false
Banks = {}

-- DEBUG COMMAND - Needed until CharacterSpawned Event is created
RegisterCommand('banksReady', function(args, src, rawCommand)
  Banks = Feather.RPC.CallAsync('Feather:Banks:GetBanks', nil)
  if Len(Banks) <= 0 then
    error('Unable to retrieve banks!')
    return
  end

  IsReady = true
  TriggerEvent('Feather:Banks:Start')
end)

RegisterNetEvent('Feather:Banks:Start', function()
  BankOpen()
  BankClosed()

  while (IsReady) do
    Wait(0)
    local sleep = true
    local playerPed = PlayerPedId()
    local playerCords = GetEntityCoords(playerPed)

    for _, bank in pairs(Banks) do
      -- Handle Open/Close Banks
      if bank.open_hour and bank.close_hour then
        local hour = GetClockHours()
        if hour >= bank.close_hour or hour < bank.open_hour then
          bank.isClosed = true
        else
          if bank.isClosed then
            bank.isClosed = false
            if bank.blip_handle then
              SetBlipColor(bank.blip_handle, bank.isClosed)
            end
          end
        end
      end

      -- Handle Closed Cleanup
      if bank.isClosed then
        if bank.blip_handle then
          if Config.BlipSettings.Show and Config.BlipSettings.ShowClosed then
            SetBlipColor(bank.blip_handle, bank.isClosed)
          else
            bank.blip_handle.Remove()
            bank.blip_handle = nil
          end
        end

        if bank.npc then
          bank.npc:Remove()
          bank.npc = nil
        end
      end

      local bankCords = vector3(tonumber(bank.x), tonumber(bank.y), tonumber(bank.z))
      local distance = #(playerCords - bankCords)

      -- Handle Blips
      if Config.BlipSettings.Show then
        if Config.BlipSettings.UseDistance then
          if distance <= Config.BlipSettings.Distance then
            if not bank.blip_handle then
              bank.blip_handle = AddBlip(bank)
              SetBlipColor(bank.blip_handle, bank.isClosed)
            end
          else
            if bank.blip_handle then
              RemoveBlip(bank.blip_handle)
              bank.blip_handle = nil
            end
          end
        else
          if bank.isClosed then
            if Config.BlipSettings.ShowClosed then
              if not bank.blip_handle then
                bank.blip_handle = AddBlip(bank)
              end
              SetBlipColor(bank.blip_handle, bank.isClosed)
            end
          else
            SetBlipColor(bank.blip_handle, bank.isClosed)
          end
        end
      else
        -- Should never run. Clean up just incase
        if bank.blip_handle then
          RemoveBlip(bank.blip_handle)
          bank.blip_handle = nil
        end
      end

      -- Handle NPCs
      if Config.NPCSettings.Show then
        if distance <= Config.NPCSettings.Distance then
          if not bank.npc then
            bank.npc = AddNPC(bank)
          end
        else
          if bank.npc then
            bank.npc:Remove()
            bank.npc = nil
          end
        end
      end

      -- Prompts
      if distance <= Config.PromptSettings.Distance then
        sleep = false
        if bank.isClosed then
          GetClosedPromptGroup():ShowGroup(bank.name .. '  ~o~: ~e~CLOSED')
        else
          GetOpenPromptGroup():ShowGroup(bank.name)
          if GetOpenPrompt():HasCompleted() then
            OpenUI(bank)
          end
        end
      end
    end
  end
end)

function CleanUp()
  DeletePrompts()
  ClearBlips()
  ClearNPCs()
  Banks = {}
  IsReady = false
end

AddEventHandler('onResourceStop', function(resourceName)
  if (GetCurrentResourceName() ~= resourceName) then
    return
  end

  CleanUp()
end)
