MafMenu = MafMenu or {}
MafMenu.Profile = MafMenu.Profile or {}

local Profile = MafMenu.Profile
local AceDB = LibStub("AceDB-3.0")

Profile.GLOBAL = "global"
Profile.CHARACTER = "character"
Profile.GLOBAL_PROFILE = "Global"
Profile.DB_SCHEMA_VERSION = 2

local db
local defaults
local activeVars

local function Clamp(value, minValue, maxValue, fallback)
    value = value or fallback
    if value < minValue then
        return minValue
    elseif value > maxValue then
        return maxValue
    end
    return value
end

local function GetCharacterProfileName()
    local name = UnitName("player") or "Character"
    local realm = GetRealmName and GetRealmName() or nil
    if realm and realm ~= "" then
        return name .. " - " .. realm
    end
    return name
end

local function CopyLegacySettings(source, target)
    if type(source) ~= "table" or type(target) ~= "table" then
        return
    end

    target.hidden = source.hidden or target.hidden
    target.favorites = source.favorites or target.favorites
    target.hiddenCurrencies = source.hiddenCurrencies or target.hiddenCurrencies
    target.width = source.width or target.width
    target.rowHeight = source.rowHeight or target.rowHeight
    target.collapsed = source.collapsed == true
    if source.showCurrencies ~= nil then
        target.showCurrencies = source.showCurrencies
    end
    if type(source.currency) == "table" then
        target.currency = target.currency or {}
        target.currency.width = source.currency.width or target.currency.width
        target.currency.rowHeight = source.currency.rowHeight or target.currency.rowHeight
        target.currency.collapsed = source.currency.collapsed == true
        target.currency.left = source.currency.left or target.currency.left
        target.currency.top = source.currency.top or target.currency.top
    end
    target.left = source.left or target.left
    target.top = source.top or target.top
end

local function ClearLegacySettings(target)
    target.hidden = nil
    target.favorites = nil
    target.hiddenCurrencies = nil
    target.currency = nil
    target.width = nil
    target.height = nil
    target.rowHeight = nil
    target.collapsed = nil
    target.showCurrencies = nil
    target.left = nil
    target.top = nil
    target.scale = nil
end

local function BuildAceDefaults()
    return {
        profile = {
            hidden = {},
            favorites = {},
            currencyFavorites = {},
            hiddenCurrencies = {},
            sectionVisibility = {
                book = true,
                tools = true,
                toggles = true,
            },
            sectionCollapsed = {},
            width = defaults.panelWidth,
            rowHeight = defaults.defaultRowHeight,
            collapsed = false,
            locked = false,
            panelVisible = true,
            showCurrencies = true,
            currency = {
                width = defaults.currencyWidth,
                rowHeight = defaults.currencyRowHeight,
                collapsed = false,
                hideEmpty = true,
                watchedOnly = false,
                nonZeroFirst = true,
                showCategories = true,
                dimZero = true,
            },
            behavior = {
                muteMenuSounds = true,
                autoCloseGossip = true,
                gossipSelectDelay = 0.22,
            },
            appearance = {
                fontScale = 1,
                iconScale = 1,
                showSectionHeaders = true,
                panelOpacity = 0.92,
                borderOpacity = 0.95,
                menuMode = "normal",
            },
        },
    }
end

