local defaultTick = 0.015
local tickInterval = engine.TickInterval()
local tickDelta = tickInterval / defaultTick

local function DoForward(ply, melon)
	local vAim = ply:EyeAngles():Forward()

	if vAim == nil then return end

	vAim.x = vAim.x * (FORWARD_SPEED * tickDelta)
	vAim.y = vAim.y * (FORWARD_SPEED * tickDelta)
	vAim.z = 0

	melon:GetPhysicsObject():ApplyForceCenter(vAim)
end

local function DoReverse(ply, melon)
	local vAim = ply:EyeAngles():Forward()

	if vAim == nil then	return end

	vAim.x = vAim.x * (REVERSE_SPEED * tickDelta)
	vAim.y = vAim.y * (REVERSE_SPEED * tickDelta)
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
			DoForward(ply, melon)
		end

		if ucmd:GetForwardMove() < 0 or (clickcontrols and ucmd:KeyDown(IN_ATTACK2)) then
			DoReverse(ply, melon)
		end
	end

	ply:SetAbsVelocity(melon:GetPhysicsObject():GetVelocity())
end