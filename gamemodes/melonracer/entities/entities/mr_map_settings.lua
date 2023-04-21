ENT.Type = "point"
ENT.Base = "base_point"

ENT.Version = 0
ENT.LapCount = 0
ENT.PlayerModel = ""
ENT.Shortcuts = false
ENT.FSpeed = 0
ENT.RSpeed = 0
ENT.CheckRespawn = false
ENT.GodMode = false

function ENT:KeyValue(k, v)
	if k == "force_version" then
		self.Version = v
	elseif k == "lap_count" then
		self.LapCount = v
	elseif k == "force_model" and v != "" then
		local dev = GetConVar("developer"):GetInt() > 0 -- look i'll make a more sophisticated dev msg later okay
		if util.IsValidModel(v) then
			util.PrecacheModel(v)
			self.PlayerModel = v

			if dev then
				print("ttt_map_settings: set player model to be " .. v)
			end
		elseif dev then
			print("mr_map_settings: FAILED to set player model due to invalid path: " .. v)
		end
	elseif k == "allow_shortcut" then
		self.Shortcuts = v
	elseif k == "forward_speed" then
		self.FSpeed = v
	elseif k == "reverse_speed" then
		self.RSpeed = v
	elseif k == "check_respawn" then
		self.CheckRespawn = v
	end
end