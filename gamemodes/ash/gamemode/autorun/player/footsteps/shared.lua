hook.Add( "PlayerStepSoundTime", "StopNativeSounds", function()
    return 1000
end )

hook.Add( "PlayerFootstep", "StopNativeSounds", function()
    return true
end )
