Feather.RPC.Register('Feather:Banks:GetAccounts', function(params, res, src)
  local character = Feather.Character.GetCharacterBySrc(src)
  local bank = tonumber(params.bank)
  res(GetAccounts(character.id, bank))
  return
end)

Feather.RPC.Register('Feather:Banks:CreateAccount', function(params, res, src)
  local character = Feather.Character.GetCharacterBySrc(src)
  local name = params.name
  local bank = tonumber(params.bank)

  res(CreateAccount(name, character.id, bank))
  return
end)

Feather.RPC.Register('Feather:Banks:CloseAccount', function(params, res, src)
  local character = Feather.Character.GetCharacterBySrc(src)
  local bank = params.bank
  local account = params.account
  res(CloseAccount(bank, account, character.id))
end)

Feather.RPC.Register('Feather:Banks:GetAccount', function(params, res, src)
  local character = Feather.Character.GetCharacterBySrc(src)
  local account = tostring(params.account)
  local lockAccount = params.lockAccount

  if not HasAccountAccess(account, character.id) then
    res({ status = false, message = 'Insufficient Access' })
    return
  end
  if IsAccountLocked(account, src) and not IsActiveUser(account, src) then
    res({ status = false, message = 'Account is locked.' })
    return
  end
  if lockAccount then
    SetLockedAccount(account, src, true)
  end

  res({ account = GetAccount(account), transactions = GetAccountTransactions(account) })
end)

Feather.RPC.Register('Feather:Banks:UnlockAccount', function(params, res, src)
  local account = tostring(params.account)
  if not IsActiveUser(account, src) then
    return
  end

  SetLockedAccount(account, src, false)
end)

Feather.RPC.Register('Feather:Banks:AddAccountAccess', function(params, res, src)
  local character = Feather.Character.GetCharacterBySrc(src)
  local account = tonumber(params.account)
  local otherSrc = tonumber(params.user)
  local otherCharacter = Feather.Character.GetCharacterBySrc(otherSrc).id
  local level = tonumber(params.level)

  if not IsAccountOwner(account, character.id) and not IsAccountAdmin(account, character.id) then
    res({ status = false, message = 'Insufficient Access' })
    return
  end

  AddAccountAccess(account, otherCharacter, level)

  res({ status = true, message = 'Added User' })
  return
end)

Feather.RPC.Register('Feather:Banks:DepositCash', function(params, res, src)
  local character = Feather.Character.GetCharacterBySrc(src)
  local account = tonumber(params.account)
  local amount = tonumber(params.amount)
  local description = params.description

  if GetAccountAccess(account, character.id) > Config.AccessLevels.Deposit then
    res({ status = false, message = 'Insufficient Access' })
    return
  end

  if character.dollars - amount < 0 then
    res({ status = false, message = 'Insufficient Funds' })
    return
  end

  if not DepositCash(account, amount) then
    res({ status = false, message = 'Unable to Deposit' })
    return
  end

  Feather.Character.UpdateAttribute(src, 'dollars', character.dollars - amount)
  AddAccountTransaction(account, character.id, amount, 'deposit - cash', description)

  res({ account = GetAccount(account), transactions = GetAccountTransactions(account) })
  return
end)

Feather.RPC.Register('Feather:Banks:DepositGold', function(params, res, src)
  local character = Feather.Character.GetCharacterBySrc(src)
  local account = tonumber(params.account)
  local amount = tonumber(params.amount)
  local description = params.description

  if GetAccountAccess(account, character.id) > Config.AccessLevels.Deposit then
    res({ status = false, message = 'Insufficient Access' })
    return
  end

  if character.gold - amount < 0 then
    res({ status = false, message = 'Insufficient Funds' })
    return
  end

  if not DepositGold(account, amount) then
    res({ status = false, message = 'Unable to Deposit' })
    return
  end

  Feather.Character.UpdateAttribute(src, 'gold', character.gold - amount)
  AddAccountTransaction(account, character.id, amount, 'deposit - gold', description)

  res({ account = GetAccount(account), transactions = GetAccountTransactions(account) })
  return
end)

Feather.RPC.Register('Feather:Banks:WithdrawCash', function(params, res, src)
  local character = Feather.Character.GetCharacterBySrc(src)
  local account = tonumber(params.account)
  local amount = tonumber(params.amount)
  local description = params.description

  if GetAccountAccess(account, character.id) > Config.AccessLevels.Withdraw_Deposit then
    res({ status = false, message = 'Insufficient Access' })
    return
  end

  if not WithdrawCash(account, amount) then
    res({ status = false, message = 'Insufficient Funds' })
    return
  end


  Feather.Character.UpdateAttribute(src, 'dollars', character.dollars + amount)
  AddAccountTransaction(account, character.id, amount, 'withdraw - cash', description)


  res({ account = GetAccount(account), transactions = GetAccountTransactions(account) })
  return
end)

Feather.RPC.Register('Feather:Banks:WithdrawGold', function(params, res, src)
  local character = Feather.Character.GetCharacterBySrc(src)
  local account = tonumber(params.account)
  local amount = tonumber(params.amount)
  local description = params.description

  if GetAccountAccess(account, character.id) > Config.AccessLevels.Withdraw_Deposit then
    res({ status = false, message = 'Insufficient Access' })
    return
  end

  if not WithdrawGold(account, amount) then
    res({ status = false, message = 'Insufficient Funds' })
    return
  end

  Feather.Character.UpdateAttribute(src, 'gold', character.gold + amount)
  AddAccountTransaction(account, character.id, amount, 'withdraw - gold', description)

  res({ account = GetAccount(account), transactions = GetAccountTransactions(account) })
  return
end)


-- Cache = Direct map of the database
-- Character.dollars = current dollar amount
-- Character Update Attribute
-- dollars & gold
