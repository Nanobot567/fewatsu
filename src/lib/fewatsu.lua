-- fewatsu lib by nanobot567

import "CoreLibs/animator"
import "CoreLibs/object"
import "CoreLibs/timer"
import "CoreLibs/ui"

import "fewatsu/funcs"
import "fewatsu/imageViewer"
import "fewatsu/menu"

local pd <const> = playdate
local gfx <const> = playdate.graphics

local FEWATSU_LIB_PATH = getScriptPath()

local FEWATSU_X = 0
local FEWATSU_WIDTH = 400
local FEWATSU_LISTINDENT = 20

local FEWATSU_DEFAULT_DATA = {
  title = "Fewatsu",
  id = "main",
  data = {
    {
      type = "title",
      text = "Fewatsu",
    },
    "Fewatsu is an electronic manual library for *Playdate*.",
    "If you are seeing this, then nothing has been loaded into Fewatsu yet! Check that your code is calling either a *fewatsu:load()* or *fewatsu:loadFile()*. If you're confused, check out the documentation online!"
  }
}


class("Fewatsu").extends()

---Initializes a new Fewatsu instance.
---
---@return nil
function Fewatsu:init()
  self.font = gfx.getSystemFont()
  self.subheadingFont = gfx.font.new(FEWATSU_LIB_PATH .. "fewatsu/fnt/Sasser-Slab")
  self.headingFont = gfx.font.new(FEWATSU_LIB_PATH .. "fewatsu/fnt/Sasser-Slab-Bold")
  self.boldFont = gfx.getSystemFont(gfx.font.kVariantBold)
  self.italicFont = gfx.getSystemFont(gfx.font.kVariantItalic)
  self.titleFont = gfx.font.new(FEWATSU_LIB_PATH .. "fewatsu/fnt/Asheville-Sans-24-Light")
  self.linkFont = self.boldFont

  self.selectedObject = 0

  self.offset = 0

  self.offsetAnimator = nil
  self.animatorEaseTime = 350
  self.animatorEaseFunction = pd.easingFunctions.outExpo

  self.menuAnimator = gfx.animator.new(0, self.menuWidth, self.menuWidth)
  self.menuAnimatorEaseTime = 350

  self.inputDelayTimer = nil

  self.leftPadding = 2
  self.rightPadding = 2

  self.quoteBoxPadding = 20

  self.titlesToPaths = {}

  self.title = ""
  self.path = ""

  self.elements = {}

  self.preUpdate = nil
  self.postUpdate = nil
  self.callback = nil

  self:load(FEWATSU_DEFAULT_DATA)
end

