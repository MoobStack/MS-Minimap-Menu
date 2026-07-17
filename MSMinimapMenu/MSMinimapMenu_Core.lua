-- MSMinimapMenu_Core.lua
-- Minimalist minimap button list for World of Warcraft 1.12.1.

MSMinimapMenu = MSMinimapMenu or {}
-- Temporary runtime compatibility alias for integrations that referenced the
-- former addon table. New code should use MSMinimapMenu.
OctoMinimapMenu = MSMinimapMenu
local MSM = MSMinimapMenu

MSM.displayName = "MS Minimap Menu"
MSM.publisher = "MoobStack"
MSM.version = "1.0.11"
MSM.versionNumber = 10011
MSM.interfaceVersion = 11200
MSM.addonName = "MSMinimapMenu"
MSM.coreLoaded = nil
MSM.loadStage = "core file executing"
MSM.loadError = nil
MSM.legacyBridgeLoaded = nil
MSM.legacyImportedAtLoad = nil
MSM.legacyMigrationSourceVersion = "1.0.10"
MSM.entries = MSM.entries or {}
MSM.entryOrder = MSM.entryOrder or {}
MSM.hiddenFrames = MSM.hiddenFrames or {}
MSM.collectorFrames = MSM.collectorFrames or {}
MSM.rows = MSM.rows or {}
MSM.scanPending = 1
MSM.scanAt = 0
MSM.lastScan = 0
MSM.initialized = nil
MSM.menuOpen = nil
MSM.suppressMessages = nil
MSM.lastScanError = nil
MSM.scanFailures = 0
MSM.scanStats = { roots = 0, candidates = 0, invalid = 0, captured = 0, scopeRejected = 0, mode = "event-driven-minimap-scope" }
MSM.worldReady = nil
MSM.scanInProgress = nil
MSM.globalRegistry = MSM.globalRegistry or {}
MSM.globalScanPending = nil
MSM.lastGlobalScan = 0
MSM.lastDeepScan = 0
MSM.nextHiddenMaintenance = 0
MSM.updateAccumulator = 0
MSM.addonNameIndex = MSM.addonNameIndex or {}
MSM.addonIndexBuilt = nil

local DEFAULTS = {
  version = MSM.versionNumber,
  enabled = 1,
  locked = 1,
  launcherStyle = "bar",
  launcherText = "ADDONS",
  launcherWidth = 92,
  launcherHeight = 20,
  launcherScale = 1,
  launcherAlpha = 1,
  menuWidth = 230,
  rowHeight = 24,
  maxRows = 12,
  fontSize = 11,
  showIcons = 1,
  showHidden = nil,
  closeAfterClick = 1,
  usePfUITheme = 1,
  suppressPfUI = 1,
  point = "TOPRIGHT",
  relativePoint = "TOPRIGHT",
  x = -170,
  y = -8,
  aliases = {},
  excluded = {},
}

local KNOWN_LABELS = {
  ["GameTimeFrame"] = "Clock / Calendar",
  ["TimeManagerClockButton"] = "Clock / Calendar",
  ["MiniMapWorldMapButton"] = "World Map",
  ["MinimapZoneTextButton"] = "World Map",
  ["MinimapZoomIn"] = "Zoom In",
  ["MinimapZoomOut"] = "Zoom Out",
  ["MinimapToggleButton"] = "Toggle Minimap",
  ["MiniMapTracking"] = "Tracking",
  ["MiniMapTrackingFrame"] = "Tracking",
  ["MiniMapBattlefieldFrame"] = "Battleground",
  ["MiniMapMailFrame"] = "New Mail",
  ["LFTMinimapButton"] = "Looking For Turtles",
  ["LFT_Minimap"] = "Looking For Turtles",
  ["LFT_MinimapButton"] = "Looking For Turtles",
  ["LFT_MinimapFrame"] = "Looking For Turtles",
  ["LFGMinimapButton"] = "Group Finder",
  ["LFGFrameMinimapButton"] = "Group Finder",
  ["LookingForGroupMinimapButton"] = "Group Finder",
  ["pfQuestMinimapButton"] = "pfQuest",
  ["pfQuestIcon"] = "pfQuest",
  ["AtlasCFMMinimapButton"] = "Atlas-CFM",
  ["CFMAtlasMinimapButton"] = "Atlas-CFM",
  ["FlightTrackerMinimapButton"] = "Flight Tracker",
  ["FTMinimapButton"] = "Flight Tracker",
  ["FlightTrackerButton"] = "Flight Tracker",
  ["pfMinimapTracking"] = "Tracking",
}

local KNOWN_SPECIAL = {
  ["MiniMapWorldMapButton"] = "WORLD_MAP",
  ["MinimapZoneTextButton"] = "WORLD_MAP",
  ["MinimapZoomIn"] = "ZOOM_IN",
  ["MinimapZoomOut"] = "ZOOM_OUT",
  ["MinimapToggleButton"] = "TOGGLE_MINIMAP",
  ["MiniMapMailFrame"] = "MAIL_STATUS",
  ["LFTMinimapButton"] = "LFT_TOGGLE",
  ["LFT_Minimap"] = "LFT_TOGGLE",
  ["LFT_MinimapButton"] = "LFT_TOGGLE",
  ["LFT_MinimapFrame"] = "LFT_TOGGLE",
  ["pfQuestIcon"] = "PFQUEST_TOGGLE",
  ["pfQuestMinimapButton"] = "PFQUEST_TOGGLE",
  ["AtlasCFMMinimapButton"] = "ATLAS_CFM_TOGGLE",
  ["CFMAtlasMinimapButton"] = "ATLAS_CFM_TOGGLE",
  ["FlightTrackerMinimapButton"] = "FLIGHT_TRACKER_TOGGLE",
  ["FTMinimapButton"] = "FLIGHT_TRACKER_TOGGLE",
  ["FlightTrackerButton"] = "FLIGHT_TRACKER_TOGGLE",
}

-- pfUI deliberately hides several stock controls. Keep those useful controls in
-- the list even when their original frames are hidden, but do not force
-- conditional indicators (mail, battleground queue, etc.) to appear.
local ALWAYS_LIST = {
  ["GameTimeFrame"] = 1,
  ["TimeManagerClockButton"] = 1,
  ["MiniMapWorldMapButton"] = 1,
  ["MinimapZoneTextButton"] = 1,
  ["MinimapZoomIn"] = 1,
  ["MinimapZoomOut"] = 1,
  ["MinimapToggleButton"] = 1,
  ["MiniMapTracking"] = 1,
  ["MiniMapTrackingFrame"] = 1,
  ["pfMinimapTracking"] = 1,
}

local KNOWN_ICON_PATHS = {
  ["GameTimeFrame"] = "Interface\\Icons\\INV_Misc_PocketWatch_01",
  ["TimeManagerClockButton"] = "Interface\\Icons\\INV_Misc_PocketWatch_01",
  ["MiniMapWorldMapButton"] = "Interface\\Icons\\INV_Misc_Map_01",
  ["MinimapZoneTextButton"] = "Interface\\Icons\\INV_Misc_Map_01",
  ["MinimapToggleButton"] = "Interface\\Icons\\INV_Misc_Map_01",
  ["MinimapZoomIn"] = "Interface\\Minimap\\UI-Minimap-ZoomInButton-Up",
  ["MinimapZoomOut"] = "Interface\\Minimap\\UI-Minimap-ZoomOutButton-Up",
  ["MiniMapMailFrame"] = "Interface\\Icons\\INV_Letter_15",
  ["MiniMapBattlefieldFrame"] = "Interface\\Icons\\INV_BannerPVP_02",
  ["pfQuestIcon"] = "Interface\\AddOns\\pfQuest\\img\\logo",
  ["pfQuestMinimapButton"] = "Interface\\AddOns\\pfQuest\\img\\logo",
  ["AtlasCFMMinimapButton"] = "Interface\\WorldMap\\WorldMap-Icon",
  ["CFMAtlasMinimapButton"] = "Interface\\WorldMap\\WorldMap-Icon",
  ["FlightTrackerMinimapButton"] = "Interface\\AddOns\\FlightTracker\\img\\flight",
  ["FTMinimapButton"] = "Interface\\AddOns\\FlightTracker\\img\\flight",
  ["FlightTrackerButton"] = "Interface\\AddOns\\FlightTracker\\img\\flight",
}

local KNOWN_HIDE_FRAMES = {
  ["AtlasCFMMinimapButton"] = "AtlasCFMButtonFrame",
  ["CFMAtlasMinimapButton"] = "AtlasCFMButtonFrame",
}

local KNOWN_ICON_OBJECTS = {
  ["MiniMapTracking"] = { "MiniMapTrackingIcon", "MiniMapTrackingButtonIcon" },
  ["MiniMapTrackingFrame"] = { "MiniMapTrackingIcon", "MiniMapTrackingButtonIcon" },
  ["pfMinimapTracking"] = { "MiniMapTrackingIcon", "MiniMapTrackingButtonIcon" },
  ["MiniMapMailFrame"] = { "MiniMapMailIcon" },
  ["LFTMinimapButton"] = { "LFTMinimapButtonIcon", "LFTMinimapIcon", "LFT_MinimapEye" },
  ["LFT_Minimap"] = { "LFT_MinimapEye", "LFTMinimapButtonIcon", "LFTMinimapIcon" },
  ["LFT_MinimapButton"] = { "LFT_MinimapEye", "LFTMinimapButtonIcon", "LFTMinimapIcon" },
  ["LFT_MinimapFrame"] = { "LFT_MinimapEye", "LFTMinimapButtonIcon", "LFTMinimapIcon" },
  ["AtlasCFMMinimapButton"] = { "AtlasCFMButtonIcon" },
  ["CFMAtlasMinimapButton"] = { "AtlasCFMButtonIcon" },
}

-- Common WoW 1.12.1-era minimap buttons whose names do not always contain the
-- word "minimap". The global registry scan still validates size, action, and
-- position before collecting them.
local KNOWN_GLOBAL_INCLUDE = {
  ["DPSMate_MiniMap"] = 1,
  ["EVTButtonFrame"] = 1,
  ["MinimapShopFrame"] = 1,
  ["TWMiniMapBattlefieldFrame"] = 1,
  ["EBC_Minimap"] = 1,
  ["MetaMapButton"] = 1,
  ["MetamapButton"] = 1,
  ["AtlasButton"] = 1,
  ["AtlasCFMMinimapButton"] = 1,
  ["CFMAtlasMinimapButton"] = 1,
  ["pfQuestIcon"] = 1,
  ["FlightTrackerMinimapButton"] = 1,
  ["FTMinimapButton"] = 1,
  ["FlightTrackerButton"] = 1,
  ["BigWigsMinimapButton"] = 1,
  ["KLHTM_MinimapButton"] = 1,
  ["QuestieMinimapButton"] = 1,
  ["ShaguTweaksMinimapButton"] = 1,
  ["Dcr_MinimapButton"] = 1,
  ["MonkeyBuddyIconButton"] = 1,
  ["ABProfiles_IconFrame"] = 1,
  ["ISync_MiniMapButtonFrame"] = 1,
  ["SprocketMinimapButton"] = 1,
  ["CensusButtonFrame"] = 1,
  ["WIM_Icon"] = 1,
  ["LFT_Minimap"] = 1,
  ["LFT_MinimapButton"] = 1,
  ["LFT_MinimapFrame"] = 1,
  ["LFTMinimapButton"] = 1,
}

local GLOBAL_UI_PREFIX_IGNORE = {
  "actionbutton",
  "bonusactionbutton",
  "multibaractionbutton",
  "shapeshiftbutton",
  "petactionbutton",
  "buffbutton",
  "debuffbutton",
  "characterbag",
  "containerframe",
  "characterframe",
  "spellbookframe",
  "talentframe",
  "questlogframe",
  "socialframe",
  "helpframe",
  "chatframe",
  "partyframe",
  "partymemberframe",
  "playerframe",
  "targetframe",
  "gamefont",
  "msminimapmenu",
  "octominimapmenu",
}

local IGNORE_EXACT = {
  ["MSMinimapMenuLauncher"] = 1,
  ["MSMinimapMenuList"] = 1,
  ["MSMinimapMenuOptions"] = 1,
  ["pfMinimapButton"] = 1,
  ["pfMinimapButtons"] = 1,
  ["MBB_MinimapButtonFrame"] = 1,
  ["MBB_MinimapButton"] = 1,
  ["MBB_Button"] = 1,
  ["MBF_MinimapButton"] = 1,
  ["MBF_Frame"] = 1,
  ["MinimapButtonFrame"] = 1,
  ["Minimap"] = 1,
  ["MinimapBackdrop"] = 1,
  ["MinimapBorder"] = 1,
  ["MinimapBorderTop"] = 1,
  ["MinimapNorthTag"] = 1,
  ["MinimapCluster"] = 1,
  ["MiniMapBattlefieldBorder"] = 1,
  ["MiniMapMailBorder"] = 1,
  ["MinimapCoordinatesText"] = 1,
  ["minimapZoneText"] = 1,
  ["pfMinimap"] = 1,
  ["pfMinimapCoord"] = 1,
  ["pfMinimapZone"] = 1,
}

local IGNORE_PARTIAL = {
  "minimapiconbuttonbag",
  "minimapbuttonbag",
  "mbfminimapbutton",
  "mbfbutton",
  "pfminimapbutton",
  "msminimapmenu",
  "octominimapmenu",
  "gathermatepin",
  "questienote",
  "pfminimappin",
  "pfmappin",
  "gathernotecompatfake",
  "cartographernotespoi",
  "mininotepoi",
  "gathernote",
  "recipe radar minimap icon",
  "reciperadarminimapicon",
  "westpointer",
  "minimaparrow",
  "minimapplayer",
  "minimap ping",
}

local COLLECTOR_NAMES = {
  "pfMinimapButton",
  "pfMinimapButtons",
  "MBB_MinimapButtonFrame",
  "MBB_MinimapButton",
  "MBB_Button",
  "MBF_MinimapButton",
  "MBF_Frame",
  "MinimapButtonFrame",
}

local function SafeNumber(value, fallback)
  value = tonumber(value)
  if value == nil then return fallback end
  return value
