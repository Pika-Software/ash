---@class ash.ui
---@field ScreenWidth integer
---@field ScreenHeight integer
---@field ScreenAspect number
---@field ScreenCenterX integer
---@field ScreenCenterY integer
---@field CursorX integer
---@field CursorY integer
local ash_ui = {}

ash_ui.Colors = ash.Colors

local math = math
local math_floor = math.floor
local math_min, math_max = math.min, math.max

local hook_Run = hook.Run
local vgui_Create = vgui.Create
local string_match = string.match

local pairs = pairs
local tonumber = tonumber
local ScrW, ScrH = ScrW, ScrH

local logger = ash.Logger

local screen_aspect = 0
local screen_width, screen_height = 0, 0
local screen_center_x, screen_center_y = 0, 0

local viewport_width, viewport_height = 0, 0
local viewport_min, viewport_max = 0, 0

---@type table<string, fun( number ): number>
local units = {
    px = function( x )
        return x
    end,
    vmin = function( x )
        return viewport_min * x
    end,
    vmax = function( x )
        return viewport_max * x
    end,
    vw = function( x )
        return viewport_width * x
    end,
    vh = function( x )
        return viewport_height * x
    end,
    pw = function( x )
        return ( ScrW() * 0.01 ) * x
    end,
    ph = function( x )
        return ( ScrH() * 0.01 ) * x
    end,
    p = function( x )
        return ( ( ScrW() + ScrH() ) * 0.005 ) * x
    end,
    pmin = function( x )
        return ( math_min( ScrW(), ScrH() ) * 0.01 ) * x
    end,
    pmax = function( x )
        return ( math_max( ScrW(), ScrH() ) * 0.01 ) * x
    end,
    cm = function( x )
        return x * 37.8
    end,
    mm = function( x )
        return x * 3.78
    end,
    [ "in" ] = function( x )
        return x * 96
    end,
    pc = function( x )
        return x * 16
    end,
    pt = function( x )
        return ( x * 96 ) / 72
    end,
    q = function( x )
        return x * 0.945
    end
}

setmetatable( units, {
    __index = function( self, unit )
        return self.px
    end
} )

--- [CLIENT]
---
--- Converts a string to pixels.
---
---@param str string
---@return integer px
local function ui_unit( str )
    local number, unit = string_match( str, "^(%d+%.?%d*)([%a][%w_]*)$" )
    return math_floor( units[ unit ]( tonumber( number, 10 ) or 0 ) )
end

ash_ui.scale = ui_unit

---@type table<string, string>
local unit_sizes = {}

---@type table<string, integer>
local unit_values = {}

do

    local map_metatable = {
        __index = function( self, name )
            return unit_values[ unit_sizes[ name ] or 0 ] or 0
        end
    }

    --- [CLIENT]
    ---
    --- Creates a size map.
    ---
    ---@param map_params table<string, string>
    ---@return table<string, integer> map_obj
    function ash_ui.scaleMap( map_params )
        local map = {}

        setmetatable( map, map_metatable )

        for name, size in pairs( map_params ) do
            unit_sizes[ name ] = size
            unit_values[ size ] = ui_unit( size )
        end

        return map
    end

end

