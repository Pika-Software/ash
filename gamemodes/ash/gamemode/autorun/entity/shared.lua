---@type dreamwork.std
local std = dreamwork.std

local math = std.math
local math_sqrt = math.sqrt
local math_huge = math.huge

local Entity_GetNW2Var = Entity.GetNW2Var
local Entity_SetNW2Var = Entity.SetNW2Var
local Entity_IsValid = Entity.IsValid

local Variable = std.console.Variable
local hook_Run = hook.Run
local isnumber = isnumber
local SERVER = SERVER

---@class ash.entity
---@field count integer
local ash_entity = {}

do

    local Player_GetRenderAngles = Player.GetRenderAngles
    local debug_getmetatable = debug.getmetatable
    local Entity_GetAngles = Entity.GetAngles

    ---@class Player
    local PLAYER = debug.findmetatable( "Player" )

    --- [SHARED]
    ---
    --- Checks if an entity is a player.
    ---
    ---@param entity Entity | any
    ---@return boolean is_player
    local function entity_isPlayer( entity )
        return debug_getmetatable( entity ) == PLAYER
    end

    ash_entity.isPlayer = entity_isPlayer

    --- [SHARED]
    ---
    --- Returns the angles of an entity.
    ---
    ---@param entity Entity
    ---@return Angle
    function ash_entity.getAngles( entity )
        if entity_isPlayer( entity ) then
            return Player_GetRenderAngles( entity )
        else
            return Entity_GetAngles( entity )
        end
    end

end

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
        return Entity_GetHitBoxCount( entity, (hitbox_group or 0) - 1 )
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

    local Entity_SelectWeightedSequenceSeeded = Entity.SelectWeightedSequenceSeeded
    local Entity_SelectWeightedSequence = Entity.SelectWeightedSequence

    --- [SHARED]
    ---
    --- Get sequence by activity.
    ---
    ---@param entity Entity
    ---@param activity integer
    ---@param seed integer
    ---@return integer | nil
    function ash_entity.getSequenceByActivity( entity, activity, seed )
        if seed == nil then
            return Entity_SelectWeightedSequence( entity, activity )
        else
            return Entity_SelectWeightedSequenceSeeded( entity, activity, seed )
        end
    end

    --- [SHARED]
    ---
    --- Check if activity exists.
    ---
    ---@param entity Entity
    ---@param activity integer
    ---@return boolean is_exists
    function ash_entity.isActivityExists( entity, activity )
        local sequence_id = Entity_SelectWeightedSequence( entity, activity )
        return sequence_id ~= nil and sequence_id > 0
    end

end

ash_entity.getActivityNameBySequence = Entity.GetSequenceActivityName
ash_entity.getActivityBySequence = Entity.GetSequenceActivity

do

    local Entity_LookupSequence = Entity.LookupSequence

    ash_entity.getSequenceByName = Entity_LookupSequence

    --- [SHARED]
    ---
    --- Check if sequence exists.
    ---
    ---@param entity Entity
    ---@param sequence_name string
    function ash_entity.isSequenceExists( entity, sequence_name )
        local sequence_id = Entity_LookupSequence( entity, sequence_name )
        return sequence_id ~= nil and sequence_id > 0
    end

end

ash_entity.getSequences = Entity.GetSequenceList

ash_entity.getSequence = Entity.GetSequence
ash_entity.setSequence = Entity.SetSequence

ash_entity.getSequenceProgress = Entity.GetCycle
ash_entity.setSequenceProgress = Entity.SetCycle

ash_entity.getSequenceRate = Entity.GetPlaybackRate
ash_entity.setSequenceRate = Entity.SetPlaybackRate

ash_entity.getSequenceInfo = Entity.GetSequenceInfo

ash_entity.startSequence = Entity.ResetSequence
ash_entity.resetSequence = Entity.ResetSequenceInfo

ash_entity.getSequenceName = Entity.GetSequenceName
ash_entity.getSequenceCount = Entity.GetSequenceCount
ash_entity.getSequenceDuration = Entity.SequenceDuration

ash_entity.getSequenceVelocity = Entity.GetSequenceVelocity
ash_entity.getSequenceGroundSpeed = Entity.GetSequenceGroundSpeed

