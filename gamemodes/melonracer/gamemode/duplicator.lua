-- one big copy-paste job from sandbox

local dupeNPCs = {
	-- HL2
	"npc_alyx",
	"npc_magnusson",
	"npc_breen",
	"npc_kleiner",
	"npc_antlion",
	"npc_antlion_worker",
	"npc_antlion_grub",
	"npc_antlionguard",
	"npc_barnacle",
	"npc_barney",
	"npc_combine_s",
	"npc_crow",
	"npc_cscanner",
	"npc_clawscanner",
	"npc_dog",
	"npc_eli",
	"npc_gman",
	"npc_headcrab",
	"npc_headcrab_black",
	"npc_headcrab_poison",
	"npc_headcrab_fast",
	"npc_manhack",
	"npc_metropolice",
	"npc_monk",
	"npc_mossman",
	"npc_pigeon",
	"npc_rollermine",
	"npc_strider",
	"npc_helicopter",
	"npc_combinegunship",
	"npc_combinedropship",
	"npc_turret_ceiling",
	"npc_combine_camera",
	"npc_turret_floor",
	"npc_vortigaunt",
	"npc_hunter",
	"npc_sniper",
	"npc_seagull",
	"npc_citizen",
	"npc_stalker",
	"npc_fisherman",
	"npc_zombie",
	"npc_zombie_torso",
	"npc_zombine",
	"npc_poisonzombie",
	"npc_fastzombie",
	"npc_fastzombie_torso",

	-- HL1
	"monster_alien_grunt",
	"monster_alien_slave",
	"monster_alien_controller",
	"monster_barney",
	"monster_bigmomma",
	"monster_bullchicken",
	"monster_babycrab",
	"monster_cockroach",
	"monster_houndeye",
	"monster_headcrab",
	"monster_gargantua",
	"monster_human_assassin",
	"monster_human_grunt",
	"monster_scientist",
	"monster_snark",
	"monster_nihilanth",
	"monster_tentacle",
	"monster_zombie",
	"monster_turret",
	"monster_miniturret",
	"monster_sentry"
}

