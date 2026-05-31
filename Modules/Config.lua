MafMenu = MafMenu or {}
MafMenu.Config = MafMenu.Config or {}

local Config = MafMenu.Config
local Profile = MafMenu.Profile
local Services = MafMenu.Services
local Currency = MafMenu.Currency
local Panel = MafMenu.Panel
local Playerbots = MafMenu.Playerbots

local AceConfig = LibStub("AceConfig-3.0-ElvUI")
local AceConfigDialog = LibStub("AceConfigDialog-3.0-ElvUI")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0-ElvUI")

local APP_NAME = "MafMenu"
local GITHUB_URL = "https://github.com/Peaap/MafMenu"
local context
local options
local newProfileName = ""
local copyProfileName
local deleteProfileName

local function GetSaved()
    return context.GetSaved()
end

local function RefreshUI()
    if not context then
        return
    end
    context.BuildMenu()
    Currency.Update()
end

local function OnProfileChanged()
    Profile.Refresh()
    if context then
        context.ApplyProfileLayout()
    end
    Config.Refresh()
end

local function Trim(value)
    if type(value) ~= "string" then
        return ""
    end
    return value:match("^%s*(.-)%s*$") or ""
end

local function GetProfileValues(includeCurrent)
    local db = Profile.GetDatabase()
    local values = {}
    local profiles = {}
    local current = db:GetCurrentProfile()

    db:GetProfiles(profiles)
    for _, profileName in ipairs(profiles) do
        if includeCurrent or profileName ~= current then
            values[profileName] = profileName
        end
    end

    if includeCurrent then
        values[current] = current
    end

    return values
end

local function ActivateProfile(profileName)
    local db = Profile.GetDatabase()
    profileName = Trim(profileName)
    if profileName == "" then
        return
    end

    Profile.SetProfile(profileName).profileCreated = true
    OnProfileChanged()
end

local function BuildServiceOptions()
    local args = {
        groups = {
            type = "group",
            name = "Groups",
            order = 1,
            inline = true,
            args = {
                book = {
                    type = "toggle",
                    name = "Book services",
                    order = 1,
                    get = function() return GetSaved().sectionVisibility.book end,
                    set = function(_, value) GetSaved().sectionVisibility.book = value == true; RefreshUI() end,
                },
                tools = {
                    type = "toggle",
                    name = "Tools",
                    order = 2,
                    get = function() return GetSaved().sectionVisibility.tools end,
                    set = function(_, value) GetSaved().sectionVisibility.tools = value == true; RefreshUI() end,
                },
                toggles = {
                    type = "toggle",
                    name = "Server toggles",
                    order = 3,
                    get = function() return GetSaved().sectionVisibility.toggles end,
                    set = function(_, value) GetSaved().sectionVisibility.toggles = value == true; RefreshUI() end,
                },
                playerbots = {
                    type = "toggle",
                    name = "Playerbots",
                    order = 4,
                    get = function() return GetSaved().sectionVisibility.playerbots end,
                    set = function(_, value) GetSaved().sectionVisibility.playerbots = value == true; RefreshUI() end,
                },
                collapseBook = {
                    type = "toggle",
                    name = "Collapse Book",
                    order = 5,
                    get = function() return GetSaved().sectionCollapsed.book == true end,
                    set = function(_, value) GetSaved().sectionCollapsed.book = value or nil; RefreshUI() end,
                },
                collapseTools = {
                    type = "toggle",
                    name = "Collapse Tools",
                    order = 6,
                    get = function() return GetSaved().sectionCollapsed.tools == true end,
                    set = function(_, value) GetSaved().sectionCollapsed.tools = value or nil; RefreshUI() end,
                },
                collapseToggles = {
                    type = "toggle",
                    name = "Collapse Toggles",
                    order = 7,
                    get = function() return GetSaved().sectionCollapsed.toggles == true end,
                    set = function(_, value) GetSaved().sectionCollapsed.toggles = value or nil; RefreshUI() end,
                },
                collapsePlayerbots = {
                    type = "toggle",
                    name = "Collapse Playerbots",
                    order = 8,
                    get = function() return GetSaved().sectionCollapsed.playerbots == true end,
                    set = function(_, value) GetSaved().sectionCollapsed.playerbots = value or nil; RefreshUI() end,
                },
            },
        },
    }
    local order = 1
    for _, entry in ipairs(Services.GetEntries()) do
        local service = entry
        args[service.key] = {
            type = "group",
            name = service.label,
            order = order + 10,
            inline = true,
            args = {
                favorite = {
                    type = "toggle",
                    name = "Favorite",
                    order = 1,
                    get = function()
                        return GetSaved().favorites[service.key] == true
                    end,
                    set = function(_, value)
                        GetSaved().favorites[service.key] = value or nil
                        RefreshUI()
                    end,
                },
                hidden = {
                    type = "toggle",
                    name = "Hidden",
                    order = 2,
                    get = function()
                        return GetSaved().hidden[service.key] == true
                    end,
                    set = function(_, value)
                        GetSaved().hidden[service.key] = value or nil
                        RefreshUI()
                    end,
                },
            },
        }
        order = order + 1
    end
    return args
