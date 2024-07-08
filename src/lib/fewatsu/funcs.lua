function string.split(inputstr, sep)
  t = {}
  for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
    -- "([^"..sep.."]+)"
    table.insert(t, str)
  end

  return t
end
