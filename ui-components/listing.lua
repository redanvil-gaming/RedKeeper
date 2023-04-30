local function redraw_rows(column)
  local row_h = column._row_h
  local col_c = column._field_c
  local row_c = column._row_c

  column:setGridSize(col_c, row_c)
  for r=1, row_c do
    column:setRowHeight(r, GUI.SIZE_POLICY_ABSOLUTE, row_h)
  end

  if #column.children > row_c * col_c then
    column:removeChildren(row_c + 1, #column.children)
  end
end

local function listing_column(parent, col)
  local layout = parent:addChild(GUI.layout(
    1, 1, 1, 1,
    1, 1
  ))

  layout._row_h = 1
  layout._field_c = 6
  layout._col = col

  local old_update = layout.update
  layout.update = function()
    redraw_rows(layout)
    old_update(layout)
  end

  layout.set_row_h = function(layout, row_h) 
    layout._row_h = row_h
    layout._row_c = math.floor(layout.height / row_h)

    layout.update()
  end

  layout.set_values = function(layout, items)
    for r=1, layout._row_c do
      local item = items[(layout._col - 1) * layout._row_c + r]
      if item == nil then
        break
      end
      layout:setPosition(1, r, layout:addChild(GUI.text(1, 1, 0, string.format("T: %s", item.tier))))
      layout:setPosition(2, r, layout:addChild(GUI.text(1, 1, 0, tostring(item.status))))
      layout:setPosition(3, r, layout:addChild(GUI.text(1, 1, 0, item.display_name)))
      layout:setPosition(4, r, layout:addChild(GUI.text(1, 1, 0, tostring(item.stock))))
      layout:setPosition(5, r, layout:addChild(GUI.text(1, 1, 0, "/")))
      layout:setPosition(6, r, layout:addChild(GUI.text(1, 1, 0, tostring(item.required))))
    end
  end

  return layout
end

local function redraw_columns(listing)
  local col_c = listing._private.col_c
  local col_w = math.floor(listing.width / col_c)

  listing:setGridSize(col_c, 1)
  for c=1, col_c do
    listing:setColumnWidth(c, GUI.SIZE_POLICY_ABSOLUTE, col_w)
  end
  if #listing.children > col_c then
    listing:removeChildren(col_c + 1, #listing.children)
  end
  if #listing.children < col_c then
    for col=#listing.children + 1, col_c do
      listing_column(listing, col)
    end
  end
  for col=1, col_c do
    listing.children[col]:set_row_h(listing._private.row_h)
    listing:setPosition(col, 1, listing.children[col])
    listing:setFitting(col, 1, true, true)
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
  layout.update = function()
    redraw_columns(layout)
    old_update(layout)
  end

  state.sz.listing:subscribe(function(state) 
    layout._private.col_c = state.sz.listing.columns
    layout._private.row_h = state.sz.listing.row_h
    
    state:dispatch("MULTI", {
      {type="LOAD_PAGE", data={page=state.listing.pagination.current, size=#layout.children}},
      {type="SET_PAGE", data=1},
    })
    layout.update()
  end)

  state.listing.pagination:subscribe(function(state)
    state:dispatch("LOAD_PAGE", {page=state.listing.pagination.current, size=#layout.children})
  end)

  state.listing.content:subscribe(function(state)
    for idx, col in ipairs(layout.children) do
      col:set_values(state.listing.content)
    end
  end)


  return layout
end