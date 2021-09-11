## Usage Licence:

 - The package of content, primarily including the script(s) [GSC/CSC/GSH], is the intellectual property of EliotDucky. It is limited to use for reference only therefore may not be included in a map or mod without permission; and may not be redistributed with or without modification.
 - This licence has potential to change following the release of my map containing this feature. Follow for updates.

## How it works:
This section will describe this script's application to Celerium, a zombies level in development myself, that has progressive wallbuy weapons as a core feature.

- Around the level there are five main wallbuy locations but no mystery box.
- Like a standard zombie level, as the player progresses through buyable blockers - doors and debris - the buyable weapons are more powerful and expensive.
- However, Celerium's wallbuys have tiers of weapons to progress through. Tiers are advanced by getting kills with the current weapon at a wallbuy. Once all tiers on a wallbuy have been progressed through, a bonus perk-a-cola is unlocked for free.
- The perk that becomes unlocked at this wallbuy is shown at the trigger so that the player knows what they're working towards.

![Tier 1 on a Progressive Wallbuy, showing Deadshot as the reward perk](https://github.com/EliotDucky/progressive_weapons/blob/main/Tier1.png)

- The hintstring presented to the player when approaching the wallbuy has three lines.
 - The top line describes the weapon available, with the standard highlighting of the activate key or gamepad button, and the weapon name highlighted in blue for clarity amongst the quantity of information shown. The weapon cost is highlighted in red as are the costs on the other lines. Once the player becomes familiar with this top line, the colours aid the quick digestion of this info: Button, Weapon Name, Cost.
- The second line states the cost for ammunition for both the standard weapon and upgraded variant obtained through the pack-a-punch machine.
- The third line communicates how many kills are required from the weapon before the next tier of weapon at this location is available for purchase.

```c
hs1 = "Press ^3[{+activate}]^7 for ^5" +_name+ "^7 Cost: ^1" +wpn_cost+ "^7 ";
hs2 = "\n Ammo Cost: ^1 " +ammo_cost+ "^7 Upgraded Ammo ^1" +up_ammo_cost+ "^7 ";
hs3 = "\n Total Kills For Next Tier: ^1" +self.kills_rem+ "^7 ";
self.trig SetHintString(hs1+hs2+hs3);
```

- This is the very simple setup of what was just described. The hintstring is updated each time the wallbuy tiers up.
- The activate term is standard for being replaced with that platform's activate button - F, square, X, or whichever binding the player has it mapped to.
- The numbers following the chevrons provide the colour to the text, where `^7` takes it back to default white.
- The `\n` denotes that a new line of text should be started.
- To understand how the values of each of the variables - name, costs, and kills remaining - are determined, the struct setup must be explained.

### Struct Setup

| Property | Description |
|-----:|:-------|
| names     | Ordered array of weapon console names                                 |
| weapons   | Ordered array of weapon objects                                       |
| loc       | Unique integer representing the location of this wallbuy              |
| kills_req | Array of number of required kills for each tier on the current weapon |
| trig      | The trigger where this prog weapon is bought                          |
| kills_rem | Number of kills remaining on the current tier                         |
| tier      | Number of the current tier on this progressive wallbuy                |
| max_tier  | The tier at which a perk is unlocked                                  |

- A struct allows multiple properties to be stored on it, much like a class in object oriented programming.
- Most functions are called on this struct, meaning that, for example, the kills required for the wallbuy can be accused by `self.kills_req`.

***

- With this understood, how the values of the aforementioned variables are determined can be explained.
- The costs are found from interacting with Treyarch's `zm_weapons` script which encapsulates the logic and calculation for us. All that is needed is the weapon to pass through - this is stored on the `self.weapons` array at the same index as the value of the current tier. This means that the weapon costs and properties for the level can be set up in the standard way.

```c
self.kills_rem = Int(self.kills_req[self.tier]);
wpn_cost = zm_weapons::get_weapon_cost(self.weapons[self.tier]);
ammo_cost = zm_weapons::get_ammo_cost(self.weapons[self.tier]);
up_ammo_cost =  zm_weapons::get_upgraded_ammo_cost(self.weapons[self.tier]);
_name = self.weapons[self.tier].displayname;
_name = MakeLocalizedString(_name);
```

- In case one or more of these are not defined for the weapon elsewhere in the map's setup - for example if a level is being rapidly prototyped - defaults are set before these values are read in the hintstring.

```c
if(!isdefined(self.kills_rem))
 self.kills_rem = 20;
if(!isdefined(wpn_cost))
 wpn_cost = 2000;
if(!isdefined(ammo_cost))
 ammo_cost = wpn_cost/2;
if(!isdefined(up_ammo_cost))
 up_ammo_cost = 4500;
if(!isdefined(_name))
 _name = "Misc.";
```

- To track the weapon kills, a function tracking this is added to callbacks for the zombies and dogs encountered as the AI enemies in Celerium. The dog AI script does not natively support death event callbacks in Black Ops III, so the zombie callback was used as a template to add this additional functionality to [`zm_ai_dogs`](https://github.com/EliotDucky/zm_ai_dogs).




## Installation:
- Any file references can either be shared between maps/mods, or map specific
- Add the script(s) [GSC/CSC/GSH] to `scripts/zm/progressive_weapons`
- move the contents of `template_gamedata` to `gamedata`
- If using dog rounds, this requires the modification of the stock `_zm_ai_dogs` script to track kills on dogs, [install here]( https://github.com/EliotDucky/zm_ai_dogs )

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