function GM:RegisterDupeEnts()
	local function FixInvalidPhysicsObject( Prop )

		local PhysObj = Prop:GetPhysicsObject()
		if ( !IsValid( PhysObj ) ) then return end

		local min, max = PhysObj:GetAABB()
		if ( !min or !max ) then return end

		local PhysSize = ( min - max ):Length()
		if ( PhysSize > 5 ) then return end

		min = Prop:OBBMins()
		max = Prop:OBBMaxs()
		if ( !min or !max ) then return end

		local ModelSize = ( min - max ):Length()
		local Difference = math.abs( ModelSize - PhysSize )
		if ( Difference < 10 ) then return end

		-- This physics object is definitiely weird.
		-- Make a new one.

		Prop:PhysicsInitBox( min, max )
		Prop:SetCollisionGroup( COLLISION_GROUP_DEBRIS )

		PhysObj = Prop:GetPhysicsObject()
		if ( !IsValid( PhysObj ) ) then return end

		PhysObj:SetMass( 100 )
		PhysObj:Wake()

	end

	local function MakeProp( ply, Pos, Ang, model, _, Data )
		-- Uck.
		Data.Pos = Pos
		Data.Angle = Ang
		Data.Model = model

		-- Make sure this is allowed
		if ( IsValid( ply ) && !gamemode.Call( "PlayerSpawnProp", ply, model ) ) then return end

		local Prop = ents.Create( "prop_physics" )
		duplicator.DoGeneric( Prop, Data )
		Prop:Spawn()

		duplicator.DoGenericPhysics( Prop, ply, Data )

		-- Tell the gamemode we just spawned something
		if ( IsValid( ply ) ) then
			gamemode.Call( "PlayerSpawnedProp", ply, model, Prop )
		end

		FixInvalidPhysicsObject( Prop )

		return Prop
	end

	local function MakeRagdoll( ply, _, _, model, _, Data )
		if ( IsValid( ply ) && !gamemode.Call( "PlayerSpawnRagdoll", ply, model ) ) then return end

		local Ent = ents.Create( "prop_ragdoll" )
		duplicator.DoGeneric( Ent, Data )
		Ent:Spawn()

		duplicator.DoGenericPhysics( Ent, ply, Data )

		Ent:Activate()

		if ( IsValid( ply ) ) then
			gamemode.Call( "PlayerSpawnedRagdoll", ply, model, Ent )
		end

		return Ent
	end

	local function MakeEffect( ply, model, Data )
		Data.Model = model

		-- Make sure this is allowed
		if ( IsValid( ply ) && !gamemode.Call( "PlayerSpawnEffect", ply, model ) ) then return end

		local Prop = ents.Create( "prop_effect" )
		duplicator.DoGeneric( Prop, Data )
		if ( Data.AttachedEntityInfo ) then
			Prop.AttachedEntityInfo = table.Copy( Data.AttachedEntityInfo ) -- This shouldn't be neccesary
		end
		Prop:Spawn()

		-- duplicator.DoGenericPhysics( Prop, ply, Data )

		-- Tell the gamemode we just spawned something
		if ( IsValid( ply ) ) then
			gamemode.Call( "PlayerSpawnedEffect", ply, model, Prop )
		end

		return Prop
	end

	local function InternalSpawnNPC( ply, Position, Normal, Class, Equipment, SpawnFlagsSaved, NoDropToFloor )

		local NPCList = list.Get( "NPC" )
		local NPCData = NPCList[ Class ]

		-- Don't let them spawn this entity if it isn't in our NPC Spawn list.
		-- We don't want them spawning any entity they like!
		if ( !NPCData ) then
			if ( IsValid( ply ) ) then
				ply:SendLua( "Derma_Message( \"Sorry! You can't spawn that NPC!\" )" )
			end
			return
		end

		local isAdmin = ( IsValid( ply ) && ply:IsAdmin() ) or game.SinglePlayer()
		if ( NPCData.AdminOnly && !isAdmin ) then return end

		local bDropToFloor = false

		--
		-- This NPC has to be spawned on a ceiling ( Barnacle )
		--
		if ( NPCData.OnCeiling ) then
			if ( Vector( 0, 0, -1 ):Dot( Normal ) < 0.95 ) then
				return nil
			end

		--
		-- This NPC has to be spawned on a floor ( Turrets )
		--
		elseif ( NPCData.OnFloor && Vector( 0, 0, 1 ):Dot( Normal ) < 0.95 ) then
			return nil
		else
			bDropToFloor = true
		end

		if ( NPCData.NoDrop or NoDropToFloor ) then bDropToFloor = false end

		-- Create NPC
		local NPC = ents.Create( NPCData.Class )
		if ( !IsValid( NPC ) ) then return end

		--
		-- Offset the position
		--
		local Offset = NPCData.Offset or 32
		NPC:SetPos( Position + Normal * Offset )

		-- Rotate to face player (expected behaviour)
		local Angles = Angle( 0, 0, 0 )

		if ( IsValid( ply ) ) then
			Angles = ply:GetAngles()
		end

		Angles.pitch = 0
		Angles.roll = 0
		Angles.yaw = Angles.yaw + 180

		if ( NPCData.Rotate ) then Angles = Angles + NPCData.Rotate end

		NPC:SetAngles( Angles )

		--
		-- This NPC has a special model we want to define
		--
		if ( NPCData.Model ) then
			NPC:SetModel( NPCData.Model )
		end

		--
		-- This NPC has a special texture we want to define
		--
		if ( NPCData.Material ) then
			NPC:SetMaterial( NPCData.Material )
		end

		--
		-- Spawn Flags
		--
		local SpawnFlags = bit.bor( SF_NPC_FADE_CORPSE, SF_NPC_ALWAYSTHINK )
		if ( NPCData.SpawnFlags ) then SpawnFlags = bit.bor( SpawnFlags, NPCData.SpawnFlags ) end
		if ( NPCData.TotalSpawnFlags ) then SpawnFlags = NPCData.TotalSpawnFlags end
		if ( SpawnFlagsSaved ) then SpawnFlags = SpawnFlagsSaved end
		NPC:SetKeyValue( "spawnflags", SpawnFlags )
		NPC.SpawnFlags = SpawnFlags

		--
		-- Optional Key Values
		--
		if ( NPCData.KeyValues ) then
			for k, v in pairs( NPCData.KeyValues ) do
				NPC:SetKeyValue( k, v )
			end
		end

		--
		-- This NPC has a special skin we want to define
		--
		if ( NPCData.Skin ) then
			NPC:SetSkin( NPCData.Skin )
		end

		--
		-- What weapon should this mother be carrying
		--

		-- Check if this is a valid entity from the list, or the user is trying to fool us.
		local valid = false
		for _, v in pairs( list.Get( "NPCUsableWeapons" ) ) do
			if v.class == Equipment then valid = true break end
		end
		for _, v in pairs( NPCData.Weapons or {} ) do
			if v == Equipment then valid = true break end
		end

		if ( Equipment && Equipment != "none" && valid ) then
			NPC:SetKeyValue( "additionalequipment", Equipment )
			NPC.Equipment = Equipment
		end

		NPC:Spawn()
		NPC:Activate()

		-- For those NPCs that set their model in Spawn function
		-- We have to keep the call above for NPCs that want a model set by Spawn() time
		-- BAD: They may adversly affect entity collision bounds
		if ( NPCData.Model && NPC:GetModel():lower() != NPCData.Model:lower() ) then
			NPC:SetModel( NPCData.Model )
		end

		if ( bDropToFloor ) then
			NPC:DropToFloor()
		end

		if ( NPCData.Health ) then
			NPC:SetHealth( NPCData.Health )
		end

		-- Body groups
		if ( NPCData.BodyGroups ) then
			for k, v in pairs( NPCData.BodyGroups ) do
				NPC:SetBodygroup( k, v )
			end
		end

		return NPC

	end

	local function GenericNPCDuplicator( ply, mdl, class, equipment, spawnflags, data )
		if ( IsValid( ply ) && !gamemode.Call( "PlayerSpawnNPC", ply, class, equipment ) ) then return end

		local normal = Vector( 0, 0, 1 )

		local NPCList = list.Get( "NPC" )
		local NPCData = NPCList[ class ]
		if ( NPCData && NPCData.OnCeiling ) then normal = Vector( 0, 0, -1 ) end

		local ent = InternalSpawnNPC( ply, data.Pos, normal, class, equipment, spawnflags, true )

		if ( IsValid( ent ) ) then
			local pos = ent:GetPos() -- Hack! Prevnets the NPCs from falling through the floor

			duplicator.DoGeneric( ent, data )

			if ( !NPCData.OnCeiling && !NPCData.NoDrop ) then
				ent:SetPos( pos )
				ent:DropToFloor()
			end

			if ( IsValid( ply ) ) then
				gamemode.Call( "PlayerSpawnedNPC", ply, ent )
				ply:AddCleanup( "npcs", ent )
			end

			table.Add( ent:GetTable(), data )

		end

		return ent
	end

	-- Huuuuuuuuhhhh
	local function AddNPCToDuplicator( class ) duplicator.RegisterEntityClass( class, GenericNPCDuplicator, "Model", "Class", "Equipment", "SpawnFlags", "Data" ) end

	duplicator.RegisterEntityClass( "prop_ragdoll", MakeRagdoll, "Pos", "Ang", "Model", "PhysicsObjects", "Data" )
	duplicator.RegisterEntityClass( "prop_physics", MakeProp, "Pos", "Ang", "Model", "PhysicsObjects", "Data" )
	duplicator.RegisterEntityClass( "prop_physics_multiplayer", MakeProp, "Pos", "Ang", "Model", "PhysicsObjects", "Data" )
	duplicator.RegisterEntityClass( "prop_effect", MakeEffect, "Model", "Data" )

	for i = 1, #dupeNPCs do
		AddNPCToDuplicator(dupeNPCs[i])
	end

	self.DupeEntsRegistered = true
end