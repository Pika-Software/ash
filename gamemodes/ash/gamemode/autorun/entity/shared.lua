---@type dreamwork.std
local std = _G.dreamwork.std

local math = std.math
local math_huge = math.huge

local Entity_GetNW2Var = Entity.GetNW2Var
local Entity_SetNW2Var = Entity.SetNW2Var
local Entity_IsValid = Entity.IsValid

local Variable = std.console.Variable
local hook_Run = hook.Run
local isnumber = isnumber

local NULL = NULL

---@class ash.entity
local ash_entity = {}

ash_entity.isPlayer = Entity.IsPlayer

do

    local prop_class_names = list.GetForEdit( "ash.prop.classnames" )

    prop_class_names.prop_physics_multiplayer = true
	prop_class_names.prop_physics_override = true
	prop_class_names.prop_dynamic_override = true
	prop_class_names.prop_dynamic = true
	prop_class_names.prop_ragdoll = true
	prop_class_names.prop_physics = true
	prop_class_names.prop_detail = true
	prop_class_names.prop_static = true

    --- [SHARED]
    ---
    --- Checks if the class name is a prop class.
    ---
    ---@param class_name string
    ---@return boolean is_prop
    function ash_entity.isPropClass( class_name )
        return prop_class_names[ class_name ] == true
    end

end

do

    local ragdoll_class_names = list.GetForEdit( "ash.ragdoll.classnames" )

    ragdoll_class_names.prop_ragdoll = true
    ragdoll_class_names.C_ClientRagdoll = true
    ragdoll_class_names.C_HL2MPRagdoll = true
    ragdoll_class_names.hl2mp_ragdoll = true

    --- [SHARED]
    ---
    --- Checks if the class name is a ragdoll class.
    ---
    ---@param class_name string
    ---@return boolean is_ragdoll
    function ash_entity.isRagdollClass( class_name )
        return ragdoll_class_names[ class_name ] == true
    end

end

do

    local button_class_names = list.GetForEdit( "ash.button.classnames" )

    button_class_names.momentary_rot_button = true
    button_class_names.func_rot_button = true
    button_class_names.func_button = true
    button_class_names.gmod_button = true

    --- [SHARED]
    ---
    --- Checks if the class name is a button class.
    ---
    ---@param class_name string
    ---@return boolean is_button
    function ash_entity.isButtonClass( class_name )
        return button_class_names[ class_name ] == true
    end

end

do

    local door_class_names = list.GetForEdit( "ash.door.classnames" )

    door_class_names.prop_door_rotating_checkpoint = true
    door_class_names.prop_testchamber_door = true
    door_class_names.prop_door_rotating = true
    door_class_names.func_door_rotating = true
    door_class_names.func_door = true

    --- [SHARED]
    ---
    --- Checks if the class name is a door class.
    ---
    ---@param class_name string
    ---@return boolean is_door
    function ash_entity.isDoorClass( class_name )
        return door_class_names[ class_name ] == true
    end

end

do

    local breakable_class_names = list.GetForEdit( "ash.breakable.classnames" )

    breakable_class_names.func_breakable_surf = true
    breakable_class_names.func_breakable = true
    breakable_class_names.func_physbox = true

    --- [SHARED]
    ---
    --- Checks if the class name is a breakable class.
    ---
    ---@param class_name string
    ---@return boolean is_breakable
    function ash_entity.isBreakableClass( class_name )
        return breakable_class_names[ class_name ] == true
    end

end

