## How it works:
This section will describe this script's application to Celerium, a zombies level in development myself, that has progressive wallbuy weapons as a core feature.

- Around the level there are five main wallbuy locations but no mystery box.
- Like a standard zombie level, as the player progresses through buyable blockers - doors and debris - the buyable weapons are more powerful and expensive.
- However, Celerium's wallbuys have tiers of weapons to progress through. Tiers are advanced by getting kills with the current weapon at a wallbuy. Once all tiers on a wallbuy have been progressed through, a bonus perk-a-cola is unlocked for free.
- The perk that becomes unlocked at this wallbuy is shown at the trigger so that the player knows what they're working towards.

![Tier 1 on a Progressive Wallbuy, showing Deadshot as the reward perk](https://github.com/EliotDucky/progressive_weapons/blob/main/readme_images/Tier1.png)

- The hintstring presented to the player when approaching the wallbuy has three lines.
 - The top line describes the weapon available, with the standard highlighting of the activate key or gamepad button, and the weapon name highlighted in blue for clarity amongst the quantity of information shown. The weapon cost is highlighted in red as are the costs on the other lines. Once the player becomes familiar with this top line, the colours aid the quick digestion of this info: Button, Weapon Name, Cost.
- The second line states the cost for ammunition for both the standard weapon and upgraded variant obtained through the pack-a-punch machine.
- The third line communicates how many kills are required from the weapon before the next tier of weapon at this location is available for purchase.

```gsc
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
| model 		| The `script_model` representing the current weapon 										|
| delta     | The vector to move the current displaying model by in the buy station |

- A struct allows multiple properties to be stored on it, much like a class in object oriented programming.
- Most functions are called on this struct, meaning that, for example, the kills required for the wallbuy can be accused by `self.kills_req`.

***

- With this understood, how the values of the aforementioned variables are determined can be explained.
- The costs are found from interacting with Treyarch's `zm_weapons` script which encapsulates the logic and calculation for us. All that is needed is the weapon to pass through - this is stored on the `self.weapons` array at the same index as the value of the current tier. This means that the weapon costs and properties for the level can be set up in the standard way.

```gsc
self.kills_rem = Int(self.kills_req[self.tier]);
wpn_cost = zm_weapons::get_weapon_cost(self.weapons[self.tier]);
ammo_cost = zm_weapons::get_ammo_cost(self.weapons[self.tier]);
up_ammo_cost =  zm_weapons::get_upgraded_ammo_cost(self.weapons[self.tier]);
_name = self.weapons[self.tier].displayname;
_name = MakeLocalizedString(_name);
```

- The localisation function obtains the display name for the weapon depending on the player's language.
- In case one or more of these are not defined for the weapon elsewhere in the map's setup - for example if a level is being rapidly prototyped - defaults are set before these values are read in the hintstring.

```gsc
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

![Getting kills with a progressive wallbuy weapon in Celerium](https://github.com/EliotDucky/progressive_weapons/blob/main/readme_images/Kills.png)

- To track the weapon kills, a function tracking this is added to callbacks for the zombies and dogs encountered as the AI enemies in Celerium. The dog AI script does not natively support death event callbacks in Black Ops III, so the zombie callback was used as a template to add this additional functionality to [`zm_ai_dogs`](https://github.com/EliotDucky/zm_ai_dogs).

```gsc
//Called On: Dead Enemy
function trackProgWpnKills(player){
	if(isdefined(self)){
		for(i=0; i<level.prog_weapons.size; i++){
			wpn_struct = level.prog_weapons[i];
			wpn = wpn_struct.weapons[wpn_struct.tier];
			dmg_wpn = self.damageWeapon;
			if(self.damageWeapon.inventorytype == "dwlefthand"){
                dmg_wpn = dmg_wpn.dualWieldWeapon;
			}

			counts = zm_weapons::get_base_weapon(dmg_wpn) === wpn;
			if(counts){
				level.prog_weapons[i].kills_rem--;
				IPrintLnBold(level.prog_weapons[i].kills_rem);
				if(wpn_struct.kills_rem <= 0){
					wpn_struct nextTier();
				}
			}
		}
	}
}
```

- The callback function checks the weapon used to kill the enemy against the weapon at the current tier on each of the progressive weapons wallbuys. This includes special handling for if it was a left hand weapon used as part of a dual wield and gets the base weapon in case an upgraded variant is used.
- The weapons that are progressed through and the kills required per weapon per wallbuy are defined in CSV files as described in the Game Setup Section below.
- Once enough kills with a weapon have been achieved, by one player or a combination of all, the hintstring progresses to the next weapon's information.

![A later tier on the same wallbuy](https://github.com/EliotDucky/progressive_weapons/blob/main/readme_images/Tier.png)

- Once all tiers are complete for a progressive wallbuy location, a perk-a-cola is unlocked that can be drank at any time provided that the player doesn't already have it.
- In Celerium, there a four perk-a-cola machines placed throughout the level. The perks available at the progressive wallbuys are specifically selected due to being auxiliary perks that a player is unlikely to purchase in place of a core perk or are too powerful to be unlocked at early rounds, such as Double Tap II.
- Notice how the wallbuy was started on round one and completely on round nine, and that's with focusing entirely on progressing that one single wallbuy. The progression time will vary with number of players and how many other utilities the player has to purchase instead of buying the next tier of weapon.

![Deadshot Daiquiri available at the wallbuy after completing all tiers](https://github.com/EliotDucky/progressive_weapons/blob/main/readme_images/PerkUnlocked.png)

- The third line of the hintstring is then changed from the kills required to progress to the next tier to the buttons to press to scroll through the weapons available. This allows the player to scroll back to any weapon if ammo is required or they want to repurchase it.
 - Like the activate button, the text changes to Dpad icons for controllers (Inventory Slot Up and Inventory Slot Down)
- Unlike before completing the wallbuy, the hintstring now updates independently for each player, depending on which weapon they scroll to.

![Scroll icons added to the completed wallbuy](https://github.com/EliotDucky/progressive_weapons/blob/main/readme_images/Scrolling.png)

- This is simply handled by modulo operations on the tier the player has the wallbuy hintstring showing.
- Modulo operations do not work on negative numbers however, so if the `prog_index` (`player.prog_indecies[self.loc]`) becomes negative after subtracting, it simply loops back to the index of the max tier - the perk reward.

```gsc
//Call On: level.prog_weapons[i] Struct
function checkActionSlots(player){
	if(player ActionSlotOneButtonPressed()){
		player.prog_indices[self.loc] ++;
		player.prog_indices[self.loc] %= (self.max_tier+1);
		self updatePlayerHintStr(player);
		wait(0.20);
	}else if(player ActionSlotTwoButtonPressed()){
		//player.prog_indices[self.loc] %= (self.max_tier+1);
		player.prog_indices[self.loc] --;
		if(player.prog_indices[self.loc] < 0){
			player.prog_indices[self.loc] = self.max_tier;
		}
		self updatePlayerHintStr(player);
		wait(0.20);
	}
}
```

- It is worth highlighting the complexity of checking whether a player can purchase the weapon or ammo at that time, as there's more to it than just whether the player has the points.
 - Firstly, it must be determined what the player is trying to purchase: the weapon itself, ammo, or upgraded ammo if they have the upgrade of the weapon.
  - This determines which function needs to be called to give the player what they want `give_func`. The cost requirement changes depending on which `give_func` is to be ran. Multiple checks and function calls could exist but can complicate logical error tracing so are just stored by reference and ran at the end of the code block to give only one cost check and function exit point.
 - Whether the player can buy it depends on what they're also doing at the same time, whether a perk is being drank, they're reviving someone, and doesn't have a deployable weapon out. This is handled in the `canBuy(cost)` function.
 - Communicating to the player whether this has recorded their input is important and so is following the standard for purchased utilites. The `denyPurchase(purchase_loc_)` function plays sound effects and voice over - using the universal system such that any character setup for any level will still work.

```gsc
function wpnBuyHandling(_wpn, p, cost, cost_ammo, cost_up_ammo){
	if(p zm_weapons::has_weapon_or_upgrade(_wpn)){
		to_charge = cost_ammo;
		give_func = &zm_weapons::ammo_give;
		if(p zm_weapons::has_upgrade(_wpn)){
			to_charge = cost_up_ammo;
			_wpn = zm_weapons::get_upgrade_weapon(_wpn);
		}
	}else{
			to_charge = cost;
			give_func = &zm_weapons::weapon_give;
			_vox = undefined;
		}
	if(p canBuy(to_charge)){
		p zm_score::minus_to_player_score(to_charge);
		zm_utility::play_sound_at_pos("purchase", self.trig.origin);
		if(isdefined(give_func)){
			p [[give_func]](_wpn);
		}

		wait(0.5);
	}else{
		p denyPurchase(self.trig.origin);
	}
}

//Call On: Player
function canBuy(cost){
	can_buy = self UseButtonPressed() && !self zm_utility::in_revive_trigger() && !(self.is_drinking);
	can_buy &= zm_utility::is_player_valid(self) && self zm_score::can_player_purchase(cost);
	can_buy &= !(isdefined(self.intermission) && self.intermission) && !self IsThrowingGrenade() && !self zm_utility::is_placeable_mine(self GetCurrentWeapon());
	
	return can_buy;
}

//Call On: Player
function denyPurchase(purchase_loc){
	zm_utility::play_sound_at_pos("no_purchase", purchase_loc);
	if ( isdefined( level.custom_generic_deny_vo_func ) )
	{
		self [[level.custom_generic_deny_vo_func]]();
	}
	else
	{
		self zm_audio::create_and_play_dialog( "general", "outofmoney" );
	}
}
```

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
  - For weapons to be moved in the buy station, a single function call corrects its position:
  	- for example `prog_weapons::registerWeaponDelta("gr_minigun_std", (-12.5, 0, 5.5))`
- APE:
	- Setup a preview model, with digital materials, for each weapon with the name `prog_wpn_[weapon_name]` without the `_zm` suffix


- mapname.zone:
```gsc
//Progressive Wallbuys
scriptparsetree,scripts/zm/progressive_weapons/zm_progressive_weapons.gsc
scriptparsetree,scripts/zm/_zm_ai_dogs.gsc
scriptparsetree,scripts/zm/_zm_powerups.gsc
scriptparsetree,scripts/zm/_zm_spawner.gsc
stringtable,gamedata/weapons/prog_wallbuys.csv
stringtable,gamedata/weapons/prog_kills.csv
```

## Usage Licence:

 - The package of content, primarily including the script(s) [GSC/CSC/GSH], is the intellectual property of EliotDucky. It is limited to use for reference only therefore may not be included in a map or mod without permission; and may not be redistributed with or without modification.
 - This licence has potential to change following the release of my map containing this feature. Follow for updates.

## Further development to come:
- Easier control over which keybinds are used for scrolling
- Perk hintstrings without mapname.gsc setup of perks
