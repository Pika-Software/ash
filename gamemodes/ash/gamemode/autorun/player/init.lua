MODULE.Networks = {
    "player"
}

MODULE.ClientFiles = {
    "shared.lua"
}

---@class ash.player
local player = include( "shared.lua" )
local player_isInitialized = player.isInitialized

---@type dreamwork.std.math
local math = require( "dreamwork.math" )
local math_floor = math.floor

hook.Add( "PlayerInitialized", "HullSync", function( pl )
    if player_isInitialized( pl ) then
        net.Start( "player" )

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

    net.Receive( "player", function( len, pl )
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
    function player.setHull( pl, on_crouch, mins, maxs )
        if on_crouch then
            Player_SetHullDuck( pl, mins, maxs )
        else
            Player_SetHull( pl, mins, maxs )
        end

        net.Start( "player" )
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
    ---@param height integer
    ---@param depth integer
    function player.setHullSize( pl, on_crouch, width, height, depth )
        local width_half, depth_half = math_floor( width * 0.5 ), math_floor( depth * 0.5 )
        player.setHull( pl, on_crouch, Vector( -width_half, -depth_half, 0 ), Vector( width_half, depth_half, height ) )
    end

end

return player