do

    local spawnpoint_class_names = list.GetForEdit( "ash.spawnpoint.classnames" )

    -- Garry's Mod
    spawnpoint_class_names.info_player_start = true

    -- Garry's Mod (old)
    spawnpoint_class_names.gmod_player_start = true

    -- Half-Life 2: Deathmatch
    spawnpoint_class_names.info_player_deathmatch = true
    spawnpoint_class_names.info_player_combine = true
    spawnpoint_class_names.info_player_rebel = true

    -- Counter-Strike: Source & Counter-Strike: Global Offensive
    spawnpoint_class_names.info_player_counterterrorist = true
    spawnpoint_class_names.info_player_terrorist = true

    -- Day of Defeat: Source
    spawnpoint_class_names.info_player_axis = true
    spawnpoint_class_names.info_player_allies = true

    -- Team Fortress 2
    spawnpoint_class_names.info_player_teamspawn = true

    -- Insurgency
    spawnpoint_class_names.ins_spawnpoint = true

    -- AOC
    spawnpoint_class_names.aoc_spawnpoint = true

    -- Dystopia
    spawnpoint_class_names.dys_spawn_point = true

    -- Pirates, Vikings, and Knights II
    spawnpoint_class_names.info_player_pirate = true
    spawnpoint_class_names.info_player_viking = true
    spawnpoint_class_names.info_player_knight = true

    -- D.I.P.R.I.P. Warm Up
    spawnpoint_class_names.diprip_start_team_blue = true
    spawnpoint_class_names.diprip_start_team_red = true

    -- OB
    spawnpoint_class_names.info_player_red = true
    spawnpoint_class_names.info_player_blue = true

    -- Synergy
    spawnpoint_class_names.info_player_coop = true

    -- Zombie Panic! Source
    spawnpoint_class_names.info_player_human = true
    spawnpoint_class_names.info_player_zombie = true

    -- Zombie Master
    spawnpoint_class_names.info_player_zombiemaster = true

    -- Fistful of Frags
    spawnpoint_class_names.info_player_fof = true
    spawnpoint_class_names.info_player_desperado = true
    spawnpoint_class_names.info_player_vigilante = true

    -- Left 4 Dead & Left 4 Dead 2
    spawnpoint_class_names.info_survivor_rescue = true
    -- spawnpoint_class_names.info_survivor_position = true

    --- [SHARED]
    ---
    --- Checks if the class name is a spawnpoint class.
    ---
    ---@param class_name string
    ---@return boolean is_spawnpoint
    function ash_entity.isSpawnpointClass( class_name )
        return spawnpoint_class_names[ class_name ] == true
    end

end

do

    local Entity_GetHitboxSetCount = Entity.GetHitboxSetCount
    local Entity_GetHitBoxCount = Entity.GetHitBoxCount

    local Entity_GetHitboxSet = Entity.GetHitboxSet
    local Entity_SetHitboxSet = Entity.SetHitboxSet

    local Entity_GetHitBoxHitGroup = Entity.GetHitBoxHitGroup
    local Entity_GetHitBoxBounds = Entity.GetHitBoxBounds
    local Entity_GetHitBoxBone = Entity.GetHitBoxBone

    --- [SHARED]
    ---
    --- Get hitbox set count.
    ---
    ---@param entity Entity
    ---@return integer
    function ash_entity.getHitboxGroupCount( entity )
        return Entity_GetHitboxSetCount( entity )
    end

    --- [SHARED]
    ---
    --- Get hitbox count.
    ---
    ---@param entity Entity
    ---@param hitbox_group integer
    ---@return integer
    function ash_entity.getHitboxCount( entity, hitbox_group )
        return Entity_GetHitBoxCount( entity, ( hitbox_group or 0 ) - 1 )
    end

    --- [SHARED]
    ---
    --- Get hitbox groups.
    ---
    ---@param entity Entity
    ---@return string[] groups
    ---@return integer group_count
    function ash_entity.getHitboxGroups( entity )
        local initial_hitbox_group = Entity_GetHitboxSet( entity )
        local groups, group_count = {}, 0

        for hitbox_group = 1, Entity_GetHitboxSetCount( entity ), 1 do
            Entity_SetHitboxSet( entity, hitbox_group - 1 )
            local _, group_name = Entity_GetHitboxSet( entity )

            group_count = group_count + 1
            groups[ group_count ] = group_name
        end

        Entity_SetHitboxSet( entity, initial_hitbox_group )

        return groups, group_count
    end

    --- [SHARED]
    ---
    --- Get hitbox set.
    ---
    ---@param entity Entity
    ---@return integer hitbox_group
    function ash_entity.getHitboxGroup( entity )
        return Entity_GetHitboxSet( entity ) + 1
    end

    --- [SHARED]
    ---
    --- Set hitbox set.
    ---
    ---@param entity Entity
    ---@param hitbox_group integer
    function ash_entity.setHitboxGroup( entity, hitbox_group )
        return Entity_SetHitboxSet( entity, hitbox_group - 1 )
    end

    --- [SHARED]
    ---
    --- Get hitbox ID.
    ---
    ---@param entity Entity
    ---@param bone_id integer
    ---@return integer | nil hitbox
    ---@return integer hitbox_group
    function ash_entity.getHitbox( entity, bone_id )
        local hitbox_group = Entity_GetHitboxSet( entity )

        for hitbox = 0, Entity_GetHitBoxCount( entity, hitbox_group ) - 1, 1 do
            if Entity_GetHitBoxBone( entity, hitbox, hitbox_group ) == bone_id then
                return hitbox + 1, hitbox_group + 1
            end
        end

        return nil, hitbox_group + 1
    end

    --- [SHARED]
    ---
    --- Get hitbox bone.
    ---
    ---@param entity Entity
    ---@param hitbox integer
    ---@param hitbox_group integer
    ---@return integer | nil
    function ash_entity.getHitboxBone( entity, hitbox, hitbox_group )
        return Entity_GetHitBoxBone( entity, hitbox - 1, hitbox_group - 1 )
    end

    --- [SHARED]
    ---
    --- Get hitbox bounds.
    ---
    ---@param entity Entity
    ---@param hitbox integer
    ---@param hitbox_group integer
    ---@return Vector | nil mins
    ---@return Vector | nil maxs
    function ash_entity.getHitboxBounds( entity, hitbox, hitbox_group )
        return Entity_GetHitBoxBounds( entity, hitbox - 1, hitbox_group - 1 )
    end

    --- [SHARED]
    ---
    --- Get hitbox hit group.
    ---
    ---@param entity Entity
    ---@param hitbox integer
    ---@param hitbox_group integer
    ---@return integer | nil
    function ash_entity.getHitboxHitGroup( entity, hitbox, hitbox_group )
        return Entity_GetHitBoxHitGroup( entity, hitbox - 1, hitbox_group - 1 )
    end

