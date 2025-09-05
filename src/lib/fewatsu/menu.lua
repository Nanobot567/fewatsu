local pd <const> = playdate
local gfx <const> = playdate.graphics

fewatsu_menu = {}

local menu = fewatsu_menu

local listview = playdate.ui.gridview.new(0, 20)
listview:setCellPadding(4, 4, 2, 2)

local menuOptions
local menuItemPaths

local fewatsuInstance

function listview:drawCell(section, row, column, selected, x, y, width, height)
  if selected then
    gfx.fillRoundRect(x, y, width, 20, 4)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
  else
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
  end
  gfx.drawTextInRect(menuOptions[row], x, y + 2, width, height, nil, "...", kTextAlignment.center)
end

menu.titleItemText = "Fewatsu"
menu.EXIT_ITEM_TEXT = "*Exit...*"

menu.easeTime = 350
menu.easeFunc = pd.easingFunctions.outExpo

menu.width = 120

local oldFont

function menu.open(fwInstance, currentItem, options, closingCallback, callback) -- it's probably bad that i'm passing in self here.. but meh lol
  oldFont = gfx.getFont()
  gfx.setFont(gfx.getSystemFont())

  fewatsuInstance = fwInstance

  listview:removeHorizontalDividers()
  menuOptions = { "*" .. menu.titleItemText .. "*", menu.EXIT_ITEM_TEXT}
  menuItemPaths = {}
  listview:addHorizontalDividerAbove(1, 2)

  for i, v in ipairs(options) do
    local disp = options[i]["pageTitle"]
    if options[i]["displayName"] then
      disp = options[i]["displayName"]
    end

    table.insert(menuOptions, #menuOptions, disp)

    table.insert(menuItemPaths, options[i]["path"])
  end

  table.insert(menuItemPaths, menu.EXIT_ITEM_TEXT)

  listview:addHorizontalDividerAbove(1, #menuOptions)

  listview:setNumberOfRows(#menuOptions)

  if currentItem ~= nil then
    listview:setSelectedRow(currentItem + 1)
  else
    listview:setSelectedRow(2)
  end

  menu.closing = false
  menu.animating = false
  menu.isOpen = true

  menu.playSounds = fewatsuInstance.playSFX

  menu.soundClick = fewatsuInstance.soundClick
  menu.soundSelect = fewatsuInstance.soundSelect
  menu.soundMenuOpen = fewatsuInstance.soundMenuOpen

  menu.selectedItem = nil

  menu.closingCallback = closingCallback
  menu.callback = callback
  menu.backgroundImage = gfx.getDisplayImage():fadedImage(0.5, gfx.image.kDitherTypeBayer4x4)

  menu.oldUpdate = pd.update
  pd.update = menu.update
  pd.inputHandlers.push(menu, true)

  menu.animator = gfx.animator.new(menu.easeTime, menu.width, 0, menu.easeFunc)

  if menu.playSounds then
    menu.soundMenuOpen:play()
  end
end

function menu.update()
  pd.timer.updateTimers()

  if not menu.closing then
    if pd.buttonJustPressed("a") then
      if menu.playSounds then
        menu.soundClick:play()
      end

      menu.selectedItem = menuItemPaths[listview:getSelectedRow() - 1]

      if menu.selectedItem == menu.EXIT_ITEM_TEXT then
        menu.close()

        if menu.closingCallback then
          menu.closingCallback(menu.EXIT_ITEM_TEXT)
        end
      else
        menu.closeStage1()
      end
    end

    if pd.buttonJustPressed("b") then
      if menu.playSounds then
        menu.soundMenuOpen:play(1, 1.1)
      end
      menu.closeStage1()
    end

    if pd.buttonJustPressed("down") then
      if menu.playSounds then
        menu.soundSelect:play()
      end
      listview:selectNextRow()
    elseif pd.buttonJustPressed("up") then
      if menu.playSounds then
        menu.soundSelect:play()
      end
      if listview:getSelectedRow() > 2 then
        listview:selectPreviousRow()
      end
    end
  end

  if menu.animating or menu.closing or (listview.needsDisplay and menu.isOpen) then
    gfx.clear()

    menu.backgroundImage:draw(0, 0)

    if menu.animator ~= nil then
      if menu.animator:ended() == false then
        menu.animating = true
      else
        menu.animating = false
      end

      gfx.setColor(gfx.kColorWhite)
      gfx.fillRoundRect(-10 - menu.animator:currentValue(), 0, menu.width + 10, 240, 4)
      gfx.setColor(gfx.kColorBlack)
      gfx.drawRoundRect(-10 - menu.animator:currentValue(), 0, menu.width + 10, 240, 4)
      listview:drawInRect(0 - menu.animator:currentValue(), 0, menu.width, 240)

      if menu.closing and menu.animator:ended() == true then
        menu.close()
      end
    end
  end
end

function menu.closeStage1()
  if menu.closing == false then
    menu.closing = true

    if menu.closingCallback then
      menu.closingCallback(menu.selectedItem)

      menu.animator = gfx.animator.new(0, 0, 0)

      menu.backgroundImage = gfx.getWorkingImage()

      menu.animator = gfx.animator.new(menu.easeTime, 0, menu.width, menu.easeFunc)
    end
  end
end

function menu.close(noCallback)
  pd.update = menu.oldUpdate
  pd.inputHandlers.pop()
  menu.isOpen = false
  menu.closing = false
  menu.animating = false

  gfx.setFont(oldFont)

  if menu.callback and not noCallback then
    menu.callback(menu.selectedItem)
  end
end
