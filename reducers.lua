local reducers = {}

function reducers.set_page_size(state, data)
  local setters = {}
  if state.listing.pagination.row_c ~= data.rows then
    table.insert(setters, {type="SET", data={path = {"listing", "pagination", "row_c"}, value = data.rows}})
  end 
  if state.listing.pagination.size ~= data.cols * data.rows then
    table.insert(setters, {type="SET", data={path = {"listing", "pagination", "size"}, value = data.cols * data.rows}})
  end
  if #setters then
    table.insert(setters, {type="SET_PAGE", data=1})
    return "MULTI", setters
  end
  return {}
end

function reducers.set_page(state, data)
  return "SET", {path = {"listing", "pagination", "current"}, value = data}
end

function reducers.dec_page(state, data)
  if state.listing.pagination.current > 1 then
    return "SET_PAGE", state.listing.pagination.current - 1
  end
  return {}
end

function reducers.inc_page(state, data)
  if state.listing.pagination.current < state.listing.pagination.total then
    return "SET_PAGE", state.listing.pagination.current + 1
  end
  return {}
end

function reducers.load_page(state, data)
  return "SET", {path = {"listing", "content"}, value=state:get_blackbox("keeper"):get_page(
    state.listing.pagination.current, 
    state.listing.pagination.size, 
    state.listing.pagination.filter
  )}
end

local function bind(state, keeper)
  for name, reducer in pairs(reducers) do
    state:add_reducer(string.upper(name), reducer)
  end
  return state
end

return bind