end

do

    local Entity_SelectWeightedSequence = Entity.SelectWeightedSequence

    --- [SHARED]
    ---
    --- Check if activity exists.
    ---
    ---@param entity Entity
    ---@param activity integer
    function ash_entity.isActivityExists( entity, activity )
        local sequence_id = Entity_SelectWeightedSequence( entity, activity )
        return sequence_id ~= nil and sequence_id > 0
    end

end

do

    local Entity_LookupAttachment = Entity.LookupAttachment
    local Entity_GetAttachment = Entity.GetAttachment

    --- [SHARED]
    ---
    --- Get attachment ID.
    ---
    ---@param entity Entity
    ---@param attachment_name string
    ---@return integer | nil
    local function getAttachmentID( entity, attachment_name )
        local attachment_id = Entity_LookupAttachment( entity, attachment_name )

        if attachment_id == nil or attachment_id == 0 or attachment_id == -1 then
            return nil
        end

        return attachment_id
    end

    ash_entity.getAttachmentID = getAttachmentID

    --- [SHARED]
    ---
    --- Get attachment by ID.
    ---
    ---@param entity Entity
    ---@param attachment_id integer | nil
    ---@return Vector | nil attachment_origin
    ---@return Angle | nil attachment_angles
    ---@return integer | nil bone_id
    local function getAttachmentByID( entity, attachment_id )
        if attachment_id == nil then
            return nil, nil, nil
        end

        local attachment_data = Entity_GetAttachment( entity, attachment_id )

        if attachment_data == nil then
            return nil, nil, nil
        end

        return attachment_data.Pos, attachment_data.Ang, attachment_data.Bone
    end

    ash_entity.getAttachmentByID = getAttachmentByID

    --- [SHARED]
    ---
    --- Get attachment by name.
    ---
    ---@param entity Entity
    ---@param attachment_name string
    ---@return Vector | nil attachment_origin
    ---@return Angle | nil attachment_angles
    ---@return integer | nil bone_id
    function ash_entity.getAttachmentByName( entity, attachment_name )
        return getAttachmentByID( entity, getAttachmentID( entity, attachment_name ) )
    end

end

