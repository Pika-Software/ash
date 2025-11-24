MODULE.Networks = {
    "network"
}

MODULE.ClientFiles = {
    "animations.lua",
    "shared.lua"
}

---@class ash.player
local player_lib = include( "shared.lua" )
local player_isInitialized = player_lib.isInitialized

---@type ash.entity
local entity_lib = require( "ash.entity" )
local entity_getHitbox = entity_lib.getHitbox
local entity_getHitboxBounds = entity_lib.getHitboxBounds

---@type ash.utils
local utils = require( "ash.utils" )

local util_TraceLine = util.TraceLine
local util_TraceHull = util.TraceHull

local Entity_GetBoneMatrix = Entity.GetBoneMatrix
local Entity_IsValid = Entity.IsValid

local math_floor = math.floor
local hook_Run = hook.Run

local NULL = NULL

hook.Add( "PlayerInitialized", "HullSync", function( pl )
    if player_isInitialized( pl ) then
        net.Start( "network" )

        net.WriteUInt( 0, 8 )
        net.WritePlayer( pl )

        local mins, maxs = pl:GetHull()
        net.WriteVector( mins ); net.WriteVector( maxs )

        local mins_ducked, maxs_ducked = pl:GetHullDuck()
        net.WriteVector( mins_ducked ); net.WriteVector( maxs_ducked )

        net.Broadcast()
    end
end )

do

    local Entity_SetNWEntity = Entity.SetNWEntity

    --- [SERVER]
    ---
    --- Sets the player's ragdoll entity.
    ---
    ---@param pl Player
    ---@param ragdoll Entity
    function player_lib.setRagdoll( pl, ragdoll )
        Entity_SetNWEntity( pl, "m_eRagdoll", ragdoll )
    end

end

do

    local player_getRagdoll = player_lib.getRagdoll

    --- [SERVER]
    ---
    --- Removes the player's ragdoll entity.
    ---
    ---@param pl Player
    function player_lib.ragdollRemove( pl )
        local ragdoll = player_getRagdoll( pl )
        if ragdoll ~= nil and Entity_IsValid( ragdoll ) and hook_Run( "PrePlayerRagdollRemove", pl, ragdoll ) ~= false then
            hook_Run( "PlayerRagdollRemove", pl, ragdoll )
        end

        hook_Run( "PostPlayerRagdollRemove", pl )
    end

    hook.Add( "PlayerRagdollRemove", "DefaultRagdoll", function( pl, ragdoll )
        ragdoll:Remove()
    end )

    hook.Add( "PrePlayerRagdoll", "DefaultRagdoll", player_lib.ragdollRemove )

end

do

    local Entity_TranslatePhysBoneToBone = Entity.TranslatePhysBoneToBone
    local Entity_GetPhysicsObjectCount = Entity.GetPhysicsObjectCount
    local Entity_GetPhysicsObjectNum = Entity.GetPhysicsObjectNum

    local player_getVelocity = player_lib.getVelocity

    local utils_isInLevelBounds = utils.isInLevelBounds

    local trace_result = {}

    local trace = {
        output = trace_result
    }

    --- [SERVER]
    ---
    --- Creates the player's ragdoll entity.
    ---
    ---@param pl Player
    ---@return Entity ragdoll
    function player_lib.ragdollCreate( pl )
        hook_Run( "PrePlayerRagdoll", pl )

        local ragdoll_entity = hook_Run( "PlayerRagdoll", pl ) or NULL

        if ragdoll_entity ~= nil and Entity_IsValid( ragdoll_entity ) then
            local player_velocity = player_getVelocity( pl )
            player_lib.setRagdoll( pl, ragdoll_entity )

            for i = 0, Entity_GetPhysicsObjectCount( ragdoll_entity ) - 1 do
                local physics_object = Entity_GetPhysicsObjectNum( ragdoll_entity, i )
                if physics_object ~= nil and physics_object:IsValid() then
                    local bone_id = Entity_TranslatePhysBoneToBone( ragdoll_entity, i )
                    if bone_id ~= nil and bone_id ~= -1 then
                        local matrix = Entity_GetBoneMatrix( pl, bone_id )
                        if matrix ~= nil then
                            physics_object:SetAngles( matrix:GetAngles() )
                            local origin = matrix:GetTranslation()

                            if utils_isInLevelBounds( origin ) then
                                trace.start = origin
                                trace.endpos = origin
                                trace.filter = { ragdoll_entity, pl }

                                local hitbox, hitbox_group = entity_getHitbox( pl, bone_id )
                                if hitbox == nil then
                                    util_TraceLine( trace )
                                else
                                    trace.mins, trace.maxs = entity_getHitboxBounds( pl, hitbox, hitbox_group )
                                    util_TraceHull( trace )
                                end

                                if not trace_result.Hit then
                                    physics_object:SetPos( origin )
                                end
                            end
                        end
                    end

                    physics_object:SetVelocity( player_velocity )
                    physics_object:Wake()
                end
            end

            hook_Run( "PostPlayerRagdoll", pl, ragdoll_entity )
        end

        return ragdoll_entity
    end

