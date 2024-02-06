ENT.Base = "base_brush"
ENT.Type = "brush"

AccessorFunc( ENT, "pos1", "Pos1")
AccessorFunc( ENT, "pos2", "Pos2")

if SERVER then
	function ENT:SetupDataTables()
		self:NetworkVar("Int", 0, "ID")
	end

	function ENT:Initialize()
		self:SetSolid(SOLID_BBOX)
		self:SetCollisionBoundsWS(self:GetPos1(), self:GetPos2())
	end

	function ENT:SetupGlobals( activator, caller )
		ACTIVATOR = activator
		CALLER = caller

		if ( IsValid( activator ) && activator:IsPlayer() ) then
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

		local dests = ents.FindByClass("mr_rearmtpdest")
		local ourdests = {}
		for i = 1, #dests do
			local dest = dests[i]
			if dest:GetID() != self:GetID() then continue end

			ourdests[#ourdests + 1] = dest
		end

		local vel = entity:GetPhysicsObject():GetVelocity()

		local finaldest = ourdests[math.random(#ourdests)]
		entity:SetPos(finaldest:GetPos() + Vector(0, 0, 8))
		entity:SetAngles(finaldest:GetAngles())
		entity:GetPhysicsObject():SetVelocityInstantaneous(vel)

		self:KillGlobals()
	end
end