end

local function Clamp(value, minimum, maximum)
  value = SafeNumber(value, minimum)
  if value < minimum then return minimum end
  if value > maximum then return maximum end
  return value
end

local function Trim(text)
  if not text then return "" end
  text = tostring(text)
  text = string.gsub(text, "^%s+", "")
  text = string.gsub(text, "%s+$", "")
  return text
end

local function CopyDefaults(destination, source)
  local key, value
  for key, value in pairs(source) do
    if type(value) == "table" then
      if type(destination[key]) ~= "table" then destination[key] = {} end
      CopyDefaults(destination[key], value)
    elseif destination[key] == nil then
      destination[key] = value
    end
  end
end

local function CopyValue(value)
  local copy, key, child
  if type(value) ~= "table" then return value end
  copy = {}
  for key, child in pairs(value) do copy[key] = CopyValue(child) end
  return copy
end

local function HasTableData(value, ignoredKey)
  local key
  if type(value) ~= "table" then return nil end
  for key in pairs(value) do
    if key ~= ignoredKey then return 1 end
  end
  return nil
end

local function CopyMissingKeys(target, source)
  local key, value
  if type(target) ~= "table" or type(source) ~= "table" then return end
  for key, value in pairs(source) do
    if target[key] == nil then
      target[key] = CopyValue(value)
    elseif type(target[key]) == "table" and type(value) == "table" then
      CopyMissingKeys(target[key], value)
    end
  end
end

function MSM:MigrateLegacySavedVariables()
  local bridge = MSMinimapMenuLegacyMigration
  local legacy = type(OctoMinimapMenuDB) == "table" and OctoMinimapMenuDB or nil
  local markerTable

  if type(legacy) ~= "table" and type(bridge) == "table" and type(bridge.account) == "table" then
    legacy = bridge.account
  end

  if type(MSMinimapMenuDB) ~= "table" then MSMinimapMenuDB = {} end
  markerTable = MSMinimapMenuDB._moobStackMigration
  if type(markerTable) ~= "table" then markerTable = {} end

  if markerTable.octoMinimapMenu1010 ~= 1 and type(legacy) == "table" then
    if not HasTableData(MSMinimapMenuDB, "_moobStackMigration") then
      MSMinimapMenuDB = CopyValue(legacy)
      if type(MSMinimapMenuDB) ~= "table" then MSMinimapMenuDB = {} end
    else
      CopyMissingKeys(MSMinimapMenuDB, legacy)
    end

    if type(MSMinimapMenuDB._moobStackMigration) ~= "table" then
      MSMinimapMenuDB._moobStackMigration = markerTable
    end
    MSMinimapMenuDB._moobStackMigration.octoMinimapMenu1010 = 1
    MSMinimapMenuDB._moobStackMigration.completedBy = "MS Minimap Menu 1.0.11"
    MSMinimapMenuDB._moobStackMigration.sourceVersion = "1.0.10"
    self.legacyImportedAtLoad = 1
  end

  self.legacyBridgeLoaded = type(bridge) == "table" and bridge.loaded and 1 or nil
end

local function ParseColor(value, r, g, b, a)
  if type(value) ~= "string" then return r, g, b, a end
  local _, _, sr, sg, sb, sa = string.find(value, "([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)")
  if sr then
    return SafeNumber(sr, r), SafeNumber(sg, g), SafeNumber(sb, b), SafeNumber(sa, a)
  end
  return r, g, b, a
end

local function Lower(text)
  return string.lower(tostring(text or ""))
end

local function Contains(text, needle)
  return string.find(Lower(text), Lower(needle), 1, true) ~= nil
end

local function IsObjectLike(value)
  local valueType = type(value)
  return valueType == "table" or valueType == "userdata"
end

-- WoW 1.12 exposes UI objects through C-backed tables/userdata. Only values
-- with the complete basic frame method set are treated as frames. This avoids
-- invoking arbitrary addon module tables while scanning.
local function SafeGetMethod(object, methodName)
  if not IsObjectLike(object) or type(methodName) ~= "string" then return nil end
  local ok, method = pcall(function() return object[methodName] end)
  if ok and type(method) == "function" then return method end
  return nil
end

local function IsFrameObject(frame)
  if not IsObjectLike(frame) then return nil end
  if not SafeGetMethod(frame, "GetName") then return nil end
  if not SafeGetMethod(frame, "GetParent") then return nil end
  if not SafeGetMethod(frame, "GetWidth") then return nil end
  if not SafeGetMethod(frame, "GetHeight") then return nil end
  local method = SafeGetMethod(frame, "GetObjectType")
  if not method then return nil end
  local ok, objectType = pcall(method, frame)
  if not ok then return nil end
  if objectType == "Frame" or objectType == "Button" or objectType == "CheckButton" then return 1 end
  return nil
end

local function GetFrameName(frame)
  if not IsFrameObject(frame) then return nil end
  local method = SafeGetMethod(frame, "GetName")
  local ok, name = pcall(method, frame)
  if ok and type(name) == "string" and name ~= "" then return name end
  return nil
end

local function SafeGetParent(frame)
  if not IsFrameObject(frame) then return nil end
  local method = SafeGetMethod(frame, "GetParent")
  if not method then return nil end
  local ok, parent = pcall(method, frame)
  if ok and IsFrameObject(parent) then return parent end
  return nil
end

local function SafeGetObjects(frame, methodName, maximum)
  if not IsFrameObject(frame) then return {} end
  local method = SafeGetMethod(frame, methodName)
  if not method then return {} end
  local values = { pcall(method, frame) }
  if not values[1] then return {} end
  local output = {}
  local limit = table.getn(values)
  maximum = maximum or 96
  if limit > maximum + 1 then limit = maximum + 1 end
  local index, value
  for index = 2, limit do
    value = values[index]
    if value ~= nil then table.insert(output, value) end
  end
  return output
end

local function SafeGetNumber(frame, methodName, fallback)
  if not IsObjectLike(frame) then return fallback end
  local method = SafeGetMethod(frame, methodName)
  if not method then return fallback end
  local ok, value = pcall(method, frame)
  if ok and type(value) == "number" then return value end
  return fallback
end

local function SafeGetAlpha(frame)
  return SafeGetNumber(frame, "GetAlpha", 1)
end

local function SafeIsMouseEnabled(frame)
  if not IsFrameObject(frame) then return 1 end
  local method = SafeGetMethod(frame, "IsMouseEnabled")
  if not method then return 1 end
  local ok, value = pcall(method, frame)
  if not ok then return 1 end
  return value and 1 or nil
end

local function SafeSetAlpha(frame, alpha)
  if not IsFrameObject(frame) then return nil end
  local method = SafeGetMethod(frame, "SetAlpha")
  if not method then return nil end
  return pcall(method, frame, alpha)
end

local function SafeEnableMouse(frame, enabled)
  if not IsFrameObject(frame) then return nil end
  local method = SafeGetMethod(frame, "EnableMouse")
  if not method then return nil end
  return pcall(method, frame, enabled and 1 or nil)
end

local function SafeIsShown(frame)
  if not IsFrameObject(frame) then return nil end
  local method = SafeGetMethod(frame, "IsShown")
  if not method then return 1 end
  local ok, shown = pcall(method, frame)
  if not ok then return 1 end
  return shown and 1 or nil
end

-- WoW 1.12 can throw when GetScript is queried with a script type unsupported
-- by a frame. Every lookup is protected and only real function handlers pass.
local function SafeGetScript(frame, scriptName)
  if not IsFrameObject(frame) or not scriptName then return nil end
  local method = SafeGetMethod(frame, "GetScript")
  if not method then return nil end
  local ok, handler = pcall(method, frame, scriptName)
  if not ok or type(handler) ~= "function" then return nil end
  return handler
end

local function SafeGetField(object, fieldName)
  if not IsObjectLike(object) or type(fieldName) ~= "string" then return nil end
  local ok, value = pcall(function() return object[fieldName] end)
  if ok then return value end
  return nil
end

local function SafeGetCenter(frame)
  if not IsFrameObject(frame) then return nil, nil end
  local method = SafeGetMethod(frame, "GetCenter")
  if not method then return nil, nil end
  local ok, x, y = pcall(method, frame)
  if ok and type(x) == "number" and type(y) == "number" then return x, y end
  return nil, nil
end

local function SafeGetTextureValue(texture)
  if not IsObjectLike(texture) then return nil end
  local method = SafeGetMethod(texture, "GetTexture")
  if not method then return nil end
  local ok, value = pcall(method, texture)
  if not ok then return nil end
  if type(value) == "string" and value ~= "" then return value end
  if type(value) == "number" and value > 0 then return value end
  return nil
end

local function IsTextureObject(value)
  return SafeGetTextureValue(value) ~= nil and 1 or nil
end

local function StripColorCodes(value)
  value = tostring(value or "")
  value = string.gsub(value, "|c%x%x%x%x%x%x%x%x", "")
  value = string.gsub(value, "|r", "")
  value = string.gsub(value, "[\r\n]+", " ")
  return Trim(value)
end

local function NormalizeNameToken(value)
  value = StripColorCodes(value)
  value = Lower(value)
  value = string.gsub(value, "[^%w]", "")
  return value
end

local function GetFrameKey(frame)
  return GetFrameName(frame)
end

local function IsOurFrame(frame)
  if not IsFrameObject(frame) then return nil end
  if frame == MSM.launcher or frame == MSM.menu or frame == MSM.options then return 1 end
  local parent = SafeGetParent(frame)
  local depth = 0
  while parent and depth < 8 do
    if parent == MSM.launcher or parent == MSM.menu or parent == MSM.options then return 1 end
    parent = SafeGetParent(parent)
    depth = depth + 1
  end
  return nil
end

function MSM:Print(message)
  if self.suppressMessages then return end
  if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccMS Minimap Menu:|r " .. tostring(message))
  end
end

function MSM:NormalizeSettings()
  self:MigrateLegacySavedVariables()
  MSMinimapMenuDB = MSMinimapMenuDB or {}
  CopyDefaults(MSMinimapMenuDB, DEFAULTS)
  self.db = MSMinimapMenuDB

  self.db.enabled = self.db.enabled and 1 or nil
  self.db.locked = self.db.locked and 1 or nil
  self.db.showIcons = self.db.showIcons and 1 or nil
  self.db.showHidden = self.db.showHidden and 1 or nil
  self.db.closeAfterClick = self.db.closeAfterClick and 1 or nil
  self.db.usePfUITheme = self.db.usePfUITheme and 1 or nil
  self.db.suppressPfUI = self.db.suppressPfUI and 1 or nil
  self.db.launcherWidth = Clamp(self.db.launcherWidth, 24, 240)
  self.db.launcherHeight = Clamp(self.db.launcherHeight, 16, 48)
  self.db.launcherScale = Clamp(self.db.launcherScale, 0.5, 2)
  self.db.launcherAlpha = Clamp(self.db.launcherAlpha, 0.15, 1)
  self.db.menuWidth = Clamp(self.db.menuWidth, 150, 420)
  self.db.rowHeight = Clamp(self.db.rowHeight, 18, 44)
  self.db.maxRows = math.floor(Clamp(self.db.maxRows, 4, 24))
  self.db.fontSize = math.floor(Clamp(self.db.fontSize, 8, 18))
  self.db.launcherStyle = self.db.launcherStyle == "icon" and "icon" or "bar"
  self.db.launcherText = Trim(self.db.launcherText)
  if self.db.launcherText == "" then self.db.launcherText = "ADDONS" end
  self.db.aliases = self.db.aliases or {}
  self.db.excluded = self.db.excluded or {}
  self.db.version = self.versionNumber
end

function MSM:GetTheme()
  local theme = {
    font = "Fonts\\ARIALN.TTF",
    fontSize = self.db and self.db.fontSize or 11,
    background = {0.08, 0.08, 0.08, 0.92},
    border = {0.18, 0.18, 0.18, 1},
    hover = {0.35, 0.35, 0.35, 0.45},
    text = {0.92, 0.92, 0.92, 1},
    muted = {0.55, 0.55, 0.55, 1},
    accent = {1, 0.82, 0.18, 1},
  }

  if self.db and self.db.usePfUITheme and pfUI then
    if pfUI.font_default then theme.font = pfUI.font_default end
    local cfg = pfUI_config or C
    if cfg then
      if cfg.global and cfg.global.font_default and cfg.global.font_default ~= "" then
        theme.font = cfg.global.font_default
      end
      if cfg.global and cfg.global.font_size then
        theme.fontSize = math.floor(SafeNumber(cfg.global.font_size, theme.fontSize))
      end
      if cfg.appearance and cfg.appearance.border then
        local border = cfg.appearance.border
        theme.background[1], theme.background[2], theme.background[3], theme.background[4] =
          ParseColor(border.background, theme.background[1], theme.background[2], theme.background[3], theme.background[4])
        theme.border[1], theme.border[2], theme.border[3], theme.border[4] =
          ParseColor(border.color, theme.border[1], theme.border[2], theme.border[3], theme.border[4])
      end
    end
  end

  theme.fontSize = self.db and self.db.fontSize or theme.fontSize
  return theme
end

function MSM:ApplyBackdrop(frame, backgroundAlpha)
  if not frame then return end
  local theme = self:GetTheme()
  if not frame.msmBackground then
    frame.msmBackground = frame:CreateTexture(nil, "BACKGROUND")
    frame.msmBackground:SetAllPoints(frame)
    frame.msmBorderTop = frame:CreateTexture(nil, "BORDER")
    frame.msmBorderBottom = frame:CreateTexture(nil, "BORDER")
    frame.msmBorderLeft = frame:CreateTexture(nil, "BORDER")
    frame.msmBorderRight = frame:CreateTexture(nil, "BORDER")
    frame.msmBorderTop:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    frame.msmBorderTop:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    frame.msmBorderTop:SetHeight(1)
    frame.msmBorderBottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    frame.msmBorderBottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    frame.msmBorderBottom:SetHeight(1)
    frame.msmBorderLeft:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    frame.msmBorderLeft:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    frame.msmBorderLeft:SetWidth(1)
    frame.msmBorderRight:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    frame.msmBorderRight:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    frame.msmBorderRight:SetWidth(1)
  end
  local alpha = backgroundAlpha or theme.background[4]
  frame.msmBackground:SetTexture(theme.background[1], theme.background[2], theme.background[3], alpha)
  frame.msmBorderTop:SetTexture(theme.border[1], theme.border[2], theme.border[3], theme.border[4])
  frame.msmBorderBottom:SetTexture(theme.border[1], theme.border[2], theme.border[3], theme.border[4])
  frame.msmBorderLeft:SetTexture(theme.border[1], theme.border[2], theme.border[3], theme.border[4])
  frame.msmBorderRight:SetTexture(theme.border[1], theme.border[2], theme.border[3], theme.border[4])
