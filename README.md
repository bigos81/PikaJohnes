## What is it?
Pika-Johnes is a World of Warcraft addon to help priests cast Power Infusion in optimal timing. The optimal timing is when your teammate uses their own DPS coodldowns.

Back in the day a Weak Aura existed called "Dibs on Power Infusion". My goal is to recreate at least part of its functionality after 12.0 addon chanages.

## How does it work?
The assumption is that you will focus your DPS. This is reqired as it's possible to monitor successfull spell casts on your Focus target even during combat.

When focussed, the addon checks for major DPS cooldowns, and if the cooldown is used by the player and the priest had PI off cooldown the alert goes off: an icon is shown and a telephone ring sound is being played. Yep, you are being asked to PI your focus!

It's here to best get a macro going:
```
#showtooltip Power Infusion
/cast [@focus][] Power Infusion
```
This will cast PI on your current focus without changing your current target.

The addon also reminds you to put on focus when zoining to dungeon or raid and when ready check is issued and you have noone on focus. Additionally, the addon announces your PI target (your focus) when ready cehck is issued and you have a focus already.

## What can be configured?
At this point you can:
- Turn focus reminders on/off
- Turn sound of alert on/off
- Turn announcing on/off
- Change the place where the PI Alert icon is shown

## Limitations
The interesting part. It's not all sunshine and rainbows. The biggest issue is that monitoring PI cooldown (your own) is actually not that straightforward in combat or during encounter. This requires the addon to monitor your casts, and if you successfully cast PI yourself, the 2 minute timer is set. Only after this timer is done, the addon will start monitoring focused player spells again. 

This mechanism can fail if you will /reload or disconnect during encounter/combat. The addon will try to read the PI cooldown information whenever it's not secret to recover, but disconnecting or realoading during combat may result in false-positive alerts.

## Is the addon done?
Faar from it. It's in Proof of Concept stage and will undergo testing by myself. I'm hesitant on publishing the addon in this state on WOW addon pages as of now, but you are free to use the sources if you are brave enbough :)