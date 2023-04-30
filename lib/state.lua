local serialization = require("serialization")

local make_state


local RootStateIndex = {}
local ChildStateIndex = {}


local function get_hidden_fields(state)
  if type(state) ~= "table" then return {} end
  return getmetatable(state).__hidden_fields
end


function RootStateIndex.add_blackbox(state, key, blackbox)
  get_hidden_fields(state).blackboxes[key] = blackbox
end


function RootStateIndex.get_blackbox(state, key)
  return get_hidden_fields(state).blackboxes[key]
end


function RootStateIndex.add_reducer(state, tp, reducer)
  get_hidden_fields(state).reducers[tp] = reducer
end


local function do_reduce(state, tp, data)
  local level = 1
  while type(tp) == "string" do
    if get_hidden_fields(state).logging then
      table.insert(get_hidden_fields(state).log, string.format("%d| %s: %s", level, tp, serialization.serialize(data)))
    end
    local reducer = get_hidden_fields(state).reducers[tp]
    if reducer == nil then
      return
    end 
    tp, data = reducer(state, data)
    level = level + 1
  end
  if get_hidden_fields(state).logging then
    table.insert(get_hidden_fields(state).log, string.format("callbacks: %d", #tp))
  end
  return tp
end


function RootStateIndex.dispatch(state, tp, data)
  local callbacks = do_reduce(state, tp, data)
  if callbacks == nil then return end
  for idx, callback in ipairs(callbacks) do
    callback(state)
  end
end


local function set_reducer(state, data)
  local current = state
  local callbacks = {}
  for idx, token in ipairs(data.path) do
    for i, callback in pairs(get_hidden_fields(current).subscriptions) do
      table.insert(callbacks, callback)
    end
    if idx == #data.path then
      current[token] = make_state(data.value, current, get_hidden_fields(current[token]))
    else
      current = current[token]
    end
  end
  return callbacks
end


local function toggle_log_reducer(state, data)
  get_hidden_fields(state).logging = not get_hidden_fields(state).logging
end


local function clear_log_reducer(state, data)
  get_hidden_fields(state).log = {}
end


function RootStateIndex.logs(state)
  return get_hidden_fields(state).log
end


local function multi_reducer(state, events)
  local callbacks = {}
  for idx, entry in pairs(events) do    
    for idx, callback in ipairs(do_reduce(state, entry.type, entry.data)) do
      table.insert(callbacks, callback)
    end
  end
  return callbacks
end


function ChildStateIndex.dispatch(state, tp, data)
  get_hidden_fields(state).root_parent:dispatch(type, data)
end


local function state_subscribe(state, callback)
  local sz = 0
  for _, _ in pairs(get_hidden_fields(state).subscriptions) do sz = sz + 1 end
  local key = "s"..sz
  get_hidden_fields(state).subscriptions[key] = callback
  return function()
    state[key] = nil
  end
end
RootStateIndex.subscribe = state_subscribe
ChildStateIndex.subscribe = state_subscribe


local function update_all(state)
  for idx, callback in pairs(get_hidden_fields(state).subscriptions) do
    callback(get_hidden_fields(state).root_parent)
  end

  for k, v in pairs(state) do
    if type(v) == "table" and v.update_all ~= nil then
      v:update_all()
    end
  end
end
RootStateIndex.update_all = update_all
ChildStateIndex.update_all = update_all


local function create_empty_state(parent, hidden_fields)
  local state = {}
  local index = nil
  state_hidden_fields = hidden_fields or {}
  state_hidden_fields.subscriptions = state_hidden_fields.subscriptions or {}

  if parent == nil then
    state_hidden_fields.root_parent = state
    state_hidden_fields.blackboxes = {}
    state_hidden_fields.reducers = { 
      SET = set_reducer,
      MULTI = multi_reducer,
      TOGGLE_LOG = toggle_log_reducer,
      CLEAR_LOG = clear_log_reducer,
    }
    state_hidden_fields.log = {}
    state_hidden_fields.logging = true
    index = RootStateIndex
  else 
    state_hidden_fields.root_parent = get_hidden_fields(parent).root_parent
    index = ChildStateIndex
  end 


  setmetatable(state, {
    __hidden_fields = state_hidden_fields, 
    __index = index
  })  
  return state  
end


make_state = function(value, parent, hidden_fields)
  if value == nil then
    value = {}
  end
  if type(value) ~= "table" then
    return value
  end
  hidden_fields = hidden_fields or {} 
  local state = create_empty_state(parent, hidden_fields)
  for k, v in pairs(value) do
    state[k] = make_state(v, state)
  end 
  return state
end


return make_state