end

function MSM:SetBorderColor(frame, r, g, b, a)
  if not frame or not frame.msmBorderTop then return end
  frame.msmBorderTop:SetTexture(r, g, b, a)
  frame.msmBorderBottom:SetTexture(r, g, b, a)
  frame.msmBorderLeft:SetTexture(r, g, b, a)
  frame.msmBorderRight:SetTexture(r, g, b, a)
end

local function SetFont(fontString, path, size, flags)
  if not fontString then return end
  local ok = fontString:SetFont(path, size, flags or "OUTLINE")
  if not ok then fontString:SetFont("Fonts\\ARIALN.TTF", size, flags or "OUTLINE") end
end

function MSM:CreateLauncher()
  if self.launcher then return end
  local launcher = CreateFrame("Button", "MSMinimapMenuLauncher", UIParent)
  self.launcher = launcher
  launcher:SetFrameStrata("HIGH")
  launcher:SetFrameLevel(20)
  launcher:SetClampedToScreen(1)
  launcher:SetMovable(1)
  launcher:EnableMouse(1)
  launcher:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  launcher:RegisterForDrag("LeftButton")

  launcher.icon = launcher:CreateTexture(nil, "ARTWORK")
  launcher.icon:SetTexture("Interface\\Icons\\INV_Misc_Gear_01")
  launcher.text = launcher:CreateFontString("MSMinimapMenuLauncherText", "OVERLAY", "GameFontNormal")
  launcher.text:SetJustifyH("CENTER")
  launcher.text:SetJustifyV("MIDDLE")
  launcher.text:SetAllPoints(launcher)
  launcher.count = launcher:CreateFontString("MSMinimapMenuLauncherCount", "OVERLAY", "GameFontNormalSmall")
  launcher.count:SetPoint("BOTTOMRIGHT", launcher, "BOTTOMRIGHT", -2, 1)
  launcher.count:SetJustifyH("RIGHT")

  launcher:SetScript("OnDragStart", function()
    if not MSM.db.locked then
      this:StartMoving()
    end
  end)
  launcher:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
    MSM:SaveLauncherPosition()
  end)
  launcher:SetScript("OnClick", function()
    if arg1 == "RightButton" then
      MSM:ToggleOptions()
    else
      MSM:ToggleMenu()
    end
  end)
  launcher:SetScript("OnEnter", function()
    local theme = MSM:GetTheme()
    MSM:SetBorderColor(this, theme.accent[1], theme.accent[2], theme.accent[3], theme.accent[4])
    if GameTooltip then
      GameTooltip:SetOwner(this, "ANCHOR_LEFT")
      GameTooltip:SetText("MSMinimapMenu", 1, 0.82, 0.18)
      GameTooltip:AddLine("Left-click: open button list", 1, 1, 1)
      GameTooltip:AddLine("Right-click: settings", 1, 1, 1)
      if not MSM.db.locked then GameTooltip:AddLine("Drag: move launcher", 0.6, 1, 0.6) end
      GameTooltip:Show()
    end
  end)
  launcher:SetScript("OnLeave", function()
    MSM:RefreshLauncherBorder()
    if GameTooltip and GameTooltip:IsOwned(this) then GameTooltip:Hide() end
  end)

  self:UpdateLauncher()
end

function MSM:RefreshLauncherBorder()
  if not self.launcher then return end
  local theme = self:GetTheme()
  if self.db.locked then
    self:SetBorderColor(self.launcher, theme.border[1], theme.border[2], theme.border[3], theme.border[4])
  else
    self:SetBorderColor(self.launcher, theme.accent[1], theme.accent[2], theme.accent[3], theme.accent[4])
  end
end

function MSM:SaveLauncherPosition()
  if not self.launcher then return end
  local point, _, relativePoint, x, y = self.launcher:GetPoint()
  if point then
    self.db.point = point
    self.db.relativePoint = relativePoint or point
    self.db.x = math.floor((x or 0) + 0.5)
    self.db.y = math.floor((y or 0) + 0.5)
  end
end

function MSM:UpdateLauncher()
  if not self.launcher or not self.db then return end
  local theme = self:GetTheme()
  local launcher = self.launcher
  launcher:SetScale(self.db.launcherScale)
  launcher:SetAlpha(self.db.launcherAlpha)
  launcher:ClearAllPoints()
  launcher:SetPoint(self.db.point, UIParent, self.db.relativePoint, self.db.x, self.db.y)

  if self.db.launcherStyle == "icon" then
    launcher:SetWidth(self.db.launcherHeight)
    launcher:SetHeight(self.db.launcherHeight)
    launcher.icon:ClearAllPoints()
    launcher.icon:SetPoint("TOPLEFT", launcher, "TOPLEFT", 3, -3)
    launcher.icon:SetPoint("BOTTOMRIGHT", launcher, "BOTTOMRIGHT", -3, 3)
    launcher.icon:Show()
    launcher.text:Hide()
    launcher.count:Show()
  else
    launcher:SetWidth(self.db.launcherWidth)
    launcher:SetHeight(self.db.launcherHeight)
    launcher.icon:Hide()
    launcher.text:Show()
    launcher.count:Hide()
    launcher.text:SetText(self.db.launcherText .. "  " .. tostring(self:GetVisibleEntryCount()))
  end

  SetFont(launcher.text, theme.font, theme.fontSize, "OUTLINE")
  SetFont(launcher.count, theme.font, math.max(8, theme.fontSize - 2), "OUTLINE")
  launcher.text:SetTextColor(theme.text[1], theme.text[2], theme.text[3], theme.text[4])
  launcher.count:SetTextColor(theme.accent[1], theme.accent[2], theme.accent[3], theme.accent[4])
  launcher.count:SetText(tostring(self:GetVisibleEntryCount()))
  self:ApplyBackdrop(launcher)
  self:RefreshLauncherBorder()

  if self.db.enabled then launcher:Show() else launcher:Hide() end
end

function MSM:CreateMenu()
  if self.menu then return end
  local menu = CreateFrame("Frame", "MSMinimapMenuList", UIParent)
  self.menu = menu
  menu:SetFrameStrata("DIALOG")
  menu:SetFrameLevel(60)
  menu:SetClampedToScreen(1)
  menu:EnableMouse(1)
  menu:Hide()

  menu.header = CreateFrame("Frame", "MSMinimapMenuListHeader", menu)
  menu.header:SetPoint("TOPLEFT", menu, "TOPLEFT", 1, -1)
  menu.header:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -1, -1)
  menu.header:SetHeight(20)
  menu.header.title = menu.header:CreateFontString("MSMinimapMenuListTitle", "OVERLAY", "GameFontNormal")
  menu.header.title:SetPoint("LEFT", menu.header, "LEFT", 6, 0)
  menu.header.title:SetJustifyH("LEFT")

  menu.header.scan = CreateFrame("Button", "MSMinimapMenuListScan", menu.header)
  menu.header.scan:SetWidth(20)
  menu.header.scan:SetHeight(18)
  menu.header.scan:SetPoint("RIGHT", menu.header, "RIGHT", -21, 0)
  menu.header.scan.text = menu.header.scan:CreateFontString("MSMinimapMenuListScanText", "OVERLAY", "GameFontNormal")
  menu.header.scan.text:SetAllPoints(menu.header.scan)
  menu.header.scan.text:SetText("R")
  menu.header.scan:SetScript("OnClick", function()
    MSM.captureRescanAll = 1
    MSM:RequestScan(0)
    MSM:ScanNow(1)
  end)
  menu.header.scan:SetScript("OnEnter", function()
    local theme = MSM:GetTheme()
    MSM:SetBorderColor(this, theme.accent[1], theme.accent[2], theme.accent[3], theme.accent[4])
    GameTooltip:SetOwner(this, "ANCHOR_TOP")
    GameTooltip:SetText("Refresh captured minimap buttons")
    GameTooltip:Show()
  end)
  menu.header.scan:SetScript("OnLeave", function()
    MSM:ApplyBackdrop(this)
    if GameTooltip:IsOwned(this) then GameTooltip:Hide() end
  end)

  menu.header.close = CreateFrame("Button", "MSMinimapMenuListClose", menu.header)
  menu.header.close:SetWidth(20)
  menu.header.close:SetHeight(18)
  menu.header.close:SetPoint("RIGHT", menu.header, "RIGHT", -1, 0)
  menu.header.close.text = menu.header.close:CreateFontString("MSMinimapMenuListCloseText", "OVERLAY", "GameFontNormal")
  menu.header.close.text:SetAllPoints(menu.header.close)
  menu.header.close.text:SetText("x")
  menu.header.close:SetScript("OnClick", function() MSM:HideMenu() end)

  menu.scroll = CreateFrame("ScrollFrame", "MSMinimapMenuListScroll", menu)
  menu.scroll:SetPoint("TOPLEFT", menu.header, "BOTTOMLEFT", 0, -1)
  menu.scroll:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -15, 1)
  menu.content = CreateFrame("Frame", "MSMinimapMenuListContent", menu.scroll)
  menu.content:SetWidth(200)
  menu.content:SetHeight(1)
  menu.scroll:SetScrollChild(menu.content)

  menu.scrollbar = CreateFrame("Slider", "MSMinimapMenuListScrollbar", menu)
  menu.scrollbar:SetOrientation("VERTICAL")
  menu.scrollbar:SetPoint("TOPRIGHT", menu.header, "BOTTOMRIGHT", -2, -2)
  menu.scrollbar:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -2, 3)
  menu.scrollbar:SetWidth(11)
  menu.scrollbar:SetMinMaxValues(0, 0)
  menu.scrollbar:SetValueStep(1)
  menu.scrollbar:SetValue(0)
  menu.scrollbar.thumb = menu.scrollbar:CreateTexture(nil, "OVERLAY")
  menu.scrollbar.thumb:SetTexture(0.65, 0.65, 0.65, 0.8)
  menu.scrollbar.thumb:SetWidth(9)
  menu.scrollbar.thumb:SetHeight(28)
  menu.scrollbar:SetThumbTexture(menu.scrollbar.thumb)
  menu.scrollbar:SetScript("OnValueChanged", function()
    MSM.menu.scroll:SetVerticalScroll(arg1 or this:GetValue())
  end)

  menu.scroll:EnableMouseWheel(1)
  menu.scroll:SetScript("OnMouseWheel", function()
    local current = MSM.menu.scrollbar:GetValue()
    local step = MSM.db.rowHeight * 2
    if arg1 > 0 then current = current - step else current = current + step end
    MSM.menu.scrollbar:SetValue(current)
  end)
  menu:SetScript("OnHide", function() MSM.menuOpen = nil end)
  menu:SetScript("OnShow", function() MSM.menuOpen = 1 end)

  if UISpecialFrames then table.insert(UISpecialFrames, "MSMinimapMenuList") end
  self:ApplyMenuTheme()
end

function MSM:ApplyMenuTheme()
  if not self.menu then return end
  local theme = self:GetTheme()
  self:ApplyBackdrop(self.menu)
  self:ApplyBackdrop(self.menu.header, theme.background[4])
  self:ApplyBackdrop(self.menu.header.scan, theme.background[4])
  self:ApplyBackdrop(self.menu.header.close, theme.background[4])
  SetFont(self.menu.header.title, theme.font, theme.fontSize, "OUTLINE")
  SetFont(self.menu.header.scan.text, theme.font, theme.fontSize, "OUTLINE")
  SetFont(self.menu.header.close.text, theme.font, theme.fontSize, "OUTLINE")
  self.menu.header.title:SetTextColor(theme.text[1], theme.text[2], theme.text[3], theme.text[4])
  self.menu.header.scan.text:SetTextColor(theme.accent[1], theme.accent[2], theme.accent[3], theme.accent[4])
  self.menu.header.close.text:SetTextColor(theme.text[1], theme.text[2], theme.text[3], theme.text[4])
end

function MSM:CreateRow(index)
  local row = CreateFrame("Button", "MSMinimapMenuRow" .. index, self.menu.content)
  self.rows[index] = row
  row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  row:EnableMouse(1)
  row.icon = row:CreateTexture(nil, "ARTWORK")
  row.icon:SetWidth(18)
  row.icon:SetHeight(18)
  row.icon:SetPoint("LEFT", row, "LEFT", 4, 0)
  row.text = row:CreateFontString("MSMinimapMenuRowText" .. index, "OVERLAY", "GameFontNormal")
  row.text:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
  row.text:SetPoint("RIGHT", row, "RIGHT", -6, 0)
  row.text:SetJustifyH("LEFT")
  row.hover = row:CreateTexture(nil, "BACKGROUND")
  row.hover:SetAllPoints(row)
  row.hover:Hide()

  row:SetScript("OnClick", function()
    if not this.entry then return end
    MSM:ActivateEntry(this.entry, arg1)
  end)
  row:SetScript("OnEnter", function()
    local theme = MSM:GetTheme()
    this.hover:SetTexture(theme.hover[1], theme.hover[2], theme.hover[3], theme.hover[4])
    this.hover:Show()
    MSM:ShowEntryTooltip(this.entry, this)
  end)
  row:SetScript("OnLeave", function()
    this.hover:Hide()
    if GameTooltip and GameTooltip:IsOwned(this) then GameTooltip:Hide() end
    if this.entry then MSM:ForwardScript(this.entry, "OnLeave", nil) end
  end)
  return row
end

