---@class ash.config
local config = include( "shared.lua" )

local config_queue, config_queue_count = {}, 0
local config_callbacks, config_callback_count = {}, 0

--- [CLIENT]
---
--- Requests a config from the server.
---
---@param path string
---@param callback fun(tbl: table, tbl: table)
function config.receive( path, callback )
    local _, data = config.get( path, false )

    if callback then
        config_callbacks[ path ] = callback
    end

    config_queue_count = config_queue_count + 1
    config_queue[ config_queue_count ] = { path, data[ 0 ] }
end

file.CreateDir( "ash_config" )

net.Receive( "request", function()
    local path = net.ReadString()
    local success = net.ReadBool()

    if not success then
        local callback = config_callbacks[ path ]
        if callback then
            local _, data = config.get( path, false )
            callback( data[ 2 ], data )
        end

        config_callbacks[ path ] = nil
        return
    end

    local json = util.Decompress( net.ReadData( net.ReadUInt( 16 ) ) )

    if json ~= nil then
        local split = string.split( path, "/" )

        local path_folder = "ash_config/"
        for i = 1, #split - 1 do
            path_folder = path_folder .. split[ i ]
            ash.Logger:debug( "Creating directory: " .. path_folder )
            file.CreateDir( path_folder )
            path_folder = path_folder .. "/"
        end

        file.Write( "ash_config/" .. path .. ".json", json )

        local _, data = config.get( path, false, true )

        local callback = config_callbacks[ path ]
        if callback then
            callback( data[ 2 ], data )
        end

        config_callbacks[ path ] = nil
    end

end )

hook.Add( "Think", "Defaults", function()
    if config_queue_count <= 0 and IsValid( LocalPlayer() ) then return end

    for i = config_queue_count, 1, -1 do
        local data = config_queue[ i ]
        config_queue[ i ] = nil
        config_queue_count = config_queue_count - 1

        net.Start( "request" )
        net.WriteString( data[ 1 ] )
        net.WriteUInt( data[ 2 ], 32 )
        net.SendToServer()

        ash.Logger:debug( "requesting config", data[ 1 ] )
    end
end )

return config
