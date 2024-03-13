include("shared.lua")
include("gui.lua")
include("hookexamples.lua")

include("controls.lua")
include("sh_player_ext.lua")

local textScale = CreateClientConVar("mr_hudscale", "1", true, false, "Text scale multiplier for the HUD.")
local ntScale = CreateClientConVar("mr_nametagscale", "1", true, false, "Text scale multiplier for the name tags.")
local enableBeta = CreateClientConVar("mr_betahud", "0", true, true, "Enable GMod 8.4 mode. Disables the stats HUD, replaces the lap animation with text, and shows Checkpoint 0 when the lap point has been hit.")

-- replicated
CreateClientConVar("mr_godmode", "0")
CreateClientConVar("mr_forwardspeed", "170")
CreateClientConVar("mr_reversespeed", "170")

local function CreateNameFont()
	local scale = ntScale:GetFloat()

	surface.CreateFont("BrandingSmall", {
		font = "Verdana",
		size = 12 * scale,
		weight = 100,
		antialias = true,
		shadow = true,
	})
end

local function CreateOtherFonts()
	local scale = textScale:GetFloat()

	surface.CreateFont("ImpactMassive", {
		font = "Impact",
		size = ScreenScaleH(23.333) * scale,
		weight = 200
	})

	surface.CreateFont("DefaultShadow", {
		font = "Verdana",
		size = ScreenScaleH(8) * scale,
		weight = 700,
		shadow = true
	})

	surface.CreateFont("LegacyDefault", {
		font = "Verdana",
		size = ScreenScaleH(8) * scale,
		weight = 700
	})

	surface.CreateFont("ScoreboardText", {
		font = "Default",
		size = ScreenScaleH(5.333) * scale,
		weight = 800
	})
end

local function CreateFonts()
	CreateNameFont()
	CreateOtherFonts()
end
CreateFonts()

cvars.AddChangeCallback("mr_hudscale", CreateFonts)
cvars.AddChangeCallback("mr_nametagscale", CreateFonts)
hook.Add("OnScreenSizeChanged", "MR_RegenFonts", CreateFonts)

local clickforward = CreateClientConVar("mr_clickcontrols", "0", true, true, "When enabled, left click will act as a forward key.")

-- local function DrawCheckpoints()
-- 	for _, checkpoint in ipairs(ents.FindByClass("trigger_multiple")) do
-- 		print(checkpoint)
-- 		local mins, maxs = checkpoint:GetCollisionBounds()
-- 		render.DrawBox(checkpoint:GetPos(), Angle(0, 0, 0), mins, maxs)
-- 	end

-- 	return false
-- end
-- hook.Add("PostDrawOpaqueRenderables", "MR_CheckpointDraw", DrawCheckpoints)

function GM:HUDPaint()
	self:UpdatePlayerLabels()

	local ply = LocalPlayer()
	if ply:Team() == TEAM_SPECTATOR or enableBeta:GetBool() then return end
	self:DrawStats()
	self:DrawPersonalStats()
end

local function QueryTrack()
	if !LocalPlayer():IsAdmin() then return end

	local w = ScrW()
	local h = ScrH()

	local dframe = vgui.Create("DFrame")
	dframe:SetSize(w / 8, h / 4)
	dframe:SetPos((w / 2) - ((w / 8) / 2), (h / 2) - ((h / 4) / 2))
	dframe:SetTitle("Track Select")
	dframe:MakePopup()

	local dlist = vgui.Create("DScrollPanel", dframe)
	dlist:Dock(FILL)

	local numTracks = net.ReadUInt(8)

	for i = 1, numTracks do
		local name = net.ReadString()
		local nick = net.ReadString()

		local dbutton = dlist:Add("DButton")

		dbutton:SetText(name .. " by " .. nick)
		dbutton:Dock(TOP)
		dbutton:DockMargin(0, 0, 0, 5)

		function dbutton:DoClick()
			net.Start("MelonRacer_SelectTrack")
				net.WriteUInt(i, 8)
			net.SendToServer()

			dframe:Close()
		end
	end
end
net.Receive("MelonRacer_QueryTrack", QueryTrack)

local function AskForTracks()
	net.Start("MelonRacer_AskForTracks")
	net.SendToServer()
