
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


local math = std.math
local math_max = math.max
local math_clamp = math.clamp
local math_floor = math.floor
local math_random = math.random

local fs = std.fs

---@class ash.sound.bass
local ash_bass = {}

---@class ash.sound.bass.Channel : dreamwork.Object
---@field __class ash.sound.bass.ChannelClass
---@field isValid fun( self: ash.sound.bass.Channel ): boolean Returns `true` if the channel is valid.
---@field isBlocked fun( self: ash.sound.bass.Channel ): boolean Returns `true` if the channel is blocked.
---@field getStatus fun( self: ash.sound.bass.Channel ): GMOD_CHANNEL Returns the status of the channel. From 0 to 3.
---@field getFilePath fun( self: ash.sound.bass.Channel ): string Returns the file path of the channel.
---@field getBitRate fun( self: ash.sound.bass.Channel ): integer Returns the bit rate of the channel.
---@field getBitDepth fun( self: ash.sound.bass.Channel ): integer Returns the bit depth of the channel.
---@field getSampleRate fun( self: ash.sound.bass.Channel ): integer Returns the sample rate of the channel.
---@field getOGGVendor fun( self: ash.sound.bass.Channel ): string Returns the OGG vendor of the channel.
---@field getResponseHeaders fun( self: ash.sound.bass.Channel ): table Returns the response headers of the channel.
---@field getTime fun( self: ash.sound.bass.Channel ): number Returns the time of the channel.
---@field getVolume fun( self: ash.sound.bass.Channel ): number Returns the volume of the channel. Range is from 0 to 1.
---@field setVolume fun( self: ash.sound.bass.Channel, volume: number ) Sets the volume of the channel. Range is from 0 to 1.
---@field getVolumeLevels fun( self: ash.sound.bass.Channel ): number, number Returns the right and left levels of sound played by the sound channel. Range is from 0 to 1.
---@field getPlaybackRate fun( self: ash.sound.bass.Channel ): number Returns the playback rate of the channel.
---@field setPlaybackRate fun( self: ash.sound.bass.Channel, rate: number ) Sets the playback rate of the channel.
---@field isLooping fun( self: ash.sound.bass.Channel ): boolean Returns `true` if the channel is looping.
---@field setLooping fun( self: ash.sound.bass.Channel, loop: boolean ) Sets the looping of the channel.
---@field is3D fun( self: ash.sound.bass.Channel ): boolean Returns `true` if the channel is 3D.
---@field set3D fun( self: ash.sound.bass.Channel, enable: boolean ) Sets the channel to 3D.
---@field getPosition fun( self: ash.sound.bass.Channel ): Vector Returns the position of the channel.
---@field setPosition fun( self: ash.sound.bass.Channel, position: Vector ) Sets the position of the channel.
---@field getFadeDistance fun( self: ash.sound.bass.Channel ): number, number Returns 3D fade distances of a sound channel.
---@field setFadeDistance fun( self: ash.sound.bass.Channel, min: number, max: number ) Sets 3D fade distances of a sound channel.
---@field getProjectionCone fun( self: ash.sound.bass.Channel ): number, number, number Returns 3D projection cone of a sound channel.
---@field setProjectionCone fun( self: ash.sound.bass.Channel, inside_angle: number, outside_angle: number, outside_volume: number ) Sets 3D projection cone of a sound channel.
---@field pause fun( self: ash.sound.bass.Channel ) Pauses the channel.
---@field play fun( self: ash.sound.bass.Channel ) Plays the channel.
---@field stop fun( self: ash.sound.bass.Channel ) Stops the channel.
---@field fft fun( self: ash.sound.bass.Channel, fft: integer[], size: integer ): integer Returns the number of frequency bins that have been filled in the output table.
local Channel = class.base( "bass.Channel", true )

---@class ash.sound.bass.ChannelClass : ash.sound.bass.Channel
---@field __base ash.sound.bass.Channel
local ChannelClass = class.create( Channel )

---@type table<ash.sound.bass.Channel, IGModAudioChannel>
local channels = {}
setmetatable( channels, { __mode = "k" } )

---@param channel IGModAudioChannel
---@protected
function Channel:__init( channel )
    channels[ self ] = channel
end

function Channel:__gc()
    self:stop()
end

local function channel_alias( name, fn )
    Channel[ name ] = function( self, ... )
        return fn( channels[ self ], ... )
    end
end

channel_alias( "IsValid", AudioChannel_IsValid )
channel_alias( "isValid", AudioChannel_IsValid )
channel_alias( "isBlocked", AudioChannel.IsBlockStreamed )

channel_alias( "getStatus", AudioChannel_GetState )
channel_alias( "getFilePath", AudioChannel.GetFileName )

channel_alias( "getBitRate", AudioChannel.GetAverageBitRate )
channel_alias( "getBitDepth", AudioChannel.GetBitsPerSample )
channel_alias( "getSampleRate", AudioChannel.GetSamplingRate )

channel_alias( "getOGGVendor", AudioChannel.GetTagsVendor )
channel_alias( "getResponseHeaders", AudioChannel.GetTagsHTTP )

channel_alias( "getTime", AudioChannel_GetTime )

channel_alias( "getVolume", AudioChannel.GetVolume )
channel_alias( "setVolume", AudioChannel_SetVolume )
channel_alias( "getVolumeLevels", AudioChannel.GetLevel )

channel_alias( "getPlaybackRate", AudioChannel_GetPlaybackRate )
channel_alias( "setPlaybackRate", AudioChannel_SetPlaybackRate )

channel_alias( "isLooping", AudioChannel.IsLooping )
channel_alias( "setLooping", AudioChannel.EnableLooping )

channel_alias( "is3D", AudioChannel.Get3DEnabled )
channel_alias( "set3D", AudioChannel.Set3DEnabled )
channel_alias( "getPosition", AudioChannel_GetPos )
channel_alias( "setPosition", AudioChannel_SetPos )
channel_alias( "getFadeDistance", AudioChannel_Get3DFadeDistance )
channel_alias( "setFadeDistance", AudioChannel_Set3DFadeDistance )
channel_alias( "getProjectionCone", AudioChannel_Get3DCone )
channel_alias( "setProjectionCone", AudioChannel_Set3DCone )

channel_alias( "pause", AudioChannel.Pause )
channel_alias( "play", AudioChannel.Play )
channel_alias( "stop", AudioChannel.Stop )

channel_alias( "fft", AudioChannel.FFT )

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
    ---@return table tags
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

    if fs.isFile( "/workspace/" .. name ) then
        sound_PlayFile( name, flags, bass_callback )
    end

    error( "file '" .. name .. "' not found", 2 )
end

return ash_bass
