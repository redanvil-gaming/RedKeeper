local make_state = require "lib.state"
local keeperlib = require "lib.keeperlib"
local dblib = require "lib.fl"
local bind_reducers = require "reducers"

state = bind_reducers(make_state({
  sz = {
    body = {
      y_offset = 2,
      header_size = 3,
      footer_size = 2,
    },
    listing = {
      columns = 2,
      row_h = 3,
      fields = {
        tier = 4,
        state = 3,
        stock = 12,
        required = 12,
      },
    }
  },
  cs = {
    main = {
      bg = 0x262626,
    },
    menu = {
      bg = 0xEEEEEE,
      fg = 0x666666,
      pbg = 0x3366CC,
      pfg = 0xFFFFFF,
    },
    header = {
      bg = 0x363636,
      fg = 0xFFFFFF,
    },
    footer = {
      bg = 0x363636,
      fg = 0xFFFFFF,
      button = {
        bg = 0x363636,
        fg = 0xFFFFFF,
        pressed_bg = 0x363636,
        pressed_fg = 0xFFFFFF,
      }
    },
    listing = {
      fg = 0xFFFFFF,
    }
  },
  cpus = {
    available = 10,
    used = 5,
  },
  tier = {
    current = 2,
    max = 5,
  },
  stats = {
    stocked = 0,
    crafting = 1,
    waiting = 2,
    total = 3,
  },
  listing = {
    content = {},
    pagination = {
      current = 1,
      row_c = 1,
      size = 1,
      total = 1
    },
  },
  system = {
    running = true,
    interval = 10,
    craft_every = 6,
  },
}))

keeper = keeperlib.Keeper:new(dblib.DB:new("stock.db"), component.me_controller, keeperlib.IM:new(component.inventory_controller, sides.up, 1), "~auto")

state:add_blackbox("keeper", keeper)

workspace = GUI.workspace()

workspace:addChild(GUI.panel(1, 1, workspace.width, workspace.height, state.cs.main.bg))

local menu = require("menu")(state, workspace, state.cs.menu)
local body = require("body")(state, workspace)

--------------------------------------------------------------------------------

-- initialize all auto calculated dimentions
state:update_all()
workspace:draw()

-- Start processing events for workspace

local function keeper_scrabber()
  local iter = 1
  while true do
    if state.system.running then
      keeper:refresh()
      state:dispatch("LOAD_PAGE")
      state:dispatch("SET", {path={"cpus"}, value=keeper:get_cpu_stats()})
      state:dispatch("SET", {path={"stats"}, value=keeper:get_general_stats()})
      state:dispatch("SET", {path={"tiers"}, value=keeper:get_tier_stats()})
      if iter == state.system.craft_every then
        keeper:crafting_iter()
        iter = 1
      end
      iter = iter + 1
    else
      iter = 1
    end
    os.sleep(state.system.interval)
  end
end

local function ui_dispatcher()
  workspace:start()
end

thread.waitForAny({
  thread.create(keeper_scrabber),
  thread.create(ui_dispatcher),
})
