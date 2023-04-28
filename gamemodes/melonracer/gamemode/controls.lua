local tickDelta = engine.TickInterval() / 0.015

function GM:DoForward(ply, melon)
	local vAim = ply:EyeAngles():Forward()

	if vAim == nil then return end

	vAim.x = vAim.x * (self.FORWARD_SPEED * tickDelta)
	vAim.y = vAim.y * (self.FORWARD_SPEED * tickDelta)
	vAim.z = 0

	melon:GetPhysicsObject():ApplyForceCenter(vAim)
end

function GM:DoReverse(ply, melon)
	local vAim = ply:EyeAngles():Forward()

	if vAim == nil then	return end

	vAim.x = vAim.x * (-self.REVERSE_SPEED * tickDelta)
	vAim.y = vAim.y * (-self.REVERSE_SPEED * tickDelta)
	vAim.z = 0

	melon:GetPhysicsObject():ApplyForceCenter(vAim)
end

function GM:StartCommand(ply, ucmd)
	local melon = ply.Melon
	if !IsValid(melon) then
		ply:SetAbsVelocity(Vector(0, 0, 0))
		return
	end

	if ply:IsConnected() and ply:Team() != TEAM_SPECTATOR and !ply.FinishedRace then
		local clickcontrols = ply:GetInfoNum("mr_clickcontrols", 0) > 0
		if ucmd:GetForwardMove() > 0 or (clickcontrols and ucmd:KeyDown(IN_ATTACK)) then
			self:DoForward(ply, melon)
		end

		if ucmd:GetForwardMove() < 0 or (clickcontrols and ucmd:KeyDown(IN_ATTACK2)) then
			self:DoReverse(ply, melon)
		end
	end

	if !GetConVar("mr_godmode"):GetBool() then
		ply:SetAbsVelocity(melon:GetPhysicsObject():GetVelocity())
	end
end