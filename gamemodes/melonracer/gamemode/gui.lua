--[[
this is all useless info now, comments stay for accuracy

Rect index

0  - Melon for intro

1  - Melon 2

2  - Title

3  - Lap!

Text index

0 = 1st

1 = 2nd + 3rd

2 = Fastest lap + your fastest

3 = Data for 2

4 = Personal data labels

5 = Personal data stats

6 = intro countdown

50+ = PlayerLabels
]]

function GM:UpdatePlayerLabels()
	if hook.Run("MR_PlayerLabels") then return end

	surface.SetTextColor(255, 255, 255, 255)
	surface.SetFont("BrandingSmall")

	for _, ply in player.Iterator() do
		local plymel = ply:GetMelon()
		if !IsValid(plymel) then continue end

		local pos = plymel:GetPos()
		pos.z = pos.z + 16

		local toscreen = pos:ToScreen()
		local x = toscreen.x
		local y = toscreen.y

		local nick = ply:Nick()
		local w = surface.GetTextSize(nick)

		surface.SetTextPos(x - (w / 2), y)
		surface.DrawText(nick)
	end
end

local titlemat = Material("gmod/melonracer/title")
local melon = Material("gmod/melonracer/melon")
function GM:DrawIntro()
	if hook.Run("MR_DrawIntro") then return end

	local w = ScrW()
	local h = ScrH()

	local title = vgui.Create("DPanel")
	title:SetSize(w * 0.4, h * 0.25)
	title:SetPos(w * -0.06375, 0)

	title:MoveTo(w * 0.03, 0, 0.2, 0, 1)
	title:AlphaTo(1, 1, 5, function(_, pnl) pnl:Remove() end)

	title.Paint = function(s, x, y)
		surface.SetDrawColor(255, 255, 255)
		surface.SetMaterial(titlemat)

		s:DrawTexturedRect()
	end

	local mln1 = vgui.Create("DPanel")
	mln1:SetSize(w * 0.4, h * 0.4)
	mln1:SetPos(w * -0.4, h * 0.25)

	mln1.Paint = function(s, x, y)
		surface.SetDrawColor(255, 255, 255)
		surface.SetMaterial(melon)

		s:DrawTexturedRect()

		return true
	end

	mln1:MoveTo(w * 1.4, h * 0.25, 2.5, 1, 2, function(_, pnl) pnl:Remove() end)

	local mln2 = vgui.Create("DPanel")
	mln2:SetSize(w * 0.3, h * 0.3)
	mln2:SetPos(w * -0.4, h * 0.25)

	mln2.Paint = function(s, x, y)
		surface.SetDrawColor(255, 255, 255)
		surface.SetMaterial(melon)

		s:DrawTexturedRect()
	end

	mln2:MoveTo(w * 1.4, h * 0.3, 2, 1, 1, function(_, pnl) pnl:Remove() end)
end
-- concommand.Add("mr_intro", function() GAMEMODE:DrawIntro() end)

local function CentreMessage(text, col, font)
	local w = ScrW()
	local h = ScrH()

	surface.SetFont(font)
	local tw, th = surface.GetTextSize(text)

	local msg = vgui.Create("DLabel")
	msg:SetSize(tw, th)
	msg:SetPos((w / 2) - (tw / 2), h * 0.3)
	msg:SetFont(font)
	msg:SetTextColor(col)
	msg:SetText(text)

	msg:AlphaTo(0, 1, 2, function(_, pnl) pnl:Remove() end)
end

function GM:WrongWay()
	if hook.Run("MR_WrongWay") then return end

	CentreMessage("#MelonRacer.WrongWay", Color(255, 0, 0), "LegacyDefault")
end
net.Receive("MelonRacer_WrongWay", function() GAMEMODE:WrongWay() end)

local white = Color(255, 255, 255)
local function Checkpoint(override)
	local ply = LocalPlayer()

	ply.Checkpoint = override

	local NewCP = ply.Checkpoint

	if hook.Run("MR_ShowCheckpoint", NewCP) then return end

	local str = string.format(language.GetPhrase("MelonRacer.Checkpoint"), NewCP)

	surface.SetFont("LegacyDefault")
	local w, h = surface.GetTextSize(str)

	local point = vgui.Create("DLabel")
	point:SetFont("LegacyDefault")
	point:SetSize(w, h)
	point:SetText(str)
	point:SetAlpha(0)
	point:SetColor(white)

	point:SetPos((ScrW() / 2) - (w / 2), ScrH() * 0.8)
	point:AlphaTo(255, 0.2, 0)
	point:AlphaTo(0, 0.5, 1.5, function(_, pnl) pnl:Remove() end)
