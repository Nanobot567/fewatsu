-- animated image class

import "CoreLibs/frameTimer"

local pd <const> = playdate
local gfx <const> = playdate.graphics

class("AnimatedImage").extends()

AnimatedImage.SEGMENT_SIZE = 25

local function grabImages(imagetable, start, fin)
  local images = {}

  for i = start, fin do
    table.insert(images, imagetable:getImage(i):copy())
  end

  return images
end

function AnimatedImage:init(path, delay)
  self.frame = 1
  self.segmentFrame = 1
  self.delay = delay
  self.path = path

  self.timer = pd.timer.new(delay)
  self.timer.repeats = true

  self.timer.timerEndedCallback = function()
    self:updateFrame()
  end

  local itable = playdate.graphics.imagetable.new(path)

  self.imagetableLength = itable:getLength()

  self.images = grabImages(itable, self.frame, self.frame + self.SEGMENT_SIZE)

  self.currentFrame = self.images[1]
end

function AnimatedImage:updateFrame()
  self.frame = self.frame + 1
  self.segmentFrame = self.segmentFrame + 1

  if self.frame % self.SEGMENT_SIZE == 1 then
    local itable = playdate.graphics.imagetable.new(self.path)
    local origFrame = self.frame
    local endFrame = self.frame + self.SEGMENT_SIZE
    if endFrame > self.imagetableLength then
      endFrame = self.imagetableLength
    end

    self.images = grabImages(itable, origFrame, endFrame - 1)

    self.segmentFrame = 1
  elseif self.frame == self.imagetableLength then
    self.frame = 1
    self.segmentFrame = 1
    local itable = playdate.graphics.imagetable.new(self.path)

    self.images = grabImages(itable, self.frame, self.frame + self.SEGMENT_SIZE)
  end

  self.currentFrame = self.images[self.segmentFrame]
end

function AnimatedImage:update()
  pd.frameTimer.updateTimers()
end

function AnimatedImage:getCurrentFrame()
  return self.currentFrame
end

function AnimatedImage:getDelay()
  return self.delay
end

function AnimatedImage:destroy()
  self.timer:remove()
  self = nil
end
