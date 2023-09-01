ServerReady = false

local function makeReady()
  -- Check if DB has been Setup
  local result = MySQL.query.await(
    "SELECT * FROM `INFORMATION_SCHEMA`.`TABLES` WHERE `TABLE_SCHEMA` = 'feather' AND `TABLE_NAME`='safety_deposit_boxes_access';")
  [1]
  if result == nil then
    LoadDatabase()
  end

  -- Register Custom Inventory
  FeatherInventory.Inventory.RegisterForeignKey('safety_deposit_boxes', 'BIGINT UNSIGNED', 'id')

  -- StartAPI()

  ServerReady = true
end

makeReady()

-- Clear locks on player drop
AddEventHandler('feather:character:logout', function(src)
  ClearBankerBusy(src)
  ClearAccountLocks(src)
end)
