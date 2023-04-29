return function(parent, cs)
  local header = parent:addChild(GUI.layout(
    1, 1, parent.width, 1,
    4, 1
  ))
  
  header:setPosition(1, 1, header:addChild(GUI.text(1, 1, cs.fg, "Tier: 2/5")))
  header:setPosition(2, 1, header:addChild(GUI.text(1, 1, cs.fg, "CPUS: 2/5")))
  header:setPosition(3, 1, header:addChild(GUI.text(1, 1, cs.fg, "S/C/W/A: 2/5/3/10")))
  header:setPosition(4, 1, header:addChild(GUI.text(1, 1, cs.fg, "Running: V")))
  
  local old_draw = header.draw
  header.draw = function(header)
    screen.drawRectangle(header.x, header.y, header.width, header.height, cs.bg, cs.fg, " ")
    old_draw(header)
  end

  return header
end
