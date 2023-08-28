Feather.RPC.Register('Banks:GetBanks', function(params, res, src)
  res(GetBanks())
end)

Feather.RPC.Register('Banks:CreateBank', function(params, res, src)
  -- TODO: Implmenet a method to create a bank at your current location.
  res(true)
end)
