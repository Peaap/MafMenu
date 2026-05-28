local ADDON_PATH = "Interface\\AddOns\\MafMenu\\"
local MAF_FONT = ADDON_PATH .. "Fonts\\Expressway.ttf"
local MAF_FONT_FALLBACK = "Fonts\\FRIZQT__.TTF"
local PANEL_WIDTH = 232
local PANEL_HEIGHT = 508
local PANEL_MIN_WIDTH = 190
local PANEL_MAX_WIDTH = 10000
local DEFAULT_ROW_HEIGHT = 30
local MIN_ROW_HEIGHT = 18
local GAP = 5
local debugEnabled = false
local lastBookClickTime
MafMenu_SavedVars = MafMenu_SavedVars or {}
MafMenu_SavedVars.hidden = MafMenu_SavedVars.hidden or {}
MafMenu_SavedVars.favorites = MafMenu_SavedVars.favorites or {}
MafMenu_SavedVars.width = math.max(PANEL_MIN_WIDTH, math.min(PANEL_MAX_WIDTH, MafMenu_SavedVars.width or PANEL_WIDTH))
MafMenu_SavedVars.rowHeight = math.max(MIN_ROW_HEIGHT, MafMenu_SavedVars.rowHeight or DEFAULT_ROW_HEIGHT)
if MafMenu_SavedVars.showCurrencies == nil then
    MafMenu_SavedVars.showCurrencies = true
end

local commandProbe = {
    active = false,
    elapsed = 0,
    index = 1,
    commands = {},
}

local function DebugPrint(message)
    if debugEnabled then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00aaffMafMenu|r " .. message)
    end
end

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00aaffMafMenu|r " .. message)
end

local COLORS = {
    panel = {0.015, 0.020, 0.022, 0.92},
    panelBorder = {0.34, 0.42, 0.43, 0.95},
    header = {0.055, 0.070, 0.075, 0.98},
    headerBorder = {0.48, 0.58, 0.58, 0.95},
    button = {0.035, 0.045, 0.047, 0.94},
    buttonHover = {0.095, 0.120, 0.125, 0.98},
    buttonDown = {0.018, 0.023, 0.025, 1},
    buttonBorder = {0.18, 0.24, 0.25, 0.95},
    buttonBorderHover = {0.74, 0.82, 0.78, 1},
    text = {0.92, 0.90, 0.82, 1},
    subtext = {0.52, 0.60, 0.58, 1},
    gold = {1.00, 0.78, 0.18, 1},
    green = {0.42, 1.00, 0.50, 1},
    mutedRed = {1.00, 0.45, 0.42, 1},
}

local function ApplyBackdrop(frame, bg, border, edgeSize, tooltipBorder)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = tooltipBorder and "Interface\\Tooltips\\UI-Tooltip-Border" or "Interface\\Buttons\\WHITE8x8",
        tile = false,
        tileSize = 0,
        edgeSize = edgeSize or 1,
        insets = { left = tooltipBorder and 3 or 0, right = tooltipBorder and 3 or 0, top = tooltipBorder and 3 or 0, bottom = tooltipBorder and 3 or 0 },
    })
    frame:SetBackdropColor(unpack(bg))
    frame:SetBackdropBorderColor(unpack(border))
end

local function SetMafFont(fontString, size, flags)
    if not fontString:SetFont(MAF_FONT, size, flags) then
        fontString:SetFont(MAF_FONT_FALLBACK, size, flags)
    end
end

local function SetTooltip(button, text)
    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(unpack(COLORS.buttonHover))
        self:SetBackdropBorderColor(unpack(COLORS.buttonBorderHover))
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(text)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(COLORS.button))
        self:SetBackdropBorderColor(unpack(COLORS.buttonBorder))
        GameTooltip:Hide()
    end)
    button:SetScript("OnMouseDown", function(self)
        self:SetBackdropColor(unpack(COLORS.buttonDown))
    end)
    button:SetScript("OnMouseUp", function(self)
        self:SetBackdropColor(unpack(COLORS.buttonHover))
    end)
end

local pendingGossipOption
local gossipWaitTime = 0
local GOSSIP_SELECT_DELAY = 0.22
local GOSSIP_SELECT_TIMEOUT = 2.5
local gossipChecker = CreateFrame("Frame")
gossipChecker:Hide()
local BuildMenu
local UpdateCurrencyFrame

local soundMute = {
    active = false,
    elapsed = 0,
    duration = 1.15,
    saved = {},
    cvars = {"Sound_EnableSFX", "Sound_EnableErrorSpeech"},
    errorEventsMuted = false,
}

local soundRestoreFrame = CreateFrame("Frame")
soundRestoreFrame:Hide()
soundRestoreFrame:SetScript("OnUpdate", function(self, elapsed)
    soundMute.elapsed = soundMute.elapsed + elapsed
    if soundMute.elapsed < soundMute.duration then
        return
    end

    for cvar, value in pairs(soundMute.saved) do
        SetCVar(cvar, value)
    end
    if soundMute.errorEventsMuted and UIErrorsFrame then
        UIErrorsFrame:RegisterEvent("UI_ERROR_MESSAGE")
        UIErrorsFrame:RegisterEvent("UI_INFO_MESSAGE")
        UIErrorsFrame:Show()
    end
    soundMute.saved = {}
    soundMute.active = false
    soundMute.elapsed = 0
    soundMute.errorEventsMuted = false
    self:Hide()
end)

local function MuteMenuSounds()
    if not soundMute.active then
        soundMute.saved = {}
        for _, cvar in ipairs(soundMute.cvars) do
            local value = GetCVar(cvar)
            if value ~= nil then
                soundMute.saved[cvar] = value
                SetCVar(cvar, "0")
            end
        end
        soundMute.active = true
    else
        for _, cvar in ipairs(soundMute.cvars) do
            if soundMute.saved[cvar] ~= nil then
                SetCVar(cvar, "0")
            end
        end
    end

    if UIErrorsFrame then
        UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE")
        UIErrorsFrame:UnregisterEvent("UI_INFO_MESSAGE")
        UIErrorsFrame:Clear()
        soundMute.errorEventsMuted = true
    end

    soundMute.elapsed = 0
    soundRestoreFrame:Show()
end

