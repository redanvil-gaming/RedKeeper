return function(state, parent)
  return parent:addChild(GUI.layout(
    1, 1, parent.width, 1,
    2, 1
  ))
end