---Parses the given JSON file and sets the current manual page to the image generated. Returns the image.
---
---@param json table
---@return playdate.image
function Fewatsu:load(json)
  self.linkXs = {}
  self.linkYs = {}
  self.linkWidths = {}
  self.linkHeights = {}
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

  self.title = json["title"]

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

    if element["text"] then
      element["text"] = replaceIconCodes(element["text"])
    end

    if element["items"] then
      for itemI, item in ipairs(element["items"]) do
        element["items"][itemI] = replaceIconCodes(item)
      end
    end

    if elemType == "title" then
      local textw, texth = gfx.getTextSizeForMaxWidth(element["text"],
        FEWATSU_WIDTH - (self.rightPadding + self.leftPadding), nil, self.titleFont)

      table.insert(textHeights, texth)

      self.headerYs[string.lower(element["text"])] = currentY

      if not element["y"] then
        currentY = texth + 10
      end
    elseif elemType == "heading" then
      local textw, texth = gfx.getTextSizeForMaxWidth(element["text"],
        FEWATSU_WIDTH - (self.rightPadding + self.leftPadding), nil, self.headingFont)

      table.insert(textHeights, texth)

      self.headerYs[string.lower(element["text"])] = currentY

      if not element["y"] then
        currentY = currentY + texth + 10
      end
    elseif elemType == "subheading" then
      local textw, texth = gfx.getTextSizeForMaxWidth(element["text"],
        FEWATSU_WIDTH - (self.rightPadding + self.leftPadding), nil, self.subheadingFont)

      table.insert(textHeights, texth)

      self.headerYs[string.lower(element["text"])] = currentY

      if not element["y"] then
        currentY = currentY + texth + 10
      end
    elseif elemType == "text" then
      local textw, texth = gfx.getTextSizeForMaxWidth(element["text"],
        FEWATSU_WIDTH - (self.rightPadding + self.leftPadding))

      table.insert(textHeights, texth)

      if not element["y"] then
        currentY = currentY + texth + 10
      end
    elseif elemType == "orderedlist" or elemType == "unorderedlist" then
      local temp = {}
      local text = ""

      if elemType == "orderedlist" then
        for listi, item in ipairs(element["items"]) do
          table.insert(temp, "*" .. tostring(listi) .. ".* " .. item)
        end
      else
        for listi, item in ipairs(element["items"]) do
          table.insert(temp, "*-* " .. item)
        end
      end

      text = table.concat(temp, "\n")

      table.insert(processedLists, text)

      local textw, texth = gfx.getTextSizeForMaxWidth(text,
        FEWATSU_WIDTH - FEWATSU_LISTINDENT - (self.rightPadding + self.leftPadding))

      table.insert(textHeights, texth)

      currentY = currentY + texth + 10
    elseif elemType == "quote" then
      local textw, texth = gfx.getTextSizeForMaxWidth(element["text"],
        FEWATSU_WIDTH - (self.quoteBoxPadding * 2) - (self.rightPadding + self.leftPadding))

      table.insert(textHeights, texth)

      currentY = currentY + texth + 24
    elseif elemType == "image" then
      local img
      local imgpath = element["source"]
      local scale, yscale = 1, 1

      if element["scale"] then
        scale = element["scale"]
      end

      if element["yscale"] then
        yscale = element["yscale"]
      end

      imgpath = getExistentPath(self.cwd, imgpath .. ".pdi")

      if imgpath ~= nil then
        img = gfx.image.new(imgpath)

        img = img:scaledImage(scale, yscale)
      else
        img = generateImageNotFoundImage(element["source"])
      end

      currentY = currentY + img.height * scale + 20
    elseif elemType == "link" then
      local textw, texth = gfx.getTextSizeForMaxWidth(element["text"],
        FEWATSU_WIDTH - (self.rightPadding + self.leftPadding), nil, self.linkFont)

      table.insert(textHeights, texth)

      table.insert(self.linkXs, (FEWATSU_X + self.leftPadding - 2)) -- TODO: allow custom x and y positions
      table.insert(self.linkYs, currentY - 2)
      table.insert(self.linkWidths, textw + 4)
      table.insert(self.linkHeights, texth + 2)

      if element["page"] then
        element["page"] = string.lower(element["page"])
      end

      if element["section"] then
        element["section"] = string.lower(element["section"])
      end

      table.insert(self.linkLocations, { element["page"], element["section"] })

      currentY = currentY + texth + 10
    elseif elemType == "break" then
      currentY = currentY + 30
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

    if elemType == "title" or elemType == "heading" or elemType == "subheading" or elemType == "text" or elemType == "link" then
      if element["x"] == nil then
        element["x"] = FEWATSU_X + self.leftPadding
      end

      if element["y"] == nil then
        element["y"] = currentElementY
      end

      if element["width"] == nil then
        element["width"] = FEWATSU_WIDTH - self.rightPadding - self.leftPadding
      end

      -- if element["height"] == nil then
      --   element["height"] = table.remove(textHeights, 1)
      -- end

      if element["alignment"] == nil then
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
      gfx.drawTextInRect(element["text"], element["x"], currentElementY, element["width"], table.remove(textHeights, 1),
        nil, nil, element["alignment"], self.titleFont)
    elseif elemType == "heading" then
      gfx.drawTextInRect(element["text"], element["x"], currentElementY, element["width"], table.remove(textHeights, 1),
        nil, nil, element["alignment"], self.headingFont)
    elseif elemType == "subheading" then
      gfx.drawTextInRect(element["text"], element["x"], currentElementY, element["width"], table.remove(textHeights, 1),
        nil, nil, element["alignment"], self.subheadingFont)
    elseif elemType == "text" then
      gfx.drawTextInRect(element["text"], element["x"], currentElementY, element["width"], table.remove(textHeights, 1),
        nil, nil, element["alignment"])
    elseif elemType == "orderedlist" or elemType == "unorderedlist" then
      gfx.drawTextInRect(table.remove(processedLists, 1), self.leftPadding + FEWATSU_LISTINDENT, currentElementY,
        FEWATSU_WIDTH - FEWATSU_LISTINDENT - self.rightPadding - self.leftPadding, table.remove(textHeights, 1))
    elseif elemType == "quote" then
      local textHeight = table.remove(textHeights, 1)
      local radius = 4
      local rect = pd.geometry.rect.new(self.leftPadding + self.quoteBoxPadding, currentElementY + 5,
        FEWATSU_WIDTH - (self.quoteBoxPadding * 2) - (self.leftPadding + self.rightPadding), textHeight + 4)

      gfx.drawRoundRect(rect, radius)

      rect.y = rect.y + 2

      gfx.drawTextInRect(element["text"], rect, nil, nil, kTextAlignment.center)

      if element["radius"] then
        radius = element["radius"]
      end
    elseif elemType == "image" then
      local img
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

      imgpath = getExistentPath(self.cwd, imgpath .. ".pdi")

      if imgpath ~= nil then
        img = gfx.image.new(imgpath)

        img = img:scaledImage(scale, yscale)
      else
        img = generateImageNotFoundImage(element["source"])
      end

      img:draw(element["x"], currentElementY)

      table.insert(self.imgXs, element["x"])
      table.insert(self.imgYs, currentElementY)
      table.insert(self.imgWidths, img.width)
      table.insert(self.imgHeights, img.height)
      table.insert(self.imgPaths, imgpath)
      table.insert(self.imgCaptions, element["caption"])
    elseif elemType == "link" then
      gfx.drawTextInRect(element["text"], element["x"], currentElementY, element["width"], table.remove(textHeights, 1),
        nil,
        nil, element["alignment"], self.linkFont)
    elseif elemType == "break" then
      if element["visible"] ~= false then
        gfx.setLineWidth(2)
        gfx.drawLine(FEWATSU_X + self.leftPadding + 20, currentElementY, FEWATSU_WIDTH - self.rightPadding - 20,
          currentElementY)
        gfx.setLineWidth(1)
      end
    end
  end

  gfx.popContext()

  return self.image
