---@class ash.player
local ash_player = ...

---@type ash.entity
local ash_entity = require( "ash.entity" )
local entity_getWaterLevel = ash_entity.getWaterLevel

local ACT_MP_CROUCH_IDLE = ACT_MP_CROUCH_IDLE
local ACT_MP_STAND_IDLE = ACT_MP_STAND_IDLE

local ACT_MP_CROUCHWALK = ACT_MP_CROUCHWALK
local ACT_MP_SWIM = ACT_MP_SWIM
local ACT_MP_WALK = ACT_MP_WALK
local ACT_MP_JUMP = ACT_MP_JUMP
local ACT_MP_RUN = ACT_MP_RUN

local ACT_HL2MP_SIT = ACT_HL2MP_SIT
local ACT_HL2MP_RUN_FAST = ACT_HL2MP_RUN_FAST
local ACT_HL2MP_RUN_PANICKED = ACT_HL2MP_RUN_PANICKED

local Entity_GetNW2Int = Entity.GetNW2Int
local Entity_SetNW2Int = Entity.SetNW2Int

local Entity_GetNW2String = Entity.GetNW2String
local Entity_SetNW2String = Entity.SetNW2String

local setmetatable = setmetatable
local string_byte = string.byte
local hook_Run = hook.Run

---@class ash.player.animator
local animator = {}
ash_player.animator = animator

--- [SHARED]
---
--- Gets the player stand activity.
---
---@return integer activity
local function getStandActivity( pl )
    return Entity_GetNW2Int( pl, "m_iStandActivity", ACT_MP_STAND_IDLE )
end

animator.getStandActivity = getStandActivity

--- [SHARED]
---
--- Sets the player stand activity.
---
---@param pl Player
---@param activity integer
function animator.setStandActivity( pl, activity )
    Entity_SetNW2Int( pl, "m_iStandActivity", activity )
end

--- [SHARED]
---
--- Gets the player walk activity.
---
---@return integer activity
local function getWalkActivity( pl )
    return Entity_GetNW2Int( pl, "m_iWalkActivity", ACT_MP_WALK )
end

animator.getWalkActivity = getWalkActivity

--- [SHARED]
---
--- Sets the player walk activity.
---
---@param pl Player
---@param activity integer
function animator.setWalkActivity( pl, activity )
    Entity_SetNW2Int( pl, "m_iWalkActivity", activity )
end

--- [SHARED]
---
--- Gets the player crouch activity.
---
---@return integer activity
local function getCrouchActivity( pl )
    return Entity_GetNW2Int( pl, "m_iCrouchActivity", ACT_MP_CROUCH_IDLE )
end

animator.getCrouchActivity = getCrouchActivity

--- [SHARED]
---
--- Sets the player crouch activity.
---
---@param pl Player
---@param activity integer
function animator.setCrouchActivity( pl, activity )
    Entity_SetNW2Int( pl, "m_iCrouchActivity", activity )
end

--- [SHARED]
---
--- Gets the player ladder activity.
---
---@return integer activity
local function getLadderActivity( pl )
    return Entity_GetNW2Int( pl, "m_iLadderActivity", ACT_MP_STAND_IDLE )
end

animator.getLadderActivity = getLadderActivity

--- [SHARED]
---
--- Sets the player ladder activity.
---
---@param pl Player
---@param activity integer
function animator.setLadderActivity( pl, activity )
    Entity_SetNW2Int( pl, "m_iLadderActivity", activity )
end

--- [SHARED]
---
--- Gets the player ladder crouch activity.
---
---@return integer activity
local function getLadderCrouchActivity( pl )
    return Entity_GetNW2Int( pl, "m_iLadderCrouchActivity", ACT_MP_CROUCH_IDLE )
end

animator.getLadderCrouchActivity = getLadderCrouchActivity

--- [SHARED]
---
--- Sets the player ladder crouch activity.
---
---@param pl Player
---@param activity integer
function animator.setLadderCrouchActivity( pl, activity )
    Entity_SetNW2Int( pl, "m_iLadderCrouchActivity", activity )
