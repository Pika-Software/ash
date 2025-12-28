---@type ash.model
local ash_model = require( "ash.model" )

---@type ash.entity
local ash_entity = require( "ash.entity" )
local entity_getWaterLevel = ash_entity.getWaterLevel

---@class ash.player
local ash_player = {
    BitCount = math.ceil( math.log( 1 + game.MaxPlayers() ) / math.log( 2 ) )
}

---@class ash.Player
local Player = Player

---@class ash.Vector
local Vector = Vector

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

    local Entity_GetModel = Entity.GetModel

    --- [SHARED]
    ---
    --- Gets the player's model.
    ---
    ---@param pl Player
    ---@return string model_path
    function ash_player.getModel( pl )
        return Entity_GetModel( pl ) or "models/player/infoplayerstart.mdl"
    end

end

ash_player.setModel = Entity.SetModel

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

---@type table<Player, integer>
local players_keys = {}

setmetatable( players_keys, {
    __index = function()
        return 0
    end,
    __mode = "k"
} )

--- [SHARED]
---
--- Gets the player's players_keys.
---
---@param pl Player
---@return integer players_keys
function ash_player.getKeys( pl )
    return players_keys[ pl ]
end

--- [SHARED]
---
--- Checks if the player is pressing a key.
---
---@param pl Player
---@param key integer
---@return boolean
function ash_player.isKeyPressed( pl, key )
    return bit_band( players_keys[ pl ], key ) ~= 0
end

---@type table<Player, integer>
local move_types = {}

--- [SHARED]
---
--- Gets the player's move type.
---
---@param pl Player
---@return integer move_type
function ash_player.getMoveType( pl )
    return move_types[ pl ]
end

do

    local CurTime = CurTime

    ---@type table<Player, table<integer, number>>
    local players_key_times = {}

    setmetatable( players_key_times, {
        __index = function( self, pl )
            local key_times = {}
            self[ pl ] = key_times
            return key_times
        end,
        __mode = "k"
    } )

    --- [SHARED]
    ---
    --- Gets the player's last key press time.
    ---
    ---@param pl Player
    ---@param key integer
    ---@return number cur_time
    function ash_player.getKeyLastPressed( pl, key )
        return players_key_times[ pl ][ key ] or 0
    end

    hook.Add( "KeyPress", "InputTimeCapture", function( _, pl, key )
        players_key_times[ pl ][ key ] = CurTime()
    end, POST_HOOK )

end

---@type table<Player, boolean>
local players_on_ground = {}

--- [SHARED]
---
--- Checks if the player is on the ground.
---
---@param pl Player
---@return boolean is_on_ground
function ash_player.isOnGround( pl )
    return players_on_ground[ pl ]
end

