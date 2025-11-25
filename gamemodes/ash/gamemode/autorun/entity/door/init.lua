---@class ash.entity.door
local door_lib = {}

local Entity_IsFlagSet, Entity_AddFlags, Entity_RemoveFlags = Entity.IsFlagSet, Entity.AddFlags, Entity.RemoveFlags
local Entity_GetNW2Int, Entity_SetNW2Int = Entity.GetNW2Int, Entity.SetNW2Int
local Entity_GetInternalVariable = Entity.GetInternalVariable
local Entity_SetKeyValue = Entity.SetKeyValue
local Entity_GetClass = Entity.GetClass
local hook_Run = hook.Run

---@type ash.entity
local entity_lib = require( "ash.entity" )
local entity_sendInput = entity_lib.sendInput

--- [SHARED]
---
--- Checks if the door is locked.
---
---@param entity Entity
---@return boolean is_locked
function door_lib.isLocked( entity )
    return Entity_GetInternalVariable( entity, "m_bLocked" )
end

--- [SHARED]
---
--- Sets the door's locked state.
---
---@param entity Entity
---@param locked boolean
function door_lib.setLocked( entity, locked )
    if locked then
        if Entity_GetInternalVariable( entity, "m_bLocked" ) then
            return
        end

        entity_sendInput( entity, "Lock" )
    elseif Entity_GetInternalVariable( entity, "m_bLocked" ) then
        entity_sendInput( entity, "Unlock" )
    end
end

---@alias ash.entity.door.State
---| `0` Door is closed.
---| `1` Door is opening.
---| `2` Door is open.
---| `3` Door is closing.
---| `4` Door is slightly open (ajar).

--- [SHARED]
---
--- Gets the door's state.
---
---@param entity Entity
---@return ash.entity.door.State state
function door_lib.getState( entity )
    if Entity_GetClass( entity ) == "prop_door_rotating" then
        return Entity_GetInternalVariable( entity, "m_eDoorState" )
    end

    return 0
end

--- [SHARED]
---
--- Opens the door.
---
---@param entity Entity
---@param delay number | nil
---@param activator Entity | nil
---@param caller Entity | nil
function door_lib.open( entity, delay, activator, caller )
    entity_sendInput( entity, "Open", nil, delay, activator, caller )
end

--- [SHARED]
---
--- Closes the door.
---
---@param entity Entity
---@param delay number | nil
---@param activator Entity | nil
---@param caller Entity | nil
function door_lib.close( entity, delay, activator, caller )
    entity_sendInput( entity, "Close", nil, delay, activator, caller )
end

--- [SHARED]
---
--- Toggles the door.
---
---@param entity Entity
---@param delay number | nil
---@param activator Entity | nil
---@param caller Entity | nil
function door_lib.toggle( entity, delay, activator, caller )
    entity_sendInput( entity, "Toggle", nil, delay, activator, caller )
end

--- [SHARED]
---
--- Locks the door.
---
---@param entity Entity
---@param delay number | nil
---@param activator Entity | nil
---@param caller Entity | nil
function door_lib.lock( entity, delay, activator, caller )
    entity_sendInput( entity, "Lock", nil, delay, activator, caller )
end

--- [SHARED]
---
--- Unlocks the door.
---
---@param entity Entity
---@param delay number | nil
---@param activator Entity | nil
---@param caller Entity | nil
function door_lib.unlock( entity, delay, activator, caller )
    entity_sendInput( entity, "Unlock", nil, delay, activator, caller )
end

--- [SHARED]
---
--- Opens the door away from the specified entity.
---
---@param entity Entity
---@param away_entity Entity
---@param delay number | nil
---@param activator Entity | nil
---@param caller Entity | nil
function door_lib.openAwayFrom( entity, away_entity, delay, activator, caller )
    entity_sendInput( entity, "OpenAwayFrom", away_entity, delay, activator, caller )
end

--- [SHARED]
---
--- Gets the rotation distance of the door.
---
---@param entity Entity
---@return number distance
function door_lib.getRotationDistance( entity )
    return Entity_GetInternalVariable( entity, "distance" )
end

