local reducers = {}

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
  state:dispatch("SET", {path = {"listing", "content"} value=state.get_blackbox["keeper"]:get_page(data.page, data.size, data.filter)})
  return {}
end

local function bind(state, keeper)
  for name, reducer in pairs(reducers) do
    state:add_reducer(string.upper(name), reducer)
  end
  return state
end

return bind