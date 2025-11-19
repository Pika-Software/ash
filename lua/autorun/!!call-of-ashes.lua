local _G = _G
if _G.ash then return end

---@type dreamwork
local dreamwork = _G.dreamwork

if dreamwork == nil then
    error( "dreamwork is missing!" )
    return
end

---@type dreamwork.std
local std = dreamwork.std

local LUA_CLIENT = std.LUA_CLIENT
local LUA_SERVER = std.LUA_SERVER

local ErrorNoHaltWithStack = _G.ErrorNoHaltWithStack

local setmetatable = std.setmetatable
local setfenv = std.setfenv
local pcall = std.pcall

local debug = std.debug
local string = std.string
local table = std.table
local class = std.class
local path = std.path
local fs = std.fs

local hook = _G.hook
local file = _G.file

local table_insert = table.insert
local table_remove = table.remove
local table_concat = table.concat
local table_unpack = table.unpack

local string_format = string.format
local string_lower = string.lower
local string_len = string.len

local raw_ipairs = std.raw.ipairs

local Color = std.Color

---
--- The ash global namespace.
---
---@class ash
ash = ash or {}

ash.Name = "Ash"
ash.Version = "0.1.0"
ash.Author = "Unknown Developer"
ash.Tag = string_lower( string.match( ash.Name, "[^%s%p]+" ) ) .. "@" .. ash.Version

ash.Dedicated = game.IsDedicated()
ash.dreamwork = std

setmetatable( ash, {
    __tostring = function( self )
        return string_format( "%s: %p", self.Tag, self )
    end
} )

---@class dreamwork.std.ColorClass.scheme
local color_scheme = std.Color.scheme
ash.Colors = color_scheme

color_scheme.ash_main = Color( 180, 120, 255 )

color_scheme.ash_white = Color( 255, 255, 255 )
color_scheme.ash_black = Color( 0, 0, 0 )
color_scheme.ash_red = Color( 220, 80, 80 )
color_scheme.ash_green = Color( 80, 200, 100 )
color_scheme.ash_blue = Color( 50, 150, 250 )
color_scheme.ash_yellow = Color( 220, 220, 80 )
color_scheme.ash_orange = Color( 255, 128, 0 )

color_scheme.ash_log = Color( 240, 240, 240 )
color_scheme.ash_time = Color( 100, 100, 100 )
color_scheme.ash_separator = Color( 150, 150, 150 )

color_scheme.ash_client = Color( 225, 170, 10 )
color_scheme.ash_server = Color( 5, 170, 250 )

local logger = std.console.Logger( {
    color = color_scheme.ash_main,
    title = ash.Tag,
    interpolation = false
} )

ash.Logger = logger

function ash.printTable( t )
    print( "{" )

    for k, v in pairs( t ) do
        print( string_format( "\t[ %s ] = %s,", k, v ) )
    end

    print( "}" )
end

local active_gamemode = engine.ActiveGamemode()
ash.GamemodeName = active_gamemode

if not fs.isDirectory( "/workspace/lua/" .. active_gamemode .. "/gamemode" ) then
    logger:error( "Could not find gamemode '%s', exiting...", active_gamemode )
    return
end

local chain_file = "ash/" .. active_gamemode .. "_chain.lua"

local clientFileSend
do

    local AddCSLuaFile = _G.AddCSLuaFile

    ---@type table<string, boolean>
    local sended = {}

    ---@param file_path string
    ---@param stack_level? integer
    function clientFileSend( file_path, stack_level )
        if not LUA_SERVER or LUA_CLIENT or sended[ file_path ] ~= nil then
            return
        end

        if stack_level == nil then
            stack_level = 2
        else
            stack_level = stack_level + 1
        end

        if pcall( AddCSLuaFile, file_path ) then
            logger:debug( "File '%s' sent to the client.", file_path )
            sended[ file_path ] = true
        else
            logger:error( "Failed to send file '%s' to the client.", file_path )
        end
    end

end

---@class ash.Gamemode
---@field Title string
---@field Name string
---@field Version string
---@field Maps string
---@field Logger dreamwork.std.console.Logger

