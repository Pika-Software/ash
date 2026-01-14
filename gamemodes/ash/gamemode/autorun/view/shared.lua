local Vector_Normalize = Vector.Normalize
local Vector_Dot = Vector.Dot

local Angle_Forward = Angle.Forward

local math_acos = math.acos
local math_deg = math.deg

local Entity_GetNW2Var = Entity.GetNW2Var

---@type ash.trace
local ash_trace = require( "ash.trace" )
local trace_cast = ash_trace.cast

---@class ash.view
local ash_view = {}

--- [SERVER]
---
--- Gets the player's aim vector.
---
---@param pl Player
---@return Vector aim
function ash_view.getAimVector( pl )
    return Entity_GetNW2Var( pl, "m_vAim", pl:GetAimVector() )
end

--- [SHARED]
---
--- Gets the player's eye origin.
---
---@param pl Player
---@return Vector origin
function ash_view.getEyeOrigin( pl )
    return Entity_GetNW2Var( pl, "m_vEyeOrigin", pl:EyePos() )
end

--- [SHARED]
---
--- Get the angle to look at a position from a position.
---
---@param view_origin Vector
---@param view_angles Angle
---@param observed_position Vector
---@return number angle
local function getAngle( view_origin, view_angles, observed_position )
    local direction = observed_position - view_origin
    Vector_Normalize( direction )

    return math_deg( math_acos( Vector_Dot( Angle_Forward( view_angles ), direction ) ) )
end

ash_view.getAngle = getAngle

--- [SHARED]
---
--- Checks if a position is inside the field of view of an observer.
---
---@param view_origin Vector
---@param view_angles Angle
---@param view_fov number
---@param observed_position Vector
local function isInFOV( view_origin, view_angles, view_fov, observed_position )
    return getAngle( view_origin, view_angles, observed_position ) <= view_fov
end

ash_view.isInFOV = isInFOV

---@type ash.trace.Output
local trace_result = {}

---@type ash.trace.Params
local trace = {
    output = trace_result
}

local mask_with_actors = bit.bor( MASK_OPAQUE, CONTENTS_IGNORE_NODRAW_OPAQUE )
local mask_without_actors = bit.bor( mask_with_actors, CONTENTS_MONSTER )

--- [SHARED]
---
--- Checks if a line of sight is clear between two positions.
---
---@param view_origin Vector
---@param observed_position Vector
---@param ignore_actors? boolean
---@param filter? fun( entity: Entity ): boolean
---@param collision_group? integer
---@return boolean
local function isLineOfSightClear( view_origin, observed_position, ignore_actors, filter, collision_group )
    trace.start = view_origin
    trace.endpos = observed_position

    trace.mask = ignore_actors == true and mask_without_actors or mask_with_actors

    ---@diagnostic disable-next-line: assign-type-mismatch
    trace.filter = filter

    if collision_group == nil then
        trace.collisiongroup = 0
    else
        trace.collisiongroup = collision_group
    end

    trace_cast( trace )

    return trace_result.Fraction == 1
end

ash_view.isLineOfSightClear = isLineOfSightClear

local Vector_DistToSqr = Vector.DistToSqr

local default_distance = 512 ^ 2

function ash_view.isScreenVisible( entity, view_origin, view_angles, view_fov, view_distance, observed_position )
    return Vector_DistToSqr( view_origin, observed_position ) <= view_distance and entity:IsLineOfSightClear( observed_position ) and isInFOV( view_origin, view_angles, view_fov, observed_position )
end

return ash_view
