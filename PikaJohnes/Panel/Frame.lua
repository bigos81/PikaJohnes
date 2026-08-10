local PI_SPELL_ID = 10060;

-- PanelFrame module: handles the alert panel UI
local PanelFrame = {};

-- Create the main frame — draggable (EnableMouse true for dragging)
local frame = CreateFrame("FRAME", "PikaJohnesPanelFrame", UIParent);
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 350);
frame:SetSize(48, 48);
frame:SetMovable(true);
frame:SetToplevel(true);
frame:SetFrameStrata("MEDIUM");
frame:EnableMouse(false);
frame:RegisterForDrag("LeftButton");

frame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and PanelFrame:IsUnlocked() then
        self:StartMoving();
    end;
end);

frame:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and PanelFrame:IsUnlocked() then
        self:StopMovingOrSizing();
        PanelFrame:SavePosition();
    end;
end);

-- PI icon texture
local iconTex = frame:CreateTexture(nil, "OVERLAY");
iconTex:SetAllPoints();
iconTex:SetTexture("Interface\\Icons\\spell_holy_powerinfusion");
iconTex:SetVertexColor(1, 0.82, 0);

-- "DRAG ME!" text label (always visible, centered on icon)
local dragText = frame:CreateFontString(nil, "OVERLAY");
dragText:SetPoint("CENTER", frame, "CENTER", 0, 0);
dragText:SetFont("Fonts\\FRIZQT__.ttf", 14, "OUTLINE");
dragText:SetText("DRAG ME!");

-- Create blinking animation (autocast glow pattern)
local animGroup = frame:CreateAnimationGroup();
animGroup:SetLooping("REPEAT");
local fadeIn = animGroup:CreateAnimation("Alpha");
fadeIn:SetDuration(1);
fadeIn:SetFromAlpha(0.2);
fadeIn:SetToAlpha(1);

local fadeOut = animGroup:CreateAnimation("Alpha");
fadeOut:SetDuration(1);
fadeOut:SetFromAlpha(1);
fadeOut:SetToAlpha(0.2);

-- Restore saved position from DB on load 
PikaJohnesDB = PikaJohnesDB or {};
local savedPos = PikaJohnesDB.panelPosition;
if savedPos then
    local p = savedPos.point or "CENTER";
    local rTo = savedPos.relativeTo or "UIParent";
    local rPoint = savedPos.relativePoint;
    local xO = savedPos.xOffset or 0;
    local yO = savedPos.yOffset or 0;
    frame:ClearAllPoints();
    frame:SetPoint(p, rTo, rPoint, xO, yO);
end;

-- Hide initially (defer RestorePosition until PikaJohnesDB exists)
frame:Hide();

-- Show the frame immediately (always visible for position, but icon hidden when locked)
frame:Show();
iconTex:Hide();

function PanelFrame:RestorePosition()
    local db = PikaJohnesDB and PikaJohnesDB.panelPosition;
    if not db then return end

    local p = db.point or "CENTER";
    local rTo = UIParent;
    local rPoint = nil;
    local xO = 0;
    local yO = 0;

    if db.relativeTo and db.relativeTo ~= "UIParent" then
        rTo = _G[db.relativeTo] or UIParent;
    end
    if db.relativePoint then
        rPoint = db.relativePoint;
    end
    xO = db.xOffset or 0;
    yO = db.yOffset or 0;

    frame:ClearAllPoints();
    frame:SetPoint(p, rTo, rPoint, xO, yO);
end

function PanelFrame:SavePosition()
    PikaJohnesDB = PikaJohnesDB or {};
    local p, rTo, rPoint, xO, yO = frame:GetPoint(1);
    
    if p then
        local points = {};
        points.point = p;
        
        if rTo and rTo ~= UIParent then
            points.relativeTo = rTo:GetName() or tostring(rTo);
        else
            points.relativeTo = "UIParent";
        end;
        
        points.relativePoint = rPoint;
        points.xOffset = xO;
        points.yOffset = yO;
        
        PikaJohnesDB.panelPosition = points;
    end;
end;

function PanelFrame:ResetPosition()
    PikaJohnesDB = PikaJohnesDB or {};
    PikaJohnesDB.panelPosition = nil;
    frame:ClearAllPoints();
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 220);
    PanelFrame:SavePosition();
end;

function PanelFrame:Lock()
    PikaJohnesDB = PikaJohnesDB or {};
    PikaJohnesDB.unlockFrame = false;
    
    -- Save position (works even when hidden)
    PanelFrame:SavePosition();
    -- Hide icon (animation handles the visual)
    iconTex:Hide();
    -- Hide drag text
    dragText:Hide();
    -- Start animation
    animGroup:Play();
    -- Disable mouse interaction
    frame:EnableMouse(false);
end;

function PanelFrame:Unlock()
    PikaJohnesDB = PikaJohnesDB or {};
    PikaJohnesDB.unlockFrame = true;
    
    -- Show the frame
    frame:Show();
    -- Show icon (static)
    iconTex:Show();
    -- Show drag text
    dragText:Show();
    -- Stop animation (static icon)
    animGroup:Stop();
    -- Enable mouse interaction
    frame:EnableMouse(true);
end;

function PanelFrame:IsUnlocked()
    return PikaJohnesDB and PikaJohnesDB.unlockFrame == true;
end;

-- Public API
PanelFrame = {
    frame = frame,

    Show = function()
        if PanelFrame:IsUnlocked() then return end;
        frame:Show();
        iconTex:Show();
        animGroup:Play();
        if Sound.Play then
            Sound.Play();
        end;
    end,

    Hide = function()
        if PanelFrame:IsUnlocked() then return end;
        frame:Hide();
        iconTex:Hide();
        animGroup:Stop();
    end,

    Preview = function()
        if PanelFrame:IsUnlocked() then return end;
        frame:Show();
        iconTex:Show();
        animGroup:Play();
        C_Timer.After(3.0, function()
            PanelFrame:Hide();
        end);
        if Sound.Play then
            Sound.Play();
        end;
    end,

    RestorePosition = PanelFrame.RestorePosition,
    ResetPosition = PanelFrame.ResetPosition,
    SavePosition = PanelFrame.SavePosition,
    Lock = PanelFrame.Lock,
    Unlock = PanelFrame.Unlock,
    IsUnlocked = PanelFrame.IsUnlocked,
};

-- Expose globally
_G.PanelFrame = PanelFrame;
