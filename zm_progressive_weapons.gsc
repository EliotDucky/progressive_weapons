#using scripts\codescripts\struct;
#using scripts\shared\system_shared;
#using scripts\shared\array_shared;
#using scripts\shared\flag_shared;

#using scripts\zm\_zm_audio;
#using scripts\zm\_zm_spawner;
#using scripts\zm\_zm_ai_dogs;
#using scripts\zm\_zm_score;
#using scripts\zm\_zm_perks;
#using scripts\zm\_zm_powerups;
#using scripts\zm\_zm_score;
#using scripts\zm\_zm_weapons;
#using scripts\zm\_zm_utility;

#insert scripts\shared\shared.gsh;

#precache("model", "prog_wpn_perk_bottle");
#precache("eventstring", "zombie_notification");

#namespace prog_weapons;

REGISTER_SYSTEM("zm_progressive_weapons", &startup, undefined)

function startup(){

	//Check the kill weapon on an enemy death
	zm_spawner::register_zombie_death_event_callback(&trackProgWpnKills);
	if(isdefined(level.dog_rounds_enabled) && level.dog_rounds_enabled || isdefined(level.dogs_enabled) && level.dogs_enabled){
		zm_ai_dogs::register_dog_death_event_callback(&trackProgWpnKills);
	}
	//Instakill tracking
	level.check_for_instakill_override = &instakillWrapper;

	//The weapon structs
	level.prog_weapons = [];

	weapon_names = generateArraysFromCSV("gamedata/weapons/prog_wallbuys.csv");

	//The number of kills required for each tier of each wallbuy
	prog_kills_req = generateArraysFromCSV("gamedata/weapons/prog_kills.csv");

	//All of the wallbuy triggers
	prog_trigs = [];
	unsorted_locs = GetEntArray("prog_wallbuy", "targetname");
	prog_trigs = orderStructs(unsorted_locs);

	//Set Remaining Kills Array, Gives remaining kills for each wallbuy, whichever tier it is on
	remaining_kills = [];

	//Setup of actual structs
	for(i=0; i<weapon_names.size && isdefined(prog_trigs[i]); i++){
		wpn = SpawnStruct();
		wpn.tier = -1;
		wpn.max_tier = weapon_names[i].size-1;
		wpn.names = [];
		wpn.names = weapon_names[i];
		wpn.loc = i;
		wpn.kills_req = [];
		wpn.kills_req = prog_kills_req[i];
		wpn.trig = prog_trigs[i];
		wpn.trig SetCursorHint("HINT_NOICON");
		wpn.trig SetHintString("");
		wpn.perk = weapon_names[i][wpn.max_tier];
		wpn.weapons = [];
		model_loc = GetEnt(prog_trigs[i].target, "targetname");
		if(isdefined(model_loc)){
			wpn.model = Spawn("script_model", model_loc.origin);
			wpn.model.angles = model_loc.angles;
			wpn.model SetModel("tag_origin");
		}
		for(j=0; j<wpn.max_tier; j++){
			wpn.weapons[j] = GetWeapon(wpn.names[j]);
		}
		wpn.kills_rem = -1;
		wpn.delta = (0, 0, 0);
		level.prog_weapons[i] = wpn;
	}
	wait(0.05);
	level flag::wait_till("initial_blackscreen_passed");
	foreach(wpn in level.prog_weapons){
		wpn nextTier();
	}
}

/*
level.prog_weapons[i] Struct
	.names 			Ordered Array of Weapon Console Names
	.weapons 		Ordered Array of Weapon Objects
	.loc 			Integer for this prog wallbuy
	.kills_req 		Array of number of required kills for each tier on this prog weapon
	.trig 			The trigger where this prog weapon is bought
	.kills_rem 		Number of kills remaining on the current tier
	.tier 			The number of the current tier on this prog wpn
	.max_tier 		The tier at which a perk is unlocked
	.model 			The spawned model to show the weapon on
	.delta 			Current origin change from original
*/

