return function(state, parent)
  local menu = parent:addChild(GUI.menu(1, 1, parent.width, state.cs.menu.bg, state.cs.menu.fg, state.cs.menu.pbg, state.cs.menu.pfg))

  menu:addItem("AE2 StockKeeper", 0x0)

  menu:addItem("Reboot").onTouch = function() os.execute("reboot") end

  menu:addItem("Pull").onTouch = function() 
    local file, err = io.open("current_branch", "r")
    local current_branch = ""
    if not (err ~= nil) then
      current_branch = file:read()
      file:close()
    end
    if current_branch == "" then
      GUI.alert("No branch set as current")
      return
    end
    local file, err = io.open("branch", "w")
    if not (err == nil) then
      GUI.alert("Can not open file [branch] for write")
    end
    file:write(current_branch)
    file:close()
    GUI.alert("Requested, pull usually takes ~10 sec. Please wait and reboot.")
  end

  menu:addItem("Set branch").onTouch = function()
    local filename = "current_branch"
    local file, err = io.open(filename, "r")
    local current_branch = ""
    if not (err ~= nil) then
      current_branch = file:read()
      file:close()
    end
    local container = GUI.addBackgroundContainer(parent, true, true, "Change current git branch")
    local input = GUI.input(1, 1, 30, 3, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, current_branch, "Enter branch name")
    input.onInputFinished = function()
      local file, err = io.open(filename, "w")
      if not (err == nil) then
        GUI.alert(string.format("Can not open file [%s] for write", filename))
      end
      file:write(input.text)
      file:close()
    end
    container.layout:addChild(input)
    parent:draw()
  end

  menu:addItem("Lua").onTouch = function() 
    menu.firstParent:stop()
    screen.clear()
    screen.update()
    os.execute("lua")
    menu.firstParent:draw()
    menu.firstParent:start()
  end


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

  return menu
end