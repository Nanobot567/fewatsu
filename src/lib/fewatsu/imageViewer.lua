-- fewatsu image viewer

local pd <const> = playdate
local gfx <const> = playdate.graphics

fewatsu_imageViewer = {}

local imageViewer = fewatsu_imageViewer

imageViewer.hideUI = false
imageViewer.isOpen = false

function imageViewer.open(image, caption, callback)
  imageViewer.isOpen = true

  imageViewer.x = 200
  imageViewer.y = 120
  imageViewer.scale = 1
  
  imageViewer.image = image
  imageViewer.originalImage = image

  gfx.setImageDrawMode(gfx.kDrawModeNXOR)

  if callback ~= nil then
    imageViewer.callback = callback
  else
    imageViewer.callback = function() end
  end

  if caption == nil then
    imageViewer.caption = ""
  else
    imageViewer.caption = caption
  end

  pd.inputHandlers.push(imageViewer, true)
  imageViewer.oldUpdate = pd.update
  pd.update = imageViewer.update
end

function imageViewer.update()
  gfx.clear()

  if pd.buttonIsPressed("up") then
    imageViewer.y += 5
  elseif pd.buttonIsPressed("down") then
    imageViewer.y -= 5
  end
  
  if pd.buttonIsPressed("left") then
    imageViewer.x += 5
  elseif pd.buttonIsPressed("right") then
    imageViewer.x -= 5
  end

  imageViewer.image:drawCentered(imageViewer.x, imageViewer.y)

  if not imageViewer.hideUI then
    gfx.drawTextInRect(imageViewer.caption, 2, 2, 396, gfx.getFont():getHeight() * 2 + 2, nil, "...")
    gfx.drawTextAligned("Ⓐ = toggle UI, 🎣 = scale, Ⓑ = exit", 398, 220, kTextAlignment.right)
    gfx.drawText(math.round(imageViewer.scale, 2) .. "x", 2, 224)
  end
end

function imageViewer.AButtonDown()
  imageViewer.hideUI = not imageViewer.hideUI
end

function imageViewer.BButtonDown()
  imageViewer.close()
end

function imageViewer.cranked(chg, accelChg)
  local originalScale = imageViewer.scale
  imageViewer.scale += chg / 360
  
  if imageViewer.scale < 0 then
    imageViewer.scale = 0
  elseif imageViewer.scale > 2 then
    imageViewer.scale = 2
  end

  if imageViewer.scale ~= originalScale then
    imageViewer.image = imageViewer.originalImage:scaledImage(imageViewer.scale)
  end
end

function imageViewer.crankDocked()
  imageViewer.scale = 1
  imageViewer.x = 200
  imageViewer.y = 120

  imageViewer.image = imageViewer.originalImage
end

function imageViewer.close()
  gfx.setImageDrawMode(gfx.kDrawModeCopy)

  imageViewer.callback()

  pd.update = imageViewer.oldUpdate
  pd.inputHandlers.pop()

  imageViewer.image = nil
  imageViewer.originalImage = nil

  imageViewer.isOpen = false
end
