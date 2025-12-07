---@type dreamwork.std
local std = _G.dreamwork.std

local math = std.math
local math_huge = math.huge

local Variable = std.console.Variable
local hook_Run = hook.Run

local NULL = NULL

---@class ash.entity
local ash_entity = {}

ash_entity.isPlayer = Entity.IsPlayer

---@type ash.utils
local utils = require( "ash.utils" )

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

    local Entity_GetNW2Vector = Entity.GetNW2Vector
    local math_floor = math.floor

    local default_color = Vector( 0.33, 0.33, 0.33 )

    --- [SHARED]
    ---
    --- Get player color.
    ---
    ---@param entity Entity
    ---@return Vector color_vec3
    function Entity.GetPlayerColor( entity )
        return Entity_GetNW2Vector( entity, "m_vPlayerColor", default_color )
    end

    --- [SHARED]
    ---
    --- Get player color.
    ---
    ---@param entity Entity
    ---@return Color color
    function ash_entity.getPlayerColor( entity )
        local vector = Entity_GetNW2Vector( entity, "m_vPlayerColor", default_color )
        return Color( math_floor( vector[ 1 ] * 255 ), math_floor( vector[ 2 ] * 255 ), math_floor( vector[ 3 ] * 255 ), 255 )
    end

end

do

    local Entity_GetNW2Bool = Entity.GetNW2Bool

    --- [SHARED]
    ---
    --- Check if entity is button.
    ---
    ---@param entity Entity
    ---@return boolean is_button
    function ash_entity.isButton( entity )
        return Entity_GetNW2Bool( entity, "m_bButton", false )
    end

end

local Entity_GetClass = Entity.GetClass

ash_entity.getSolidType = Entity.GetSolid
ash_entity.getClassName = Entity_GetClass

ash_entity.getEngineValue = Entity.GetInternalVariable
ash_entity.setEngineValue = Entity.SetKeyValue

do

    local utils_isRagdollClass = utils.isRagdollClass

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

    local utils_isRagdollClass = utils.isRagdollClass

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

    local utils_isRagdollClass = utils.isRagdollClass
    local utils_isButtonClass = utils.isButtonClass
    local utils_isPropClass = utils.isPropClass
    local utils_isDoorClass = utils.isDoorClass

    local Entity_SetNW2Bool = Entity.SetNW2Bool
    local Entity_GetModel = Entity.GetModel

    hook.Add( "OnEntityCreated", "Handler", function( entity )
        local class_name = Entity_GetClass( entity )

        if hook_Run( "AllowEntityCreation", entity, class_name ) == false then
            if entity ~= nil and entity:IsValid() then
                entity:Remove()
            end

            return false
        end

        hook_Run( "EntityCreated", entity, class_name )

        if class_name == "player" then
            hook_Run( "PlayerEntityCreated", entity )
        elseif class_name == "world" then
            hook_Run( "WorldEntityCreated", entity )
        elseif utils_isPropClass( class_name ) then
            Entity_SetNW2Bool( entity, "m_bProp", true )
            hook_Run( "PropEntityCreated", entity, class_name, Entity_GetModel( entity ) )
        elseif utils_isDoorClass( class_name ) then
            Entity_SetNW2Bool( entity, "m_bDoor", true )
            hook_Run( "DoorEntityCreated", entity, class_name )
        elseif utils_isButtonClass( class_name ) then
            Entity_SetNW2Bool( entity, "m_bButton", true )
            hook_Run( "ButtonEntityCreated", entity, class_name )
        elseif utils_isRagdollClass( class_name ) then
            Entity_SetNW2Bool( entity, "m_bRagdoll", true )
            hook_Run( "RagdollEntityCreated", entity, class_name )
        elseif entity:IsWeapon() then
            hook_Run( "WeaponEntityCreated", entity, class_name )
        end
    end, PRE_HOOK )

    hook.Add( "EntityRemoved", "Handler", function( entity, is_full_update )
        local class_name = Entity_GetClass( entity )
        if class_name == "player" then
            hook_Run( "PlayerEntityRemoved", entity, class_name, is_full_update )
        elseif utils_isPropClass( class_name ) then
            hook_Run( "PropEntityRemoved", entity, class_name, is_full_update )
        elseif utils_isDoorClass( class_name ) then
            hook_Run( "DoorEntityRemoved", entity, class_name, is_full_update )
        elseif utils_isButtonClass( class_name ) then
            hook_Run( "ButtonEntityRemoved", entity, class_name, is_full_update )
        elseif utils_isRagdollClass( class_name ) then
            hook_Run( "RagdollEntityRemoved", entity, class_name, is_full_update )
        elseif entity:IsWeapon() then
            hook_Run( "WeaponEntityRemoved", entity, class_name, is_full_update )
        end
    end, PRE_HOOK )

end

do

	local sv_cheats, host_timescale = Variable.get( "sv_cheats", "boolean" ), Variable.get( "host_timescale", "float" )
	local engine_GetDemoPlaybackTimeScale = engine.GetDemoPlaybackTimeScale
	local game_GetTimeScale = game.GetTimeScale
	local math_clamp = math.clamp

    hook.Add( "EntityEmitSound", "Handler", function( arguments, data )
        local result = arguments[ 1 ]
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
				result = hook_Run( "PlayerEmitSound", entity, data )
				if result ~= nil then return result end
			else
				result = hook_Run( "ValidEntityEmitSound", entity, data )
				if result ~= nil then return result end
			end
		elseif entity:IsWorld() then
			result = hook_Run( "WorldEmitSound", entity, data )
			if result ~= nil then return result end
		end

		if data.Pitch ~= start_pitch then
			return true
		end
	end, POST_HOOK_RETURN )

end

---@param arguments table
---@param entity Entity
---@param bullet Bullet
hook.Add( "EntityFireBullets", "BulletCallback", function( arguments, entity, bullet )
    if arguments[ 1 ] == false then return false end

    local callback = bullet.Callback

    bullet.Callback = function( attacker, trace_result, damage_info )
        local do_effects, do_damage = hook.Run( "EntityFireBulletsImpact", attacker, trace_result, damage_info )
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

return ash_entity
