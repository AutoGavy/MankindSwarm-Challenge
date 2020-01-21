local dummyTarget = Entities.CreateByClassname("info_target");
dummyTarget.PrecacheSoundScript("ASW_Chainsaw.attackOff");
dummyTarget.PrecacheSoundScript("ASWGrenade.Explode");
dummyTarget.PrecacheSoundScript("ASWRocket.Explosion");
dummyTarget.PrecacheSoundScript("ASW_Weapon_Flamer.FlameLoop");
dummyTarget.PrecacheSoundScript("ASW_Weapon_Flamer.FlameStop");
dummyTarget.PrecacheSoundScript("ASW_Hornet_Barrage.FireFP");
dummyTarget.PrecacheSoundScript("ASW_GrenadeLauncher.Fire");
dummyTarget.PrecacheSoundScript("ASW_Tesla_Laser.Damage");
dummyTarget.PrecacheSoundScript("ASW_Tesla_Trap.Zap");
dummyTarget.PrecacheSoundScript("ASW_Drone.Attack");
dummyTarget.PrecacheSoundScript("ASW_Ranger_Projectile.Spawned");
dummyTarget.PrecacheSoundScript("Ranger.fire");
dummyTarget.PrecacheSoundScript("Ranger.projectileImpactPlayer");
dummyTarget.PrecacheSoundScript("Ranger.projectileImpactWorld");
dummyTarget.PrecacheSoundScript("ASW_MedGrenade.ActiveLoop");
dummyTarget.PrecacheSoundScript("ASW_Extinguisher.Stop");
dummyTarget.PrecacheSoundScript("ASW_Harvester.Spawn");
dummyTarget.PrecacheSoundScript("ASW_Parasite.Attack");
dummyTarget.PrecacheModel("models/humans/group01/female_01.mdl");
dummyTarget.PrecacheModel("models/swarm/marine/marine.mdl");
dummyTarget.PrecacheModel("models/items/teslacoil/teslacoil.mdl");
dummyTarget.PrecacheModel("models/sentry_gun/sentry_base.mdl");
dummyTarget.Destroy();

Convars.SetValue("asw_marine_death_cam_slowdown", 0);
Convars.SetValue("rd_override_allow_rotate_camera", 1);
Convars.SetValue("rd_increase_difficulty_by_number_of_marines", 0);
IncludeScript("msw_dronepropthinkfunc.nut")

MarineManager <- [];

class cMarine
{
	constructor(hMarine = null)
	{
		m_strBeamTargetname = UniqueString();
		if (hMarine != null)
		{
			m_hMarine = hMarine;
			m_strName = hMarine.GetMarineName();
		}
	}
	
	m_hMarine = null;
	m_strName = null;
	m_strBeamTargetname = null;
	m_hBeamTarget = {slot = null};
	m_hBeamParticle = {slot = null};
	m_hIdleProp = {slot = null};
	m_hRunProp = {slot = null};
	m_bOnFire = false;
	m_bEmiting = false;
	m_bIsAttacking = false;
	
	function SetOnFire(action)
	{
		if (action)
		{
			NetProps.SetPropInt(m_hMarine, "m_bOnFire", 1);
			m_bOnFire = true;
		}
		else
		{
			NetProps.SetPropInt(m_hMarine, "m_bOnFire", 0);
			m_bOnFire = false;
		}
	}
	function IsValid()
	{
		if (m_hMarine == null)
			return false;
		else
			return true;
	}
}

if (Convars.GetFloat("asw_skill") == 1) //easy
{
	Convars.SetValue("asw_horde_interval_min", 15);
	Convars.SetValue("asw_horde_interval_max", 160);
}
else if (Convars.GetFloat("asw_skill") == 2) //normal
{
	Convars.SetValue("asw_horde_interval_min", 15);
	Convars.SetValue("asw_horde_interval_max", 140);
}
else if (Convars.GetFloat("asw_skill") == 3) //hard
{
	Convars.SetValue("asw_horde_interval_min", 15);
	Convars.SetValue("asw_horde_interval_max", 120);
}
else if (Convars.GetFloat("asw_skill") == 4) //insane
{
	Convars.SetValue("asw_horde_interval_min", 15);
	Convars.SetValue("asw_horde_interval_max", 80);
}
else if (Convars.GetFloat("asw_skill") == 5) //brutal
{
	Convars.SetValue("asw_horde_interval_min", 15);
	Convars.SetValue("asw_horde_interval_max", 60);
	Convars.SetValue("asw_difficulty_alien_health_step", 0);
	Convars.SetValue("asw_drone_health", 88);
	Convars.SetValue("asw_ranger_health", 222);
	Convars.SetValue("asw_drone_uber_health", 1300);
	Convars.SetValue("asw_shaman_health", 129);
	Convars.SetValue("rd_harvester_health", 440);
	Convars.SetValue("rd_mortarbug_health", 770);
	Convars.SetValue("rd_parasite_health", 55);
	Convars.SetValue("rd_parasite_defanged_health", 22);
	Convars.SetValue("rd_shieldbug_health", 2200);
	Convars.SetValue("sk_asw_buzzer_health", 66);
	Convars.SetValue("sk_antlionguard_health", 1000);
}
if (Convars.GetFloat("asw_marine_ff_absorption") == 0) //hardcode ff
{
	Convars.SetValue("asw_marine_ff", 2);
	Convars.SetValue("asw_marine_ff_dmg_base", 3);
	Convars.SetValue("asw_marine_time_until_ignite", 0);
	Convars.SetValue("rd_marine_ignite_immediately", 1);
	Convars.SetValue("asw_marine_burn_time_easy", 60);
	Convars.SetValue("asw_marine_burn_time_normal", 60);
	Convars.SetValue("asw_marine_burn_time_hard", 60);
	Convars.SetValue("asw_marine_burn_time_insane", 60);
}

function OnMissionStart()
{
	local hSpawner = null;
	while((hSpawner = Entities.FindByClassname(hSpawner, "asw_spawner")) != null)
	{
		switch (hSpawner.GetKeyValue("AlienClass").tostring())
		{
			case "0": //drone
				hSpawner.__KeyValueFromString("alien_vscripts", "msw_drone.nut");
				break;
			case "13": //uber drone
				hSpawner.__KeyValueFromString("alien_vscripts", "msw_drone_uber.nut");
				break;
			case "10": //ranger
				hSpawner.__KeyValueFromString("alien_vscripts", "msw_ranger.nut");
				break;
			case "6": //harvester
				hSpawner.__KeyValueFromString("alien_vscripts", "msw_harvester.nut");
				break;
			case "11": //mortarbug
				hSpawner.__KeyValueFromString("alien_vscripts", "msw_mortarbug.nut");
				break;
			case "12": //shaman
				hSpawner.__KeyValueFromString("alien_vscripts", "msw_shaman.nut");
				break;
			/*case "5": //jumper drone
				hSpawner.__KeyValueFromString("alien_vscripts", "msw_drone.nut");
				break;
			case "9": //boomer
				hSpawner.__KeyValueFromString("alien_vscripts", "msw_boomer.nut");
				break;*/
		}
	}
}

