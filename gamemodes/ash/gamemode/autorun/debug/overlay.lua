local std = _G.dreamwork.std
local angle_zero = angle_zero
local os_clock = os.clock
local assert = std.assert
local arg = std.arg

local render_DrawWireframeBox = render.DrawWireframeBox
local render_SetMaterial = render.SetMaterial
local render_DrawLine = render.DrawLine
local render_DrawBox = render.DrawBox

local cam_Start3D2D = cam.Start3D2D
local cam_End3D2D = cam.End3D2D
local cam_IgnoreZ = cam.IgnoreZ

---@class ash.debug.overlay
local overlay = {}


---@type function[]
local queue = {}

---@type integer
local queue_size = 0

local function gen( lifetime, fn )
    local death_time = os_clock() + math.max( lifetime or 0, 0.5 )

    local index = queue_size + 1
    queue_size = index

    queue[ index ] = function()
        if os_clock() > death_time then
            table.remove( queue, index )
            queue_size = queue_size - 1
            return
        end

        fn()
    end
end

---@param start_position Vector
---@param end_position Vector
---@param r? integer
---@param g? integer
---@param b? integer
---@param write_depth? boolean
---@param lifetime? number
local function line( start_position, end_position, r, g, b, write_depth, lifetime )
    assert( arg( start_position, 1, "Vector" ) )
    assert( arg( end_position, 2, "Vector" ) )

    local color = Color( r or 255, g or 255, b or 255, 255 )
    write_depth = write_depth ~= false

    return gen( lifetime, function()
        render_DrawLine( start_position, end_position, color, write_depth )
    end )
end

overlay.line = line

---@param origin Vector
---@param size Vector
---@param r? integer
---@param g? integer
---@param b? integer
---@param write_depth? boolean
---@param lifetime? number
function overlay.cross( origin, size, r, g, b, write_depth, lifetime )
    assert( arg( origin, 1, "Vector" ) )
    assert( arg( size, 2, "number" ) )

    local color = Color( r or 255, g or 255, b or 255, 255 )
    write_depth = write_depth ~= false

    local x_start = Vector( origin.x - size.x, origin.y, origin.z )
    local x_end = Vector( origin.x + size.x, origin.y, origin.z )

    local y_start = Vector( origin.x, origin.y - size.y, origin.z )
    local y_end = Vector( origin.x, origin.y + size.y, origin.z )

    local z_start = Vector( origin.x, origin.y, origin.z - size.z )
    local z_end = Vector( origin.x, origin.y, origin.z + size.z )

    return gen( lifetime, function()
        render_DrawLine( x_start, x_end, color, write_depth )
        render_DrawLine( y_start, y_end, color, write_depth )
        render_DrawLine( z_start, z_end, color, write_depth )
    end )
end

local matColorIgnoreZ = Material( "color_ignorez" )

---@param filled boolean
---@param origin Vector
---@param angles? Angle
---@param mins Vector
---@param maxs Vector
---@param r? integer
---@param g? integer
---@param b? integer
---@param write_depth? boolean
---@param lifetime? number
function overlay.box( filled, origin, angles, mins, maxs, r, g, b, write_depth, lifetime )
    assert( arg( origin, 1, "Vector" ) )

    local color = Color( r or 255, g or 255, b or 255, 255 )
    write_depth = write_depth ~= false

    if angles == nil then
        angles = angle_zero
    else
        assert( arg( angles, 2, "Angle" ) )
    end

    assert( arg( mins, 3, "Vector" ) )
    assert( arg( maxs, 4, "Vector" ) )

    local fn

    if filled then
        if write_depth then
            function fn()
                render_SetMaterial( matColorIgnoreZ )
                render_DrawBox( origin, angles, mins, maxs, color )
            end
        else
            function fn()
                cam_IgnoreZ( true )
                render_SetMaterial( matColorIgnoreZ )
                render_DrawBox( origin, angles, mins, maxs, color )
                cam_IgnoreZ( false )
            end
        end
    else
        function fn()
            render_DrawWireframeBox( origin, angles, mins, maxs, color, write_depth )
        end
    end

    gen( lifetime, fn )
end

---@param str string
---@param origin Vector
---@param size number
---@param r? integer
---@param g? integer
---@param b? integer
---@param write_depth? boolean
---@param lifetime? number
function overlay.text( str, origin, size, r, g, b, write_depth, lifetime )
    assert( arg( str, 1, "string" ) )
    assert( arg( origin, 2, "Vector" ) )
    assert( arg( size, 3, "number" ) )

    local color = Color( r or 255, g or 255, b or 255, 255 )
    write_depth = write_depth ~= false

    surface.SetFont( "DermaLarge" )
    local text_width, text_height = surface.GetTextSize( str )
    local text_x, text_y = text_width * 0.5, text_height * 0.5

    return gen( lifetime, function()
        cam.Start3D2D( origin, angle_zero, 0.25 )
            surface.SetFont( "DermaLarge" )
            surface.SetDrawColor( color )
            surface.SetTextPos( text_x, text_y )
            surface.DrawText( str )
        cam.End3D2D()
    end )
end

hook.Add( "PostDrawTranslucentRenderables", "Render", function( is_depth, is_skybox, is_3d_skybox )
    if is_skybox then return end

    for i = queue_size, 1, -1 do
        queue[ i ]()
    end
end )

return overlay
