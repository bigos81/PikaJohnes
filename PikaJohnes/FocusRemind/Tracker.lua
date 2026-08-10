local FocusRemind = {};

-- Track state
FocusRemind.hasRemindedOnEnter = false;
FocusRemind.noFocusTimer = nil;
FocusRemind.noFocusCountdown = 0;
FocusRemind.lastFocusTime = nil;

function FocusRemind:Initialize()
    -- Create frame if not exists (must be called before event registration)
    if not self.frame then
        local frame = CreateFrame("FRAME", nil, UIParent);
        frame:SetScript("OnEvent", function(event, ...)
            FocusRemind:HandleEvent(event, ...);
        end);
        self.frame = frame;
    end
    
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
    -- Print reminder message
    DEFAULT_CHAT_FRAME:AddMessage("|cff4facfe[Pika-Johnes]|r |cffffff00Please focus a player for Power Infusion!", 1, 1, 1);
    
    -- Also play a distinct sound
    PlaySoundFile("Interface\\Addons\\PikaJohnes\\Sound\\telephone-ring.wav", "Master");
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
        
        local message = string.format("|cff4facfe[Pika-Johnes]|r PI target: %s%s|r", focusName or "Unknown", classColor or "");
        
    else
        -- No focus - announce we'll use on CD
        if self.lastFocusTime and (GetTime() - self.lastFocusTime) > 30 then
            DEFAULT_CHAT_FRAME:AddMessage("|cff4facfe[Pika-Johnes]|r Focus not selected for 30s. PI on cooldown on random player.", 1, 1, 1);
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff4facfe[Pika-Johnes]|r No focus target! Please set your focus!", 1, 1, 1);
        end;
    end;
end

-- Expose globally
_G.FocusRemind = FocusRemind;
