MafMenu = MafMenu or {}
MafMenu.Currency = MafMenu.Currency or {}

local Currency = MafMenu.Currency
local UI = MafMenu.UI
local frame
local header
local collapseButton
local resizeGrip
local footerText
local rows = {}
local context
local GetSaved
local categoryOrder = {
    Emblems = 1,
    Mythic = 2,
    Shards = 3,
    Events = 4,
    Other = 5,
}

function Currency.Initialize(initContext)
    context = initContext
end

function Currency.GetAll()
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

local function GetCategory(currency)
    local name = currency.name or ""
    if string.find(name, "Emblem") then
        return "Emblems"
    elseif string.find(name, "Mythic") then
        return "Mythic"
    elseif string.find(name, "Shard") then
        return "Shards"
    elseif string.find(name, "Timewalking") or string.find(name, "Champion") or string.find(name, "Stone Keeper") then
        return "Events"
    end
    return "Other"
end

local function IsFavorite(currency)
    return GetSaved().currencyFavorites[currency.key] == true
end

local function SortCurrencies(currencies)
    local saved = GetSaved()
    table.sort(currencies, function(a, b)
        local aFavorite = IsFavorite(a)
        local bFavorite = IsFavorite(b)
        if aFavorite ~= bFavorite then
            return aFavorite
        end
        if (a.watched == true) ~= (b.watched == true) then
            return a.watched == true
        end
        if saved.currency.nonZeroFirst and ((a.quantity or 0) > 0) ~= ((b.quantity or 0) > 0) then
            return (a.quantity or 0) > 0
        end
        local aCategory = GetCategory(a)
        local bCategory = GetCategory(b)
        if aCategory ~= bCategory then
            return (categoryOrder[aCategory] or 99) < (categoryOrder[bCategory] or 99)
        end
        return (a.name or "") < (b.name or "")
    end)
end

function GetSaved()
    return context.GetSaved()
end

local function GetRowHeight()
    local saved = GetSaved()
    return math.max(16, saved.currency.rowHeight or 21)
end

local function SavePosition()
    if frame then
        UI.SaveTopLeft(frame, GetSaved().currency)
    end
end

local function IsHidden(currency)
    local saved = GetSaved()
    if saved.hiddenCurrencies[currency.key] == true then
        return true
    end
    if saved.currency.hideEmpty and (currency.quantity or 0) == 0 and not IsFavorite(currency) and not currency.watched then
        return true
    end
    if saved.currency.watchedOnly and not currency.watched and not IsFavorite(currency) then
        return true
    end
end

local function CreateFrameIfNeeded()
    if frame then
        return
    end

    local saved = GetSaved()
    frame = CreateFrame("Frame", "MafMenuCurrencyFrame", UIParent)
    frame:SetSize(saved.currency.width, 120)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("MEDIUM")
    UI.SkinPanel(frame)
    UI.RestoreTopLeft(frame, saved.currency, function()
        frame:SetPoint("LEFT", context.panel, "RIGHT", 8, 0)
    end)

    header = CreateFrame("Button", nil, frame)
    header:SetHeight(24)
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", 7, -7)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -7, -7)
    UI.SkinHeader(header)
    header:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self:GetParent():StartMoving()
        end
    end)
    header:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            self:GetParent():StopMovingOrSizing()
            SavePosition()
        end
    end)

    local headerText = header:CreateFontString(nil, "OVERLAY")
    UI.SetFont(headerText, 13, "OUTLINE")
    headerText:SetTextColor(unpack(UI.COLORS.gold))
    headerText:SetPoint("LEFT", header, "LEFT", 9, 0)
    headerText:SetText("Currencies")

    local close = CreateFrame("Button", nil, header, "UIPanelCloseButton")
    close:SetPoint("RIGHT", header, "RIGHT", 2, 0)
    close:SetScript("OnClick", function()
        GetSaved().showCurrencies = false
        frame:Hide()
        MafMenu.Config.Refresh()
    end)

    collapseButton = UI.CreateTitleButton(header, "-", 20)
    collapseButton:SetPoint("RIGHT", close, "LEFT", -2, 0)
    collapseButton:SetScript("OnClick", function()
        local vars = GetSaved()
        vars.currency.collapsed = not vars.currency.collapsed
        Currency.Update()
    end)

    resizeGrip = CreateFrame("Button", nil, frame)
    resizeGrip:SetSize(18, 18)
    resizeGrip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
    resizeGrip:SetFrameLevel(frame:GetFrameLevel() + 5)
    resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

    local startX, startY, startWidth, startRowHeight
    resizeGrip:SetScript("OnUpdate", function()
        if not startX then
            return
        end
        local cursorX, cursorY = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        local vars = GetSaved()
        vars.currency.width = math.max(170, startWidth + ((cursorX - startX) / scale))
        vars.currency.rowHeight = math.max(16, startRowHeight + ((startY - cursorY) / scale / 12))
        Currency.Update()
    end)
    resizeGrip:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            startX, startY = GetCursorPosition()
            startWidth = frame:GetWidth()
            startRowHeight = GetRowHeight()
        end
    end)
    resizeGrip:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            startX, startY, startWidth, startRowHeight = nil, nil, nil, nil
            SavePosition()
            Currency.Update()
        end
    end)
