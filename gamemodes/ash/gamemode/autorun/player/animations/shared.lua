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

local string_byte = string.byte

---@class ash.animation
local animation = {}

--- [SHARED]
---
--- Gets the player stand activity.
---
---@return integer activity
local function getStandActivity( pl )
    return Entity_GetNW2Int( pl, "m_iStandActivity", ACT_MP_STAND_IDLE )
end

animation.getStandActivity = getStandActivity

--- [SHARED]
---
--- Sets the player stand activity.
---
---@param pl Player
---@param activity integer
function animation.setStandActivity( pl, activity )
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

animation.getWalkActivity = getWalkActivity

--- [SHARED]
---
--- Sets the player walk activity.
---
---@param pl Player
---@param activity integer
function animation.setWalkActivity( pl, activity )
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

animation.getCrouchActivity = getCrouchActivity

--- [SHARED]
---
--- Sets the player crouch activity.
---
---@param pl Player
---@param activity integer
function animation.setCrouchActivity( pl, activity )
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

animation.getLadderActivity = getLadderActivity

--- [SHARED]
---
--- Sets the player ladder activity.
---
---@param pl Player
---@param activity integer
function animation.setLadderActivity( pl, activity )
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

animation.getLadderCrouchActivity = getLadderCrouchActivity

--- [SHARED]
---
--- Sets the player ladder crouch activity.
---
---@param pl Player
---@param activity integer
function animation.setLadderCrouchActivity( pl, activity )
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

animation.getCrouchWalkActivity = getCrouchWalkActivity

--- [SHARED]
---
--- Sets the player crouch walk activity.
---
---@param pl Player
---@param activity integer
function animation.setCrouchWalkActivity( pl, activity )
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

animation.getJumpActivity = getJumpActivity

--- [SHARED]
---
--- Sets the player jump activity.
---
---@param pl Player
---@param activity integer
function animation.setJumpActivity( pl, activity )
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

animation.getFallingActivity = getFallingActivity

--- [SHARED]
---
--- Sets the player falling activity.
---
---@param pl Player
---@param activity integer
function animation.setFallingActivity( pl, activity )
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

animation.getFlightActivity = getFlightActivity

--- [SHARED]
---
--- Sets the player flight activity.
---
---@param pl Player
---@param activity integer
function animation.setFlightActivity( pl, activity )
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

animation.getSwimActivity = getSwimActivity

--- [SHARED]
---
--- Sets the player swim activity.
---
---@param pl Player
---@param activity integer
function animation.setSwimActivity( pl, activity )
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

animation.getSitActivity = getSitActivity

--- [SHARED]
---
--- Sets the player sit activity.
---
---@param pl Player
---@param activity integer
function animation.setSitActivity( pl, activity )
    Entity_SetNW2Int( pl, "m_iSitActivity", activity )
end

--- [SHARED]
---
--- Gets the player run activity.
---
---@return integer activity
local function getRunActivity( pl )
    return Entity_GetNW2Int( pl, "m_iRunActivity", ACT_MP_RUN )
end

animation.getRunActivity = getRunActivity

--- [SHARED]
---
--- Sets the player run activity.
---
---@param pl Player
---@param activity integer
function animation.setRunActivity( pl, activity )
    Entity_SetNW2Int( pl, "m_iRunActivity", activity )
end

--- [SHARED]
---
--- Gets the player run fast activity.
---
---@return integer activity
local function getRunFastActivity( pl )
    return Entity_GetNW2Int( pl, "m_iRunFastActivity", ACT_HL2MP_RUN_FAST )
end

animation.getRunFastActivity = getRunFastActivity

--- [SHARED]
---
--- Sets the player run fast activity.
---
---@param pl Player
---@param activity integer
function animation.setRunFastActivity( pl, activity )
    Entity_SetNW2Int( pl, "m_iRunFastActivity", activity )
end

--- [SHARED]
---
--- Gets the player run without weapon activity.
---
---@return integer activity
local function getRunUnarmedActivity( pl )
    return Entity_GetNW2Int( pl, "m_iRunUnarmedActivity", ACT_HL2MP_RUN_PANICKED )
end

animation.getRunUnarmedActivity = getRunUnarmedActivity

--- [SHARED]
---
--- Sets the player run without weapon activity.
---
---@param pl Player
---@param activity integer
function animation.setRunUnarmedActivity( pl, activity )
    Entity_SetNW2Int( pl, "m_iRunUnarmedActivity", activity )
end

--- [SHARED]
---
--- Gets the player run fast without weapon activity.
---
---@return integer activity
local function getRunFastUnarmedActivity( pl )
    return Entity_GetNW2Int( pl, "m_iRunFastUnarmedActivity", ACT_HL2MP_RUN_PANICKED )
end

