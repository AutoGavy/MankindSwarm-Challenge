IncludeScript("msw_dronepropthinkfunc.nut")

function DroneDied()
{
	if (hProp.IsValid())
		hProp.Destroy();
	if (weaponProp.IsValid())
		weaponProp.Destroy();
	
	self.DisconnectOutput("OnDeath", "DroneDied");
}

self.__KeyValueFromInt("renderamt", 0);
self.__KeyValueFromInt("rendermode", 1);
self.__KeyValueFromString("disableshadows", "1");
self.__KeyValueFromString("disablereceiveshadows", "1");
local vecAngles = self.GetAngles();
hProp <- Entities.CreateByClassname("prop_dynamic");
hProp.__KeyValueFromString("model", "models/humans/group01/female_01.mdl");
hProp.__KeyValueFromInt("DisableBoneFollowers", 1);
hProp.__KeyValueFromString("solid", "0");
hProp.SetOrigin(self.GetOrigin() + Vector(-7, 0, 0));
hProp.SetLocalAngles(vecAngles.x, vecAngles.y, vecAngles.z);

DoEntFire("!self", "SetDefaultAnimation", "run_alert_holding_all", 0, self, hProp);
DoEntFire("!self", "SetAnimation", "run_alert_holding_all", 0, self, hProp);
//DoEntFire("!self", "SetParent", "!activator", 0, self, hProp);
hProp.SetOwner(self);
hProp.Spawn();

propTarget <- Entities.CreateByClassname("info_target");
propTarget.SetOwner(hProp);
propTarget.ValidateScriptScope();
propTarget.GetScriptScope().iCount <- 0;
propTarget.GetScriptScope().SetPropOrgin <- SetPropOrgin;
AddThinkToEnt(propTarget, "SetPropOrgin");

weaponProp <- Entities.CreateByClassname("prop_dynamic");
weaponProp.__KeyValueFromString("model", "models/weapons/chainsaw/chainsaw.mdl");
weaponProp.__KeyValueFromString("solid", "0");
weaponProp.SetOrigin(hProp.GetOrigin());
DoEntFire("!self", "SetParent", "!activator", 0, hProp, weaponProp);
DoEntFire("!self", "SetParentAttachment", "anim_attachment_RH", 0, null, weaponProp);
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

self.ValidateScriptScope();
self.GetScriptScope().DroneDied <- DroneDied;
self.ConnectOutput("OnDeath", "DroneDied");
