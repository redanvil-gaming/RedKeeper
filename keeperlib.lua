--[[

  basic stockpile API
  it has no while(true) do stockpile()
  but it provides all basic functionality
  

  Tier goes from 1 to inf (smaller goes first)
  Tier 0 is special [do not touch]
]]

local strictness = require("strictness")

local L = {}
local IM = {} --Item Manager
local IM_obj = {} --Item manager Object 
L.IM = IM

function IM:new(ic, side, slot) -- inventory controller, sides, slot TODO : fuck it
  local im = setmetatable(
    { ic = ic, side = side, slot = slot },
    { __index = function(t, k) return rawget(IM_obj, k) end }
  )
  im = strictness.strict(im, "ic", "side", "slot")
  return im
end
setmetatable(IM, { __call = IM.new })


function IM_obj:get() -- getStakInSlot TODO : rename, maybe ?
  return self.ic.getStackInSlot(self.side, self.slot)
end


local Keeper = {} -- stockpile api class
local Keeper_obj = {} -- stockpile api obj
L.Keeper = Keeper

function Keeper:new(db, me, im, cpu_filter) 
  -- fl.DB("stockpile.db"), 
  -- component.me_controller, 
  -- keeperlib.IM(component.inventory_controller, sides.side, slot_number), 
  -- cpu_filter_string (can be nil)
  local keeper = setmetatable(
    {db = db, me = me, im = im, cpu_filter = cpu_filter},
    { __index = function(t, k) return rawget(Keeper_obj, k) end} -- TODO : Yarik, wtf is that ?
  )
  keeper = strictness.strict(keeper, "db", "me", "im", "cpu_filter", "_tasks", "_cpus") -- strct about adding or geting value by new key
  keeper:refresh()
  return keeper
end

setmetatable(Keeper, { __call = Keeper.new }) -- to type Keeper() instead of Keeper.new()

local function check_filter_match(item, status, stock, filter) -- UNFINISHED 
--smth for when we want to filter display output
  local b -- fuck it
  local e -- fuck it
  if filter.display_name ~= nil and string.find(item.display_name, filter.display_name) == nil then
    return false
  end
  return true
end

function Keeper_obj:format_list(c, page, filter) --UNTESTED
-- c-count, page-screen pages
  page = page or 0
  filter = filter or {}
  local offset = page * c
  local results = {}
  for item in self.db:iter_items() do
    if offset == 0 and c > 0 then
      local stock = self:item_stock(item)
      local status = self:item_status(item)
      if check_filter_match(item, status, stock, filter) then
        table.insert(results, item:format(status,stock))
      end
      c = c - 1
    else
      offset = offset - 1
    end
  end
  return results
end


function Keeper_obj:item_status(item)
  --[[
  c - crafting
  ? - not 1 craft found
  - - not enought items
  + - enought items
  ]]
  if self._tasks[item.id] ~= nil then
    return "c"
  end
  if #self.me.getCraftables(item.spec) ~= 1 then
    return "?"
  end
  if item.required_amount > self:item_stock(item) then
    return "-"
  end
  return "+"
end


function Keeper_obj:item_stock(item)
  local sum = 0
  for idx, stack in pairs(self.me.getItemsInNetwork(item.spec)) do --looks sus [for NBT reasons]
    --TODO : log if #self.me.getItemsInNetwork(item.spec) ~= 1
    sum = sum + stack.size
  end
  return sum
end


function Keeper_obj:refresh_cpus()
  self._cpus = {}
  for idx, spec in pairs(self.me.getCpus()) do 
    if self.cpu_filter == nil and spec.name == "" then
      table.insert(self._cpus, spec)
    end
    if self.cpu_filter ~= nil and string.find(spec.name, self.cpu_filter) ~= nil then
      table.insert(self._cpus, spec)
    end
  end
end


function Keeper_obj:refresh_tasks()
  self._tasks = {}
  for idx, cpu in pairs(self._cpus) do
    if cpu.busy then
      for item in self.db:iter_items() do
        if item:spec_weak_eq(cpu.cpu.finalOutput()) then -- TODO : unfuck it
          self._tasks[item.id] = idx
        end
      end
    end
  end
end


function Keeper_obj:refresh()
  self:refresh_cpus()
  self:refresh_tasks()
end


function Keeper_obj:start_crafts() -- launch all '-' items crafting
  local last_requested_tier = 0
  local attempting_cpu = next(self._cpus, nil)
  for item in self.db:iter_items() do
    if last_requested_tier ~= 0 and last_requested_tier ~= item.tier then -- still not sure about it
      return
    end
    if self:item_status(item) == '-' then
      local craftable = self.me.getCraftables(item.spec)[1] -- TODO error handle !?
      while attempting_cpu ~= nil and self._cpus[attempting_cpu].busy do
        attempting_cpu = next(self._cpus, attempting_cpu)
      end
      if attempting_cpu == nil then
        return
      end
      craftable.request(item.required_amount - self:item_stock(item), true, self._cpus[attempting_cpu].name)
      last_requested_tier = item.tier
    end
  end
end


function Keeper_obj:crafting_iter() -- not iterator but iteration
  self:refresh_cpus()
  self:refresh_tasks()
  self:start_crafts()
end

function Keeper_obj:ui() -- console keeper status output
  for idx, row in pairs(self:format_list(10)) do
    print(row)
  end
end


function Keeper_obj:add(options) -- TODO : check error handling
  local stack = self.im:get()
  if stack == nil then
    print("Please insert the item")
    return
  end
  options.tier = options.tier or 0
  if options.damage == nil then
    if options.meta ~= nil then
      options.damage = options.meta
    else
      options.damage = true
    end
  end
  options.charge = options.charge or false

  if type(options.tier) ~= "number" then
    print("parameter `tier` must have type `number`")
    return
  end
  if type(options.required) ~= "number" then
    print("parameter `required` must have type `number`")
    return
  end
  if options.display ~= nil and type(options.display) ~= "string" then
    print("parameter `display` must have type `string`")
    return
  end

  if not options.damage then
    stack.damage = nil
  end
  if not options.charge then
    stack.charge = nil
  end
  self.db:add{tier=options.tier, display=options.display, required=options.required, stack=stack}
  self:refresh()
end

return L

