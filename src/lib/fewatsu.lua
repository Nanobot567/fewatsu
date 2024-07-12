-- fewatsu lib by nanobot567

import "fewatsu/funcs"
import "fewatsu/imageViewer"

import "CoreLibs/object"

local pd <const> = playdate
local gfx <const> = playdate.graphics

local FEWATSU_X = 2
local FEWATSU_WIDTH = 396
local FEWATSU_LISTINDENT = 20

class("Fewatsu").extends()

function Fewatsu:init()
  self.font = gfx.getSystemFont()
  self.headingFont = gfx.font.new("lib/fewatsu/fnt/Sasser-Slab")
  self.boldHeadingFont = gfx.font.new("lib/fewatsu/fnt/Sasser-Slab-Bold")
  self.boldFont = gfx.getSystemFont(gfx.font.kVariantBold)
  self.italicFont = gfx.getSystemFont(gfx.font.kVariantItalic)
  self.titleFont = gfx.font.new("lib/fewatsu/fnt/Asheville-Sans-24-Light")
  self.underlineFont = gfx.font.new("lib/fewatsu/fnt/Asheville-Sans-14-Light-Underlined")

  self.linkXs = {}
  self.linkYs = {}
  self.linkWidths = {}
  self.linkLocations = {}

  self.selectedObject = 0

  self.headerYs = {}

  self.offset = 0

  self.elements = {}

  self:updateText()
end

-- show function. this should push the handler
function Fewatsu:show()
  self.originalRefreshRate = pd.display.getRefreshRate()

  pd.display.setRefreshRate(50)

  pd.inputHandlers.push(self, true)
  self.oldUpdate = pd.update
  pd.update = function() self.update(self) end
end

function Fewatsu:hide()
  pd.inputHandlers.pop()
  pd.update = self.oldUpdate

  pd.display.setRefreshRate(self.originalRefreshRate)
end

