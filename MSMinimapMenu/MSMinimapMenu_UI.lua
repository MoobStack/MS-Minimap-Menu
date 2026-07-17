-- MSMinimapMenu_UI.lua
-- Configuration interface for MSMinimapMenu.

local MSM = MSMinimapMenu
if not MSM then return end

MSM.optionWidgets = MSM.optionWidgets or {}
MSM.buttonManagerRows = MSM.buttonManagerRows or {}
MSM.buttonManagerOffset = 0
MSM.selectedEntryKey = nil

local function Clamp(value, minimum, maximum)
  value = tonumber(value) or minimum
  if value < minimum then return minimum end
  if value > maximum then return maximum end
  return value
end

local function SetFont(fontString, path, size, flags)
  if not fontString then return end
  local ok = fontString:SetFont(path, size, flags or "OUTLINE")
  if not ok then fontString:SetFont("Fonts\\ARIALN.TTF", size, flags or "OUTLINE") end
end

local function OptionFontSize(theme)
  -- The menu font may be set as large as 18px. Keep configuration labels at a
  -- compact size so pfUI profiles with a large font cannot overlap columns.
  return math.min((theme and theme.fontSize) or 11, 13)
end

local function AddWidget(widget)
  table.insert(MSM.optionWidgets, widget)
  return widget
end

-- WoW 1.12-derived clients do not expose a consistent Enable/Disable pair on
-- EditBox objects. Some builds provide Disable() but no matching Enable(),
-- while buttons normally provide both. Use the native pair only when both
-- methods exist; otherwise fall back to mouse/keyboard input toggles.
local function SetControlEnabled(control, enabled)
  if not control then return end

  local hasEnable = type(control.Enable) == "function"
  local hasDisable = type(control.Disable) == "function"
  if hasEnable and hasDisable then
    if enabled then
      control:Enable()
    else
      control:Disable()
    end
  else
    if type(control.EnableMouse) == "function" then
      control:EnableMouse(enabled and 1 or nil)
    end
    if type(control.EnableKeyboard) == "function" then
      control:EnableKeyboard(enabled and 1 or nil)
    end
  end

  if not enabled and type(control.ClearFocus) == "function" then
    control:ClearFocus()
  end
  if type(control.SetAlpha) == "function" then
    control:SetAlpha(enabled and 1 or 0.45)
  end
end

function MSM:CreateText(parent, name, text, size, point, relative, relativePoint, x, y)
  local theme = self:GetTheme()
  local fs = parent:CreateFontString(name, "OVERLAY", "GameFontNormal")
  SetFont(fs, theme.font, size or OptionFontSize(theme), "OUTLINE")
  fs:SetTextColor(theme.text[1], theme.text[2], theme.text[3], theme.text[4])
  fs:SetPoint(point or "TOPLEFT", relative or parent, relativePoint or point or "TOPLEFT", x or 0, y or 0)
  fs:SetText(text or "")
  AddWidget(fs)
  return fs
end

function MSM:CreateOptionButton(parent, name, text, width, height)
  local theme = self:GetTheme()
  local button = CreateFrame("Button", name, parent)
  button:SetWidth(width or 90)
  button:SetHeight(height or 20)
  button.text = button:CreateFontString(name .. "Text", "OVERLAY", "GameFontNormal")
  button.text:SetAllPoints(button)
  SetFont(button.text, theme.font, OptionFontSize(theme), "OUTLINE")
  button.text:SetText(text or "")
  button.text:SetTextColor(theme.text[1], theme.text[2], theme.text[3], theme.text[4])
  self:ApplyBackdrop(button)
  button:SetScript("OnEnter", function()
    local t = MSM:GetTheme()
    MSM:SetBorderColor(this, t.accent[1], t.accent[2], t.accent[3], t.accent[4])
  end)
  button:SetScript("OnLeave", function() MSM:ApplyBackdrop(this) end)
  AddWidget(button)
  return button
end

