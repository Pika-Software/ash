local file = file
local table_isEmpty = table.isEmpty
local checksum = dreamwork.std.checksum

---@class ash.config
local config = {}

local config_data = {}

---@param path string path to the config file.
---@param only_static boolean whether to only load static config.
local function read( path, only_static )
    if not only_static then
        local file_data = file.Read( path .. ".json", "DATA" )

        if file_data ~= nil then
            local decoded = util.JSONToTable( file_data )
            if decoded ~= nil and not table_isEmpty( decoded ) then
                return {
                    [ 0 ] = checksum.CRC32.digest( file_data ),
                    [ 1 ] = file_data,
                    [ 2 ] = decoded,
                }
            end
        end
    end

    local file_data_static = file.Read( "data_static/" .. path .. ".json", "GAME" )
    if file_data_static ~= nil then
        local decoded = util.JSONToTable( file_data_static )
        if decoded ~= nil and not table_isEmpty( decoded ) then
            return {
                [ 0 ] = checksum.CRC32.digest( file_data_static ),
                [ 1 ] = file_data_static,
                [ 2 ] = decoded,
            }
        end
    end

    return {
        [ 0 ] = 0,
        [ 1 ] = nil,
        [ 2 ] = {},
    }
end

config.read = read

--- [SHARED]
---
--- Load & get config data.
---
---@param path string path to the config file.
---@param only_static boolean whether to only load static config.
---@return table config data.
---@return table raw data.
function config.get( path, only_static, clear_cache )
    if clear_cache then
        config_data[ path ] = nil
    end

    local data = config_data[ path ]
    if data then
        return data[ 2 ], data
    end

    local tbl = read( "ash_config/" .. path, only_static )
    config_data[ path ] = tbl
    return tbl[ 2 ], tbl
end

return config
