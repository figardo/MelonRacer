-- ported to gm13 by figardo :)
-- thanks to richter overtime for asking for the port and doing the icon, logo, and backgrounds (and also making a vid on the whole thing)
-- thanks to yashirmare, pigsheepcowduck, and deltarennen for testing

--[[
	MelonRacer 1.3 License

	MIT License

	Copyright (c) 2022 Valkyrie

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("gui.lua")

include("shared.lua")
AddCSLuaFile("shared.lua")
include("controls.lua")
AddCSLuaFile("controls.lua")
include("hookexamples.lua")
AddCSLuaFile("hookexamples.lua")
include("sh_player_ext.lua")
AddCSLuaFile("sh_player_ext.lua")

include("convars.lua")
include("gamerules.lua")
include("events.lua")
include("duplicator.lua")
include("sv_player_ext.lua")

util.AddNetworkString("MelonRacer_PlayerLap")
util.AddNetworkString("MelonRacer_Lap")
util.AddNetworkString("MelonRacer_Winner")
util.AddNetworkString("MelonRacer_SetLeader")
util.AddNetworkString("MelonRacer_WrongWay")
util.AddNetworkString("MelonRacer_AskForTracks")
util.AddNetworkString("MelonRacer_QueryTrack")
util.AddNetworkString("MelonRacer_SelectTrack")
util.AddNetworkString("MelonRacer_StartRound")
util.AddNetworkString("MelonRacer_PlayerRespawn")
util.AddNetworkString("MelonRacer_RespawnAtLast")
util.AddNetworkString("MelonRacer_Checkpoint")

function GM:Initialize()
	team.SetUp(1, "BLUE", Color(0, 0, 255))

	self.Stats = {}

	self.Stats.BestLap		= 0
	self.Stats.BestLapName 	= NO_NAME
	self.Stats.Places = {}

	self.DupeEntsRegistered = false

	self.RestartingRound = false
	self.FirstRoundStarted = false -- We start a round when the first player spawns
	self.Intermission = false
	self.RoundStarted = false

	hook.Remove("Think", "qtg_plyhighspeeddmg") -- remove incompatible addon
end

local spawnFuncs = {
	["checkpoint"] = function(gmtbl, params)
		local check = ents.Create("mr_rearmtrigger")

		local checkpointID = tonumber(params[1])
		check:SetID(checkpointID)

		local pos = Vector(tonumber(params[2]), tonumber(params[3]), tonumber(params[4]))
		check:SetPos(pos)
		check:SetPos1(pos)
		check:SetPos2(Vector(tonumber(params[5]), tonumber(params[6]), tonumber(params[7])))

		check:Spawn()

		if checkpointID > gmtbl.HighestID then
			gmtbl.HighestID = checkpointID
		end
	end,
	["spawn"] = function(gmtbl, params)
		local spawn = ents.Create("gmod_player_start")

		spawn:SetPos(Vector(tonumber(params[2]), tonumber(params[3]), tonumber(params[4])))
		spawn:SetAngles(Angle(0, tonumber(params[5]), 0))

		spawn:Spawn()

		gmtbl.Spawns[#gmtbl.Spawns + 1] = spawn
	end,
	["tp"] = function(gmtbl, params)
		local tp = ents.Create("mr_rearmtp")

		tp:SetID(tonumber(params[2]))

		local pos = Vector(tonumber(params[3]), tonumber(params[4]), tonumber(params[5]))
		tp:SetPos(pos)
		tp:SetPos1(pos)
		tp:SetPos2(Vector(tonumber(params[6]), tonumber(params[7]), tonumber(params[8])))

		tp:Spawn()
	end,
	["tpdest"] = function(gmtbl, params)
		local tpdest = ents.Create("mr_rearmtpdest")

		tpdest:SetID(tonumber(params[2]))
		tpdest:SetPos(Vector(tonumber(params[3]), tonumber(params[4]), tonumber(params[5])))
		tpdest:SetAngles(Angle(0, tonumber(params[6]), 0))

		tpdest:Spawn()
	end,
	["prop"] = function(gmtbl, params)
		local prop = ents.Create("prop_physics")

		prop:SetModel(params[2])
		prop:SetPos(Vector(tonumber(params[3]), tonumber(params[4]), tonumber(params[5])))
		prop:SetAngles(Angle(tonumber(params[6]), tonumber(params[7]), tonumber(params[8])))

		prop:Spawn()

		prop:GetPhysicsObject():EnableMotion(!tobool(params[9]))
	end
}

function GM:HandleTrackData(ply)
	if !ply:IsAdmin() then return end

	local prefix = "melonracer/" .. game.GetMap() .. "/"
	local trackID = net.ReadUInt(8)
	local filename = file.Find(prefix .. "*", "DATA", "nameasc")[trackID]

	local entList = file.Read(prefix .. filename, "DATA"):Split("\n")

	local removeEnts = ents.FindByClass("*_player_*")
	table.Add(removeEnts, ents.FindByClass("mr_rearmtrigger"))
	table.Add(removeEnts, ents.FindByClass("mr_rearmtp"))
	table.Add(removeEnts, ents.FindByClass("mr_rearmtpdest"))
	table.Add(removeEnts, ents.FindByClass("prop_physics*"))

	for i = 1, #removeEnts do
		removeEnts[i]:Remove()
	end

	self.TrackMap = true
	self.Spawns = {}
	self.HighestID = 0

	local saveData = entList[#entList]
	if string.StartsWith(saveData, "{") then
		if !self.DupeEntsRegistered then
			self:RegisterDupeEnts()
		end

		gmsave.LoadMap(saveData)
	end

	timer.Simple(0.1, function() -- gmsave.LoadMap calls game.CleanUpMap, which now cleans up on the next tick, removing this lot in the process
		local oldtrack = false

		for i = 1, #entList do
			local data = entList[i]
			local params = data:Split(" ")

			local entity = params[1]
			local checkpointID = tonumber(entity)
			if checkpointID then
				entity = "checkpoint"
			elseif entity == "prop" then
				oldtrack = true
			end

			local spawnfunc = spawnFuncs[entity]
			if !spawnfunc then continue end

			spawnfunc(self, params)
		end

		if oldtrack then
			ply:ChatPrint("This is an old format track. Please load it in the track creator and re-export it.")
			ply:ChatPrint("The track creator can be downloaded here: https://steamcommunity.com/sharedfiles/filedetails/?id=2925384863")
		end

		if self.FirstRoundStarted then
			self:StartRound()
		end
	end)
end
net.Receive("MelonRacer_SelectTrack", function(_, ply) GAMEMODE:HandleTrackData(ply) end)

local function AskForTracks(_, ply)
	local prefix = "melonracer/" .. game.GetMap() .. "/"
	local tracks = file.Find(prefix .. "*", "DATA", "nameasc")

	net.Start("MelonRacer_QueryTrack")
		net.WriteUInt(#tracks, 8)
		for _, track in ipairs(tracks) do
			local data = file.Read(prefix .. track, "DATA"):Split("\n")[1]
			local name = data:Split(" ")[2]
			local nick = data:match("'.*$"):Replace("'", "")

			net.WriteString(name)
			net.WriteString(nick)
		end
	net.Send(ply)
end
net.Receive("MelonRacer_AskForTracks", AskForTracks)

local checkpointent
local triggerQueue = {}
function GM:VerifyTrigger(v)
	local tbl
	if v:find("") then
		tbl = v:Split("") -- gmod hammer uses this character to separate outputs for some reason
	else
		tbl = v:Split(",")
	end

	local name = tbl[1]

	local outputs = ents.FindByName(name)
	local pass = false
	for _, output in ipairs(outputs) do
		if output != checkpointent then continue end

		pass = true
		break
	end

	if !pass then return end

	local id = tonumber(tbl[3])

	if id > self.HighestID then
		self.HighestID = id
	end
end

function GM:EntityKeyValue(ent, k, v)
	if !self.HighestID then self.HighestID = 0 end
	local class = ent:GetClass()

	if class == "trigger_checkpoint" and k == "checkpoint" then
		local id = tonumber(v) - 1

		if id > self.HighestID then
			self.HighestID = id
		end

		return
	end

	if class == "checkpoint" and k == "number" then -- fucking stupid classname
		local id = tonumber(v) - 1

		if id > self.HighestID then
			self.HighestID = id
		end

		return
	end

	if class == "gmod_runfunction" and k == "FunctionName" and v == "HitCheckpoint" then
		checkpointent = ent

		for _, values in ipairs(triggerQueue) do
			self:VerifyTrigger(values)
		end

		return
	end

	if class == "trigger_multiple" and k == "OnStartTouch" then
		if !IsValid(checkpointent) then
			table.insert(triggerQueue, v)
			return
		end

		self:VerifyTrigger(v)
	end
end

function GM:InitPostEntity()
	self:CreateConVars()

	local usetbl = hook.GetTable()["PlayerUse"]
	if usetbl and #usetbl > 0 then
		for name, _ in pairs(usetbl) do -- to be ABSOLUTELY sure that no hook is enabling the use key
			hook.Remove("PlayerUse", name)
		end
	end

	if !self.TrackMap then
		self.Spawns = {}

		local spawns = ents.FindByClass("*_player_*")
		for i = 1, #spawns do
			self.Spawns[#self.Spawns + 1] = spawns[i]
		end
	end
end