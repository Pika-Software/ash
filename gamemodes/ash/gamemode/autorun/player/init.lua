MODULE.Networks = {
    "network"
}

MODULE.ClientFiles = {
    "animator.lua",
    "cl_init.lua",
    "shared.lua",
    "voice.lua"
}

do

    local mp_show_voice_icons = console.Variable.get( "mp_show_voice_icons", "boolean" )
    mp_show_voice_icons.value = false

end

---@class ash.player
---@field SpawnPoints ash.player.SpawnPoint[]
---@field SpawnPointCount integer
local ash_player = include( "shared.lua" )
local player_BitCount = ash_player.BitCount
local player_isInitialized = ash_player.isInitialized

---@type ash.entity
local ash_entity = require( "ash.entity" )
local entity_getHitbox = ash_entity.getHitbox
local entity_getHitboxBounds = ash_entity.getHitboxBounds

---@type ash.trace
local ash_trace = require( "ash.trace" )
local trace_cast = ash_trace.cast

---@type ash.level
local ash_level = require( "ash.level" )

local Entity_GetBoneMatrix = Entity.GetBoneMatrix
local Entity_IsValid = Entity.IsValid

local math_floor = math.floor
local hook_Run = hook.Run

local Player_IsBot = Player.IsBot

local NULL = NULL

ash_player.isSpeaking = Player.IsSpeaking

---@param pl Player
hook.Add( "ash.player.Initialized", "HullSync", function( pl )
    if not Player_IsBot( pl ) then
        ash_player.setHull( pl, true, pl:GetHullDuck() )
        ash_player.setHull( pl, false, pl:GetHull() )
    end
end )

--- [SERVER]
---
--- Checks if the player is uses family shared account.
---
---@param pl Player
---@return boolean
function ash_player.isFamilySharedAccount( pl )
    return not Player_IsBot( pl ) and pl:SteamID64() ~= pl:OwnerSteamID64()
end

do

    local Entity_SetNWEntity = Entity.SetNWEntity

    --- [SERVER]
    ---
    --- Sets the player's ragdoll entity.
    ---
    ---@param pl Player
    ---@param ragdoll Entity
    function ash_player.setRagdoll( pl, ragdoll )
        Entity_SetNWEntity( pl, "m_eRagdoll", ragdoll )
    end

end

do

    local player_getRagdoll = ash_player.getRagdoll

    --- [SERVER]
    ---
    --- Removes the player's ragdoll entity.
    ---
    ---@param pl Player
    function ash_player.ragdollRemove( pl )
        local ragdoll = player_getRagdoll( pl )
        if ragdoll ~= nil and Entity_IsValid( ragdoll ) and hook_Run( "ash.player.ragdoll.ShouldRemove", pl, ragdoll ) ~= false then
            ragdoll:Remove()
        end
    end

end

