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

    local UserCommand_ClearMovement = UserCommand.ClearMovement
    local UserCommand_ClearButtons = UserCommand.ClearButtons
    local UserCommand_SetImpulse = UserCommand.SetImpulse

    ---@param pl Player
    ---@param cmd CUserCmd
    ---@diagnostic disable-next-line: redundant-parameter
    hook.Add( "StartCommand", "MovementController", function( pl, cmd )
        if hook_Run( "CanPlayerMove", pl, cmd ) == false then
            UserCommand_SetImpulse( cmd, 0 )
            UserCommand_ClearMovement( cmd )
            UserCommand_ClearButtons( cmd )
        end
    end, POST_HOOK )

end

do

    local MoveData_SetMaxClientSpeed = MoveData.SetMaxClientSpeed
    local MoveData_SetMaxSpeed = MoveData.SetMaxSpeed

    local MoveData_GetMaxClientSpeed = MoveData.GetMaxClientSpeed
    local MoveData_GetMaxSpeed = MoveData.GetMaxSpeed

    local math_max = math.max

    ---@param pl Player
    ---@param mv CMoveData
    ---@diagnostic disable-next-line: redundant-parameter
    hook.Add( "Move", "SpeedController", function( _, pl, mv )
        local max_speed = math_max( MoveData_GetMaxSpeed( mv ), MoveData_GetMaxClientSpeed( mv ) )
        max_speed = hook_Run( "PlayerSpeed", pl, mv, max_speed ) or 450
        MoveData_SetMaxClientSpeed( mv, max_speed )
        MoveData_SetMaxSpeed( mv, max_speed )
    end, POST_HOOK )

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
    local Entity_WaterLevel = Entity.WaterLevel
    local Vector = Vector

    local player_isAlive = player_lib.isAlive

    -- ---@type table<Player, Vector>
    -- local velocities = {}

    -- --- [SHARED]
    -- ---
    -- --- Gets the player's current velocity.
    -- ---
    -- ---@param pl Player
    -- ---@return Vector velocity
    -- function player_lib.getVelocity( pl )
    --     return velocities[ pl ]
    -- end

    -- setmetatable( velocities, {
    --     __index = function()
    --         return Vector( 0, 0, 0 )
    --     end,
    --     __mode = "k"
    -- } )

    ---@alias ash.player.MoveState "standing" | "crouching" | "jumping" | "falling" | "swimming" | "wandering" | "running" | "walking" | string

    ---@type table<Player, ash.player.MoveState>
    local move_states = {}

    setmetatable( move_states, {
        __index = function()
            return "standing"
        end,
        __mode = "k"
    } )

    --- [SHARED]
    ---
    --- Gets the player's current move state.
    ---
    ---@param pl Player
    ---@return ash.player.MoveState move_state
    function player_lib.getMoveState( pl )
        return move_states[ pl ]
    end

    hook.Add( "FinishMove", "MovementController", function( pl, mv )
        if player_isAlive( pl ) then
            -- velocities[ pl ] = MoveData_GetVelocity( mv )
            move_states[ pl ] = hook_Run( "PlayerSelectMoveState", pl, mv )
        end
    end, PRE_HOOK )

    local IN_JUMP = IN_JUMP
    local IN_DUCK = IN_DUCK
    local IN_WALK = IN_WALK
    local IN_SPEED = IN_SPEED

    local IN_MOVE = bit_bor( IN_FORWARD, IN_MOVELEFT, IN_MOVERIGHT, IN_BACK )

    ---@param arguments string[]
    ---@param pl Player
    ---@param mv CMoveData
    hook.Add( "PlayerSelectMoveState", "DefaultStates", function( arguments, pl, mv )
        ---@type ash.player.MoveState | nil
        local move_state = arguments[ 1 ]

        if move_state == nil then
            if Entity_IsOnGround( pl ) then
                local buttons = MoveData_GetButtons( mv )

                if bit_band( buttons, IN_DUCK ) ~= 0 then
                    move_state = "crouching"
                elseif bit_band( buttons, IN_JUMP ) ~= 0 then
                    move_state = "jumping"
                elseif bit_band( buttons, IN_MOVE ) ~= 0 then
                    if bit_band( buttons, IN_WALK ) ~= 0 then
                        move_state = "wandering"
                    elseif bit_band( buttons, IN_SPEED ) ~= 0 then
                        move_state = "running"
                    else
                        move_state = "walking"
                    end
                else
                    move_state = "standing"
                end
            elseif Entity_WaterLevel( pl ) ~= 0 then
                move_state = "swimming"
            else
                move_state = "falling"
            end
        end

        return move_state
    end, POST_HOOK_RETURN )

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
