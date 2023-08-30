Feather.RPC.Register('Feather:Banks:GetBanks', function(params, res, src)
  res(GetBanks())
end)

Feather.RPC.Register('Feather:Banks:CreateBank', function(params, res, src)
  -- TODO Implmenet a method to create a bank at your current location.
  res(true)
end)

Feather.RPC.Register('Feather:Banks:GetBankerBusy', function(params, res, src)
  local bank = params.bank
  res(IsBankerBusy(bank, src))
end)

Feather.RPC.Register('Feather:Banks:SetBankerBusy', function(params, res, src)
  local bank = params.bank
  local state = params.state

  if state then
    SetBankerBusy(bank, src)
  else
    ClearBankerBusy(src)
  end
end)
