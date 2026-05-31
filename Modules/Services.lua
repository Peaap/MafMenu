MafMenu = MafMenu or {}
MafMenu.Services = MafMenu.Services or {}

local Services = MafMenu.Services
local UI = MafMenu.UI
local Profile = MafMenu.Profile

local bookMacro = "/use Book of Maf\n/stopcasting"
local pendingGossipOption
local gossipWaitTime = 0
local lastBookClickTime
local GOSSIP_SELECT_TIMEOUT = 2.5
local gossipChecker = CreateFrame("Frame")
gossipChecker:Hide()

local commandProbe = {
    active = false,
    elapsed = 0,
    index = 1,
    commands = {},
}

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
        MafMenu:PrintMessage("command probe done")
        return
    end

    MafMenu:PrintMessage("probing .help " .. command)
    SendChatMessage(".help " .. command)
    commandProbe.index = commandProbe.index + 1
end)

local function CreateBookServiceMacro()
    return bookMacro
end

Services.entries = {
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
    { key = "aoeOn", buttonName = "buttonAoELootOn", label = "AoE On", tooltip = "AoELoot On", section = "toggles", macro = ".aoeloot on", color = UI.COLORS.green },
    { key = "aoeOff", buttonName = "buttonAoELootOff", label = "AoE Off", tooltip = "AoELoot Off", section = "toggles", macro = ".aoeloot off", color = UI.COLORS.mutedRed },
    { key = "mythicOn", buttonName = "buttonMythicEnable", label = "Mythic On", tooltip = "Mythic Enable", section = "toggles", macro = ".mythic enable", color = {0.62, 1, 0.62, 1} },
    { key = "mythicTrash", buttonName = "buttonMythicTrash", label = "Mythic Trash", tooltip = "Mythic Trash", section = "toggles", macro = ".mythic trash", color = {1, 0.55, 0.55, 1} },
}

function Services.GetEntries()
    return Services.entries
end

function Services.ClearPendingBookOption()
    pendingGossipOption = nil
    gossipWaitTime = 0
    gossipChecker:Hide()
end

local function CloseBookGossipFrame()
    if CloseGossip then
        CloseGossip()
    elseif GossipFrame and GossipFrame:IsVisible() then
        GossipFrame:Hide()
    end
end

local function MuteMenuSounds()
    if not Profile.Refresh().behavior.muteMenuSounds then
        return
    end

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

local function SelectPendingBookOption()
    local behavior = Profile.Refresh().behavior
    if pendingGossipOption and gossipWaitTime >= behavior.gossipSelectDelay and GossipFrame and GossipFrame:IsVisible() then
        MafMenu:Debug("Selecting gossip option " .. pendingGossipOption)
        SelectGossipOption(pendingGossipOption)
        Services.ClearPendingBookOption()

        if behavior.autoCloseGossip and GossipFrame and GossipFrame:IsVisible() then
            CloseBookGossipFrame()
        end
        return true
    end
end

gossipChecker:SetScript("OnUpdate", function(self, elapsed)
    gossipWaitTime = gossipWaitTime + elapsed

    if SelectPendingBookOption() then
        return
    elseif gossipWaitTime > GOSSIP_SELECT_TIMEOUT then
        Services.ClearPendingBookOption()
    end
end)

function Services.SelectBookOptionWhenReady(gossipOption)
    pendingGossipOption = gossipOption
    gossipWaitTime = 0
    lastBookClickTime = GetTime()
    if GossipFrame and GossipFrame:IsVisible() then
        MafMenu:Debug("Book already open; delaying gossip option " .. gossipOption)
    else
        MafMenu:Debug("Waiting for Book gossip option " .. gossipOption)
    end
    gossipChecker:Show()
end

local function AddGossipSelect(button, gossipOption)
    button:HookScript("PostClick", function()
        Services.SelectBookOptionWhenReady(gossipOption)
    end)
end

function Services.CreateMenuButton(entry, parent, width, height, x, y, textColor, fontSize, justify)
    local button = CreateFrame("Button", entry.buttonName, parent, "SecureActionButtonTemplate")
    button:SetSize(width, height)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetAttribute("type1", "macro")
    button:SetAttribute("macrotext1", entry.macro or bookMacro)
    button:HookScript("PreClick", MuteMenuSounds)
    UI.ApplyBackdrop(button, UI.COLORS.button, UI.COLORS.buttonBorder, 1)
    button.baseFontSize = fontSize or 12
    button.hasMenuIcon = entry.icon ~= nil
    button.justify = justify

    local labelX = entry.icon and 38 or 0
    if entry.icon then
        button.icon = button:CreateTexture(nil, "ARTWORK")
        button.icon:SetSize(22, 22)
        button.icon:SetPoint("LEFT", button, "LEFT", 6, 0)
        button.icon:SetTexture(entry.icon)

        button.iconBorder = button:CreateTexture(nil, "OVERLAY")
        button.iconBorder:SetSize(24, 24)
        button.iconBorder:SetPoint("CENTER", button.icon, "CENTER", 0, 0)
        button.iconBorder:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    end

    button.labelX = labelX
    button.label = button:CreateFontString(nil, "OVERLAY")
    UI.SetFont(button.label, fontSize or 12)
    if justify == "CENTER" then
        button.label:SetPoint("CENTER", button, "CENTER", 0, 0)
    else
        button.label:SetPoint("LEFT", button, "LEFT", labelX, 0)
    end
    button.label:SetJustifyH(justify or "LEFT")
    button.label:SetJustifyV("MIDDLE")
    button.label:SetTextColor(unpack(textColor or UI.COLORS.text))
    button.label:SetText(entry.label)

    UI.SetTooltip(button, entry.tooltip)
    if entry.gossip then
        AddGossipSelect(button, entry.gossip)
    end

    return button
end

function Services.HandleGossipShow()
    if pendingGossipOption then
        local delay = lastBookClickTime and (GetTime() - lastBookClickTime) or 0
        MafMenu:Debug(string.format("GOSSIP_SHOW after %.3fs; selecting after %.2fs", delay, Profile.Refresh().behavior.gossipSelectDelay))
        gossipChecker:Show()
        return true
    end

    if MafMenu.debugEnabled and GetGossipOptions then
        local options = {GetGossipOptions()}
        for i = 1, table.getn(options), 2 do
            local optionIndex = ((i + 1) / 2)
            MafMenu:Debug(optionIndex .. ": " .. tostring(options[i]) .. " [" .. tostring(options[i + 1]) .. "]")
        end
    end
end

function MafMenu:ProbeCommands(msg)
    local commands = {}
    for command in string.gmatch(msg or "", "%S+") do
        table.insert(commands, command)
    end

    if table.getn(commands) == 0 then
        commands = {
            "vendor", "bank", "auction", "ah", "trainer", "teleport", "teleporter",
            "reagent", "collector", "legacy", "gear", "gear vendor", "transmog",
            "lootbot", "account", "server",
        }
    end

    commandProbe.commands = commands
    commandProbe.index = 1
    commandProbe.elapsed = 0.8
    commandProbe.active = true
    commandProbeFrame:Show()
    self:PrintMessage("probing " .. table.getn(commands) .. " command candidates")
end
