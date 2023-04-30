return function(state, parent)
  local footer = parent:addChild(GUI.layout(
    1, 1, parent.width, 1,
    3, 1
  ))

  local old_draw = footer.draw
  footer.draw = function(footer)
    screen.drawRectangle(footer.x, footer.y, footer.width, footer.height, state.cs.footer.bg, state.cs.footer.fg, " ")
    old_draw(footer)
  end

  local prev = footer:addChild(GUI.adaptiveButton(
    1, 1,
    0, 0, 
    0, 0xFFFFFF, 
    0, 0xFFFFFF,
    "< previous"
  ))

  local page_counter = footer:addChild(GUI.text(
    1, 1,
    0xFFFFFF,
    "???"
  ))

  local nxt = footer:addChild(GUI.adaptiveButton(
    1, 1,
    0, 0, 
    0, 0xFFFFFF, 
    0, 0xFFFFFF,
    "next >"
  ))

  state.cs.footer:subscribe(function(state)
    prev.colors.default.background = state.cs.footer.button.bg
    nxt.colors.default.background = state.cs.footer.button.bg
    prev.colors.default.text = state.cs.footer.button.fg
    nxt.colors.default.text = state.cs.footer.button.fg
    prev.colors.pressed.background = state.cs.footer.button.pressed_bg
    nxt.colors.pressed.background = state.cs.footer.button.pressed_bg
    prev.colors.pressed.text = state.cs.footer.button.pressed_fg
    nxt.colors.pressed.text = state.cs.footer.button.pressed_fg

    page_counter.color = state.cs.footer.fg
  end)

  state.listing.pagination:subscribe(function(state)
    page_counter.text = string.format("page: %d/%d", state.listing.pagination.current, state.listing.pagination.total)
  end)

  prev.onTouch = function()
    state:dispatch("DEC_PAGE")
  end

  nxt.onTouch = function()
    state:dispatch("INC_PAGE")
  end

  footer:setPosition(1, 1, prev)
  footer:setPosition(2, 1, page_counter)
  footer:setPosition(3, 1, nxt)

  return footer
end
