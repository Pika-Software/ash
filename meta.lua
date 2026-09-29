---@meta

---@diagnostic disable: lowercase-global
local std = dreamwork.std

--- [SHARED]
---
--- Is the game in debug mode?
---
---@type boolean
DEBUG = nil

--- [SHARED]
---
--- The current module.
---
---@class ash.Module
MODULE = {}

--- [SHARED]
---
--- The name of the current file.
---
---@type string
__file = ""

--- [SHARED]
---
--- The directory of the current file.
---
---@type string
__dir = ""

---@class ash.Angle : Angle
---@overload fun( pitch: number, yaw: number, roll: number ): Angle
Angle = {}

---@class ash.Color : Color
---@field Lerp fun( f: number, from: Color, to: Color, do_alpha?: boolean ): Color
---@overload fun( r: number, g: number, b: number, a: number ): Color
Color = {}

---@class ash.ConVar : ConVar
---@overload fun( name: string, value: string, flags: number, description: string, min_value: number, max_value: number ): ConVar
ConVar = {}

---@class ash.DamageInfo : CTakeDamageInfo
DamageInfo = {}

---@class ash.Entity : Entity
---@overload fun( index: integer ): Entity
Entity = {}

---@class ash.Material : IMaterial
---@overload fun( name: string ): IMaterial
Material = {}

---@class ash.Texture : ITexture
Texture = {}

---@class ash.MoveData : CMoveData
MoveData = {}

---@class ash.Panel : Panel
---@overload fun( name: string ): Panel
Panel = {}

---@class ash.AudioChannel : IGModAudioChannel
AudioChannel = {}

---@class ash.Player : Player
---@overload fun( name: string ): Player
Player = {}

---@class ash.UserCommand : CUserCmd
UserCommand = {}

---@class ash.Physics : PhysObj
Physics = {}

---@class ash.Vector : Vector
---@overload fun( x: number, y: number, z: number ): Vector
Vector = {}

---@class ash.Matrix.Collumn
---@field [1] number
---@field [2] number
---@field [3] number
---@field [4] number

---@class ash.Matrix.Rows
---@field [1] ash.Matrix.Collumn
---@field [2] ash.Matrix.Collumn
---@field [3] ash.Matrix.Collumn
---@field [4] ash.Matrix.Collumn

---@class ash.Matrix : VMatrix
---@overload fun( data: ash.Matrix.Rows ): VMatrix
Matrix = {}

---@class ash.Weapon : Weapon
---@overload fun( class_name: string ): Weapon
Weapon = {}

