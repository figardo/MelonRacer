local meta = FindMetaTable("Player")

function meta:ResetStats()
	self:SetMelon(nil)

	self:SetNWVector("CPDir", Vector(0, 0, 0))

	self.Checkpoint = 0
	self.RespawnCheckpoint = 0
	self.NextCheckpoint = 1
	self.Laps = 0
	self.LapTime = 0
	self.LapStart = 0
	self.FinishedRace = false
	self.BestLap = 0

	self.NextCheckPoint = 1
	self.LastCheckPointTime = 0
	self.CheckpointPitch = 50
end

function meta:BreakMelon()
	local plymel = self:GetMelon()

	if !IsValid(plymel) then return end

	plymel:Fire("break")
	self:SetMelon(nil)

	hook.Run("MR_MelonDied", self)
end

function meta:DoneLap()
	local pb = false
	local sr = false
	self.LapTime = CurTime() - self.LapStart

	-- Personal best changed
	if self.LapTime < self.BestLap or self.BestLap == 0 then
		self.BestLap = self.LapTime
		pb = true

		local bestLap = GAMEMODE.Stats.BestLap
		-- Check to see if this is a new server best
		if self.BestLap < bestLap or bestLap == 0 then
			GAMEMODE.Stats.BestLap  = self.BestLap
			GAMEMODE.Stats.BestLapPlayer = self

			sr = true
		end
	end

	-- Reset lap time counter
	self.LapStart = CurTime()
	self.Laps = self.Laps + 1

	net.Start("MelonRacer_PlayerLap")
		net.WriteFloat(self.LapTime)
		net.WriteBool(pb)
		net.WriteBool(sr)
	net.Send(self)

	net.Start("MelonRacer_Lap")
		net.WritePlayer(self)
		net.WriteBool(sr)
		if sr then
			net.WriteFloat(GAMEMODE.Stats.BestLap)
		end
	net.SendOmit(self)
end