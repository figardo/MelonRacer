function GM:UpdatePositions()
	local Places = {}

	local plys = player.GetAll()
	for i = 1, #plys do
		local ply = plys[i]

		if !ply:IsConnected() then continue end

		table.insert( Places, { Player = ply, Lap = ply.Laps, CheckPoint = ply.Checkpoint, CPTime = ply.LastCheckPointTime } )
	end

	table.sort( Places, function( a, b )
		if ( b == nil ) then return false end
		if (a.Lap < b.Lap) then return false end
		if (a.Lap > b.Lap) then return true end
		if (a.CheckPoint < b.CheckPoint) then return false end
		if (a.CheckPoint > b.CheckPoint) then return true end

		return a.CPTime < b.CPTime
	end )

	if self.IsGM11 then
		for k, v in ipairs( Places ) do
			v.Player:SetNWInt( "place", k )
			v.Player:SetNWInt( "lap", v.Lap )
			v.Player:SetNWInt( "checkpoint", v.CheckPoint )
			SetGlobalEntity( "Pos" .. k, v.Player )
		end

		self.CurrentPlaces = Places
	else
		local first = Places[1]
		local second = Places[2]
		local third = Places[3]

		-- Set our leaders
		self.Stats.FirstPlace = (first and IsValid(first.Player)) and Places[1].Player or 0
		self.Stats.SecondPlace = (second and IsValid(Places[2].Player)) and Places[2].Player or 0
		self.Stats.ThirdPlace = (third and IsValid(Places[3].Player)) and Places[3].Player or 0

		-- Send them to the clients
		net.Start("MelonRacer_SetLeader") -- less bandwidth to network ent indexes rather than strings
			MR_WritePlayer(self.Stats.FirstPlace)
			MR_WritePlayer(self.Stats.SecondPlace)
			MR_WritePlayer(self.Stats.ThirdPlace)
		net.Broadcast()
	end
end

function GM:CheckRoundFinished(ply)
	if ply.Laps <= self.NUM_LAPS then return end

	ply.FinishedRace = true

	if bRestartingRound then return end

	if !hook.Run("MR_EndRound", ply) then
		timer.Simple(10, function() self:StartRound() end)
	end

	bRestartingRound = true

	net.Start("MelonRacer_Winner")
		net.WriteEntity(ply)
	net.Broadcast()
end

function GM:ResetStats()
	if !self.Stats then self.Stats = {} end
	self.Stats.BestLap		= 0
	self.Stats.BestLapName 	= NO_NAME
	self.Stats.FirstPlace = 0
	self.Stats.SecondPlace = 0
	self.Stats.ThirdPlace = 0
end

-- Start a whole new round
function GM:StartRound()
	for _, ply in ipairs(player.GetAll()) do
		if !IsValid(ply) or ply:Team() == TEAM_SPECTATOR then continue end

		-- smash the player's melon if he has one
		ply:BreakMelon()

		-- reset their statistics
		ply:ResetStats()

		-- reset global stats
		self:ResetStats()

		-- respawn the bastard
		ply:Spawn()

		-- If the player doesn't have a melon then we're fucked anyway so lets not do any error checking
		ply.Melon:GetPhysicsObject():EnableMotion(false)
	end

	bRestartingRound	=	false
	bIntermission		=	true
	bRoundStarted		=	true

	local plys = player.GetAll()
	for i = 1, #plys do
		local ply = plys[i]
		ply:ConCommand("cl_mr_startround")
	end

	hook.Run("MR_PrepRound")

	timer.Simple(4, function() self:RaceStart() end)
end
concommand.Add("mr_restartround", function() GAMEMODE:StartRound() end)

function GM:RaceStart()
	for _, ply in ipairs(player.GetAll()) do
		ply.LapStart = CurTime()

		local plymel = ply.Melon
		if IsValid(ply) and IsValid(plymel) then
			-- unfreeze the melon
			plymel:GetPhysicsObject():EnableMotion(true)
			ply:Freeze(false)
		end
	end

	bIntermission		=	false
	bRestartingRound	=	false

	hook.Run("MR_StartRound")
end