-- Clear locks on player drop
AddEventHandler('feather:character:logout', function(src)
  ClearBankerBusy(src)
  ClearAccountLocks(src)
end)

-- Backfill SDB inventories for rows created before VORP integration
CreateThread(function()
  Wait(2000)
  local rows = MySQL.query.await('SELECT id, size FROM `bcc_safety_deposit_boxes` WHERE `inventory_id` IS NULL') or {}
  if #rows == 0 then return end

  for _, row in ipairs(rows) do
    local sizeKey = tostring(row.size)
    local sizes = Config and Config.SafetyDepositBoxes and Config.SafetyDepositBoxes.Sizes or {}
    local sz = sizes[sizeKey]
    if sz then
      local invId = 'sdb_' .. tostring(row.id)
      local invName = 'SDB #' .. tostring(row.id)
      local invData = {
        id = invId,
        name = invName,
        limit = 100,
        acceptWeapons = true,
        shared = true,
        ignoreItemStackLimit = (sz.IgnoreItemLimit == true),
        whitelistItems = false,
        UsePermissions = false,
        UseBlackList = (sz.BlacklistItems and #sz.BlacklistItems or 0) > 0,
        whitelistWeapons = false,
        useWeight = true,
        weight = sz.MaxWeight or 0.0,
      }

      exports.vorp_inventory:registerInventory(invData)

      if sz.BlacklistItems and #sz.BlacklistItems > 0 then
        for _, itemName in ipairs(sz.BlacklistItems) do
          exports.vorp_inventory:BlackListCustomAny(invId, itemName)
        end
      end

      MySQL.query.await('UPDATE `bcc_safety_deposit_boxes` SET `inventory_id`=? WHERE `id`=?', { invId, row.id })
    end
  end
end)

BccUtils.Versioner.checkFile(GetCurrentResourceName(), "https://github.com/BryceCanyonCounty/bcc-banks")
