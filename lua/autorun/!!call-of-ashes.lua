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

local isString = std.isString

local debug = std.debug
local string = std.string
local table = std.table
local class = std.class
local path = std.path
local raw = std.raw
local fs = std.fs

local glua_cvars = _G.cvars
local glua_timer = _G.timer
local glua_util = _G.util
local glua_hook = _G.hook
local glua_file = _G.file
local glua_net = _G.net

local table_insert = table.insert
local table_remove = table.remove
local table_concat = table.concat

local string_format = string.format
local string_lower = string.lower
local string_match = string.match
local string_byte = string.byte
local string_sub = string.sub

local raw_ipairs = raw.ipairs
local raw_pairs = raw.pairs

local file_Exists = glua_file.Exists
local file_IsDir = glua_file.IsDir
local file_Open = glua_file.Open

local util_Base64Encode = glua_util.Base64Encode
local util_TableToJSON = glua_util.TableToJSON
local util_Decompress = glua_util.Decompress
local util_Compress = glua_util.Compress
local util_SHA256 = glua_util.SHA256

local path_getDirectory = path.getDirectory

local Color = std.Color

---
--- The ash global namespace.
---
---@class ash
ash = ash or {}

ash.Name = "Ash"
ash.Version = "0.2.0"
ash.Author = "Unknown Developer"
ash.Tag = string_lower( string_match( ash.Name, "[^%s%p]+" ) ) .. "@" .. ash.Version

ash.DedicatedServer = game.IsDedicated()

ash.errorf = std.errorf

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

    for k, v in raw_pairs( t ) do
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

ash.ChainFile = "ash/" .. active_gamemode .. "_chain.lua"
ash.WorkshopFile = "ash/" .. active_gamemode .. "_workshop.lua"
ash.ChecksumFile = "ash/" .. active_gamemode .. "_checksums.lua"

local DEBUG = glua_cvars.Number( "developer", 0 ) ~= 0
ash.Debug = DEBUG

---@type table<string, string>
local client_checksums = {}
local clientFileSend

if LUA_SERVER then

    local AddCSLuaFile = _G.AddCSLuaFile

    ---@param file_path string
    ---@param stack_level? integer
    ---@return boolean has_changes
    ---@return string file_sha256
    function clientFileSend( file_path, stack_level )
        if stack_level == nil then
            stack_level = 2
        else
            stack_level = stack_level + 1
        end

        local file_object, is_directory = fs.lookup( "/workspace/gamemodes/" .. file_path )

        if file_object == nil then
            file_object, is_directory = fs.lookup( "/workspace/lua/" .. file_path )
        end

        if file_object == nil then
            std.errorf( stack_level, false, "File '%s' not found.", file_path )
        end

        if is_directory then
            std.errorf( stack_level, false, "File '%s' is a directory.", file_path )
        end

        ---@cast file_object dreamwork.std.fs.File

        local mount_point, mount_path = fs.whereis( file_object )

        ---@type File
        ---@diagnostic disable-next-line: assign-type-mismatch
        local file_handler = file.Open( mount_path, "rb", mount_point )

        if file_handler == nil then
            std.errorf( stack_level, false, "File '%s' does not exist.", file_path )
        end

        ---@cast file_handler File

        local lua_code = file_handler:Read( file_handler:Size() )
        file_handler:Close()

        if lua_code == nil or string_byte( lua_code, 1, 1 ) == nil then
            std.errorf( stack_level, false, "File '%s' is empty.", file_path )
        end

        ---@cast lua_code string

        local file_sha256 = util_SHA256( lua_code .. "\0" )

        if file_sha256 ~= client_checksums[ file_path ] then
            if pcall( AddCSLuaFile, file_path ) then
                logger:debug( "File '%s' with SHA-256 '%s' successfully sent to the client.", file_path, file_sha256 )
                client_checksums[ file_path ] = file_sha256

                if DEBUG then
                    if mount_point == "MOD" then
                        local fs_object
                        fs_object, is_directory = fs.lookup( "/garrysmod/" .. mount_path )

                        if not is_directory and fs_object ~= nil and fs.watchdog.watch( fs_object ) then
                            logger:debug( "'%s' being watched for changes.", fs_object.path )
                        end
                    end
                end

                return true, file_sha256
            end

            std.errorf( stack_level, false, "Failed to add file 'lua/%s' to the client.", file_path )
        end

        return false, file_sha256
    end

end

---@class ash.Gamemode
---@field Title string
---@field Name string
---@field Version string
---@field Maps string
---@field Logger dreamwork.std.console.Logger

--- [SERVER]
---
--- Build the injection file.
---
---@param name string
---@param description string
function ash.pack( name, description )
    local files_map = {}
    local file_list = {}
    local file_count = 0

    local function add_file( file_path, content )
        file_path = string_lower( file_path )

        local file_data = files_map[ file_path ]
        if file_data == nil then
            file_data = {
                path = file_path,
                content = content
            }

            file_count = file_count + 1
            file_list[ file_count ] = file_data
            files_map[ file_path ] = file_data

            file_data.index = file_count
            return
        end

        file_data.content = content
    end

    local string_len = string.len

    local function build( file_path )
        if file_count == 0 then
            return nil, "no files to inject (gma would be empty)"
        end

        ---@type File
        ---@diagnostic disable-next-line: assign-type-mismatch
        local injection_handler = file_Open( file_path, "wb", "DATA" )

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

        for i = 1, file_count, 1 do
            local file_info = file_list[ i ]
            local info_path = file_info.path

            injection_handler:WriteULong( i ) -- index
            injection_handler:Write( info_path .."\0" ) -- file_path

            local info_content = file_info.content

            injection_handler:WriteULong( string_len( info_content ) ) -- size
            injection_handler:Write( "\0\0\0\0" )

            injection_handler:WriteULong( tonumber( glua_util.CRC( info_content ), 10 ) ) -- crc32

            logger:debug( "File '%s' (%d) will be injected.", info_path, i )
        end

        -- End of file list
        injection_handler:WriteULong( 0 )

        for i = 1, file_count, 1 do
            injection_handler:Write( file_list[ i ].content )
        end

        injection_handler:WriteULong( 0 ) -- no crc :c

        injection_handler:Close()

        return "data/" .. file_path
    end

    return add_file, build
