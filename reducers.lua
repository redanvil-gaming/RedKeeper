local reducers = {}

function reducers.dec_page(state, data)
  if state.listing.pagination.current > 1 then
    state:dispatch("SET", {path = {"listing", "pagination", "current"}, value = state.listing.pagination.current - 1})
  end
  return {}
end

function reducers.inc_page(state, data)
  if state.listing.pagination.current < state.listing.pagination.total then
    state:dispatch("SET", {path = {"listing", "pagination", "current"}, value = state.listing.pagination.current + 1})
  end
  return {}
end

local function bind(state)
  for name, reducer in pairs(reducers) do
    state:add_reducer(string.upper(name), reducer)
  end
  return state
end

return bind