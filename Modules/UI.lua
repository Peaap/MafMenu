MafMenu = MafMenu or {}
MafMenu.UI = MafMenu.UI or {}

local UI = MafMenu.UI

UI.ADDON_PATH = "Interface\\AddOns\\MafMenu\\"
UI.MAF_FONT = UI.ADDON_PATH .. "Fonts\\Expressway.ttf"
UI.MAF_FONT_FALLBACK = "Fonts\\FRIZQT__.TTF"

UI.COLORS = {
    panel = {0.015, 0.020, 0.022, 0.92},
    panelBorder = {0.34, 0.42, 0.43, 0.95},
    header = {0.055, 0.070, 0.075, 0.98},
    headerBorder = {0.48, 0.58, 0.58, 0.95},
    button = {0.035, 0.045, 0.047, 0.94},
    buttonAlt = {0.025, 0.034, 0.036, 0.90},
    buttonHover = {0.095, 0.120, 0.125, 0.98},
    buttonDown = {0.018, 0.023, 0.025, 1},
    buttonBorder = {0.18, 0.24, 0.25, 0.95},
    buttonBorderHover = {0.74, 0.82, 0.78, 1},
    section = {0.030, 0.040, 0.044, 0.88},
    sectionBorder = {0.18, 0.25, 0.26, 0.72},
    zero = {0.48, 0.50, 0.48, 0.72},
    text = {0.92, 0.90, 0.82, 1},
    subtext = {0.52, 0.60, 0.58, 1},
    gold = {1.00, 0.78, 0.18, 1},
    green = {0.42, 1.00, 0.50, 1},
    mutedRed = {1.00, 0.45, 0.42, 1},
}

function UI.IsValidNumber(value)
    return type(value) == "number" and value == value
end

function UI.ClampPanelWidth(width)
    return math.max(MafMenu.PANEL_MIN_WIDTH, math.min(MafMenu.PANEL_MAX_WIDTH, width or MafMenu.PANEL_WIDTH))
end

function UI.ClampRowHeight(height)
    return math.max(MafMenu.MIN_ROW_HEIGHT, height or MafMenu.DEFAULT_ROW_HEIGHT)
end

function UI.ApplyBackdrop(frame, bg, border, edgeSize, tooltipBorder)
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

function UI.SkinPanel(frame)
    UI.ApplyBackdrop(frame, UI.COLORS.panel, UI.COLORS.panelBorder, 12, true)
end

function UI.SkinHeader(frame)
    UI.ApplyBackdrop(frame, UI.COLORS.header, UI.COLORS.headerBorder, 1)
end

function UI.SkinButton(button)
    UI.ApplyBackdrop(button, UI.COLORS.button, UI.COLORS.buttonBorder, 1)
    button:SetNormalFontObject(GameFontNormalSmall)
    button:SetHighlightFontObject(GameFontHighlightSmall)
end

function UI.SetButtonStateColor(button, state)
    if state == "on" then
        button:SetBackdropColor(0.035, 0.090, 0.050, 0.96)
        button:SetBackdropBorderColor(0.26, 0.72, 0.34, 1)
    elseif state == "off" or state == "danger" then
        button:SetBackdropColor(0.095, 0.040, 0.038, 0.96)
        button:SetBackdropBorderColor(0.72, 0.25, 0.24, 1)
    else
        button:SetBackdropColor(unpack(UI.COLORS.button))
        button:SetBackdropBorderColor(unpack(UI.COLORS.buttonBorder))
    end
end

function UI.CreateTitleButton(parent, text, width)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width or 20, 18)
    UI.SkinButton(button)
    button:SetText(text)
    return button
end

function UI.SetFont(fontString, size, flags)
    if not fontString:SetFont(UI.MAF_FONT, size, flags) then
        fontString:SetFont(UI.MAF_FONT_FALLBACK, size, flags)
    end
end

function UI.SaveTopLeft(frame, target)
    local left = frame:GetLeft()
    local top = frame:GetTop()
    if UI.IsValidNumber(left) and UI.IsValidNumber(top) then
        target.left = left
        target.top = top
    else
        target.left = nil
        target.top = nil
    end
end

function UI.RestoreTopLeft(frame, target, fallback)
    frame:ClearAllPoints()
    if target and UI.IsValidNumber(target.left) and UI.IsValidNumber(target.top) then
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", target.left, target.top)
    elseif fallback then
        if target then
            target.left = nil
            target.top = nil
        end
        fallback()
    end
end

function UI.SetTooltip(button, text)
    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(unpack(UI.COLORS.buttonHover))
        self:SetBackdropBorderColor(unpack(UI.COLORS.buttonBorderHover))
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(text)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function(self)
        UI.SetButtonStateColor(self, self.visualState)
        GameTooltip:Hide()
    end)
    button:SetScript("OnMouseDown", function(self)
        self:SetBackdropColor(unpack(UI.COLORS.buttonDown))
    end)
    button:SetScript("OnMouseUp", function(self)
        self:SetBackdropColor(unpack(UI.COLORS.buttonHover))
    end)
end

function UI.CreateConfigToggle(parent, width)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, 18)
    button:SetNormalFontObject(GameFontNormalSmall)
    button:SetHighlightFontObject(GameFontHighlightSmall)
    UI.ApplyBackdrop(button, UI.COLORS.button, UI.COLORS.buttonBorder, 1)
    return button
end

function UI.SetConfigToggle(button, enabled, enabledText, disabledText, enabledColor, disabledColor)
    button:SetText(enabled and enabledText or disabledText)
    button:SetBackdropColor(unpack(enabled and enabledColor or disabledColor))
    button:SetBackdropBorderColor(unpack(enabled and UI.COLORS.buttonBorderHover or UI.COLORS.buttonBorder))
end
