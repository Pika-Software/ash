---@class ash.player
local player_lib = {}

---@class ash.Player
local Player = Player

local hook_Run = hook.Run
local bit_band = bit.band
local bit_bor = bit.bor

---@type ash.model
local model_lib = require( "ash.model" )

do

    local MoveData_SetMaxClientSpeed = MoveData.SetMaxClientSpeed
    local MoveData_SetMaxSpeed = MoveData.SetMaxSpeed

    local MoveData_GetMaxClientSpeed = MoveData.GetMaxClientSpeed
    local MoveData_GetMaxSpeed = MoveData.GetMaxSpeed

    local math_max = math.max

    ---@param pl Player
    ---@param mv CMoveData
    hook.Add( "Move", "SpeedController", function( pl, mv )
        local max_speed = math_max( MoveData_GetMaxSpeed( mv ), MoveData_GetMaxClientSpeed( mv ) )
        max_speed = hook_Run( "PlayerSpeed", pl, mv, max_speed ) or 450
        MoveData_SetMaxClientSpeed( mv, max_speed )
        MoveData_SetMaxSpeed( mv, max_speed )

        ---@diagnostic disable-next-line: redundant-parameter, undefined-global
    end, PRE_HOOK )

end

local Player_Alive = Player.Alive

player_lib.isAlive = Player_Alive

--- [SHARED]
---
--- Checks if the player is dead.
---
---@param pl Player
---@return boolean
function player_lib.isDead( pl )
    return not Player_Alive( pl )
end

do

    local Player_IsBot = Player.IsBot

    player_lib.isNextBot = Player_IsBot

    --- [SHARED]
    ---
    --- Checks if the player is uses real game client.
    ---
    ---@param pl Player
    ---@return boolean
    function player_lib.isHuman( pl )
        return not Player_IsBot( pl )
    end

end

do

    local model_precache = model_lib.precache
    local Entity_SetModel = Entity.SetModel

    --- [SERVER]
    ---
    --- Sets the player's model.
    ---
    ---@param pl Player
    ---@param model_path string
    function Player.SetModel( pl, model_path )
        model_path = model_precache( model_path )

        if hook_Run( "PrePlayerChangesModel", pl, model_path ) ~= false then
            Entity_SetModel( pl, hook_Run( "PlayerChangesModel", pl, model_path ) or model_path )
            hook_Run( "PostPlayerChangesModel", pl, model_path )
            return true
        end

        return false
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
    function player_lib.isInitialized( pl )
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
    function player_lib.getHull( pl, on_crouch )
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
    function player_lib.getHullSize( pl, on_crouch )
        local mins, maxs = player_lib.getHull( pl, on_crouch )
        return maxs[ 1 ] - mins[ 1 ], maxs[ 2 ] - mins[ 2 ], maxs[ 3 ] - mins[ 3 ]
    end

end

do

    local MoveData_GetVelocity = MoveData.GetVelocity
    local MoveData_GetButtons = MoveData.GetButtons
    local Entity_IsOnGround = Entity.IsOnGround
    local Vector = Vector

    local player_isAlive = player_lib.isAlive

    ---@type table<Player, Vector>
    local velocities = {}

    --- [SHARED]
    ---
    --- Gets the player's current velocity.
    ---
    ---@param pl Player
    ---@return Vector velocity
    function player_lib.getVelocity( pl )
        return velocities[ pl ]
    end

    setmetatable( velocities, {
        __index = function()
            return Vector( 0, 0, 0 )
        end
    } )

    ---@type table<Player, integer>
    local move_states = {}

    setmetatable( move_states, {
        __index = function()
            return 0
        end
    } )

    --- [SHARED]
    ---
    --- Checks if the player is crouching.
    ---
    ---@param pl Player
    ---@return boolean
    function player_lib.isCrouching( pl )
        return move_states[ pl ] == 0
    end

    --- [SHARED]
    ---
    --- Checks if the player is walking.
    ---
    ---@param pl Player
    ---@return boolean
    function player_lib.isWandering( pl )
        return move_states[ pl ] == 1
    end

    --- [SHARED]
    ---
    --- Checks if the player is running.
    ---
    ---@param pl Player
    ---@return boolean
    function player_lib.isWalking( pl )
        return move_states[ pl ] == 2
    end

    --- [SHARED]
    ---
    --- Checks if the player is sprinting.
    ---
    ---@param pl Player
    ---@return boolean
    function player_lib.isRunning( pl )
        return move_states[ pl ] == 3
    end

    --- [SHARED]
    ---
    --- Checks if the player is falling.
    ---
    ---@param pl Player
    ---@return boolean
    function player_lib.isFalling( pl )
        return move_states[ pl ] == 4
    end

    local move_keys = bit_bor( IN_FORWARD, IN_MOVELEFT, IN_MOVERIGHT, IN_BACK )

    hook.Add( "FinishMove", "Movement", function( pl, mv )
        if player_isAlive( pl ) then
            velocities[ pl ] = MoveData_GetVelocity( mv )

            if Entity_IsOnGround( pl ) then
                local buttons = MoveData_GetButtons( mv )

                if bit_band( buttons, move_keys ) ~= 0 then
                    if bit_band( buttons, IN_DUCK ) ~= 0 then
                        move_states[ pl ] = 0
                    elseif bit_band( buttons, IN_WALK ) ~= 0 then
                        move_states[ pl ] = 1
                    elseif bit_band( buttons, IN_SPEED ) ~= 0 then
                        move_states[ pl ] = 3
                    else
                        move_states[ pl ] = 2
                    end
                end

                return
            end
        end

        move_states[ pl ] = 4

        ---@diagnostic disable-next-line: redundant-parameter, undefined-global
    end, PRE_HOOK )

end

do

    local Entity_GetNWEntity = Entity.GetNWEntity

    --- [SHARED]
    ---
    --- Gets the player's ragdoll.
    ---
    ---@param pl Player
    ---@return Entity ragdoll
    function player_lib.getRagdoll( pl )
        return Entity_GetNWEntity( pl, "m_eRagdoll", NULL )
    end

end

return player_lib
