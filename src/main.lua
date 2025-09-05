import "lib/fewatsu"

import "CoreLibs/graphics"

local pd <const> = playdate
local gfx <const> = playdate.graphics

local darkmode = false
local splash = true
local loadingScreen = true

local sineWavePhase = 0

local sineCustomElement = {
  heightCalculationFunction = function()
    return 100
  end,

  drawFunction = function(y, data)
    gfx.drawSineWave(0, y + 45, 400, y + 45, 35, 35, 50)
  end
}

local dynamicSineCustomElement = {
  heightCalculationFunction = function ()
    return 100
  end,

  drawFunction = function(y, data)
    sineWavePhase += data["step"]

    if sineWavePhase >= 50 then
      sineWavePhase = 0
    end

    gfx.drawSineWave(0, y + 45, 420, y + 45, 35, 35, 50, -sineWavePhase)
  end,

  drawEveryFrame = true
}

local function redraw()
  gfx.clear()
  gfx.drawText("Press A to start Fewatsu.", 0, 1)
  gfx.drawText("Dark mode: " .. tostring(darkmode) .. " (press B to toggle)", 0, 40)
  gfx.drawText("Splash screen: " .. tostring(splash) .. " (press up to toggle)", 0, 60)
  gfx.drawText("Loading screen: " .. tostring(loadingScreen) .. " (press down to toggle)", 0, 80)
end

fewatsu = Fewatsu:init()
-- EPIC EASE :fire:
-- fewatsu:setScrollEasingFunction(pd.easingFunctions.inOutExpo)
-- fewatsu:setScrollDuration(800)
fewatsu:registerCustomElement("sine", sineCustomElement)
fewatsu:registerCustomElement("dynamicSine", dynamicSineCustomElement)
fewatsu:setCallback(redraw)

redraw()

function pd.update()
  
end

function pd.AButtonDown()
  fewatsu:show(function(fw)
    fw:loadFile("manual.json")
  end)
end

function pd.BButtonDown()
  darkmode = not darkmode
  fewatsu:setDarkMode(darkmode)
  redraw()
end

function pd.upButtonDown()
  splash = not splash
  fewatsu:setShowSplash(splash)
  redraw()
end

function pd.downButtonDown()
  loadingScreen = not loadingScreen
  fewatsu:setEnableLoadingScreen(loadingScreen)
  redraw()
end
