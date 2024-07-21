import "lib/fewatsu"

import "CoreLibs/graphics"

local pd <const> = playdate
local gfx <const> = playdate.graphics

fewatsu = Fewatsu()
fewatsu:setCurrentWorkingDirectory("manual/")
fewatsu:setDarkMode(true)

function playdate.update()
  gfx.clear()
  gfx.drawText("Press A to start Fewatsu.", 0, 1)
end

function playdate.AButtonDown()
  fewatsu:loadFile("manual/manual.json")
  fewatsu:show()
end
