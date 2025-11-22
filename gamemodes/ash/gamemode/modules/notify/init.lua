MODULE.Networks = {
    "ash.Notify"
}

--- [SHARED]
---
--- ash's notification module.
---
---@class ash.notify
local notify = {}

--- [SERVER]
---
--- Sends a notification to a player in chat.
---
---@param ply Player
---@param fmt string
---@param ... any
function notify.Send( ply, fmt, ... )
    net.Start( "ash.Notify" )
        net.WriteString( fmt )
        net.WriteTable( { ... } , true )
    net.Send( ply )
end

return notify