do

    local Entity_TranslatePhysBoneToBone = Entity.TranslatePhysBoneToBone
    local Entity_GetPhysicsObjectCount = Entity.GetPhysicsObjectCount
    local Entity_GetPhysicsObjectNum = Entity.GetPhysicsObjectNum
    local Entity_SetCollisionGroup = Entity.SetCollisionGroup
    local Entity_SetModel = Entity.SetModel
    local Entity_SetSkin = Entity.SetSkin

    local animator_getVelocity = ash_player.animator.getVelocity
    local level_containsPosition = ash_level.containsPosition

    local entity_getPlayerColor = ash_entity.getPlayerColor
    local entity_setPlayerColor = ash_entity.setPlayerColor

    local ents_Create = ents.Create

    ---@type ash.trace.Output
    ---@diagnostic disable-next-line: missing-fields
    local trace_result = {}

    ---@type ash.trace.Params
    local trace = {
        output = trace_result
    }

    ---@type table<Entity, Player>
    local ragdoll_owners = {}

    --- [SERVER]
    ---
    --- Creates the player's ragdoll entity.
    ---
    ---@param pl Player
    ---@return Entity ragdoll
    function ash_player.ragdollCreate( pl )
        hook_Run( "ash.player.ragdoll.PreCreate", pl )

        local ragdoll_entity = ents_Create( "prop_ragdoll" )
        if ragdoll_entity ~= nil and Entity_IsValid( ragdoll_entity ) then
            ragdoll_owners[ ragdoll_entity ] = pl

            Entity_SetModel( ragdoll_entity, ash_player.getModel( pl ) )
            Entity_SetSkin( ragdoll_entity, ash_player.getSkin( pl ) )

            ragdoll_entity:Spawn()

            local player_velocity = animator_getVelocity( pl )
            ash_player.setRagdoll( pl, ragdoll_entity )

            ash_entity.setPlayerColor( ragdoll_entity, ash_entity.getPlayerColor( pl ) )
            Entity_SetCollisionGroup( ragdoll_entity, 11 )

            for i = 0, Entity_GetPhysicsObjectCount( ragdoll_entity ) - 1 do
                local physics_object = Entity_GetPhysicsObjectNum( ragdoll_entity, i )
                if physics_object ~= nil and physics_object:IsValid() then
                    local bone_id = Entity_TranslatePhysBoneToBone( ragdoll_entity, i )
                    if bone_id ~= nil and bone_id ~= -1 then
                        local matrix = Entity_GetBoneMatrix( pl, bone_id )
                        if matrix ~= nil then
                            physics_object:SetAngles( matrix:GetAngles() )

                            local origin = matrix:GetTranslation()

                            if level_containsPosition( origin ) then
                                trace.start = origin
                                trace.endpos = origin
                                trace.filter = { ragdoll_entity, pl }

                                local hitbox, hitbox_group = entity_getHitbox( pl, bone_id )
                                if hitbox ~= nil then
                                    trace.mins, trace.maxs = entity_getHitboxBounds( pl, hitbox, hitbox_group )
                                end

                                trace_cast( trace )

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

            ---@type string[]
            local materials = pl:GetMaterials()
            for i = 1, #materials, 1 do
                ragdoll_entity:SetSubMaterial( i - 1, materials[ i ] )
            end

            entity_setPlayerColor( ragdoll_entity, entity_getPlayerColor( pl ) )
            ragdoll_entity:SetColor( pl:GetColor() )

            hook_Run( "ash.player.ragdoll.Setup", pl, ragdoll_entity )
        end

        hook_Run( "ash.player.ragdoll.PostCreate", pl, ragdoll_entity )

        return ragdoll_entity
    end

    ---@param pl Player
    hook.Add( "ash.player.ragdoll.Create", "Defaults", function( arguments, pl )
    end, POST_HOOK_RETURN )

    hook.Add( "ash.entity.Removed", "Ragdoll", function( ragdoll )
        local owner = ragdoll_owners[ ragdoll ]

        if owner == nil then return end
        ragdoll_owners[ ragdoll ] = nil

        hook_Run( "ash.player.ragdoll.Removed", owner, ragdoll )
    end, PRE_HOOK )

end

