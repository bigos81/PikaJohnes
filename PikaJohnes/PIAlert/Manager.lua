local PI_SPELL_ID = 10060
local GRACE_PERIOD_SECONDS = 3 -- Grace period after a tracked spell is cast on focus before we alert for PI

local PIAlert = {}
PIAlert.state = "IDLE" -- IDLE | WAITING | ALERT
PIAlert.pollInterval = 1.0
PIAlert.alertEnteredTime = 0
PIAlert.piIsReady = true
PIAlert.pendingPiTimer = nil
PIAlert.recentlyCast = {} -- spellId -> timestamp, tracks focus casts of our tracked spells

local function ExtractSpellIdFromCastLine(castLine)
    castLine = tostring(castLine)
    if not string.find(castLine, "Cast-") then return nil end
    local _, _, _, _,_, foundSpellStr = strsplit("-", castLine)
    return tonumber(foundSpellStr)
end

-- Frame to listen for PI cast event for cooldown tracking in combat or during event (e.g., Mythic+)
local piCastFrame = CreateFrame("FRAME")
piCastFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
piCastFrame:SetScript("OnEvent", function(self, event, caster, spellId)
    if event == "UNIT_SPELLCAST_SUCCEEDED" and caster == "focus" then
        local foundSpellId = ExtractSpellIdFromCastLine(spellId)
        for trackedSpellId in pairs(PIAlert.allCooldownSpells) do
            if tonumber(trackedSpellId) == foundSpellId then
                PIAlert.recentlyCast[trackedSpellId] = GetTime()
                break
            end
        end
    end
    if event == "UNIT_SPELLCAST_SUCCEEDED" and caster == "player" then
        local playerSpellId = ExtractSpellIdFromCastLine(spellId)
        if playerSpellId == PI_SPELL_ID then
            PIAlert.piIsReady = false
            PIAlert.pendingPiTimer = C_Timer.NewTimer(120 - GRACE_PERIOD_SECONDS, function()
                PIAlert.piIsReady = true
                PIAlert.pendingPiTimer = nil
            end)
        end
    end
end)

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
        84714, -- Frozen Orb (Frost)
    },
    ["PALADIN"] = {
        31884, -- Avenging Wrath
    },
    ["ROGUE"] = {
        121471, -- Shadow Blades (Subtlety)
        315508, -- Roll the Bones (Outlaw)
        360194, -- Death Mark (Assassination)
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
    ["PRIEST"] = {
        228260,  -- Voidform (Shadow)
--        32379,  -- Shadow word Death (Shadow) -- debug for follower dungeons
    },
}

-- PI spell ID lookup map for quick checking
PIAlert.allCooldownSpells = {}
for classKey, spells in pairs(PIAlert.classCooldowns) do
    for _, spellId in ipairs(spells) do
        PIAlert.allCooldownSpells[spellId] = true
    end
end

function PIAlert:OnInitialize()
    self.state = "IDLE"
    self.alertEnteredTime = 0
    self.piIsReady = true
    PIAlert.pendingPiTimer = nil
    
    -- Initial check
    self:CheckPIState()
end

function PIAlert:CheckPIState()
    -- if out of combat, we can use C_Spell.GetSpellCooldown to check if PI is ready
    if not UnitAffectingCombat("player") then
        local cdInfo = C_Spell.GetSpellCooldown(PI_SPELL_ID)
        if not issecretvalue(cdInfo.duration) then
            if cdInfo.duration == 0 then
                PIAlert.piIsReady = true
                if PIAlert.pendingPiTimer then
                    PIAlert.pendingPiTimer:Cancel()
                    PIAlert.pendingPiTimer = nil
                end
            else
                PIAlert.piIsReady = false
                if not PIAlert.pendingPiTimer and cdInfo.duration then
                    local dur = 1
                    if cdInfo.duration > GRACE_PERIOD_SECONDS then
                        dur = cdInfo.duration
                    end
                    PIAlert.pendingPiTimer = C_Timer.NewTimer(dur, function()
                        PIAlert.piIsReady = true
                        PIAlert.pendingPiTimer = nil
                    end)
                end
            end
            C_Timer.After(self.pollInterval, function()
                self:CheckPIState()
            end)
            return
        end
    end
    
    local isReady = PIAlert.piIsReady
    
    if self.state == "IDLE" and isReady then
        -- Check focus for relevant casts and enter WAITING state
        local focusClass = self:GetFocusedClass()
        local hasCooldownAura = PIAlert.classCooldowns[focusClass] ~= nil
        
        if not UnitExists("focus") then
            -- No valid focus, stay IDLE
            C_Timer.After(self.pollInterval, function() self:CheckPIState() end)
            return
        elseif hasCooldownAura then
            -- Focus has tracked cooldowns, enter WAITING for cast detection
            PIAlert.recentlyCast = {} -- clear stale entries on state transition
            self.state = "WAITING"
            self.alertEnteredTime = 0
        else
            self.state = "WAITING"
            self.alertEnteredTime = 0
        end
    elseif self.state == "WAITING" and isReady then
        -- Check if focus cast one of our tracked spells (UNIT_SPELLCAST_SUCCEEDED)
        if not UnitExists("focus") then
            -- Focus lost, go back to IDLE
            PIAlert.recentlyCast = {}
            self.state = "IDLE"
            self.alertEnteredTime = 0
        elseif self:HasCooldownOnFocus() then
            -- Focus cast a tracked spell, alert immediately
            self.state = "ALERT"
            self.alertEnteredTime = GetTime()
            PanelFrame:Show()
            Sound.Play()
        end
    elseif self.state == "WAITING" and not isReady then
        PIAlert.recentlyCast = {}
        self.state = "IDLE"
        self.alertEnteredTime = 0
        PanelFrame:Hide()
    elseif self.state == "ALERT" and not isReady then
        -- PI was cast, go to IDLE (player used PI)
        self.state = "IDLE"
        PanelFrame:Hide()
    elseif self.state == "ALERT" and GetTime() - self.alertEnteredTime >= 5 then
        -- 5 seconds elapsed, dismiss alert
        self.state = "IDLE"
        PanelFrame:Hide()
    end
    
    -- Schedule next check
    C_Timer.After(self.pollInterval, function()
        self:CheckPIState()
    end)
end

function PIAlert:GetFocusedClass()
    if not UnitExists("focus") then
        return nil
    end
    
    -- UnitClass returns (className, localizedClassName) where className is English key like "PRIEST"
    local classKey = select(2, UnitClass("focus"))
    
    -- In 12.1, UnitClass may return secret values during combat/encounters/M+
    -- We use strupper to ensure uppercase comparison works
    if classKey then
        return strupper(classKey)
    end
    
    return nil
end

function PIAlert:HasCooldownOnFocus()
    local focusClass = self:GetFocusedClass()
    if not focusClass then
        return false
    end
    
    -- Check if any of our tracked cooldown spells were recently cast by focus
    for spellId in pairs(PIAlert.allCooldownSpells) do
        if PIAlert.recentlyCast[spellId] and (GetTime() - PIAlert.recentlyCast[spellId]) < 10 then
            return true
        end
    end
    
    return false
end

function PIAlert:IsPIReady()
    return PIAlert.piIsReady
end

-- Expose to global namespace (PikaJohnes.lua calls OnInitialize)
_G.PIAlert = PIAlert
