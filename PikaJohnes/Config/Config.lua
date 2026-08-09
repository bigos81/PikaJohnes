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

function Config:CreateMenu()
    -- Add to SpellCheck tooltip or use a slash command
    -- Slash commands will be registered in main file
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
    end;
end

SlashCmdList["PIKAJOHNES"] = SlashCommand;
SLASH_PIKAJOHNES1 = "/pj";
SLASH_PIKAJOHNES2 = "/pikajohnes";

function Config:ShowConfigUI()
    -- Create a simple config frame
    local frame = CreateFrame("FRAME", "PikaJohnesConfigFrame", UIParent);
    frame:SetSize(300, 200);
    frame:SetPoint("TOPRIGHT", -50, -50);
    frame:EnableMouse(true);
    frame:SetMovable(true);
    frame:RegisterForDrag("LeftButton");
    frame:SetScript("OnDragStart", function(self) self:StartMoving(); end);
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); end);
    
    -- Background
    local bg = CreateFrame("FRAME", nil, frame);
    bg:SetAllPoints();
    bg:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 16,
    });
    bg:SetBackdropColor(0, 0, 0, 0.8);
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
    title:SetText("Pika-Johnes Config");
    title:SetPoint("TOP", 0, -10);
    
    -- Toggle: Remind Focus
    local remindFocusBtn = CreateFrame("CHECKBOX", nil, frame, "OptionsCheckButton");
    remindFocusBtn:SetPoint("LEFT", 20, -35);
    remindFocusBtn:SetScript("OnClick", function()
        PikaJohnesDB.remindFocus = not PikaJohnesDB.remindFocus;
    end);
    
    local remindFocusLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
    remindFocusLabel:SetPoint("LEFT", 45, -30);
    remindFocusLabel:SetText("Remind to focus on enter");
    
    -- Toggle: Announce PI Target
    local announceBtn = CreateFrame("CHECKBOX", nil, frame, "OptionsCheckButton");
    announceBtn:SetPoint("LEFT", 20, -65);
    announceBtn:SetScript("OnClick", function()
        PikaJohnesDB.announcePI = not PikaJohnesDB.announcePI;
    end);
    
    local announceLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
    announceLabel:SetPoint("LEFT", 45, -60);
    announceLabel:SetText("Announce PI target to group");
    
    -- Preview button
    local previewBtn = CreateFrame("BUTTON", nil, frame, "UIPanelButtonTemplate");
    previewBtn:SetSize(200, 22);
    previewBtn:SetPoint("BOTTOM", 0, 15);
    previewBtn:SetText("Preview Alert");
    previewBtn:SetScript("OnClick", function()
        PanelFrame.Preview();
    end);
    
    -- Close button
    local closeBtn = CreateFrame("BUTTON", nil, frame, "UIPanelButtonTemplate");
    closeBtn:SetSize(80, 22);
    closeBtn:SetPoint("BOTTOMRIGHT", -15, 15);
    closeBtn:SetText("Close");
    closeBtn:SetScript("OnClick", function()
        frame:Hide();
    end);
    
    -- Set checkbox states from saved vars
    remindFocusBtn:SetChecked(PikaJohnesDB.remindFocus ~= false);
    announceBtn:SetChecked(PikaJohnesDB.announcePI ~= false);
    
    frame:Show();
end

-- Expose globally
_G.Config = Config;