//Called On: Dead Enemy
function trackProgWpnKills(player){
	if(isdefined(self)){
		for(i=0; i<level.prog_weapons.size; i++){
			wpn_struct = level.prog_weapons[i];
			wpn = wpn_struct.weapons[wpn_struct.tier];
			dmg_wpn = self.damageWeapon;
			if(self.damageWeapon.inventorytype == "dwlefthand"){ //self.damageWeapon.dualWield && 
                dmg_wpn = dmg_wpn.dualWieldWeapon;
			}

			counts = zm_weapons::get_base_weapon(dmg_wpn) === wpn;
			//upgrade manually added for when not called wpn_upgraded, i.e. Bloodhound+
			counts |= zm_weapons::get_upgrade_weapon(wpn) === dmg_wpn;
			if(counts){
				level.prog_weapons[i].kills_rem--;
				//IPrintLnBold(level.prog_weapons[i].kills_rem);
				if(wpn_struct.kills_rem <= 0){
					wpn_struct nextTier();
				}
			}
		}
	}
	
}

function instakillWrapper(player){
	b_kill = player zm_powerups::is_insta_kill_active();
	if(b_kill){
		trackProgWpnKills(player);
	}
	return b_kill;
}

//Call On: a level.prog_weapons[i] Struct
function nextTier(){
	self.tier++;
	if(self.tier < self.max_tier){
		//play tier up sound
		if(self.tier != 0){
			level thread zm_utility::really_play_2D_sound("prog_wpn_tier_up");
		}
		

		self.kills_rem = Int(self.kills_req[self.tier]);
		wpn_cost = zm_weapons::get_weapon_cost(self.weapons[self.tier]);
		ammo_cost = zm_weapons::get_ammo_cost(self.weapons[self.tier]);
		up_ammo_cost =  zm_weapons::get_upgraded_ammo_cost(self.weapons[self.tier]);
		_name = self.weapons[self.tier].displayname;
		_name = MakeLocalizedString(_name);
		//Define catching
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

		hs1 = "Press ^3[{+activate}]^7 for ^5" +_name+ "^7 Cost: ^1" +wpn_cost+ "^7 ";
		hs2 = "\n Ammo Cost: ^1 " +ammo_cost+ "^7 Upgraded Ammo ^1" +up_ammo_cost+ "^7 ";
		hs3 = "\n Total Kills For Next Tier: ^1" +self.kills_rem+ "^7 ";
		self.trig SetHintString(hs1+hs2+hs3);
		//self.trig SetCursorHint("HINT_WEAPON", self.weapons[self.tier]);
		self thread progWaitForBuy(wpn_cost, ammo_cost, up_ammo_cost);

		//model
		if(isdefined(self.model)){
			self.origin -= self.delta; //reset position
			self.delta = (0, 0, 0);
			self.model SetModel("prog_wpn_"+self.names[self.tier]);
			if(isdefined(level.prog_wpn_deltas[self.names[self.tier]])){
				self.delta = level.prog_wpn_deltas[self.names[self.tier]];
				self.model.origin += self.delta;
			}
		}
	}else if(self.tier == self.max_tier){
		//play max tier sound
		level thread zm_utility::really_play_2D_sound("prog_wpn_max_tier");

		prk_name = level.prog_perk_names[self.perk];
		hs1 = "Press ^3[{+activate}]^7 for ^5" + prk_name + "^7 \n ";
		self.trig SetHintString(hs1);
		//self.trig SetCursorHint("HINT_NOICON");

		self.kills_rem = 0;

		self thread progPerkWaitFor();
		self thread progScrollWaitFor();
		foreach(_p_ in GetPlayers()){
			self thread updatePlayerHintStr(_p_);
		}
		if(isdefined(level.wallbuy_complete_func)){
			self thread [[level.wallbuy_complete_func]]();
		}

		if(isdefined(self.model)){
			self.model SetModel("prog_wpn_perk_bottle");
		}
	}else{
		self.kills_rem = 0;
	}
}