end

local function BuildCurrencyOptions()
    local args = {
        watcher = {
            type = "group",
            name = "Currency Watcher",
            order = 1,
            inline = true,
            args = {
                showCurrencies = {
                    type = "toggle",
                    name = "Show currency watcher",
                    order = 1,
                    get = function() return GetSaved().showCurrencies == true end,
                    set = function(_, value) GetSaved().showCurrencies = value == true; Currency.Update() end,
                },
                collapsed = {
                    type = "toggle",
                    name = "Collapse by default",
                    order = 2,
                    get = function() return GetSaved().currency.collapsed == true end,
                    set = function(_, value) GetSaved().currency.collapsed = value == true; Currency.Update() end,
                },
                hideEmpty = {
                    type = "toggle",
                    name = "Hide empty currencies",
                    order = 3,
                    get = function() return GetSaved().currency.hideEmpty == true end,
                    set = function(_, value) GetSaved().currency.hideEmpty = value == true; Currency.Update() end,
                },
                watchedOnly = {
                    type = "toggle",
                    name = "Only show watched currencies",
                    width = "double",
                    order = 4,
                    get = function() return GetSaved().currency.watchedOnly == true end,
                    set = function(_, value) GetSaved().currency.watchedOnly = value == true; Currency.Update() end,
                },
                nonZeroFirst = {
                    type = "toggle",
                    name = "Sort non-zero first",
                    order = 5,
                    get = function() return GetSaved().currency.nonZeroFirst == true end,
                    set = function(_, value) GetSaved().currency.nonZeroFirst = value == true; Currency.Update() end,
                },
                showCategories = {
                    type = "toggle",
                    name = "Show category headers",
                    order = 6,
                    get = function() return GetSaved().currency.showCategories == true end,
                    set = function(_, value) GetSaved().currency.showCategories = value == true; Currency.Update() end,
                },
                dimZero = {
                    type = "toggle",
                    name = "Dim zero currencies",
                    order = 7,
                    get = function() return GetSaved().currency.dimZero == true end,
                    set = function(_, value) GetSaved().currency.dimZero = value == true; Currency.Update() end,
                },
                width = {
                    type = "range",
                    name = "Width",
                    order = 8,
                    min = 170,
                    max = 700,
                    step = 1,
                    get = function() return GetSaved().currency.width end,
                    set = function(_, value) GetSaved().currency.width = value; Currency.Update() end,
                },
                rowHeight = {
                    type = "range",
                    name = "Row height",
                    order = 9,
                    min = 16,
                    max = 60,
                    step = 1,
                    get = function() return GetSaved().currency.rowHeight end,
                    set = function(_, value) GetSaved().currency.rowHeight = value; Currency.Update() end,
                },
                resetPosition = {
                    type = "execute",
                    name = "Reset currency position",
                    width = "double",
                    order = 10,
                    func = function() Currency.ResetPosition() end,
                },
            },
        },
    }
    local order = 20
    for _, currency in ipairs(Currency.GetAll()) do
        local current = currency
        args["currency_" .. current.key] = {
            type = "toggle",
            name = current.name,
            order = order,
            get = function()
                return not GetSaved().hiddenCurrencies[current.key]
            end,
            set = function(_, value)
                GetSaved().hiddenCurrencies[current.key] = not value or nil
                Currency.Update()
            end,
        }
        order = order + 1
    end
    return args
end

