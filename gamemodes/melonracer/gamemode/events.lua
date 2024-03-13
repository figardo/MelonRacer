-- the only real way this can happen is 'kill' in the console
function GM:PlayerDeath(killed, attacker, weapon)
	-- If the player owns a melon then explode the melon.
	killed:BreakMelon()
end

function GM:PlayerDisconnected(ply)
	-- This will be 0 if the player hasn't become active yet
	if !IsValid(ply) then return end

	-- If the player owns a melon then explode the melon.
	ply:BreakMelon()
end

function GM:PlayerUse()
	return false -- disable picking up your own melon
end

function GM:SetSpectatorMode(ply, iMelon)
	if !IsValid(ply) or !IsValid(iMelon) then return end

	ply:Spectate(OBS_MODE_CHASE)
	ply:SpectateEntity(iMelon)
end

function GM:PlayerInitialSpawn(ply)
	if self.HighestID <= 0 and ply:IsAdmin() then
		ply:ChatPrint("Map doesn't support MelonRacer. Please choose a track using the command mr_choosetrack.")
	end

	ply:ConCommand("cl_showpos 1") -- for speedrun.com verification

	ply:ResetStats()

	ply:Freeze(false)

	-- Their model is moot because the player won't actually be drawn.
	ply:SetModel(self.PLAYER_MODEL) -- replacing PlayerSpawnChooseModel

	-- Start on the spectator team (joins the game when fire is pressed)
	ply:SetTeam(TEAM_SPECTATOR)

	timer.Simple(0, function()
		ply:Spectate(OBS_MODE_ROAMING)
	end)
end

local i = 1
function GM:PlayerSelectSpawn(ply)
	if !self.Spawns or table.IsEmpty(self.Spawns) then
		self:InitPostEntity()
	end

	if i > #self.Spawns then i = 1 end

	local spawnEnt = self.Spawns[i]
	i = i + 1

	return spawnEnt
end

local godCol = Color(100, 100, 255)
function GM:PlayerSpawn(ply)
	-- Don't do anything if they're spectating
	if ply:Team() == TEAM_SPECTATOR then return end

	local vPos = ply:GetPos()

	-- Spawn a melon
	local iMelon = ents.Create("prop_physics")
	iMelon:SetModel(self.PLAYER_MODEL)

	local checkpoint = ply.RespawnCheckpoint
	if self.CHECKPOINT_RESPAWN and checkpoint > 0 then
		DevPrint("Respawning at checkpoint " .. checkpoint)

		vPos = ply.CheckpointPos and ply.CheckpointPos[checkpoint] or vPos

		if ply.CheckpointAng then
			ply:SetEyeAngles(ply.CheckpointAng[checkpoint])
		end
	else
		ply.Checkpoint = 0
		ply.LapTime = 0

		ply.RespawnCheckpoint = 0

		if self.RoundStarted then
			ply.LapStart = CurTime()
		end
	end

	iMelon:SetPos(vPos + Vector(0, 0, 8))

	iMelon:Spawn()

	if self.GODMODE then
		iMelon:SetRenderMode(1)
		iMelon:SetColor(godCol)
		iMelon:SetKeyValue("physdamagescale", "0")
	end

	-- still doesn't feel right
	-- if self.GM9_PHYSICS then
	-- 	local phys = iMelon:GetPhysicsObject()
	-- 	phys:SetInertia(phys:GetInertia() * 1.5)
	-- end

	ply:SetMelon(iMelon)
	iMelon.Player = ply

	-- We need to time this because PlayerSpawn is called while they're still spawning
	timer.Simple(0.1, function() self:SetSpectatorMode(ply, iMelon) end)

	if !self.FirstRoundStarted then
		timer.Simple(2, function() self:StartRound() end)
		self.FirstRoundStarted = true
	end

	-- If they're spawning during the intermission - freeze them.
	if self.Intermission then
		iMelon:GetPhysicsObject():EnableMotion(false)
	end
end

