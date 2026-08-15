local PI_SPELL_ID = 10060;

local PIAlert = {};
PIAlert.state = "IDLE"; -- IDLE | WAITING | ALERT
PIAlert.lastCheckTime = 0;
PIAlert.pollInterval = 1.0;
PIAlert.cooldownStart = nil;
PIAlert.alertEnteredTime = 0;
PIAlert.piIsReady = true;
PIAlert.pendingPiTimer = nil;

-- Frame to listen for PI cast event for cooldown tracking in combat or during event (e.g., Mythic+)
local piCastFrame = CreateFrame("FRAME");
piCastFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
piCastFrame:SetScript("OnEvent", function(self, event, caster, spellId)
    if caster == "focus" then
        print("FOCUS: UNIT_SPELLCAST_SUCCEEDED", event, caster, spellId);
    end
    if event == "UNIT_SPELLCAST_SUCCEEDED" and caster == "player" and string.find(tostring(spellId), "10060") then
        PIAlert.piIsReady = false;
        PIAlert.pendingPiTimer = C_Timer.NewTimer(120, function()
            PIAlert.piIsReady = true;
            PIAlert.pendingPiTimer = nil;
        end);
    end;
end);

-- Spell IDs for each class major cooldowns (HARMFUL auras on friendly targets)
-- Format: [classKey] = {spellIds}
PIAlert.classCooldowns = {
    ["DRUID"] = {
        194223,  -- Celestial alignment (Balance)
        106951,  -- Berserk (Feral)
    },
    ["HUNTER"] = {
        19574,  -- Bestial Wrath (Beast Mastery)
        288613, -- Trueshot (Marksmanship)
        1250646, -- Takedown (Survival)
    },
    ["MAGE"] = {
        365350, -- Arcane Surge (Arcane)
        190319,  -- Combustion (Fire)
        26297, -- Berserking (Frost)
        1236994, -- Potion of Recklessness (Frost)
    },
    ["PALADIN"] = {
        31884, -- Avenging Wrath
    },
    ["ROGUE"] = {
        121471, -- Shadow Blades (Subtlety)
        315508, -- Roll the Bones (Outlaw)
        1856, -- Vanish (Assassination)
    },
    ["WARRIOR"] = {
        107574, -- Avatar
        1719,   -- Recklessness
    },
    ["WARLOCK"] = {
        205180,  -- Summon Darkglare (Affliction)
        265187,  -- Summon Demonic Tyrant (Demonology)
        1122,     -- Summon Infernal (Destruction)
    },
    ["MONK"] = {
        1249625,  -- Zenith (Windwalker)
    },
    ["DEATHKNIGHT"] = {
        1249658,  -- Breath of Sindragosa
        42650,  -- Army of the Dead (Unholy)
    },
    ["EVOKER"] = {
        375087,  -- Dream Breath (Devastation)
    },
    ["SHAMAN"] = {
        114050,  -- Ascendance (Elemental)
        114051,  -- Ascendance (Enhancement)
        114052,  -- Ascendance (Restoration)
    },
    ["DEMON_HUNTER"] = {
        162264,  -- Metamorphosis (Havoc)
        1217607,  -- Void Metamorphosis (Devourer)
    },
};

-- PI spell ID lookup map for quick checking
PIAlert.allCooldownSpells = {};
for classKey, spells in pairs(PIAlert.classCooldowns) do
    for _, spellId in ipairs(spells) do
        PIAlert.allCooldownSpells[spellId] = true;
    end
end

function PIAlert:OnInitialize()
    self.state = "IDLE";
    self.cooldownStart = nil;
    self.alertEnteredTime = 0;
    self.piIsReady = true;
    PIAlert.pendingPiTimer = nil;
    
    -- Initial check
    self:CheckPIState();
end