function MSM:ShowEntryTooltip(entry, owner)
  if not entry or not owner or not GameTooltip then return end
  local called = self:ForwardScript(entry, "OnEnter", nil, 1)
  if called and GameTooltip:IsShown() then
    GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
    GameTooltip:Show()
    return
  end
  GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
  GameTooltip:SetText(entry.label or "Minimap button", 1, 0.82, 0.18)
  if entry.key then GameTooltip:AddLine(entry.key, 0.55, 0.55, 0.55) end
  if entry.special == "MAIL_STATUS" then
    GameTooltip:AddLine("Notification only", 0.85, 0.85, 0.85)
  else
    GameTooltip:AddLine("Left-click or right-click to activate", 0.85, 0.85, 0.85)
  end
  GameTooltip:Show()
end

function MSM:PositionMenu()
  local menu = self.menu
  local launcher = self.launcher
  if not menu or not launcher then return end

  -- Compare centers in the same UI coordinate space. This remains correct when
  -- the user changes UI scale or the launcher has its own scale.
  local centerX, centerY
  local parentX, parentY
  if launcher.GetCenter then centerX, centerY = launcher:GetCenter() end
  if UIParent.GetCenter then parentX, parentY = UIParent:GetCenter() end
  if not centerX then
    local left = launcher:GetLeft() or 0
    local bottom = launcher:GetBottom() or 0
    centerX = left + launcher:GetWidth() / 2
    centerY = bottom + launcher:GetHeight() / 2
  end
  parentX = parentX or ((UIParent:GetWidth() or 0) / 2)
  parentY = parentY or ((UIParent:GetHeight() or 0) / 2)

  menu:ClearAllPoints()
  if centerY > parentY then
    if centerX > parentX then
      menu:SetPoint("TOPRIGHT", launcher, "BOTTOMRIGHT", 0, -3)
    else
      menu:SetPoint("TOPLEFT", launcher, "BOTTOMLEFT", 0, -3)
    end
  else
    if centerX > parentX then
      menu:SetPoint("BOTTOMRIGHT", launcher, "TOPRIGHT", 0, 3)
    else
      menu:SetPoint("BOTTOMLEFT", launcher, "TOPLEFT", 0, 3)
    end
  end
end

function MSM:GetVisibleEntries()
  local result = {}
  local index, entry
  for index = 1, table.getn(self.entryOrder) do
    entry = self.entryOrder[index]
    if entry and not self.db.excluded[entry.key] then
      if self.db.showHidden or entry.nativeShown or entry.forceVisible then
        table.insert(result, entry)
      end
    end
  end
  return result
end

function MSM:GetVisibleEntryCount()
  if not self.db then return 0 end
  return table.getn(self:GetVisibleEntries())
end

function MSM:RefreshMenu()
  if not self.menu then return end
  local theme = self:GetTheme()
  local entries = self:GetVisibleEntries()
  local count = table.getn(entries)
  local visibleRows = math.min(math.max(count, 1), self.db.maxRows)
  local menuHeight = 22 + visibleRows * self.db.rowHeight + 2
  self.menu:SetWidth(self.db.menuWidth)
  self.menu:SetHeight(menuHeight)
  self.menu.content:SetWidth(self.db.menuWidth - 17)
  self.menu.content:SetHeight(math.max(1, count * self.db.rowHeight))
  self.menu.header.title:SetText("MINIMAP BUTTONS  " .. tostring(count))

  local index, row, entry
  local loopCount = math.max(count, table.getn(self.rows))
  if loopCount < 1 then loopCount = 1 end
  for index = 1, loopCount do
    row = self.rows[index] or self:CreateRow(index)
    entry = entries[index]
    if entry then
      row.entry = entry
      row:SetHeight(self.db.rowHeight)
      row:SetWidth(self.db.menuWidth - 17)
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", self.menu.content, "TOPLEFT", 0, -((index - 1) * self.db.rowHeight))
      row.text:SetText(entry.label)
      SetFont(row.text, theme.font, theme.fontSize, "OUTLINE")
      if entry.nativeShown or self.db.showHidden then
        row.text:SetTextColor(theme.text[1], theme.text[2], theme.text[3], theme.text[4])
      else
        row.text:SetTextColor(theme.muted[1], theme.muted[2], theme.muted[3], theme.muted[4])
      end
      if self.db.showIcons then
        row.icon:Show()
        row.text:ClearAllPoints()
        row.text:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
        row.text:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        self:UpdateEntryIcon(entry, row.icon)
      else
        row.icon:Hide()
        row.text:ClearAllPoints()
        row.text:SetPoint("LEFT", row, "LEFT", 7, 0)
        row.text:SetPoint("RIGHT", row, "RIGHT", -6, 0)
      end
      row:Show()
    elseif count == 0 and index == 1 then
      row.entry = nil
      row:SetHeight(self.db.rowHeight)
      row:SetWidth(self.db.menuWidth - 17)
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", self.menu.content, "TOPLEFT", 0, 0)
      row.icon:Hide()
      row.text:ClearAllPoints()
      row.text:SetPoint("LEFT", row, "LEFT", 7, 0)
      row.text:SetPoint("RIGHT", row, "RIGHT", -6, 0)
      row.text:SetText("No minimap buttons detected")
      SetFont(row.text, theme.font, theme.fontSize, "OUTLINE")
      row.text:SetTextColor(theme.muted[1], theme.muted[2], theme.muted[3], theme.muted[4])
      row:Show()
    else
      row.entry = nil
      row:Hide()
    end
  end

  local maxScroll = math.max(0, count * self.db.rowHeight - visibleRows * self.db.rowHeight)
  self.menu.scrollbar:SetMinMaxValues(0, maxScroll)
  if self.menu.scrollbar:GetValue() > maxScroll then self.menu.scrollbar:SetValue(maxScroll) end
  if maxScroll > 0 then self.menu.scrollbar:Show() else self.menu.scrollbar:Hide() end
  self:ApplyMenuTheme()
  self:PositionMenu()
  self:UpdateLauncher()
end

function MSM:ShowMenu()
  if not self.db.enabled then return end
  -- Opening the list must remain instant. A pending event-driven scan may run,
  -- but the menu no longer forces a full capture/global pass on every click.
  if self.scanPending and GetTime() >= (self.scanAt or 0) then self:ScanNow(1) end
  self:RefreshMenu()
  self:PositionMenu()
  self.menu:Show()
end

function MSM:HideMenu()
  if self.menu then self.menu:Hide() end
end

function MSM:ToggleMenu()
  if not self.menu then return end
  if self.menu:IsShown() then self:HideMenu() else self:ShowMenu() end
end

function MSM:RequestScan(delay, fullGlobalScan)
  self.scanPending = 1
  self.scanAt = GetTime() + (delay or 0.1)
  if fullGlobalScan then self.globalScanPending = 1 end
end

function MSM:BuildAddonNameIndex()
  self.addonNameIndex = {}
  self.addonIndexBuilt = 1
  if not GetNumAddOns or not GetAddOnInfo then return end
  local ok, count = pcall(GetNumAddOns)
  if not ok or type(count) ~= "number" then return end
  if count > 300 then count = 300 end
  local index
  for index = 1, count do
    local info = { pcall(GetAddOnInfo, index) }
    if info[1] then
      local folder = info[2]
      local title = info[3]
      local token = NormalizeNameToken(folder)
      local cleanTitle = StripColorCodes(title or folder)
      if token ~= "" and string.len(token) >= 3 and cleanTitle ~= "" then
        table.insert(self.addonNameIndex, { token = token, title = cleanTitle, folder = folder })
      end
    end
  end
  table.sort(self.addonNameIndex, function(a, b) return string.len(a.token) > string.len(b.token) end)
end

function MSM:FindAddonLabel(frameName)
  if not self.addonIndexBuilt then self:BuildAddonNameIndex() end
  local token = NormalizeNameToken(frameName)
  if token == "" then return nil end
  local index, item, position
  for index = 1, table.getn(self.addonNameIndex) do
    item = self.addonNameIndex[index]
    if item and item.token and string.len(item.token) >= 4 then
      position = string.find(token, item.token, 1, true)
      if position == 1 or (position and string.len(item.token) >= 6) then return item.title end
    end
  end
  return nil
end

function MSM:IsCollectorFrame(frame)
  if not IsFrameObject(frame) then return nil end
  local index
  for index = 1, table.getn(COLLECTOR_NAMES) do
    if frame == _G[COLLECTOR_NAMES[index]] then return 1 end
  end
  if type(pfUI) == "table" then
    local pfButtons = SafeGetField(pfUI, "addonbuttons")
    if frame == pfButtons then return 1 end
  end
  return nil
end

function MSM:IsMapRoot(frame)
  if not IsFrameObject(frame) then return nil end
  if frame == Minimap or frame == MinimapBackdrop or frame == UIParent or frame == _G["MinimapCluster"] then return 1 end
  if frame == _G["pfMinimap"] then return 1 end
  if type(pfUI) == "table" then
    local pfMap = SafeGetField(pfUI, "minimap")
    if frame == pfMap then return 1 end
  end
  if self:IsCollectorFrame(frame) then return 1 end
  return nil
end

function MSM:IsMapRelatedFrame(frame)
  if not IsFrameObject(frame) then return nil end
  -- UIParent is a traversal boundary, not evidence that a frame belongs to the
  -- minimap. Treating it as a map root would classify every normal UI frame as
  -- a minimap control merely because it is anchored to UIParent.
  if frame ~= UIParent and self:IsMapRoot(frame) then return 1 end
  local name = GetFrameName(frame)
  if name then
    local lowered = Lower(name)
    if string.find(lowered, "minimap", 1, true) or string.find(lowered, "mini_map", 1, true) then return 1 end
    if string.find(lowered, "mapbutton", 1, true) or string.find(lowered, "map_button", 1, true) then return 1 end
  end
  return nil
end

function MSM:FrameHasMapAnchor(frame)
  if not IsFrameObject(frame) then return nil end
  local method = SafeGetMethod(frame, "GetPoint")
  if not method then return nil end
  local count = math.floor(SafeGetNumber(frame, "GetNumPoints", 1))
  if count < 1 then count = 1 end
  if count > 4 then count = 4 end
  local index, ok, point, relative
  for index = 1, count do
    ok, point, relative = pcall(method, frame, index)
    if not ok and index == 1 then ok, point, relative = pcall(method, frame) end
    if ok and point and self:IsMapRelatedFrame(relative) then return 1 end
  end
  return nil
end

local function HasStrongMinimapToken(name)
  if type(name) ~= "string" or name == "" then return nil end
  local lowered = Lower(name)
  if string.find(lowered, "minimap", 1, true) then return 1 end
  if string.find(lowered, "mini_map", 1, true) then return 1 end
  if string.find(lowered, "mapbutton", 1, true) then return 1 end
  if string.find(lowered, "map_button", 1, true) then return 1 end
  if string.find(lowered, "mapicon", 1, true) then return 1 end
  if string.find(lowered, "map_icon", 1, true) then return 1 end
  return nil
end

local NON_MINIMAP_WIDGET_TOKENS = {
  "buffbutton",
  "debuffbutton",
  "buffframe",
  "debuffframe",
  "aurabutton",
  "auraframe",
  "pfbuff",
  "pfdebuff",
  "playerbuff",
  "targetbuff",
  "unitbuff",
  "unitdebuff",
  "temporaryenchant",
  "consolidatedbuff",
  "actionbutton",
  "bonusaction",
  "multibaraction",
  "petaction",
  "shapeshiftbutton",
  "stancebutton",
  "spellbutton",
  "spellbook",
  "talentbutton",
  "totembutton",
  "characterbag",
  "containerframe",
  "unitframe",
  "partyframe",
  "raidframe",
  "playerframe",
  "targetframe",
  "focusframe",
  "castbar",
}

local function HasNonMinimapWidgetToken(name)
  if type(name) ~= "string" or name == "" then return nil end
  local lowered = Lower(name)
  local index
  for index = 1, table.getn(NON_MINIMAP_WIDGET_TOKENS) do
    if string.find(lowered, NON_MINIMAP_WIDGET_TOKENS[index], 1, true) then
      return 1, NON_MINIMAP_WIDGET_TOKENS[index]
    end
  end
  return nil
end

-- Reject ordinary interface controls even when their layout happens to be near
-- or anchored to the minimap. The candidate's own explicit minimap name is
-- exempt, so names such as SomeBuffMinimapButton remain valid; parent aura or
-- action-bar containers are never exempt.
function MSM:FrameHasNonMinimapWidgetLineage(frame, ownExplicitMinimapName)
  if not IsFrameObject(frame) then return nil end
  local current = frame
  local depth = 0
  local name, blocked, token
  while current and depth < 10 do
    name = GetFrameName(current)
    if name and not (depth == 0 and ownExplicitMinimapName) then
      blocked, token = HasNonMinimapWidgetToken(name)
      if blocked then return 1, token end
    end
    current = SafeGetParent(current)
    depth = depth + 1
  end
  return nil
end

-- Return true only when the frame center sits in a bounded rectangular ring
-- around the visible minimap. This is deliberately stricter than a broad
-- circular distance test: pfUI users often place buff bars, unit-frame buttons,
-- and other clickable widgets near the minimap, but those are not minimap
-- launchers and must never be collected.
function MSM:FrameIsOnMinimapPerimeter(frame)
  if not IsFrameObject(frame) or not IsFrameObject(Minimap) then return nil end
  local fx, fy = SafeGetCenter(frame)
  local mx, my = SafeGetCenter(Minimap)
  if not fx or not fy or not mx or not my then return nil end

  local mapWidth = SafeGetNumber(Minimap, "GetWidth", 140)
  local mapHeight = SafeGetNumber(Minimap, "GetHeight", 140)
  if mapWidth <= 0 then mapWidth = 140 end
  if mapHeight <= 0 then mapHeight = 140 end

  local halfWidth = mapWidth * 0.5
  local halfHeight = mapHeight * 0.5
  local dx = math.abs(fx - mx)
  local dy = math.abs(fy - my)
  local outerMargin = 58
  local innerInset = 24

  if dx > halfWidth + outerMargin or dy > halfHeight + outerMargin then return nil end
  if dx < math.max(0, halfWidth - innerInset) and dy < math.max(0, halfHeight - innerInset) then return nil end
  return 1
