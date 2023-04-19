GM.Name = "MelonRacer"
GM.Author = "Garry Newman"
GM.Email = ""
GM.Website = "garry.blog"

NO_NAME			= "n/a"

-- saving some bits

local pcountcache = 0
local bitcache = 0

local function GetPlayerBits()
	local plycount = player.GetCount()
	if pcountcache != plycount then
		pcountcache = plycount

		local plylog = math.log(plycount)
		local log2 = math.log(2)
		bitcache = math.ceil((plylog > 0 and plylog or log2) / log2)
	end

	return bitcache
end

function MR_WritePlayer(ent)
	local bits = GetPlayerBits()

	if IsEntity(ent) then ent = ent:EntIndex() end
	net.WriteUInt(ent, bits)
end

function MR_ReadPlayer()
	local bits = GetPlayerBits()
	local index = net.ReadUInt(bits)
	if index == 0 then return index end

	local ent = Entity(index)

	return ent
end