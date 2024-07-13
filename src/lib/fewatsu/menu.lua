local pd <const> = playdate
local gfx <const> = playdate.graphics

fewatsu_menu = {}

local menu = fewatsu_menu

local menuOptions = {"Fewatsu", "Exit..."}
local listview = playdate.ui.gridview.new(0, 20)
listview:setCellPadding(4, 4, 2, 2)
listview:setNumberOfRows(#menuOptions)
listview:setSelectedRow(2)

function listview:drawCell(section, row, column, selected, x, y, width, height)
  if selected then
    gfx.fillRoundRect(x, y, width, 20, 4)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
  else
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
  end
  gfx.drawTextInRect(menuOptions[row], x, y+2, width, height, nil, "...", kTextAlignment.center)
end

function menu.open(currentItem, width, options, callback)
  listview:removeHorizontalDividers()
  menuOptions = {"*Fewatsu*", "*Exit...*"}
  listview:addHorizontalDividerAbove(1, 2)

  for i = #options, 1, -1 do
    table.insert(menuOptions, 2, options[i])
  end

  listview:addHorizontalDividerAbove(1, #menuOptions)

  listview:setNumberOfRows(#menuOptions)
  listview:setSelectedRow(currentItem + 1)

  menu.closing = false
  menu.animating = false
  menu.isOpen = true

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

function menu.AButtonDown()
  menu.close(menuOptions[listview:getSelectedRow()])
end

function menu.BButtonDown()
  if menu.closing == false then
    menu.closing = true
    menu.animator = gfx.animator.new(300, 0, menu.width, pd.easingFunctions.outExpo)
  end
end

function menu.downButtonDown()
  listview:selectNextRow()
end

function menu.upButtonDown()
  if listview:getSelectedRow() > 2 then
    listview:selectPreviousRow()
  end
end

function menu.close(item) -- TODO: return item text
  pd.update = menu.oldUpdate
  pd.inputHandlers.pop()

  if menu.callback then
    menu.callback(item)
  end
end