end
net.Receive("MelonRacer_Checkpoint", function() Checkpoint(net.ReadUInt(8)) end)

local lap = Material("gmod/melonracer/lap")
function GM:DoLapZoom()
	local ply = LocalPlayer()
	ply.Checkpoint = 0

	local lapcount = ply.Laps or 0
	ply.Laps = lapcount + 1

	local lastlap = net.ReadFloat()
	ply.LapTime = lastlap

	local ispb = net.ReadBool()
	if ispb then
		ply.BestLap = ply.LapTime
	end

	local issr = net.ReadBool()
	if issr then
		self.Stats.BestLap = ply.BestLap
		self.Stats.BestLapName = ply:Nick()
	end

	if hook.Run("MR_LapAnimation") then return end

	if GetConVar("mr_betahud"):GetBool() then
		CentreMessage("LAP!", white, "DefaultShadow")
		Checkpoint(0)
		return
	end

	local w = ScrW()
	local h = ScrH()

	local lappnl = vgui.Create("DPanel")
	lappnl:SetPos(w / 2, h / 2)
	lappnl:SetSize(0, 0)
	lappnl:AlphaTo(0, 1, 0, function(_, pnl) pnl:Remove() end)
	lappnl:SizeTo(w * 9, h * 7, 1, 0, 2.5)
	lappnl:MoveTo(-w * 4, -h * 3, 1, 0, 2.5)

	lappnl.Paint = function(s, x, y)
		surface.SetDrawColor(255, 255, 255)
		surface.SetMaterial(lap)

		s:DrawTexturedRect()
	end
end
net.Receive("MelonRacer_PlayerLap", function() GAMEMODE:DoLapZoom() end)

function GM:DoOtherLap()
	local ply = net.ReadPlayer()

	if ply == 0 then return end

	if !ply.Laps then ply.Laps = 0 end
	ply.Laps = ply.Laps + 1

	local serverRecord = net.ReadBool()
	if serverRecord then
		local bestLap = net.ReadFloat()

		self.Stats.BestLap = bestLap
		self.Stats.BestLapName = ply:Nick()
	end
end
net.Receive("MelonRacer_Lap", function() GAMEMODE:DoOtherLap() end)

function GM:SetLeaders()
	local na = self.IsGM13 and NO_NAME_CAPITAL or NO_NAME

	local numPlaces = net.ReadUInt(2)

	for i = 1, 3 do
		self.Stats.Places[i] = i <= numPlaces and net.ReadPlayer():Nick() or na
	end
end
net.Receive("Melonracer_SetLeader", function() GAMEMODE:SetLeaders() end)

local one = "1. "
local two = "2. "
local three = "3. "

function string.OldMSMS(TimeInSeconds)
	local ms = TimeInSeconds % 1
	ms = string.format("%03i", math.floor(ms * 1000))
	return string.FormattedTime(TimeInSeconds, "%01i:%02i:") .. ms
end

local msms = string.OldMSMS
function GM:DrawStats()
	if hook.Run("MR_DrawStats") then return end

	if !self.Stats then self:ResetStats() end

	local w = ScrW()
	local x = w * 0.02

	local h = ScrH()
	local y = h * 0.1

	local places = self.Stats.Places

	surface.SetFont("DefaultShadow")
	surface.SetTextColor(255, 255, 0)
	surface.SetTextPos(x, y)
	local first = one .. places[1] or NO_NAME
	surface.DrawText(first)

	local _, th = surface.GetTextSize(first)
	y = y + th

	surface.SetTextColor(200, 200, 200)
	surface.SetTextPos(x, y)
	local second = two .. places[2] or NO_NAME
	surface.DrawText(second)

	_, th = surface.GetTextSize(second)
	y = y + th

	surface.SetTextPos(x, y)
	local third = three .. places[3] or NO_NAME
	surface.DrawText(third)

	surface.SetTextColor(120, 120, 120)

	y = h * 0.18
	surface.SetTextPos(x, y)
	local bl = "#MelonRacer.BestLap"
	surface.DrawText(bl)

	_, th = surface.GetTextSize(bl)
	y = y + th

	surface.SetTextPos(x, y)
	local blb = "#MelonRacer.BestLapBy"
	surface.DrawText(blb)

	surface.SetTextColor(200, 200, 200)

	x = w * 0.14
	y = h * 0.18
	surface.SetTextPos(x, y)
	local blp = msms(self.Stats.BestLap or 0)
	surface.DrawText(blp)

	_, th = surface.GetTextSize(blp)
	y = y + th

	surface.SetTextPos(x, y)
	surface.DrawText(self.Stats.BestLapName or NO_NAME)
