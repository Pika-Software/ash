---@class ash.utils
local utils = include( "shared.lua" )

do

    local math_min, math_max = math.min, math.max
    local ScrW, ScrH = ScrW, ScrH

    local screen_width, screen_height = ScrW(), ScrH()

    local vmin = math_min( screen_width, screen_height ) * 0.01
    local vmax = math_max( screen_width, screen_height ) * 0.01

    hook.Add( "OnScreenSizeChanged", "ScreenSize", function( _, __, w, h )
        screen_width, screen_height = w, h
        vmin = math_min( w, h ) * 0.01
        vmax = math_max( w, h ) * 0.01
    end )

    --- [CLIENT]
    ---
    --- Get the value of a value based on the screen's minimum dimension.
    ---
    ---@param value number
    ---@return number
    function utils.vMin( value )
        return vmin * value
    end

    --- [CLIENT]
    ---
    --- Get the value of a value based on the screen's maximum dimension.
    ---
    ---@param value number
    ---@return number
    function utils.vMax( value )
        return vmax * value
    end

end

--- [SHARED]
---
--- Get text size
---
---@param text string
---@param font string
---@return number
---@return number
function utils.GetTextSize( text, font )
    surface.SetFont( font )
    return surface.GetTextSize( text )
end

return utils
