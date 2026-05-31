local initialized

local function InitializeMafMenu()
    if initialized then
        return
    end
    initialized = true

    MafMenu_SavedVars = MafMenu_SavedVars or {}
    MafMenu_CharVars = MafMenu_CharVars or {}

    MafMenu.Profile.Initialize(MafMenu_SavedVars, MafMenu_CharVars, {
        panelWidth = MafMenu.PANEL_WIDTH,
        panelMinWidth = MafMenu.PANEL_MIN_WIDTH,
        panelMaxWidth = MafMenu.PANEL_MAX_WIDTH,
        defaultRowHeight = MafMenu.DEFAULT_ROW_HEIGHT,
        minRowHeight = MafMenu.MIN_ROW_HEIGHT,
        currencyWidth = 230,
        currencyMinWidth = 170,
        currencyRowHeight = 21,
        currencyMinRowHeight = 16,
    })

    MafMenu.FlashGuard.Install()
    MafMenu.Panel.Initialize()
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, _, addonName)
    if addonName == "MafMenu" or addonName == "MafMenu-2.1.0" then
        self:UnregisterEvent("ADDON_LOADED")
        InitializeMafMenu()
    end
end)
