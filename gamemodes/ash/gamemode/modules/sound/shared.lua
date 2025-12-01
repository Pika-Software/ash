local unpack = unpack

local sound = sound
local sound_Add = sound.Add
local sound_GetTable = sound.GetTable
local sound_GetProperties = sound.GetProperties

---@class ash.sound
local ash_sound = {}

---@class ash.sound.Data.pitch
---@field [1] integer Minimal pitch value of the sound.
---@field [2] integer Maximal pitch value of the sound.

---@class ash.sound.Data
---@field name string | nil
---@field channel integer | nil
---@field volume number | nil
---@field pitch integer | ash.sound.Data.pitch | nil
---@field level integer | nil
---@field sound string | string[] | nil

ash_sound.getNames = sound_GetTable

--- [SHARED]
---
--- Returns all registered sounds.
---
---@return ash.sound.Data[], integer
function ash_sound.getAll()
    local names = sound_GetTable()
    local sounds, sound_count = {}, 0

    for i = 1, #names, 1 do
        local sound_data = sound_GetProperties( names[ i ] )
        if sound_data ~= nil then
            sound_count = sound_count + 1
            sounds[ sound_count ] = sound_data
        end
    end

    return sounds, sound_count
end

--- [SHARED]
---
--- Returns the properties of a sound.
---
---@param sound_name string
---@return ash.sound.Data | nil
function ash_sound.get( sound_name )
    ---@diagnostic disable-next-line: return-type-mismatch
    return sound_GetProperties( sound_name )
end

--- [SHARED]
---
--- Returns whether a sound exists.
---
---@param sound_name string
---@return boolean is_exists
function ash_sound.exists( sound_name )
    return sound_GetProperties( sound_name ) ~= nil
end

-- ash_sound.setActorGender = sound.SetActorGender

--- [SHARED]
---
--- Registers a sound.
---
---@param sound_data ash.sound.Data
function ash_sound.register( sound_data )
    if sound_data.name == nil then
        error( "sound name cannot be nil", 2 )
    end

    if sound_data.sound == nil then
        error( "sound sound cannot be nil", 2 )
    end

    if sound_data.channel == nil then
        sound_data.channel = 0
    end

    if sound_data.level == nil then
        sound_data.level = 75
    end

    if sound_data.pitch == nil then
        sound_data.pitch = 100
    end

    if sound_data.volume == nil then
        sound_data.volume = 1.0
    end

    ---@diagnostic disable-next-line: param-type-mismatch
    sound_Add( sound_data )
end

ash_sound.loadScript = sound.AddSoundOverrides

--- [SHARED]
---
--- Replaces a sound with another.
---
---@param sound_name string
---@param sound_data ash.sound.Data
function ash_sound.merge( sound_name, sound_data )
    local data = sound_GetProperties( sound_name ) or {}

    local name = sound_data.name
    if name ~= nil then
        data.name = name
    elseif data.name == nil then
        data.name = sound_name
    end

    local channel = sound_data.channel
    if channel ~= nil then
        data.channel = channel
    elseif data.channel == nil then
        data.channel = 0
    end

    local volume = sound_data.volume
    if volume ~= nil then
        data.volume = volume
    elseif data.volume == nil then
        data.volume = 1
    end

    local pitch = sound_data.pitch
    if pitch ~= nil then
        ---@diagnostic disable-next-line: assign-type-mismatch
        data.pitch = pitch
    elseif data.pitch == nil then
        data.pitch = 100
    end

    local level = sound_data.level
    if level ~= nil then
        data.level = level
    elseif data.level == nil then
        data.level = 75
    end

    local sounds_1 = data.sound
    local sounds_2 = sound_data.sound

    if sounds_1 == nil then
        if sounds_2 == nil then return end
        ---@diagnostic disable-next-line: assign-type-mismatch
        data.sound = sounds_2
    elseif sounds_2 ~= nil then
        if isstring( sounds_1 ) then
            ---@cast sounds_1 string
            if isstring( sounds_2 ) then
                ---@cast sounds_2 string
                ---@diagnostic disable-next-line: assign-type-mismatch
                data.sound = { sounds_1, sounds_2 }
            else
                ---@cast sounds_2 string[]
                ---@diagnostic disable-next-line: assign-type-mismatch
                data.sound = { sounds_1, unpack( sounds_2 ) }
            end
        else
            ---@type table<string, boolean>
            local sound_map = {}

            local sound_count_1 = #sounds_1
            for i = 1, sound_count_1, 1 do
                sound_map[ sounds_1[ i ] ] = true
            end

            if isstring( sounds_2 ) then
                if sound_map[ sounds_2 ] == nil then
                    sound_count_1 = sound_count_1 + 1
                    sounds_1[ sound_count_1 ] = sounds_2
                end
            else
                for i = 1, #sounds_2, 1 do
                    local sound_path = sounds_2[ i ]
                    if sound_map[ sound_path ] == nil then
                        sound_count_1 = sound_count_1 + 1
                        sounds_1[ sound_count_1 ] = sound_path
                    end
                end
            end
        end
    end

    sound_Add( data )
end

ash_sound.generate = sound.Generate
ash_sound.play = sound.Play
ash_sound.emit = EmitSound

return ash_sound
