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

return player
