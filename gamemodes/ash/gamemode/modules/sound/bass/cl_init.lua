
---@type dreamwork.std
local std = _G.dreamwork.std

local string = std.string
local string_isURL = string.isURL
local string_format = string.format

local sound = sound
local sound_PlayURL = sound.PlayURL
local sound_PlayFile = sound.PlayFile

---@type ash.sound
local ash_sound = require( "ash.sound" )
local sound_get = ash_sound.get

local AudioChannel = AudioChannel
local AudioChannel_IsValid = AudioChannel.IsValid

local AudioChannel_GetTime = AudioChannel.GetTime
local AudioChannel_SetTime = AudioChannel.SetTime

local AudioChannel_GetPos = AudioChannel.GetPos
local AudioChannel_SetPos = AudioChannel.SetPos

local AudioChannel_GetPan = AudioChannel.GetPan
local AudioChannel_SetPan = AudioChannel.SetPan

local AudioChannel_GetLength = AudioChannel.GetLength

local AudioChannel_SetVolume = AudioChannel.SetVolume

local AudioChannel_GetPlaybackRate = AudioChannel.GetPlaybackRate
local AudioChannel_SetPlaybackRate = AudioChannel.SetPlaybackRate

local AudioChannel_Get3DFadeDistance = AudioChannel.Get3DFadeDistance
local AudioChannel_Set3DFadeDistance = AudioChannel.Set3DFadeDistance

local AudioChannel_Get3DCone = AudioChannel.Get3DCone
local AudioChannel_Set3DCone = AudioChannel.Set3DCone

local AudioChannel_GetBufferedTime = AudioChannel.GetBufferedTime
local AudioChannel_IsOnline = AudioChannel.IsOnline
local AudioChannel_GetState = AudioChannel.GetState

local file_Exists = file.Exists
local file_IsDir = file.IsDir

local math = std.math
local math_max = math.max
local math_clamp = math.clamp
local math_floor = math.floor
local math_random = math.random

---@class ash.sound.bass
local ash_bass = {}

---@class ash.sound.bass.Channel : dreamwork.Object
---@field __class ash.sound.bass.ChannelClass
local Channel = class.base( "bass.Channel", true )

---@class ash.sound.bass.ChannelClass : ash.sound.bass.Channel
---@field __base ash.sound.bass.Channel
local ChannelClass = class.create( Channel )

---@type table<ash.sound.bass.Channel, IGModAudioChannel>
local channels = {}
gc.setTableRules( channels, true )

---@param channel IGModAudioChannel
---@protected
function Channel:__init( channel )
    channels[ self ] = channel
end

---@protected
function Channel:__gc()
    local channel = channels[ self ]
    if channel ~= nil and AudioChannel_IsValid( channel ) then
        channel:Stop()
    end
end

function Channel:isValid()
    return AudioChannel_IsValid( channels[ self ] )
end

Channel.IsValid = Channel.isValid

do

    local AudioChannel_IsBlockStreamed = AudioChannel.IsBlockStreamed

    --- [CLIENT]
    ---
    --- Returns `true` if the channel is blocked.
    ---
    ---@return boolean is_blocked
    function Channel:isBlocked()
        return AudioChannel_IsBlockStreamed( channels[ self ] )
    end

end

--- [CLIENT]
---
--- Returns the status of the channel.
---
---@return GMOD_CHANNEL status
function Channel:getStatus()
    return AudioChannel_GetState( channels[ self ] )
end

do

    local AudioChannel_GetFileName = AudioChannel.GetFileName

    --- [CLIENT]
    ---
    --- Returns the file path or URL of the channel.
    ---
    ---@return string path
    function Channel:getFilePath()
        return AudioChannel_GetFileName( channels[ self ] )
    end

end

do

    local AudioChannel_GetAverageBitRate = AudioChannel.GetAverageBitRate

    --- [CLIENT]
    ---
    --- Returns the average bit rate of the channel.
    ---
    ---@return integer bit_rate
    function Channel:getBitRate()
        return AudioChannel_GetAverageBitRate( channels[ self ] )
    end

end

do

    local AudioChannel_GetBitsPerSample = AudioChannel.GetBitsPerSample

    --- [CLIENT]
    ---
    --- Returns the average bit depth of the channel.
    ---
    ---@return integer bit_depth
    function Channel:getBitDepth()
        return AudioChannel_GetBitsPerSample( channels[ self ] )
    end

end

