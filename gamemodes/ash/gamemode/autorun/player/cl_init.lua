local timer_Simple = timer.Simple

local Entity = Entity
local Entity_IsValid = Entity.IsValid

local coroutine_yield = coroutine.yield
local coroutine_resume = coroutine.resume

local hook_Run = hook.Run
local Vector = Vector
local net = net

local NULL = NULL

---@class ash.player
---@field Entity Player The local player entity.
---@field ViewEntity Entity The view entity.
local ash_player = include( "shared.lua" )

do

    ---@type table<integer, function>
    local net_commands = {}

    do

        local Player_SetHullDuck = Player.SetHullDuck
        local Player_SetHull = Player.SetHull

        -- player hull setup
        net_commands[ 0 ] = function()
            local index = net.ReadUInt( ash_player.BitCount )

            local is_crouch = net.ReadBool()

            local mins = Vector( net.ReadDouble(), net.ReadDouble(), net.ReadDouble() )
            local maxs = Vector( net.ReadDouble(), net.ReadDouble(), net.ReadDouble() )

            timer_Simple( 0, function()
                local pl = Entity( index )
                if pl ~= nil and Entity_IsValid( pl ) then
                    if is_crouch then
                        Player_SetHullDuck( pl, mins, maxs )
                    else
                        Player_SetHull( pl, mins, maxs )
                    end
                end
            end )
        end

    end

    do

        local Player_AddVCDSequenceToGestureSlot = Player.AddVCDSequenceToGestureSlot
        local Player_AnimResetGestureSlot = Player.AnimResetGestureSlot
        local Player_AnimRestartGesture = Player.AnimRestartGesture

        local Entity_SelectWeightedSequence = Entity.SelectWeightedSequence
        local Entity_LookupSequence = Entity.LookupSequence

        net_commands[ 1 ] = function()
            local pl = net.ReadPlayer()
            if pl ~= nil and Entity_IsValid( pl ) then
                local slot = net.ReadUInt( 3 )
                local activity = net.ReadUInt( 32 )
                local auto_kill = net.ReadBool()

                local sequence_id = Entity_SelectWeightedSequence( pl, activity )
                if sequence_id ~= nil and sequence_id > 0 then
                    Player_AddVCDSequenceToGestureSlot( pl, slot, sequence_id, net.ReadFloat(), auto_kill )
                else
                    Player_AnimRestartGesture( pl, slot, activity, auto_kill )
                end
            end
        end

        net_commands[ 2 ] = function()
            local pl = net.ReadPlayer()
            if pl ~= nil and Entity_IsValid( pl ) then
                local slot = net.ReadUInt( 3 )
                local sequence_name = net.ReadString()
                local auto_kill = net.ReadBool()

                local sequence_id = Entity_LookupSequence( pl, sequence_name )
                if sequence_id ~= nil and sequence_id > 0 then
                    Player_AddVCDSequenceToGestureSlot( pl, slot, sequence_id, net.ReadFloat(), auto_kill )
                else
                    Player_AnimResetGestureSlot( pl, slot )
                end
            end
        end

    end

    net_commands[ 3 ] = function()
        local index = net.ReadUInt( ash_player.BitCount )

        timer_Simple( 0, function()
            local pl = Entity( index )
            if pl ~= nil and Entity_IsValid( pl ) then
                hook.Run( "PlayerInitialized", pl, false )
            end
        end )
    end


    net.Receive( "network", function( length )
        local cmd_fn = net_commands[ net.ReadUInt( 8 ) ]
        if cmd_fn ~= nil then
            cmd_fn( length )
        end
    end )

end