end

--- [SHARED]
---
--- Gets the player crouch walk activity.
---
---@return integer activity
local function getCrouchWalkActivity( pl )
    return Entity_GetNW2Int( pl, "m_iCrouchWalkActivity", ACT_MP_CROUCHWALK )
end

animator.getCrouchWalkActivity = getCrouchWalkActivity

--- [SHARED]
---
--- Sets the player crouch walk activity.
---
---@param pl Player
---@param activity integer
function animator.setCrouchWalkActivity( pl, activity )
    Entity_SetNW2Int( pl, "m_iCrouchWalkActivity", activity )
end

--- [SHARED]
---
--- Gets the player jump activity.
---
---@return integer activity
local function getJumpActivity( pl )
    return Entity_GetNW2Int( pl, "m_iJumpActivity", ACT_MP_JUMP )
end

animator.getJumpActivity = getJumpActivity

--- [SHARED]
---
--- Sets the player jump activity.
---
---@param pl Player
---@param activity integer
function animator.setJumpActivity( pl, activity )
    Entity_SetNW2Int( pl, "m_iJumpActivity", activity )
end

--- [SHARED]
---
--- Gets the player falling activity.
---
---@return integer activity
local function getFallingActivity( pl )
    return Entity_GetNW2Int( pl, "m_iFallingActivity", ACT_MP_SWIM )
end

animator.getFallingActivity = getFallingActivity

--- [SHARED]
---
--- Sets the player falling activity.
---
---@param pl Player
---@param activity integer
function animator.setFallingActivity( pl, activity )
    Entity_SetNW2Int( pl, "m_iFallingActivity", activity )
end

--- [SHARED]
---
--- Gets the player flight activity.
---
---@return integer activity
local function getFlightActivity( pl )
    return Entity_GetNW2Int( pl, "m_iFlightActivity", ACT_MP_SWIM )
end

animator.getFlightActivity = getFlightActivity

--- [SHARED]
---
--- Sets the player flight activity.
---
---@param pl Player
---@param activity integer
function animator.setFlightActivity( pl, activity )
    Entity_SetNW2Int( pl, "m_iFlightActivity", activity )
end

--- [SHARED]
---
--- Gets the player swim activity.
---
---@return integer activity
local function getSwimActivity( pl )
    return Entity_GetNW2Int( pl, "m_iSwimActivity", ACT_MP_SWIM )
end

animator.getSwimActivity = getSwimActivity

--- [SHARED]
---
--- Sets the player swim activity.
---
---@param pl Player
---@param activity integer
function animator.setSwimActivity( pl, activity )
    Entity_SetNW2Int( pl, "m_iSwimActivity", activity )
end

--- [SHARED]
---
--- Gets the player sit activity.
---
---@return integer activity
local function getSitActivity( pl )
    return Entity_GetNW2Int( pl, "m_iSitActivity", ACT_HL2MP_SIT )
end

animator.getSitActivity = getSitActivity

--- [SHARED]
---
--- Sets the player sit activity.
---
---@param pl Player
---@param activity integer
function animator.setSitActivity( pl, activity )
    Entity_SetNW2Int( pl, "m_iSitActivity", activity )
end

--- [SHARED]
---
--- Gets the player run activity.
---
---@return integer activity
local function getRunActivity( pl )
    return Entity_GetNW2Int( pl, "m_iRunActivity", ACT_MP_RUN ) -- ACT_HL2MP_RUN_FAST
end

animator.getRunActivity = getRunActivity

--- [SHARED]
---
--- Sets the player run activity.
---
---@param pl Player
---@param activity integer
function animator.setRunActivity( pl, activity )
    Entity_SetNW2Int( pl, "m_iRunActivity", activity )
end

--- [SHARED]
---
--- Gets the player crouch without weapon sequence.
---
---@return string sequence
local function getCrouchUnarmedSequence( pl )
    return Entity_GetNW2String( pl, "m_sCrouchUnarmedSequence", "pose_ducking_01" )
end

animator.getCrouchUnarmedSequence = getCrouchUnarmedSequence