function OnGameplayStart()
{
	local hMarine = null;
	while ((hMarine = Entities.FindByClassname(hMarine, "asw_marine")) != null)
	{
		MarineManager.push(cMarine(hMarine));
		local strWP1 = null;
		local strWP2 = null;
		local TableInv = hMarine.GetInvTable();
		if ("slot0" in TableInv && TableInv["slot0"] != null) 
			strWP1 = TableInv["slot0"].GetClassname();
		if ("slot1" in TableInv && TableInv["slot1"] != null) 
			strWP2 = TableInv["slot1"].GetClassname();
		
		if (strWP1 == "asw_weapon_sentry_cannon" && strWP2 == "asw_weapon_sentry_cannon")
			HenshinFunc(hMarine,"Ranger" , true);
		else if (strWP1 == "asw_weapon_railgun" && strWP2 == "asw_weapon_railgun")
		{
			if (hMarine.GetMarineName() == "Sarge" || hMarine.GetMarineName() == "Jaeger")
				HenshinFunc(hMarine,"Drone" , true);
			else if (hMarine.GetMarineName() == "Wildcat" || hMarine.GetMarineName() == "Wolfe")
				HenshinFunc(hMarine,"Mortarbug" , true);
			else if (hMarine.GetMarineName() == "Faith" || hMarine.GetMarineName() == "Bastille")
				HenshinFunc(hMarine,"Shaman" , true);
			else if (hMarine.GetMarineName() == "Crash" || hMarine.GetMarineName() == "Vegas")
				HenshinFunc(hMarine,"Harvester" , true);
		}
		/*else if (strWP1 == "asw_weapon_chainsaw" || strWP2 == "asw_weapon_chainsaw")
			HenshinFunc(hMarine, "Drone", false);
		else if (strWP1 == "asw_weapon_grenade_launcher" || strWP2 == "asw_weapon_grenade_launcher")
			HenshinFunc(hMarine, "Ranger", false);
		else if (strWP1 == "asw_weapon_heal_gun" || strWP2 == "asw_weapon_heal_gun" || strWP1 == "asw_weapon_medrifle" || strWP2 == "asw_weapon_medrifle")
			HenshinFunc(hMarine, "Shaman", false);
		else
			HenshinFunc(hMarine, "Ranger", false);*/
	}
	
	local hDrone = null;
	while ((hDrone = Entities.FindByClassname(hDrone, "asw_drone")) != null)
	{
		if (hDrone.GetKeyValue("renderamt").tointeger() != 0)
		{
			hDrone.__KeyValueFromInt("renderamt", 0);
			hDrone.__KeyValueFromInt("rendermode", 1);
			hDrone.__KeyValueFromString("disableshadows", "1");
			hDrone.__KeyValueFromString("disablereceiveshadows", "1");
			local vecAngles = hDrone.GetAngles();
			local hProp = Entities.CreateByClassname("prop_dynamic");
			hProp.__KeyValueFromString("model", "models/humans/group01/female_01.mdl");
			hProp.__KeyValueFromInt("DisableBoneFollowers", 1);
			hProp.__KeyValueFromString("solid", "0");
			hProp.SetOrigin(hDrone.GetOrigin());
			hProp.SetLocalAngles(vecAngles.x, vecAngles.y, vecAngles.z);
			
			DoEntFire("!self", "SetDefaultAnimation", "run_alert_holding_all", 0, hDrone, hProp);
			DoEntFire("!self", "SetAnimation", "run_alert_holding_all", 0, hDrone, hProp);
			//DoEntFire("!self", "SetParent", "!activator", 0, hDrone, hProp);
			hProp.SetOwner(hDrone);
			hProp.SetName("droneProp");
			hProp.Spawn();
			
			local propTarget = Entities.CreateByClassname("info_target");
			propTarget.SetOwner(hProp);
			propTarget.ValidateScriptScope();
			propTarget.GetScriptScope().iCount <- 0;
			propTarget.GetScriptScope().SetPropOrgin <- SetPropOrgin;
			AddThinkToEnt(propTarget, "SetPropOrgin");
			
			local weaponProp = Entities.CreateByClassname("prop_dynamic");
			weaponProp.__KeyValueFromString("model", "models/weapons/chainsaw/chainsaw.mdl");
			weaponProp.__KeyValueFromString("solid", "0");
			weaponProp.SetOrigin(hProp.GetOrigin());
			DoEntFire("!self", "SetParent", "!activator", 0, hProp, weaponProp);
			DoEntFire("!self", "SetParentAttachment", "anim_attachment_RH", 0, null, weaponProp);
			weaponProp.SetName("droneProp");
			weaponProp.Spawn();
			
			local hTimer = Entities.CreateByClassname("logic_timer");
			hTimer.__KeyValueFromFloat("RefireTime", 0.1);
			DoEntFire("!self", "Disable", "", 0, null, hTimer);
			hTimer.ValidateScriptScope();
			
			hTimer.GetScriptScope().weaponProp <- weaponProp;
			hTimer.GetScriptScope().vecAngles <- vecAngles;
			hTimer.GetScriptScope().TimerFunc <- function()
			{
				if (weaponProp != null && weaponProp.IsValid())
				{
					weaponProp.SetLocalOrigin(Vector(11, -5, 15));
					weaponProp.SetLocalAngles(180, -112, -22);
				}
				
				self.DisconnectOutput("OnTimer", "TimerFunc");
				self.Destroy();	
			}
			hTimer.ConnectOutput("OnTimer", "TimerFunc");
			DoEntFire("!self", "Enable", "", 0, null, hTimer);
			
			hDrone.ValidateScriptScope();
			hDrone.GetScriptScope().DroneDied <- DroneDied;
			hDrone.ConnectOutput("OnDeath", "DroneDied");
		}
	}
	local hDroneUber = null;
	while ((hDroneUber = Entities.FindByClassname(hDroneUber, "asw_drone_uber")) != null)
	{
		if (hDroneUber.GetKeyValue("renderamt").tointeger() != 0)
		{
			hDroneUber.__KeyValueFromInt("renderamt", 0);
			hDroneUber.__KeyValueFromInt("rendermode", 1);
			hDroneUber.__KeyValueFromString("disableshadows", "1");
			hDroneUber.__KeyValueFromString("disablereceiveshadows", "1");
			local vecAngles = hDroneUber.GetAngles();
			local hProp = Entities.CreateByClassname("prop_dynamic");
			hProp.__KeyValueFromString("model", "models/humans/group01/female_01.mdl");
			hProp.__KeyValueFromInt("DisableBoneFollowers", 1);
			hProp.__KeyValueFromFloat("modelscale", 1.3);
			hProp.__KeyValueFromString("solid", "0");
			hProp.SetOrigin(hDroneUber.GetOrigin());
			hProp.SetLocalAngles(vecAngles.x, vecAngles.y, vecAngles.z);
			
			DoEntFire("!self", "SetDefaultAnimation", "run_alert_holding_all", 0, hDroneUber, hProp);
			DoEntFire("!self", "SetAnimation", "run_alert_holding_all", 0, hDroneUber, hProp);
			//DoEntFire("!self", "SetParent", "!activator", 0, hDroneUber, hProp);
			hProp.SetOwner(hDroneUber);
			hProp.SetName("droneProp");
			hProp.Spawn();
			
			local propTarget = Entities.CreateByClassname("info_target");
			propTarget.SetOwner(hProp);
			propTarget.ValidateScriptScope();
			propTarget.GetScriptScope().iCount <- 0;
			propTarget.GetScriptScope().SetPropOrgin <- SetPropOrgin;
			AddThinkToEnt(propTarget, "SetPropOrgin");
			
			local weaponProp = Entities.CreateByClassname("prop_dynamic");
			weaponProp.__KeyValueFromString("model", "models/weapons/chainsaw/chainsaw.mdl");
			weaponProp.__KeyValueFromFloat("modelscale", 1.3);
			weaponProp.__KeyValueFromString("solid", "0");
			weaponProp.SetOrigin(hProp.GetOrigin());
			DoEntFire("!self", "SetParent", "!activator", 0, hProp, weaponProp);
			DoEntFire("!self", "SetParentAttachment", "anim_attachment_RH", 0, null, weaponProp);
			weaponProp.SetName("droneProp");
			weaponProp.Spawn();
			
			local hTimer = Entities.CreateByClassname("logic_timer");
			hTimer.__KeyValueFromFloat("RefireTime", 0.1);
			DoEntFire("!self", "Disable", "", 0, null, hTimer);
			hTimer.ValidateScriptScope();
			
			hTimer.GetScriptScope().weaponProp <- weaponProp;
			hTimer.GetScriptScope().vecAngles <- vecAngles;
			hTimer.GetScriptScope().TimerFunc <- function()
			{
				if (weaponProp != null && weaponProp.IsValid())
				{
					weaponProp.SetLocalOrigin(Vector(11, -5, 15));
					weaponProp.SetLocalAngles(180, -112, -22);
				}
				
				self.DisconnectOutput("OnTimer", "TimerFunc");
				self.Destroy();	
			}
			hTimer.ConnectOutput("OnTimer", "TimerFunc");
			DoEntFire("!self", "Enable", "", 0, null, hTimer);
			
			hDroneUber.ValidateScriptScope();
			hDroneUber.GetScriptScope().DroneDied <- DroneDied;
			hDroneUber.ConnectOutput("OnDeath", "DroneDied");
		}
	}
	local hRanger = null;
	while ((hRanger = Entities.FindByClassname(hRanger, "asw_ranger")) != null)
	{
		if (hRanger.GetKeyValue("renderamt").tointeger() != 0)
		{
			hRanger.__KeyValueFromInt("renderamt", 0);
			hRanger.__KeyValueFromInt("rendermode", 1);
			hRanger.__KeyValueFromString("disableshadows", "1");
			hRanger.__KeyValueFromString("disablereceiveshadows", "1");
			local vecAngles = hRanger.GetAngles();
			local hProp = Entities.CreateByClassname("prop_dynamic");
			local iSkin = RandomSkinNoMed();
			hRanger.SetName(iSkin.tostring());
			hProp.__KeyValueFromString("model", "models/swarm/marine/marine.mdl");
			hProp.__KeyValueFromInt("DisableBoneFollowers", 1);
			hProp.__KeyValueFromInt("skin", iSkin);
			hProp.__KeyValueFromString("SetBodyGroup", iSkin.tostring());
			hProp.__KeyValueFromString("solid", "0");
			hProp.SetOrigin(hRanger.GetOrigin());
			hProp.SetLocalAngles(vecAngles.x, vecAngles.y, vecAngles.z);
			
			DoEntFire("!self", "SetDefaultAnimation", "CrouchIdle", 0, hRanger, hProp);
			DoEntFire("!self", "SetAnimation", "CrouchIdle", 0, hRanger, hProp);
			DoEntFire("!self", "SetParent", "!activator", 0, hRanger, hProp);
			hProp.SetName("rangerProp");
			hProp.Spawn();
			
			local weaponProp = Entities.CreateByClassname("prop_dynamic");
			weaponProp.__KeyValueFromString("model", RandomWeapon());
			weaponProp.__KeyValueFromString("solid", "0");
			weaponProp.SetOrigin(hProp.GetOrigin());
			DoEntFire("!self", "SetParent", "!activator", 0, hProp, weaponProp);
			DoEntFire("!self", "SetParentAttachment", "RHand", 0, null, weaponProp);
			weaponProp.SetName("rangerProp");
			weaponProp.Spawn();
			
			local hTimer = Entities.CreateByClassname("logic_timer");
			hTimer.__KeyValueFromFloat("RefireTime", 0.1);
			DoEntFire("!self", "Disable", "", 0, null, hTimer);
			hTimer.ValidateScriptScope();
			
			hTimer.GetScriptScope().weaponProp <- weaponProp;
			hTimer.GetScriptScope().vecAngles <- vecAngles;
			hTimer.GetScriptScope().TimerFunc <- function()
			{
				if (weaponProp != null && weaponProp.IsValid())
				{
					weaponProp.SetLocalOrigin(Vector(9, -2, 3));
					weaponProp.SetLocalAngles(180, -90, 0);
				}
				
				self.DisconnectOutput("OnTimer", "TimerFunc");
				self.Destroy();	
			}
			hTimer.ConnectOutput("OnTimer", "TimerFunc");
			DoEntFire("!self", "Enable", "", 0, null, hTimer);
			
			hRanger.ValidateScriptScope();
			hRanger.GetScriptScope().RangerDied <- RangerDied;
			hRanger.ConnectOutput("OnDeath", "RangerDied");
		}
	}
	local hHarvester = null;
	while ((hHarvester = Entities.FindByClassname(hHarvester, "asw_harvester")) != null)
	{
		if (hHarvester.GetKeyValue("renderamt").tointeger() != 0)
		{
			hHarvester.__KeyValueFromInt("renderamt", 0);
			hHarvester.__KeyValueFromInt("rendermode", 1);
			hHarvester.__KeyValueFromString("disableshadows", "1");
			hHarvester.__KeyValueFromString("disablereceiveshadows", "1");
			local vecAngles = hHarvester.GetAngles();
			local hProp = Entities.CreateByClassname("prop_dynamic");
			local iSkin = RandomSkinNoMed();
			hHarvester.SetName(iSkin.tostring());
			hProp.__KeyValueFromString("model", "models/swarm/marine/marine.mdl");
			hProp.__KeyValueFromInt("DisableBoneFollowers", 1);
			hProp.__KeyValueFromFloat("modelscale", 1.5);
			hProp.__KeyValueFromInt("skin", iSkin);
			hProp.__KeyValueFromString("SetBodyGroup", iSkin.tostring());
			hProp.__KeyValueFromString("solid", "0");
			hProp.SetAngles(vecAngles.x, vecAngles.y + 90, vecAngles.z);
			hProp.SetOrigin(hHarvester.GetOrigin() + hHarvester.GetForwardVector() * 60);
			
			DoEntFire("!self", "SetDefaultAnimation", "reload_smg1", 0, hHarvester, hProp);
			DoEntFire("!self", "SetAnimation", "reload_smg1", 0, hHarvester, hProp);
			DoEntFire("!self", "SetParent", "!activator", 0, hHarvester, hProp);
			hProp.SetName("harvesterProp");
			hProp.Spawn();
			
			local weaponProp = Entities.CreateByClassname("prop_dynamic");
			weaponProp.__KeyValueFromString("model", "models/weapons/mininglaser/mininglaser.mdl");
			weaponProp.__KeyValueFromFloat("modelscale", 1.5);
			weaponProp.__KeyValueFromInt("skin", 1);
			weaponProp.__KeyValueFromString("solid", "0");
			weaponProp.SetOrigin(hProp.GetOrigin());
			DoEntFire("!self", "SetParent", "!activator", 0, hProp, weaponProp);
			DoEntFire("!self", "SetParentAttachment", "RHand", 0, null, weaponProp);
			weaponProp.SetName("harvesterProp");
			weaponProp.Spawn();
		
			local hTimer = Entities.CreateByClassname("logic_timer");
			hTimer.__KeyValueFromFloat("RefireTime", 0.1);
			DoEntFire("!self", "Disable", "", 0, null, hTimer);
			hTimer.ValidateScriptScope();
			
			hTimer.GetScriptScope().weaponProp <- weaponProp;
			hTimer.GetScriptScope().vecAngles <- vecAngles;
			hTimer.GetScriptScope().TimerFunc <- function()
			{
				if (weaponProp != null && weaponProp.IsValid())
					weaponProp.SetLocalAngles(180, -90, 0);
				
				self.DisconnectOutput("OnTimer", "TimerFunc");
				self.Destroy();	
			}
			hTimer.ConnectOutput("OnTimer", "TimerFunc");
			DoEntFire("!self", "Enable", "", 0, null, hTimer);
		}
	}
	local hMortar = null;
	while ((hMortar = Entities.FindByClassname(hMortar, "asw_mortarbug")) != null)
	{
		if (hMortar.GetKeyValue("renderamt").tointeger() != 0)
		{
			hMortar.__KeyValueFromInt("renderamt", 0);
			hMortar.__KeyValueFromInt("rendermode", 1);
			hMortar.__KeyValueFromString("disableshadows", "1");
			hMortar.__KeyValueFromString("disablereceiveshadows", "1");
			local vecAngles = hMortar.GetAngles();
			local hProp = Entities.CreateByClassname("prop_dynamic");
			local iSkin = RandomSkinNoMed();
			hMortar.SetName(iSkin.tostring());
			hProp.__KeyValueFromString("model", "models/swarm/marine/marine.mdl");
			hProp.__KeyValueFromInt("DisableBoneFollowers", 1);
			hProp.__KeyValueFromFloat("modelscale", 1.5);
			hProp.__KeyValueFromInt("skin", iSkin);
			hProp.__KeyValueFromString("SetBodyGroup", iSkin.tostring());
			hProp.__KeyValueFromString("solid", "0");
			hProp.SetAngles(vecAngles.x, vecAngles.y + 90, vecAngles.z);
			hProp.SetOrigin(hMortar.GetOrigin() + hMortar.GetForwardVector() * 60);
			
			DoEntFire("!self", "SetDefaultAnimation", "reload_smg1", 0, hMortar, hProp);
			DoEntFire("!self", "SetAnimation", "reload_smg1", 0, hMortar, hProp);
			DoEntFire("!self", "SetParent", "!activator", 0, hMortar, hProp);
			hProp.SetName("mortarProp");
			hProp.Spawn();
			
			local weaponProp = Entities.CreateByClassname("prop_dynamic");
			weaponProp.__KeyValueFromString("model", "models/weapons/grenadelauncher/grenadelauncher.mdl");
			weaponProp.__KeyValueFromFloat("modelscale", 1.5);
			weaponProp.__KeyValueFromString("solid", "0");
			weaponProp.SetOrigin(hProp.GetOrigin());
			DoEntFire("!self", "SetParent", "!activator", 0, hProp, weaponProp);
			DoEntFire("!self", "SetParentAttachment", "RHand", 0, null, weaponProp);
			weaponProp.SetName("mortarProp");
			weaponProp.Spawn();
		
			local hTimer = Entities.CreateByClassname("logic_timer");
			hTimer.__KeyValueFromFloat("RefireTime", 0.1);
			DoEntFire("!self", "Disable", "", 0, null, hTimer);
			hTimer.ValidateScriptScope();
			
			hTimer.GetScriptScope().weaponProp <- weaponProp;
			hTimer.GetScriptScope().vecAngles <- vecAngles;
			hTimer.GetScriptScope().TimerFunc <- function()
			{
				if (weaponProp != null && weaponProp.IsValid())
					weaponProp.SetLocalAngles(180, -90, 0);
				
				self.DisconnectOutput("OnTimer", "TimerFunc");
				self.Destroy();	
			}
			hTimer.ConnectOutput("OnTimer", "TimerFunc");
			DoEntFire("!self", "Enable", "", 0, null, hTimer);
		}
	}
	/*local hBoomer = null;
	while ((hBoomer = Entities.FindByClassname(hBoomer, "asw_boomer")) != null)
	{
		if (hBoomer.GetKeyValue("renderamt").tointeger() != 0)
		{
			hBoomer.__KeyValueFromInt("renderamt", 0);
			hBoomer.__KeyValueFromInt("rendermode", 1);
			hBoomer.__KeyValueFromString("disableshadows", "1");
			hBoomer.__KeyValueFromString("disablereceiveshadows", "1");
			local vecAngles = hBoomer.GetAngles();
			local hProp = Entities.CreateByClassname("prop_dynamic");
			local iSkin = RandomSkinNoMed();
			hBoomer.SetName(iSkin.tostring());
			hProp.__KeyValueFromString("model", "models/swarm/marine/marine.mdl");
			hProp.__KeyValueFromInt("DisableBoneFollowers", 1);
			hProp.__KeyValueFromFloat("modelscale", 1.5);
			hProp.__KeyValueFromInt("skin", iSkin);
			hProp.__KeyValueFromString("SetBodyGroup", iSkin.tostring());
			hProp.__KeyValueFromString("solid", "0");
			hProp.SetOrigin(hBoomer.GetOrigin());
			hProp.SetLocalAngles(vecAngles.x, vecAngles.y, vecAngles.z);
			
			DoEntFire("!self", "SetDefaultAnimation", "kick", 0, hBoomer, hProp);
			DoEntFire("!self", "SetAnimation", "kick", 0, hBoomer, hProp);
			DoEntFire("!self", "SetParent", "!activator", 0, hBoomer, hProp);
			hProp.SetName("boomerProp");
			hProp.Spawn();
			
			hBoomer.ValidateScriptScope();
			hBoomer.GetScriptScope().BoomerDied <- BoomerDied;
			hBoomer.ConnectOutput("OnDeath", "BoomerDied");
		}
	}*/
	local hShaman = null;
	while ((hShaman = Entities.FindByClassname(hShaman, "asw_shaman")) != null)
	{
		if (hShaman.GetKeyValue("renderamt").tointeger() != 0)
		{
			hShaman.__KeyValueFromInt("renderamt", 0);
			hShaman.__KeyValueFromInt("rendermode", 1);
			hShaman.__KeyValueFromString("disableshadows", "1");
			hShaman.__KeyValueFromString("disablereceiveshadows", "1");
			local vecAngles = hShaman.GetAngles();
			local hProp = Entities.CreateByClassname("prop_dynamic");
			hProp.__KeyValueFromString("model", "models/swarm/marine/marine.mdl");
			hProp.__KeyValueFromInt("DisableBoneFollowers", 1);
			hProp.__KeyValueFromInt("skin", 2);
			hProp.__KeyValueFromString("SetBodyGroup", "2");
			hProp.__KeyValueFromString("solid", "0");
			hProp.SetOrigin(hShaman.GetOrigin());
			hProp.SetLocalAngles(vecAngles.x, vecAngles.y, vecAngles.z);
			
			DoEntFire("!self", "SetDefaultAnimation", "pistol_run_n_test", 0, hShaman, hProp);
			DoEntFire("!self", "SetAnimation", "pistol_run_n_test", 0, hShaman, hProp);
			DoEntFire("!self", "SetParent", "!activator", 0, hShaman, hProp);
			hProp.SetOwner(hShaman);
			hProp.SetName("shamanProp");
			hProp.Spawn();
			hProp.ValidateScriptScope();
			
			local weaponProp = Entities.CreateByClassname("prop_dynamic");
			weaponProp.__KeyValueFromString("model", "models/weapons/healgun/healgun.mdl");
			weaponProp.__KeyValueFromString("solid", "0");
			weaponProp.SetOrigin(hProp.GetOrigin());
			DoEntFire("!self", "SetParent", "!activator", 0, hProp, weaponProp);
			DoEntFire("!self", "SetParentAttachment", "RHand", 0, null, weaponProp);
			weaponProp.SetOwner(hShaman);
			weaponProp.SetName("shamanProp");
			weaponProp.Spawn();
			
			local hTimer = Entities.CreateByClassname("logic_timer");
			hTimer.__KeyValueFromFloat("RefireTime", 0.1);
			DoEntFire("!self", "Disable", "", 0, null, hTimer);
			hTimer.ValidateScriptScope();
			
			hTimer.GetScriptScope().weaponProp <- weaponProp;
			hTimer.GetScriptScope().vecAngles <- vecAngles;
			hTimer.GetScriptScope().TimerFunc <- function()
			{
				if (weaponProp != null && weaponProp.IsValid())
				{
					weaponProp.SetLocalOrigin(Vector(6, -2, 9));
					weaponProp.SetLocalAngles(180, -90, 0);
				}
				
				self.DisconnectOutput("OnTimer", "TimerFunc");
				self.Destroy();	
			}
			hTimer.ConnectOutput("OnTimer", "TimerFunc");
			DoEntFire("!self", "Enable", "", 0, null, hTimer);
			
			hShaman.ValidateScriptScope();
			hShaman.GetScriptScope().ShamanDied <- ShamanDied;
			hShaman.ConnectOutput("OnDeath", "ShamanDied");
		}
	}
	local hEgg = null;
	while ((hEgg = Entities.FindByClassname(hEgg, "asw_egg")) != null)
	{
		if (hEgg.GetKeyValue("renderamt").tointeger() != 0)
		{
			hEgg.__KeyValueFromInt("renderamt", 0);
			hEgg.__KeyValueFromInt("rendermode", 1);
			hEgg.__KeyValueFromString("disableshadows", "1");
			hEgg.__KeyValueFromString("disablereceiveshadows", "1");
			
			/*local vecAngles = hEgg.GetAngles();
			local hProp = Entities.CreateByClassname("prop_dynamic");
			hProp.__KeyValueFromString("model", "");
			hProp.__KeyValueFromInt("DisableBoneFollowers", 1);
			hProp.__KeyValueFromString("solid", "0");
			hProp.SetOrigin(hEgg.GetOrigin());
			hProp.SetLocalAngles(vecAngles.x, vecAngles.y, vecAngles.z);
			
			DoEntFire("!self", "SetDefaultAnimation", "run_alert_holding_all", 0, hEgg, hProp);
			DoEntFire("!self", "SetAnimation", "run_alert_holding_all", 0, hEgg, hProp);
			DoEntFire("!self", "SetParent", "!activator", 0, hEgg, hProp);
			hProp.SetName("eggProp");
			hProp.Spawn();
			
			hEgg.ValidateScriptScope();
			hEgg.GetScriptScope().EggDied <- EggDied;
			hEgg.ConnectOutput("OnDeath", "EggDied");*/
		}
	}
	local hBiomass = null;
	while ((hBiomass = Entities.FindByClassname(hBiomass, "asw_alien_goo")) != null)
	{
		if (hBiomass.GetKeyValue("renderamt").tointeger() != 0)
		{
			hBiomass.__KeyValueFromInt("renderamt", 0);
			hBiomass.__KeyValueFromInt("rendermode", 1);
			hBiomass.__KeyValueFromString("disableshadows", "1");
			hBiomass.__KeyValueFromString("disablereceiveshadows", "1");
			
			local vecAngles = hBiomass.GetAngles();
			local hProp = Entities.CreateByClassname("prop_dynamic");
			hProp.__KeyValueFromString("model", "models/sentry_gun/sentry_base.mdl");
			hProp.__KeyValueFromInt("modelscale", 3);
			hProp.__KeyValueFromInt("DisableBoneFollowers", 1);
			hProp.__KeyValueFromString("solid", "0");
			hProp.SetOrigin(hBiomass.GetOrigin() + Vector(0, 0, 25));
			hProp.SetLocalAngles(vecAngles.x, vecAngles.y, vecAngles.z);
			
			DoEntFire("!self", "SetParent", "!activator", 0, hBiomass, hProp);
			hProp.SetName("biomassProp");
			hProp.Spawn();
			
			hBiomass.ValidateScriptScope();
			hBiomass.GetScriptScope().BiomassDied <- BiomassDied();
			hBiomass.ConnectOutput("OnDeath", "BiomassDied");
		}
	}
}