end

-- Inspect the frame and a few small wrapper ancestors for a real anchor to the
-- minimap. Merely being parented to UIParent or owned by an addon is not map
-- evidence. This distinction prevents aura/buff buttons near the map from being
-- mistaken for addon launchers.
function MSM:FrameHasMapAnchorChain(frame)
  if not IsFrameObject(frame) then return nil end
  local current = frame
  local depth = 0
  while current and depth < 5 do
    if current ~= UIParent and self:IsMapRoot(current) then return 1 end
    if self:FrameHasMapAnchor(current) then return 1 end
    local parent = SafeGetParent(current)
    if parent and parent ~= UIParent and self:IsMapRoot(parent) then return 1 end
    current = parent
    depth = depth + 1
  end
  return nil
end

local function IsKnownContentNodeName(name)
  if type(name) ~= "string" or name == "" then return nil end
  local lowered = Lower(name)
  -- pfQuest creates one real launcher (pfQuestIcon) and a large pool of
  -- clickable minimap quest nodes named pfMiniMapPin*. Only the launcher is a
  -- menu command; the nodes must remain map content.
  if lowered == "pfquesticon" or lowered == "pfquestminimapbutton" then return nil end
  if string.find(lowered, "pfminimappin", 1, true) == 1 then return 1 end
  if string.find(lowered, "pfmappin", 1, true) == 1 then return 1 end
  if string.find(lowered, "gathernotecompatfake", 1, true) == 1 then return 1 end
  if string.find(lowered, "pfquestpin", 1, true) == 1 then return 1 end
  if string.find(lowered, "pfquestnode", 1, true) == 1 then return 1 end
  if string.find(lowered, "pfquestroute", 1, true) == 1 then return 1 end
  return nil
end

local function IsNonMinimapControlName(name)
  if type(name) ~= "string" or name == "" then return nil end
  if IsKnownContentNodeName(name) then return 1 end
  if HasStrongMinimapToken(name) then return nil end
  local lowered = Lower(name)
  local index, prefix
  for index = 1, table.getn(GLOBAL_UI_PREFIX_IGNORE) do
    prefix = GLOBAL_UI_PREFIX_IGNORE[index]
    if string.find(lowered, prefix, 1, true) == 1 then return 1 end
  end
  if string.find(lowered, "buff", 1, true) then return 1 end
  if string.find(lowered, "debuff", 1, true) then return 1 end
  if string.find(lowered, "aura", 1, true) then return 1 end
  if string.find(lowered, "actionbutton", 1, true) then return 1 end
  if string.find(lowered, "spellbutton", 1, true) then return 1 end
  if string.find(lowered, "cooldownbutton", 1, true) then return 1 end
  if string.find(lowered, "unitframe", 1, true) then return 1 end
  return nil
end

function MSM:FrameHasNonMinimapWidgetContext(frame)
  if not IsFrameObject(frame) then return nil end
  local current = frame
  local depth = 0
  while current and depth < 6 do
    if current ~= frame and current ~= UIParent and self:IsMapRoot(current) then return nil end
    if IsNonMinimapControlName(GetFrameName(current)) then return 1 end
    current = SafeGetParent(current)
    depth = depth + 1
  end
  return nil
end

-- Hard scope gate shared by named-global discovery and the early capture
-- helper. Accepted frames must be stock minimap controls, already inside a
-- known minimap-button collector, or both physically on the minimap perimeter
-- and demonstrably anchored/named as a minimap launcher.
function MSM:FrameIsInStrictMinimapScope(frame, frameName)
  if not IsFrameObject(frame) or IsOurFrame(frame) then return nil end
  local name = frameName or GetFrameName(frame)
  if IsKnownContentNodeName(name) then
    if self.scanStats then self.scanStats.contentNodesRejected = (self.scanStats.contentNodesRejected or 0) + 1 end
    return nil
  end
  local known = name and (KNOWN_LABELS[name] or KNOWN_SPECIAL[name] or KNOWN_GLOBAL_INCLUDE[name])
  local explicitName = known or HasStrongMinimapToken(name)

  local blocked = self:FrameHasNonMinimapWidgetLineage(frame, explicitName)
  if blocked then
    if self.scanStats then self.scanStats.scopeRejected = (self.scanStats.scopeRejected or 0) + 1 end
    return nil
  end

  if known then return 1 end

  if type(self.IsInsideManagedCollector) == "function" then
    local ok, inside = pcall(self.IsInsideManagedCollector, self, frame)
    if ok and inside then return 1 end
  end

  if self:FrameHasNonMinimapWidgetContext(frame) then return nil end
  if not self:FrameIsOnMinimapPerimeter(frame) then return nil end
  if self:FrameHasMapAnchorChain(frame) then return 1 end
  if explicitName then return 1 end
  return nil
end

function MSM:FrameIsNearMinimap(frame, frameName)
  return self:FrameIsInStrictMinimapScope(frame, frameName)
end

local function HasIgnoredGlobalPrefix(name)
  local lowered = Lower(name)
  local index, prefix
  for index = 1, table.getn(GLOBAL_UI_PREFIX_IGNORE) do
    prefix = GLOBAL_UI_PREFIX_IGNORE[index]
    if string.find(lowered, prefix, 1, true) == 1 then return 1 end
  end
  return nil
end

function MSM:IsPotentialGlobalButtonName(name)
  if type(name) ~= "string" or name == "" then return nil end
  if IGNORE_EXACT[name] then return nil end
  local ignoredLower = Lower(name)
  local ignoredIndex
  for ignoredIndex = 1, table.getn(IGNORE_PARTIAL) do
    if string.find(ignoredLower, IGNORE_PARTIAL[ignoredIndex], 1, true) then return nil end
  end
  if HasIgnoredGlobalPrefix(name) then return nil end
  if KNOWN_GLOBAL_INCLUDE[name] or KNOWN_LABELS[name] then return 1 end
  local lowered = Lower(name)
  if string.find(lowered, "minimap", 1, true) or string.find(lowered, "mini_map", 1, true) then return 1 end
  if string.find(lowered, "mapbutton", 1, true) or string.find(lowered, "map_button", 1, true) then return 1 end
  if string.find(lowered, "mapicon", 1, true) or string.find(lowered, "map_icon", 1, true) then return 1 end
  if string.find(lowered, "button", 1, true) or string.find(lowered, "icon", 1, true) or string.find(lowered, "launcher", 1, true) then return 1 end
  return nil
end

local function FrameHasAction(frame)
  if SafeGetScript(frame, "OnClick") then return 1 end
  if SafeGetScript(frame, "OnMouseDown") then return 1 end
  if SafeGetScript(frame, "OnMouseUp") then return 1 end
  return nil
end

local function IsIgnoredName(name)
  if not name then return nil end
  if IGNORE_EXACT[name] then return 1 end
  local lowered = Lower(name)
  local index
  for index = 1, table.getn(IGNORE_PARTIAL) do
    if string.find(lowered, IGNORE_PARTIAL[index], 1, true) then return 1 end
  end
  return nil
end

local function IsKnownFrame(name)
  if not name then return nil end
  if KNOWN_LABELS[name] or KNOWN_SPECIAL[name] then return 1 end
  return nil
end

local function IsReasonableSize(frame, known)
  if known then return 1 end
  local width = SafeGetNumber(frame, "GetWidth", 0)
  local height = SafeGetNumber(frame, "GetHeight", 0)
  if width <= 0 or height <= 0 then return nil end
  if width > 80 or height > 80 then return nil end
  if width < 5 or height < 5 then return nil end
  return 1
end

function MSM:IsCandidate(frame, fromRoot)
  if not IsFrameObject(frame) then return nil end
  if IsOurFrame(frame) then return nil end
  local name = GetFrameName(frame)
  if not name then return nil end
  if IsIgnoredName(name) then return nil end
  local known = IsKnownFrame(name)
  if not IsReasonableSize(frame, known) then return nil end
  if known then return 1 end
  if not FrameHasAction(frame) then return nil end

  -- A trusted discovery source is not by itself enough. pfUI and many addons
  -- create ordinary clickable aura/action widgets near the minimap. Every
  -- non-stock candidate must still pass the strict minimap scope gate.
  if self:FrameIsInStrictMinimapScope(frame, name) then return 1 end
  return nil
end

function MSM:IsAnchoredToMap(frame)
  if not IsFrameObject(frame) then return nil end
  local method = SafeGetMethod(frame, "GetPoint")
  if not method then return nil end
  local ok, point, relative = pcall(method, frame)
  if not ok or not point then return nil end
  if relative == Minimap or relative == MinimapBackdrop or relative == _G["pfMinimap"] or relative == _G["pfMinimapButtons"] then return 1 end
  local relativeName = GetFrameName(relative)
  if relativeName and string.find(Lower(relativeName), "minimap", 1, true) then return 1 end
  return nil
end

function MSM:DeriveLabel(frame)
  local key = GetFrameKey(frame)
  if self.db.aliases[key] and Trim(self.db.aliases[key]) ~= "" then return Trim(self.db.aliases[key]) end
  local name = GetFrameName(frame)
  if name and KNOWN_LABELS[name] then return KNOWN_LABELS[name] end

  local getText = SafeGetMethod(frame, "GetText")
  if getText then
    local ok, value = pcall(getText, frame)
    local text = ok and StripColorCodes(value) or ""
    if text ~= "" and string.len(text) <= 48 then return text end
  end

  local fields = { "tooltipText", "displayName", "title", "label", "tooltip" }
  local index, value, candidate
  for index = 1, table.getn(fields) do
    value = SafeGetField(frame, fields[index])
    if type(value) == "string" then
      candidate = StripColorCodes(value)
      if candidate ~= "" and string.len(candidate) <= 60 and not string.find(Lower(candidate), "interface\\", 1, true) then
        return candidate
      end
    end
  end

  local addonLabel = self:FindAddonLabel(name)
  if addonLabel and addonLabel ~= "" then return addonLabel end

  local label = name or "Minimap Button"
  label = string.gsub(label, "MiniMap", " ")
  label = string.gsub(label, "Minimap", " ")
  label = string.gsub(label, "miniMap", " ")
  label = string.gsub(label, "_", " ")
  label = string.gsub(label, "(%l)(%u)", "%1 %2")
  label = string.gsub(label, "(%u)(%u%l)", "%1 %2")
  label = string.gsub(label, "Button", " ")
  label = string.gsub(label, "Frame", " ")
  label = string.gsub(label, "Icon", " ")
  label = string.gsub(label, "Launcher", " ")
  label = string.gsub(label, "%s+", " ")
  label = Trim(label)

  if label == "" or string.len(label) < 2 then
    local parent = SafeGetParent(frame)
    local parentName = GetFrameName(parent)
    if parentName then
      label = string.gsub(parentName, "MiniMap", " ")
      label = string.gsub(label, "Minimap", " ")
      label = string.gsub(label, "Button", " ")
      label = string.gsub(label, "Frame", " ")
      label = string.gsub(label, "(%l)(%u)", "%1 %2")
      label = Trim(string.gsub(label, "%s+", " "))
    end
  end
  if label == "" then label = "Minimap Button" end
  return label
end

local function ReadTextureSnapshot(texture, bonus)
  local value = SafeGetTextureValue(texture)
  if not value then return nil end
  local snapshot = { texture = value, bonus = bonus or 0, r = 1, g = 1, b = 1 }
  local nameMethod = SafeGetMethod(texture, "GetName")
  if nameMethod then
    local ok, name = pcall(nameMethod, texture)
    if ok and type(name) == "string" then snapshot.name = name end
  end
  snapshot.width = SafeGetNumber(texture, "GetWidth", 0)
  snapshot.height = SafeGetNumber(texture, "GetHeight", 0)

  local coordMethod = SafeGetMethod(texture, "GetTexCoord")
  if coordMethod then
    local values = { pcall(coordMethod, texture) }
    if values[1] then
      snapshot.coords = {}
      local index
      for index = 2, math.min(table.getn(values), 9) do
        if type(values[index]) == "number" then table.insert(snapshot.coords, values[index]) end
      end
      if table.getn(snapshot.coords) ~= 4 and table.getn(snapshot.coords) ~= 8 then snapshot.coords = nil end
    end
  end

  local colorMethod = SafeGetMethod(texture, "GetVertexColor")
  if colorMethod then
    local ok, r, g, b = pcall(colorMethod, texture)
    if ok then
      if type(r) == "number" then snapshot.r = r end
      if type(g) == "number" then snapshot.g = g end
      if type(b) == "number" then snapshot.b = b end
    end
  end

  local layerMethod = SafeGetMethod(texture, "GetDrawLayer")
  if layerMethod then
    local ok, layer = pcall(layerMethod, texture)
    if ok then snapshot.layer = layer end
  end
  return snapshot
end

local function ScoreTextureSnapshot(snapshot, frame)
  if not snapshot or not snapshot.texture then return -9999 end
  -- Some candidates are direct texture-path strings rather than Texture
  -- regions. Normalize every optional numeric field before comparison so one
  -- legacy addon cannot abort the complete minimap scan.
  local score = SafeNumber(snapshot.bonus, 0)
  local path = Lower(snapshot.texture)
  local name = Lower(snapshot.name)
  if string.find(path, "interface\\icons\\", 1, true) or string.find(path, "interface/icons/", 1, true) then score = score + 140 end
  if string.find(path, "\\icons\\", 1, true) then score = score + 80 end
  if string.find(path, "inv_", 1, true) or string.find(path, "spell_", 1, true) or string.find(path, "ability_", 1, true) then score = score + 35 end
  if string.find(path, "icon", 1, true) then score = score + 30 end
  if string.find(name, "icon", 1, true) then score = score + 55 end
  if string.find(name, "texture", 1, true) then score = score + 10 end

  local reject = { "border", "highlight", "background", "backdrop", "mask", "gloss", "overlay", "white8x8", "minimap-mask" }
  local index, word
  for index = 1, table.getn(reject) do
    word = reject[index]
    if string.find(path, word, 1, true) or string.find(name, word, 1, true) then score = score - 180 end
  end

  if snapshot.layer == "ARTWORK" then score = score + 18
  elseif snapshot.layer == "OVERLAY" then score = score + 8
  elseif snapshot.layer == "BACKGROUND" then score = score - 8 end

  local snapshotWidth = SafeNumber(snapshot.width, 0)
  local snapshotHeight = SafeNumber(snapshot.height, 0)
  local frameWidth = SafeGetNumber(frame, "GetWidth", 0)
  local frameHeight = SafeGetNumber(frame, "GetHeight", 0)
  if snapshotWidth > 0 and snapshotHeight > 0 and frameWidth > 0 and frameHeight > 0 then
    local ratio = math.min(snapshotWidth / frameWidth, snapshotHeight / frameHeight)
    if ratio >= 0.45 and ratio <= 1.05 then score = score + 22
    elseif ratio > 1.25 then score = score - 25 end
  end
  if snapshot.coords and table.getn(snapshot.coords) >= 4 then
    if snapshot.coords[1] ~= 0 or snapshot.coords[2] ~= 1 or snapshot.coords[3] ~= 0 or snapshot.coords[4] ~= 1 then score = score + 8 end
  end
  return score
