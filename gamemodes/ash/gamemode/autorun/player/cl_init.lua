---@class ash.player
local player = include( "shared.lua" )

do

    local util_actions = {
        -- hull sync
        [ 0 ] = function()
            local pl = net.ReadPlayer()
            if pl ~= nil and pl:IsValid() then
                pl:SetHull( net.ReadVector(), net.ReadVector() )
                pl:SetHullDuck( net.ReadVector(), net.ReadVector() )
            end
        end
    }

    net.Receive( "ash.player", function()
        local fn = util_actions[ net.ReadUInt( 8 ) ]
        if fn == nil then return end
        fn()
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

            MODULE:Call( "PlayerConnected", player_entity )
        end

        coroutine_yield( true )
    end )

    if not coroutine_resume( thread ) then
        MODULE:On( "InitPostEntity", function()
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
