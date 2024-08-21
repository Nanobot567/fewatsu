-- animated image class

import "CoreLibs/frameTimer"

local pd <const> = playdate
local gfx <const> = playdate.graphics

local dbg = fewatsu_debug

class("AnimatedImage").extends()

AnimatedImage.SEGMENT_SIZE = 25

function AnimatedImage:init(path, scale, delay, darkModeInvert)
  self.frame = 1
  self.segmentFrame = 1

  if not delay then
    delay = 0
  end

  self.delay = delay
  self.path = path
  self.darkModeInvert = darkModeInvert

  self.timer = pd.timer.new(delay)
  self.timer.repeats = true

  self.timer.timerEndedCallback = function()
    self:updateFrame()
  end

  local itable = playdate.graphics.imagetable.new(path)

  if scale and scale ~= 1 then
    for i = 1, #itable do
      itable:setImage(i, itable[i]:scaledImage(scale))
    end
  end

  self.imagetableLength = itable:getLength()

  self.images = itable

  self.currentFrame = self.images[1]

  dbg.log(table.concat({"new (", path .. ", " .. tostring(scale) .. " scale, " .. tostring(delay) .. " delay)"}), "animated image")
end

function AnimatedImage:updateFrame()
  self.frame = self.frame + 1

  if self.frame > self.imagetableLength then
    self.frame = 1
  end

  self.currentFrame = self.images[self.frame]
end

function AnimatedImage:getCurrentFrame(invert)
  local frame = self.currentFrame

  if invert and self.darkModeInvert then
    frame = frame:invertedImage()
  end

  return frame
end

function AnimatedImage:getDelay()
  return self.delay
end

function AnimatedImage:destroy()
  self.timer:remove()
  self.images = nil
  self = nil
end
