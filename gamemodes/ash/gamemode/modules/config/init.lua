MODULE.ClientFiles = {
    "cl_init.lua",
}
---@class ash.config
local config = include( "shared.lua" )

MODULE.Networks = {
    "request",
}

local allowed_receive = {}

--- [SERVER]
---
--- Checks if the server is allowed to request a config from the client.
---
---@param path string
function config.setAllowReceive( path )
    allowed_receive[ path ] = true
end

--- [SERVER]
---
--- Allows the server to request a config from the client.
---
---@param path string
---@return boolean allowed or false
function config.isAllowedReceive( path )
    return allowed_receive[ path ] or false
end

local config_requested = {}
gc.setTableRules( config_requested, true )

net.Receive( "request", function( _, pl )
    local path = net.ReadString()
    if not config.isAllowedReceive( path ) then return end

    local crc = net.ReadUInt( 32 )
    local _, data = config.get( path, false )

    if not config_requested[ pl ] then
        config_requested[ pl ] = {}
    end

    if crc ~= data[ 0 ] and not config_requested[ pl ][ path ] then
        local json = util.Compress( data[ 1 ] )
        local bytes_amount = #json
        net.Start( "request" )
        net.WriteString( path )
        net.WriteBool( true )
        net.WriteUInt( bytes_amount, 16 )
        net.WriteData( json, bytes_amount )
        net.Send( pl )

        ash.Logger:debug( "Sending config update for %s to %s", tostring( path ), tostring( pl ) )

        config_requested[ pl ][ path ] = true
    else
        net.Start( "request" )
        net.WriteString( path )
        net.WriteBool( false )
        net.Send( pl )
    end

end )

return config