--- [SHARED]
---
--- Sets the rotation distance of the door.
---
--- Degrees of rotation that the door will open.
---
---@param entity Entity
---@param distance number
---@param delay number | nil
function door_lib.setRotationDistance( entity, distance, delay )
    entity_sendInput( entity, "SetRotationDistance", distance, delay )
end

--- [SHARED]
---
--- Sets the open distance (in degrees) and moves there.
---
---@param entity Entity
---@param distance number
---@param delay number | nil
---@param activator Entity | nil
---@param caller Entity | nil
function door_lib.moveTo( entity, distance, delay, activator, caller )
    entity_sendInput( entity, "MoveToRotationDistance", distance, delay, activator, caller )
end

--- [SHARED]
---
--- Gets the speed at which the door rotates.
---
---@param entity Entity
---@return number
function door_lib.getSpeed( entity )
    return Entity_GetInternalVariable( entity, "speed" )
end

--- [SHARED]
---
--- Set the speed at which the door rotates.
---
---@param entity Entity
---@param speed number
function door_lib.setSpeed( entity, speed )
    Entity_SetKeyValue( entity, "speed", speed )
    -- entity_sendInput( entity, "SetSpeed", speed, delay, activator, caller )
end

---@alias ash.entity.door.OpenDirection
---| `0` Both directions
---| `1` Forward only
---| `2` Backward only

--- [SHARED]
---
--- Gets the open direction of the door.
---
---@param entity Entity
---@return ash.entity.door.OpenDirection direction
function door_lib.getOpenDirection( entity )
    return Entity_GetInternalVariable( entity, "opendir" )
end

--- [SHARED]
---
--- Sets the open direction of the door.
---
---@param entity Entity
---@param direction ash.entity.door.OpenDirection
function door_lib.setOpenDirection( entity, direction )
    Entity_SetKeyValue( entity, "opendir", direction )
end

--- [SHARED]
---
--- Checks if the door is silent.
---
---@param entity Entity
---@return boolean is_silent
function door_lib.isSilent( entity )
    return Entity_IsFlagSet( entity, 4096 )
end

--- [SHARED]
---
--- Sets the silent state of the door.
---
---@param entity Entity
---@param silent boolean
function door_lib.setSilent( entity, silent )
    if silent then
        if Entity_IsFlagSet( entity, 4096 ) then
            return
        end

        Entity_AddFlags( entity, 4096 )
    elseif Entity_IsFlagSet( entity, 4096 ) then
        Entity_RemoveFlags( entity, 4096 )
    end
end

--- [SHARED]
---
--- Destroys the door.
---
---@param entity Entity
---@param delay number | nil
---@param activator Entity | nil
---@param caller Entity | nil
function door_lib.destroy( entity, delay, activator, caller )
    entity_sendInput( entity, "Break", nil, delay, activator, caller )
end

do

    local table_remove = table.remove

    ---@type Entity[]
    local doors = {}

    ---@type integer
    local door_count = 0

    timer.Create( "StateHandler", 0.25, 0, function()
		for i = 1, door_count, 1 do
            local entity = doors[ i ]

            local state = Entity_GetInternalVariable( entity, "m_eDoorState" )
            if Entity_GetNW2Int( entity, "m_eDoorState" ) ~= state then
                local previous_state = Entity_GetNW2Int( entity, "m_eDoorState" )
                Entity_SetNW2Int( entity, "m_eDoorState", state )
                hook_Run( "DoorEntityStateChanged", entity, state, previous_state )
            end
        end
	end )

    hook.Add( "DoorEntityCreated", "CreationHandler", function( door_entity, class_name )
        if class_name == "prop_door_rotating" then
            door_count = door_count + 1
            doors[ door_count ] = door_entity
        end
    end, PRE_HOOK )

    hook.Add( "DoorEntityRemoved", "RemovalHandler", function( entity, class_name, is_full_update )
        if not is_full_update and class_name == "prop_door_rotating" then
            for i = door_count, 1, -1 do
                if doors[ i ] == entity then
                    table_remove( doors, i )
                    break
                end
            end
        end
    end, PRE_HOOK )

end

return door_lib
