local function redraw_rows(state, column)
  local row_h = state.sz.listing.row_h
  local row_c = state.listing.pagination.row_c

  -- extremely dirty hack to reset all values on resize, TODO (@rebenkoy): there must be a `clever` way to do this
  if math.floor(layout.height / state.sz.listing.row_h) ~= row_c then
    state:dispatch("SET", {path = {"sz", "listing", "row_h"}, value = row_h})
  end

  local field_c = #column.columnSizes
  column:setGridSize(field_c, row_c)

  column:setColumnWidth(1, GUI.SIZE_POLICY_ABSOLUTE, state.sz.listing.fields.tier)
  column:setColumnWidth(2, GUI.SIZE_POLICY_ABSOLUTE, state.sz.listing.fields.state)
  column:setColumnWidth(3, GUI.SIZE_POLICY_ABSOLUTE, column.width - (
    state.sz.listing.fields.tier + state.sz.listing.fields.state + state.sz.listing.fields.stock + state.sz.listing.fields.required
  ))
  column:setColumnWidth(4, GUI.SIZE_POLICY_ABSOLUTE, state.sz.listing.fields.stock)
  column:setColumnWidth(5, GUI.SIZE_POLICY_ABSOLUTE, 1)
  column:setColumnWidth(6, GUI.SIZE_POLICY_ABSOLUTE, state.sz.listing.fields.required)

  for r=1, row_c do
    column:setRowHeight(r, GUI.SIZE_POLICY_ABSOLUTE, row_h)
    column:setAlignment(1, r, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_CENTER)
    column:setAlignment(2, r, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_CENTER)
    column:setAlignment(3, r, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_CENTER)
    column:setAlignment(4, r, GUI.ALIGNMENT_HORIZONTAL_RIGHT, GUI.ALIGNMENT_VERTICAL_CENTER)
    column:setAlignment(5, r, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_CENTER)
    column:setAlignment(6, r, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_CENTER)
  end

  if #column.children > row_c * field_c then
    column:removeChildren(row_c + 1, #column.children)
  end
  while #column.children < row_c * field_c do
    for f=1, field_c do
      column:setPosition(f, math.floor(#column.children / field_c) + 1, column:addChild(GUI.text(1, 1, state.cs.listing.fg, "")))
    end
  end
end

local function set_column_values(state, column)
  local row_h = state.sz.listing.row_h
  local row_c = state.listing.pagination.row_c
  for r=1, row_c do
    local item = state.listing.content[(column._col - 1) * row_c + r]
    if item == nil then
      break
    end
    column.children[#column.columnSizes * (r - 1) + 1].text = string.format("T: %s", item.tier)
    column.children[#column.columnSizes * (r - 1) + 2].text = tostring(item.status)
    column.children[#column.columnSizes * (r - 1) + 3].text = item.display_name
    column.children[#column.columnSizes * (r - 1) + 4].text = tostring(item.stock)
    column.children[#column.columnSizes * (r - 1) + 5].text = "/"
    column.children[#column.columnSizes * (r - 1) + 6].text = tostring(item.required)
  end
end

local function listing_column(state, parent, col)
  local layout = parent:addChild(GUI.layout(
    1, 1, 1, 1,
    6, 1
  ))
  
  layout._col = col

  return layout
end

local function redraw_columns(state, listing)
  local col_c = state.sz.listing.columns
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
      listing_column(state, listing, col)
    end
  end
  for col=1, col_c do
    listing:setPosition(col, 1, listing.children[col])
    listing:setFitting(col, 1, true, true)
    redraw_rows(state, listing.children[col])
    set_column_values(state, listing.children[col])
  end
end

return function(state, parent)
  local layout = parent:addChild(GUI.layout(
    1, 1, parent.width, 1,
    1, 1
  ))

  state.sz.listing:subscribe(function(state)  
    state:dispatch("SET_PAGE_SIZE", {cols=state.sz.listing.columns, rows=math.floor(layout.height / state.sz.listing.row_h)})
  end)

  state.listing.pagination:subscribe(function(state)
    state:dispatch("LOAD_PAGE")
  end)

  state.listing.content:subscribe(function(state)
    redraw_columns(state, layout)
  end)
  
  return layout
end