--- [SHARED]
---
--- Sets the player crouch without weapon sequence.
---
---@param pl Player
---@param sequence string
function animator.setCrouchUnarmedSequence( pl, sequence )
    Entity_SetNW2String( pl, "m_sCrouchUnarmedSequence", sequence )
end

local MOVETYPE_OBSERVER = MOVETYPE_OBSERVER
local MOVETYPE_NOCLIP = MOVETYPE_NOCLIP
local MOVETYPE_LADDER = MOVETYPE_LADDER
local MOVETYPE_WALK = MOVETYPE_WALK

local Vector_Length2DSqr = Vector.Length2DSqr
local Vector_LengthSqr = Vector.LengthSqr

local Entity_LookupSequence = Entity.LookupSequence
local Entity_IsValid = Entity.IsValid

local Player_GetActiveWeapon = Player.GetActiveWeapon

local Weapon_GetHoldType = Weapon.GetHoldType

---@type table<string, boolean>
local unarmed_holdtypes = {
    -- passive = true,
    normal = true,
    magic = true
}

animator.UnarmedHoldTypes = unarmed_holdtypes

---@type table<integer, boolean>
local unhandled_move_types = {
    [ MOVETYPE_VPHYSICS ] = true,
    [ MOVETYPE_OBSERVER ] = true,
    [ MOVETYPE_CUSTOM ] = true,
    [ MOVETYPE_PUSH ] = true
}

animator.UnhandledMoveTypes = unhandled_move_types

---@type table<integer, boolean>
local flight_move_types = {
    [ MOVETYPE_FLYGRAVITY ] = true,
    [ MOVETYPE_NOCLIP ] = true,
    [ MOVETYPE_FLY ] = true
}

animator.FlightMoveTypes = flight_move_types

---@type table<integer, boolean>
local walk_move_types = {
    [ MOVETYPE_WALK ] = true,
    [ MOVETYPE_STEP ] = true,
    [ MOVETYPE_ISOMETRIC ] = true
}

animator.WalkMoveTypes = walk_move_types

