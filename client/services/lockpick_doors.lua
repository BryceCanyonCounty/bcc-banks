-- Bank door lockpicking integration using [OTHER]/lockpick
-- Uses Door System natives to unlock on minigame success

local lockpickCfg = Config.LockPicking or { Enabled = false }
if not lockpickCfg.Enabled then return end

-- BccUtils initialized in client/helpers/main.lua
local Prompts = BccUtils and BccUtils.Prompts

-- Positions for bank doors from bcc-doorlocks doorhashes.lua
-- Only includes doors referenced in Config.Doors
local BankDoorPositions = {
  -- Valentine
  [2642457609] = vector3(-309.05206298828, 779.73010253906, 117.7299118042),
  [3886827663] = vector3(-306.88534545898, 780.11541748047, 117.7299118042),
  [1340831050] = vector3(-311.74063110352, 774.67565917969, 117.7299118042),
  -- [576950805]  = vector3(-307.75375366211, 766.34899902344, 117.7015914917), -- vault door (commented)
  [3718620420] = vector3(-311.05978393555, 770.1240234375, 117.70217895508),
  [2343746133] = vector3(-301.93618774414, 771.751953125,   117.7299041748),
  [2307914732] = vector3(-301.51000976563, 762.98345947266, 117.7331237793),
  [334467483]  = vector3(-302.92282104492, 767.60430908203, 117.69805145264),

  -- Saint Denis
  [1733501235] = vector3(2638.7221679688, -1300.0184326172, 51.24600982666),
  [2158285782] = vector3(2637.7978515625, -1298.0363769531, 51.24600982666),
  [1634115439] = vector3(2646.9802246094, -1300.9831542969, 51.245384216309),
  [965922748]  = vector3(2648.98046875,   -1300.0491943359, 51.245391845703),
  [2817024187] = vector3(2642.1567382813, -1285.4188232422, 51.24600982666),
  [2089945615] = vector3(2640.1755371094, -1286.3425292969, 51.24600982666),
  -- [1751238140] = vector3(2643.3005371094, -1300.4267578125, 51.255825042725), -- vault door (commented)

  -- Blackwater
  [531022111]  = vector3(-809.14184570313, -1279.1900634766, 42.661499023438),
  [2817192481] = vector3(-817.81109619141, -1277.6684570313, 42.651943206787),
  [2117902999] = vector3(-816.72528076172, -1276.7509765625, 42.641235351563),
  -- [1462330364] = vector3(-817.78656005859, -1274.3852539063, 42.662132263184), -- vault door (commented)

  -- Rhodes
  [3317756151] = vector3(1296.2719726563, -1299.0120849609, 76.03963470459),
  [3088209306] = vector3(1294.595703125,  -1297.5837402344, 76.03963470459),
  [2058564250] = vector3(1285.1475830078, -1303.1185302734, 76.040069580078),
  [1634148892] = vector3(1295.7341308594, -1305.4748535156, 76.033004760742),
  -- [3483244267] = vector3(1282.5363769531, -1309.3159179688, 76.036422729492), -- vault door (commented)
  [3142122679] = vector3(1278.8559570313, -1310.4030761719, 76.039642333984),
}

local function ensureDoorRegistered(doorHash)
  if not IsDoorRegisteredWithSystem(doorHash) then
    -- _ADD_DOOR_TO_SYSTEM_NEW
    Citizen.InvokeNative(0xD99229FE93B46286, doorHash, true, true, false, 0, 0, false)
  end
end

local function tryLockpickDoor(doorHash)
  -- Optional item gate
  if lockpickCfg.RequireItem then
    local p = promise.new()
    local handler
    handler = AddEventHandler('feather-banks:lockpick:canStart:cb', function(can)
      if handler then RemoveEventHandler(handler) end
      handler = nil
      p:resolve(can and true or false)
    end)
    TriggerServerEvent('feather-banks:lockpick:canStart')
    local ok = Citizen.Await(p)
    if not ok then
      Notify('You need a lockpick', 'error', 2500)
      return
    end
  end

  local res = lockpickCfg.Resource or 'lockpick'
  if GetResourceState(res) ~= 'started' then
    if lockpickCfg.NotifyOnMissing then
      Notify(('Lockpick resource "%s" not started.'):format(res), 'error', 4000)
    end
    return
  end

  local attempts = tonumber(lockpickCfg.Attempts or 3) or 3
  local ok = false
  pcall(function()
    ok = exports[res]:startLockpick(attempts)
  end)

  if ok then
    DoorSystemSetDoorState(doorHash, 0) -- unlock
    DoorSystemSetOpenRatio(doorHash, 0.0, true)
    Notify('Lockpick succeeded', 'success', 3000)

    local relock = tonumber(lockpickCfg.RelockSeconds or 0) or 0
    if relock > 0 then
      SetTimeout(relock * 1000, function()
        DoorSystemSetDoorState(doorHash, 1) -- re-lock
      end)
    end
  else
    Notify('Lockpick failed', 'error', 2500)
    DoorSystemSetDoorState(doorHash, 1) -- ensure door stays locked so prompt appears again
    DoorSystemSetOpenRatio(doorHash, 0.0, true)
    -- signal server to handle durability / consume item
    TriggerServerEvent('feather-banks:lockpick:onFail')
  end
end

CreateThread(function()
  if not Prompts then return end

  local group = Prompts:SetupPromptGroup()
  local prompt = group:RegisterPrompt('Lockpick Door', lockpickCfg.PromptKey or 0xCEFD9220, 1, 1, true, 'hold', { timedeventhash = 'MEDIUM_TIMED_EVENT' })

  while true do
    Wait(5)
    local ped = PlayerPedId()
    local pC = GetEntityCoords(ped)
    local shown = false

    for doorHash, state in pairs(Config.Doors) do
      local pos = BankDoorPositions[doorHash]
      if pos then
        local dist = #(pC - pos)
        if dist <= (lockpickCfg.Radius or 1.6) then
          ensureDoorRegistered(doorHash)
          local doorState = DoorSystemGetDoorState(doorHash)
          if doorState ~= 0 then
            shown = true
            group:ShowGroup('Door')
            if prompt:HasCompleted() then
              tryLockpickDoor(doorHash)
            end
            break -- avoid overlapping prompts
          end
        end
      end
    end

    if not shown then
      Wait(250)
    end
  end
end)
