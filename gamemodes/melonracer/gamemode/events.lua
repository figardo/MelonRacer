local ultrashortcut = CreateConVar("mr_ultrashortcut", "0", FCVAR_NOTIFY, "Disable check to see if player has passed all checkpoints.", -1, 1)
local respawntime = CreateConVar("mr_respawntime", "3", FCVAR_NOTIFY, "Change time after death until melon is respawned.")

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
	if MR_HighestID <= 0 and ply:IsAdmin() then
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
	if !MR_Spawns or table.IsEmpty(MR_Spawns) then
		self:InitPostEntity()
	end

	if i > #MR_Spawns then i = 1 end

	local spawnEnt = MR_Spawns[i]
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
	iMelon:SetPos(vPos + Vector(0, 0, 8))

	iMelon:Spawn()

	if self.GODMODE then
		iMelon:SetRenderMode(1)
		iMelon:SetColor(godCol)
		iMelon:SetKeyValue("physdamagescale", "0")
	end

	ply:SetMelon(iMelon)
	ply.Checkpoint = 0
	ply.LapTime = 0
	ply:ConCommand("cl_mr_respawn")

	if bRoundStarted then
		ply.LapStart = CurTime()
	end

	-- We need to time this because PlayerSpawn is called while they're still spawning
	timer.Simple(0.1, function() self:SetSpectatorMode(ply, iMelon) end)

	if !bFirstRoundStarted then
		timer.Simple(2, function() self:StartRound() end)
		bFirstRoundStarted = true
	end

	-- If they're spawning during the intermission - freeze them.
	if bIntermission then
		iMelon:GetPhysicsObject():EnableMotion(false)
	end
end

function GM:PropBreak(att, prop)
	local iPlayer = MelonToPlayer(prop)
	if !IsValid(iPlayer) then return end

	iPlayer:AddDeaths(1)

	local time = respawntime:GetFloat()
	time = time < 0 and 3 or time

	timer.Simple(time, function()
		if !IsValid(iPlayer) then
			ErrorNoHalt("[ERROR] Somehow, melon " .. prop:EntIndex() .. " doesn't have a player entity. Retrying...")

			GAMEMODE:PropBreak(att, prop)
			return
		end

		iPlayer:Spawn()
	end)
	iPlayer:SetMelon(nil)
end

-- Coverts a melon to a player
function MelonToPlayer(Melon)
	for _, ply in ipairs(player.GetAll()) do
		local plymel = ply.Melon
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
function HitCheckpoint(NewCP)
	local a = ACTIVATOR
	local iPlayer = MelonToPlayer(a)
	if !IsValid(iPlayer) or !iPlayer:IsPlayer() then return end

	local LastCP = iPlayer.Checkpoint

	if GetConVar("developer"):GetInt() > 0 then
		print("Player " .. iPlayer:Nick() .. " Hit checkpoint " .. NewCP)
	end

	hook.Run("MR_HitCheckpoint", iPlayer, NewCP)

	-- They're going backwards!
	if LastCP == NewCP + 1 then
		net.Start("MelonRacer_WrongWay")
		net.Send(iPlayer)

		iPlayer.Checkpoint = NewCP
		return
	end

	-- Going forwards - but no lap.
	if LastCP == NewCP - 1 then
		iPlayer:ConCommand("cl_mr_checkpoint " .. NewCP)

		iPlayer.Checkpoint = NewCP
		GAMEMODE:UpdatePositions()
	end

	-- Lap!
	local us = ultrashortcut:GetBool()
	if NewCP == 0 and ((us and LastCP > 1) or (!us and LastCP == MR_HighestID)) then
		GAMEMODE:CountLap(iPlayer)
	end
end

function GM:KeyPress(ply, in_key)
	if ply.FinishedRace then return false end
	if bIntermission then return false end

	if in_key == IN_ATTACK and ply:Team() == TEAM_SPECTATOR then
		ply:SetTeam(1)
		ply:Spawn(userid)
	end
end

function GM:ShowHelp(ply)
	ply:ConCommand("mr_helpscreen")
end