local fs = require("filesystem")
local serialization = require("serialization")
local base64 = require("base64")
local strictness = require("strictness")
local tablefunc = require "lib.tablefunc"

-- local funcDoc = function(func, string) -- not sure if its a good idea
--   func = tablefunc(func, string)
-- end

-- TODO (RedMage) : rename L to fl

local L = {}
local Item = {}
local Item_obj = {}
local Item_fmt = string.format("T-%%-%dd [%%1s] %%-%ds %%%dd/%%-%dd", 2, 40, 5, 5)
L.Item = Item
local DB = {}
local DB_obj = {}
L.DB = DB


local item_obj_fields = {"spec", "display_name", "tier", "id", "required_amount"}
local item_obj_spec_fields = {"name", "label", "charge", "damage"}

function Item:new()
  if self ~= Item then
    error("Inappropriate use of Item constructor")
  end

  local item = setmetatable({}, {
    __index = function(t, k) return rawget(Item_obj, k) end
  })
  item = strictness.strict(item, table.unpack(item_obj_fields))
  item.spec = strictness.strict({}, table.unpack(item_obj_spec_fields))
  return item
end
Item.new = tablefunc.funcWrapper(Item.new,
[[class function Item:new() or Item()
creates a blank strict Item instance with methods attached]])
setmetatable(Item, { __call = Item.new })


function Item_obj:format(state, current)
  return string.format(Item_fmt, self.tier or -1, state, self.display_name, current, self.required_amount)
end
Item_obj.format = tablefunc.funcWrapper(Item_obj.format, -- TODO(RedMage) : document '?' state
[[bound function Item_obj:format()
Formats item for display\nparams:
state: string; state label
  `c` for crafting
  `-` for needs to be crafted
  `+` for stored\n  current: number, current items in stock
returns: str, formatted string]])



function Item_obj:spec_weak_eq(spec)
  if spec == nil then
    return false
  end
  for idx, field in pairs(item_obj_spec_fields) do
    if spec[field] ~= nil and self.spec[field] ~= nil then
      if self.spec[field] ~= spec[field] then
        return false
      end
    end
  end
  return true
end
Item_obj.spec_weak_eq = tablefunc.funcWrapper(Item_obj.spec_weak_eq,
[[bound function Item_obj:spec_weak_eq()
  checks if item spec corresponds to given spec, `nil` equals to anything
  params:
    spec: table, as returned from getStackFromSlot or simmilar]]) 



function Item_obj:_dump()
  local serialized = {}
  for idx, field in pairs(item_obj_fields) do
    serialized[field] = self[field]
  end
  serialized.spec = {}
  for idx, field in pairs(item_obj_spec_fields) do
    serialized.spec[field] = self.spec[field]
  end
  return serialized
end
Item_obj._dump = tablefunc.funcWrapper(Item_obj._dump,
[[bound function Item_obj:dump()
  Prepares item to be dumped on disk
  returns: str, new non-strict table with escaped fields]])


function Item:create(options)
  if self ~= Item then
    error("Inappropriate use of Item:create")
  end
  if type(options.name) ~= "string" then
    error("parameter `name` must be provided and have type `string`")
  end
  if type(options.required) ~= "number" then
    error("parameter `required` must be provided and have type `number`")
  end
  if options.id ~=nil and type(options.id) ~= "number" then
    error("parameter `id` must have type `number`")
  end
  if options.label ~= nil and type(options.label) ~= "string" then
    error("parameter `label` must have type `string`")
  end
  if options.charge ~= nil and type(options.charge) ~= "number" then
    error("parameter `charge` must have type `number`")
  end
  if options.damage ~= nil and type(options.damage) ~= "number" then
    error("parameter `damage` must have type `number`")
  end
  if options.tier ~= nil and type(options.tier) ~= "number" then
    error("parameter `tier` must have type `number`")
  end
  if options.display ~= nil and type(options.display) ~= "string" then
    error("parameter `display` must have type `string`")
  end

  local item = Item:new()
  item.display_name = options.display or options.label or options.name
  item.required_amount = options.required
  item.id = options.id
  item.tier = options.tier or 0
  item.spec.name = options.name
  item.spec.label = options.label
  item.spec.charge = options.charge
  item.spec.damage = options.damage
  return item
