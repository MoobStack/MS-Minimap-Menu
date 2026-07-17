-- MSMinimapMenu_CaptureBridge.lua
-- Adds safe discovery for addon-created, anonymous and arbitrarily named
-- minimap launchers without enumerating UIParent's child list.

local MSM = MSMinimapMenu
if not MSM then return end

MSM.captureMetaByFrame = MSM.captureMetaByFrame or {}
MSM.captureFrameKeys = MSM.captureFrameKeys or {}
MSM.captureKeyFrames = MSM.captureKeyFrames or {}
MSM.captureAnonymousSerial = MSM.captureAnonymousSerial or 0
MSM.captureAcceptedByFrame = MSM.captureAcceptedByFrame or {}
MSM.captureProcessedIndex = MSM.captureProcessedIndex or 0
if MSM.captureRescanAll == nil then MSM.captureRescanAll = 1 end

local function IsObject(value)
  local valueType = type(value)
  return valueType == "table" or valueType == "userdata"
end

local function Method(object, name)
  if not IsObject(object) then return nil end
  local ok, value = pcall(function() return object[name] end)
  if ok and type(value) == "function" then return value end
  return nil
end

local function IsFrame(frame)
  if not IsObject(frame) then return nil end
  local getType = Method(frame, "GetObjectType")
  if not getType or not Method(frame, "GetParent") or not Method(frame, "GetWidth") or not Method(frame, "GetHeight") then return nil end
  local ok, objectType = pcall(getType, frame)
  if not ok then return nil end
  if objectType == "Frame" or objectType == "Button" or objectType == "CheckButton" then return 1 end
  return nil
end

local function Name(frame)
  if not IsFrame(frame) then return nil end
  local method = Method(frame, "GetName")
  if not method then return nil end
  local ok, value = pcall(method, frame)
  if ok and type(value) == "string" and value ~= "" then return value end
  return nil
end

local function Parent(frame)
  if not IsFrame(frame) then return nil end
  local method = Method(frame, "GetParent")
  if not method then return nil end
  local ok, value = pcall(method, frame)
  if ok and IsFrame(value) then return value end
  return nil
end

local function Number(frame, methodName, fallback)
  local method = Method(frame, methodName)
  if not method then return fallback end
  local ok, value = pcall(method, frame)
  if ok and type(value) == "number" then return value end
  return fallback
end

local function Center(frame)
  local method = Method(frame, "GetCenter")
  if not method then return nil, nil end
  local ok, x, y = pcall(method, frame)
  if ok and type(x) == "number" and type(y) == "number" then return x, y end
  return nil, nil
end

local function Script(frame, scriptName)
  local method = Method(frame, "GetScript")
  if not method then return nil end
  local ok, value = pcall(method, frame, scriptName)
  if ok and type(value) == "function" then return value end
  return nil
end

local function HasAction(frame)
  return Script(frame, "OnClick") or Script(frame, "OnMouseDown") or Script(frame, "OnMouseUp")
end

local function IsShown(frame)
  local method = Method(frame, "IsShown")
  if not method then return 1 end
  local ok, value = pcall(method, frame)
  if not ok then return 1 end
  return value and 1 or nil
end

local function Lower(value) return string.lower(tostring(value or "")) end
local function Trim(value)
  value = tostring(value or "")
  value = string.gsub(value, "^%s+", "")
  value = string.gsub(value, "%s+$", "")
  return value
end
local function Strip(value)
  value = tostring(value or "")
  value = string.gsub(value, "|c%x%x%x%x%x%x%x%x", "")
  value = string.gsub(value, "|r", "")
  return Trim(value)
end
local function Token(value)
  value = Lower(Strip(value))
  return string.gsub(value, "[^%w]", "")
end

