## Usage Licence:

 - The package of content, primarily including the script(s) [GSC/CSC/GSH], is the intellectual property of EliotDucky. It is limited to use for reference only therefore may not be included in a map or mod without permission; and may not be redistributed with or without modification.
 - This licence has potential to change following the release of my map containing this feature. Follow for updates.

## How it works:
- //

## Installation:
- Any file references can either be shared between maps/mods, or map specific
- Add the script(s) [GSC/CSC/GSH] to `scripts/zm/progressive_weapons`
- move the contents of `template_gamedata` to `gamedata`
- If using dog rounds, this requires the modification of the stock `_zm_ai_dogs` script to track kills on dogs, (install here)[]


## Game Setup:
- trigger_use
  - targetname: "prog_wallbuy"
  - script_int: [unique number corresponding to row in CSVs (0=row1)]
- prog_wallbuys.csv (gamadata/weapons/)
  - Each row corresponds to the script_int on the trigger use (0=row1)
  - List as many weapon names (using console name, e.g. smg_standard) horizontally
    - (one weapon per cell)
  - End this list with the code name of the perk you wish to use upon completion of this tier (see names in `Perk Codenames.txt`)
- prog_kills.csv (gamadata/weapons/)
  - Each row corresponds to the script_int on the trigger use (0=row1)
  - Each column corresponds to the tier of the wallbuys
  - The kills required to move on from tier 2 (onto tier 3) on the 4th (script_int 3) wallbuy trigger:
    - column: 2, row 4
  - There should be no kills in the cells corresponding to perks
- mapname.gsc:
  - In the using section, add:
    - `#using scripts\zm\progressive_weapons\zm_progressive_weapons;`
  - For each perk which can be obtained from a progressive wallbuy, add the function call:
    `prog_weapons::addPerkName(code_name, display_name);`
    - for example: `prog_weapons::addPerkName("specialty_deadshot", "Deadshot Daiquiri");`
- mapname.zone:
```php
//Progressive Wallbuys
scriptparsetree,scripts/zm/progressive_weapons/zm_progressive_weapons.gsc
scriptparsetree,scripts/zm/_zm_ai_dogs.gsc
stringtable,gamedata/weapons/zm/zm_levelcommon_weapons.csv
stringtable,gamedata/weapons/prog_wallbuys.csv
stringtable,gamedata/weapons/prog_kills.csv
```

## Further development to come:
- Easier control over which keybinds are used for scrolling
- Perk hintstrings without mapname.gsc setup of perks