end

if LUA_SERVER then

    fs.makeDirectory( "/garrysmod/data/ash/injections", true )

    for _, file_name in raw_ipairs( glua_file.Find( "ash/injections/*.dat", "DATA" ) ) do
        glua_file.Delete( "ash/injections/" .. file_name )
    end

    ---@class ash.gamemode.Settings
    ---@field name string The name of ConVar.
    ---@field text string The title to show in game to describe this convar.
    ---@field help string The description text to show on the convar (in the console).
    ---@field type "Text" | "CheckBox" | "Numeric" VGUI element type. These are case-sensitive!
    ---@field replicate boolean Whether this convar should be replicated (networked) to clients automatically.
    ---@field dontcreate boolean Whether this convar should not be created, but still listed in the UI. Useful for engine convars.
    ---@field singleplayer boolean Whether this convar should show up for singleplayer, just having this key will enable it, it doesn't matter what the value is.
    ---@field default string The default value for the convar.

    ---@class ash.gamemode.Info
    ---@field name string
    ---@field title string
    ---@field base string
    ---@field maps string
    ---@field author string
    ---@field version string
    ---@field category "rp" | "pvp" | "pve" | "other" | string
    ---@field workshopid string
    ---@field menusystem boolean
    ---@field settings ash.gamemode.Settings[]

    --- [SERVER]
    ---
    --- Parse a gamemode file and return the gamemode info.
    ---
    ---@param name string
    ---@return ash.gamemode.Info | nil
    ---@return string | nil
    function ash.parse( name )
        local file_path = "gamemodes/" .. name .. "/" .. name .. ".txt"
        if not file_Exists( file_path, "GAME" ) then
            return nil, string_format( "could not find file '%s'", file_path )
        end

        ---@type File | nil
        ---@diagnostic disable-next-line: assign-type-mismatch
        local file_handler = file_Open( file_path, "rb", "GAME" )
        if file_handler == nil then
            return nil, string_format( "could not open file '%s'", file_path )
        end

        local file_content = file_handler:Read( file_handler:Size() )
        file_handler:Close()

        if file_content == nil or string_byte( file_content, 1, 1 ) == nil then
            return nil, string_format( "file '%s' is empty", file_path )
        end

        local gamemode_info = glua_util.KeyValuesToTable( file_content, false, false )
        if gamemode_info == nil or not istable( gamemode_info ) then
            return nil, string_format( "could not parse file '%s'", file_path )
        end

        gamemode_info.name = name

        if gamemode_info.title == nil then
            gamemode_info.title = name
        end

        if gamemode_info.base == nil then
            gamemode_info.base = "base"
        end

        if gamemode_info.maps == nil then
            gamemode_info.maps = "[%w_]+"
        end

        if gamemode_info.author == nil then
            gamemode_info.author = "unknown"
        end

        if gamemode_info.version == nil then
            gamemode_info.version = "0.1.0"
        end

        if gamemode_info.category == nil then
            gamemode_info.category = "other"
        end

        if gamemode_info.workshopid == nil then
            gamemode_info.workshopid = 0
        else
            gamemode_info.workshopid = tostring( gamemode_info.workshopid )
        end

        if gamemode_info.menusystem == nil then
            gamemode_info.menusystem = false
        else
            gamemode_info.menusystem = std.toboolean( gamemode_info.menusystem )
        end

        -- TODO: settings

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

    do

        local chain, err_msg = ash.chain( active_gamemode )
        if chain == nil then
            logger:warn( "Tethering failed: %s", err_msg )
            return
        end

        logger:info( "Tethering completed, chain is ready!" )
        ---@cast chain ash.gamemode.Info[]

        ash.Chain = chain

    end

    do

        ---@param folder_path string
        local function folder_send( folder_path )
            for _, directory_name in raw_ipairs( select( 2, glua_file.Find( folder_path .. "*", "LUA" ) ) ) do
                local directory_path = folder_path .. directory_name

                local cl_init_path = directory_path .. "/cl_init.lua"
                if file_Exists( cl_init_path, "LUA" ) then
                    clientFileSend( cl_init_path, 2 )
                end

                local shared_path = directory_path .. "/shared.lua"
                if file_Exists( shared_path, "LUA" ) then
                    clientFileSend( shared_path, 2 )
                end

                folder_send( directory_path .. "/" )
            end
        end

        --- [SERVER]
        ---
        --- Resend all files to clients.
        ---
        function ash.resend()
            local chain = ash.Chain

            for i = #chain, 1, -1 do
                folder_send( chain[ i ].name .. "/gamemode/modules/" )
            end
        end

    end

end