function Fewatsu:load(json)
  self.linkXs = {}
  self.linkYs = {}
  self.linkWidths = {}
  self.linkLocations = {}

  self.imgXs = {}
  self.imgYs = {}
  self.imgWidths = {}
  self.imgHeights = {}
  self.imgPaths = {}
  self.imgCaptions = {}

  self.selectedLink = 0

  self.headerYs = {}

  self.offset = 0

  self.elements = {}


  local currentY = 0
  local elements = json["data"]
  local elementYs = {}
  local textHeights = {}
  local processedLists = {}
  local elemType = ""

  for i, element in ipairs(elements) do -- preprocessing for string elements
    if type(element) == "string" then
      elements[i] = {}
      elements[i].type = "text"
      elements[i].text = element
    end
  end

  self.elements = elements

  for i, element in ipairs(elements) do
    table.insert(elementYs, currentY)

    elemType = element["type"]
    if elemType == "title" then
      local textw, texth = gfx.getTextSizeForMaxWidth(element["text"], FEWATSU_WIDTH, nil, self.titleFont)

      table.insert(textHeights, texth)

      self.headerYs[string.lower(element["text"])] = currentY

      if not element["y"] then
        currentY += texth + 10
      end
    elseif elemType == "heading" then
      local textw, texth = gfx.getTextSizeForMaxWidth(element["text"], FEWATSU_WIDTH, nil, self.boldHeadingFont)

      table.insert(textHeights, texth)

      self.headerYs[string.lower(element["text"])] = currentY

      if not element["y"] then
        currentY += texth + 10
      end
    elseif elemType == "subheading" then
      local textw, texth = gfx.getTextSizeForMaxWidth(element["text"], FEWATSU_WIDTH, nil, self.headingFont)
      
      table.insert(textHeights, texth)

      self.headerYs[string.lower(element["text"])] = currentY

      if not element["y"] then
        currentY += texth + 10
      end
    elseif elemType == "text" then
      local textw, texth = gfx.getTextSizeForMaxWidth(element["text"], FEWATSU_WIDTH)

      table.insert(textHeights, texth)

      if not element["y"] then
        currentY += texth + 10
      end
    elseif elemType == "orderedlist" or elemType == "unorderedlist" then
      local temp = {}
      local text = ""

      if elemType == "orderedlist" then
        for listi, item in ipairs(element["items"]) do
          table.insert(temp, tostring(listi) .. ". " .. item)
        end
      else
        for listi, item in ipairs(element["items"]) do
          table.insert(temp, "- " .. item)
        end
      end

      text = table.concat(temp, "\n")

      table.insert(processedLists, text)

      local textw, texth = gfx.getTextSizeForMaxWidth(text, FEWATSU_WIDTH - FEWATSU_LISTINDENT) -- indent

      table.insert(textHeights, texth)

      currentY += texth + 10
    elseif elemType == "quote" then
      local textw, texth = gfx.getTextSizeForMaxWidth(element["text"], FEWATSU_WIDTH)

      table.insert(textHeights, texth)

      currentY += texth + 24
    elseif elemType == "image" then
      local imgpath = element["source"]
      local scale, yscale = 1, 1

      if element["scale"] then
        scale = element["scale"]
      end

      if element["yscale"] then
        yscale = element["yscale"]
      end

      local img = gfx.image.new(imgpath):scaledImage(scale, yscale)

      if img ~= nil then
        currentY += img.height * scale + 20
      end
    elseif elemType == "link" then
      local textw, texth = gfx.getTextSizeForMaxWidth(element["text"], FEWATSU_WIDTH, nil, self.boldFont)

      table.insert(textHeights, texth)

      table.insert(self.linkXs, FEWATSU_X - 2) -- TODO: allow custom x and y positions
      table.insert(self.linkYs, currentY - 2)
      table.insert(self.linkWidths, textw + 4)

      if element["page"] then
        element["page"] = string.lower(element["page"])
      end

      if element["section"] then
        element["section"] = string.lower(element["section"])
      end

      table.insert(self.linkLocations, {element["page"], element["section"]})

      currentY += texth + 10
    elseif elemType == "break" then
      currentY += 30
    end
  end

  local currentElementY = 0

  self.image = gfx.image.new(400, currentY + 10)

  gfx.pushContext(self.image)

  gfx.setFont(self.font, gfx.font.kVariantNormal)
  gfx.setFont(self.boldFont, gfx.font.kVariantBold)
  gfx.setFont(self.italicFont, gfx.font.kVariantItalic)

  gfx.clear()

  for elementI, element in ipairs(elements) do -- draw
    elemType = element["type"]
    currentElementY = table.remove(elementYs, 1)

    if elemType == "title" or elemType == "heading" or elemType == "subheading" or elemType == "text" then
      if element["x"] == nil then
        element["x"] = FEWATSU_X
      elseif element["y"] == nil then
        element["y"] = currentElementY
      elseif element["width"] == nil then
        element["width"] = FEWATSU_WIDTH
      elseif element["height"] == nil then
        element["height"] = table.remove(textHeights, 1)
      elseif element["alignment"] == nil then
        element["alignment"] = kTextAlignment.left
      end

      if element["alignment"] then
        if element["alignment"] == "left" then
          element["alignment"] = kTextAlignment.left
        elseif element["alignment"] == "center" then
          element["alignment"] = kTextAlignment.center
        elseif element["alignment"] == "right" then
          element["alignment"] = kTextAlignment.right
        end
      end
    end

    if elemType == "title" then
      gfx.drawTextInRect(element["text"], FEWATSU_X, currentElementY, FEWATSU_WIDTH, table.remove(textHeights, 1), nil, nil, element["alignment"], self.titleFont)
    elseif elemType == "heading" then
      gfx.drawTextInRect(element["text"], FEWATSU_X, currentElementY, FEWATSU_WIDTH, table.remove(textHeights, 1), nil, nil, element["alignment"], self.boldHeadingFont)
    elseif elemType == "subheading" then
      gfx.drawTextInRect(element["text"], FEWATSU_X, currentElementY, FEWATSU_WIDTH, table.remove(textHeights, 1), nil, nil, element["alignment"], self.headingFont)
    elseif elemType == "text" then
      gfx.drawTextInRect(element["text"], FEWATSU_X, currentElementY, FEWATSU_WIDTH, table.remove(textHeights, 1), nil, nil, element["alignment"])
    elseif elemType == "orderedlist" or elemType == "unorderedlist" then
      gfx.drawTextInRect(table.remove(processedLists, 1), FEWATSU_X + FEWATSU_LISTINDENT, currentElementY, FEWATSU_WIDTH - FEWATSU_LISTINDENT, table.remove(textHeights, 1))
    elseif elemType == "quote" then
      local radius = 4
      local rect = pd.geometry.rect.new(40, currentElementY + 5, 320, table.remove(textHeights, 1) + 4)

      gfx.drawRoundRect(rect, radius)

      rect.y += 2

      gfx.drawTextInRect(element["text"], rect, nil, nil, kTextAlignment.center)

      if element["radius"] then
        radius = element["radius"]
      end
    elseif elemType == "image" then
      local imgpath = element["source"]

      local scale, yscale = 1, 1

      if element["scale"] then
        scale = element["scale"]
      end

      if element["yscale"] then
        yscale = element["yscale"]
      elseif element["scale"] then
        yscale = scale
      end

      local img = gfx.image.new(imgpath):scaledImage(scale, yscale)

      local x = FEWATSU_X

      if img ~= nil then
        if element["x"] ~= nil then
          x = element["x"]
        end

        img:draw(x, currentElementY)
      end

      table.insert(self.imgXs, x)
      table.insert(self.imgYs, currentElementY)
      table.insert(self.imgWidths, img.width)
      table.insert(self.imgHeights, img.height)
      table.insert(self.imgPaths, imgpath)
      table.insert(self.imgCaptions, element["caption"])
    elseif elemType == "link" then
      gfx.drawTextInRect(element["text"], FEWATSU_X, currentElementY, FEWATSU_WIDTH, table.remove(textHeights, 1), nil, nil, element["alignment"], self.boldFont)
    elseif elemType == "break" then
      if element["visible"] ~= false then
        gfx.drawLine(FEWATSU_X + 20, currentElementY, FEWATSU_WIDTH - 20, currentElementY)
      end
    end
  end

  gfx.popContext()

  return self.image
