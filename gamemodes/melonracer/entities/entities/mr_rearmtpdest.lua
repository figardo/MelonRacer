AddCSLuaFile()

ENT.Type = "point"
ENT.Base = "base_point"

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "ID", {KeyName = "MelonRacer_TeleportDestID", Edit = {type = "Generic", order = 1}})
end