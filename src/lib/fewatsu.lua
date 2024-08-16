-- fewatsu lib by nanobot567

import "CoreLibs/animator"
import "CoreLibs/object"
import "CoreLibs/timer"
import "CoreLibs/ui"
import "CoreLibs/qrcode"

import "fewatsu/funcs"
import "fewatsu/imageViewer"
import "fewatsu/menu"
import "fewatsu/animatedImage"
import "fewatsu/loadScreen"

local pd <const> = playdate
local gfx <const> = playdate.graphics
local playdateMenu <const> = playdate.getSystemMenu()

local BLANK_INPUT_HANDLERS = {
  AButtonDown = function() end,
  BButtonDown = function() end,
  upButtonDown = function() end,
  downButtonDown = function() end,
  rightButtonDown = function() end,
  leftButtonDown = function() end
}

local FEWATSU_LIB_PATH = getScriptPath()

local FEWATSU_X = 0
local FEWATSU_WIDTH = 400
local FEWATSU_LISTINDENT = 20

local FEWATSU_DEFAULT_DATA = json.decodeFile(FEWATSU_LIB_PATH .. "/fewatsu/pages/default.json")

---@class Fewatsu
---@field private selectedObject number
---@field private offset number
---@field private offsetAnimator playdate.graphics.animator
---@field private inputDelayTimer playdate.timer
---@field private titlesToPaths table
---@field private title string
---@field private path string
---@field private elements table
---@field private linkXs table
---@field private linkYs table
---@field private linkWidths table
---@field private linkHeights table
---@field private linkLocations table
---@field private imgXs table
---@field private imgYs table
---@field private imgWidths table
---@field private imgHeights table
---@field private imgPaths table
---@field private imgCaptions table
---@field private originalRefreshRate number
---@field private originalDisplayInvertedMode number
---@field private animatedImages table
---@field font playdate.graphics.font|_Font The font used for drawing plaintext.
---@field headingFont playdate.graphics.font|_Font The font used for drawing headings.
---@field subheadingFont playdate.graphics.font|_Font The font used for drawing subheadings.
---@field boldFont playdate.graphics.font|_Font The font used for drawing bold text.
---@field italicFont playdate.graphics.font|_Font The font used for drawing italic text.
---@field titleFont playdate.graphics.font|_Font The font used for drawing titles.
---@field linkFont playdate.graphics.font|_Font The font used for drawing links.
---@field animatorEaseTime number The time it takes for Fewatsu to ease to a new document position.
---@field animatorEaseFunction function The function used when easing to a new document position.
---@field leftPadding number The amount to pad the left side of the document when generating.
---@field rightPadding number The amount to pad the right side of the document when generating.
---@field topPadding number The amount to pad the top of the document when generating.
---@field quoteBoxPadding number The amount to pad the left and right side of quote boxes.
---@field darkMode boolean
---@field preUpdate function The function which will be called before any processing is done in `Fewatsu:update()`.
---@field postUpdate function The function which will be called after all processing is done in `Fewatsu:update()`.
---@field callback function The function which will be called after `Fewatsu:hide()` has completed execution.
---@field cwd string Fewatsu current working directory.
Fewatsu = {}

class("Fewatsu").extends()

