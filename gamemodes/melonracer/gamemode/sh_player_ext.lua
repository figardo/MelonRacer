local meta = FindMetaTable("Player")

function meta:SetMelon(ent)
	-- Set our new melon
	self.Melon = ent

	if SERVER then
		self:SetNWEntity("melon", ent)
	end
end

function meta:GetMelon()
	if IsValid(self.Melon) then return self.Melon end

	self.Melon = self:GetNWEntity("melon")

	return self.Melon
end