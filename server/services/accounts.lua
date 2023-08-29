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

Feather.RPC.Register('Feather:Banks:DeleteAccount', function(params, res, src)
  local character = Feather.Character.GetCharacterBySrc(src)
  local account = params.account
  res(DeleteAccount(account, character.id))
end)

Feather.RPC.Register('Feather:Banks:AddAccountAccess', function(params, res, src)
  local character = Feather.Character.GetCharacterBySrc(src)
  local account = tonumber(params.account)
  local otherSrc = tonumber(params.user)
  local otherCharacter = Feather.Character.GetCharacterBySrc(otherSrc).id
  local level = tonumber(params.level)

  if not IsAccountOwner(account, character.id) and not IsAccountAdmin(account, character.id) then
    res(false)
    return
  end

  AddAccountAccess(account, otherCharacter, level)

  res(true)
  return
end)

Feather.RPC.Register('Feather:Banks:DepositCash', function(params, res, src)
  local character = Feather.Character.GetCharacterBySrc(src)
  local account = tonumber(params.account)
  local amount = tonumber(params.amount)

  if GetAccountAccess(account, character.id) > Config.AccessLevels.Deposit then
    res(false)
    return
  end

  if character.dollars - amount < 0 then
    res(false)
    return
  end

  if not DepositCash(account, amount) then
    res(false)
    return
  end

  Feather.Character.UpdateAttribute(src, 'dollars', character.dollars - amount)

  res(GetAccount(account))
  return
end)

Feather.RPC.Register('Feather:Banks:DepositGold', function(params, res, src)
  local character = Feather.Character.GetCharacterBySrc(src)
  local account = tonumber(params.account)
  local amount = tonumber(params.amount)

  if GetAccountAccess(account, character.id) > Config.AccessLevels.Deposit then
    res(false)
    return
  end

  if character.gold - amount < 0 then
    res(false)
    return
  end

  if not DepositGold(account, amount) then
    res(false)
    return
  end

  Feather.Character.UpdateAttribute(src, 'gold', character.gold - amount)

  res(GetAccount(account))
  return
end)

Feather.RPC.Register('Feather:Banks:WithdrawCash', function(params, res, src)
  local character = Feather.Character.GetCharacterBySrc(src)
  local account = tonumber(params.account)
  local amount = tonumber(params.amount)

  if GetAccountAccess(account, character.id) > Config.AccessLevels.Withdraw_Deposit then
    res(false)
    return
  end

  if not WithdrawCash(account, amount) then
    res(false)
    return
  end

  Feather.Character.UpdateAttribute(src, 'dollars', character.dollars + amount)

  res(GetAccount(account))
  return
end)

Feather.RPC.Register('Feather:Banks:WithdrawGold', function(params, res, src)
  local character = Feather.Character.GetCharacterBySrc(src)
  local account = tonumber(params.account)
  local amount = tonumber(params.amount)

  if GetAccountAccess(account, character.id) > Config.AccessLevels.Withdraw_Deposit then
    res(false)
    return
  end

  if not WithdrawGold(account, amount) then
    res(false)
    return
  end

  Feather.Character.UpdateAttribute(src, 'gold', character.gold + amount)

  res(GetAccount(account))
  return
end)


-- Cache = Direct map of the database
-- Character.dollars = current dollar amount
-- Character Update Attribute
-- dollars & gold
