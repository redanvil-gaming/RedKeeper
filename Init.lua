thread = require("thread")

function main()
  local timeout = 0.5
  local threads = {}

  local function kp()
    print(string.format("Init script will start in %.1f seconds", timeout))
    print("Press any key to stop init")
    io.read(1)
    pressed = true
  end

  kpt = thread.create(kp)
  local pressed = thread.waitForAny({kpt}, timeout)
  kpt:kill()
  
  if pressed then
    return
  end
  
  print("Proceeding with loading core libs")
  -- Core
  computer = require("computer")
  component = require("component")
  unicode = require("unicode")

  -- Filesystem
  Filesystem = require("Filesystem")
  local primary_fs_proxy
  for address, _ in component.list("filesystem", true) do
    primary_fs_proxy = component.proxy(address)
    if primary_fs_proxy.getLabel() == "OpenOS" then
      break
    end
  end
  Filesystem.setProxy(primary_fs_proxy)

  -- GUI
  GUI = require("GUI")
  screen = require("Screen")
  color = require("Color")
  screen.setGPUAddress(component.gpu.address)

  -- Startup
  require("UI")
end

main()
