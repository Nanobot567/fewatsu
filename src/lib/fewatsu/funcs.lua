function string.split(inputstr, sep)
  t = {}
  for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
    -- "([^"..sep.."]+)"
    table.insert(t, str)
  end

  return t
end

-- return number in table closest to target
function math.closest(t, target)
  local closest = 0

  for i, v in pairs(t) do
    if math.abs(v - target) < closest then
      closest = v
    end
  end

  return closest
end

function math.round(num, numDecimalPlaces)
  local mult = 10 ^ (numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

local textReplacementTable = {
  ["%[%[a%]%]"] = "Ⓐ",
  ["%[%[b%]%]"] = "Ⓑ",
  ["%[%[left%]%]"] = "⬅️",
  ["%[%[right%]%]"] = "➡️",
  ["%[%[up%]%]"] = "⬆️",
  ["%[%[down%]%]"] = "⬇️",
  ["%[%[dpad%]%]"] = "✛",
  ["%[%[playdate%]%]"] = "🟨",
  ["%[%[menu%]%]"] = "⊙",
  ["%[%[lock%]%]"] = "🔒",
  ["%[%[crank%]%]"] = "🎣"
}


function replaceIconCodes(text)
  for k, v in pairs(textReplacementTable) do
    text = string.gsub(text, k, v)
  end

  return text
end
