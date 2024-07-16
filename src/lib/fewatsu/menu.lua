local pd <const> = playdate
local gfx <const> = playdate.graphics

fewatsu_menu = {}

local menu = fewatsu_menu

local menuOptions = {"*Fewatsu*", menu.EXIT_ITEM}

local listview = playdate.ui.gridview.new(0, 20)
listview:setCellPadding(4, 4, 2, 2)

function listview:drawCell(section, row, column, selected, x, y, width, height)
  if selected then
    gfx.fillRoundRect(x, y, width, 20, 4)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
  else
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
  end
  gfx.drawTextInRect(menuOptions[row], x, y+2, width, height, nil, "...", kTextAlignment.center)
end


menu.EXIT_ITEM = "*Exit...*"

function menu.open(currentItem, width, options, callback)
  listview:removeHorizontalDividers()
  menuOptions = {"*Fewatsu*", menu.EXIT_ITEM}
  listview:addHorizontalDividerAbove(1, 2)

  for i = #options, 1, -1 do
    table.insert(menuOptions, 2, options[i])
  end

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

  menu.selectedItem = nil

  menu.callback = callback

  menu.width = width
  menu.backgroundImage = gfx.getDisplayImage():fadedImage(0.5, gfx.image.kDitherTypeBayer4x4)

  menu.oldUpdate = pd.update
  pd.update = menu.update
  pd.inputHandlers.push(menu, true)

  menu.animator = gfx.animator.new(350, menu.width, 0, pd.easingFunctions.outExpo)
end

function menu.update()
  pd.timer.updateTimers()

  if pd.buttonJustPressed("a") then
    menu.selectedItem = menuOptions[listview:getSelectedRow()]

    if menu.selectedItem == menu.EXIT_ITEM then
      menu.close()

      if menu.callback then
        menu.callback(menu.EXIT_ITEM)
      end
    else
      menu.closeStage1()
    end
  end

  if pd.buttonJustPressed("b") then
    menu.closeStage1()
  end

  if pd.buttonJustPressed("down") then
    listview:selectNextRow()

    menu.SOUND_MOVE:play()
  elseif pd.buttonJustPressed("up") then
    if listview:getSelectedRow() > 2 then
      listview:selectPreviousRow()

      menu.SOUND_MOVE:play()
    end
  end

  if menu.animating or menu.closing or listview.needsDisplay then
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

    if menu.callback then
      menu.callback(menu.selectedItem)

      menu.animator = gfx.animator.new(0, 0, 0)

      menu.backgroundImage = gfx.getWorkingImage()

      menu.animator = gfx.animator.new(250, 0, menu.width, pd.easingFunctions.outExpo)
    end
  end
end

function menu.close()
  pd.update = menu.oldUpdate
  pd.inputHandlers.pop()
end