function MSM:CreateCheckOption(parent, name, label, x, y, getter, setter, width)
  local theme = self:GetTheme()
  local button = CreateFrame("Button", name, parent)
  button:SetWidth(width or 285)
  button:SetHeight(22)
  button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  button.box = CreateFrame("Frame", name .. "Box", button)
  button.box:SetWidth(16)
  button.box:SetHeight(16)
  button.box:SetPoint("LEFT", button, "LEFT", 0, 0)
  self:ApplyBackdrop(button.box)
  button.check = button.box:CreateFontString(name .. "Check", "OVERLAY", "GameFontNormal")
  button.check:SetAllPoints(button.box)
  SetFont(button.check, theme.font, OptionFontSize(theme) + 1, "OUTLINE")
  button.check:SetText("x")
  button.check:SetTextColor(theme.accent[1], theme.accent[2], theme.accent[3], theme.accent[4])
  button.label = button:CreateFontString(name .. "Label", "OVERLAY", "GameFontNormal")
  button.label:SetPoint("LEFT", button.box, "RIGHT", 7, 0)
  button.label:SetPoint("RIGHT", button, "RIGHT", 0, 0)
  button.label:SetHeight(18)
  button.label:SetJustifyH("LEFT")
  SetFont(button.label, theme.font, OptionFontSize(theme), "OUTLINE")
  button.label:SetText(label)
  button.label:SetTextColor(theme.text[1], theme.text[2], theme.text[3], theme.text[4])
  button.getter = getter
  button.setter = setter
  button:SetScript("OnClick", function()
    local current = this.getter()
    this.setter(not current)
    MSM:RefreshOptions()
  end)
  button:SetScript("OnEnter", function()
    local t = MSM:GetTheme()
    MSM:SetBorderColor(this.box, t.accent[1], t.accent[2], t.accent[3], t.accent[4])
  end)
  button:SetScript("OnLeave", function() MSM:ApplyBackdrop(this.box) end)
  AddWidget(button)
  return button
end

function MSM:CreateStepper(parent, name, label, x, y, width, getter, setter, step, minimum, maximum, format)
  local theme = self:GetTheme()
  local frame = CreateFrame("Frame", name, parent)
  frame:SetWidth(width or 225)
  frame:SetHeight(22)
  frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  frame.label = frame:CreateFontString(name .. "Label", "OVERLAY", "GameFontNormal")
  frame.label:SetPoint("LEFT", frame, "LEFT", 0, 0)
  frame.label:SetWidth((width or 225) - 86)
  frame.label:SetJustifyH("LEFT")
  SetFont(frame.label, theme.font, OptionFontSize(theme), "OUTLINE")
  frame.label:SetText(label)
  frame.label:SetTextColor(theme.text[1], theme.text[2], theme.text[3], theme.text[4])

  frame.minus = self:CreateOptionButton(frame, name .. "Minus", "-", 22, 20)
  frame.minus:SetPoint("RIGHT", frame, "RIGHT", -64, 0)
  frame.value = frame:CreateFontString(name .. "Value", "OVERLAY", "GameFontNormal")
  frame.value:SetPoint("LEFT", frame.minus, "RIGHT", 2, 0)
  frame.value:SetWidth(38)
  frame.value:SetJustifyH("CENTER")
  SetFont(frame.value, theme.font, OptionFontSize(theme), "OUTLINE")
  frame.value:SetTextColor(theme.accent[1], theme.accent[2], theme.accent[3], theme.accent[4])
  frame.plus = self:CreateOptionButton(frame, name .. "Plus", "+", 22, 20)
  frame.plus:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
  frame.getter = getter
  frame.setter = setter
  frame.step = step
  frame.minimum = minimum
  frame.maximum = maximum
  frame.format = format
  frame.minus:SetScript("OnClick", function()
    local host = this:GetParent()
    host.setter(Clamp(host.getter() - host.step, host.minimum, host.maximum))
    MSM:RefreshOptions()
  end)
  frame.plus:SetScript("OnClick", function()
    local host = this:GetParent()
    host.setter(Clamp(host.getter() + host.step, host.minimum, host.maximum))
    MSM:RefreshOptions()
  end)
  AddWidget(frame)
  return frame
end