function Update()
{
	local hSpit = null;
	while ((hSpit = Entities.FindByClassname(hSpit, "asw_missile_round")) != null)
	{
		if (hSpit.GetName() != "rangerSpit_Ex")
		{
			hSpit.EmitSound("ASW_Hornet_Barrage.Fire");
			CreateParticle(9, "rocket_trail_small_glow", hSpit.GetOrigin(), hSpit);
			CreateParticle(9, "rocket_trail_small", hSpit.GetOrigin(), hSpit);
			hSpit.SetName("rangerSpit_Ex");
		}
	}
	local hShell = null;
	while ((hShell = Entities.FindByClassname(hShell, "asw_mortarbug_shell")) != null)
	{
		if (hShell.GetName() != "mortarShell_player" && hShell.GetName() != "mortarShell_Ex")
		{
			hShell.EmitSound("ASW_GrenadeLauncher.Fire");
			CreateParticle(9, "rocket_trail_small_glow", hShell.GetOrigin(), hShell);
			CreateParticle(9, "rocket_trail_small", hShell.GetOrigin(), hShell);
			hShell.SetName("mortarShell_Ex");
		}
	}
	local hParas = null;
	while ((hParas = Entities.FindByClassname(hParas, "asw_parasite")) != null)
	{
		if (hParas.GetKeyValue("renderamt").tointeger() != 0)
		{
			hParas.__KeyValueFromInt("renderamt", 0);
			hParas.__KeyValueFromInt("rendermode", 1);
			hParas.__KeyValueFromString("disableshadows", "1");
			hParas.__KeyValueFromString("disablereceiveshadows", "1");
			local vecAngles = hParas.GetAngles();
			local hProp = Entities.CreateByClassname("prop_dynamic");
			local iSkin = RandomSkinNoMed();
			hParas.SetName(iSkin.tostring());
			hProp.__KeyValueFromString("model", "models/swarm/marine/marine.mdl");
			hProp.__KeyValueFromInt("DisableBoneFollowers", 1);
			hProp.__KeyValueFromInt("skin", iSkin);
			hProp.__KeyValueFromString("SetBodyGroup", iSkin.tostring());
			hProp.__KeyValueFromString("solid", "0");
			hProp.SetOrigin(hParas.GetOrigin());
			hProp.SetLocalAngles(vecAngles.x, vecAngles.y, vecAngles.z);
			
			if (NetProps.GetPropInt(hParas, "m_bDoEggIdle"))
			{
				DoEntFire("!self", "SetDefaultAnimation", "walk_aiming_all", 0, hParas, hProp);
				DoEntFire("!self", "SetAnimation", "walk_aiming_all", 0, hParas, hProp);
			}
			else
			{
				DoEntFire("!self", "SetDefaultAnimation", "pistol_run_n_test", 0, hParas, hProp);
				DoEntFire("!self", "SetAnimation", "pistol_run_n_test", 0, hParas, hProp);
			}
			DoEntFire("!self", "SetParent", "!activator", 0, hParas, hProp);
			hProp.SetOwner(hParas);
			hProp.SetName("parasiteProp");
			hProp.Spawn();
			hProp.ValidateScriptScope();
			
			local weaponProp = Entities.CreateByClassname("prop_dynamic");
			weaponProp.__KeyValueFromString("model", "models/weapons/flamethrower/flamethrower.mdl");
			weaponProp.__KeyValueFromString("solid", "0");
			weaponProp.SetOrigin(hProp.GetOrigin());
			DoEntFire("!self", "SetParent", "!activator", 0, hProp, weaponProp);
			DoEntFire("!self", "SetParentAttachment", "RHand", 0, null, weaponProp);
			weaponProp.SetOwner(hProp);
			weaponProp.SetName("parasitePropWP");
			weaponProp.Spawn();
			weaponProp.ValidateScriptScope();
			weaponProp.GetScriptScope().IsInfesting <- IsInfesting;
			weaponProp.GetScriptScope().SetFlameAngles <- SetFlameAngles;
			AddThinkToEnt(weaponProp, "IsInfesting");
			
			local hTimer = Entities.CreateByClassname("logic_timer");
			hTimer.__KeyValueFromFloat("RefireTime", 0.1);
			DoEntFire("!self", "Disable", "", 0, null, hTimer);
			hTimer.ValidateScriptScope();
			
			hTimer.GetScriptScope().weaponProp <- weaponProp;
			hTimer.GetScriptScope().vecAngles <- vecAngles;
			hTimer.GetScriptScope().TimerFunc <- function()
			{
				if (weaponProp != null && weaponProp.IsValid())
				{
					weaponProp.SetLocalOrigin(Vector(6, -2, 9));
					weaponProp.SetLocalAngles(180, -90, 0);
				}
				
				self.DisconnectOutput("OnTimer", "TimerFunc");
				self.Destroy();	
			}
			hTimer.ConnectOutput("OnTimer", "TimerFunc");
			DoEntFire("!self", "Enable", "", 0, null, hTimer);
			
			hParas.ValidateScriptScope();
			hParas.GetScriptScope().ParasDied <- ParasDied;
			hParas.ConnectOutput("OnDeath", "ParasDied");
		}
		else if (!NetProps.GetPropInt(hParas, "m_bDoEggIdle"))
		{
			local hProp = null;
			while ((hProp = Entities.FindByClassnameWithin(hProp, "prop_dynamic", hParas.GetOrigin(), 9)) != null)
			{
				if (hProp.GetName() == "parasiteProp")
				{
					DoEntFire("!self", "SetDefaultAnimation", "pistol_run_n_test", 0, hParas, hProp);
					DoEntFire("!self", "SetAnimation", "pistol_run_n_test", 0, hParas, hProp);
					hProp.SetName("parasiteProp_Ex");
				}
			}
		}
	}
	local hEgg = null;
	while ((hEgg = Entities.FindByClassname(hEgg, "asw_egg")) != null)
	{
		if (NetProps.GetPropInt(hEgg, "m_bHatched") && hEgg.GetName() != "eggEx")
		{
			hEgg.__KeyValueFromInt("renderamt", 255);
			hEgg.__KeyValueFromInt("rendermode", 0);
			hEgg.__KeyValueFromString("disableshadows", "0");
			hEgg.__KeyValueFromString("disablereceiveshadows", "0");
			hEgg.SetName("eggEx");
		}
	}
	local hXeno = null;
	while ((hXeno = Entities.FindByClassname(hXeno, "asw_parasite_defanged")) != null)
	{
		if (hXeno.GetKeyValue("renderamt").tointeger() != 0)
		{
			CreateParticle(2, "thorns_zap", hXeno.GetOrigin());
			hXeno.EmitSound("ASW_Tesla_Laser.Damage");
			hXeno.__KeyValueFromInt("renderamt", 0);
			hXeno.__KeyValueFromInt("rendermode", 1);
			hXeno.__KeyValueFromString("disableshadows", "1");
			hXeno.__KeyValueFromString("disablereceiveshadows", "1");
			local vecAngles = hXeno.GetAngles();
			local hProp = Entities.CreateByClassname("prop_dynamic");
			hProp.__KeyValueFromString("model", "models/items/teslacoil/teslacoil.mdl");
			hProp.__KeyValueFromInt("DisableBoneFollowers", 1);
			hProp.__KeyValueFromString("solid", "0");
			hProp.SetOrigin(hXeno.GetOrigin());
			hProp.SetLocalAngles(vecAngles.x, vecAngles.y, vecAngles.z);
			
			DoEntFire("!self", "SetDefaultAnimation", "active", 0, hXeno, hProp);
			DoEntFire("!self", "SetAnimation", "active", 0, hXeno, hProp);
			DoEntFire("!self", "SetParent", "!activator", 0, hXeno, hProp);
			hProp.SetName("xenomiteProp");
			hProp.Spawn();
			
			hXeno.ValidateScriptScope();
			hXeno.GetScriptScope().XenoDied <- XenoDied;
			hXeno.ConnectOutput("OnDeath", "XenoDied");
		}
	}
	local hBuzzer = null;
	while ((hBuzzer = Entities.FindByClassname(hBuzzer, "asw_buzzer")) != null)
	{
		if (hBuzzer.GetKeyValue("renderamt").tointeger() != 0)
		{
			hBuzzer.__KeyValueFromInt("renderamt", 0);
			hBuzzer.__KeyValueFromInt("rendermode", 1);
			hBuzzer.__KeyValueFromString("disableshadows", "1");
			hBuzzer.__KeyValueFromString("disablereceiveshadows", "1");
			local vecAngles = hBuzzer.GetAngles();
			local hProp = Entities.CreateByClassname("prop_dynamic");
			local iSkin = RandomSkinNoMed();
			hBuzzer.SetName(iSkin.tostring());
			hProp.__KeyValueFromString("model", "models/swarm/marine/marine.mdl");
			hProp.__KeyValueFromInt("DisableBoneFollowers", 1);
			hProp.__KeyValueFromInt("skin", iSkin);
			hProp.__KeyValueFromString("SetBodyGroup", iSkin.tostring());
			hProp.__KeyValueFromString("solid", "0");
			hProp.SetOrigin(hBuzzer.GetOrigin() + Vector(0, 0, -35));
			hProp.SetLocalAngles(vecAngles.x, vecAngles.y, vecAngles.z);
			
			DoEntFire("!self", "SetDefaultAnimation", "jumpjet_pound", 0, hBuzzer, hProp);
			DoEntFire("!self", "SetAnimation", "jumpjet_pound", 0, hBuzzer, hProp);
			DoEntFire("!self", "SetParent", "!activator", 0, hBuzzer, hProp);
			hProp.SetName("buzzerProp");
			hProp.Spawn();

			local hTrail = Entities.CreateByClassname("info_particle_system");
			hTrail.__KeyValueFromString("effect_name", "jj_trail_small");
			hTrail.__KeyValueFromString("start_active", "1");
			hTrail.SetOrigin(hProp.GetOrigin());
			DoEntFire("!self", "SetParent", "!activator", 0, hProp, hTrail);
			DoEntFire("!self", "SetParentAttachment", "jump_jet_r", 0, null, hTrail);
			hTrail.Spawn();
			hTrail.Activate();
		}
	}
	return 0.1;
}

