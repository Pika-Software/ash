---@class ash.player
local player = include( "shared.lua" )

local player_isInitialized = player.isInitialized

local Entity_SetNW2Bool = Entity.SetNW2Bool

MODULE.Networks = {
    "ash.player"
}

MODULE.ClientFiles = {
    "shared.lua"
}

do

    local function player_sync( pl )
        if player_isInitialized( pl ) then
            net.Start( "ash.player" )
            net.WriteUInt( 0, 8 )

            net.WritePlayer( pl )

            local mins, maxs = pl:GetHull()
            net.WriteVector( mins )
            net.WriteVector( maxs )

            local mins_ducked, maxs_ducked = pl:GetHullDuck()
            net.WriteVector( mins_ducked )
            net.WriteVector( maxs_ducked )

            net.Broadcast()
        end
    end

    MODULE:On( "PlayerConnected", player_sync )
    MODULE:On( "PlayerSpawn", player_sync )

end

do

    ---@type table<integer, fun( pl: Player, len: integer )>
    local util_actions = {
        -- hull sync
        [ 0 ] = function( pl )
            if player_isInitialized( pl ) then
                return
            end

            Entity_SetNW2Bool( pl, "m_bConnected", true )
            MODULE:Call( "PlayerConnected", pl )
        end
    }

    net.Receive( "ash.player", function( len, pl )
        local fn = util_actions[ net.ReadUInt( 8 ) ]
        if fn == nil then return end
        fn( pl, len )
    end )

end

return player