do

    local default_player_color = Vector( 62 / 255, 88 / 255, 106 / 255 )
    local default_weapon_color = Vector( 0.4, 1, 1 )

    --- [SHARED]
    ---
    --- Get player color.
    ---
    ---@param entity Entity
    ---@return Vector color_vec3
    function Entity.GetPlayerColor( entity )
        return Entity_GetNW2Var( entity, "m_vPlayerColor", default_player_color )
    end

    Player.GetPlayerColor = Entity.GetPlayerColor

    --- [SHARED]
    ---
    --- Get weapon color.
    ---
    ---@param entity Entity
    ---@return Vector color_vec3
    function Entity.GetWeaponColor( entity )
        return Entity_GetNW2Var( entity, "m_vWeaponColor", default_weapon_color )
    end

    Player.GetWeaponColor = Entity.GetWeaponColor

    if CLIENT then

        local Material_SetVector = Material.SetVector

        matproxy.Add( {
            name = "PlayerColor",
            init = function( self, _, values )
                self.ResultTo = values.resultvar
            end,
            bind = function( self, material, entity )
                return Material_SetVector( material, self.ResultTo, Entity_GetNW2Var( entity, "m_vPlayerColor", default_player_color ) )
            end
        } )

        matproxy.Add( {
            name = "PlayerWeaponColor",
            init = function( self, _, values )
                self.ResultTo = values.resultvar
            end,
            bind = function( self, material, entity )
                return Material_SetVector( material, self.ResultTo, Entity_GetNW2Var( entity, "m_vWeaponColor", default_weapon_color ) )
            end
        } )

    end

    do

        local math_floor = math.floor

        --- [SHARED]
        ---
        --- Get player color.
        ---
        ---@param entity Entity
        ---@return Color color
        function ash_entity.getPlayerColor( entity )
            local vector = Entity_GetNW2Var( entity, "m_vPlayerColor", default_player_color )
            return Color( math_floor( vector[ 1 ] * 255 ), math_floor( vector[ 2 ] * 255 ), math_floor( vector[ 3 ] * 255 ), 255 )
        end

        --- [SHARED]
        ---
        --- Get weapon color.
        ---
        ---@param entity Entity
        ---@return Color color
        function ash_entity.getWeaponColor( entity )
            local vector = Entity_GetNW2Var( entity, "m_vWeaponColor", default_weapon_color )
            return Color( math_floor( vector[ 1 ] * 255 ), math_floor( vector[ 2 ] * 255 ), math_floor( vector[ 3 ] * 255 ), 255 )
        end

    end

end

--- [SHARED]
---
--- Check if entity is button.
---
---@param entity Entity
---@return boolean is_button
function ash_entity.isButton( entity )
    return Entity_GetNW2Var( entity, "m_bButton", false ) == true
end

local Entity_GetClass = Entity.GetClass

ash_entity.getSolidType = Entity.GetSolid
ash_entity.getClassName = Entity_GetClass

ash_entity.getEngineValue = Entity.GetInternalVariable
ash_entity.setEngineValue = Entity.SetKeyValue

do

    local utils_isRagdollClass = ash_entity.isRagdollClass

    --- [SHARED]
    ---
    --- Check if entity is prop.
    ---
    ---@param entity Entity
    ---@return boolean is_prop
    function ash_entity.isProp( entity )
        return utils_isRagdollClass( Entity_GetClass( entity ) )
    end

end

do

    local utils_isRagdollClass = ash_entity.isRagdollClass

    --- [SHARED]
    ---
    --- Check if entity is ragdoll.
    ---
    ---@param entity Entity
    ---@return boolean is_ragdoll
    function ash_entity.isRagdoll( entity )
        return utils_isRagdollClass( Entity_GetClass( entity ) )
    end

end

do

    local Entity_GetBrushPlaneCount = Entity.GetBrushPlaneCount

    --- [SHARED]
    ---
    --- Check if entity is brush.
    ---
    ---@param entity Entity
    ---@return boolean is_brush
    function ash_entity.isBrush( entity )
       return Entity_GetBrushPlaneCount( entity ) ~= 0
    end

end

do

    local Entity_GetRenderMode = Entity.GetRenderMode
    ash_entity.getRenderMode = Entity_GetRenderMode

    ---@type table<integer, boolean>
    local transparent_modes = {
        [ RENDERMODE_NORMAL ] = false,
        [ RENDERMODE_TRANSCOLOR ] = true,
        [ RENDERMODE_TRANSTEXTURE ] = true,
        [ RENDERMODE_GLOW ] = true,
        [ RENDERMODE_TRANSALPHA ] = false,
        [ RENDERMODE_TRANSADD ] = true,
        [ RENDERMODE_ENVIROMENTAL ] = false,
        [ RENDERMODE_TRANSADDFRAMEBLEND	] = true,
        [ RENDERMODE_TRANSALPHADD ] = true,
        [ RENDERMODE_WORLDGLOW ] = true,
        [ RENDERMODE_NONE ] = false
    }

    setmetatable( transparent_modes, {
        __index = function()
            return false
        end
    } )

    --- [SHARED]
    ---
    --- Check if entity is transparent.
    ---
    ---@param entity Entity
    ---@return boolean is_transparent
    function ash_entity.isTransparent( entity )
        return transparent_modes[ Entity_GetRenderMode( entity ) ]
    end

