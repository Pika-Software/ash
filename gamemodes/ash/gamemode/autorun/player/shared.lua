---@type ash.model
local ash_model = require( "ash.model" )

---@class ash.player
local ash_player = {
    BitCount = math.ceil( math.log( 1 + game.MaxPlayers() ) / math.log( 2 ) )
}

---@class ash.Player
local Player = Player

---@class ash.Vector
local Vector = Vector

local MoveData_GetButtons = MoveData.GetButtons
local hook_Run = hook.Run
local bit_band = bit.band
local bit_bor = bit.bor

local tick_interval = engine.TickInterval()

local Player_Alive = Player.Alive

ash_player.isAlive = Player_Alive

--- [SHARED]
---
--- Checks if the player is dead.
---
---@param pl Player
---@return boolean
function ash_player.isDead( pl )
    return not Player_Alive( pl )
end

do

    local Player_IsBot = Player.IsBot

    ash_player.isNextBot = Player_IsBot

    --- [SHARED]
    ---
    --- Checks if the player is uses real game client.
    ---
    ---@param pl Player
    ---@return boolean
    function ash_player.isHuman( pl )
        return not Player_IsBot( pl )
    end

end

do

    local model_precache = ash_model.precache
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
    function ash_player.isInitialized( pl )
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
    function ash_player.getHull( pl, on_crouch )
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
    function ash_player.getHullSize( pl, on_crouch )
        local mins, maxs = ash_player.getHull( pl, on_crouch )
        return maxs[ 1 ] - mins[ 1 ], maxs[ 2 ] - mins[ 2 ], maxs[ 3 ] - mins[ 3 ]
    end

end

do

    local Entity_GetNWEntity = Entity.GetNWEntity

    --- [SHARED]
    ---
    --- Gets the player's ragdoll.
    ---
    ---@param pl Player
    ---@return Entity ragdoll
    function ash_player.getRagdoll( pl )
        return Entity_GetNWEntity( pl, "m_eRagdoll", NULL )
    end

end

do

    local UserCommand_ClearMovement = UserCommand.ClearMovement
    local UserCommand_ClearButtons = UserCommand.ClearButtons
    local UserCommand_SetImpulse = UserCommand.SetImpulse

    ---@param pl Player
    ---@param cmd CUserCmd
    ---@diagnostic disable-next-line: redundant-parameter
    hook.Add( "StartCommand", "MovementControl", function( _, pl, cmd )
        if hook_Run( "CanPlayerMove", pl, cmd ) == false then
            UserCommand_SetImpulse( cmd, 0 )
            UserCommand_ClearMovement( cmd )
            UserCommand_ClearButtons( cmd )
        end
    end, POST_HOOK )

end

