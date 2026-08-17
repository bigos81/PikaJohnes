local _, player_class = UnitClass("player")
if player_class ~= "PRIEST" then
    return
end

local REMINDER_DURATION = 10
local FocusRemind = {}

function FocusRemind:CreateReminderFrame()
    if self.reminderFrame then
        return self.reminderFrame
    end
    
    local frame = CreateFrame("FRAME", "REMINDER_FRAME", UIParent)
    frame:SetSize(800, 40)
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(10)
    frame:EnableMouse(false)
    frame:SetClampedToScreen(true)
    
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 250)
    
    -- Background
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(frame)
    
    -- Inset border texture (visible border)
    local border = frame:CreateTexture(nil, "BORDER")
    border:SetBlendMode("ADD")
    border:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
    border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
    
    -- Icon (Power Infusion)
    local icon = frame:CreateTexture(nil, "OVERLAY")
    icon:SetSize(28, 28)
    icon:SetPoint("LEFT", frame, "LEFT", 8, 0)
    icon:SetTexture("Interface\\Icons\\spell_holy_powerinfusion")
    icon:SetVertexColor(1, 0.82, 0)
    
    -- Reminder text
    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    text:SetTextHeight(26)
    text:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    text:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
    text:SetJustifyH("LEFT")
    text:SetNonSpaceWrap(true)
    text:SetWordWrap(true)
    text:SetHeight(52)
    local anim = text:CreateAnimationGroup()
    anim:SetLooping("BOUNCE")
    local fadeOut = anim:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(0.5)
    fadeOut:SetOrder(1)

    local fadeIn = anim:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(0.5)
    fadeIn:SetOrder(2)

    anim:Play()
    
    
    self.reminderFrame = frame
    self.reminderBg = bg
    self.reminderBorder = border
    self.reminderIcon = icon
    self.reminderText = text
    
    return frame
end

function FocusRemind:SetReminderText(msg)
    if not self.reminderFrame then
        self:CreateReminderFrame()
    end
    self.reminderText:SetText(msg)
end

function FocusRemind:ShowReminder()
    if not self.reminderFrame then
        self:CreateReminderFrame()
    end
    self.reminderFrame:Show()
    C_Timer.After(REMINDER_DURATION, function()
        self:HideReminder()
    end)
end

function FocusRemind:HideReminder()
    if self.reminderFrame then
        self.reminderFrame:Hide()
    end
end

function FocusRemind:Initialize()
   
    self.frame = self:CreateReminderFrame()
    self.frame:SetScript("OnEvent", function(self, event, ...)
        FocusRemind:HandleEvent(event, ...)
    end)
    self.reminderFrame:Hide()
    
    -- Register for events
    self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.frame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    self.frame:RegisterEvent("READY_CHECK")

end

function FocusRemind:HandleEvent(event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        self:onPlayerEnteringWorld()
    elseif event == "PLAYER_FOCUS_CHANGED" then
        -- Hide reminder when focus is set
        if UnitExists("focus") then
            self:HideReminder()
        end
    elseif event == "READY_CHECK" then
        -- Answer the ready check and announce PI focus if we have focus

        if UnitExists("focus") then
            self:AnnouncePIFocus()
        else
            self:SendReminder()
        end
    end
end

function FocusRemind:onPlayerEnteringWorld()
    -- Check if we're in an instance
    local isInInstance, instanceType = IsInInstance()
    
    -- Only remind for dungeons (mythic+) and raids
    if not isInInstance or (instanceType ~= "party" and instanceType ~= "raid") then
        return
    end
    
    -- Check if focus exists
    if UnitExists("focus") then
        return
    end
    
    -- No focus - remind player
    if not PikaJohnesDB or not PikaJohnesDB.remindFocus then
        return
    end
    
    self:SendReminder()
end

function FocusRemind:SendReminder()
    -- Show reminder in floating frame
    self:SetReminderText("[PikaJohnes] Please focus a player for Power Infusion!")
    self:ShowReminder()
   
end

function FocusRemind:AnnouncePIFocus()
    local isInInstance, instanceType = IsInInstance()
    if not isInInstance then
        -- return
    end
    
    -- Determine chat channel based on group type
    local chatType = (instanceType == "raid") and "RAID" or "PARTY"
    
    if UnitExists("focus") then
        local focusName = UnitName("focus")

        local message = string.format("[PikaJohnes] PI targeting: %s", focusName or "Unknown")
        C_ChatInfo.SendChatMessage(message, chatType)
    end
end

-- Expose globally
_G.FocusRemind = FocusRemind