end

---Updates Fewatsu and draws it to the screen if needed.
---
---If `force` is true, draw to the screen no matter what.
---
---@param force boolean
function Fewatsu:update(force)
  local oldOffset = self.offset
  pd.timer.updateTimers()

  if self.preUpdate then
    self.preUpdate()
  end

  local selectableObjects = {}

  if self.inputDelayTimer == nil or self.inputDelayTimer.timeLeft == 0 then
    if self.image.height >= 240 then
      if pd.buttonIsPressed("down") then
        self.offset = self.offset + 10
      elseif pd.buttonIsPressed("up") then
        self.offset = self.offset - 10
      end

      local chg, achg = pd.getCrankChange()

      self.offset = self.offset + chg

      if self.offset < 0 then
        self.offset = 0
      elseif self.offset > self.image.height - 240 then
        self.offset = self.image.height - 240
      end
    end

    if pd.buttonJustPressed("a") then
      if self.selectedObject ~= nil and self.selectedObject ~= 0 then
        local obj = self.selectedObject

        if obj["type"] == "link" then
          local location = obj["location"]

          if location[1] ~= nil then
            local decodedFile
            local path = getExistentPath(self.cwd, location[1])

            if path == nil then
              path = getExistentPath(self.cwd, location[1] .. ".json")
            end

            if path ~= nil then
              decodedFile = json.decodeFile(path)
            else
              local ids = {}
              for i, v in ipairs(pd.file.listFiles(self.cwd)) do
                local dc = json.decodeFile(self.cwd .. v)

                if dc ~= nil then
                  if (dc["id"] == location[1] and string.sub(location[1], #location[1] - 4) ~= ".json") or (v == location[1] or self.cwd .. v == location[1]) then
                    decodedFile = dc
                    break
                  end
                end
              end
            end

            if decodedFile == nil then
              error("couldn't load file with id " .. location[1] .. " in directory " .. self.cwd)
            end

            self:load(decodedFile)

            force = true
          end

          if location[2] ~= nil then
            if location[2] == "#top" then
              self.offset = 0
            elseif location[2] == "#bottom" then
              self.offset = self.image.height - 240
            else
              if self.image.height > 240 then
                self.offset = self.headerYs[location[2]]

                if self.offset > self.image.height - 240 then
                  self.offset = self.image.height - 240
                end
              end
            end
          end

          if oldOffset ~= self.offset then
            self.offsetAnimator = gfx.animator.new(self.animatorEaseTime, oldOffset, self.offset,
              self.animatorEaseFunction)
          end
        elseif obj["type"] == "image" then
          if obj["path"] ~= nil then
            fewatsu_imageViewer.open(gfx.image.new(obj["path"]), obj["caption"], function()
              self.inputDelayTimer = pd.timer.new(10)

              self:update(true)
            end)
          end
        end
      end
    elseif pd.buttonJustPressed("b") then
      local menuOptions = {}

      for k, v in pairs(self.titlesToPaths) do
        table.insert(menuOptions, k)
      end

      table.sort(menuOptions)

      fewatsu_menu.open(table.indexOfElement(menuOptions, self.title), menuOptions, function(item)
        if item == fewatsu_menu.EXIT_ITEM_TEXT then
          self:hide()
        elseif item ~= nil then
          self:loadFile(self.titlesToPaths[item])
        end

        self.inputDelayTimer = pd.timer.new(10)

        self:update(true)
      end)
      -- self:hide()
    end
  end

  if self.offsetAnimator ~= nil and self.offsetAnimator:ended() == false then
    self.offset = self.offsetAnimator:currentValue()
  end

  if force or self.offset ~= oldOffset then
    gfx.clear()
    self.image:draw(0, 0 - self.offset)

    self.selectedObject = nil

    for i, v in ipairs(self.linkYs) do
      if v - self.offset < 120 and v - self.offset > -120 then
        table.insert(selectableObjects, {
          type = "link",
          i = i,
          y = v,
          location = self.linkLocations[i]
        })
      end
    end

    for i, v in ipairs(self.imgYs) do
      if v - self.offset < 120 and v - self.offset > -120 then
        table.insert(selectableObjects, {
          type = "image",
          i = i,
          y = v,
          path = self.imgPaths[i],
          caption = self.imgCaptions[i]
        })
      end
    end

    table.sort(selectableObjects, function(a, b)
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
        gfx.drawRoundRect(self.linkXs[closest["i"]], closest["y"] - self.offset, self.linkWidths[closest["i"]], self.linkHeights[closest["i"]], 2)
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
  end

  if self.postUpdate then
    self.postUpdate()
  end

  -- pd.drawFPS(380, 220)
end

---Displays Fewatsu.
---
---Executing this function replaces the current `playdate.update` function, pushes new input handlers, and changes the display refresh rate. To restore, call `Fewatsu:hide()`.
---
---@return nil
function Fewatsu:show()
  self.offset = 0

  self.originalRefreshRate = pd.display.getRefreshRate()

  pd.display.setRefreshRate(50)

  pd.inputHandlers.push(self, true)
  self.oldUpdate = pd.update
  pd.update = function() self.update(self) end

  self.inputDelayTimer = pd.timer.new(10)

  self:update(true)
end

---Hides Fewatsu, restoring the original `playdate.update()` function and input handlers.
---
---@return nil
function Fewatsu:hide()
  pd.inputHandlers.pop()
  pd.update = self.oldUpdate

  pd.display.setRefreshRate(self.originalRefreshRate)

  if self.callback then
    self.callback()
  end
end

---Shorthand function for loading a JSON file into Fewatsu.
---
---@param file string
function Fewatsu:loadFile(file)
  local path = getExistentPath(self.cwd, file)

  if path ~= nil then
    self:load(json.decodeFile(path))
  else
    error("could not load file " .. file)
  end
end

---Sets the current working directory. Fewatsu can use this to call for images and JSON files without using the absolute path.
---
---Returns `true` on success, `false` on failure.
---
---@param dir string
---@return boolean
function Fewatsu:setCurrentWorkingDirectory(dir)
  self.titlesToPaths = {}

  if pd.file.exists(dir) then
    self.cwd = dir

    for i, v in ipairs(pd.file.listFiles(self.cwd)) do
      if string.sub(v, #v - 4) == ".json" then
        local fileData = json.decodeFile(self.cwd .. v)

        self.titlesToPaths[fileData["title"]] = self.cwd .. v
      end
    end

    return true
  else
    return false
  end
end

---Returns the current working directory.
---
---@return string
function Fewatsu:getCurrentWorkingDirectory()
  return self.cwd
end

---Sets the time it takes to scroll to a new manual page offset.
---
---Defaults to `350`.
---
---@param ms number
function Fewatsu:setScrollDuration(ms)
  self.animatorEaseTime = ms
end

---Sets a different easing function which will be used instead of the default when scrolling to a new manual page offset. Can be any `playdate.easingFunction`.
---
---Defaults to `playdate.easingFunctions.outExpo`.
---
---@param func function
function Fewatsu:setScrollEasingFunction(func)
  self.animatorEaseFunction = func
end

---Sets the function to be called when Fewatsu has completed its `:hide()` function.
---
---@param callback function
function Fewatsu:setCallback(callback)
  self.callback = callback
end

---Sets the function that is called before any processing happens in `Fewatsu:update()`.
---
---@param func function
function Fewatsu:setPreUpdate(func)
  self.preUpdate = func
end

---Sets the function that is called after all processing in `Fewatsu:update()`.
---
---@param func function
function Fewatsu:setPostUpdate(func)
  self.postUpdate = func
end

---Sets the font used for plaintext.
---
---@param font playdate.graphics.font
function Fewatsu:setFont(font)
  self.font = font
end

---Sets the font used for heading text.
---
---@param font playdate.graphics.font
function Fewatsu:setHeadingFont(font)
  self.headingFont = font
end

---Sets the font used for subheading text.
---
---@param font playdate.graphics.font
function Fewatsu:setSubheadingFont(font)
  self.subheadingFont = font
end

---Sets the font used for bold text.
---
---@param font playdate.graphics.font
function Fewatsu:setBoldFont(font)
  self.boldFont = font
end

---Sets the font used for italic text.
---
---@param font playdate.graphics.font
function Fewatsu:setItalicFont(font)
  self.italicFont = font
end

---Sets the font used for title text.
---
---@param font playdate.graphics.font
function Fewatsu:setTitleFont(font)
  self.titleFont = font
end

---Sets the font used for link text.
---
---@param font playdate.graphics.font
function Fewatsu:setLinkFont(font)
  self.linkFont = font
end

---Sets the text shown at the top of the menu.
---
---Defaults to `Fewatsu`.
---
---@param title string
function Fewatsu:setMenuTitle(title)
  fewatsu_menu.titleItemText = title
end

---Sets the menu width.
---
---Defaults to `120`.
---
---@param title string
function Fewatsu:setMenuWidth(width)
  fewatsu_menu.width = width
end

function Fewatsu:setMenuEaseDuration(ms)
  fewatsu_menu.easeTime = ms
end

function Fewatsu:setMenuEasingFunction(func)
  fewatsu_menu.easeFunc = func
end