local Mod = math.mod or math.fmod
if not Mod then Mod = function(a, b) return a - math.floor(a / b) * b end end
local function Hash(value)
  value = tostring(value or "")
  local hash = 5381
  local index
  for index = 1, string.len(value) do
    hash = Mod((hash * 33) + string.byte(value, index), 2147483647)
  end
  return string.format("%08x", math.floor(hash))
end

local addonTitles = nil
local function BuildAddonTitles()
  addonTitles = {}
  if type(GetNumAddOns) ~= "function" or type(GetAddOnInfo) ~= "function" then return end
  local ok, count = pcall(GetNumAddOns)
  if not ok or type(count) ~= "number" then return end
  if count > 400 then count = 400 end
  local index
  for index = 1, count do
    local info = { pcall(GetAddOnInfo, index) }
    if info[1] then
      local folder = info[2]
      local title = Strip(info[3] or folder)
      if type(folder) == "string" and folder ~= "" and title ~= "" then addonTitles[Lower(folder)] = title end
    end
  end
end

local function AddonTitle(folder)
  if type(folder) ~= "string" or folder == "" then return nil end
  if not addonTitles then BuildAddonTitles() end
  return addonTitles[Lower(folder)] or Strip(folder)
end

local function OwnerFromTexture(path)
  if type(path) ~= "string" then return nil end
  local _, _, folder = string.find(Lower(path), "interface[\\/]addons[\\/]([^\\/]+)[\\/]")
  return folder
end

local function IsOurFrame(frame)
  if not IsFrame(frame) then return nil end
  if frame == MSM.launcher or frame == MSM.menu or frame == MSM.options then return 1 end
  local current = Parent(frame)
  local depth = 0
  while current and depth < 10 do
    if current == MSM.launcher or current == MSM.menu or current == MSM.options then return 1 end
    current = Parent(current)
    depth = depth + 1
  end
  return nil
end

local function IsCollectorDescendant(frame)
  if type(MSM.IsInsideManagedCollector) == "function" then
    local ok, value = pcall(MSM.IsInsideManagedCollector, MSM, frame)
    if ok and value then return 1 end
  end
  return nil
end

local function HasMapAncestor(frame)
  local current = Parent(frame)
  local depth = 0
  while current and depth < 12 do
    if current == Minimap or current == MinimapBackdrop or current == _G["pfMinimap"] or current == _G["pfMinimapButtons"] then return 1 end
    current = Parent(current)
    depth = depth + 1
  end
  return nil
end

local function StrictCoreScope(frame, name)
  if type(MSM.FrameIsInStrictMinimapScope) ~= "function" then return nil end
  local ok, value = pcall(MSM.FrameIsInStrictMinimapScope, MSM, frame, name)
  if ok and value then return 1 end
  return nil
end

local function OnCorePerimeter(frame)
  if type(MSM.FrameIsOnMinimapPerimeter) ~= "function" then return nil end
  local ok, value = pcall(MSM.FrameIsOnMinimapPerimeter, MSM, frame)
  if ok and value then return 1 end
  return nil
end

local function HasExplicitMinimapName(name)
  name = Lower(name)
  if name == "" then return nil end
  if string.find(name, "minimap", 1, true) or string.find(name, "mini_map", 1, true) then return 1 end
  if string.find(name, "mapbutton", 1, true) or string.find(name, "map_button", 1, true) then return 1 end
  if string.find(name, "mapicon", 1, true) or string.find(name, "map_icon", 1, true) then return 1 end
  return nil
end

-- Content-heavy addons can create hundreds of clickable minimap markers. Their
-- actual launcher names are known, so require the exact launcher for these
-- owners instead of treating every Minimap-parented Button as a command.
local OWNER_LAUNCHERS = {
  pfquest = { pfquesticon = 1, pfquestminimapbutton = 1 },
  atlascfm = { atlascfmminimapbutton = 1, cfmatlasminimapbutton = 1 },
  flighttracker = { flighttrackerminimapbutton = 1, ftminimapbutton = 1, flighttrackerbutton = 1 },
}