do

    local player_isInitialized = ash_player.isInitialized
    local LocalPlayer = _G.LocalPlayer

    local player_entity

    local thread = coroutine.create( function()
        ::retry_loop::

        local entity = LocalPlayer()

        if entity == nil or not Entity_IsValid( entity ) then
            coroutine_yield( false )
            goto retry_loop
        end

        ash_player.Entity = entity
        player_entity = entity

        if not player_isInitialized( entity ) then
            net.Start( "network" )
            net.WriteUInt( 0, 8 )
            net.SendToServer()

            hook.Run( "PlayerInitialized", entity, true )
        end

        coroutine_yield( true )
    end )

    local function player_find()
        local success, is_ready = coroutine_resume( thread )
        return not success or is_ready
    end

    if not player_find() then
        hook.Add( "InitPostEntity", "PlayerInit", function()
            if player_find() then
                return
            end

            timer.Create( "await", 0.05, 0, function()
                if player_find() then
                    timer.Remove( "await" )
                end
            end )
        end )
    end

    function ash_player.isLocal( pl )
        return pl == player_entity
    end

    do

        local player_Iterator = player.Iterator

        hook.Add( "Tick", "Ticking", function()
            if player_entity == nil then return end
            hook_Run( "LocalPlayerThink", player_entity )

            for _, pl in player_Iterator() do
                hook_Run( "PlayerThink", pl, player_entity, pl == player_entity )
            end
        end )

    end

end

do

    local GetViewEntity = GetViewEntity

    ash_player.ViewEntity = GetViewEntity() or NULL

    timer.Create( "ViewEntity", 0.5, 0, function()
        local entity = GetViewEntity() or NULL
        if entity ~= ash_player.ViewEntity then
            hook_Run( "ViewEntityChanged", entity, ash_player.ViewEntity )
            ash_player.ViewEntity = entity
        end
    end )

end

do

    gameevent.Listen( "player_activate" )
    gameevent.Listen( "player_spawn" )

    local Player = Player

    ---@type table<integer, boolean>
    local player_initial_spawns = {}

    ---@type integer[]
    local player_spawns = {}

    ---@type integer
    local player_spawns_count = 0

    hook.Add( "player_activate", "ClientSideInitialSpawn", function( data )
        local user_id = data.userid
        player_initial_spawns[ user_id ] = true
        player_spawns_count = player_spawns_count + 1
        player_spawns[ player_spawns_count ] = user_id
    end, PRE_HOOK )

    -- try https://wiki.facepunch.com/gmod/player.GetByID

    hook.Add( "player_spawn", "ClientSideSpawn", function( data )
        player_spawns_count = player_spawns_count + 1
        player_spawns[ player_spawns_count ] = data.userid
    end, PRE_HOOK )

    hook.Add( "Tick", "ClientSideSpawn", function()
        for i = player_spawns_count, 1, -1 do
            local user_id = player_spawns[ i ]

            local pl = Player( user_id )
            if pl ~= nil and Entity_IsValid( pl ) then
                player_spawns_count = player_spawns_count - 1
                table.remove( player_spawns, i )

                hook_Run( "PlayerSpawn", pl, false )

                if player_initial_spawns[ user_id ] then
                    player_initial_spawns[ user_id ] = nil
                    hook_Run( "PlayerInitialSpawn", pl, false )
                end
            end
        end
    end, PRE_HOOK )

end

do

    local Player_isSpeaking = Player.IsSpeaking

    ---@type table<Player, boolean>
    local voice_statuses = {}

    setmetatable( voice_statuses, {
        __index = function( self, pl )
            return Player_isSpeaking( pl )
        end,
        __mode = "k"
    } )

    --- [CLIENT]
    ---
    --- Checks if the player is speaking (using voice chat).
    ---
    ---@return boolean
    function ash_player.isSpeaking( pl )
        return voice_statuses[ pl ]
    end

    hook.Add( "PlayerStartVoice", "Voice", function( pl, index )
        voice_statuses[ pl ] = true
    end, PRE_HOOK )

    hook.Add( "PlayerEndVoice", "Voice", function( pl )
        voice_statuses[ pl ] = false
    end, PRE_HOOK )

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

    hook.Add( "PlayerThink", "WeaponChanger", function( pl, _, is_local )
        if is_local then return end

        local active_weapon = Player_GetActiveWeapon( pl ) or NULL
        if active_weapons[ pl ] ~= active_weapon then
            hook_Run( "PlayerSwitchWeapon", pl, active_weapons[ pl ], active_weapon )
            active_weapons[ pl ] = active_weapon
        end
    end, PRE_HOOK )

end

return ash_player
