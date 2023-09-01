local LockedAccounts = {}

function GetAccountCount(owner, bank)
  local result = MySQL.query.await(
    'SELECT COUNT(*) FROM `accounts` WHERE `owner_id`=? AND `bank_id`=?',
    { owner, bank }
  )[1]

  return result["COUNT(*)"]
end

function CreateAccount(name, owner, bank)
  local currentAccounts = GetAccountCount(owner, bank)


  if Config.Accounts.MaxAccounts ~= 0 and (currentAccounts >= Config.Accounts.MaxAccounts) then
    return false
  end


  local account = MySQL.query.await('INSERT INTO `accounts` (name, bank_id, owner_id) VALUES (?,?,?) RETURNING *;',
    { name, bank, owner })[1]

  if account ~= nil then
    MySQL.query.await('INSERT INTO `accounts_access` (`account_id`, `character_id`, `level`) VALUES (?,?,?)',
      { account["id"], owner, Config.AccessLevels.Admin })
  end

  return GetAccounts(owner, bank)
end

function CloseAccount(bank, account, character)
  local accountDetails = GetAccount(account)
  if accountDetails == nil then
    return { status = false, message = 'This account does not exist.' }
  end

  if accountDetails.gold > 0 or accountDetails.cash > 0 then
    return { status = false, message = 'You must withdraw all cash and gold before closing this account.' }
  end

  if not IsAccountAdmin(account, character) then
    return { status = false, message = 'You don\'t have permission to close this account.' }
  end

  MySQL.query.await('DELETE FROM `accounts` WHERE `id`=?', { account })
  return { status = true, accounts = GetAccounts(character, bank) }
end

function GetAccounts(character, bank)
  local accounts = MySQL.query.await(
    "SELECT `accounts`.`id`, `accounts`.`name` as 'account_name', CONCAT(`characters`.`first_name`, ' ', `characters`.`last_name`) as 'owner_name', `accounts_access`.`level` FROM `accounts` INNER JOIN `accounts_access` ON `accounts`.`id`=`accounts_access`.`account_id` INNER JOIN `banks`on`banks`.`id`=`accounts`.`bank_id` INNER JOIN `characters` ON `characters`.`id` = `accounts`.`owner_id` WHERE `accounts_access`.`character_id`= ? AND `banks`.`id`= ?;",
    { character, bank })

  return accounts
end

function GetAccount(account)
  return MySQL.query.await('SELECT * FROM `accounts` WHERE `id`=?', { account })[1]
end

function AddAccountAccess(account, character, level)
  MySQL.query.await('INSERT INTO `accounts_access` (`account_id`, `character_id`, `level`) VALUES (?,?,?);',
    { account, character, level })

  return true
end

function IsAccountOwner(account, character)
  local owner = MySQL.query.await('SELECT `owner_id` FROM `accounts` WHERE `id`=? LIMIT 1;', { account })[1]

  if owner == nil then
    return false
  end

  return owner == character
end

function IsAccountAdmin(account, character)
  local record = MySQL.query.await(
    'SELECT `level` FROM `accounts_access` WHERE `account_id`=? and `character_id`=? LIMIT 1;',
    { account, character })[1]['level']

  if record == nil then
    return false
  end

  return record == 1
end

function HasAccountAccess(account, character)
  local record = MySQL.query.await(
    'SELECT `level` FROM `accounts_access` WHERE `account_id`=? and `character_id`=? LIMIT 1;',
    { account, character })[1]

  if record == nil then
    return false
  end

  return true
end

function GetAccountAccess(account, character)
  local record = MySQL.query.await(
    'SELECT `level` FROM `accounts_access` WHERE `account_id`=? and `character_id`=? LIMIT 1;',
    { account, character })[1]

  if record == nil then
    return false
  end

  return record
end

function DepositCash(account, amount)
  local cash = MySQL.query.await('SELECT `cash` FROM `accounts` WHERE `id`=? LIMIT 1;', { account })[1]

  if cash == nil then
    return false
  end

  local newAmount = cash + amount
  MySQL.query.await('UPDATE `accounts` SET `cash`=? WHERE `id`=?', { newAmount, account })
  return true
end

function DepositGold(account, amount)
  local gold = MySQL.query.await('SELECT `gold` FROM `accounts` WHERE `id`=? LIMIT 1;', { account })[1]

  if gold == nil then
    return false
  end

  local newAmount = gold + amount
  MySQL.query.await('UPDATE `accounts` SET `gold`=? WHERE `id`=?', { newAmount, account })
  return true
end

function WithdrawCash(account, amount)
  local cash = MySQL.query.await('SELECT `cash` FROM `accounts` WHERE `id`=? LIMIT 1;', { account })[1]

  if cash == nil then
    return false
  end

  local newAmount = cash - amount

  if newAmount < 0 then
    return false
  end

  MySQL.query.await('UPDATE `accounts` SET `cash`=? WHERE `id`=?', { newAmount, account })
  return true
end

function WithdrawGold(account, amount)
  local gold = MySQL.query.await('SELECT `gold` FROM `accounts` WHERE `id`=? LIMIT 1;', { account })[1]

  if gold == nil then
    return false
  end

  local newAmount = gold - amount

  if newAmount < 0 then
    return false
  end

  MySQL.query.await('UPDATE `accounts` SET `gold`=? WHERE `id`=?', { newAmount, account })
  return true
end

function IsAccountLocked(account, src)
  return LockedAccounts[account] ~= nil
end

function IsActiveUser(account, src)
  return LockedAccounts[account] == src
end

function SetLockedAccount(account, src, state)
  if state then
    LockedAccounts[account] = src
  else
    LockedAccounts[account] = nil
  end
end

function ClearAccountLocks(src)
  for k, v in pairs(LockedAccounts) do
    if v == src then
      LockedAccounts[k] = nil
      return
    end
  end
end
