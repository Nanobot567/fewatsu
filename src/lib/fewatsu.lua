-- fewatsu lib by nanobot567

import "CoreLibs/animator"
import "CoreLibs/object"
import "CoreLibs/timer"
import "CoreLibs/ui"
import "CoreLibs/qrcode"

import "fewatsu/debug"
import "fewatsu/funcs"
import "fewatsu/imageViewer"
import "fewatsu/menu"
import "fewatsu/animatedImage"
import "fewatsu/loadScreen"
import "fewatsu/splash"

local dbg = fewatsu_debug
dbg.enabled = false

dbg.log("Hi! I'm the fewatsu debugger. It looks like I'm enabled! ^w^", "FEWATSU")

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
  self.animatorEaseTime = 400
  self.animatorEaseFunction = pd.easingFunctions.outExpo

  self.menuAnimator = gfx.animator.new(0, self.menuWidth, self.menuWidth)
  self.menuAutoItemAdd = true
  self.menuItems = {}

  self.inputDelayTimer = pd.timer.new(10)

  self.leftPadding = 4
  self.rightPadding = 4
  self.topPadding = 4

  self.quoteBoxPadding = 30

  self.customElements = {}

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

  self.showSplash = true
  self.splashText = "Fewatsu"
  self.splashFont = gfx.font.new(FEWATSU_LIB_PATH .. "fewatsu/fnt/Asheville-Sans-24-Light")
  self.splashBackground = nil

  self.playBGM = true
  self.backgroundMusic = pd.sound.fileplayer.new(FEWATSU_LIB_PATH .. "fewatsu/snd/bgm")
  self.backgroundMusicVolume = 0.2
  self.backgroundMusicFadeTime = 1

  self.playSFX = true
  self.soundClick = pd.sound.sampleplayer.new(FEWATSU_LIB_PATH .. "fewatsu/snd/click")
  self.soundSelect = pd.sound.sampleplayer.new(FEWATSU_LIB_PATH .. "fewatsu/snd/select")
  self.soundMenuOpen = pd.sound.sampleplayer.new(FEWATSU_LIB_PATH .. "fewatsu/snd/menu_open")

  self.displayScrollbar = true

  self.scrollbarBackgroundImage = gfx.image.new(FEWATSU_LIB_PATH .. "fewatsu/img/scrollbar-bg")
  self.scrollbarSmallImage = gfx.image.new(FEWATSU_LIB_PATH .. "fewatsu/img/scrollbar-small")
  self.scrollbarAnimator = gfx.animator.new(0, 0, 0)
  self.scrollbarShownTimer = pd.timer.new(0)
  self.scrollbarTimeout = 750
  self.scrollbarLockedObject = nil

  self.scrollbarTimerEndedCallback = function()
    if self.documentImage.height >= 240 and self.scrollbarAnimator:currentValue() == self.scrollbarBackgroundImage.width / 2 then
      self.scrollbarAnimator = gfx.animator.new(100, self.scrollbarBackgroundImage.width / 2, 0)
      self.scrollbarLockedObject = self.selectedObject
      pd.timer.performAfterDelay(90, function()
        self:update(true)
        pd.display.flush()
        self.scrollbarLockedObject = nil
      end)
    end
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

  self:clearAnimatedImageCache()

  self.scrollbarShownTimer:start()
  self.scrollbarShownTimer:remove()
  self.scrollbarAnimator = gfx.animator.new(0, 0, 0)
  self.scrollbarShownTimer = pd.timer.new(0)

  self.inputDelayTimer = pd.timer.new(10)

  self.headerYs = {}

  self.offset = 0

  self.elements = {}

  self.customElementYs = {}

  local currentY = self.topPadding
  local elements = data["data"]
  local elementYs = {}
  local textHeights = {}
  local processedLists = {}
  local elemType = ""
  local textw, texth

  self.title = data["title"]

  dbg.log("loading data, title " .. self.title, "load")

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
      local percent = math.floor((i / (#elements * 2)) * 100)
      fewatsu_loadScreen.step("parsing " .. element["type"] .. "...", percent)
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
      textw, texth = gfx.getTextSizeForMaxWidth(element["text"],
        FEWATSU_WIDTH - (self.rightPadding + self.leftPadding), nil, self.titleFont)

      table.insert(textHeights, texth)

      self.headerYs[string.lower(element["text"])] = currentY

      if not element["y"] then
        currentY = texth + 10
      end
    elseif elemType == "heading" then
      textw, texth = gfx.getTextSizeForMaxWidth(element["text"],
        FEWATSU_WIDTH - (self.rightPadding + self.leftPadding), nil, self.headingFont)

      table.insert(textHeights, texth)

      self.headerYs[string.lower(element["text"])] = currentY

      if not element["y"] then
        currentY = currentY + texth + 10
      end
    elseif elemType == "subheading" then
      textw, texth = gfx.getTextSizeForMaxWidth(element["text"],
        FEWATSU_WIDTH - (self.rightPadding + self.leftPadding), nil, self.subheadingFont)

      table.insert(textHeights, texth)

      self.headerYs[string.lower(element["text"])] = currentY

      if not element["y"] then
        currentY = currentY + texth + 10
      end
    elseif elemType == "text" then
      textw, texth = gfx.getTextSizeForMaxWidth(element["text"],
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

      textw, texth = gfx.getTextSizeForMaxWidth(text,
        FEWATSU_WIDTH - FEWATSU_LISTINDENT - (self.rightPadding + self.leftPadding))

      table.insert(textHeights, texth)

      currentY = currentY + texth + 10
    elseif elemType == "quote" then
      textw, texth = gfx.getTextSizeForMaxWidth(element["text"],
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

      imgpath = getExistentPath(self.cwd, imgpath, { ".pdi", ".pdt" })

      if imgpath ~= nil then
        if string.sub(imgpath, #imgpath - 3) == ".pdi" then
          img = gfx.image.new(imgpath)
        elseif string.sub(imgpath, #imgpath - 3) == ".pdt" then
          if self.shown and self.displayLoadingScreen then
            fewatsu_loadScreen.step("loading animated image, please wait...")
          end

          self.animatedImages[currentY] = AnimatedImage(imgpath, element["scale"], element["delay"],
            element["darkModeInvert"])

          img = self.animatedImages[currentY]:getCurrentFrame()
        end
      else
        img = generateImageNotFoundImage(element["source"])

        scale = 1
      end

      if imgpath ~= nil and string.sub(imgpath, #imgpath - 3) == ".pdi" then
        img = img:scaledImage(scale, yscale)
      end

      currentY = currentY + img.height * scale + 20
    elseif elemType == "link" then
      textw, texth = gfx.getTextSizeForMaxWidth(element["text"],
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
          local origInvert = pd.display.getInverted()

          pd.display.setInverted(true)
          fewatsu_loadScreen.step("generating qr code...")
          pd.display.flush()
          pd.display.setInverted(false)
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
    else
      for k, v in pairs(self.customElements) do
        if k == elemType then
          self.customElementYs[i] = currentY
          currentY = currentY + v["heightCalculationFunction"](element) + v["padding"]
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
      local percent = math.floor(((#elements + elementI) / (#elements * 2)) * 100)
      fewatsu_loadScreen.step("drawing " .. elemType .. " @ " .. math.floor(currentElementY) .. "...", percent)
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
    elseif elemType == "image" then
      if element["x"] == nil then
        element["x"] = FEWATSU_X
      end
    end

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

      imgpath = getExistentPath(self.cwd, imgpath, { ".pdi", ".pdt" })

      if imgpath ~= nil then
        if string.sub(imgpath, #imgpath - 3) == ".pdi" then
          img = gfx.image.new(imgpath)

          img = img:scaledImage(scale, yscale)
        elseif string.sub(imgpath, #imgpath - 3) == ".pdt" then
          img = self.animatedImages[currentElementY]:getCurrentFrame()
        end

        if self.darkMode and element["darkModeInvert"] then
          img = img:invertedImage()
        end
      else
        img = generateImageNotFoundImage(element["source"])
      end

      local oldDrawMode = gfx.getImageDrawMode()
      gfx.setImageDrawMode(gfx.kDrawModeCopy)

      if element["alignment"] == kTextAlignment.center then -- erm, it's not actually text :nerd:
        element["x"] = 200 - element["x"] - (img.width / 2)
      elseif element["alignment"] == kTextAlignment.right then
        element["x"] = 400 - element["x"] - img.width
      end

      img:draw(element["x"], currentElementY)

      gfx.setImageDrawMode(oldDrawMode)

      if imgpath == nil then
        imgpath = ""
      end

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

      if element["alignment"] == kTextAlignment.center then
        img:draw(200 - (img.width / 2), currentElementY)
      elseif element["alignment"] == kTextAlignment.right then
        img:draw(400 - self.rightPadding - img.width, currentElementY)
      else
        img:draw(0, currentElementY)
      end
    else
      for k, v in pairs(self.customElements) do
        if k == elemType and not v["drawEveryFrame"] then
          v["drawFunction"](currentElementY, element)
        end
      end
    end
  end

  gfx.popContext()

  if self.shown then
    pd.display.setInverted(false)
  end

  self.allowInput = true

  return self.documentImage
end

local scrollbarY = 0
local selectableObjects = {}
local visibleObjects = {}

---Updates Fewatsu and draws it to the screen if needed.
---
---If `force` is true, draw to the screen regardless of status.
---
---You shouldn't have to call this at all yourself. If you're looking to display Fewatsu, see `:show()`.
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

      self.offset = self.offset + math.round(chg)

      if self.offset < 0 then
        self.offset = 0
      elseif self.offset > self.documentImage.height - 240 then
        self.offset = self.documentImage.height - 240
      end
    end

    if pd.buttonJustPressed("a") and self.allowInput then
      dbg.log("A", "button")

      if self.selectedObject ~= nil and self.selectedObject ~= 0 then
        if self.playSFX then
          self.soundClick:play()
        end

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

              self.path = path

              dbg.log("path = " .. self.path, "path")
            else
              for i, v in ipairs(pd.file.listFiles(self.cwd)) do
                local dc = json.decodeFile(self.cwd .. v)

                if dc ~= nil then
                  if (dc["id"] == location[1] and string.sub(location[1], #location[1] - 4) ~= ".json") or (v == location[1] or self.cwd .. v == location[1]) then
                    decodedFile = dc

                    self.path = self.cwd .. v

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
              self.inputDelayTimer = pd.timer.new(20)

              self:update(true)
            end)
          end
        end
      end
    elseif pd.buttonJustPressed("b") and self.allowInput and not fewatsu_menu.isOpen then
      dbg.log("displaying menu", "menu")

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
          dbg.log("found path: " .. self.path, "menu")

          menuItemIndex = i
          break
        end
      end

      fewatsu_menu.open(self, menuItemIndex, menuOptions, function(item)
        dbg.log("got item " .. tostring(item), "menu")

        if item == fewatsu_menu.EXIT_ITEM_TEXT then
          self:hide()
        elseif item ~= nil and item ~= self.path then
          self:loadFile(item)
        end

        self.scrollbarShownTimer:start()

        self:update(true)
      end,
        function(item)    -- something to do with this function being called causes a nil timer error.. maybe find better solution to error later on?
          dbg.log("closed menu completely", "menu")

          pd.timer.performAfterDelay(0, function()
            self:update(true)
          end)
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
      dbg.log("drawing animated image at " .. k, "animated image")
      v:getCurrentFrame(self.darkMode):draw(0, k - self.offset)
    end
  end

  for elementI, element in ipairs(self.elements) do
    for k, v in pairs(self.customElements) do
      if k == element["type"] and v["drawEveryFrame"] and self.customElementYs[elementI] ~= nil then
        if self.customElementYs[elementI] - self.offset < 240 and self.customElementYs[elementI] - self.offset > -v["heightCalculationFunction"](element) then
          dbg.log("drawing " .. k .. " at " .. self.customElementYs[elementI], "custom elements")

          local origColor = gfx.getColor()
          local origDrawMode = gfx.getImageDrawMode()

          if self.darkMode then
            gfx.setColor(gfx.kColorBlack)
          else
            gfx.setColor(gfx.kColorWhite)
          end

          gfx.fillRect(0, self.customElementYs[elementI] - self.offset, 400,
            v["heightCalculationFunction"](element) - v["padding"])

          if self.darkMode then
            gfx.setColor(gfx.kColorWhite)
          else
            gfx.setColor(gfx.kColorBlack)
          end

          gfx.setImageDrawMode(gfx.kDrawModeCopy)

          v["drawFunction"](self.customElementYs[elementI] - self.offset, element)

          gfx.setColor(origColor)
          gfx.setImageDrawMode(origDrawMode)
        end
      end
    end
  end

  if force or self.offset ~= oldOffset or pd.buttonJustPressed("right") or pd.buttonJustPressed("left") or not self.scrollbarAnimator:ended() then
    dbg.log("updating display", "update")

    selectableObjects = {}
    visibleObjects = {}

    dbg.log("grabbing objects", "objects")

    for i, v in ipairs(self.linkYs) do
      dbg.log({ "self.offset: ", self.offset, " link: ", v }, "y vals")

      if v - self.offset < 120 and v - self.offset > -120 then
        dbg.log({ "passed selectable calculation" }, "objects")
        table.insert(selectableObjects, {
          type = "link",
          i = i,
          y = v,
          location = self.linkLocations[i]
        })
      end

      if v - self.offset < 220 and v - self.offset > -20 then
        dbg.log({ "passed visible calculation" }, "objects")
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
        local p = self.imgPaths[i]
        if p == "" then
          p = nil
        end

        if v - self.offset < 129 and v - self.offset > -120 then
          table.insert(selectableObjects, {
            type = "image",
            i = i,
            y = v,
            path = p,
            caption = self.imgCaptions[i]
          })
        end

        if v - self.offset < 220 and v - self.offset > -20 then
          table.insert(visibleObjects, {
            type = "image",
            i = i,
            y = v,
            path = p,
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

    dbg.log("checking for selectable objects", "objects")

    dbg.log({ "offset: ", self.offset, " doc height: ", self.documentImage.height })

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
    elseif (self.documentImage.height - 40 <= self.offset + 240 and self.offset + 240 <= self.documentImage.height + 40) then
      dbg.log("selecting last object in page", "objects")

      selected = visibleObjects[#visibleObjects]

      self.selectedObject = selected

      drawSelector = true
    else
      dbg.log("no objects visible", "objects")

      self.selectedObject = nil
    end

    if self.scrollbarLockedObject then
      self:_drawObjectSelector(self.scrollbarLockedObject)
    elseif drawSelector and selected then
      self:_drawObjectSelector(selected)
    end

    if self.documentImage.height > 240 then
      scrollbarY = (math.abs(1 - ((self.documentImage.height - self.offset - 240) / (self.documentImage.height - 240))) * (240 - self.scrollbarSmallImage.height))
    else
      scrollbarY = 0
    end

    if oldOffset ~= self.offset and math.abs(self.offset - oldOffset) > 3 then
      if self.scrollbarShownTimer.timeLeft == 0 then
        self.scrollbarAnimator = gfx.animator.new(100, 0, self.scrollbarBackgroundImage.width / 2)
      end

      self.scrollbarShownTimer:remove()
      self.scrollbarShownTimer = pd.timer.new(self.scrollbarTimeout, self.scrollbarTimerEndedCallback)
    end
  end

  if self.documentImage.height > 240 and self.scrollbarAnimator:currentValue() ~= 0 then
    self.scrollbarBackgroundImage:draw(400 - self.scrollbarAnimator:currentValue() * 2, 0)
    self.scrollbarSmallImage:draw(400 - self.scrollbarAnimator:currentValue() * 2, scrollbarY)
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
---`callback` can be provided if you would like an action to be performed after Fewatsu's splash screen has finished displaying (or, if you have it disabled, immediately after Fewatsu finishes its `show()` function).
---
---@param callback function
---@return nil
function Fewatsu:show(callback)
  self.offset = 0

  self.scrollbarAnimator = gfx.animator.new(0, 0, 0)
  self.scrollbarShownTimer:start()
  self.scrollbarShownTimer = pd.timer.new(0)
  self.scrollbarLockedObject = nil

  self.originalRefreshRate = pd.display.getRefreshRate()
  self.originalDisplayInvertedMode = pd.display.getInverted()

  pd.display.setRefreshRate(50)
  pd.inputHandlers.push(BLANK_INPUT_HANDLERS, true)

  playdateMenu:removeAllMenuItems()

  local function finishShow()
    playdateMenu:addMenuItem("about...", function()
      if fewatsu_menu.isOpen then
        fewatsu_menu.close(true)
      end

      if not fewatsu_imageViewer.isOpen then
        self:loadFile(FEWATSU_LIB_PATH .. "/fewatsu/pages/about.json")
      end
    end)

    playdateMenu:addMenuItem("help...", function()
      if fewatsu_menu.isOpen then
        fewatsu_menu.close(true)
      end

      if not fewatsu_imageViewer.isOpen then
        self:loadFile(FEWATSU_LIB_PATH .. "/fewatsu/pages/help.json")
      end
    end)

    local audioText = "bgm + sfx"

    if self.playBGM == false and self.playSFX == false then
      audioText = "off"
    elseif self.playBGM == false and self.playSFX then
      audioText = "sfx"
    elseif self.playBGM and self.playSFX == false then
      audioText = "bgm"
    end

    playdateMenu:addOptionsMenuItem("audio", {"bgm + sfx", "bgm", "sfx", "off"}, audioText, function(out)
      if out == "bgm + sfx" then
        self.playBGM = true
        self.playSFX = true
      elseif out == "bgm" then
        self.playBGM = true
        self.playSFX = false
      elseif out == "sfx" then
        self.playBGM = false
        self.playSFX = true
      elseif out == "off" then
        self.playBGM = false
        self.playSFX = false
      end
      
      if not self.playBGM then
        self.backgroundMusic:stop()
      elseif self.playBGM and self.backgroundMusic ~= nil then
        self.backgroundMusic:play(0)
      end
    end)

    self.inputDelayTimer = pd.timer.new(10)

    self.oldUpdate = pd.update
    pd.update = function() self.update(self) end

    if self.playBGM and self.backgroundMusic ~= nil then
      self.backgroundMusic:setVolume(0, 0)
      self.backgroundMusic:setVolume(self.backgroundMusicVolume, self.backgroundMusicVolume, self
      .backgroundMusicFadeTime)
      self.backgroundMusic:play(0)
    end

    self.shown = true
    self.allowInput = true

    pd.display.setInverted(false)

    self:update(true)

    if callback then
      callback(self)
    end
  end

  if self.showSplash then
    self:update(true)
    fewatsu_splash.open(self.splashText, self.splashFont, self.splashBackground, finishShow)
  else
    finishShow()
  end
end

---Hides Fewatsu, restoring the original `playdate.update()` function and input handlers.
---
---If `preserveCache` is `true`, doesn't clear the animated image and QR code caches.
---
---The current Fewatsu document and state are preserved.
---
---@param preserveCache boolean
---@return nil
function Fewatsu:hide(preserveCache)
  dbg.log("hiding", "fewatsu")

  pd.inputHandlers.pop()
  pd.update = self.oldUpdate

  pd.display.setRefreshRate(self.originalRefreshRate)
  pd.display.setInverted(self.originalDisplayInvertedMode)

  playdateMenu:removeAllMenuItems()

  if not preserveCache then
    self:clearAnimatedImageCache()
    self.cachedQRCodes = {}
  end

  if self.playBGM and self.backgroundMusic ~= nil then
    self.backgroundMusic:setVolume(0, 0, self.backgroundMusicFadeTime, function(self)
      self:stop()
    end)
  end

  self.shown = false
  self.allowInput = false

  if self.callback then
    self.callback()
  end
end

---Shorthand function for loading a JSON file into Fewatsu.
---
---`path` can be an absolute path or a path from the current working directory.
---
---File extension can be omitted (will check for `.json` files).
---
---Returns the generated image.
---
---@param path string
---@return playdate.graphics.image
function Fewatsu:loadFile(path)
  dbg.log("attempting to load file " .. path, "loadfile")

  local newpath = getExistentPath(self.cwd, path, ".json")
  if newpath ~= nil then
    self.path = newpath

    local decodedFile = json.decodeFile(newpath)

    if decodedFile then
      return self:load(decodedFile)
    end
  end
  error("could not load file " .. path)
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
  if pd.file.exists(dir) then
    self.cwd = dir

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
---Defaults to `400`ms.
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

---Sets if sound effects should play on user interaction (A button press, B button press, crank, etc)
---
---Defaults to `true`.
---
---@param status boolean
function Fewatsu:setEnableSFX(status)
  self.playSFX = status
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
---Defaults to `0.2`.
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
---The image should be 20 pixels wide, and up to 160 pixels tall. For the best results, it is recommended to add two or so pixels of padding to every side of the image.
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
---To customize the menu manually, see `:addMenuItem()` and `:clearMenuItems()`. (auto add must be `false`)
---
---@param enable boolean
function Fewatsu:setMenuAutoAdd(enable)
  self.menuAutoItemAdd = enable
end

---Adds a page to the Fewatsu menu. `:setMenuAutoAdd()` must be `false`.
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


---Clears all side menu items. `:setMenuAutoAdd()` must be `false`.
---
function Fewatsu:clearMenuItems()
  self.menuItems = {}
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

---Sets if loading screens should display the percent complete alongside the text.
---
---The loading screen must be enabled for this to take effect. See `:setEnableLoadingScreen()` for more details.
---
---Loading screen text must be enabled for this to take effect. See `:setLoadingScreenShowText()` for more details.
---
---Defaults to `true`.
---
---@param show boolean
function Fewatsu:setLoadingScreenShowPercent(show)
  fewatsu_loadScreen.showPercentage = show
end

---Clears the Fewatsu animated image cache.
---
function Fewatsu:clearAnimatedImageCache()
  if self.animatedImages then
    for k, v in pairs(self.animatedImages) do
      v:destroy()
    end
  end

  self.animatedImages = {}
end

---Registers a new custom element.
---
---Please see the `custom elements` section in the Fewatsu format documentation (`FORMAT.md`) for more information.
---
---@param name string
---@param data table
function Fewatsu:registerCustomElement(name, data)
  if not data["padding"] then
    data["padding"] = 10
  end

  self.customElements[name] = data
end

---Set if a splash screen should be displayed when `:show()` is called.
---
---Defaults to `true`.
---
---@param show boolean
function Fewatsu:setShowSplash(show)
  self.showSplash = show
end

---Sets the splash screen text.
---
---Requires that `:setShowSplash()` has been set to true.
---
---Defaults to `Fewatsu`.
---
---@param text string
function Fewatsu:setSplashText(text)
  self.splashText = text
end

---Sets the splash screen font.
---
---Requires that `:setShowSplash()` has been set to true.
---
---@param font playdate.graphics.font
function Fewatsu:setSplashFont(font)
  self.splashFont = font
end

---Sets the splash screen background.
---
---Requires that `:setShowSplash()` has been set to true.
---
---By default, shows the latest Fewatsu frame.
---
---`bg` image size must be 400 x 240 pixels.
---
---@param bg playdate.graphics.image
function Fewatsu:setSplashBackground(bg)
  self.splashBackground = bg
end
