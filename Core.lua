local AceAddon = LibStub("AceAddon-3.0")

MafMenu = AceAddon:NewAddon("MafMenu", "AceEvent-3.0", "AceConsole-3.0", "AceTimer-3.0", "AceHook-3.0")
MafMenu.title = "|cff00aaffMafMenu|r"
MafMenu.PANEL_WIDTH = 232
MafMenu.PANEL_HEIGHT = 508
MafMenu.PANEL_MIN_WIDTH = 190
MafMenu.PANEL_MAX_WIDTH = 10000
MafMenu.DEFAULT_ROW_HEIGHT = 30
MafMenu.MIN_ROW_HEIGHT = 18
MafMenu.GAP = 5
MafMenu.debugEnabled = false

function MafMenu:PrintMessage(message)
    DEFAULT_CHAT_FRAME:AddMessage(self.title .. " " .. tostring(message))
end

function MafMenu:Debug(message)
    if self.debugEnabled then
        self:PrintMessage(message)
    end
end

function MafMenu:OnInitialize()
    self:RegisterChatCommand("mafmenu", "OpenConfig")
    self:RegisterChatCommand("mafcurrencies", "ShowCurrencies")
    self:RegisterChatCommand("mafdebug", "ToggleDebug")
    self:RegisterChatCommand("mafprobe", "ProbeCommands")
end

function MafMenu:ToggleDebug()
    self.debugEnabled = not self.debugEnabled
    if self.debugEnabled then
        self:PrintMessage("debug enabled")
    else
        self:PrintMessage("debug disabled")
    end
end

function MafMenu:SetDebug(enabled)
    self.debugEnabled = enabled == true
end

function MafMenu:OpenConfig()
    if self.Config then
        self.Config.Show()
    end
end

function MafMenu:ShowCurrencies()
    if self.Profile and self.Currency then
        local saved = self.Profile.Refresh()
        saved.showCurrencies = true
        self.Currency.Update()
        if self.Config then
            self.Config.Refresh()
        end
    end
end
