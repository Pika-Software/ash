local Entity_EntIndex = Entity.EntIndex
local Entity_IsValid = Entity.IsValid
local hook_Run = hook.Run

---@type ash.player
local ash_player = require( "ash.player" )
local player_isSpeaking = ash_player.isSpeaking

---@type ash.sound.bass
local ash_bass = require( "ash.sound.bass" )

-- ---@type ash.player.voice
-- local ash_voice = require( "ash.player.voice" )

---@type table<Player, ash.sound.bass.Channel>
local channels = {}
setmetatable( channels, { __mode = "k" } )

---@param pl Player
local function stop( pl )
    timer.Remove( "play." .. Entity_EntIndex( pl ) )

    local channel = channels[ pl ]
    channels[ pl ] = nil

    if channel ~= nil and channel:isValid() then
        channel:stop()
        hook_Run( "PlayerEndVoice", pl )
    end
end

net.Receive( "sync", function()
    local pl = net.ReadPlayer()
    if pl == nil or not Entity_IsValid( pl ) then return end

    if not net.ReadBool() then
        stop( pl )
        return
    end

    if player_isSpeaking( pl ) then return end

    local start_time = net.ReadDouble()
    local file_path = net.ReadString()
    local sound_level = net.ReadUInt( 9 )
    local sound_pitch = net.ReadUInt( 8 )
    local sound_volume = net.ReadFloat()

    ash_bass.play( {
        name = "sound/" .. file_path,
        volume = 0,
        pitch = sound_pitch,
        callback = function( channel, _, error_msg )
            if channel == nil then
                error( error_msg )
            end

            if player_isSpeaking( pl ) then
                return
            end

            hook_Run( "PlayerStartVoice", pl )

            channels[ pl ] = channel
            channel:setTime( CurTime() - start_time )
            channel:play()

            if not channel:isStream() then
                timer.Create( "play." .. Entity_EntIndex( pl ), channel:getLength(), 1, function()
                    stop( pl )
                end )
            end
        end
    } )
end )

hook.Add( "PlayerStartVoice", "Cleanup", function( pl )
    local channel = channels[ pl ]
    if channel ~= nil and channel:isValid() then
        channel:stop()
    end
end, PRE_HOOK )

hook.Add( "PlayerVoiceVolume", "Volume", function( pl, volume )
    local channel = channels[ pl ]
    if channel ~= nil and channel:isValid() then
        return channel:getVolumeLevel()
    end
end )

-- hook.Add( "PlayerThink", "Perform", function( pl, me )
--     if hook_Run( "PlayerCanHearPlayersVoice", me, pl ) == false then
--         return
--     end



-- end )