ash_entity.getSequenceMovement = Entity.GetSequenceMovement
ash_entity.getSequenceMovementYaw = Entity.GetSequenceMoveYaw
ash_entity.getSequenceMovementDistance = Entity.GetSequenceMoveDist

ash_entity.getLayerSequence = Entity.GetLayerSequence
ash_entity.setLayerSequence = Entity.SetLayerSequence

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

    ---@type table<Entity, Vector>
    local player_colors = {}

    setmetatable( player_colors, {
        __index = function( self, entity )
            local color_vec3 = default_player_color

            if Entity_IsValid( entity ) and entity:EntIndex() > 0 then
                color_vec3 = Entity_GetNW2Var( entity, "m_vPlayerColor", default_player_color )
            end

            self[ entity ] = color_vec3
            return color_vec3
        end,
        __mode = "k"
    } )

    hook.Add( "ash.entity.NW2Changed", "PlayerColor", function( entity, key, _, value )
        if key == "m_vPlayerColor" then
            player_colors[ entity ] = value
        end
    end, PRE_HOOK )

    --- [SHARED]
    ---
    --- Get player color.
    ---
    ---@param entity Entity
    ---@return Vector color_vec3
    function Entity.GetPlayerColor( entity )
        return player_colors[ entity ]
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
                return Material_SetVector( material, self.ResultTo, player_colors[ entity ] )
            end
        } )

        matproxy.Add( {
            name = "PlayerWeaponColor",
            init = function( self, _, values )
                self.ResultTo = values.resultvar
            end,
            bind = function( self, material, entity )
                return Material_SetVector( material, self.ResultTo, player_colors[ entity ] )
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
            local vector = player_colors[ entity ]
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
        [ RENDERMODE_TRANSADDFRAMEBLEND ] = true,
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

    local table_removeByValue = table.removeByValue

    local Entity_GetModel = Entity.GetModel

    local entity_list, entity_count = dreamwork.engine.entity.getAll()
    ash_entity.count = entity_count

    dreamwork.engine.hook.catch( "dreamwork.entity.registry", "ash.entity", function( new_entities, new_count )
        entity_list, entity_count = new_entities, new_count
        ash_entity.count = entity_count
    end )

    ---@type table<string, Entity[]>
    local entity_classes = {}

    setmetatable( entity_classes, {
        __index = function( self, class_name )
            local class_entities = { [ 0 ] = 0 }
            self[ class_name ] = class_entities
            return class_entities
        end
    } )

    ---@type Entity[]
    local init_queue = { [ 0 ] = 0 }

    hook.Add( "PreCleanupMap", "InitQueue", function()
        init_queue = { [ 0 ] = 0 }
    end, PRE_HOOK )


    ---@param entity Entity
    ---@param class_name string
    local function perform_entity_creation( entity, class_name )
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

    hook.Add( "Tick", "InitQueue", function()
        for i = init_queue[ 0 ], 1, -1 do
            ---@type Entity
            ---@diagnostic disable-next-line: assign-type-mismatch
            local entity = init_queue[ i ]
            if entity ~= nil and Entity_IsValid( entity ) then
                local class_name

                if entity:IsPlayer() then
                    class_name = "player"
                else
                    class_name = Entity_GetClass( entity )
                end

                local success, err_msg = pcall( perform_entity_creation, entity, class_name )
                if not success then
                    ErrorNoHalt( err_msg .. "\n" )
                end
            end
        end

        init_queue = { [ 0 ] = 0 }
    end, PRE_HOOK )

    ---@type ash.entity.Filter[]
    local entity_filters = {}
    gc.setTableRules( entity_filters, false, true )

    ---@type integer
    local entity_filter_count = 0

    ---@param entity Entity
    ---@param is_player boolean
    dreamwork.engine.hook.catch( "dreamwork.entity.spawn", "ash.entity", function( entity, is_player )
        if hook_Run( "ash.entity.AllowCreation", entity ) == false then
            if entity ~= nil and entity:IsValid() then
                entity:Remove()
            end

            return
        end

        local entities = entity_classes[ Entity_GetClass( entity ) ]
        local count = entities[ 0 ] + 1

        entities[ count ] = entity
        entities[ 0 ] = count

        if SERVER then
            for i = 1, entity_filter_count, 1 do
                local filter = entity_filters[ i ]
                if filter ~= nil then
                    filter:created( entity )
                end
            end

            local queue_size = init_queue[ 0 ] + 1
            init_queue[ queue_size ] = entity
            init_queue[ 0 ] = queue_size
        end
    end )

    if CLIENT then

        hook.Add( "NetworkEntityCreated", "InitializeCapture", function( entity )
            for i = 1, entity_filter_count, 1 do
                local filter = entity_filters[ i ]
                if filter ~= nil then
                    filter:created( entity )
                end
            end

            local queue_size = init_queue[ 0 ] + 1
            init_queue[ queue_size ] = entity
            init_queue[ 0 ] = queue_size
        end )

    end

    ---@param entity Entity
    ---@param is_player boolean
    dreamwork.engine.hook.catch( "dreamwork.entity.destroy", "ash.entity", function( entity, is_player )
        local class_name = Entity_GetClass( entity )

        local entities = entity_classes[ class_name ]
        local count = entities[ 0 ]

        if table_removeByValue( entities, entity, count ) ~= nil then
            count = count - 1

            if count == 0 then
                entity_classes[ class_name ] = nil
            else
                entities[ 0 ] = count
            end
        end

        for i = 1, entity_filter_count, 1 do
            local filter = entity_filters[ i ]
            if filter ~= nil then
                filter:removed( entity )
            end
        end

        if is_player or entity:IsPlayer() then
            hook_Run( "ash.entity.PlayerRemoved", entity )
        elseif utils_isPropClass( class_name ) then
            hook_Run( "ash.entity.PropRemoved", entity, class_name )
        elseif utils_isDoorClass( class_name ) then
            hook_Run( "ash.entity.DoorRemoved", entity, class_name )
        elseif utils_isButtonClass( class_name ) then
            hook_Run( "ash.entity.ButtonRemoved", entity, class_name )
        elseif utils_isRagdollClass( class_name ) then
            hook_Run( "ash.entity.RagdollRemoved", entity, class_name )
        elseif entity:IsWeapon() then
            hook_Run( "ash.entity.WeaponRemoved", entity, class_name )
        end

        hook_Run( "ash.entity.Removed", entity, class_name )
    end )

    local raw_inext = raw.inext

    --- [SHARED]
    ---
    ---  Iterates over all entities.
    ---
    ---@return ( fun(table: Entity[], i: (integer | nil)): (integer, Entity) ), Entity[], integer
    function ash_entity.iterator()
        return raw_inext, entity_list, 0
    end

    --- [SHARED]
    ---
    --- Returns a list of all entities.
    ---
    ---@return Entity[], integer
    function ash_entity.getAll()
        local copy = {}

        for i = 1, entity_count, 1 do
            copy[ i ] = entity_list[ i ]
        end

        return copy, entity_count
    end

    --- [SHARED]
    ---
    --- Get entities by class.
    ---
    ---@param class_name string
    ---@return Entity[]
    ---@return integer
    function ash_entity.findByClass( class_name )
        local entities = entity_classes[ class_name ]
        if entities == nil then
            return {}, 0
        end

        local count = entities[ 0 ]
        local copy = {}

        for i = 1, count, 1 do
            copy[ i ] = entities[ i ]
        end

        return copy, count
    end

    ---@deprecated
    ash_entity.getByClass = ash_entity.findByClass

    do

        ---@alias ash.entity.FilterFunc fun( entity: Entity): boolean

        ---@type table<ash.entity.Filter, ash.entity.FilterFunc>
        local filter_functions = {}

        ---@type table<ash.entity.Filter, Entity[]>
        local filter_lists = {}

        ---@type table<ash.entity.Filter, integer>
        local filter_counts = {}

        ---@class ash.entity.Filter : dreamwork.std.Object
        ---@field fn ash.entity.FilterFunc
        ---@field list Entity[]
        ---@field count integer
        local Filter = class.base( "ash.entity.Filter", true )

        local raw_index = raw.index

        ---@protected
        function Filter:__index( key )
            if key == "fn" then
                return filter_functions[ self ]
            elseif key == "list" then
                return filter_lists[ self ]
            elseif key == "count" then
                return filter_counts[ self ]
            end

            return raw_index( Filter, key )
        end

        --- [SHARED]
        ---
        --- Inserts an entity into the filter if it passes the filter function.
        ---
        ---@param entity Entity
        ---@return boolean
        function Filter:created( entity )
            if filter_functions[ self ]( entity ) then
                local filter_count = filter_counts[ self ] + 1
                filter_lists[ self ][ filter_count ] = entity
                filter_counts[ self ] = filter_count
                return true
            end

            return false
        end

        --- [SHARED]
        ---
        --- Removes an entity from the filter.
        ---
        ---@param entity Entity
        ---@return boolean
        function Filter:removed( entity )
            if table_removeByValue( filter_lists[ self ], entity, filter_counts[ self ] ) ~= nil then
                filter_counts[ self ] = filter_counts[ self ] - 1
                return true
            end

            return false
        end

        --- [SHARED]
        ---
        --- Updates the filter, re-evaluating all entities.
        ---
        function Filter:update()
            filter_counts[ self ] = 0
            filter_lists[ self ] = {}

            for i = 1, entity_count, 1 do
                self:created( entity_list[ i ] )
            end
        end

        ---@param fn ash.entity.FilterFunc
        ---@protected
        function Filter:__init( fn )
            entity_filter_count = entity_filter_count + 1
            entity_filters[ entity_filter_count ] = self

            filter_functions[ self ] = fn
            filter_counts[ self ] = 0
            filter_lists[ self ] = {}
        end

        ---@protected
        function Filter:__gc()
            if table_removeByValue( entity_filters, self ) then
                entity_filter_count = entity_filter_count - 1
            end
        end

        ---@class ash.entity.FilterClass : ash.entity.Filter
        ---@overload fun(fn: ash.entity.FilterFunc): ash.entity.Filter
        local FilterClass = class.create( Filter )
        ash_entity.Filter = FilterClass

        --- [SHARED]
        ---
        --- Get filtered entities.
        ---
        ---@see Use `entity.Filter` instead.
        ---
        ---@param filter_fn ash.entity.FilterFunc
        ---@return ash.entity.Filter
        ---@deprecated
        function ash_entity.filter( filter_fn )
            return FilterClass( filter_fn )
        end

    end

    -- TODO: possibly deprecated
    hook.Add( "InitPostEntity", "Handler", function()
        hook_Run( "ash.entity.PostSpawnEntities" )
    end )

    -- TODO: possibly deprecated
    hook.Add( "PostCleanupMap", "Handler", function()
        hook_Run( "ash.entity.PostCleanupMap" )
    end )

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

do

    local result = {}

    ---@param arguments table
    ---@param entity Entity
    ---@param bullet Bullet
    hook.Add( "EntityFireBullets", "BulletCallback", function( arguments, entity, bullet )
        if arguments[ 2 ] == false then return false end

        local callback = bullet.Callback

        bullet.Callback = function( attacker, trace_result, damage_info )
            local do_effects, do_damage = hook_Run( "ash.entity.BulletImpact", bullet, attacker, trace_result, damage_info )

            result.do_effects = do_effects ~= false
            result.do_damage = do_damage ~= false

            if callback ~= nil then
                do_effects, do_damage = callback( attacker, trace_result, damage_info )

                if do_effects ~= nil then
                    result.do_effects = do_effects ~= false
                end

                if do_damage ~= nil then
                    result.do_damage = do_damage ~= false
                end
            end

            return result
        end

        return true
    end, POST_HOOK_RETURN )

end

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
    ---@return Entity | nil entity
    ---@return number | nil distance
    function ash_entity.closest( entities, origin, position_fn )
        if position_fn == nil then
            position_fn = Entity_GetPos
        end

        local min_distance = math_huge
        local selected_entity

        for i = 1, #entities, 1 do
            local entity = entities[ i ]

            local distance = Vector_DistToSqr( position_fn( entity ), origin )
            if distance < min_distance then
                selected_entity = entity
                min_distance = distance
            end
        end

        return selected_entity, math_sqrt( min_distance )
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
        hook.Add( "ash.entity.Tick", "WaterLevel", function( entity )
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

    hook.Add( "Tick", "Ticking", function()
        for _, entity in ents_Iterator() do
            hook_Run( "ash.entity.Tick", entity )
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

dreamwork.engine.hook.catch( "dreamwork.entity.gc", "ash.entity", function( entity )
    hook_Run( "ash.entity.GarbageCollected", entity )
end )

do
    local collide_map = {}

    --- [SHARED]
    ---
    --- Sets whether two entity classes should collide with each other.
    ---
    --- @param class1 string
    --- @param class2 string
    --- @param bool? bool
    function ash_entity.setNoCollideClasses( class1, class2, bool )
        collide_map[ class1 ] = collide_map[ class1 ] or {}
        collide_map[ class1 ][ class2 ] = bool
    end

    hook.Add( "ShouldCollide", "Default", function( ent1, ent2 )
        local class1 = Entity_GetClass( ent1 )
        if collide_map[ class1 ] and collide_map[ class1 ][ Entity_GetClass( ent2 ) ] == false then
            return false
        end

        if hook_Run( "ash.entity.CanCollide", ent1, ent2 ) == false then
            return false
        end

        return true
    end, PRE_HOOK_RETURN )
end

do
    local DistToSqr = Vector.DistToSqr
    local Entity_GetPos = Entity.GetPos

    --- [SHARED]
    ---
    --- Finds entities within a given range of a position.
    ---
    ---@param pos Vector distance squared
    ---@param range number
    ---@param ... string
    ---@return Entity[] entity list
    ---@return integer count
    function ash_entity.findInRange( pos, range, ... )
        local count_varang = select( "#", ... )
        local results = {}
        local result_count = 0

        if count_varang <= 0 then
            for _, v in ash_entity.iterator() do
                if DistToSqr( pos, Entity_GetPos( v ) ) <= range then
                    result_count = result_count + 1
                    results[ result_count ] = v
                end
            end
        else
            for i = 1, count_varang do
                local v = select( i, ... )
                local ents_list, ents_count = ash_entity.findByClass( v )

                for j = 1, ents_count do
                    local ent = ents_list[ j ]
                    if DistToSqr( pos, Entity_GetPos( ent ) ) <= range then
                        result_count = result_count + 1
                        results[ result_count ] = ent
                    end
                end
            end
        end

        return results, result_count
    end

    --- [SHARED]
    ---
    --- Returns whether there is an entity in range of the given position.
    ---
    ---@param pos Vector
    ---@param range number
    ---@param ... string
    ---@return boolean
    function ash_entity.hasInRange( pos, range, ... )
        for i = 1, select( "#", ... ) do
            local v = select( i, ... )
            local ents_list, ents_count = ash_entity.findByClass( v )

            for j = 1, ents_count do
                local ent = ents_list[ j ]
                if DistToSqr( pos, Entity_GetPos( ent ) ) <= range then
                    return true
                end
            end
        end

        return false
    end
end

do
    local math_floor = math.floor
    local math_abs = math.abs
    local math_huge = math.huge
    local Vector_DistToSqr = Vector.DistToSqr
    local hook_Run = hook.Run
    local table_removeByValue = table.removeByValue
    local ash_entity_iterator = ash_entity.iterator

    local Entity_GetPos = Entity.GetPos

    ---@type integer
    local chunk_size = 256

    ---@type integer
    local chunk_count = 128

    ---@type integer
    local half = chunk_count / 2

    ---@class ash.entity.chunk
    ---@field id integer unique chunk id
    ---@field x number world X of the chunk origin (chunk_size * cx)
    ---@field y number world Y of the chunk origin (chunk_size * cy)
    ---@field [1] number same as x
    ---@field [2] number same as y
    ---@field cx integer chunk grid index along X, from -half to half - 1
    ---@field cy integer chunk grid index along Y, from -half to half - 1
    ---@field entities Entity[] entities in the chunk, entities[0] holds the count
    ---@field neighbors ash.entity.chunk[] up to 8 surrounding chunks, neighbors[0] holds the count
    ---@field area ash.entity.chunk[] the chunk itself + neighbors (3x3), shared table, do not modify
    ---@field area_count integer number of chunks in `area`

    ---@type table<integer, table<integer, ash.entity.chunk>>
    local chunks = {}

    ---@type table<integer, ash.entity.chunk>
    local chunks_byid = {}

    -- Build the grid
    do
        local id = 0
        for j = -half, half - 1 do
            chunks[ j ] = {}

            for i = -half, half - 1 do
                id = id + 1

                local x = chunk_size * j
                local y = chunk_size * i

                ---@type ash.entity.chunk
                local chunk = {
                    [ "id" ] = id,
                    [ "x" ] = x,
                    [ "y" ] = y,
                    [ 1 ] = x,
                    [ 2 ] = y,
                    [ "cx" ] = j,
                    [ "cy" ] = i,
                    [ "entities" ] = { [ 0 ] = 0 },
                }

                chunks[ j ][ i ] = chunk
                chunks_byid[ id ] = chunk
            end
        end
    end

    for j = -half, half - 1 do
        for i = -half, half - 1 do
            local chunk = chunks[ j ][ i ]

            ---@type ash.entity.chunk[]
            local neighbors = { [ 0 ] = 0 }
            local count = 0

            for dj = -1, 1 do
                local row = chunks[ j + dj ]
                if row ~= nil then
                    for di = -1, 1 do
                        if dj ~= 0 or di ~= 0 then
                            local neighbor = row[ i + di ]
                            if neighbor ~= nil then
                                count = count + 1
                                neighbors[ count ] = neighbor
                            end
                        end
                    end
                end
            end

            neighbors[ 0 ] = count
            chunk[ "neighbors" ] = neighbors

            ---@type ash.entity.chunk[]
            local area = { chunk }
            for k = 1, count do
                area[ k + 1 ] = neighbors[ k ]
            end

            chunk[ "area" ] = area
            chunk[ "area_count" ] = count + 1
        end
    end

    --- [SHARED]
    ---
    --- Get a chunk by its unique id.
    ---
    ---@param id integer unique chunk id
    ---@return ash.entity.chunk? chunk the chunk, or `nil` if the id is invalid
    ---@nodiscard
    local function getChunkByID( id )
        return chunks_byid[ id ]
    end
    ash_entity.getChunkByID = getChunkByID

    --- [SHARED]
    ---
    --- Get the chunk that contains the given world position (Z is ignored).
    ---
    ---@param position Vector world position
    ---@return ash.entity.chunk? chunk the chunk, or `nil` if the position is outside the grid
    ---@nodiscard
    local function getChunk( position )
        local column = chunks[ math_floor( position[ 1 ] / chunk_size ) ]
        if not column then return nil end

        return column[ math_floor( position[ 2 ] / chunk_size ) ]
    end
    ash_entity.getChunk = getChunk


    ---@type table<Entity, ash.entity.chunk>
    local entity_chunk = {}
    gc.setTableRules( entity_chunk, true )
    gc.setup( entity_chunk, "Entity" )

    ---@type table<Entity, Vector>
    local entity_positions = {}
    gc.setTableRules( entity_positions, true )
    gc.setup( entity_positions, "Entity" )

    --- [SHARED]
    ---
    --- Get all chunks that a line segment passes through (grid traversal, Z is ignored).
    --- Chunks are returned in order from `start_pos` to `end_pos`.
    --- Parts of the line outside the grid are skipped.
    ---
    ---@param start_pos Vector line start in world coordinates
    ---@param end_pos Vector line end in world coordinates
    ---@return ash.entity.chunk[] chunks list of chunks, a new table on every call
    ---@return integer count number of chunks in the list
    local function getChunksInLine( start_pos, end_pos )
        ---@type ash.entity.chunk[]
        local result = {}
        local count = 0

        local x0, y0 = start_pos[ 1 ] / chunk_size, start_pos[ 2 ] / chunk_size
        local x1, y1 = end_pos[ 1 ] / chunk_size, end_pos[ 2 ] / chunk_size

        local cx, cy = math_floor( x0 ), math_floor( y0 )
        local end_cx, end_cy = math_floor( x1 ), math_floor( y1 )

        local dx, dy = x1 - x0, y1 - y0

        local step_x, step_y = 0, 0
        local t_max_x, t_max_y = math_huge, math_huge
        local t_delta_x, t_delta_y = math_huge, math_huge

        if dx > 0 then
            step_x = 1
            t_max_x = ( cx + 1 - x0 ) / dx
            t_delta_x = 1 / dx
        elseif dx < 0 then
            step_x = -1
            t_max_x = ( cx - x0 ) / dx
            t_delta_x = -1 / dx
        end

        if dy > 0 then
            step_y = 1
            t_max_y = ( cy + 1 - y0 ) / dy
            t_delta_y = 1 / dy
        elseif dy < 0 then
            step_y = -1
            t_max_y = ( cy - y0 ) / dy
            t_delta_y = -1 / dy
        end

        local max_steps = math_abs( end_cx - cx ) + math_abs( end_cy - cy ) + 1

        for _ = 1, max_steps do
            local column = chunks[ cx ]
            local chunk = column and column[ cy ]

            if chunk then
                count = count + 1
                result[ count ] = chunk
            end

            if cx == end_cx and cy == end_cy then break end

            if t_max_x < t_max_y then
                t_max_x = t_max_x + t_delta_x
                cx = cx + step_x
            else
                t_max_y = t_max_y + t_delta_y
                cy = cy + step_y
            end
        end

        return result, count
    end
    ash_entity.getChunksInLine = getChunksInLine

    --- [SHARED]
    ---
    --- Get the chunk at `position` and all chunks within `range` chunks around it
    --- (a square area of `(2 * range + 1)^2` chunks, clamped to the grid).
    ---
    --- If `range` is 0 or less, only the chunk itself is returned.
    --- If `range` is 1, the shared precomputed `chunk.area` table is returned,
    --- **do not modify it**. Otherwise a new table is created.
    ---
    ---@param position Vector world position of the center
    ---@param range integer how many chunks to add on each side of the center chunk
    ---@return ash.entity.chunk[] chunks list of chunks (empty if the position is outside the grid)
    ---@return integer count number of chunks in the list
    local function getChunkInRange( position, range )
        local chunk = getChunk( position )

        if chunk == nil then
            return {}, 0
        end

        if range <= 0 then
            return { chunk }, 1
        end

        if range == 1 then
            return chunk.area, chunk.area_count
        end

        local cx, cy = chunk.cx, chunk.cy

        local min_x = cx - range
        if min_x < -half then min_x = -half end

        local max_x = cx + range
        if max_x > half - 1 then max_x = half - 1 end

        local min_y = cy - range
        if min_y < -half then min_y = -half end

        local max_y = cy + range
        if max_y > half - 1 then max_y = half - 1 end

        ---@type ash.entity.chunk[]
        local list = {}
        local count = 0

        for x = min_x, max_x do
            local column = chunks[ x ]

            for y = min_y, max_y do
                count = count + 1
                list[ count ] = column[ y ]
            end
        end

        return list, count
    end
    ash_entity.getChunkInRange = getChunkInRange

    --- [SHARED]
    ---
    --- Get all tracked entities within `radius` of `position` (2D chunk culling + 3D distance check).
    --- Positions are taken from the cache, which is updated every 0.5 seconds,
    --- so results may lag slightly behind the real entity positions.
    ---
    ---@param position Vector center of the search
    ---@param radius number search radius in world units
    ---@return Entity[] entities a new table with the found entities
    ---@return integer count number of found entities
    local function getChunksEntitiesInRadius( position, radius )
        ---@type Entity[]
        local result = {}
        local count = 0

        local px, py = position[ 1 ], position[ 2 ]
        local radius_sqr = radius * radius

        local min_cx = math_floor( ( px - radius ) / chunk_size )
        local max_cx = math_floor( ( px + radius ) / chunk_size )
        local min_cy = math_floor( ( py - radius ) / chunk_size )
        local max_cy = math_floor( ( py + radius ) / chunk_size )

        if min_cx < -half then min_cx = -half end
        if max_cx > half - 1 then max_cx = half - 1 end
        if min_cy < -half then min_cy = -half end
        if max_cy > half - 1 then max_cy = half - 1 end

        for cx = min_cx, max_cx do
            local column = chunks[ cx ]

            local x0 = cx * chunk_size
            local x1 = x0 + chunk_size

            -- distance along X from the point to the chunk column
            local dx = 0
            if px < x0 then dx = x0 - px elseif px > x1 then dx = px - x1 end
            local dx_sqr = dx * dx

            if dx_sqr <= radius_sqr then
                for cy = min_cy, max_cy do
                    local chunk = column[ cy ]
                    local entities = chunk.entities
                    local n = entities[ 0 ]

                    if n ~= 0 then
                        local y0 = cy * chunk_size
                        local y1 = y0 + chunk_size

                        -- distance along Y from the point to the chunk
                        local dy = 0
                        if py < y0 then dy = y0 - py elseif py > y1 then dy = py - y1 end

                        -- skip the chunk if it is entirely outside the radius
                        if dx_sqr + dy * dy <= radius_sqr then
                            for i = 1, n do
                                local entity = entities[ i ]

                                if Vector_DistToSqr( position, entity_positions[ entity ] ) <= radius_sqr then
                                    count = count + 1
                                    result[ count ] = entity
                                end
                            end
                        end
                    end
                end
            end
        end

        return result, count
    end
    ash_entity.getChunksEntitiesInRadius = getChunksEntitiesInRadius

    ---@param chunk ash.entity.chunk chunk to remove the entity from
    ---@param entity Entity entity to remove
    local function removeFromChunk( chunk, entity )
        local entities = chunk.entities
        local count = entities[ 0 ]

        if table_removeByValue( entities, entity, count ) then
            entities[ 0 ] = count - 1
        end
    end

    --- [ SHARED ]
    ---
    --- Forget the entity when it is removed.
    ---
    ---@param entity Entity the removed entity
    hook.Add( "ash.entity.Removed", "Chunks", function( entity )
        local cur_chunk = entity_chunk[ entity ]

        if cur_chunk ~= nil then
            removeFromChunk( cur_chunk, entity )
        end

        entity_chunk[ entity ] = nil
        entity_positions[ entity ] = nil
    end )

    do
        ---@param entity Entity entity to move
        ---@param chunk ash.entity.chunk? new chunk, `nil` if the entity left the grid
        local function setEntityChunk( entity, chunk )
            local old_chunk = entity_chunk[ entity ]
            if old_chunk == chunk then return end

            if old_chunk then
                removeFromChunk( old_chunk, entity )
            end

            if chunk then
                local entities = chunk.entities
                local count = entities[ 0 ] + 1

                entities[ count ] = entity
                entities[ 0 ] = count
            end

            entity_chunk[ entity ] = chunk
        end

        timer.Create( "ash.entity.ChunksPositionUpdate", 0.5, 0, function()
            for _, entity in ash_entity_iterator() do
                ---@cast entity Entity
                local position = Entity_GetPos( entity )
                local old_position = entity_positions[ entity ]

                if old_position == nil or position ~= old_position then
                    entity_positions[ entity ] = position

                    setEntityChunk( entity, getChunk( position ) )

                    hook_Run( "ash.entity.ChunksPositionUpdate", entity, position )
                end
            end
        end )
    end

    -- if  CLIENT then
    --     --- Height of the debug box top.
    --     ---@type number
    --     local height = chunk_size

    --     ---@type Color
    --     local color_red = Color( 255, 0, 0 )

    --     --- Bottom Z of the debug box (near the map's lower bound).
    --     ---@type number
    --     local bottom = -( 16384 - 100 )

    --     --- Radius (in chunks) of the debug area around the origin.
    --     ---@type integer
    --     local radius = 2

    --     -- reusable vectors to avoid allocations every frame
    --     local mins, maxs = Vector(), Vector()

    --     ---
    --     --- Draw a wireframe box around a chunk.
    --     ---
    --     ---@param chunk ash.entity.chunk chunk to draw
    --     ---@param color Color wireframe color
    --     local function drawChunk( chunk, color )
    --         mins[ 1 ], mins[ 2 ], mins[ 3 ] = chunk[ 1 ], chunk[ 2 ], bottom
    --         maxs[ 1 ], maxs[ 2 ], maxs[ 3 ] = chunk[ 1 ] + chunk_size, chunk[ 2 ] + chunk_size, height

    --         render.DrawWireframeBox( vector_origin, angle_zero, mins, maxs, color, true )
    --     end

    --     --- Debug: draw chunks around the world origin, the one the local player stands in is red.
    --     hook.Add( "PostDrawOpaqueRenderables", "DebugChunks", function()
    --         local ply = LocalPlayer()
    --         if not IsValid( ply ) then return end

    --         local pos = Entity_GetPos( ply )
    --         local cur_chunk = getChunk( pos )

    --         local chunks_list, chunks_count = getChunkInRange( vector_origin, radius )

    --         for i = 1, chunks_count do
    --             local chunk = chunks_list[ i ]

    --             drawChunk( chunk, chunk == cur_chunk and color_red or color_white )
    --         end
    --     end )
    -- end
end

return ash_entity

