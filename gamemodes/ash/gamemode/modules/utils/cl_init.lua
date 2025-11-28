---@class ash.utils
local utils = include( "shared.lua" )

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
