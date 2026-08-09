# Pika-Johnes — Agent Instructions

WoW 12.1 addon that alerts a Priest when to cast Power Infusion (PI) on their focus target.

## TOC & Build

- `## Interface: 120100` — numeric format, **not** dotted (`12.1.0`)
- Sound files must be `.ogg`, not `.wav`
- Directory is lowercase `sound/` (not `Sound/`)
- TOC file: `PikaJohnes.toc`

## 12.1 API — Aura Checking

Use **only** `C_UnitAuras.GetAuraDataBySpellId(unit, spellID)` for friendly unit aura queries during combat. Index-based `UnitAura()` is deprecated for this purpose in 12.1. No fallback code needed.

```lua
-- Correct (12.1)
local aura = C_UnitAuras.GetAuraDataBySpellId("focus", spellId)
if aura and aura.spellId == spellId then
    -- aura is active on focus
end

-- Wrong: UnitAura index iteration or name-based lookup for cooldown detection
```

`UnitClass(unit)` returns two values — use `select(2, ...)` to get the English class key ("PRIEST", "MAGE").

## PI Spell ID

`10060` — Power Infusion. Always hardcoded in `PIAlert/Manager.lua`.

## Checking Priest's Own PI on Focus

When verifying PI was cast by *this* priest (not another player), check `auraData.caster == "player"`:

```lua
local aura = C_UnitAuras.GetAuraDataBySpellId("focus", 10060)
if aura and aura.caster == "player" then
    -- Priest cast PI on focus target
end
```

## Class Cooldown Table

`PIAlert/Manager.lua:11-65` — spell IDs for DRUID/HUNTER/MAGE/PALADIN/PRIEST/ROGUE/WARRIOR are populated. WARLOCK, MONK, DEATHKNIGHT, EVOKER are **placeholders** (empty arrays) and trigger permissively on any buff until filled.

## Module Structure

| Path | Responsibility |
|---|---|
| `PIAlert/Manager.lua` | PI cooldown polling, aura checking, state machine (IDLE/WAITING/ALERT) |
| `FocusRemind/Tracker.lua` | Focus reminders on instance enter, 30s countdown, /party or /raid announcements |
| `Panel/Frame.lua` | Glowing alert panel UI, draggable, animation |
| `sound/sound.lua` | Audio playback (`PlaySoundFile`) |
| `Config/Config.lua` | Slash commands `/pj`, `/pikajohnes`, config UI |
| `PikaJohnes.lua` | Main entry, event routing, module initialization |

## State Machine (PIAlert)

```
IDLE → (PI ready + focus has cooldown) → ALERT
WAITING → (focus gains cooldown) → ALERT
ALERT → (PI on CD or cast) → IDLE
```

Panel auto-shows/hides with state transitions. `Sound.Play()` fires on ALERT entry.

## Slash Commands

- `/pj preview` — show panel + play sound for 3 seconds
- `/pj status` — print current state, PI readiness, focus target
- `/pj announce` — announce PI focus to party/raid
- `/pj config` — open configuration UI

## Spell IDs to Fill (TODO)

WARLOCK, MONK, DEATHKNIGHT, EVOKER entries in `PIAlert/classCooldowns` need real spell IDs.
