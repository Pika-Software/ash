---@class ash.entity.door
local ash_door = {}

local Entity_IsFlagSet, Entity_AddFlags, Entity_RemoveFlags = Entity.IsFlagSet, Entity.AddFlags, Entity.RemoveFlags
local hook_Run = hook.Run

---@type ash.entity
local ash_entity = require( "ash.entity" )

local entity_getEngineValue, entity_setEngineValue = ash_entity.getEngineValue, ash_entity.setEngineValue
local entity_getClassName = ash_entity.getClassName
local entity_sendInput = ash_entity.sendInput

--- [SHARED]
---
--- Checks if the door is locked.
---
---@param entity Entity
---@return boolean is_locked
---@diagnostic disable-next-line: duplicate-set-field
function ash_door.isLocked( entity )
    return entity_getEngineValue( entity, "m_bLocked" )
end

--- [SHARED]
---
--- Sets the door's locked state.
---
---@param entity Entity
---@param locked boolean
function ash_door.setLocked( entity, locked )
    if locked then
        if entity_getEngineValue( entity, "m_bLocked" ) then
            return
        end

        entity_sendInput( entity, "Lock" )
    elseif entity_getEngineValue( entity, "m_bLocked" ) then
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
---@diagnostic disable-next-line: duplicate-set-field
function ash_door.getState( entity )
    if entity_getClassName( entity ) == "prop_door_rotating" then
        return entity_getEngineValue( entity, "m_eDoorState" )
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
function ash_door.open( entity, delay, activator, caller )
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
function ash_door.close( entity, delay, activator, caller )
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
function ash_door.toggle( entity, delay, activator, caller )
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
function ash_door.lock( entity, delay, activator, caller )
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
function ash_door.unlock( entity, delay, activator, caller )
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
function ash_door.openAwayFrom( entity, away_entity, delay, activator, caller )
    entity_sendInput( entity, "OpenAwayFrom", away_entity, delay, activator, caller )
end

--- [SHARED]
---
--- Gets the rotation distance of the door.
---
---@param entity Entity
---@return number distance
function ash_door.getRotationDistance( entity )
    return entity_getEngineValue( entity, "distance" )
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
function ash_door.setRotationDistance( entity, distance, delay )
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
function ash_door.moveTo( entity, distance, delay, activator, caller )
    entity_sendInput( entity, "MoveToRotationDistance", distance, delay, activator, caller )
end

--- [SHARED]
---
--- Gets the speed at which the door rotates.
---
---@param entity Entity
---@return number
function ash_door.getSpeed( entity )
    return entity_getEngineValue( entity, "speed" )
end

--- [SHARED]
---
--- Set the speed at which the door rotates.
---
---@param entity Entity
---@param speed number
function ash_door.setSpeed( entity, speed )
    entity_setEngineValue( entity, "speed", speed )
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
function ash_door.getOpenDirection( entity )
    return entity_getEngineValue( entity, "opendir" )
end

--- [SHARED]
---
--- Sets the open direction of the door.
---
---@param entity Entity
---@param direction ash.entity.door.OpenDirection
function ash_door.setOpenDirection( entity, direction )
    entity_setEngineValue( entity, "opendir", direction )
end

--- [SHARED]
---
--- Checks if the door is silent.
---
---@param entity Entity
---@return boolean is_silent
function ash_door.isSilent( entity )
    return Entity_IsFlagSet( entity, 4096 )
end

--- [SHARED]
---
--- Sets the silent state of the door.
---
---@param entity Entity
---@param silent boolean
function ash_door.setSilent( entity, silent )
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
function ash_door.destroy( entity, delay, activator, caller )
    entity_sendInput( entity, "Break", nil, delay, activator, caller )
end

do

    local Entity_GetNW2Bool, Entity_SetNW2Bool = Entity.GetNW2Bool, Entity.SetNW2Bool
    local Entity_GetNW2Int, Entity_SetNW2Int = Entity.GetNW2Int, Entity.SetNW2Int
    local table_remove = table.remove

    ---@type Entity[]
    local doors = {}

    ---@type integer
    local door_count = 0

    timer.Create( "StateHandler", 0.25, 0, function()
		for i = 1, door_count, 1 do
            local entity = doors[ i ]

            local state = entity_getEngineValue( entity, "m_eDoorState" )

            if Entity_GetNW2Int( entity, "m_eDoorState" ) ~= state then
                hook_Run( "ash.entity.door.State", entity, Entity_GetNW2Int( entity, "m_eDoorState" ), state )
                Entity_SetNW2Int( entity, "m_eDoorState", state )
            end

            local is_locked = entity_getEngineValue( entity, "m_bLocked" )
            if Entity_GetNW2Bool( entity, "" ) ~= is_locked then
                Entity_SetNW2Bool( entity, "m_bLocked", is_locked )
                hook_Run( "ash.entity.door.Lock", entity, is_locked )
            end
        end
	end )

    hook.Add( "ash.entity.DoorCreated", "CreationHandler", function( door_entity, class_name )
        if class_name == "prop_door_rotating" then
            door_count = door_count + 1
            doors[ door_count ] = door_entity
        end
    end, PRE_HOOK )

    hook.Add( "ash.entity.DoorRemoved", "RemovalHandler", function( entity, class_name, is_full_update )
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

return ash_door