function OnTakeDamage_Alive_Any(hVictim, inflictor, hAttacker, weapon, damage, damageType, ammoName) 
{
	if (hAttacker != null && hVictim != null)
	{
		if (hAttacker.IsAlien())
		{
			if (hAttacker.GetClassname() == "asw_drone")
			{
				hAttacker.EmitSound("ASW_Chainsaw.attackOff");
				CreateParticle(1.5, "piercing_spark", hVictim.GetOrigin());
			}
			else if (hVictim.GetClassname() == "asw_marine")
			{
				if (hAttacker.GetClassname() == "asw_ranger")
				{
					hVictim.EmitSound("ASWRocket.Explosion");
					CreateParticle(3, "explosion_air_small", hVictim.GetOrigin());
				}
				else if (damageType == 1048576 && hAttacker.GetClassname() == "asw_parasite_defanged")
				{
					hVictim.EmitSound("ASW_Tesla_Trap.Zap");
					CreateParticle(3, "thorns_zap_cp1", hVictim.GetOrigin());
					CreateParticle(3, "blink", hVictim.GetOrigin());
				}
			}
		}
		if (hVictim.IsAlien() && hVictim.GetKeyValue("renderamt").tointeger() == 0)
		{
			if (hVictim.GetClassname() != "asw_drone_jumper" && hVictim.GetClassname() != "asw_shieldbug" && hVictim.GetClassname() != "npc_antlionguard_normal" && hVictim.GetClassname() != "npc_antlionguard_cavern")
				CreateParticle(1.5, "marine_hit_blood", hVictim.GetOrigin());
		}
	}
	else if (damageType == 33554432 && hVictim != null && hVictim.GetClassname() == "asw_marine")
	{
		local cTarget = MarineManager[GetMarineIndex(hVictim)];
		if (cTarget.IsValid() && !cTarget.m_bOnFire)
		{
			local target = Entities.CreateByClassname("info_target");
			target.SetOwner(hVictim);
			target.ValidateScriptScope();
			target.GetScriptScope().MarineManager <- MarineManager;
			target.GetScriptScope().GetMarineIndex <- GetMarineIndex;
			target.GetScriptScope().IsMarineInfested <- IsMarineInfested;
			
			cTarget.SetOnFire(true);
			hVictim.EmitSound("ASW_Weapon_Flamer.FlameLoop");
			AddThinkToEnt(target, "IsMarineInfested");
		}
	}
	return damage;
}