local commandProbeFrame = CreateFrame("Frame")
commandProbeFrame:Hide()
commandProbeFrame:SetScript("OnUpdate", function(self, elapsed)
    commandProbe.elapsed = commandProbe.elapsed + elapsed
    if commandProbe.elapsed < 0.8 then
        return
    end

    commandProbe.elapsed = 0
    local command = commandProbe.commands[commandProbe.index]
    if not command then
        commandProbe.active = false
        self:Hide()
        Print("command probe done")
        return
    end

    Print("probing .help " .. command)
    SendChatMessage(".help " .. command)
    commandProbe.index = commandProbe.index + 1
end)

local function StartCommandProbe(commands)
    commandProbe.commands = commands
    commandProbe.index = 1
    commandProbe.elapsed = 0.8
    commandProbe.active = true
    commandProbeFrame:Show()
end

local function SelectPendingBookOption()
    if pendingGossipOption and gossipWaitTime >= GOSSIP_SELECT_DELAY and GossipFrame and GossipFrame:IsVisible() then
        DebugPrint("Selecting gossip option " .. pendingGossipOption)
        SelectGossipOption(pendingGossipOption)
        pendingGossipOption = nil
        gossipWaitTime = 0
        gossipChecker:Hide()

        if GossipFrame and GossipFrame:IsVisible() then
            GossipFrame:Hide()
        end
        return true
    end
end

gossipChecker:SetScript("OnUpdate", function(self, elapsed)
    gossipWaitTime = gossipWaitTime + elapsed

    if SelectPendingBookOption() then
        return
    elseif gossipWaitTime > GOSSIP_SELECT_TIMEOUT then
        pendingGossipOption = nil
        gossipWaitTime = 0
        self:Hide()
    end
end)

local function SelectBookOptionWhenReady(gossipOption)
    if GossipFrame and GossipFrame:IsVisible() then
        pendingGossipOption = gossipOption
        gossipWaitTime = 0
        lastBookClickTime = GetTime()
        DebugPrint("Book already open; delaying gossip option " .. gossipOption)
        gossipChecker:Show()
        return
    end

    pendingGossipOption = gossipOption
    gossipWaitTime = 0
    lastBookClickTime = GetTime()
    DebugPrint("Waiting for Book gossip option " .. gossipOption)
    gossipChecker:Show()
end

local function AddGossipSelect(button, gossipOption)
    button:HookScript("PostClick", function()
        SelectBookOptionWhenReady(gossipOption)
    end)
end

local function CreateMenuButton(name, parent, label, width, height, x, y, textColor, tooltip, macroText, gossipOption, fontSize, iconPath, justify)
    local button = CreateFrame("Button", name, parent, "SecureActionButtonTemplate")
    button:SetSize(width, height)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetAttribute("type1", "macro")
    button:SetAttribute("macrotext1", macroText)
    button:HookScript("PreClick", MuteMenuSounds)
    ApplyBackdrop(button, COLORS.button, COLORS.buttonBorder, 1)
    button.baseFontSize = fontSize or 12
    button.hasMenuIcon = iconPath ~= nil
    button.justify = justify

    local labelX = iconPath and 38 or 0
    if iconPath then
        button.icon = button:CreateTexture(nil, "ARTWORK")
        button.icon:SetSize(22, 22)
        button.icon:SetPoint("LEFT", button, "LEFT", 6, 0)
        button.icon:SetTexture(iconPath)

        button.iconBorder = button:CreateTexture(nil, "OVERLAY")
        button.iconBorder:SetSize(24, 24)
        button.iconBorder:SetPoint("CENTER", button.icon, "CENTER", 0, 0)
        button.iconBorder:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    end

    button.labelX = labelX
    button.label = button:CreateFontString(nil, "OVERLAY")
    SetMafFont(button.label, fontSize or 12)
    if justify == "CENTER" then
        button.label:SetPoint("CENTER", button, "CENTER", 0, 0)
    else
        button.label:SetPoint("LEFT", button, "LEFT", labelX, 0)
    end
    button.label:SetJustifyH(justify or "LEFT")
    button.label:SetJustifyV("MIDDLE")
    button.label:SetTextColor(unpack(textColor or COLORS.text))
    button.label:SetText(label)

    SetTooltip(button, tooltip)

    if gossipOption then
        AddGossipSelect(button, gossipOption)
    end

    return button
end

local panel = CreateFrame("Frame", "panel3_mini", UIParent)
panel:RegisterEvent("PLAYER_ENTERING_WORLD")
panel:RegisterEvent("PLAYER_LEAVING_WORLD")
panel:RegisterEvent("PLAYER_LOGIN")
panel:RegisterEvent("PLAYER_LOGOUT")
panel:RegisterEvent("GOSSIP_SHOW")
panel:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
panel:RegisterEvent("CHAT_MSG_CURRENCY")
panel:SetSize(MafMenu_SavedVars.width, PANEL_HEIGHT)
if MafMenu_SavedVars.left and MafMenu_SavedVars.top then
    panel:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", MafMenu_SavedVars.left, MafMenu_SavedVars.top)
else
    panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
end
panel:SetMovable(true)
panel:SetResizable(true)
panel:SetMinResize(PANEL_MIN_WIDTH, 1)
panel:SetMaxResize(PANEL_MAX_WIDTH, 10000)
panel:EnableMouse(true)
panel:SetClampedToScreen(true)
ApplyBackdrop(panel, COLORS.panel, COLORS.panelBorder, 12, true)
panel:Show()
panel:SetScript("OnEvent", function(_, event)
    if event == "GOSSIP_SHOW" and pendingGossipOption then
        local delay = lastBookClickTime and (GetTime() - lastBookClickTime) or 0
        DebugPrint(string.format("GOSSIP_SHOW after %.3fs; selecting after %.2fs", delay, GOSSIP_SELECT_DELAY))
        gossipChecker:Show()
        return
    end

    if event == "GOSSIP_SHOW" and debugEnabled then
        if GetGossipOptions then
            local options = {GetGossipOptions()}
            for i = 1, table.getn(options), 2 do
                local optionIndex = ((i + 1) / 2)
                DebugPrint(optionIndex .. ": " .. tostring(options[i]) .. " [" .. tostring(options[i + 1]) .. "]")
            end
        end
    end

    if event == "PLAYER_ENTERING_WORLD" then
        if BuildMenu then
            BuildMenu()
        end
        if UpdateCurrencyFrame then
            UpdateCurrencyFrame()
        end
    elseif (event == "CURRENCY_DISPLAY_UPDATE" or event == "CHAT_MSG_CURRENCY") and UpdateCurrencyFrame then
        UpdateCurrencyFrame()
    end
end)