end

do

    local utils_isRagdollClass = ash_entity.isRagdollClass
    local utils_isButtonClass = ash_entity.isButtonClass
    local utils_isPropClass = ash_entity.isPropClass
    local utils_isDoorClass = ash_entity.isDoorClass

    local Entity_GetModel = Entity.GetModel

    ---@type Entity[]
    local queue = {
        [ 0 ] = 0
    }

    hook.Add( "OnEntityCreated", "Handler", function( entity )
        if hook_Run( "ash.entity.AllowCreation", entity ) == false then
            if entity ~= nil and entity:IsValid() then
                entity:Remove()
            end

            return false
        end

        local queue_size = queue[ 0 ] + 1
        queue[ queue_size ] = entity
        queue[ 0 ] = queue_size
    end, PRE_HOOK )

    hook.Add( "Think", "Processor", function()
        for i = queue[ 0 ], 1, -1 do
            ---@type Entity
            ---@diagnostic disable-next-line: assign-type-mismatch
            local entity = queue[ i ]
            queue[ i ] = nil

            if entity ~= nil and Entity_IsValid( entity ) then
                local class_name = Entity_GetClass( entity )
                hook_Run( "ash.entity.Created", entity, class_name )

                if class_name == "player" then
                    hook_Run( "ash.entity.PlayerCreated", entity )
                -- elseif class_name == "world" then
                --     hook_Run( "ash.level.Created", entity )
                elseif utils_isPropClass( class_name ) then
                    Entity_SetNW2Var( entity, "m_bProp", true )
                    hook_Run( "ash.entity.PropCreated", entity, class_name, Entity_GetModel( entity ) )
                elseif utils_isDoorClass( class_name ) then
                    Entity_SetNW2Var( entity, "m_bDoor", true )
                    hook_Run( "ash.entity.DoorCreated", entity, class_name )
                elseif utils_isButtonClass( class_name ) then
                    Entity_SetNW2Var( entity, "m_bButton", true )
                    hook_Run( "ash.entity.ButtonCreated", entity, class_name )
                elseif utils_isRagdollClass( class_name ) then
                    Entity_SetNW2Var( entity, "m_bRagdoll", true )
                    hook_Run( "ash.entity.RagdollCreated", entity, class_name )
                elseif entity:IsWeapon() then
                    hook_Run( "ash.entity.WeaponCreated", entity, class_name )
                end
            end
        end

        queue[ 0 ] = 0
    end, PRE_HOOK )

    hook.Add( "EntityRemoved", "Handler", function( entity, is_full_update )
        local class_name = Entity_GetClass( entity )

        if class_name == "player" then
            hook_Run( "ash.entity.PlayerRemoved", entity, class_name, is_full_update )
        elseif utils_isPropClass( class_name ) then
            hook_Run( "ash.entity.PropRemoved", entity, class_name, is_full_update )
        elseif utils_isDoorClass( class_name ) then
            hook_Run( "ash.entity.DoorRemoved", entity, class_name, is_full_update )
        elseif utils_isButtonClass( class_name ) then
            hook_Run( "ash.entity.ButtonRemoved", entity, class_name, is_full_update )
        elseif utils_isRagdollClass( class_name ) then
            hook_Run( "ash.entity.RagdollRemoved", entity, class_name, is_full_update )
        elseif entity:IsWeapon() then
            hook_Run( "ash.entity.WeaponRemoved", entity, class_name, is_full_update )
        end

        hook_Run( "ash.entity.Removed", entity, class_name, is_full_update )
    end, PRE_HOOK )

end