do

    local Entity_SetNWBool = Entity.SetNWBool

    do

        local player_isNextBot = ash_player.isNextBot

        hook.Add( "PlayerInitialSpawn", "Initialization", function( pl )
            if player_isNextBot( pl ) then
                Entity_SetNWBool( pl, "m_bInitialized", true )
                hook_Run( "ash.player.Initialized", pl )
            end
        end, PRE_HOOK )

    end

    ---@type table<integer, fun( pl: Player, len: integer )>
    local net_commands = {
        -- player initialized
        [ 0 ] = function( pl )
            if not player_isInitialized( pl ) then
                Entity_SetNWBool( pl, "m_bInitialized", true )

                net.Start( "network" )
                net.WriteUInt( 0, 8 )
                net.WriteUInt( pl:EntIndex(), player_BitCount )
                net.SendOmit( pl )

                hook_Run( "ash.player.Initialized", pl )
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
    ---@diagnostic disable-next-line: duplicate-set-field
    function ash_player.setHull( pl, on_crouch, mins, maxs )
        if on_crouch then
            Player_SetHullDuck( pl, mins, maxs )
        else
            Player_SetHull( pl, mins, maxs )
        end

        net.Start( "network" )
        net.WriteUInt( 1, 8 )

        net.WriteUInt( pl:EntIndex(), player_BitCount )
        net.WriteBool( on_crouch )

        net.WriteDouble( mins[ 1 ] )
        net.WriteDouble( mins[ 2 ] )
        net.WriteDouble( mins[ 3 ] )

        net.WriteDouble( maxs[ 1 ] )
        net.WriteDouble( maxs[ 2 ] )
        net.WriteDouble( maxs[ 3 ] )

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
    function ash_player.setHullSize( pl, on_crouch, width, depth, height )
        local width_half, depth_half = math_floor( width * 0.5 ), math_floor( depth * 0.5 )
        ash_player.setHull( pl, on_crouch, Vector( -width_half, -depth_half, 0 ), Vector( width_half, depth_half, height ) )
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
            end,
            __mode = "k"
        } )

    end

    --- [SERVER]
    ---
    --- Gets the player's respawn key.
    ---
    ---@param pl Player
    ---@return integer key
    function ash_player.getRespawnKey( pl )
        return respawn_keys[ pl ]
    end

    --- [SERVER]
    ---
    --- Sets the player's respawn key.
    ---
    ---@param pl Player
    ---@param key integer
    function ash_player.setRespawnKey( pl, key )
        respawn_keys[ pl ] = key
    end

    ---@type table<Player, boolean>
    local awaiting_respawn = {}

    do

        local player_isDead = ash_player.isDead

        setmetatable( awaiting_respawn, {
            __index = function( _, pl )
                return player_isDead( pl )
            end,
            __mode = "k"
        } )

    end

    hook.Add( "DoPlayerDeath", "Death", function( pl, attacker, dmg_info )
        if hook_Run( "ash.player.ragdoll.ShouldCreate", pl ) ~= false then
            ash_player.ragdollCreate( pl )
        end

        hook_Run( "ash.player.PreDeath", pl, attacker, dmg_info )
    end, PRE_HOOK )

    hook.Add( "PlayerDeath", "Death", function( pl, inflictor, attacker )
        hook_Run( "ash.player.Death", pl, false, inflictor or NULL, attacker or NULL )
    end, PRE_HOOK )

    hook.Add( "PlayerSilentDeath", "Death", function( pl )
        hook_Run( "ash.player.Death", pl, true, NULL, NULL )
    end, PRE_HOOK )

    hook.Add( "PostPlayerDeath", "Death", function( pl )
        awaiting_respawn[ pl ] = true
        hook_Run( "ash.player.PostDeath", pl )
    end, PRE_HOOK )

    do

        local Entity_SetPos = Entity.SetPos
        local Entity_Spawn = Entity.Spawn

        ---@param pl Player
        ---@param in_key integer
        hook.Add( "ash.player.Key", "Spawn", function( pl, in_key )
            if awaiting_respawn[ pl ] and bit_band( in_key, respawn_keys[ pl ] ) ~= 0 and hook_Run( "ash.player.ShouldSpawn", pl ) ~= false then
                Entity_Spawn( pl )
            end
        end, PRE_HOOK )

        ---@param pl Player
        ---@param transition boolean
        hook.Add( "PlayerSpawn", "PreSpawn", function( pl, transition )
            awaiting_respawn[ pl ] = false

            hook_Run( "ash.player.PreSpawn", pl, transition )

            local max_speed = physenv.GetPerformanceSettings().MaxVelocity

            pl:SetSlowWalkSpeed( max_speed )
            pl:SetWalkSpeed( max_speed )
            pl:SetRunSpeed( max_speed )
            pl:SetMaxSpeed( max_speed )

            pl:SetCrouchedWalkSpeed( 1 )

            hook_Run( "ash.player.SetupModel", pl, transition )
            hook_Run( "ash.player.SetupAmmo", pl, transition )

            local weapon_classes = hook_Run( "ash.player.SetupWeapons", pl, transition )
            if weapon_classes ~= nil then
                for i = 1, #weapon_classes, 1 do
                    local weapon = pl:Give( weapon_classes[ i ] )
                    if weapon ~= nil and Entity_IsValid( weapon ) and weapon:IsWeapon() then
                        hook_Run( "ash.player.SetupWeapon", pl, weapon, transition )
                    end
                end
            end

            hook_Run( "ash.player.SetupLoadout", pl, transition )

            hook_Run( "ash.player.Spawn", pl, transition )
        end, PRE_HOOK )

        ---@param pl Player
        ---@param is_transition boolean
        ---@diagnostic disable-next-line: undefined-doc-param
        hook.Add( "PlayerSpawn", "PostSpawn", function( _, pl, is_transition )
            if not is_transition then
                Entity_SetPos( pl, hook_Run( "ash.player.SetupPosition", pl ) or vector_origin )
            end

            hook_Run( "ash.player.PostSpawn", pl, is_transition )
        end, POST_HOOK )

    end

end

do

    local player_Iterator = player.Iterator

    hook.Add( "Tick", "Ticking", function()
        for _, pl in player_Iterator() do
            hook_Run( "ash.player.Think", pl )
        end
    end )

end