end

local function AddTextureCandidate(list, value, bonus)
  if IsTextureObject(value) then
    local snapshot = ReadTextureSnapshot(value, bonus)
    if snapshot then table.insert(list, snapshot) end
  elseif type(value) == "string" and value ~= "" then
    -- Direct texture paths are common on Vanilla-era addon buttons. They do
    -- not expose region dimensions, so provide explicit zero-size metadata.
    -- The scorer must still keep the path because it may be the best or only
    -- usable icon for an anonymously captured addon launcher.
    table.insert(list, {
      texture = value,
      bonus = SafeNumber(bonus, 0),
      r = 1,
      g = 1,
      b = 1,
      width = 0,
      height = 0,
    })
  end
end

function MSM:CollectIconCandidates(frame, depth, candidates)
  if not IsFrameObject(frame) then return end
  depth = depth or 0
  candidates = candidates or {}

  local fields = { "icon", "Icon", "iconTexture", "IconTexture", "buttonIcon", "ButtonIcon", "texture", "Texture" }
  local index
  for index = 1, table.getn(fields) do AddTextureCandidate(candidates, SafeGetField(frame, fields[index]), 90) end

  local normalMethod = SafeGetMethod(frame, "GetNormalTexture")
  if normalMethod then
    local ok, value = pcall(normalMethod, frame)
    if ok then AddTextureCandidate(candidates, value, 28) end
  end
  local pushedMethod = SafeGetMethod(frame, "GetPushedTexture")
  if pushedMethod then
    local ok, value = pcall(pushedMethod, frame)
    if ok then AddTextureCandidate(candidates, value, 8) end
  end

  local regions = SafeGetObjects(frame, "GetRegions", 36)
  local region
  for index = 1, table.getn(regions) do
    region = regions[index]
    if IsTextureObject(region) then AddTextureCandidate(candidates, region, depth == 0 and 12 or 4) end
  end

  if depth == 0 then
    local children = SafeGetObjects(frame, "GetChildren", 16)
    local child
    for index = 1, table.getn(children) do
      child = children[index]
      if IsFrameObject(child) then self:CollectIconCandidates(child, 1, candidates) end
    end
  end
  return candidates
end

function MSM:CaptureEntryIcon(entry)
  if not entry or not IsFrameObject(entry.frame) then return end
  local frameName = GetFrameName(entry.frame)
  local candidates = {}
  local objectNames = frameName and KNOWN_ICON_OBJECTS[frameName] or nil
  local index, textureObject
  if objectNames then
    for index = 1, table.getn(objectNames) do
      textureObject = _G[objectNames[index]]
      AddTextureCandidate(candidates, textureObject, 520)
    end
  end
  self:CollectIconCandidates(entry.frame, 0, candidates)
  if entry.hideFrame and entry.hideFrame ~= entry.frame then self:CollectIconCandidates(entry.hideFrame, 0, candidates) end

  local best, bestScore, candidate, score, scoreOK
  bestScore = -9999
  for index = 1, table.getn(candidates) do
    candidate = candidates[index]
    scoreOK, score = pcall(ScoreTextureSnapshot, candidate, entry.frame)
    if not scoreOK or type(score) ~= "number" then
      local iconError = scoreOK and "invalid icon score" or tostring(score)
      score = -9999
      if self.scanStats then
        self.scanStats.iconErrors = (self.scanStats.iconErrors or 0) + 1
        self.scanStats.lastIconError = iconError
      end
    end
    if score > bestScore then best, bestScore = candidate, score end
  end

  local knownPath = frameName and KNOWN_ICON_PATHS[frameName] or nil
  -- Stock paths are fallbacks, not forced replacements. When the source frame
  -- exposes a real icon, preserve that exact icon instead of substituting a
  -- generic map/plus symbol.
  if knownPath and (not best or bestScore < 40) then
    best = { texture = knownPath, r = 1, g = 1, b = 1 }
    bestScore = 100
  end
  if not best or bestScore < -80 then
    best = { texture = "Interface\\Icons\\INV_Misc_QuestionMark", r = 1, g = 1, b = 1 }
    entry.iconFallback = 1
  else
    entry.iconFallback = nil
  end

  entry.iconPath = best.texture
  entry.iconCoords = best.coords
  entry.iconR = best.r or 1
  entry.iconG = best.g or 1
  entry.iconB = best.b or 1
  entry.iconScore = bestScore
end

function MSM:UpdateEntryIcon(entry, targetTexture)
  if not entry or not targetTexture then return end
  if not entry.iconPath then self:CaptureEntryIcon(entry) end
  targetTexture:SetTexture(entry.iconPath or "Interface\\Icons\\INV_Misc_QuestionMark")
  if entry.iconCoords and table.getn(entry.iconCoords) == 8 then
    targetTexture:SetTexCoord(unpack(entry.iconCoords))
  elseif entry.iconCoords and table.getn(entry.iconCoords) == 4 then
    targetTexture:SetTexCoord(entry.iconCoords[1], entry.iconCoords[2], entry.iconCoords[3], entry.iconCoords[4])
  else
    targetTexture:SetTexCoord(0, 1, 0, 1)
  end
  -- Never copy source alpha: many collectors intentionally fade original icons
  -- to zero, which previously made otherwise correct menu icons invisible.
  targetTexture:SetVertexColor(entry.iconR or 1, entry.iconG or 1, entry.iconB or 1, 1)
  if targetTexture.SetAlpha then targetTexture:SetAlpha(1) end
end

function MSM:GetHideFrame(frame)
  if not IsFrameObject(frame) then return frame end
  local frameName = GetFrameName(frame)
  local explicitHideName = frameName and KNOWN_HIDE_FRAMES[frameName] or nil
  local explicitHideFrame = explicitHideName and _G[explicitHideName] or nil
  if IsFrameObject(explicitHideFrame) then return explicitHideFrame end

  local current = frame
  local parent = SafeGetParent(current)
  local depth = 0
  while parent and depth < 5 do
    if self:IsMapRoot(parent) or IsOurFrame(parent) then break end

    -- Never climb from an admitted click target into an unrelated aura, buff,
    -- action-bar, or layout container. Earlier versions could hide a whole
    -- parent group after one child was misclassified.
    local parentName = GetFrameName(parent)
    if parentName and (HasIgnoredGlobalPrefix(parentName) or IsIgnoredName(parentName)) then break end

    local insideCollector = nil
    if type(self.IsInsideManagedCollector) == "function" then
      local ok, value = pcall(self.IsInsideManagedCollector, self, parent)
      if ok and value then insideCollector = 1 end
    end
    if not insideCollector and not self:FrameIsInStrictMinimapScope(parent, parentName) then break end

    local width = SafeGetNumber(parent, "GetWidth", 0)
    local height = SafeGetNumber(parent, "GetHeight", 0)
    if width > 90 or height > 90 or width <= 0 or height <= 0 then break end
    current = parent
    parent = SafeGetParent(current)
    depth = depth + 1
  end
  return current
end

function MSM:RememberAndHide(frame)
  if not IsFrameObject(frame) then return end
  -- The clickable child is normally named, but several legacy addons wrap it
  -- in an anonymous decorative frame. Exclusion is evaluated by the entry key
  -- before this function is called, so the wrapper itself does not need a
  -- global name in order to be safely suppressed and later restored.
  local state = self.hiddenFrames[frame]
  if not state then
    state = {}
    state.alpha = SafeGetAlpha(frame)
    state.mouse = SafeIsMouseEnabled(frame)
    self.hiddenFrames[frame] = state
  end
  SafeSetAlpha(frame, 0)
  SafeEnableMouse(frame, nil)
end

function MSM:RestoreFrame(frame)
  local state = self.hiddenFrames[frame]
  if not state or not IsFrameObject(frame) then
    self.hiddenFrames[frame] = nil
    return
  end
  SafeSetAlpha(frame, state.alpha or 1)
  SafeEnableMouse(frame, state.mouse)
  self.hiddenFrames[frame] = nil
end

function MSM:RestoreAllFrames()
  local frames = {}
  local frame, index
  for frame in pairs(self.hiddenFrames) do table.insert(frames, frame) end
  for index = 1, table.getn(frames) do self:RestoreFrame(frames[index]) end

  frames = {}
  for frame in pairs(self.collectorFrames) do table.insert(frames, frame) end
  for index = 1, table.getn(frames) do self:RestoreCollector(frames[index]) end
end

function MSM:MaintainHiddenState()
  if not self.db or not self.db.enabled then return end
  local frame
  for frame in pairs(self.hiddenFrames) do
    if IsFrameObject(frame) then
      SafeSetAlpha(frame, 0)
      SafeEnableMouse(frame, nil)
    end
  end
  for frame in pairs(self.collectorFrames) do
    if IsFrameObject(frame) then
      SafeSetAlpha(frame, 0)
      SafeEnableMouse(frame, nil)
    end
  end
end

function MSM:RememberCollector(frame)
  if not IsFrameObject(frame) or IsOurFrame(frame) then return end
  local state = self.collectorFrames[frame]
  if not state then
    state = {}
    state.alpha = SafeGetAlpha(frame)
    state.mouse = SafeIsMouseEnabled(frame)
    self.collectorFrames[frame] = state
  end
  SafeSetAlpha(frame, 0)
  SafeEnableMouse(frame, nil)
end

function MSM:RestoreCollector(frame)
  local state = self.collectorFrames[frame]
  if not state or not IsFrameObject(frame) then
    self.collectorFrames[frame] = nil
    return
  end
  SafeSetAlpha(frame, state.alpha or 1)
  SafeEnableMouse(frame, state.mouse)
  self.collectorFrames[frame] = nil
end

function MSM:RestoreCollectors()
  local frames = {}
  local frame, index
  for frame in pairs(self.collectorFrames) do table.insert(frames, frame) end
  for index = 1, table.getn(frames) do self:RestoreCollector(frames[index]) end
end

function MSM:IsDescendantOf(frame, ancestor)
  if not IsFrameObject(frame) or not IsFrameObject(ancestor) then return nil end
  local parent = SafeGetParent(frame)
  local depth = 0
  while parent and depth < 12 do
    if parent == ancestor then return 1 end
    parent = SafeGetParent(parent)
    depth = depth + 1
  end
  return nil
end

function MSM:CollectorHasEntry(collector)
  if not IsFrameObject(collector) then return nil end
  local _, entry
  for _, entry in pairs(self.entries or {}) do
    local managed = entry and (entry.hideFrame or entry.frame) or nil
    if IsFrameObject(managed) and self:IsDescendantOf(managed, collector) then return 1 end
  end
  return nil
end

function MSM:IsInsideManagedCollector(frame)
  local index, collector
  for index = 1, table.getn(COLLECTOR_NAMES) do
    collector = _G[COLLECTOR_NAMES[index]]
    if IsFrameObject(collector) and self:IsDescendantOf(frame, collector) then return 1 end
  end
  local pfButtons = type(pfUI) == "table" and pfUI.addonbuttons or nil
  if IsFrameObject(pfButtons) and self:IsDescendantOf(frame, pfButtons) then return 1 end
  return nil
end

function MSM:SuppressOtherCollectors(allowSuppression)
  if not allowSuppression or not self.db.suppressPfUI or not self.db.enabled then
    self:RestoreCollectors()
    return
  end

  local index, frame
  for index = 1, table.getn(COLLECTOR_NAMES) do
    frame = _G[COLLECTOR_NAMES[index]]
    if IsFrameObject(frame) and self:CollectorHasEntry(frame) then self:RememberCollector(frame) end
  end

  local pfButtons = type(pfUI) == "table" and SafeGetField(pfUI, "addonbuttons") or nil
  if not IsFrameObject(pfButtons) then pfButtons = _G["pfMinimapButtons"] end
  if IsFrameObject(pfButtons) and (self:CollectorHasEntry(pfButtons) or (self.scanStats and (self.scanStats.registry or 0) > 0)) then
    self:RememberCollector(pfButtons)
    local minimapButton = SafeGetField(pfButtons, "minimapbutton")
    if not IsFrameObject(minimapButton) then minimapButton = _G["pfMinimapButton"] end
    if IsFrameObject(minimapButton) then self:RememberCollector(minimapButton) end
  end
end

