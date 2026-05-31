MafMenu = MafMenu or {}
MafMenu.Panel = MafMenu.Panel or {}

local Panel = MafMenu.Panel
local UI = MafMenu.UI
local Profile = MafMenu.Profile
local Services = MafMenu.Services
local Currency = MafMenu.Currency
local Config = MafMenu.Config

local activeSavedVars
local panel
local dragFrame
local mainCollapseButton
local mainLockButton
local mainResizeGrip
local menuButtons = {}
local sectionLabels = {}
local rowX = 10
local rowY = -38
local sectionTitles = {
    favorites = "Favorites",
    book = "Book services",
    tools = "Tools",
    toggles = "Server toggles",
}
local sectionOrder = {"book", "tools", "toggles"}
local sectionAccent = {
    favorites = UI.COLORS.gold,
    book = {0.56, 0.72, 0.82, 1},
    tools = {0.72, 0.66, 0.92, 1},
    toggles = {0.78, 0.74, 0.52, 1},
}

local function GetSaved()
    activeSavedVars = Profile.Refresh()
    return activeSavedVars
end

local function SavePanelPosition()
    UI.SaveTopLeft(panel, GetSaved())
end

local function ApplyAppearance()
    local saved = GetSaved()
    local panelColor = {UI.COLORS.panel[1], UI.COLORS.panel[2], UI.COLORS.panel[3], saved.appearance.panelOpacity}
    local borderColor = {UI.COLORS.panelBorder[1], UI.COLORS.panelBorder[2], UI.COLORS.panelBorder[3], saved.appearance.borderOpacity}
    panel:SetBackdropColor(unpack(panelColor))
    panel:SetBackdropBorderColor(unpack(borderColor))
end

local function GetRowWidth()
    return math.max(120, panel:GetWidth() - (rowX * 2))
end

local function GetRowHeight()
    return UI.ClampRowHeight(GetSaved().rowHeight)
end

local function GetRowStep()
    return GetRowHeight() + MafMenu.GAP
end

local function GetSectionLabelHeight()
    if not GetSaved().appearance.showSectionHeaders then
        return 0
    end
    return math.max(12, math.floor(GetRowHeight() * 0.5))
end

local function IsHidden(entry)
    return GetSaved().hidden[entry.key] == true
end

local function IsFavorite(entry)
    return GetSaved().favorites[entry.key] == true
end

local function EnsureSectionLabel(key)
    if not sectionLabels[key] then
        local holder = CreateFrame("Button", nil, panel)
        holder.key = key
        UI.ApplyBackdrop(holder, UI.COLORS.section, UI.COLORS.sectionBorder, 1)
        holder.text = holder:CreateFontString(nil, "OVERLAY")
        UI.SetFont(holder.text, 10)
        holder.text:SetTextColor(unpack(sectionAccent[key] or UI.COLORS.subtext))
        holder.text:SetPoint("LEFT", holder, "LEFT", 7, 0)
        holder.text:SetText(sectionTitles[key])
        holder.toggle = holder:CreateFontString(nil, "OVERLAY")
        UI.SetFont(holder.toggle, 10, "OUTLINE")
        holder.toggle:SetTextColor(unpack(UI.COLORS.gold))
        holder.toggle:SetPoint("RIGHT", holder, "RIGHT", -7, 0)
        holder:SetScript("OnClick", function(self)
            local saved = GetSaved()
            saved.sectionCollapsed[self.key] = not saved.sectionCollapsed[self.key] or nil
            Panel.BuildMenu()
        end)
        holder:SetScript("OnEnter", function(self)
            self:SetBackdropColor(unpack(UI.COLORS.buttonHover))
            self:SetBackdropBorderColor(unpack(UI.COLORS.buttonBorderHover))
        end)
        holder:SetScript("OnLeave", function(self)
            self:SetBackdropColor(unpack(UI.COLORS.section))
            self:SetBackdropBorderColor(unpack(UI.COLORS.sectionBorder))
        end)
        sectionLabels[key] = holder
    end
    if not GetSaved().appearance.showSectionHeaders then
        sectionLabels[key]:Hide()
    end
    return sectionLabels[key]
end