do

    local surface_CreateFont = surface.CreateFont
    local table_remove = table.remove

    ---@class asg.ui.FontData : FontData
    ---@diagnostic disable-next-line: duplicate-doc-field
    ---@field size string

    ---@type table<FontData, string>
    local font_sizes = {}

    ---@type table<FontData, string>
    local font_names = {}

    ---@type FontData[]
    local font_list = {}

    ---@type integer
    local font_count = 0

    --- [CLIENT]
    ---
    --- Creates a font.
    ---
    ---@param name string
    ---@param font_data asg.ui.FontData
    ---@return string
    function ash_ui.font( name, font_data )
        font_data.extended = font_data.extended ~= false
        font_data.antialias = font_data.antialias ~= false

        if font_data.weight == nil then
            font_data.weight = 500
        end

        if font_data.blursize == nil then
            font_data.blursize = 0
        end

        if font_data.scanlines == nil then
            font_data.scanlines = 0
        end

        font_data.underline = font_data.underline == true
        font_data.italic = font_data.italic == true
        font_data.strikeout = font_data.strikeout == true
        font_data.symbol = font_data.symbol == true
        font_data.rotary = font_data.rotary == true
        font_data.shadow = font_data.shadow == true
        font_data.additive = font_data.additive == true
        font_data.outline = font_data.outline == true

        font_sizes[ font_data ] = font_data.size

        ---@diagnostic disable-next-line: cast-type-mismatch
        ---@cast font_data FontData

        font_data.size = ui_unit( font_sizes[ font_data ] )

        for i = 1, font_count, 1 do
            local font_data_i = font_list[ i ]
            if font_names[ font_data_i ] == name then
                table_remove( font_list, i )
                font_count = font_count - 1
                break
            end
        end

        font_names[ font_data ] = name

        font_count = font_count + 1
        font_list[ font_count ] = font_data

        surface_CreateFont( name, font_data )
        return name
    end

    ---@param width integer
    ---@param height integer
    local function perform_layout( width, height )
        screen_width, screen_height = width, height
        ash_ui.ScreenWidth, ash_ui.ScreenHeight = screen_width, screen_height

        screen_aspect = screen_width / screen_height
        ash_ui.ScreenAspect = screen_aspect

        screen_center_x, screen_center_y = math_floor( screen_width * 0.5 ), math_floor( screen_height * 0.5 )
        ash_ui.ScreenCenterX, ash_ui.ScreenCenterY = screen_center_x, screen_center_y

        viewport_width, viewport_height = screen_width * 0.01, screen_height * 0.01
        viewport_min, viewport_max = math_min( viewport_width, viewport_height ), math_max( viewport_width, viewport_height )

        for _, size in pairs( unit_sizes ) do
            unit_values[ size ] = ui_unit( size )
        end

        for i = 1, font_count, 1 do
            local font_data = font_list[ i ]
            font_data.size = ui_unit( font_sizes[ font_data ] )
            surface_CreateFont( font_names[ font_data ], font_data )
            logger:debug( "Font '%s' was re-scaled, %s -> %spx", font_names[ font_data ], font_sizes[ font_data ], font_data.size )
        end

        hook_Run( "ash.ui.ScreenResolution", width, height, screen_aspect )
    end

    hook.Add( "OnScreenSizeChanged", "RescalingEvent", function( _, __, width, height )
        perform_layout( width, height )
    end, PRE_HOOK )

    perform_layout( ScrW(), ScrH() )

end

do

    ---@type table<string, Panel>
    local panels = {}

    --- [CLIENT]
    ---
    --- Creates a panel and stores it in the internal naming table.
    ---
    ---@param store_name string
    ---@param panel_class string
    ---@param panel_parent? Panel
    ---@param panel_name? string
    ---@return Panel panel
    function ash_ui.setPanel( store_name, panel_class, panel_parent, panel_name )
        local panel = panels[ store_name ]
        if panel ~= nil and panel:IsValid() then
            panel:Remove()
        end

        panel = vgui_Create( panel_class, panel_parent, panel_name )
        panels[ store_name ] = panel
        return panel
    end

    --- [CLIENT]
    ---
    --- Get panel by key from the internal naming table.
    ---
    ---@param store_name string
    ---@return Panel panel
    function ash_ui.getPanel( store_name )
        return panels[ store_name ]
    end

    hook.Add( "ash.ModuleUnloaded", "StorageCleanup", function( module )
        if module ~= MODULE then return end

        for name, panel in pairs( panels ) do
            if panel ~= nil and panel:IsValid() then
                panel:Remove()
            end

            panels[ name ] = nil
        end
    end, PRE_HOOK )

end

do

    local input_GetCursorPos = input.GetCursorPos
    local vgui_CursorVisible = vgui.CursorVisible

    local cursor_x, cursor_y = screen_center_x, screen_center_y
    local cursor_visible = false

    local function cursor_update()
        local x, y = screen_center_x, screen_center_y

        cursor_visible = vgui_CursorVisible()
        ash_ui.CursorVisible = cursor_visible

        if cursor_visible then
            x, y = input_GetCursorPos()
        end

        if x ~= cursor_x or y ~= cursor_y then
            cursor_x, cursor_y = x or screen_center_x, y or screen_center_y
            ash_ui.CursorX, ash_ui.CursorY = x, y

            hook_Run( "ash.ui.CursorMoved", x, y, cursor_visible )
        end
    end

    hook.Add( "Tick", "CursorCapture", cursor_update, PRE_HOOK )
    cursor_update()

    local vgui_GetHoveredPanel = vgui.GetHoveredPanel
    local Panel_IsValid = Panel.IsValid

    local Panel_SetCursor = Panel.__SetCursor or Panel.SetCursor
    Panel.__SetCursor = Panel_SetCursor

    ---@type table<Panel, string>
    local cursors = {}

    setmetatable( cursors, {
        __index = function()
            return "arrow"
        end,
        __mode = "k"
    } )

    function Panel:SetCursor( name )
        Panel_SetCursor( self, name )
        cursors[ self ] = name
    end

    hook.Add( "PostRenderVGUI", "MouseCursor", function()
        if cursor_visible then
            local pnl = vgui_GetHoveredPanel()
            if pnl ~= nil and Panel_IsValid( pnl ) then
                if hook_Run( "ash.ui.DrawCursor", cursor_x, cursor_y, cursors[ pnl ] ) then
                    Panel_SetCursor( pnl, "blank" )
                end

                return
            end

            hook_Run( "ash.ui.DrawCursor", cursor_x, cursor_y, "arrow" )
        end
    end, PRE_HOOK )

