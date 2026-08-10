local PI_SPELL_ID = 10060;

-- PanelFrame module: handles the alert panel UI
local PanelFrame = {};

-- Create the main frame — click-through (EnableMouse false)
local frame = CreateFrame("FRAME", "PikaJohnesPanelFrame", UIParent);
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 150);
frame:SetSize(48, 48);
frame:SetToplevel(true);
frame:SetFrameStrata("MEDIUM");
frame:EnableMouse(false); -- click-through overlay

-- PI icon texture
local iconTex = frame:CreateTexture(nil, "OVERLAY");
iconTex:SetAllPoints();
iconTex:SetTexture("Interface\\Icons\\spell_holy_powerinfusion");
iconTex:SetVertexColor(1, 0.82, 0);
iconTex:SetAlpha(0);

-- Hide initially (defer RestorePosition until PikaJohnesDB exists)
frame:Hide();

function PanelFrame:RestorePosition()
    local db = PikaJohnesDB and PikaJohnesDB.panelPosition;
    if not db then return end

    local point = db.point or "CENTER";
    local relativeTo = UIParent;
    local relativePoint = nil;
    local xOfs = 0;
    local yOfs = 0;

    if db.relativeTo and db.relativeTo ~= "UIParent" then
        relativeTo = _G[db.relativeTo] or UIParent;
    end
    if db.relativePoint then
        relativePoint = db.relativePoint;
    end
    xOfs = db.xOffset or 0;
    yOfs = db.yOffset or 0;

    frame:ClearAllPoints();
    frame:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs);
end

function PanelFrame:ResetPosition()
    PikaJohnesDB = PikaJohnesDB or {};
    PikaJohnesDB.panelPosition = nil;
    frame:ClearAllPoints();
    frame:SetPoint("CENTER");
end

-- Public API
PanelFrame = {
    frame = frame,

    Show = function()
        frame:Show();
        iconTex:SetAlpha(0);
        C_Timer.After(0.5, function()
            iconTex:SetAlpha(1);
        end);
        C_Timer.After(2.5, function()
            iconTex:SetAlpha(0);
        end);
        C_Timer.After(3.5, function()
            frame:Hide();
        end);
        if Sound.Play then
            Sound.Play();
        end;
    end,

    Hide = function()
        frame:Hide();
    end,

    Preview = function()
        frame:Show();
        iconTex:SetAlpha(0);
        C_Timer.After(0.5, function()
            iconTex:SetAlpha(1);
        end);
        C_Timer.After(2.5, function()
            iconTex:SetAlpha(0);
        end);
        C_Timer.After(3.5, function()
            frame:Hide();
        end);
        if Sound.Play then
            Sound.Play();
        end;
    end,

    RestorePosition = PanelFrame.RestorePosition,
    ResetPosition = PanelFrame.ResetPosition,
};

-- Expose globally
_G.PanelFrame = PanelFrame;
