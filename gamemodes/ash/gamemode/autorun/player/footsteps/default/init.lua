include( "shared.lua" )

---@type ash.player
local player_lib = require( "ash.player" )
local player_getMoveState = player_lib.getMoveState

---@type ash.footsteps
local footsteps_lib = require( "ash.player.footsteps" )
local footsteps_getShoesType = footsteps_lib.getShoesType

local util_GetSurfaceData = util.GetSurfaceData
local util_TraceLine = util.TraceLine

local Entity_WaterLevel = Entity.WaterLevel

local hook_Run = hook.Run

---@type TraceResult
local trace_result = {}

---@type Trace
local trace = {
    output = trace_result
}

hook.Add( "PlayerFootstep", "ServerSounds", function( pl, origin, _, sound_name, volume )
    local move_state = player_getMoveState( pl )
    if move_state ~= "swimming" then
        trace.start = origin
        trace.endpos = origin - pl:EyePos()
        trace.filter = pl

        util_TraceLine( trace )

        local material_name

        if Entity_WaterLevel( pl ) == 0 then
            local surface_data = util_GetSurfaceData( trace_result.SurfaceProps )
            if surface_data ~= nil then
                material_name = surface_data.name
                sound_name = surface_data.impactSoftSound
            end
        else
            material_name = "water"
        end

        hook_Run( "PlayerFootDown", pl, trace_result.HitPos, footsteps_getShoesType( pl ), material_name, move_state, -1, sound_name )
    end

    return true
end )