end

do

    local math_isint = math.isint
    local setTimeout = setTimeout
    local util_CRC = util.CRC

    local string_lower = string.lower
    local string_isURL = string.isURL

    local engine_loadMaterial = _G.dreamwork.engine.loadMaterial
    local CreateMaterial = CreateMaterial
    local string_gsub = string.gsub
    local futures_run = futures.run
    local type = type

    local Material = Material
    local Material_SetInt = Material.SetInt
    local Material_SetFloat = Material.SetFloat
    local Material_GetKeyValues = Material.GetKeyValues

    local type2fn = {
        string = Material.SetString,
        ---@param material IMaterial
        ---@param key string
        ---@param value number
        number = function( material, key, value )
            if math_isint( value ) then
                Material_SetInt( material, key, value )
            else
                Material_SetFloat( material, key, value )
            end
        end,
        ITexture = Material.SetTexture,
        VMatrix = Material.SetMatrix,
        Vector = Material.SetVector,
    }

    ---@param from IMaterial
    ---@param to IMaterial
    local function translate( from, to )
        for key, value in pairs( Material_GetKeyValues( from ) ) do
            local fn = type2fn[ type( value ) ]
            if fn ~= nil then
               fn( to, key, value )
            end
        end
    end

    ---@type table<string, boolean>
    local supported_formats = {
        jpeg = true,
        png = true
    }

    file.CreateDir( "ash/downloads/images" )

    ---@type table<string, IMaterial>
    local materials = {}

    local function image_request( image_url )
        local response = http.get( image_url )
        if response.status ~= 200 then return end

        local headers = {}

        for key, value in pairs( response.headers ) do
            headers[ string_lower( key ) ] = value
        end

        local content_type = headers["content-type"]
        if content_type == nil then
            error( "failed to fetch data from URL (" .. image_url .. ") - no content-type" )
        end

        local content, format = string.match( content_type, "^([^/]+)/([^/;]+)" )
        if content == nil or format == nil then
            error( "failed to fetch data from URL (" .. image_url .. ") - invalid content-type" )
        end

        if content ~= "image" then
            error( "failed to fetch data from URL (" .. image_url .. ") - not an image" )
        end

        if supported_formats[ format ] == nil then
            error( "failed to fetch data from URL (" .. image_url .. ") - unsupported format ( " .. format .. " )" )
        end

        local body = response.body

        local file_name = util_CRC( body ) .. "." .. format
        local file_path = "ash/downloads/images/" .. file_name

        if not file.Exists( file_path, "DATA" ) then
            file.Write( "ash/downloads/images/" .. file_name, body )
        end

        return "data/" .. file_path
    end

    --- [SHARED]
    ---
    --- Load a material from the specified path.
    ---
    ---@param name string
    ---@param path string
    ---@param image_parameters? dreamwork.engine.ImageParameters
    ---@param shader_parameters? dreamwork.std.Material.Shader
    function ash_ui.loadMaterial( name, path, image_parameters, shader_parameters )
        if shader_parameters == nil then
            shader_parameters = {}
        end

        local shader = shader_parameters.name or "UnlitGeneric"
        shader_parameters.name = nil

        shader_parameters["$basetexture"] = shader_parameters["$basetexture"] or ash.LoadingTextureName or "color/white"
        shader_parameters["$translucent"] = shader_parameters["$translucent"] or 1
        shader_parameters["$vertexalpha"] = shader_parameters["$vertexalpha"] or 1
        shader_parameters["$vertexcolor"] = shader_parameters["$vertexcolor"] or 1

        local material = materials[ name ]
        if material == nil then
            material = CreateMaterial( string_gsub( name, "[^%w_]+", "_" ), shader, shader_parameters )
            materials[ name ] = material
        end

        if string_isURL( path ) then
            futures_run( image_request, function( ok, file_path )
                if ok then
                    translate( engine_loadMaterial( file_path, image_parameters ), material )
                else
                    ash.Logger:error( "failed to fetch data from URL (" .. path .. ")")
                end
            end, path )
        else
            setTimeout( function()
                translate( engine_loadMaterial( path, image_parameters ), material )
            end )
        end

        return material
    end

end

--- [CLIENT]
---
--- Returns the width and height of the specified text in pixels.
---
---@param text string
---@param font_name string
---@return number text_width
---@return number text_height
function ash_ui.getTextSize( text, font_name )
    surface.SetFont( font_name )
    return surface.GetTextSize( text )
end

return ash_ui
