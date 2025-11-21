---@class ash.player
local player = include( "shared.lua" )

do

    ---@type table<integer, function>
    local net_commands = {}

    do

        local Player_SetHullDuck = Player.SetHullDuck
        local Player_SetHull = Player.SetHull

        -- player hull setup
        net_commands[ 0 ] = function()
            local pl = net.ReadPlayer()
            if not ( pl ~= nil and pl:IsValid() ) then return end

            if net.ReadBool() then
                Player_SetHullDuck( pl, net.ReadVector(), net.ReadVector() )
            else
                Player_SetHull( pl, net.ReadVector(), net.ReadVector() )
            end
        end

    end

    net.Receive( "ash.player", function()
        local cmd_fn = net_commands[ net.ReadUInt( 8 ) ]
        if cmd_fn ~= nil then
            cmd_fn()
        end
    end )

end

do

    local player_isInitialized = player.isInitialized
    local Entity_IsValid = Entity.IsValid
    local LocalPlayer = _G.LocalPlayer

    local coroutine_resume = coroutine.resume
    local coroutine_yield = coroutine.yield

    local player_entity = LocalPlayer()

    local thread = coroutine.create( function()
        ::retry_loop::

        player_entity = LocalPlayer()

        if player_entity == nil or not Entity_IsValid( player_entity ) then
            coroutine_yield( false )
            goto retry_loop
        end

        if not player_isInitialized( player_entity ) then
            net.Start( "ash.player" )
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

            timer.Create( "ash::player::await", 0.25, 0, function()
                if coroutine_resume( thread ) then
                    timer.Remove( "ash::player::await" )
                end
            end )
        end )
    end

    function player.isLocal( pl )
        return pl == player_entity
    end

end

return player