function PIAlert:CheckPIState()
    -- if out of combat, we can use C_Spell.GetSpellCooldown to check if PI is ready
    if not UnitAffectingCombat("player") then
        local cdInfo = C_Spell.GetSpellCooldown(PI_SPELL_ID);
        if issecretvalue(cdInfo.duration) then
            C_Timer.After(self.pollInterval, function()
            self:CheckPIState();
            end);
            return;
        end
        if cdInfo.duration == 0 then
            PIAlert.piIsReady = true;
            if PIAlert.pendingPiTimer then
                PIAlert.pendingPiTimer:Cancel();
                PIAlert.pendingPiTimer = nil;
            end;
        elseif self.state == "WAITING" or self.state == "ALERT" then
            self.state = "IDLE";
            PanelFrame:Hide();
        end
        C_Timer.After(self.pollInterval, function()
            self:CheckPIState();
        end);
        return;
    end
    
    local isReady = PIAlert.piIsReady;
    
    if self.state == "IDLE" and isReady then
        -- Check focus for cooldowns first before entering WAITING
        if self:HasCooldownOnFocus() then
            self.state = "ALERT";
            self.alertEnteredTime = GetTime();
            PanelFrame:Show();
            Sound.Play();
        else
            self.state = "WAITING";
            self.alertEnteredTime = 0;
        end
    elseif self.state == "WAITING" and isReady then
        -- Check if focus now has a cooldown active
        if not UnitExists("focus") then
            -- Focus lost, go back to IDLE
            self.state = "IDLE";
            self.alertEnteredTime = 0;
        elseif self:HasCooldownOnFocus() then
            self.state = "ALERT";
            self.alertEnteredTime = GetTime();
            PanelFrame:Show();
            Sound.Play();
        end
    elseif self.state == "WAITING" and not isReady then
        self.state = "IDLE";
        self.alertEnteredTime = 0;
        PanelFrame:Hide();
    elseif self.state == "ALERT" and not isReady then
        -- PI was cast, go to IDLE (player used PI)
        self.state = "IDLE";
        PanelFrame:Hide();
    elseif self.state == "ALERT" and GetTime() - self.alertEnteredTime >= 5 then
        -- 5 seconds elapsed, dismiss alert
        self.state = "IDLE";
        PanelFrame:Hide();
    end
    
    PIAlert.cooldownStart = nil;
    
    -- Schedule next check
    C_Timer.After(self.pollInterval, function()
        self:CheckPIState();
    end);
end

function PIAlert:GetFocusedClass()
    if not UnitExists("focus") then
        return nil;
    end
    
    -- UnitClass returns (className, localizedClassName) where className is English key like "PRIEST"
    local classKey = select(2, UnitClass("focus"));
    
    -- In 12.1, UnitClass may return secret values during combat/encounters/M+
    -- We use strupper to ensure uppercase comparison works
    if classKey then
        return strupper(classKey);
    end
    
    return nil;
end

-- Use C_UnitAuras.GetAuraDataBySpellId for 12.1 API compatibility
-- This works during combat when auras are "secret" (index-based queries don't)
function PIAlert:GetFocusBuffs()
    if not UnitExists("focus") then
        return {};
    end
    
    local buffs = {};
    
    -- Query each known cooldown spell by ID using C_UnitAuras.GetAuraDataBySpellId (12.1 API)
    for classKey, spells in pairs(PIAlert.classCooldowns) do
        for _, spellId in ipairs(spells) do
            if C_UnitAuras and C_UnitAuras.GetAuraDataBySpellId then
                local auraData = C_UnitAuras.GetAuraDataBySpellId("focus", spellId);
                if auraData and auraData.spellId == spellId then
                    buffs[spellId] = {
                        name = auraData.name,
                        icon = auraData.iconFileId,
                        duration = auraData.duration,
                        expires = auraData.expirationTime,
                        caster = auraData.caster,
                    };
                end;
            end;
        end;
    end;
    
    return buffs;
end

function PIAlert:HasCooldownOnFocus()
    local focusClass = self:GetFocusedClass();
    if not focusClass then
        return false;
    end
    
    -- Priests PI themselves, so skip them entirely (like healers/tanks)
    if focusClass == "PRIEST" then
        return false;
    end
    
    -- Get class-specific cooldowns
    local relevantSpells = PIAlert.classCooldowns[focusClass];
    
    -- If no spells defined yet (placeholder), trigger on ANY buff to be permissive
    if not relevantSpells or #relevantSpells == 0 then
        return true;
    end
    
    -- Check each spell ID against focus buffs using C_UnitAuras.GetAuraDataBySpellId (12.1 API)
    for _, spellId in ipairs(relevantSpells) do
        if C_UnitAuras and C_UnitAuras.GetAuraDataBySpellId then
            local auraData = C_UnitAuras.GetAuraDataBySpellId("focus", spellId);
            if auraData and auraData.spellId == spellId then
                return true;
            end;
        end;
    end;
    
    return false;
end

function PIAlert:IsPIReady()
    return PIAlert.piIsReady;
end

-- Expose to global namespace (PikaJohnes.lua calls OnInitialize)
_G.PIAlert = PIAlert;
