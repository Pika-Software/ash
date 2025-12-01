---@class ash.entity.door
local ash_door = {}

local Entity_GetNW2Bool = Entity.GetNW2Bool
local Entity_GetNW2Int = Entity.GetNW2Int

--- [SHARED]
---
--- Checks if the door is locked.
---
---@param entity Entity
---@return boolean is_locked
function ash_door.isLocked( entity )
    return Entity_GetNW2Bool( entity, "m_bLocked", false )
end

--- [SHARED]
---
--- Gets the door's state.
---
---@param entity Entity
---@return ash.entity.door.State state
function ash_door.getState( entity )
    return Entity_GetNW2Int( entity, "m_eDoorState", 0 )
end

return ash_door