local function SavePanelPosition()
    MafMenu_SavedVars = MafMenu_SavedVars or {}
    MafMenu_SavedVars.left = panel:GetLeft()
    MafMenu_SavedVars.top = panel:GetTop()
end

SLASH_MAFMENUDEBUG1 = "/mafdebug"
SlashCmdList["MAFMENUDEBUG"] = function()
    debugEnabled = not debugEnabled
    DebugPrint(debugEnabled and "debug enabled" or "debug disabled")
    if not debugEnabled then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00aaffMafMenu|r debug disabled")
    end
end

SLASH_MAFMENUPROBE1 = "/mafprobe"
SlashCmdList["MAFMENUPROBE"] = function(msg)
    local commands = {}
    for command in string.gmatch(msg or "", "%S+") do
        table.insert(commands, command)
    end

    if table.getn(commands) == 0 then
        commands = {
            "vendor",
            "bank",
            "auction",
            "ah",
            "trainer",
            "teleport",
            "teleporter",
            "reagent",
            "collector",
            "legacy",
            "gear",
            "gear vendor",
            "transmog",
            "lootbot",
            "playerbots",
            "playerbots bank",
            "playerbots vendor",
            "playerbots trainer",
            "account",
            "server",
        }
    end

    Print("probing " .. table.getn(commands) .. " command candidates")
    StartCommandProbe(commands)
end

local minimapIcon = CreateFrame("Button", "panel_minimapIcon", Minimap)
minimapIcon:EnableMouseWheel(true)
minimapIcon:SetMovable(true)
minimapIcon:SetSize(22, 20)
minimapIcon:SetPoint("TOPLEFT", 0, 0)
minimapIcon:SetFrameStrata("HIGH")
minimapIcon:SetFrameLevel(1)

local myIconPos = 0

local function UpdateMapBtn()
    local Xpoa, Ypoa = GetCursorPosition()
    local Xmin, Ymin = Minimap:GetLeft(), Minimap:GetBottom()
    Xpoa = Xmin - Xpoa / Minimap:GetEffectiveScale() + 70
    Ypoa = Ypoa / Minimap:GetEffectiveScale() - Ymin - 70
    myIconPos = math.deg(math.atan2(Ypoa, Xpoa))
    minimapIcon:ClearAllPoints()
    minimapIcon:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 52 - (80 * cos(myIconPos)), (80 * sin(myIconPos)) - 52)
end

minimapIcon:RegisterForDrag("RightButton")
minimapIcon:SetScript("OnDragStart", function()
    minimapIcon:StartMoving()
    minimapIcon:SetScript("OnUpdate", UpdateMapBtn)
end)
minimapIcon:SetScript("OnDragStop", function()
    minimapIcon:StopMovingOrSizing()
    minimapIcon:SetScript("OnUpdate", nil)
    UpdateMapBtn()
end)
minimapIcon:ClearAllPoints()
minimapIcon:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 52 - (80 * cos(myIconPos)), (80 * sin(myIconPos)) - 52)
minimapIcon:SetScript("OnClick", function()
    if panel:IsShown() then
        panel:Hide()
    else
        panel:Show()
    end
end)

local minimapIcon_icon = minimapIcon:CreateTexture("minimapIcon_icon")
minimapIcon_icon:SetAllPoints(true)
minimapIcon_icon:SetTexture(ADDON_PATH .. "Icons\\EC128")

local dragframe2 = CreateFrame("Button", nil, panel)
dragframe2:SetSize(PANEL_WIDTH - 14, 24)
dragframe2:SetPoint("TOPLEFT", panel, "TOPLEFT", 7, -7)
ApplyBackdrop(dragframe2, COLORS.header, COLORS.headerBorder, 1)
dragframe2:SetFrameLevel(panel:GetFrameLevel() + 1)
dragframe2:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        self:GetParent():StartMoving()
    end
end)
dragframe2:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" then
        self:GetParent():StopMovingOrSizing()
        SavePanelPosition()
    end
end)

local title = dragframe2:CreateFontString(nil, "OVERLAY")
SetMafFont(title, 13, "OUTLINE")
title:SetTextColor(unpack(COLORS.gold))
title:SetPoint("LEFT", dragframe2, "LEFT", 9, 0)
title:SetText("Book of Maf")

local subtitle = panel:CreateFontString(nil, "OVERLAY")
SetMafFont(subtitle, 10)
subtitle:SetTextColor(unpack(COLORS.subtext))
subtitle:SetPoint("RIGHT", dragframe2, "RIGHT", -9, 0)
subtitle:SetText("shortcuts")

local bookMacro = "/use Book of Maf\n/stopcasting"
local function CreateBookServiceMacro(npcName)
    return bookMacro
end

local rowX = 10
local rowY = -38
local textColor = COLORS.text

local function ClampPanelWidth(width)
    return math.max(PANEL_MIN_WIDTH, math.min(PANEL_MAX_WIDTH, width or PANEL_WIDTH))
end

local function ClampRowHeight(height)
    return math.max(MIN_ROW_HEIGHT, height or DEFAULT_ROW_HEIGHT)
end

local function GetRowWidth()
    return math.max(120, panel:GetWidth() - (rowX * 2))
end

local function GetRowHeight()
    return MafMenu_SavedVars and ClampRowHeight(MafMenu_SavedVars.rowHeight) or DEFAULT_ROW_HEIGHT
end

local function GetRowStep()
    return GetRowHeight() + GAP
end

local function GetSectionLabelHeight()
    return math.max(12, math.floor(GetRowHeight() * 0.5))
end