function OnGameEvent_entity_killed(params)
{
	local hVictim = null;
	if ("entindex_killed" in params)
		hVictim = EntIndexToHScript(params["entindex_killed"]);
	
	if (!hVictim)
		return;
	
	if (hVictim.IsAlien() && hVictim.GetKeyValue("renderamt").tointeger() == 0)
	{
		if (hVictim.GetClassname() == "asw_drone")
		{
			hVictim.StopSound("ASW_Drone.Death");
			hVictim.StopSound("ASW_Drone.DeathFancy");
			hVictim.StopSound("ASW_Drone.DeathFire");
			hVictim.StopSound("ASW_Drone.DeathFireSizzle");
			hVictim.StopSound("ASW_Drone.DeathElectric");
			hVictim.StopSound("ASW_Chainsaw.attackOff");
			CreateCorpse(hVictim, "models/humans/group01/female_01.mdl");
			CreateParticle(4, "marine_death_ragdoll", hVictim.GetOrigin());
		}
		else if (hVictim.GetClassname() == "asw_drone_uber")
		{
			hVictim.StopSound("ASW_Drone.Death");
			hVictim.StopSound("ASW_Drone.DeathFancy");
			hVictim.StopSound("ASW_Drone.DeathFire");
			hVictim.StopSound("ASW_Drone.DeathFireSizzle");
			hVictim.StopSound("ASW_Drone.DeathElectric");
			hVictim.StopSound("ASW_Chainsaw.attackOff");
			CreateCorpse(hVictim, "models/humans/group01/female_01.mdl", null, 1.3);
			CreateParticle(4, "marine_death_ragdoll", hVictim.GetOrigin());
		}
		else if (hVictim.GetClassname() == "asw_ranger")
		{
			CreateCorpse(hVictim, "models/swarm/marine/marine.mdl", hVictim.GetName());
			CreateParticle(4, "marine_death_ragdoll", hVictim.GetOrigin());
		}
		else if (hVictim.GetClassname() == "asw_parasite")
		{
			hVictim.StopSound("ASW_Parasite.Death");
			CreateCorpse(hVictim, "models/swarm/marine/marine.mdl", hVictim.GetName());
			CreateParticle(4, "marine_death_ragdoll", hVictim.GetOrigin());
		}
		else if (hVictim.GetClassname() == "asw_harvester")
		{
			hVictim.StopSound("ASW_Harvester.Death");
			//CreateCorpse(hVictim, "models/swarm/marine/marine.mdl", hVictim.GetName(), 1.5);
			CreateParticle(4, "marine_death_ragdoll", hVictim.GetOrigin());
		}
		else if (hVictim.GetClassname() == "asw_parasite_defanged")
			hVictim.StopSound("ASW_Parasite.Death");
		else if (hVictim.GetClassname() == "asw_mortarbug")
		{
			hVictim.StopSound("ASW_MortarBug.Death");
			//CreateCorpse(hVictim, "models/swarm/marine/marine.mdl", hVictim.GetName(), 1.5);
			CreateParticle(4, "marine_death_ragdoll", hVictim.GetOrigin());
		}
		/*else if (hVictim.GetClassname() == "asw_boomer")
		{
			CreateCorpse(hVictim, "models/swarm/marine/marine.mdl", hVictim.GetName(), 1.5);
			CreateParticle(4, "marine_death_ragdoll", hVictim.GetOrigin());
		}*/
		else if (hVictim.GetClassname() == "asw_buzzer")
		{
			CreateCorpse(hVictim, "models/swarm/marine/marine.mdl", hVictim.GetName());
			CreateParticle(4, "marine_death_ragdoll", hVictim.GetOrigin());
		}
		else if (hVictim.GetClassname() == "asw_shaman")
		{
			CreateCorpse(hVictim, "models/swarm/marine/marine.mdl", "2");
			CreateParticle(4, "marine_death_ragdoll", hVictim.GetOrigin());
		}
	}
}

function HenshinFunc(hMarine, strDrone = null, bRealMode = false)
{
	if (!hMarine || !strDrone)
		return;

	switch(strDrone)
	{
		case "Drone":
			ChangeDrone(hMarine, bRealMode);
			break;
		case "Ranger":
			ChangeRanger(hMarine, bRealMode);
			break;
		case "Mortarbug":
			ChangeMortar(hMarine, bRealMode);
			break;
		case "Shaman":
			ChangeShaman(hMarine, bRealMode);
			break;
		case "Harvester":
			ChangeHarvester(hMarine, bRealMode);
			break;
	}
}

function ChangeDrone(hMarine, bRealMode)
{
	//hMarine.SetModel("models/aliens/drone/drone.mdl");
	//hMarine.SetSize(Vector(-15,-15,0), Vector(15,15,50));
	//hMarine.SetOrigin(hMarine.GetOrigin() + Vector(0,0,6));
	hMarine.__KeyValueFromInt("modelscale", 0);
	
	if (!bRealMode)
		return;
	
	//hMarine.__KeyValueFromFloat("modelscale", 1.3);
	if (hMarine.GetMarineName() == "Sarge")
	{
		hMarine.SetHealth(500);
		hMarine.SetMaxHealth(500);
	}
	else
	{
		hMarine.SetHealth(490);
		hMarine.SetMaxHealth(490);
	}
	hMarine.DropWeapon(0);
	hMarine.DropWeapon(1);
	local target = Entities.CreateByClassname("info_target");
	target.SetOwner(hMarine);
	target.ValidateScriptScope();
	target.GetScriptScope().delay <- Time();
	target.GetScriptScope().DamageFilter <- DamageFilter;
	target.GetScriptScope().DroneTargetFilter <- DroneTargetFilter;
	target.GetScriptScope().cTarget <- MarineManager[GetMarineIndex(hMarine)];
	target.GetScriptScope().DroneThinkFunc <- DroneThinkFunc;
	AddThinkToEnt(target, "DroneThinkFunc");
}

function ChangeRanger(hMarine, bRealMode)
{
	hMarine.SetModel("models/aliens/mortar3/mortar3.mdl");
	hMarine.SetSize(Vector(-15,-15,0), Vector(15,15,50));
	hMarine.SetOrigin(hMarine.GetOrigin() + Vector(0,0,6));
	
	if (!bRealMode)
		return;
	
	hMarine.SetHealth(hMarine.GetHealth() * 2.6);
	hMarine.SetMaxHealth(hMarine.GetHealth());
	hMarine.DropWeapon(0);
	hMarine.DropWeapon(1);
	local target = Entities.CreateByClassname("info_target");
	target.SetOwner(hMarine);
	target.ValidateScriptScope();
	target.GetScriptScope().delay <- Time();
	target.GetScriptScope().CreateParticle <- CreateParticle;
	target.GetScriptScope().DamageFilter <- DamageFilter;
	target.GetScriptScope().DroneTargetFilter <- DroneTargetFilter;
	target.GetScriptScope().RangerSoundScript <- RangerSoundScript;
	target.GetScriptScope().RangerThinkFunc <- RangerThinkFunc;
	target.GetScriptScope().MoveForward <- MoveForward;
	AddThinkToEnt(target, "RangerThinkFunc");
}

function ChangeMortar(hMarine, bRealMode)
{
	hMarine.SetModel("models/aliens/mortar/mortar.mdl");
	hMarine.SetSize(Vector(-15,-15,0), Vector(15,15,50));
	hMarine.SetOrigin(hMarine.GetOrigin() + Vector(0,0,6));
	
	if (!bRealMode)
		return;
	
	if (hMarine.GetMarineName() == "Wildcat")
	{
		hMarine.SetHealth(466);
		hMarine.SetMaxHealth(466);
	}
	else
	{
		hMarine.SetHealth(511);
		hMarine.SetMaxHealth(511);
	}
	hMarine.DropWeapon(0);
	hMarine.DropWeapon(1);
	local target = Entities.CreateByClassname("info_target");
	target.SetOwner(hMarine);
	target.ValidateScriptScope();
	target.GetScriptScope().delay <- Time();
	target.GetScriptScope().MaxFunc <- MaxFunc;
	target.GetScriptScope().LaunchVector <- LaunchVector;
	target.GetScriptScope().MortarThinkFunc <- MortarThinkFunc;
	AddThinkToEnt(target, "MortarThinkFunc");
}

function ChangeShaman(hMarine, bRealMode)
{
	hMarine.SetModel("models/aliens/shaman/shaman.mdl");
	hMarine.SetSize(Vector(-15,-15,0), Vector(15,15,50));
	hMarine.SetOrigin(hMarine.GetOrigin() + Vector(0,0,6));
	
	if (!bRealMode)
		return;
	
	hMarine.SetHealth(120);
	hMarine.SetMaxHealth(120);
	hMarine.DropWeapon(0);
	hMarine.DropWeapon(1);
	local target = Entities.CreateByClassname("info_target");
	target.SetOwner(hMarine);
	target.ValidateScriptScope();
	target.GetScriptScope().delay <- Time();
	target.GetScriptScope().CreateParticle <- CreateParticle;
	target.GetScriptScope().cTarget <- MarineManager[GetMarineIndex(hMarine)];
	target.GetScriptScope().ShamanThinkFunc <- ShamanThinkFunc;
	AddThinkToEnt(target, "ShamanThinkFunc");
}

function ChangeHarvester(hMarine, bRealMode)
{
	hMarine.SetModel("models/aliens/harvester/harvester.mdl");
	hMarine.SetSize(Vector(-15,-15,0), Vector(15,15,50));
	hMarine.SetOrigin(hMarine.GetOrigin() + Vector(0,0,6));
	
	if (!bRealMode)
		return;
	
	if (hMarine.GetMarineName() == "Crash")
	{
		hMarine.SetHealth(460);
		hMarine.SetMaxHealth(460);
	}
	else
	{
		hMarine.SetHealth(500);
		hMarine.SetMaxHealth(500);
	}
	hMarine.DropWeapon(0);
	hMarine.DropWeapon(1);
	local target = Entities.CreateByClassname("info_target");
	target.SetOwner(hMarine);
	target.ValidateScriptScope();
	target.GetScriptScope().delay <- Time();
	target.GetScriptScope().MaxFunc <- MaxFunc;
	target.GetScriptScope().LaunchVector <- LaunchVector;
	target.GetScriptScope().DamageFilter <- DamageFilter;
	target.GetScriptScope().HarvesterThinkFunc <- HarvesterThinkFunc;
	AddThinkToEnt(target, "HarvesterThinkFunc");
}

function RandomSkinNoMed()
{
	local SkinArray = [1, 3, 4];
	return SkinArray[RandomInt(0, 2)];
}

function RandomWeapon()
{
	switch (RandomInt(0, 3))
	{
		case 0:
			return "models/weapons/assaultrifle/assaultrifle.mdl";
		case 1:
			return "models/weapons/prototype/prototyperifle.mdl";
		case 2:
			return "models/weapons/combatrifle/combatrifle.mdl";
		case 3:
			return "models/weapons/heavyrifle/heavyrifle.mdl";
	}
	return "models/weapons/assaultrifle/assaultrifle.mdl";
}

function DamageFilter(strType)
{
	local Damage = 0;
	switch(strType)
	{
		case "Uber":
			Damage = 10;
		case "Ranger":
			Damage = 5;
		case "Xenomite":
			Damage = 5;
	}
	return Damage + Convars.GetFloat("asw_skill") * 10;
}

function DroneTargetFilter(strName)
{
	local bValue = false;
	switch(strName)
	{
		case "prop_physics":
			bValue = true;
			break;
		case "asw_door":
			bValue = true;
			break;
		case "asw_barrel_explosive":
			bValue = true;
			break;
		case "asw_barrel_radioactive":
			bValue = true;
			break;
		case "asw_sentry_base":
			bValue = true;
			break;
		case "asw_marine":
			bValue = false;
			break;
		case "func_breakable_surf":
			bValue = true;
			break;
	}
	return bValue;
}

function RangerSoundScript(hVictim)
{
	if (hVictim == null)
		return "Ranger.projectileImpactWorld";
	if (hVictim.IsAlien() || hVictim.GetClassname() == "asw_marine")
		return "Ranger.projectileImpactPlayer";
	else
		return "Ranger.projectileImpactWorld";
}

function GetMarineIndex(hMarine)
{
	local strName = hMarine.GetMarineName();
	foreach (index, val in MarineManager)
	{
		if (strName == val.m_strName)
			return index;
	}
	return 0;
}