local function EnsureEntryButton(entry)
    if not menuButtons[entry.key] then
        menuButtons[entry.key] = Services.CreateMenuButton(entry, panel, GetRowWidth(), GetRowHeight(), rowX, rowY, entry.color or UI.COLORS.text, 12, entry.icon and nil or "CENTER")
        menuButtons[entry.key].entry = entry
        menuButtons[entry.key].favorite = CreateFrame("Button", nil, panel)
        menuButtons[entry.key].favorite.entry = entry
        menuButtons[entry.key].favorite:SetSize(18, 18)
        UI.SkinButton(menuButtons[entry.key].favorite)
        menuButtons[entry.key].favorite:SetScript("OnClick", function(self)
            local saved = GetSaved()
            saved.favorites[self.entry.key] = not saved.favorites[self.entry.key] or nil
            Panel.BuildMenu()
            Config.Refresh()
        end)
        UI.SetTooltip(menuButtons[entry.key].favorite, "Toggle favorite")
    end
    return menuButtons[entry.key]
end

local function GetEntryState(entry)
    if entry.key == "aoeOn" or entry.key == "mythicOn" then
        return "on"
    elseif entry.key == "aoeOff" or entry.key == "mythicTrash" then
        return "off"
    end
end

local function UpdateButtonLayout(button)
    local height = GetRowHeight()
    local appearance = GetSaved().appearance
    local iconSize = math.max(12, (height - 8) * appearance.iconScale)
    local borderSize = iconSize + 2
    local fontSize = math.max(8, math.floor(height * 0.40 * appearance.fontScale))
    local iconOnly = appearance.menuMode == "icons" and button.hasMenuIcon
    local textOnly = appearance.menuMode == "text"
    local labelX = button.hasMenuIcon and not textOnly and (iconSize + 14) or 6
    local favoriteWidth = 22

    button:SetSize(GetRowWidth() - favoriteWidth, height)
    button.visualState = GetEntryState(button.entry)
    UI.SetButtonStateColor(button, button.visualState)
    UI.SetFont(button.label, fontSize)
    button.label:ClearAllPoints()
    if iconOnly then
        button.label:Hide()
    elseif button.justify == "CENTER" then
        button.label:Show()
        button.label:SetPoint("CENTER", button, "CENTER", 0, 0)
    else
        button.label:Show()
        button.label:SetPoint("LEFT", button, "LEFT", labelX, 0)
        button.label:SetPoint("RIGHT", button, "RIGHT", -6, 0)
    end
    if button.icon then
        button.icon:SetSize(iconSize, iconSize)
        button.icon:ClearAllPoints()
        if textOnly then
            button.icon:Hide()
        else
            button.icon:Show()
            if iconOnly then
                button.icon:SetPoint("CENTER", button, "CENTER", 0, 0)
            else
                button.icon:SetPoint("LEFT", button, "LEFT", 6, 0)
            end
        end
    end
    if button.iconBorder then
        button.iconBorder:SetSize(borderSize, borderSize)
        button.iconBorder:ClearAllPoints()
        if textOnly then
            button.iconBorder:Hide()
        else
            button.iconBorder:Show()
            button.iconBorder:SetPoint("CENTER", button.icon, "CENTER", 0, 0)
        end
    end
end

local function PlaceEntry(entry, y)
    local button = EnsureEntryButton(entry)
    button:ClearAllPoints()
    button.entry = entry
    UpdateButtonLayout(button)
    button:SetPoint("TOPLEFT", panel, "TOPLEFT", rowX, y)
    button:Show()
    button.favorite:ClearAllPoints()
    button.favorite:SetSize(math.min(20, GetRowHeight()), GetRowHeight())
    button.favorite:SetPoint("TOPRIGHT", panel, "TOPLEFT", rowX + GetRowWidth(), y)
    button.favorite:SetText(IsFavorite(entry) and "*" or "+")
    button.favorite:Show()
    return y - GetRowStep()
end

local function HideAllDynamicMenu()
    for _, button in pairs(menuButtons) do
        button:Hide()
        if button.favorite then
            button.favorite:Hide()
        end
    end
    for _, label in pairs(sectionLabels) do
        label:Hide()
    end
end

local function PlaceSectionLabel(key, y)
    local label = EnsureSectionLabel(key)
    if not GetSaved().appearance.showSectionHeaders then
        return y
    end
    label:ClearAllPoints()
    label:SetPoint("TOPLEFT", panel, "TOPLEFT", rowX + 2, y)
    label:SetSize(GetRowWidth() - 4, GetSectionLabelHeight())
    UI.SetFont(label.text, math.max(8, math.floor(GetRowHeight() * 0.34)))
    UI.SetFont(label.toggle, math.max(8, math.floor(GetRowHeight() * 0.34)), "OUTLINE")
    label.toggle:SetText(GetSaved().sectionCollapsed[key] and "+" or "-")
    label:Show()
    return y - GetSectionLabelHeight()