local menuEntries = {
    { key = "vendor", buttonName = "buttonSummonVendor", label = "Vendor", tooltip = "Vendor", section = "book", gossip = 1, icon = "Interface\\Icons\\INV_Misc_Coin_01", macro = CreateBookServiceMacro("Ungar") },
    { key = "resetCombat", buttonName = "buttonResetCombat", label = "Reset Combat", tooltip = "Reset Combat", section = "book", gossip = 2, icon = "Interface\\Icons\\Ability_Warrior_BattleShout" },
    { key = "bank", buttonName = "buttonBank", label = "Bank", tooltip = "Bank", section = "book", gossip = 3, icon = "Interface\\Icons\\INV_Box_02" },
    { key = "auctionHouse", buttonName = "buttonAuctionHouse", label = "Auction House", tooltip = "Auction House", section = "book", gossip = 4, icon = "Interface\\Icons\\INV_Misc_Note_01" },
    { key = "resetInstances", buttonName = "buttonResetInstance", label = "Reset Instances", tooltip = "Reset Instances", section = "book", gossip = 5, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { key = "teleporter", buttonName = "buttonTeleport", label = "Teleporter", tooltip = "Teleporter", section = "book", gossip = 6, icon = "Interface\\Icons\\Spell_Arcane_TeleportStormWind", macro = CreateBookServiceMacro("Portal Master") },
    { key = "reagentBank", buttonName = "buttonReagentBank", label = "Reagent Bank", tooltip = "Reagent Bank", section = "book", gossip = 7, icon = "Interface\\Icons\\INV_Misc_Bag_10" },
    { key = "buffMe", buttonName = "buttonSummonBuff", label = "Buff Me", tooltip = "Buff Me", section = "book", gossip = 8, icon = "Interface\\Icons\\Spell_Nature_Regeneration" },
    { key = "trainer", buttonName = "buttonTrainer", label = "Trainer", tooltip = "Trainer", section = "book", gossip = 9, icon = "Interface\\Icons\\INV_Sword_27" },
    { key = "itemCollector", buttonName = "buttonItemCollector", label = "Item Collector", tooltip = "Item Collector", section = "book", gossip = 10, icon = "Interface\\Icons\\INV_Misc_Book_09" },
    { key = "legacyVendor", buttonName = "buttonLegacyVendor", label = "Legacy Vendor", tooltip = "Legacy Vendor", section = "book", gossip = 11, macro = CreateBookServiceMacro("Legara") },
    { key = "gearStats", buttonName = "buttonLegacyStats", label = "Gear Stats", tooltip = "Gear Stats", section = "tools", macro = ".gear stats" },
    { key = "aoeOn", buttonName = "buttonAoELootOn", label = "AoE On", tooltip = "AoELoot On", section = "toggles", macro = ".aoeloot on", color = COLORS.green },
    { key = "aoeOff", buttonName = "buttonAoELootOff", label = "AoE Off", tooltip = "AoELoot Off", section = "toggles", macro = ".aoeloot off", color = COLORS.mutedRed },
    { key = "mythicOn", buttonName = "buttonMythicEnable", label = "Mythic On", tooltip = "Mythic Enable", section = "toggles", macro = ".mythic enable", color = {0.62, 1, 0.62, 1} },
    { key = "mythicTrash", buttonName = "buttonMythicTrash", label = "Mythic Trash", tooltip = "Mythic Trash", section = "toggles", macro = ".mythic trash", color = {1, 0.55, 0.55, 1} },
}

local menuButtons = {}
local currencyRows = {}
local currencyFrame
local currencyHeader
local currencyCollapseButton
local currencyResizeGrip
local sectionLabels = {}
local configFrame
local configRows = {}
local currencyConfigRows = {}
local currencyToggle
local mainCollapseButton
local mainResizeGrip
local RefreshConfigRows

local sectionTitles = {
    favorites = "Favorites",
    book = "Book services",
    tools = "Tools",
    toggles = "Server toggles",
}

local sectionOrder = {"book", "tools", "toggles"}

local function EnsureSavedVars()
    MafMenu_SavedVars = MafMenu_SavedVars or {}
    MafMenu_SavedVars.hidden = MafMenu_SavedVars.hidden or {}
    MafMenu_SavedVars.favorites = MafMenu_SavedVars.favorites or {}
    MafMenu_SavedVars.hiddenCurrencies = MafMenu_SavedVars.hiddenCurrencies or {}
    MafMenu_SavedVars.width = ClampPanelWidth(MafMenu_SavedVars.width or PANEL_WIDTH)
    MafMenu_SavedVars.rowHeight = ClampRowHeight(MafMenu_SavedVars.rowHeight or DEFAULT_ROW_HEIGHT)
    MafMenu_SavedVars.collapsed = MafMenu_SavedVars.collapsed == true
    if MafMenu_SavedVars.showCurrencies == nil then
        MafMenu_SavedVars.showCurrencies = true
    end
    MafMenu_SavedVars.currency = MafMenu_SavedVars.currency or {}
    MafMenu_SavedVars.currency.width = math.max(170, MafMenu_SavedVars.currency.width or 230)
    MafMenu_SavedVars.currency.rowHeight = math.max(16, MafMenu_SavedVars.currency.rowHeight or 21)
    MafMenu_SavedVars.currency.collapsed = MafMenu_SavedVars.currency.collapsed == true
end

local function IsHidden(entry)
    return MafMenu_SavedVars.hidden[entry.key] == true
end

local function IsFavorite(entry)
    return MafMenu_SavedVars.favorites[entry.key] == true
end

local function EnsureSectionLabel(key)
    if not sectionLabels[key] then
        local label = panel:CreateFontString(nil, "OVERLAY")
        SetMafFont(label, 10)
        label:SetTextColor(unpack(COLORS.subtext))
        label:SetText(sectionTitles[key])
        sectionLabels[key] = label
    end
    return sectionLabels[key]
end

local function EnsureEntryButton(entry)
    if not menuButtons[entry.key] then
        menuButtons[entry.key] = CreateMenuButton(entry.buttonName, panel, entry.label, GetRowWidth(), GetRowHeight(), rowX, rowY, entry.color or textColor, entry.tooltip, entry.macro or bookMacro, entry.gossip, 12, entry.icon, entry.icon and nil or "CENTER")
    end
    return menuButtons[entry.key]
end

local function UpdateButtonLayout(button)
    local height = GetRowHeight()
    local iconSize = math.max(12, height - 8)
    local borderSize = iconSize + 2
    local fontSize = math.max(8, math.floor(height * 0.40))
    local labelX = button.hasMenuIcon and (iconSize + 14) or 0

    button:SetSize(GetRowWidth(), height)
    SetMafFont(button.label, fontSize)
    button.label:ClearAllPoints()

    if button.justify == "CENTER" then
        button.label:SetPoint("CENTER", button, "CENTER", 0, 0)
    else
        button.label:SetPoint("LEFT", button, "LEFT", labelX, 0)
    end

    if button.icon then
        button.icon:SetSize(iconSize, iconSize)
        button.icon:ClearAllPoints()
        button.icon:SetPoint("LEFT", button, "LEFT", 6, 0)
    end

    if button.iconBorder then
        button.iconBorder:SetSize(borderSize, borderSize)
        button.iconBorder:ClearAllPoints()
        button.iconBorder:SetPoint("CENTER", button.icon, "CENTER", 0, 0)
    end
end

local function PlaceEntry(entry, y)
    local button = EnsureEntryButton(entry)
    button:ClearAllPoints()
    UpdateButtonLayout(button)
    button:SetPoint("TOPLEFT", panel, "TOPLEFT", rowX, y)
    button:Show()
    return y - GetRowStep()
end

local function HideAllDynamicMenu()
    for _, button in pairs(menuButtons) do
        button:Hide()
    end
    for _, label in pairs(sectionLabels) do
        label:Hide()
    end
end

local function PlaceSectionLabel(key, y)
    local label = EnsureSectionLabel(key)
    label:ClearAllPoints()
    label:SetPoint("TOPLEFT", panel, "TOPLEFT", rowX + 2, y)
    SetMafFont(label, math.max(8, math.floor(GetRowHeight() * 0.34)))
    label:Show()
    return y - GetSectionLabelHeight()
end

local function HasVisibleFavorite()
    for _, entry in ipairs(menuEntries) do
        if IsFavorite(entry) and not IsHidden(entry) then
            return true
        end
    end
end

local function HasVisibleSection(section)
    for _, entry in ipairs(menuEntries) do
        if entry.section == section and not IsFavorite(entry) and not IsHidden(entry) then
            return true
        end
    end
end

local function GetAllCurrencies()
    local currencies = {}
    if TokenFrame_LoadUI then
        TokenFrame_LoadUI()
    end

    if not GetCurrencyListSize or not GetCurrencyListInfo then
        return currencies
    end

    if ExpandCurrencyList then
        local index = 1
        while index <= GetCurrencyListSize() do
            local _, isHeader, isExpanded = GetCurrencyListInfo(index)
            if isHeader and not isExpanded then
                ExpandCurrencyList(index, 1)
            end
            index = index + 1
        end
    end

    for index = 1, GetCurrencyListSize() do
        local name, isHeader, _, _, isWatched, quantity, _, iconFileID, itemID = GetCurrencyListInfo(index)
        if name and not isHeader then
            table.insert(currencies, {
                name = name,
                quantity = quantity or 0,
                icon = iconFileID,
                itemID = itemID,
                key = tostring(itemID or name),
                watched = isWatched,
            })
        end
    end

    return currencies
end

local function IsCurrencyHidden(currency)
    EnsureSavedVars()
    return MafMenu_SavedVars.hiddenCurrencies[currency.key] == true
end

local function GetCurrencyRowHeight()
    EnsureSavedVars()
    return math.max(16, MafMenu_SavedVars.currency.rowHeight or 21)
end

local function SaveCurrencyFramePosition()
    if not currencyFrame then
        return
    end

    EnsureSavedVars()
    MafMenu_SavedVars.currency.left = currencyFrame:GetLeft()
    MafMenu_SavedVars.currency.top = currencyFrame:GetTop()
end

local function CreateCurrencyFrame()
    if currencyFrame then
        return
    end

    EnsureSavedVars()
    currencyFrame = CreateFrame("Frame", "MafMenuCurrencyFrame", UIParent)
    currencyFrame:SetSize(MafMenu_SavedVars.currency.width, 120)
    currencyFrame:SetMovable(true)
    currencyFrame:EnableMouse(true)
    currencyFrame:SetClampedToScreen(true)
    currencyFrame:SetFrameStrata("MEDIUM")
    ApplyBackdrop(currencyFrame, COLORS.panel, COLORS.panelBorder, 12, true)

    if MafMenu_SavedVars.currency.left and MafMenu_SavedVars.currency.top then
        currencyFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", MafMenu_SavedVars.currency.left, MafMenu_SavedVars.currency.top)
    else
        currencyFrame:SetPoint("LEFT", panel, "RIGHT", 8, 0)
    end

    currencyHeader = CreateFrame("Button", nil, currencyFrame)
    currencyHeader:SetHeight(24)
    currencyHeader:SetPoint("TOPLEFT", currencyFrame, "TOPLEFT", 7, -7)
    currencyHeader:SetPoint("TOPRIGHT", currencyFrame, "TOPRIGHT", -7, -7)
    ApplyBackdrop(currencyHeader, COLORS.header, COLORS.headerBorder, 1)
    currencyHeader:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self:GetParent():StartMoving()
        end
    end)
    currencyHeader:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            self:GetParent():StopMovingOrSizing()
            SaveCurrencyFramePosition()
        end
    end)

    local headerText = currencyHeader:CreateFontString(nil, "OVERLAY")
    SetMafFont(headerText, 13, "OUTLINE")
    headerText:SetTextColor(unpack(COLORS.gold))
    headerText:SetPoint("LEFT", currencyHeader, "LEFT", 9, 0)
    headerText:SetText("Currencies")

    local close = CreateFrame("Button", nil, currencyHeader, "UIPanelCloseButton")
    close:SetPoint("RIGHT", currencyHeader, "RIGHT", 2, 0)
    close:SetScript("OnClick", function()
        EnsureSavedVars()
        MafMenu_SavedVars.showCurrencies = false
        currencyFrame:Hide()
        RefreshConfigRows()
    end)

    currencyCollapseButton = CreateFrame("Button", nil, currencyHeader)
    currencyCollapseButton:SetSize(20, 18)
    currencyCollapseButton:SetPoint("RIGHT", close, "LEFT", -2, 0)
    currencyCollapseButton:SetNormalFontObject(GameFontNormalSmall)
    currencyCollapseButton:SetHighlightFontObject(GameFontHighlightSmall)
    ApplyBackdrop(currencyCollapseButton, COLORS.button, COLORS.buttonBorder, 1)
    currencyCollapseButton:SetScript("OnClick", function()
        EnsureSavedVars()
        MafMenu_SavedVars.currency.collapsed = not MafMenu_SavedVars.currency.collapsed
        UpdateCurrencyFrame()
    end)

    currencyResizeGrip = CreateFrame("Button", nil, currencyFrame)
    currencyResizeGrip:SetSize(18, 18)
    currencyResizeGrip:SetPoint("BOTTOMRIGHT", currencyFrame, "BOTTOMRIGHT", -4, 4)
    currencyResizeGrip:SetFrameLevel(currencyFrame:GetFrameLevel() + 5)
    currencyResizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    currencyResizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    currencyResizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

    local startX
    local startY
    local startWidth
    local startRowHeight
    currencyResizeGrip:SetScript("OnUpdate", function()
        if not startX then
            return
        end

        local cursorX, cursorY = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        local deltaX = (cursorX - startX) / scale
        local deltaDown = (startY - cursorY) / scale

        MafMenu_SavedVars.currency.width = math.max(170, startWidth + deltaX)
        MafMenu_SavedVars.currency.rowHeight = math.max(16, startRowHeight + (deltaDown / 12))
        UpdateCurrencyFrame()
    end)
    currencyResizeGrip:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            EnsureSavedVars()
            startX, startY = GetCursorPosition()
            startWidth = currencyFrame:GetWidth()
            startRowHeight = GetCurrencyRowHeight()
        end
    end)
    currencyResizeGrip:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            startX = nil
            startY = nil
            startWidth = nil
            startRowHeight = nil
            SaveCurrencyFramePosition()
            UpdateCurrencyFrame()
        end
    end)
