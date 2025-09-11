local IsReady = false
Banks = {}

local IsReady = false
Banks = {}

RegisterCommand('banksReady', function(src, args, rawCommand)  -- correct param order
    devPrint("DEBUG: Registering command 'banksReady'.")
    local ok; ok, Banks = BccUtils.RPC:CallAsync('Feather:Banks:GetBanks', {})
    if not ok or not Banks or #Banks <= 0 then
        error('Unable to retrieve banks!')
        return
    end

    IsReady = true
    TriggerEvent('Feather:Banks:Start')
    devPrint("DEBUG: Banks are ready and Feather:Banks:Start triggered.")
end, false)

CreateThread(function()
    Wait(2000)
    devPrint("DEBUG: Initializing banks (auto instead of command).")

    local ok; ok, Banks = BccUtils.RPC:CallAsync('Feather:Banks:GetBanks', {})
    if not ok or not Banks or #Banks <= 0 then
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
            -- Handle Open/Close Banks (respect hours_active boolean from DB)
            local hoursActive = (bank.hours_active == 1 or bank.hours_active == true or bank.hours_active == '1')
            if hoursActive and bank.open_hour and bank.close_hour then
                local hour = GetClockHours()
                devPrint("DEBUG: Current hour:", hour)

                if hour >= bank.close_hour or hour < bank.open_hour then
                    bank.isClosed = true
                    devPrint("DEBUG: Bank", bank.name, "is CLOSED (by hours).")
                else
                    if bank.isClosed then
                        bank.isClosed = false
                        if bank.blip_handle then
                            SetBlipColor(bank.blip_handle, bank.isClosed)
                        end
                        devPrint("DEBUG: Bank", bank.name, "is OPEN now (by hours).")
                    end
                end
            else
                -- If hours are not active, ensure bank is considered open
                if bank.isClosed then
                    bank.isClosed = false
                    if bank.blip_handle then
                        SetBlipColor(bank.blip_handle, bank.isClosed)
                    end
                    devPrint("DEBUG: Bank", bank.name, "hours inactive; forcing OPEN.")
                end
            end

            -- Handle Closed Cleanup
            if bank.isClosed then
                if bank.blip_handle then
                    if Config.BlipSettings.Show and Config.BlipSettings.ShowClosed then
                        SetBlipColor(bank.blip_handle, bank.isClosed)
                        devPrint("DEBUG: Showing closed blip for", bank.name)
                    else
                        RemoveBlip(bank.blip_handle)
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

            -- Handle NPCs (do not spawn when bank is closed)
            if Config.NPCSettings.Show then
                if bank.isClosed then
                    if bank.npc then
                        bank.npc:Remove()
                        bank.npc = nil
                        devPrint("DEBUG: Ensured NPC removed for closed bank", bank.name)
                    end
                else
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
            end

            -- Prompts
            if distance <= Config.PromptSettings.Distance then
                sleep = false
                if bank.isClosed then
                    -- Disable open prompt and show a closed message with opening hours like stables/guarma
                    if GetOpenPrompt() then GetOpenPrompt():EnabledPrompt(false) end
                    local openTxt = tostring(bank.open_hour or '')
                    local closeTxt = tostring(bank.close_hour or '')
                    local label = ( _U('bank_label') or 'Bank') .. (_U('hours') or ' is open from ~o~') .. openTxt .. (_U('to') or ':00~q~ to ~o~') .. closeTxt .. (_U('hundred') or ':00')
                    GetClosedPromptGroup():ShowGroup(label)
                    devPrint("DEBUG: Showing closed prompt for bank", bank.name, 'hours', openTxt, closeTxt)
                else
                    -- Re-enable open prompt when bank is open
                    if GetOpenPrompt() then GetOpenPrompt():EnabledPrompt(true) end
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

-- Server-triggered refresh after admin changes (hours etc.)
RegisterNetEvent('Feather:Banks:Refresh', function()
    devPrint("DEBUG: Refresh event received; reloading banks.")
    local ok; ok, Banks = BccUtils.RPC:CallAsync('Feather:Banks:GetBanks', {})
    if not ok or not Banks then
        devPrint("DEBUG: Refresh failed to load banks.")
        return
    end
end)