if LUA_SERVER then

    fs.makeDirectory( "/garrysmod/data/ash/injections", true )

    for _, file_name in raw_ipairs( file.Find( "ash/injections/*.dat", "DATA" ) ) do
        file.Delete( "ash/injections/" .. file_name )
    end

    ---@class ash.gamemode.Info
    ---@field name string
    ---@field title string
    ---@field base string
    ---@field maps string
    ---@field author string
    ---@field version string
    ---@field menusystem integer

    --- [SERVER]
    ---
    --- Parse a gamemode file and return the gamemode info.
    ---
    ---@param name string
    ---@return ash.gamemode.Info | nil
    ---@return string | nil
    function ash.parse( name )
        local file_path = "gamemodes/" .. name .. "/" .. name .. ".txt"
        if not file.Exists( file_path, "GAME" ) then
            return nil, string_format( "could not find file '%s'", file_path )
        end

        local file_content = file.Read( file_path, "GAME" )
        if file_content == nil or string_len( file_content ) == 0 then
            return nil, string_format( "file '%s' is empty", file_path )
        end

        local gamemode_info = util.KeyValuesToTable( file_content, false, false )
        if gamemode_info == nil or not istable( gamemode_info ) then
            return nil, string_format( "Could not parse file '%s'", file_path )
        end

        return gamemode_info
    end

    --- [SERVER]
    ---
    --- Get the chain of ash gamemodes.
    ---
    ---@param gamemode_base string
    ---@return ash.gamemode.Info[] | nil
    ---@return nil | string
    function ash.chain( gamemode_base )
        local gamemode_info, err_msg = ash.parse( gamemode_base )

        ---@type ash.gamemode.Info[]
        local chain = {}

        ::ash_lookup_loop::

        if gamemode_info == nil then
            return nil, err_msg
        end

        gamemode_info.version = gamemode_info.version or "0.1.0"
        gamemode_info.author = gamemode_info.author or "unknown"
        gamemode_info.name = gamemode_base
        gamemode_base = gamemode_info.base

        if gamemode_base == "base" then
            return nil, "current gamemode is not based on ash"
        end

        table_insert( chain, gamemode_info )

        if gamemode_base ~= "ash" then
            gamemode_info, err_msg = ash.parse( gamemode_base )
            goto ash_lookup_loop
        end

        do

            local ash_info = ash.parse( "ash" )
            ash_info.name = "ash"
            ash_info.author = ash.Author
            ash_info.version = ash.Version
            table_insert( chain, ash_info )

        end

        return chain, nil
    end

    --- [SERVER]
    ---
    --- Build the injection file.
    ---
    ---@param name string
    ---@param description string
    function ash.pack( name, description )
        local files = {}
        local files_map = {}

        local function add_file( file_path, content )
            file_path = string_lower( file_path )

            local file_data = files_map[ file_path ]
            if file_data == nil then
                file_data = {
                    path = file_path,
                    content = content
                }

                file_data.index = table_insert( files, file_data )
                files_map[ file_path ] = file_data
                return
            end

            file_data.content = content
        end

        local function build( file_path )
            ---@type File
            ---@diagnostic disable-next-line: assign-type-mismatch
            local injection_handler = file.Open( file_path, "wb", "DATA" )

            injection_handler:Write( "GMAD\3" )
            injection_handler:WriteUInt64( "76561198100459279" )

            injection_handler:Write( "\0\0\0\0" )
            injection_handler:WriteULong( os.time() )

            -- TODO: insert ash here ( required content )
            injection_handler:Write( "\0" )

            injection_handler:Write( name .. "\0" )
            injection_handler:Write( description .. "\0" )

            injection_handler:Write( "Unknown Developer\0" )
            injection_handler:WriteULong( 1 )

            -- Start of file list

            for i = 1, #files, 1 do
                local file_info = files[ i ]
                local info_path = file_info.path

                injection_handler:WriteULong( i ) -- index
                injection_handler:Write( info_path .."\0" ) -- file_path

                local info_content = file_info.content

                injection_handler:WriteULong( string_len( info_content ) ) -- size
                injection_handler:Write( "\0\0\0\0" )

                injection_handler:WriteULong( tonumber( util.CRC( info_content ), 10 ) ) -- crc32

                logger:debug( "File '%s' (%d) will be injected.", info_path, i )
            end

            -- End of file list
            injection_handler:WriteULong( 0 )

            for i = 1, #files, 1 do
                injection_handler:Write( files[ i ].content )
            end

            injection_handler:WriteULong( 0 ) -- no crc :c

            injection_handler:Close()

            return "data/" .. file_path
        end

        return add_file, build
    end

    --- [SERVER]
    ---
    --- Rebuild ash gamemode.
    ---
    function ash.rebuild()
        local chain, err_msg = ash.chain( active_gamemode )
        if chain == nil then
            logger:warn( "Tethering failed: %s", err_msg )
            return
        end

        logger:info( "Tethering completed, injecting...", active_gamemode )

        local injection_name = string_format( "%s_%s.gma.dat", active_gamemode, std.uuid.v7() )
        local add_file, build = ash.pack( injection_name, "A magical injection into the game to bang greedy, fat f*ck Garry Newman." )

        add_file( "lua/" .. chain_file, "return \"" .. util.Base64Encode( util.Compress( util.TableToJSON( chain, false ) ), true ) .. "\"" )
        add_file( "lua/" .. active_gamemode .. "/gamemode/cl_init.lua", "include( \"ash/loader.lua\" )" )
        add_file( "lua/" .. active_gamemode .. "/gamemode/init.lua", "include( \"ash/loader.lua\" )" )

        ---@param name string
        ---@param path_to string
        local function bake_content( name, path_to )
            local parent_path = "gamemodes/" .. name .. "/content/" .. path_to
            local parent_files, parent_directories = file.Find( parent_path .. "*", "GAME" )

            for _, file_name in raw_ipairs( parent_files ) do
                if not file.Exists( path_to .. file_name, "GAME" ) then
                    add_file( path_to .. file_name, file.Read( parent_path .. file_name, "GAME" ) )
                end
            end

            for _, directory_name in raw_ipairs( parent_directories ) do
                bake_content( name, path_to .. directory_name .. "/" )
            end
        end

        for i = 1, #chain, 1 do
            local info_name = chain[ i ].name
            bake_content( info_name, "maps/" )
            bake_content( info_name, "sound/" )
            bake_content( info_name, "models/" )
            bake_content( info_name, "materials/" )
        end

        if not game.MountGMA( build( "ash/injections/" .. injection_name ) ) then
            std.errorf( 2, false, "failed to inject '%s'", injection_name )
        end

        logger:info( "Gamemode info for '%s' successfully injected!", active_gamemode )
    end

    ash.rebuild()

    --- [SERVER]
    ---
    --- Resend all files to clients.
    ---
    function ash.resend()
        local chain = ash.Chain

        for i = #chain, 1, -1 do
            local gamemode_info = chain[ i ]
            local name = gamemode_info.name

            local modules_path = name .. "/gamemode/modules/"

            for _, directory_name in raw_ipairs( select( 2, file.Find( modules_path .. "*", "LUA" ) ) ) do
                local module_path = modules_path .. directory_name

                local entrypoint_path = module_path .. "/cl_init.lua"
                if file.Exists( entrypoint_path, "LUA" ) then
                    clientFileSend( entrypoint_path, 2 )
                else
                    entrypoint_path = module_path .. "/shared.lua"
                    if file.Exists( entrypoint_path, "LUA" ) then
                        clientFileSend( entrypoint_path, 2 )
                    end
                end
            end
        end
    end

