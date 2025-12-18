---@type dreamwork.std
local std = _G.dreamwork.std
local fs = std.fs

---@class ash.level
---@field Name string The name of the current loaded level.
---@field Model string The model of the current loaded level.
---@field Entity Entity The entity of the current loaded level.
local ash_level = {}

do

    local coroutine_resume = coroutine.resume
    local coroutine_yield = coroutine.yield

    ---@param entity Entity
    ---@param name string
    hook.Add( "WorldEntityCreated", "Initialize", function( entity, name )
        if entity == nil or entity == NULL or not entity:IsWorld() or name == nil or string.byte( name, 1, 1 ) == nil then
            return
        end

        ---@diagnostic disable-next-line: assign-type-mismatch
        ash_level.Model = entity:GetModel()
        ash_level.Entity = entity
        ash_level.Name = name

        ash.Logger:info( "Game level '%s' loaded!", name )
        hook.Run( "LevelLoaded", name, entity )
    end )

    local world_entity

    local thread = coroutine.create( function()
        ::retry_loop::

        world_entity = game.GetWorld()


        if world_entity == nil or world_entity == NULL then
            coroutine_yield( false )
            goto retry_loop
        end

        ash_level.Entity = world_entity

        hook.Run( "WorldEntityCreated", world_entity, game.GetMap() )
        coroutine_yield( true )
    end )

    local function world_find()
        local success, is_ready = coroutine_resume( thread )
        return not success or is_ready
    end

    if not world_find() then
        hook.Add( "InitPostEntity", "WorldInit", function()
            if world_find() then
                hook.Remove( "InitPostEntity", "WorldInit" )
                return
            end

            timer.Create( "await", 0.05, 0, function()
                if world_find() then
                    timer.Remove( "await" )
                end
            end )
        end )
    end

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
    ash_level.containsPosition = util.IsInWorld or function( origin )
        trace.start = origin
        trace.endpos = origin

        util_TraceLine( trace )

        return not trace_result.HitWorld
    end

end

return ash_level