do

    local Player_GetActiveWeapon = Player.GetActiveWeapon

    ---@type table<Player, Weapon>
    local active_weapons = {}

    setmetatable( active_weapons, {
        __index = function( self, pl )
            return Player_GetActiveWeapon( pl ) or NULL
        end,
        __mode = "k"
    } )

    --- [SERVER]
    ---
    --- Returns the player's active weapon.
    ---
    ---@param pl Player
    ---@return Weapon weapon
    ---@diagnostic disable-next-line: duplicate-set-field
    function ash_player.getActiveWeapon( pl )
        return active_weapons[ pl ]
    end

    hook.Add( "PlayerSwitchWeapon", "WeaponLookup", function( arguments, pl, old, new )
        active_weapons[ pl ] = new
        return hook_Run( "ash.player.SwitchedWeapon", pl, old, new ) == false or arguments[ 2 ] == true
    end, POST_HOOK_RETURN )

end

do

    local table_remove = table.remove

    ---@class ash.player.SpawnPoint
    ---@field id integer
    ---@field position Vector
    ---@field angles Angle
    ---@field entity Entity

    ---@type ash.player.SpawnPoint[]
    local spawnpoints = {}

    ash_player.SpawnPoints = spawnpoints

    ---@type integer
    local spawnpoint_count = 0

    ash_player.SpawnPointCount = spawnpoint_count

    --- [SERVER]
    ---
    --- Returns a spawnpoint for the player or nil if there are no spawnpoints.
    ---
    ---@param pl Player
    ---@return ash.player.SpawnPoint | nil spawnpoint
    function ash_player.getSpawnPoint( pl )
        for i = 1, spawnpoint_count, 1 do
            local spawnpoint = spawnpoints[ i ]
            if hook_Run( "ash.player.SpawnPoint", pl, spawnpoint ) ~= false then
                table.shuffle( spawnpoints, spawnpoint_count )
                return spawnpoint
            end
        end

        return nil
    end

    ---@type table<Entity, integer>
    local spawn_entities = {}

    hook.Add( "EntityRemoved", "SpawnControl", function( entity )
        local id = spawn_entities[ entity ]
        if id ~= nil then
            ash_player.removeSpawnPoint( id )
        end
    end, PRE_HOOK )

    --- [SERVER]
    ---
    --- Adds a spawnpoint.
    ---
    ---@param entity Entity | nil
    ---@param position Vector | nil
    ---@param angles Angle | nil
    ---@return ash.player.SpawnPoint spawnpoint
    function ash_player.addSpawnPoint( entity, position, angles )
        if entity ~= nil and Entity_IsValid( entity ) then
            if position == nil then
                position = entity:GetPos()
            end

            if angles == nil then
                angles = entity:GetAngles()
            end
        end

        if position == nil then
            error( "spawnpoint has no position or entity", 2 )
        end

        spawnpoint_count = spawnpoint_count + 1
        ash_player.SpawnPointCount = spawnpoint_count

        if entity ~= nil and Entity_IsValid( entity ) then
            spawn_entities[ entity ] = spawnpoint_count
        end

        local spawnpoint = {
            id = spawnpoint_count,
            position = position,
            angles = angles or Angle( 0, 0, 0 ),
            entity = entity or NULL
        }

        spawnpoints[ spawnpoint_count ] = spawnpoint
        return spawnpoint
    end

    --- [SERVER]
    ---
    --- Removes a spawnpoint.
    ---
    ---@param spawnpoint_id integer
    ---@return boolean is_removed
    function ash_player.removeSpawnPoint( spawnpoint_id )
        if spawnpoints[ spawnpoint_id ] == nil then
            return false
        end

        table_remove( spawnpoints, spawnpoint_id )

        spawnpoint_count = spawnpoint_count - 1
        ash_player.SpawnPointCount = spawnpoint_count

        return true
    end

    --- [SERVER]
    ---
    --- Removes all spawnpoints.
    ---
    function ash_player.cleanSpawnPoints()
        for i = spawnpoint_count, 1, -1 do
            spawnpoints[ i ] = nil
        end

        spawnpoint_count = 0
    end

    hook.Add( "ash.player.SetupPosition", "SpawnControl", function( pl )
        local spawnpoint = ash_player.getSpawnPoint( pl )
        if spawnpoint ~= nil then
            local entity = spawnpoint.entity
            if entity ~= nil and Entity_IsValid( entity ) then
                return entity:GetPos()
            end

            return spawnpoint.position
        end
    end )

    local utils_isSpawnpointClass = ash_entity.isSpawnpointClass
    local Vector_DistToSqr = Vector.DistToSqr

    local function entity_created( entity, class_name )
        if utils_isSpawnpointClass( class_name ) then
            local position = entity:GetPos()

            for i = 1, spawnpoint_count, 1 do
                local spawnpoint = spawnpoints[ i ]
                local point_position

                local point_entity = spawnpoint.entity
                if point_entity ~= nil and Entity_IsValid( point_entity ) then
                    point_position = point_entity:GetPos()
                else
                    point_position = spawnpoint.position
                end

                if Vector_DistToSqr( point_position, position ) < 16384 then
                    return
                end
            end

            spawn_entities[ entity ] = ash_player.addSpawnPoint( entity ).id
        end
    end

    hook.Add( "ash.entity.Created", "SpawnControl", entity_created, PRE_HOOK )

    for _, entity in ents.Iterator() do
        entity_created( entity, entity:GetClass() )
    end

