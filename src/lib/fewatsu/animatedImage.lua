-- animated image class

import "CoreLibs/frameTimer"

local pd <const> = playdate
local gfx <const> = playdate.graphics

class("AnimatedImage").extends()

AnimatedImage.SEGMENT_SIZE = 25

function AnimatedImage:init(path, scale, delay)
  self.frame = 1
  self.segmentFrame = 1

  if not delay then
    delay = 0
  end

  self.delay = delay
  self.path = path

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
end

function AnimatedImage:updateFrame()
  self.frame = self.frame + 1

  if self.frame > self.imagetableLength then
    self.frame = 1
  end

  self.currentFrame = self.images[self.frame]
end

function AnimatedImage:update()
  pd.timer.updateTimers()
end

function AnimatedImage:getCurrentFrame()
  return self.currentFrame
end

function AnimatedImage:getDelay()
  return self.delay
end

function AnimatedImage:destroy()
  self.timer:remove()
  self.images = nil
  self = nil
end