local function BuildPanelOptions()
    return {
        visibility = {
            type = "group",
            name = "Panel",
            order = 1,
            inline = true,
            args = {
                panelVisible = {
                    type = "toggle",
                    name = "Show main menu",
                    order = 1,
                    get = function() return GetSaved().panelVisible == true end,
                    set = function(_, value) Panel.SetVisible(value == true); Config.Refresh() end,
                },
                locked = {
                    type = "toggle",
                    name = "Lock dragging",
                    order = 2,
                    get = function() return GetSaved().locked == true end,
                    set = function(_, value) GetSaved().locked = value == true end,
                },
                collapsed = {
                    type = "toggle",
                    name = "Collapse by default",
                    order = 3,
                    get = function() return GetSaved().collapsed == true end,
                    set = function(_, value) GetSaved().collapsed = value == true; RefreshUI() end,
                },
                width = {
                    type = "range",
                    name = "Width",
                    order = 4,
                    min = MafMenu.PANEL_MIN_WIDTH,
                    max = 700,
                    step = 1,
                    get = function() return GetSaved().width end,
                    set = function(_, value) GetSaved().width = value; RefreshUI() end,
                },
                rowHeight = {
                    type = "range",
                    name = "Row height",
                    order = 5,
                    min = MafMenu.MIN_ROW_HEIGHT,
                    max = 80,
                    step = 1,
                    get = function() return GetSaved().rowHeight end,
                    set = function(_, value) GetSaved().rowHeight = value; RefreshUI() end,
                },
                resetPosition = {
                    type = "execute",
                    name = "Reset menu position",
                    width = "double",
                    order = 6,
                    func = function() Panel.ResetPosition() end,
                },
                resetSize = {
                    type = "execute",
                    name = "Reset menu size",
                    width = "double",
                    order = 7,
                    func = function() Panel.ResetSize() end,
                },
            },
        },
    }
end

local function BuildBehaviorOptions()
    return {
        muteMenuSounds = {
            type = "toggle",
            name = "Mute error sounds while using Book services",
            order = 1,
            get = function() return GetSaved().behavior.muteMenuSounds == true end,
            set = function(_, value) GetSaved().behavior.muteMenuSounds = value == true end,
        },
        autoCloseGossip = {
            type = "toggle",
            name = "Auto-close Book gossip after selecting service",
            order = 2,
            get = function() return GetSaved().behavior.autoCloseGossip == true end,
            set = function(_, value) GetSaved().behavior.autoCloseGossip = value == true end,
        },
        gossipSelectDelay = {
            type = "range",
            name = "Gossip select delay",
            order = 3,
            min = 0,
            max = 2,
            step = 0.01,
            get = function() return GetSaved().behavior.gossipSelectDelay end,
            set = function(_, value) GetSaved().behavior.gossipSelectDelay = value end,
        },
        debug = {
            type = "toggle",
            name = "Debug mode",
            order = 4,
            get = function() return MafMenu.debugEnabled == true end,
            set = function(_, value) MafMenu:SetDebug(value) end,
        },
        probe = {
            type = "execute",
            name = "Run command probe",
            order = 5,
            func = function() MafMenu:ProbeCommands("") end,
        },
    }
end

local function BuildAppearanceOptions()
    return {
        menuMode = {
            type = "select",
            name = "Menu mode",
            order = 1,
            values = {
                normal = "Icon and text",
                text = "Text only",
                icons = "Icon only",
            },
            get = function() return GetSaved().appearance.menuMode end,
            set = function(_, value) GetSaved().appearance.menuMode = value; RefreshUI() end,
        },
        fontScale = {
            type = "range",
            name = "Font scale",
            order = 2,
            min = 0.75,
            max = 1.5,
            step = 0.01,
            get = function() return GetSaved().appearance.fontScale end,
            set = function(_, value) GetSaved().appearance.fontScale = value; RefreshUI() end,
        },
        iconScale = {
            type = "range",
            name = "Icon scale",
            order = 3,
            min = 0.75,
            max = 1.5,
            step = 0.01,
            get = function() return GetSaved().appearance.iconScale end,
            set = function(_, value) GetSaved().appearance.iconScale = value; RefreshUI() end,
        },
        showSectionHeaders = {
            type = "toggle",
            name = "Show section headers",
            order = 4,
            get = function() return GetSaved().appearance.showSectionHeaders == true end,
            set = function(_, value) GetSaved().appearance.showSectionHeaders = value == true; RefreshUI() end,
        },
        panelOpacity = {
            type = "range",
            name = "Panel opacity",
            order = 5,
            min = 0.2,
            max = 1,
            step = 0.01,
            get = function() return GetSaved().appearance.panelOpacity end,
            set = function(_, value) GetSaved().appearance.panelOpacity = value; RefreshUI() end,
        },
        borderOpacity = {
            type = "range",
            name = "Border opacity",
            order = 6,
            min = 0.2,
            max = 1,
            step = 0.01,
            get = function() return GetSaved().appearance.borderOpacity end,
            set = function(_, value) GetSaved().appearance.borderOpacity = value; RefreshUI() end,
        },
    }
