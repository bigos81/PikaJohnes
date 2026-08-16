-- PikaJohnes main entry point
local _, player_class = UnitClass("player")
if player_class ~= "PRIEST" then
    print("Pika-Johnes is a Priest exclusive addon, no point in loading it for " .. player_class)
    return
end

PikaJohnes = {}

-- Ensure saved vars exist
PikaJohnesDB = PikaJohnesDB or {}
PikaJohnesDB.panelPosition = PikaJohnesDB.panelPosition or {}

-- Initialize modules in dependency order
PIAlert:OnInitialize()
FocusRemind:Initialize()
Config:Initialize()

-- Register with Blizzard Settings panel (follows BetterNSTTS ADDON_LOADED pattern)
local settingsFrame = CreateFrame("FRAME")
settingsFrame:RegisterEvent("ADDON_LOADED")
settingsFrame:SetScript("OnEvent", function(self, event, name)
    if name == "PikaJohnes" and Settings and Settings.RegisterVerticalLayoutCategory then
        Config:BuildSettingsPanel()
    end
end)

-- Restore saved panel position
PanelFrame:RestorePosition()

-- Print startup message
print("|cff4facfe[Pika-Johnes]|r |cffffff00Power Infusion Alert Addon loaded!|r")
print("|cff4facfe[Pika-Johnes]|r Use /pj preview to see the alert panel.")
print("|cff4facfe[Pika-Johnes]|r Use /pj status for current state.")
