---@class ash.notify
local notify = {}

local title = "[" .. ash.Tag .. "] "
local colors = ash.Colors

--- [CLIENT]
---
--- Sends a notification to a player in chat.
---
---@param fmt string
---@param ... any
function notify.SendToChat( fmt, ... )
    chat.AddText( colors.ash_main, title, colors.ash_log, string.format( fmt, ... ) )
end

net.Receive( "ash.Notify", function()
    notify.SendToChat( net.ReadString(), unpack( net.ReadTable( true ) ) )
end )

return notify
