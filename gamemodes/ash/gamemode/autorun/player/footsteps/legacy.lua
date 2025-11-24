if CLIENT then

    hook.Add( "PlayerFootstep", "OnlyServerSounds", function( pl, origin, foot_num, sound_name, volume )
        return true
    end )

end

if SERVER then

    MODULE.ClientFiles = {
        "legacy.lua"
    }

    ---@type ash.sound
    local sound_lib = require( "ash.sound" )
    local sound_play = sound_lib.play

    hook.Add( "PlayerFootstep", "ServerSounds", function( pl, origin, foot_num, sound_name, volume, rf )
        sound_play( sound_name, origin, nil, math.random( 118, 138 ), volume, 1 )
        return true
    end )

end

local Entity_GetPlaybackRate = Entity.GetPlaybackRate
local Entity_GetVelocity = Entity.GetVelocity
local Player_Crouching = Player.Crouching
local Vector_Length2D = Vector.Length2D

hook.Add( "PlayerStepSoundTime", "StopNativeSounds", function( pl, step_type, is_walking )
    local sequence_id = pl:GetSequence()
    if sequence_id ~= nil and sequence_id > 0 then
        local sequence_duration = pl:SequenceDuration( sequence_id )
        if sequence_duration ~= nil and sequence_duration > 0 then
            return sequence_duration * 500 * Entity_GetPlaybackRate( pl )
        end
    end

    if step_type == 1 then
        -- on ladder
        return 450
    end

    local step_time = 350

    if step_type == 2 then
        -- water reaching knee
        step_time = 600
    else

        -- normal walking
        local vertical_speed = Vector_Length2D( Entity_GetVelocity( pl ) )
        if vertical_speed <= 100 then
            step_time = 400
        elseif vertical_speed <= 300 then
            step_time = 350
        else
            step_time = 250
        end

    end

    -- water reaching foot
    if step_type == 3 then
        step_time = step_time * 1.15
    end

    -- crouching
    if Player_Crouching( pl ) then
		step_time = step_time * 1.2
	end

	return step_time
end )