end
concommand.Add("mr_choosetrack", AskForTracks)

local unsupported = {
	["el"] = "Η ελληνική γλώσσα δεν υποστηρίζεται. Συμβάλετε εδώ:",
	["et"] = "Eesti keel toetamata. Anna oma panus siin:",
	["fi"] = "Suomen kieltä ei tueta. Osallistu täällä:",
	["he"] = "אין תמיכה בשפה העברית. תרמו כאן:",
	["hr"] = "Hrvatski jezik nije podržan. Doprinesite ovdje:",
	["ko"] = "한국어는 지원하지 않습니다. 여기에 기여하세요:",
	-- ["lt"] = "lietuvių kalba nepalaikoma. Prisidėkite čia:",
	["nl"] = "Nederlandse taal niet ondersteund. Draag hier bij:",
	["no"] = "Norsk språk støttes ikke. Bidra her:",
	["pt-pt"] = "Língua portuguesa europeia não suportada. Contribua aqui:",
	["sk"] = "Slovenský jazyk nie je podporovaný. Prispejte sem:",
	-- ["sv-se"] = "Svenska språket stöds inte. Bidra här:",
	-- ["tr"] = "Türkçe dil desteklenmiyor. Buraya katkıda bulunun:",
	-- ["zh-cn"] = "不支持中文（简体）语言。 在这里贡献：",
	["zh-tw"] = "不支持中文（繁體）語言。 在這裡貢獻："
}

local langcvar = GetConVar("gmod_language")
function GM:InitPostEntity()
	local ply = LocalPlayer()
	ply.CamDistance = 10

	self:DrawIntro()

	self:ResetStats()

	local lang = langcvar:GetString():lower()
	if unsupported[lang] then
		ply:ChatPrint("Selected language is unsupported. Contribute here: https://crowdin.com/project/melonracer")
		ply:ChatPrint(unsupported[lang] .. " https://crowdin.com/project/melonracer")
	end
end

function GM:ResetStats()
	self.Stats = {}

	self.Stats.BestLap		= 0
	self.Stats.BestLapName	= NO_NAME
	self.Stats.Places = {
		NO_NAME,
		NO_NAME,
		NO_NAME
	}
end

local dist = 10
local camspeed = CreateClientConVar("mr_camspeed", "0.25", true, false, "The rate that the camera will approach its target distance.", 0)
function GM:CalcView(ply, pos, ang, fov)
	local view = {
		origin = pos,
		angles = ang,
		fov = fov
	}

	local melon = ply:GetObserverTarget()
	if !IsValid(melon) then
		if ply.Checkpoint == 0 then
			ply.LapStart = CurTime() -- teehee
		end

		return view
	end

	if !ply.CamDistance then ply.CamDistance = 10 end
	dist = math.Approach(dist, ply.CamDistance, camspeed:GetFloat())

	view.origin = pos - (ang:Forward() * dist)

	local tr = util.TraceLine({
		start = pos,
		endpos = view.origin,
		filter = {ply, melon}
	})

	if tr.Hit and tr.HitPos then
		view.origin = tr.HitPos + (ang:Forward() * 3)
		-- dist = ply.CamDistance - melon:GetPos()
	end

	-- view.origin = vog
	-- view.origin.x = math.Approach(view.origin.x, desired.x, 0.5)
	-- view.origin.y = math.Approach(view.origin.y, desired.y, 0.5)
	-- view.origin.z = math.Approach(view.origin.z, desired.z, 0.5)

	return view
end

function GM:KeyPress(ply, in_key)
	if in_key != IN_ATTACK2 or clickforward:GetBool() then return end

	ply.CamDistance = ply.CamDistance + 40

	if ply.CamDistance > 40 then
		dist = -80
		ply.CamDistance = -80
	end
end

local cooldown = CurTime()
function GM:CreateMove(ucmd)
	local mwheel = ucmd:GetMouseWheel()
	if mwheel == 0 or cooldown > CurTime() then return end

	local ply = LocalPlayer()
	local desired
	local current = ply.CamDistance

	if mwheel > 0 then
		desired = current - 40
	elseif mwheel < 0 then
		desired = current + 40
	end

	desired = math.Clamp(desired, -80, 40)

	ply.CamDistance = desired
	cooldown = CurTime() + 0.1
end