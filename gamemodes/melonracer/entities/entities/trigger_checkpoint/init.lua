ENT.Base = "base_brush"
ENT.Type = "brush"

/*---------------------------------------------------------
   Name: Initialize
---------------------------------------------------------*/
function ENT:Initialize()
	self.CheckpointNum = self.CheckpointNum or 0
end

/*---------------------------------------------------------
   Name: SetupGlobals
---------------------------------------------------------*/
function ENT:SetupGlobals( activator, caller )
	ACTIVATOR = activator
	CALLER = caller

	if ( IsValid( activator ) and activator:IsPlayer() ) then
		TRIGGER_PLAYER = activator
	end
end

/*---------------------------------------------------------
   Name: KillGlobals
---------------------------------------------------------*/
function ENT:KillGlobals()
	ACTIVATOR = nil
	CALLER = nil
	TRIGGER_PLAYER = nil
end

/*---------------------------------------------------------
   Name: StartTouch
---------------------------------------------------------*/
function ENT:StartTouch(entity)
	self:SetupGlobals(entity, entity)

	HitCheckpoint(self.CheckpointNum)

	self:KillGlobals()
end

/*---------------------------------------------------------
   Name: PassesTriggerFilters
   Desc: Return true if this object should trigger us
---------------------------------------------------------*/
function ENT:PassesTriggerFilters(Ent)
	return true
end

/*---------------------------------------------------------
   Name: KeyValue
   Desc: Called when a keyvalue is added to us
---------------------------------------------------------*/
function ENT:KeyValue(Key, Value)
	if (string.lower(Key) == "checkpoint") then
		self.CheckpointNum = tonumber(Value) - 1
	end
end