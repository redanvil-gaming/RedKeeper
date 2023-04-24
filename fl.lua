--[[

  Fuck my Life of File Loader (and database)

--]]


local fs = require("filesystem")
local serialization = require("serialization")
local base64 = require("base64")
local strictness = require("strictness")

local L = {} -- local namespace ( L - Library)
local Item = {} -- class
local Item_obj = {} -- class object
local Item_fmt = string.format("T-%%-%dd [%%1s] %%-%ds %%%dd/%%-%dd", 2, 40, 5, 5)
L.Item = Item
local DB = {} -- Data Base
local DB_obj = {} -- Data Base object
L.DB = DB
L.docs = {}
L.docs.Item = {}
L.docs.Item_obj = {}
L.docs.DB = {}
L.docs.DB_obj = {}

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
function L.docs.Item.new()
  print("class function Item:new() or Item()\ncreates a blank strict Item instance with methods attached")
end
setmetatable(Item, { __call = Item.new })


function Item_obj:format(state, current)
  return string.format(Item_fmt, self.tier or -1, state, self.display_name, current, self.required_amount)
end
function L.docs.Item_obj.format()
  print("bound function Item_obj:format()\nFormats item for display\nparams:\n  state: string; state label\n    `c` for crafting\n    `-` for needs to be crafted\n    `+` for stored\n  current: number, current items in stock\nreturns: str, formatted string")
end


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
function L.docs.Item_obj.spec_weak_eq()
  print("bound function Item_obj:spec_weak_eq()\nchecks if item spec corresponds to given spec, `nil` equals to anything\nparams:\n  spec: table, as returned from getStackFromSlot or simmilar")
end


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

function L.docs.Item_obj._dump()
  print("bound function Item_obj:dump()\nPrepares item to be dumped on disk\nreturns: str, new non-strict table with escaped fields")
end


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
function L.docs.Item.create()
  print("class function Item:create{}\nconvinience function to create item from flat keyword structure\nneeds to be called with curly braces\nexample:\n  Item:create{name=\"Item name\", required=10, id=14}\nparams:\n  name: required, string; raw mc name of the item\n  required: required, number; amount of items to keep in stock\n  id: required, number; internal item id\n  tier: optional, number; tier or priority of an item, if nil item is always watched, if n number will be attempted to be crafted only after all items with tier less than n are stocked\n  label: optional, string; raw mc label of the item\n  tag: optional, string; raw mc tag of the item\n  charge: optional, number; raw mc charge value of the item\n  damage: optional, number; raw mc damage value of the item\n  display: optional, string; display name for the item, if nil label or name is substituted\nreturns: Item, created item")
end


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
function L.docs.Item.load()
  print("class function Item:load()\ninverse of Item_obj:dump(), restores escaped representation into regular one\nparams:\n  uncerialized: table; table read from disk\nreturns: Item, restored item")
end


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
function L.docs.load()
  print("function load()\nloads full item database from file\nparams:\n  filename: string; file to read from\nreturns: table, {tier: {number: Item}}")
end

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
function L.docs.save()
  print("function save()\nsaves items list to file\nparams:\n  filename: string; file to write to\nitems: table, {tier: {number: Item}}")
end

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
function L.docs.DB.new()
  print("class function DB:new()\ncreates database object\nparams:\n  filename: string; file for database, will be created if does not exist\nreturns DB_obj; new db")
end
setmetatable(DB, { __call = DB.new })


function DB_obj:filename()
  return self._filename
end
function L.docs.DB_obj.filename()
  print("bound function DB_obj:filename()\ngetter for filename\nreturns string; db filename")
end


function DB_obj:take_id()
  self._item_seq = self._item_seq + 1
  return self._item_seq
end
function L.docs.DB_obj.take_id()
  print("bound function DB_obj:take_id()\ngenerate new ID\nreturns number; unused ID")
end


function DB_obj:db_exists()
  local f = io.open(self:filename(), "r")
  if f ~= nil then 
    io.close(f)
    return true
  end
  return false
end
function L.docs.DB_obj.db_exists()
  print("bound function DB_obj:db_exists()\ncheck if database exists\nreturns bool; true if exists")
end


function DB_obj:flush()
  L.save(self:filename(), self._items)
end
function L.docs.DB_obj.flush()
  print("bound function DB_obj:flush()\nflushes internal state on disk")
end


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
function L.docs.DB_obj.refresh()
  print("bound funciton DB_obj:refresh()\nreads contents from disl")
end


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
function L.docs.DB_obj.add()
  print("bound function DB_obj:add()\nadds item to database with new id\nsee docs.Item.create() for more info\nadditional mentions:\n  if id is not provided it is substituted by db:take_id()\nadditional params:\n  stack: optional, table; table returned from getStackInSlot() or simmilar functions, has lower priority than directly specified params.")
end


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
function L.docs.DB_obj.delete()
  print("bound function DB_obj:delete()\nremoves item from database\nparams:\n  item: Item_obj; must have tier and id fields set")
end


local function tier_iterator(state, idx)
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
function L.docs.DB_obj.iter_tier()
  print("bound function DB_obj:iter_tier()\niterates over items of specific tier\nparams:\n  tier: number; tier number\nreturns: iterator of Item_obj for specifed tier\nexample:\n  for item in db:iter_tier(0) do ... end")
end


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
function L.docs.DB_obj.iter_items()
  print("bound function DB_obj:iter_items()\niterates over all items tier by tier\nreturns: iterator of Item_obj\nexample:\n  for item in db:iter_items() do ... end")
end


return L

