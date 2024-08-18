import "lib/fewatsu"

import "CoreLibs/graphics"

local pd <const> = playdate
local gfx <const> = playdate.graphics

local darkmode = false

local sineWavePhase = 0

fewatsu = Fewatsu:init()
fewatsu.customElements = {
  sine = {
    heightCalculationFunction = function()
      return 100
    end,

    drawFunction = function(y, data)
      gfx.drawSineWave(0, y + 45, 400, y + 45, 35, 35, 50)
    end,

    padding = 10
  },

  dynamicSine = {
    heightCalculationFunction = function ()
      return 100
    end,

    drawFunction = function(y, data)
      sineWavePhase += 1

      if sineWavePhase == 50 then
        sineWavePhase = 0
      end

      gfx.drawSineWave(0, y + 45, 420, y + 45, 35, 35, 50, -sineWavePhase)
    end,

    padding = 10,
    updateEveryFrame = true
  }
}

function pd.update()
  gfx.clear()
  gfx.drawText("Press A to start Fewatsu.", 0, 1)
  gfx.drawText("Dark mode: " .. tostring(darkmode) .. " (press B to toggle)", 0, 40)
end

function pd.AButtonDown()
  fewatsu:show()
  fewatsu:loadFile("manual.json")
end

function pd.BButtonDown()
  darkmode = not darkmode
  fewatsu:setDarkMode(darkmode)
end
