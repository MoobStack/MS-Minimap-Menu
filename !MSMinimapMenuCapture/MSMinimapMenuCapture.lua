-- !MSMinimapMenuCapture
-- Records addon-created clickable frame candidates before normal addons load.
-- It does not inspect UIParent children and does not change any frame by itself.

MSMinimapMenuCaptureRegistry = MSMinimapMenuCaptureRegistry or {}
-- Temporary runtime compatibility alias for integrations that referenced the
-- former capture registry name.
OctoMinimapMenuCaptureRegistry = MSMinimapMenuCaptureRegistry
local registry = MSMinimapMenuCaptureRegistry
registry.frames = registry.frames or {}
registry.byFrame = registry.byFrame or {}
registry.count = registry.count or 0
registry.dropped = registry.dropped or 0
registry.filteredMapContent = registry.filteredMapContent or 0
registry.filteredWorldMapContent = registry.filteredWorldMapContent or 0
registry.version = 10012

local function FindOwnerAddon()
  if type(debugstack) ~= "function" then return nil end
  local ok, stack = pcall(debugstack, 2, 12, 0)
  if not ok or type(stack) ~= "string" then return nil end
  local pattern = "Interface[\\/]AddOns[\\/]([^\\/]+)[\\/]"
  local startAt, best = 1, nil
  while 1 do
    local first, last, owner = string.find(stack, pattern, startAt)
    if not first then return best end
    if string.lower(owner or "") ~= "!msminimapmenucapture" and string.lower(owner or "") ~= "!octominimapmenucapture" then best = owner end
    startAt = last + 1
  end
end

local function StartsWith(value, prefix)
  value = string.lower(tostring(value or ""))
  prefix = string.lower(tostring(prefix or ""))
  if prefix == "" or string.len(value) < string.len(prefix) then return nil end
  return string.sub(value, 1, string.len(prefix)) == prefix and 1 or nil
end

local WORLD_MAP_LAUNCHER_ALLOW = {
  minimapworldmapbutton = 1,
  minimapzonetextbutton = 1,
}

local function SafeName(frame)
  if frame == nil then return "" end
  local okMethod, method = pcall(function() return frame.GetName end)
  if not okMethod or type(method) ~= "function" then return "" end
  local ok, value = pcall(method, frame)
  if ok and type(value) == "string" then return value end
  return ""
end

local function SafeParent(frame)
  if frame == nil then return nil end
  local okMethod, method = pcall(function() return frame.GetParent end)
  if not okMethod or type(method) ~= "function" then return nil end
  local ok, value = pcall(method, frame)
  if ok then return value end
  return nil
end

local function IsWorldMapContentName(name)
  local lowered = string.lower(tostring(name or ""))
  if lowered == "" or WORLD_MAP_LAUNCHER_ALLOW[lowered] then return nil end
  if string.sub(lowered, 1, 8) == "worldmap" or string.sub(lowered, 1, 9) == "world_map" then return 1 end
  if string.find(lowered, "worldmappoi", 1, true) or string.find(lowered, "world_map_poi", 1, true) then return 1 end
  if string.find(lowered, "worldmappin", 1, true) or string.find(lowered, "worldmapnote", 1, true) or string.find(lowered, "worldmapmarker", 1, true) then return 1 end
  return nil
end

local function HasWorldMapLineage(frame)
  local current = frame
  local depth = 0
  while current and depth < 16 do
    if current == _G["WorldMapFrame"] or current == _G["WorldMapDetailFrame"] then return 1 end
    if IsWorldMapContentName(SafeName(current)) then return 1 end
    current = SafeParent(current)
    depth = depth + 1
  end
  return nil
end

local function IsKnownMapContentName(name)
  local lowered = string.lower(tostring(name or ""))
  if IsWorldMapContentName(lowered) then return 1 end
  if StartsWith(lowered, "pfminimappin") or StartsWith(lowered, "pfmappin") then return 1 end
  if StartsWith(lowered, "gathernotecompatfake") then return 1 end
  if StartsWith(lowered, "pfquestpin") or StartsWith(lowered, "pfquestnode") or StartsWith(lowered, "pfquestroute") then return 1 end
  return nil
end

local function ShouldResolveOwner(frameType, name, parent)
  -- This helper loads after Blizzard FrameXML but before normal addons, so every
  -- captured frame is addon-created. Resolving ownership once at creation gives
  -- anonymous Frame-based minimap launchers the same coverage as Buttons.
  return 1
end

local function NotifyManager(frameType, name, parent)
  -- ADDON_LOADED performs the authoritative pass for Frame-based launchers.
  -- Late Button/CheckButton creation gets a debounced event-driven refresh.
  if frameType ~= "Button" and frameType ~= "CheckButton" then return end
  local lowered = string.lower(tostring(name or ""))
  local likelyRoot = parent == UIParent or parent == Minimap or parent == MinimapBackdrop
  local likelyName = string.find(lowered, "minimap", 1, true) or string.find(lowered, "mapbutton", 1, true) or string.find(lowered, "mapicon", 1, true)
  if not likelyRoot and not likelyName then return end
  local manager = _G["MSMinimapMenu"]
  if type(manager) == "table" and manager.worldReady and type(manager.RequestScan) == "function" then
    manager:RequestScan(0.75)
  end
end

local function Remember(frame, frameType, name, parent)
  if frame == nil or registry.byFrame[frame] then return end
  registry.count = registry.count + 1
  if registry.count > 8192 then
    registry.dropped = registry.dropped + 1
    return
  end
  if IsWorldMapContentName(name) or HasWorldMapLineage(parent) then
    registry.filteredMapContent = registry.filteredMapContent + 1
    registry.filteredWorldMapContent = registry.filteredWorldMapContent + 1
    return
  end
  if IsKnownMapContentName(name) then
    registry.filteredMapContent = registry.filteredMapContent + 1
    return
  end
  local owner = nil
  if ShouldResolveOwner(frameType, name, parent) then owner = FindOwnerAddon() end
  local meta = { frame = frame, frameType = frameType, name = name, parent = parent, owner = owner, serial = registry.count }
  registry.byFrame[frame] = meta
  table.insert(registry.frames, meta)
  NotifyManager(frameType, name, parent)
end

if not registry.hooked and type(CreateFrame) == "function" then
  local OriginalCreateFrame = CreateFrame
  registry.originalCreateFrame = OriginalCreateFrame
  function CreateFrame(frameType, name, parent, inherits)
    local frame = OriginalCreateFrame(frameType, name, parent, inherits)
    if frameType == "Frame" or frameType == "Button" or frameType == "CheckButton" then
      Remember(frame, frameType, name, parent)
    end
    return frame
  end
  registry.hooked = 1
end
