local Config = {};

-- Default config
Config.defaults = {
    remindFocus = true,       -- Remind to focus on instance entry
    announcePI = true,        -- Announce PI target to party/raid
    soundEnabled = true,      -- Enable/disable sounds
};

function Config:Initialize()
    PikaJohnesDB = PikaJohnesDB or {};

    -- Merge defaults
    for key, value in pairs(self.defaults) do
        if PikaJohnesDB[key] == nil then
            PikaJohnesDB[key] = value;
        end;
    end;
end

-- Slash command handler
local function SlashCommand(msg)
    msg = strlower(msg or "");

    if msg == "preview" then
        PanelFrame.Preview();
    elseif msg == "config" then
        Config:ShowConfigUI();
    elseif msg == "announce" then
        FocusRemind:AnnouncePIFocus();
    elseif msg == "status" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff4facfe[Pika-Johnes]|r State: " .. (PIAlert.state or "unknown"));
        DEFAULT_CHAT_FRAME:AddMessage("|cff4facfe[Pika-Johnes]|r PI Ready: " .. tostring(PIAlert:IsPIMastered()));
        DEFAULT_CHAT_FRAME:AddMessage("|cff4facfe[Pika-Johnes]|r Focus: " .. (UnitExists("focus") and UnitName("focus") or "none"));
        DEFAULT_CHAT_FRAME:AddMessage("|cff4facfe[Pika-Johnes]|r RemindFocus: " .. tostring(PikaJohnesDB.remindFocus));
        DEFAULT_CHAT_FRAME:AddMessage("|cff4facfe[Pika-Johnes]|r AnnouncePI: " .. tostring(PikaJohnesDB.announcePI));
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff4facfe[Pika-Johnes]|r Available commands: /pj preview, /pj status, /pj announce, /pj config");
    end;
end

SlashCmdList["PIKAJOHNES"] = SlashCommand;
SLASH_PIKAJOHNES1 = "/pj";
SLASH_PIKAJOHNES2 = "/pikajohnes";

-- Blizzard Settings panel integration (follows BetterNSTTS pattern)
function Config:BuildSettingsPanel()
    local category = Settings.RegisterVerticalLayoutCategory("PikaJohnes");

    -- Register settings so they persist to PikaJohnesDB
    local remindFocusSetting = Settings.RegisterAddOnSetting(
        category, "remindFocus", "remindFocus",
        PikaJohnesDB, Settings.VarType.Boolean,
        "Remind to focus on enter", true);
    Settings.CreateCheckbox(category, remindFocusSetting, "Reminds you to set a focus target when entering an instance.");

    local announcePISetting = Settings.RegisterAddOnSetting(
        category, "announcePI", "announcePI",
        PikaJohnesDB, Settings.VarType.Boolean,
        "Announce PI target to group", true);
    Settings.CreateCheckbox(category, announcePISetting, "Sends a chat message announcing your PI focus target to party/raid.");

    local soundEnabledSetting = Settings.RegisterAddOnSetting(
        category, "soundEnabled", "soundEnabled",
        PikaJohnesDB, Settings.VarType.Boolean,
        "Play alert sound", true);
    Settings.CreateCheckbox(category, soundEnabledSetting, "Enables or disables the audio alert when PI is ready.");

    -- Preview button
    local previewBtn = CreateSettingsButtonInitializer(
        "", "Preview Alert", function()
            PanelFrame.Preview();
        end, "Shows the alert panel and plays the sound for 3 seconds", false, nil, nil);

    -- Reset panel position button
    local resetPosBtn = CreateSettingsButtonInitializer(
        "", "Reset Panel Position", function()
            PanelFrame:ResetPosition();
        end, "Resets the alert panel to center screen", false, nil, nil);

    local layout = SettingsPanel:GetLayout(category);
    layout:AddInitializer(previewBtn);
    layout:AddInitializer(resetPosBtn);

    Settings.RegisterAddOnCategory(category);
end

function Config:ShowConfigUI()
    Settings.OpenToCategory(Settings.GetCategory("PikaJohnes").key);
end

-- Expose globally
_G.Config = Config;
