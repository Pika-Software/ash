local OrderVectors = OrderVectors

---@class ash.trigger : ENT
---@field EntityList table
---@field EntityMap table
---@field Mins Vector
---@field Maxs Vector
local ENT = ENT

ENT.Type = "brush"
-- ENT.Base = "base_brush"

local hook_Run = hook.Run

function ENT:setup( mins, maxs )
    OrderVectors( mins, maxs )
    self:SetCollisionBounds( mins, maxs )
    self.Mins = mins
    self.Maxs = maxs
end

function ENT:Initialize()
    self:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )
    self:SetMoveType( MOVETYPE_NONE )
    self:SetSolid( SOLID_BBOX )
    self:DrawShadow( false )
    self:SetNoDraw( true )

    self:SetTrigger( true )
    self:setup( self.Mins, self.Maxs )

    self.EntityList = { [ 0 ] = 0 }
    self.EntityMap = {}
end

---@param entity Entity
function ENT:startTouch( entity ) end

---@param entity Entity
function ENT:endTouch( entity ) end

---@param entity Entity
function ENT:touch( entity ) end

--- [SERVER]
---
--- Checking touching trigger zone.
---
---@param entity Entity
---@return boolean
function ENT:inZone( entity )
    if self.EntityMap[ entity ] then
        return true
    end

    return false
end

function ENT:Touch( entity )
    local entity_map = self.EntityMap
    local entity_list = self.EntityList
    if not entity_map[ entity ] then
        entity_map[ entity ] = true

        local new_count = entity_list[ 0 ] + 1
        entity_list[ 0 ] = new_count

        entity_list[ new_count ] = entity

        self:startTouch( entity )

        hook_Run( "ash.trigger.StartTouch", entity )
    end

    self:touch( entity )
    hook_Run( "ash.trigger.Touch", entity )
end

do
    local table_removeByValue = table.removeByValue

    function ENT:EndTouch( entity )
        local entity_map = self.EntityMap
        local entity_list = self.EntityList

        entity_map[ entity ] = nil

        self:endTouch( entity )
        hook_Run( "ash.trigger.EndTouch", entity )

        if table_removeByValue( entity_list, entity, entity_list[ 0 ] ) ~= nil then
            local new_count = entity_list[ 0 ] - 1
            entity_list[ 0 ] = new_count
        end
    end
end
