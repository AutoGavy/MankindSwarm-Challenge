function RandomSkinNoMed()
{
	local SkinArray = [1, 3, 4];
	return SkinArray[RandomInt(0, 2)];
}

function MortarDied()
{
	if (hProp.IsValid())
		hProp.Destroy();
	if (weaponProp.IsValid())
		weaponProp.Destroy();
	
	self.DisconnectOutput("OnDeath", "MortarDied");
}

self.__KeyValueFromInt("renderamt", 0);
self.__KeyValueFromInt("rendermode", 1);
self.__KeyValueFromString("disableshadows", "1");
self.__KeyValueFromString("disablereceiveshadows", "1");
local vecAngles = self.GetAngles();
hProp <- Entities.CreateByClassname("prop_dynamic");
local iSkin = RandomSkinNoMed();
self.SetName(iSkin.tostring());
hProp.__KeyValueFromString("model", "models/swarm/marine/marine.mdl");
hProp.__KeyValueFromInt("DisableBoneFollowers", 1);
hProp.__KeyValueFromFloat("modelscale", 1.5);
hProp.__KeyValueFromInt("skin", iSkin);
hProp.__KeyValueFromString("SetBodyGroup", iSkin.tostring());
hProp.__KeyValueFromString("solid", "0");
hProp.SetAngles(vecAngles.x, vecAngles.y + 90, vecAngles.z);
hProp.SetOrigin(self.GetOrigin() + self.GetForwardVector() * 60);

DoEntFire("!self", "SetDefaultAnimation", "reload_smg1", 0, self, hProp);
DoEntFire("!self", "SetAnimation", "reload_smg1", 0, self, hProp);
DoEntFire("!self", "SetParent", "!activator", 0, self, hProp);
hProp.Spawn();

weaponProp <- Entities.CreateByClassname("prop_dynamic");
weaponProp.__KeyValueFromString("model", "models/weapons/grenadelauncher/grenadelauncher.mdl");
weaponProp.__KeyValueFromFloat("modelscale", 1.5);
weaponProp.__KeyValueFromString("solid", "0");
weaponProp.SetOrigin(hProp.GetOrigin());
DoEntFire("!self", "SetParent", "!activator", 0, hProp, weaponProp);
DoEntFire("!self", "SetParentAttachment", "RHand", 0, null, weaponProp);
weaponProp.Spawn();

local hTimer = Entities.CreateByClassname("logic_timer");
hTimer.__KeyValueFromFloat("RefireTime", 0.1);
DoEntFire("!self", "Disable", "", 0, null, hTimer);
hTimer.ValidateScriptScope();

hTimer.GetScriptScope().weaponProp <- weaponProp;
hTimer.GetScriptScope().TimerFunc <- function()
{
	if (weaponProp != null && weaponProp.IsValid())
		weaponProp.SetLocalAngles(180, -90, 0);
	
	self.DisconnectOutput("OnTimer", "TimerFunc");
	self.Destroy();	
}
hTimer.ConnectOutput("OnTimer", "TimerFunc");
DoEntFire("!self", "Enable", "", 0, null, hTimer);

self.ValidateScriptScope();
self.GetScriptScope().MortarDied <- MortarDied;
self.ConnectOutput("OnDeath", "MortarDied");
