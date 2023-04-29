return function(state, parent, cs)
  local header = parent:addChild(GUI.layout(
    1, 1, parent.width, 1,
    4, 1
  ))
  
  local tier_label = GUI.text(1, 1, cs.fg, "???")
  header:setPosition(1, 1, header:addChild(tier_label))
  local cpus_label = GUI.text(1, 1, cs.fg, "???")
  header:setPosition(2, 1, header:addChild(cpus_label))
  local scwt_label = GUI.text(1, 1, cs.fg, "???")
  header:setPosition(3, 1, header:addChild(scwt_label))
  local running_label = GUI.text(1, 1, cs.fg, "???")
  header:setPosition(4, 1, header:addChild(running_label))
  
  local old_draw = header.draw
  header.draw = function(header)
    screen.drawRectangle(header.x, header.y, header.width, header.height, cs.bg, cs.fg, " ")
    old_draw(header)
  end

  state.tier:subscribe(
    function(state)
      tier_label.text = string.format("Tier: %d/%d", state.tier.current, state.tier.max)
    end
  )
  state.cpus:subscribe(
    function(state)
      cpus_label.text = string.format("CPUs: %d/%d", state.cpus.used, state.cpus.available)
    end
  )
  state.stats:subscribe(
    function(state)
      scwt_label.text = string.format("S/C/W/T: %d/%d/%d/%d", state.stats.stocked, state.stats.crafting, state.stats.waiting, state.stats.total)
    end
  )
  state.health:subscribe(
    function(state)
      running_label.text = string.format("Running: %s", tostring(state.health.running))
    end
  )

  return header
end
