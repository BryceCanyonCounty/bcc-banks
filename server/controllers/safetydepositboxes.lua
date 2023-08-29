function GetSDBCount(owner, bank)
  local result = MySQL.query.await(
    'SELECT COUNT(*) FROM `safety_deposit_boxes` WHERE `owner_id`=? AND `bank_id`=?',
    { owner, bank }
  )[1]

  return result["COUNT(*)"]
end

function CreateSDB(name, owner, bank, size)
  local currentBoxes = GetSDBCount(owner, bank)

  if Config.SafetyDepositBoxes.MaxBoxes ~= 0 and (currentBoxes >= Config.SafetyDepositBoxes.MaxBoxes) then
    return false
  end

  local box = MySQL.query.await(
    'INSERT INTO `safety_deposit_boxes` (`name`, `bank_id`, `owner_id`, `size`) VALUES (?,?,?,?) RETURNING *;',
    { name, bank, owner, size })[1]


  if box == nil then
    return false
  end

  -- Get Box Settings
  local maxWeight = Config.SafetyDepositBoxes.Sizes[size].MaxWeight
  local restrictedItems = nil
  if Len(Config.SafetyDepositBoxes.Sizes[size].BlacklistItems) > 0 then
    restrictedItems = Config.SafetyDepositBoxes.Sizes[size].BlacklistItems
  end
  local ignoreItemLimits = Config.SafetyDepositBoxes.Sizes[size].IgnoreItemLimit

  -- Register a Custom Inventory
  local inventoryId = FeatherInventory.RegisterInventory('safety_deposit_boxes', box["id"], maxWeight, restrictedItems,
    ignoreItemLimits)

  -- Save the Inventory ID in the Safety Deposit Box
  MySQL.query.await('UPDATE `safety_deposit_boxes` SET `inventory_id`=? WHERE `id`=?', { inventoryId, box["id"] })

  -- Give owner access to Safety Deposit Box
  MySQL.query.await(
    'INSERT INTO `safety_deposit_boxes_access` (`safety_deposit_box_id`, `character_id`, `level`) VALUES (?,?,?)',
    { box["id"], owner, Config.AccessLevels.Admin })

  return box
end

function GetUserSDBData(character, bank)
  local accounts = MySQL.query.await(
    'SELECT `safety_deposit_boxes`.`id`, `safety_deposit_boxes`.`name`, `safety_deposit_boxes`.`owner_id`, `safety_deposit_boxes`.`inventory_id`, `safety_deposit_boxes_access`.`level` FROM `safety_deposit_boxes` INNER JOIN `safety_deposit_boxes_access` ON `safety_deposit_boxes`.`id` = `safety_deposit_boxes_access`.`safety_deposit_box_id` INNER JOIN `banks` on `banks`.`id` = `safety_deposit_boxes`.`bank_id` WHERE `safety_deposit_boxes_access`.`character_id` = ? AND `banks`.`id` = ?;',
    { character, bank })

  return accounts
end

function AddSDBAccess(account, character, level)
  MySQL.await.query(
    'INSERT INTO `safety_deposit_boxes_access` (`safety_deposit_box_id`, `character_id`, `level`) VALUES (?,?,?);',
    { account, character, level })

  return true
end

function IsSDBOwner(account, character)
  local owner = MySQL.query.await('SELECT `owner_id` FROM `accounts` WHERE `safety_deposit_box_id`=? LIMIT 1;',
    { account })[1]

  if owner == nil then
    return false
  end

  return owner == character
end

function IsSDBAdmin(account, character)
  local record = MySQL.query.await(
    'SELECT `level` FROM `safety_deposit_boxes_access` WHERE `safety_deposit_box_id`=? and `character_id`=? LIMIT 1;',
    { account, character })[1]

  if record == nil then
    return false
  end

  return record == 1
end

function HasSDBAccess(account, character)
  local record = MySQL.query.await(
    'SELECT `level` FROM `safety_deposit_boxes_access` WHERE `safety_deposit_box_id`=? and `character_id`=? LIMIT 1;',
    { account, character })[1]

  if record == nil then
    return false
  end

  return true
end

function GetSDBAccess(account, character)
  local record = MySQL.query.await(
    'SELECT `level` FROM `safety_deposit_boxes_access` WHERE `safety_deposit_box_id`=? and `character_id`=? LIMIT 1;',
    { account, character })[1]

  if record == nil then
    return false
  end

  return record
end