end

local function EnsureCurrencyRow(index)
    CreateCurrencyFrame()

    if not currencyRows[index] then
        local frame = CreateFrame("Frame", nil, currencyFrame)
        ApplyBackdrop(frame, {0.020, 0.028, 0.030, 0.55}, {0.10, 0.14, 0.15, 0.40}, 1)

        local icon = frame:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("LEFT", frame, "LEFT", 6, 0)

        local name = frame:CreateFontString(nil, "OVERLAY")
        name:SetJustifyH("LEFT")
        name:SetTextColor(unpack(COLORS.text))

        local count = frame:CreateFontString(nil, "OVERLAY")
        count:SetJustifyH("RIGHT")
        count:SetTextColor(unpack(COLORS.gold))

        currencyRows[index] = { frame = frame, icon = icon, name = name, count = count }
    end

    return currencyRows[index]
end

local function PlaceCurrency(currency, index, y, width)
    local row = EnsureCurrencyRow(index)
    local height = GetCurrencyRowHeight()
    local iconSize = math.max(12, height - 4)
    local fontSize = math.max(8, math.floor(height * 0.48))

    row.frame:ClearAllPoints()
    row.frame:SetSize(width, height)
    row.frame:SetPoint("TOPLEFT", currencyFrame, "TOPLEFT", 10, y)
    row.frame:Show()

    row.icon:SetSize(iconSize, iconSize)
    row.icon:SetTexture(currency.icon)

    row.name:ClearAllPoints()
    row.name:SetPoint("LEFT", row.frame, "LEFT", iconSize + 12, 0)
    row.name:SetPoint("RIGHT", row.frame, "RIGHT", -46, 0)
    SetMafFont(row.name, fontSize)
    row.name:SetText(currency.name)

    row.count:ClearAllPoints()
    row.count:SetPoint("RIGHT", row.frame, "RIGHT", -4, 0)
    SetMafFont(row.count, fontSize)
    row.count:SetText(currency.quantity)

    return y - height - 2
