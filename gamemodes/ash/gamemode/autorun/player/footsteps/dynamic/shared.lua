hook.Add( "PlayerStepSoundTime", "StopNativeSounds", function()
    return 60000
end )

hook.Add( "PlayerFootstep", "StopNativeSounds", function()
    return true
end )