//Call On: level.prog_weapons[i] Struct
function progWaitForBuy(cost, cost_ammo, cost_up_ammo){
	level endon("death");
	_wpn = self.weapons[self.tier];
	_tier = self.tier;
	while(true){
		self.trig waittill("trigger", p);
		//ADD SND FX,
		if(_tier != self.tier){
			return;
		}

		self wpnBuyHandling(_wpn, p, cost, cost_ammo, cost_up_ammo);
	}
}

//Call On: level.prog_weapons[i] Struct
function wpnBuyHandling(_wpn, p, cost, cost_ammo, cost_up_ammo){
	if(p zm_weapons::has_weapon_or_upgrade(_wpn)){
		to_charge = cost_ammo;
		give_func = &zm_weapons::ammo_give;
		if(p zm_weapons::has_upgrade(_wpn)){
			to_charge = cost_up_ammo;
			_wpn = zm_weapons::get_upgrade_weapon(_wpn);
			//ADD UPGRADED
		}
	}else{
		to_charge = cost;
		give_func = &zm_weapons::weapon_give;
		if(_wpn.name == "ray_gun" || _wpn.name == "raygun_mark2"){
			if(p zm_weapons::has_weapon_or_upgrade(GetWeapon("raygun_mark2"))
				|| p zm_weapons::has_weapon_or_upgrade(GetWeapon("ray_gun"))){
				give_func = &rayGunBuyHandling;
			}
		}
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
		//PLAY character point shortage vox & announcer deny
	}
}

//Call On: player
function rayGunBuyHandling(weapon){
	wpns = self GetWeaponsListPrimaries();
	if(weapon.name == "ray_gun"){
		if(self zm_weapons::has_weapon_or_upgrade(GetWeapon("raygun_mark2"))){
			foreach(wpn in wpns){
				if(IsSubStr(wpn.name, "raygun_mark2")){
					self zm_weapons::weapon_take(wpn);
				}
			}
		}
	}else if(weapon.name == "raygun_mark2"){
		if(self zm_weapons::has_weapon_or_upgrade(GetWeapon("ray_gun"))){
			foreach(wpn in wpns){
				if(IsSubStr(wpn.name, "ray_gun")){
					self zm_weapons::weapon_take(wpn);
				}
			}
		}
	}

	weapon = self zm_weapons::give_build_kit_weapon(weapon);
	self notify("weapon_give", weapon);

	self GiveStartAmmo(weapon);
	self SwitchToWeapon(weapon);
	return weapon;
}

//Call On: level.prog_weapons[i] Struct
function progScrollWaitFor(){
	self endon("death");
	foreach(player in GetPlayers()){
		if(!isdefined(player.prog_indices)){
			//create a tracking on each player of which index they keep wallbuys on
			player.prog_indices = []; //dict of wallbuy and which tier they're looking at
			for(i = 0; i < level.prog_weapons.size; i++){
				array::add(player.prog_indices, level.prog_weapons[i].max_tier); //default to tier of perk unlock
			}
		}
	}
	self thread scrollBuyAttempt();
	while(true){
		foreach(player in GetPlayers()){
			if(Distance2D(player.origin, self.trig.origin) < 96){ // && player IsLookingAt(self.trig)
				self checkActionSlots(player);
			}
		}

		wait(0.05);
	}
}

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

//Call On: level.prog_weapons[i] Struct
function updatePlayerHintStr(player){
	index = player.prog_indices[self.loc];
	hs3 = "\n^7Scroll Using: ^3[{+actionslot 1}]^7 or ^3[{+actionslot 2}]^7";
	if(index < self.max_tier){
		wpn_cost = zm_weapons::get_weapon_cost(self.weapons[index]);
		ammo_cost = zm_weapons::get_ammo_cost(self.weapons[index]);
		up_ammo_cost =  zm_weapons::get_upgraded_ammo_cost(self.weapons[index]);
		_name = self.weapons[index].displayname;
		_name = MakeLocalizedString(_name);
		hs1 = "Press ^3[{+activate}]^7 for ^5" +_name+ "^7 Cost: ^1" +wpn_cost+ "^7 ";
		hs2 = "\n Ammo Cost: ^1 " +ammo_cost+ "^7 Upgraded Ammo ^1" +up_ammo_cost+ "^7 ";
	}else{
		prk_name = level.prog_perk_names[self.perk];
		hs1 = "Press ^3[{+activate}]^7 for ^5" + prk_name + "^7 \n ";
		hs2 = "\n";
	}
	self.trig SetHintStringForPlayer(player, hs1+hs2+hs3);
}