end

UpdateCurrencyFrame = function()
    EnsureSavedVars()
    if not MafMenu_SavedVars.showCurrencies then
        if currencyFrame then
            currencyFrame:Hide()
        end
        return
    end

    CreateCurrencyFrame()

    local width = math.max(170, MafMenu_SavedVars.currency.width)
    local rowWidth = math.max(140, width - 20)
    local currencies = GetAllCurrencies()
    local y = -38
    local visibleCount = 0

    currencyFrame:SetWidth(width)
    if currencyCollapseButton then
        currencyCollapseButton:SetText(MafMenu_SavedVars.currency.collapsed and "+" or "-")
    end

    if MafMenu_SavedVars.currency.collapsed then
        for _, row in ipairs(currencyRows) do
            row.frame:Hide()
        end
        if currencyResizeGrip then
            currencyResizeGrip:Hide()
        end
        currencyFrame:SetHeight(38)
        currencyFrame:Show()
        return
    elseif currencyResizeGrip then
        currencyResizeGrip:Show()
    end

    for index, currency in ipairs(currencies) do
        if not IsCurrencyHidden(currency) then
            visibleCount = visibleCount + 1
            y = PlaceCurrency(currency, visibleCount, y, rowWidth)
        end
    end

    for index = visibleCount + 1, table.getn(currencyRows) do
        currencyRows[index].frame:Hide()
    end

    currencyFrame:SetHeight(math.max(74, math.abs(y) + 14))
    currencyFrame:Show()
end

BuildMenu = function()
    EnsureSavedVars()
    panel:SetWidth(MafMenu_SavedVars.width)
    dragframe2:SetWidth(panel:GetWidth() - 14)
    HideAllDynamicMenu()
    if mainCollapseButton then
        mainCollapseButton:SetText(MafMenu_SavedVars.collapsed and "+" or "-")
    end

    if MafMenu_SavedVars.collapsed then
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
        for _, entry in ipairs(menuEntries) do
            if IsFavorite(entry) and not IsHidden(entry) then
                y = PlaceEntry(entry, y)
            end
        end
        y = y - 3
    end

    for _, section in ipairs(sectionOrder) do
        if HasVisibleSection(section) then
            y = PlaceSectionLabel(section, y)
            for _, entry in ipairs(menuEntries) do
                if entry.section == section and not IsFavorite(entry) and not IsHidden(entry) then
                    y = PlaceEntry(entry, y)
                end
            end
            y = y - 3
        end
    end

    panel:SetHeight(math.abs(y) + 18)
end

local function CreateConfigToggle(parent, width)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, 18)
    button:SetNormalFontObject(GameFontNormalSmall)
    button:SetHighlightFontObject(GameFontHighlightSmall)
    ApplyBackdrop(button, COLORS.button, COLORS.buttonBorder, 1)
    return button
end

local function SetConfigToggle(button, enabled, enabledText, disabledText, enabledColor, disabledColor)
    button:SetText(enabled and enabledText or disabledText)
    button:SetBackdropColor(unpack(enabled and enabledColor or disabledColor))
    button:SetBackdropBorderColor(unpack(enabled and COLORS.buttonBorderHover or COLORS.buttonBorder))
