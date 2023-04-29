local cs = {
  bg = 0x262626,
  menu = {
    bg = 0xEEEEEE,
    fg = 0x666666,
    pbg = 0x3366CC,
    pfg = 0xFFFFFF,
  },
  header = {
    bg = 0x363636,
    fg = 0x0,
    abg = 0x363636,
    afg = 0xFF0000,
    sbg = 0x464646,
    sfg = 0x0000FF,
  },
}

local sz = {
  menu = 2,
  header = {
    h = 3,
    itemSize = 3,
    spacing = 5,
  },
}

local workspace = GUI.workspace()

workspace:addChild(GUI.panel(1, 1, workspace.width, workspace.height, cs.bg))

local menu = workspace:addChild(GUI.menu(1, 1, workspace.width, cs.menu.bg, cs.menu.fg, cs.menu.pbg, cs.menu.pfg))

menu:addItem("AE2 StockKeeper", 0x0)

menu:addItem("Reboot").onTouch = function() os.execute("reboot") end


local cs_menu = menu:addContextMenuItem("Preferences")

cs_menu:addItem("Reload CS")
cs_menu:addItem("Set default CS")
cs_menu:addItem("Copy CS")
cs_menu:addItem("Alter CS")
cs_menu:addItem("Delete CS")
cs_menu:addSeparator()
cs_menu:addItem("Reload sizes")
cs_menu:addItem("Set default sizes")
cs_menu:addItem("Copy sizes")
cs_menu:addItem("Alter sizes")
cs_menu:addItem("Delete sizes")


local body = require("body")(workspace, sz.menu, sz, cs)

--------------------------------------------------------------------------------


-- Draw workspace content once on screen when program starts
workspace:draw()
-- Start processing events for workspace
workspace:start()