end

if not file.Exists( chain_file, "LUA" ) then
    logger:info( "No chain file detected, skipping." )
    return
end

do

    local fn = CompileFile( chain_file, false )
    if fn == nil then
        logger:error( "Failed to compile '%s'.", chain_file )
        return
    end

    -- script kiddy protection :p
    setfenv( fn, {} )

    local chain_data = fn()
    if chain_data == nil then
        logger:error( "Failed to run '%s', no data :c", chain_file )
        return
    end

    if not isstring( chain_data ) then
        logger:error( "Failed to read '%s', invalid data >:c", chain_file )
        return
    end

    local decoded_data = util.Base64Decode( chain_data )
    if decoded_data == nil then
        logger:error( "Failed to decode '%s', invalid data >:c", chain_file )
        return
    end

    local compressed_data = util.Decompress( decoded_data )
    if compressed_data == nil then
        logger:error( "Failed to decompress '%s', possibly data corruption :-c", chain_file )
        return
    end

    local chain = util.JSONToTable( compressed_data, true, true )
    if chain == nil or not istable( chain ) then
        logger:error( "Failed to parse '%s', possibly data corruption x_x", chain_file )
        return
    end

    ---@cast chain ash.gamemode.Info[]

    if LUA_CLIENT then
        logger:debug( "Satellite successfully received information about the chain!" )
    end

    ---@type ash.gamemode.Info[]
    ash.Chain = chain

    local active_link = chain[ 1 ]
    local active_name = active_link.name

    if _G[ active_name ] == nil then
        local active_title = active_link.title
        local active_author = active_link.author

        _G[ active_name ] = {
            Version = active_link.version,
            Author = active_author,
            Title = active_title,
            Maps = active_link.maps,
            Name = active_name,
            Logger = std.console.Logger( {
                title = active_name .. "@" .. active_link.version,
                color = Color( 255, 255, 255 ),
                interpolation = false
            } )
        }

        hook.Add( "PostGamemodeLoaded", "ash.gamemode", function()
            ---@type GM
            local GM = GM or GAMEMODE

            local folder_name = GM.FolderName
            local folder = GM.Folder

            table.clearKeys( GM )

            GM.Name = active_title
            GM.Author = active_author

            GM.FolderName = folder_name
            GM.Folder = folder

            ---@diagnostic disable-next-line: undefined-field, redundant-parameter
        end, _G.PRE_HOOK )
    end

