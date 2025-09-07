local IsReady = false
Banks = {}

-- DEBUG COMMAND - Needed until CharacterSpawned Event is created
RegisterCommand('banksReady', function(args, src, rawCommand)
    devPrint("DEBUG: Registering command 'banksReady'.")
    Banks = BccUtils.RPC:CallAsync('Feather:Banks:GetBanks', nil)
    if Len(Banks) <= 0 then
        error('Unable to retrieve banks!')
        return
    end

    IsReady = true
    TriggerEvent('Feather:Banks:Start')
    devPrint("DEBUG: Banks are ready and Feather:Banks:Start triggered.")
end, false)

-- DEBUG INIT - Needed until CharacterSpawned Event is created
CreateThread(function()
    Wait(2000) -- small delay to let feather-core + RPC init

    devPrint("DEBUG: Initializing banks (auto instead of command).")

    Banks = BccUtils.RPC:CallAsync('Feather:Banks:GetBanks', nil)
    if not Banks or Len(Banks) <= 0 then
        error('Unable to retrieve banks!')
        return
    end

    IsReady = true
    TriggerEvent('Feather:Banks:Start')
    devPrint("DEBUG: Banks are ready and Feather:Banks:Start triggered.")
end)

FeatherMenu = exports['feather-menu'].initiate()
FeatherBankMenu = FeatherMenu:RegisterMenu('feather:bank:menu', {
    top = '3%',
    left = '3%',
    ['720width'] = '400px',
    ['1080width'] = '500px',
    ['2kwidth'] = '600px',
    ['4kwidth'] = '800px',
    style = {},
    contentslot = {
        style = {
            ['height'] = '450px',
            ['min-height'] = '350px'
        }
    },
    draggable = true,
    canclose = true
}, {
    opened = function()
        --DisplayRadar(false)
    end,
    closed = function()
        --DisplayRadar(true)
    end
})

RegisterNetEvent('Feather:Banks:Start', function()
    devPrint("DEBUG: Feather:Banks:Start event triggered.")
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
                devPrint("DEBUG: Current hour:", hour)

                if hour >= bank.close_hour or hour < bank.open_hour then
                    bank.isClosed = true
                    devPrint("DEBUG: Bank", bank.name, "is CLOSED.")
                else
                    if bank.isClosed then
                        bank.isClosed = false
                        if bank.blip_handle then
                            SetBlipColor(bank.blip_handle, bank.isClosed)
                        end
                        devPrint("DEBUG: Bank", bank.name, "is OPEN now.")
                    end
                end
            end

            -- Handle Closed Cleanup
            if bank.isClosed then
                if bank.blip_handle then
                    if Config.BlipSettings.Show and Config.BlipSettings.ShowClosed then
                        SetBlipColor(bank.blip_handle, bank.isClosed)
                        devPrint("DEBUG: Showing closed blip for", bank.name)
                    else
                        bank.blip_handle.Remove()
                        bank.blip_handle = nil
                        devPrint("DEBUG: Removed closed blip for", bank.name)
                    end
                end

                if bank.npc then
                    bank.npc:Remove()
                    bank.npc = nil
                    devPrint("DEBUG: Removed NPC for closed bank", bank.name)
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
                            devPrint("DEBUG: Removed blip for bank", bank.name)
                        end
                    end
                else
                    if bank.isClosed then
                        if Config.BlipSettings.ShowClosed then
                            if not bank.blip_handle then
                                bank.blip_handle = AddBlip(bank)
                            end
                        end
                    else
                        SetBlipColor(bank.blip_handle, bank.isClosed)
                    end
                end
            else
                if bank.blip_handle then
                    RemoveBlip(bank.blip_handle)
                    bank.blip_handle = nil
                    devPrint("DEBUG: Removed blip for bank", bank.name, "due to Config.BlipSettings.Show being false.")
                end
            end

            -- Handle NPCs
            if Config.NPCSettings.Show then
                if distance <= Config.NPCSettings.Distance then
                    if not bank.npc then
                        bank.npc = AddNPC(bank)
                        --print("DEBUG: Added NPC for bank " .. bank.name)
                    end
                else
                    if bank.npc then
                        bank.npc:Remove()
                        bank.npc = nil
                        --print("DEBUG: Removed NPC for bank " .. bank.name)
                    end
                end
            end

            -- Prompts
            if distance <= Config.PromptSettings.Distance then
                sleep = false
                if bank.isClosed then
                    GetClosedPromptGroup():ShowGroup(bank.name .. '  ~o~: ~e~CLOSED')
                    devPrint("DEBUG: Showing closed prompt for bank", bank.name)
                else
                    GetOpenPromptGroup():ShowGroup(bank.name)
                    if GetOpenPrompt():HasCompleted() then
                        OpenUI(bank)
                        devPrint("DEBUG: Prompt completed, opening UI for bank", bank.name)
                    end
                end
            end
        end

        -- Handle sleep (only sleep if nothing is being processed)
        if sleep then
            Wait(1000) -- Adjust the sleep time to avoid unnecessary processing
        end
    end
end)

function CleanUp()
	devPrint("DEBUG: Cleaning up resources.")
	DeletePrompts()
	ClearBlips()
	ClearNPCs()
	FeatherBankMenu:Close()
	Banks = {}
	IsReady = false
end

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end

    devPrint("DEBUG: Resource", resourceName, "stopped. Cleaning up.")
    CleanUp()
end)