end

local function BuildPlayerbotOptions()
    return {
        setup = {
            type = "group",
            name = "Setup",
            order = 1,
            args = {
                botNames = {
                    type = "input",
                    name = "Bot names",
                    desc = "Comma-separated bot names for .playerbots bot add/remove.",
                    width = "double",
                    order = 1,
                    get = function() return GetSaved().playerbots.botNames end,
                    set = function(_, value) GetSaved().playerbots.botNames = value or "" end,
                },
                addBots = {
                    type = "execute",
                    name = "Add bots",
                    order = 2,
                    func = Playerbots.AddBots,
                },
                removeBots = {
                    type = "execute",
                    name = "Remove bots",
                    order = 3,
                    func = Playerbots.RemoveBots,
                },
                accountName = {
                    type = "input",
                    name = "Account name",
                    width = "double",
                    order = 4,
                    get = function() return GetSaved().playerbots.accountName end,
                    set = function(_, value) GetSaved().playerbots.accountName = value or "" end,
                },
                addAccount = {
                    type = "execute",
                    name = "Add account",
                    order = 5,
                    func = Playerbots.AddAccount,
                },
                className = {
                    type = "input",
                    name = "Rndbot class",
                    desc = "Example: warrior, priest, mage, dk.",
                    width = "double",
                    order = 6,
                    get = function() return GetSaved().playerbots.className end,
                    set = function(_, value) GetSaved().playerbots.className = value or "" end,
                },
                addClass = {
                    type = "execute",
                    name = "Add class bot",
                    order = 7,
                    func = Playerbots.AddClass,
                },
            },
        },
        party = {
            type = "group",
            name = "Party/Raid",
            order = 2,
            args = {
                follow = { type = "execute", name = "Follow", order = 1, func = function() Playerbots.Party("follow") end },
                attack = { type = "execute", name = "Attack", order = 2, func = function() Playerbots.Party("attack") end },
                stay = { type = "execute", name = "Stay", order = 3, func = function() Playerbots.Party("stay") end },
                summon = { type = "execute", name = "Summon", order = 4, func = function() Playerbots.Party("summon") end },
                flee = { type = "execute", name = "Flee", order = 5, func = function() Playerbots.Party("flee") end },
                grind = { type = "execute", name = "Grind", order = 6, func = function() Playerbots.Party("grind") end },
                disperseDistance = {
                    type = "range",
                    name = "Disperse distance",
                    width = "double",
                    order = 7,
                    min = 1,
                    max = 100,
                    step = 1,
                    get = function() return GetSaved().playerbots.disperseDistance end,
                    set = function(_, value) GetSaved().playerbots.disperseDistance = value end,
                },
                disperse = { type = "execute", name = "Set disperse", order = 8, func = Playerbots.Disperse },
                disperseDisable = { type = "execute", name = "Disable disperse", width = "double", order = 9, func = function() Playerbots.Party("disperse disable") end },
            },
        },
        whisper = {
            type = "group",
            name = "Whisper Target",
            order = 3,
            args = {
                whisperTarget = {
                    type = "input",
                    name = "Bot target",
                    width = "double",
                    order = 1,
                    get = function() return GetSaved().playerbots.whisperTarget end,
                    set = function(_, value) GetSaved().playerbots.whisperTarget = value or "" end,
                },
                who = { type = "execute", name = "Who", order = 2, func = function() Playerbots.Whisper("who") end },
                spells = { type = "execute", name = "Spells", order = 3, func = function() Playerbots.Whisper("spells") end },
                quests = { type = "execute", name = "Quests", order = 4, func = function() Playerbots.Whisper("quests") end },
                trainer = { type = "execute", name = "Trainer", order = 5, func = function() Playerbots.Whisper("trainer") end },
            },
        },
        custom = {
            type = "group",
            name = "Custom",
            order = 4,
            args = {
                customCommand = {
                    type = "input",
                    name = "Custom party/raid command",
                    width = "double",
                    order = 1,
                    get = function() return GetSaved().playerbots.customCommand end,
                    set = function(_, value) GetSaved().playerbots.customCommand = value or "" end,
                },
                sendCustom = { type = "execute", name = "Send custom", order = 2, func = Playerbots.Custom },
            },
        },
    }