end

if LUA_SERVER then
    clientFileSend( "ash/loader.lua" )
    clientFileSend( chain_file )
    ash.resend()
end

---@class ash.Environment
local environment = {}
ash.Environment = environment

---@class ash.EnvironmentBlacklist
local environment_blacklist = {}
ash.EnvironmentBlacklist = environment_blacklist

setmetatable( environment, {
    __index = function( self, key )
        if environment_blacklist[ key ] then
            return nil
        end

        return _G[ key ]
    end
} )

local DEBUG = cvars.Number( "developer", 0 ) ~= 0
environment.DEBUG = DEBUG

local enviroment_metatable = {
    __index = environment,
    __newindex = debug.fempty
}

---@type table<string, ash.GameEvent>
local game_events = {}

---@class ash.GameEvent : dreamwork.Object
---@field __class ash.GameEventClass
---@field name string
local GameEvent = class.base( "ash.GameEvent", false )

---@return string
---@protected
function GameEvent:__tostring()
    return string_format( "ash.GameEvent: %p [%s]", self, self.name )
end

---@class ash.Hook
---@field fn fun( ... ): ...
---@field module ash.Module

do

    local hook_Call = hook.Call
    local event_registry = {}

    ---@param name string
    ---@protected
    function GameEvent:__init( name )
        self.hook_count = 0
        self.hooks = {}
        self.name = name

        event_registry[ name ] = self
    end

    function hook.Call( event_name, gamemode_table, ... )
        local a1, b1, c1, d1, e1, f1 = hook_Call( event_name, gamemode_table, ... )
        if a1 ~= nil then
            return a1, b1, c1, d1, e1, f1
        end

        local event = event_registry[ event_name ]
        if event ~= nil then
            local hooks = event.hooks

            for i = event.hook_count, 1, -1 do
                local a2, b2, c2, d2, e2, f2 = hooks[ i ][ 1 ]( ... )
                if a2 ~= nil then
                    return a2, b2, c2, d2, e2, f2
                end
            end
        end
    end