end

RefreshConfigRows = function()
    EnsureSavedVars()
    for _, row in ipairs(configRows) do
        SetConfigToggle(row.favorite, IsFavorite(row.entry), "Fav", "Fav", {0.30, 0.22, 0.04, 0.95}, COLORS.button)
        SetConfigToggle(row.hidden, IsHidden(row.entry), "Hidden", "Visible", {0.26, 0.05, 0.04, 0.95}, {0.04, 0.12, 0.07, 0.95})
    end
    for _, row in ipairs(currencyConfigRows) do
        SetConfigToggle(row.show, not MafMenu_SavedVars.hiddenCurrencies[row.currency.key], "Shown", "Hidden", {0.04, 0.12, 0.07, 0.95}, {0.26, 0.05, 0.04, 0.95})
    end
    if currencyToggle then
        SetConfigToggle(currencyToggle, MafMenu_SavedVars.showCurrencies, "Shown", "Hidden", {0.04, 0.12, 0.07, 0.95}, {0.26, 0.05, 0.04, 0.95})
    end
end

local function CreateConfigFrame()
    if configFrame then
        RefreshConfigRows()
        configFrame:Show()
        return
    end

    configFrame = CreateFrame("Frame", "MafMenuConfigFrame", UIParent)
    configFrame:SetSize(420, 560)
    configFrame:SetPoint("CENTER", UIParent, "CENTER", 180, 0)
    configFrame:SetMovable(true)
    configFrame:EnableMouse(true)
    configFrame:SetFrameStrata("DIALOG")
    ApplyBackdrop(configFrame, COLORS.panel, COLORS.panelBorder, 12, true)

    local header = CreateFrame("Button", nil, configFrame)
    header:SetSize(406, 24)
    header:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 7, -7)
    ApplyBackdrop(header, COLORS.header, COLORS.headerBorder, 1)
    header:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self:GetParent():StartMoving()
        end
    end)
    header:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            self:GetParent():StopMovingOrSizing()
        end
    end)

    local headerText = header:CreateFontString(nil, "OVERLAY")
    SetMafFont(headerText, 13, "OUTLINE")
    headerText:SetTextColor(unpack(COLORS.gold))
    headerText:SetPoint("LEFT", header, "LEFT", 9, 0)
    headerText:SetText("MafMenu Config")

    local close = CreateFrame("Button", nil, header, "UIPanelCloseButton")
    close:SetPoint("RIGHT", header, "RIGHT", 2, 0)
    close:SetScript("OnClick", function()
        configFrame:Hide()
    end)

    local servicesTitle = configFrame:CreateFontString(nil, "OVERLAY")
    SetMafFont(servicesTitle, 10)
    servicesTitle:SetTextColor(unpack(COLORS.subtext))
    servicesTitle:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 18, -39)
    servicesTitle:SetText("Services")

    local behaviorTitle = configFrame:CreateFontString(nil, "OVERLAY")
    SetMafFont(behaviorTitle, 10)
    behaviorTitle:SetTextColor(unpack(COLORS.subtext))
    behaviorTitle:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -42, -39)
    behaviorTitle:SetText("State")

    local scroll = CreateFrame("ScrollFrame", "MafMenuConfigScrollFrame", configFrame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 10, -54)
    scroll:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -30, 42)
    scroll:EnableMouseWheel(true)

    local function ScrollConfig(delta)
        local current = scroll:GetVerticalScroll() or 0
        local maxScroll = scroll:GetVerticalScrollRange() or 0
        local nextScroll = current - (delta * 44)
        if nextScroll < 0 then
            nextScroll = 0
        elseif nextScroll > maxScroll then
            nextScroll = maxScroll
        end

        scroll:SetVerticalScroll(nextScroll)
        local scrollBar = _G["MafMenuConfigScrollFrameScrollBar"]
        if scrollBar then
            scrollBar:SetValue(nextScroll)
        end
    end

    scroll:SetScript("OnMouseWheel", function(_, delta)
        ScrollConfig(delta)
    end)

    local function AttachConfigWheel(frame)
        frame:EnableMouseWheel(true)
        frame:SetScript("OnMouseWheel", function(_, delta)
            ScrollConfig(delta)
        end)
    end

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(360, 1)
    AttachConfigWheel(content)
    scroll:SetScrollChild(content)

    local y = -4
    local currencyName = content:CreateFontString(nil, "OVERLAY")
    SetMafFont(currencyName, 11)
    currencyName:SetTextColor(unpack(COLORS.text))
    currencyName:SetPoint("TOPLEFT", content, "TOPLEFT", 8, y - 5)
    currencyName:SetText("Show currency watcher")

    currencyToggle = CreateConfigToggle(content, 58)
    currencyToggle:SetPoint("TOPRIGHT", content, "TOPRIGHT", -8, y - 2)
    AttachConfigWheel(currencyToggle)
    currencyToggle:SetScript("OnClick", function(self)
        MafMenu_SavedVars.showCurrencies = not MafMenu_SavedVars.showCurrencies
        UpdateCurrencyFrame()
        RefreshConfigRows()
    end)

    y = y - 28

    for _, entry in ipairs(menuEntries) do
        local name = content:CreateFontString(nil, "OVERLAY")
        SetMafFont(name, 11)
        name:SetTextColor(unpack(COLORS.text))
        name:SetPoint("TOPLEFT", content, "TOPLEFT", 8, y - 5)
        name:SetText(entry.label)

        local favorite = CreateConfigToggle(content, 42)
        favorite:SetPoint("TOPRIGHT", content, "TOPRIGHT", -76, y - 2)
        AttachConfigWheel(favorite)

        local hidden = CreateConfigToggle(content, 58)
        hidden:SetPoint("TOPRIGHT", content, "TOPRIGHT", -8, y - 2)
        AttachConfigWheel(hidden)

        local row = { entry = entry, favorite = favorite, hidden = hidden }
        table.insert(configRows, row)

        favorite:SetScript("OnClick", function(self)
            if MafMenu_SavedVars.favorites[entry.key] then
                MafMenu_SavedVars.favorites[entry.key] = nil
            else
                MafMenu_SavedVars.favorites[entry.key] = true
            end
            BuildMenu()
            RefreshConfigRows()
        end)
        hidden:SetScript("OnClick", function(self)
            if MafMenu_SavedVars.hidden[entry.key] then
                MafMenu_SavedVars.hidden[entry.key] = nil
            else
                MafMenu_SavedVars.hidden[entry.key] = true
            end
            BuildMenu()
            RefreshConfigRows()
        end)

        y = y - 22
    end

    y = y - 8
    local currencySection = content:CreateFontString(nil, "OVERLAY")
    SetMafFont(currencySection, 10)
    currencySection:SetTextColor(unpack(COLORS.subtext))
    currencySection:SetPoint("TOPLEFT", content, "TOPLEFT", 8, y - 5)
    currencySection:SetText("Currencies")
    y = y - 22

    for _, currency in ipairs(GetAllCurrencies()) do
        local name = content:CreateFontString(nil, "OVERLAY")
        SetMafFont(name, 11)
        name:SetTextColor(unpack(COLORS.text))
        name:SetPoint("TOPLEFT", content, "TOPLEFT", 8, y - 5)
        name:SetPoint("RIGHT", content, "RIGHT", -76, 0)
        name:SetJustifyH("LEFT")
        name:SetText(currency.name)

        local show = CreateConfigToggle(content, 58)
        show:SetPoint("TOPRIGHT", content, "TOPRIGHT", -8, y - 2)
        AttachConfigWheel(show)

        local row = { currency = currency, show = show }
        table.insert(currencyConfigRows, row)

        show:SetScript("OnClick", function(self)
            EnsureSavedVars()
            if MafMenu_SavedVars.hiddenCurrencies[currency.key] then
                MafMenu_SavedVars.hiddenCurrencies[currency.key] = nil
            else
                MafMenu_SavedVars.hiddenCurrencies[currency.key] = true
            end
            UpdateCurrencyFrame()
            RefreshConfigRows()
        end)

        y = y - 22
    end

    content:SetHeight(math.max(1, math.abs(y) + 8))
    scroll:UpdateScrollChildRect()
    local scrollBar = _G["MafMenuConfigScrollFrameScrollBar"]
    if scrollBar then
        scrollBar:SetMinMaxValues(0, scroll:GetVerticalScrollRange() or 0)
        scrollBar:SetValueStep(22)
        scrollBar:SetValue(0)
    end

    local reset = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    reset:SetSize(80, 22)
    reset:SetPoint("BOTTOMLEFT", configFrame, "BOTTOMLEFT", 12, 12)
    reset:SetText("Reset")
    reset:SetScript("OnClick", function()
        MafMenu_SavedVars.hidden = {}
        MafMenu_SavedVars.favorites = {}
        MafMenu_SavedVars.hiddenCurrencies = {}
        MafMenu_SavedVars.showCurrencies = true
        BuildMenu()
        UpdateCurrencyFrame()
        RefreshConfigRows()
    end)

    RefreshConfigRows()
    configFrame:Show()
