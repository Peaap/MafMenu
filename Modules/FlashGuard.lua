MafMenu = MafMenu or {}
MafMenu.FlashGuard = MafMenu.FlashGuard or {}

local FlashGuard = MafMenu.FlashGuard
local UI = MafMenu.UI

local function IsValidFlashFrame(frame)
    return frame
        and UI.IsValidNumber(frame.flashTimer)
        and UI.IsValidNumber(frame.flashDuration)
        and UI.IsValidNumber(frame.fadeInTime)
        and UI.IsValidNumber(frame.fadeOutTime)
end

local function ScrubFlashFrames()
    if not FLASHFRAMES then
        return
    end

    for index = table.getn(FLASHFRAMES), 1, -1 do
        local frame = FLASHFRAMES[index]
        if not IsValidFlashFrame(frame) then
            table.remove(FLASHFRAMES, index)
            if frame then
                frame.flashTimer = nil
                frame.flashDuration = nil
            end
            MafMenu:Debug("Removed invalid UIFrameFlash entry")
        end
    end
end

function FlashGuard.Install()
    if MafMenu_FlashGuardInstalled then
        return
    end
    MafMenu_FlashGuardInstalled = true

    if UIFrameFlash then
        local originalUIFrameFlash = UIFrameFlash
        UIFrameFlash = function(frame, fadeInTime, fadeOutTime, flashDuration, showWhenDone, flashInHoldTime, flashOutHoldTime, syncId)
            if not frame or not UI.IsValidNumber(fadeInTime) or not UI.IsValidNumber(fadeOutTime) or not UI.IsValidNumber(flashDuration) then
                MafMenu:Debug("Blocked invalid UIFrameFlash call")
                return
            end

            return originalUIFrameFlash(frame, fadeInTime, fadeOutTime, flashDuration, showWhenDone, flashInHoldTime, flashOutHoldTime, syncId)
        end
    end

    ScrubFlashFrames()

    local guard = CreateFrame("Frame")
    guard.elapsed = 0
    guard:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = self.elapsed + elapsed
        if self.elapsed >= 0.25 then
            self.elapsed = 0
            ScrubFlashFrames()
        end
    end)
end