function MaxFunc(One, Two)
{
	if (One > Two)
		return One;
	return Two;
}

function LaunchVector(src, dest, gravity, flightTime)
{
	if (flightTime == 0.0)
	{
		flightTime = MaxFunc(0.8, sqrt(((dest - src).Length() * 1.5) / gravity));
	}
	local H = dest.z - src.z ; 
	local azimuth = dest-src;
	azimuth.z = 0;
	local D = azimuth.Length();
	azimuth *= 1 / D;

	local Vy = (H / flightTime + 0.5 * gravity * flightTime);
	local Vx = (D / flightTime);
	local ret = azimuth * Vx;
	ret.z = Vy;
	return ret;
}

function DroneThinkFunc()
{
	local hMarine = cTarget.m_hMarine;
	if (hMarine && hMarine.IsValid())
	{
		local hWeapon = NetProps.GetPropEntity(hMarine, "m_hActiveWeapon");
		if (hWeapon != null)
		{
			hMarine.DropWeapon(0);
			hMarine.DropWeapon(1);
		}
		if (!cTarget.m_bIsAttacking)
		{
			if (NetProps.GetPropFloat(hMarine, "m_flPoseParameter") == 0.5)
			{
				if (cTarget.m_hRunProp.slot != null)
				{
					cTarget.m_hRunProp.slot.Destroy();
					cTarget.m_hRunProp.slot = null;
				}
				if (cTarget.m_hIdleProp.slot == null)
				{
					local vecAngles = hMarine.GetAngles();
					cTarget.m_hIdleProp.slot <- Entities.CreateByClassname("prop_dynamic");
					cTarget.m_hIdleProp.slot.__KeyValueFromString("model", "models/aliens/drone/drone.mdl");
					cTarget.m_hIdleProp.slot.__KeyValueFromFloat("modelscale", 1.3);
					cTarget.m_hIdleProp.slot.__KeyValueFromInt("DisableBoneFollowers", 1);
					cTarget.m_hIdleProp.slot.__KeyValueFromString("solid", "0");
					cTarget.m_hIdleProp.slot.SetOrigin(hMarine.GetOrigin());
					cTarget.m_hIdleProp.slot.SetLocalAngles(vecAngles.x, vecAngles.y, vecAngles.z);
					DoEntFire("!self", "SetDefaultAnimation", "Idle", 0, hMarine, cTarget.m_hIdleProp.slot);
					DoEntFire("!self", "SetAnimation", "Idle", 0, hMarine, cTarget.m_hIdleProp.slot);
					DoEntFire("!self", "SetParent", "!activator", 0, hMarine, cTarget.m_hIdleProp.slot);
					cTarget.m_hIdleProp.slot.Spawn();
				}
			}
			else
			{
				if (cTarget.m_hIdleProp.slot != null)
				{
					cTarget.m_hIdleProp.slot.Destroy();
					cTarget.m_hIdleProp.slot = null;
				}
				if (cTarget.m_hRunProp.slot == null)
				{
					local vecAngles = hMarine.GetAngles();
					cTarget.m_hRunProp.slot <- Entities.CreateByClassname("prop_dynamic");
					cTarget.m_hRunProp.slot.__KeyValueFromString("model", "models/aliens/drone/drone.mdl");
					cTarget.m_hRunProp.slot.__KeyValueFromFloat("modelscale", 1.3);
					cTarget.m_hRunProp.slot.__KeyValueFromInt("DisableBoneFollowers", 1);
					cTarget.m_hRunProp.slot.__KeyValueFromString("solid", "0");
					cTarget.m_hRunProp.slot.SetOrigin(hMarine.GetOrigin());
					cTarget.m_hRunProp.slot.SetLocalAngles(vecAngles.x, vecAngles.y, vecAngles.z);
					DoEntFire("!self", "SetDefaultAnimation", "Run", 0, hMarine, cTarget.m_hRunProp.slot);
					DoEntFire("!self", "SetAnimation", "Run", 0, hMarine, cTarget.m_hRunProp.slot);
					DoEntFire("!self", "SetParent", "!activator", 0, hMarine, cTarget.m_hRunProp.slot);
					cTarget.m_hRunProp.slot.Spawn();
				}
			}
		}
		
		if (NetProps.GetPropInt(hMarine, "m_bFaceMeleeYaw"))
		{
			NetProps.SetPropInt(hMarine, "m_bFaceMeleeYaw", 0);
			if (delay + 0.61 <= Time())
			{
				cTarget.m_bIsAttacking = true;
				if (cTarget.m_hIdleProp.slot != null)
				{
					cTarget.m_hIdleProp.slot.Destroy();
					cTarget.m_hIdleProp.slot = null;
				}
				if (cTarget.m_hRunProp.slot != null)
				{
					cTarget.m_hRunProp.slot.Destroy();
					cTarget.m_hRunProp.slot = null;
				}
				hMarine.EmitSound("ASW_Drone.Attack");
				hMarine.__KeyValueFromInt("modelscale", 0);
				local vecAngles = hMarine.GetAngles();
				local hProp = Entities.CreateByClassname("prop_dynamic");
				hProp.__KeyValueFromString("model", "models/aliens/drone/drone.mdl");
				hProp.__KeyValueFromFloat("modelscale", 1.3);
				hProp.__KeyValueFromInt("DisableBoneFollowers", 1);
				hProp.__KeyValueFromString("solid", "0");
				hProp.SetOrigin(hMarine.GetOrigin());
				hProp.SetLocalAngles(vecAngles.x, vecAngles.y, vecAngles.z);
				DoEntFire("!self", "SetDefaultAnimation", "Attack02", 0, hMarine, hProp);
				DoEntFire("!self", "SetAnimation", "Attack02", 0, hMarine, hProp);
				DoEntFire("!self", "SetParent", "!activator", 0, hMarine, hProp);
				hProp.Spawn();
				DoEntFire("!self", "Kill", "", 0.6, null, hProp);
				//DoEntFire("!self", "AddOutput", "modelscale 1.3", 0.6, null, hMarine);
				
				local hTimer = Entities.CreateByClassname("logic_timer");
				hTimer.__KeyValueFromFloat("RefireTime", 0.5);
				DoEntFire("!self", "Disable", "", 0, null, hTimer);
				hTimer.ValidateScriptScope();
				
				hTimer.GetScriptScope().cTarget <- cTarget;
				hTimer.GetScriptScope().TimerFunc <- function()
				{
					cTarget.m_bIsAttacking = false;
					
					self.DisconnectOutput("OnTimer", "TimerFunc");
					self.Destroy();	
				}
				hTimer.ConnectOutput("OnTimer", "TimerFunc");
				DoEntFire("!self", "Enable", "", 0, null, hTimer);
								
				local hEntity = null;
				while((hEntity = Entities.FindInSphere(hEntity, hMarine.GetOrigin() + hMarine.GetForwardVector() * 100, 60)) != null)
				{
					if (hEntity != hMarine && (hEntity.IsAlien() || DroneTargetFilter(hEntity.GetClassname())))
					{
						local dirVector = hEntity.GetOrigin() - hMarine.GetOrigin();
						local dirVectorNoZ = Vector(dirVector.x, dirVector.y, 0);
						hEntity.SetVelocity(dirVectorNoZ * (1 / dirVectorNoZ.Length()) * 550 + Vector(0, 0, 300));
						hEntity.TakeDamage(DamageFilter("Uber"), 4, hMarine);
					}
				}
				delay <- Time();
			}
		}
	}
	else
		self.Destroy();
	return 0.1;
}

function RangerThinkFunc()
{
	local hMarine = self.GetOwner();
	if (hMarine && hMarine.IsValid())
	{
		local hWeapon = NetProps.GetPropEntity(hMarine, "m_hActiveWeapon");
		if (hWeapon != null)
		{
			hMarine.DropWeapon(0);
			hMarine.DropWeapon(1);
		}
		
		if (NetProps.GetPropInt(hMarine, "m_bFaceMeleeYaw"))
		{
			NetProps.SetPropInt(hMarine, "m_bFaceMeleeYaw", 0);
			if (delay + 1.6 <= Time())
			{
				hMarine.EmitSound("Ranger.fire");
				hMarine.EmitSound("ASW_Ranger_Projectile.Spawned");
				hMarine.__KeyValueFromInt("modelscale", 0);
				local vecAngles = hMarine.GetAngles();
				local hProp = Entities.CreateByClassname("prop_dynamic");
				hProp.__KeyValueFromString("model", "models/aliens/mortar3/mortar3.mdl");
				hProp.__KeyValueFromInt("DisableBoneFollowers", 1);
				hProp.__KeyValueFromString("solid", "0");
				hProp.SetOrigin(hMarine.GetOrigin());
				hProp.SetLocalAngles(vecAngles.x, vecAngles.y, vecAngles.z);
				DoEntFire("!self", "SetDefaultAnimation", "fire_02", 0, hMarine, hProp);
				DoEntFire("!self", "SetAnimation", "fire_02", 0, hMarine, hProp);
				DoEntFire("!self", "SetParent", "!activator", 0, hMarine, hProp);
				hProp.Spawn();
				DoEntFire("!self", "Kill", "", 1.5, null, hProp);
				DoEntFire("!self", "AddOutput", "modelscale 1.0", 1.5, null, hMarine);
				
				CreateParticle(3, "ranger_launch", hMarine.GetOrigin() + hMarine.GetForwardVector() * 15 + Vector(0, 0, 32));
				local hSpit = Entities.CreateByClassname("info_particle_system");		
				hSpit.__KeyValueFromString("effect_name", "ranger_projectile_main_trail");
				hSpit.__KeyValueFromString("start_active", "1");
				hSpit.SetOrigin(hMarine.GetOrigin() + hMarine.GetForwardVector() * 15 + Vector(0, 0, 32));
				hSpit.SetAnglesVector(hMarine.GetAngles());
				hSpit.ValidateScriptScope();
				hSpit.GetScriptScope().iCount <- 3.0;
				hSpit.GetScriptScope().hAttacker <- hMarine;
				hSpit.GetScriptScope().CreateParticle <- CreateParticle;
				hSpit.GetScriptScope().DamageFilter <- DamageFilter;
				hSpit.GetScriptScope().DroneTargetFilter <- DroneTargetFilter;
				hSpit.GetScriptScope().RangerSoundScript <- RangerSoundScript;
				hSpit.GetScriptScope().MoveForward <- MoveForward;
				AddThinkToEnt(hSpit, "MoveForward");
				hSpit.Spawn();
				hSpit.Activate();
				
				local hTimer = Entities.CreateByClassname("logic_timer");
				hTimer.__KeyValueFromFloat("RefireTime", 0.1);
				DoEntFire("!self", "Disable", "", 0, null, hTimer);
				hTimer.ValidateScriptScope();
				
				hTimer.GetScriptScope().hMarine <- hMarine;
				hTimer.GetScriptScope().CreateParticle <- CreateParticle;
				hTimer.GetScriptScope().DamageFilter <- DamageFilter;
				hTimer.GetScriptScope().DroneTargetFilter <- DroneTargetFilter;
				hTimer.GetScriptScope().RangerSoundScript <- RangerSoundScript;
				hTimer.GetScriptScope().MoveForward <- MoveForward;
				hTimer.GetScriptScope().TimerFunc <- function()
				{
					local hSpit = Entities.CreateByClassname("info_particle_system");
					hSpit.__KeyValueFromString("effect_name", "ranger_projectile_main_trail");
					hSpit.__KeyValueFromString("start_active", "1");
					hSpit.SetOrigin(hMarine.GetOrigin() + hMarine.GetForwardVector() * 15 + Vector(0, 0, 32));
					hSpit.SetAnglesVector(hMarine.GetAngles() + Vector(0, 4, 0));
					hSpit.ValidateScriptScope();
					hSpit.GetScriptScope().iCount <- 3.0;
					hSpit.GetScriptScope().hAttacker <- hMarine;
					hSpit.GetScriptScope().CreateParticle <- CreateParticle;
					hSpit.GetScriptScope().DamageFilter <- DamageFilter;
					hSpit.GetScriptScope().DroneTargetFilter <- DroneTargetFilter;
					hSpit.GetScriptScope().RangerSoundScript <- RangerSoundScript;
					hSpit.GetScriptScope().MoveForward <- MoveForward;
					AddThinkToEnt(hSpit, "MoveForward");	
					hSpit.Spawn();
					hSpit.Activate();
					
					self.DisconnectOutput("OnTimer", "TimerFunc");
					self.Destroy();	
				}
				hTimer.ConnectOutput("OnTimer", "TimerFunc");
				DoEntFire("!self", "Enable", "", 0, null, hTimer);
									
				local hTimer2 = Entities.CreateByClassname("logic_timer");
				hTimer2.__KeyValueFromFloat("RefireTime", 0.2);
				DoEntFire("!self", "Disable", "", 0, null, hTimer2);
				hTimer2.ValidateScriptScope();
				
				hTimer2.GetScriptScope().hMarine <- hMarine;
				hTimer2.GetScriptScope().CreateParticle <- CreateParticle;
				hTimer2.GetScriptScope().DamageFilter <- DamageFilter;
				hTimer2.GetScriptScope().DroneTargetFilter <- DroneTargetFilter;
				hTimer2.GetScriptScope().RangerSoundScript <- RangerSoundScript;
				hTimer2.GetScriptScope().MoveForward <- MoveForward;
				hTimer2.GetScriptScope().TimerFunc <- function()
				{
					local hSpit = Entities.CreateByClassname("info_particle_system");
					hSpit.__KeyValueFromString("effect_name", "ranger_projectile_main_trail");
					hSpit.__KeyValueFromString("start_active", "1");
					hSpit.SetOrigin(hMarine.GetOrigin() + hMarine.GetForwardVector() * 15 + Vector(0, 0, 32));
					hSpit.SetAnglesVector(hMarine.GetAngles() + Vector(0, -4, 0));
					hSpit.ValidateScriptScope();
					hSpit.GetScriptScope().iCount <- 3.0;
					hSpit.GetScriptScope().hAttacker <- hMarine;
					hSpit.GetScriptScope().CreateParticle <- CreateParticle;
					hSpit.GetScriptScope().DamageFilter <- DamageFilter;
					hSpit.GetScriptScope().DroneTargetFilter <- DroneTargetFilter;
					hSpit.GetScriptScope().RangerSoundScript <- RangerSoundScript;
					hSpit.GetScriptScope().MoveForward <- MoveForward;
					AddThinkToEnt(hSpit, "MoveForward");	
					hSpit.Spawn();
					hSpit.Activate();
					
					self.DisconnectOutput("OnTimer", "TimerFunc");
					self.Destroy();	
				}
				hTimer2.ConnectOutput("OnTimer", "TimerFunc");
				DoEntFire("!self", "Enable", "", 0, null, hTimer2);
					
				delay <- Time();
			}
		}
	}
	else
		self.Destroy();
	return 0.1;
}

