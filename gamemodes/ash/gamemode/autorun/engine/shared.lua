---@class ash.engine
local ash_engine = {}

local hook_Run = hook.Run

cvars.AddChangeCallback( "gmod_language", function( _, __, new_language )
	timer.Create( "LanguageChange", 0.025, 1, function()
        hook_Run( "LanguageChanged", cvars.String( "gmod_language", "en" ), new_language )
	end )
end, "LanguageChange" )

do

    local hook_Remove = _G.hook.Remove
	hook_Remove( "EntityRemoved", "RemoveWidgets" )
	hook_Remove( "OnEntityCreated", "CreateWidgets" )

	-- garrysmod/lua/includes/modules/notification.lua
	hook_Remove( "Think", "NotificationThink" )

	-- garrysmod/lua/includes/extensions/entity.lua
	-- hook_Remove( "EntityRemoved", "DoDieFunction" ) -- still trash, but full removing take some time

end

hook.Add( "PostGamemodeLoaded", "Compatibility", function()
	local GM = ( GM or GAMEMODE )

	GM.GrabEarAnimation = debug.fempty
	GM.MouthMoveAnimation = debug.fempty
end, POST_HOOK )

return ash_engine
