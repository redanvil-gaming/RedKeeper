local function make_row(state, parent, row)
  local layout = parent:addChild(GUI.layout(
    1, 1, 1, 1,
    1, 1
  ))
  layout:setPosition(1, 1, layout:addChild(GUI.text(1, 1, 0, string.format("Row №%d", row))))
  return layout
end


local function redraw_columns(listing)
  local col_c = listing._private.col_c
  local row_h = listing._private.row_h
  local col_w = math.floor(listing.width / col_c)
  local row_c = math.floor(listing.height / row_h)

  listing:setGridSize(col_c, row_c)
  for r=1, row_c do
    listing:setRowHeight(r, GUI.SIZE_POLICY_ABSOLUTE, row_h)
  end
  for c=1, col_c do
    listing:setColumnWidth(c, GUI.SIZE_POLICY_ABSOLUTE, col_w)
  end
  if #listing.children > row_c * col_c then
    listing:removeChildren(row_c * col_c + 1, #listing.children)
  end
  if #listing.children < row_c * col_c then
    for row=#listing.children + 1, row_c * col_c do
      make_row(state, parent, row)
    end
  end
  for col=1, col_c do
    for row=1, row_c do
      listing:setPosition(col, row, listing.children[(col - 1) * row_c + row])
      listing:setFitting(col, row, true, true)
    end
  end
end

return function(state, parent)
  local layout = parent:addChild(GUI.layout(
    1, 1, parent.width, 1,
    1, 1
  ))

  layout._private = {
    col_c = 1,
    row_h = 1,
  }

  local old_update = layout.update
  layout.update = function(listing)
    redraw_columns(listing)
    old_update(listing)
  end

  state.sz.listing:subscribe(function(state) 
    layout._private.col_c = state.sz.listing.columns
    layout._private.row_h = state.sz.listing.row_h
    layout.update()
  end)


  return layout
end