end
Item.create = tablefunc.funcWrapper(Item.create, 
[[class function Item:create{}
  convinience function to create item from flat keyword structure
  needs to be called with curly braces
  example:
    Item:create{name="Item name", required=10, id=14}
  params:
    name: required, string; raw mc name of the item
    required: required, number; amount of items to keep in stock
    id: required, number; internal item id
    tier: optional, number; tier or priority of an item, if nil item is always watched, if n number will be attempted to be crafted only after all items with tier less than n are stocked
    label: optional, string; raw mc label of the item
    tag: optional, string; raw mc tag of the item
    charge: optional, number; raw mc charge value of the item
    damage: optional, number; raw mc damage value of the item
    display: optional, string; display name for the item, if nil label or name is substituted
returns: Item, created item]])



function Item:load(unserialized)
  if self ~= Item then
    error("Inappropriate use of Item:load")
  end
  return Item:create{
    display=unserialized.display_name,
    required=unserialized.required_amount,
    id=unserialized.id,
    tier=unserialized.tier,
    name=unserialized.spec.name,
    label=unserialized.spec.label,
    charge=unserialized.spec.charge,
    damage=unserialized.spec.damage,
  }
end
Item.load = tablefunc.funcWrapper(Item.load, 
[[class function Item:load()
  inverse of Item_obj:dump(), restores escaped representation into regular one
  params:
    uncerialized: table; table read from disk
returns: Item, restored item]])



function L.load(filename)
  local file, err = io.open(filename, "r")
  if not (err == nil) then
    error(string.format("Can not open stockpile file [%s] for read", filename))
  end
  pre_data = serialization.unserialize(file:read("*a"))
  data = {}
  for tier, items in pairs(pre_data) do
    data[tier] = {}
    for index, value in pairs(items) do
      data[tier][index] = Item:load(value)
    end
  end
  file:close()
  return data
end
L.load = tablefunc.funcWrapper(L.load,
[[function load()
  loads full item database from file
  params:
    filename: string; file to read from
returns: table, {tier: {number: Item}}]])


function L.save(filename, tiers)
  local file, err = io.open(filename, "w")
  if not (err == nil) then
    error(string.format("Can not open stockpile file [%s] for write", filename))
  end
  post_data = {}
  for tier, items in pairs(tiers) do
    post_data[tier] = {}
    for index, value in pairs(items) do
      post_data[tier][index] = value:_dump()
    end
  end
  file:write(serialization.serialize(post_data))
  file:close()
end
L.save = tablefunc.funcWrapper(L.save, 
[[function save()
  saves items list to file
  params:
    filename: string; file to write to
    items: table, {tier: {number: Item}}
]])


-- Database part

function DB:new(filename)
  if self ~= DB then
    error("Inapropriate call to DB:new(), first argument must be DB, prehaps you used DB.new() instead of DB:new()")
  end
  if type(filename) == "table" and type(filename.filename) == "string" then
    filename = filename.filename
  end
  if type(filename) ~= "string" then
    error("Inapropriate call to DB:new(), must be called with exactly one argument `filename`, named or annamed")
  end
  local db = setmetatable({}, {
    __index = function(t, k) return rawget(DB_obj, k) end,
    __tostring = function() return string.format("DB{filename=\"%s\"}", filename) end
  })
  db = strictness.strict(db, "_filename", "_items", "_item_seq")
  db._filename = filename
  db._items = {}
  db._item_seq = 0
  db:refresh()
  return db
end
DB.new = tablefunc.funcWrapper(DB.new,
[[class function DB:new()
  creates database object
  params:
    filename: string; file for database, will be created if does not exist
returns DB_obj; new db
]])
setmetatable(DB, { __call = DB.new })


function DB_obj:filename() 
  return self._filename
end
DB_obj.filename = tablefunc.funcWrapper(DB_obj.filename,
[[bound function DB_obj:filename()
  getter for filename
returns string; db filename]])



function DB_obj:take_id()
  self._item_seq = self._item_seq + 1
  return self._item_seq