end

do

    local gamemode_Register = gamemode.Register

    ---@param it GM
    ---@param name string
    ---@param base_name string
    function gamemode.Register( it, name, base_name )
        xpcall( hook.Run, ErrorNoHaltWithStack, "GamemodeRegistered", name, it, base_name )
        return gamemode_Register( it, name, base_name )
    end

end

--- [SHARED]
---
--- Calls all hooks attached to the event.
---
---@param ... any
---@return any ...
function GameEvent:call( ... )
    local hooks = self.hooks

    for i = self.hook_count, 1, -1 do
        local a, b, c, d, e = hooks[ i ][ 1 ]( ... )
        if a ~= nil then
            return a, b, c, d, e
        end
    end
end

--- [SHARED]
---
--- Attaches a hook to the event.
---
---@param module_object ash.Module
---@param fn fun( ... ): ...
---@param priority? integer
function GameEvent:attach( module_object, fn, priority )
    if priority == nil then
        table_insert( self.hooks, { fn, module_object } )
    else
        table_insert( self.hooks, priority, { fn, module_object } )
    end

    self.hook_count = self.hook_count + 1
end

---@param module_object ash.Module
function GameEvent:cleanup( module_object )
    local hook_count = self.hook_count
    local hooks = self.hooks

    for i = hook_count, 1, -1 do
        if hooks[ i ][ 2 ] == module_object then
            hook_count = hook_count - 1
            table_remove( hooks, i )
        end
    end

    self.hook_count = hook_count
end

---@class ash.GameEventClass : ash.GameEvent
---@field __base ash.GameEvent
---@overload fun( name: string ): ash.GameEvent
local GameEventClass = class.create( GameEvent )

setmetatable( game_events, {
    __index = function( self, event_name )
        local game_event = GameEventClass( event_name )
        self[ event_name ] = game_event
        return game_event
    end
} )

---@class ash.Module : dreamwork.Object
---@field __class ash.Module
---@field Name string The name of the module.
---@field Location string The location of the module.
---@field Networks? string[] The list of networks used by the module.
---@field ClientFiles? string[] The list of client files used by the module.
---@field Environment table The environment of the module.
---@field Result? any[] The result of the module execution.
local Module = class.base( "ash.module", false )

---@class ash.ModuleClass : ash.Module
---@field __base ash.Module
---@overload fun( name: string, location: string ): ash.Module
local ModuleClass = class.create( Module )
ash.Module = ModuleClass

function Module:__tostring()
    return string_format( "ash.Module: %p [%s]", self, self.Name )
end

---@param name string
---@param location string
---@protected
function Module:__init( name, location )
    self.Location = location
    self.Name = name

    self.Environment = setmetatable( {
        MODULE = self
    }, enviroment_metatable )
end

--- [SHARED]
---
--- Adds a hook to the module.
---
---@param event_name string
---@param fn fun( ... ): ...
---@param priority? integer
function Module:On( event_name, fn, priority )
    game_events[ event_name ]:attach( self, fn, priority )
    -- logger:debug( "Hook '%s' added to %s.", event_name, self )
end

--- [SHARED]
---
--- Calls the module's hooks.
---
---@param event_name string
---@param ... any
---@return any ...
function Module:Call( event_name, ... )
    return game_events[ event_name ]:call( ... )
end

---@param file_path string
---@param stack_level? integer
---@return string file_path
local function path_perform( file_path, stack_level )
    if stack_level == nil then
        stack_level = 1
    end

    stack_level = stack_level + 1

    local uint8_1, uint8_2 = string.byte( file_path, 1, 2 )
    if uint8_1 == 0x7E --[[ ~ ]] and uint8_2 == 0x2F --[[ / ]] then
        return path.normalize( getfenv( stack_level ).__homedir .. string.sub( file_path, 2 ) )
    elseif uint8_1 == 0x2F --[[ / ]] then
        return string.sub( file_path, 2 )
    end

    return path.normalize( getfenv( stack_level ).__dir .. "/" .. file_path )
end

