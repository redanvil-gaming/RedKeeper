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


function RootStateIndex.dispatch(state, tp, data)
  local reducer = get_hidden_fields(state).reducers[tp]
  if reducer == nil then
    return
  end 
  for idx, callback in ipairs(reducer(state, data)) do
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


local function multi_reducer(state, events)
  local callbacks = {}
  for idx, entry in pairs(events) do
    local reducer = get_hidden_fields(state).reducers[entry.type]
    if reducer ~= nil then
      for idx, callback in ipairs(reducer(state, entry.data)) do
        table.insert(callbacks, callback)
      end
    end
  end
  return callbacks
end


function ChildStateIndex.dispatch(state, tp, data)
  get_hidden_fields(state).root_parent:dispatch(type, data)
end


local function state_subscribe(state, callback)
  local key = "s"..#get_hidden_fields(state).subscriptions
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
    }   
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