do

    local MoveData_GetMaxClientSpeed = MoveData.GetMaxClientSpeed
    local MoveData_SetMaxClientSpeed = MoveData.SetMaxClientSpeed

    local MoveData_GetMaxSpeed = MoveData.GetMaxSpeed
    local MoveData_SetMaxSpeed = MoveData.SetMaxSpeed

    local MoveData_GetVelocity = MoveData.GetVelocity
    local MoveData_SetVelocity = MoveData.SetVelocity

    local MoveData_GetMoveAngles = MoveData.GetMoveAngles

    local MoveData_GetOrigin = MoveData.GetOrigin
    local MoveData_SetOrigin = MoveData.SetOrigin

    local Entity_GetMoveType = Entity.GetMoveType
    local Entity_IsOnGround = Entity.IsOnGround
    local Entity_WaterLevel = Entity.WaterLevel
    local Entity_GetFlags = Entity.GetFlags

    local math_max = math.max

    local Angle_Forward = Angle.Forward
    local Angle_Right = Angle.Right
    local Angle_Up = Angle.Up

    local Vector_Add = Vector.Add

    ---@type table<Player, Vector>
    local directions = {}

    setmetatable( directions, {
        __index = function( self, pl )
            return Vector( 0, 0, 0 )
        end,
        __mode = "k"
    } )

    --- [SHARED]
    ---
    --- Gets the player's direction.
    ---
    ---@param pl Player
    ---@return Vector direction
    function ash_player.getDirection( pl )
        return directions[ pl ]
    end

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
    function ash_player.getMoveState( pl )
        return move_states[ pl ]
    end

    ---@param pl Player
    ---@param mv CMoveData
    hook.Add( "FinishMove", "MovementCapture", function( _, pl, mv )
        local move_angles = MoveData_GetMoveAngles( mv )
        local buttons = MoveData_GetButtons( mv )
        local direction = Vector( 0, 0, 0 )

        if bit_band( buttons, 2 ) == 0 then -- is not up
            if bit_band( buttons, 4 ) ~= 0 then -- is down
                direction = direction - Angle_Up( move_angles )
            end
        elseif bit_band( buttons, 4 ) == 0 then -- is not down and is up
            direction = direction + Angle_Up( move_angles )
        end

        if bit_band( buttons, 8 ) == 0 then -- is not forward
            if bit_band( buttons, 16 ) ~= 0 then -- is backward
                direction = direction - Angle_Forward( move_angles )
            end
        elseif bit_band( buttons, 16 ) == 0 then -- is not backward and is forward
            direction = direction + Angle_Forward( move_angles )
        end

        if bit_band( buttons, 1024 ) == 0 then -- is not right
            if bit_band( buttons, 512 ) ~= 0 then -- is left
                direction = direction - Angle_Right( move_angles )
            end
        elseif bit_band( buttons, 512 ) == 0 then -- is not left and is right
            direction = direction + Angle_Right( move_angles )
        end

        directions[ pl ] = direction

        if Player_Alive( pl ) then
            move_states[ pl ] = hook_Run( "PlayerSelectMoveState", pl, mv, buttons )
        else
            move_states[ pl ] = "standing"
        end
    end, POST_HOOK )

    local IN_MOVE = bit_bor( IN_FORWARD, IN_MOVELEFT, IN_MOVERIGHT, IN_BACK )

    ---@param arguments string[]
    ---@param pl Player
    ---@param mv CMoveData
    ---@param buttons integer
    ---@return string
    hook.Add( "PlayerSelectMoveState", "DefaultStates", function( arguments, pl, mv, buttons )
        ---@type ash.player.MoveState | nil
        local move_state = arguments[ 2 ]

        if move_state == nil then
            if Entity_IsOnGround( pl ) then
                if bit_band( buttons, 4 ) ~= 0 then -- in duck
                    move_state = "crouching"
                elseif bit_band( buttons, 2 ) ~= 0 then -- in jump
                    move_state = "jumping"
                elseif bit_band( buttons, IN_MOVE ) ~= 0 then
                    if bit_band( buttons, 262144 ) ~= 0 then -- in walk
                        move_state = "wandering"
                    elseif bit_band( buttons, 131072 ) ~= 0 then -- in run
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

    ---@param pl Player
    ---@param mv CMoveData
    ---@diagnostic disable-next-line: redundant-parameter
    hook.Add( "Move", "SpeedControl", function( arguments, pl, mv )
        local max_speed = math_max( MoveData_GetMaxSpeed( mv ), MoveData_GetMaxClientSpeed( mv ) )
        max_speed = hook_Run( "PlayerSpeed", pl, mv, max_speed ) or 0
        MoveData_SetMaxClientSpeed( mv, max_speed )
        MoveData_SetMaxSpeed( mv, max_speed )

        local suppress_engine = arguments[ 2 ]

        if suppress_engine == nil then
            if Entity_GetMoveType( pl ) == 8 then
                local origin = MoveData_GetOrigin( mv )
                local velocity = ( ( directions[ pl ] * max_speed ) - MoveData_GetVelocity( mv ) ) * tick_interval

                Vector_Add( origin, velocity )
                MoveData_SetOrigin( mv, origin )
                MoveData_SetVelocity( mv, velocity )

                return true
            end

            return
        end

        return suppress_engine
    end, POST_HOOK_RETURN )

    ---@param pl Player
    ---@param mv CMoveData
    ---@param max_speed number
    ---@return number
    hook.Add( "PlayerSpeed", "SpeedController", function( arguments, pl, mv, max_speed )
        local speed = arguments[ 2 ]

        if speed == nil then
            local move_type = Entity_GetMoveType( pl )
            local buttons = MoveData_GetButtons( mv )

            if move_type == 8 then -- noclip movement
                if bit_band( buttons, 262144 ) ~= 0 then -- in walk
                    -- slowly walking
                    return 250
                elseif bit_band( buttons, 131072 ) ~= 0 then -- in run
                    -- running
                    return 1000
                end

                -- walking
                return 500
            elseif move_type == 9 then -- ladder movement
                return 250
            elseif move_type ~= 2 then -- not walking
                return 0
            end

            local water_level = Entity_WaterLevel( pl )
            local flags = Entity_GetFlags( pl )

            if Entity_IsOnGround( pl ) then
                if bit_band( flags, 4 ) == 0 then -- not crawling
                    if bit_band( buttons, 262144 ) ~= 0 then -- in walk
                        -- slowly walking
                        speed = 130
                    elseif bit_band( buttons, 131072 ) ~= 0 then -- in run
                        -- running
                        speed = 300
                    else
                        -- walking
                        speed = 180
                    end
                elseif bit_band( buttons, 262144 ) ~= 0 then -- in walk
                    -- slowly crawling
                    speed = 70
                elseif bit_band( buttons, 131072 ) ~= 0 then -- in run
                    -- fast crawling
                    speed = 150
                else
                    -- crawling
                    speed = 100
                end

                if water_level == 3 then
                    -- walking underwater
                    speed = speed * 0.25
                elseif water_level == 2 then
                    -- walking waist-deep in water
                    speed = speed * 0.5
                elseif water_level == 1 then
                    -- walking in shallow water
                    speed = speed * 0.75
                end
            elseif water_level == 0 then
                -- freefalling
                return 10
            else

                if bit_band( buttons, 262144 ) ~= 0 then -- in walk
                    -- slowly swimming
                    speed = 80
                elseif bit_band( buttons, 131072 ) ~= 0 then -- in run
                    -- fast swimming
                    speed = 250
                else
                    -- swimming
                    speed = 150
                end

                if water_level == 3 then
                    -- swimming underwater
                    speed = speed * 0.5 + 50
                elseif water_level == 2 then
                    -- surface swimming
                    speed = speed + 20
                end

            end
        end

        return speed
    end, POST_HOOK_RETURN )

end

return ash_player