end

function GM:DrawPersonalStats()
	if hook.Run("MR_DrawPersonalStats") then return end

	local ply = LocalPlayer()

	local x = ScrW()
	local x1 = x * 0.02
	local y = ScrH() * 0.24

	surface.SetFont("DefaultShadow")
	surface.SetTextColor(120, 120, 120)

	surface.SetTextPos(x1, y)
	local best = "#MelonRacer.YourBestLap"
	surface.DrawText(best)

	local _, h = surface.GetTextSize(best)
	local y2 = y + h
	surface.SetTextPos(x1, y2)
	local last = "#MelonRacer.YourLastLap"
	surface.DrawText(last)

	_, h = surface.GetTextSize(last)
	local y3 = y2 + (h * 2)
	surface.SetTextPos(x1, y3)
	surface.DrawText("#MelonRacer.Laps")

	surface.SetTextColor(200, 200, 200)

	local x2 = x * 0.14

	surface.SetTextPos(x2, y)
	surface.DrawText(msms(ply.BestLap or 0))

	surface.SetTextPos(x2, y2)
	surface.DrawText(msms(ply.LapTime or 0))

	surface.SetTextPos(x2, y3)
	surface.DrawText(ply.Laps or 0)
end

local wincol = Color(0, 255, 0)
local function DeclareWinner()
	local winner = net.ReadPlayer()
	if !IsValid(winner) then return end

	if hook.Run("MR_ShowWinner", winner) then return end

	local winstr = string.format(language.GetPhrase("MelonRacer.WinsTheGame"), winner:Nick())

	local winpnl = vgui.Create("DLabel")
	winpnl:SetFont("ImpactMassive")
	winpnl:SetTextColor(wincol)

	surface.SetFont("ImpactMassive")
	local w, h = surface.GetTextSize(winstr)
	winpnl:SetSize(w, h)
	winpnl:SetPos((ScrW() / 2) - (w / 2), ScrH() / 2)
	winpnl:SetAlpha(0)

	winpnl:SetText(winstr)
	winpnl:AlphaTo(255, 0.5, 0)
	winpnl:AlphaTo(0, 2, 5.5, function(_, pnl) pnl:Remove() end)
end
net.Receive("MelonRacer_Winner", DeclareWinner)

local black = Color(0, 0, 0)
local function DrawRoundStart(iNumber)
	local sw = ScrW()
	local sh = ScrH()

	if iNumber == 0 then iNumber = "#MelonRacer.Go" end

	local count = vgui.Create("DLabel")
	count:SetFont("ImpactMassive")
	count:SetText(iNumber)

	surface.SetFont("ImpactMassive")
	local w, h = surface.GetTextSize(iNumber)
	local x = (sw / 2) - (w / 2)
	local y = (sh / 2) + (sh * 0.01)

	count:SetSize(w, h)
	count:SetPos(x, y)
	count:SetColor(black)

	count:ColorTo(white, 0.5)
	count:AlphaTo(0, 0.5, 0.5, function(_, pnl) pnl:Remove() end)
	count:MoveTo(x, y - (sh * 0.1), 1.5, 0, 0.7)

	surface.PlaySound("hl1/fvox/bell.wav")
end

function GM:PlayerResetStats()
	local ply = LocalPlayer()

	ply.Laps = 0
	ply.Checkpoint = 0
	ply.LapTime = 0

	self.Stats.Places = {
		ply:Nick(),
		NO_NAME,
		NO_NAME
	}
end

