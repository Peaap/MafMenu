MafMenu = MafMenu or {}
MafMenu.Minimap = MafMenu.Minimap or {}

local MinimapModule = MafMenu.Minimap
local UI = MafMenu.UI

function MinimapModule.Initialize(panel)
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

    local icon = minimapIcon:CreateTexture("minimapIcon_icon")
    icon:SetAllPoints(true)
    icon:SetTexture(UI.ADDON_PATH .. "Icons\\EC128")
end