function GM:PropBreak(att, prop)
	local iPlayer = MelonToPlayer(prop)
	if !IsValid(iPlayer) then return end

	iPlayer:AddDeaths(1)

	local time = self.RESPAWN_TIME

	net.Start("MelonRacer_PlayerRespawn")
		net.WriteUInt(time, 5)
		net.WriteBool(self.CHECKPOINT_RESPAWN)
	net.Send(iPlayer)

	timer.Simple(time, function()
		if IsValid(iPlayer:GetMelon()) then return end

		if !IsValid(iPlayer) then
			ErrorNoHalt("[ERROR] Somehow, melon " .. prop:EntIndex() .. " doesn't have a player entity. Retrying...")

			GAMEMODE:PropBreak(att, prop)
			return
		end

		iPlayer:Spawn()
	end)
end

-- Coverts a melon to a player
function MelonToPlayer(Melon)
	if Melon.Player then return Melon.Player end

	for _, ply in player.Iterator() do
		local plymel = ply:GetMelon()
		if !IsValid(plymel) or plymel != Melon then continue end

		return ply
	end

	return nil
end

function GM:CountLap(ply)
	ply.Checkpoint = 0

	ply:AddFrags(1)

	ply:DoneLap()
	self:UpdatePositions()

	self:CheckRoundFinished(ply)
end

-- This is built for an unlimited amount of checkpoints - to make mapping a bit easier.
-- A player must not be allowed to SKIP PAST checkpoints.
function HitCheckpoint(newCheck)
	local a = ACTIVATOR
	local iPlayer = MelonToPlayer(a)
	if !IsValid(iPlayer) or !iPlayer:IsPlayer() then return end

	local lastCheck = iPlayer.Checkpoint
	local highestID = GAMEMODE.HighestID

	DevPrint("Player " .. iPlayer:Nick() .. " hit checkpoint " .. newCheck .. " out of " .. highestID)

	hook.Run("MR_HitCheckpoint", iPlayer, newCheck)

	if lastCheck == newCheck then return end

	-- They're going backwards!
	local goingBack = lastCheck == newCheck + 1
	if goingBack or (lastCheck == 0 and newCheck == highestID) then
		if !GAMEMODE.CHECKPOINT_RESPAWN or newCheck != iPlayer.RespawnCheckpoint then
			net.Start("MelonRacer_WrongWay")
			net.Send(iPlayer)
		end

		if goingBack then
			iPlayer.Checkpoint = newCheck
		end

		return
	end

	-- if the checkpoint is 0 then it probably has spawns on it anyway
	if newCheck != 0 then
		local pos = a:GetPos()
		local tr = util.QuickTrace(pos, pos - Vector(0, 0, 4096), {a, iPlayer})

		if !iPlayer.CheckpointPos then iPlayer.CheckpointPos = {} end
		if !iPlayer.CheckpointAng then iPlayer.CheckpointAng = {} end

		-- Set our checkpoint position
		iPlayer.CheckpointPos[newCheck] = tr.Hit and tr.HitPos or pos

		-- Save our angles
		iPlayer.CheckpointAng[newCheck] = iPlayer:EyeAngles()
	end

	-- Going forwards - but no lap.
	if newCheck == lastCheck + 1 then
		net.Start("MelonRacer_Checkpoint")
			net.WriteUInt(newCheck, 8)
		net.Send(iPlayer)

		iPlayer.Checkpoint = newCheck
		GAMEMODE:UpdatePositions()
	end

	-- Lap!
	local us = GAMEMODE.ALLOW_SHORTCUT
	if newCheck == 0 and ((us and lastCheck > 1) or (!us and lastCheck == highestID)) then
		GAMEMODE:CountLap(iPlayer)
	end

	iPlayer.RespawnCheckpoint = newCheck
end

function GM:KeyPress(ply, in_key)
	if ply.FinishedRace then return false end
	if self.Intermission then return false end

	if in_key == IN_ATTACK and ply:Team() == TEAM_SPECTATOR then
		ply:SetTeam(1)
		ply:Spawn()
	end
end

function GM:ShowHelp(ply)
	ply:ConCommand("mr_helpscreen")
end