local file_compile
do

    local CompileString = CompileString
    local CompileFile = CompileFile

    ---@param file_path string
    ---@param file_environment table
    ---@param stack_level integer
    ---@return fun( ... ): ... fn
    ---@return table fn_environment
    function file_compile( file_path, file_environment, stack_level )
        stack_level = stack_level + 1

        local success, result

        if LUA_CLIENT and ash.Dedicated then
            success, result = pcall( CompileFile, file_path, true )
        else
            local lua_code = file.Read( file_path, "LUA" )
            if lua_code == nil or string_len( lua_code ) == 0 then
                success, result = pcall( CompileFile, file_path, true )
            else
                result = CompileString( lua_code, file_path, false )

                if isstring( result ) or result == nil then
                    success, result = false, nil
                else
                    success = true
                end
            end
        end

        if not success or result == nil then
            std.errorf( stack_level, false, "File '%s' compilation failed:\n %s.", file_path, result or "unknown error" )
        end

        ---@cast result function

        local fn_environment = {
            __dir = path.getDirectory( file_path, false ),
            __file = file_path
        }

        setmetatable( fn_environment, {
            __index = file_environment,
            __newindex = file_environment
        } )

        setfenv( result, fn_environment )
        return result, fn_environment
    end

end

do

    local raw_set = std.raw.set

    --- [SHARED]
    ---
    --- Executes lua file with given path.
    ---
    ---@param file_path string
    ---@param ... any
    ---@return any ...
    function ash.include( file_path, ... )
        local abs_path = path_perform( file_path, 2 )
        local call_environment = getfenv( 2 )

        ---@type ash.Module | nil
        local module_object = call_environment.MODULE
        if module_object ~= nil then
            call_environment = module_object.Environment or call_environment
        end

        local fn, fn_environment = file_compile( abs_path, call_environment, 2 )

        if module_object ~= nil then
            raw_set( fn_environment, "__homedir", module_object.Location )
        end

        return fn( ... )
    end

    environment.include = ash.include
    environment.dofile = ash.include

end