do

	local sv_cheats, host_timescale = Variable.get( "sv_cheats", "boolean" ), Variable.get( "host_timescale", "float" )
	local engine_GetDemoPlaybackTimeScale = engine.GetDemoPlaybackTimeScale
	local game_GetTimeScale = game.GetTimeScale
	local math_clamp = math.clamp

    hook.Add( "EntityEmitSound", "SoundHandler", function( arguments, data )
        local result = arguments[ 2 ]
        if result ~= nil then
            return result
        end

		local time_scale = game_GetTimeScale()

        if sv_cheats ~= nil and sv_cheats.value and host_timescale ~= nil then
            time_scale = time_scale * host_timescale.value
        end

        if CLIENT then
            time_scale = time_scale * engine_GetDemoPlaybackTimeScale()
		end

        local start_pitch = data.Pitch

        data.Pitch = math_clamp( start_pitch * time_scale, 0, 255 )

		local entity = data.Entity
		if entity ~= nil and entity:IsValid() then
			if entity:IsPlayer() then
                result = hook_Run( "ash.player.EmitsSound", entity, data )
				if result ~= nil then return result end
			else
				result = hook_Run( "ash.entity.EmitsSound", entity, data )
				if result ~= nil then return result end
			end
		elseif entity:IsWorld() then
			result = hook_Run( "ash.level.EmitsSound", entity, data )
			if result ~= nil then return result end
		end

		if data.Pitch ~= start_pitch then
			return true
		end
	end, POST_HOOK_RETURN )

end

local type_to_flag = {
    pistol = 4,
    revolver = 6,
    smg = 2,
    ar2 = 0,
    shotgun	= 1,
    rpg = 7
}

---@param arguments table
---@param entity Entity
---@param bullet Bullet
hook.Add( "EntityFireBullets", "BulletCallback", function( arguments, entity, bullet )
    if arguments[ 2 ] == false then return false end

    local callback = bullet.Callback

    if bullet.TracerName == nil then
        bullet.TracerName = "none"
    end

    local inflictor = bullet.Inflictor

    if inflictor ~= nil and inflictor:IsValid() and inflictor:IsWeapon() then
        ---@cast inflictor Weapon

        local flag = type_to_flag[ inflictor:GetHoldType() ]
        bullet.Tracer = 0

        local ef = EffectData()

        if entity:IsPlayer() then
            ---@cast entity Player
            ef:SetEntity( entity:GetViewModel( 0 ) )
            flag = bit.bor( 256, flag )
        else
            ef:SetEntity( inflictor )
        end

        ef:SetFlags( flag )
        ef:SetAttachment( inflictor:LookupAttachment( "muzzle" ) or 1 )

        util.Effect( "MuzzleFlash", ef )
    end

    bullet.Callback = function( attacker, trace_result, damage_info )
        local do_effects, do_damage = hook_Run( "ash.entity.BulletImpact", bullet, attacker, trace_result, damage_info )
        local result = { do_effects == true, do_damage == true }

        if callback ~= nil then
            do_effects, do_damage = callback( attacker, trace_result, damage_info )

            if do_effects ~= nil then
                result[ 1 ] = do_effects == true
            end

            if do_damage ~= nil then
                result[ 2 ] = do_damage == true
            end
        end

        return result
    end

    return true
end, POST_HOOK_RETURN )

do

    local Vector_DistToSqr = Vector.DistToSqr
    local Entity_GetPos = Entity.GetPos

    --- [SHARED]
    ---
    --- Selects the closest entity to the origin and returns it.
    ---
    ---@param entities Entity[]
    ---@param origin Vector
    ---@param position_fn? fun( entity: Entity ): Vector
    ---@return Entity entity
    function ash_entity.closest( entities, origin, position_fn )
        if position_fn == nil then
            position_fn = Entity_GetPos
        end

        local min_distance = math_huge
        local selected_entity = NULL

        for i = 1, #entities, 1 do
            local entity = entities[ i ]

            local distance = Vector_DistToSqr( position_fn( entity ), origin )
            if distance < min_distance then
                selected_entity = entity
                min_distance = distance
            end
        end

        return selected_entity
    end

end

do

    local Entity_GetPhysicsObjectCount = Entity.GetPhysicsObjectCount
    local Entity_GetPhysicsObjectNum = Entity.GetPhysicsObjectNum
    local Physics_GetMass = Physics.GetMass

    --- [SHARED]
    ---
    --- Returns the mass of the entity in kilograms ( not sure ).
    ---
    ---@param entity Entity
    ---@return number mass
    function ash_entity.getMass( entity )
        local mass = 0

        for i = 0, Entity_GetPhysicsObjectCount( entity ) - 1, 1 do
            mass = mass + Physics_GetMass( Entity_GetPhysicsObjectNum( entity, i ) )
        end

        return mass
    end

