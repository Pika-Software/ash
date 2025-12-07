---@type dreamwork.std
local std = _G.dreamwork.std
local fs = std.fs

---@class ash.level
---@field name string The name of the current loaded level.
---@field entity Entity The entity of the current loaded level.
local ash_level = {}

do

    ---@param entity Entity
    local function load_level( entity )
        if entity == nil or entity == NULL or not entity:IsWorld() then
            return
        end

        local name = game.GetMap()
        if name == nil or string.byte( name, 1, 1 ) == nil then
            return
        end

        ash_level.entity = entity
        ash_level.name = name

        hook.Run( "LevelLoaded", name, entity )
    end

    hook.Add( "WorldEntityCreated", "Initialize", load_level )
    load_level( game.GetWorld() )

end

--- [SHARED]
---
--- Returns all mounted levels.
---
---@return string[]
function ash_level.getAll()
    local levels = file.Find( "maps/*.bsp", "GAME" )

    for i = 1, #levels, 1 do
        levels[ i ] = string.sub( levels[ i ], 1, -5 )
    end

    return levels
end

--- [SHARED]
---
--- Checks if a level exists.
---
---@param name string
---@return boolean
function ash_level.exists( name )
    return fs.isFile( "/workspace/maps/" .. name .. ".bsp" )
end

--- [SHARED]
---
--- Checks if a level has a navigation mesh.
---
---@param name string
---@return boolean
function ash_level.hasNavigationMesh( name )
    return fs.isFile( "/workspace/maps/" .. name .. ".nav" )
end

do

    local physenv_GetGravity = physenv.GetGravity
    local frame_const = FrameTime() / 2

    --- [SHARED]
    ---
    --- Returns the gravity of the current level.
    ---
    ---@return Vector
    function ash_level.getGravity()
        return physenv_GetGravity() * frame_const
    end

end

do

    local util_TraceLine = util.TraceLine

    ---@type TraceResult
    local trace_result = {}

    ---@type Trace
    local trace = {
        output = trace_result,
        collisiongroup = 20
    }

    --- [SHARED]
    ---
    --- Checks if a position is inside the level bounds (inside the world).
    ---
    ---@param origin Vector
    ---@return boolean
    ash_level.isContainsPosition = util.IsInWorld or function( origin )
        trace.start = origin
        trace.endpos = origin

        util_TraceLine( trace )

        return not trace_result.HitWorld
    end

end

return ash_level