animation.getRunFastUnarmedActivity = getRunFastUnarmedActivity

--- [SHARED]
---
--- Sets the player run fast without weapon activity.
---
---@param pl Player
---@param activity integer
function animation.setRunFastUnarmedActivity( pl, activity )
    Entity_SetNW2Int( pl, "m_iRunFastUnarmedActivity", activity )
end

--- [SHARED]
---
--- Gets the player crouch without weapon sequence.
---
---@return string sequence
local function getCrouchUnarmedSequence( pl )
    return Entity_GetNW2String( pl, "m_sCrouchUnarmedSequence", "pose_ducking_01" )
end

animation.getCrouchUnarmedSequence = getCrouchUnarmedSequence

--- [SHARED]
---
--- Sets the player crouch without weapon sequence.
---
---@param pl Player
---@param sequence string
function animation.setCrouchUnarmedSequence( pl, sequence )
    Entity_SetNW2String( pl, "m_sCrouchUnarmedSequence", sequence )
end

local MOVETYPE_OBSERVER = MOVETYPE_OBSERVER
local MOVETYPE_NOCLIP = MOVETYPE_NOCLIP
local MOVETYPE_LADDER = MOVETYPE_LADDER
local MOVETYPE_WALK = MOVETYPE_WALK

local FL_ANIMDUCKING = FL_ANIMDUCKING

local Vector_Length2DSqr = Vector.Length2DSqr
local Vector_LengthSqr = Vector.LengthSqr
-- local Vector_Length2D = Vector.Length2D
-- local Vector_Length = Vector.Length

local Entity_LookupSequence = Entity.LookupSequence
local Entity_GetMoveType = Entity.GetMoveType
local Entity_IsOnGround = Entity.IsOnGround
local Entity_WaterLevel = Entity.WaterLevel
local Entity_GetFlags = Entity.GetFlags
local Entity_IsValid = Entity.IsValid

local Player_GetActiveWeapon = Player.GetActiveWeapon
local Player_InVehicle = Player.InVehicle

local Weapon_GetHoldType = Weapon.GetHoldType

local bit_band = bit.band

---@type table<string, boolean>
local unarmed_holdtypes = {
    -- passive = true,
    normal = true,
    magic = true
}

animation.UnarmedHoldTypes = unarmed_holdtypes

---@type table<integer, boolean>
local unhandled_move_types = {
    [ MOVETYPE_VPHYSICS ] = true,
    [ MOVETYPE_OBSERVER ] = true,
    [ MOVETYPE_CUSTOM ] = true,
    [ MOVETYPE_PUSH ] = true
}

animation.UnhandledMoveTypes = unhandled_move_types

---@type table<integer, boolean>
local flight_move_types = {
    [ MOVETYPE_FLYGRAVITY ] = true,
    [ MOVETYPE_NOCLIP ] = true,
    [ MOVETYPE_FLY ] = true
}

animation.FlightMoveTypes = flight_move_types

---@type table<integer, boolean>
local walk_move_types = {
    [ MOVETYPE_WALK ] = true,
    [ MOVETYPE_STEP ] = true,
    [ MOVETYPE_ISOMETRIC ] = true
}

animation.WalkMoveTypes = walk_move_types