do

    --- [SHARED]
    ---
    --- The flags of the variable.
    ---
    ---@class ash.Variable.Flags
    local flags = {}

    --- If this is set, don't add to linked list, etc.
    ---
    ---@type boolean?
    flags.unregistered = nil

    --- Hidden in released products.
    ---
    --- Flag is removed automatically if `ALLOW_DEVELOPMENT_CVARS` is defined in C++.
    ---
    ---@type boolean?
    flags.development_only = nil

    --- Defined by the game DLL.
    ---
    ---@type boolean?
    flags.game_dll = nil

    --- Defined by the client DLL.
    ---
    ---@type boolean?
    flags.client_dll = nil

    --- Doesn't appear in find or autocomplete.
    ---
    --- Like `development_only`, but can't be compiled out.
    ---
    ---@type boolean?
    flags.hidden = nil

    --- It's a server cvar, but we don't send the data since it's a password, etc.
    ---
    --- Sends `1` if it's not bland/zero, `0` otherwise as value.
    ---
    ---@type boolean?
    flags.protected = nil

    --- This cvar cannot be changed by clients connected to a multiplayer server.
    ---
    ---@type boolean?
    flags.sponly = nil

    --- Save the cvar value into either `client.vdf` or `server.vdf`.
    ---
    ---@type boolean?
    flags.archive = nil

    --- For server-side cvars, notifies all players with blue chat text when the value gets changed, also makes the convar appear in [A2S_RULES](https://developer.valvesoftware.com/wiki/Server_queries#A2S_RULES).
    ---
    ---@type boolean?
    flags.notify = nil

    --- For client-side commands, sends the value to the server.
    ---
    ---@type boolean?
    flags.userinfo = nil

    --- In multiplayer, prevents this command/variable from being used unless the server has `sv_cheats` turned on.
    ---
    --- If a client connects to a server where cheats are disabled (which is the default), all client side console variables labeled as `cheat` are reverted to their default values and can't be changed as long as the client stays connected.
    ---
    --- Console commands marked as `cheat` can't be executed either.
    ---
    --- As a general rule of thumb, any client-side command that isn't specifically meant to be configured by users should be marked with this flag, as even the most harmless looking commands can sometimes be misused to cheat.
    ---
    --- For server-side only commands you can be more lenient, since these would have no effect when changed by connected clients anyway.
    ---
    ---@type boolean?
    flags.cheat = nil

    --- This cvar's string cannot contain unprintable characters ( e.g., used for player name etc ).
    ---
    ---@type boolean?
    flags.printable_only = nil

    --- If this is a server-side, don't log changes to the log file / console if we are creating a log.
    ---
    ---@type boolean?
    flags.unlogged = nil

    --- Tells the engine to never print this console variable as a string.
    ---
    --- This is used for variables which may contain control characters.
    ---
    ---@type boolean?
    flags.never_as_string = nil

    --- When set on a console variable, all connected clients will be forced to match the server-side value.
    ---
    --- This should be used for shared code where it's important that both sides run the exact same path using the same data.
    ---
    --- (e.g. predicted movement/weapons, game rules)
    ---
    ---@type boolean?
    flags.replicated = nil

    --- When starting to record a demo file, explicitly adds the value of this console variable to the recording to ensure a correct playback.
    ---
    ---@type boolean?
    flags.demo = nil

    --- Opposite of `DEMO`, ensures the cvar is not recorded in demos.
    ---
    ---@type boolean?
    flags.dont_record = nil

    --- If set and this variable changes, it forces a material reload.
    ---
    ---@type boolean?
    flags.reload_materials = nil

    --- If set and this variable changes, it forces a texture reload.
    ---
    ---@type boolean?
    flags.reload_textures = nil

    --- Prevents this variable from being changed while the client is currently in a server, due to the possibility of exploitation of the command (e.g. `fps_max`).
    ---
    ---@type boolean?
    flags.not_connected = nil

    --- Indicates this cvar is read from the material system thread.
    ---
    ---@type boolean?
    flags.material_system_thread = nil

    --- Like `archive`, but for [Xbox 360](https://de.wikipedia.org/wiki/Xbox_360).
    ---
    --- Needless to say, this is not particularly useful to most modders.
    ---
    --- Save the cvar value into `config.vdf` on XBox.
    ---
    ---@type boolean?
    flags.archive_xbox = nil

    --- Used as a debugging tool necessary to check material system thread convars.
    ---
    ---@type boolean?
    flags.accessible_from_threads = nil

    --- The server is allowed to execute this command on clients via `ClientCommand/NET_StringCmd/CBaseClientState::ProcessStringCmd`.
    ---
    ---@type boolean?
    flags.server_can_execute = nil

    --- If this is set, then the server is not allowed to query this cvar's value (via `IServerPluginHelpers::StartQueryCvarValue`).
    ---
    ---@type boolean?
    flags.server_cannot_query = nil

    --- `IVEngineClient::ClientCmd` is allowed to execute this command.
    ---
    ---@type boolean?
    flags.clientcmd_can_execute = nil

    --- Summary of `reload_materials`, `reload_textures` and `material_system_thread`.
    ---
    ---@type boolean?
    flags.material_thread_mask = nil

    --- Set automatically on all cvars and console commands created by the `client` Lua state.
    ---
    ---@type boolean?
    flags.lua_client = nil

    --- Set automatically on all cvars and console commands created by the `server` Lua state.
    ---
    ---@type boolean?
    flags.lua_server = nil

end

include = ash.include
dofile = ash.include
import = ash.import

-- https://github.com/Srlion/Hook-Library/tree/master
PRE_HOOK = { -4 }
PRE_HOOK_RETURN = { -3 }
NORMAL_HOOK = { 0 }
POST_HOOK_RETURN = { 3 }
POST_HOOK = { 4 }

---@alias hook.Type
---| `PRE_HOOK`
---| `PRE_HOOK_RETURN`
---| `NORMAL_HOOK`
---| `POST_HOOK_RETURN`
---| `POST_HOOK`

--- [SHARED]
---
--- Registers a function (or "callback") with the Hook system so that it will be called automatically whenever a specific event (or "hook") occurs.
---
---@param event_name string The event to hook on to. This can be any GM hook, gameevent after using gameevent.Listen, or custom hook run with hook.Call or hook.Run.
---@param identifier string | any The identifier can be either a string, or a table/object with an IsValid function defined such as an Entity or Panel. numbers and booleans, for example, are not allowed.
---@param func function The function to be called, arguments given to it depend on the identifier used.
---@param priority hook.Type
---@diagnostic disable-next-line: redundant-parameter, duplicate-set-field
function hook.Add( event_name, identifier, func, priority )
end

futures = std.futures
sqlite = std.sqlite
debug = std.debug
class = std.class

string = std.string
table = std.table
math = std.math

console = std.console
path = std.path
http = std.http
raw = std.raw
gc = std.gc

setTimeout = std.setTimeout
printf = std.printf

Color = std.Color

---@class flame : ash.Gamemode
flame = flame or {}

---@class ash.ui.falcon.size
falcon_size = {}

---@type string?
falcon_size.width = nil

---@type string?
falcon_size.height = nil

---@class ash.ui.falcon.base_panel : Panel
---@field keyValue table<string, any>
---@field steps table<string, any>
---@field methods table<string, function>
---@field states table
---@field actions table<string, table<string, function>>
---@field stateSize ash.ui.falcon.StateClass
---@field centerV number
---@field centerH number
falcon_base_panel = {}

---@generic T
---@param self T
---@param tbl table
---@return T
function falcon_base_panel:dockMargin(tbl) end

---@generic T
---@param self T
---@param tbl table
---@return T
function falcon_base_panel:dockPadding(tbl) end

---@generic T
---@param self T
---@param dock_type number
---@return T
function falcon_base_panel:dock(dock_type) end

---@generic T
---@param self T
---@param alpha number
---@return T
function falcon_base_panel:alpha(alpha) end

---@generic T
---@param self T
---@param visible boolean|table
---@return T
function falcon_base_panel:setVisible(visible) end

---@generic T
---@param self T
---@param animation string
---@param ... any
---@return T
function falcon_base_panel:animation(animation, ...) end

---@generic T
---@param self T
---@return T
function falcon_base_panel:center() end

---@generic T
---@param self T
---@param f? number
---@return T
function falcon_base_panel:centerVertical(f) end

---@generic T
---@param self T
---@param f? number
---@return T
function falcon_base_panel:centerHorizontal(f) end

---@generic T
---@param self T
---@param sizeW? boolean
---@param sizeH? boolean
---@return T
function falcon_base_panel:sizeToChildren( sizeW, sizeH ) end

---@generic T
---@param self T
---@param layoutNow boolean? If true the panel will re-layout instantly and not wait for the next frame.
---@return T
function falcon_base_panel:invalidateLayout(layoutNow) end

---@generic T
---@param self T
---@param data ash.ui.falcon.size
---@return T
function falcon_base_panel:setSize(data) end

---@generic T
---@param self T
---@return T
function falcon_base_panel:makePopup() end

---@generic T
---@param self T
---@param bool boolean
---@return T
function falcon_base_panel:keyboardInput(bool) end

---@generic T
---@param self T
---@param bool boolean
---@return T
function falcon_base_panel:mouseInput(bool) end

---@param key string
---@param default any
---@return any
function falcon_base_panel:get(key, default) end

---@param key string
---@param value any
---@return any
function falcon_base_panel:set(key, value) end

---@param key string
---@param value any
---@return any
function falcon_base_panel:setValue(key, value) end

---@param key string
---@param default any
---@return any
function falcon_base_panel:getValue(key, default) end

---@param key string
---@param ... any
function falcon_base_panel:addStep(key, ...) end

---@param key string
---@param ... any
function falcon_base_panel:runMethod(key, ...) end

---@generic T
---@param self T
---@param struct table<string, table>
---@return T
function falcon_base_panel:struct(struct) end

---@param key string
---@param func function
---@param noToStep? boolean
function falcon_base_panel:newMethod(key, func, noToStep) end

---@generic T
---@param self T
---@param class string
---@param name string
---@param callback function
---@return T
function falcon_base_panel:addAction(class, name, callback) end

---@param class string
---@param ... any
function falcon_base_panel:runAction(class, ...) end

---@generic T
---@param self T
---@return T
function falcon_base_panel:show() end

---@generic T
---@param self T
---@return T
function falcon_base_panel:hide() end

---@generic T
---@param self T
---@return T
function falcon_base_panel:build() end

---@generic T
---@param self T
---@param callback fun()
---@return T
function falcon_base_panel:context(callback) end

---@generic T
---@param self T
---@param callback fun()
---@return T
function falcon_base_panel:tstack(callback) end

---@generic T
---@param self T
---@param callback fun()
---@return T
function falcon_base_panel:bstack(callback) end

---@generic T
---@param self T
---@param callback fun()
---@return T
function falcon_base_panel:lstack(callback) end

---@generic T
---@param self T
---@param callback fun()
---@return T
function falcon_base_panel:rstack(callback) end

---@generic T
---@param self T
---@param key string
---@param value any
---@return T
function falcon_base_panel:set( key, value ) end

---@generic T
---@param self T
---@param func function
---@param name string
---@param isback? boolean
---@return T
function falcon_base_panel:addPaint( func, name, isback ) end

---@generic T
---@param self T
---@param state ash.ui.falcon.State
---@return T
function falcon_base_panel:insertSizeToState( state ) end

---@generic T
---@param self T
---@param x? string
---@param y? string
---@return T
function falcon_base_panel:setPos( x, y ) end

---@generic T
---@param self T
---@param x string
---@return T
function falcon_base_panel:setX( x ) end

---@generic T
---@param self T
---@param y string
---@return T
function falcon_base_panel:setX( y ) end

---@generic T
---@param self T
---@param boolean_x? boolean
---@param boolean_y? boolean
---@return T
function falcon_base_panel:uncenter( boolean_x, boolean_y ) end



---@class ash.falcon.label : ash.ui.falcon.base_panel
falcon_label = {}

---@generic T
---@param self T
---@param data table
---@return T
function falcon_label:setTextData(data) end
