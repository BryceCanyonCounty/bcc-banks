function GetBanks()
  local banks = MySQL.query.await('SELECT * FROM `banks`;')
  return banks
end
