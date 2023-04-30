local reducers = {}

function reducer.set_page_size(state, data)
  state:dispatch("MULTI", {
    {type="SET", data={path = {"listing", "pagination", "row_c"}, value = data.rows}},
    {type="SET", data={path = {"listing", "pagination", "size"}, value = data.cols * data.rows}},
  })
  return {}
end

function reducers.set_page(state, data)
  state:dispatch("SET", {path = {"listing", "pagination", "current"}, value = data})
  return {}
end

function reducers.dec_page(state, data)
  if state.listing.pagination.current > 1 then
    state:dispatch("SET_PAGE", state.listing.pagination.current - 1)
  end
  return {}
end

function reducers.inc_page(state, data)
  if state.listing.pagination.current < state.listing.pagination.total then
    state:dispatch("SET_PAGE", state.listing.pagination.current + 1)
  end
  return {}
end

function reducers.load_page(state, data)
  state:dispatch("SET", {path = {"listing", "content"}, value=state:get_blackbox("keeper"):get_page(
    state.listing.pagination.current, 
    state.listing.pagination.size, 
    state.listing.pagination.filter,
  )})
  return {}
end

local function bind(state, keeper)
  for name, reducer in pairs(reducers) do
    state:add_reducer(string.upper(name), reducer)
  end
  return state
end

return bind