---@type ash.sound
local ash_sound = require( "ash.sound" )
local sound_exists = ash_sound.exists
local sound_merge = ash_sound.merge

local string_match = string.match
local file_Find = file.Find
local hook_Run = hook.Run

---@class ash.player.footsteps
local footsteps = {}

---@type string[]
local move_types = {
    "wandering",
    "walking",
    "running",
    "landing"
}

footsteps.MoveTypes = move_types

---@type table<string, boolean>
local loud_move_types = {
    running = true,
    landing = true
}

footsteps.LoudMoveTypes = loud_move_types

---@type table<string, boolean>
local sound_registry = {}

--- [SHARED]
---
--- Register legacy footsteps for a shoes type and a directory path.
---
--- Files should be named as `{material_name}01.wav` for example.
---
---@param shoes_type string
---@param directory_path string
---@param sound_data ash.sound.Data | nil
function footsteps.registerLegacy( shoes_type, directory_path, sound_data )
    local move_types_count = #move_types

    if sound_data == nil then
        sound_data = {}
    end

    for _, file_name in ipairs( file_Find( "sound/" .. directory_path .. "/*", "GAME" ) ) do
        local material_name = string_match( file_name, "^(%l+)" ) or "default"

        local sounds = file_Find( "sound/" .. directory_path .. "/" .. material_name .. "*", "GAME" )
        local sound_count = #sounds

        if sound_count ~= 0 then
            for j = 1, sound_count, 1 do
                sounds[ j ] = ")^" .. directory_path .. "/" .. sounds[ j ]
            end

            sound_data.sound = sounds

            local base_name = shoes_type .. "." .. material_name
            sound_registry[ base_name ] = true

            for j = 1, move_types_count, 1 do
                local sound_name = base_name .. "." .. move_types[ j ]
                if not sound_exists( sound_name ) then
                    sound_merge( sound_name, sound_data )
                end
            end
        end
    end
end

--- [SHARED]
---
--- Register footsteps for a shoes type and a directory path.
---
--- Files should be named as `{material_name}/{move_type}/any_name01.wav` for example.
---
---@param shoes_type string
---@param directory_path string
---@param sound_data ash.sound.Data | nil
function footsteps.register( shoes_type, directory_path, sound_data )
    local shoes_path = directory_path .. "/" .. shoes_type .. "/"
    local move_types_count = #move_types

    if sound_data == nil then
        sound_data = {}
    end

    local _, materials = file_Find( "sound/" .. shoes_path .. "*", "GAME" )

    for k = 1, #materials, 1 do
        local material_name = materials[ k ]
        local material_path = shoes_path .. material_name .. "/"

        local base_name = shoes_type .. "." .. material_name
        local is_empty = true

        local types, type_counts = {}, {}

        for i = 1, move_types_count, 1 do
            local move_name = move_types[ i ]
            local move_path = material_path .. move_name .. "/"

            local sounds = file.Find( "sound/" .. move_path .. "*", "GAME" )
            local sound_count = #sounds

            if sound_count ~= 0 then
                is_empty = false

                for j = 1, sound_count, 1 do
                    sounds[ j ] = ")^" .. move_path .. sounds[ j ]
                end
            end

            type_counts[ move_name ] = sound_count
            types[ move_name ] = sounds
        end

        if is_empty then
            ash.Logger:warn( "Directory 'sound/%s' does not contain any files, footsteps will not be registered.", material_path )
            return
        end

        sound_registry[ base_name ] = true

        for i = 1, move_types_count, 1 do
            local move_name = move_types[ i ]

            local move_sounds, move_sound_count = types[ move_name ], type_counts[ move_name ]

            if move_sound_count == 0 then
                local init, finish, step

                if loud_move_types[ move_name ] then
                    init, finish, step = move_types_count, 1, -1
                else
                    init, finish, step = 1, move_types_count, 1
                end

                for j = init, finish, step do
                    local alt_move_name = move_types[ j ]
                    local alt_move_count = type_counts[ alt_move_name ]
                    if alt_move_count ~= 0 then
                        move_sounds = types[ alt_move_name ]
                        move_sound_count = alt_move_count
                        break
                    end
                end
            end

            sound_data.sound = move_sounds

            local sound_name = base_name .. "." .. move_name
            if not sound_exists( sound_name ) then
                sound_merge( sound_name, sound_data )
            end
        end
    end
end

--- [SHARED]
---
--- Check if footsteps exist for a shoes type and a material name.
---
---@param shoes_type string
---@param material_name string
function footsteps.exists( shoes_type, material_name )
    return sound_registry[ shoes_type .. "." .. material_name ] == true
end

--- [SHARED]
---
--- Register footsteps for a shoes type and a directory path.
---
--- Files should be named as `{material_name}/{move_type}/any_name01.wav` for example.
---
---@param shoes_type string
---@param material_name string
---@param material_base string
---@param sound_data ash.sound.Data | nil
function footsteps.alias( shoes_type, material_name, material_base, sound_data )
    local base_name = shoes_type .. "." .. material_base

    if not sound_registry[ base_name ] then
        ash.errorf( 2, true, "Footstep sounds '%s' does not exist.", base_name )
        return
    end

    if sound_data == nil then
        sound_data = {}
    end

    local sound_name = shoes_type .. "." .. material_name
    sound_registry[ sound_name ] = true

    for i = 1, #move_types, 1 do
        local move_name = move_types[ i ]

        sound_data.name = sound_name .. "." .. move_name
        sound_merge( base_name .. "." .. move_name, sound_data )
    end