function MSM:AddCandidate(frame, discovered)
  if self.scanStats then self.scanStats.candidates = (self.scanStats.candidates or 0) + 1 end
  if not IsFrameObject(frame) then
    if frame ~= nil and self.scanStats then self.scanStats.invalid = (self.scanStats.invalid or 0) + 1 end
    return nil
  end
  if (self.scanStats.captured or 0) >= 240 then return nil end
  if not self:IsCandidate(frame, discovered) then return nil end

  local key = GetFrameName(frame)
  if not key or key == "" then
    if self.scanStats then self.scanStats.invalid = (self.scanStats.invalid or 0) + 1 end
    return nil
  end
  local destination = self.scanEntries or self.entries
  local entry = destination[key]
  if not entry then
    entry = { key = key, frame = frame }
    destination[key] = entry
    if self.scanStats then self.scanStats.captured = (self.scanStats.captured or 0) + 1 end
  else
    entry.frame = frame
  end

  entry.hideFrame = self:GetHideFrame(frame)
  entry.label = self:DeriveLabel(frame)
  entry.special = KNOWN_SPECIAL[key]
  entry.nativeShown = SafeIsShown(entry.hideFrame or frame)
  entry.forceVisible = ALWAYS_LIST[key]
  entry.seen = 1
  local iconOK, iconError = pcall(self.CaptureEntryIcon, self, entry)
  if not iconOK or not entry.iconPath then
    entry.iconPath = "Interface\\Icons\\INV_Misc_QuestionMark"
    entry.iconCoords = nil
    entry.iconR, entry.iconG, entry.iconB = 1, 1, 1
    entry.iconScore = -9999
    entry.iconFallback = 1
    if self.scanStats then
      self.scanStats.iconErrors = (self.scanStats.iconErrors or 0) + 1
      self.scanStats.lastIconError = tostring(iconError or "icon path unavailable")
    end
  end
  return entry
end

-- Conservative discovery: inspect only the two known minimap roots, known
-- collector frames, and pfUI's explicit button-name list. Never walk UIParent
-- and never recurse more than two levels.
function MSM:ScanChildren(root, depth)
  depth = depth or 0
  if depth > 1 then return end
  if not IsFrameObject(root) then
    if root ~= nil and self.scanStats then self.scanStats.invalid = (self.scanStats.invalid or 0) + 1 end
    return
  end

  local children = SafeGetObjects(root, "GetChildren", 96)
  local index, child
  for index = 1, table.getn(children) do
    child = children[index]
    if IsFrameObject(child) then
      self:AddCandidate(child, 1)
      if depth < 1 then self:ScanChildren(child, depth + 1) end
    elseif child ~= nil and self.scanStats then
      self.scanStats.invalid = (self.scanStats.invalid or 0) + 1
    end
    if (self.scanStats.captured or 0) >= 160 then return end
  end
end

function MSM:ScanRoot(root)
  if not IsFrameObject(root) then
    if root ~= nil and self.scanStats then self.scanStats.invalid = (self.scanStats.invalid or 0) + 1 end
    return
  end
  if self.scanStats then self.scanStats.roots = (self.scanStats.roots or 0) + 1 end
  self:ScanChildren(root, 0)
end

local function EntryQuality(entry)
  if not entry then return -9999 end
  local score = entry.iconFallback and 0 or 25
  score = score + math.max(-20, math.min(40, tonumber(entry.iconScore) or 0) / 10)
  if entry.special then score = score + 60 end
  if SafeGetScript(entry.frame, "OnClick") then score = score + 50 end
  if SafeGetScript(entry.frame, "OnMouseDown") or SafeGetScript(entry.frame, "OnMouseUp") then score = score + 30 end
  if entry.nativeShown then score = score + 8 end
  if entry.label and entry.label ~= "Minimap Button" then score = score + 6 end
  return score
end

function MSM:BuildOrder()
  local list = {}
  local containerGroups = {}
  local knownGroups = {}
  local key, entry, container, existing, frameName, group

  -- Nested wrapper frames can expose both a container and its clickable child.
  -- Keep the best actionable/icon-bearing entry while hiding the shared wrapper.
  for key, entry in pairs(self.entries) do
    if entry.seen and IsFrameObject(entry.frame) then
      container = entry.hideFrame or entry.frame
      existing = containerGroups[container]
      if not existing or EntryQuality(entry) > EntryQuality(existing) then containerGroups[container] = entry end
    end
  end

  for container, entry in pairs(containerGroups) do
    frameName = GetFrameName(entry.frame)
    group = frameName and KNOWN_LABELS[frameName] or nil
    if group then
      existing = knownGroups[group]
      if not existing or EntryQuality(entry) > EntryQuality(existing) then knownGroups[group] = entry end
    else
      table.insert(list, entry)
    end
  end

  for group, entry in pairs(knownGroups) do table.insert(list, entry) end
  table.sort(list, function(a, b)
    local left = Lower(a.label)
    local right = Lower(b.label)
    if left == right then return Lower(a.key) < Lower(b.key) end
    return left < right
  end)
  self.entryOrder = list
end

function MSM:HarvestButtonRegistry(registry, sourceName)
  if type(registry) ~= "table" then return end
  local key, stored, inspected
  inspected = 0
  for key, stored in pairs(registry) do
    inspected = inspected + 1
    if inspected > 400 then break end
    if type(key) == "string" and IsFrameObject(_G[key]) then
      if self:AddCandidate(_G[key], 1) and self.scanStats then self.scanStats.registry = (self.scanStats.registry or 0) + 1 end
    end
    if type(stored) == "string" and IsFrameObject(_G[stored]) then
      if self:AddCandidate(_G[stored], 1) and self.scanStats then self.scanStats.registry = (self.scanStats.registry or 0) + 1 end
    elseif IsFrameObject(stored) then
      if self:AddCandidate(stored, 1) and self.scanStats then self.scanStats.registry = (self.scanStats.registry or 0) + 1 end
    elseif type(stored) == "table" then
      local nestedFrame = SafeGetField(stored, "frame") or SafeGetField(stored, "button")
      if IsFrameObject(nestedFrame) then
        if self:AddCandidate(nestedFrame, 1) and self.scanStats then self.scanStats.registry = (self.scanStats.registry or 0) + 1 end
      end
    elseif stored ~= nil and type(stored) ~= "number" and type(stored) ~= "boolean" and type(stored) ~= "function" and self.scanStats then
      self.scanStats.invalid = (self.scanStats.invalid or 0) + 1
    end
  end
end

function MSM:ScanGlobalButtonRegistry(fullScan)
  self.globalRegistry = self.globalRegistry or {}
  if fullScan then
    local globalName, value
    local checked = 0
    for globalName, value in pairs(_G) do
      if type(globalName) == "string" and self:IsPotentialGlobalButtonName(globalName) and IsObjectLike(value) then
        checked = checked + 1
        if IsFrameObject(value) and self:FrameIsNearMinimap(value, globalName) then
          self.globalRegistry[globalName] = value
        end
      end
    end
    self.lastGlobalScan = GetTime()
    if self.scanStats then self.scanStats.globalChecked = checked end
  end

  local globalName, frame, entry
  local stale = {}
  for globalName, frame in pairs(self.globalRegistry) do
    if _G[globalName] ~= frame or not IsFrameObject(frame) then
      table.insert(stale, globalName)
    elseif self:FrameIsNearMinimap(frame, globalName) or self:IsInsideManagedCollector(frame) then
      entry = self:AddCandidate(frame, 1)
      if entry and self.scanStats then self.scanStats.globalFound = (self.scanStats.globalFound or 0) + 1 end
      -- Do not enumerate children of arbitrary named globals. Even when a frame
      -- is positioned beside the minimap, its C-backed child list is not a safe
      -- traversal root on every Vanilla-derived client. Clickable child buttons
      -- are discovered by their own global names; only Minimap, MinimapBackdrop,
      -- and known collector frames are traversed elsewhere.
    end
  end
  local index
  for index = 1, table.getn(stale) do self.globalRegistry[stale[index]] = nil end
end

function MSM:CollectScanCandidates(fullGlobalScan)
  if not self.addonIndexBuilt then self:BuildAddonNameIndex() end

  -- Some pfUI builds expose addonbuttons as the collector frame; others expose
  -- a module table while the real frame remains available as pfMinimapButtons.
  -- Harvest both without requiring the registry owner itself to be a frame.
  local pfModule = type(pfUI) == "table" and SafeGetField(pfUI, "addonbuttons") or nil
  local pfButtons = IsFrameObject(pfModule) and pfModule or _G["pfMinimapButtons"]
  if IsObjectLike(pfModule) then
    self:HarvestButtonRegistry(SafeGetField(pfModule, "buttons"), "pfUI module")
  end
  if IsObjectLike(pfButtons) and pfButtons ~= pfModule then
    self:HarvestButtonRegistry(SafeGetField(pfButtons, "buttons"), "pfUI panel")
  end
  if IsFrameObject(pfButtons) then
    -- One direct child pass is safe after the delayed world-entry scan and
    -- catches wrappers omitted from older pfUI button arrays.
    local children = SafeGetObjects(pfButtons, "GetChildren", 96)
    local index
    for index = 1, table.getn(children) do self:AddCandidate(children[index], 1) end
  end

  if type(pfUI_cache) == "table" and type(pfUI_cache["abuttons"]) == "table" then
    self:HarvestButtonRegistry(pfUI_cache["abuttons"]["add"], "pfUI cache")
  end

  self:ScanRoot(Minimap)
  self:ScanRoot(MinimapBackdrop)

  local collectorIndex, collectorFrame
  for collectorIndex = 1, table.getn(COLLECTOR_NAMES) do
    local collectorName = COLLECTOR_NAMES[collectorIndex]
    collectorFrame = _G[collectorName]
    if collectorFrame ~= pfButtons then self:ScanRoot(collectorFrame) end
  end

  self:ScanGlobalButtonRegistry(fullGlobalScan)

  local knownName
  for knownName in pairs(KNOWN_LABELS) do self:AddCandidate(_G[knownName], 1) end
  for knownName in pairs(KNOWN_GLOBAL_INCLUDE) do
    local frame = _G[knownName]
    if IsFrameObject(frame) and self:FrameIsNearMinimap(frame, knownName) then self:AddCandidate(frame, 1) end
  end
end

function MSM:ApplyCollectionState()
  if not self.db.enabled then
    self:RestoreAllFrames()
    return
  end

  local key, entry, managed
  for key, entry in pairs(self.entries) do
    managed = entry.hideFrame or entry.frame
    if IsFrameObject(managed) then
      if self.db.excluded[key] then
        self:RestoreFrame(managed)
      elseif self.db.suppressPfUI and self:IsInsideManagedCollector(managed) then
        -- Hiding the collector parent is sufficient and avoids fighting its
        -- own layout loop over individual children.
        self:RestoreFrame(managed)
      else
        self:RememberAndHide(managed)
      end
    end
  end

  self:SuppressOtherCollectors(table.getn(self.entryOrder) > 0)
end

function MSM:ScanNow(force, fullGlobalScan)
  if not self.initialized or not self.db then return end
  if not self.worldReady and not force then return end
  if self.scanInProgress then return end
  local now = GetTime()
  if not force and now < self.lastScan + 1 then return end

  self.scanInProgress = 1
  self.lastScan = now
  if fullGlobalScan then
    self.globalScanPending = 1
    self.captureRescanAll = 1
  end
  -- Global _G enumeration is intentionally manual-only in 1.0.8. Earlier
  -- versions ran it automatically every 45 seconds, which caused a visible
  -- frame hitch on old clients with large addon sets.
  local doGlobalScan = self.globalScanPending and 1 or nil
  self.globalScanPending = nil
  if doGlobalScan then self.lastDeepScan = now end
  self.scanPending = nil

  local oldEntries = self.entries or {}
  local oldOrder = self.entryOrder or {}
  local newEntries = {}
  self.scanEntries = newEntries
  self.scanStats = { roots = 0, candidates = 0, invalid = 0, captured = 0, registry = 0, globalFound = 0, globalChecked = 0, iconFallbacks = 0, iconErrors = 0, scopeRejected = 0, contentNodesRejected = 0, mode = "event-driven-minimap-scope" }

  local ok, errorText = pcall(function() MSM:CollectScanCandidates(doGlobalScan) end)
  self.scanEntries = nil
  self.scanInProgress = nil
  if not ok then
    self.scanFailures = (self.scanFailures or 0) + 1
    local message = tostring(errorText or "unknown scan error")
    local changed = self.lastScanError ~= message
    self.lastScanError = message
    self:RestoreAllFrames()
    self.entries = oldEntries
    self.entryOrder = oldOrder
    self:UpdateLauncher()
    if changed then self:Print("Conservative scan failed; original buttons were restored. " .. message) end
    return
  end

  self.lastScanError = nil
  local key, oldEntry
  for key, oldEntry in pairs(oldEntries) do
    if not newEntries[key] and oldEntry then self:RestoreFrame(oldEntry.hideFrame or oldEntry.frame) end
  end

  self.entries = newEntries
  self:BuildOrder()
  local iconIndex
  for iconIndex = 1, table.getn(self.entryOrder) do
    if self.entryOrder[iconIndex].iconFallback then self.scanStats.iconFallbacks = self.scanStats.iconFallbacks + 1 end
  end
  if table.getn(self.entryOrder) == 0 then
    -- Never leave the user with an empty menu and hidden originals.
    self:RestoreAllFrames()
  else
    self:ApplyCollectionState()
  end
  self:UpdateLauncher()
  if self.menu and self.menu:IsShown() then self:RefreshMenu() end
  if self.options and self.options:IsShown() and self.RefreshOptionsButtonList then self:RefreshOptionsButtonList() end
end

function MSM:ForwardScript(entry, scriptName, mouseButton, quiet)
  if not entry or not entry.frame then return nil end
  local handler = SafeGetScript(entry.frame, scriptName)
  if not handler then return nil end
  local oldThis, oldArg1 = this, arg1
  this = entry.frame
  arg1 = mouseButton
  local ok, errorText = pcall(handler)
  this = oldThis
  arg1 = oldArg1
  if not ok and not quiet then self:Print("Button error (" .. entry.label .. "): " .. tostring(errorText)) end
  return ok and 1 or nil
end