function MSM:CreateOptions()
  if self.options then return end
  local theme = self:GetTheme()
  local frame = CreateFrame("Frame", "MSMinimapMenuOptions", UIParent)
  self.options = frame
  frame:SetWidth(660)
  frame:SetHeight(560)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
  frame:SetFrameStrata("DIALOG")
  frame:SetFrameLevel(80)
  frame:SetMovable(1)
  frame:EnableMouse(1)
  frame:SetClampedToScreen(1)
  frame:Hide()
  self:ApplyBackdrop(frame)

  frame.titleBar = CreateFrame("Frame", "MSMinimapMenuOptionsTitleBar", frame)
  frame.titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
  frame.titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
  frame.titleBar:SetHeight(28)
  frame.titleBar:EnableMouse(1)
  frame.titleBar:RegisterForDrag("LeftButton")
  frame.titleBar:SetScript("OnDragStart", function() MSM.options:StartMoving() end)
  frame.titleBar:SetScript("OnDragStop", function() MSM.options:StopMovingOrSizing() end)
  self:ApplyBackdrop(frame.titleBar)
  frame.title = self:CreateText(frame.titleBar, "MSMinimapMenuOptionsTitle", "MS Minimap Menu", theme.fontSize + 2, "LEFT", frame.titleBar, "LEFT", 8, 0)
  frame.subtitle = self:CreateText(frame.titleBar, "MSMinimapMenuOptionsSubtitle", "pfUI-themed minimap button list", math.max(9, OptionFontSize(theme) - 1), "LEFT", frame.title, "RIGHT", 10, 0)
  frame.subtitle:SetTextColor(theme.muted[1], theme.muted[2], theme.muted[3], theme.muted[4])
  frame.close = self:CreateOptionButton(frame.titleBar, "MSMinimapMenuOptionsClose", "x", 24, 22)
  frame.close:SetPoint("RIGHT", frame.titleBar, "RIGHT", -3, 0)
  frame.close:SetScript("OnClick", function() MSM.options:Hide() end)

  frame.tabAppearance = self:CreateOptionButton(frame, "MSMinimapMenuTabAppearance", "APPEARANCE", 140, 23)
  frame.tabAppearance:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -38)
  frame.tabButtons = self:CreateOptionButton(frame, "MSMinimapMenuTabButtons", "BUTTONS", 140, 23)
  frame.tabButtons:SetPoint("LEFT", frame.tabAppearance, "RIGHT", 5, 0)
  frame.tabAppearance:SetScript("OnClick", function() MSM:ShowOptionsPage("appearance") end)
  frame.tabButtons:SetScript("OnClick", function() MSM:ShowOptionsPage("buttons") end)

  self:CreateAppearancePage(frame)
  self:CreateButtonsPage(frame)
  self:ShowOptionsPage("appearance")
  frame:SetScript("OnShow", function()
    MSM:ScanNow(1)
    MSM:RefreshOptions()
  end)
  if UISpecialFrames then table.insert(UISpecialFrames, "MSMinimapMenuOptions") end
end