do

    ---@type table<string, ash.Module> | table<integer, string>
    ---@diagnostic disable-next-line: assign-type-mismatch
    local modules = ash.Modules or {}
    ash.Modules = modules

    local init_file = LUA_CLIENT and "/cl_init.lua" or "/init.lua"

    --- [SHARED]
    ---
    --- Includes and sends a module in the server and/or client.
    ---
    ---@param module_path string
    ---@param ignore_cache boolean
    ---@param stack_level integer
    ---@return ash.Module | nil module_object
    local function module_require( module_path, ignore_cache, stack_level )
        if stack_level == nil then
            stack_level = 2
        else
            stack_level = stack_level + 1
        end

        local segments, segments_count = string.byteSplit( module_path, 0x2e --[[ . ]] )
        local root_name = segments[ 1 ] or active_gamemode
        local folder_name = segments[ 2 ]

        if folder_name == nil then
            folder_name, root_name = root_name, active_gamemode
        end

        local module_name = root_name .. "." .. folder_name

        ---@type ash.Module | nil
        ---@diagnostic disable-next-line: assign-type-mismatch
        local module_object = modules[ module_name ]
        if module_object ~= nil and not ignore_cache then
            return module_object
        end

        local homedir = root_name .. "/gamemode/autorun/" .. folder_name
        if not file.IsDir( homedir, "LUA" ) then
            homedir = root_name .. "/gamemode/modules/" .. folder_name

            if not file.IsDir( homedir, "LUA" ) then
                std.errorf( stack_level, false, "Module '%s' not found!", module_name )
            end
        end

        if LUA_SERVER then
            local cl_init_path = homedir .. "/cl_init.lua"
            if file.Exists( cl_init_path, "LUA" ) then
                clientFileSend( cl_init_path, stack_level )
            else

                cl_init_path = homedir .. "/shared.lua"
                if file.Exists( cl_init_path, "LUA" ) then
                    clientFileSend( cl_init_path, stack_level )
                end

            end
        end

        local entrypoint

        if segments_count > 2 then
            entrypoint = table_concat( segments, "/", 3, segments_count )
        else
            entrypoint = init_file
        end

        local entrypoint_path = homedir .. entrypoint
        if not file.Exists( entrypoint_path, "LUA" ) then
            entrypoint_path = homedir .. "/shared.lua"

            if not file.Exists( entrypoint_path, "LUA" ) then
                -- std.errorf( stack_level, false, "Module '%s' entrypoint file is missing!", module_name )
                return nil
            end
        end

        -- cleanup
        if modules[ module_name ] ~= nil then
            local old_module = modules[ module_name ]
            modules[ module_name ] = nil

            for _, game_event in pairs( game_events ) do
                game_event:cleanup( old_module )
            end

            for i = #modules, 1, -1 do
                if modules[ i ] == module_name then
                    table_remove( modules, i )
                    break
                end
            end
        end

        module_object = ModuleClass( module_name, homedir )
        modules[ module_name ] = module_object
        table_insert( modules, module_name )

        module_object.Result = { file_compile( entrypoint_path, module_object.Environment, stack_level )() }

        if LUA_SERVER then

            local networks = module_object.Networks
            if networks ~= nil then
                for i = 1, #networks, 1 do
                    util.AddNetworkString( networks[ i ] )
                end
            end

            local client_files = module_object.ClientFiles
            if client_files ~= nil then
                for i = 1, #client_files, 1 do
                    local file_path = homedir .. "/" .. client_files[ i ]
                    if file.Exists( file_path, "lsv" ) and not file.IsDir( file_path, "lsv" ) then
                        clientFileSend( file_path, stack_level )
                    else
                        logger:error( "Failed to send file '%s' to the client from '%s'.", file_path, module_object )
                    end
                end
            end

        end

        logger:debug( "Module '%s' successfully loaded!", module_name )

        if DEBUG and LUA_SERVER then
            local workspace_object, is_directory = fs.lookup( "/workspace/gamemodes/" .. homedir )
            ---@cast workspace_object dreamwork.std.fs.File

            local mount_point, mount_path = fs.whereis( workspace_object )

            if is_directory and mount_point == "MOD" then
                local file_object
                file_object, is_directory = fs.lookup( "/garrysmod/" .. mount_path )

                if is_directory and file_object ~= nil and fs.watchdog.watch( file_object ) then
                    logger:debug( "'%s' being watched for changes.", file_object )
                end
            end
        end

        return module_object
    end

    if LUA_SERVER then

        ---@param fs_object dreamwork.std.fs.File
        ---@param is_directory boolean
        fs.watchdog.Modified:attach( function( fs_object, is_directory )
            if is_directory then return end

            local gamemode_name, module_type, directory_name = string.match( fs_object.path, "^/garrysmod/addons/[^/]+/gamemodes/([^/]+)/gamemode/(%w+)/([^/]+)/.+$" )
            if not ( module_type == "modules" or module_type == "autorun" ) then return end
            if gamemode_name == nil or directory_name == nil then return end

            local module_name = gamemode_name .. "." .. directory_name
            if modules[ module_name ] == nil then return end

            ash.resend()

            xpcall( module_require, ErrorNoHaltWithStack, module_name, true, 2 )

            timer.Create( "ash.reload.1", 2, 1, function()
                net.Start( "ash.reload" )
                net.WriteUInt( 1, 1 )
                net.WriteString( module_name )
                net.Broadcast()
            end )
        end )

    end

    --- [SHARED]
    ---
    --- Includes and sends a module in the server and/or client.
    ---
    ---@param module_name string The name of the module. e.g. "ash.utils"
    ---@param ignore_cache? boolean If true, the module will be loaded even if it is already loaded.
    ---@return ... The result of the module.
    function ash.require( module_name, ignore_cache )
        local module_object = module_require( module_name, ignore_cache == true, 2 )

        if module_object == nil then
            std.errorf( 2, false, "Module '%s' not found!", module_name )
        end

        ---@cast module_object ash.Module

        return table_unpack( module_object.Result )
    end

    environment.require = ash.require

    --- [SHARED]
    ---
    --- Reloads all modules.
    ---
    function ash.reload()
        local chain = ash.Chain

        for i = #chain, 1, -1 do
            local gamemode_info = chain[ i ]
            local name = gamemode_info.name

            local modules_path = name .. "/gamemode/autorun/"

            for _, directory_name in raw_ipairs( select( 2, file.Find( modules_path .. "*", "LUA" ) ) ) do
                xpcall( module_require, ErrorNoHaltWithStack, name .. "." .. directory_name, true, 2 )
            end
        end
    end

    if LUA_SERVER then

        util.AddNetworkString( "ash.reload" )

        concommand.Add( "ash.reload", function( pl )
            local is_player = pl and pl:IsValid()
            if is_player and not ( pl:IsSuperAdmin() or pl:IsListenServerHost() ) then
                pl:PrintMessage( 2, "You don't have permission to use this command!" )
            end

            ash.resend()
            ash.reload()

            timer.Create( "ash.reload.0", 1, 1, function()
                net.Start( "ash.reload" )
                net.WriteUInt( 0, 1 )
                net.Broadcast()
            end )
        end )

    end

    if LUA_CLIENT then

        net.Receive( "ash.reload", function()
            local uint1_1 = net.ReadUInt( 1 )
            if uint1_1 == 0 then
                timer.Create( "ash.reload.0", 1, 1, ash.reload )
            elseif uint1_1 == 1 then
                local module_name = net.ReadString()

                timer.Create( "ash.reload.1", 1, 1, function()
                    xpcall( module_require, ErrorNoHaltWithStack, module_name, true, 2 )
                end )
            end
        end )

    end

    concommand.Add( "ash.info." .. ( LUA_SERVER and "server" or "client" ), function()
        print( string_format( "%s by %s\n\nModules:", ash.Tag, ash.Author ) )

        for i = 1, #modules, 1 do
            print( string_format( "%d. %s", i, modules[ modules[ i ] ] ) )
        end

        print()
    end )