end

local function BuildProfileOptions(db)
    return {
        current = {
            type = "description",
            name = function()
                return "Current profile: " .. db:GetCurrentProfile()
            end,
            order = 1,
        },
        newProfile = {
            type = "input",
            name = "New profile",
            desc = "Enter a profile name and press Enter to create or switch to it.",
            width = "double",
            order = 2,
            get = function() return newProfileName end,
            set = function(_, value)
                newProfileName = Trim(value)
                ActivateProfile(newProfileName)
                newProfileName = ""
            end,
        },
        chooseProfile = {
            type = "select",
            name = "Existing profiles",
            order = 3,
            get = function()
                return db:GetCurrentProfile()
            end,
            set = function(_, value)
                ActivateProfile(value)
            end,
            values = function()
                return GetProfileValues(true)
            end,
        },
        copyFrom = {
            type = "select",
            name = "Copy from",
            order = 4,
            get = function() return copyProfileName end,
            set = function(_, value)
                copyProfileName = value
                if value and value ~= "" then
                    db:CopyProfile(value)
                    OnProfileChanged()
                end
            end,
            values = function()
                return GetProfileValues(false)
            end,
        },
        deleteProfile = {
            type = "select",
            name = "Delete profile",
            order = 5,
            get = function() return deleteProfileName end,
            set = function(_, value)
                deleteProfileName = value
            end,
            values = function()
                return GetProfileValues(false)
            end,
        },
        deleteSelected = {
            type = "execute",
            name = "Delete selected profile",
            order = 6,
            width = "double",
            confirm = true,
            disabled = function()
                return not deleteProfileName or deleteProfileName == ""
            end,
            func = function()
                if deleteProfileName and deleteProfileName ~= "" then
                    db:DeleteProfile(deleteProfileName)
                    deleteProfileName = nil
                    Config.Refresh()
                end
            end,
        },
        resetCurrent = {
            type = "execute",
            name = "Reset current profile",
            order = 7,
            width = "double",
            confirm = true,
            func = function()
                db:ResetProfile()
                OnProfileChanged()
            end,
        },
    }
end