function MSM:CreateAppearancePage(parent)
  local page = CreateFrame("Frame", "MSMinimapMenuAppearancePage", parent)
  parent.appearancePage = page
  page:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -68)
  page:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -12, 12)

  local leftWidth = 308
  local rightX = 334
  local rightWidth = 294

  page.sectionLauncher = self:CreateText(page, "MSMinimapMenuLauncherSection", "LAUNCHER", nil, "TOPLEFT", page, "TOPLEFT", 2, -3)
  page.styleLabel = self:CreateText(page, "MSMinimapMenuStyleLabel", "Style", nil, "TOPLEFT", page, "TOPLEFT", 2, -33)
  page.styleBar = self:CreateOptionButton(page, "MSMinimapMenuStyleBar", "BAR", 68, 20)
  page.styleBar:SetPoint("TOPLEFT", page, "TOPLEFT", 132, -27)
  page.styleIcon = self:CreateOptionButton(page, "MSMinimapMenuStyleIcon", "ICON", 68, 20)
  page.styleIcon:SetPoint("LEFT", page.styleBar, "RIGHT", 6, 0)
  page.styleBar:SetScript("OnClick", function() MSM.db.launcherStyle = "bar"; MSM:UpdateLauncher(); MSM:RefreshOptions() end)
  page.styleIcon:SetScript("OnClick", function() MSM.db.launcherStyle = "icon"; MSM:UpdateLauncher(); MSM:RefreshOptions() end)

  page.textLabel = self:CreateText(page, "MSMinimapMenuTextLabel", "Bar text", nil, "TOPLEFT", page, "TOPLEFT", 2, -64)
  page.textEdit = CreateFrame("EditBox", "MSMinimapMenuTextEdit", page, "InputBoxTemplate")
  page.textEdit:SetWidth(170)
  page.textEdit:SetHeight(20)
  page.textEdit:SetPoint("TOPLEFT", page, "TOPLEFT", 132, -58)
  page.textEdit:SetAutoFocus(nil)
  page.textEdit:SetMaxLetters(18)
  SetFont(page.textEdit, self:GetTheme().font, OptionFontSize(self:GetTheme()), "")
  page.textEdit:SetScript("OnEnterPressed", function()
    MSM.db.launcherText = this:GetText()
    this:ClearFocus()
    MSM:UpdateLauncher()
    MSM:RefreshOptions()
  end)
  page.textEdit:SetScript("OnEscapePressed", function() this:ClearFocus(); MSM:RefreshOptions() end)
  AddWidget(page.textEdit)

  page.locked = self:CreateCheckOption(page, "MSMinimapMenuLockedCheck", "Lock launcher position", 2, -94,
    function() return MSM.db.locked end,
    function(value) MSM:SetLocked(value) end, leftWidth)

  page.launcherScale = self:CreateStepper(page, "MSMinimapMenuScaleStep", "Launcher scale", rightX, -27, rightWidth,
    function() return MSM.db.launcherScale end,
    function(value) MSM.db.launcherScale = value; MSM:UpdateLauncher() end,
    0.05, 0.5, 2, "%.2f")
  page.launcherAlpha = self:CreateStepper(page, "MSMinimapMenuAlphaStep", "Launcher opacity", rightX, -59, rightWidth,
    function() return MSM.db.launcherAlpha end,
    function(value) MSM.db.launcherAlpha = value; MSM:UpdateLauncher() end,
    0.05, 0.15, 1, "%d%%")
  page.launcherWidth = self:CreateStepper(page, "MSMinimapMenuLauncherWidthStep", "Bar width", rightX, -91, rightWidth,
    function() return MSM.db.launcherWidth end,
    function(value) MSM.db.launcherWidth = math.floor(value); MSM:UpdateLauncher() end,
    5, 50, 240, "%d")

  page.sectionList = self:CreateText(page, "MSMinimapMenuListSection", "LIST MENU", nil, "TOPLEFT", page, "TOPLEFT", 2, -143)
  page.showIcons = self:CreateCheckOption(page, "MSMinimapMenuIconsCheck", "Show button icons", 2, -173,
    function() return MSM.db.showIcons end,
    function(value) MSM.db.showIcons = value and 1 or nil; MSM:RefreshMenu() end, leftWidth)
  page.showHidden = self:CreateCheckOption(page, "MSMinimapMenuHiddenCheck", "Show currently unavailable buttons", 2, -203,
    function() return MSM.db.showHidden end,
    function(value) MSM.db.showHidden = value and 1 or nil; MSM:RefreshMenu() end, leftWidth)
  page.closeAfter = self:CreateCheckOption(page, "MSMinimapMenuCloseAfterCheck", "Close list after selecting a button", 2, -233,
    function() return MSM.db.closeAfterClick end,
    function(value) MSM.db.closeAfterClick = value and 1 or nil end, leftWidth)
  page.pfTheme = self:CreateCheckOption(page, "MSMinimapMenuPfThemeCheck", "Use active pfUI colors and font", 2, -263,
    function() return MSM.db.usePfUITheme end,
    function(value) MSM.db.usePfUITheme = value and 1 or nil; MSM:ApplyAllThemes() end, leftWidth)
  page.suppressPf = self:CreateCheckOption(page, "MSMinimapMenuSuppressCheck", "Suppress pfUI and other button collectors", 2, -293,
    function() return MSM.db.suppressPfUI end,
    function(value) MSM.db.suppressPfUI = value and 1 or nil; MSM:ScanNow(1) end, leftWidth)

  page.menuWidth = self:CreateStepper(page, "MSMinimapMenuMenuWidthStep", "Menu width", rightX, -166, rightWidth,
    function() return MSM.db.menuWidth end,
    function(value) MSM.db.menuWidth = math.floor(value); MSM:RefreshMenu() end,
    10, 150, 420, "%d")
  page.rowHeight = self:CreateStepper(page, "MSMinimapMenuRowHeightStep", "Row height", rightX, -198, rightWidth,
    function() return MSM.db.rowHeight end,
    function(value) MSM.db.rowHeight = math.floor(value); MSM:RefreshMenu() end,
    1, 18, 44, "%d")
  page.maxRows = self:CreateStepper(page, "MSMinimapMenuMaxRowsStep", "Visible rows", rightX, -230, rightWidth,
    function() return MSM.db.maxRows end,
    function(value) MSM.db.maxRows = math.floor(value); MSM:RefreshMenu() end,
    1, 4, 24, "%d")
  page.fontSize = self:CreateStepper(page, "MSMinimapMenuFontSizeStep", "Menu font size", rightX, -262, rightWidth,
    function() return MSM.db.fontSize end,
    function(value) MSM.db.fontSize = math.floor(value); MSM:ApplyAllThemes() end,
    1, 8, 18, "%d")

  page.note = self:CreateText(page, "MSMinimapMenuAppearanceNote", "Configuration labels stay compact even when the list font is enlarged.", nil, "TOPLEFT", page, "TOPLEFT", 2, -337)
  page.note:SetTextColor(self:GetTheme().muted[1], self:GetTheme().muted[2], self:GetTheme().muted[3], self:GetTheme().muted[4])

  page.open = self:CreateOptionButton(page, "MSMinimapMenuOpenListButton", "OPEN LIST", 100, 23)
  page.open:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 2, 8)
  page.open:SetScript("OnClick", function() MSM:ShowMenu() end)
  page.rescan = self:CreateOptionButton(page, "MSMinimapMenuRescanButton", "RESCAN", 85, 23)
  page.rescan:SetPoint("LEFT", page.open, "RIGHT", 6, 0)
  page.rescan:SetScript("OnClick", function() MSM.captureRescanAll = 1; MSM:RequestScan(0); MSM:ScanNow(1); MSM:Print("Captured minimap buttons refreshed.") end)
  page.center = self:CreateOptionButton(page, "MSMinimapMenuCenterButton", "CENTER", 85, 23)
  page.center:SetPoint("LEFT", page.rescan, "RIGHT", 6, 0)
  page.center:SetScript("OnClick", function() MSM:CenterLauncher() end)
  page.enable = self:CreateOptionButton(page, "MSMinimapMenuEnableButton", "DISABLE", 90, 23)
  page.enable:SetPoint("LEFT", page.center, "RIGHT", 6, 0)
  page.enable:SetScript("OnClick", function() MSM:SetEnabled(not MSM.db.enabled); MSM:RefreshOptions() end)
  page.defaults = self:CreateOptionButton(page, "MSMinimapMenuDefaultsButton", "DEFAULTS", 90, 23)
  page.defaults:SetPoint("LEFT", page.enable, "RIGHT", 6, 0)
  page.defaults:SetScript("OnClick", function() MSM:ResetSettings() end)
