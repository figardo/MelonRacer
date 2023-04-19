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

local fs = CreateConVar("mr_forwardspeed", "170", FCVAR_NOTIFY, "The speed of the melon when going forwards.")
local rs = CreateConVar("mr_reversespeed", "40", FCVAR_NOTIFY, "The speed of the melon when going backwards.")
local mdl = CreateConVar("mr_model", "models/props_junk/watermelon01.mdl", FCVAR_NONE, "The model of the melons.")
local numlaps = CreateConVar("mr_laps", "10", FCVAR_NOTIFY, "The number of laps to complete in a race.")
local force = CreateConVar("mr_force", "0", FCVAR_NOTIFY, "Force gamemode into this version regardless of map. Set to 1 for GM9, 2 for GM10, or 3 for 1.3.")

local function ResetValues()
	FORWARD_SPEED = fs:GetInt()

	REVERSE_SPEED = -rs:GetInt()

	PLAYER_MODEL = mdl:GetString()

	NUM_LAPS = numlaps:GetInt()

	FORCE_VERSION = force:GetInt()
end
ResetValues()
cvars.AddChangeCallback("mr_forwardspeed", ResetValues)
cvars.AddChangeCallback("mr_reversespeed", ResetValues)
cvars.AddChangeCallback("mr_model", ResetValues)
cvars.AddChangeCallback("mr_laps", ResetValues)

TEAM_BLUE = 1

-- Hay guyz I maed a new gamemode its my first gamemode it tuk ages

-- Ps all I did was uncomment the bowlingball line from melonracer

-- PLAYER_MODEL 	= "models/mixerman3d/bowling/bowling_ball.mdl"

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

include("gamerules.lua")
include("events.lua")
include("controls.lua")
include("hookexamples.lua")
include("duplicator.lua")
include("sv_player_ext.lua")

AddCSLuaFile("gui.lua")
AddCSLuaFile("hookexamples.lua")

util.AddNetworkString("MelonRacer_PlayerLap")
util.AddNetworkString("MelonRacer_Lap")
util.AddNetworkString("MelonRacer_Winner")
util.AddNetworkString("MelonRacer_SetLeader")
util.AddNetworkString("MelonRacer_WrongWay")
util.AddNetworkString("MelonRacer_AskForTracks")
util.AddNetworkString("MelonRacer_QueryTrack")
util.AddNetworkString("MelonRacer_SelectTrack")

function GM:Initialize()
	team.SetUp(TEAM_BLUE, "BLUE", Color(0, 0, 255))

	util.PrecacheModel(PLAYER_MODEL)
	self.Stats = {}

	self.Stats.BestLap		= 0
	self.Stats.BestLapName 	= NO_NAME
	self.Stats.FirstPlace = 0
	self.Stats.SecondPlace = 0
	self.Stats.ThirdPlace = 0

	bRestartingRound	=	false
	bFirstRoundStarted	=	false -- We start a round when the first player spawns
	bIntermission		=	false
	bRoundStarted = false

	local usetbl = hook.GetTable()["PlayerUse"]
	if usetbl and #usetbl > 0 then
		for name, _ in pairs(usetbl) do -- to be ABSOLUTELY sure that no hook is enabling the use key
			hook.Remove("PlayerUse", name)
		end
	end

	hook.Remove("Think", "qtg_plyhighspeeddmg") -- remove incompatible addon
end

local function HandleTrackData(_, ply)
	if !ply:IsAdmin() then return end

	local prefix = "melonracer/" .. game.GetMap() .. "/"
	local trackID = net.ReadUInt(8)
	local filename = file.Find(prefix .. "*", "DATA", "nameasc")[trackID]

	local entList = file.Read(prefix .. filename, "DATA"):Split("\n")

	local killEnts = ents.FindByClass("*_player_*")
	table.Add(killEnts, ents.FindByClass("mr_rearmtrigger"))
	table.Add(killEnts, ents.FindByClass("prop_physics*"))

	for _, ent in ipairs(killEnts) do
		ent:Remove()
	end

	MR_Spawns = {}
	MR_HighestID = 0

	local saveData = entList[#entList]
	if string.StartWith(saveData, "{") then
		MR_RegisterDupeEnts()

		gmsave.LoadMap(saveData)
	end

	for _, data in ipairs(entList) do
		local params = data:Split(" ")

		local cid = tonumber(params[1])
		if cid then
			local check = ents.Create("mr_rearmtrigger")

			local posx, posy, posz = tonumber(params[2]), tonumber(params[3]), tonumber(params[4])
			local mx, my, mz = tonumber(params[5]), tonumber(params[6]), tonumber(params[7])

			local pos = Vector(posx, posy, posz)
			check:SetPos(pos)
			check:SetPos1(pos)
			check:SetPos2(Vector(mx, my, mz))
			check:SetID(cid)
			check:Spawn()

			if cid > MR_HighestID then
				MR_HighestID = cid
			end
		elseif params[1] == "spawn" then
			local spawn = ents.Create("gmod_player_start")

			local posx, posy, posz = tonumber(params[2]), tonumber(params[3]), tonumber(params[4])
			spawn:SetPos(Vector(posx, posy, posz))

			local angy = tonumber(params[5])
			spawn:SetAngles(Angle(0, angy, 0))

			spawn:Spawn()

			table.insert(MR_Spawns, spawn)
		end
	end

	if bFirstRoundStarted then
		GAMEMODE:StartRound()
	end
end
net.Receive("MelonRacer_SelectTrack", HandleTrackData)

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
local function VerifyTrigger(v)
	local tbl = v:Split(",")

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

	if id > MR_HighestID then
		MR_HighestID = id
	end
end

function GM:EntityKeyValue(ent, k, v)
	if !MR_HighestID then MR_HighestID = 0 end
	local class = ent:GetClass()

	if class == "trigger_checkpoint" and k == "checkpoint" then
		local id = tonumber(v) - 1

		if id > MR_HighestID then
			MR_HighestID = id
		end

		return
	end

	if class == "checkpoint" and k == "number" then -- fucking stupid classname
		local id = tonumber(v) - 1

		if id > MR_HighestID then
			MR_HighestID = id
		end

		return
	end

	if class == "gmod_runfunction" and k == "FunctionName" and v == "HitCheckpoint" then
		checkpointent = ent

		for _, values in ipairs(triggerQueue) do
			VerifyTrigger(values)
		end

		return
	end

	if class == "trigger_multiple" and k == "OnStartTouch" then
		if !IsValid(checkpointent) then
			table.insert(triggerQueue, v)
			return
		end

		VerifyTrigger(v)
	end
end

function GM:InitPostEntity()
	MR_Spawns = {}

	for _, spawn in ipairs(ents.FindByClass("*_player_*")) do
		table.insert(MR_Spawns, spawn)
	end
end