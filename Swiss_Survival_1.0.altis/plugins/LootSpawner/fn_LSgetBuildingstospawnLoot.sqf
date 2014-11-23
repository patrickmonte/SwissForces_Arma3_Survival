//	Lootspawner spawn script
//	Author: Na_Palm (BIS forums)
//-------------------------------------------------------------------------------------
//local to Server Var. "BuildingLoot" array of [state, time], placed on buildings that can spawn loot
//												state: 0-not assigned, 1-has loot, 2-currently in use/blockaded
//												time : timestamp of last spawn
//
//local to Server Var. "Lootready" time, placed on generated lootobject, needed for removing old loot
//									time: timestamp of spawn, object is ready for use by player and loot deleter
//-------------------------------------------------------------------------------------
private["_begintime","_BaP_list","_spInterval","_chfullfuel","_chpSpot","_genZadjust","_BaPname","_lootClass","_buildPosViable_list",
				"_buildPosZadj_list","_lBuildVar","_posviablecount","_spwnPos","_lootspawned","_randChance","_lootholder","_selecteditem",
				"_loot","_chfullf","_idx_sBlist","_chperSpot", "_wpnSpawnAmmo", "_radiusMkr", "_defendUnitsMarker",
				"_objectSpawnCount"];

//BaP - Buildings around Player
_BaP_list = _this select 0;
_spInterval = _this select 1;
_chfullfuel = _this select 2;
_genZadjust = _this select 3;
_chpSpot = _this select 4;

