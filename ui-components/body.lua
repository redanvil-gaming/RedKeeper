
return function(state, parent, y, sz, cs)
  local body = parent:addChild(GUI.layout(
    1, y, parent.width, parent.height,
    1, 2
  ))

  local header = require("header")(body, cs.header)
  local listing = require("listing")(body)
  
  body:setRowHeight(1, GUI.SIZE_POLICY_ABSOLUTE, sz.header.h)
  body:setRowHeight(2, GUI.SIZE_POLICY_ABSOLUTE, body.height - sz.header.h)

  body:setPosition(1, 1, header)
  body:setFitting(1, 1, 1, 1)
  body:setPosition(1, 2, listing)
  body:setFitting(1, 2, 1, 1)

  body.update = function()
    header.update()
  end
  
  return body
end
