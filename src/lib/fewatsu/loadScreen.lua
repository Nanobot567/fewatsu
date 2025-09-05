-- load screen so it doesn't freeze :fire:

local pd <const> = playdate
local gfx <const> = playdate.graphics

fewatsu_loadScreen = {}

local loader = fewatsu_loadScreen

loader.font = gfx.font.new(getScriptPath() .. "fnt/Roobert-9-Mono-Condensed")
loader.SPINNER_CHARS = {"|", "/", "-", "\\"}
loader.showPercentage = true

function loader.init(fewatsuInstance)
  loader.text = fewatsuInstance.loadingScreenText
  loader.textAlignment= fewatsuInstance.loadingScreenTextAlignment
  loader.spinner = fewatsuInstance.loadingScreenSpinner

  loader.currentStep = 1

  loader.background = gfx.getDisplayImage():copy():fadedImage(0.2, gfx.image.kDitherTypeScreen)

  -- loader.background = gfx.image.new(400, 240, gfx.kColorBlack):fadedImage(0.5, gfx.image.kDitherTypeBayer4x4)

  gfx.clear()
  loader.background:draw(0, 0)
  pd.display.flush()
end

local origInvert, fontHeight, glyph

function loader.step(text, percentage)
  origInvert = pd.display.getInverted()

  pd.display.setInverted(true)

  loader.currentStep += 1

  if loader.currentStep == #loader.SPINNER_CHARS + 1 then
    loader.currentStep = 1
  end

  fontHeight = loader.font:getHeight()
  glyph = loader.font:getGlyph(loader.SPINNER_CHARS[loader.currentStep]):scaledImage(2)

  gfx.clear()

  loader.background:invertedImage():draw(0, 0)

  if loader.spinner then
    glyph:drawCentered(200, 120)
  end

  if text and loader.text then
    local x, y = 398, 240 - fontHeight

    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, 240 - fontHeight, 400, fontHeight + 1)

    if loader.textAlignment == kTextAlignment.left then
      x = 0
    elseif loader.textAlignment == kTextAlignment.center then
      x = 200
    end

    if percentage and loader.showPercentage then
      text = text .. " [" .. tostring(percentage) .. "%]"
      -- loader.font:drawText(tostring(percentage) .. "%", 2, y)
    end

    loader.font:drawTextAligned(text, x, y, loader.textAlignment)
  end

  pd.display.flush()

  pd.display.setInverted(origInvert)
end
