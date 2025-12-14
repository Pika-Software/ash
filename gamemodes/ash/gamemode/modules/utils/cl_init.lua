---@type dreamwork
local dreamwork = _G.dreamwork

---@type dreamwork.std
local std = dreamwork.std

local http = std.http
local futures = std.futures

local math = std.math
local math_isint = math.isint

local raw = std.raw
local raw_pairs = raw.pairs

local string = std.string
local string_lower = string.lower
local string_isURL = string.isURL

local fs = std.fs
fs.makeDirectory( "/garrysmod/data/ash/downloads/images", true )

---@class ash.utils
local utils = include( "shared.lua" )

do

    local engine_loadMaterial = dreamwork.engine.loadMaterial
    local CreateMaterial = CreateMaterial
    local string_gsub = string.gsub
    local type = std.type

    local Material = Material
    local Material_SetInt = Material.SetInt
    local Material_SetFloat = Material.SetFloat
    local Material_GetKeyValues = Material.GetKeyValues

    local type2fn = {
        string = Material.SetString,
        ---@param material IMaterial
        ---@param key string
        ---@param value number
        number = function( material, key, value )
            if math_isint( value ) then
                Material_SetInt( material, key, value )
            else
                Material_SetFloat( material, key, value )
            end
        end,
        ITexture = Material.SetTexture,
        VMatrix = Material.SetMatrix,
        Vector = Material.SetVector,
    }

    ---@param from IMaterial
    ---@param to IMaterial
    local function translate( from, to )
        for key, value in raw_pairs( Material_GetKeyValues( from ) ) do
            local fn = type2fn[ type( value ) ]
            if fn ~= nil then
               fn( to, key, value )
            end
        end
    end

    ---@type table<string, boolean>
    local supported_formats = {
        jpeg = true,
        png = true
    }

    --- [SHARED]
    ---
    --- Load a material from the specified path.
    ---
    ---@param name string
    ---@param path string
    ---@param image_parameters? dreamwork.engine.ImageParameters
    ---@param shader_parameters? dreamwork.std.Material.Shader
    function utils.loadMaterial( name, path, image_parameters, shader_parameters )
        if shader_parameters == nil then
            shader_parameters = {}
        end

        local shader = shader_parameters.name or "UnlitGeneric"
        shader_parameters.name = nil

        shader_parameters["$basetexture"] = shader_parameters["$basetexture"] or ash.LoadingTextureName or "color/white"
        shader_parameters["$translucent"] = shader_parameters["$translucent"] or 1
        shader_parameters["$vertexalpha"] = shader_parameters["$vertexalpha"] or 1
        shader_parameters["$vertexcolor"] = shader_parameters["$vertexcolor"] or 1

        local material = CreateMaterial( string_gsub( name, "[^%w_]+", "_" ), shader, shader_parameters )

        if string_isURL( path ) then

            futures.run( function()
                local response = http.get( path )

                if response.status ~= 200 then return end

                local headers = {}

                for key, value in raw_pairs( response.headers ) do
                    headers[ string_lower( key ) ] = value
                end

                local content_type = headers["content-type"]
                if content_type == nil then
                    error( "failed to fetch data from URL (" .. path .. ") - no content-type" )
                end

                local content, format = string.match( content_type, "^([^/]+)/([^/;]+)" )
                if content == nil or format == nil then
                    error( "failed to fetch data from URL (" .. path .. ") - invalid content-type" )
                end

                if content ~= "image" then
                    error( "failed to fetch data from URL (" .. path .. ") - not an image" )
                end

                if supported_formats[ format ] == nil then
                    error( "failed to fetch data from URL (" .. path .. ") - unsupported format ( " .. format .. " )" )
                end

                local body = response.body

                local file_name = std.checksum.adler32( body ) .. "." .. format
                local file_path = "ash/downloads/images/" .. file_name

                if not file.Exists( file_path, "DATA" ) then
                    file.Write( "ash/downloads/images/" .. file_name, body )
                end

                return "data/" .. file_path
            end, function( ok, file_path )
                if ok then
                    translate( engine_loadMaterial( file_path, image_parameters ), material )
                else
                    ash.Logger:error( "failed to fetch data from URL (" .. path .. ")")
                end
            end )
        else
            std.setTimeout( function()
                translate( engine_loadMaterial( path, image_parameters ), material )
            end )
        end

        return material
    end

end

--- [SHARED]
---
--- Get text size
---
---@param text string
---@param font string
---@return number
---@return number
function utils.GetTextSize( text, font )
    surface.SetFont( font )
    return surface.GetTextSize( text )
end

return utils
