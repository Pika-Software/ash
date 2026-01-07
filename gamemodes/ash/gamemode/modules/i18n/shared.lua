local string_interpolate = string.interpolate
local string_byteTrim = string.byteTrim
local string_gmatch = string.gmatch
local string_gsub = string.gsub
local string_len = string.len

---@type dreamwork.std
local std = _G.dreamwork.std
local raw_get = std.raw.get

local encoding = std.encoding
local unicode_unescape = encoding.unicode.unescape

local http = std.http
local fs = std.fs

---@class ash.i18n
local i18n = {}

---@type table<string, string>
local phrases = {}

setmetatable( phrases, {
    __index = function( self, key )
        return key
    end
} )

--- [SHARED]
---
--- Checks if a phrase exists.
---
---@param key string
---@return boolean
function i18n.exists( key )
    return raw_get( phrases, key ) ~= nil
end

---@type table<string, integer>
local phrases_sizes = {}

setmetatable( phrases_sizes, {
    __index = function( self, key )
        return string_len( key )
    end
} )

--- [SHARED]
---
--- Returns a phrase.
---
---@param str string
---@param variables? table<string, string>
local function get( str, variables )
    if variables == nil then
        return phrases[ str ]
    end

    return string_interpolate( phrases[ str ], variables, nil, nil, phrases_sizes[ str ] )
end

i18n.get = get

--- [SHARED]
---
--- Sets a phrase.
---
---@param key string
---@param value string
function i18n.set( key, value )
    phrases[ key ] = value
    phrases_sizes[ key ] = string_len( value )
end

--- [SHARED]
---
--- Resolves and interpolate all phrases in a string.
---
--- The string can contain the following format:
--- `$(key)`
---
---@param str string
---@param variables? table<string, string>
---@return string text
function i18n.perform( str, variables )
    local value = string_gsub( str, "%s?%$%(([^)]+)%)%s?", function( key )
        return get( key, variables )
    end )

    return value
end

---@param content string
local function perform_content( content )
    for key, value in string_gmatch( content, "([^\n]+)%s?=%s?([^\n]+)" ) do
        i18n.set( string_byteTrim( key ), unicode_unescape( value ) )
    end
end

---@async
local function get_body( url )
    local response = http.get( url )
    if response.status ~= 200 then
        error( "unexpected status code: " .. response.status )
    end

    return response.body
end

--- [SHARED]
---
--- Loads phrases from a file.
---
---@param language string
---@param fallback_url string
function i18n.load( language, file_name, fallback_url )
    local phrases_name = language .. "/" .. file_name

    futures.run( fs.read, function( file_ok, file_content )
        if file_ok then
            perform_content( file_content )
            return
        end

        if fallback_url == nil then
            ash.Logger:error( "Failed to load '%s' phrases - file not found or corrupted.", phrases_name )
            return
        end

        ash.Logger:warn( "Failed to load '%s' phrases - file not found or corrupted, falling back to '%s'.", phrases_name, fallback_url )

        futures.run( get_body, function( http_ok, http_content )
            if http_ok then
                perform_content( http_content )
                return
            end

            ash.Logger:error( "Failed to load %s phrases ( %s ), url is not available.", phrases_name, fallback_url )
        end, fallback_url )
    end, "/workspace/resource/localization/" .. phrases_name .. ".properties" )
end

return i18n
