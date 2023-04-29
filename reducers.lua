local reducers = {}

function reducers.dec_page(state, data)
  if state.listing.pagination.current > 1 then
    state:dispathc("SET", {path = {"listing", "pagination", "current"}, value = state.listing.pagination.current - 1})
  end
end

function reducers.inc_page(state, data)
  if state.listing.pagination.current < state.listing.pagination.total then
    state:dispathc("SET", {path = {"listing", "pagination", "current"}, value = state.listing.pagination.current + 1})
  end
end

local function bind(state)
  for name, reducer in pairs(reducers) do
    state:set_reducer(string.upper(name), reducer)
  end
  return state
end

return 