if LUA_SERVER then

    --- [SERVER]
    ---
    --- Rebuild ash gamemode.
    ---
    ---@param is_post_init boolean
    function ash.rebuild( is_post_init )
        local chain = ash.Chain

        local injection_name = string_format( "%s_%s.gma.dat", active_gamemode, std.uuid.v7() )
        local add_file, build = ash.pack( injection_name, "A magical injection into the game to bang greedy, fat f*ck Garry Newman." )

        if LUA_SERVER then
            if is_post_init then
                add_file( "lua/" .. ash.WorkshopFile, "return \"" .. util_Base64Encode( util_Compress( util_TableToJSON( ash.getWorkshopDL(), false ) ), true ) .. "\"" )
                add_file( "lua/" .. ash.ChecksumFile, "return \"" .. util_Base64Encode( util_Compress( util_TableToJSON( client_checksums, false ) ), true ) .. "\"" )
            else
                add_file( "lua/" .. ash.ChainFile, "return \"" .. util_Base64Encode( util_Compress( util_TableToJSON( chain, false ) ), true ) .. "\"" )
                add_file( "lua/" .. active_gamemode .. "/gamemode/cl_init.lua", "include( \"ash/cl_init.lua\" )" )
                add_file( "lua/" .. active_gamemode .. "/gamemode/init.lua", "include( \"ash/init.lua\" )" )
            end
        end

        if not is_post_init then

            ---@param name string
            ---@param path_to string
            local function bake_content( name, path_to )
                local parent_path = "gamemodes/" .. name .. "/content/" .. path_to
                local parent_files, parent_directories = glua_file.Find( parent_path .. "*", "GAME" )

                for _, file_name in raw_ipairs( parent_files ) do
                    if not file_Exists( path_to .. file_name, "GAME" ) then
                        ---@type File | nil
                        ---@diagnostic disable-next-line: assign-type-mismatch
                        local file_handler = file_Open( parent_path .. file_name, "rb", "GAME" )
                        if file_handler ~= nil then
                            add_file( path_to .. file_name, file_handler:Read( file_handler:Size() ) )
                            file_handler:Close()
                        end
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

        end

        local file_path, err_msg = build( "ash/injections/" .. injection_name )

        if file_path ~= nil and not game.MountGMA( file_path ) then
            file_path, err_msg = nil, "could not mount injection"
        end

        if file_path == nil then
            if LUA_SERVER then
                logger:error( "Failed to build injection '%s', %s.", injection_name, err_msg )
            else
                logger:warn( "Failed to build injection '%s', %s.", injection_name, err_msg )
            end
        else
            logger:info( "Injection '%s' successfully injected!", injection_name )
        end
    end

    ---@type string[]
    local workshop_list = {}

    ---@type integer
    local workshop_length = 0

    --- [SERVER]
    ---
    --- Checks if a workshop item is in the content watcher list.
    ---
    ---@param wsid string
    ---@return boolean exists
    ---@return integer index
    function ash.isInWorkshopDL( wsid )
        for i = 1, workshop_length, 1 do
            if workshop_list[ i ] == wsid then
                return true, i
            end
        end

        return false, -1
    end

    --- [SERVER]
    ---
    --- Adds/removes a workshop item from the content watcher list.
    ---
    ---@param wsid string
    function ash.setWorkshopDL( wsid, item_state )
        if item_state then
            if not ash.isInWorkshopDL( wsid ) then
                logger:info( "Workshop item '%s' added to content watcher list.", wsid )
                workshop_length = workshop_length + 1
                workshop_list[ workshop_length ] = wsid
            end

            return
        end

        local exists, index = ash.isInWorkshopDL( wsid )
        if exists then
            logger:info( "Workshop item '%s' removed from content watcher list.", wsid )
            table.remove( workshop_list, index )
        end
    end

    --- [SERVER]
    ---
    --- Returns the content watcher list.
    ---
    ---@return string[] workshop_list
    ---@return integer workshop_length
    function ash.getWorkshopDL()
        return workshop_list, workshop_length
    end

    ash.rebuild( false )

end

if LUA_CLIENT then

    --- [CLIENT]
    ---
    --- Decode an info file.
    ---
    ---@param file_path string
    ---@return table | nil, string | nil
    function ash.infoFileDecode( file_path )
        if not file_Exists( file_path, "LUA" ) then
            return nil, string_format( "file '%s' does not exist", file_path )
        end

        local fn = CompileFile( file_path, false )
        if fn == nil then
            return nil, string_format( "failed to compile file '%s'", file_path )
        end

        -- script kiddy protection :p
        setfenv( fn, {} )

        local data_str = fn()

        if data_str == nil then
            return nil, string_format( "failed to run file '%s', no data :c", file_path )
        end

        if not isString( data_str ) then
            return nil, string_format( "failed to read file '%s', invalid data >:c", file_path )
        end

        local decoded_data = glua_util.Base64Decode( data_str )
        if decoded_data == nil then
            return nil, string_format( "failed to decode file '%s', invalid data >:c", file_path )
        end

        local compressed_data = glua_util.Decompress( decoded_data )
        if compressed_data == nil then
            return nil, string_format( "failed to decompress file '%s', possibly data corruption :-c", file_path )
        end

        local data = glua_util.JSONToTable( compressed_data, true, true )
        if data == nil or not istable( data ) then
            return nil, string_format( "failed to parse file '%s', possibly data corruption x_x", file_path )
        end

        return data
    end

    local chain, err_msg = ash.infoFileDecode( ash.ChainFile )
    if chain == nil then
        logger:error( "Satellite failed to receive gamemode '%s' information, %s", active_gamemode, err_msg )
        return
    end

    ---@cast chain ash.gamemode.Info[]

    if LUA_CLIENT then
        logger:debug( "Satellite successfully received information about the chain!" )
    end

    ---@type ash.gamemode.Info[]
    ash.Chain = chain

    client_checksums = ash.infoFileDecode( ash.ChecksumFile ) or client_checksums

    setmetatable( client_checksums, {
        __index = function( _, file_path )
            return file_path
        end
    } )

end

