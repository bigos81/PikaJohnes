local FocusRemind = {};

-- Track state
FocusRemind.hasRemindedOnEnter = false;
FocusRemind.noFocusTimer = nil;
FocusRemind.noFocusCountdown = 0;
FocusRemind.lastFocusTime = nil;

function FocusRemind:CreateReminderFrame()
    if self.reminderFrame then
        return self.reminderFrame;
    end
    
    local frame = CreateFrame("FRAME", nil, UIParent);
    frame:SetSize(320, 40);
    frame:SetFrameStrata("MEDIUM");
    frame:SetFrameLevel(10);
    frame:EnableMouse(false);
    frame:SetClampedToScreen(true);
    
    -- Anchor: 50% from center to top of screen (750 from bottom on 1000px screen)
    frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 750);
    
    -- Background
    local bg = frame:CreateTexture(nil, "BACKGROUND");
    bg:SetAllPoints(frame);
    -- bg:SetTexture(0, 0, 0, 0.75);
    
    -- Inset border texture (visible border)
    local border = frame:CreateTexture(nil, "BORDER");
    border:SetBlendMode("ADD");
    -- border:SetTexture(0.3, 0.3, 0.3, 1);
    border:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2);
    border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2);
    
    -- Icon (Power Infusion)
    local icon = frame:CreateTexture(nil, "OVERLAY");
    icon:SetSize(28, 28);
    icon:SetPoint("LEFT", frame, "LEFT", 8, 0);
    icon:SetTexture("Interface\\Icons\\spell_holy_powerinfusion");
    icon:SetVertexColor(1, 0.82, 0);
    
    -- Reminder text
    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
    text:SetPoint("LEFT", icon, "RIGHT", 6, 0);
    text:SetPoint("RIGHT", frame, "RIGHT", -8, 0);
    text:SetJustifyH("LEFT");
    text:SetNonSpaceWrap(true);
    text:SetWordWrap(true);
    text:SetHeight(36);
    
    
    self.reminderFrame = frame;
    self.reminderBg = bg;
    self.reminderBorder = border;
    self.reminderIcon = icon;
    self.reminderText = text;
    
    return frame;
end

function FocusRemind:SetReminderText(msg)
    if not self.reminderFrame then
        self:CreateReminderFrame();
    end
    self.reminderText:SetText(msg);
end

function FocusRemind:ShowReminder()
    if not self.reminderFrame then
        self:CreateReminderFrame();
    end
    self.reminderFrame:Show();
end

function FocusRemind:HideReminder()
    if self.reminderFrame then
        self.reminderFrame:Hide();
    end
end

function FocusRemind:Initialize()
    -- Create frame if not exists (must be called before event registration)
    if not self.frame then
        local frame = CreateFrame("FRAME", nil, UIParent);
        frame:SetScript("OnEvent", function(event, ...)
            FocusRemind:HandleEvent(event, ...);
        end);
        self.frame = frame;
    end
    
    self:CreateReminderFrame();
    self.reminderFrame:Hide();
    
    self.hasRemindedOnEnter = false;
    self.noFocusTimer = nil;
    self.noFocusCountdown = 0;
    self.lastFocusTime = nil;
    
    -- Register for events
    self.frame:RegisterEvent("PLAYER_ENTERING_WORLD");
    self.frame:RegisterEvent("PLAYER_FOCUS_CHANGED");

end

function FocusRemind:HandleEvent(event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        self:onPlayerEnteringWorld();
    elseif event == "PLAYER_FOCUS_CHANGED" then
        self.lastFocusTime = GetTime();
        
        if self.noFocusCountdown > 0 then
            self.noFocusCountdown = 0;
        end;
        
        -- Hide reminder when focus is set
        if UnitExists("focus") then
            self:HideReminder();
        end;
    end;
end

function FocusRemind:onPlayerEnteringWorld()
    -- Check if we're in an instance
    local isInInstance, instanceType = IsInInstance();
    
    -- Only remind for dungeons (mythic+) and raids
    if not isInInstance or (instanceType ~= "party" and instanceType ~= "raid") then
        return;
    end
    
    -- Check if focus exists
    if UnitExists("focus") then
        self.hasRemindedOnEnter = true;
        return;
    end
    
    -- No focus - remind player
    if not PikaJohnesDB or not PikaJohnesDB.remindFocus then
        return;
    end
    
    self:SendReminder();
end

function FocusRemind:SendReminder()
    -- Show reminder in floating frame
    self:SetReminderText("[Pika-Johnes] Please focus a player for Power Infusion!");
    self:ShowReminder();
   
end

function FocusRemind:AnnouncePIFocus()
    local isInInstance, instanceType = IsInInstance();
    if not isInInstance then
        return;
    end
    
    -- Determine chat channel based on group type
    local chatCmd = (instanceType == "raid") and "/raid" or "/party";
    
    if UnitExists("focus") then
        local focusName = UnitName("focus");
        local focusClass = UnitClass("focus");
        local classColor;
        
        if focusClass then
            local color = RAID_CLASS_COLORS[strupper(focusClass)];
            if color then
                classColor = "|c" .. color.colorStr;
            end;
        end;
        
        local message = string.format("PI target: %s%s|r", focusName or "Unknown", classColor or "");
        self:SetReminderText("[Pika-Johnes] " .. message);
        self:ShowReminder();
        
        C_Timer.After(5.0, function()
            self:HideReminder();
        end);
        
    else
        -- No focus - announce we'll use on CD
        local message = "";
        if self.lastFocusTime and (GetTime() - self.lastFocusTime) > 30 then
            message = "Focus not selected for 30s. PI on cooldown on random player.";
        else
            message = "No focus target! Please set your focus!";
        end;
        self:SetReminderText("[Pika-Johnes] " .. message);
        self:ShowReminder();
        
        C_Timer.After(5.0, function()
            self:HideReminder();
        end);
    end;
end

-- Expose globally
_G.FocusRemind = FocusRemind;
