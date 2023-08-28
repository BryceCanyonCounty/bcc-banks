Feather.RPC.Register('Feather:Banks:GetAccountData', function(params, res, src)
  local character = Feather.Character.GetCharacterBySrc(src)
  local bank = tonumber(params.bank)
  res(GetUserAccountData(character.id, bank))
end)

Feather.RPC.Register('Feather:Banks:CreateAccount', function(params, res, src)
  local character = Feather.Character.GetCharacterBySrc(src)
  local name = params.name
  local bank = tonumber(params.bank)
  res(CreateAccount(name, character.id, bank))
end)

Feather.RPC.Register('Feather:Banks:AddAccountAccess', function(params, res, src)
  local character = Feather.Character.GetCharacterBySrc(src)
  local account = tonumber(params.account)
  local otherCharacter = tonumber(params.character)
  local level = tonumber(params.level)

  if not IsAccountOwner(account, character.id) then
    res(false)
  end

  AddAccountAccess(account, otherCharacter, level)

  res(true)
end)


-- Cache = Direct map of the database
-- Character.dollars = current dollar amount
-- Character Update Attribute
-- dollars & gold
