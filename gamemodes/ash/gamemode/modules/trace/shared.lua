
---@type dreamwork.std
local std = _G.dreamwork.std

---@type ash.entity
local ash_entity = require( "ash.entity" )

local entity_isTransparent = ash_entity.isTransparent
local entity_isBrush = ash_entity.isBrush

local Vector_Normalize = Vector.Normalize
local Vector_Distance = Vector.Distance
local Vector_Rotate = Vector.Rotate

local util_TraceLine = util.TraceLine
local util_TraceHull = util.TraceHull

local istable = istable
local pairs = pairs

---@class ash.trace
local ash_trace = {}

---@class ash.trace.Params : HullTrace
---@field maxs Vector | nil The 3D vector that represent the corner with the upper bounds of the box. (if `nil` then trace will be a ray)
---@field mins Vector | nil The 3D vector that represent the corner with the lower bounds of the box. (if `nil` then trace will be a ray)
---@field count integer | nil The number of times the trace will be repeated.
---@field angle Angle | nil The angle to rotate the trace.
---@field penetrate boolean | nil If the trace should be allowed to penetrate solid objects.
---@field callback fun( params: ash.trace.Params, trace_result: ash.trace.Output ): ash.trace.Params | boolean | nil The callback function to call when the trace is complete.

---@class ash.trace.Output : TraceResult
---@field Distance number The distance from the start position to the end position.

--- [SHARED]
---
--- Traces a line through the world.
---
---@param params ash.trace.Params
---@return ash.trace.Output output
local function cast( params )
    ---@type ash.trace.Output
    local output = params.output

    if output == nil then
        ---@diagnostic disable-next-line: missing-fields
        output = {}; params.output = output
    end

    if params.mins == nil or params.maxs == nil then
        ---@diagnostic disable-next-line: param-type-mismatch, return-type-mismatch
        util_TraceLine( params )
    else
        ---@diagnostic disable-next-line: return-type-mismatch
        util_TraceHull( params )
    end

    output.Distance = Vector_Distance( params.start, params.endpos )
    params.count = math.max( 0, ( params.count or 1 ) - 1 )

    local callback = params.callback
    local hit_pos = output.HitPos

    if callback == nil then
        params.start = hit_pos
    else
        local result = callback( params, output )
        params.start = hit_pos

        if istable( result ) then
            ---@cast result ash.trace.Params
            for key, value in pairs( result ) do
                params[ key ] = value
            end
        elseif result == false then
            return output
        end
    end

    if params.count == 0 then
        return output
    end

    local start = params.start

    if params.penetrate then
        if Vector_Distance( hit_pos, params.endpos ) <= 1 then
            return output
        end

        params.start = start + output.Normal
    end

    local angle = params.angle

    if angle ~= nil then
        local direction = params.endpos - start
        Vector_Rotate( direction, angle )
        Vector_Normalize( direction )

        if output.Hit then
            params.angle = -angle
        end

        params.endpos = start + direction * output.Distance
    end

    return cast( params )
end

ash_trace.cast = cast

return ash_trace