do

    local player_isInCrouchingAnim = ash_player.isInCrouchingAnim
    local player_getMoveType = ash_player.getMoveType
    local player_isInVehicle = ash_player.isInVehicle
    local player_isOnGround = ash_player.isOnGround
    local player_isInWater = ash_player.isInWater

    ---@type table<string, string>
    local sit_sequences_cache = {
        [ "" ] = "sit_rollercoaster"
    }

    setmetatable( sit_sequences_cache, {
        __index = function( self, hold_type )
            local sequence_name

            if hold_type == "smg" then
                sequence_name = "sit_smg1"
            else
                sequence_name = "sit_" .. hold_type
            end

            self[ hold_type ] = sequence_name
            return sequence_name
        end
    } )

    ---@type table<Player, integer>
    local activities = {}

    setmetatable( activities, {
        __index = function()
            return 0
        end,
        __mode = "k"
    } )

    --- [SHARED]
    ---
    --- Gets the player's current animator activity.
    ---
    ---@param pl Player
    ---@return integer activity
    function animator.getActivity( pl )
        return activities[ pl ]
    end

    ---@type table<Player, integer>
    local sequences = {}

    setmetatable( sequences, {
        __index = function()
            return 0
        end,
        __mode = "k"
    } )

    --- [SHARED]
    ---
    --- Gets the player's current animator sequence.
    ---
    ---@param pl Player
    ---@return integer sequence_id
    function animator.getSequence( pl )
        return sequences[ pl ]
    end

    ---@type table<Player, Vector>
    local velocities = {}

    setmetatable( velocities, {
        __index = function()
            return Vector( 0, 0, 0 )
        end,
        __mode = "k"
    } )

    --- [SHARED]
    ---
    --- Gets the player's current velocity.
    ---
    ---@param pl Player
    ---@return Vector velocity
    function animator.getVelocity( pl )
        return velocities[ pl ]
    end

    do

        local player_getKeys = ash_player.getKeys
        local bit_band = bit.band

        local in_walk_keys = bit.bor( IN_FORWARD, IN_BACK, IN_MOVELEFT, IN_MOVERIGHT )
        local IN_SPEED = IN_SPEED

        local is_crouching, move_type = false, 0

        ---@param arguments integer[]
        ---@param pl Player
        ---@param velocity Vector
        ---@diagnostic disable-next-line: redundant-parameter
        hook.Add( "CalcMainActivity", "AnimationController", function( arguments, pl, velocity )
            velocities[ pl ] = velocity

            local activity = arguments[ 2 ]
            local sequence_id = -1

            if activity ~= nil then
                sequence_id = arguments[ 3 ]
                goto activity_selected
            end

            if player_isInVehicle( pl ) then
                activity = getSitActivity( pl )

                local weapon_entity = Player_GetActiveWeapon( pl )
                if weapon_entity ~= nil and Entity_IsValid( weapon_entity ) then
                    local sequence_name = sit_sequences_cache[ Weapon_GetHoldType( weapon_entity ) ]
                    if sequence_name ~= nil then
                        sequence_id = Entity_LookupSequence( pl, sequence_name ) or 0
                    end
                end

                if sequence_id == -1 or sequence_id == 0 then
                    sequence_id = Entity_LookupSequence( pl, "sit_rollercoaster" )
                end

                goto activity_selected
            end

            move_type = player_getMoveType( pl )

            if unhandled_move_types[ move_type ] then
                activity = getStandActivity( pl )
                goto activity_selected
            elseif flight_move_types[ move_type ] then
                activity = getFlightActivity( pl )
                goto activity_selected
            end

            is_crouching = player_isInCrouchingAnim( pl )

            if move_type == 9 then
                if is_crouching then
                    activity = getLadderCrouchActivity( pl )
                else
                    activity = getLadderActivity( pl )
                end

                goto activity_selected
            elseif walk_move_types[ move_type ] then
                if player_isOnGround( pl ) then
                    local in_keys = player_getKeys( pl )

                    if entity_getWaterLevel( pl ) == 3 then
                        activity = getSwimActivity( pl )
                    elseif is_crouching then
                        if bit_band( in_keys, in_walk_keys ) == 0 then
                            local weapon_entity = Player_GetActiveWeapon( pl )
                            if weapon_entity == nil or not Entity_IsValid( weapon_entity ) or unarmed_holdtypes[ Weapon_GetHoldType( weapon_entity ) ] then
                                local sequence_name = getCrouchUnarmedSequence( pl )
                                if string_byte( sequence_name, 1, 1 ) ~= nil then
                                    sequence_id = Entity_LookupSequence( pl, sequence_name )
                                end
                            end

                            activity = getCrouchActivity( pl )
                        else
                            activity = getCrouchWalkActivity( pl )
                        end
                    elseif bit_band( in_keys, IN_SPEED ) == 0 then
                        if bit_band( in_keys, in_walk_keys ) == 0 then
                            activity = getStandActivity( pl )
                        else
                            activity = getWalkActivity( pl )
                        end
                    else
                        activity = getRunActivity( pl )
                    end

                    goto activity_selected
                elseif player_isInWater( pl ) then
                    activity = getSwimActivity( pl )
                elseif is_crouching then
                    activity = getCrouchActivity( pl )
                elseif velocity[ 3 ] < -512 then
                    activity = getFallingActivity( pl )
                else
                    activity = getJumpActivity( pl )
                end

                goto activity_selected
            end

            activity = getFlightActivity( pl )
            ::activity_selected::

            if activity ~= activities[ pl ] then
                hook_Run( "PlayerActivitySelected", pl, activity, activities[ pl ] )
                activities[ pl ] = activity
            end

            if sequence_id ~= sequences[ pl ] then
                hook_Run( "PlayerSequenceSelected", pl, sequence_id, sequences[ pl ] )
                sequences[ pl ] = sequence_id
            end

            return activity, sequence_id
        end, POST_HOOK_RETURN )

    end

    local Entity_GetSequenceGroundSpeed = Entity.GetSequenceGroundSpeed
    local Entity_SetPlaybackRate = Entity.SetPlaybackRate

    local player_getSequence = ash_player.getSequence
    local player_Iterator = player.Iterator

    local math_sqrt = math.sqrt
    local math_min = math.min

    timer.Create( "AnimationUpdate", 0.25, 0, function()
        for _, pl in player_Iterator() do
            local move_type = player_getMoveType( pl )
            local rate = 1.00

            if move_type == 2 then
                local max_speed = Entity_GetSequenceGroundSpeed( pl, player_getSequence( pl ) )
                if max_speed ~= 0 then
                    rate = math_sqrt( Vector_LengthSqr( velocities[ pl ] ) ) / max_speed

                    if player_isOnGround( pl ) then
                        rate = math_min( 2, rate )
                    else
                        rate = math_min( 1, rate )
                    end
                end
            elseif flight_move_types[ move_type ] then
                if Vector_LengthSqr( velocities[ pl ] ) > 22500 then
                    rate = 0.00
                else
                    rate = 0.25
                end
            elseif move_type == 9 then
                rate = 0.25
            end

            Entity_SetPlaybackRate( pl, rate )
        end
    end )