function MSM:RunSpecial(entry, mouseButton)
  if not entry then return nil end

  local frameName = GetFrameName(entry.frame) or ""
  local label = Lower(entry.label or "")
  local owner = Lower(entry.captureOwner or "")
  local isLFT = entry.special == "LFT_TOGGLE"
    or frameName == "LFT_Minimap"
    or frameName == "LFT_MinimapButton"
    or frameName == "LFT_MinimapFrame"
    or frameName == "LFTMinimapButton"
    or owner == "lft"
    or string.find(label, "looking for turtles", 1, true) ~= nil

  -- Looking For Turtles uses a global toggle routine in addition to its
  -- minimap mouse scripts. Calling it directly avoids wrapper/button script
  -- differences between LFT builds and prevents an accidental double toggle.
  if isLFT and (not mouseButton or mouseButton == "LeftButton") and type(LFT_Toggle) == "function" then
    local ok, errorText = pcall(LFT_Toggle)
    if not ok then self:Print("Looking For Turtles error: " .. tostring(errorText)) end
    return ok and 1 or nil
  end

  if not entry.special then return nil end
  if entry.special == "PFQUEST_TOGGLE" and (not mouseButton or mouseButton == "LeftButton") then
    if type(pfQuestMenu) == "table" and type(pfQuestMenu.IsShown) == "function" then
      local ok, errorText = pcall(function()
        if pfQuestMenu:IsShown() then pfQuestMenu:Hide() else pfQuestMenu:Show() end
      end)
      if not ok then self:Print("pfQuest error: " .. tostring(errorText)) end
      return ok and 1 or nil
    end
  elseif entry.special == "ATLAS_CFM_TOGGLE" and (not mouseButton or mouseButton == "LeftButton") then
    if type(AtlasCFM) == "table" and type(AtlasCFM.ToggleAtlas) == "function" then
      local ok, errorText = pcall(AtlasCFM.ToggleAtlas)
      if not ok then self:Print("Atlas-CFM error: " .. tostring(errorText)) end
      return ok and 1 or nil
    end
  elseif entry.special == "FLIGHT_TRACKER_TOGGLE" and (not mouseButton or mouseButton == "LeftButton") then
    if type(FlightTracker) == "table" and type(FlightTracker.GUI) == "table" and type(FlightTracker.GUI.Toggle) == "function" then
      local ok, errorText = pcall(function() FlightTracker.GUI:Toggle() end)
      if not ok then self:Print("Flight Tracker error: " .. tostring(errorText)) end
      return ok and 1 or nil
    end
  elseif entry.special == "WORLD_MAP" and ToggleWorldMap then
    ToggleWorldMap()
    return 1
  elseif entry.special == "ZOOM_IN" and Minimap_ZoomIn then
    Minimap_ZoomIn()
    return 1
  elseif entry.special == "ZOOM_OUT" and Minimap_ZoomOut then
    Minimap_ZoomOut()
    return 1
  elseif entry.special == "TOGGLE_MINIMAP" and ToggleMinimap then
    ToggleMinimap()
    return 1
  elseif entry.special == "MAIL_STATUS" then
    return 1
  end
  return nil
end

function MSM:ActivateEntry(entry, mouseButton)
  if not entry then return end
  local activated = self:RunSpecial(entry, mouseButton)
  if not activated then
    activated = self:ForwardScript(entry, "OnClick", mouseButton)
  end
  -- A number of Vanilla-era minimap launchers implement only mouse-down or
  -- mouse-up handlers. Forward one normal down/up sequence when OnClick is not
  -- available. Row scripts no longer pre-forward these events, preventing the
  -- same toggle from firing twice.
  if not activated then
    local down = self:ForwardScript(entry, "OnMouseDown", mouseButton, 1)
    local up = self:ForwardScript(entry, "OnMouseUp", mouseButton, 1)
    activated = down or up
  end
  if not activated and not FrameHasAction(entry.frame) then
    self:Print(entry.label .. " is a status indicator and has no click action.")
  end
  if self.db.closeAfterClick then self:HideMenu() end
end

function MSM:SetEnabled(state)
  self.db.enabled = state and 1 or nil
  if self.db.enabled then
    self.captureRescanAll = 1
    self:RequestScan(0)
    self:ScanNow(1)
    self.launcher:Show()
  else
    self:HideMenu()
    self:RestoreAllFrames()
    self.launcher:Hide()
  end
  if self.RefreshOptions then self:RefreshOptions() end
end

function MSM:SetLocked(state)
  self.db.locked = state and 1 or nil
  self:RefreshLauncherBorder()
  if self.RefreshOptions then self:RefreshOptions() end
end

function MSM:CenterLauncher()
  self.db.point = "CENTER"
  self.db.relativePoint = "CENTER"
  self.db.x = 0
  self.db.y = 120
  self:UpdateLauncher()
  self:SetLocked(nil)
end

function MSM:RenameEntry(key, label)
  if not key then return end
  label = Trim(label)
  if label == "" then self.db.aliases[key] = nil else self.db.aliases[key] = label end
  if self.entries[key] then self.entries[key].label = self:DeriveLabel(self.entries[key].frame) end
  self:BuildOrder()
  self:RefreshMenu()
end

function MSM:SetEntryExcluded(key, excluded)
  if not key then return end
  if excluded then self.db.excluded[key] = 1 else self.db.excluded[key] = nil end
  local entry = self.entries[key]
  if entry and entry.frame then
    local managed = entry.hideFrame or entry.frame
    if excluded then self:RestoreFrame(managed) else self:RememberAndHide(managed) end
  end
  self:RequestScan(0)
  self:ScanNow(1)
end

function MSM:ResetSettings()
  local aliases = self.db.aliases or {}
  local excluded = self.db.excluded or {}
  local migration = self.db._moobStackMigration
  MSMinimapMenuDB = {}
  CopyDefaults(MSMinimapMenuDB, DEFAULTS)
  MSMinimapMenuDB.aliases = aliases
  MSMinimapMenuDB.excluded = excluded
  MSMinimapMenuDB._moobStackMigration = migration
  self:NormalizeSettings()
  self:UpdateLauncher()
  self:RefreshMenu()
  self.captureRescanAll = 1
  self:ScanNow(1)
  if self.RefreshOptions then self:RefreshOptions() end
end

function MSM:Status()
  local stats = self.scanStats or {}
  self:Print("Version " .. self.version .. " | enabled: " .. (self.db.enabled and "yes" or "no") .. " | locked: " .. (self.db.locked and "yes" or "no"))
  local migration = self.db and self.db._moobStackMigration
  local savedState = "MS database active"
  if self.legacyImportedAtLoad then
    savedState = "legacy settings imported this session"
  elseif type(migration) == "table" and migration.octoMinimapMenu1010 == 1 then
    savedState = "legacy migration complete"
  elseif self.legacyBridgeLoaded then
    savedState = "legacy bridge loaded; no legacy settings found"
  end
  self:Print("Saved data: " .. savedState .. " | database: MSMinimapMenuDB")
  self:Print("Scanner: event-driven minimap scope | world ready: " .. (self.worldReady and "yes" or "no") .. " | detected: " .. tostring(table.getn(self.entryOrder)) .. " | visible: " .. tostring(self:GetVisibleEntryCount()))
  self:Print("pfUI/collector registry hits: " .. tostring(stats.registry or 0) .. " | global minimap buttons: " .. tostring(stats.globalFound or 0) .. " | global names checked: " .. tostring(stats.globalChecked or 0))
  self:Print("Roots: " .. tostring(stats.roots or 0) .. " | candidates: " .. tostring(stats.candidates or 0) .. " | outside scope: " .. tostring(stats.scopeRejected or 0) .. " | fallback icons: " .. tostring(stats.iconFallbacks or 0) .. " | icon errors isolated: " .. tostring(stats.iconErrors or 0) .. " | unsafe skipped: " .. tostring(stats.invalid or 0))
  self:Print("Automatic deep scans: off | last manual deep scan: " .. ((self.lastDeepScan or 0) > 0 and string.format("%.1fs ago", GetTime() - self.lastDeepScan) or "never"))
  self:Print("Map content rejected: " .. tostring(stats.contentNodesRejected or 0) .. " | only genuine launcher buttons are listed.")
  self:Print("Scan failures this session: " .. tostring(self.scanFailures or 0) .. (self.lastScanError and (" | last: " .. self.lastScanError) or ""))
  local pfButtons = type(pfUI) == "table" and SafeGetField(pfUI, "addonbuttons") or nil
  if not IsFrameObject(pfButtons) then pfButtons = _G["pfMinimapButtons"] end
  if IsFrameObject(pfButtons) then
    self:Print("pfUI addon-button panel detected and " .. (self.db.suppressPfUI and table.getn(self.entryOrder) > 0 and "suppressed" or "left active") .. ".")
  else
    self:Print("pfUI addon-button panel not detected; named global discovery is active.")
  end
end

function MSM:PrintList()
  local entries = self:GetVisibleEntries()
  local index, entry
  self:Print("Detected minimap buttons:")
  for index = 1, table.getn(entries) do
    entry = entries[index]
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffaaaaaa%02d|r  %s  |cff666666[%s]|r", index, entry.label, entry.key))
  end
  if table.getn(entries) == 0 then DEFAULT_CHAT_FRAME:AddMessage("  None detected. Use /msminimap scan after all addons load.") end
end

function MSM:Help()
  self:Print("Commands:")
  DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/msminimap|r - open or close the button list")
  DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/msminimap config|r - open settings")
  DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/msminimap scan|r - refresh captured minimap buttons")
  DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/msminimap deep|r - one-time full global scan (may briefly pause)")
  DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/msminimap lock|r / |cff33ffccunlock|r - lock or move the launcher")
  DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/msminimap center|r - center and unlock the launcher")
  DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/msminimap list|r - print detected buttons")
  DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/msminimap enable|r / |cff33ffccdisable|r - collect or restore minimap buttons")
  DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/msminimap status|r - show diagnostic and migration status")
  DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/msminimap reset|r - reset appearance and position")
  DEFAULT_CHAT_FRAME:AddMessage("|cff888888Legacy aliases: /omm, /octominimap, /octomapmenu|r")
end

function MSM:SlashCommand(message)
  message = Trim(Lower(message or ""))
  local _, _, command, rest = string.find(message, "^(%S*)%s*(.-)$")
  command = command or ""
  rest = rest or ""
  if command == "" or command == "toggle" or command == "menu" then
    self:ToggleMenu()
  elseif command == "config" or command == "options" or command == "settings" then
    self:ToggleOptions()
  elseif command == "scan" or command == "refresh" then
    self.captureRescanAll = 1
    self:RequestScan(0)
    self:ScanNow(1)
    self:Print("Captured minimap buttons refreshed: " .. tostring(table.getn(self.entryOrder)) .. " detected.")
  elseif command == "deep" or command == "fullscan" then
    self.captureRescanAll = 1
    self:RequestScan(0, 1)
    self:ScanNow(1, 1)
    self:Print("Deep minimap scan completed: " .. tostring(table.getn(self.entryOrder)) .. " detected.")
  elseif command == "lock" then
    self:SetLocked(1)
    self:Print("Launcher locked.")
  elseif command == "unlock" or command == "move" then
    self:SetLocked(nil)
    self.launcher:Show()
    self:Print("Launcher unlocked. Drag it with the left mouse button.")
  elseif command == "center" then
    self:CenterLauncher()
    self:Print("Launcher centered and unlocked.")
  elseif command == "enable" or command == "show" then
    self:SetEnabled(1)
    self:Print("Minimap button collection enabled.")
  elseif command == "disable" or command == "restore" then
    self:SetEnabled(nil)
    self:Print("Original minimap buttons restored until re-enabled.")
  elseif command == "list" or command == "buttons" then
    self:PrintList()
  elseif command == "status" then
    self:Status()
  elseif command == "reset" then
    self:ResetSettings()
    self:Print("Appearance and launcher position reset. Button names and exclusions were preserved.")
  elseif command == "help" then
    self:Help()
  else
    self:Help()
  end
end

function MSM:Initialize()
  if self.initialized then return end
  self:NormalizeSettings()
  self:CreateLauncher()
  self:CreateMenu()
  self.initialized = 1
  self:UpdateLauncher()
  self:Print("v" .. self.version .. " loaded. Event-driven addon-button capture starts after the eight-second safety delay.")
end

function MSM:TryInitialize(reason)
  local ok, errorText
  if self.initialized then return 1 end
  self.loadStage = "initializing from " .. tostring(reason or "event")
  ok, errorText = pcall(self.Initialize, self)
  if not ok then
    self.loadError = tostring(errorText)
    self.loadStage = "initialization failed"
    self:Print("Initialization failed: " .. tostring(errorText))
    return nil
  end
  self.loadError = nil
  self.loadStage = "ready"
  return 1
end

local eventFrame = CreateFrame("Frame", "MSMinimapMenuEventFrame", UIParent)
MSM.eventFrame = eventFrame
eventFrame:RegisterEvent("VARIABLES_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("UPDATE_PENDING_MAIL")
eventFrame:RegisterEvent("MINIMAP_UPDATE_TRACKING")
eventFrame:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", function()
  if event == "VARIABLES_LOADED" then
    MSM:TryInitialize("VARIABLES_LOADED")
  elseif event == "PLAYER_ENTERING_WORLD" then
    if not MSM.initialized then MSM:TryInitialize("PLAYER_ENTERING_WORLD") end
    MSM.worldReady = 1
    -- pfUI finishes its own minimap-button layout from OnUpdate. Waiting avoids
    -- touching the same C-backed frames while the loading screen is closing.
    MSM.captureRescanAll = 1
    MSM:RequestScan(8)
  elseif event == "ADDON_LOADED" then
    if not MSM.initialized and arg1 == MSM.addonName then MSM:TryInitialize("ADDON_LOADED") end
    if MSM.worldReady and arg1 ~= MSM.addonName then
      MSM.addonIndexBuilt = nil
      MSM:RequestScan(2)
    end
  elseif MSM.worldReady then
    MSM:RequestScan(1, nil)
  end
end)

eventFrame:SetScript("OnUpdate", function()
  if not MSM.initialized or not MSM.worldReady then return end
  local elapsed = tonumber(arg1) or 0.1
  MSM.updateAccumulator = (MSM.updateAccumulator or 0) + elapsed
  if MSM.updateAccumulator < 0.10 then return end
  MSM.updateAccumulator = 0

  local now = GetTime()
  if MSM.scanPending and now >= MSM.scanAt then MSM:ScanNow(1) end
  if now >= (MSM.nextHiddenMaintenance or 0) then
    MSM.nextHiddenMaintenance = now + 2
    MSM:MaintainHiddenState()
  end
end)


MSM.HandleSlash = MSM.SlashCommand
MSM.coreLoaded = 1
MSM.loadStage = "core loaded"
