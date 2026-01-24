
---@type ash.sound
local ash_sound = require( "ash.sound" )

---@class ash.ambient
local ash_ambient = {}

local registry = {}

---@class ash.ambient.Sound.Crossfade
---@field in_fade? number
---@field out_fade? number
---@field ease? dreamwork.std.math.ease

---@class ash.ambient.Sound : ash.sound.Data
---@field crossfade? ash.ambient.Sound.Crossfade
---@field time? number

---@class ash.ambient.Data
---@field name string
---@field sounds ash.ambient.Sound[]
---@field mode? "all" | "shuffle" | "sequence"
---@field loop? boolean

---@param name string
---@param data ash.ambient.Data
function ash_ambient.register( name, data )

end

---@param name string
---@param fade_in? number
---@param ease? dreamwork.std.math.ease
function ash_ambient.play( name, fade_in, ease )

end

---@param fade_out? number
---@param ease? dreamwork.std.math.ease
function ash_ambient.stop( fade_out, ease )

end

return ash_ambient
