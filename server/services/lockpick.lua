local function hasLockpickItem(src)
  if not Config.LockPicking or not Config.LockPicking.RequireItem then
    return true
  end
  local item = Config.LockPicking.ItemName or 'lockpick'
  local count = 0
  local ok = pcall(function()
    count = exports.vorp_inventory:getItemCount(src, nil, item, {}) or 0
  end)
  if not ok then return false end
  return (tonumber(count) or 0) > 0
end

local authorizedAttempts = {}

RegisterNetEvent('feather-banks:lockpick:canStart', function(doorHash)
  local src = source
  doorHash = tonumber(doorHash)
  local can = doorHash ~= nil
      and Config.LockPicking and Config.LockPicking.Enabled == true
      and Config.Doors[doorHash] ~= nil
      and IsPlayerNearBank(src, nil, 25.0, false)
      and hasLockpickItem(src)
  if can then
    authorizedAttempts[src] = {
      door = doorHash,
      earliest = GetGameTimer() + 1000,
      expires = GetGameTimer() + 120000,
    }
  else
    authorizedAttempts[src] = nil
  end
  TriggerClientEvent('feather-banks:lockpick:canStart:cb', src, can)
end)

RegisterNetEvent('feather-banks:lockpick:onSuccess', function(doorHash)
  local src = source
  doorHash = tonumber(doorHash)
  local attempt = authorizedAttempts[src]
  authorizedAttempts[src] = nil
  local now = GetGameTimer()
  if not attempt or attempt.door ~= doorHash or now < attempt.earliest or now > attempt.expires then return end
  if Config.Doors[doorHash] == nil or not IsPlayerNearBank(src, nil, 25.0, false) then return end
  if not hasLockpickItem(src) then return end

  TriggerClientEvent('feather-banks:lockpick:setDoorState', -1, doorHash, 0, src)
  local relock = tonumber(Config.LockPicking.RelockSeconds or 0) or 0
  if relock > 0 then
    SetTimeout(relock * 1000, function()
      TriggerClientEvent('feather-banks:lockpick:setDoorState', -1, doorHash, 1, 0)
    end)
  end
end)

AddEventHandler('playerDropped', function()
  authorizedAttempts[source] = nil
end)

-- Reduce lockpick durability or destroy on failure (mirrors MMS style)
RegisterNetEvent('feather-banks:lockpick:onFail', function()
  local src = source
  local cfg = Config.LockPicking or {}
  local itemName = (cfg and cfg.ItemName) or 'lockpick'
  local dur = (cfg and cfg.Durability) or {}

  if dur.Enabled then
    local ok, item = pcall(function()
      return exports.vorp_inventory:getItem(src, itemName)
    end)
    if not ok or not item or not item.id then
      return -- nothing to do
    end

    local maxD = tonumber(dur.Max or 100) or 100
    local damage = tonumber(dur.DamageOnFail or 10) or 10
    local current = (item.metadata and item.metadata.durability) or maxD
    local newVal = (tonumber(current) or maxD) - damage

    if newVal <= 0 then
      -- remove this specific item instance
      pcall(function()
        exports.vorp_inventory:subItemID(src, item.id)
      end)
    else
      local newMeta = {
        description = string.format('Durabilitate = %d%%', newVal),
        durability = newVal,
        id = item.id
      }
      pcall(function()
        exports.vorp_inventory:setItemMetadata(src, item.id, newMeta, 1)
      end)
    end
  elseif (dur.DestroyOnFailIfDisabled == true) then
    -- fallback remove one
    pcall(function()
      exports.vorp_inventory:subItem(src, itemName, 1)
    end)
  end
end)