end

function Fewatsu:updateText()
  self:load(json.decodeFile("manual/manual.json"))
end

function Fewatsu:update()
  local selectableObjects = {}
  gfx.clear()

  if self.image.height >= 240 then
    if pd.buttonIsPressed("down") then
      self.offset += 10
    elseif pd.buttonIsPressed("up") then
      self.offset -= 10
    end

    local chg, achg = pd.getCrankChange()

    self.offset += chg

    if self.offset < 0 then
      self.offset = 0
    elseif self.offset > self.image.height - 240 then
      self.offset = self.image.height - 240
    end
  end

  self.image:draw(0, 0 - self.offset)

  self.selectedObject = nil

  for i, v in ipairs(self.linkYs) do
    if v - self.offset < 120 and v - self.offset > -240 then
      table.insert(selectableObjects, {
        type = "link",
        i = i,
        y = v,
        location = self.linkLocations[i]
      })
    end
  end

  for i, v in ipairs(self.imgYs) do
    if v - self.offset < 120 and v - self.offset > -240 then
      table.insert(selectableObjects, {
        type = "image",
        i = i,
        y = v,
        path = self.imgPaths[i],
        caption = self.imgCaptions[i]
      })
    end
  end

  table.sort(selectableObjects, function (a, b)
    return a["y"] < b["y"]
  end)

  if #selectableObjects ~= 0 then
    local closest = selectableObjects[1]

    for i, v in pairs(selectableObjects) do
      if math.abs(v["y"] - self.offset - 120) < closest["y"] then
        closest = v
      end
    end

    if closest["type"] == "link" then
      gfx.drawRoundRect(self.linkXs[closest["i"]], closest["y"] - self.offset, self.linkWidths[closest["i"]], 22, 2)
    elseif closest["type"] == "image" then
      local index = closest["i"]
      gfx.setLineWidth(3)
      gfx.setColor(gfx.kColorXOR)
      gfx.drawRect(self.imgXs[index], self.imgYs[index] - self.offset, self.imgWidths[index], self.imgHeights[index])
      gfx.setColor(gfx.kColorBlack)
      gfx.setLineWidth(1)
    end

    self.selectedObject = closest
  end

  -- for i = #self.linkYs, 1, -1 do
  --   local v = self.linkYs[i]

  --   if v - self.offset < 120 and v - self.offset > -120 then
  --     self.selectedLink = i
  --     break
  --   end
  -- end

  if pd.buttonJustPressed("a") then
    if self.selectedObject ~= nil then
      local obj = self.selectedObject

      if obj["type"] == "link" then
        local location = obj["location"]

        if location[2] ~= nil then
          if location[2] == "#top" then
            self.offset = 0
          elseif location[2] == "#bottom" then
            self.offset = self.image.height
          else
            if self.image.height > 240 then
              self.offset = self.headerYs[location[2]]

              if self.offset > self.image.height - 240 then
                self.offset = self.image.height - 240
              end
            end
          end
        end
      elseif obj["type"] == "image" then
        fewatsu_imageViewer.open(gfx.image.new(obj["path"]), obj["caption"])
      end
    end
  end

  -- pd.drawFPS(380, 220)
end
