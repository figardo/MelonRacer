if SERVER then -- SERVER SIDED HOOKS
	local totalRounds = CreateConVar("mr_rounds", "6", FCVAR_NOTIFY, "The number of rounds per map (if MapVote is installed).")

	-- adds fretta like mapvote support - https://steamcommunity.com/sharedfiles/filedetails/?id=151583504
	local roundCount = 0
	hook.Add("MR_EndRound", "MR_FrettaMapVote", function(ply) -- called when a race is finished (ply = player who finished)
		local maxrounds = totalRounds:GetInt()
		if maxrounds <= 0 then return end -- opt out for people who don't want to disable mapvote

		roundCount = roundCount + 1
		if MapVote and roundCount >= maxrounds then
			timer.Simple(5, function()
				MapVote.Start(nil, nil, nil, {"gm_melon", "mr_", "melon_"}) -- look for maps with gm_melon, mr_, or melon_ prefixes
			end)

			return true -- prevents round from restarting
		end

		return false -- allows round to restart
	end)

	--[[ plays a car starting sound from each melon during the countdown
	hook.Add("MR_PrepRound", "MR_RevSound", function() -- called when all players are respawned
		for _, ply in player.Iterator() do
			local snd = CreateSound(ply, "vehicles/v8/v8_start_loop1.wav") -- created as an object so we can control when it stops
			snd:Play()

			timer.Simple(4, function() snd:Stop() end) -- don't want the sound looping
		end
	end)
	]]

	--[[ called when the race starts
	hook.Add("MR_StartRound")
	]]

	--[[ called when a melon breaks, ply = player who died
	hook.Add("MR_MelonDied", "", function(ply))
	]]

	--[[ called when a player hits a checkpoint, ply = player that hit the checkpoint, newCP = id of the hit checkpoint
	hook.Add("MR_HitCheckpoint", "", function(ply, newCP))
	]]
elseif CLIENT then -- CLIENT SIDED HOOKS
	local checkSplit = CreateClientConVar("mr_checkpointsplit", "0", true, false, "Display the current lap time when reaching a checkpoint.", 0, 1)

	--[[ called when drawing player labels, return true to prevent labels from being drawn
	hook.Add("MR_PlayerLabels")
	]]

	--[[ called when playing the intro animation, return true to stop the animation from playing
	hook.Add("MR_DrawIntro")
	]]

	--[[ called when the wrong way text is displayed, return true to not display the text
	hook.Add("MR_WrongWay")
	]]

	--called when the lap animation is played, return true to not play the lap animation
	hook.Add("MR_LapAnimation", "MR_ResetLapTime", function()
		LocalPlayer().LapStart = CurTime()
	end)

	--[[ called when drawing server wide stats (top 3, best lap), return true to not show these stats
	hook.Add("MR_DrawStats")
	]]

	--[[ called when drawing personal stats (your best lap, your last lap, lap count), return true to not show these stats
	hook.Add("MR_DrawPersonalStats")
	]]

	--[[ called when showing everyone the round winner, ply = round winner, return true to not show the winner
	hook.Add("MR_ShowWinner", ply)
	]]

	-- called when showing the checkpoint text, newCP = id of checkpoint hit, return true to not show the text
	local lastCP = 0
	hook.Add("MR_ShowCheckpoint", "MR_CheckpointTime", function(newCP) -- displays checkpoint splits
		if !checkSplit:GetBool() or newCP <= lastCP then return false end

		local startTime = LocalPlayer().LapStart
		if !startTime then return end

		local split = CurTime() - startTime

		local str = string.OldMSMS(split)

		surface.SetFont("LegacyDefault")
		local w, h = surface.GetTextSize(str)

		local point = vgui.Create("DLabel")
		point:SetFont("LegacyDefault")
		point:SetColor(color_white)
		point:SetSize(w, h)
		point:SetText(str)
		point:SetAlpha(0)

		point:SetPos((ScrW() / 2) - (w / 2), ScrH() * 0.85)
		point:AlphaTo(255, 0.2, 0)
		point:AlphaTo(0, 0.5, 1.5, function(_, pnl) pnl:Remove() end)

		return false
	end)

	-- called when showing the countdown, return true to not show the countdown
	hook.Add("MR_DrawRoundStart", "MR_GetLapTime", function() -- assists hook above
		timer.Simple(4, function()
			LocalPlayer().LapStart = CurTime()
		end)
	end)

	--[[ called when someone presses f1, return true to not show the help text
	hook.Add("MR_Help")
	]]
end