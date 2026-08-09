local PI_SPELL_ID = 10060;

-- PanelFrame module: handles the glowing alert panel UI
local PanelFrame = {};

-- Create the main frame
local frame = CreateFrame("FRAME", "PikaJohnesPanelFrame", UIParent);
frame:SetSize(256, 256);
frame:SetPoint("CENTER");

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

-- Restore position from saved vars
local function RestorePosition()
    local db = PikaJohnesDB and PikaJohnesDB.panelPosition;
    if db then
        frame:SetPoint(db.point or "CENTER", UIParent, db.relativePoint or "CENTER", db.xOffset or 0, db.yOffset or 0);
    end
end

-- Background with glow effect
local bg = CreateFrame("FRAME", nil, frame);
bg:SetAllPoints();
bg:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\White8x8",
    tile = true,
    tileSize = 256,
    edgeSize = 4,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
});
bg:SetBackdropColor(0, 0, 0, 0.8);
bg:SetBackdropBorderColor(1, 0.82, 0, 1); -- golden border (PI color)

-- PI Spell Icon
local icon = CreateFrame("BUTTON", nil, frame);
icon:SetSize(128, 128);
icon:SetPoint("CENTER");
icon:RegisterForClicks("LeftButtonUp", "RightButtonUp");

-- Set the spell icon
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

-- Glow animation (alpha pulse)
local glowAnimGroup = bg:CreateAnimationGroup();
local glowAlpha = glowAnimGroup:CreateAnimation("Alpha");
glowAlpha:SetDuration(0.5);
glowAlpha:SetFromTo(1, 0.4);
glowAlpha:SetSmoothing("IN_OUT");
glowAnimGroup:SetLooping("REPEAT");

-- Outer glow overlay
local outerGlow = CreateFrame("FRAME", nil, frame);
outerGlow:SetAllPoints();
outerGlow:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    tile = true,
    tileSize = 64,
    edgeSize = 2,
});
outerGlow:SetBackdropColor(1, 0.82, 0, 0);
outerGlow:SetFrameLevel(frame:GetFrameLevel() + 1);

-- Glow animation for outer overlay
local outerAnimGroup = outerGlow:CreateAnimationGroup();
local outerAlpha = outerAnimGroup:CreateAnimation("Alpha");
outerAlpha:SetDuration(0.75);
outerAlpha:SetFromTo(0, 0.6);
outerAlpha:SetSmoothing("IN_OUT");
outerAnimGroup:SetLooping("REPEAT");

-- "PI" text label below icon
local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge");
label:SetPoint("BOTTOM", 0, -10);
label:SetText("PI!");
label:SetFontObject("GameFontHighlightLarge");
label:SetTextColor(1, 0.82, 0);
label:SetShadowColor(0, 0, 0);
label:SetShadowOffset(2, 2);

-- Hide initially
frame:Hide();
RestorePosition();

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
        RestorePosition();
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
