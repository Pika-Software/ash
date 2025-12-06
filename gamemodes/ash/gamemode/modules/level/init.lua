---@class ash.level
---@field mins Vector The minimum bounds of the current loaded level.
---@field maxs Vector The maximum bounds of the current loaded level.
local ash_level = include( "shared.lua" )

--- [SHARED]
---
--- Changes the server level.
---
---@param name string
function ash_level.change( name )
    if ash_level.exists( name ) then
        timer.Create( "LevelChange", 0, 1, function()
            ash.Logger:info( "Changing level, '%s' -> '%s'", ash_level.name, name )
            RunConsoleCommand( "changelevel", name )
        end )

        return
    end

    error( "Level '" .. name .. "' does not exist!" )
end

hook.Add( "LevelLoaded", "Bounds", function( name, entity )
    local mins, maxs = entity:Entity_GetInternalVariable( "m_WorldMins" ), entity:Entity_GetInternalVariable( "m_WorldMaxs" )
    ash_level.mins, ash_level.maxs = mins, maxs

    hook.Run( "LevelBounds", name, entity, mins, maxs )
end )
