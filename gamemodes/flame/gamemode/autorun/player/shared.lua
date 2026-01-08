local hook_Run = hook.Run

---@class flame.player
local flame_player = {}

---@type ash.entity
local ash_entity = require( "ash.entity" )

---@type ash.trace
local ash_trace = require( "ash.trace" )
local trace_cast = ash_trace.cast

hook.Add( "PlayerNoClip", "Defaults", function( arguments, pl, requested )
    local overridden = arguments[ 2 ]

    if overridden == nil then
        return not requested or pl:IsSuperAdmin()
    end

    return overridden
end, POST_HOOK_RETURN )

hook.Add( "PhysgunPickup", "Defaults", function( arguments, pl, entity )
    return arguments[ 2 ] ~= false
end, POST_HOOK_RETURN )

do

    local entity_isActivityExists = ash_entity.isActivityExists
    local Entity_LookupSequence = Entity.LookupSequence

    local hit_activities = {
        [ HITGROUP_HEAD ] = ACT_FLINCH_HEAD,
        [ HITGROUP_CHEST ] = ACT_FLINCH_CHEST,
        [ HITGROUP_STOMACH ] = ACT_FLINCH_STOMACH,
        [ HITGROUP_LEFTARM ] = ACT_FLINCH_LEFTARM,
        [ HITGROUP_RIGHTARM ] = ACT_FLINCH_RIGHTARM,
        [ HITGROUP_LEFTLEG ] = ACT_FLINCH_LEFTLEG,
        [ HITGROUP_RIGHTLEG ] = ACT_FLINCH_RIGHTLEG,
        [ HITGROUP_GENERIC ] = ACT_FLINCH_PHYSICS,
        [ HITGROUP_GEAR ] = ACT_FLINCH_PHYSICS
    }

    hook.Add( "ScalePlayerDamage", "FlinchOnHit", function( pl, hitgroup, dmginfo )
        local activity = hit_activities[ hitgroup ]
        if activity == nil then
            return
        end

        if not entity_isActivityExists( pl, activity ) then
            local sequence_name

            if hitgroup == HITGROUP_LEFTARM then
                sequence_name = "flinch_shoulder_l"
            elseif hitgroup == HITGROUP_RIGHTARM then
                sequence_name = "flinch_shoulder_r"
            elseif hitgroup == HITGROUP_LEFTLEG then
                sequence_name = "flinch_01"
            elseif hitgroup == HITGROUP_RIGHTLEG then
                sequence_name = "flinch_02"
            end

            if sequence_name ~= nil then
                local sequence_id = Entity_LookupSequence( pl, sequence_name )
                if sequence_id ~= nil and sequence_id > 0 then
                    pl:AddVCDSequenceToGestureSlot( GESTURE_SLOT_FLINCH, sequence_id, 0, true )
                    return
                end
            end

            activity = ACT_FLINCH_STOMACH
        end

        if entity_isActivityExists( pl, activity ) then
            pl:AnimRestartGesture( GESTURE_SLOT_FLINCH, activity, true )
        end
    end, PRE_HOOK )

end

do

    local Entity_GetNW2Float = Entity.GetNW2Float

    hook.Add( "PlayerSpeed", "SpeedScale", function( arguments, pl, mv )
        local speed = arguments[ 2 ]
        if speed ~= nil then
            return speed * Entity_GetNW2Float( pl, "m_fModelScale", 1 )
        end
    end, POST_HOOK_RETURN )

end

do

    ---@type ash.trace.Output
    ---@diagnostic disable-next-line: missing-fields
    local trace_result = {}

    ---@type ash.trace.Params
    local trace = {
        output = trace_result
    }

    ---@param pl Player
    hook.Add( "PlayerSelectsUseEntity", "Defaults", function( pl )
        local start = pl:GetShootPos()

        trace.start = start
        trace.endpos = start + pl:GetAimVector() * hook_Run( "PlayerSelectsUseDistance", pl )
        trace.filter = pl

        trace_cast( trace )

        if trace_result.Hit and not trace_result.HitWorld then
            return trace_result.Entity
        end
    end )

end

hook.Add( "PlayerSelectsUseDistance", "Defaults", function( arguments, pl )
    return ( arguments[ 2 ] or 72 ) * pl:GetNW2Float( "m_fModelScale", 1 )
end, POST_HOOK_RETURN )

if DEBUG then

    ---@type ash.debug
    local debug = require( "ash.debug" )

    ---@param pl Player
    ---@param entity Entity
    hook.Add( "PlayerUsedEntity", "Defaults", function( pl, entity, usage_state )
        if usage_state then
            local mins, maxs = entity:GetCollisionBounds()
            -- local color = entity:GetColor()

            debug.overlay.box( false, entity:GetPos(), entity:GetAngles(), mins, maxs, 50, 240, 120, false, 10 )
        end
    end )

end

---@param str string
---@return integer r
---@return integer g
---@return integer b
function flame_player.toRGB( str )
    local segments = string.byteSplit( str, 0x20 )

    return math.clamp( tonumber( segments[ 1 ] or 0, 10 ) or 0, 0, 255 ),
        math.clamp( tonumber( segments[ 2 ] or 0, 10 ) or 0, 0, 255 ),
        math.clamp( tonumber( segments[ 3 ] or 0, 10 ) or 0, 0, 255 )
end

require( "ash.player.footsteps.dynamic" )

return flame_player
