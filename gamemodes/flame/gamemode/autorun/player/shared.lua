local hook_Run = hook.Run

---@class flame.player
local flame_player = {}

---@type ash.entity
local ash_entity = require( "ash.entity" )

---@type ash.player
local ash_player = require( "ash.player" )
local player_startGestureBySequence = ash_player.startGestureBySequence
local player_startGestureByActivity = ash_player.startGestureByActivity

---@type ash.trace
local ash_trace = require( "ash.trace" )
local trace_cast = ash_trace.cast

---@type ash.view
local ash_view = require( "ash.view" )

hook.Add( "PhysgunPickup", "Defaults", function( arguments, pl, entity )
    return arguments[ 2 ] ~= false
end, POST_HOOK_RETURN )

if SERVER then

    local entity_isActivityExists = ash_entity.isActivityExists

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
                player_startGestureBySequence( pl, 4, sequence_name, 0, true )
            end

            activity = ACT_FLINCH_STOMACH
        end

        if entity_isActivityExists( pl, activity ) then
            player_startGestureByActivity( pl, 4, activity, 0, true )
        end
    end, PRE_HOOK )

end

do

    local Entity_GetNW2Float = Entity.GetNW2Float

    local function move_speed_multiplier( arguments, pl )
        local speed = arguments[ 2 ]
        if speed ~= nil then
            return speed * Entity_GetNW2Float( pl, "m_fModelScale", 1 )
        end
    end

    hook.Add( "ash.player.LadderSpeed", "SpeedModifier", move_speed_multiplier, POST_HOOK_RETURN )
    hook.Add( "ash.player.WalkSpeed", "SpeedModifier", move_speed_multiplier, POST_HOOK_RETURN )
    hook.Add( "ash.player.SwimSpeed", "SpeedModifier", move_speed_multiplier, POST_HOOK_RETURN )

end

---@type ash.debug
local debug = require( "ash.debug" )

do

    ---@type ash.trace.Output
    ---@diagnostic disable-next-line: missing-fields
    local trace_result = {}

    ---@type ash.trace.Params
    local trace = {
        output = trace_result
    }

    local player_getUseDistance = ash_player.getUseDistance
    local ents_FindInSphere = ents.FindInSphere

    local view_getAimVector = ash_view.getAimVector

    ---@param pl Player
    hook.Add( "ash.player.SelectsUseEntity", "Defaults", function( pl )
        local start = pl:EyePos()

        trace.start = start
        trace.endpos = start + view_getAimVector( pl ) * player_getUseDistance( pl )
        trace.filter = pl

        trace_cast( trace )

        if not trace_result.Hit or trace_result.StartSolid then
            return
        end

        if not trace_result.HitWorld then
            local entity = trace_result.Entity
            if hook_Run( "ash.player.ShouldUse", pl, entity ) ~= false then
                return entity
            end
        end

        local entites = ents_FindInSphere( trace_result.HitPos, 1 )

        for i = 1, #entites, 1 do
            local entity = entites[ i ]
            if entity ~= pl and hook_Run( "ash.player.ShouldUse", pl, entity ) ~= false then
                return entity
            end
        end
    end )

end

if DEBUG then

    ---@param pl Player
    ---@param entity Entity
    hook.Add( "ash.player.UsedEntity", "Defaults", function( pl, entity, in_use )
        if in_use then
            local mins, maxs = entity:GetCollisionBounds()
            debug.overlay.box( false, entity:GetPos(), entity:GetAngles(), mins, maxs, 50, 240, 120, false, 10 )
        end
    end )

end

---@param str string
---@return integer r
---@return integer g
---@return integer b
function flame_player.V3toRGB( str )
    local segments = string.byteSplit( string.byteTrim( str, 0x20 --[[ space ]] ), 0x20 --[[ space ]] )

    return math.clamp( ( tonumber( segments[ 1 ] or 0, 10 ) or 0 ) * 255, 0, 255 ),
        math.clamp( ( tonumber( segments[ 2 ] or 0, 10 ) or 0 ) * 255, 0, 255 ),
        math.clamp( ( tonumber( segments[ 3 ] or 0, 10 ) or 0 ) * 255, 0, 255 )
