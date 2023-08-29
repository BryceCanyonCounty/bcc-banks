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

Boolean = {
  ["1"] = true,
  ["0"] = false,
  [1] = true,
  [0] = false,
  ["true"] = true,
  ["false"] = false,
  ["True"] = true,
  ["False"] = false
}