end

do

    ---@type table<Player, table<integer, integer>>
    local translation_cache = {}

    do

        local Player_TranslateWeaponActivity = Player.TranslateWeaponActivity

        local activity_translations = {
            [ ACT_MP_STAND_IDLE ] = ACT_HL2MP_IDLE,
            [ ACT_MP_WALK ] = ACT_HL2MP_IDLE + 1,
            [ ACT_MP_RUN ] = ACT_HL2MP_IDLE + 2,
            [ ACT_MP_CROUCH_IDLE ] = ACT_HL2MP_IDLE + 3,
            [ ACT_MP_CROUCHWALK ] = ACT_HL2MP_IDLE + 4,
            [ ACT_MP_ATTACK_STAND_PRIMARYFIRE ] = ACT_HL2MP_IDLE + 5,
            [ ACT_MP_ATTACK_CROUCH_PRIMARYFIRE ] = ACT_HL2MP_IDLE + 5,
            [ ACT_MP_RELOAD_STAND ] = ACT_HL2MP_IDLE + 6,
            [ ACT_MP_RELOAD_CROUCH ] = ACT_HL2MP_IDLE + 6,
            [ ACT_MP_JUMP ] = ACT_HL2MP_JUMP_SLAM,
            [ ACT_MP_SWIM ] = ACT_HL2MP_IDLE + 9,
            [ ACT_LAND ] = ACT_LAND
        }

        local activity_map_metatable = {
            __index = function( self, activity )
                local translated_activity = Player_TranslateWeaponActivity( self.Entity, activity )

                if translated_activity == activity then
                    translated_activity = activity_translations[ activity ]
                end

                self[ activity ] = translated_activity

                return translated_activity
            end
        }

        setmetatable( translation_cache, {
            __index = function( self, pl )
                local activity_map = { Entity = pl }
                setmetatable( activity_map, activity_map_metatable )
                self[ pl ] = activity_map
                return activity_map
            end,
            __mode = "k"
        } )

    end

    hook.Add( "TranslateActivity", "TranslationCacher", function( arguments, pl, activity )
        return arguments[ 2 ] or translation_cache[ pl ][ activity ]
    end, POST_HOOK_RETURN )

    local function cleanup_cache( pl )
        -- print( pl, CurTime(), "Translation cache cleared." )
        translation_cache[ pl ] = nil
    end

    hook.Add( "PlayerSequenceChanged", "TranslationCacher", cleanup_cache, PRE_HOOK )
    hook.Add( "PlayerActivitySelected", "TranslationCacher", cleanup_cache, PRE_HOOK )
    hook.Add( "PlayerSequenceSelected", "TranslationCacher", cleanup_cache, PRE_HOOK )
    hook.Add( "PlayerSwitchWeapon", "TranslationCacher", cleanup_cache, PRE_HOOK )

end

return animator
