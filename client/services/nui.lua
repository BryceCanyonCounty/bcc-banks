local State = false
function OpenUI(bank)
  -- Is Banker Busy?
  if not Feather.RPC.CallAsync('Feather:Banks:GetBankerBusy', { bank = bank }) then
    -- Open UI
    SendNUIMessage({
      type = 'toggle',
      visible = true,
      bank = bank, -- Complete DB Table for bank
      accounts = Feather.RPC.CallAsync('Feather:Banks:GetAccounts', { bank = bank.id })
    })

    -- Notify Server banker is now busy
    Feather.RPC.Notify('Feather:Banks:SetBankerBusy', { bank = bank.id })
  else
    -- Notify player he's gotta wait in line
  end
end

RegisterNUICallback('Feather:Banks:UpdateState', function(args, cb)
  State = args.state
  SetNuiFocus(State, State)
  cb('ok')

  if not State then
    Feather.RPC.Notify('Feather:Banks:SetBankerBusy')
  end
end)

RegisterNUICallback('Feather:Banks:CreateAccount', function(args, cb)
  local data = {
    name = args.name,
    bank = args.bank,
  }

  cb(Feather.RPC.CallAsync('Feather:Banks:CreateAccount', data))
end)

RegisterNUICallback('Feather:Banks:CloseAccount', function(args, cb)
  local data = {
    bank = args.bank,
    account = args.account,
  }

  cb(Feather.RPC.CallAsync('Feather:Banks:CloseAccount', data))
end)

RegisterNUICallback('Feather:Banks:GetAccount', function(args, cb)
  local data = {
    account = args.account,
    lockAccount = args.lockAccount,
  }

  cb(Feather.RPC.CallAsync('Feather:Banks:GetAccount', data))
end)

RegisterNUICallback('Feather:Banks:UnlockAccount', function(args, cb)
  cb('ok')

  local data = {
    account = args.account,
  }

  Feather.RPC.Notify('Feather:Banks:UnlockAccount', data)
end)

RegisterNUICallback('Feather:Banks:AddAccess', function(args, cb)
  local data = {
    account = args.account,
    user = args.user,
    level = args.level,
  }

  cb(Feather.RPC.CallAsync('Feather:Banks:AddAccountAccess', data))
end)

RegisterNUICallback('Feather:Banks:Deposit', function(args, cb)
  local type = args.type
  local data = {
    account = args.account,
    amount = args.amount,
    description = args.description,
  }

  if type == 'cash' then
    cb(Feather.RPC.CallAsync('Feather:Banks:DepositCash', data))
  elseif type == 'gold' then
    cb(Feather.RPC.CallAsync('Feather:Banks:DepositGold', data))
  end
end)

RegisterNUICallback('Feather:Banks:Withdraw', function(args, cb)
  local type = args.type
  local data = {
    account = args.account,
    amount = args.amount,
    description = args.description,
  }

  if type == 'cash' then
    cb(Feather.RPC.CallAsync('Feather:Banks:WithdrawCash', data))
  elseif type == 'gold' then
    cb(Feather.RPC.CallAsync('Feather:Banks:WithdrawGold', data))
  end
end)

RegisterNUICallback('Feather:Banks:Notify', function(args, cb)
  Feather.Notify.RightNotify(args.message, 4000)
  cb('ok')
end)