do

    local AudioChannel_GetSamplingRate = AudioChannel.GetSamplingRate

    --- [CLIENT]
    ---
    --- Returns the sample rate of the channel.
    ---
    ---@return integer sample_rate
    function Channel:getSampleRate()
        return AudioChannel_GetSamplingRate( channels[ self ] )
    end

end

do

    local AudioChannel_GetTagsVendor = AudioChannel.GetTagsVendor

    --- [CLIENT]
    ---
    --- Returns the vendor of the channel.
    ---
    ---@return string vendor
    function Channel:getOGGVendor()
        return AudioChannel_GetTagsVendor( channels[ self ] )
    end

end

do

    local AudioChannel_GetTagsHTTP = AudioChannel.GetTagsHTTP

    --- [CLIENT]
    ---
    --- Returns the response headers of the channel.
    ---
    ---@return table headers
    function Channel:getResponseHeaders()
        return AudioChannel_GetTagsHTTP( channels[ self ] )
    end

end

--- [CLIENT]
---
--- Returns the time of the channel in seconds.
---
---@return number time
function Channel:getTime()
    return AudioChannel_GetTime( channels[ self ] )
end

do

    local AudioChannel_GetVolume = AudioChannel.GetVolume

    --- [CLIENT]
    ---
    --- Returns the volume of the channel.
    ---
    ---@return number volume
    function Channel:getVolume()
        return AudioChannel_GetVolume( channels[ self ] )
    end

end

--- [CLIENT]
---
--- Sets the volume of the channel.
---
---@param volume number
function Channel:setVolume( volume )
    AudioChannel_SetVolume( channels[ self ], volume )
end

do

    local AudioChannel_GetLevel = AudioChannel.GetLevel

    --- [CLIENT]
    ---
    --- Returns the right and left levels of sound played by the sound channel.
    ---
    ---@return number left_volume The audio volume in the left ear.
    ---@return number right_volume The audio volume in the right ear.
    function Channel:getVolumeLevels()
        return AudioChannel_GetLevel( channels[ self ] )
    end

    --- [CLIENT]
    ---
    --- Returns the average volume of the channel.
    ---
    ---@return number volume
    function Channel:getVolumeLevel()
        local left_volume, right_volume = self:getVolumeLevels()
        return ( left_volume + right_volume ) * 0.5
    end

end

--- [CLIENT]
---
--- Returns the playback rate of the channel.
---
---@return number playback_rate
function Channel:getPlaybackRate()
    return AudioChannel_GetPlaybackRate( channels[ self ] )
end

--- [CLIENT]
---
--- Sets the playback rate of the channel.
---
---@param rate number The playback rate of the channel. Range is from 0 to 1.
function Channel:setPlaybackRate( rate )
    AudioChannel_SetPlaybackRate( channels[ self ], rate )
end

do

    local AudioChannel_IsLooping = AudioChannel.IsLooping

    --- [CLIENT]
    ---
    --- Returns `true` if the channel is looping.
    ---
    ---@return boolean is_looping
    function Channel:isLooping()
        return AudioChannel_IsLooping( channels[ self ] )
    end

end

do

    local AudioChannel_EnableLooping = AudioChannel.EnableLooping

    --- [CLIENT]
    ---
    --- Sets the looping of the channel.
    ---
    ---@param loop boolean
    function Channel:setLooping( loop )
        AudioChannel_EnableLooping( channels[ self ], loop )
    end

end

do

    local AudioChannel_Get3DEnabled = AudioChannel.Get3DEnabled

    --- [CLIENT]
    ---
    --- Returns `true` if the channel is in 3D.
    ---
    ---@return boolean is_3d
    function Channel:is3D()
        return AudioChannel_Get3DEnabled( channels[ self ] )
    end

end

do

    local AudioChannel_Set3DEnabled = AudioChannel.Set3DEnabled

    --- [CLIENT]
    ---
    --- Sets the 3D state of the channel.
    ---
    ---@param enabled boolean
    function Channel:set3D( enabled )
        AudioChannel_Set3DEnabled( channels[ self ], enabled )
    end

end

--- [CLIENT]
---
--- Returns the absolute position of the channel in 3D space (world/level).
---
---@return Vector position
function Channel:getPosition()
    return AudioChannel_GetPos( channels[ self ] )
end

--- [CLIENT]
---
--- Sets the absolute position of the channel in 3D space (world/level).
---
---@param position Vector
function Channel:setPosition( position )
    AudioChannel_SetPos( channels[ self ], position )