function MortarThinkFunc()
{
	local hMarine = self.GetOwner();
	if (hMarine && hMarine.IsValid())
	{
		local hWeapon = NetProps.GetPropEntity(hMarine, "m_hActiveWeapon");
		if (hWeapon != null)
		{
			hMarine.DropWeapon(0);
			hMarine.DropWeapon(1);
		}

		if (NetProps.GetPropInt(hMarine, "m_bFaceMeleeYaw"))
		{
			NetProps.SetPropInt(hMarine, "m_bFaceMeleeYaw", 0);
			if (delay + 1.6 <= Time())
			{
				hMarine.EmitSound("ASW_MortarBug.Spit");
				hMarine.__KeyValueFromInt("modelscale", 0);
				local vecAngles = hMarine.GetAngles();
				local hProp = Entities.CreateByClassname("prop_dynamic");
				hProp.__KeyValueFromString("model", "models/aliens/mortar/mortar.mdl");
				hProp.__KeyValueFromInt("DisableBoneFollowers", 1);
				hProp.__KeyValueFromString("solid", "0");
				hProp.SetOrigin(hMarine.GetOrigin());
				hProp.SetLocalAngles(vecAngles.x, vecAngles.y, vecAngles.z);
				DoEntFire("!self", "SetDefaultAnimation", "spit", 0, hMarine, hProp);
				DoEntFire("!self", "SetAnimation", "spit", 0, hMarine, hProp);
				DoEntFire("!self", "SetParent", "!activator", 0, hMarine, hProp);
				hProp.Spawn();
				DoEntFire("!self", "Kill", "", 1.5, null, hProp);
				DoEntFire("!self", "AddOutput", "modelscale 1.0", 1.5, null, hMarine);
				
				local hVomitus1 = Entities.CreateByClassname("asw_mortarbug_shell");		
				hVomitus1.SetOrigin(hMarine.GetOrigin() + hMarine.GetForwardVector() * 30 + Vector(0, 0, 60));
				hVomitus1.SetForwardVector(hMarine.GetForwardVector());
				hVomitus1.SetName("mortarShell_player");
				hVomitus1.SetOwner(hMarine);
				hVomitus1.Spawn();
				hVomitus1.Activate();
				
				local hVomitus2 = Entities.CreateByClassname("asw_mortarbug_shell");		
				hVomitus2.SetOrigin(hMarine.GetOrigin() + hMarine.GetForwardVector() * 30 + Vector(0, 0, 60));
				hVomitus2.SetForwardVector(hMarine.GetForwardVector());
				hVomitus2.SetName("mortarShell_player");
				hVomitus2.SetOwner(hMarine);
				hVomitus2.Spawn();
				hVomitus2.Activate();
				
				local hVomitus3 = Entities.CreateByClassname("asw_mortarbug_shell");		
				hVomitus3.SetOrigin(hMarine.GetOrigin() + hMarine.GetForwardVector() * 30 + Vector(0, 0, 60));
				hVomitus3.SetForwardVector(hMarine.GetForwardVector());
				hVomitus3.SetName("mortarShell_player");
				hVomitus3.SetOwner(hMarine);
				hVomitus3.Spawn();
				hVomitus3.Activate();
				
				local player = null;
				local VecCrosshairOrigin = null;
				while((player = Entities.FindByClassname(player, "player")) != null)
				{
					local m_hMarine = NetProps.GetPropEntity(player, "m_hMarine");
					if (m_hMarine != null && m_hMarine == hMarine)
						VecCrosshairOrigin = NetProps.GetPropVector(player, "m_vecCrosshairTracePos");
				}

				local marinePos = hMarine.GetOrigin();
				local gravity = 500.0;
				local flightTime = 0.0;
				
				hVomitus1.SetVelocity(LaunchVector(marinePos, VecCrosshairOrigin + hMarine.GetForwardVector() * -70, gravity, flightTime));
				hVomitus2.SetVelocity(LaunchVector(marinePos, VecCrosshairOrigin, gravity, flightTime));
				hVomitus3.SetVelocity(LaunchVector(marinePos, VecCrosshairOrigin + hMarine.GetForwardVector() * 70, gravity, flightTime));
				delay <- Time();
			}
		}
	}
	else
		self.Destroy();
	return 0.1;
}

function ShamanThinkFunc()
{
	local hMarine = cTarget.m_hMarine;
	if (hMarine && hMarine.IsValid())
	{
		local hWeapon = NetProps.GetPropEntity(hMarine, "m_hActiveWeapon");
		if (hWeapon != null)
		{
			hMarine.DropWeapon(0);
			hMarine.DropWeapon(1);
		}
		
		if (NetProps.GetPropInt(hMarine, "m_bFaceMeleeYaw"))
		{
			NetProps.SetPropInt(hMarine, "m_bFaceMeleeYaw", 0);
			if (delay + 9 <= Time())
			{
				hMarine.EmitSound("ASW_Extinguisher.Stop");
				DropFreezeGrenade(0, 1, 40, hMarine.GetOrigin() + hMarine.GetForwardVector() * 50);
				local hEntity = null;
				while((hEntity = Entities.FindInSphere(hEntity, hMarine.GetOrigin() + hMarine.GetForwardVector() * 50, 32)) != null)
				{
					if (hEntity.IsAlien() || hEntity.GetClassname() == "asw_marine")
					{
						hEntity.Extinguish();
						if (hEntity.GetClassname() == "asw_marine")
						{
							hEntity.CureInfestation();
							if (NetProps.GetPropInt(hEntity, "m_bOnFire"))
								NetProps.SetPropInt(hEntity, "m_bOnFire", 0);
						}
					}
				}
				delay <- Time();
			}
		}
		
		if (hMarine.IsInhabited())
		{
			local VecCrosshairOrigin = NetProps.GetPropVector(hMarine.GetCommander(), "m_vecCrosshairTracePos");
			if (VecCrosshairOrigin != null)
			{
				local hEntity = null;
				local bShouldDelete = true;
				while((hEntity = Entities.FindInSphere(hEntity, VecCrosshairOrigin, 40)) != null)
				{
					if (hEntity.GetClassname() == "asw_marine")
					{
						if (hEntity.GetHealth() <= hEntity.GetMaxHealth())
						{
							if (!cTarget.m_bEmiting)
							{
								hMarine.EmitSound("ASW_MedGrenade.ActiveLoop");
								cTarget.m_bEmiting = true;
							}

							hEntity.SetHealth(hEntity.GetHealth() + 1);
							
							bShouldDelete = false;
							if (cTarget.m_hBeamTarget.slot == null)
							{
								cTarget.m_hBeamTarget.slot <- Entities.CreateByClassname("info_target");
								cTarget.m_hBeamTarget.slot.SetOrigin(hEntity.GetOrigin() + Vector(0, 0, 20));
								cTarget.m_hBeamTarget.slot.__KeyValueFromString("spawnflags", "2");
								cTarget.m_hBeamTarget.slot.__KeyValueFromString("targetname", cTarget.m_strBeamTargetname);
								cTarget.m_hBeamTarget.slot.Spawn();
								cTarget.m_hBeamTarget.slot.Activate();
							}
							if (cTarget.m_hBeamParticle.slot == null)
							{
								cTarget.m_hBeamParticle.slot <- Entities.CreateByClassname("info_particle_system");						
								cTarget.m_hBeamParticle.slot.__KeyValueFromString("effect_name", "shaman_heal_attach");
								cTarget.m_hBeamParticle.slot.__KeyValueFromString("cpoint1", cTarget.m_strBeamTargetname);
								cTarget.m_hBeamParticle.slot.__KeyValueFromString("start_active", "1");
								cTarget.m_hBeamParticle.slot.SetOrigin(hMarine.GetOrigin() + Vector(0, 0, 25));
								cTarget.m_hBeamParticle.slot.Spawn();
								cTarget.m_hBeamParticle.slot.Activate();
								DoEntFire("!self", "SetParent", "!activator", 0, hMarine, cTarget.m_hBeamParticle.slot);
							}
							DoEntFire("!self", "SetParent", "!activator", 0, hEntity, cTarget.m_hBeamTarget.slot);
						}
					}
				}
				if (bShouldDelete)
				{
					if (cTarget.m_bEmiting)
					{
						hMarine.StopSound("ASW_MedGrenade.ActiveLoop");
						cTarget.m_bEmiting = false;
					}
					if (cTarget.m_hBeamTarget.slot != null)
					{
						DoEntFire("!self", "Kill", "", 0, null, cTarget.m_hBeamTarget.slot);
						cTarget.m_hBeamTarget.slot <- null;
					}
					if (cTarget.m_hBeamParticle.slot != null)
					{
						DoEntFire("!self", "Kill", "", 0, null, cTarget.m_hBeamParticle.slot);
						cTarget.m_hBeamParticle.slot <- null;
					}
				}
			}
		}
	}
	else
		self.Destroy();
	return 0.1;
}

