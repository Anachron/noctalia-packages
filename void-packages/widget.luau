noctalia.setUpdateInterval(1000)

barWidget.setGlyph("package")
barWidget.setColor("primary")

local localUpdates = "?"
local remoteUpdates = "?"

local function render()
  local checkRemote = noctalia.getConfig("remote_updates")
  if checkRemote == true then
    barWidget.setText(localUpdates .. "/" .. remoteUpdates)
  else
    barWidget.setText(localUpdates)
  end
end

noctalia.state.watch("localUpdates", function(value)
  localUpdates = value
  render()
end)

noctalia.state.watch("remoteUpdates", function(value)
  remoteUpdates = value
  render()
end)

render()