end

do

    local Entity_WaterLevel = Entity.WaterLevel

    ---@alias ash.entity.WaterLevel `0` | `1` | `2` | `3`

    ---@type table<Entity, ash.entity.WaterLevel>
    local water_levels = {}

    setmetatable( water_levels, {
        __index = function( _, entity )
            local water_level = Entity_WaterLevel( entity ) or 0
            water_levels[ entity ] = water_level
            return water_level
        end,
        __mode = "k"
    } )

    --- [SHARED]
    ---
    --- Returns the water level of the entity.
    ---
    --- - 0 - The entity isn't in water.
    --- - 1 - Slightly submerged (at least to the feet).
    --- - 2 - The majority of the entity is submerged (at least to the waist).
    --- - 3 - Completely submerged.
    ---
    ---@param entity Entity
    ---@return ash.entity.WaterLevel water_level
    function ash_entity.getWaterLevel( entity )
        return water_levels[ entity ]
    end

    if SERVER then
        hook.Add( "OnEntityWaterLevelChanged", "WaterLevel", function( entity, old, new )
            water_levels[ entity ] = new
            hook_Run( "ash.entity.WaterLevel", entity, old, new )
        end, PRE_HOOK )
    else
        hook.Add( "ash.entity.Think", "WaterLevel", function( entity )
            local water_level = Entity_WaterLevel( entity ) or 0
            if water_levels[ entity ] ~= water_level then
                hook_Run( "ash.entity.WaterLevel", entity, water_levels[ entity ], water_level )
                water_levels[ entity ] = water_level
            end
        end, PRE_HOOK )
    end

end

do

    local ents_Iterator = ents.Iterator

    hook.Add( "Tick", "Think", function()
        for _, entity in ents_Iterator() do
            hook_Run( "ash.entity.Think", entity )
        end
    end, PRE_HOOK )

end

--- [SHARED]
---
--- Calls use event for entity.
---
---@param entity Entity
---@param activator Entity
---@param controller? Entity
---@param use_type? USE
---@param value? any
function ash_entity.use( entity, activator, controller, use_type, value )
    if hook_Run( "ash.entity.UsageAllowed", entity, activator, controller, use_type, value ) ~= false then
        local fn = entity.Use
        if fn ~= nil then
            fn( entity, activator, controller, use_type, value )
        end
    end
end

hook.Add( "EntityNetworkedVarChanged", "NW2Handler", function( entity, key, old_value, value )
    if old_value == value then return end
    hook_Run( "ash.entity.NW2Changed", entity, key, old_value, value )
end, PRE_HOOK )

