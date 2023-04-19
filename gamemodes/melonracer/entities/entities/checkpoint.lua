ENT.Base = "base_brush"
ENT.Type = "brush"

-- for backwards compatibility with gm12 maps... DO NOT USE!

ENT.CheckID = 0

if SERVER then
	function ENT:Initialize()
		self:SetSolid(SOLID_BBOX)
	end

	function ENT:KeyValue(k, v)
		if k == "number" then
			self.CheckID = tonumber(v) - 1
		end
	end

	function ENT:SetupGlobals( activator, caller )
		ACTIVATOR = activator
		CALLER = caller

		if ( IsValid( activator ) and activator:IsPlayer() ) then
			TRIGGER_PLAYER = activator
		end
	end

	function ENT:KillGlobals()
		ACTIVATOR = nil
		CALLER = nil
		TRIGGER_PLAYER = nil
	end

	function ENT:StartTouch(entity)
		self:SetupGlobals(entity, entity)

		HitCheckpoint(self.CheckID)

		self:KillGlobals()
	end
end