end

--- [CLIENT]
---
--- Returns 3D fade distances of a sound channel.
---
---@return number min_distance The minimum distance. The channel's volume is at maximum when the listener is within this distance.
---@return number max_distance The maximum distance. The channel's volume stops decreasing when the listener is beyond this distance.
function Channel:getFadeDistance()
    return AudioChannel_Get3DFadeDistance( channels[ self ] )
end

--- [CLIENT]
---
--- Sets 3D fade distances of a sound channel.
---
---@param min_distance number The minimum distance. The channel's volume is at maximum when the listener is within this distance.
---@param max_distance number The maximum distance. The channel's volume stops decreasing when the listener is beyond this distance.
function Channel:setFadeDistance( min_distance, max_distance )
    AudioChannel_Set3DFadeDistance( channels[ self ], min_distance, max_distance )
end

--- [CLIENT]
---
--- Returns the inside projection angle of the channel.
---
---@return number inside_angle The angle of the inside projection cone in degrees.
---@return number outside_angle The angle of the outside projection cone in degrees.
---@return number outside_volume The delta-volume outside the outer projection cone.
function Channel:getProjectionCone()
    return AudioChannel_Get3DCone( channels[ self ] )
end

--- [CLIENT]
---
--- Sets the inside projection angle of the channel.
---
---@param inside_angle number The angle of the inside projection cone in degrees.
---@param outside_angle number The angle of the outside projection cone in degrees.
---@param outside_volume number The delta-volume outside the outer projection cone.
function Channel:setProjectionCone( inside_angle, outside_angle, outside_volume )
    AudioChannel_Set3DCone( channels[ self ], inside_angle, outside_angle, outside_volume )
end

do

    local AudioChannel_Pause = AudioChannel.Pause
    local AudioChannel_Play = AudioChannel.Play
    local AudioChannel_Stop = AudioChannel.Stop

    --- [CLIENT]
    ---
    --- Plays the channel.
    ---
    function Channel:play()
        if self:isPlaying() or self:isPaused() then return end
        AudioChannel_Play( channels[ self ] )
    end

    --- [CLIENT]
    ---
    --- Pauses the channel.
    ---
    function Channel:pause()
        if self:isPlaying() then
            AudioChannel_Pause( channels[ self ] )
        end
    end

    --- [CLIENT]
    ---
    --- Resumes the channel.
    ---
    function Channel:resume()
        if self:isPaused() then
            AudioChannel_Play( channels[ self ] )
        end
    end

    --- [CLIENT]
    ---
    --- Stops the channel.
    ---
    function Channel:stop()
        if not self:isStopped() then
            AudioChannel_Stop( channels[ self ] )
        end
    end

end

