-- PikaJohnes main entry point
PikaJohnes = {};

-- Ensure saved vars exist
PikaJohnesDB = PikaJohnesDB or {};
PikaJohnesDB.panelPosition = PikaJohnesDB.panelPosition or {};

-- Initialize modules in dependency order
PIAlert:OnInitialize();
FocusRemind:Initialize();
Config:Initialize();

-- Create main frame for event handling
local mainFrame = CreateFrame("FRAME");
mainFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
mainFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");

mainFrame.frame = mainFrame;

-- Link FocusRemind to use this frame
FocusRemind.frame = mainFrame;
mainFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        FocusRemind:onPlayerEnteringWorld();
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local caster, spellId = ...;
        if caster == "player" and spellId == 10060 then
            PIAlert.state = "IDLE";
            PanelFrame:Hide();
        end;
end;
end);

-- Override PIAlert alert triggers to use PanelFrame
local originalCheck = PIAlert.CheckPIState;
PIAlert._origCheckPIState = function(self)
    self.state = "ALERT";
    PanelFrame:Show();
end;

-- Patch the manager's alert trigger
PIAlert.TriggerAlert = function()
    if PIAlert.state ~= "ALERT" then
        PIAlert.state = "ALERT";
        PanelFrame:Show();
    end;
end;

-- Print startup message
print("|cff4facfe[Pika-Johnes]|r |cffffff00Power Infusion Alert Addon loaded!|r");
print("|cff4facfe[Pika-Johnes]|r Use /pj preview to see the alert panel.");
print("|cff4facfe[Pika-Johnes]|r Use /pj status for current state.");
