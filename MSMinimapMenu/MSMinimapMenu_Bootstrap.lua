-- MSMinimapMenu_Bootstrap.lua
-- MS Minimap Menu 1.0.12 early command bootstrap for the WoW 1.12.1 client.
-- Loaded before the core so commands remain available for load diagnostics.

MSMinimapMenu = MSMinimapMenu or {}
local MSM = MSMinimapMenu
-- Temporary runtime compatibility alias for the former addon table.
OctoMinimapMenu = MSMinimapMenu

MSM.bootstrapLoaded = 1
MSM.bootstrapVersion = "1.0.12"
MSM.loadStage = MSM.loadStage or "bootstrap loaded"

local function BootstrapPrint(message)
  if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccMS Minimap Menu:|r " .. tostring(message or ""))
  end
end

SlashCmdList = SlashCmdList or {}

function MSMinimapMenu_CommandDispatch(message)
  local command = string.lower(tostring(message or ""))
  local ok, errorText

  if command == "bootstrap" or command == "loadstatus" then
    BootstrapPrint("Bootstrap " .. tostring(MSM.bootstrapVersion)
      .. " | stage: " .. tostring(MSM.loadStage or "unknown")
      .. " | core: " .. (MSM.coreLoaded and "loaded" or "not loaded")
      .. " | initialized: " .. (MSM.initialized and "yes" or "no"))
    if MSM.loadError then BootstrapPrint("Last initialization error: " .. tostring(MSM.loadError)) end
    return
  end

  if not MSM.coreLoaded or type(MSM.HandleSlash) ~= "function" then
    BootstrapPrint("The command bootstrap loaded, but the core did not finish loading.")
    BootstrapPrint("Load stage: " .. tostring(MSM.loadStage or "unknown")
      .. ". Use /console scriptErrors 1 and /reload for the underlying error.")
    return
  end

  if not MSM.initialized and type(MSM.TryInitialize) == "function" then
    MSM:TryInitialize("slash command")
  end

  if not MSM.initialized then
    BootstrapPrint("The core loaded, but initialization is not complete.")
    if MSM.loadError then BootstrapPrint("Last initialization error: " .. tostring(MSM.loadError)) end
    return
  end

  ok, errorText = pcall(MSM.HandleSlash, MSM, message)
  if not ok then
    MSM.loadError = tostring(errorText)
    BootstrapPrint("Command failed: " .. tostring(errorText))
  end
end

-- Primary MoobStack aliases.
SLASH_MSMINIMAPMENU1 = "/msminimap"
SLASH_MSMINIMAPMENU2 = "/msmm"
SLASH_MSMINIMAPMENU3 = "/msminimapmenu"
-- Legacy aliases retained for existing macros and user habits.
SLASH_MSMINIMAPMENU4 = "/omm"
SLASH_MSMINIMAPMENU5 = "/octominimap"
SLASH_MSMINIMAPMENU6 = "/octomapmenu"

OctoMinimapMenu_CommandDispatch = MSMinimapMenu_CommandDispatch
SlashCmdList["MSMINIMAPMENU"] = MSMinimapMenu_CommandDispatch
SlashCmdList["OCTOMINIMAPMENU"] = MSMinimapMenu_CommandDispatch