//Call On: level.prog_weapons[i] Struct
function scrollBuyAttempt(){
	self endon("death");
	while(true){
		self.trig waittill("trigger", player);
		plr_tier = player.prog_indices[self.loc];
		if(plr_tier < self.max_tier){
			//currently on weapon
			wpn_to_buy = self.weapons[plr_tier];
			wpn_cost = zm_weapons::get_weapon_cost(self.weapons[plr_tier]);
			ammo_cost = zm_weapons::get_ammo_cost(self.weapons[plr_tier]);
			up_ammo_cost =  zm_weapons::get_upgraded_ammo_cost(self.weapons[plr_tier]);
			wpnBuyHandling(wpn_to_buy, player, wpn_cost, ammo_cost, up_ammo_cost);
		}else{
			//currently on perk
			self thread progPerkWaitFor();
		}
		
	}
}

//Call On: level.prog_weapons[i] Struct
function progPerkWaitFor(){
	//IPrintLnBold("waiting");
	self endon("death");
	while(true){
		self.trig waittill("trigger", p);
		if(p HasPerk(self.perk)){
			//NEEDS UPGRADED CHECKS
			c_wpn = p GetCurrentWeapon();
			price = zm_weapons::get_ammo_cost(c_wpn);
			if(p canBuy(price)){
				zm_weapons::ammo_give(c_wpn);
			}else{
				p denyPurchase(self.trig.origin);
			}
		}else{
			//IPrintLnBold("no_perk");
			//orig = p zm_perks::perk_give_bottle_begin(self.perk);
			//wait(1);
			//p zm_perks::perk_give_bottle_end(orig, self.perk);
			p zm_perks::give_perk(self.perk, false);
			//perk vox & sound fx
		}
	}
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

//Call On: Player
function canBuy(cost){
	can_buy = self UseButtonPressed() && !self zm_utility::in_revive_trigger() && !(self.is_drinking);
	can_buy &= zm_utility::is_player_valid(self) && self zm_score::can_player_purchase(cost);
	can_buy &= !(isdefined(self.intermission) && self.intermission) && !self IsThrowingGrenade() && !self zm_utility::is_placeable_mine(self GetCurrentWeapon()); //DO DEFINED CHECK ON INTERMISSION
	
	return can_buy;
}

//returns 2D dictionary/array
//use for independently both weapon names and then kills required
//call on level
function generateArraysFromCSV(csv_filename){
	num_rows = TableLookupRowCount(csv_filename);
	rows = [];
	for(i=0; i<num_rows; i++){
		rows[i] = [];
		rows[i] = TableLookupRow(csv_filename, i);
	}
	return rows;
}


//sort structs or ents by script_int
function orderStructs(structs){
	new_structs = [];
	for(i = 0; i<structs.size; i++){
		foreach(_struct in structs){
			if(isdefined(_struct.script_int) && _struct.script_int == i){
				array::add(new_structs, _struct);
			}
		}
	}
	return new_structs;
}

//Set up the perk names in mapname.gsc
function addPerkName(code_name, display_name){
	if(!isdefined(level.prog_perk_names)){
		level.prog_perk_names = [];
	}
	level.prog_perk_names[code_name] = display_name;
}

//Adjust the position of this model
function registerWeaponDelta(str_weapon, vector_delta){
	DEFAULT(level.prog_wpn_deltas, array());
	level.prog_wpn_deltas[str_weapon] = vector_delta;
}