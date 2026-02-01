local Entity_GetNW2Var = Entity.GetNW2Var
local Entity_SetNW2Var = Entity.SetNW2Var
local CurTime = CurTime

---@type ash.model
local ash_model = require( "ash.model" )

---@type ash.entity
local ash_entity = require( "ash.entity" )
local entity_getWaterLevel = ash_entity.getWaterLevel

---@type ash.trace
local ash_trace = require( "ash.trace" )
local trace_cast = ash_trace.cast

---@class ash.player
local ash_player = {
    BitCount = math.ceil( math.log( 1 + game.MaxPlayers() ) / math.log( 2 ) )
}

---@class ash.Player
local Player = Player

---@class ash.Vector
local Vector = Vector

local rawget = rawget

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

---@param entity Entity
---@param key string
---@param old_value any
---@param value any
hook.Add( "ash.entity.NW2Changed", "NW2Handler", function( entity, key, old_value, value )
    if not entity:IsPlayer() then return end
    hook_Run( "PlayerNW2Changed", entity, key, old_value, value )
end, PRE_HOOK )

---@type table<Player, integer>
local players_keys = {}

do

    ---@type table<Player, integer>
    local keys_cache = {}

    setmetatable( keys_cache, {
        __index = function( self, pl )
            return Entity_GetNW2Var( pl, "m_iPlayerKeys", 0 )
        end,
        __mode = "k"
    } )

    setmetatable( players_keys, {
        __index = keys_cache,
        __newindex = function( self, pl, keys )
            if keys_cache[ pl ] == keys then return end
            Entity_SetNW2Var( pl, "m_iPlayerKeys", keys )
            keys_cache[ pl ] = keys
        end
    } )

end

--- [SHARED]
---
--- Gets the player's players_keys.
---
---@param pl Player
---@return integer players_keys
function ash_player.getKeys( pl )
    return players_keys[ pl ]
end

---@type table<Player, table<integer, boolean>>
local players_key_states = {}

setmetatable( players_key_states, {
    __index = function( self, pl )
        local keys = {}
        self[ pl ] = keys
        return keys
    end,
    __mode = "k"
} )

