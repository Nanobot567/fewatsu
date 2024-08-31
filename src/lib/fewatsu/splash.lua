-- splash screen

fewatsu_splash = {}

local pd <const> = playdate
local gfx <const> = pd.graphics

local spl = fewatsu_splash

spl.startupSound = pd.sound.sampleplayer.new(getScriptPath() .. "/snd/startup")

spl.oldUpdate = nil
spl.callback = nil
spl.text = nil

spl.animator = nil
spl.tm = nil
spl.bg = nil

spl.textW, spl.textH = nil, nil

function spl.open(text, font, bg, callback)
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

  spl.textW = spl.font:getTextWidth(spl.text)
  spl.textH = spl.font:getHeight()

  spl.animator = gfx.animator.new(800, 300, 118, pd.easingFunctions.outExpo)
  spl.tm = pd.timer.new(2100, function()
    spl.close()
  end)

  pd.display.flush()

  if bg then
    spl.bg = bg
  else
    spl.bg = gfx.getDisplayImage():copy():fadedImage(0.2, gfx.image.kDitherTypeScreen)
  end

  pd.update = spl.update
  
  spl.startupSound:play()
end

function spl.update()
  pd.timer.updateTimers()
  gfx.clear()

  spl.bg:draw(0, 0)

  gfx.setColor(gfx.kColorWhite)
  gfx.fillRect(198 - (spl.textW / 2), spl.animator:currentValue()  - (spl.textH / 2) -2, spl.textW + 4, spl.textH)
  gfx.setColor(gfx.kColorBlack)
  spl.font:drawTextAligned(spl.text, 200, spl.animator:currentValue() - (spl.textH / 2), kTextAlignment.center)
end

function spl.close()
  pd.update = spl.oldUpdate

  gfx.clear()
  pd.display.flush()
  coroutine.yield()
  
  if spl.callback then
    spl.callback()
  end
end
