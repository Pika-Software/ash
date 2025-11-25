MODULE.ClientFiles = {
    "shared.lua"
}

include( "shared.lua" )

---@type ash.sound
local sound_lib = require( "ash.sound" )
local sound_play = sound_lib.play

---@type ash.player
local player_lib = require( "ash.player" )
local player_getMoveState = player_lib.getMoveState

---@type ash.footsteps
local footsteps_lib = require( "ash.player.footsteps" )
local footplayer_getShoesType = footsteps_lib.getShoesType

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

    if move_state == "swimming" then
        sound_play( sound_name, origin, nil, nil, volume, 1 )
    else

        trace.start = origin
        trace.endpos = origin - pl:EyePos()
        trace.filter = pl

        util_TraceLine( trace )

        if Entity_WaterLevel( pl ) == 0 then
            local surface_data = util_GetSurfaceData( trace_result.SurfaceProps )
            if surface_data == nil then
                sound_play( sound_name, trace_result.HitPos, nil, nil, volume, 1 )
            else
                hook_Run( "PlayerFootDown", pl, trace_result.HitPos, footplayer_getShoesType( pl ), surface_data.name, move_state, -1 )
            end
        else
            hook_Run( "PlayerFootDown", pl, trace_result.HitPos, footplayer_getShoesType( pl ), "water", move_state, -1 )
        end

    end

    return true
end )
