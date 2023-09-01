Feather.RPC.Register('Feather:Banks:GetTransactions', function(params, res, src)
  local account = tonumber(params.account)

  res(GetAccountTransactions(account))
  return
end)