local function OwnerLauncherPolicy(owner)
  local token = Token(owner)
  if string.find(token, "pfquest", 1, true) == 1 then return OWNER_LAUNCHERS.pfquest end
  if string.find(token, "atlascfm", 1, true) == 1 or string.find(token, "cfmatlas", 1, true) == 1 then return OWNER_LAUNCHERS.atlascfm end
  if string.find(token, "flighttracker", 1, true) == 1 then return OWNER_LAUNCHERS.flighttracker end
  return nil
end

local function IsKnownMapContentNode(frame, name, owner)
  local lowered = Lower(name)
  if string.find(lowered, "pfminimappin", 1, true) == 1 then return 1 end
  if string.find(lowered, "pfmappin", 1, true) == 1 then return 1 end
  if string.find(lowered, "gathernotecompatfake", 1, true) == 1 then return 1 end
  if string.find(lowered, "pfquestpin", 1, true) == 1 then return 1 end
  if string.find(lowered, "pfquestnode", 1, true) == 1 then return 1 end
  if string.find(lowered, "pfquestroute", 1, true) == 1 then return 1 end

  local ownerPolicy = OwnerLauncherPolicy(owner)
  if ownerPolicy and not ownerPolicy[Token(name)] then return 1 end

  -- pfQuest minimap nodes carry these fields even if stack-based addon owner
  -- detection is unavailable on a particular client build.
  local okMini, mini = pcall(function() return frame.minimap end)
  local okNode, node = pcall(function() return frame.node end)
  if okMini and mini and okNode and node ~= nil and Lower(name) ~= "pfquesticon" then return 1 end
  return nil
end

local function LooksLikeNonMinimapWidget(frame, ownExplicitMinimapName)
  if type(MSM.FrameHasNonMinimapWidgetLineage) == "function" then
    local ok, value = pcall(MSM.FrameHasNonMinimapWidgetLineage, MSM, frame, ownExplicitMinimapName)
    if ok and value then return 1 end
  end

  local current = frame
  local depth = 0
  while current and depth < 5 do
    local name = Lower(Name(current))
    if name ~= "" and not (depth == 0 and ownExplicitMinimapName) then
      if string.find(name, "buffbutton", 1, true) or string.find(name, "debuffbutton", 1, true) or string.find(name, "aurabutton", 1, true) then return 1 end
      if string.find(name, "buffframe", 1, true) or string.find(name, "debuffframe", 1, true) or string.find(name, "auraframe", 1, true) then return 1 end
      if string.find(name, "pfbuff", 1, true) or string.find(name, "pfdebuff", 1, true) then return 1 end
      if string.find(name, "actionbutton", 1, true) or string.find(name, "spellbutton", 1, true) then return 1 end
      if string.find(name, "unitframe", 1, true) or string.find(name, "cooldownbutton", 1, true) then return 1 end
    end
    current = Parent(current)
    depth = depth + 1
  end
  return nil
end

local PrepareIcon

local function IsMinimapParentObject(frame)
  if not IsFrame(frame) then return nil end
  if frame == Minimap or frame == MinimapBackdrop or frame == _G["pfMinimap"] or frame == _G["pfMinimapButtons"] then return 1 end
  if type(MSM.IsCollectorFrame) == "function" then
    local ok, value = pcall(MSM.IsCollectorFrame, MSM, frame)
    if ok and value then return 1 end
  end
  local lowered = Lower(Name(frame))
  if string.find(lowered, "minimap", 1, true) or string.find(lowered, "mapbutton", 1, true) then return 1 end
  return nil
end

