-- types:
-- 1: int
-- 2: float
-- 3: bool
-- 4: string

if !MR_ConVars then
	MR_ConVars = {
		{name = "mr_forwardspeed", default = "170", flags = FCVAR_NOTIFY + FCVAR_REPLICATED, desc = "The speed of the melon when going forwards.", type = 1, gmval = "FORWARD_SPEED", mapsettings = "FSpeed"},
		{name = "mr_reversespeed", default = "40", flags = FCVAR_NOTIFY + FCVAR_REPLICATED, desc = "The speed of the melon when going backwards.", type = 1, gmval = "REVERSE_SPEED", mapsettings = "RSpeed"},
		{name = "mr_model", default = "", flags = FCVAR_NONE, desc = "Override player model. Leave blank to allow the map to decide.", type = 4, gmval = "PLAYER_MODEL", mapsettings = "PlayerModel", kill = true},
		{name = "mr_laps", default = "10", flags = FCVAR_NOTIFY, desc = "The number of laps to complete in a race.", type = 1, gmval = "NUM_LAPS", mapsettings = "LapCount"},
		{name = "mr_godmode", default = "0", flags = FCVAR_NOTIFY + FCVAR_REPLICATED, desc = "Makes the melon invincible.", type = 3, gmval = "GODMODE", mapsettings = "GodMode", kill = true},
		{name = "mr_ultrashortcut", default = "0", flags = FCVAR_NOTIFY, desc = "Disable check to see if player has passed all checkpoints.", type = 3, gmval = "ALLOW_SHORTCUT", mapsettings = "Shortcuts"},
		{name = "mr_checkpointrespawn", default = "0", flags = FCVAR_NOTIFY, desc = "Respawn players at their last checkpoint instead of spawn.", type = 3, gmval = "CHECKPOINT_RESPAWN", mapsettings = "CheckRespawn"},
		{name = "mr_respawntime", default = "3", flags = FCVAR_NOTIFY, desc = "Change time after death until melon is respawned.", type = 2, gmval = "RESPAWN_TIME", mapsettings = "RespawnTime", min = 0, max = 30},
		{name = "mr_countdown", default = "3", flags = FCVAR_NOTIFY, desc = "Change countdown timer before lap starts.", type = 1, gmval = "COUNTDOWN", mapsettings = "Countdown", min = 0, max = 30},
		{name = "mr_postround", default = "10", flags = FCVAR_NOTIFY, desc = "Change time after lap ends until the round is restarted.", type = 1, gmval = "POST_ROUND", mapsettings = "PostRound", min = 0, max = 30}
		-- {name = "mr_gm9physics", default = "0", flags = FCVAR_NOTIFY, desc = "Enable GM9 style physics.", type = 3, gmval = "GM9_PHYSICS", mapsettings = "GM9Physics", kill = true},
		-- {name = "mr_force", default = "0", flags = FCVAR_NOTIFY, desc = "Force gamemode into this version regardless of map. Set to 1 for GM9, 2 for GM10, or 3 for 1.3.", type = 1, gmval = "FORCE_VERSION", mapsettings = "ForceVersion", min = 0, max = 3}
	}
end

local defaultMdl = Model("models/props_junk/watermelon01.mdl")

local mr_override_mapsettings = CreateConVar("mr_override_mapsettings", "0", FCVAR_ARCHIVE, "If enabled, the gamemode will ignore the map settings and use server settings instead.", 0, 1)

local function ProcessConVarNum(mapSettings, setting, convar)
	if !mr_override_mapsettings:GetBool() and mapSettings then return mapSettings[setting] end

	return convar
end

local function ProcessConVarBool(mapSettings, setting, convar)
	if !mr_override_mapsettings:GetBool() and mapSettings then return mapSettings[setting] == 1 end

	return convar
end

local function GetMapSettings()
	local mapSettings = ents.FindByClass("mr_map_settings")
	return #mapSettings > 0 and mapSettings[1] or nil
end

local function KillTheBastards()
	for _, ply in player.Iterator() do
		ply:Kill()
	end
end

function GM:CreateConVars()
	local mapSettings = GetMapSettings()

	local convars = MR_ConVars

	for i = 1, #convars do
		local data = convars[i]

		local min = data.min
		local max = data.max

		if data.type == 3 then
			min = 0
			max = 1
		end

		local convar = CreateConVar(data.name, data.default, data.flags, data.desc, min, max)
		convars[i].convar = convar

		self:ResetConVar(mapSettings, data, convar)

		local callback = data.kill and function() GAMEMODE:ResetConVars() KillTheBastards() end or function() GAMEMODE:ResetConVars() end

		cvars.AddChangeCallback(data.name, callback)
	end
end

function GM:ResetConVar(mapSettings, data, convar)
	local cvtype = data.type

	convar = convar or data.convar

	if cvtype == 1 then
		self[data.gmval] = ProcessConVarNum(mapSettings, data.mapsettings, convar:GetInt())
	elseif cvtype == 2 then
		self[data.gmval] = ProcessConVarNum(mapSettings, data.mapsettings, convar:GetFloat())
	elseif cvtype == 3 then
		self[data.gmval] = ProcessConVarBool(mapSettings, data.mapsettings, convar:GetBool())
	elseif cvtype == 4 then
		-- Hay guyz I maed a new gamemode its my first gamemode it tuk ages

		-- Ps all I did was uncomment the bowlingball line from melonracer

		-- self.PLAYER_MODEL 	= "models/mixerman3d/bowling/bowling_ball.mdl"

		local mdl = convar:GetString()
		self[data.gmval] = util.IsValidModel(mdl) and mdl or ((mapSettings and util.IsValidModel(mapSettings[data.mapsettings])) and mapSettings[data.mapsettings] or defaultMdl)
	end
end

function GM:ResetConVars()
	local mapSettings = GetMapSettings()

	local convars = MR_ConVars

	for i = 1, #convars do
		self:ResetConVar(mapSettings, convars[i])
	end
end