end
DB_obj.take_id = tablefunc.funcWrapper(DB_obj.take_id, 
[[bound function DB_obj:take_id()
  generate new ID
returns number; unused ID]])



function DB_obj:db_exists()
  local f = io.open(self:filename(), "r")
  if f ~= nil then 
    io.close(f)
    return true
  end
  return false
end
DB_obj.db_exists = tablefunc.funcWrapper(DB_obj.db_exists,
[[bound function DB_obj:db_exists()
  check if database exists
  returns bool; true if exists]])



function DB_obj:flush()
  L.save(self:filename(), self._items)
end
DB_obj.flush = tablefunc.funcWrapper(DB_obj.flush, 
[[bound function DB_obj:flush()
  flushes internal state on disk]])



function DB_obj:refresh()
  if not self:db_exists() then
    self:flush()
  end
  self._items = L.load(self:filename())
  for item in self:iter_items() do
    if item.id > self._item_seq then
      self._item_seq = item.id
    end
  end
end
DB_obj.refresh = tablefunc.funcWrapper(DB_obj.refresh,
[[bound funciton DB_obj:refresh()
reads contents from disl]])



function DB_obj:add(options)
  if options.id == nil then
    options.id = self:take_id()
  end
  if options.stack ~= nil then
    options.name = options.name or options.stack.name
    options.label = options.label or options.stack.label
    options.tag = options.tag or options.stack.tag
    options.damage = options.damage or options.stack.damage
    options.charge = options.charge or options.stack.charge
  end
  local addition = Item:create(options)
  if self._items[addition.tier] == nil then
    self._items[addition.tier] = {}
  end
  self._items[addition.tier][addition.id] = addition
  self:flush()
end
DB_obj.add = tablefunc.funcWrapper(DB_obj.add, 
[[bound function DB_obj:add()
  adds item to database with new id
  see docs.Item.create() for more info
  additional mentions:
    if id is not provided it is substituted by db:take_id()
  additional params:
    stack: optional, table; table returned from getStackInSlot() or simmilar functions, has lower priority than directly specified params.]])



function DB_obj:delete(item)
  if item.tier == nil or item.id == nil then
    error("DB_obj:delete, fields `tier` and `id` must be set in the item")
  end
  if self[item.tier] == nil or self[item.tier][item.id] == nil then
    return
  end
  self[item.tier][item.id] = nil
  if #self[item.tier] == 0 then
    self[item.tier] = nil
  end
  self:flush()
end
DB_obj.delete = tablefunc.funcWrapper(DB_obj.delete,
[[bound function DB_obj:delete()
  removes item from database
  params:
    item: Item_obj; must have tier and id fields set]])



local function tier_iterator(state, idx) --internal function no documentation needed
  if state == nil then
    return nil
  end
  local id = idx.id
  id = next(state, id)
  if id == nil then
    return nil
  end
  return state[id]
end


function DB_obj:iter_tier(tier)
  return tier_iterator, self._items[tier], { id = nil }
end
DB_obj.iter_tier = tablefunc.funcWrapper(DB_obj.iter_tier,
[[bound function DB_obj:iter_tier()
  iterates over items of specific tier\nparams:
    tier: number; tier number\nreturns: iterator of Item_obj for specifed tier
  example:
    for item in db:iter_tier(0) do ... end]]) 



local function items_iterator(state, idx)
  local tier = idx.tier
  local id = idx.id
  if tier == nil then
    tier, _ = next(state, nil)
  end
  if tier == nil then
    return nil
  end
  id, _ = next(state[tier], id)
  while id == nil do
    tier, _ = next(state, tier)
    if tier == nil then
      return nil
    end
    id, _ = next(state[tier], nil)
  end

  return state[tier][id]
end

function DB_obj:iter_items()
  table.sort(self._items)
  return items_iterator, self._items, { tier = nil, id = nil }
end
DB_obj.iter_items = tablefunc.funcWrapper(DB_obj.iter_items,
[[bound function DB_obj:iter_items()
  iterates over all items tier by tier
returns: iterator of Item_obj
  example:
    for item in db:iter_items() do ... end]])



return L

