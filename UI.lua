local make_state = require "lib.state"
local keeperlib = require "lib.keeperlib"
local dblib = require "lib.fl"
local bind_reducers = require "reducers"

local state = bind_reducers(make_state({
  sz = {
    body = {
      y_offset = 2,
      header_size = 3,
      footer_size = 2,
    },
    listing = {
      columns = 2,
      row_h = 3,
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
      total = 5,
    },
  },
  health = {
    running = true,
  }
}))

keeper = keeperlib.Keeper(dblib.DB("stock.db"), component.me_controller, keeperlib.IM(component.inventory_controller, sides.up, 1))

state:add_blackbox("keeper", keeper)

local workspace = GUI.workspace()

workspace:addChild(GUI.panel(1, 1, workspace.width, workspace.height, state.cs.main.bg))

local menu = require("menu")(state, workspace, state.cs.menu)
local body = require("body")(state, workspace)

state:update_all()

--------------------------------------------------------------------------------

-- Draw workspace content once on screen when program starts
workspace:draw()
-- Start processing events for workspace
workspace:start()
