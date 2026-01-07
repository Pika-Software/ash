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

return ash_engine