local function IsCapturedLauncher(frame, meta)
  if not IsFrame(frame) or IsOurFrame(frame) or not HasAction(frame) then return nil, "invalid" end

  local name = Name(frame)
  local owner = meta and Lower(meta.owner) or ""
  -- Reject quest/map content before collector membership or original-parent
  -- evidence. pfQuest deliberately uses collector-compatible pin names, so the
  -- order is essential: a pin inside pfUI's collector is still a pin.
  if IsKnownMapContentNode(frame, name, owner) then return nil, "map-content" end
  local ownerPolicy = OwnerLauncherPolicy(owner)
  if ownerPolicy and ownerPolicy[Token(name)] then return 1, "scope" end
  if IsCollectorDescendant(frame) then return 1, "collector" end

  local width = Number(frame, "GetWidth", 0)
  local height = Number(frame, "GetHeight", 0)
  if width < 5 or height < 5 or width > 80 or height > 80 then return nil, "size" end

  local explicitName = HasExplicitMinimapName(name)
  if LooksLikeNonMinimapWidget(frame, explicitName) then return nil, "ui" end
  -- pfUI creates many ordinary aura and action widgets near the minimap. Its
  -- real minimap controls have explicit minimap names or live in the collector;
  -- anonymous/generic pfUI buttons are therefore outside this addon's scope.
  if owner == "pfui" and not explicitName then return nil, "pfui-ui" end

  -- The parent passed to CreateFrame is durable evidence even when pfUI or the
  -- addon later reparents the launcher. Version 1.0.7 discarded this evidence.
  if meta and IsMinimapParentObject(meta.parent) then return 1, "original-parent" end
  if StrictCoreScope(frame, name) then return 1, "scope" end

  -- Static addon launchers are common in Vanilla: they may have no drag scripts
  -- and may be parented to UIParent while only their coordinates place them on
  -- the minimap ring. Require the strict perimeter, a harmless parent chain, and
  -- positive addon evidence before admitting that fallback.
  if not OnCorePerimeter(frame) then return nil, "position" end
  local currentParent = Parent(frame)
  local originalParent = meta and meta.parent or nil
  if currentParent and currentParent ~= UIParent and originalParent ~= UIParent then return nil, "parent" end

  local probe = PrepareIcon(frame, frame)
  local textureOwner = OwnerFromTexture(probe and probe.iconPath)
  if owner == "" and textureOwner then
    owner = Lower(textureOwner)
    if meta then meta.owner = textureOwner end
  end
  if owner == "" or owner == "pfui" then return nil, "owner" end

  if textureOwner and Lower(textureOwner) == owner then return 1, "addon-icon" end
  if Script(frame, "OnDragStart") and Script(frame, "OnDragStop") then return 1, "drag" end
  if Script(frame, "OnEnter") and meta and (meta.frameType == "Frame" or meta.frameType == "Button" or meta.frameType == "CheckButton") then return 1, "tooltip" end
  if meta and (meta.frameType == "Button" or meta.frameType == "CheckButton") and probe and not probe.iconFallback then return 1, "owner-button" end
  if meta and meta.frameType == "Frame" and probe and not probe.iconFallback then return 1, "owner-frame" end
  return nil, "evidence"
end

local function HideFrameFor(frame)
  -- Early capture is intentionally conservative: outside a known minimap
  -- collector, hide only the captured launcher itself. The sole wrapper
  -- exception is Atlas-CFM's documented 32px minimap container.
  local frameName = Name(frame)
  if frameName == "AtlasCFMMinimapButton" or frameName == "CFMAtlasMinimapButton" then
    local wrapper = _G["AtlasCFMButtonFrame"]
    if IsFrame(wrapper) then return wrapper end
  end
  if IsCollectorDescendant(frame) and type(MSM.GetHideFrame) == "function" then
    local ok, value = pcall(MSM.GetHideFrame, MSM, frame)
    if ok and IsFrame(value) then return value end
  end
  return frame
end

