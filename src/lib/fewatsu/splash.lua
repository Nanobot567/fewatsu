-- splash screen

fewatsu_splash = {}

local pd <const> = playdate
local gfx <const> = pd.graphics

local spl = fewatsu_splash

spl.oldUpdate = nil
spl.callback = nil
spl.text = nil

spl.animator = nil
spl.tm = nil

function spl.open(text, font, callback)
  spl.oldUpdate = pd.update
  spl.callback = callback

  if text ~= nil then
    spl.text = text
  else
    spl.text = "Fewatsu"
  end

  if font ~= nil then
    spl.font = font
  else
    spl.font = gfx.font.new(getScriptPath() .. "/fnt/Asheville-Sans-24-Light")
  end

  spl.animator = gfx.animator.new(800, 300, 118, pd.easingFunctions.outExpo)
  spl.tm = pd.timer.new(2100, function()
    spl.close()
  end)

  pd.update = spl.update
end

function spl.update()
  pd.timer.updateTimers()
  gfx.clear()

  spl.font:drawTextAligned(spl.text, 200, spl.animator:currentValue() - (spl.font:getHeight() / 2), kTextAlignment.center)
end

function spl.close()
  pd.update = spl.oldUpdate
  
  if spl.callback then
    spl.callback()
  end
end