if _G[ active_gamemode ] == nil then
    local active_link = ash.Chain[ 1 ]
    local active_title = active_link.title
    local active_author = active_link.author

    _G[ active_gamemode ] = {
        Version = active_link.version,
        Author = active_author,
        Title = active_title,
        Maps = active_link.maps,
        Name = active_link.name,
        Logger = std.console.Logger( {
            title = active_gamemode .. "@" .. active_link.version,
            color = Color( 255, 255, 255 ),
            interpolation = false
        } )
    }

    glua_hook.Add( "PostGamemodeLoaded", "ash.gamemode", function()
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

environment.futures = std.futures
environment.string = string
environment.math = std.math
environment.class = class
environment.path = path

environment.printf = std.printf
environment.Color = Color

environment.DEBUG = DEBUG
environment._G = _G

environment.isfunction = std.isFunction
environment.isnumber = std.isNumber
environment.isbool = std.isBoolean
environment.isstring = isString

do

    local debug_getmetavalue = debug.getmetavalue
    local type = std.type

    function environment.type( value )
        return debug_getmetavalue( value, "MetaName" ) or type( value )
    end

end

local enviroment_metatable = {
    __index = environment,
    -- __newindex = debug.fempty
}

do

    local gamemode_Register = gamemode.Register

    ---@param it GM
    ---@param name string
    ---@param base_name string
    ---@diagnostic disable-next-line: duplicate-set-field
    function gamemode.Register( it, name, base_name )
        xpcall( glua_hook.Run, ErrorNoHaltWithStack, "GamemodeRegistered", name, it, base_name )
        return gamemode_Register( it, name, base_name )
    end

end

---@class ash.Module : dreamwork.Object
---@field __class ash.Module
---@field Name string The name of the module.
---@field Prefix string The prefix of the module.
---@field Location string The location of the module.
---@field EntryPoint string The entrypoint of the module.
---@field Networks? string[] The list of networks used by the module.
---@field ClientFiles? string[] The list of client files used by the module.
---@field Environment table The environment of the module.
---@field Result? any[] The result of the module execution.
---@field Error? string The error of the module execution.
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
    self.Prefix = name .. "::"
    self.Location = location
    self.Name = name
end

do

    ---@type table<ash.Module, table<string, any[]>>
    local hooks = {}

    ---@type table<ash.Module, string[]>
    local timers = {}

    ---@type table<ash.Module, table<string, integer>>
    local networks = {}

    ---@type table<ash.Module, table<string, string[]>>
    local cvar_callbacks = {}

    do

        local events_metatable = {
            __index = function( self, event_name )
                local identifiers = {}
                self[ event_name ] = identifiers
                return identifiers
            end
        }

        setmetatable( hooks, {
            -- __mode = "k",
            __index = function( self, module_object )
                local events = {}
                setmetatable( events, events_metatable )
                self[ module_object ] = events
                return events
            end
        } )

        setmetatable( timers, events_metatable )
        setmetatable( networks, events_metatable )

        setmetatable( cvar_callbacks, {
            __index = function( self, module_object )
                local identifiers = {}
                setmetatable( identifiers, events_metatable )
                self[ module_object ] = identifiers
                return identifiers
            end
        } )

    end

    local cvars_RemoveChangeCallback = glua_cvars.RemoveChangeCallback

    do


        local cvars = {}
        environment.cvars = cvars

        local cvars_AddChangeCallback = glua_cvars.AddChangeCallback

        ---@param cvar_name string
        ---@param fn function
        ---@param identifier? string
        function cvars.AddChangeCallback( cvar_name, fn, identifier )
            if identifier == nil then
                identifier = "Default"
            end

            local call_environment = getfenv( 2 )
            if call_environment ~= nil then
                ---@type ash.Module | nil
                local module_object = call_environment.MODULE
                if module_object ~= nil then
                    local identifiers = cvar_callbacks[ module_object ][ cvar_name ]

                    for i = #identifiers, 1, -1 do
                        if identifiers[ i ] == identifier then
                            table_remove( identifiers, i )
                            break
                        end
                    end

                    table_insert( identifiers, identifier )

                    identifier = module_object.Prefix .. identifier
                end
            end

            return cvars_AddChangeCallback( cvar_name, fn, identifier )
        end

        ---@param cvar_name string
        ---@param identifier? string
        function cvars.RemoveChangeCallback( cvar_name, identifier )
            if identifier == nil then
                identifier = "Default"
            end

            local call_environment = getfenv( 2 )
            if call_environment ~= nil then
                ---@type ash.Module | nil
                local module_object = call_environment.MODULE
                if module_object ~= nil then
                    local identifiers = cvar_callbacks[ module_object ][ cvar_name ]

                    for i = #identifiers, 1, -1 do
                        if identifiers[ i ] == identifier then
                            identifier = module_object.Prefix .. identifier
                            table_remove( identifiers, i )
                            break
                        end
                    end
                end
            end

            return cvars_RemoveChangeCallback( cvar_name, identifier )
        end

        setmetatable( cvars, {
            __index = glua_cvars,
            -- __newindex = glua_cvars
        } )

    end

    if LUA_SERVER then

        local util = {}
        environment.util = util

        local util_AddNetworkString = glua_util.AddNetworkString

        function util.AddNetworkString( network_name )
            local call_environment = getfenv( 2 )
            if call_environment ~= nil then
                ---@type ash.Module | nil
                local module_object = call_environment.MODULE
                if module_object ~= nil then
                    network_name = module_object.Prefix .. network_name

                    local network_id = util_AddNetworkString( network_name )
                    networks[ module_object ][ network_name ] = network_id
                    return network_id
                end
            end

            return util_AddNetworkString( network_name )
        end

        setmetatable( util, {
            __index = glua_util,
            -- __newindex = glua_util
        } )

    end

    local net_Receive = glua_net.Receive

    do

        local net = {}
        environment.net = net

        local net_Start = glua_net.Start

        ---@param network_name string
        ---@param unreliable boolean
        ---@return boolean
        function net.Start( network_name, unreliable )
            local call_environment = getfenv( 2 )
            if call_environment ~= nil then
                ---@type ash.Module | nil
                local module_object = call_environment.MODULE
                if module_object ~= nil then
                    network_name = module_object.Prefix .. network_name
                end
            end

            return net_Start( network_name, unreliable )
        end

        ---@param network_name string
        ---@param fn function
        function net.Receive( network_name, fn )
            local call_environment = getfenv( 2 )
            if call_environment ~= nil then
                ---@type ash.Module | nil
                local module_object = call_environment.MODULE
                if module_object ~= nil then
                    network_name = module_object.Prefix .. network_name
                end
            end

            return net_Receive( network_name, fn )
        end

        setmetatable( net, {
            __index = glua_net,
            -- __newindex = glua_net
        } )


    end

    if LUA_SERVER then

        local resource = {}
        environment.resource = resource

        function resource.AddWorkshop( wsid )
            ash.setWorkshopDL( wsid, true )
        end

        setmetatable( resource, {
            __index = _G.resource,
            -- __newindex = _G.resource
        } )

    end

    local ash_hook = {}
    environment.hook = ash_hook

    do

        local hook_Add = glua_hook.Add

        ---@param event_name string
        ---@param identifier any
        ---@param fn function
        ---@param priority? integer
        function ash_hook.Add( event_name, identifier, fn, priority )
            if isString( identifier ) then
                local call_environment = getfenv( 2 )
                if call_environment ~= nil then
                    ---@type ash.Module | nil
                    local module_object = call_environment.MODULE
                    if module_object ~= nil then
                        local identifiers = hooks[ module_object ][ event_name ]

                        for i = #identifiers, 1, -1 do
                            if identifiers[ i ] == identifier then
                                table_remove( identifiers, i )
                                break
                            end
                        end

                        table_insert( identifiers, identifier )

                        ---@diagnostic disable-next-line: redundant-parameter
                        return hook_Add( event_name, module_object.Prefix .. identifier, fn, priority )
                    end
                end
            end

            ---@diagnostic disable-next-line: redundant-parameter
            return hook_Add( event_name, identifier, fn, priority )
        end

    end

    ash_hook.Call = glua_hook.Call
    ash_hook.Run = glua_hook.Run

    local ash_timer = {}
    environment.timer = ash_timer

    do

        local timer_Create = glua_timer.Create

        ---@param identifier string
        ---@param delay number
        ---@param repetitions integer
        ---@param event_fn function
        function ash_timer.Create( identifier, delay, repetitions, event_fn )
            local call_environment = getfenv( 2 )
            if call_environment ~= nil then
                ---@type ash.Module | nil
                local module_object = call_environment.MODULE
                if module_object ~= nil then
                    local identifiers = timers[ module_object ]

                    for i = #identifiers, 1, -1 do
                        if identifiers[ i ] == identifier then
                            table_remove( identifiers, i )
                            break
                        end
                    end

                    table_insert( identifiers, identifier )

                    return timer_Create( module_object.Prefix .. identifier, delay, repetitions, event_fn )
                end
            end

            return timer_Create( identifier, delay, repetitions, event_fn )
        end

    end

    setmetatable( ash_timer, {
        __index = glua_timer,
        -- __newindex = glua_timer
    } )

    do

        ---@param fn function
        ---@return fun( identifier: string, ... ): ...
        local function timer_fn( fn )
            return function( identifier, ... )
                local call_environment = getfenv( 2 )
                if call_environment ~= nil then
                    ---@type ash.Module | nil
                    local module_object = call_environment.MODULE
                    if module_object ~= nil then
                        local identifiers = timers[ module_object ]

                        for i = #identifiers, 1, -1 do
                            if identifiers[ i ] == identifier then
                                return fn( module_object.Prefix .. identifier, ... )
                            end
                        end
                    end
                end

                return fn( identifier, ... )
            end
        end

        ash_timer.Adjust = timer_fn( glua_timer.Adjust )
        ash_timer.Create = timer_fn( glua_timer.Create )
        ash_timer.Exists = timer_fn( glua_timer.Exists )

        ash_timer.Start = timer_fn( glua_timer.Start )
        ash_timer.Stop = timer_fn( glua_timer.Stop )

        ash_timer.Pause = timer_fn( glua_timer.Pause )
        ash_timer.UnPause = timer_fn( glua_timer.UnPause )
        ash_timer.Toggle = timer_fn( glua_timer.Toggle )

        ash_timer.RepsLeft = timer_fn( glua_timer.RepsLeft )
        ash_timer.TimeLeft = timer_fn( glua_timer.TimeLeft )

    end

    do

        local hook_Remove = glua_hook.Remove

        ---@param event_name string
        ---@param identifier any
        function ash_hook.Remove( event_name, identifier )
            if isString( identifier ) then
                local call_environment = getfenv( 2 )
                if call_environment ~= nil then
                    ---@type ash.Module | nil
                    local module_object = call_environment.MODULE
                    if module_object ~= nil then
                        local identifiers = hooks[ module_object ][ event_name ]

                        for i = #identifiers, 1, -1 do
                            if identifiers[ i ] == identifier then
                                table_remove( identifiers, i )
                                return hook_Remove( event_name, module_object.Prefix .. identifier )
                            end
                        end
                    end
                end
            end

            return hook_Remove( event_name, identifier )
        end

        local timer_Remove = glua_timer.Remove

        ---@param timer_name string
        function ash_timer.Remove( timer_name )
            local call_environment = getfenv( 2 )
            if call_environment ~= nil then
                ---@type ash.Module | nil
                local module_object = call_environment.MODULE
                if module_object ~= nil then
                    local identifiers = hooks[ module_object ]

                    for i = #identifiers, 1, -1 do
                        if identifiers[ i ] == timer_name then
                            table_remove( identifiers, i )
                            return timer_Remove( module_object.Prefix .. timer_name )
                        end
                    end
                end
            end

            return timer_Remove( timer_name )
        end

        --- [SHARED]
        ---
        --- Unloads the module.
        ---
        function Module:unload()
            if self.Environment == nil then return end

            self.Environment = nil
            self.Result = nil
            self.Error = nil

            local prefix = self.Prefix

            for event_name, identifiers in raw_pairs( hooks[ self ] ) do
                for i = #identifiers, 1, -1 do
                    local identifier = identifiers[ i ]

                    if isString( identifier ) then
                        identifier = prefix .. identifier
                    end

                    hook_Remove( event_name, identifier )
                end
            end

            local timer_list = timers[ self ]

            for i = #timer_list, 1, -1 do
                timer_Remove( timer_list[ i ] )
            end

            for network_name, network_id in raw_pairs( networks[ self ] ) do
                ---@diagnostic disable-next-line: param-type-mismatch
                net_Receive( network_name, nil )
            end

            for cvar_name, identifiers in raw_pairs( cvar_callbacks[ self ] ) do
                for i = 1, #identifiers, 1 do
                    cvars_RemoveChangeCallback( cvar_name, identifiers[ i ] )
                end
            end
        end

    end

end

---@param file_path string
---@param stack_level? integer
---@return string file_path
local function path_perform( file_path, stack_level )
    if stack_level == nil then
        stack_level = 1
    end

    stack_level = stack_level + 1

    local uint8_1, uint8_2 = string_byte( file_path, 1, 2 )
    if uint8_1 == 0x7E --[[ ~ ]] and uint8_2 == 0x2F --[[ / ]] then
        return path.normalize( getfenv( stack_level ).__homedir .. string_sub( file_path, 2 ) )
    elseif uint8_1 == 0x2F --[[ / ]] then
        return string_sub( file_path, 2 )
    end

    return path.normalize( getfenv( stack_level ).__dir .. "/" .. file_path )
end

if LUA_SERVER then

    --- [SHARED]
    ---
    --- Adds a file to the list of files to be sended to the client.
    ---
    ---@param file_path string
    function environment.AddCSLuaFile( file_path )
        clientFileSend( path_perform( file_path ), 2 )
    end

    ash.send = environment.AddCSLuaFile

end

local file_compile
do

    local CompileString = CompileString

    local compiler_fn

    if LUA_SERVER then

        ---@param file_path string
        ---@param stack_level integer
        ---@return function
        function compiler_fn( file_path, stack_level )
            stack_level = stack_level + 1

            local file_object, is_directory = fs.lookup( "/workspace/gamemodes/" .. file_path )

            if file_object == nil then
                file_object, is_directory = fs.lookup( "/workspace/lua/" .. file_path )
            end

            if file_object == nil then
                std.errorf( stack_level, false, "File '%s' not found.", file_path )
            end

            if is_directory then
                std.errorf( stack_level, false, "File '%s' is a directory.", file_path )
            end

            ---@cast file_object dreamwork.std.fs.File

            local mount_point, mount_path = fs.whereis( file_object )

            if DEBUG then
                if mount_point == "MOD" then
                    local fs_object
                    fs_object, is_directory = fs.lookup( "/garrysmod/" .. mount_path )

                    if not is_directory and fs_object ~= nil and fs.watchdog.watch( fs_object ) then
                        logger:debug( "'%s' being watched for changes.", fs_object.path )
                    end
                end
            end

            ---@type File
            ---@diagnostic disable-next-line: assign-type-mismatch
            local file_handler = file.Open( mount_path, "rb", mount_point )

            if file_handler == nil then
                local success, result = pcall( CompileFile, file_path, true )

                if not success or result == nil then
                    std.errorf( stack_level, false, "File '%s' compilation failed:\n %s.", file_path, result or "unknown error" )
                end

                ---@cast result function

                return result
            end

            local lua_code = file_handler:Read( file_handler:Size() )
            file_handler:Close()

            if string_byte( lua_code, 1, 1 ) == nil then
                std.errorf( stack_level, false, "File '%s' is empty.", file_path )
            end

            local success, result = pcall( CompileString, lua_code, file_path, false )

            if isString( result ) then
                success = false
            end

            if not success or result == nil then
                std.errorf( stack_level, false, "File '%s' compilation failed:\n %s.", file_path, result or "unknown error" )
            end

            ---@cast result function

            return result
        end

    elseif LUA_CLIENT then

        ---@param file_path string
        ---@param stack_level integer
        ---@return function
        function compiler_fn( file_path, stack_level )
            stack_level = stack_level + 1

            local success, result = pcall( CompileFile, file_path, true )

            if success and result ~= nil then
                ---@cast result function
                return result
            end

            ---@type File | nil
            ---@diagnostic disable-next-line: assign-type-mismatch
            local file_handler = file_Open( "cache/lua/" .. string_sub( client_checksums[ file_path ], 1, 40 ) .. ".lua", "rb", "MOD" )

            if file_handler == nil then
                std.errorf( stack_level, false, "File '%s' does not exist.", file_path )
            end

            ---@cast file_handler File

            local compressed_data = file_handler:Read( file_handler:Size() )
            file_handler:Close()

            if compressed_data == nil or string_byte( compressed_data, 1, 1 ) == nil then
                std.errorf( stack_level, false, "File '%s' is empty.", file_path )
            end

            ---@cast compressed_data string

            local lua_code = util_Decompress( string_sub( compressed_data, 33 ) )

            if lua_code == nil or string_byte( lua_code, 1, 1 ) == nil then
                std.errorf( stack_level, false, "File '%s' is empty.", file_path )
            end

            ---@cast lua_code string

            if util_SHA256( lua_code ) ~= client_checksums[ file_path ] then
                std.errorf( stack_level, false, "File '%s' has been modified.", file_path )
            end

            local success, result = pcall( CompileString, lua_code, file_path, false )

            if isString( result ) then
                success = false
            end

            if not success or result == nil then
                std.errorf( stack_level, false, "File '%s' compilation failed:\n %s.", file_path, result or "unknown error" )
            end

            ---@cast result function

            return result
        end

    end

    ---@param file_path string
    ---@param file_environment table
    ---@param stack_level integer
    ---@return fun( ... ): ... fn
    ---@return table fn_environment
    function file_compile( file_path, file_environment, stack_level )
        stack_level = stack_level + 1

        local fn = compiler_fn( file_path, stack_level )

        ---@cast fn function

        local fn_environment = {
            __dir = path_getDirectory( file_path, false ),
            __file = file_path
        }

        setmetatable( fn_environment, {
            __index = file_environment,
            __newindex = file_environment
        } )

        setfenv( fn, fn_environment )
        return fn, fn_environment
    end

end

--- [SHARED]
---
--- Loads the module.
---
---@param stack_level integer
function Module:load( stack_level )
    local module_enviroment = self.Environment
    if module_enviroment ~= nil then return end

    module_enviroment = {
        MODULE = self
    }

    setmetatable( module_enviroment, enviroment_metatable )
    self.Environment = module_enviroment

    local success, result = pcall( file_compile( self.EntryPoint, module_enviroment, stack_level ) )

    if success then
        self.Result = result
    else
        self.Error = self.EntryPoint .. ":0: " .. ( string_match( result, "^[^:]+:%d+: (.*)$" ) or result )
    end
end

do

    local raw_set = raw.set

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
            call_environment = module_object.Environment
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

    local ErrorNoHalt = _G.ErrorNoHalt

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

        if segments_count == 0 then
            std.error( "Module path cannot be empty.", stack_level, false )
        end

        if segments_count == 1 then
            segments[ 2 ] = segments[ 1 ]

            local main_fn = debug.getfmain( stack_level )
            if main_fn ~= nil then
                local fn_path = debug.getfpath( main_fn )
                if fn_path ~= nil then
                    segments[ 1 ] = string_match( fn_path, "^/workspace/lua/([^/]+)/gamemode/" )
                end
            end

            if segments[ 1 ] == nil then
                segments[ 1 ] = active_gamemode
            end

            segments_count = 2
        end

        local root_name = segments[ 1 ]
        local folder_name = segments[ 2 ]

        local module_name = table.concat( segments, ".", 1, segments_count )

        ---@type ash.Module | nil
        ---@diagnostic disable-next-line: assign-type-mismatch
        local module_object = modules[ module_name ]
        if module_object ~= nil and not ignore_cache then
            return module_object
        end

        local homedir = root_name .. "/gamemode/autorun/" .. folder_name
        if not file_IsDir( homedir, "LUA" ) then
            homedir = root_name .. "/gamemode/modules/" .. folder_name
            if not file_IsDir( homedir, "LUA" ) then
                return nil
            end
        end

        local entrypoint_path

        if segments_count == 2 then

            entrypoint_path = homedir .. init_file

            if not file_Exists( entrypoint_path, "LUA" ) then
                entrypoint_path = homedir .. "/shared.lua"
            end

        else

            entrypoint_path = homedir .. "/" .. table_concat( segments, "/", 3, segments_count )

            if file_IsDir( entrypoint_path, "LUA" ) then
                homedir, entrypoint_path = entrypoint_path, entrypoint_path .. init_file

                if not file_Exists( entrypoint_path, "LUA" ) then
                    entrypoint_path = homedir .. "/shared.lua"
                end
            else
                entrypoint_path = entrypoint_path .. ".lua"
                homedir = path_getDirectory( entrypoint_path, false ) or homedir
            end

        end

        if LUA_SERVER then
            local cl_init_path = homedir .. "/cl_init.lua"
            if file_Exists( cl_init_path, "LUA" ) then
                clientFileSend( cl_init_path, stack_level )
            end

            local shared_path = homedir .. "/shared.lua"
            if file_Exists( shared_path, "LUA" ) then
                clientFileSend( shared_path, stack_level )
            end
        end

        if not file_Exists( entrypoint_path, "LUA" ) then
            return nil
        end

        if module_object == nil then
            module_object = ModuleClass( module_name, homedir )
            modules[ module_name ] = module_object
            table_insert( modules, module_name )
        else
            module_object:unload()
        end

        module_object.EntryPoint = entrypoint_path
        module_object:load( stack_level )

        if LUA_SERVER then

            local networks = module_object.Networks
            if networks ~= nil then
                local prefix = module_object.Prefix

                for i = 1, #networks, 1 do
                    glua_util.AddNetworkString( prefix .. networks[ i ] )
                end
            end

            local client_files = module_object.ClientFiles
            if client_files ~= nil then
                for i = 1, #client_files, 1 do
                    local file_path = homedir .. "/" .. client_files[ i ]
                    if file_Exists( file_path, "lsv" ) and not file_IsDir( file_path, "lsv" ) then
                        clientFileSend( file_path, stack_level )
                    else
                        logger:error( "Failed to send file '%s' to the client from '%s'.", file_path, module_object )
                    end
                end
            end

        end

        logger:debug( "Module '%s' successfully loaded!", module_name )

        return module_object
    end

    --- [SHARED]
    ---
    --- Reloads the module.
    ---
    function Module:reload()
        logger:debug( "'%s' is being reloaded.", self )

        local module_name = self.Name
        local module_object = module_require( module_name, true, 2 )

        if module_object == nil then
            logger:error( "Failed to reload module '%s', module not found.", module_name )
            return
        end

        local error_msg = module_object.Error
        if error_msg ~= nil then
            ErrorNoHalt( error_msg .. "\n" )
            return
        end

        -- if LUA_SERVER then
        --     local timer_name = "ash.reload::" .. module_name
        --     module_require( module_name, true, 2 )

        --     glua_timer.Create( timer_name, 1, 1, function()
        --         glua_timer.Remove( timer_name )

        --         glua_net.Start( "ash.network" )
        --         glua_net.WriteUInt( 1, 2 )
        --         glua_net.WriteString( module_name )
        --         glua_net.Broadcast()
        --     end )
        -- end
    end

    if LUA_SERVER and DEBUG then

        ---@param fs_object dreamwork.std.fs.File
        ---@param is_directory boolean
        fs.watchdog.Modified:attach( function( fs_object, is_directory )
            if is_directory then return end

            local gamemode_name, module_type, directory_path, file_name = string_match( fs_object.path, "^/garrysmod/addons/[^/]+/gamemodes/([^/]+)/gamemode/(%w+)/(.+)/(.+%.lua)$" )
            if gamemode_name == nil or not ( module_type == "modules" or module_type == "autorun" ) or directory_path == nil then return end

            local segments, segment_count = string.byteSplit( directory_path, 0x2F --[[ / ]] )
            if segment_count == 0 then return end

            local lua_path = table_concat( { gamemode_name, "gamemode", module_type, directory_path, file_name }, "/", 1, 5 )

            if client_checksums[ lua_path ] ~= nil then
                local has_changes, file_sha256 = clientFileSend( lua_path, 2 )
                if has_changes then
                    std.setTimeout( function()
                        glua_net.Start( "ash.network" )
                        glua_net.WriteUInt( 2, 2 )
                        glua_net.WriteString( lua_path )
                        glua_net.WriteString( file_sha256 )
                        glua_net.Broadcast()
                    end )
                end
            end

            for i = segment_count, 1, -1 do
                local module_object = modules[ gamemode_name .. "." .. table_concat( segments, ".", 1, i ) ]
                if module_object ~= nil then
                    ---@cast module_object ash.Module
                    module_object:reload()
                    break
                end
            end
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

        local err_msg = module_object.Error
        if err_msg ~= nil then
            error( err_msg, 2 )
        end

        return module_object.Result
    end

    environment.require = ash.require

    do

        local raw_tonumber = raw.tonumber

        --- [SHARED]
        ---
        --- Reloads all modules.
        ---
        function ash.reload()
            local chain = ash.Chain

            for i = #chain, 1, -1 do
                local gamemode_info = chain[ i ]
                local root_name = gamemode_info.name

                local workshopid = gamemode_info.workshopid
                if workshopid ~= nil and ( raw_tonumber( workshopid, 10 ) or 0 ) > 0 then
                    ash.setWorkshopDL( workshopid, true )
                end

                local modules_path = root_name .. "/gamemode/autorun/"

                for _, directory_name in raw_ipairs( select( 2, glua_file.Find( modules_path .. "*", "LUA" ) ) ) do
                    local module_object = module_require( root_name .. "." .. directory_name, true, 2 )
                    if module_object ~= nil then
                        local err_msg = module_object.Error
                        if err_msg ~= nil then
                            ErrorNoHalt( err_msg .. "\n" )
                        end
                    end
                end
            end
        end

    end

    if LUA_SERVER then

        glua_util.AddNetworkString( "ash.network" )

        concommand.Add( "ash.reload", function( pl )
            local is_player = pl and pl:IsValid()
            if is_player and not ( pl:IsSuperAdmin() or pl:IsListenServerHost() ) then
                pl:PrintMessage( 2, "You don't have permission to use this command!" )
            end

            ash.resend()
            ash.reload()

            glua_timer.Create( "ash.reload", 1, 1, function()
                glua_net.Start( "ash.network" )
                glua_net.WriteUInt( 0, 2 )
                glua_net.Broadcast()
            end )
        end )

        glua_net.Receive( "ash.network", function( len, pl )
            pl:Kick( "WorkshopDL is corrupted, please reconnect to the server!" )
        end )

    end

    if LUA_CLIENT then

        glua_net.Receive( "ash.network", function()
            local uint1_1 = glua_net.ReadUInt( 2 )
            if uint1_1 == 0 then
                glua_timer.Create( "ash.reload", 1, 1, ash.reload )
            elseif uint1_1 == 1 then
                local module_name = glua_net.ReadString()
                local timer_name = "ash.reload." .. module_name

                glua_timer.Create( timer_name, 1, 1, function()
                    glua_timer.Remove( timer_name )

                    local module_object = module_require( module_name, true, 2 )
                    if module_object ~= nil then
                        local err_msg = module_object.Error
                        if err_msg ~= nil then
                            ErrorNoHalt( err_msg .. "\n" )
                        end
                    end
                end )
            elseif uint1_1 == 2 then
                local file_path, file_sha256 = glua_net.ReadString(), glua_net.ReadString()
                logger:debug( "Received file '%s' checksum SHA-256 '%s'.", file_path, file_sha256 )
                client_checksums[ file_path ] = file_sha256

                local gamemode_name, module_type, directory_path = string_match( file_path, "^([^/]+)/gamemode/(%w+)/(.+)/.+%.lua$" )
                if gamemode_name == nil or not ( module_type == "modules" or module_type == "autorun" ) or directory_path == nil then return end

                local segments, segment_count = string.byteSplit( directory_path, 0x2F --[[ / ]] )

                for i = segment_count, 1, -1 do
                    local module_object = modules[ gamemode_name .. "." .. table_concat( segments, ".", 1, i ) ]
                    if module_object ~= nil then
                        ---@cast module_object ash.Module
                        module_object:reload()
                        break
                    end
                end

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

        environment.AudioChannel = addMetatable( "IGModAudioChannel" )
        environment.Panel = addMetatable( "Panel", vgui.Create )

    end

    environment.Texture = addMetatable( "ITexture" )

    ---@diagnostic disable-next-line: param-type-mismatch
    environment.Entity = addMetatable( "Entity", _G.Entity )
    environment.Weapon = addMetatable( "Weapon", LUA_SERVER and ents.Create or ents.CreateClientside )

    ---@diagnostic disable-next-line: param-type-mismatch
    environment.Player = addMetatable( "Player", Player )

    ---@diagnostic disable-next-line: param-type-mismatch
    environment.Vector = addMetatable( "Vector", Vector )

    ---@diagnostic disable-next-line: param-type-mismatch
    environment.Angle = addMetatable( "Angle", Angle )

    ---@diagnostic disable-next-line: param-type-mismatch
    environment.Matrix = addMetatable( "VMatrix", Matrix )

    -- ---@diagnostic disable-next-line: param-type-mismatch
    -- environment.Color = addMetatable( "Color", Color )

    environment.ConVar = addMetatable( "ConVar", CreateConVar )

end