end

function MSM:CreateButtonsPage(parent)
  local page = CreateFrame("Frame", "MSMinimapMenuButtonsPage", parent)
  parent.buttonsPage = page
  page:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -68)
  page:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -12, 12)

  page.help = self:CreateText(page, "MSMinimapMenuButtonsHelp", "Detected buttons are alphabetized. Uncheck a row to restore that button to the minimap.", nil, "TOPLEFT", page, "TOPLEFT", 2, -3)
  page.help:SetWidth(610)
  page.help:SetJustifyH("LEFT")
  page.help:SetTextColor(self:GetTheme().muted[1], self:GetTheme().muted[2], self:GetTheme().muted[3], self:GetTheme().muted[4])
  page.summary = self:CreateText(page, "MSMinimapMenuButtonsSummary", "Detected: 0", nil, "TOPRIGHT", page, "TOPRIGHT", -2, -26)
  page.summary:SetJustifyH("RIGHT")
  page.summary:SetTextColor(self:GetTheme().accent[1], self:GetTheme().accent[2], self:GetTheme().accent[3], self:GetTheme().accent[4])

  page.list = CreateFrame("Frame", "MSMinimapMenuButtonManagerList", page)
  page.list:SetPoint("TOPLEFT", page, "TOPLEFT", 2, -48)
  page.list:SetWidth(610)
  page.list:SetHeight(300)
  self:ApplyBackdrop(page.list)

  page.scrollbar = CreateFrame("Slider", "MSMinimapMenuButtonManagerScrollbar", page.list)
  page.scrollbar:SetOrientation("VERTICAL")
  page.scrollbar:SetPoint("TOPRIGHT", page.list, "TOPRIGHT", -3, -4)
  page.scrollbar:SetPoint("BOTTOMRIGHT", page.list, "BOTTOMRIGHT", -3, 4)
  page.scrollbar:SetWidth(11)
  page.scrollbar:SetMinMaxValues(0, 0)
  page.scrollbar:SetValueStep(1)
  page.scrollbar.thumb = page.scrollbar:CreateTexture(nil, "OVERLAY")
  page.scrollbar.thumb:SetTexture(0.65, 0.65, 0.65, 0.8)
  page.scrollbar.thumb:SetWidth(9)
  page.scrollbar.thumb:SetHeight(28)
  page.scrollbar:SetThumbTexture(page.scrollbar.thumb)
  page.scrollbar:SetScript("OnValueChanged", function()
    MSM.buttonManagerOffset = math.floor(arg1 or this:GetValue())
    MSM:RefreshOptionsButtonList()
  end)
  page.list:EnableMouseWheel(1)
  page.list:SetScript("OnMouseWheel", function()
    local offset = MSM.buttonManagerOffset
    if arg1 > 0 then offset = offset - 1 else offset = offset + 1 end
    page.scrollbar:SetValue(offset)
  end)

  local index
  for index = 1, 10 do
    local row = CreateFrame("Button", "MSMinimapMenuManagerRow" .. index, page.list)
    self.buttonManagerRows[index] = row
    row:SetPoint("TOPLEFT", page.list, "TOPLEFT", 3, -4 - ((index - 1) * 29))
    row:SetWidth(585)
    row:SetHeight(27)
    row.check = CreateFrame("Button", "MSMinimapMenuManagerRowCheck" .. index, row)
    row.check:SetWidth(18)
    row.check:SetHeight(18)
    row.check:SetPoint("LEFT", row, "LEFT", 3, 0)
    self:ApplyBackdrop(row.check)
    row.check.text = row.check:CreateFontString("MSMinimapMenuManagerRowCheckText" .. index, "OVERLAY", "GameFontNormal")
    row.check.text:SetAllPoints(row.check)
    row.check.text:SetText("x")
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetWidth(20)
    row.icon:SetHeight(20)
    row.icon:SetPoint("LEFT", row.check, "RIGHT", 7, 0)
    row.text = row:CreateFontString("MSMinimapMenuManagerRowText" .. index, "OVERLAY", "GameFontNormal")
    row.text:SetPoint("LEFT", row.icon, "RIGHT", 7, 0)
    row.text:SetPoint("RIGHT", row, "RIGHT", -7, 0)
    row.text:SetJustifyH("LEFT")
    row.hover = row:CreateTexture(nil, "BACKGROUND")
    row.hover:SetAllPoints(row)
    row.hover:Hide()
    row:SetScript("OnClick", function()
      if this.entry then
        MSM.selectedEntryKey = this.entry.key
        MSM:RefreshOptionsButtonList()
        MSM:RefreshSelectedEntryEditor()
      end
    end)
    row.check:SetScript("OnClick", function()
      local host = this:GetParent()
      if host.entry then
        MSM:SetEntryExcluded(host.entry.key, not MSM.db.excluded[host.entry.key])
        MSM.selectedEntryKey = host.entry.key
        MSM:RefreshOptionsButtonList()
        MSM:RefreshSelectedEntryEditor()
      end
    end)
    row:SetScript("OnEnter", function()
      local t = MSM:GetTheme()
      this.hover:SetTexture(t.hover[1], t.hover[2], t.hover[3], t.hover[4])
      this.hover:Show()
    end)
    row:SetScript("OnLeave", function() this.hover:Hide() end)
  end

  page.selected = self:CreateText(page, "MSMinimapMenuSelectedLabel", "Selected: none", nil, "TOPLEFT", page, "TOPLEFT", 2, -363)
  page.selected:SetWidth(610)
  page.selected:SetJustifyH("LEFT")
  page.key = self:CreateText(page, "MSMinimapMenuSelectedKey", "", math.max(9, OptionFontSize(self:GetTheme()) - 1), "TOPLEFT", page, "TOPLEFT", 2, -386)
  page.key:SetWidth(610)
  page.key:SetJustifyH("LEFT")
  page.key:SetTextColor(self:GetTheme().muted[1], self:GetTheme().muted[2], self:GetTheme().muted[3], self:GetTheme().muted[4])
  page.nameLabel = self:CreateText(page, "MSMinimapMenuRenameLabel", "Display name", nil, "TOPLEFT", page, "TOPLEFT", 2, -416)
  page.nameEdit = CreateFrame("EditBox", "MSMinimapMenuRenameEdit", page, "InputBoxTemplate")
  page.nameEdit:SetWidth(260)
  page.nameEdit:SetHeight(20)
  page.nameEdit:SetPoint("TOPLEFT", page, "TOPLEFT", 110, -410)
  page.nameEdit:SetAutoFocus(nil)
  page.nameEdit:SetMaxLetters(40)
  SetFont(page.nameEdit, self:GetTheme().font, OptionFontSize(self:GetTheme()), "")
  page.nameEdit:SetScript("OnEnterPressed", function() MSM:SaveSelectedEntryName(); this:ClearFocus() end)
  page.nameEdit:SetScript("OnEscapePressed", function() this:ClearFocus(); MSM:RefreshSelectedEntryEditor() end)
  AddWidget(page.nameEdit)

  page.saveName = self:CreateOptionButton(page, "MSMinimapMenuSaveNameButton", "SAVE NAME", 90, 22)
  page.saveName:SetPoint("LEFT", page.nameEdit, "RIGHT", 7, 0)
  page.saveName:SetScript("OnClick", function() MSM:SaveSelectedEntryName() end)
  page.resetName = self:CreateOptionButton(page, "MSMinimapMenuResetNameButton", "RESET NAME", 95, 22)
  page.resetName:SetPoint("LEFT", page.saveName, "RIGHT", 6, 0)
  page.resetName:SetScript("OnClick", function()
    if MSM.selectedEntryKey then
      MSM.db.aliases[MSM.selectedEntryKey] = nil
      local entry = MSM.entries[MSM.selectedEntryKey]
      if entry then entry.label = MSM:DeriveLabel(entry.frame) end
      MSM:BuildOrder()
      MSM:RefreshOptionsButtonList()
      MSM:RefreshSelectedEntryEditor()
      MSM:RefreshMenu()
    end
  end)
  page.rescan = self:CreateOptionButton(page, "MSMinimapMenuManagerRescan", "RESCAN", 85, 23)
  page.rescan:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 2, 8)
  page.rescan:SetScript("OnClick", function() MSM.captureRescanAll = 1; MSM:RequestScan(0); MSM:ScanNow(1); MSM:RefreshOptionsButtonList() end)
  page.restore = self:CreateOptionButton(page, "MSMinimapMenuManagerRestore", "INCLUDE ALL", 105, 23)
  page.restore:SetPoint("LEFT", page.rescan, "RIGHT", 6, 0)
  page.restore:SetScript("OnClick", function()
    MSM.db.excluded = {}
    MSM.captureRescanAll = 1
    MSM:RequestScan(0)
    MSM:ScanNow(1)
    MSM:RefreshOptionsButtonList()
  end)
