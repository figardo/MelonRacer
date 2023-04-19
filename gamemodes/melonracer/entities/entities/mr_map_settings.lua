ENT.Type = "point"
ENT.Base = "base_point"

function ENT:KeyValue(k, v)
	if k == "force_version" then
		-- blahhhhh
	elseif k == "lap_count" then
		-- GRAHHHHH!
	elseif k == "force_model" and v != "" then
		if util.IsValidModel(v) then
			util.PrecacheModel(v)
			GAMEMODE.force_plymodel = v

			Dev(2, "ttt_map_settings: set player model to be " .. v)
		else
			Dev(2, "ttt_map_settings: FAILED to set player model due to invalid path: " .. v)
		end
	elseif k == "allow_shortcut" then
		-- FUHH!
	elseif k == "force_speed" then
		-- RRAAAAAHH!!
	elseif k == "check_respawn" then
		
	end
end