---Initializes a new Fewatsu instance at `workingDirectory` and loads the default document.
---
---Default path is `manual/`.
---
---@param workingDirectory? string
---@return Fewatsu
function Fewatsu:init(workingDirectory)
  self.font = gfx.getSystemFont()
  self.headingFont = gfx.font.new(FEWATSU_LIB_PATH .. "fewatsu/fnt/Sasser-Slab-Bold")
  self.subheadingFont = gfx.font.new(FEWATSU_LIB_PATH .. "fewatsu/fnt/Sasser-Slab")
  self.boldFont = gfx.getSystemFont(gfx.font.kVariantBold)
  self.italicFont = gfx.getSystemFont(gfx.font.kVariantItalic)
  self.titleFont = gfx.font.new(FEWATSU_LIB_PATH .. "fewatsu/fnt/Asheville-Sans-24-Light")
  self.linkFont = self.boldFont

  self.selectedObject = 0

  self.offset = 0

  self.shown = false

  self.offsetAnimator = nil
  self.animatorEaseTime = 350
  self.animatorEaseFunction = pd.easingFunctions.outExpo

  self.menuAnimator = gfx.animator.new(0, self.menuWidth, self.menuWidth)
  self.menuAutoItemAdd = true
  self.menuItems = {}

  self.inputDelayTimer = nil

  self.leftPadding = 4
  self.rightPadding = 4
  self.topPadding = 4

  self.quoteBoxPadding = 30

  self.titlesToPaths = {}

  self.title = ""
  self.path = ""

  self.elements = {}
  self.cachedQRCodes = {}

  self.darkMode = false

  self.allowInput = true

  self.preUpdate = nil
  self.postUpdate = nil
  self.callback = nil

  self.displayLoadingScreen = true
  self.loadingScreenText = true
  self.loadingScreenTextAlignment = kTextAlignment.right
  self.loadingScreenSpinner = true

  self.backgroundMusic = pd.sound.fileplayer.new(FEWATSU_LIB_PATH .. "fewatsu/snd/bgm")
  self.backgroundMusicVolume = 0.1
  self.backgroundMusicFadeTime = 1
  self.playBGM = true

  self.soundClick = pd.sound.sampleplayer.new(FEWATSU_LIB_PATH .. "fewatsu/snd/click")
  self.soundSelect = pd.sound.sampleplayer.new(FEWATSU_LIB_PATH .. "fewatsu/snd/select")
  self.soundMenuOpen = pd.sound.sampleplayer.new(FEWATSU_LIB_PATH .. "fewatsu/snd/menu_open")

  self.displayScrollbar = true

  self.scrollbarBackgroundImage = gfx.image.new(FEWATSU_LIB_PATH .. "fewatsu/img/scrollbar-bg")
  self.scrollbarSmallImage = gfx.image.new(FEWATSU_LIB_PATH .. "fewatsu/img/scrollbar-small")
  self.scrollbarAnimator = gfx.animator.new(0, 0, 0)
  self.scrollbarShownTimer = pd.timer.new(0)
  self.scrollbarTimeout = 750

  self.scrollbarTimerEndedCallback = function()
    self.scrollbarAnimator = gfx.animator.new(100, 20, 0)
    pd.timer.performAfterDelay(90, function()  -- FIX
      self:update(true)
      pd.display.flush()
    end)
  end

  if not workingDirectory then
    if pd.file.exists("manual/") then
      workingDirectory = "manual/"
    else
      workingDirectory = ""
    end
  end

  self:setCurrentWorkingDirectory(workingDirectory)

  self:load(FEWATSU_DEFAULT_DATA)

  return self
end