end

function MSM:ShowOptionsPage(pageName)
  if not self.options then return end
  local theme = self:GetTheme()
  if pageName == "buttons" then
    self.options.appearancePage:Hide()
    self.options.buttonsPage:Show()
    self:SetBorderColor(self.options.tabButtons, theme.accent[1], theme.accent[2], theme.accent[3], theme.accent[4])
    self:ApplyBackdrop(self.options.tabAppearance)
    self.currentOptionsPage = "buttons"
    self:RefreshOptionsButtonList()
    self:RefreshSelectedEntryEditor()
  else
    self.options.buttonsPage:Hide()
    self.options.appearancePage:Show()
    self:SetBorderColor(self.options.tabAppearance, theme.accent[1], theme.accent[2], theme.accent[3], theme.accent[4])
    self:ApplyBackdrop(self.options.tabButtons)
    self.currentOptionsPage = "appearance"
  end
end

function MSM:ApplyAllThemes()
  local theme = self:GetTheme()
  if self.launcher then self:UpdateLauncher() end
  if self.menu then self:RefreshMenu() end
  if self.options then
    self:ApplyBackdrop(self.options)
    self:ApplyBackdrop(self.options.titleBar)
    local index, widget
    for index = 1, table.getn(self.optionWidgets) do
      widget = self.optionWidgets[index]
      if widget then
        if widget.GetObjectType and widget:GetObjectType() == "FontString" then
          SetFont(widget, theme.font, OptionFontSize(theme), "OUTLINE")
        elseif widget.text and widget.text.SetFont then
          SetFont(widget.text, theme.font, OptionFontSize(theme), "OUTLINE")
        elseif widget.GetObjectType and widget:GetObjectType() == "EditBox" then
          SetFont(widget, theme.font, OptionFontSize(theme), "")
        end
      end
    end
    self:RefreshOptions()
  end
