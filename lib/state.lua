local make_state


local RootStateIndex = {}
local ChildStateIndex = {}


local function get_hidden_fields(state)
  return getmetatable(state).__hidden_fields
end


function RootStateIndex.add_reducer(state, tp, reducer)
  get_hidden_fields(state).reducers[tp] = reducer
end


function RootStateIndex.dispatch(state, tp, data)
  local dispatcher = get_hidden_fields(state).dispatchers[tp]
  if dispatcher == nil then
    return
  end 
  for idx, callback in ipairs(dispatcher(state, data)) do
    callback(state)
  end
end


local function set_reducer(state, data)
  local current = state
  local callbacks = {}
  for idx, token in ipairs(data.path) do
    for i, callback in ipairs(get_hidden_fields(current).subscriptions) do
      table.insert(callbacks, callback)
    end
    if idx == #data.path then
      current[token] = make_state(data.value)
    else
      current = current[token]
    end
  end
  return callbacks
end


local function multiset_reducer(state, data)
  local callbacks = {}
  for idx, entry in pairs(data) do
    for idx, callback in ipairs(set_reducer(state, entry)) do
      table.insert(callbacks, callback)
    end
  end
  return callbacks
end


function ChildStateIndex.dispatch(state, tp, data)
  get_hidden_fields(state).root_parent:dispatch(type, data)
end


local function state_subscribe(state, callback)
  table.insert(get_hidden_fields(state).subscriptions, callback)
end
RootStateIndex.subscribe = state_subscribe
ChildStateIndex.subscribe = state_subscribe


local function update_all(state)
  for idx, callback in ipairs(get_hidden_fields(state).subscriptions) do
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


local function create_empty_state(parent)
  local state = {}
  local index = nil
  state_hidden_fields = { 
    subscriptions = {}
  }

  if parent == nil then
    state_hidden_fields.root_parent = state
    state_hidden_fields.reducers = { 
      SET = set_reducer,
      MULTISET = multiset_reducer,
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


make_state = function(value, parent)
  if value == nil then
    value = {}
  end 
  if type(value) ~= "table" then
    return value
  end 
  local state = create_empty_state(parent)
  for k, v in pairs(value) do
    state[k] = make_state(v, state)
  end 
  return state
end


return make_state