do

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
    --- Gets the player's current animation activity.
    ---
    ---@param pl Player
    ---@return integer activity
    function animation.getActivity( pl )
        return activities[ pl ]
    end

    --- [SHARED]
    ---
    --- Gets the player's current animation sequence.
    ---
    ---@param pl Player
    ---@return integer sequence_id
    function animation.getSequence( pl )
        return sequences[ pl ]
    end

    local is_standing, move_type = false, 0

    ---@param arguments integer[]
    ---@param pl Player
    ---@param velocity Vector
    ---@diagnostic disable-next-line: redundant-parameter
    hook.Add( "CalcMainActivity", "AnimationController", function( arguments, pl, velocity )
        local activity, sequence_id = arguments[ 1 ], -1
        if activity ~= nil then
            sequence_id = arguments[ 2 ]
            goto activity_selected
        end

        if Player_InVehicle( pl ) then
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
        end

        move_type = Entity_GetMoveType( pl )

        if unhandled_move_types[ move_type ] then
            activity = getStandActivity( pl )
            goto activity_selected
        elseif flight_move_types[ move_type ] then
            activity = getFlightActivity( pl )
            goto activity_selected
        end

        is_standing = bit_band( Entity_GetFlags( pl ), FL_ANIMDUCKING ) == 0

        if move_type == MOVETYPE_LADDER then
            if is_standing then
                activity = getLadderActivity( pl )
            else
                activity = getLadderCrouchActivity( pl )
            end

            goto activity_selected
        elseif walk_move_types[ move_type ] then
            local vertical_speed = Vector_Length2DSqr( velocity )
            local water_level = Entity_WaterLevel( pl )

            if Entity_IsOnGround( pl ) then
                if water_level == 3 then
                    activity = getSwimActivity( pl )
                    goto activity_selected
                elseif is_standing then
                    if vertical_speed > 22500 then
                        local weapon_entity = Player_GetActiveWeapon( pl )
                        if weapon_entity ~= nil and Entity_IsValid( weapon_entity ) and unarmed_holdtypes[ Weapon_GetHoldType( weapon_entity ) ] then
                            if vertical_speed > 360000 then
                                activity = getRunFastUnarmedActivity( pl )
                            else
                                activity = getRunUnarmedActivity( pl )
                            end

                            goto activity_selected
                        end

                        if vertical_speed > 360000 then
                            activity = getRunFastActivity( pl )
                        else
                            activity = getRunActivity( pl )
                        end

                        goto activity_selected
                    elseif vertical_speed < 0.25 then
                        activity = getStandActivity( pl )
                    else
                        activity = getWalkActivity( pl )
                    end

                    goto activity_selected
                end

                if vertical_speed > 0.25 then
                    activity = getCrouchWalkActivity( pl )
                    goto activity_selected
                end

                local weapon_entity = Player_GetActiveWeapon( pl )
                if weapon_entity ~= nil and Entity_IsValid( weapon_entity ) and unarmed_holdtypes[ Weapon_GetHoldType( weapon_entity ) ] then
                    local sequence_name = getCrouchUnarmedSequence( pl )
                    if string_byte( sequence_name, 1, 1 ) ~= nil then
                        sequence_id = Entity_LookupSequence( pl, sequence_name )
                    end
                end

                activity = getCrouchActivity( pl )
            elseif water_level ~= 0 then
                activity = getSwimActivity( pl )
            elseif vertical_speed > 62500 then
                activity = getFallingActivity( pl )
            elseif is_standing then
                activity = getJumpActivity( pl )
            else
                activity = getCrouchActivity( pl )
            end

            goto activity_selected
        end

        activity = getFlightActivity( pl )
        ::activity_selected::

        activities[ pl ] = activity
        sequences[ pl ] = sequence_id

        return activity, sequence_id
    end, POST_HOOK_RETURN )

end

do

    local Entity_SetPlaybackRate = Entity.SetPlaybackRate
    -- local Vector_Length = Vector.Length

    ---@param pl Player
    ---@param velocity Vector
    ---@param max_seq_ground_speed number
    hook.Add( "UpdateAnimation", "Animations", function( pl, velocity, max_seq_ground_speed )
        -- local speed = Vector_Length2DSqr( velocity ) * 0.75
        local water_level = Entity_WaterLevel( pl )
        local move_type = Entity_GetMoveType( pl )
        local on_ground = Entity_IsOnGround( pl )

        local rate = 1

        if flight_move_types[ move_type ] then
            if Vector_LengthSqr( velocity ) > 22500 then
                rate = 0
            else
                rate = 0.25
            end
        elseif move_type == MOVETYPE_LADDER then
            rate = 0.25
        elseif Entity_IsOnGround( pl ) then
            -- rate =
        end

        Entity_SetPlaybackRate( pl, rate )


        -- local rate = 1.0
        -- if flight_move_types[ Entity_GetMoveType( pl ) ] then
        -- 	rate = speed < 32 and 0.25 or 0
        -- elseif Entity_WaterLevel( pl ) > 1 then
        -- 	rate = 0.5
        -- else
        --     if speed > 0.25 then
        -- 		rate = speed / max_seq_ground_speed
        -- 	end
        -- 	if Entity_WaterLevel( pl ) >= 2 then
        --         rate = math_max( rate, 0.5 )
        -- 	elseif not Entity_IsOnGround( pl ) and speed >= 1000 then
        -- 		rate = 0.1
        --     else
        --         rate = math_min( rate, 2 )
        -- 	end
        -- end

        -- if CLIENT and not pl:IsBot() then
        -- 	if not pl:IsLocalPlayer() then
        -- 		Run( "PerformPlayerVoice", pl )
        -- 	end
        -- 	if Alive( pl ) then
        -- 		Run( "MouthMoveAnimation", pl )
        -- 		return Run( "GrabEarAnimation", pl )
        -- 	end
        -- end
    end, PRE_HOOK )

end

do

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

    local Player_TranslateWeaponActivity = Player.TranslateWeaponActivity

    hook.Add( "TranslateActivity", "TranslateController", function( pl, activity )
        local translated_activity = Player_TranslateWeaponActivity( pl, activity )
        if translated_activity == activity then
            return activity_translations[ activity ] or activity
        else
            return translated_activity
        end
    end )

end

return animation