local OriginalDeriveLabel = MSM.DeriveLabel
function MSM:DeriveLabel(frame)
  local info = self.captureMetaByFrame and self.captureMetaByFrame[frame] or nil
  if info then
    local alias = self.db and self.db.aliases and self.db.aliases[info.key] or nil
    if alias and Trim(alias) ~= "" then return Trim(alias) end
    if info.anonymous and info.ownerLabel and info.ownerLabel ~= "" then return info.ownerLabel end
  end
  local label = OriginalDeriveLabel(self, frame)
  if info and info.ownerLabel and info.ownerLabel ~= "" then
    if not label or label == "" or label == "Minimap Button" or label == "Addon Button" then return info.ownerLabel end
  end
  return label
end

PrepareIcon = function(frame, hideFrame)
  local probe = { frame = frame, hideFrame = hideFrame }
  local ok = pcall(MSM.CaptureEntryIcon, MSM, probe)
  if not ok or not probe.iconPath then
    probe.iconPath = "Interface\\Icons\\INV_Misc_QuestionMark"
    probe.iconFallback = 1
    probe.iconR, probe.iconG, probe.iconB = 1, 1, 1
  end
  return probe
end

local function AnonymousKey(frame, meta, probe)
  local existing = MSM.captureFrameKeys[frame]
  if existing then return existing end
  local owner = meta and meta.owner or OwnerFromTexture(probe.iconPath)
  local ownerToken = Token(owner)
  if ownerToken == "" then ownerToken = "addon" end
  local parentName = Name(Parent(frame)) or ""
  local width = math.floor(Number(frame, "GetWidth", 0) + 0.5)
  local height = math.floor(Number(frame, "GetHeight", 0) + 0.5)
  local seed = Lower(owner) .. "|" .. Lower(probe.iconPath) .. "|" .. Lower(parentName) .. "|" .. tostring(width) .. "x" .. tostring(height)
  if probe.iconFallback and meta and meta.serial then seed = seed .. "|" .. tostring(meta.serial) end
  local key = "anon:" .. ownerToken .. ":" .. Hash(seed)
  if MSM.captureKeyFrames[key] and MSM.captureKeyFrames[key] ~= frame then
    MSM.captureAnonymousSerial = MSM.captureAnonymousSerial + 1
    key = key .. ":" .. tostring(meta and meta.serial or MSM.captureAnonymousSerial)
  end
  MSM.captureFrameKeys[frame] = key
  MSM.captureKeyFrames[key] = frame
  return key
end

local function AddAnonymous(frame, meta)
  local hideFrame = HideFrameFor(frame)
  local probe = PrepareIcon(frame, hideFrame)
  local key = AnonymousKey(frame, meta, probe)
  local owner = meta and meta.owner or OwnerFromTexture(probe.iconPath)
  local ownerLabel = AddonTitle(owner)
  local destination = MSM.scanEntries or MSM.entries
  local entry = destination[key]
  if not entry then
    entry = { key = key, frame = frame }
    destination[key] = entry
    MSM.scanStats.captured = (MSM.scanStats.captured or 0) + 1
  else
    entry.frame = frame
  end
  entry.hideFrame = hideFrame
  entry.nativeShown = IsShown(hideFrame or frame)
  entry.forceVisible = 1
  entry.special = nil
  entry.seen = 1
  entry.iconPath = probe.iconPath
  entry.iconCoords = probe.iconCoords
  entry.iconR, entry.iconG, entry.iconB = probe.iconR, probe.iconG, probe.iconB
  entry.iconScore = probe.iconScore
  entry.iconFallback = probe.iconFallback
  entry.captureOwner = owner
  entry.captureSource = "early"
  MSM.captureMetaByFrame[frame] = { key = key, owner = owner, ownerLabel = ownerLabel, anonymous = 1 }
  entry.label = MSM:DeriveLabel(frame)
  MSM.scanStats.anonymous = (MSM.scanStats.anonymous or 0) + 1
  return entry
end

