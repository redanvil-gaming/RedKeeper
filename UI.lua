local cs = {
  bg = 0x262626,
  menu = {
    bg = 0xEEEEEE,
    fg = 0x666666,
    pbg = 0x3366CC,
    pfg = 0xFFFFFF,
  },
  body = {
    header = {
      bg = 0x363636,
      fg = 0x0,
    },
  }
}

local sz = {
  menu = 2,
  body = {
    header = {
      h = 3,
      itemSize = 3,
      spacing = 5,
    },
  }
}

local state = {
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
  running = true,
  listing = {},
  page = 1,
}

local workspace = GUI.workspace()

workspace:addChild(GUI.panel(1, 1, workspace.width, workspace.height, cs.bg))

local menu = require("menu")(state, workspace, cs.menu)
local body = require("body")(state, workspace, sz.menu, sz.body, cs.body)

body.update_data()

--------------------------------------------------------------------------------


-- Draw workspace content once on screen when program starts
workspace:draw()
-- Start processing events for workspace
workspace:start()
