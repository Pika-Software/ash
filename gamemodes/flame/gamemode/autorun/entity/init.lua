---@type ash.entity.door
local ash_door = require( "ash.entity.door" )

hook.Add( "ash.entity.door.State", "DoorUnlocker", function( entity, state )
    if state ~= 0 and ash_door.isLocked( entity ) then
        ash_door.unlock( entity )
    end
end )

do

    ---@type table<integer, integer>
    local state2state = {
        [ 0 ] = 1,
        [ 1 ] = 0,
        [ 2 ] = 0,
        [ 3 ] = 1,
        [ 4 ] = 0
    }

    hook.Add( "ash.player.SelectsUseType", "Default", function( pl, entity )
        if entity:GetClass() == "prop_door_rotating" then
            return state2state[ ash_door.getState( entity ) ] or 0
        end
    end )

end