_begintime = time;
{
	_BaPname = "";
	_lootClass = 0;
	_buildPosViable_list = [];
	_buildPosZadj_list = [];
	_lBuildVar = (_x getVariable ["BuildingLoot", [0, 0]]);
	//diag_log format["-- LOOTSPAWNER DEBUG BaP _lBuildVar: v%1v v%2v --", _lBuildVar ,_x];
	if ((_lBuildVar select 0) < 2) then {
		//flag immediately as in use
		_x setVariable ["BuildingLoot", [2, (_lBuildVar select 1)]];
		if (((_lBuildVar select 1) == 0) || ((time - (_lBuildVar select 1)) > _spInterval)) then {
			//get building class
			_BaPname = typeOf _x;
			//here an other _x
			{
				//if junction found, get lists and -> exit forEach
				if (_BaPname == (_x select 0)) exitWith {
					_lootClass = (_x select 1);
					//get viable positions Idx
					_buildPosViable_list set [count _buildPosViable_list, ((Buildingpositions_list select _forEachIndex) select 1)];
					if (swSpZadjust) then {
						//get position adjustments
						_buildPosZadj_list set [count _buildPosZadj_list, ((Buildingpositions_list select _forEachIndex) select 2)];
					};
				};
				sleep 0.001;
			}forEach Buildingstoloot_list;
			//diag_log format["-- LOOTSPAWNER DEBUG BaP: v%1v%2v :: v%3v :: v%4v --", _BaPname, _lootClass, _buildPosViable_list, _buildPosZadj_list];
			//get spawn position, here the former _x
			_posviablecount = 0;
			for "_poscount" from 0 to 100 do {
				//check if position is viable
				if (_poscount == ((_buildPosViable_list select 0) select _posviablecount)) then {
					_posviablecount = _posviablecount +1;
					//consider chance per Slot
					if ((floor random 100) < _chpSpot) then {
						_spwnPos = (_x buildingPos _poscount);
						if ((_spwnPos select 0) == 0 && (_spwnPos select 1) == 0) then {
							_spwnPos = getPosATL _x;
						};
						if (swSpZadjust) then {
							_spwnPos = [_spwnPos select 0, _spwnPos select 1, (_spwnPos select 2) + ((_buildPosZadj_list select 0) select _poscount)];
						};
						//generally add 0.1 on z
						_spwnPos = [_spwnPos select 0, _spwnPos select 1, (_spwnPos select 2) + _genZadjust];
						//check if position has old loot
						if ((count (nearestObjects [_spwnPos, LSusedclass_list, 0.5])) == 0) then {
							sleep 0.001;
							//check what type of loot to spawn
							_lootspawned = false;
							for "_lootType" from 1 to 5 do {
								//get chance for loot every time, so all combos in spawnClassChance_list are viable
								_randChance = floor(random(100));
								if (((spawnClassChance_list select _lootClass) select _lootType) > _randChance) then {
									_lootspawned = true;
									diag_log format ["Loottype: %1", _lootType];
									//special for weapons
									if(_lootType == 1) exitWith {
										_lootholder = createVehicle ["Box_NATO_Wps_F", _spwnPos, [], 0, "CAN_COLLIDE"];
										clearWeaponCargoGlobal _lootholder;
										clearMagazineCargoGlobal _lootholder;
										
										_selecteditem = (floor(random(count((lootWeapon_list select _lootClass) select 1))));
										
										_loot = (((lootWeapon_list select _lootClass) select 1) select _selecteditem);
										_wpnSpawnAmmo = (((lootMagazine_list select _lootClass) select 1) select _selecteditem);
										
										// Set num of weapons spawned
										_objectSpawnCount = 0;
										_objectSpawnCount = round(random(3)); // 0 to 1
										_objectSpawnCount = _objectSpawnCount + 1; // Add 1 --> 1 to 2
										
										_lootholder addWeaponCargoGlobal [_loot, _objectSpawnCount];
										
										// Set num of magazines spawned
										_objectSpawnCount = 0;
										_objectSpawnCount = round(random(3)); // 0 to 2
										_objectSpawnCount = _objectSpawnCount + 1; // Add 3 --> 3 to 5
										
										_lootholder addMagazineCargoGlobal [_wpnSpawnAmmo, _objectSpawnCount];
									};
									//special for magazines: spawn 1-6
									if(_lootType == 2) exitWith {
										_lootholder = createVehicle ["Box_NATO_Wps_F", _spwnPos, [], 0, "CAN_COLLIDE"];
										clearWeaponCargoGlobal _lootholder;
										clearMagazineCargoGlobal _lootholder;
										_selecteditem = (floor(random(count((lootMagazine_list select _lootClass) select 1))));
										_loot = (((lootMagazine_list select _lootClass) select 1) select _selecteditem);
										
										// Set num of magazines spawned
										_objectSpawnCount = 0;
										_objectSpawnCount = round(random(3)); // 0 to 4
										_objectSpawnCount = _objectSpawnCount + 1; // Add 3 --> 3 to 7
										
										_lootholder addMagazineCargoGlobal [_loot, _objectSpawnCount];
									};
									//special for item/cloth/vests
									if(_lootType == 3) exitWith {
										_lootholder = createVehicle ["Box_NATO_Wps_F", _spwnPos, [], 0, "CAN_COLLIDE"];
										clearWeaponCargoGlobal _lootholder;
										clearMagazineCargoGlobal _lootholder;
										_selecteditem = (floor(random(count((lootItem_list select _lootClass) select 1))));
										_loot = (((lootItem_list select _lootClass) select 1) select _selecteditem);
										
										// Set num of ICV spawned
										_objectSpawnCount = 0;
										_objectSpawnCount = round(random(3)); // 0 to 1
										_objectSpawnCount = _objectSpawnCount + 1; // Add 1 --> 1 to 2
										
										_lootholder addItemCargoGlobal [_loot, _objectSpawnCount];
										//_lootholder setPosATL _spwnPos;
									};
									//special for backpacks
									if(_lootType == 4) exitWith {
										_lootholder = createVehicle ["GroundWeaponHolder", _spwnPos, [], 0, "CAN_COLLIDE"];
										_selecteditem = (floor(random(count((lootBackpack_list select _lootClass) select 1))));
										_loot = (((lootBackpack_list select _lootClass) select 1) select _selecteditem);
										_lootholder addBackpackCargoGlobal [_loot, 1];
										//_lootholder setPosATL _spwnPos;
									};
									//special for world objects: account for Wasteland and other items
									if(_lootType == 5) exitWith {
										_selecteditem = (floor(random(count((lootworldObject_list select _lootClass) select 1))));
										_loot = (((lootworldObject_list select _lootClass) select 1) select _selecteditem);
										_lootholder = createVehicle [_loot, _spwnPos, [], 0, "CAN_COLLIDE"];
										//if container clear its cargo
										if (({_x == _loot} count exclcontainer_list) > 0) then {
											clearWeaponCargoGlobal _lootholder;
											clearMagazineCargoGlobal _lootholder;
											clearBackpackCargoGlobal _lootholder;
											clearItemCargoGlobal _lootholder;
										};
										//_lootholder setPosATL _spwnPos;
									};
								};
								
								// Maybe add some defending units (5% Chance)
								if((random(100)) < 5) then {
									
									// The radiant of the marker ranges from 10 to 30 meters
									/*_radiusMkr = ((round(random(20))) + 10);
									
									// Create actual marker
									_marker = createMarker ["randomLootDefenseMkr" + str var_randomLootDefenseMkrIndex, _spwnPos];
									_marker setMarkerShape "ELLIPSE";
									_marker setMarkerSize [_radiusMkr, _radiusMkr];
									_marker setMarkerColor "ColorRed";
									_marker setMarkerAlpha 1;
																																																														//1
									_null = [["randomLootDefenseMkr" + str var_randomLootDefenseMkrIndex],[1,1],[1,1,66],[0,0],[0],[0],[0,0],[0,0,300,EAST,TRUE]] call EOS_Spawn;
									*/
									// Count up index
									var_randomLootDefenseMkrIndex = var_randomLootDefenseMkrIndex + 1;
								};
								
								//1 category loot only per place so -> exit For
								//no lootpiling
								if (_lootspawned) exitWith {
									_lootholder setVariable ["Lootready", time];
								};
							};
						};
					};
				};
				//if all viable positions run through -> exit For
				if (_posviablecount == (count (_buildPosViable_list select 0))) exitWith {};
			};
			//release building with new timestamp
			_x setVariable ["BuildingLoot", [1, time]];
		} else {
			//release building with old timestamp
			_x setVariable ["BuildingLoot", [1, (_lBuildVar select 1)]];
		};
	};
	sleep 0.001;
}forEach _BaP_list;
//diag_log format["-- LOOTSPAWNER DEBUG BaP: %1 buildings ready, needed %2s, EXIT now --", (count _BaP_list), (time - _begintime)];
