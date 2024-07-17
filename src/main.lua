import "lib/fewatsu"

import "CoreLibs/graphics"

local pd <const> = playdate
local gfx <const> = playdate.graphics

fewatsu = Fewatsu()

fewatsu:setMenuWidth(200)

function playdate.update()
  gfx.clear()
  gfx.drawText("Press A to start Fewatsu.", 0, 1)
end

function playdate.AButtonDown()
  fewatsu:setCurrentWorkingDirectory("manual/")
  fewatsu:loadFile("manual/manual.json")
  fewatsu:show()
end