end

local configButton = CreateFrame("Button", nil, dragframe2)
configButton:SetSize(42, 18)
configButton:SetPoint("RIGHT", dragframe2, "RIGHT", -8, 0)
configButton:SetText("Config")
configButton:SetNormalFontObject(GameFontNormalSmall)
configButton:SetHighlightFontObject(GameFontHighlightSmall)
ApplyBackdrop(configButton, COLORS.button, COLORS.buttonBorder, 1)
configButton:SetScript("OnClick", function()
    CreateConfigFrame()
end)

mainCollapseButton = CreateFrame("Button", nil, dragframe2)
mainCollapseButton:SetSize(20, 18)
mainCollapseButton:SetPoint("RIGHT", configButton, "LEFT", -4, 0)
mainCollapseButton:SetNormalFontObject(GameFontNormalSmall)
mainCollapseButton:SetHighlightFontObject(GameFontHighlightSmall)
ApplyBackdrop(mainCollapseButton, COLORS.button, COLORS.buttonBorder, 1)
mainCollapseButton:SetScript("OnClick", function()
    EnsureSavedVars()
    MafMenu_SavedVars.collapsed = not MafMenu_SavedVars.collapsed
    BuildMenu()
end)
subtitle:Hide()

mainResizeGrip = CreateFrame("Button", nil, panel)
mainResizeGrip:SetSize(18, 18)
mainResizeGrip:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -4, 4)
mainResizeGrip:SetFrameLevel(panel:GetFrameLevel() + 5)
mainResizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
mainResizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
mainResizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
local resizeStartX
local resizeStartY
local resizeStartWidth
local resizeStartRowHeight
mainResizeGrip:SetScript("OnUpdate", function(self)
    if not resizeStartX then
        return
    end

    local cursorX, cursorY = GetCursorPosition()
    local uiScale = UIParent:GetEffectiveScale()
    local deltaX = (cursorX - resizeStartX) / uiScale
    local deltaDown = (resizeStartY - cursorY) / uiScale

    local nextWidth = ClampPanelWidth(resizeStartWidth + deltaX)
    local nextRowHeight = ClampRowHeight(resizeStartRowHeight + (deltaDown / 12))

    MafMenu_SavedVars.width = nextWidth
    MafMenu_SavedVars.rowHeight = nextRowHeight
    panel:SetWidth(nextWidth)
    BuildMenu()
end)
mainResizeGrip:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        resizeStartX, resizeStartY = GetCursorPosition()
        resizeStartWidth = panel:GetWidth()
        resizeStartRowHeight = GetRowHeight()
        self:SetScript("OnUpdate", self:GetScript("OnUpdate"))
    end
end)
mainResizeGrip:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" then
        EnsureSavedVars()
        MafMenu_SavedVars.width = ClampPanelWidth(panel:GetWidth())
        MafMenu_SavedVars.rowHeight = ClampRowHeight(MafMenu_SavedVars.rowHeight)
        resizeStartX = nil
        resizeStartY = nil
        resizeStartWidth = nil
        resizeStartRowHeight = nil
        BuildMenu()
    end
end)

SLASH_MAFMENUCONFIG1 = "/mafmenu"
SlashCmdList["MAFMENUCONFIG"] = function()
    CreateConfigFrame()
end

SLASH_MAFCURRENCIES1 = "/mafcurrencies"
SlashCmdList["MAFCURRENCIES"] = function()
    EnsureSavedVars()
    MafMenu_SavedVars.showCurrencies = true
    UpdateCurrencyFrame()
    RefreshConfigRows()
end

BuildMenu()
UpdateCurrencyFrame()