end

do

    local Player_IsSpeaking = Player.IsSpeaking

    ---@type table<Player, boolean>
    local players_speaking = {}

    --- [SERVER]
    ---
    --- Checks if the player is speaking (using voice chat).
    ---
    ---@param pl Player
    ---@return boolean is_speaking
    ---@diagnostic disable-next-line: duplicate-set-field
    function ash_player.isSpeaking( pl )
        return players_speaking[ pl ]
    end

    setmetatable( players_speaking, {
        __index = function( self, pl )
            local is_speaking = Player_IsSpeaking( pl )
            self[ pl ] = is_speaking
            return is_speaking
        end,
        __mode = "k"
    } )

    ---@param pl Player
    hook.Add( "ash.player.Think", "VoiceChatStateController", function( pl )
        local is_speaking = Player_IsSpeaking( pl )
        if players_speaking[ pl ] ~= is_speaking then
            players_speaking[ pl ] = is_speaking
            hook_Run( "ash.player.Speaking", pl, is_speaking )
        end
    end, PRE_HOOK )

end

hook.Add( "PlayerSay", "ChatHandler", function( arguments, sender, message, is_team_chat )
    message = arguments[ 2 ] or message

    if hook_Run( "ash.player.ChatMessage", sender, message, is_team_chat ) ~= false then
        return message
    end

    return ""
end, POST_HOOK_RETURN )

hook.Add( "GetFallDamage", "LandingHandler", function()
    return 0
end, POST_HOOK_RETURN )

hook.Add( "CanPlayerSuicide", "SuicideHandler", function( arguments, pl )
    if arguments[ 2 ] == false or hook_Run( "ash.player.CanSuicide", pl ) == false then
        return false
    end

    return hook_Run( "ash.player.Suicide", pl ) ~= false
end, POST_HOOK_RETURN )

---@param pl Player
---@param vehicle Entity
hook.Add( "CanPlayerEnterVehicle", "VehicleEnter", function( pl, vehicle )
    return hook_Run( "ash.player.ShouldEnterVehicle", pl, vehicle )
end, PRE_HOOK_RETURN )

---@param pl Player
---@param vehicle Entity
hook.Add( "CanExitVehicle", "VehicleLeave", function( vehicle, pl )
    return hook_Run( "ash.player.ShouldLeaveVehicle", pl, vehicle )
end, PRE_HOOK_RETURN )

---@param pl Player
---@param vehicle Entity
hook.Add( "PlayerEnteredVehicle", "VehicleEnter", function( pl, vehicle )
    hook_Run( "ash.player.Vehicle", pl, vehicle, true )
end, PRE_HOOK )

---@param pl Player
---@param vehicle Entity
hook.Add( "PlayerLeaveVehicle", "VehicleLeave", function( pl, vehicle )
    hook_Run( "ash.player.Vehicle", pl, vehicle, false )
end, PRE_HOOK )

---@param arguments table
---@param pl Player
---@param vehicle Entity
hook.Add( "CanPlayerEnterVehicle", "VehicleEnter", function( arguments, pl, vehicle )
    if arguments[ 2 ] ~= false then
        hook_Run( "ash.player.EnterVehicle", pl, vehicle )
    end
end, POST_HOOK )

---@param arguments table
---@param pl Player
---@param vehicle Entity
hook.Add( "CanExitVehicle", "VehicleLeave", function( arguments, vehicle, pl )
    if arguments[ 2 ] ~= false then
        hook_Run( "ash.player.LeaveVehicle", pl, vehicle )
    end
end, POST_HOOK )

---@param arguments table
---@param pl Player
---@param entity Entity
hook.Add( "GravGunPickupAllowed", "GravityGunHandler", function( arguments, pl, entity )
    return arguments[ 2 ] ~= false
end, POST_HOOK_RETURN )

return ash_player
