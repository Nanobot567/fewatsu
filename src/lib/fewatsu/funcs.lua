local pd <const> = playdate
local gfx <const> = playdate.graphics

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

function table.getKeys(t)
  local keys = {}
  for k, v in pairs(t) do
    table.insert(keys, k)
  end
  return keys
end

function table.slice(tbl, first, last, step)
  local sliced = {}

  for i = first or 1, last or #tbl, step or 1 do
    sliced[#sliced+1] = tbl[i]
  end

  return sliced
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

function getScriptPath()
  return string.match(string.sub(debug.getinfo(2, "S").source, 2), "(.*/)")
end

-- returns the path which exists, first trying from `cwd`, then trying as an absolute path
function getExistentPath(cwd, path, extensions)
  local checkTable = {""}

  if type(extensions) == "table" then
    for i, v in ipairs(extensions) do
      table.insert(checkTable, v)
    end
  elseif extensions ~= nil then
    table.insert(checkTable, extensions)
  end

  for i, v in ipairs(checkTable) do
    local p = path .. v

    if pd.file.exists(cwd .. p) and not pd.file.isdir(cwd .. p) then
      return cwd .. p
    elseif pd.file.exists(p) and not pd.file.isdir(p) then
      return p
    end
  end

  return nil
end

function generateImageNotFoundImage(path)
  local img = gfx.image.new(200, 120)

  gfx.pushContext(img)

  gfx.clear(gfx.kColorBlack)
  
  gfx.setImageDrawMode(gfx.kDrawModeFillWhite)

  gfx.drawTextInRect("*image not found: " .. path .. "*", 10, 10, 180, 80, nil, "...")

  gfx.setImageDrawMode(gfx.kDrawModeInverted)

  gfx.image.new(getScriptPath() .. "img/dead-playdate"):drawCentered(100, 90)

  gfx.popContext()

  return img
end