end

do

    ---@type table<Player, string>
    local player_shoes_registry = {}

    setmetatable( player_shoes_registry, {
        __index = function( self, pl )
            local shoes_type = "default"
            self[ pl ] = shoes_type
            return shoes_type
        end,
        __mode = "k"
    } )

    --- [SHARED]
    ---
    --- Gets the player's shoes type.
    ---
    ---@param pl Player
    ---@return string shoes_type
    function footsteps.getShoesType( pl )
        return player_shoes_registry[ pl ]
    end

    --- [SHARED]
    ---
    --- Sets the player's shoes type.
    ---
    ---@param pl Player
    ---@param shoes_type string
    function footsteps.setShoesType( pl, shoes_type )
        player_shoes_registry[ pl ] = shoes_type
    end

end

do

    ---@class ash.player.footsteps.ShoesData : ash.sound.Data
    ---@field aliases table<string, string>
    ---@field path string | nil

    --- https://developer.valvesoftware.com/wiki/Material_surface_properties
    ---@type table<string, ash.player.footsteps.ShoesData>
    local shoes = {
        default = {
            channel = 6,
            level = 75,
            pitch = { 118, 138 },
            aliases = {
                { "tile", "concrete" },
                { "default", "concrete" },
                { "default_silent", "tile" },
                { "boulder", "concrete" },
                { "brick", "concrete" },
                { "concrete_block", "concrete" },
                { "gravel", "concrete" },
                { "rock", "concrete" },
                { "plastic", "concrete" },
                { "antlionsand", "sand" },
                -- { "metal", "metalbar" },
                { "solidmetal", "metal" },
                { "metalbox", "metal" },
                { "metalvent", "metalbox" },
                { "computer", "metalbox" },
                { "metalgrate", "metal" },
                { "wood_solid", "wood" },
                { "woodpanel", "wood_solid" },
                { "wood_furniture", "woodpanel" },
                { "wood_lowdensity", "wood_furniture" },
                { "wood_box", "wood_furniture" },
                { "wood_crate", "wood_furniture" },
                { "wood_plank", "wood_furniture" },
                { "rubber", "carpet" }
            }
        }
    }

    footsteps.Shoes = shoes

    timer.Simple( 0, function()
        for shoes_name, data in pairs( shoes ) do
            local directory_path = data.path or "player/footsteps"

            footsteps.register( shoes_name, directory_path, data )
            footsteps.registerLegacy( shoes_name, directory_path, data )

            local aliases = data.aliases

            for i = 1, #aliases, 1 do
                local alias = aliases[ i ]
                local material_name, material_base = alias[ 1 ], alias[ 2 ]

                if not footsteps.exists( shoes_name, material_name ) then
                    footsteps.alias( shoes_name, material_name, material_base )
                end
            end
        end
    end )

end

do

    local sound_play = ash_sound.play
    local math_random = math.random

    ---@type table<string, string>
    local move_states = {
        crouching = "wandering",
        wandering = "walking",
        standing = "walking",
        jumping = "landing",
        falling = "landing"
    }

    setmetatable( move_states, {
        __index = function( self, move_state )
            self[ move_state ] = move_state
            return move_state
        end
    } )

    --- [SHARED]
    ---
    --- Plays a footstep sound.
    ---
    ---@param origin Vector
    ---@param shoes_type string
    ---@param material_name string
    ---@param move_type string
    ---@param volume number | nil
    ---@param sound_level integer | nil
    ---@param pitch integer | nil
    ---@param dsp integer | nil
    function footsteps.play( origin, shoes_type, material_name, move_type, volume, sound_level, pitch, dsp )
        local sound_name = shoes_type .. "." .. material_name
        if sound_registry[ sound_name ] then
            sound_play( sound_name .. "." .. move_states[ move_type ], origin, sound_level, pitch, volume, dsp )
        end
    end

    ---@param pl Player
    ---@param sound_position Vector
    ---@param move_state string
    ---@param bone_id integer
    ---@param fallback_sound string
    hook.Add( "ash.player.footsteps.FootDown", "Sounds", function( pl, sound_position, player_shoes, material_name, move_state, bone_id, fallback_sound )
        local selected_state = move_states[ move_state ]

        local sound_level, pitch, volume = hook_Run( "ash.player.footsteps.Sound", pl, sound_position, player_shoes, material_name, selected_state, bone_id )

        if material_name ~= nil then
            local sound_name = player_shoes .. "." .. material_name
            if sound_registry[ sound_name ] then
                sound_play( sound_name .. "." .. selected_state, sound_position, sound_level, pitch, volume, 1 )
                return
            end
        end

        if fallback_sound ~= nil then
            sound_play( fallback_sound, sound_position, sound_level, pitch, volume, 1 )
        end
    end )

end

return footsteps