-- A named launcher accepted only by the narrow draggable-perimeter fallback
-- cannot pass the core's anchor/name scope gate. Add it through the same safe
-- entry path used for anonymous launchers rather than weakening the core gate
-- for every named button in the UI.
local function AddCapturedNamed(frame, meta)
  local key = Name(frame)
  if not key then return nil end
  local hideFrame = HideFrameFor(frame)
  local probe = PrepareIcon(frame, hideFrame)
  local owner = meta and meta.owner or OwnerFromTexture(probe.iconPath)
  local ownerLabel = AddonTitle(owner)
  local destination = MSM.scanEntries or MSM.entries
  local entry = destination[key]
  if not entry then
    entry = { key = key, frame = frame }
    destination[key] = entry
    MSM.scanStats.captured = (MSM.scanStats.captured or 0) + 1
  else
    entry.frame = frame
  end
  entry.hideFrame = hideFrame
  entry.nativeShown = IsShown(hideFrame or frame)
  entry.forceVisible = nil
  entry.special = nil
  entry.seen = 1
  entry.iconPath = probe.iconPath
  entry.iconCoords = probe.iconCoords
  entry.iconR, entry.iconG, entry.iconB = probe.iconR, probe.iconG, probe.iconB
  entry.iconScore = probe.iconScore
  entry.iconFallback = probe.iconFallback
  entry.captureOwner = owner
  entry.captureSource = "early-static"
  MSM.captureMetaByFrame[frame] = { key = key, owner = owner, ownerLabel = ownerLabel, anonymous = nil }
  entry.label = MSM:DeriveLabel(frame)
  return entry
end

local OriginalAddCandidate = MSM.AddCandidate
local function AddCapturedRecord(frame, meta, reason)
  local frameName = Name(frame)
  local entry
  if frameName and (reason == "scope" or reason == "collector") then
    MSM.captureMetaByFrame[frame] = { key = frameName, owner = meta and meta.owner, ownerLabel = AddonTitle(meta and meta.owner), anonymous = nil }
    entry = OriginalAddCandidate(MSM, frame, 1)
    if entry then
      entry.hideFrame = HideFrameFor(frame)
      entry.captureOwner = (meta and meta.owner) or OwnerFromTexture(entry.iconPath)
      entry.captureSource = "early-" .. tostring(reason)
    end
  elseif frameName then
    entry = AddCapturedNamed(frame, meta)
  else
    entry = AddAnonymous(frame, meta)
  end
  if entry then
    entry.captureSource = "early-" .. tostring(reason or "captured")
    if not entry.captureOwner or entry.captureOwner == "" then entry.captureOwner = OwnerFromTexture(entry.iconPath) end
  end
  return entry
end