end

local function HasVisibleFavorite()
    for _, entry in ipairs(Services.GetEntries()) do
        if IsFavorite(entry) and not IsHidden(entry) then
            return true
        end
    end
end

local function HasVisibleSection(section)
    if GetSaved().sectionVisibility[section] == false then
        return
    end
    for _, entry in ipairs(Services.GetEntries()) do
        if entry.section == section and not IsFavorite(entry) and not IsHidden(entry) then
            return true
        end
    end
end

function Panel.BuildMenu()
    local saved = GetSaved()
    ApplyAppearance()
    panel:SetWidth(saved.width)
    dragFrame:SetWidth(panel:GetWidth() - 14)
    HideAllDynamicMenu()
    if mainCollapseButton then
        mainCollapseButton:SetText(saved.collapsed and "+" or "-")
    end
    if mainLockButton then
        mainLockButton:SetText(saved.locked and "L" or "U")
    end
    if saved.collapsed then
        if mainResizeGrip then
            mainResizeGrip:Hide()
        end
        panel:SetHeight(38)
        return
    elseif mainResizeGrip then
        mainResizeGrip:Show()
    end

    local y = rowY
    if HasVisibleFavorite() then
        y = PlaceSectionLabel("favorites", y)
        if not saved.sectionCollapsed.favorites then
            for _, entry in ipairs(Services.GetEntries()) do
                if IsFavorite(entry) and not IsHidden(entry) then
                    y = PlaceEntry(entry, y)
                end
            end
        end
        y = y - 3
    end
    for _, section in ipairs(sectionOrder) do
        if HasVisibleSection(section) then
            y = PlaceSectionLabel(section, y)
            if not saved.sectionCollapsed[section] then
                for _, entry in ipairs(Services.GetEntries()) do
                    if entry.section == section and not IsFavorite(entry) and not IsHidden(entry) then
                        y = PlaceEntry(entry, y)
                    end
                end
            end
            y = y - 3
        end
    end
    panel:SetHeight(math.abs(y) + 18)
end

function Panel.ApplyProfileLayout()
    local saved = GetSaved()
    UI.RestoreTopLeft(panel, saved, function()
        panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end)
    Currency.RestorePosition()
    Panel.BuildMenu()
    Panel.SetVisible(saved.panelVisible)
    Currency.Update()
    Config.Refresh()
end

function Panel.SetVisible(visible)
    GetSaved().panelVisible = visible == true
    if visible then
        panel:Show()
    else
        panel:Hide()
    end
end

function Panel.ResetPosition()
    local saved = GetSaved()
    saved.left = nil
    saved.top = nil
    UI.RestoreTopLeft(panel, saved, function()
        panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end)
end

function Panel.ResetSize()
    local saved = GetSaved()
    saved.width = MafMenu.PANEL_WIDTH
    saved.rowHeight = MafMenu.DEFAULT_ROW_HEIGHT
    Panel.BuildMenu()
end

