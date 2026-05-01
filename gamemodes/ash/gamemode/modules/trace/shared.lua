---@type dreamwork.std
local std = dreamwork.std

---@type ash.entity
local ash_entity = import "ash.entity"

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

---@alias ash.trace.Callback fun( params: ash.trace.Params, trace_result: ash.trace.Output ): ash.trace.Params | boolean | nil

---@class ash.trace.Params : HullTrace
---@field maxs Vector | nil The 3D vector that represent the corner with the upper bounds of the box. (if `nil` then trace will be a ray)
---@field mins Vector | nil The 3D vector that represent the corner with the lower bounds of the box. (if `nil` then trace will be a ray)
---@field count integer | nil The number of times the trace will be repeated.
---@field angle Angle | nil The angle to rotate the trace.
---@field penetrate boolean | nil If the trace should be allowed to penetrate solid objects.
---@field callback ash.trace.Callback | nil The callback function to call when the trace is complete.

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

---@alias ash.trace.Filter.ShouldHit fun( entity: Entity, content_masks: CONTENTS ): boolean

---@class ash.trace.Filter : dreamwork.Object
---@field __class ash.trace.FilterClass
---@field PassEntity Entity | nil
---@field CollisionGroup integer | nil
---@field ShouldHit ash.trace.Filter.ShouldHit | nil
local Filter = std.class.base( "ash.trace.Filter", false )

---@class ash.trace.FilterClass : ash.trace.Filter
---@field __base ash.trace.Filter
---@overload fun( pass_entity: Entity, collision_group: integer, should_hit: ash.trace.Filter.ShouldHit ): ash.trace.Filter
local FilterClass = std.class.create( Filter )
ash_trace.Filter = FilterClass

---@param pass_entity Entity
---@param collision_group integer
---@param should_hit ash.trace.Filter.ShouldHit
---@protected
function Filter:__init( pass_entity, collision_group, should_hit )
    self.PassEntity = pass_entity
    self.CollisionGroup = collision_group
    self.ShouldHit = should_hit
end

local Entity_GetMoveType = Entity.GetMoveType
local Entity_GetSolid = Entity.GetSolid
local Entity_GetOwner = Entity.GetOwner

local bit_band = bit.band
local NULL = NULL

---@param entity Entity
---@param content_masks integer
---@return boolean
local function StandardFilterRules( entity, content_masks )
    if entity == nil or entity == NULL then
        return false
    end

    local solid = Entity_GetSolid( entity )

    if not entity_isBrush( entity ) or not ( solid == SOLID_BSP or solid == SOLID_VPHYSICS ) and bit_band( content_masks, CONTENTS_MONSTER ) == 0 then
        return false
    end

    -- This code is used to cull out tests against see-thru entities
    if bit_band( content_masks, CONTENTS_WINDOW ) == 0 and entity_isTransparent( entity ) then
        return false
    end

    -- FIXME: this is to skip BSP models that are entities that can be potentially moved/deleted, similar to a monster but doors don't seem to be flagged as monsters
    -- FIXME: the FL_WORLDBRUSH looked promising, but it needs to be set on everything that's actually a worldbrush and it currently isn't
    -- !(touch->flags & FL_WORLDBRUSH) )

    return not ( bit_band( content_masks, CONTENTS_MOVEABLE ) == 0 or Entity_GetMoveType( entity ) == MOVETYPE_PUSH )
end

---@param entity Entity
---@param pass_entity Entity
---@return boolean
local function PassServerEntityFilter( entity, pass_entity )
    if entity == nil or entity == NULL or pass_entity == nil or pass_entity == NULL then
        return true
    end

    -- don't clip against own missiles
    if Entity_GetOwner( entity ) == pass_entity then
        return false
    end

    -- don't clip against owner
    if Entity_GetOwner( pass_entity ) == entity then
        return false
    end

    return true
end

--- [SHARED]
---
--- Checks if the entity should be hit.
---
---@param entity Entity
---@param content_masks CONTENTS
---@return boolean
function Filter:ShouldHitEntity( entity, content_masks )
    if not StandardFilterRules( entity, content_masks ) then
        return false
    end

    local pass_entity = self.PassEntity
    if pass_entity ~= nil and not PassServerEntityFilter( entity, pass_entity ) then
        return false
    end

    if entity == nil or entity == NULL then
        return false
    end

    -- if not pEntity->ShouldCollide( m_collisionGroup, contentsMask ) then
    --     return false
    -- end

    -- if pEntity and not g_pGameRules->ShouldCollide( m_collisionGroup, pEntity->GetCollisionGroup() ) then
    --     return false
    -- end

    local should_hit = self.ShouldHit
    if should_hit ~= nil and not should_hit( entity, content_masks ) then
        return false
    end

    return true
end

-- traceFilter = CTraceFilterNoCombatCharacters( pass_entity, COLLISION_GROUP_NONE )
-- traceFilter = CTraceFilterSkipTwoEntities( this, pass_entity, COLLISION_GROUP_NONE )

return ash_trace
