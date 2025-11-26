local Entity_IsValid = Entity.IsValid

---@class ash.player
---@field Entity Player The local player entity.
local player_lib = include( "shared.lua" )

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

    local player_isInitialized = player_lib.isInitialized
    local LocalPlayer = _G.LocalPlayer

    local coroutine_resume = coroutine.resume
    local coroutine_yield = coroutine.yield

    local player_entity = LocalPlayer() or _G.NULL
    player_lib.Entity = player_entity

    local thread = coroutine.create( function()
        ::retry_loop::

        player_entity = LocalPlayer()

        if player_entity == nil or not Entity_IsValid( player_entity ) then
            coroutine_yield( false )
            goto retry_loop
        end

        player_lib.Entity = player_entity

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

    function player_lib.isLocal( pl )
        return pl == player_entity
    end

end

do

    gameevent.Listen( "player_spawn" )

    local hook_Run = hook.Run
    local Player = Player

    hook.Add( "player_spawn", "ClientSideSpawn", function( data )
        local pl = Player( data.userid )
        if pl ~= nil and Entity_IsValid( pl ) then
            hook_Run( "PlayerSpawn", pl, false )
        end
    end, PRE_HOOK )

end

return player_lib
