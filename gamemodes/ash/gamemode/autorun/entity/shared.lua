---@type dreamwork.std
local std = _G.dreamwork.std

local math = std.math
local math_huge = math.huge

local Entity_GetNW2Var = Entity.GetNW2Var
local Entity_SetNW2Var = Entity.SetNW2Var
local Entity_IsValid = Entity.IsValid

local Variable = std.console.Variable
local hook_Run = hook.Run

local NULL = NULL

---@class ash.entity
local ash_entity = {}

do

    local entity_Create = SERVER and ents.Create or ents.CreateClientside
    local entity_Register = scripted_ents.Register
    local Entity_DrawModel = Entity.DrawModel
    local getfenv = getfenv

    ---@class ash.entity.Structure : ENT
    ---@field ClassName string The class name of the entity to register.
    ---@field Type "anim" | "brush" | "point" | "ai" | "nextbot" | "filter" | nil The type of the entity. Defaults to `"anim"`.
    ---@field PrintName string | nil The name of the entity. Defaults use the class name.
    ---@field Spawnable boolean | nil Whether the entity can be spawned by players. Defaults to `false`.
    ---@field Editable boolean | nil Whether the entity can be edited by players. Defaults to `false`.
    ---@field Category string | nil The name of the entity category. Defaults to `nil`.
    ---@field RenderGroup RENDERGROUP | integer | nil The render group of the entity. Defaults to `RENDERGROUP_TRANSLUCENT`.
    ---@field WantsTranslucency boolean | nil Whether the entity wants translucency. Defaults to `true`.
    ---@field DisableDuplicator boolean | nil Whether the entity should be disabled in the duplicator. Defaults to `false`.
    ---@field IconOverride string | nil The icon of the entity. Defaults to `nil`.
    ---@field PhysicsSolidMask CONTENTS | integer | nil The physics solid mask of the entity. Defaults to `nil`.
    ---@field OnCreate nil | fun( self: Entity, ... ) The function to call when the entity is created. Defaults to `nil`.

    --- [SHARED]
    ---
    --- Register an entity and return a creation function to create it.
    ---
    ---@generic T : ash.entity.Structure
    ---@param entity_structure T The entity structure to register.
    ---@param ignore_environment? boolean If `true` entity will be registered without a module prefix.
    ---@return fun( ... ): T | nil entity The entity creation function.
    function ash_entity.register( entity_structure, ignore_environment )
        ---@diagnostic disable-next-line: undefined-field
        local class_name = entity_structure.ClassName
        if class_name == nil then
            error( "failed to register entity, 'ClassName' field cannot be nil", 2 )
        end

        if entity_structure.Type == nil then
            ---@diagnostic disable-next-line: inject-field
            entity_structure.Type = "anim"
        end

        if entity_structure.Draw == nil then
            entity_structure.Draw = Entity_DrawModel
        end

        if entity_structure.DrawTranslucent == nil then
            entity_structure.DrawTranslucent = Entity_DrawModel
        end

        if not ignore_environment then
            local environment = getfenv( 3 )
            if environment ~= nil then
                ---@type ash.Module
                local module = environment.MODULE
                if module ~= nil then
                    class_name = module.Prefix .. class_name
                end
            end
        end

        entity_structure.Spawnable = entity_structure.Spawnable == true
        entity_structure.Editable = entity_structure.Editable == true

        entity_structure.WantsTranslucency = entity_structure.WantsTranslucency ~= false
        entity_structure.DisableDuplicator = entity_structure.DisableDuplicator == true

        if entity_structure.RenderGroup == nil then
            entity_structure.RenderGroup = 8
        end

        entity_Register( entity_structure, class_name )

        local on_create = entity_structure.OnCreate
        if not isfunction( on_create ) then
            on_create = nil
        end

        return function( ... )
            local entity = entity_Create( class_name )

            if entity ~= nil and entity ~= NULL and Entity_IsValid( entity ) then
                if on_create ~= nil then
                    on_create( entity, ... )
                end

                return entity
            end

            return nil
        end
    end