end

local function EnsureRow(index)
    CreateFrameIfNeeded()
    if not rows[index] then
        local rowFrame = CreateFrame("Frame", nil, frame)
        rowFrame:EnableMouse(true)
        UI.ApplyBackdrop(rowFrame, {0.020, 0.028, 0.030, 0.55}, {0.10, 0.14, 0.15, 0.40}, 1)
        local favorite = CreateFrame("Button", nil, rowFrame)
        favorite:SetSize(16, 16)
        favorite:SetPoint("LEFT", rowFrame, "LEFT", 4, 0)
        UI.SkinButton(favorite)
        local icon = rowFrame:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("LEFT", rowFrame, "LEFT", 24, 0)
        local name = rowFrame:CreateFontString(nil, "OVERLAY")
        UI.SetFont(name, 9)
        name:SetJustifyH("LEFT")
        name:SetTextColor(unpack(UI.COLORS.text))
        local count = rowFrame:CreateFontString(nil, "OVERLAY")
        UI.SetFont(count, 9)
        count:SetJustifyH("RIGHT")
        count:SetTextColor(unpack(UI.COLORS.gold))
        rows[index] = { frame = rowFrame, favorite = favorite, icon = icon, name = name, count = count }
    end
    return rows[index]
end

local function PlaceHeader(title, index, y, width)
    local row = EnsureRow(index)
    row.frame:ClearAllPoints()
    row.frame:SetSize(width, 16)
    row.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, y)
    row.frame:SetBackdropColor(unpack(UI.COLORS.section))
    row.frame:SetBackdropBorderColor(unpack(UI.COLORS.sectionBorder))
    row.frame.currency = nil
    row.frame:SetScript("OnEnter", nil)
    row.frame:SetScript("OnLeave", nil)
    row.favorite:Hide()
    row.icon:Hide()
    row.count:SetText("")
    row.name:ClearAllPoints()
    row.name:SetPoint("LEFT", row.frame, "LEFT", 7, 0)
    row.name:SetPoint("RIGHT", row.frame, "RIGHT", -7, 0)
    UI.SetFont(row.name, 9, "OUTLINE")
    row.name:SetTextColor(unpack(UI.COLORS.subtext))
    row.name:SetText(title)
    row.frame:Show()
    return y - 18
end

