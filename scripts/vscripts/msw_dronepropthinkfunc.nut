function SetPropOrgin()
{
	if (self.GetOwner() != null && self.GetOwner().GetOwner() != null)
	{
		local vecPropPos = self.GetOwner().GetOrigin();
		local vecDronePos = self.GetOwner().GetOwner().GetOrigin();
		if (iCount < 3)
		{
			if (abs(vecPropPos.x - vecDronePos.x) < 32 && abs(vecPropPos.y - vecDronePos.y) < 32 && abs(vecPropPos.z - vecDronePos.z) < 7)
			{
				self.GetOwner().SetOrigin(vecDronePos);
				iCount++;
			}
			else
			{
				self.GetOwner().SetOrigin(vecDronePos);
				iCount = 0;
			}
		}
		else
		{
			self.GetOwner().SetOrigin(vecDronePos);
			DoEntFire("!self", "SetParent", "!activator", 0, self.GetOwner().GetOwner(), self.GetOwner());
			self.Destroy();
		}
	}
	else
	{
		if (self.GetOwner() != null)
			self.GetOwner().Destroy();
		self.Destroy();
	}
	return 0.1;
}