local function CreateHeader()
    dragFrame = CreateFrame("Button", nil, panel)
    dragFrame:SetSize(MafMenu.PANEL_WIDTH - 14, 24)
    dragFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 7, -7)
    UI.SkinHeader(dragFrame)
    dragFrame:SetFrameLevel(panel:GetFrameLevel() + 1)
    dragFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and not GetSaved().locked then
            self:GetParent():StartMoving()
        end
    end)
    dragFrame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and not GetSaved().locked then
            self:GetParent():StopMovingOrSizing()
            SavePanelPosition()
        end
    end)

    local title = dragFrame:CreateFontString(nil, "OVERLAY")
    UI.SetFont(title, 13, "OUTLINE")
    title:SetTextColor(unpack(UI.COLORS.gold))
    title:SetPoint("LEFT", dragFrame, "LEFT", 9, 0)
    title:SetText("Book of Maf")

    local configButton = CreateFrame("Button", nil, dragFrame)
    configButton:SetSize(22, 18)
    configButton:SetPoint("RIGHT", dragFrame, "RIGHT", -8, 0)
    configButton:SetText("*")
    UI.SkinButton(configButton)
    configButton:SetScript("OnClick", function()
        Config.Show()
    end)
    UI.SetTooltip(configButton, "Open MafMenu config")

    mainCollapseButton = UI.CreateTitleButton(dragFrame, "-", 20)
    mainCollapseButton:SetPoint("RIGHT", configButton, "LEFT", -4, 0)
    mainCollapseButton:SetScript("OnClick", function()
        local saved = GetSaved()
        saved.collapsed = not saved.collapsed
        Panel.BuildMenu()
    end)

    mainLockButton = UI.CreateTitleButton(dragFrame, GetSaved().locked and "L" or "U", 20)
    mainLockButton:SetPoint("RIGHT", mainCollapseButton, "LEFT", -4, 0)
    mainLockButton:SetScript("OnClick", function()
        local saved = GetSaved()
        saved.locked = not saved.locked
        mainLockButton:SetText(saved.locked and "L" or "U")
        Config.Refresh()
    end)
    mainLockButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(GetSaved().locked and "Unlock dragging" or "Lock dragging")
        GameTooltip:Show()
    end)
    mainLockButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function CreateResizeGrip()
    mainResizeGrip = CreateFrame("Button", nil, panel)
    mainResizeGrip:SetSize(18, 18)
    mainResizeGrip:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -4, 4)
    mainResizeGrip:SetFrameLevel(panel:GetFrameLevel() + 5)
    mainResizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    mainResizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    mainResizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

    local startX, startY, startWidth, startRowHeight
    mainResizeGrip:SetScript("OnUpdate", function(self)
        if not startX then
            return
        end
        local cursorX, cursorY = GetCursorPosition()
        local uiScale = UIParent:GetEffectiveScale()
        local saved = GetSaved()
        saved.width = UI.ClampPanelWidth(startWidth + ((cursorX - startX) / uiScale))
        saved.rowHeight = UI.ClampRowHeight(startRowHeight + ((startY - cursorY) / uiScale / 12))
        panel:SetWidth(saved.width)
        Panel.BuildMenu()
    end)
    mainResizeGrip:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            startX, startY = GetCursorPosition()
            startWidth = panel:GetWidth()
            startRowHeight = GetRowHeight()
            self:SetScript("OnUpdate", self:GetScript("OnUpdate"))
        end
    end)
    mainResizeGrip:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            local saved = GetSaved()
            saved.width = UI.ClampPanelWidth(panel:GetWidth())
            saved.rowHeight = UI.ClampRowHeight(saved.rowHeight)
            startX, startY, startWidth, startRowHeight = nil, nil, nil, nil
            Panel.BuildMenu()
        end
    end)
end

function Panel.Initialize()
    activeSavedVars = Profile.GetActive()
    panel = CreateFrame("Frame", "panel3_mini", UIParent)
    panel:RegisterEvent("PLAYER_ENTERING_WORLD")
    panel:RegisterEvent("PLAYER_LEAVING_WORLD")
    panel:RegisterEvent("PLAYER_LOGIN")
    panel:RegisterEvent("PLAYER_LOGOUT")
    panel:RegisterEvent("GOSSIP_SHOW")
    panel:RegisterEvent("GOSSIP_CLOSED")
    panel:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    panel:RegisterEvent("CHAT_MSG_CURRENCY")
    panel:SetSize(activeSavedVars.width, MafMenu.PANEL_HEIGHT)
    UI.RestoreTopLeft(panel, activeSavedVars, function()
        panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end)
    panel:SetMovable(true)
    panel:SetResizable(true)
    panel:SetMinResize(MafMenu.PANEL_MIN_WIDTH, 1)
    panel:SetMaxResize(MafMenu.PANEL_MAX_WIDTH, 10000)
    panel:EnableMouse(true)
    panel:SetClampedToScreen(true)
    UI.SkinPanel(panel)
    panel:Show()
    if not activeSavedVars.panelVisible then
        panel:Hide()
    end

    panel:SetScript("OnEvent", function(_, event)
        if event == "GOSSIP_CLOSED" then
            Services.ClearPendingBookOption()
            return
        end
        if event == "GOSSIP_SHOW" and Services.HandleGossipShow() then
            return
        end
        if event == "PLAYER_ENTERING_WORLD" then
            Panel.BuildMenu()
            Currency.Update()
        elseif event == "CURRENCY_DISPLAY_UPDATE" or event == "CHAT_MSG_CURRENCY" then
            Currency.Update()
        end
    end)

    CreateHeader()
    CreateResizeGrip()
    Currency.Initialize({ panel = panel, GetSaved = GetSaved })
    Config.Initialize({ GetSaved = GetSaved, BuildMenu = Panel.BuildMenu, ApplyProfileLayout = Panel.ApplyProfileLayout })
    MafMenu.Minimap.Initialize(panel)
    Panel.BuildMenu()
    Currency.Update()
end
