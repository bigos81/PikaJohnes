local PI_SPELL_ID = 10060;

local PIAlert = {};
PIAlert.state = "IDLE"; -- IDLE | WAITING | ALERT
PIAlert.lastCheckTime = 0;
PIAlert.pollInterval = 1.0;
PIAlert.cooldownStart = nil;

-- Spell IDs for each class major cooldowns (HARMFUL auras on friendly targets)
-- Format: [classKey] = {spellIds}
PIAlert.classCooldowns = {
    ["DRUID"] = {
        194223,  -- Celestial alignment (Balance)
        106951,  -- Berserk (Feral)
    },
    ["HUNTER"] = {
        -- Aspect of the Wild, Barrage, Ascendance
        193530,  -- Aspect of the Wild (Beast Mastery)
        288613, -- Trueshot (Marksmanship)
        266779, -- Coordinated Aspect (Survival)
    },
    ["MAGE"] = {
        -- Shatter (Frost), Combustion (Fire), Archmage's Power (Arcane)
        365350, -- Arcane Surge (Arcane)
        190319,  -- Combustion (Fire)
        12472, -- Icy Veins (Frost)
    },
    ["PALADIN"] = {
        -- Avenging Wrath (Retribution)
        31884, -- Avenging Wrath
    },
    ["ROGUE"] = {
        -- Shadow Dance, Adrenaline Rush
        360194, -- Deathmark (Subtlety)
        13750, -- Adrenaline Rush (Outlaw)
        121471, -- Shadow Blades (Assassination)
    },
    ["WARRIOR"] = {
        -- Bladestorm (Arms/Fury), Bloodbath, Recklessness
        167105,  -- Colossus Smash (Arms)
        1719,   -- Recklessness
    },
    ["WARLOCK"] = {
        205180,  -- Summon Darkglare (Affliction)
        265187,  -- Summon Demonic Tyrant (Demonology)
        1122,     -- Summon Infernal (Destruction)
    },
    ["MONK"] = {
        137639,  -- Storm, Earth, and Fire (Windwalker)
    },
    ["DEATHKNIGHT"] = {
        51271,  -- Pillar of Frost (Frost)
        275699,  -- Apocalypse (Unholy)
    },
    ["EVOKER"] = {
        375087,  -- Dream Breath (Devastation)
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
    
    -- Initial check
    self:CheckPIState();
end

function PIAlert:CheckPIState()
    local start, duration, enabled = GetSpellCooldown(PI_SPELL_ID);
    local isReady = (start == 0 or start == nil) and enabled ~= false;
    
    if self.state == "IDLE" and isReady then
        -- Check focus for cooldowns first before entering WAITING
        if self:HasCooldownOnFocus() then
            self.state = "ALERT";
            PanelFrame:Show();
            Sound.Play();
        else
            self.state = "WAITING";
        end
    elseif self.state == "WAITING" and isReady then
        -- Check if focus now has a cooldown active
        if not UnitExists("focus") then
            -- Focus lost, go back to IDLE
            self.state = "IDLE";
        elseif self:HasCooldownOnFocus() then
            self.state = "ALERT";
            PanelFrame:Show();
            Sound.Play();
        end
    elseif self.state == "WAITING" and not isReady then
        self.state = "IDLE";
        PanelFrame:Hide();
    elseif self.state == "ALERT" and not isReady then
        -- PI was cast or went on CD while alerting
        self.state = "IDLE";
        PanelFrame:Hide();
    end
    
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
        local auraData = C_UnitAuras.GetAuraDataBySpellId("focus", spellId);
        if auraData and auraData.spellId == spellId then
            return true;
        end;
    end;
    
    return false;
end

function PIAlert:HasPIOnFocus()
    -- Check if Power Infusion is active on the focus target (cast by player)
    if not UnitExists("focus") then
        return false;
    end
    
    -- Use C_UnitAuras.GetAuraDataBySpellId (12.1 API) to check PI on focus
    local auraData = C_UnitAuras.GetAuraDataBySpellId("focus", PI_SPELL_ID);
    if auraData then
        -- Verify caster is the player (not another priest who cast PI on focus)
        return auraData.caster == "player" or auraData.caster == nil;
    end;
    
    return false;
end

function PIAlert:IsPIOnFocus()
    -- Alias for clarity - checks if priest's PI is on focus target
    return self:HasPIOnFocus();
end

function PIAlert:IsPIMastered()
    local start, duration, enabled = GetSpellCooldown(PI_SPELL_ID);
    return (start == 0 or start == nil) and enabled ~= false;
end

-- Expose to global namespace
PIAlert:OnInitialize();
_G.PIAlert = PIAlert;
