MafMenu = MafMenu or {}
MafMenu.Playerbots = MafMenu.Playerbots or {}

local Playerbots = MafMenu.Playerbots
local Profile = MafMenu.Profile

local function GetSaved()
    return Profile.Refresh().playerbots
end

local function SendServerCommand(command)
    if command and command ~= "" then
        SendChatMessage(command)
    end
end

local function SendPartyCommand(command)
    if command and command ~= "" then
        if GetNumRaidMembers and GetNumRaidMembers() > 0 then
            SendChatMessage(command, "RAID")
        elseif GetNumPartyMembers and GetNumPartyMembers() > 0 then
            SendChatMessage(command, "PARTY")
        else
            SendChatMessage(command, "SAY")
        end
    end
end

local function SendWhisperCommand(command)
    local target = GetSaved().whisperTarget
    if command and command ~= "" and target and target ~= "" then
        SendChatMessage(command, "WHISPER", nil, target)
    else
        MafMenu:PrintMessage("Set a bot whisper target first.")
    end
end

function Playerbots.AddBots()
    local names = GetSaved().botNames
    if names and names ~= "" then
        SendServerCommand(".playerbots bot add " .. names)
    else
        MafMenu:PrintMessage("Set bot names first.")
    end
end

function Playerbots.RemoveBots()
    local names = GetSaved().botNames
    if names and names ~= "" then
        SendServerCommand(".playerbots bot remove " .. names)
    else
        MafMenu:PrintMessage("Set bot names first.")
    end
end

function Playerbots.AddAccount()
    local account = GetSaved().accountName
    if account and account ~= "" then
        SendServerCommand(".playerbots bot addaccount " .. account)
    else
        MafMenu:PrintMessage("Set an account name first.")
    end
end

function Playerbots.AddClass()
    local className = GetSaved().className
    if className and className ~= "" then
        SendServerCommand(".playerbots bot addclass " .. className)
    else
        MafMenu:PrintMessage("Set a class name first.")
    end
end

function Playerbots.Party(command)
    SendPartyCommand(command)
end

function Playerbots.Whisper(command)
    SendWhisperCommand(command)
end

function Playerbots.Disperse()
    SendPartyCommand("disperse set " .. tostring(GetSaved().disperseDistance))
end

function Playerbots.Custom()
    local command = GetSaved().customCommand
    if command and command ~= "" then
        SendPartyCommand(command)
    else
        MafMenu:PrintMessage("Set a custom Playerbots command first.")
    end
end
