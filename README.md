<div align="center"><img width="500" alt="pikajohnes" src="https://github.com/user-attachments/assets/c6d0e4ec-c9a6-4f20-bfc5-902596d66eab" /></div>  

# What is it?
PikaJohnes is a World of Warcraft addon to help priests cast Power Infusion in optimal timing. The optimal timing is when your teammate uses their own DPS coodldowns.

Back in the day a Weak Aura existed called "Dibs on Power Infusion". My goal is to recreate at least part of its functionality after 12.0 addon changes.

# PikaJohnes - why this name?
Well, it's something that was on my mind for a long time. Roughly ... it's: Power Infusion Kombat Asistance (PIKA) and Johnes is just for fun. I won't judge you if you hate that name :)

# How does it work?
The assumption is that you will focus your DPS. This is required as it's possible to monitor successful spell casts on your Focus target even during combat.

When focused, the addon checks for major DPS cooldowns, and if the cooldown is used by the player and the priest had PI off cooldown the alert goes off: an icon is shown and a telephone ring sound is being played. Yep, you are being asked to PI your focus! This is how it looks like in game:

<div align="center"><img width="500" alt="image" src="https://github.com/user-attachments/assets/2b3c47e8-dc1b-4262-a2c3-146147122e73" /></div>

It's here to best get a macro going:
```
#showtooltip Power Infusion
/cast [@focus][] Power Infusion
```
This will cast PI on your current focus without changing your current target, if no focus is provided it will be cast on yourself - choosing DPS in random manner.

Or more sophisticated:
```
#showtooltip
/cast [@focus,exists,help,nodead] Power Infusion
/cast [target=mouseover,exists] Power Infusion
/cast Power Infusion
```
Casts on focus, if focus is dead or not existent checks for your mouse-over, if that's not present it casts it on yourself.


The addon also reminds you to put on focus when zoning to dungeon or raid and when ready check is issued and you have no one on focus. Additionally, the addon announces your PI target (your focus) when ready check is issued and you have a focus already. Here's how reminder text looks like (it's currently blinking):

<div align="center"><img width="500" alt="image" src="https://github.com/user-attachments/assets/87bd6029-e1a5-457d-9e9d-a66c44fbbfab" /></div>

# What can be configured?
At this point you can:
- Turn focus reminders on/off
- Turn sound of alert on/off
- Turn announcing on/off
- Change the place where the PI Alert icon is shown

All options accessible though in-game Options->Addons.

# Limitations
The interesting part. It's not all sunshine and rainbows. The biggest issue is that monitoring PI cooldown (your own) is actually not that straightforward in combat or during encounter. This requires the addon to monitor your casts, and if you successfully cast PI yourself, the 2 minute timer is set. Only after this timer is done, the addon will start monitoring focused player spells again. 

This mechanism can fail if you will /reload or disconnect during encounter/combat. The addon will try to read the PI cooldown information whenever it's not secret to recover, but disconnecting or reloading during combat may result in false-positive alerts.

# Is the addon done?
Far from it. It's in Proof of Concept stage and will undergo testing by myself. I'm hesitant on publishing the addon in this state on WOW addon pages as of now, but you are free to use the sources if you are brave enough :) There is probably still some PoC leftover code inside. But the addon works and I've decided to start commiting the code to github rather than local repo only.

# I'd like to thank you for this work
Great! You can write me a nice private message or if you feel generous you can buy me a coffe using the button below.
(NOTE: only donate if you DO HAVE spare income, I don't live of my GitHub donations, so it's really just a coffe for me)

[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/black_img.png)](https://www.buymeacoffee.com/bigos81)
