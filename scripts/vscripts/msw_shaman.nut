function ShamanDied()
{
	if (hProp.IsValid())
		hProp.Destroy();
	if (weaponProp.IsValid())
		weaponProp.Destroy();
	
	self.DisconnectOutput("OnDeath", "ShamanDied");
}

self.__KeyValueFromInt("renderamt", 0);
self.__KeyValueFromInt("rendermode", 1);
self.__KeyValueFromString("disableshadows", "1");
self.__KeyValueFromString("disablereceiveshadows", "1");
local vecAngles = self.GetAngles();
hProp <- Entities.CreateByClassname("prop_dynamic");
hProp.__KeyValueFromString("model", "models/swarm/marine/marine.mdl");
hProp.__KeyValueFromInt("DisableBoneFollowers", 1);
hProp.__KeyValueFromInt("skin", 2);
hProp.__KeyValueFromString("SetBodyGroup", "2");
hProp.__KeyValueFromString("solid", "0");
hProp.SetOrigin(self.GetOrigin());
hProp.SetLocalAngles(vecAngles.x, vecAngles.y, vecAngles.z);

DoEntFire("!self", "SetDefaultAnimation", "pistol_run_n_test", 0, self, hProp);
DoEntFire("!self", "SetAnimation", "pistol_run_n_test", 0, self, hProp);
DoEntFire("!self", "SetParent", "!activator", 0, self, hProp);
hProp.SetOwner(self);
hProp.Spawn();
hProp.ValidateScriptScope();

weaponProp <- Entities.CreateByClassname("prop_dynamic");
weaponProp.__KeyValueFromString("model", "models/weapons/healgun/healgun.mdl");
weaponProp.__KeyValueFromString("solid", "0");
weaponProp.SetOrigin(hProp.GetOrigin());
DoEntFire("!self", "SetParent", "!activator", 0, hProp, weaponProp);
DoEntFire("!self", "SetParentAttachment", "RHand", 0, null, weaponProp);
weaponProp.SetOwner(self);
weaponProp.Spawn();

local hTimer = Entities.CreateByClassname("logic_timer");
hTimer.__KeyValueFromFloat("RefireTime", 0.1);
DoEntFire("!self", "Disable", "", 0, null, hTimer);
hTimer.ValidateScriptScope();

hTimer.GetScriptScope().weaponProp <- weaponProp;
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

self.ValidateScriptScope();
self.GetScriptScope().ShamanDied <- ShamanDied;
self.ConnectOutput("OnDeath", "ShamanDied");
