---@class ash.player
local player = {}

---@class ash.Player
local Player = Player

do

    local Player_Alive = Player.Alive

    player.isAlive = Player_Alive

    --- [SHARED]
    ---
    --- Checks if the player is dead.
    ---
    ---@param pl Player
    ---@return boolean
    function player.isDead( pl )
        return not Player_Alive( pl )
    end

end

do

    local Player_IsBot = Player.IsBot

    player.isNextBot = Player_IsBot

    --- [SHARED]
    ---
    --- Checks if the player is uses real game client.
    ---
    ---@param pl Player
    ---@return boolean
    function player.isHuman( pl )
        return not Player_IsBot( pl )
    end

end

do

    local Entity_GetNWBool = Entity.GetNWBool

    --- [SHARED]
    ---
    --- Checks if the player is fully initialized.
    ---
    --- Aka the player has been spawned (player entity available) and can receive network messages.
    ---
    ---@param pl Player
    ---@return boolean
    function player.isInitialized( pl )
        return Entity_GetNWBool( pl, "m_bInitialized", false )
    end

end

do

    local Player_GetHullDuck = Player.GetHullDuck
    local Player_GetHull = Player.GetHull

    --- [SHARED]
    ---
    --- Gets the player's hull.
    ---
    ---@param pl Player
    ---@param on_crouch boolean
    ---@return Vector mins
    ---@return Vector maxs
    function player.getHull( pl, on_crouch )
        return ( on_crouch and Player_GetHullDuck or Player_GetHull )( pl )
    end

    --- [SHARED]
    ---
    --- Gets the player's hull size.
    ---
    ---@param pl Player
    ---@param on_crouch boolean
    ---@return integer width
    ---@return integer depth
    ---@return integer height
    function player.getHullSize( pl, on_crouch )
        local mins, maxs = player.getHull( pl, on_crouch )
        return maxs[ 1 ] - mins[ 1 ], maxs[ 2 ] - mins[ 2 ], maxs[ 3 ] - mins[ 3 ]
    end

end

return player
