
return function(state, parent)
  local body = parent:addChild(GUI.layout(
    1, 1, parent.width, parent.height,
    1, 2
  ))

  local header = require("header")(state, body)
  local listing = require("listing")(state, body)

  body:setPosition(1, 1, header)
  body:setFitting(1, 1, 1, 1)
  body:setPosition(1, 2, listing)
  body:setFitting(1, 2, 1, 1)

    
  state.sz.body:subscribe(function(state)
    body.y = state.sz.body.y_offset
    body:setRowHeight(1, GUI.SIZE_POLICY_ABSOLUTE, state.sz.body.header_size)
    body:setRowHeight(2, GUI.SIZE_POLICY_ABSOLUTE, body.height - state.sz.body.header_size)  
  end)
  return body
end
