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

local isGod = GetConVar("mr_godmode")
local forwardspeed = GetConVar("mr_forwardspeed")
local reversespeed = GetConVar("mr_reversespeed")

local still = Vector(0, 0, 0)
function GM:StartCommand(ply, ucmd)
	local melon = ply:GetMelon()
	if !IsValid(melon) then
		if SERVER then return end

		ply:SetAbsVelocity(still)
		return
	end

	if SERVER then
		ply.GoingToPreviousCheckpoint = false

		if ply:IsConnected() and ply:Team() != TEAM_SPECTATOR and !ply.FinishedRace then
			local clickcontrols = ply:GetInfoNum("mr_clickcontrols", 0) > 0
			if ucmd:GetForwardMove() > 0 or (clickcontrols and ucmd:KeyDown(IN_ATTACK)) then
				self:DoForward(ply, melon)
			end

			if ucmd:GetForwardMove() < 0 or (clickcontrols and ucmd:KeyDown(IN_ATTACK2)) then
				self:DoReverse(ply, melon)
			end
		end
	elseif !isGod:GetBool() and forwardspeed:GetInt() == 170 and reversespeed:GetInt() == 40 then
		ply:SetAbsVelocity(melon:GetVelocity())
	end
end

function GM:PlayerButtonDown(ply, key)
	if CLIENT or ply:Team() == TEAM_SPECTATOR or IsValid(ply:GetMelon()) or !self.CHECKPOINT_RESPAWN or ply.GoingToPreviousCheckpoint or key != MOUSE_FIRST then return end

	local curCheck = ply.RespawnCheckpoint
	ply.RespawnCheckpoint = curCheck == 0 and self.HighestID or ply.RespawnCheckpoint - 1

	net.Start("MelonRacer_RespawnAtLast")
	net.Send(ply)

	DevPrint("Player " .. ply:Nick() .. " will respawn at checkpoint " .. ply.RespawnCheckpoint)

	ply.GoingToPreviousCheckpoint = true
end