--- [SHARED]
---
--- Checks if the player is pressing a key.
---
---@param pl Player
---@param in_key integer
function ash_player.getKeyState( pl, in_key )
    return players_key_states[ pl ][ in_key ] == true
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

    ---@type table<Player, table<integer, number>>
    local press_times = {}

    ---@type table<Player, table<integer, number>>
    local release_times = {}

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
    --- Gets the time the player pressed a key.
    ---
    ---@param pl Player
    ---@param key integer
    ---@return number seconds_in_use
    function ash_player.getKeyDownTime( pl, key )
        return CurTime() - press_times[ pl ][ key ]
    end

    --- [SHARED]
    ---
    --- Gets the time the player released a key.
    ---
    ---@param pl Player
    ---@param key integer
    ---@return number seconds_in_use
    function ash_player.getKeyUpTime( pl, key )
        return CurTime() - release_times[ pl ][ key ]
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

    hook.Add( "ash.player.Key", "InputTimeCapture", function( _, pl, in_key, is_pressed )
        if is_pressed then
            press_times[ pl ][ in_key ] = CurTime()
        else
            release_times[ pl ][ in_key ] = CurTime()
        end
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
local players_crouching_anim = {}

--- [SHARED]
---
--- Checks if the player is in crouching.
---
---@param pl Player
---@return boolean is_in_crouching
function ash_player.isInCrouchingAnim( pl )
    return players_crouching_anim[ pl ]
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

---@type table<Player, integer>
local players_sequence = {}

--- [SHARED]
---
--- Gets the player's sequence.
---
---@param pl Player
---@return integer sequence
function ash_player.getSequence( pl )
    return players_sequence[ pl ]
end

do

    local Entity_GetMoveType = Entity.GetMoveType
    local Entity_GetSequence = Entity.GetSequence
    local Entity_GetModel = Entity.GetModel
    local Entity_GetFlags = Entity.GetFlags
    local Entity_GetSkin = Entity.GetSkin

    local Player_GetVehicle = Player.GetVehicle
    local Player_InVehicle = Player.InVehicle
    local Player_IsTyping = Player.IsTyping

    ---@type table<Player, boolean>
    local players_typing = {}

    --- [SHARED]
    ---
    --- Checks if the player is typing a chat message.
    ---
    ---@param pl Player
    ---@return boolean is_typing
    function ash_player.isTyping( pl )
        return players_typing[ pl ]
    end

    setmetatable( players_typing, {
        __index = function( self, pl )
            local is_typing = Player_IsTyping( pl )
            self[ pl ] = is_typing
            return is_typing
        end,
        __mode = "k"
    } )

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

    setmetatable( players_crouching_anim, {
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

    setmetatable( players_sequence, {
        __index = function( self, pl )
            local sequence = Entity_GetSequence( pl )
            self[ pl ] = sequence
            return sequence
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

            if rawget( players_model, pl ) ~= model_path  then
                local new_model = hook_Run( "ash.player.Model", pl, players_model[ pl ], model_path ) or model_path

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

    ---@param pl Player
    hook.Add( "ash.player.Think", "StateController", function( pl )
        local in_vehicle = Player_InVehicle( pl )
        if rawget( players_in_vehicle, pl ) ~= in_vehicle then
            players_in_vehicle[ pl ] = in_vehicle
            players_vehicle[ pl ] = Player_GetVehicle( pl )
        end

        local move_type = Entity_GetMoveType( pl )
        if rawget( players_move_type, pl ) ~= move_type then
            local new_type = hook_Run( "ash.player.MoveType", pl, players_move_type[ pl ], move_type ) or move_type
            players_move_type[ pl ] = move_type

            if new_type ~= move_type then
                pl:SetMoveType( new_type )
            end
        end

        local model_path = Entity_GetModel( pl ) or "models/player/infoplayerstart.mdl"
        if rawget( players_model, pl ) ~= model_path then
            ash_player.setModel( pl, model_path )
        end

        local skin = Entity_GetSkin( pl )
        if rawget( players_skin, pl ) ~= skin then
            local new_skin = hook_Run( "ash.player.Skin", pl, skin, players_skin[ pl ] ) or skin
            players_skin[ pl ] = new_skin

            if new_skin ~= skin then
                pl:SetSkin( new_skin )
            end
        end

        local sequence = Entity_GetSequence( pl )
        if rawget( players_sequence, pl ) ~= sequence then
            local new_sequence = hook_Run( "ash.player.Sequence", pl, players_sequence[ pl ], sequence ) or sequence
            players_sequence[ pl ] = new_sequence

            if new_sequence ~= sequence then
                pl:ResetSequence( new_sequence )
            end
        end

        local is_typing = Player_IsTyping( pl )
        if rawget( players_typing, pl ) ~= is_typing then
            players_typing[ pl ] = ( hook_Run( "ash.player.Typing", pl, is_typing ) or is_typing ) == true
        end

        local flags = Entity_GetFlags( pl )
        if rawget( players_flags, pl ) ~= flags then
            players_flags[ pl ] = flags

            local is_on_ground = bit_band( flags, 1 ) ~= 0
            if rawget( players_on_ground, pl ) ~= is_on_ground then
                local new_state = hook_Run( "ash.player.OnGround", pl, is_on_ground ) or is_on_ground
                players_on_ground[ pl ] = is_on_ground

                if new_state ~= is_on_ground then
                    if new_state then
                        flags = bit_bor( flags, 1 )
                        pl:AddFlags( 1 )
                    else
                        flags = bit_band( flags, -2 )
                        pl:RemoveFlags( 1 )
                    end
                end
            end

            local is_crouching = bit_band( flags, 2 ) ~= 0
            if rawget( players_crouching, pl ) ~= is_crouching then
                local new_state = hook_Run( "ash.player.Crouching", pl, is_crouching ) or is_crouching
                players_crouching[ pl ] = is_crouching

                if new_state ~= is_crouching then
                    if new_state then
                        flags = bit_bor( flags, 2 )
                        pl:AddFlags( 2 )
                    else
                        flags = bit_band( flags, -3 )
                        pl:RemoveFlags( 2 )
                    end
                end
            end

            local in_crouching = bit_band( flags, 4 ) ~= 0
            if rawget( players_crouching_anim, pl ) ~= in_crouching then
                local new_state = hook_Run( "ash.player.CrouchingAnimation", pl, in_crouching ) or in_crouching
                players_crouching_anim[ pl ] = in_crouching

                if new_state ~= in_crouching then
                    if new_state then
                        flags = bit_bor( flags, 4 )
                        pl:AddFlags( 4 )
                    else
                        flags = bit_band( flags, -5 )
                        pl:RemoveFlags( 4 )
                    end
                end
            end

            players_water_jumping[ pl ] = bit_band( flags, 8 ) ~= 0
            players_in_train[ pl ] = bit_band( flags, 16 ) ~= 0

            local is_under_rain = bit_band( flags, 32 ) ~= 0
            if rawget( players_under_rain, pl ) ~= is_under_rain then
                local new_state = hook_Run( "ash.player.UnderRain", pl, is_under_rain ) or is_under_rain
                players_under_rain[ pl ] = is_under_rain

                if new_state ~= is_under_rain then
                    if new_state then
                        flags = bit_bor( flags, 32 )
                        pl:AddFlags( 32 )
                    else
                        flags = bit_band( flags, -33 )
                        pl:RemoveFlags( 32 )
                    end
                end
            end

            local is_frozen = bit_band( flags, 64 ) ~= 0
            if rawget( players_frozen, pl ) ~= is_frozen then
                local new_state = hook_Run( "ash.player.Frozen", pl, is_frozen ) or is_frozen
                players_frozen[ pl ] = is_frozen

                if new_state ~= is_frozen then
                    if new_state then
                        flags = bit_bor( flags, 64 )
                        pl:AddFlags( 64 )
                    else
                        flags = bit_band( flags, -65 )
                        pl:RemoveFlags( 64 )
                    end
                end
            end

            local in_water = bit_band( flags, 1024 ) ~= 0
            if rawget( players_in_water, pl ) ~= in_water then
                local new_state = hook_Run( "ash.player.InWater", pl, in_water ) or in_water
                players_in_water[ pl ] = in_water

                if new_state ~= in_water then
                    if new_state then
                        flags = bit_bor( flags, 1024 )
                        pl:AddFlags( 1024 )
                    else
                        flags = bit_band( flags, -1025 )
                        pl:RemoveFlags( 1024 )
                    end
                end
            end
        end
    end, PRE_HOOK )

end

do

    local UserCommand_GetMouseWheel = UserCommand.GetMouseWheel
    local UserCommand_GetViewAngles = UserCommand.GetViewAngles
    local UserCommand_GetButtons = UserCommand.GetButtons
    local UserCommand_GetImpulse = UserCommand.GetImpulse
    local UserCommand_GetMouseX = UserCommand.GetMouseX
    local UserCommand_GetMouseY = UserCommand.GetMouseY

    ---@type table<Player, Angle>
    local player_view_angles = {}

    setmetatable( player_view_angles, {
        ---@param pl Player
        __index = function( self, pl )
            return pl:EyeAngles()
        end,
        __mode = "k"
    } )

    --- [SHARED]
    ---
    --- Returns the player's view angles (eye angles) that client requires.
    ---
    ---@param pl Player
    ---@return Angle view_angles
    function ash_player.getViewAngles( pl )
        return player_view_angles[ pl ]
    end

    ---@type integer[]
    local in_keys = {}

    for i = 1, 32, 1 do
        in_keys[ i ] = 2 ^ i
    end

    if CLIENT then

        hook.Add( "PlayerNW2Changed", "NW2Sync", function( pl, key, _, keys )
            if key == "m_iPlayerKeys" then
                if players_keys[ pl ] == keys then return end
                local pressed_keys = players_key_states[ pl ]

                for i = 1, 32, 1 do
                    local in_key = in_keys[ i ]

                    local key_state = bit_band( keys, in_key ) ~= 0
                    if pressed_keys[ in_key ] ~= key_state then
                        pressed_keys[ in_key ] = key_state
                        hook_Run( "ash.player.Key", pl, in_key, key_state )
                    end
                end
            end
        end, PRE_HOOK )

    end

    ---@param pl Player
    ---@param cmd CUserCmd
    hook.Add( "StartCommand", "InputCapture", function( pl, cmd )
        local keys = UserCommand_GetButtons( cmd )
        if rawget( players_keys, pl ) ~= keys then
            local pressed_keys = players_key_states[ pl ]
            players_keys[ pl ] = keys

            for i = 1, 32, 1 do
                local in_key = in_keys[ i ]

                local key_state = bit_band( keys, in_key ) ~= 0
                if pressed_keys[ in_key ] ~= key_state then
                    pressed_keys[ in_key ] = key_state
                    hook_Run( "ash.player.Key", pl, in_key, key_state )
                end
            end
        end

        local mouse_wheel = UserCommand_GetMouseWheel( cmd )
        if mouse_wheel ~= 0 then
            hook_Run( "ash.player.MouseWheel", pl, mouse_wheel )
        end

        local impulse = UserCommand_GetImpulse( cmd )
        if impulse ~= 0 then
            hook_Run( "ash.player.Impulse", pl, impulse )
        end

        local view_angles = UserCommand_GetViewAngles( cmd )
        if rawget( player_view_angles, pl ) ~= view_angles then
            player_view_angles[ pl ] = view_angles
            hook_Run( "ash.player.ViewAngles", pl, cmd, view_angles )
        end

        local x, y = UserCommand_GetMouseX( cmd ), UserCommand_GetMouseY( cmd )
        if x ~= 0 or y ~= 0 then
            hook_Run( "ash.player.Mouse", pl, cmd, x, y, view_angles )
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
        if hook_Run( "ash.player.CanMove", pl, cmd ) == false then
            UserCommand_SetImpulse( cmd, 0 )
            UserCommand_ClearMovement( cmd )
            UserCommand_ClearButtons( cmd )
        end
    end, POST_HOOK )

end

do

    local MoveData_SetMaxClientSpeed = MoveData.SetMaxClientSpeed
    local MoveData_SetMaxSpeed = MoveData.SetMaxSpeed

    local MoveData_GetVelocity = MoveData.GetVelocity
    local MoveData_SetVelocity = MoveData.SetVelocity

    local MoveData_GetMoveAngles = MoveData.GetMoveAngles

    local MoveData_GetOrigin = MoveData.GetOrigin
    local MoveData_SetOrigin = MoveData.SetOrigin

    local Angle_Forward = Angle.Forward
    local Angle_Right = Angle.Right
    local Angle_Up = Angle.Up

    local Vector_Add = Vector.Add

    local math_max = math.max

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
    hook.Add( "FinishMove", "MovementCapture", function( pl, mv )
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
            move_states[ pl ] = hook_Run( "ash.player.MoveState", pl, mv, keys )
        else
            move_states[ pl ] = "standing"
        end
    end, PRE_HOOK )

    local IN_MOVE = bit_bor( IN_FORWARD, IN_MOVELEFT, IN_MOVERIGHT, IN_BACK )

    ---@param arguments string[]
    ---@param pl Player
    ---@param mv CMoveData
    ---@param buttons integer
    ---@return string
    hook.Add( "ash.player.MoveState", "DefaultStates", function( arguments, pl, mv, buttons )
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
        local suppress_engine = arguments[ 2 ]
        if suppress_engine ~= nil then
            return suppress_engine
        end

        local move_type = players_move_type[ pl ]
        local player_speed = 0

        if move_type == 2 then -- walking
            local water_level = entity_getWaterLevel( pl )
            if players_on_ground[ pl ] then
                player_speed = hook_Run( "ash.player.WalkSpeed", pl, players_keys[ pl ], players_crouching[ pl ], water_level ) or 200
            elseif water_level == 0 then
                player_speed = hook_Run( "ash.player.FallSpeed", pl, players_keys[ pl ], players_crouching[ pl ] ) or 10
            else
                player_speed = hook_Run( "ash.player.SwimSpeed", pl, players_keys[ pl ], water_level ) or 150
            end
        elseif move_type == 8 then -- noclip movement
            player_speed = hook_Run( "ash.player.NoclipSpeed", pl, players_keys[ pl ] ) or 1000

            MoveData_SetMaxClientSpeed( mv, player_speed )
            MoveData_SetMaxSpeed( mv, player_speed )

            local origin = MoveData_GetOrigin( mv )
            local velocity = ( ( directions[ pl ] * player_speed ) - MoveData_GetVelocity( mv ) ) * tick_interval

            MoveData_SetVelocity( mv, velocity )

            Vector_Add( origin, velocity )
            MoveData_SetOrigin( mv, origin )

            return true
        elseif move_type == 9 then -- ladder movement
            player_speed = hook_Run( "ash.player.LadderSpeed", pl, players_keys[ pl ] ) or 150
        end

        MoveData_SetMaxClientSpeed( mv, player_speed )
        MoveData_SetMaxSpeed( mv, player_speed )
    end, POST_HOOK_RETURN )

    if SERVER then

        local Player_PrintMessage = Player.PrintMessage

        local string_format = string.format
        local math_snap = math.snap
        local math_min = math.min

        ---@param pl Player
        ---@param wheel number
        hook.Add( "ash.player.MouseWheel", "NoclipSpeed", function( pl, wheel )
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

        hook.Add( "ash.player.PreSpawn", "NoclipSpeed", function( pl )
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

    hook.Add( "ash.player.NoclipSpeed", "Defaults", function( pl )
        return Entity_GetNW2Var( pl, "m_fNoclipSpeed", 500 )
    end )

    local side_keys = bit_bor( IN_MOVELEFT, IN_MOVERIGHT )

    hook.Add( "ash.player.WalkSpeed", "Defaults", function( pl, in_keys, is_crouching )
        if bit_band( in_keys, 262144 ) ~= 0 then -- in walk
            if is_crouching then
                -- slowly crawling
                return 60
            end

            if bit_band( in_keys, 8 ) == 0 then
                if bit_band( in_keys, 16 ) ~= 0 then
                    -- backward walking
                    return 80
                elseif bit_band( in_keys, side_keys ) ~= 0 then
                    -- side walking
                    return 60
                end
            end

            -- forward walking
            return 100
        elseif bit_band( in_keys, 131072 ) ~= 0 then -- in run
            if is_crouching then
                -- fast crawling
                return 120
            end

            if bit_band( in_keys, 8 ) == 0 then
                if bit_band( in_keys, 16 ) ~= 0 then
                    -- backward running
                    return 160
                elseif bit_band( in_keys, side_keys ) ~= 0 then
                    -- side running
                    return 170
                end
            end

            -- forward running
            return 300
        else
            if is_crouching then
                -- crawling
                return 80
            end

            if bit_band( in_keys, 8 ) == 0 then
                if bit_band( in_keys, 16 ) ~= 0 then
                    -- backward walking
                    return 140
                elseif bit_band( in_keys, side_keys ) ~= 0 then
                    -- side walking
                    return 160
                end
            end

            -- walking
            return 180
        end
    end )

    hook.Add( "ash.player.WalkSpeed", "DefaultModifiers", function( arguments, pl, in_keys, is_crouching, water_level )
        local speed = arguments[ 2 ] or 200

        if water_level == 3 then -- walking underwater
            speed = speed * 0.25
        elseif water_level == 2 then -- walking waist-deep in water
            speed = speed * 0.5
        elseif water_level == 1 then -- walking in shallow water
            speed = speed * 0.6
        end

        return speed
    end, POST_HOOK_RETURN )

    hook.Add( "ash.player.SwimSpeed", "Defaults", function( pl, in_keys )
         if bit_band( in_keys, 262144 ) ~= 0 then -- slowly swimming
            return 80
        elseif bit_band( in_keys, 131072 ) ~= 0 then -- fast swimming
            return 250
        else -- swimming
            return 150
        end
    end )

    hook.Add( "ash.player.SwimSpeed", "DefaultModifiers", function( arguments, pl, in_keys, water_level )
        local speed = arguments[ 2 ] or 150

        if water_level == 3 then -- swimming underwater
            speed = speed * 0.5 + 50
        elseif water_level == 2 then -- surface swimming
            speed = speed + 20
        end

        return speed
    end, POST_HOOK_RETURN )

    hook.Add( "ash.player.LadderSpeed", "Defaults", function( pl )
        return pl:GetLadderClimbSpeed()
    end )

end

do

    ---@param pl Player
    ---@param sound_data EmitSoundInfo
    ---@return boolean | nil
    hook.Add( "ash.player.EmitsSound", "StopDrowning", function( pl, sound_data )
        if entity_getWaterLevel( pl ) < 2 and sound_data.OriginalSoundName == "Player.DrownStart" then
            return false
        end
    end, PRE_HOOK_RETURN )

end

--- [SHARED]
---
--- Returns the distance the player can use an entity.
---
---@return number distance
function ash_player.getUseDistance( pl )
    return Entity_GetNW2Var( pl, "m_fUseDistance", 72 )
end

--- [SHARED]
---
--- Sets the distance the player can use an entity.
---
---@param pl Player
---@param distance number
function ash_player.setUseDistance( pl, distance )
    Entity_SetNW2Var( pl, "m_fUseDistance", distance )
end

do

    local Entity_IsValid = Entity.IsValid
    local entity_use = ash_entity.use

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

    hook.Add( "ash.player.Key", "UsageHandler", function( pl, in_key, is_pressed )
        if in_key == 32 then
            if is_pressed then
                local seleted_entity = hook_Run( "ash.player.SelectsUseEntity", pl )
                if seleted_entity ~= nil and Entity_IsValid( seleted_entity ) and hook_Run( "ash.player.ShouldUse", pl, seleted_entity ) ~= false then
                    entity_use( seleted_entity, pl, pl, hook_Run( "ash.player.SelectsUseType", pl, seleted_entity ) )
                    Entity_SetNW2Var( pl, "m_eUseEntity", seleted_entity )
                    Entity_SetNW2Var( pl, "m_fUseStartTime", CurTime() )

                    hook_Run( "ash.player.UsedEntity", pl, seleted_entity, true )
                end

                return
            end

            local seleted_entity = Entity_GetNW2Var( pl, "m_eUseEntity" )

            Entity_SetNW2Var( pl, "m_fUseStartTime", 0 )
            Entity_SetNW2Var( pl, "m_eUseEntity", nil )

            if seleted_entity ~= nil and Entity_IsValid( seleted_entity ) then
                hook_Run( "ash.player.UsedEntity", pl, seleted_entity, false )
            end
        end
    end, PRE_HOOK )

end

hook.Add( "ash.entity.WaterLevel", "WaterLevel", function( entity, old, new )
    if entity:IsPlayer() then
        hook_Run( "ash.player.WaterLevel", entity, old, new )
    end
end, PRE_HOOK )

hook.Add( "FindUseEntity", "DisableDefaultUse", debug.fempty, PRE_HOOK_RETURN )

hook.Add( "PlayerUse", "DisableDefaultUse", function( pl, entity )
    return false
end, PRE_HOOK_RETURN )

hook.Add( "PlayerShouldTakeDamage", "DamageHandler", function( arguments )
    return arguments[ 2 ] ~= false
end, POST_HOOK_RETURN )

hook.Add( "PlayerNoClip", "NoclipController", function( arguments, pl, requested )
    local overridden = arguments[ 2 ]
    if overridden == nil then
        return not requested or ( Player_Alive( pl ) and hook_Run( "ash.player.CanNoclip", pl ) )
    else
        return overridden == true
    end
end, POST_HOOK_RETURN )

---@type ash.player.animator
local animator = include( "animator.lua", ash_player )

do

    local Entity_GetCollisionBounds = Entity.GetCollisionBounds
    local math_min = math.min

    ---@type ash.trace.Output
    ---@diagnostic disable-next-line: missing-fields
    local trace_result = {}

    ---@type ash.trace.Params
    local trace = {
        output = trace_result
    }

    local temp_vector = Vector( 0, 0, 0 )

    local function perform_trace( pl, speed )
        trace.mins, trace.maxs = Entity_GetCollisionBounds( pl )
        trace.filter = pl

        temp_vector[ 3 ] = speed

        local start = pl:GetPos()
        trace.start = start
        trace.endpos = start + temp_vector

        trace_cast( trace )
    end

    hook.Add( "OnPlayerHitGround", "LandingHandler", function( pl, _, __, fall_speed )
        fall_speed = -fall_speed
        perform_trace( pl, fall_speed )
        hook_Run( "ash.player.Landed", pl, fall_speed, false, trace_result )
    end, PRE_HOOK )

    hook.Add( "ash.player.WaterLevel", "LandingHandler", function( pl, old, new )
        if players_on_ground[ pl ] or players_in_water[ pl ] or old > new then return end

        local fall_speed = math_min( 0, animator.getVelocity( pl )[ 3 ] )
        perform_trace( pl, fall_speed )

        hook_Run( "ash.player.Landed", pl, fall_speed, true, trace_result )
    end, PRE_HOOK )

end

do

    local Player_Nick = Player.Nick

    --- [SHARED]
    ---
    --- Gets the player's name.
    ---
    ---@param pl Player
    ---@return string
    function ash_player.getName( pl )
        return Entity_GetNW2Var( pl, "m_sNickname", Player_Nick( pl ) )
    end

end

--- [SHARED]
---
--- Sets the player's name.
---
---@param pl Player
---@param name string
function ash_player.setName( pl, name )
    if ash_player.getName( pl ) == name then return end
    Entity_SetNW2Var( pl, "m_sNickname", name )
    hook_Run( "ash.player.Name", pl, name )
end

---@param pl Player
---@param damage_info CTakeDamageInfo
hook.Add( "ScalePlayerDamage", "DamageControl", function( pl, _, damage_info )
    if hook_Run( "ash.player.ShouldTakeDamage", pl, damage_info ) == false then
        return true
    end
end, PRE_HOOK_RETURN )

---@alias ash.player.GESTURE_SLOT integer
---| `0` Slot for weapon gestures
---| `1` Slot for grenade gestures
---| `2` Slot for jump gestures
---| `3` Slot for swimming gestures
---| `4` Slot for flinching gestures
---| `5` Slot for VCD gestures
---| `6` Slot for custom gestures

do

    local Player_AddVCDSequenceToGestureSlot = Player.AddVCDSequenceToGestureSlot
    local Player_AnimSetGestureWeight = Player.AnimSetGestureWeight
    local Player_AnimResetGestureSlot = Player.AnimResetGestureSlot
    local Player_AnimRestartGesture = Player.AnimRestartGesture

    local Entity_SelectWeightedSequence = Entity.SelectWeightedSequence
    local Entity_LookupSequence = Entity.LookupSequence

    --- [SHARED]
    ---
    --- Starts a player's gesture.
    ---
    ---@param pl Player
    ---@param slot ash.player.GESTURE_SLOT
    ---@param activity integer
    ---@param cycle number
    ---@param auto_kill boolean
    ---@param networked boolean
    function ash_player.startGestureByActivity( pl, slot, activity, cycle, auto_kill, networked )
        if SERVER and networked ~= false then
            net.Start( "network" )
            net.WriteUInt( 3, 8 )
            net.WritePlayer( pl )
            net.WriteUInt( slot, 3 )
            net.WriteUInt( activity, 32 )
            net.WriteBool( auto_kill )
            net.WriteDouble( CurTime() )
            net.WriteFloat( cycle )
            net.Broadcast()
        end

        local sequence_id = Entity_SelectWeightedSequence( pl, activity )
        if sequence_id ~= nil and sequence_id > 0 then
            return Player_AddVCDSequenceToGestureSlot( pl, slot, sequence_id, cycle, auto_kill )
        end

        return Player_AnimRestartGesture( pl, slot, activity, auto_kill )
    end

    --- [SHARED]
    ---
    --- Starts a player's gesture.
    ---
    ---@param pl Player
    ---@param slot ash.player.GESTURE_SLOT
    ---@param sequence_name string
    ---@param cycle number
    ---@param auto_kill boolean
    ---@param networked boolean
    function ash_player.startGestureBySequence( pl, slot, sequence_name, cycle, auto_kill, networked )
        if SERVER and networked ~= false then
            net.Start( "network" )
            net.WriteUInt( 4, 8 )
            net.WritePlayer( pl )
            net.WriteUInt( slot, 3 )
            net.WriteString( sequence_name )
            net.WriteBool( auto_kill )
            net.WriteDouble( CurTime() )
            net.WriteFloat( cycle )
            net.Broadcast()
        end

        local sequence_id = Entity_LookupSequence( pl, sequence_name )
        if sequence_id ~= nil and sequence_id > 0 then
            return Player_AddVCDSequenceToGestureSlot( pl, slot, sequence_id, cycle, auto_kill )
        end

        return Player_AnimResetGestureSlot( pl, slot )
    end

    --- [SHARED]
    ---
    --- Stops a player's gesture.
    ---
    ---@param pl Player
    ---@param slot ash.player.GESTURE_SLOT
    ---@param networked boolean
    function ash_player.stopGesture( pl, slot, networked )
        if SERVER and networked ~= false then
            net.Start( "network" )
            net.WriteUInt( 5, 8 )
            net.WritePlayer( pl )
            net.WriteUInt( slot, 3 )
            net.Broadcast()
        end

        return Player_AnimResetGestureSlot( pl, slot )
    end

    --- [SHARED]
    ---
    --- Sets the weight of a player's gesture.
    ---
    ---@param pl Player
    ---@param slot ash.player.GESTURE_SLOT
    ---@param weight number
    ---@param networked boolean
    function ash_player.setGestureWeight( pl, slot, weight, networked )
        if SERVER and networked ~= false then
            net.Start( "network" )
            net.WriteUInt( 6, 8 )
            net.WritePlayer( pl )
            net.WriteUInt( slot, 3 )
            net.WriteFloat( weight )
            net.Broadcast()
        end

        return Player_AnimSetGestureWeight( pl, slot, weight )
    end

end

include( "voice.lua", ash_player )

return ash_player