function GM:StartRound()
	self:PlayerResetStats()

	local countdown = net.ReadUInt(5)
	if hook.Run("MR_DrawRoundStart", countdown) then return end

	for i = 1, countdown + 1 do
		local time = countdown - i + 1
		timer.Simple(i, function() DrawRoundStart(time) end)
	end
end
net.Receive("MelonRacer_StartRound", function() GAMEMODE:StartRound() end)

local respawningAtLast = false

local function SetRespawningAtLast()
	respawningAtLast = true
end
net.Receive("MelonRacer_RespawnAtLast", SetRespawningAtLast)

local function OnPlayerRespawn()
	local respawnTime = net.ReadUInt(5)
	local ply = LocalPlayer()

	local checkpointRespawning = net.ReadBool()

	if checkpointRespawning then
		local lastCheckHint = "#MelonRacer.LastCheckpointHint"

		local w = ScrW()
		local h = ScrH()

		local delta = CurTime()

		respawningAtLast = false

		hook.Add("HUDPaint", "MelonRacer_DeathHUD", function()
			-- Respawn timer --
			if respawnTime <= 0 then
				hook.Remove("HUDPaint", "MelonRacer_DeathHUD")
				return
			end

			local Seconds = math.floor(respawnTime * 10) / 10

			if Seconds % 1 == 0 then
				-- There's no decimal, add it
				Seconds = Seconds .. ".0"
			end

			local respawnStr = string.format(language.GetPhrase("MelonRacer.Respawning"), Seconds)

			-- Show respawn text
			draw.SimpleTextOutlined(respawnStr, "ScoreboardText", w * 0.5, h * 0.5, white, 1, 1, 1, Color(0, 0, 0, 255))

			if !respawningAtLast then
				draw.SimpleTextOutlined(lastCheckHint, "ScoreboardText", w * 0.5, h * 0.5 + 15, white, 1, 1, 1, Color(0, 0, 0, 255))
			end

			local diff = CurTime() - delta
			delta = CurTime()
			respawnTime = respawnTime - diff
		end)

		if ply.Checkpoint == 0 then
			ply.LapStart = CurTime() - respawnTime
		end

	else
		ply.Checkpoint = 0
	end
end
net.Receive("MelonRacer_PlayerRespawn", OnPlayerRespawn)

local function GetLargestHelp()
	local x1, y = surface.GetTextSize("#MelonRacer.Help1")
	local x2 = surface.GetTextSize("#MelonRacer.Help2")
	local x3 = surface.GetTextSize("#MelonRacer.Help3")
	local x4 = surface.GetTextSize("#MelonRacer.Help4")

	return math.max(x1, x2, x3, x4), y
end

local help
local function HelpScreen()
	if hook.Run("MR_Help") then return end

	if IsValid(help) then
		help:Remove()
	end

	local help1 = "#MelonRacer.Help1"
	local help2 = "#MelonRacer.Help2"
	local help3 = "#MelonRacer.Help3"
	local help4 = "#MelonRacer.Help4"

	local w, h = ScrW(), ScrH()

	help = vgui.Create("DPanel")

	surface.SetFont("LegacyDefault")
	local x, y = GetLargestHelp()
	help:SetSize(x, y * 5)
	help:SetPos((w / 2) - (x / 2), h * 0.3)

	help.Paint = function(s, pw, ph)
		surface.SetFont("LegacyDefault")
		surface.SetTextColor(255, 255, 255, s:GetAlpha())

		local tx = surface.GetTextSize(help1)
		surface.SetTextPos((pw / 2) - (tx / 2), 0)
		surface.DrawText(help1)

		tx = surface.GetTextSize(help2)
		surface.SetTextPos((pw / 2) - (tx / 2), y * 2)
		surface.DrawText(help2)

		tx = surface.GetTextSize(help3)
		surface.SetTextPos((pw / 2) - (tx / 2), y * 3)
		surface.DrawText(help3)

		tx = surface.GetTextSize(help4)
		surface.SetTextPos((pw / 2) - (tx / 2), y * 4)
		surface.DrawText(help4)
	end

	help:SetAlpha(0)

	help:AlphaTo(255, 0.2, 0)
	help:AlphaTo(0, 2, 5, function(_, pnl) pnl:Remove() end)
end
concommand.Add("mr_helpscreen", HelpScreen)