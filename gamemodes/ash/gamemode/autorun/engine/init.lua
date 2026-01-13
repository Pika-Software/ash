MODULE.ClientFiles = {
    "cl_init.lua",
    "shared.lua"
}

---@class ash.engine
local ash_engine = include( "shared.lua" )

local RunConsoleCommand = _G.RunConsoleCommand

local convars = {
    { "sv_defaultdeployspeed", "1" },
    { "mp_show_voice_icons", "0" },
    { "sv_gravity", "800" }
}

hook.Add( "InitPostEntity", "Defaults", function()
    for i = 1, #convars, 1 do
        local convar_data = convars[ i ]
        RunConsoleCommand( convar_data[ 1 ], convar_data[ 2 ] )
    end
end, PRE_HOOK )

resource.AddWorkshop( "129739986" )

do

    local timer_Remove = _G.timer.Remove
    local hook_Remove = _G.hook.Remove

    -- garrysmod/gamemodes/sandbox/gamemode/persistence.lua
    hook_Remove( "InitPostEntity", "PersistenceInit" )
    hook_Remove( "ShutDown", "SavePersistenceOnShutdown" )

    hook_Remove( "PersistenceSave", "PersistenceSave" )

    hook_Remove( "PersistenceLoad", "PersistenceLoad" )
    hook_Remove( "PostCleanupMap", "GMod_Sandbox_PersistanceLoad" )

    timer_Remove( "sbox_persist_change_timer" )

    -- garrysmod/lua/includes/extensions/player_auth.lua
    hook_Remove( "PlayerInitialSpawn", "PlayerAuthSpawn" ) -- purified piece of crap

    -- garrysmod/lua/includes/extensions/util/worldpicker.lua
    hook_Remove( "VGUIMousePressAllowed", "WorldPickerMouseDisable" )

end

return ash_engine