local function Place(currency, index, y, width)
    local row = EnsureRow(index)
    local saved = GetSaved()
    local height = GetRowHeight()
    local iconSize = math.max(12, height - 4)
    local fontSize = math.max(8, math.floor(height * 0.48))
    local quantity = currency.quantity or 0
    local zero = quantity == 0
    row.frame:ClearAllPoints()
    row.frame:SetSize(width, height)
    row.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, y)
    row.frame:SetBackdropColor(unpack(zero and {0.018, 0.023, 0.025, 0.42} or {0.020, 0.028, 0.030, 0.68}))
    row.frame:SetBackdropBorderColor(unpack(zero and {0.08, 0.10, 0.10, 0.30} or {0.13, 0.18, 0.19, 0.55}))
    row.frame:Show()
    row.favorite.currency = currency
    row.favorite:SetText(IsFavorite(currency) and "*" or "+")
    row.favorite:SetScript("OnClick", function(self)
        local vars = GetSaved()
        vars.currencyFavorites[self.currency.key] = not vars.currencyFavorites[self.currency.key] or nil
        Currency.Update()
        MafMenu.Config.Refresh()
    end)
    row.favorite:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(IsFavorite(self.currency) and "Remove watched pin" or "Pin currency")
        GameTooltip:Show()
    end)
    row.favorite:SetScript("OnLeave", function() GameTooltip:Hide() end)
    row.favorite:Show()
    row.frame.currency = currency
    row.frame:SetScript("OnEnter", function(self)
        local current = self.currency
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(current.name or "Currency")
        GameTooltip:AddLine("Category: " .. GetCategory(current), 0.65, 0.78, 0.78)
        if current.watched then
            GameTooltip:AddLine("Tracked by the character currency watch.", 0.42, 1, 0.50)
        end
        GameTooltip:Show()
    end)
    row.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
    row.icon:SetSize(iconSize, iconSize)
    row.icon:SetTexture(currency.icon)
    row.icon:Show()
    row.name:ClearAllPoints()
    row.name:SetPoint("LEFT", row.frame, "LEFT", iconSize + 30, 0)
    row.name:SetPoint("RIGHT", row.frame, "RIGHT", -46, 0)
    UI.SetFont(row.name, fontSize)
    row.name:SetTextColor(unpack(saved.currency.dimZero and zero and UI.COLORS.zero or UI.COLORS.text))
    row.name:SetText(currency.name)
    row.count:ClearAllPoints()
    row.count:SetPoint("RIGHT", row.frame, "RIGHT", -4, 0)
    UI.SetFont(row.count, fontSize)
    row.count:SetTextColor(unpack(zero and UI.COLORS.zero or UI.COLORS.gold))
    row.count:SetText(quantity)
    return y - height - 2
end

function Currency.Update()
    local saved = GetSaved()
    if not saved.showCurrencies then
        if frame then
            frame:Hide()
        end
        return
    end

    CreateFrameIfNeeded()
    local width = math.max(170, saved.currency.width)
    local y = -38
    local visibleCount = 0
    frame:SetWidth(width)
    if collapseButton then
        collapseButton:SetText(saved.currency.collapsed and "+" or "-")
    end
    if saved.currency.collapsed then
        for _, row in ipairs(rows) do
            row.frame:Hide()
        end
        if footerText then
            footerText:Hide()
        end
        if resizeGrip then
            resizeGrip:Hide()
        end
        frame:SetHeight(38)
        frame:Show()
        return
    elseif resizeGrip then
        resizeGrip:Show()
    end
    if not footerText then
        footerText = frame:CreateFontString(nil, "OVERLAY")
        UI.SetFont(footerText, 9)
        footerText:SetTextColor(unpack(UI.COLORS.subtext))
    end
    local currencies = Currency.GetAll()
    local lastCategory
    local watchedCount = 0
    local currencyCount = 0
    SortCurrencies(currencies)
    for _, currency in ipairs(currencies) do
        if not IsHidden(currency) then
            currencyCount = currencyCount + 1
            if currency.watched or IsFavorite(currency) then
                watchedCount = watchedCount + 1
            end
            local category = GetCategory(currency)
            if saved.currency.showCategories and category ~= lastCategory then
                visibleCount = visibleCount + 1
                y = PlaceHeader(category, visibleCount, y, math.max(140, width - 20))
                lastCategory = category
            end
            visibleCount = visibleCount + 1
            y = Place(currency, visibleCount, y, math.max(140, width - 20))
        end
    end
    for index = visibleCount + 1, table.getn(rows) do
        rows[index].frame:Hide()
    end
    footerText:ClearAllPoints()
    footerText:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, y - 2)
    footerText:SetPoint("RIGHT", frame, "RIGHT", -12, 0)
    footerText:SetText(currencyCount .. " shown, " .. watchedCount .. " watched")
    footerText:Show()
    y = y - 14
    frame:SetHeight(math.max(74, math.abs(y) + 14))
    frame:Show()
end

function Currency.RestorePosition()
    if frame then
        UI.RestoreTopLeft(frame, GetSaved().currency, function()
            frame:SetPoint("LEFT", context.panel, "RIGHT", 8, 0)
        end)
    end
end

function Currency.ResetPosition()
    local saved = GetSaved()
    saved.currency.left = nil
    saved.currency.top = nil
    if frame then
        UI.RestoreTopLeft(frame, saved.currency, function()
            frame:SetPoint("LEFT", context.panel, "RIGHT", 8, 0)
        end)
    end
end
