---@class ash.player.chat
local ash_chat = include( "shared.lua" )


---@class ash.player.chat.ServerMessage : dreamwork.Object
local ServerMessage = class.base( "ash.player.chat.ServerMessage", false )

---@class ash.player.chat.ClientMessage : ash.player.chat.ServerMessage
local ServerMessageClass = class.create( ServerMessage )

function ash_chat.send( speaker, message_type, text )

end


return ash_chat
