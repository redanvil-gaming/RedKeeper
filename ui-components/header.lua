return function(parent)
  local header = parent:addChild(GUI.layout(
    1, 1, parent.width, 1,
    4, 1
  ))
  
  header:setPosition(1, 1, header:addChild(GUI.text(1, 1, fg, "Tier: 2/5")))
  header:setPosition(2, 1, header:addChild(GUI.text(1, 1, fg, "CPUS: 2/5")))
  header:setPosition(3, 1, header:addChild(GUI.text(1, 1, fg, "S/C/W/A: 2/5/3/10")))
  header:setPosition(4, 1, header:addChild(GUI.text(1, 1, fg, "Running: V")))
  
  return header
end
