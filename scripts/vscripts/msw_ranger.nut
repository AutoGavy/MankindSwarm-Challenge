function RandomSkinNoMed()
{
	local SkinArray = [1, 3, 4];
	return SkinArray[RandomInt(0, 2)];
}

function RangerDied()
{
	if (hProp.IsValid())
		hProp.Destroy();
	if (weaponProp.IsValid())
		weaponProp.Destroy();
	
	self.DisconnectOutput("OnDeath", "RangerDied");
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
hProp.__KeyValueFromInt("skin", iSkin);
hProp.__KeyValueFromString("SetBodyGroup", iSkin.tostring());
hProp.__KeyValueFromString("solid", "0");
hProp.SetOrigin(self.GetOrigin());
hProp.SetLocalAngles(vecAngles.x, vecAngles.y, vecAngles.z);

DoEntFire("!self", "SetDefaultAnimation", "CrouchIdle", 0, self, hProp);
DoEntFire("!self", "SetAnimation", "CrouchIdle", 0, self, hProp);
DoEntFire("!self", "SetParent", "!activator", 0, self, hProp);
hProp.Spawn();

weaponProp <- Entities.CreateByClassname("prop_dynamic");
weaponProp.__KeyValueFromString("model", RandomWeapon());
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

self.ValidateScriptScope();
self.GetScriptScope().RangerDied <- RangerDied;
self.ConnectOutput("OnDeath", "RangerDied");
