local Entity_GetNW2Var = Entity.GetNW2Var
local Entity_SetNW2Var = Entity.SetNW2Var

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

---@type table<Player, boolean>
local players_in_vehicle = {}

--- [SHARED]
---
--- Checks if the player is in a vehicle.
---
---@param pl Player
---@return boolean is_in_vehicle
function ash_player.isInVehicle( pl )
    return players_in_vehicle[ pl ]
end

---@type table<Player, integer>
local players_move_type = {}

--- [SHARED]
---
--- Gets the player's move type.
---
---@param pl Player
---@return integer move_type
function ash_player.getMoveType( pl )
    return players_move_type[ pl ]
end

do

    local CurTime = CurTime

    ---@type table<Player, table<integer, number>>
    local press_times = {}

    --- [SHARED]
    ---
    --- Gets the time the player pressed a key.
    ---
    ---@param pl Player
    ---@param key integer
    ---@return number cur_time
    function ash_player.getKeyPressedTime( pl, key )
        return press_times[ pl ][ key ]
    end

    --- [SHARED]
    ---
    --- Gets the time the player pressed a key.
    ---
    ---@param pl Player
    ---@param key integer
    ---@return number seconds_in_use
    function ash_player.getKeyDownTime( pl, key )
        if bit_band( players_keys[ pl ], key ) == 0 then
            return 0
        else
            return CurTime() - press_times[ pl ][ key ]
        end
    end

    ---@type table<Player, table<integer, number>>
    local release_times = {}

    --- [SHARED]
    ---
    --- Gets the time the player released a key.
    ---
    ---@param pl Player
    ---@param key integer
    ---@return number cur_time
    function ash_player.getKeyReleasedTime( pl, key )
        return release_times[ pl ][ key ]
    end

    --- [SHARED]
    ---
    --- Gets the time the player released a key.
    ---
    ---@param pl Player
    ---@param key integer
    ---@return number seconds_in_use
    function ash_player.getKeyUpTime( pl, key )
        if bit_band( players_keys[ pl ], key ) == 0 then
            return 0
        else
            return CurTime() - release_times[ pl ][ key ]
        end
    end

    do

        local key_meta = {
            __index = function( self, key )
                return 0
            end
        }

        local keys_meta = {
            __index = function( self, pl )
                local keys = {}
                setmetatable( keys, key_meta )
                self[ pl ] = keys
                return keys
            end,
            __mode = "k"
        }

        setmetatable( press_times, keys_meta )
        setmetatable( release_times, keys_meta )

    end

    hook.Add( "KeyPress", "InputTimeCapture", function( _, pl, key )
        press_times[ pl ][ key ] = CurTime()
    end, POST_HOOK )

    hook.Add( "KeyRelease", "InputTimeCapture", function( _, pl, key )
        release_times[ pl ][ key ] = CurTime()
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

---@type table<Player, integer>
local players_flags = {}

--- [SHARED]
---
--- Gets the player's flags.
---
---@param pl Player
---@return integer flags
function ash_player.getEntityFlags( pl )
    return players_flags[ pl ]
end

---@type table<Player, boolean>
local players_crouching = {}

--- [SHARED]
---
--- Checks if the player is crouching.
---
---@param pl Player
---@return boolean is_crouching
function ash_player.isCrouching( pl )
    return players_crouching[ pl ]
end

---@type table<Player, boolean>
local players_in_crouching = {}

--- [SHARED]
---
--- Checks if the player is in crouching.
---
---@param pl Player
---@return boolean is_in_crouching
function ash_player.isInCrouchingAnim( pl )
    return players_in_crouching[ pl ]
end

---@type table<Player, boolean>
local players_frozen = {}

--- [SHARED]
---
--- Checks if the player is frozen.
---
---@param pl Player
---@return boolean is_frozen
function ash_player.isFrozen( pl )
    return players_frozen[ pl ]
end

---@type table<Player, boolean>
local players_in_water = {}

--- [SHARED]
---
--- Checks if the player is in water.
---
---@param pl Player
---@return boolean is_in_water
function ash_player.isInWater( pl )
    return players_in_water[ pl ]
end

do

    local Entity_GetMoveType = Entity.GetMoveType
    local Entity_GetSequence = Entity.GetSequence
    local Entity_GetModel = Entity.GetModel
    local Entity_GetFlags = Entity.GetFlags
    local Entity_GetSkin = Entity.GetSkin

    local Player_GetVehicle = Player.GetVehicle
    local Player_InVehicle = Player.InVehicle

    ---@type table<Player, Entity>
    local players_vehicle = {}

    --- [SHARED]
    ---
    --- Gets the player's vehicle.
    ---
    ---@param pl Player
    ---@return Entity vehicle
    function ash_player.getVehicle( pl )
        return players_vehicle[ pl ]
    end

    setmetatable( players_vehicle, {
        __index = function( self, pl )
            local vehicle = Player_GetVehicle( pl )
            self[ pl ] = vehicle
            return vehicle
        end,
        __mode = "k"
    } )

    setmetatable( players_in_vehicle, {
        __index = function( self, pl )
            local in_vehicle = Player_InVehicle( pl )
            self[ pl ] = in_vehicle
            return in_vehicle
        end,
        __mode = "k"
    } )

    setmetatable( players_move_type, {
        __index = function( self, pl )
            local move_type = Entity_GetMoveType( pl )
            self[ pl ] = move_type
            return move_type
        end,
        __mode = "k"
    } )

    setmetatable( players_flags, {
        __index = function( self, pl )
            local flags = Entity_GetFlags( pl )
            self[ pl ] = flags
            return flags
        end,
        __mode = "k"
    } )

    setmetatable( players_on_ground, {
        __index = function( self, pl )
            local is_on_ground = bit_band( players_flags[ pl ], 1 ) ~= 0
            self[ pl ] = is_on_ground
            return is_on_ground
        end,
        __mode = "k"
    } )

    setmetatable( players_crouching, {
        __index = function( self, pl )
            local is_crouching = bit_band( players_flags[ pl ], 2 ) ~= 0
            self[ pl ] = is_crouching
            return is_crouching
        end,
        __mode = "k"
    } )

    setmetatable( players_in_crouching, {
        __index = function( self, pl )
            local is_in_crouching = bit_band( players_flags[ pl ], 4 ) ~= 0
            self[ pl ] = is_in_crouching
            return is_in_crouching
        end,
        __mode = "k"
    } )

    setmetatable( players_frozen, {
        __index = function( self, pl )
            local is_frozen = bit_band( players_flags[ pl ], 64 ) ~= 0
            self[ pl ] = is_frozen
            return is_frozen
        end,
        __mode = "k"
    } )

    setmetatable( players_in_water, {
        __index = function( self, pl )
            local is_in_water = bit_band( players_flags[ pl ], 1024 ) ~= 0
            self[ pl ] = is_in_water
            return is_in_water
        end,
        __mode = "k"
    } )

    ---@type table<Player, string>
    local players_model = {}

    --- [SHARED]
    ---
    --- Gets the player's model.
    ---
    ---@param pl Player
    ---@return string model_path
    function ash_player.getModel( pl )
        return players_model[ pl ]
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
        function ash_player.setModel( pl, model_path )
            model_path = model_precache( model_path )

            if model_path ~= players_model[ pl ] then
                local new_model = hook_Run( "PlayerModelChanged", pl, model_path, players_model[ pl ] ) or model_path

                if new_model ~= model_path then
                    new_model = model_precache( new_model )
                    Entity_SetModel( pl, new_model )
                end

                players_model[ pl ] = new_model
            end
        end

    end

    setmetatable( players_model, {
        __index = function( self, pl )
            local model_path = Entity_GetModel( pl )
            self[ pl ] = model_path
            return model_path
        end,
        __mode = "k"
    } )

    ---@type table<Player, integer>
    local players_skin = {}

    --- [SHARED]
    ---
    --- Gets the player's skin.
    ---
    ---@param pl Player
    ---@return integer skin
    function ash_player.getSkin( pl )
        return players_skin[ pl ]
    end

    setmetatable( players_skin, {
        __index = function( self, pl )
            local skin = Entity_GetSkin( pl )
            self[ pl ] = skin
            return skin
        end,
        __mode = "k"
    } )

    ---@type table<Player, boolean>
    local players_water_jumping = {}

    --- [SHARED]
    ---
    --- Checks if the player is jumping in water.
    ---
    ---@param pl Player
    ---@return boolean is_jumping_in_water
    function ash_player.isJumpingInWater( pl )
        return players_water_jumping[ pl ]
    end

    setmetatable( players_water_jumping, {
        __index = function( self, pl )
            local is_jumping_in_water = bit_band( players_flags[ pl ], 8 ) ~= 0
            self[ pl ] = is_jumping_in_water
            return is_jumping_in_water
        end,
        __mode = "k"
    } )

    ---@type table<Player, boolean>
    local players_in_train = {}

    --- [SHARED]
    ---
    --- Checks if the player is in a train.
    ---
    ---@param pl Player
    ---@return boolean is_in_train
    function ash_player.isInTrain( pl )
        return players_in_train[ pl ]
    end

    setmetatable( players_in_train, {
        __index = function( self, pl )
            local is_in_train = bit_band( players_flags[ pl ], 16 ) ~= 0
            self[ pl ] = is_in_train
            return is_in_train
        end,
        __mode = "k"
    } )

    ---@type table<Player, boolean>
    local players_under_rain = {}

    --- [SHARED]
    ---
    --- Checks if the player is under rain.
    ---
    ---@param pl Player
    ---@return boolean is_under_rain
    function ash_player.isUnderRain( pl )
        return players_under_rain[ pl ]
    end

    setmetatable( players_under_rain, {
        __index = function( self, pl )
            local is_under_rain = bit_band( players_flags[ pl ], 32 ) ~= 0
            self[ pl ] = is_under_rain
            return is_under_rain
        end,
        __mode = "k"
    } )

    ---@type table<Player, integer>
    local player_sequences = {}

    setmetatable( player_sequences, {
        __index = function( self, pl )
            local sequence = Entity_GetSequence( pl )
            self[ pl ] = sequence
            return sequence
        end,
        __mode = "k"
    } )

    ---@param pl Player
    hook.Add( "PlayerThink", "PerformStates", function( pl )
        local in_vehicle = Player_InVehicle( pl )
        if in_vehicle ~= players_in_vehicle[ pl ] then
            players_in_vehicle[ pl ] = in_vehicle
            players_vehicle[ pl ] = Player_GetVehicle( pl )
        end

        local move_type = Entity_GetMoveType( pl )
        if move_type ~= players_move_type[ pl ] then
            local new_type = hook_Run( "PlayerMoveTypeChanged", pl, players_move_type[ pl ], move_type ) or move_type

            if new_type ~= move_type then
                pl:SetMoveType( new_type )
            end

            players_move_type[ pl ] = move_type
        end

        local model_path = Entity_GetModel( pl ) or "models/player/infoplayerstart.mdl"
        if model_path ~= players_model[ pl ] then
            ash_player.setModel( pl, model_path )
        end

        local skin = Entity_GetSkin( pl )
        if skin ~= players_skin[ pl ] then
            local new_skin = hook_Run( "PlayerSkinChanged", pl, skin, players_skin[ pl ] ) or skin

            if new_skin ~= skin then
                pl:SetSkin( new_skin )
            end

            players_skin[ pl ] = new_skin
        end

        local sequence = Entity_GetSequence( pl )
        if sequence ~= player_sequences[ pl ] then
            local new_sequence = hook_Run( "PlayerSequenceChanged", pl, sequence, player_sequences[ pl ] ) or sequence

            if new_sequence ~= sequence then
                pl:ResetSequence( new_sequence )
            end

            player_sequences[ pl ] = new_sequence
        end

        local flags = Entity_GetFlags( pl )
        if flags ~= players_flags[ pl ] then
            local is_on_ground = bit_band( flags, 1 ) ~= 0
            if is_on_ground ~= players_on_ground[ pl ] then
                local new_state = hook_Run( "PlayerGroundStateChanged", pl, is_on_ground ) or is_on_ground

                if new_state ~= is_on_ground then
                    if new_state then
                        flags = bit_bor( flags, 1 )
                        pl:AddFlags( 1 )
                    else
                        flags = bit_band( flags, -2 )
                        pl:RemoveFlags( 1 )
                    end
                end

                players_on_ground[ pl ] = is_on_ground
            end

            local is_crouching = bit_band( flags, 2 ) ~= 0
            if is_crouching ~= players_crouching[ pl ] then
                local new_state = hook_Run( "PlayerCrouchingStateChanged", pl, is_crouching ) or is_crouching

                if new_state ~= is_crouching then
                    if new_state then
                        flags = bit_bor( flags, 2 )
                        pl:AddFlags( 2 )
                    else
                        flags = bit_band( flags, -3 )
                        pl:RemoveFlags( 2 )
                    end
                end

                players_crouching[ pl ] = is_crouching
            end

            local in_crouching = bit_band( flags, 4 ) ~= 0
            if in_crouching ~= players_in_crouching[ pl ] then
                local new_state = hook_Run( "PlayerInCrouchingStateChanged", pl, in_crouching ) or in_crouching

                if new_state ~= in_crouching then
                    if new_state then
                        flags = bit_bor( flags, 4 )
                        pl:AddFlags( 4 )
                    else
                        flags = bit_band( flags, -5 )
                        pl:RemoveFlags( 4 )
                    end
                end

                players_in_crouching[ pl ] = in_crouching
            end

            players_water_jumping[ pl ] = bit_band( flags, 8 ) ~= 0
            players_in_train[ pl ] = bit_band( flags, 16 ) ~= 0

            local is_under_rain = bit_band( flags, 32 ) ~= 0
            if is_under_rain ~= players_under_rain[ pl ] then
                local new_state = hook_Run( "PlayerUnderRainStateChanged", pl, is_under_rain ) or is_under_rain

                if new_state ~= is_under_rain then
                    if new_state then
                        flags = bit_bor( flags, 32 )
                        pl:AddFlags( 32 )
                    else
                        flags = bit_band( flags, -33 )
                        pl:RemoveFlags( 32 )
                    end
                end

                players_under_rain[ pl ] = is_under_rain
            end

            local is_frozen = bit_band( flags, 64 ) ~= 0
            if is_frozen ~= players_frozen[ pl ] then
                local new_state = hook_Run( "PlayerFrozenStateChanged", pl, is_frozen ) or is_frozen

                if new_state ~= is_frozen then
                    if new_state then
                        flags = bit_bor( flags, 64 )
                        pl:AddFlags( 64 )
                    else
                        flags = bit_band( flags, -65 )
                        pl:RemoveFlags( 64 )
                    end
                end

                players_frozen[ pl ] = is_frozen
            end

            local in_water = bit_band( flags, 1024 ) ~= 0
            if in_water ~= players_in_water[ pl ] then
                local new_state = hook_Run( "PlayerInWaterStateChanged", pl, in_water ) or in_water

                if new_state ~= in_water then
                    if new_state then
                        flags = bit_bor( flags, 1024 )
                        pl:AddFlags( 1024 )
                    else
                        flags = bit_band( flags, -1025 )
                        pl:RemoveFlags( 1024 )
                    end
                end

                players_in_water[ pl ] = in_water
            end

            players_flags[ pl ] = flags
        end
    end, PRE_HOOK )

end

do

    local UserCommand_GetMouseWheel = UserCommand.GetMouseWheel
    local UserCommand_GetButtons = UserCommand.GetButtons
    local UserCommand_GetImpulse = UserCommand.GetImpulse
    local UserCommand_GetMouseX = UserCommand.GetMouseX
    local UserCommand_GetMouseY = UserCommand.GetMouseY

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
        if hook_Run( "ShouldPlayerMove", pl, cmd ) == false then
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
        return players_move_type[ pl ] == 8
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
            move_states[ pl ] = hook_Run( "PlayerSelectsMoveState", pl, mv, keys )
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
    hook.Add( "PlayerSelectsMoveState", "DefaultStates", function( arguments, pl, mv, buttons )
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
        max_speed = hook_Run( "PlayerSpeed", pl, players_move_type[ pl ], players_keys[ pl ] ) or 0
        MoveData_SetMaxClientSpeed( mv, max_speed )
        MoveData_SetMaxSpeed( mv, max_speed )

        local suppress_engine = arguments[ 2 ]

        if suppress_engine == nil then
            if players_move_type[ pl ] == 8 then
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

        local string_format = string.format
        local math_snap = math.snap
        local math_min = math.min

        ---@param pl Player
        ---@param wheel number
        hook.Add( "PlayerMouseWheel", "NoclipSpeed", function( pl, wheel )
            if players_move_type[ pl ] == 8 then
                local noclip_speed = Entity_GetNW2Var( pl, "m_fNoclipSpeed", 500 )
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

                noclip_speed = math_min( 10000, math_max( 0, noclip_speed ) )

                Entity_SetNW2Var( pl, "m_fNoclipSpeed", noclip_speed )
                Player_PrintMessage( pl, 4, string_format( "Noclip Speed: %d ups", noclip_speed ) )
            end
        end, PRE_HOOK )

        hook.Add( "PrePlayerSpawn", "NoclipSpeed", function( pl )
            Entity_SetNW2Var( pl, "m_fNoclipSpeed", 500 )
        end, PRE_HOOK )

    end

    if CLIENT then

        hook.Add( "HUDShouldDraw", "NoclipHUD", function( name )
            if name == "CHudWeaponSelection" then
                local pl = ash_player.Entity
                if pl ~= nil and players_move_type[ pl ] == 8 then
                    return false
                end
            end
        end )

    end

    ---@param pl Player
    ---@return number
    hook.Add( "PlayerSpeed", "SpeedController", function( pl, move_type, in_keys )
        if move_type == 8 then -- noclip movement
            return Entity_GetNW2Var( pl, "m_fNoclipSpeed", 500 )
        elseif move_type == 9 then -- ladder movement
            return 250
        elseif move_type ~= 2 then -- not walking
            return 0
        end

        local water_level = entity_getWaterLevel( pl )
        local speed = 0

        if players_on_ground[ pl ] then
            if players_crouching[ pl ] then -- crawling
                if bit_band( in_keys, 262144 ) ~= 0 then -- in walk
                    -- slowly crawling
                    speed = 70
                elseif bit_band( in_keys, 131072 ) ~= 0 then -- in run
                    -- fast crawling
                    speed = 150
                else
                    -- crawling
                    speed = 100
                end
            elseif bit_band( in_keys, 262144 ) ~= 0 then -- in walk
                -- slowly walking
                speed = 130
            elseif bit_band( in_keys, 131072 ) ~= 0 then -- in run
                -- running
                speed = 300
            else
                -- walking
                speed = 180
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

do

    ---@param pl Player
    ---@param sound_data EmitSoundInfo
    ---@return boolean | nil
    hook.Add( "PlayerEmitsSound", "StopDrowning", function( pl, sound_data )
        if entity_getWaterLevel( pl ) < 2 and sound_data.OriginalSoundName == "Player.DrownStart" then
            return false
        end
    end, PRE_HOOK_RETURN )

end

do

    local Entity_IsValid = Entity.IsValid
    local entity_use = ash_entity.use
    local CurTime = CurTime

    ---@type table<Player, number>
    local usage_starts = {}
    gc.setTableRules( usage_starts, true )

    --- [SHARED]
    ---
    --- Returns the amount of time the player has been using an entity.
    ---
    ---@param pl Player
    ---@return number seconds_in_use
    function ash_player.getUsageTime( pl )
        local usage_start = Entity_GetNW2Var( pl, "m_fUseStartTime", 0 )
        if usage_start == 0 then
            return 0
        else
            return CurTime() - usage_start
        end
    end

    hook.Add( "KeyPress", "UsageHandler", function( pl, in_key )
        if in_key == 32 then
            local seleted_entity = hook_Run( "PlayerSelectsUseEntity", pl )
            if seleted_entity == nil or not Entity_IsValid( seleted_entity ) then return end

            entity_use( seleted_entity, pl, pl, hook_Run( "PlayerSelectsUseType", pl, seleted_entity ) )
            Entity_SetNW2Var( pl, "m_eUseEntity", seleted_entity )
            Entity_SetNW2Var( pl, "m_fUseStartTime", CurTime() )

            hook_Run( "PlayerUsedEntity", pl, seleted_entity, true )
        end
    end, PRE_HOOK )

    hook.Add( "KeyRelease", "UsageHandler", function( pl, in_key )
        if in_key == 32 then
            local seleted_entity = Entity_GetNW2Var( pl, "m_eUseEntity" )

            Entity_SetNW2Var( pl, "m_fUseStartTime", 0 )
            Entity_SetNW2Var( pl, "m_eUseEntity", nil )

            if seleted_entity ~= nil and Entity_IsValid( seleted_entity ) then
                hook_Run( "PlayerUsedEntity", pl, seleted_entity, false )
            end
        end
    end, PRE_HOOK )

end

-- hook.Add( "FindUseEntity", "UsageControl", debug.fempty, PRE_HOOK_RETURN )
hook.Add( "PlayerUse", "UsageControl", function( pl, entity )
    return false
end, PRE_HOOK_RETURN )

include( "animator.lua", ash_player )

return ash_player
