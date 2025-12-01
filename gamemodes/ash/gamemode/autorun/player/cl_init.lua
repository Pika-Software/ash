local coroutine_resume = coroutine.resume
local coroutine_yield = coroutine.yield
local Entity_IsValid = Entity.IsValid
local timer_Simple = timer.Simple

---@class ash.player
---@field Entity Player The local player entity.
local ash_player = include( "shared.lua" )

do

    ---@type table<integer, function>
    local net_commands = {}

    do

        local Player_SetHullDuck = Player.SetHullDuck
        local Player_SetHull = Player.SetHull

        -- player hull setup
        net_commands[ 0 ] = function()
            local pl = net.ReadPlayer()
            if pl ~= nil and Entity_IsValid( pl ) then
                if net.ReadBool() then
                    Player_SetHullDuck( pl, net.ReadVector(), net.ReadVector() )
                else
                    Player_SetHull( pl, net.ReadVector(), net.ReadVector() )
                end
            end
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

    local player_entity = LocalPlayer() or _G.NULL
    ash_player.Entity = player_entity

    local thread = coroutine.create( function()
        ::retry_loop::

        player_entity = LocalPlayer()

        if player_entity == nil or not Entity_IsValid( player_entity ) then
            coroutine_yield( false )
            goto retry_loop
        end

        ash_player.Entity = player_entity
        -- player_entity:SetIK( true )

        if not player_isInitialized( player_entity ) then
            net.Start( "network" )
            net.WriteUInt( 0, 8 )
            net.SendToServer()

            hook.Run( "PlayerInitialized", player_entity )
        end

        coroutine_yield( true )
    end )

    if not coroutine_resume( thread ) then
        hook.Add( "InitPostEntity", "PlayerInit", function()
            if coroutine_resume( thread ) then
                return
            end

            timer.Create( "await", 0.05, 0, function()
                if coroutine_resume( thread ) then
                    timer.Remove( "await" )
                end
            end )
        end )
    end

    function ash_player.isLocal( pl )
        return pl == player_entity
    end

end

do

    gameevent.Listen( "player_activate" )
    gameevent.Listen( "player_spawn" )

    local hook_Run = hook.Run
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

return ash_player