end

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

    local math_floor = math.floor

    local default_color = Vector( 0.33, 0.33, 0.33 )

    --- [SHARED]
    ---
    --- Get player color.
    ---
    ---@param entity Entity
    ---@return Vector color_vec3
    function Entity.GetPlayerColor( entity )
        return Entity_GetNW2Var( entity, "m_vPlayerColor", default_color )
    end

    Player.GetPlayerColor = Entity.GetPlayerColor

    --- [SHARED]
    ---
    --- Get player color.
    ---
    ---@param entity Entity
    ---@return Color color
    function ash_entity.getPlayerColor( entity )
        local vector = Entity_GetNW2Var( entity, "m_vPlayerColor", default_color )
        return Color( math_floor( vector[ 1 ] * 255 ), math_floor( vector[ 2 ] * 255 ), math_floor( vector[ 3 ] * 255 ), 255 )
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

    local Entity_GetModel = Entity.GetModel

    ---@type Entity[]
    local queue = {}

    ---@type integer
    local queue_size = 0

    hook.Add( "OnEntityCreated", "Handler", function( entity )
        if hook_Run( "AllowEntityCreation", entity ) == false then
            if entity ~= nil and entity:IsValid() then
                entity:Remove()
            end

            return false
        end

        queue_size = queue_size + 1
        queue[ queue_size ] = entity
    end, PRE_HOOK )

    hook.Add( "Think", "Processor", function()
        for i = queue_size, 1, -1 do
            local entity = queue[ i ]

            queue_size = queue_size - 1
            queue[ i ] = nil

            if Entity_IsValid( entity ) then
                local class_name = Entity_GetClass( entity )
                hook_Run( "EntityCreated", entity, class_name )

                if class_name == "player" then
                    hook_Run( "PlayerEntityCreated", entity )
                -- elseif class_name == "world" then
                --     hook_Run( "WorldEntityCreated", entity )
                elseif utils_isPropClass( class_name ) then
                    Entity_SetNW2Var( entity, "m_bProp", true )
                    hook_Run( "PropEntityCreated", entity, class_name, Entity_GetModel( entity ) )
                elseif utils_isDoorClass( class_name ) then
                    Entity_SetNW2Var( entity, "m_bDoor", true )
                    hook_Run( "DoorEntityCreated", entity, class_name )
                elseif utils_isButtonClass( class_name ) then
                    Entity_SetNW2Var( entity, "m_bButton", true )
                    hook_Run( "ButtonEntityCreated", entity, class_name )
                elseif utils_isRagdollClass( class_name ) then
                    Entity_SetNW2Var( entity, "m_bRagdoll", true )
                    hook_Run( "RagdollEntityCreated", entity, class_name )
                elseif entity:IsWeapon() then
                    hook_Run( "WeaponEntityCreated", entity, class_name )
                end
            end
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
        else
            hook_Run( "EntityClassRemoved", entity, class_name, is_full_update )
        end
    end, PRE_HOOK )

end

do

	local sv_cheats, host_timescale = Variable.get( "sv_cheats", "boolean" ), Variable.get( "host_timescale", "float" )
	local engine_GetDemoPlaybackTimeScale = engine.GetDemoPlaybackTimeScale
	local game_GetTimeScale = game.GetTimeScale
	local math_clamp = math.clamp

    hook.Add( "EntityEmitSound", "Handler", function( arguments, data )
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
                result = hook_Run( "PlayerEmitsSound", entity, data )
				if result ~= nil then return result end
			else
				result = hook_Run( "EntityEmitsSound", entity, data )
				if result ~= nil then return result end
			end
		elseif entity:IsWorld() then
			result = hook_Run( "WorldEmitsSound", entity, data )
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
    if arguments[ 2 ] == false then return false end

    local callback = bullet.Callback

    bullet.Callback = function( attacker, trace_result, damage_info )
        local do_effects, do_damage = hook.Run( "EntityFireBulletsImpact", bullet, attacker, trace_result, damage_info )
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
            hook_Run( "EntityWaterLevelChanged", entity, old, new )
        end, PRE_HOOK )
    else
        hook.Add( "EntityThink", "WaterLevel", function( entity )
            local water_level = Entity_WaterLevel( entity ) or 0
            if water_levels[ entity ] ~= water_level then
                hook_Run( "EntityWaterLevelChanged", entity, water_levels[ entity ], water_level )
                water_levels[ entity ] = water_level
            end
        end, PRE_HOOK )
    end

end

do

    local ents_Iterator = ents.Iterator

    hook.Add( "Tick", "Think", function()
        for _, entity in ents_Iterator() do
            hook_Run( "EntityThink", entity )
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
    if hook_Run( "ShouldUseEntity", entity, activator, controller, use_type, value ) ~= false then
        local fn = entity.Use
        if fn ~= nil then
            fn( entity, activator, controller, use_type, value )
        end
    end
end

do

    local Entity_GetPoseParameter = Entity.GetPoseParameter
    local Entity_GetPoseParameterRange = Entity.GetPoseParameterRange

    local math_remap = math.remap

    ash_entity.getPoseParamaterCount = Entity.GetNumPoseParameters

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

    ash_entity.setPoseParameter = Entity.SetPoseParameter
    ash_entity.resetPoseParameters = Entity.ClearPoseParameters
    ash_entity.lookupPoseParameter = Entity.LookupPoseParameter
    ash_entity.getPoseParamaterFloat = Entity_GetPoseParameter
    ash_entity.getPosteParameterName = Entity.GetPoseParameterName
    ash_entity.getPoseParamaterRange = Entity.GetPoseParameterRange

end

return ash_entity