function HarvesterThinkFunc()
{
	local hMarine = self.GetOwner();
	if (hMarine && hMarine.IsValid())
	{
		local hWeapon = NetProps.GetPropEntity(hMarine, "m_hActiveWeapon");
		if (hWeapon != null)
		{
			hMarine.DropWeapon(0);
			hMarine.DropWeapon(1);
		}
		
		if (NetProps.GetPropInt(hMarine, "m_bFaceMeleeYaw"))
		{
			NetProps.SetPropInt(hMarine, "m_bFaceMeleeYaw", 0);
			if (delay + 1 <= Time())
			{
				hMarine.EmitSound("ASW_Harvester.Spawn");
				local hXeno = Entities.CreateByClassname("asw_tesla_trap");
				hXeno.__KeyValueFromInt("renderamt", 0);
				hXeno.__KeyValueFromInt("rendermode", 1);
				hXeno.__KeyValueFromString("disableshadows", "1");
				hXeno.__KeyValueFromString("disablereceiveshadows", "1");
				hXeno.SetOrigin(hMarine.GetOrigin() + hMarine.GetForwardVector() * 32 + Vector(0, 0, 10));
				hXeno.SetAnglesVector(hMarine.GetAngles());
				hXeno.Spawn();
				NetProps.SetPropInt(hXeno, "m_iAmmo", 1);
				NetProps.SetPropInt(hXeno, "m_iMaxAmmo", 1);
				NetProps.SetPropInt(hXeno, "m_bAssembled", 1);
				NetProps.SetPropFloat(hXeno, "m_flRadius", 64);
				NetProps.SetPropFloat(hXeno, "m_flDamage", DamageFilter("Xenomite"));
				hXeno.EmitSound("ASW_Parasite.Attack");
				
				local vecAngles = hMarine.GetAngles();
				local hProp = Entities.CreateByClassname("prop_dynamic");
				hProp.__KeyValueFromString("model", "models/aliens/parasite/parasite.mdl");
				hProp.__KeyValueFromString("SetBodyGroup", "1");
				hProp.__KeyValueFromInt("DisableBoneFollowers", 1);
				hProp.__KeyValueFromString("solid", "0");
				hProp.SetOrigin(hXeno.GetOrigin());
				hProp.SetLocalAngles(vecAngles.x, vecAngles.y, vecAngles.z);

				DoEntFire("!self", "SetDefaultAnimation", "Jump_Attack", 0, hXeno, hProp);
				DoEntFire("!self", "SetAnimation", "Jump_Attack", 0, hXeno, hProp);
				DoEntFire("!self", "SetParent", "!activator", 0, hXeno, hProp);
				hProp.Spawn();
				DoEntFire("!self", "Kill", "", 5, null, hXeno);
				DoEntFire("!self", "Kill", "", 5, null, hProp);
				
				local player = null;
				local VecCrosshairOrigin = null;
				while((player = Entities.FindByClassname(player, "player")) != null)
				{
					local m_hMarine = NetProps.GetPropEntity(player, "m_hMarine");
					if (m_hMarine != null && m_hMarine == hMarine)
						VecCrosshairOrigin = NetProps.GetPropVector(player, "m_vecCrosshairTracePos");
				}
				hXeno.SetVelocity(LaunchVector(hMarine.GetOrigin(), VecCrosshairOrigin, 500.0, 0.0));
				delay <- Time();
			}
		}
	}
	else
		self.Destroy();
	return 0.1;
}

function MoveForward()
{
	self.SetOrigin(self.GetOrigin() + self.GetForwardVector() * iCount);
	iCount += 0.09;
	local bShouldDestroy = false;
	local hStuff = null;
	
	local hEntity = null;
	while ((hEntity = Entities.FindInSphere(hEntity, self.GetOrigin(), 7)) != null)
	{
		if (hEntity != hAttacker && (hEntity.IsAlien() || DroneTargetFilter(hEntity.GetClassname())))
		{
			hStuff = hEntity;
			bShouldDestroy = true;
			hEntity.TakeDamage(DamageFilter("Ranger"), 4098, hAttacker);
		}
	}
	if (bShouldDestroy)
	{
		self.EmitSound(RangerSoundScript(hStuff));
		CreateParticle(3, "ranger_projectile_hit", self.GetOrigin());
		self.Destroy();
	}
	else if (iCount > 14)
	{
		self.EmitSound("Ranger.projectileImpactWorld");
		CreateParticle(3, "ranger_projectile_hit", self.GetOrigin());
		self.Destroy();
	}
	
	return 0.01;
}

function IsMarineInfested()
{
	if (NetProps.GetPropFloat(self.GetOwner(), "m_fInfestedTime") == 0)
	{
		local cTarget = MarineManager[GetMarineIndex(self.GetOwner())];
		if (cTarget.IsValid())
			cTarget.SetOnFire(false);
		self.GetOwner().StopSound("ASW_Weapon_Flamer.FlameLoop");
		self.GetOwner().EmitSound("ASW_Weapon_Flamer.FlameStop");
		self.Destroy();
	}
	
	return 0.1;
}

function IsInfesting()
{
	if (self.IsValid() && NetProps.GetPropInt(self.GetOwner().GetOwner(), "m_bInfesting") && self.GetName() == "parasitePropWP")
	{
		DoEntFire("!self", "SetDefaultAnimation", "CrouchIdle", 0, self.GetOwner().GetOwner(), self.GetOwner());
		DoEntFire("!self", "SetAnimation", "CrouchIdle", 0, self.GetOwner().GetOwner(), self.GetOwner());
		local hFlameFX = Entities.CreateByClassname("info_particle_system");
		hFlameFX.__KeyValueFromString("effect_name", "asw_flamethrower");
		hFlameFX.__KeyValueFromString("start_active", "1");
		DoEntFire("!self", "SetParent", "!activator", 0, self, hFlameFX);
		DoEntFire("!self", "SetParentAttachment", "flame", 0, null, hFlameFX);
		hFlameFX.SetOwner(self);
		hFlameFX.Spawn();
		hFlameFX.Activate();
		hFlameFX.ValidateScriptScope();
		hFlameFX.GetScriptScope().SetFlameAngles <- SetFlameAngles;
		AddThinkToEnt(hFlameFX, "SetFlameAngles");
		self.SetName("parasitePropWP_Ex");
	}
	return 0.1;
}

function SetFlameAngles()
{
	if (self.tostring().slice(0, 2) != "(i")
	{
		if (self.GetOwner() != null)
			self.SetForwardVector(self.GetOwner().GetForwardVector() + Vector(-1, 0, 0));
		else
			self.Destroy();
	}
	else
		return 100;
	return 0.1;
}

function DroneDied()
{
	local hProp = null;
	while ((hProp = Entities.FindByClassnameWithin(hProp, "prop_dynamic", self.GetOrigin(), 9)) != null)
	{
		if (hProp.GetName() == "droneProp")
			hProp.Destroy();
	}
	
	self.DisconnectOutput("OnDeath", "DroneDied");
}

function RangerDied()
{
	local hProp = null;
	while ((hProp = Entities.FindByClassnameWithin(hProp, "prop_dynamic", self.GetOrigin(), 9)) != null)
	{
		if (hProp.GetName() == "rangerProp")
			hProp.Destroy();
	}
	
	self.DisconnectOutput("OnDeath", "RangerDied");
}

function BoomerDied()
{
	local hProp = null;
	while ((hProp = Entities.FindByClassnameWithin(hProp, "prop_dynamic", self.GetOrigin(), 9)) != null)
	{
		if (hProp.GetName() == "boomerProp")
			hProp.Destroy();
	}
	
	self.DisconnectOutput("OnDeath", "BoomerDied");
}

function EggDied()
{
	local hProp = null;
	while ((hProp = Entities.FindByClassnameWithin(hProp, "prop_dynamic", self.GetOrigin(), 9)) != null)
	{
		if (hProp.GetName() == "eggProp")
			hProp.Destroy();
	}
	
	self.DisconnectOutput("OnDeath", "EggDied");
}

function BiomassDied()
{
	local hProp = null;
	while ((hProp = Entities.FindByClassnameWithin(hProp, "prop_dynamic", self.GetOrigin(), 9)) != null)
	{
		if (hProp.GetName() == "biomassProp")
			hProp.Destroy();
	}
	
	self.DisconnectOutput("OnDeath", "BiomassDied");
}

function ShamanDied()
{
	local hProp = null;
	while ((hProp = Entities.FindByClassnameWithin(hProp, "prop_dynamic", self.GetOrigin(), 9)) != null)
	{
		if (hProp.GetName() == "shamanProp")
			hProp.Destroy();
	}
	
	self.DisconnectOutput("OnDeath", "ShamanDied");
}

function XenoDied()
{
	local hProp = null;
	while ((hProp = Entities.FindByClassnameWithin(hProp, "prop_dynamic", self.GetOrigin(), 1)) != null)
	{
		if (hProp.GetName() == "xenomiteProp")
			hProp.Destroy();
	}
	
	self.DisconnectOutput("OnDeath", "XenoDied");
}

function ParasDied()
{
	local hProp = null;
	while ((hProp = Entities.FindByClassnameWithin(hProp, "prop_dynamic", self.GetOrigin(), 9)) != null)
	{
		if (hProp.GetName() == "parasiteProp" || hProp.GetName() == "parasiteProp_Ex" || hProp.GetName() == "parasitePropWP" || hProp.GetName() == "parasitePropWP_Ex")
			hProp.Destroy();
	}

	self.DisconnectOutput("OnDeath", "ParasDied");
}

function CreateParticle(fAliveTime, strParticleClass, VecOrigin, hParent = null, VecAngles = Vector(0, 0, 0))
{
	local hParticle = Entities.CreateByClassname("info_particle_system");
	hParticle.__KeyValueFromString("effect_name", strParticleClass);
	hParticle.__KeyValueFromString("start_active", "1");
	hParticle.SetOrigin(VecOrigin);
	hParticle.SetAnglesVector(VecAngles);
	hParticle.Spawn();
	hParticle.Activate();
	DoEntFire("!self", "Kill", "", fAliveTime, null, hParticle);
	
	if (hParent != null)
		DoEntFire("!self", "SetParent", "!activator", 0, hParent, hParticle);
}

function CreateCorpse(hVictim, strModel, strSkin = null, iModelScale = null)
{
	local hCorpse = Entities.CreateByClassname("asw_client_corpse");
	hCorpse.__KeyValueFromString("model", strModel);
	hCorpse.__KeyValueFromInt("DisableBoneFollowers", 1);
	
	if (strSkin != null)
	{
		hCorpse.__KeyValueFromString("skin", strSkin);
		hCorpse.__KeyValueFromString("SetBodyGroup", strSkin);
	}
	
	if (iModelScale != null)
		hCorpse.__KeyValueFromFloat("modelscale", iModelScale);
	
	hCorpse.SetOrigin(hVictim.GetOrigin());
	hCorpse.SetAnglesVector(hVictim.GetAngles());
	hCorpse.Spawn();
	hCorpse.Activate();
	
	DoEntFire("!self", "Kill", "", 5, null, hCorpse);
}

function PrecacheParticles()
{
	local ArrayParticlesStr = ["piercing_spark", "marine_hit_blood", "marine_death_ragdoll", "asw_flamethrower", "rocket_trail_small", "rocket_trail_small_glow", "explosion_air_small", "blink", "thorns_zap_cp1", "thorns_zap", "jj_trail_small", "ranger_launch", "ranger_projectile_hit", "ranger_projectile_main_trail", "shaman_heal_attach", "shaman_heal_healing_fx"];
	
	local VecPosition = Vector(16384, 16384, 16384);
	
	foreach(index, value in ArrayParticlesStr)
		CreateParticle(0.5, value, VecPosition);
}
PrecacheParticles();
