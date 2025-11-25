---@class ash.entity.door
local door_lib = {}

local Entity_GetNW2Bool = Entity.GetNW2Bool
local Entity_GetNW2Int = Entity.GetNW2Int

--- [SHARED]
---
--- Checks if the door is locked.
---
---@param entity Entity
---@return boolean is_locked
function door_lib.isLocked( entity )
    return Entity_GetNW2Bool( entity, "m_bLocked", false )
end

--- [SHARED]
---
--- Gets the door's state.
---
---@param entity Entity
---@return ash.entity.door.State state
function door_lib.getState( entity )
    return Entity_GetNW2Int( entity, "m_eDoorState", 0 )
end

return door_lib