do

    local Entity_GetPoseParameterRange = Entity.GetPoseParameterRange
    local Entity_LookupPoseParameter = Entity.LookupPoseParameter
    local Entity_ClearPoseParameters = Entity.ClearPoseParameters

    local Entity_GetPoseParameter = Entity.GetPoseParameter
    local Entity_SetPoseParameter = Entity.SetPoseParameter

    local math_remap = math.remap
    local net = net

    ash_entity.getPoseParameterCount = Entity.GetNumPoseParameters
    ash_entity.getPoseParameterIndex = Entity_LookupPoseParameter
    ash_entity.getPoseParameterName = Entity.GetPoseParameterName
    ash_entity.getPoseParameterRange = Entity.GetPoseParameterRange

    if SERVER then

        --- [SHARED]
        ---
        --- Returns the value of a pose parameter.
        ---
        ---@param entity Entity
        ---@param index integer
        ---@return number value
        function ash_entity.getPoseParameterFloat( entity, index )
            local min, max = Entity_GetPoseParameterRange( entity, index )
            return math_remap( Entity_GetPoseParameter( entity, index ), min, max, 0, 1 )
        end

        ash_entity.getPoseParameter = Entity_GetPoseParameter

    else

        ash_entity.getPoseParameterFloat = Entity_GetPoseParameter

        --- [SHARED]
        ---
        --- Returns the value of a pose parameter.
        ---
        ---@param entity Entity
        ---@param index integer
        ---@return number value
        function ash_entity.getPoseParameter( entity, index )
            return math_remap( Entity_GetPoseParameter( entity, index ), 0, 1, Entity_GetPoseParameterRange( entity, index ) )
        end

    end

    ---@class ash.entity.PoseParameter
    ---@field index integer
    ---@field value number

    ---@type table<Player, ash.entity.PoseParameter[]>
    local player_pose_parameters = {}

    setmetatable( player_pose_parameters, {
        __index = function( self, pl )
            local parameters = { [ 0 ] = 0 }
            self[ pl ] = parameters
            return parameters
        end,
        __mode = "k"
    } )

    if SERVER then

        --- [SERVER]
        ---
        --- Resets a entity's pose parameters.
        ---
        ---@param entity Entity
        ---@param networked boolean
        function ash_entity.resetPoseParameters( entity, networked )
            if networked ~= false then
                net.Start( "network" )
                net.WriteUInt( 1, 8 )
                net.WriteEntity( entity )
                net.Broadcast()
            end

            if entity:IsPlayer() then
                ---@cast entity Player
                player_pose_parameters[ entity ] = nil
            end

            Entity_ClearPoseParameters( entity )
        end

        --- [SERVER]
        ---
        --- Sets a entity's pose parameter.
        ---
        ---@param entity Entity
        ---@param name string | integer
        ---@param value number
        ---@param networked boolean
        function ash_entity.setPoseParameter( entity, name, value, networked )
            ---@type integer
            local index

            if isnumber( name ) then
                ---@cast name integer
                index = name
            else
                ---@cast name string
                index = Entity_LookupPoseParameter( entity, name )
            end

            if index == nil or index < 0 then return end

            if networked ~= false then
                net.Start( "network" )
                net.WriteUInt( 2, 8 )
                net.WriteEntity( entity )
                net.WriteUInt( index, 16 )
                net.WriteDouble( value )
                net.Broadcast()
            end

            if entity:IsPlayer() then
                ---@cast entity Player

                local parameters = player_pose_parameters[ entity ]
                local count = parameters[ 0 ]

                local found = false

                for i = 1, count, 1 do
                    local parameter = parameters[ i ]
                    if parameter ~= nil and parameter.index == index then
                        parameter.value = value
                        found = true
                        break
                    end
                end

                if not found then
                    count = count + 1

                    parameters[ count ] = {
                        index = index,
                        value = value
                    }

                    parameters[ 0 ] = count
                end
            end

            Entity_SetPoseParameter( entity, index, value )
        end

    else

        --- [CLIENT]
        ---
        --- Resets a entity's pose parameters.
        ---
        ---@param entity Entity
        function ash_entity.resetPoseParameters( entity )
            if entity:IsPlayer() then
                ---@cast entity Player
                player_pose_parameters[ entity ] = nil
            end

            Entity_ClearPoseParameters( entity )
        end

        --- [CLIENT]
        ---
        --- Sets a entity's pose parameter.
        ---
        ---@param entity Entity
        ---@param name string | integer
        ---@param value number
        function ash_entity.setPoseParameter( entity, name, value )
            ---@type integer
            local index

            if isnumber( name ) then
                ---@cast name integer
                index = name
            else
                ---@cast name string
                index = Entity_LookupPoseParameter( entity, name )
            end

            if index == nil or index < 0 then return end

            if entity:IsPlayer() then
                ---@cast entity Player

                local parameters = player_pose_parameters[ entity ]
                local count = parameters[ 0 ]

                local found = false

                for i = 1, count, 1 do
                    local parameter = parameters[ i ]
                    if parameter ~= nil and parameter.index == index then
                        parameter.value = value
                        found = true
                        break
                    end
                end

                if not found then
                    count = count + 1

                    parameters[ count ] = {
                        index = index,
                        value = value
                    }

                    parameters[ 0 ] = count
                end
            end

            Entity_SetPoseParameter( entity, index, value )
        end

    end

    hook.Add( "UpdateAnimation", "PoseParameters", function( pl )
        local parameters = player_pose_parameters[ pl ]

        for i = 1, parameters[ 0 ], 1 do
            local parameter = parameters[ i ]
            Entity_SetPoseParameter( pl, parameter.index, parameter.value )
        end
    end, PRE_HOOK )

end

return ash_entity