end

do

    local Entity_SetNWBool = Entity.SetNWBool

    ---@type table<integer, fun( pl: Player, len: integer )>
    local net_commands = {
        -- player initialized
        [ 0 ] = function( pl )
            if not player_isInitialized( pl ) then
                Entity_SetNWBool( pl, "m_bInitialized", true )
                hook.Run( "PlayerInitialized", pl )
            end
        end
    }

    net.Receive( "network", function( len, pl )
        local cmd_fn = net_commands[ net.ReadUInt( 8 ) ]
        if cmd_fn ~= nil then
            cmd_fn( pl, len )
        end
    end )

end

do

    local Player_SetHullDuck = Player.SetHullDuck
    local Player_SetHull = Player.SetHull
    local Vector = Vector

    --- [SERVER]
    ---
    --- Sets the player's hull.
    ---
    ---@param pl Player
    ---@param on_crouch boolean
    ---@param mins Vector
    ---@param maxs Vector
    function player_lib.setHull( pl, on_crouch, mins, maxs )
        if on_crouch then
            Player_SetHullDuck( pl, mins, maxs )
        else
            Player_SetHull( pl, mins, maxs )
        end

        net.Start( "network" )
        net.WriteUInt( 0, 8 )
        net.WritePlayer( pl )
        net.WriteBool( on_crouch )
        net.WriteVector( mins )
        net.WriteVector( maxs )
        net.Broadcast()
    end

    --- [SERVER]
    ---
    --- Sets the player's hull size.
    ---
    ---@param pl Player
    ---@param on_crouch boolean
    ---@param width integer
    ---@param depth integer
    ---@param height integer
    function player_lib.setHullSize( pl, on_crouch, width, depth, height )
        local width_half, depth_half = math_floor( width * 0.5 ), math_floor( depth * 0.5 )
        player_lib.setHull( pl, on_crouch, Vector( -width_half, -depth_half, 0 ), Vector( width_half, depth_half, height ) )
    end

end

---@alias ash.player.GESTURE_SLOT integer
---| `0` Slot for weapon gestures
---| `1` Slot for grenade gestures
---| `2` Slot for jump gestures
---| `3` Slot for swimming gestures
---| `4` Slot for flinching gestures
---| `5` Slot for VCD gestures
---| `6` Slot for custom gestures

do

    local Player_AddVCDSequenceToGestureSlot = Player.AddVCDSequenceToGestureSlot
    local Player_AnimResetGestureSlot = Player.AnimResetGestureSlot
    local Player_AnimRestartGesture = Player.AnimRestartGesture

    local Entity_SelectWeightedSequence = Entity.SelectWeightedSequence
    local Entity_LookupSequence = Entity.LookupSequence

    --- [SERVER]
    ---
    --- Starts a player's gesture.
    ---
    ---@param pl Player
    ---@param slot ash.player.GESTURE_SLOT
    ---@param activity integer
    ---@param cycle number
    ---@param auto_kill boolean
    function player_lib.startGestureByActivity( pl, slot, activity, cycle, auto_kill )
        net.Start( "network" )
        net.WriteUInt( 1, 8 )
        net.WritePlayer( pl )
        net.WriteUInt( slot, 3 )
        net.WriteUInt( activity, 32 )
        net.WriteBool( auto_kill )
        net.WriteFloat( cycle )
        net.Broadcast()

        local sequence_id = Entity_SelectWeightedSequence( pl, activity )
        if sequence_id ~= nil and sequence_id > 0 then
            return Player_AddVCDSequenceToGestureSlot( pl, slot, sequence_id, cycle, auto_kill )
        end

        return Player_AnimRestartGesture( pl, slot, activity, auto_kill )
    end

    --- [SERVER]
    ---
    --- Starts a player's gesture.
    ---
    ---@param pl Player
    ---@param slot ash.player.GESTURE_SLOT
    ---@param sequence_name string
    ---@param cycle number
    ---@param auto_kill boolean
    function player_lib.startGestureBySequence( pl, slot, sequence_name, cycle, auto_kill )
        net.Start( "network" )
        net.WriteUInt( 2, 8 )
        net.WritePlayer( pl )
        net.WriteUInt( slot, 3 )
        net.WriteString( sequence_name )
        net.WriteBool( auto_kill )
        net.WriteFloat( cycle )
        net.Broadcast()

        local sequence_id = Entity_LookupSequence( pl, sequence_name )
        if sequence_id ~= nil and sequence_id > 0 then
            return Player_AddVCDSequenceToGestureSlot( pl, slot, sequence_id, cycle, auto_kill )
        end

        return Player_AnimResetGestureSlot( pl, slot )
    end

    --- [SERVER]
    ---
    --- Stops a player's gesture.
    ---
    ---@param pl Player
    ---@param slot ash.player.GESTURE_SLOT
    function player_lib.stopGesture( pl, slot )
        return Player_AnimResetGestureSlot( pl, slot )
    end