do

    local AudioChannel_FFT = AudioChannel.FFT

    --- [CLIENT] Computes the [DFT (discrete Fourier transform)](https://en.wikipedia.org/wiki/Discrete_Fourier_transform) of the sound channel.
    ---
    --- The size parameter specifies the number of consecutive audio samples to use as the input to the DFT and is restricted to a power of two. A [Hann window](https://en.wikipedia.org/wiki/Hann_function) is applied to the input data.
    ---
    --- The computed DFT has the same number of frequency bins as the number of samples. Only half of this DFT is returned, since [the DFT magnitudes are symmetric for real input data](https://en.wikipedia.org/wiki/Discrete_Fourier_transform#The_real-input_DFT). The magnitudes of the DFT (values from 0 to 1) are used to fill the output table, starting at index 1.
    ---
    --- **Visualization protip:** For a size N DFT, bin k (1-indexed) corresponds to a frequency of (k - 1) / N * sampleRate.
    ---
    --- **Visualization protip:** Sound energy is proportional to the square of the magnitudes. Adding magnitudes together makes no sense physically, but adding energies does.
    ---
    --- **Visualization protip:** The human ear works on a logarithmic amplitude scale. You can convert to [decibels](https://en.wikipedia.org/wiki/Decibel) by taking 20 * [math.log10](https://wiki.facepunch.com/gmod/math.log10) of frequency magnitudes, or 10 * [math.log10](https://wiki.facepunch.com/gmod/math.log10) of energy. The decibel values will range from -infinity to 0.
    ---
    ---[View wiki](https://wiki.facepunch.com/gmod/IGModAudioChannel:FFT)
    ---@param tbl number[] The table to output the DFT magnitudes (numbers between 0 and 1) into. Indices start from 1.
    ---@param size FFT The number of samples to use. See Enums/FFT
    ---@return number frequency_bins # The number of frequency bins that have been filled in the output table.
    function Channel:fft( tbl, size )
        return AudioChannel_FFT( channels[ self ], tbl, size )
    end

end

do

    ---@type table<string, fun( channel:ash.sound.bass.Channel ): table>
    local identify_types = {
        ogg = AudioChannel.GetTagsOGG,
        id3 = AudioChannel.GetTagsID3,
        ---@diagnostic disable-next-line: undefined-field
        mp4 = AudioChannel.GetTagsMP4,
        ---@diagnostic disable-next-line: undefined-field
        wma = AudioChannel.GetTagsWMA,
        icy = AudioChannel.GetTagsMeta
    }

    identify_types.mp3 = identify_types.id3
    identify_types.vorbis = identify_types.ogg

    --- [CLIENT]
    ---
    --- Returns the tags of the channel.
    ---
    ---@param name string
    ---@return table | string tags
    function Channel:getIdentify( name )
        local identify = identify_types[ name ]
        if identify ~= nil then
            return identify( channels[ self ] )
        end

        error( "unknown identify type: " .. name )
    end

end

function Channel:__tostring()
    return string_format( "bass.Channel: %p [%s/%s]", self, self:getTime(), self:getLength() )
end


---@type table<ash.sound.bass.Channel, number | `0`>
local lengths = {}

setmetatable( lengths, {
    ---@param self table<ash.sound.bass.Channel, number | `0`>
    ---@param channel ash.sound.bass.Channel
    __index = function( self, channel )
        local length = math_max( 0, AudioChannel_GetLength( channels[ channel ] ) )
        self[ channel ] = length
        return length
    end,
    __mode = "k"
} )

---@type table<ash.sound.bass.Channel, boolean>
local is_streams = {}

setmetatable( is_streams, {
    ---@param self table<ash.sound.bass.Channel, boolean>
    ---@param channel ash.sound.bass.Channel
    __index = function( self, channel )
        local is_stream
        if lengths[ channel ] == 0 or AudioChannel_IsOnline( channels[ channel ] ) then
            is_stream = true
        else
            is_stream = false
        end

        self[ channel ] = is_stream
        return is_stream
    end,
    __mode = "k"
} )

--- [CLIENT]
---
--- Checks if the channel is a online stream.
---
---@return boolean is_stream
function Channel:isStream()
    return is_streams[ self ]
end

--- [CLIENT]
---
--- Checks if the channel is playing/buferring.
---
---@return boolean is_playing
---@return boolean is_buferring
function Channel:isPlaying()
    local state = AudioChannel_GetState( channels[ self ] )
    return state == 1 or state == 3, state == 3
end

--- [CLIENT]
---
--- Checks if the channel is stopped.
---
---@return boolean is_stopped
function Channel:isStopped()
    return AudioChannel_GetState( channels[ self ] ) == 0
end

--- [CLIENT]
---
--- Checks if the channel is paused.
---
---@return boolean is_paused
function Channel:isPaused()
    return AudioChannel_GetState( channels[ self ] ) == 2
end

--- [CLIENT]
---
--- Checks if the channel is buferring.
---
---@return boolean is_buferring
function Channel:isBuferring()
    return AudioChannel_GetState( channels[ self ] ) == 3
end

--- [CLIENT]
---
--- Returns the buferring time of the channel in seconds.
---
---@return number buferring_time
function Channel:getBuferringTime()
    if is_streams[ self ] then
        return AudioChannel_GetBufferedTime( channels[ self ] )
    end

    return 0
end

--- [CLIENT]
---
--- Returns the length of the channel in seconds.
---
--- If the channel is a online stream, `0` is returned.
---
---@return number | `0` length
function Channel:getLength()
    return lengths[ self ]
end

--- [CLIENT]
---
--- Sets the time of the channel.
---
---@param seconds number
function Channel:setTime( seconds )
    AudioChannel_SetTime( channels[ self ], math_clamp( seconds, 0, lengths[ self ] ) )
end

--- [CLIENT]
---
--- Adds time to the channel.
---
---@param seconds number
function Channel:addTime( seconds )
    self:setTime( AudioChannel_GetTime( channels[ self ] ) + seconds )
end

--- [CLIENT]
---
--- Takes time from the channel.
---
---@param seconds number
function Channel:takeTime( seconds )
    self:setTime( AudioChannel_GetTime( channels[ self ] ) - seconds )
end

--- [CLIENT]
---
--- Returns the pitch of the channel.
---
---@return integer pitch
function Channel:getPitch()
    return AudioChannel_GetPlaybackRate( channels[ self ] ) * 100
end

--- [CLIENT]
---
--- Sets the pitch of the channel.
---
---@param pitch integer
function Channel:setPitch( pitch )
    AudioChannel_SetPlaybackRate( channels[ self ], pitch * 0.01 )
end

--- [CLIENT]
---
--- Returns the balance of the channel.
---
---@return number balance
function Channel:getBalance()
    return ( AudioChannel_GetPan( channels[ self ] ) + 1 ) * 0.5
end

--- [CLIENT]
---
--- Sets the balance of the channel.
---
---@param balance number
function Channel:setBalance( balance )
    AudioChannel_SetPan( channels[ self ], math_clamp( balance * 2 - 1, -1, 1 ) )
end

--- [CLIENT]
---
--- Returns the minimum distance of the channel.
---
---@return number min_distance
function Channel:getFadeDistanceMin()
    local min_distance = AudioChannel_Get3DFadeDistance( channels[ self ] )
    return min_distance
end

--- [CLIENT]
---
--- Returns the maximum distance of the channel.
---
---@return number max_distance
function Channel:getFadeDistanceMax()
    local _, max_distance = AudioChannel_Get3DFadeDistance( channels[ self ] )
    return max_distance
end

--- [CLIENT]
---
--- Sets the minimum distance of the channel.
---
---@param min_distance number
function Channel:setFadeDistanceMin( min_distance )
    local channel = channels[ self ]
    local _, max_distance = AudioChannel_Get3DFadeDistance( channel )
    AudioChannel_Set3DFadeDistance( channel, min_distance, max_distance )
end

--- [CLIENT]
---
--- Sets the maximum distance of the channel.
---
---@param max_distance number
function Channel:setFadeDistanceMax( max_distance )
    local channel = channels[ self ]
    AudioChannel_Set3DFadeDistance( channel, AudioChannel_Get3DFadeDistance( channel ), max_distance )
end

--- [CLIENT]
---
--- Returns the inside projection angle of the channel.
---
--- Range is from 0 (no cone) to 360 (sphere)
---
---@return number inside_angle
function Channel:getInsideProjectionAngle()
    local inside_angle = AudioChannel_Get3DCone( channels[ self ] )
    return inside_angle
end

--- [CLIENT]
---
--- Returns the outside projection angle of the channel.
---
--- Range is from 0 (no cone) to 360 (sphere)
---
---@return number outside_angle
function Channel:getOutsideProjectionAngle()
    local _, outside_angle = AudioChannel_Get3DCone( channels[ self ] )
    return outside_angle
end

--- [CLIENT]
---
--- Returns the outside volume of the channel.
---
--- Range is from 0 (silent) to 1 (same as inside the cone)
---
---@return number outside_volume
function Channel:getOutsideVolume()
    local _, __, outside_volume = AudioChannel_Get3DCone( channels[ self ] )
    return outside_volume
end

--- [CLIENT]
---
--- Sets the inside projection angle of the channel.
---
--- Range is from 0 (no cone) to 360 (sphere)
---
---@param inside_angle number
function Channel:setInsideProjectionAngle( inside_angle )
    local channel = channels[ self ]
    local _, outside_angle, outside_volume = AudioChannel_Get3DCone( channel )
    AudioChannel_Set3DCone( channel, inside_angle, outside_angle, outside_volume )
end

--- [CLIENT]
---
--- Sets the outside projection angle of the channel.
---
--- Range is from 0 (no cone) to 360 (sphere)
---
---@param outside_angle number
function Channel:setOutsideProjectionAngle( outside_angle )
    local channel = channels[ self ]
    local inside_angle, _, outside_volume = AudioChannel_Get3DCone( channel )
    AudioChannel_Set3DCone( channel, inside_angle, outside_angle, outside_volume )
end

--- [CLIENT]
---
--- Sets the outside volume of the channel.
---
--- Range is from 0 (silent) to 1 (same as inside the cone)
---
---@param outside_volume number
function Channel:setOutsideVolume( outside_volume )
    local channel = channels[ self ]
    local inside_angle, outside_angle, _ = AudioChannel_Get3DCone( channel )
    AudioChannel_Set3DCone( channel, inside_angle, outside_angle, outside_volume )
end

---@alias ash.sound.bass.Callback fun( channel: ash.sound.bass.Channel | nil, error_id: integer | nil, error_msg: string | nil )

---@class ash.sound.bass.Params
---@field name string A sound name, path or URL.
---@field callback ash.sound.bass.Callback A callback function, which is called when the channel is created.
---@field volume number | nil Sound volume from 0 to 1.
---@field pitch integer | nil Sound pitch from 0 to 255.
---@field time number | nil Sound start time in seconds.
---@field loop boolean | nil Loop the sound.
---@field position Vector | nil Sound position on the game level ( map/world ).
---@field min_distance number | nil The minimum distance. The channel's volume is at maximum when the listener is within this distance.
---@field max_distance number | nil The maximum distance. The channel's volume stops decreasing when the listener is beyond this distance.
---@field inside_angle number | nil The angle of the inside projection cone in degrees. Range is from 0 (no cone) to 360 (sphere), -1 = leave current.
---@field outside_angle number | nil The angle of the outside projection cone in degrees. Range is from 0 (no cone) to 360 (sphere), -1 = leave current.
---@field outside_volume number | nil The delta-volume outside the outer projection cone. Range is from 0 (silent) to 1 (same as inside the cone), less than 0 = leave current.
---@field mono boolean | nil Make the sound mono.

--- [CLIENT]
---
--- Plays a sound using BASS library.
---
---@param params ash.sound.bass.Params
function ash_bass.play( params )
    local callback = params.callback
    if callback == nil then
        error( "callback is missing", 2 )
    end

    local flags = "noplay noblock"

    local position = params.position
    if position ~= nil then
        flags = flags .. " 3d"
    end

    if params.mono then
        flags = flags .. " mono"
    end

    local name = params.name

    local volume = params.volume
    local pitch = params.pitch
    local loop = params.loop

    local min_distance = params.min_distance
    local max_distance = params.max_distance

    local inside_angle = params.inside_angle
    local outside_angle = params.outside_angle
    local outside_volume = params.outside_volume

    ---@param channel ash.sound.bass.Channel
    ---@param error_id integer
    ---@param error_msg string
    local function bass_callback( channel, error_id, error_msg )
        if channel ~= nil then
            local object = ChannelClass( channel )

            if object:isValid() then
                if pitch ~= nil then
                    object:setPitch( pitch )
                end

                if volume ~= nil then
                    object:setVolume( volume )
                end

                if loop ~= nil then
                    object:setLooping( loop == true )
                end

                if position ~= nil then
                    object:setPosition( position )
                end

                if min_distance ~= nil then
                    object:setFadeDistanceMin( min_distance )
                end

                if max_distance ~= nil then
                    object:setFadeDistanceMax( max_distance )
                end

                if inside_angle ~= nil then
                    object:setInsideProjectionAngle( inside_angle )
                end

                if outside_angle ~= nil then
                    object:setOutsideProjectionAngle( outside_angle )
                end

                if outside_volume ~= nil then
                    object:setOutsideVolume( outside_volume )
                end

                callback( object, error_id, error_msg )
                return
            end
        end

        callback( nil, error_id, error_msg )
    end

    if string_isURL( name ) then
        sound_PlayURL( name, flags, bass_callback )
        return
    end

    local data = sound_get( name )

    if data ~= nil then
        local sounds = data.sound

        if istable( sounds ) then
            ---@cast sounds string[]
            name = sounds[ math_random( 1, #sounds ) ]
        else
            ---@cast sounds string
            name = sounds
        end

        if not isstring( name ) then
            error( "sound '" .. name .. "' has no file path", 2 )
        end

        name = "sound/" .. name

        if volume == nil then
            volume = data.volume
        end

        if pitch == nil then
            local pitch_data = data.pitch
            if istable( pitch_data ) then
                ---@cast pitch_data integer[]
                pitch = math_random( pitch_data[ 1 ], pitch_data[ 2 ] )
            elseif isnumber( pitch_data ) then
                ---@cast pitch_data integer
                pitch = math_floor( pitch_data )
            end
        end
    end

    if not file_Exists( name, "GAME" ) then
        error( "file '" .. name .. "' not found!", 2 )
    end

    if file_IsDir( name, "GAME" ) then
        error( "file '" .. name .. "' is a directory!", 2 )
    end

    sound_PlayFile( name, flags, bass_callback )
end

return ash_bass
