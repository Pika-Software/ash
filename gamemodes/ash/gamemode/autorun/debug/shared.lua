
---@class ash.debug : dreamwork.std.debug
local debug = {}

setmetatable( debug, {
    __index = _G.dreamwork.std.debug
} )

return debug
