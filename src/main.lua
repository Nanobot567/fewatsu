import "lib/fewatsu"

import "CoreLibs/graphics"

local pd <const> = playdate
local gfx <const> = playdate.graphics

local darkmode = false

class("Particle").extends()

function Particle:init()
  self.x = math.random(1, 400)
  self.y = math.random(1, 30) * 2
  self.yOffset = 0
  self.speed = math.random(1, 3) + math.random()
  self.radius = math.random(1, 3)
end

function Particle:draw()
  local oldColor = gfx.getColor()
  gfx.setColor(gfx.kColorBlack)

  gfx.fillCircleAtPoint(self.x, self.y + self.yOffset, self.radius)

  gfx.setColor(oldColor)
end

function Particle:update()
  self.x = self.x + self.speed

  if self.x > 410 then
    self.x = -20
    self.len = math.random(30, 80)
    self.y = math.random(1, 30) * 2
    self.speed = math.random(1, 3) + math.random()
  end
end

local particles = {}

for i = 1, 10 do
  table.insert(particles, Particle())
end


fewatsu = Fewatsu:init()
fewatsu.customElements = {
  particles = {
    heightCalculationFunction = function(data)
      return 60
    end,

    drawFunction = function(y, data)
      for i, v in ipairs(particles) do
        v.yOffset = y
        v:update()
        v:draw()
      end
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
