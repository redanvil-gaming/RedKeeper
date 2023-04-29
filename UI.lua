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
      abg = 0x363636,
      afg = 0xFF0000,
      sbg = 0x464646,
      sfg = 0x0000FF,
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

local workspace = GUI.workspace()

workspace:addChild(GUI.panel(1, 1, workspace.width, workspace.height, cs.bg))

local menu = require("menu")(workspace, cs.menu)
local body = require("body")(workspace, sz.menu, sz.body, cs.body)

--------------------------------------------------------------------------------


-- Draw workspace content once on screen when program starts
workspace:draw()
-- Start processing events for workspace
workspace:start()
