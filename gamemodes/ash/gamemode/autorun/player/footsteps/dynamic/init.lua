include( "shared.lua" )

---@type ash.footsteps
local footsteps_lib = require( "ash.player.footsteps" )
local footplayer_getShoesType = footsteps_lib.getShoesType

---@type ash.entity
local entity_lib = require( "ash.entity" )
local entity_getHitbox = entity_lib.getHitbox
local entity_getHitboxBounds = entity_lib.getHitboxBounds

---@type ash.player
local player_lib = require( "ash.player" )
local player_getMoveState = player_lib.getMoveState

local Entity_GetBonePosition = Entity.GetBonePosition
local Entity_GetBoneMatrix = Entity.GetBoneMatrix
local Entity_GetBoneCount = Entity.GetBoneCount
local Entity_GetBoneName = Entity.GetBoneName
local Entity_GetMoveType = Entity.GetMoveType
local Entity_WaterLevel = Entity.WaterLevel

local Matrix_GetTranslation = Matrix.GetTranslation
local Vector_Normalize = Vector.Normalize
local Vector_Distance = Vector.Distance

local util_GetSurfaceData = util.GetSurfaceData
local util_TraceHull = util.TraceHull
local util_TraceLine = util.TraceLine

local string_match = string.match

local hook_Run = hook.Run

---@type TraceResult
local trace_result = {}

---@type HullTrace | Trace
local trace = {
    output = trace_result
}

---@type table<Player, table<integer, boolean>>
local foot_states = {}

setmetatable( foot_states, {
    __mode = "k",
    __index = function( self, pl )
        local bone_ids = {}
        self[ pl ] = bone_ids
        return bone_ids
    end
} )

hook.Add( "PlayerPostThink", "FootstepsThink", function( pl )
    if Entity_GetMoveType( pl ) ~= 2 --[[ MOVETYPE_WALK ]] then return end

    local move_state = player_getMoveState( pl )
    if move_state == "swimming" then return end

    local water_level = Entity_WaterLevel( pl )
    local player_shoes = footplayer_getShoesType( pl )

    for bone_id = 0, Entity_GetBoneCount( pl ) - 1, 1 do
        local bone_name = Entity_GetBoneName( pl, bone_id )
        if bone_name ~= nil and string_match( bone_name, "^ValveBiped.Bip%d+_%w_Foot$" ) ~= nil then
            local bone_matrix = Entity_GetBoneMatrix( pl, bone_id )
            if bone_matrix ~= nil then
                local bone_position = Matrix_GetTranslation( bone_matrix )
                trace.start = bone_position

                local root_matrix = Entity_GetBoneMatrix( pl, 0 )
                local root_position

                if root_matrix == nil then
                    root_position = Entity_GetBonePosition( pl, 0 ) or pl:WorldSpaceCenter()
                else
                    root_position = Matrix_GetTranslation( root_matrix )
                end

                local bone_direction = ( root_position - bone_position )
                Vector_Normalize( bone_direction )

                trace.endpos = bone_position - bone_direction * 5 -- Vector_Distance( root_position, bone_position ) * 0.25
                trace.filter = pl

                local hitbox, hitbox_group = entity_getHitbox( pl, bone_id )

                if hitbox == nil then
                    ---@cast trace Trace
                    util_TraceLine( trace )
                else
                    ---@diagnostic disable-next-line: assign-type-mismatch
                    trace.mins, trace.maxs = entity_getHitboxBounds( pl, hitbox, hitbox_group )
                    ---@cast trace HullTrace
                    util_TraceHull( trace )
                end

                local hit_ground = trace_result.Hit

                if hit_ground ~= foot_states[ pl ][ bone_id ] then
                    foot_states[ pl ][ bone_id ] = hit_ground

                    local material_name, fallback_sound

                    if water_level == 0 then
                        local surface_data = util_GetSurfaceData( trace_result.SurfaceProps )
                        if surface_data ~= nil then
                            material_name = surface_data.name
                            fallback_sound = surface_data.impactSoftSound
                        end
                    else
                        material_name = "water"
                    end

                    if hit_ground then
                        hook_Run( "PlayerFootDown", pl, trace_result.HitPos, player_shoes, material_name, move_state, bone_id, fallback_sound )
                    else
                        hook_Run( "PlayerFootUp", pl, trace_result.HitPos, player_shoes, material_name, move_state, bone_id, fallback_sound )
                    end
                end
            end
        end
    end
end, PRE_HOOK )
