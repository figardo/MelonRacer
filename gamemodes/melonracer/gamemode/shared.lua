GM.Name = "MelonRacer"
GM.Author = "Garry Newman"
GM.Email = ""
GM.Website = "garry.blog"

NO_NAME			= "n/a"

local developer = GetConVar("developer")
function DevPrint(...) -- ttt my beloved
	if !developer:GetBool() then return end

	Msg("[MelonRacer]")
	-- table.concat does not tostring, derp

	local params = {...}
	for i = 1,#params do
		Msg(" " .. tostring(params[i]))
	end

	Msg("\n")
end