end

do

    local FindMetaTable = _G.FindMetaTable

    local cls2fn = {}

    local function call( cls, ... )
        local fn = cls2fn[ cls ]
        if fn == nil then
            std.errorf( 3, false, "attempt to call %s", cls )
        else
            return fn( ... )
        end
    end

    ---@param name string
    ---@param create_fn nil | function
    local function addMetatable( name, create_fn )
        local obj = newproxy( true )

        local obj_metatable = debug.getmetatable( obj )
        obj_metatable.MetaName = name
        obj_metatable.__call = call

        local metatable = FindMetaTable( name )
        obj_metatable.__newindex = metatable
        obj_metatable.__index = metatable


        cls2fn[ obj ] = create_fn

        return obj
    end

    ---@diagnostic disable-next-line: param-type-mismatch
    environment.DamageInfo = addMetatable( "CTakeDamageInfo", DamageInfo )

    ---@diagnostic disable-next-line: param-type-mismatch
    environment.Material = addMetatable( "IMaterial", Material )

    environment.MoveData = addMetatable( "CMoveData" )
    environment.UserCommand = addMetatable( "CUserCmd" )

    if LUA_CLIENT then

        environment.Panel = addMetatable( "Panel", vgui.Create )

    end

    ---@diagnostic disable-next-line: param-type-mismatch
    environment.Entity = addMetatable( "Entity", _G.Entity )
    environment.Weapon = addMetatable( "Weapon", LUA_SERVER and ents.Create or ents.CreateClientside )
    environment.Player = addMetatable( "Player", player.CreateNextBot )

    ---@diagnostic disable-next-line: param-type-mismatch
    environment.Vector = addMetatable( "Vector", Vector )

    ---@diagnostic disable-next-line: param-type-mismatch
    environment.Angle = addMetatable( "Angle", Angle )

    ---@diagnostic disable-next-line: param-type-mismatch
    environment.Color = addMetatable( "Color", Color )

    environment.ConVar = addMetatable( "ConVar", CreateConVar )

end
