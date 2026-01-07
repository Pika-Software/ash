---@class ash.ui
---@field ScreenWidth integer
---@field ScreenHeight integer
---@field ScreenAspect number
---@field ScreenCenterX integer
---@field ScreenCenterY integer
local ui = {}

local math_min, math_max = math.min, math.max
local math_floor = math.floor

local string_match = string.match
local ScrW, ScrH = ScrW, ScrH
local tonumber = tonumber
local hook_Run = hook.Run
local pairs = pairs
local IsValid = IsValid
local vgui_Create = vgui.Create

local logger = ash.Logger

local screen_width, screen_height, screen_aspect = 0, 0, 0
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

ui.scale = ui_unit

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
    function ui.scaleMap( map_params )
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
    function ui.font( name, font_data )
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

        font_names[ name ] = font_data

        font_count = font_count + 1
        font_list[ font_count ] = font_data

        surface_CreateFont( name, font_data )
        return name
    end

    ---@param width integer
    ---@param height integer
    local function perform_layout( width, height )
        screen_width, screen_height = width, height
        screen_aspect = screen_width / screen_height

        ui.ScreenWidth, ui.ScreenHeight, ui.ScreenAspect = screen_width, screen_height, screen_aspect
        ui.ScreenCenterX, ui.ScreenCenterY = math_floor( screen_width * 0.5 ), math_floor( screen_height * 0.5 )

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

        hook_Run( "ScreenResolutionChanged", width, height, screen_aspect )
    end

    hook.Add( "OnScreenSizeChanged", "RescalingEvent", function( _, __, width, height )
        perform_layout( width, height )
    end, PRE_HOOK )

    perform_layout( ScrW(), ScrH() )

end

do
    local panel_storage = {}
    ui.panel_storage = panel_storage

    --- [CLIENT]
    ---
    --- Create and save panel to table.
    ---
    ---@param key string | nil
    ---@param class_name string | nil
    ---@param parent Panel | nil
    ---@return Panel | nil
    function ui.setPanel( key, class_name, parent, custom_name )
        if key == nil then
            return
        end

        local old_panel = panel_storage[ key ]
        if IsValid( old_panel ) then
            old_panel:Remove()
        end

        local panel = vgui_Create( class_name, parent, custom_name )

        panel_storage[ key ] = panel

        return panel
    end

    --- [CLIENT]
    ---
    --- Get panel from table by key.
    ---
    ---@param key string
    function ui.getPanel( key )
        return panel_storage[ key ]
    end

    return ui
end