function MSM:HarvestEarlyCapturedButtons()
  local registry = _G["MSMinimapMenuCaptureRegistry"]
  self.scanStats.captureActive = type(registry) == "table" and registry.hooked and 1 or 0
  self.scanStats.captureChecked = 0
  self.scanStats.captureNewChecked = 0
  self.scanStats.captureCached = 0
  self.scanStats.captureFound = 0
  self.scanStats.captureRejectedUi = 0
  self.scanStats.captureRejectedScope = 0
  self.scanStats.captureRejectedMapContent = 0
  self.scanStats.captureMatchedByDrag = 0
  self.scanStats.captureMatchedStatic = 0
  self.scanStats.anonymous = self.scanStats.anonymous or 0
  self.scanStats.captureDropped = type(registry) == "table" and tonumber(registry.dropped) or 0
  self.scanStats.captureFilteredMapContent = type(registry) == "table" and tonumber(registry.filteredMapContent) or 0
  if type(registry) ~= "table" or type(registry.frames) ~= "table" then return end

  if self.captureRescanAll then
    self.captureAcceptedByFrame = {}
    self.captureProcessedIndex = 0
    self.captureRescanAll = nil
  end

  -- Re-add only the small accepted set to each transactional scan. This avoids
  -- reclassifying thousands of ordinary captured UI frames on every event.
  local nextAccepted = {}
  local frame, record, entry
  for frame, record in pairs(self.captureAcceptedByFrame or {}) do
    if IsFrame(frame) and not IsOurFrame(frame) and HasAction(frame) then
      entry = AddCapturedRecord(frame, record.meta, record.reason)
      self.scanStats.captureChecked = self.scanStats.captureChecked + 1
      self.scanStats.captureCached = self.scanStats.captureCached + 1
      if entry then
        nextAccepted[frame] = record
        self.scanStats.captureFound = self.scanStats.captureFound + 1
      end
    end
  end
  self.captureAcceptedByFrame = nextAccepted

  local maximum = table.getn(registry.frames)
  if maximum > 8192 then maximum = 8192 end
  local startIndex = (self.captureProcessedIndex or 0) + 1
  if startIndex < 1 then startIndex = 1 end
  local index, meta, owner, accepted, reason
  for index = startIndex, maximum do
    meta = registry.frames[index]
    frame = type(meta) == "table" and meta.frame or nil
    self.scanStats.captureChecked = self.scanStats.captureChecked + 1
    self.scanStats.captureNewChecked = self.scanStats.captureNewChecked + 1
    if IsFrame(frame) and not IsOurFrame(frame) then
      owner = Lower(meta.owner)
      if owner ~= "msminimapmenu" and owner ~= "!msminimapmenucapture" and owner ~= "octominimapmenu" and owner ~= "!octominimapmenucapture" then
        accepted, reason = IsCapturedLauncher(frame, meta)
        if accepted then
          entry = AddCapturedRecord(frame, meta, reason)
          if entry then
            self.captureAcceptedByFrame[frame] = { meta = meta, reason = reason }
            self.scanStats.captureFound = self.scanStats.captureFound + 1
            if reason == "drag" then
              self.scanStats.captureMatchedByDrag = self.scanStats.captureMatchedByDrag + 1
            elseif reason == "scope" or reason == "addon-icon" or reason == "tooltip" or reason == "owner-button" or reason == "owner-frame" or reason == "original-parent" then
              self.scanStats.captureMatchedStatic = self.scanStats.captureMatchedStatic + 1
            end
          end
        elseif reason == "ui" or reason == "pfui-ui" then
          self.scanStats.captureRejectedUi = self.scanStats.captureRejectedUi + 1
        elseif reason == "map-content" then
          self.scanStats.captureRejectedMapContent = self.scanStats.captureRejectedMapContent + 1
          self.scanStats.contentNodesRejected = (self.scanStats.contentNodesRejected or 0) + 1
        else
          self.scanStats.captureRejectedScope = self.scanStats.captureRejectedScope + 1
        end
      end
    end
  end
  self.captureProcessedIndex = maximum
end

local OriginalCollectScanCandidates = MSM.CollectScanCandidates
function MSM:CollectScanCandidates(fullGlobalScan)
  OriginalCollectScanCandidates(self, fullGlobalScan)
  self:HarvestEarlyCapturedButtons()
end

local OriginalStatus = MSM.Status
function MSM:Status()
  OriginalStatus(self)
  local stats = self.scanStats or {}
  self:Print("Early addon capture: " .. ((stats.captureActive or 0) == 1 and "active" or "missing") .. " | matched: " .. tostring(stats.captureFound or 0) .. " | cached: " .. tostring(stats.captureCached or 0) .. " | newly checked: " .. tostring(stats.captureNewChecked or 0) .. " | anonymous: " .. tostring(stats.anonymous or 0))
  self:Print("Capture evidence: static " .. tostring(stats.captureMatchedStatic or 0) .. " | draggable " .. tostring(stats.captureMatchedByDrag or 0) .. " | UI widgets rejected " .. tostring(stats.captureRejectedUi or 0) .. " | map content rejected " .. tostring((stats.captureRejectedMapContent or 0) + (stats.captureFilteredMapContent or 0)) .. " | other out-of-scope " .. tostring(stats.captureRejectedScope or 0) .. " | dropped " .. tostring(stats.captureDropped or 0))
end
