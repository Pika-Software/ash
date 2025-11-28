local hook_Run = hook.Run

cvars.AddChangeCallback( "gmod_language", function( _, __, new_language )
	timer.Create( "LanguageChange", 0.025, 1, function()
        hook_Run( "LanguageChanged", cvars.String( "gmod_language", "en" ), new_language )
	end )
end, "LanguageChange" )
