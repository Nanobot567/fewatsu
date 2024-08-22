-- debugger

local pd <const> = playdate
local gfx <const> = pd.graphics

fewatsu_debug = {}
fewatsu_debug.enabled = true

function fewatsu_debug.log(text, context)
  if fewatsu_debug.enabled then
    local cmpT = {}

    if type(text) == "table" then
      text = table.concat(text)
    else
      text = tostring(text)
    end

    if not context then
      context = "INFO"
    end

    cmpT = {"(", pd.getCurrentTimeMilliseconds(), "ms) [", string.upper(context), "] ", text}

    print(table.concat(cmpT))
  end
end