end

function MSM:RefreshOptions()
  if not self.options then return end
  local theme = self:GetTheme()
  local page = self.options.appearancePage
  page.textEdit:SetText(self.db.launcherText)
  page.locked.check:SetText(self.db.locked and "x" or "")
  page.showIcons.check:SetText(self.db.showIcons and "x" or "")
  page.showHidden.check:SetText(self.db.showHidden and "x" or "")
  page.closeAfter.check:SetText(self.db.closeAfterClick and "x" or "")
  page.pfTheme.check:SetText(self.db.usePfUITheme and "x" or "")
  page.suppressPf.check:SetText(self.db.suppressPfUI and "x" or "")
  page.enable.text:SetText(self.db.enabled and "DISABLE" or "ENABLE")

  local steppers = { page.launcherScale, page.launcherAlpha, page.launcherWidth, page.menuWidth, page.rowHeight, page.maxRows, page.fontSize }
  local index, stepper, value
  for index = 1, table.getn(steppers) do
    stepper = steppers[index]
    value = stepper.getter()
    if stepper.format == "%d%%" then
      stepper.value:SetText(tostring(math.floor(value * 100 + 0.5)) .. "%")
    elseif stepper.format == "%.2f" then
      stepper.value:SetText(string.format("%.2f", value))
    else
      stepper.value:SetText(tostring(math.floor(value + 0.5)))
    end
  end

  self:ApplyBackdrop(page.styleBar)
  self:ApplyBackdrop(page.styleIcon)
  if self.db.launcherStyle == "icon" then
    self:SetBorderColor(page.styleIcon, theme.accent[1], theme.accent[2], theme.accent[3], theme.accent[4])
  else
    self:SetBorderColor(page.styleBar, theme.accent[1], theme.accent[2], theme.accent[3], theme.accent[4])
  end

  if self.currentOptionsPage == "buttons" then
    self:RefreshOptionsButtonList()
    self:RefreshSelectedEntryEditor()
  end