local function BuildGeneralOptions(db)
    return {
        about = {
            type = "group",
            name = "About",
            order = 0,
            inline = true,
            args = {
                title = {
                    type = "description",
                    name = "MafMenu 2.1.0",
                    order = 1,
                    fontSize = "medium",
                },
                summary = {
                    type = "description",
                    name = "Book of Maf shortcuts, server toggles, Playerbots controls, currency watcher, profiles, and layout tools for MafWoW WotLK 3.3.5a.",
                    order = 2,
                    width = "double",
                },
                credits = {
                    type = "description",
                    name = "Maintained by @peaps. Original Playerbots/MafMenu work credited to #Likon69.",
                    order = 3,
                    width = "double",
                },
                github = {
                    type = "input",
                    name = "GitHub",
                    order = 4,
                    width = "double",
                    get = function() return GITHUB_URL end,
                    set = function() end,
                },
            },
        },
        status = {
            type = "group",
            name = "Status",
            order = 1,
            inline = true,
            args = {
                currentProfile = {
                    type = "description",
                    name = function()
                        return "Current profile: " .. db:GetCurrentProfile()
                    end,
                    order = 1,
                    width = "double",
                },
                menuState = {
                    type = "description",
                    name = function()
                        return "Main menu: " .. (GetSaved().panelVisible and "shown" or "hidden")
                    end,
                    order = 2,
                },
                currencyState = {
                    type = "description",
                    name = function()
                        return "Currency watcher: " .. (GetSaved().showCurrencies and "shown" or "hidden")
                    end,
                    order = 3,
                },
                lockState = {
                    type = "description",
                    name = function()
                        return "Dragging: " .. (GetSaved().locked and "locked" or "unlocked")
                    end,
                    order = 4,
                },
            },
        },
        quickToggles = {
            type = "group",
            name = "Quick toggles",
            order = 2,
            inline = true,
            args = {
                panelVisible = {
                    type = "toggle",
                    name = "Show main menu",
                    order = 1,
                    get = function() return GetSaved().panelVisible == true end,
                    set = function(_, value) Panel.SetVisible(value == true); Config.Refresh() end,
                },
                locked = {
                    type = "toggle",
                    name = "Lock dragging",
                    order = 2,
                    get = function() return GetSaved().locked == true end,
                    set = function(_, value) GetSaved().locked = value == true; RefreshUI(); Config.Refresh() end,
                },
                collapsed = {
                    type = "toggle",
                    name = "Collapse menu",
                    order = 3,
                    get = function() return GetSaved().collapsed == true end,
                    set = function(_, value) GetSaved().collapsed = value == true; RefreshUI() end,
                },
                showCurrencies = {
                    type = "toggle",
                    name = "Show currency watcher",
                    order = 4,
                    get = function() return GetSaved().showCurrencies == true end,
                    set = function(_, value) GetSaved().showCurrencies = value == true; Currency.Update(); Config.Refresh() end,
                },
                currencyCollapsed = {
                    type = "toggle",
                    name = "Collapse currency watcher",
                    order = 5,
                    get = function() return GetSaved().currency.collapsed == true end,
                    set = function(_, value) GetSaved().currency.collapsed = value == true; Currency.Update() end,
                },
                debug = {
                    type = "toggle",
                    name = "Debug mode",
                    order = 6,
                    get = function() return MafMenu.debugEnabled == true end,
                    set = function(_, value) MafMenu:SetDebug(value) end,
                },
            },
        },
        quickActions = {
            type = "group",
            name = "Quick actions",
            order = 3,
            inline = true,
            args = {
                resetMenuPosition = {
                    type = "execute",
                    name = "Reset menu position",
                    order = 1,
                    width = "double",
                    func = function() Panel.ResetPosition() end,
                },
                resetMenuSize = {
                    type = "execute",
                    name = "Reset menu size",
                    order = 2,
                    width = "double",
                    func = function() Panel.ResetSize() end,
                },
                resetCurrencyPosition = {
                    type = "execute",
                    name = "Reset currency position",
                    order = 3,
                    width = "double",
                    func = function() Currency.ResetPosition() end,
                },
                runProbe = {
                    type = "execute",
                    name = "Run command probe",
                    order = 4,
                    width = "double",
                    func = function() MafMenu:ProbeCommands("") end,
                },
                resetCurrent = {
                    type = "execute",
                    name = "Reset current profile",
                    order = 10,
                    width = "double",
                    confirm = true,
                    func = function()
                        db:ResetProfile()
                        OnProfileChanged()
                    end,
                },
            },
        },
    }
end

local function CreateOptions()
    local db = Profile.GetDatabase()
    options = {
        type = "group",
        name = "MafMenu",
        args = {
            general = {
                type = "group",
                name = "General",
                order = 1,
                args = BuildGeneralOptions(db),
            },
            services = {
                type = "group",
                name = "Services",
                order = 3,
                args = BuildServiceOptions(),
            },
            playerbots = {
                type = "group",
                name = "Playerbots",
                order = 2,
                args = BuildPlayerbotOptions(),
            },
            panel = {
                type = "group",
                name = "Panel",
                order = 4,
                args = BuildPanelOptions(),
            },
            currencies = {
                type = "group",
                name = "Currency Watcher",
                order = 5,
                args = BuildCurrencyOptions(),
            },
            behavior = {
                type = "group",
                name = "Behavior",
                order = 6,
                args = BuildBehaviorOptions(),
            },
            appearance = {
                type = "group",
                name = "Appearance",
                order = 7,
                args = BuildAppearanceOptions(),
            },
            profiles = {
                type = "group",
                name = "Profiles",
                order = 99,
                args = BuildProfileOptions(db),
            },
        },
    }
    return options
end

function Config.Initialize(initContext)
    context = initContext
    local db = Profile.GetDatabase()
    db:RegisterCallback("OnProfileChanged", OnProfileChanged)
    db:RegisterCallback("OnProfileCopied", OnProfileChanged)
    db:RegisterCallback("OnProfileReset", OnProfileChanged)
    db:RegisterCallback("OnNewProfile", OnProfileChanged)
    AceConfig:RegisterOptionsTable(APP_NAME, CreateOptions)
    AceConfigDialog:SetDefaultSize(APP_NAME, 620, 620)
end

function Config.Refresh()
    if AceConfigRegistry then
        AceConfigRegistry:NotifyChange(APP_NAME)
    end
end

function Config.Show()
    if not options then
        CreateOptions()
    end
    Config.Refresh()
    AceConfigDialog:Open(APP_NAME)
end