---Parses the given table (if valid) and sets the current manual page to the image generated. Refer to the Fewatsu FORMAT.md doc for more information.
---
---@param data table
---@return playdate.image
function Fewatsu:load(data)
  self.allowInput = false

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

  self.qrCodes = {}

  if self.animatedImages then
    for k, v in pairs(self.animatedImages) do
      v:destroy()
    end
  end

  self.animatedImages = {}

  self.scrollbarShownTimer:remove()
  self.scrollbarAnimator = gfx.animator.new(0, 0, 0)
  self.scrollbarShownTimer = pd.timer.new(0)

  self.headerYs = {}

  self.offset = 0

  self.elements = {}

  local currentY = self.topPadding
  local elements = data["data"]
  local elementYs = {}
  local textHeights = {}
  local processedLists = {}
  local elemType = ""

  self.title = data["title"]

  for i, element in ipairs(elements) do -- preprocessing for string elements
    if type(element) == "string" then
      elements[i] = {}
      elements[i].type = "text"
      elements[i].text = element
    end
  end

  if self.shown and self.displayLoadingScreen then
    fewatsu_loadScreen.init(self)
  end

  self.elements = elements

  for i, element in ipairs(elements) do
    if self.shown and self.displayLoadingScreen then
      fewatsu_loadScreen.step("parsing " .. element["type"] .. "...")
    end

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
    elseif elemType == "list" then
      local temp = {}
      local text = ""

      if element["ordered"] == true then
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
    elseif elemType == "quote" then -- TODO: maybe needs fixing for larger text padding
      local textw, texth = gfx.getTextSizeForMaxWidth(element["text"],
        FEWATSU_WIDTH - (self.quoteBoxPadding * 2) - (self.rightPadding + self.leftPadding) - 8)

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
      else
        imgpath = getExistentPath(self.cwd, element["source"] .. ".pdt")

        if imgpath == nil then
          img = generateImageNotFoundImage(element["source"])

          scale = 1
        else
          if self.shown and self.displayLoadingScreen then
            fewatsu_loadScreen.step("loading animated image, please wait...")
          end

          self.animatedImages[currentY] = AnimatedImage(imgpath, element["scale"], element["delay"])

          img = self.animatedImages[currentY]:getCurrentFrame()

          scale = 1
        end
      end

      if imgpath ~= nil then
        img = img:scaledImage(scale, yscale)
      end

      currentY = currentY + img.height * scale + 20
    elseif elemType == "link" then
      local textw, texth = gfx.getTextSizeForMaxWidth(element["text"],
        FEWATSU_WIDTH - (self.rightPadding + self.leftPadding), nil, self.linkFont)

      table.insert(textHeights, texth)

      local x = FEWATSU_X + self.leftPadding - 3

      if element["alignment"] == "right" then
        x = FEWATSU_WIDTH - textw - self.rightPadding - 3
      end

      table.insert(self.linkXs, x) -- TODO: allow custom x and y positions
      table.insert(self.linkYs, currentY - 2)
      table.insert(self.linkWidths, textw + 6)
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
      if not element["linewidth"] then
        element["linewidth"] = 2
      end

      currentY = currentY + 20 + element["linewidth"]
    elseif elemType == "qr" then
      local waitingForQR = true

      if self.cachedQRCodes[element["data"]] then
        if self.shown and self.displayLoadingScreen then
          fewatsu_loadScreen.step("using cached qr code...")
          pd.display.flush()
        end

        table.insert(self.qrCodes, self.cachedQRCodes[element["data"]])

        currentY = currentY + self.qrCodes[#self.qrCodes].height + 10
      else
        if self.shown and self.displayLoadingScreen then
          fewatsu_loadScreen.step("generating qr code...")
          pd.display.flush()
        end

        gfx.generateQRCode(element["data"], element["desiredEdgeDimension"], function(qrcode)
          waitingForQR = false

          table.insert(self.qrCodes, qrcode)

          if not self.cachedQRCodes[element["data"]] then
            self.cachedQRCodes[element["data"]] = qrcode:copy()
          end

          currentY = currentY + qrcode.height + 10
        end)

        while waitingForQR do
          pd.timer.updateTimers()
        end
      end
    end

    if elements[i + 1] then
      if elements[i + 1]["type"] == "break" then
        currentY = currentY + 10
      end
    end
  end

  if self.shown and self.displayLoadingScreen then
    fewatsu_loadScreen.step("pushing document image context...")
  end

  local currentElementY = 0

  self.documentImage = gfx.image.new(400, currentY + 10)

  gfx.pushContext(self.documentImage)

  gfx.setFont(self.font, gfx.font.kVariantNormal)
  gfx.setFont(self.boldFont, gfx.font.kVariantBold)
  gfx.setFont(self.italicFont, gfx.font.kVariantItalic)

  local origColor = gfx.getColor()
  local color = gfx.kColorBlack
  local imageDrawMode = gfx.kDrawModeCopy
  local altColor = gfx.kColorWhite

  gfx.clear(gfx.kColorWhite)

  if self.darkMode then
    color = gfx.kColorWhite
    altColor = gfx.kColorBlack
    imageDrawMode = gfx.kDrawModeInverted
    gfx.clear(gfx.kColorBlack)
  end

  gfx.setColor(color)
  gfx.setImageDrawMode(imageDrawMode)

  for elementI, element in ipairs(elements) do -- draw
    elemType = element["type"]
    currentElementY = table.remove(elementYs, 1)

    if self.shown and self.displayLoadingScreen then
      gfx.popContext()
      fewatsu_loadScreen.step("drawing " .. elemType .. " @ " .. math.floor(currentElementY) .. "...")
      gfx.pushContext(self.documentImage)

      gfx.setColor(color)
      gfx.setImageDrawMode(imageDrawMode)
    end

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
    elseif elemType == "image" then
      if element["x"] == nil then
        element["x"] = FEWATSU_X
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
    elseif elemType == "list" then
      gfx.drawTextInRect(table.remove(processedLists, 1), self.leftPadding + FEWATSU_LISTINDENT, currentElementY,
        FEWATSU_WIDTH - FEWATSU_LISTINDENT - self.rightPadding - self.leftPadding, table.remove(textHeights, 1))
    elseif elemType == "quote" then
      local textHeight = table.remove(textHeights, 1)
      local radius = 4
      local rect = pd.geometry.rect.new(self.leftPadding + self.quoteBoxPadding, currentElementY + 5,
        FEWATSU_WIDTH - (self.quoteBoxPadding * 2) - (self.leftPadding + self.rightPadding), textHeight + 4)

      gfx.drawRoundRect(rect, radius)

      rect.x = rect.x + 4
      rect.y = rect.y + 4
      rect.width = rect.width - 8

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
        imgpath = getExistentPath(self.cwd, element["source"] .. ".pdt")

        if imgpath == nil then
          img = generateImageNotFoundImage(element["source"])
        else
          img = self.animatedImages[currentElementY]:getCurrentFrame()
        end
      end

      local oldDrawMode = gfx.getImageDrawMode()
      gfx.setImageDrawMode(gfx.kDrawModeCopy)

      img:draw(element["x"], currentElementY)

      gfx.setImageDrawMode(oldDrawMode)

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
        if not element["linewidth"] then
          element["linewidth"] = 2
        end

        gfx.setLineWidth(element["linewidth"])
        gfx.drawLine(FEWATSU_X + self.leftPadding + 20, currentElementY, FEWATSU_WIDTH - self.rightPadding - 20,
          currentElementY)
        gfx.setLineWidth(1)
      end
    elseif elemType == "qr" then
      local img = table.remove(self.qrCodes, 1)

      if element["alignment"] == "center" then
        img:draw(200 - (img.width / 2), currentElementY)
      elseif element["alignment"] == "right" then
        img:draw(400 - self.rightPadding - img.width, currentElementY)
      else
        img:draw(0, currentElementY)
      end
    end
  end

  gfx.popContext()

  self.allowInput = true

  return self.documentImage
end

local scrollbarY = 0
local selectableObjects = {}
local visibleObjects = {}

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

  if self.inputDelayTimer == nil or self.inputDelayTimer.timeLeft == 0 then
    if self.documentImage.height >= 240 then
      if pd.buttonIsPressed("down") and self.allowInput then
        self.offset = self.offset + 10
      elseif pd.buttonIsPressed("up") and self.allowInput then
        self.offset = self.offset - 10
      end

      local chg, achg = pd.getCrankChange()

      self.offset = self.offset + chg

      if self.offset < 0 then
        self.offset = 0
      elseif self.offset > self.documentImage.height - 240 then
        self.offset = self.documentImage.height - 240
      end
    end

    if pd.buttonJustPressed("a") and self.allowInput then
      if self.selectedObject ~= nil and self.selectedObject ~= 0 then
        self.soundClick:play()

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
              self.offset = self.documentImage.height - 240
            else
              if self.documentImage.height > 240 then
                self.offset = self.headerYs[location[2]] - 4

                if self.offset > self.documentImage.height - 240 then
                  self.offset = self.documentImage.height - 240
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
    elseif pd.buttonJustPressed("b") and self.allowInput then
      local menuItemIndex = 1
      local menuOptions = {}

      if self.menuAutoItemAdd then
        for i, v in ipairs(pd.file.listFiles(self.cwd)) do
          if string.sub(v, #v - 4) == ".json" then
            local fileJSON = json.decodeFile(self.cwd .. v)

            table.insert(menuOptions, {
              path = self.cwd .. v,
              pageTitle = fileJSON["title"]
            })
          end
        end

        table.sort(menuOptions, function(a, b)
          return a["pageTitle"] < b["pageTitle"]
        end)
      else
        menuOptions = self.menuItems
      end

      self.scrollbarShownTimer:pause()

      for i, v in ipairs(menuOptions) do
        if v["path"] == self.path then
          menuItemIndex = i
          break
        end
      end

      fewatsu_menu.open(self, menuItemIndex, menuOptions, function(item)
        self.inputDelayTimer = pd.timer.new(10)

        if item == fewatsu_menu.EXIT_ITEM_TEXT then
          self:hide()
        elseif item ~= nil and item ~= self.path then
          self:loadFile(item)
        end

        self.scrollbarShownTimer:start()

        self:update(true)
      end)
    end
  end

  if self.offsetAnimator ~= nil and self.offsetAnimator:ended() == false then
    self.offset = self.offsetAnimator:currentValue()
  end

  if force or self.offset ~= oldOffset or pd.buttonJustPressed("right") or pd.buttonJustPressed("left") or not self.scrollbarAnimator:ended() then
    if self.darkMode then
      gfx.clear(gfx.kColorBlack)
    else
      gfx.clear(gfx.kColorWhite)
    end
    self.documentImage:draw(0, 0 - self.offset)
  end

  for k, v in pairs(self.animatedImages) do
    if k - self.offset < v:getCurrentFrame().height and k - self.offset > -v:getCurrentFrame().height then
      v:update()
      v:getCurrentFrame():draw(0, k - self.offset)
    end
  end

  if force or self.offset ~= oldOffset or pd.buttonJustPressed("right") or pd.buttonJustPressed("left") or not self.scrollbarAnimator:ended() then
    selectableObjects = {}
    visibleObjects = {}

    for i, v in ipairs(self.linkYs) do
      if v - self.offset < 120 and v - self.offset > -120 then
        table.insert(selectableObjects, {
          type = "link",
          i = i,
          y = v,
          location = self.linkLocations[i]
        })
      end

      if v - self.offset < 220 and v - self.offset > -20 then
        table.insert(visibleObjects, {
          type = "link",
          i = i,
          y = v,
          location = self.linkLocations[i]
        })
      end
    end

    for i, v in ipairs(self.imgYs) do
      if not table.indexOfElement(table.getKeys(self.animatedImages), v) then
        if v - self.offset < 120 and v - self.offset > -120 then
          table.insert(selectableObjects, {
            type = "image",
            i = i,
            y = v,
            path = self.imgPaths[i],
            caption = self.imgCaptions[i]
          })
        end

        if v - self.offset < 220 and v - self.offset > -20 then
          table.insert(visibleObjects, {
            type = "image",
            i = i,
            y = v,
            path = self.imgPaths[i],
            caption = self.imgCaptions[i]
          })
        end
      end
    end

    table.sort(selectableObjects, function(a, b)
      return a["y"] < b["y"]
    end)

    table.sort(visibleObjects, function(a, b)
      return a["y"] < b["y"]
    end)

    local selected
    local passed = false -- better variable name for this lol
    local drawSelector = false

    if #selectableObjects ~= 0 then
      if pd.buttonJustPressed("left") and self.allowInput then
        local index = 0
        for i, v in ipairs(visibleObjects) do
          if v["y"] == self.selectedObject["y"] then
            index = i
            break
          end
        end

        if index - 1 == 0 then
          selected = table.deepcopy(visibleObjects[1])

          passed = true
        elseif index - 1 > 0 then
          selected = table.deepcopy(visibleObjects[index - 1])

          passed = true
        end
      elseif pd.buttonJustPressed("right") and self.allowInput then
        local index = 0
        for i, v in ipairs(visibleObjects) do
          if v["y"] == self.selectedObject["y"] then
            index = i
            break
          end
        end

        if index + 1 > #visibleObjects then
          if visibleObjects[#visibleObjects] then
            selected = table.deepcopy(visibleObjects[#visibleObjects])

            passed = true
          end
        elseif index ~= 0 and index + 1 <= #visibleObjects then
          if visibleObjects[index + 1] then
            selected = table.deepcopy(visibleObjects[index + 1])

            passed = true
          end
        end
      end

      if not passed then
        selected = selectableObjects[1]

        for i, v in pairs(selectableObjects) do
          if math.abs(v["y"] - self.offset - 120) < selected["y"] then
            selected = table.deepcopy(v)
          end
        end
      end

      self.selectedObject = selected

      drawSelector = true
    elseif self.documentImage.height - 20 >= self.offset and self.offset <= self.documentImage.height + 20 then
      selected = visibleObjects[#visibleObjects]

      self.selectedObject = selected

      drawSelector = true
    else
      self.selectedObject = nil
    end

    if drawSelector and selected then
      self:_drawObjectSelector(selected)
    end

    -- if (drawSelector or not self.scrollbarAnimator:ended()) and self.selectedObject then
    --   self:_drawObjectSelector(selected)
    -- end

    if self.documentImage.height > 240 then
      scrollbarY = (math.abs(1 - ((self.documentImage.height - self.offset - 240) / (self.documentImage.height - 240))) * (240 - self.scrollbarSmallImage.height))
    else
      scrollbarY = 0
    end

    if oldOffset ~= self.offset and math.abs(self.offset - oldOffset) > 3 then
      if self.scrollbarAnimator:currentValue() == 0 and self.scrollbarShownTimer.timeLeft == 0 then
        self.scrollbarAnimator = gfx.animator.new(100, 0, 20)
      end

      self.scrollbarShownTimer:remove()
      self.scrollbarShownTimer = pd.timer.new(self.scrollbarTimeout, self.scrollbarTimerEndedCallback)

      -- print(self.scrollbarShownTimer:currentValue(), pd.getCurrentTimeMilliseconds())
    end
  end

  if self.documentImage.height > 240 then
    self.scrollbarBackgroundImage:draw(400 - self.scrollbarAnimator:currentValue(), 0)
    self.scrollbarSmallImage:draw(400 - self.scrollbarAnimator:currentValue(), scrollbarY)
  end

  if self.postUpdate then
    self.postUpdate()
  end

  -- pd.drawFPS(380, 220)
end

function Fewatsu:_drawObjectSelector(selected)
  local origColor = gfx.getColor()

  gfx.setColor(gfx.kColorXOR)

  if selected["type"] == "link" then
    gfx.drawRoundRect(self.linkXs[selected["i"]], selected["y"] - self.offset, self.linkWidths[selected["i"]],
      self.linkHeights[selected["i"]], 2)
  elseif selected["type"] == "image" then
    local index = selected["i"]

    gfx.setLineWidth(3)
    gfx.drawRect(self.imgXs[index], self.imgYs[index] - self.offset, self.imgWidths[index], self.imgHeights[index])
    gfx.setLineWidth(1)
  end

  gfx.setColor(origColor)
end

---Displays Fewatsu.
---
---Executing this function replaces the current `playdate.update` function, pushes new input handlers, and changes the display refresh rate. To restore, call `:hide()`.
---
---All `playdate.menu` items will also be cleared. To restore these, set a callback function using `:setCallback()` containing instructions to restore the previous menu items.
---
---@return nil
function Fewatsu:show()
  self.offset = 0

  self.shown = true

  self.originalRefreshRate = pd.display.getRefreshRate()
  self.originalDisplayInvertedMode = pd.display.getInverted()

  pd.display.setRefreshRate(50)
  pd.display.setInverted(false)

  playdateMenu:removeAllMenuItems()

  playdateMenu:addMenuItem("about...", function()
    if fewatsu_menu.isOpen then
      fewatsu_menu.close()
    end
    self:loadFile(FEWATSU_LIB_PATH .. "/fewatsu/pages/about.json")
  end)

  playdateMenu:addMenuItem("help...", function()
    if fewatsu_menu.isOpen then
      fewatsu_menu.close()
    end
    self:loadFile(FEWATSU_LIB_PATH .. "/fewatsu/pages/help.json")
  end)

  self.inputDelayTimer = pd.timer.new(10)

  pd.inputHandlers.push(BLANK_INPUT_HANDLERS, true)
  self.oldUpdate = pd.update
  pd.update = function() self.update(self) end

  if self.playBGM then
    self.backgroundMusic:setVolume(0, 0)
    self.backgroundMusic:setVolume(self.backgroundMusicVolume, self.backgroundMusicVolume, self.backgroundMusicFadeTime)
    self.backgroundMusic:play(0)
  end

  self:update(true)
end

---Hides Fewatsu, restoring the original `playdate.update()` function and input handlers.
---
---@return nil
function Fewatsu:hide()
  pd.inputHandlers.pop()
  pd.update = self.oldUpdate

  pd.display.setRefreshRate(self.originalRefreshRate)
  pd.display.setInverted(self.originalDisplayInvertedMode)

  playdateMenu:removeAllMenuItems()

  if self.playBGM then
    self.backgroundMusic:setVolume(0, 0, self.backgroundMusicFadeTime, function(self)
      self:stop()
    end)
  end

  self.shown = false

  if self.callback then
    self.callback()
  end
end

---Shorthand function for loading a JSON file into Fewatsu.
---
---Returns the generated image.
---
---@param file string
---@return playdate.graphics.image
function Fewatsu:loadFile(file)
  local path = getExistentPath(self.cwd, file)
  if path ~= nil then
    self.path = path

    local decodedFile = json.decodeFile(path)

    if decodedFile then
      return self:load(decodedFile)
    end
  end
  error("could not load file " .. file)
end

---Sets the current working directory. Fewatsu can use this to call for images and JSON files without using the absolute path.
---
---By default, the working directory is set to `/manual/`.
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
---Defaults to `350`ms.
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

---Sets the function that is called before any processing happens in `:update()`.
---
---@param func function
function Fewatsu:setPreUpdate(func)
  self.preUpdate = func
end

---Sets the function that is called after all processing in `:update()`.
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
---Defaults to `120`px.
---
---@param width number
function Fewatsu:setMenuWidth(width)
  fewatsu_menu.width = width
end

---Sets the time it takes for the menu to ease in.
---
---Defaults to `350`ms.
---
---@param ms number
function Fewatsu:setMenuEaseDuration(ms)
  fewatsu_menu.easeTime = ms
end

---Sets a different easing function which will be used instead of the default when animating the menu slide-in. Can be any `playdate.easingFunction`.
---
---Defaults to `playdate.easingFunctions.outExpo`.
---
---@param func function
function Fewatsu:setMenuEasingFunction(func)
  fewatsu_menu.easeFunc = func
end

---Sets the amount to pad both sides of the Fewatsu document.
---
---Shorthand function for `:setLeftPadding()` and `:setRightPadding()`.
---
---Defaults to `4`px.
---
---@param px number
function Fewatsu:setPadding(px)
  self.leftPadding = px
  self.rightPadding = px
end

---Sets the amount to pad the top of the Fewatsu document.
---
---Defaults to `4`px.
---
---@param px number
function Fewatsu:setTopPadding(px)
  self.topPadding = px
end

---Sets the pixel amount to pad the left side of the Fewatsu viewing area.
---
---Defaults to `4`px.
---
---@param px number
function Fewatsu:setLeftPadding(px)
  self.leftPadding = px
end

---Sets the pixel amount to pad the right side of the Fewatsu viewing area.
---
---Defaults to `4`px.
---
---@param px number
function Fewatsu:setRightPadding(px)
  self.rightPadding = px
end

---Sets the pixel amount to pad the right and left side of quote boxes.
---
---Defaults to `30`px.
---
---@param px number
function Fewatsu:setQuoteBoxPadding(px)
  self.quoteBoxPadding = px
end

---Set if dark theme should be used. Doesn't apply to images, and is only applied on `:load()`.
---
---Defaults to `false`.
---
---@param mode boolean
function Fewatsu:setDarkMode(mode)
  self.darkMode = mode
end

---Sets the sound that will be played when the A button is pressed.
---
---@param sound playdate.sound.sampleplayer
function Fewatsu:setClickSound(sound)
  self.soundClick = sound
end

---Sets the sound that will be played in the Fewatsu menu when `up` or `down` is pressed.
---
---@param sound playdate.sound.sampleplayer
function Fewatsu:setSelectSound(sound)
  self.soundSelect = sound
end

---Sets the sound that will be played when the Fewatsu menu is opened or closed.
---
---@param sound playdate.sound.sampleplayer
function Fewatsu:setMenuSound(sound)
  self.soundMenuOpen = sound
end

---Sets the background music that will play while Fewatsu is active.
---
---By default uses the file `FEWATSU_LIB_PATH/snd/bgm`.
---
---@param sound playdate.sound.fileplayer
function Fewatsu:setBGM(music)
  self.backgroundMusic = music
end

---Enables or disables background music.
---
---Defaults to `true`.
---
---@param status boolean
function Fewatsu:setEnableBGM(status)
  self.playBGM = status
end

---Sets the background music volume.
---
---Defaults to `0.1`.
---
---@param volume number
function Fewatsu:setBGMVolume(volume)
  self.backgroundMusicVolume = volume
end

---Sets the background music fade in/out time in seconds.
---
---Defaults to `1` second.
---
---@param fadetime number
function Fewatsu:setBGMFade(fadetime)
  self.backgroundMusicFadeTime = fadetime
end

---Sets if the scroll bar should be displayed when the user scrolls through the Fewatsu document.
---
---See `:setScrollBarBackgroundImage()` and `:setScrollBarImage()` to customize the scroll bar.
---
---Defaults to `true`.
---
---@param enable boolean
function Fewatsu:setEnableScrollBar(enable)
  self.displayScrollbar = enable
end

---Sets the amount of time after user input has stopped to retract the scroll bar.
---
---Defaults to `750`ms.
---
---@param ms any
function Fewatsu:setScrollBarTimeout(ms)
  self.scrollbarTimeout = ms
end

---Sets the image to use for the scroll bar.
---
---The image should be 20 pixels wide, and up to 160 pixels tall. For the best results, add two or so pixels of padding to every side of the image.
---
---@param image playdate.graphics.image
function Fewatsu:setScrollBarImage(image)
  self.scrollbarSmallImage = image
end

---Sets the image to use for the scroll bar background.
---
---The image should be 20 pixels wide and 240 pixels tall.
---
---@param image playdate.graphics.image
function Fewatsu:setScrollBarBackgroundImage(image)
  self.scrollbarBackgroundImage = image
end

---Enables or disables the automatic adding of pages to the Fewatsu menu.
---
---By default, the menu will add all of the valid Fewatsu JSON files in the current working directory.
---
---To customize the menu manually, see `:addMenuItem()`, `:removeMenuItem()` and `:clearMenuItems()`.
---
---@param enable boolean
function Fewatsu:setMenuAutoAdd(enable)
  self.menuAutoItemAdd = enable
end

---Adds a page to the Fewatsu menu.
---
---`path` can be either an absolute path to the file or the path from Fewatsu's current working directory. Looks for [path], then [path].json.
---
---`displayName` can be provided if you would like the item to have a different display name than the default (the page's title).
---
---@param path string
---@param displayName? string
function Fewatsu:addMenuItem(path, displayName)
  local origPath = path
  local path = getExistentPath(self.cwd, path)

  if path == nil then
    path = getExistentPath(self.cwd, origPath .. ".json")
  end

  if path ~= nil then
    local fileData = json.decodeFile(path)

    table.insert(self.menuItems, {
      pageTitle = fileData["title"],
      path = path,
      displayName = displayName
    })
  else
    error("could not load file at " .. path)
  end
end

---Sets if a loading screen should be displayed on document load and Fewatsu is currently shown.
---
---Please note that this reduces load times.
---
---Defaults to `true`.
---
---@param enable boolean
function Fewatsu:setEnableLoadingScreen(enable)
  self.displayLoadingScreen = enable
end

---Sets if loading screens should display text detailing the current action on the bottom of the screen.
---
---The loading screen must be enabled for this to take effect. See `:setEnableLoadingScreen()` for more details.
---
---Defaults to `true`.
---
---@param show boolean
function Fewatsu:setLoadingScreenShowText(show)
  self.loadingScreenText = show
end

---Sets how the loading screen bottom information text should be aligned. Can be any `kTextAlignment` or integer from 0 to 2.
---
---The loading screen must be enabled for this to take effect. See `:setEnableLoadingScreen()` for more details.
---
---Loading screen text must be enabled for this to take effect. See `:setLoadingScreenShowText()` for more details.
---
---Defaults to `kTextAlignment.right`.
---
---@param alignment integer
function Fewatsu:setLoadingScreenTextAlignment(alignment)
  self.loadingScreenTextAlignment = alignment
end

---Sets if loading screens should display a spinner in the center of the screen.
---
---The loading screen must be enabled for this to take effect. See `:setEnableLoadingScreen()` for more details.
---
---Defaults to `true`.
---
---@param show boolean
function Fewatsu:setLoadingScreenShowSpinner(show)
  self.loadingScreenSpinner = show
end

function Fewatsu:destroy() -- TODO: function that sets everything in this fewatsu instance to nil
  self = nil
end