end

function MSM:RefreshOptionsButtonList()
  if not self.options or not self.options.buttonsPage then return end
  local page = self.options.buttonsPage
  local total = table.getn(self.entryOrder)
  local maxOffset = math.max(0, total - 10)
  if self.buttonManagerOffset > maxOffset then self.buttonManagerOffset = maxOffset end
  if self.buttonManagerOffset < 0 then self.buttonManagerOffset = 0 end
  page.scrollbar:SetMinMaxValues(0, maxOffset)
  if page.scrollbar:GetValue() ~= self.buttonManagerOffset then page.scrollbar:SetValue(self.buttonManagerOffset) end
  if maxOffset > 0 then page.scrollbar:Show() else page.scrollbar:Hide() end

  local theme = self:GetTheme()
  if page.summary then
    local stats = self.scanStats or {}
    page.summary:SetText("Detected: " .. tostring(total) .. "   Addon capture: " .. tostring(stats.captureFound or 0) .. "   Anonymous: " .. tostring(stats.anonymous or 0) .. "   Fallback: " .. tostring(stats.iconFallbacks or 0))
  end
  local rowIndex, entryIndex, row, entry
  for rowIndex = 1, 10 do
    entryIndex = self.buttonManagerOffset + rowIndex
    row = self.buttonManagerRows[rowIndex]
    entry = self.entryOrder[entryIndex]
    if entry then
      row.entry = entry
      row.text:SetText(entry.label)
      SetFont(row.text, theme.font, OptionFontSize(theme), "OUTLINE")
      SetFont(row.check.text, theme.font, OptionFontSize(theme) + 1, "OUTLINE")
      row.check.text:SetText(self.db.excluded[entry.key] and "" or "x")
      row.check.text:SetTextColor(theme.accent[1], theme.accent[2], theme.accent[3], theme.accent[4])
      if self.db.excluded[entry.key] then
        row.text:SetTextColor(theme.muted[1], theme.muted[2], theme.muted[3], theme.muted[4])
      else
        row.text:SetTextColor(theme.text[1], theme.text[2], theme.text[3], theme.text[4])
      end
      self:UpdateEntryIcon(entry, row.icon)
      if self.selectedEntryKey == entry.key then
        row.hover:SetTexture(theme.hover[1], theme.hover[2], theme.hover[3], 0.7)
        row.hover:Show()
      else
        row.hover:Hide()
      end
      row:Show()
    else
      row.entry = nil
      row:Hide()
    end
  end
end

function MSM:RefreshSelectedEntryEditor()
  if not self.options or not self.options.buttonsPage then return end
  local page = self.options.buttonsPage
  local entry = self.selectedEntryKey and self.entries[self.selectedEntryKey] or nil
  if not entry then
    page.selected:SetText("Selected: none")
    page.key:SetText("")
    page.nameEdit:SetText("")
    SetControlEnabled(page.nameEdit, nil)
    SetControlEnabled(page.saveName, nil)
    SetControlEnabled(page.resetName, nil)
    return
  end
  page.selected:SetText("Selected: " .. entry.label)
  page.key:SetText(entry.key)
  SetControlEnabled(page.nameEdit, 1)
  SetControlEnabled(page.saveName, 1)
  SetControlEnabled(page.resetName, 1)
  page.nameEdit:SetText(self.db.aliases[entry.key] or entry.label)
end

function MSM:SaveSelectedEntryName()
  if not self.selectedEntryKey or not self.options then return end
  local text = self.options.buttonsPage.nameEdit:GetText()
  self:RenameEntry(self.selectedEntryKey, text)
  self:RefreshOptionsButtonList()
  self:RefreshSelectedEntryEditor()
end

function MSM:ToggleOptions()
  self:CreateOptions()
  if self.options:IsShown() then self.options:Hide() else self.options:Show() end
end