end

do

    local bit_band = bit.band
    local bit_bor = bit.bor

    ---@type table<Player, integer>
    local respawn_keys = {}

    do

        local default_respawn_keys = bit_bor( IN_JUMP, IN_ATTACK, IN_ATTACK2 )

        setmetatable( respawn_keys, {
            __index = function()
                return default_respawn_keys
            end
        } )

    end

    --- [SERVER]
    ---
    --- Gets the player's respawn key.
    ---
    ---@param pl Player
    ---@return integer key
    function player_lib.getRespawnKey( pl )
        return respawn_keys[ pl ]
    end

    --- [SERVER]
    ---
    --- Sets the player's respawn key.
    ---
    ---@param pl Player
    ---@param key integer
    function player_lib.setRespawnKey( pl, key )
        respawn_keys[ pl ] = key
    end

    ---@type table<Player, boolean>
    local awaiting_respawn = {}

    do

        local player_isDead = player_lib.isDead

        setmetatable( awaiting_respawn, {
            __index = function( _, pl )
                return player_isDead( pl )
            end
        } )

    end

    ---@param pl Player
    ---@param attacker Entity
    ---@param dmg_info CTakeDamageInfo
    hook.Add( "PlayerRagdoll", "DefaultRagdoll", function( pl, attacker, dmg_info )
        local ragdoll_entity = ents.Create( "prop_ragdoll" )

        for key, value in pairs( pl:GetSaveTable( true ) ) do
            ragdoll_entity:SetSaveValue( key, value )
        end

        ragdoll_entity:Spawn()
        return ragdoll_entity
    end )

    do

        hook.Add( "DoPlayerDeath", "Ragdoll", function( pl, attacker, dmg_info )
            hook_Run( "PrePlayerDeath", pl, attacker, dmg_info )

            if hook_Run( "CanPlayerRagdoll", pl ) ~= false then
                player_lib.ragdollCreate( pl )
            end

            ---@diagnostic disable-next-line: redundant-parameter, undefined-global
        end, PRE_HOOK )

    end

    hook.Add( "PostPlayerDeath", "Respawn", function( pl )
        awaiting_respawn[ pl ] = true

        ---@diagnostic disable-next-line: redundant-parameter, undefined-global
    end, PRE_HOOK )

    do

        local Entity_SetPos = Entity.SetPos
        local Entity_Spawn = Entity.Spawn

        hook.Add( "KeyRelease", "Respawn", function( pl, key )
            if awaiting_respawn[ pl ] and bit_band( key, respawn_keys[ pl ] ) ~= 0 and hook_Run( "CanPlayerRespawn", pl ) ~= false then
                Entity_Spawn( pl )
            end

            ---@diagnostic disable-next-line: redundant-parameter, undefined-global
        end, PRE_HOOK )

        hook.Add( "PlayerSpawn", "SpeedController", function( pl, is_transition )
            awaiting_respawn[ pl ] = false

            hook_Run( "PrePlayerSpawn", pl, is_transition )

            local max_speed = physenv.GetPerformanceSettings().MaxVelocity

            pl:SetSlowWalkSpeed( max_speed )
            pl:SetWalkSpeed( max_speed )
            pl:SetRunSpeed( max_speed )
            pl:SetMaxSpeed( max_speed )

            pl:SetCrouchedWalkSpeed( 1 )

            Entity_SetPos( pl, hook_Run( "PlayerSetupPosition", pl ) or vector_origin )

            hook_Run( "PlayerSetupModel", pl, is_transition )
            hook_Run( "PlayerSetupLoadout", pl, is_transition )

            hook_Run( "PostPlayerSpawn", pl, is_transition )

            ---@diagnostic disable-next-line: redundant-parameter, undefined-global
        end, PRE_HOOK )

    end

end

return player_lib
