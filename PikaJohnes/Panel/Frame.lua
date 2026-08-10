local PI_SPELL_ID = 10060;

-- PanelFrame module: handles the glowing alert panel UI
local PanelFrame = {};

-- Create the main frame
local frame = CreateFrame("FRAME", "PikaJohnesPanelFrame", UIParent);
frame:SetSize(256, 256);
frame:SetPoint("CENTER");
frame:SetToplevel(true);

-- Make it draggable
frame:EnableMouse(true);
frame:SetMovable(true);
frame:RegisterForDrag("LeftButton");
frame:SetScript("OnDragStart", function(self)
    self:StartMoving();
end);
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing();
    
    -- Save position
    local db = PikaJohnesDB and PikaJohnesDB.panelPosition;
    if not db then
        PikaJohnesDB = PikaJohnesDB or {};
        db = PikaJohnesDB.panelPosition or {};
        PikaJohnesDB.panelPosition = db;
    end
    
    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint();
    db.point = point;
    db.relativeTo = relativeTo and relativePoint == "FRAME" and nil or (relativeTo and tostring(relativeTo) or "UIParent");
    db.relativePoint = relativePoint;
    db.xOffset = xOfs;
    db.yOffset = yOfs;
end);

-- Background with glow effect using textures instead of SetBackdrop
local bg = CreateFrame("FRAME", nil, frame);
bg:SetAllPoints();
bg:SetFrameLevel(0);

-- Use texture layers for background (replaces SetBackdrop)
local bgTex = bg:CreateTexture(nil, "BACKGROUND");
bgTex:SetAllPoints();
bgTex:SetColorTexture(0, 0, 0, 0.8);

-- Border overlay
local borderTex = CreateFrame("FRAME", nil, frame);
borderTex:SetAllPoints();
borderTex:SetFrameLevel(1);
borderTex.bgTex = borderTex:CreateTexture(nil, "BACKGROUND");
borderTex.bgTex:SetAllPoints();
borderTex.bgTex:SetColorTexture(1, 0.82, 0, 1);

-- PI Spell Icon button
local icon = CreateFrame("BUTTON", nil, frame);
icon:SetSize(128, 128);
icon:SetPoint("CENTER");
icon:RegisterForClicks("LeftButtonUp", "RightButtonUp");
icon:SetNormalTexture("Interface\\Icons\\spell_holy_powerinfusion");
local normalTex = icon:GetNormalTexture();
normalTex:SetAllPoints();

-- Spell ID tooltip on hover
icon:RegisterEvent("UPDATE_MOUSEOVER_UNIT");
icon:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT", -50, 0);
    GameTooltip:SetText("Power Infusion", 1, 1, 1);
    GameTooltip:AddLine("Click to cast on focus target");
    GameTooltip:Show();
end);
icon:SetScript("OnLeave", function(self)
    GameTooltip:Hide();
end);

-- Outer glow overlay with separate animation
local outerGlow = CreateFrame("FRAME", nil, frame);
outerGlow:SetAllPoints();
outerGlow:SetFrameLevel(2);
outerGlow.bgTex = outerGlow:CreateTexture(nil, "BACKGROUND");
outerGlow.bgTex:SetAllPoints();
outerGlow.bgTex:SetColorTexture(1, 0.82, 0, 0);

-- Glow animation (alpha pulse) on bg frame
local glowAnimGroup = bg:CreateAnimationGroup();
local glowAlpha = glowAnimGroup:CreateAnimation("Alpha");
glowAlpha:SetDuration(0.5);
glowAlpha:SetFromAlpha(1);
glowAlpha:SetToAlpha(0.4);
glowAnimGroup:SetLooping("REPEAT");

-- Outer glow animation on outerGlow frame
local outerAnimGroup = outerGlow:CreateAnimationGroup();
local outerAlpha = outerAnimGroup:CreateAnimation("Alpha");
outerAlpha:SetDuration(0.75);
outerAlpha:SetFromAlpha(0);
outerAlpha:SetToAlpha(0.6);
outerAnimGroup:SetLooping("REPEAT");

-- "PI" text label below icon
local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge");
label:SetPoint("BOTTOM", 0, -10);
label:SetText("PI!");
label:SetFontObject("GameFontHighlightLarge");
label:SetTextColor(1, 0.82, 0);
label:SetShadowColor(0, 0, 0);
label:SetShadowOffset(2, 2);

-- Hide initially (defer RestorePosition until PikaJohnesDB exists)
frame:Hide();

-- Public API
PanelFrame = {
    frame = frame,
    
    Show = function()
        frame:Show();
        glowAnimGroup:Play();
        outerAnimGroup:Play();
        
        -- Play sound
        if Sound.Play then
            Sound.Play();
        end;
    end,
    
    Hide = function()
        frame:Hide();
        glowAnimGroup:Stop();
        outerAnimGroup:Stop();
    end,
    
    Preview = function()
        frame:Show();
        glowAnimGroup:Play();
        outerAnimGroup:Play();
        
        -- Play sound once during preview
        if Sound.Play then
            Sound.Play();
        end;
        
        -- Auto-hide after 3 seconds for preview
        C_Timer.After(3, function()
            frame:Hide();
            glowAnimGroup:Stop();
            outerAnimGroup:Stop();
        end);
    end,
};

-- Expose globally
_G.PanelFrame = PanelFrame;
