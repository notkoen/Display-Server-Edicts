# Display Server Edicts
A CS:GO SourceMod plugin for displaying live server edict count. Useful for testing maps or monitoring the edict count on a map/server to check for possible edict limit crash.

**Note: It is suggested to set `sm_edict_display_enable` to `0` if you just want to have a plugin readily available to check for edicts via a command. Otherwise, set this convar to `1` if you want to actively monitor the edict count.**

*Compiled in SM 1.11.6881*

# Images
![Sample image on Aurora Tower (v6_8)](https://i.ibb.co/rQjHpqZ/image.png)
![Sample image on Visualizer (v1_2)](https://i.ibb.co/PxWXfg2/image.png)

# Credits and Thanks:
- Possession Server (PŠΣ™) and Games for Life Clan (GFL) for idea to create an edict display and checker
- [tilgep](https://steamcommunity.com/id/tilgep) for spotting bugs and giving fixes
- [Vauff](https://steamcommunity.com/id/Vauff), [Snowy](https://steamcommunity.com/id/SnowyWasHere), and [Luffaren](https://steamcommunity.com/id/LuffarenPer) for explaining and giving me information on how to count edicts properly instead of `GetEntityCount()`
- JoinedSenses#0001, Impact#9229, and uvvai#4094 for helping me with timers on the AlliedModders discord server

# Change Log
## 1.0
- Initial Commit
## 1.1
- Fix incorrect edict amount being reported by replacing `GetEdictCount()` with a separate function utilizing `IsValidEdict()`
- Added a cvar option to disable the display command and timer
- If `sm_edict_display_enable` is changed mid-game, plugin will now automatically start or stop the update timer
