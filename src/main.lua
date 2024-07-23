import "lib/fewatsu"

import "CoreLibs/graphics"

local pd <const> = playdate
local gfx <const> = playdate.graphics

local darkmode = false

fewatsu = Fewatsu:init()
-- fewatsu:setCurrentWorkingDirectory("manual/")

function pd.update()
  gfx.clear()
  gfx.drawText("Press A to start Fewatsu.", 0, 1)
  gfx.drawText("Dark mode: " .. tostring(darkmode) .. " (press B to toggle)", 0, 40)
end

function pd.AButtonDown()
  fewatsu:loadFile("manual/manual.json")
  fewatsu:show()
end

function pd.BButtonDown()
  darkmode = not darkmode
  fewatsu:setDarkMode(darkmode)
end