function Profile.Normalize(savedVars)
    savedVars.hidden = savedVars.hidden or {}
    savedVars.favorites = savedVars.favorites or {}
    savedVars.currencyFavorites = savedVars.currencyFavorites or {}
    savedVars.hiddenCurrencies = savedVars.hiddenCurrencies or {}
    savedVars.sectionVisibility = savedVars.sectionVisibility or {}
    savedVars.sectionCollapsed = savedVars.sectionCollapsed or {}
    if savedVars.sectionVisibility.book == nil then savedVars.sectionVisibility.book = true end
    if savedVars.sectionVisibility.tools == nil then savedVars.sectionVisibility.tools = true end
    if savedVars.sectionVisibility.toggles == nil then savedVars.sectionVisibility.toggles = true end
    savedVars.width = Clamp(savedVars.width, defaults.panelMinWidth, defaults.panelMaxWidth, defaults.panelWidth)
    savedVars.rowHeight = math.max(defaults.minRowHeight, savedVars.rowHeight or defaults.defaultRowHeight)
    savedVars.collapsed = savedVars.collapsed == true
    savedVars.locked = savedVars.locked == true
    if savedVars.panelVisible == nil then
        savedVars.panelVisible = true
    end
    if savedVars.showCurrencies == nil then
        savedVars.showCurrencies = true
    end
    savedVars.currency = savedVars.currency or {}
    savedVars.currency.width = math.max(defaults.currencyMinWidth, savedVars.currency.width or defaults.currencyWidth)
    savedVars.currency.rowHeight = math.max(defaults.currencyMinRowHeight, savedVars.currency.rowHeight or defaults.currencyRowHeight)
    savedVars.currency.collapsed = savedVars.currency.collapsed == true
    if savedVars.currency.hideEmpty == nil then savedVars.currency.hideEmpty = true else savedVars.currency.hideEmpty = savedVars.currency.hideEmpty == true end
    savedVars.currency.watchedOnly = savedVars.currency.watchedOnly == true
    if savedVars.currency.nonZeroFirst == nil then savedVars.currency.nonZeroFirst = true else savedVars.currency.nonZeroFirst = savedVars.currency.nonZeroFirst == true end
    if savedVars.currency.showCategories == nil then savedVars.currency.showCategories = true else savedVars.currency.showCategories = savedVars.currency.showCategories == true end
    if savedVars.currency.dimZero == nil then savedVars.currency.dimZero = true else savedVars.currency.dimZero = savedVars.currency.dimZero == true end
    savedVars.behavior = savedVars.behavior or {}
    if savedVars.behavior.muteMenuSounds == nil then savedVars.behavior.muteMenuSounds = true end
    if savedVars.behavior.autoCloseGossip == nil then savedVars.behavior.autoCloseGossip = true end
    savedVars.behavior.gossipSelectDelay = math.max(0, math.min(2, savedVars.behavior.gossipSelectDelay or 0.22))
    savedVars.appearance = savedVars.appearance or {}
    savedVars.appearance.fontScale = math.max(0.75, math.min(1.5, savedVars.appearance.fontScale or 1))
    savedVars.appearance.iconScale = math.max(0.75, math.min(1.5, savedVars.appearance.iconScale or 1))
    if savedVars.appearance.showSectionHeaders == nil then savedVars.appearance.showSectionHeaders = true end
    savedVars.appearance.panelOpacity = math.max(0.2, math.min(1, savedVars.appearance.panelOpacity or 0.92))
    savedVars.appearance.borderOpacity = math.max(0.2, math.min(1, savedVars.appearance.borderOpacity or 0.95))
    if savedVars.appearance.menuMode ~= "icons" and savedVars.appearance.menuMode ~= "text" and savedVars.appearance.menuMode ~= "normal" then
        savedVars.appearance.menuMode = "normal"
    end
    return savedVars
end

function Profile.Refresh()
    activeVars = Profile.Normalize(db.profile)
    return activeVars
end

function Profile.GetActive()
    return activeVars or Profile.Refresh()
end

function Profile.GetScope()
    if db and db:GetCurrentProfile() == GetCharacterProfileName() then
        return Profile.CHARACTER
    end
    return Profile.GLOBAL
end

function Profile.SetScope(scope)
    if scope == Profile.CHARACTER then
        Profile.SetProfile(GetCharacterProfileName())
    else
        Profile.SetProfile(Profile.GLOBAL_PROFILE)
    end
    return Profile.Refresh()
end

function Profile.SetProfile(profileName)
    if type(profileName) ~= "string" or profileName == "" then
        return Profile.Refresh()
    end
    db:SetProfile(profileName)
    db.profile.profileName = profileName
    return Profile.Refresh()
end

function Profile.GetDatabase()
    return db
end

function Profile.Initialize(savedVars, savedCharVars, profileDefaults)
    defaults = profileDefaults
    if type(savedVars) == "table" and savedVars.profiles == nil and (savedVars.hidden or savedVars.favorites or savedVars.width or savedVars.currency) then
        local profileName = GetCharacterProfileName()
        savedVars.profileKeys = savedVars.profileKeys or {}
        savedVars.profileKeys[profileName] = savedVars.profileKeys[profileName] or profileName
        savedVars.profiles = savedVars.profiles or {}
        savedVars.profiles[profileName] = savedVars.profiles[profileName] or {}
        CopyLegacySettings(savedVars, savedVars.profiles[profileName])
        savedVars.profiles[profileName].legacyMigratedToAceDB = true
        savedVars.profiles[profileName].profileName = profileName
        ClearLegacySettings(savedVars)
    end
    if type(savedVars) == "table" then
        savedVars.mafMenuSchemaVersion = Profile.DB_SCHEMA_VERSION
    end

    db = AceDB:New("MafMenu_SavedVars", BuildAceDefaults())

    return Profile.Refresh()
end
