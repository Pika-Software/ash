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
--- The current gamemode.
---
---@class ash.Game
GAME = {}

--- [SHARED]
---
--- The name of the current file.
---
---@type string
---@diagnostic disable-next-line: lowercase-global
__file = ""

--- [SHARED]
---
--- The directory of the current file.
---
---@type string
---@diagnostic disable-next-line: lowercase-global
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

---@class ash.MoveData : CMoveData
MoveData = {}

---@class ash.Panel : Panel
---@overload fun( name: string ): Panel
Panel = {}

---@class ash.Player : Player
---@overload fun( name: string ): Player
Player = {}

---@class ash.UserCommand : CUserCmd
UserCommand = {}

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
