---@class ash.player
local ash_player = ...

---@class ash.player.Camera : dreamwork.std.Object
local Camera = class.base( "ash.player.Camera", false )

---@class ash.player.CameraClass : ash.player.Camera
local CameraClass = class.new( Camera )
