ENT.Type = "point"
ENT.Base = "base_point"

ENT.Version = 0
ENT.LapCount = 0
ENT.PlayerModel = ""
ENT.Shortcuts = 0
ENT.FSpeed = 0
ENT.RSpeed = 0
ENT.CheckRespawn = 0
ENT.GodMode = 0
ENT.RespawnTime = 0
ENT.Countdown = 0
ENT.AuthorTime = ""

function ENT:KeyValue(k, v)
	if k == "ForceVersion" then
		self.Version = tonumber(v)
		DevPrint("Map settings set gamemode version to " .. v)
	elseif k == "LapCount" then
		self.LapCount = tonumber(v) - 1
		DevPrint("Map settings set lap count to " .. v)
	elseif k == "PlayerModel" and v != "" then
		if util.IsValidModel(v) then
			util.PrecacheModel(v)
			self.PlayerModel = v

			DevPrint("Map settings set player model to be " .. v)
		else
			DevPrint("Map settings FAILED to set player model due to invalid path: " .. v)
		end
	elseif k == "Shortcuts" then
		self.Shortcuts = tonumber(v)
		DevPrint("Map settings set allow shortcuts to " .. v)
	elseif k == "ForwardSpeed" then
		self.FSpeed = tonumber(v)
		DevPrint("Map settings set forward speed to " .. v)
	elseif k == "ReverseSpeed" then
		self.RSpeed = tonumber(v)
		DevPrint("Map settings set reverse speed to " .. v)
	elseif k == "CheckpointRespawning" then
		self.CheckRespawn = tonumber(v)
		DevPrint("Map settings set checkpoint respawning to " .. v)
	elseif k == "GodMode" then
		self.GodMode = tonumber(v)
		DevPrint("Map settings set god mode to " .. v)
	elseif k == "RespawnTime" then
		self.RespawnTime = tonumber(v)
		DevPrint("Map settings set respawn time to " .. v)
	elseif k == "Countdown" then
		self.Countdown = tonumber(v)
		DevPrint("Map settings set countdown timer to " .. v)
	elseif k == "AuthorTime" then
		self.AuthorTime = v
		DevPrint("Map settings set author time to " .. v)
	elseif k == "PostRound" then
		self.PostRound = tonumber(v)
		DevPrint("Map settings set postround time to " .. v)
	end
end