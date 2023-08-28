Feather = exports['feather-core'].initiate()


RegisterCommand('createAccount', function(source, args, rawCommand)
  local data = {
    name = args[1],
    bank = args[2]
  }

  local result = Feather.RPC.CallAsync('Feather:Banks:CreateAccount', data)

  Feather.Print(result)
end, false)


RegisterCommand('getAccountData', function(source, args, rawCommand)
  local data = {
    bank = args[1]
  }

  local result = Feather.RPC.CallAsync('Feather:Banks:GetAccountData', data)

  Feather.Print(result)
end, false)


RegisterCommand('addAccess', function(source, args, rawCommand)
  local data = {
    account = args[1],
    character = 2,
    level = args[3]
  }
  local result = Feather.RPC.CallAsync('Feather:Banks:AddAccountAccess', data)

  Feather.Print(result)
end, false)
