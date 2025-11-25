local Entity_GetVelocity = Entity.GetVelocity
local Player_Crouching = Player.Crouching
local Vector_Length2D = Vector.Length2D

hook.Add( "PlayerStepSoundTime", "StopNativeSounds", function( pl, step_type, is_walking )
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

if CLIENT then

    hook.Add( "PlayerFootstep", "OnlyServerSounds", function( pl, origin, foot_num, sound_name, volume )
        return true
    end )

end
