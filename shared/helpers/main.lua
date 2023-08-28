function Len(table)
  if type(table) ~= 'table' then
    return 0
  end

  local count = 0
  for _, v in pairs(table) do
    count = count + 1
  end

  return count
end