do

    local UserCommand_GetMouseWheel = UserCommand.GetMouseWheel
    local UserCommand_GetButtons = UserCommand.GetButtons
    local UserCommand_GetImpulse = UserCommand.GetImpulse
    local UserCommand_GetMouseX = UserCommand.GetMouseX
    local UserCommand_GetMouseY = UserCommand.GetMouseY

    local Entity_GetMoveType = Entity.GetMoveType
    local Entity_IsOnGround = Entity.IsOnGround

    setmetatable( move_types, {
        __index = function( self, pl )
            return Entity_GetMoveType( pl )
        end,
        __newindex = function (t, k, v)

        end,
        __mode = "k"
    } )

    setmetatable( players_on_ground, {
        __index = function( self, pl )
            return Entity_IsOnGround( pl )
        end,
        __mode = "k"
    } )

    ---@param pl Player
    ---@param cmd CUserCmd
    hook.Add( "StartCommand", "InputCapture", function( pl, cmd )
        players_keys[ pl ] = UserCommand_GetButtons( cmd )

        local mouse_wheel = UserCommand_GetMouseWheel( cmd )
        if mouse_wheel ~= 0 then
            hook_Run( "PlayerMouseWheel", pl, mouse_wheel )
        end

        local impulse = UserCommand_GetImpulse( cmd )
        if impulse ~= 0 then
            hook_Run( "PlayerImpulse", pl, impulse )
        end

        local x, y = UserCommand_GetMouseX( cmd ), UserCommand_GetMouseY( cmd )
        if x ~= 0 or y ~= 0 then
            hook_Run( "PlayerMouse", pl, x, y )
        end

        local is_on_ground = Entity_IsOnGround( pl )
        if is_on_ground ~= players_on_ground[ pl ] then
            players_on_ground[ pl ] = is_on_ground
            hook_Run( "PlayerGroundStateChanged", pl, is_on_ground )
        end

        local move_type = Entity_GetMoveType( pl )
        if move_type ~= move_types[ pl ] then
            hook_Run( "PlayerMoveTypeChanged", pl, move_types[ pl ], move_type )
            move_types[ pl ] = move_type
        end
    end, PRE_HOOK )

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

    local Entity_GetFlags = Entity.GetFlags

    local math_max = math.max

    local Angle_Forward = Angle.Forward
    local Angle_Right = Angle.Right
    local Angle_Up = Angle.Up

    local Vector_Add = Vector.Add

    --- [SHARED]
    ---
    --- Checks if the player is in noclip.
    ---
    ---@param pl Player
    ---@return boolean is_in_noclip
    function ash_player.inInNoclip( pl )
        return move_types[ pl ] == 8
    end

    ---@type table<Player, Vector>
    local directions = {}

    setmetatable( directions, {
        __index = function( self, pl )
            return Vector( 1, 0, 0 )
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
        move_angles[ 1 ], move_angles[ 3 ] = 0, 0

        local direction = Vector( 0, 0, 0 )
        local keys = players_keys[ pl ]

        if bit_band( keys, 2 ) == 0 then -- is not up
            if bit_band( keys, 4 ) ~= 0 then -- is down
                Vector_Add( direction, -Angle_Up( move_angles ) )
            end
        elseif bit_band( keys, 4 ) == 0 then -- is not down and is up
            Vector_Add( direction, Angle_Up( move_angles ) )
        end

        if bit_band( keys, 8 ) == 0 then -- is not forward
            if bit_band( keys, 16 ) ~= 0 then -- is backward
                Vector_Add( direction, -Angle_Forward( move_angles ) )
            end
        elseif bit_band( keys, 16 ) == 0 then -- is not backward and is forward
            Vector_Add( direction, Angle_Forward( move_angles ) )
        end

        if bit_band( keys, 1024 ) == 0 then -- is not right
            if bit_band( keys, 512 ) ~= 0 then -- is left
                Vector_Add( direction, -Angle_Right( move_angles ) )
            end
        elseif bit_band( keys, 512 ) == 0 then -- is not left and is right
            Vector_Add( direction, Angle_Right( move_angles ) )
        end

        directions[ pl ] = direction

        if Player_Alive( pl ) then
            move_states[ pl ] = hook_Run( "PlayerSelectMoveState", pl, mv, keys )
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
            if players_on_ground[ pl ] then
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
            elseif entity_getWaterLevel( pl ) ~= 0 then
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
    hook.Add( "Move", "SpeedController", function( arguments, pl, mv )
        local max_speed = math_max( MoveData_GetMaxSpeed( mv ), MoveData_GetMaxClientSpeed( mv ) )
        max_speed = hook_Run( "PlayerSpeed", pl, move_types[ pl ], players_keys[ pl ] ) or 0
        MoveData_SetMaxClientSpeed( mv, max_speed )
        MoveData_SetMaxSpeed( mv, max_speed )

        local suppress_engine = arguments[ 2 ]

        if suppress_engine == nil then
            if move_types[ pl ] == 8 then
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

    if SERVER then

        local Player_PrintMessage = Player.PrintMessage

        local Entity_GetNW2Float = Entity.GetNW2Float
        local Entity_SetNW2Float = Entity.SetNW2Float

        local string_format = string.format
        local math_snap = math.snap

        ---@param pl Player
        ---@param wheel number
        hook.Add( "PlayerMouseWheel", "NoclipSpeed", function( pl, wheel )
            if move_types[ pl ] == 8 then
                local noclip_speed = Entity_GetNW2Float( pl, "m_fNoclipSpeed", 500 )
                local in_keys = players_keys[ pl ]

                if bit_band( in_keys, 262144 ) ~= 0 then
                    noclip_speed = noclip_speed + wheel
                elseif bit_band( in_keys, 131072 ) ~= 0 then
                    noclip_speed = math_snap( noclip_speed + wheel * 500, 100 )
                elseif wheel > 0 then
                    if noclip_speed >= 100 then
                        noclip_speed = math_snap( noclip_speed + wheel * 100, 100 )
                    elseif noclip_speed >= 10 then
                        noclip_speed = math_snap( noclip_speed + wheel * 10, 10 )
                    else
                        noclip_speed = noclip_speed + wheel
                    end
                elseif noclip_speed > 100 then
                    noclip_speed = math_snap( noclip_speed + wheel * 100, 100 )
                elseif noclip_speed > 10 then
                    noclip_speed = math_snap( noclip_speed + wheel * 10, 10 )
                else
                    noclip_speed = noclip_speed + wheel
                end

                noclip_speed = math_max( 0, noclip_speed )

                Entity_SetNW2Float( pl, "m_fNoclipSpeed", noclip_speed )
                Player_PrintMessage( pl, 4, string_format( "Noclip Speed: %d ups", noclip_speed ) )
            end
        end, PRE_HOOK )

        hook.Add( "PrePlayerSpawn", "NoclipSpeed", function( pl )
            Entity_SetNW2Float( pl, "m_fNoclipSpeed", 500 )
        end, PRE_HOOK )

    end

    if CLIENT then

        hook.Add( "HUDShouldDraw", "NoclipHUD", function( name )
            if name == "CHudWeaponSelection" then
                local pl = ash_player.Entity
                if pl ~= nil and move_types[ pl ] == 8 then
                    return false
                end
            end
        end )

    end

    local Entity_GetNW2Float = Entity.GetNW2Float

    ---@param pl Player
    ---@return number
    hook.Add( "PlayerSpeed", "SpeedController", function( pl, move_type, in_keys )
        if move_type == 8 then -- noclip movement
            return Entity_GetNW2Float( pl, "m_fNoclipSpeed", 500 )
        elseif move_type == 9 then -- ladder movement
            return 250
        elseif move_type ~= 2 then -- not walking
            return 0
        end

        local water_level = entity_getWaterLevel( pl )
        local flags = Entity_GetFlags( pl )
        local speed = 0

        if players_on_ground[ pl ] then
            if bit_band( flags, 4 ) == 0 then -- not crawling
                if bit_band( in_keys, 262144 ) ~= 0 then -- in walk
                    -- slowly walking
                    speed = 130
                elseif bit_band( in_keys, 131072 ) ~= 0 then -- in run
                    -- running
                    speed = 300
                else
                    -- walking
                    speed = 180
                end
            elseif bit_band( in_keys, 262144 ) ~= 0 then -- in walk
                -- slowly crawling
                speed = 70
            elseif bit_band( in_keys, 131072 ) ~= 0 then -- in run
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
        elseif bit_band( in_keys, 262144 ) ~= 0 then -- in walk
            -- slowly swimming
            speed = 80
        elseif bit_band( in_keys, 131072 ) ~= 0 then -- in run
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

        return speed
    end )

end

return ash_player