end


---@param str string
---@return integer r
---@return integer g
---@return integer b
---@return integer a
function flame_player.StoRGB( str )
    local segments = string.byteSplit( string.byteTrim( str, 0x20 --[[ space ]] ), 0x20 --[[ space ]] )

    return math.clamp( tonumber( segments[ 1 ] or 0, 10 ) or 0, 0, 255 ),
        math.clamp( tonumber( segments[ 2 ] or 0, 10 ) or 0, 0, 255 ),
        math.clamp( tonumber( segments[ 3 ] or 0, 10 ) or 0, 0, 255 ),
        255
end

require( "ash.player.footsteps.dynamic" )

---@param pl Player
hook.Add( "ash.player.CanNoclip", "Defaults", function( pl )
    if pl:IsSuperAdmin() then return true end
end )

do

    local util_TraceLine = util.TraceLine

    ---@type TraceResult
    local trace_result = {}

    ---@type Trace
    local trace = {
        output = trace_result
    }

    ---@param pl Player
    ---@param data Bullet
    local function data_setup( pl, data )
        local eye_pos = pl:EyePos()
        local shoot_pos = pl:GetShootPos()
        data.Src = shoot_pos

        trace.start = eye_pos
        trace.endpos = eye_pos + pl:GetAimVector() * 16384
        trace.filter = pl

        util_TraceLine( trace )

        data.Dir = ( ( trace_result.HitPos or trace.endpos ) - shoot_pos ):GetNormalized()
    end

    ---@param entity Entity
    ---@param data Bullet
    hook.Add( "EntityFireBullets", "BulletFix", function( entity, data )
        if entity:IsPlayer() then
            ---@cast entity Player
            data_setup( entity, data )
        elseif entity:IsWeapon() then
            local owner = entity:GetOwner()
            if owner and owner:IsValid() and owner:IsPlayer() then
                ---@cast owner Player
                data_setup( owner, data )
            end
        end
    end, PRE_HOOK )

end

do

    local Player_AddVCDSequenceToGestureSlot = Player.AddVCDSequenceToGestureSlot

    local Entity_GetLayerSequence = Entity.GetLayerSequence
    local Entity_SetLayerWeight = Entity.SetLayerWeight
    local Entity_LookupSequence = Entity.LookupSequence

    local player_isTyping = ash_player.isTyping

    local math_clamp = math.clamp
    local FrameTime = FrameTime

    ---@type table<Player, number>
    local fractions = {}
    gc.setTableRules( fractions, true )

    hook.Add( "UpdateAnimation", "TypeAnim", function( pl )
        local fraction = fractions[ pl ] or 0

        if player_isTyping( pl ) then
            fraction = math_clamp( fraction + FrameTime() * 2.5, 0, 1 )
        elseif fraction ~= 0 then
            fraction = math_clamp( fraction - FrameTime() * 2.5, 0, 1 )
        else
            return
        end

        Entity_SetLayerWeight( pl, 5, fraction )
        fractions[ pl ] = fraction

        if fraction == 0 then
            fractions[ pl ] = nil
            return
        end

        local idle_sequence = Entity_LookupSequence( pl, "agl_texting_idle" )
        if idle_sequence == nil or idle_sequence < 1 then
            idle_sequence = Entity_LookupSequence( pl, "gesture_voicechat" )
            if idle_sequence == nil or idle_sequence < 1 then
                idle_sequence = 0
            end
        end

        if idle_sequence ~= 0 and Entity_GetLayerSequence( pl, 5 ) ~= idle_sequence then
            Player_AddVCDSequenceToGestureSlot( pl, 5, idle_sequence, 0, false )
        end
    end )

end

do

    local player_isInVehicle = ash_player.isInVehicle
    local ACT_MP_STAND_IDLE = ACT_MP_STAND_IDLE

    hook.Add( "CalcMainActivity", "PrisonerPod", function( pl )
        if player_isInVehicle( pl ) and pl:GetNW2Bool( "m_bInPrisonerPod" ) then
            return ACT_MP_STAND_IDLE, pl:LookupSequence( "drive_pd" ) or -1
        end
    end )

end

return flame_player
