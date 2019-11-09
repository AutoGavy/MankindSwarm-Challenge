function RandomSkinNoMed()
{
	local SkinArray = [1, 3, 4];
	return SkinArray[RandomInt(0, 2)];
}

function BoomerDied()
{
	if (hProp.IsValid())
		hProp.Destroy();
	
	self.DisconnectOutput("OnDeath", "BoomerDied");
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
hProp.SetOrigin(self.GetOrigin());
hProp.SetLocalAngles(vecAngles.x, vecAngles.y, vecAngles.z);

DoEntFire("!self", "SetDefaultAnimation", "kick", 0, self, hProp);
DoEntFire("!self", "SetAnimation", "kick", 0, self, hProp);
DoEntFire("!self", "SetParent", "!activator", 0, self, hProp);
hProp.Spawn();

self.ValidateScriptScope();
self.GetScriptScope().BoomerDied <- BoomerDied;
self.ConnectOutput("OnDeath", "BoomerDied");
